module app::approvers {

    use std::signer;
    use aptos_std::smart_table::{SmartTable, add};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::timestamp;
    friend app::fundraiser;

    // ERRORS
    const ERROR_USER_UNAUTHORIZED: u64 = 1;
    const ERROR_ADDRESS_NOT_APPROVER: u64 = 2;

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
    public entry fun become_approver(
        account: &signer,
        amount: u64
    ) {
        coin::transfer<AptosCoin>(account, @app, amount);
        move_to(account, Approver{
            last_withdrawal_timestamp: timestamp::now_seconds(),
            is_approved: false,
            amount_staked: amount
        });
    }

    public entry fun allow_approver(
        account: &signer,
        approve_request_address: address
    ) acquires Approver, Admin {
        assert!(exists<Admin>(signer::address_of(account)), ERROR_USER_UNAUTHORIZED);
        assert!(exists<Approver>(approve_request_address), ERROR_ADDRESS_NOT_APPROVER);

        let approver_resource = borrow_global_mut<Approver>(approve_request_address);
        approver_resource.is_approved = true;
        approver_resource.last_withdrawal_timestamp = timestamp::now_seconds();

        let admin_resource = borrow_global_mut<Admin>(signer::address_of(account));
        add(&mut admin_resource.approver_to_amount_staked, approve_request_address, approver_resource.amount_staked);
    }
}
