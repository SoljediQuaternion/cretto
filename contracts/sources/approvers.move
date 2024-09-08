module app::approvers {

    use std::signer;
    use aptos_std::smart_table::{SmartTable, add, borrow_mut};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::event;
    use aptos_framework::timestamp;
    friend app::fundraiser;

    // ERRORS
    const ERROR_USER_ALREADY_HAS_APPROVER_RESOURCE: u64 = 1;
    const ERROR_USER_UNAUTHORIZED: u64 = 2;
    const ERROR_ADDRESS_NOT_APPROVER: u64 = 3;
    const ERROR_AMOUNT_ADDED_TOO_LOW: u64 = 4;
    const ERROR_USER_NOT_STAKER: u64 = 5;
    const ERROR_ADMIN_CANNOT_BE_APPROVER: u64 = 6;
    const ERROR_DELAY_BETWEEN_CONSECUTIVE_WITHDRAWALS_TOO_LOW: u64 = 7;
    const ERROR_WITHDRAWAL_AMOUNT_TOO_HIGH: u64 = 8;
    const ERROR_USER_ALREADY_UNAUTHORIZED: u64 = 9;
    // CONSTANTS
    const MIN_APPROVER_STAKE: u64 = 1000;
    const MIN_DELAY_BETWEEN_WITHDRAWALS_IN_SECONDS: u64 = 1000;

    // EVENTS
    #[event]
    struct ApproverRequestRaised has store, drop {
        approval_request: address,
        amount_to_stake: u64
    }

    #[event]
    struct ApproverRequestApproved has store, drop {
        approved_user: address,
        amount_staked: u64
    }

    #[event]
    struct ApproverSlashed has store, drop {
        slashed_user: address
    }

    // STRUCTS
    struct Admin has key, store {
        total_approvers_stake: u64,
        approver_to_amount_staked: SmartTable<address, u64>
    }

    struct Approver has key, store {
        last_withdrawal_timestamp: u64,
        is_approved: bool,
        amount_staked: u64
    }

    // FUNCTIONS
    public entry fun become_approver(account: &signer, amount: u64) {
        assert!(
            !exists<Admin>(signer::address_of(account)), ERROR_ADMIN_CANNOT_BE_APPROVER
        );
        assert!(
            !exists<Approver>(signer::address_of(account)),
            ERROR_USER_ALREADY_HAS_APPROVER_RESOURCE
        );
        assert!(amount >= MIN_APPROVER_STAKE, ERROR_AMOUNT_ADDED_TOO_LOW);
        coin::transfer<AptosCoin>(account, @app, amount);
        move_to(
            account,
            Approver {
                last_withdrawal_timestamp: timestamp::now_seconds(),
                is_approved: false,
                amount_staked: amount
            }
        );
    }

    public entry fun allow_approver(
        account: &signer, approve_request_address: address
    ) acquires Approver, Admin {
        assert!(exists<Admin>(signer::address_of(account)), ERROR_USER_UNAUTHORIZED);
        assert!(exists<Approver>(approve_request_address), ERROR_ADDRESS_NOT_APPROVER);

        let approver_resource: &mut Approver =
            borrow_global_mut<Approver>(approve_request_address);
        approver_resource.is_approved = true;
        approver_resource.last_withdrawal_timestamp = timestamp::now_seconds();

        let admin_resource: &mut Admin =
            borrow_global_mut<Admin>(signer::address_of(account));
        add(
            &mut admin_resource.approver_to_amount_staked,
            approve_request_address,
            approver_resource.amount_staked
        );
    }

    public entry fun stake(account: &signer, amount: u64) acquires Approver, Admin {
        assert!(exists<Approver>(signer::address_of(account)), ERROR_ADDRESS_NOT_APPROVER);
        assert!(amount >= MIN_APPROVER_STAKE, ERROR_AMOUNT_ADDED_TOO_LOW);
        let approver_resource: &mut Approver =
            borrow_global_mut<Approver>(signer::address_of(account));
        coin::transfer<AptosCoin>(account, @app, amount);
        if (approver_resource.is_approved == false) {
            approver_resource.amount_staked = approver_resource.amount_staked + amount;
        } else {
            // In case user already allowed to approve other users
            // then his balance is added to staked amount
            let admin_resource = borrow_global_mut<Admin>(@admin);
            let old_amount_stake =
                borrow_mut(
                    &mut admin_resource.approver_to_amount_staked,
                    signer::address_of(account)
                );
            *old_amount_stake = *old_amount_stake + amount;
            admin_resource.total_approvers_stake = admin_resource.total_approvers_stake
                + amount;
        };
    }

    public entry fun slash_approver(
        account: &signer, approver_address: address
    ) acquires Admin, Approver {
        assert!(exists<Admin>(signer::address_of(account)), ERROR_USER_UNAUTHORIZED);
        assert!(exists<Approver>(approver_address), ERROR_ADDRESS_NOT_APPROVER);
        let approver_resource = borrow_global_mut<Approver>(signer::address_of(account));
        assert!(approver_resource.is_approved, ERROR_USER_ALREADY_UNAUTHORIZED);

        approver_resource.is_approved = false;
        approver_resource.amount_staked = 0;

        let admin_resource = borrow_global_mut<Admin>(@admin);
        let stake_amount =
            borrow_mut(&mut admin_resource.approver_to_amount_staked, approver_address);
        *stake_amount = 0;
        event::emit(ApproverSlashed{
            slashed_user: signer::address_of(account)
        });
    }

    public entry fun withdraw_amount(account: &signer, amount: u64) acquires Admin, Approver {
        // user should have approver resource
        assert!(exists<Approver>(signer::address_of(account)), ERROR_ADDRESS_NOT_APPROVER);
        let approver_resource = borrow_global_mut<Approver>(signer::address_of(account));
        let time_delta =
            timestamp::now_seconds() - approver_resource.last_withdrawal_timestamp;
        // check difference between last withdrawal timestamp and current.
        assert!(
            time_delta >= MIN_DELAY_BETWEEN_WITHDRAWALS_IN_SECONDS,
            ERROR_DELAY_BETWEEN_CONSECUTIVE_WITHDRAWALS_TOO_LOW
        );
        // case-1: user is not yet approved
        if (approver_resource.is_approved == false) {
            let max_withdrawal_allowed = approver_resource.amount_staked;
            assert!(max_withdrawal_allowed < amount, ERROR_WITHDRAWAL_AMOUNT_TOO_HIGH);
            // TODO : transfer coins from @app to approver

            approver_resource.last_withdrawal_timestamp = timestamp::now_seconds();
            approver_resource.amount_staked = approver_resource.amount_staked - amount;
        } else {
            let admin_resource = borrow_global_mut<Admin>(@admin);
            let max_withdrawal_allowed =
                (coin::balance<AptosCoin>(@app) * approver_resource.amount_staked)
                    / admin_resource.total_approvers_stake;
            assert!(max_withdrawal_allowed < amount, ERROR_WITHDRAWAL_AMOUNT_TOO_HIGH);
            // TODO : transfer coins from @app to approver

            approver_resource.last_withdrawal_timestamp = timestamp::now_seconds();
            approver_resource.amount_staked = approver_resource.amount_staked - amount;
            admin_resource.total_approvers_stake = admin_resource.total_approvers_stake
                - amount;
            let prev_user_balance =
                borrow_mut(
                    &mut admin_resource.approver_to_amount_staked,
                    signer::address_of(account)
                );
            *prev_user_balance = *prev_user_balance - amount;
        };

    }

    #[view]
    public(friend) fun is_approver_verified(address: address): bool acquires Approver{
        assert!(exists<Approver>(address), ERROR_USER_UNAUTHORIZED);
        let approver_resource = borrow_global<Approver>(address);
        approver_resource.is_approved
    }
}
