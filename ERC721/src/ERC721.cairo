#[contract]
mod ERC721 {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use array::ArrayTrait;
    use zeroable::Zeroable;

    // storage
    struct Storage {
        name: felt252,
        symbol: felt252,
        owner: LegacyMap::<u256, ContractAddress>,
        balance: LegacyMap::<ContractAddress, u256>,
        token_approvals: LegacyMap::<(ContractAddress, u256), ContractAddress>,
        token_uri: LegacyMap::<u256, felt252>,
        token_counter: u256,
        admin: ContractAddress,
    }

    #[constructor]
    fn constructor(name: felt252, symbol: felt252) {
        name::write(name);
        symbol::write(symbol);
        admin::write(get_caller_address());
    }

    #[view]
    fn balance_of(owner: ContractAddress) -> u256 {
        assert(!owner.is_zero(), 'ERC721: address_zero');
        balance::read(owner)
    }

    #[view]
    fn owner_of(tokenId: u256) -> ContractAddress {
        let T_owner: ContractAddress = owner::read(tokenId);
        assert(!T_owner.is_zero(), 'ERC721: invalid tokenId');
        T_owner
    }

    #[view]
    fn getApproved(tokenId: u256, owner: ContractAddress) -> ContractAddress {
        assert(!owner.is_zero(), 'ERC721: address_zero(input)');
        let approved: ContractAddress = token_approvals::read((owner, tokenId));
        assert(!approved.is_zero(), 'ERC721: address_zero(approved)');
        approved
    }

    #[view]
    fn tokenURI(tokenId: u256) -> felt252 {
        let Token_owner: ContractAddress = owner::read(tokenId);
        assert(!Token_owner.is_zero(), 'ERC721: invalid tokenId');
        token_uri::read(tokenId)
    }

    #[extermal]
    fn approve(to: ContractAddress, tokenId: u256) {
        assert(!to.is_zero(), 'ERC721: address_zero');
        let caller: ContractAddress = get_caller_address();
        assert(owner::read(tokenId) == caller, 'ERC721: Not owner');
        token_approvals::write((caller, tokenId), to);
    }

    #[external]
    fn transfer(to: ContractAddress, tokenId: u256) {
        assert(!to.is_zero(), 'ERC721: address_zero');
        let caller: ContractAddress = get_caller_address();
        assert(owner::read(tokenId) == caller, 'ERC721: Not owner');
        _transfer(caller, to, tokenId);
    }

    #[external]
    fn transfer_from(from: ContractAddress, to: ContractAddress, tokenId: u256) {
        assert(!to.is_zero() & !from.is_zero(), 'ERC721: address_zero');
        let caller: ContractAddress = get_caller_address();
        assert(owner::read(tokenId) == from, 'ERC721: From Add. Not Owner');
        assert(token_approvals::read((from, tokenId)) == caller, 'ERC721: Not approved');
        token_approvals::write((from, tokenId), Zeroable::zero());
        _transfer(from, to, tokenId);
    }

    #[external]
    fn mint(to: ContractAddress, Uri: felt252) -> u256 {
        assert(get_caller_address() == admin::read(), 'ERC721: not Admin');
        assert(!to.is_zero(), 'ERC721: address zero');
        // assert(Uri.len() > 0 & Uri.len() < 31, 'ERC721: wrong uri format');
        let tokenId = _token_counter();
        balance::write(to, balance::read(to) + 1);
        owner::write(tokenId, to);
        token_uri::write(tokenId, Uri);
        tokenId
    }

    #[external]
    fn burn(tokenId: u256) {
        let caller: ContractAddress = get_caller_address();
        assert(owner::read(tokenId) == caller, 'ERC721: Not owner');
        _transfer(caller, Zeroable::zero(), tokenId);
    }


    #[external]
    fn bulk_transfer_to_single_receiver(tokenIDs: Array::<u256>, to: ContractAddress) {
        assert(!to.is_zero(), 'ERC721: address zero');
        assert(tokenIDs.len() != 0, 'ERC721: Empty Id list');
        let no_of_tokens: usize = tokenIDs.len();
        let caller: ContractAddress = get_caller_address();
        let mut i: usize = 0;
        let mut j: usize = 0;
        // Loop through to assert confirm the tokens belong to the caller
        loop {
            if i == no_of_tokens {
                break ();
            }
            if i < no_of_tokens {
                assert(owner::read(*tokenIDs.at(i)) == caller, 'ERC721: Not owner');
            }
            i += 1;
        };
        // loop through to transfer the tokens
        loop {
            if j == no_of_tokens {
                break ();
            }
            if j < no_of_tokens {
                _transfer(caller, to, *tokenIDs.at(j));
            }
            j += 1;
        }
    }

    #[external]
    fn bulk_transfer(tokenIDs: Array::<u256>, receivers: Array::<ContractAddress>) {
        assert(tokenIDs.len() != 0, 'ERC721: Empty Id list');
        assert(tokenIDs.len() == receivers.len(), 'ERC721: array length mismatch');
        let no_of_tokens: usize = tokenIDs.len();
        let caller: ContractAddress = get_caller_address();
        let mut i: usize = 0;
        let mut j: usize = 0;
        // Loop through to assert confirm the tokens belong to the caller
        loop {
            if i == no_of_tokens {
                break ();
            }
            if i < no_of_tokens {
                assert(owner::read(*tokenIDs.at(i)) == caller, 'ERC721: Not owner');
                assert(!((*receivers.at(i)).is_zero()), 'ERC721: address_zero');
            }
            i += 1;
        };
        // loop through to transfer the tokens
        loop {
            if j == no_of_tokens {
                break ();
            }
            if j < no_of_tokens {
                _transfer(caller, (*receivers.at(j)), *tokenIDs.at(j));
            }
            j += 1;
        }
    }

    #[Internal]
    fn _transfer(from: ContractAddress, to: ContractAddress, tokenId: u256) {
        balance::write(from, balance::read(from) - 1);
        balance::write(to, balance::read(to) + 1);
        owner::write(tokenId, to);
    }

    #[internal]
    fn _token_counter() -> u256 {
        let current_count: u256 = token_counter::read();
        let Id: u256 = current_count + 1;
        token_counter::write(Id);
        Id
    }
}