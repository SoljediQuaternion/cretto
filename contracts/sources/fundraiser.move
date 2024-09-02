module app::fundraiser {

    use std::signer;
    use std::vector;
    use aptos_framework::event;
    use aptos_framework::guid;
    use aptos_framework::timestamp;

    // EVENTS
    #[event]
    struct FundraiserStarted has store, drop {
        fundraise_creator: address,
        recepient_address: address,
        id: guid::ID,
        amount_to_raise: u64,
        timestamp: u64
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
            id: fundraise_new_id,
            amount_to_raise,
            timestamp: timestamp::now_seconds()
        });
    }
}

// STRUCTS
// fundraiser struct
// fundraiserStore struct
// struct for approvers
// --------------------------------------------------------------
// FUNCTIONS
// create a fundraiser
// donate to a fundraiser (some % given to approvers, admin) -> feature (seperate vault for approvers)
// withdraw money from fundraiser