module app::fundraiser {


    use std::signer;
    use std::vector;
    use aptos_framework::event;
    use aptos_framework::guid;
    use aptos_framework::timestamp;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    // ERRORS
    const ERROR_FUNDRAISE_STORE_DOES_NOT_EXIST: u64 = 1;
    const ERROR_FUNDRAISER_NOT_FOUND: u64 = 2;
    const ERROR_FUNDRAISER_NOT_APPROVED: u64 = 3;
    const ERROR_INSUFFICIENT_BALANCE: u64 = 4;
    const ERROR_FUNDRAISE_ALREADY_APPROVED: u64 = 5;

    // CONSTANTS
    const ADMIN_PERCENTAGE: u8 = 2;
    const APPROVERS_PERCENTAGE: u8 = 3;

    // EVENTS
    #[event]
    struct FundraiserStarted has store, drop {
        fundraise_creator: address,
        recepient_address: address,
        id: u64,
        amount_to_raise: u64,
        timestamp: u64
    }

    #[event]
    struct DonationMade has store, drop {
        donor: address,
        fundraise_creator: address,
        fundraise_id: u64,
        amount: u64,
        timestamp: u64
    }

    #[event]
    struct FundraiseApproved has store, drop {
        fundraise_creator: address,
        fundraise_id: u64,
        approver: address
    }


    struct FundraiserStore has key, store {
        fundraisers: vector<Fundraise>,
        fundraisers_count: u64
    }

    struct Fundraise has store, drop {
        id: guid::ID,
        recepient_address: address,
        is_approved: bool,
        approved_by: address,
        amount_to_raise: u64,
        amount_raised: u64
    }

    public entry fun start_fundraiser(
        account: &signer,
        recepient_address: address,
        amount_to_raise: u64
    ) acquires FundraiserStore {
        let fundraiser_creator = signer::address_of(account);
        if(!exists<FundraiserStore>(fundraiser_creator)){
            move_to(account, FundraiserStore{
                fundraisers: vector<Fundraise>[],
                fundraisers_count: 0
            });
        };

        let store = borrow_global_mut<FundraiserStore>(fundraiser_creator);

        let fundraise_new_id: guid::ID = guid::create_id(fundraiser_creator, store.fundraisers_count);
        let new_fundraiser = Fundraise {
            id: fundraise_new_id,
            recepient_address,
            is_approved: false,
            approved_by: @0x0,
            amount_to_raise,
            amount_raised: 0
        };

        vector::push_back(&mut store.fundraisers, new_fundraiser);
        store.fundraisers_count = store.fundraisers_count + 1;
        event::emit(FundraiserStarted{
            fundraise_creator: fundraiser_creator,
            recepient_address,
            id: store.fundraisers_count,
            amount_to_raise,
            timestamp: timestamp::now_seconds()
        });
    }

    public entry fun donate(
        account: &signer,
        fundraiser_creator: address,
        fundraise_index: u64,
        amount: u64
    ) acquires FundraiserStore {
        assert!(exists<FundraiserStore>(fundraiser_creator), ERROR_FUNDRAISE_STORE_DOES_NOT_EXIST);
        let fundraise_store = borrow_global_mut<FundraiserStore>(fundraiser_creator);

        // Find the fundraiser
        assert!( fundraise_index < vector::length(&fundraise_store.fundraisers),  ERROR_FUNDRAISER_NOT_FOUND);
        let fundraiser = vector::borrow_mut(&mut fundraise_store.fundraisers, fundraise_index);

        let donor_address = signer::address_of(account);

        // Check if the donor has sufficient balance
        assert!(coin::balance<AptosCoin>(donor_address) >= amount, ERROR_INSUFFICIENT_BALANCE);

        // Calculate distribution
        let admin_amount = (((amount as u128) * (ADMIN_PERCENTAGE as u128) / 100u128) as u64);
        let approvers_amount = (((amount as u128) * (APPROVERS_PERCENTAGE as u128) / 100u128) as u64);
        let recipient_amount = amount - admin_amount - approvers_amount;

        // TODO: Transfer funds portion
        coin::transfer<AptosCoin>(account, @admin, admin_amount);
        coin::transfer<AptosCoin>(account, @app, approvers_amount);
        coin::transfer<AptosCoin>(account, fundraiser.recepient_address, recipient_amount);

        // Update fundraiser state
        fundraiser.amount_raised = fundraiser.amount_raised + amount;

        // Emit event
        event::emit(DonationMade {
            donor: donor_address,
            fundraise_creator: fundraiser_creator,
            fundraise_id: fundraise_index,
            amount,
            timestamp: timestamp::now_seconds()
        });
    }

    public entry fun approve_fundraise(
        account: &signer,
        fundraiser_creator: address,
        fundraise_index: u64
    ) acquires FundraiserStore {
        assert!(exists<FundraiserStore>(fundraiser_creator), ERROR_FUNDRAISE_STORE_DOES_NOT_EXIST);
        let fundraise_store = borrow_global_mut<FundraiserStore>(fundraiser_creator);

        // TODO: check if account is approver or not

        assert!( fundraise_index < vector::length(&fundraise_store.fundraisers),  ERROR_FUNDRAISER_NOT_FOUND);
        let fundraise = vector::borrow_mut(&mut fundraise_store.fundraisers, fundraise_index);
        assert!(!fundraise.is_approved, ERROR_FUNDRAISE_ALREADY_APPROVED);
        fundraise.is_approved = true;
        fundraise.approved_by = signer::address_of(account);
        event::emit(FundraiseApproved{
            fundraise_creator: fundraiser_creator,
            fundraise_id: fundraise_index,
            approver: signer::address_of(account)
        });
    }
}
