#[starknet::contract]
mod NFTMinterContract {
    ////////////////////////////////
    // library imports
    ////////////////////////////////
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use zeroable::Zeroable;
    use starknet::contract_address_to_felt252;
    use traits::Into;
    use traits::TryInto;
    use option::OptionTrait;

    ////////////////////////////////
    // storage variables
    ////////////////////////////////
    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        owners: LegacyMap::<u256, ContractAddress>,
        balances: LegacyMap::<ContractAddress, u256>,
        token_uri: LegacyMap<u256, felt252>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
    }

    ////////////////////////////////
    // Transfer event emitted on token transfer
    ////////////////////////////////
    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }


    ////////////////////////////////
    // Constructor - initialized on deployment
    ////////////////////////////////
    #[constructor]
    fn constructor(ref self: ContractState, _name: felt252, _symbol: felt252) {
        self.name.write(_name);
        self.symbol.write(_symbol);
    }

    #[external(v0)]
    #[generate_trait]
    impl IERC721Impl of IERC721Trait {
        ////////////////////////////////
        // get_name function returns token name
        ////////////////////////////////
        fn get_name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        ////////////////////////////////
        // get_symbol function returns token symbol
        ////////////////////////////////
        fn get_symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        ////////////////////////////////
        // token_uri returns the token uri
        ////////////////////////////////
        fn get_token_uri(self: @ContractState, token_id: u256) -> felt252 {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self.token_uri.read(token_id)
        }

        ////////////////////////////////
        // balance_of function returns token balance
        ////////////////////////////////
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            assert(account.is_non_zero(), 'ERC721: address zero');
            self.balances.read(account)
        }

        ////////////////////////////////
        // owner_of function returns owner of token_id
        ////////////////////////////////
        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let owner = self.owners.read(token_id);
            assert(owner.is_non_zero(), 'ERC721: invalid token ID');
            owner
        }


        ////////////////////////////////
        // mint function is used to mint a new token
        ////////////////////////////////
        fn mint(ref self: ContractState, to: ContractAddress, token_id: u256, token_uri: felt252) {
            self._mint(to, token_id, token_uri);
        }
    }

    #[generate_trait]
    impl ERC721HelperImpl of ERC721HelperTrait {
        ////////////////////////////////
        // internal function to check if a token exists
        ////////////////////////////////
        fn _exists(self: @ContractState, token_id: u256) -> bool {
            // check that owner of token is not zero
            self.owner_of(token_id).is_non_zero()
        }

        ////////////////////////////////
        // internal function that sets the token uri
        ////////////////////////////////
        fn _set_token_uri(ref self: ContractState, token_id: u256, token_uri: felt252) {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self.token_uri.write(token_id, token_uri)
        }

        ////////////////////////////////
        // _mint function mints a new token to the to address
        ////////////////////////////////
        fn _mint(ref self: ContractState, to: ContractAddress, token_id: u256, token_uri: felt252) {
            assert(to.is_non_zero(), 'TO_IS_ZERO_ADDRESS');

            // Ensures token_id is unique
            assert(!self.owner_of(token_id).is_non_zero(), 'ERC721: Token already minted');

            // Increase receiver balance
            let receiver_balance = self.balances.read(to);
            self.balances.write(to, receiver_balance + 1.into());

            // Update token_id owner
            self.owners.write(token_id, to);

            // Set token uri
            self._set_token_uri(token_id, token_uri);

            // emit Transfer event
            self.emit(
                Transfer{ from: Zeroable::zero(), to: to, token_id: token_id }
            );
        }

    }


}