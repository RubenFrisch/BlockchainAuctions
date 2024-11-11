// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "OwnershipController.sol";
import "CancellableAuctionController.sol";
import "WhitelistAuctionController.sol";
import "EntryFeeController.sol";
import "CircuitBreakerEmergencyController.sol";
import "BlacklistAuctionController.sol";
import "AuctionERC721.sol";

/// @title Auction core implementation contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract facilitates the registration, configuration and management of all processes of decentralized parametric auctions
/// @dev This contract facilitates the registration, configuration and management of all processes of decentralized parametric auctions
contract AuctionsLogic is 
    OwnershipController, 
    CancellableAuctionController, 
    WhitelistAuctionController, 
    BlacklistAuctionController, 
    EntryFeeController, 
    CircuitBreakerEmergencyController
{

     // <<< STATE VARIABLES >>>
    /// @dev Indicates whether an auction exists (has been created) or not
    mapping(bytes32 => bool) private _auctionID;

    /// @dev Stores the bid amounts of participants of the respective auction
    mapping(bytes32 => mapping(address => uint256)) private _bidAmountsOfBidders;

    /// @dev Stores the highest bid amount of the respective auction
    mapping(bytes32 => uint256) private _auctionHighestBidAmount;

    /// @dev Stores the winner's address of the respective auction
    mapping(bytes32 => address) private _auctionWinner;

    /// @dev Stores the block number where the respective auction begins
    mapping(bytes32 => uint256) private _auctionStartBlock;

    /// @dev Stores the block number where the respective auction ends
    mapping(bytes32 => uint256) private _auctionEndBlock;

    /// @dev Stores the starting price of the respective auction
    mapping(bytes32 => uint256) private _startingPrice;

    /// @dev Stores the bid increment value of the respective auction
    mapping(bytes32 => uint256) private _bidIncrement;

    /// @dev Stores the reserve price of the respective auction
    mapping(bytes32 => uint256) private _reservePrice;

    /// @dev Indicates whether the owner has withdrawn the winning bid from the respective auction or not
    mapping(bytes32 => bool) private _ownerWithdrew;

    /// @dev Stores the snipe prevention mechanism's block interval value of the respective auction
    mapping(bytes32 => uint256) private _auctionSnipeInterval;

    /// @dev Stores the snipe prevention mechanism's block increment value of the respective auction
    mapping(bytes32 => uint256) private _auctionSnipeBlocks;

    /// @dev Stores the NFT contract's address of the respective auction
    mapping(bytes32 => AuctionERC721) private _nftContractAddress;

    /// @dev Stores the NFT token ID number of the respective auction
    mapping(bytes32 => uint256) private _nftTokenID;

    /// @dev Stores the IPFS metadata reference string of the respective auction
    mapping(bytes32 => string) private _ipfs;

     // <<< EVENTS >>>
    /// @dev Event for logging the registration of new auctions
    /// @notice Event for logging the registration of new auctions
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being initialized
    event NewAuctionRegistered(bytes32 indexed auctionID_);

    /// @dev Event for logging bids
    /// @notice Event for logging bids
    /// @param auctionID_ The 256 bit hash identifier of the auction that the bid was placed for
    /// @param bidder_ The address of the bidder
    /// @param newHighestBidAmount_ The amount of the bid in Wei (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    event BidPlaced(bytes32 indexed auctionID_, address bidder_, uint256 newHighestBidAmount_);

    /// @dev Event for logging bid withdrawals
    /// @notice Event for logging bid withdrawals
    /// @param auctionID_ The 256 bit hash identifier of the auction that the bid was withdrawn from
    /// @param entity_ The address which initiated the bid withdrawal
    /// @param withdrawAmount_ The amount of the withdrawal in Wei (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    event BidWithdrawn(bytes32 indexed auctionID_, address entity_, uint256 withdrawAmount_);

    /// @dev Event for logging snipe prevention mechanism triggers
    /// @notice Event for logging snipe prevention mechanism triggers
    /// @param auctionID_ The 256 bit hash identifier of the auction at which the snipe prevention mechanism was triggered
    /// @param bidder_ The address of the bidder who triggered the snipe prevention mechanism
    event SnipePreventionTriggered(bytes32 indexed auctionID_, address bidder_);

     // <<< MODIFIERS >>>
    /// @dev This modifier absorbs the associated function's body when the auction does exist, otherwise it reverts execution
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being evaluated
    modifier onlyIfAuctionExists(bytes32 auctionID_) {
        require(auctionExists(auctionID_), "Auction does not exist!");
        _;
    }

    /// @dev This modifier absorbs the associated function's body when the auction does not exist, otherwise it reverts execution
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being evaluated
    modifier onlyIfAuctionDoesNotExist(bytes32 auctionID_) {
        require(!auctionExists(auctionID_), "Auction already exists!");
        _;
    }

    /// @dev This modifier absorbs the associated function's body when the specified auction's starting block number is less or equal compared to the current block number in the context of the function call, otherwise it reverts execution
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being evaluated
    modifier onlyAfterStartBlock(bytes32 auctionID_) {
        require(auctionStartBlock(auctionID_) <= block.number, "Auction has not started!");
        _;
    }

    /// @dev This modifier absorbs the associated function's body when the specified auction's ending block number is greater or equal compared to the current block number in the context of the function call, otherwise it reverts execution
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being evaluated
    modifier onlyBeforeEndBlock(bytes32 auctionID_) {
        require(block.number <= auctionEndBlock(auctionID_), "Auction has ended!");
        _;
    }

    /// @dev This modifier absorbs the associated function's body when the specified auction's starting block is greater than the current block number in the context of the function call, otherwise it reverts execution
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being evaluated
    modifier onlyBeforeStartBlock(bytes32 auctionID_) {
        require(block.number < auctionStartBlock(auctionID_), "Auction is running!");
        _;
    }

     // <<< AUCTION REGISTRATION FUNCTIONALITY >>>
    /// @dev Registers and configures a new parametric auction
    /// @notice Registers and configures a new parametric auction
    /// @param auctionID_ The 256 bit hash identifier (pass with 0x prefix, hexadeciaml encoding, recommended hash function is SHA256 or Keccak256) of the auction
    /// @param auctionStartBlock_ The block number where the auction will start
    /// @param auctionEndBlock_ The block number where the auction will end
    /// @param startingPrice_ The starting price in Wei (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    /// @param bidIncrement_ The bid increment value in Wei (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    /// @param reservePrice_ The reserve price in Wei (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    /// @param auctionSnipeInterval_ The snipe prevention mechanism's activation interval value
    /// @param auctionSnipeBlocks_ The snipe prevention mechanism's auction duration expansion value
    /// @param nftContractAddress_ The address of the IERC-721 complient NFT smart contract
    /// @param nftTokenID_ The ID number of the NFT token that represents the item to be sold
    /// @param ipfs_ The IPFS auction metadata URL string
    /// @return Returns a true boolean literal if the auction registration was successful
    /// @custom:requirement-modifier Only the owner can register new auctions
    /// @custom:requirement-modifier New auctions cannot be registered while the system is paused by the emergency circuit breaker
    /// @custom:requirement-modifier The auction ID must be unique (auctions with the same ID must not exist)
    /// @custom:requirement-body The auction start block must be lower than the auction end block
    /// @custom:requirement-body The auction start block must be at least of the value of the current block number
    /// @custom:requirement-body The starting price must be greater or equal to 0
    /// @custom:requirement-body The bid increment value must be greater or equal to 0
    /// @custom:requirement-body The reserve price must be greater or equal to 0
    /// @custom:requirement-body The snipe prevention mechanism's activation interval value must be greater or equal to 0
    /// @custom:requirement-body The snipe prevention mechanism's activation interval value must be lower than the total duration of the auction
    /// @custom:requirement-body The snipe prevention mechanism's auction duration expansion value must be greater or equal to 0
    /// @custom:requirement-body The NFT contract address must be a smart contract
    /// @custom:requirement-body The NFT contract address must support the IERC721 interface
    /// @custom:requirement-body The NFT with the passed token ID must be owned by the auction smart contract
    function createNewAuction (
        bytes32 auctionID_,
        uint256 auctionStartBlock_,
        uint256 auctionEndBlock_,
        uint256 startingPrice_,
        uint256 bidIncrement_,
        uint256 reservePrice_,
        uint256 auctionSnipeInterval_,
        uint256 auctionSnipeBlocks_,
        address nftContractAddress_,
        uint256 nftTokenID_,
        string memory ipfs_
    ) 
        external 
        onlyOwner 
        onlyWhenNotPaused 
        onlyIfAuctionDoesNotExist(auctionID_) 
        returns (bool) 
    {
        require(auctionStartBlock_ < auctionEndBlock_);
        require(auctionStartBlock_ >= block.number);
        require(startingPrice_ >= 0);
        require(bidIncrement_ >= 0);
        require(reservePrice_ >= 0);
        require(auctionSnipeInterval_ >= 0);
        require(auctionSnipeInterval_ < (auctionEndBlock_ - auctionStartBlock_));
        require(auctionSnipeBlocks_ >= 0);
        require(isSmartContract(nftContractAddress_));
        require(AuctionERC721(nftContractAddress_).supportsInterface(type(IERC721).interfaceId));
        require(AuctionERC721(nftContractAddress_).ownerOf(nftTokenID_) == address(this));

        _auctionID[auctionID_] = true;
        _auctionStartBlock[auctionID_] = auctionStartBlock_;
        _auctionEndBlock[auctionID_] = auctionEndBlock_;
        _startingPrice[auctionID_] = startingPrice_;
        _bidIncrement[auctionID_] = bidIncrement_;
        _reservePrice[auctionID_] = reservePrice_;
        _auctionSnipeInterval[auctionID_] = auctionSnipeInterval_;
        _auctionSnipeBlocks[auctionID_] = auctionSnipeBlocks_;
        _nftContractAddress[auctionID_] = AuctionERC721(nftContractAddress_);
        _nftTokenID[auctionID_] = nftTokenID_;
        _ipfs[auctionID_] = ipfs_;

        emit NewAuctionRegistered(auctionID_);
        return true;
    }

     // <<< BID FUNCTIONALITY >>>
    /// @dev Places a bid on an auction
    /// @notice Places a bid on an auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a true boolean literal if the bid was successful
    /// @custom:requirement-modifier The owner cannot place bids
    /// @custom:requirement-modifier Bids cannot be placed while the system is paused by the emergency circuit breaker
    /// @custom:requirement-modifier Bids can only be placed for registered auctions
    /// @custom:requirement-modifier Bids cannot be placed on cancelled auctions
    /// @custom:requirement-modifier Bids can only be placed on auctions that have already started
    /// @custom:requirement-modifier Bids can only be placed on auctions that have not ended yet
    /// @custom:requirement-body The bid's value must be greater than 0
    /// @custom:requirement-body If there is an entry fee configured for the auction, it must be paid in order to participate in the bidding process
    /// @custom:requirement-body If it is a blacklist auction and the address is blacklisted, then the caller will not be able to participate in bidding
    /// @custom:requirement-body If it is a whitelist auction and the address is not whitelisted, then the caller will not be able to participate in bidding
    /// @custom:requirement-body The total bid of the participant must be greater or equal to the starting price of the auction
    /// @custom:requirement-body The total bid of the participant must be greater or equal to the highest bid + the bid increment
    function bid(bytes32 auctionID_) 
        external 
        payable 
        onlyWhenNotOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        whenNotCancelled(auctionID_) 
        onlyAfterStartBlock(auctionID_) 
        onlyBeforeEndBlock(auctionID_) 
        returns (bool) 
    {
        require(msg.value > 0);

        if(getEntryFee(auctionID_) != 0) {
            require(hasPaidEntryFee(auctionID_, msg.sender), "Address has not paid entry fee!");
        }

        if(isBlacklistAuction(auctionID_)) {
            require(!isBlacklistedParticipant(auctionID_, msg.sender), "Address is blacklisted!");
        }

        if(closedAuction(auctionID_)) {
            require(isWhitelisted(auctionID_, msg.sender), "Address not whitelisted!");
        }

        uint256 totalBid = msg.value + getBidAmountOfBidder(auctionID_, msg.sender);

        require(totalBid >= startingPrice(auctionID_), "Bid lower than staring price!");

        if(auctionHighestBidAmount(auctionID_) != 0) {
            require(totalBid >= (auctionHighestBidAmount(auctionID_) + bidIncrement(auctionID_)), "Bid too low!");
        }

        _bidAmountsOfBidders[auctionID_][msg.sender] = totalBid;
        _auctionHighestBidAmount[auctionID_] = totalBid;

        if(msg.sender != auctionWinner(auctionID_)) {
            _auctionWinner[auctionID_] = msg.sender;
        }

        if(auctionSnipeInterval(auctionID_) > 0 && auctionSnipeBlocks(auctionID_) > 0) {
            if((auctionEndBlock(auctionID_) - block.number) <= auctionSnipeInterval(auctionID_)) { 
                _auctionEndBlock[auctionID_] += auctionSnipeBlocks(auctionID_);
                emit SnipePreventionTriggered(auctionID_, msg.sender);
            }
        }

        emit BidPlaced(auctionID_, msg.sender, totalBid);
        return true;
    }

     // <<< BID WITHDRAWAL FUNCTIONALITY >>>
    /// @dev Withdraws a bid from an aucttion
    /// @notice Withdraws a bid from an aucttion
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a true boolean literal if the bid withdrawal was successful
    /// @custom:requirement-modifier Bid withdrawal requests can only be submitted to registered auctions
    /// @custom:requirement-body Bid withdrawals can only be submitted when the auction is either cancelled or has ended naturally
    /// @custom:requirement-body The owner can only withdraw the winning bid once from an auction
    /// @custom:requirement-body The winner of the auction can only withdraw the prize NFT once
    function withdrawBid(bytes32 auctionID_) 
        external 
        onlyIfAuctionExists(auctionID_) 
        returns (bool) 
    {
        require(isCancelled(auctionID_) || (block.number > auctionEndBlock(auctionID_)), "Auction is running!");

        if(isCancelled(auctionID_) || (auctionHighestBidAmount(auctionID_) < reservePrice(auctionID_))) {
            uint256 withdrawBidAmount = getBidAmountOfBidder(auctionID_, msg.sender);
            _bidAmountsOfBidders[auctionID_][msg.sender] -= withdrawBidAmount;
            if(payable(msg.sender).send(withdrawBidAmount)) {
                emit BidWithdrawn(auctionID_, msg.sender, withdrawBidAmount);
                return true;
            } else {
                revert();
            }
        } else if(msg.sender == owner()) {
            require(!ownerWithdrew(auctionID_));
            uint256 withdrawBidAmount = auctionHighestBidAmount(auctionID_);
            _bidAmountsOfBidders[auctionID_][auctionWinner(auctionID_)] -= withdrawBidAmount;
            _ownerWithdrew[auctionID_] = true;
            if(payable(msg.sender).send(withdrawBidAmount)) {
                emit BidWithdrawn(auctionID_, msg.sender, withdrawBidAmount);
                return true;
            } else {
                revert();
            }
        } else if(msg.sender == auctionWinner(auctionID_)) {
            require(nftContractAddress(auctionID_).ownerOf(nftTokenID(auctionID_)) == address(this));
            nftContractAddress(auctionID_).safeTransferFrom(address(this), auctionWinner(auctionID_), nftTokenID(auctionID_));
            return true;
        } else {
            uint256 withdrawBidAmount = getBidAmountOfBidder(auctionID_, msg.sender);
            _bidAmountsOfBidders[auctionID_][msg.sender] -= withdrawBidAmount;
            if(payable(msg.sender).send(withdrawBidAmount)) {
                emit BidWithdrawn(auctionID_, msg.sender, withdrawBidAmount);
                return true;
            } else {
                revert();
            }
        }
    }

     // <<< READ FUNCTIONS >>>
    /// @dev Retrieves the boolean value associated with the passed auction ID
    /// @notice Retrieves the boolean value associated with the passed auction ID
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a boolean literal that indicates whether the auction is registered or not
    function auctionExists(bytes32 auctionID_) public view returns (bool) {
        return _auctionID[auctionID_];
    }

    /// @dev Retrieves the amount of the current highest bid in the specific auction
    /// @notice Retrieves the amount of the current highest bid in the specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the amount of the current highest bid in WEI (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    function auctionHighestBidAmount(bytes32 auctionID_) public view returns (uint256) {
        return _auctionHighestBidAmount[auctionID_];
    }

    /// @dev Retrieves the current auction winnner's address from the specific auction
    /// @notice Retrieves the current auction winnner's address from the specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the address of the current auction winner
    function auctionWinner(bytes32 auctionID_) public view returns (address) {
        return _auctionWinner[auctionID_];
    }

    /// @dev Retrieves the start block number where the specific auction begins
    /// @notice Retrieves the starting block number of the specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the start block number where the auction starts
    function auctionStartBlock(bytes32 auctionID_) public view returns (uint256) {
        return _auctionStartBlock[auctionID_];
    }

    /// @dev Retrieves the end block number where the specific auction ends
    /// @notice Retrieves the end block number where the specific auction ends
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the end block number where the auction ends
    function auctionEndBlock(bytes32 auctionID_) public view returns (uint256) {
        return _auctionEndBlock[auctionID_];
    }

    /// @dev Retrieves the bid amount of a bidder from a specific auction
    /// @notice Retrieves the bid amount of a bidder from a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param bidder_ The address of the bidder
    /// @return Returns the bid amount of a bidder from a specific auction
    function getBidAmountOfBidder(bytes32 auctionID_, address bidder_) public view returns (uint256) {
        return _bidAmountsOfBidders[auctionID_][bidder_];
    }

    /// @dev Retrieves the starting price of a specific auction
    /// @notice Retrieves the starting price of a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the starting price of the auction in WEI (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    function startingPrice(bytes32 auctionID_) public view returns (uint256) {
        return _startingPrice[auctionID_];
    }

    /// @dev Retrieves the bid increment value of a specific auction
    /// @notice Retrieves the bid increment value of a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the bid increment value of the auction in WEI (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    function bidIncrement(bytes32 auctionID_) public view returns (uint256) {
        return _bidIncrement[auctionID_];
    }

    /// @dev Retrieves the reserve price of a specific auction
    /// @notice Retrieves the reserve price of a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the reserve price of the auction in WEI (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    function reservePrice(bytes32 auctionID_) public view returns (uint256) {
        return _reservePrice[auctionID_];
    }

    /// @dev Retrieves the ETH balance of the contract itself (funds from committed bids and collected entry fees)
    /// @notice Retrieves the ETH balance of the contract itself (funds from committed bids and collected entry fees)
    /// @return Returns the ETH balance of the smart contract in WEI (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    function contractETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @dev Retrieves whether the owner has withdrawn from the specific auction or not
    /// @notice Retrieves whether the owner has withdrawn from the specific auction or not
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a boolean literal that indicates whether the owner has withdrawn from the specified auction or not
    function ownerWithdrew(bytes32 auctionID_) public view returns (bool) {
        return _ownerWithdrew[auctionID_];
    }

    /// @dev Retrieves the auction snipe interval of a specific auction
    /// @notice Retrieves the auction snipe interval of a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the auction snipe interval of the auction
    function auctionSnipeInterval(bytes32 auctionID_) public view returns (uint256) {
        return _auctionSnipeInterval[auctionID_];
    }

    /// @dev Retrieves the auction snipe block count of a specific auction
    /// @notice Retrieves the auction snipe block count of a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the auction snipe block count of the auction
    function auctionSnipeBlocks(bytes32 auctionID_) public view returns (uint256) {
        return _auctionSnipeBlocks[auctionID_];
    }

    /// @dev Retrieves the NFT contract address associated with a specific auction
    /// @notice Retrieves the NFT contract address associated with a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the NFT contract address of the auction
    function nftContractAddress(bytes32 auctionID_) public view returns (AuctionERC721) {
        return _nftContractAddress[auctionID_];
    }

    /// @dev Retrieves the NFT token ID of a specific auction
    /// @notice Retrieves the NFT token ID of a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the NFT token ID of the auction
    function nftTokenID(bytes32 auctionID_) public view returns (uint256) {
        return _nftTokenID[auctionID_];
    }

    /// @dev Retrieves the IPFS of a specific auction
    /// @notice Retrieves the IPFS of a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the IPFS string of the auction
    function getIPFS(bytes32 auctionID_) external view returns (string memory) {
        return _ipfs[auctionID_];
    }

     // <<< ADDRESS BYTECODE SIZE CHECKER >>>
    /// @dev Checks whether the passed address is a smart contract or not by evaluating the size of the code stored at the specified address
    /// @dev Inline assembly is used for higher gas efficiency, extcodesize is an EVM opcode that checks and returns the bytecode size of the address, in case of an EOA, the size will be 0
    /// @notice Checks whether the passed address is a smart contract or not by evaluating the size of the code stored at the specified address
    /// @param address_ The address to be checked whether if it is an EOA (externally owned account) or a smart contract
    /// @return Returns a boolean literal indicating whether the passed address is a smart contract or not
    function isSmartContract(address address_) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(address_) 
        }
        return (size > 0);
    }

     // <<< CANCELLABLE AUCTION FUNCTIONALITY >>>
    /// @dev Configures an auction as cancellable
    /// @notice Configures an auction as cancellable
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a true boolean literal if the configuration of an auction as cancellable was successful
    /// @custom:requirement-modifier Only the owner can call this function
    /// @custom:requirement-modifier This function will only execute if the contracts are not paused by the emergency circuit breaker
    /// @custom:requirement-modifier Only an existing (registered) auction can be configured as a cancellable auction
    /// @custom:requirement-modifier An auction can only be configured when it hasn't started yet
    /// @custom:requirement-body Only a non-cancellable auction can be configured as cancellable (prevents additional wasted computation and gas)
    function configureAsCancellableAuction(bytes32 auctionID_) 
        external 
        override 
        onlyOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(!isCancellable(auctionID_));
        super._configureAsCancellableAuction(auctionID_);
        return true;
    }

    /// @dev Cancels a cancellable auction and burns the NFT
    /// @notice Cancels a cancellable auction and burns the NFT
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a true boolean literal if the auction was cancelled successfully
    /// @custom:requirement-modifier Only the owner can call this function
    /// @custom:requirement-modifier This function will only execute if the contracts are not paused by the emergency circuit breaker
    /// @custom:requirement-modifier Only an existing (registered) auction can be cancelled
    /// @custom:requirement-modifier A cancellable auction can only be cancelled once the auction has started
    /// @custom:requirement-modifier A cancellable auction can only be cancelled before it ends
    /// @custom:requirement-body Only a cancellable auction can be cancalled (needs to be configured as cancellable before the auction starts)
    function cancelAuction(bytes32 auctionID_) 
        external 
        override 
        onlyOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        onlyAfterStartBlock(auctionID_) 
        onlyBeforeEndBlock(auctionID_)  
        returns (bool) 
    {
        require(isCancellable(auctionID_));
        super._cancelAuction(auctionID_);
        nftContractAddress(auctionID_).burn(nftTokenID(auctionID_));
        return true;
    }

     // <<< ERC-721 RECEIVER INTERFACE >>>
    /// @dev Ensures that the auction contract receiving the ERC-721 token is capable of handling ERC-721 NFT tokens (safeTranfer eligibility to prevent accidental NFT token loss)
    /// @dev Prevents accidental transfers to contracts that don't know how to process them and are not IERC-721 complient
    /// @dev When the ERC-721 token is transferred to the auction contracct with the safeTransferFrom method, it needs to implement the onERC721Received function to accept the token
    /// @dev Computes the 4 byte Keccak-256 hash of the function signature (name and parameter list data types) to generate a selector hash, then truncates it to the first 4 bytes to form a selector
    /// @dev The function will always return 0x150b7a02
    /// @dev The safeTransferFrom function from the ERC-721 contract will require the recipient (to parameter) to implement the onERC721Received function
    /// @dev For a successful safeTransferFrom execution, the called onERC721Received return value must be equal to the hardcoded selector hash in the ERC-721 contract (IERC721Receiver.onERC721Received.selector)
    /// @notice Ensures that the auction contract receiving the ERC-721 token is capable of handling ERC-721 NFT tokens
    /// @custom:param-unnamed _operator The address which called `safeTransferFrom` function
    /// @custom:param-unnamed _from The address which previously owned the token
    /// @custom:param-unnamed _tokenId The NFT identifier which is being transferred
    /// @custom:param-unnamed _data Additional data with no specified format
    /// @return Returns the function selector (first 4 bytes of the Keccak-256 hash of the function signature (name + parameter list data types))
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

     // <<< WHITELIST FUNCTIONALITY >>>
    /// @dev Configure an auction as closed (whitelisted)
    /// @notice Configure an auction as closed (whitelisted)
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns true if the auction has been configured successfully as a closed (whitelisted) auction
    /// @custom:requirement-modifier Only the owner can call this function
    /// @custom:requirement-modifier This function will only execute if the contracts are not paused by the emergency circuit breaker
    /// @custom:requirement-modifier Only an existing (registered) auction can be configured as a whitelist auction
    /// @custom:requirement-modifier An auction can only be configured when it hasn't started yet
    /// @custom:requirement-body Only an auction that is not yet a whitelist auction can be configured as one (prevents additional wasted computation and gas)
    function configureAsClosedAuction(bytes32 auctionID_) 
        external 
        override 
        onlyOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(!closedAuction(auctionID_));
        super._configureAsClosedAuction(auctionID_);
        return true;
    }

    /// @dev Whitelists an array of addresses to be eligible for participation in a closed (whitelisted) auction
    /// @notice Whitelists a group of users to be eligible for participation in a closed (whitelisted) auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participants_ The array of addresses to be whitelisted
    /// @return Returns true if the whitelisting of the passed addresses was successful
    /// @custom:requirement-modifier Only the owner can call this function
    /// @custom:requirement-modifier This function will only execute if the contracts are not paused by the emergency circuit breaker
    /// @custom:requirement-modifier Only an existing (registered) auction can have whitelisted participants
    /// @custom:requirement-modifier Participants can only be whitelisted for a whitelist auction before it starts running
    /// @custom:requirement-body Participants can only be whitelisted if the auction is configured as a whitelist auction
    function whitelistParticipants(bytes32 auctionID_, address[] memory participants_) 
        external 
        override 
        onlyOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(closedAuction(auctionID_));
        super._whitelistParticipants(auctionID_, participants_);
        return true;
    }

     // <<< ENTRY FEE FUNCTIONALITY >>>
    /// @dev Sets the entry fee for a specific auction
    /// @notice Sets the entry fee for a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param entryFee_ The amount of the entry fee in WEI (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    /// @return Returns true boolean literal if the entry fee has been successfully set
    /// @custom:requirement-modifier Only the owner can call this function
    /// @custom:requirement-modifier This function will only execute if the contracts are not paused by the emergency circuit breaker
    /// @custom:requirement-modifier Only an existing (registered) auction can have an entry fee
    /// @custom:requirement-modifier Entry fee can only be set before the auction begins
    /// @custom:requirement-body The passed entry fee argument must be greater than 0
    function setEntryFee(bytes32 auctionID_, uint256 entryFee_) 
        external 
        override 
        onlyOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(entryFee_ > 0);
        super._setEntryFee(auctionID_, entryFee_);
        return true;
    }

    /// @dev Manages the internal accounting of entry fee payments
    /// @notice Manages the internal accounting of entry fee payments
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns true boolean literal if the entry fee has been successfully paid
    /// @custom:requirement-modifier Only non-owner accounts can pay entry fee
    /// @custom:requirement-modifier This function will only execute if the contracts are not paused by the emergency circuit breaker
    /// @custom:requirement-modifier Only an existing (registered) auction can receive entry fee payments
    /// @custom:requirement-modifier Entry fee can only be paid before the auction begins
    /// @custom:requirement-body The entry fee configured for the specified auction must be greater than 0 (meaning that it is an entry fee gated auction)
    /// @custom:requirement-body The value of the function call must be equal to the configured entry fee in order to accept an entry fee payment
    /// @custom:requirement-body The entry fee can only be paid once by the same account at the specified auction
    function payEntryFee(bytes32 auctionID_) 
        external 
        override 
        payable 
        onlyWhenNotOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(getEntryFee(auctionID_) > 0);
        require(msg.value == getEntryFee(auctionID_));
        require(!hasPaidEntryFee(auctionID_, msg.sender));

        super._payEntryFee(auctionID_);
        return true;
    }

    /// @dev Manages the internal accounting of entry fee withdrawals
    /// @notice Manages the internal accounting of entry fee withdrawals
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns true if the entry fee withdrawal was successful
    /// @custom:requirement-modifier Only non-owner accounts can withdraw the entry fee
    /// @custom:requirement-modifier Only from existing auctions can the entry fee be withdrawn
    /// @custom:requirement-body The entry fee can only be withdrawn when the auction is either cancelled or the duration elapsed naturally
    /// @custom:requirement-body Entry fee can only be withdrawn from an auction that has an entry fee configured
    /// @custom:requirement-body Only participants who paid the entry fee can withdraw it
    /// @custom:requirement-body Entry fee can only be withdrawn once from the specific auction by an account
    function withdrawEntryFee(bytes32 auctionID_) 
        external 
        override 
        onlyWhenNotOwner 
        onlyIfAuctionExists(auctionID_) 
        returns (bool) 
    {
        require(isCancelled(auctionID_) || (block.number > auctionEndBlock(auctionID_)));
        require(getEntryFee(auctionID_) > 0);
        require(hasPaidEntryFee(auctionID_, msg.sender));
        require(!hasWithdrawnEntryFee(auctionID_, msg.sender));

        if(payable(msg.sender).send(getEntryFee(auctionID_))) {
            super._withdrawEntryFee(auctionID_);
            return true;
        } else {
            revert();
        }
    }

     // <<< EMERGENCY CIRCUIT BREAKER FUNCTIONALITY >>>
    /// @dev Turns emergency pause on
    /// @notice Turns emergency pause on
    /// @return Returns true boolean if the emergency pause has been enabled successfully
    /// @custom:requirement-modifier Only the owner can turn on the circuit breaker emergency
    /// @custom:requirement-modifier Emergency can only be enabled if if was previously disabled
    function turnEmergencyPauseOn() 
        external 
        override 
        onlyOwner 
        onlyWhenNotPaused 
        returns (bool) 
    {
        super._turnEmergencyPauseOn();
        return true;
    }

    /// @dev Turns emergency pause off
    /// @notice Turns emergency pause off
    /// @return Returns true boolean if the emergency pause has been disabled successfully
    /// @custom:requirement-modifier Only the owner can turn off the circuit breaker emergency
    /// @custom:requirement-modifier Emergency can only be disabled if if was previously enabled
    function turnEmergencyPauseOff() 
        external 
        override 
        onlyOwner 
        onlyWhenPaused 
        returns (bool) 
    {
        super._turnEmergencyPauseOff();
        return true;
    }

     // <<< BLACKLIST FUNCTIONALITY >>>
    /// @dev Configures a blacklist auction
    /// @notice Configures a blacklist auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns true boolean literal if the blacklist auction configuration was successful
    /// @custom:requirement-modifier Only the owner can configure an auction as a blacklist auction
    /// @custom:requirement-modifier Blacklist auction configuration is only possible when the contracts are not paused by the emergency circuit breaker
    /// @custom:requirement-modifier Only a registered (existing) auction can be configured as a blacklist auction
    /// @custom:requirement-modifier An auction can only be configured as a blacklist auction before it begins
    /// @custom:requirement-body Only a non-blacklist auction can be configured as a blacklist auction (save gas)
    function configureAsBlacklistedAuction(bytes32 auctionID_) 
        external 
        override 
        onlyOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(!isBlacklistAuction(auctionID_));
        super._configureAsBlacklistedAuction(auctionID_);
        return true;
    }

    /// @dev Blacklists an array of addresses (participants) at the specified blacklist auction
    /// @notice Blacklists an array of addresses (participants) at the specified blacklist auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participants_ The addresses (participants) to be blacklisted at the specified blacklist auction
    /// @return Returns true boolean literal if the addresses (participants) were successfully blacklisted at the specified auction
    /// @custom:requirement-modifier Only the owner can blacklist addresses
    /// @custom:requirement-modifier Blacklisting addresses is only possible when the contracts are not paused by the emergency circuit breaker
    /// @custom:requirement-modifier Only at a registered (existing) auction can addresses be blacklisted
    /// @custom:requirement-modifier Blacklisting is only possible before the auction begins
    /// @custom:requirement-body Only at an auction that was configured as a blacklist auction can addresses be blacklisted
    function blacklistParticipants(bytes32 auctionID_, address[] memory participants_) 
        external 
        override 
        onlyOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(isBlacklistAuction(auctionID_));
        super._blacklistParticipants(auctionID_, participants_);
        return true;
    }
}