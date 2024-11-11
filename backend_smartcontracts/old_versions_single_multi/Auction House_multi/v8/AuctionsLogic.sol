// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "OwnershipControl.sol";
import "Cancellable.sol";
import "WhitelistedAuction.sol";
import "IPFSManager.sol";
import "AuctionERC721.sol";
import "EntryFeeManager.sol";

/// @title Auction implementation (logic) contract
/// @author Ruben Frisch (ÓE-NIK, Business Informatics MSc)
/// @notice You can use this contract to facilitate decentralized, feature-rich, parametric English type auctions
/// @dev Implementation contract for parametric English type auctions
contract AuctionsLogic is OwnershipControl, Cancellable, WhitelistedAuction, IPFSManager, EntryFeeManager {

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

    // <<< EVENTS >>>
    /// @dev Event for logging the creation of new auctions
    /// @notice Event for logging the creation of new auctions
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being initialized
    /// @param owner_ The address of the owner who initiated the 'createNewAuction' function call
    event NewAuctionCreated(bytes32 indexed auctionID_, address owner_);

    /// @dev Event for logging placed bids
    /// @notice Event for logging placed bids
    /// @param auctionID_ The 256 bit hash identifier of the auction that the bid belongs to
    /// @param bidder_ The address of the bidder who called the 'bid' function
    /// @param newHighestBidAmount_ The amount of the bid in Wei (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    event BidPlaced(bytes32 indexed auctionID_, address bidder_, uint256 newHighestBidAmount_);

    /// @dev Event for logging withdrawals of bids
    /// @notice Event for logging withdrawals of bids
    /// @param auctionID_ The 256 bit hash identifier of the auction that the bid is being withdrawn from
    /// @param entity_ The address which initiated the withdrawal by calling the 'withdrawBid' function
    /// @param withdrawAmount_ The amount of the withdrawal in Wei (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    event BidWithdrawn(bytes32 indexed auctionID_, address entity_, uint256 withdrawAmount_);

    /// @dev Event for logging snipe prevention mechanism triggers
    /// @notice Event for logging snipe prevention mechanism triggers
    /// @param auctionID_ The 256 bit hash identifier of the auction where the snipe prevention mechanism has been triggered during a bid that matched the snipe configuration
    /// @param bidder_ The address of the bidder for the bid that triggered the snipe prevention mechanism
    /// @param blockNumber_ The specific number of the block in the blockchain where the snipe bid occured
    event SnipePreventionTriggered(bytes32 indexed auctionID_, address bidder_, uint256 blockNumber_);

    // <<< MODIFIERS >>>
    /// @dev Checks whether the auction exists in the storage of the contract
    /// @dev The modifier absorbs the function body when the auction does exist, otherwise it reverts execution
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being evaluated
    modifier onlyIfAuctionExists(bytes32 auctionID_) {
        require(auctionExists(auctionID_), "Auction does not exist!");
        _;
    }

    /// @dev This modifier absorbs the associated function body when the auction does not exist, otherwise it reverts execution
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being evaluated
    modifier onlyIfAuctionDoesNotExist(bytes32 auctionID_) {
        require(!auctionExists(auctionID_), "Auction already exists!");
        _;
    }

    /// @dev This modifier absorbs the associated function body when the specified auction's starting block number is less or equal compared to the current block number in the context of the function call
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being evaluated
    modifier onlyAfterStartBlock(bytes32 auctionID_) {
        require(auctionStartBlock(auctionID_) <= block.number, "Auction has not started!");
        _;
    }

    /// @dev This modifier absorbs the associated function body when the specified auction's ending block number is greater or equal compared to the current block number in the context of the function call
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being evaluated
    modifier onlyBeforeEndBlock(bytes32 auctionID_) {
        require(block.number <= auctionEndBlock(auctionID_), "Auction has ended!");
        _;
    }

    /// @dev This modifier absorbs the associated function body when the specified auction's starting block is greater than the current block number in the context of the function call
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being evaluated
    modifier onlyBeforeStartBlock(bytes32 auctionID_) {
        require(block.number < auctionStartBlock(auctionID_), "Auction is running!");
        _;
    }

    // <<< AUCTION BUILDER FUNCTION >>>
    /// @dev Core function that enables the creation of new parametric auctions, only the owner can create new auctions
    /// @notice Core function that enables the creation of new parametric auctions
    /// @param auctionID_ The 256 bit hash identifier (pass with 0x prefix, hexadeciaml encoding, recommended hash function is SHA256 or Keccak256) of the auction to be created, function reverts if there is an auction already created with the same auctionID_
    /// @param auctionStartBlock_ The block number where the auction will be considered commenced, the function reverts if the auctionStartBlock_ argument is not less than auctionEndBlock_ argument or when auctionStartBlock_ is not at least the height of the current block
    /// @param auctionEndBlock_ The block number where the auction will be considered concluded, the function reverts if the auctionEndBlock_ argument is not greater than the auctionStartBlock_ argument
    /// @param startingPrice_ The starting price in Wei of the good or service being sold, the function reverts if startingPrice_ is not at least 0
    /// @param bidIncrement_ The amount of Wei that the next bid must be higher than the previous highest bid amount in order to be accepted as the winning bid (except for the first bid), the function reverts if bidIncrement_ is not at least 0
    /// @param reservePrice_ The minimum amount of Wei that the highest bid must reach for the good or service to be sold to the winner (also called reservation price), the function reverts if reservePrice_ is not at least 0
    /// @param auctionSnipeInterval_ The interval where the snipe prevention mechanism is triggered during a successful bid, precisely when: (auction end block - current block number) <= auction snipe interval, the function reverts if auctionSnipeInterval_ is not at least 0 or when the snipe interval is greater or equal to the whole auction duration
    /// @param auctionSnipeBlocks_ The number of additional blocks to be added to the ending block number in case of a bid that triggers the snipe prevention mechansim, extending the auction's duration, the function reverts if the auctionSnipeBlocks_ is not at least 0
    /// @param nftContractAddress_ The address of the IERC-721 complient NFT smart contract that the implementation auction contract will interact with to manage the ownership of the NFT that represents the good or service, the function reverts if nftContractAddress_ does not belong to a smart contract account or when nftContractAddress_ does not support the IERC721 interface
    /// @param nftTokenID_ The ID of the NFT token that represents the good or service to be sold in the specific auction, the function reverts if the owner of the NFT token with the specified nftTokenID_ is not the auction implementation contract itself
    /// @return Boolean literal that indicates whether the creation of the new auction was successful or not
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
        uint256 nftTokenID_
    ) 
        external 
        onlyOwner 
        onlyIfAuctionDoesNotExist(auctionID_) 
        returns (bool) 
    {
        require(auctionStartBlock_ < auctionEndBlock_, "Invalid duration!");
        require(auctionStartBlock_ >= block.number, "Invalid start block!");
        require(startingPrice_ >= 0, "Invalid starting price!");
        require(bidIncrement_ >= 0, "Invalid bid increment!");
        require(reservePrice_ >= 0, "Invalid reserve price!");
        require(auctionSnipeInterval_ >= 0, "Invalid snipe interval!");
        require(auctionSnipeInterval_ < (auctionEndBlock_ - auctionStartBlock_),"Invalid snipe interval!");
        require(auctionSnipeBlocks_ >= 0, "Invalid snipe block count!");
        require(isSmartContract(nftContractAddress_), "Not a contract!");
        require(AuctionERC721(nftContractAddress_).supportsInterface(type(IERC721).interfaceId), "Not IERC721 complient!");
        require(AuctionERC721(nftContractAddress_).ownerOf(nftTokenID_) == address(this),"NFT must be transferred to the auction contract!");

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

        emit NewAuctionCreated(auctionID_, msg.sender);
        return true;
    }

    /// <<< BID FUNCTION >>>
    /// @dev Core function that enables bidding on ongoing auctions
    function bid(bytes32 auctionID_) 
        external 
        payable 
        onlyWhenNotOwner 
        onlyIfAuctionExists(auctionID_) 
        whenNotCancelled(auctionID_) 
        onlyAfterStartBlock(auctionID_) 
        onlyBeforeEndBlock(auctionID_) 
        returns (bool) 
    {
        require(msg.value > 0, "Bid must be > 0!");

        if(getEntryFee(auctionID_) != 0) {
            require(hasPaidEntryFee(auctionID_, msg.sender), "Address has not paid entry fee!");
        }

        if(closedAuction(auctionID_)) {
            require(isWhitelisted(auctionID_, msg.sender), "Address is not whitelisted!");
        }

        uint256 totalBid = msg.value + getBidAmountOfBidder(auctionID_, msg.sender);

        require(totalBid >= startingPrice(auctionID_), "Bid is lower than the staring price!");

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
                emit SnipePreventionTriggered(auctionID_, msg.sender, block.number);
            }
        }

        emit BidPlaced(auctionID_, msg.sender, totalBid);
        return true;
    }

    /**
     * @dev This function allows a user to attempt the withdrawal of the placed bid.
     */
    function withdrawBid(bytes32 auctionID_) 
        external 
        onlyIfAuctionExists(auctionID_) 
        returns (bool) 
    {
        require(isCancelled(auctionID_) || (block.number > auctionEndBlock(auctionID_)), "Cannot withdraw bids while the auction is running!");

        if(isCancelled(auctionID_) || (auctionHighestBidAmount(auctionID_) < reservePrice(auctionID_))) {
            uint256 withdrawBidAmount = getBidAmountOfBidder(auctionID_, msg.sender);
            _bidAmountsOfBidders[auctionID_][msg.sender] -= withdrawBidAmount;
            if(payable(msg.sender).send(withdrawBidAmount)) {
                emit BidWithdrawn(auctionID_, msg.sender, withdrawBidAmount);
                return true;
            } else {
                revert("Withdraw failed!");
            }
        } else if(msg.sender == owner()) {
            require(!ownerWithdrew(auctionID_), "Owner has already withdrawn!");
            uint256 withdrawBidAmount = auctionHighestBidAmount(auctionID_);
            _bidAmountsOfBidders[auctionID_][auctionWinner(auctionID_)] -= withdrawBidAmount;
            _ownerWithdrew[auctionID_] = true;
            if(payable(msg.sender).send(withdrawBidAmount)) {
                emit BidWithdrawn(auctionID_, msg.sender, withdrawBidAmount);
                return true;
            } else {
                revert("Withdraw failed!");
            }
        } else if(msg.sender == auctionWinner(auctionID_)) {
            require(nftContractAddress(auctionID_).ownerOf(nftTokenID(auctionID_)) == address(this), "NFT has been already withdrawn!");
            nftContractAddress(auctionID_).safeTransferFrom(address(this), auctionWinner(auctionID_), nftTokenID(auctionID_));
            return true;
        } else {
            uint256 withdrawBidAmount = getBidAmountOfBidder(auctionID_, msg.sender);
            _bidAmountsOfBidders[auctionID_][msg.sender] -= withdrawBidAmount;
            if(payable(msg.sender).send(withdrawBidAmount)) {
                emit BidWithdrawn(auctionID_, msg.sender, withdrawBidAmount);
                return true;
            } else {
                revert("Withdraw failed!");
            }
        }
    }




    // <<<< Read functions >>>>
    function auctionExists(bytes32 auctionID_) public view returns (bool) {
        return _auctionID[auctionID_];
    }

    function auctionHighestBidAmount(bytes32 auctionID_) public view returns (uint256) {
        return _auctionHighestBidAmount[auctionID_];
    }

    function auctionWinner(bytes32 auctionID_) public view returns (address) {
        return _auctionWinner[auctionID_];
    }

    function auctionStartBlock(bytes32 auctionID_) public view returns (uint256) {
        return _auctionStartBlock[auctionID_];
    }

    function auctionEndBlock(bytes32 auctionID_) public view returns (uint256) {
        return _auctionEndBlock[auctionID_];
    }

    function getBidAmountOfBidder(bytes32 auctionID_, address bidder_) public view returns (uint256) {
        return _bidAmountsOfBidders[auctionID_][bidder_];
    }

    function startingPrice(bytes32 auctionID_) public view returns (uint256) {
        return _startingPrice[auctionID_];
    }

    function bidIncrement(bytes32 auctionID_) public view returns (uint256) {
        return _bidIncrement[auctionID_];
    }

    function reservePrice(bytes32 auctionID_) public view returns (uint256) {
        return _reservePrice[auctionID_];
    }

    function contractETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function ownerWithdrew(bytes32 auctionID_) public view returns (bool) {
        return _ownerWithdrew[auctionID_];
    }

    function auctionSnipeInterval(bytes32 auctionID_) public view returns (uint256) {
        return _auctionSnipeInterval[auctionID_];
    }

    function auctionSnipeBlocks(bytes32 auctionID_) public view returns (uint256) {
        return _auctionSnipeBlocks[auctionID_];
    }

    function nftContractAddress(bytes32 auctionID_) public view returns (AuctionERC721) {
        return _nftContractAddress[auctionID_];
    }

    function nftTokenID(bytes32 auctionID_) public view returns (uint256) {
        return _nftTokenID[auctionID_];
    }






    // <<<< Cancellation functionality >>>>

    function configureAsCancellableAuction(bytes32 auctionID_) 
        external 
        override 
        onlyOwner 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(!isCancellable(auctionID_), "Auction is already cancellable!");
        super._configureAsCancellableAuction(auctionID_);
        return true;
    }

    function cancelAuction(bytes32 auctionID_) 
        external 
        override 
        onlyOwner 
        onlyIfAuctionExists(auctionID_) 
        onlyAfterStartBlock(auctionID_) 
        onlyBeforeEndBlock(auctionID_) 
        returns (bool) 
    {
        require(isCancellable(auctionID_), "Auction is not cancellable!");
        super._cancelAuction(auctionID_);
        nftContractAddress(auctionID_).burn(nftTokenID(auctionID_));
        return true;
    }





    // <<<< ERC721 complience checker >>>>
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    // <<<< Smart contract address checker >>>>
    function isSmartContract(address address_) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(address_)
        }
        return (size > 0);
    }

    // <<<< Whitelisting functionality >>>>

    function configureAsClosedAuction(bytes32 auctionID_) 
        external 
        override 
        onlyOwner 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(!closedAuction(auctionID_), "This auction is already set to closed!");
        super._configureAsClosedAuction(auctionID_);
        return true;
    }

    function whitelistParticipants(bytes32 auctionID_, address[] memory participants_) 
        external 
        override 
        onlyOwner 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(closedAuction(auctionID_), "Not configured as a closed auction!");
        super._whitelistParticipants(auctionID_, participants_);
        return true;
    }

    // <<<< IPFS functionality >>>>
    function setIPFS(bytes32 auctionID_, string memory ipfs_) 
        external 
        override 
        onlyOwner 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        super._setIPFS(auctionID_, ipfs_);
        return true;
    }









    // <<<< Entry fee functionality >>>>
    function getEntryFee(bytes32 auctionID_) public view returns (uint256) {
        return _entryfee[auctionID_];
    }

    function setEntryFee(bytes32 auctionID_, uint256 entryFee_) 
        external 
        onlyOwner 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(entryFee_ > 0, "Entry fee must be greater than 0!");
        _entryfee[auctionID_] = entryFee_;
        return true;
    }

    function hasPaidEntryFee(bytes32 auctionID_, address participant_) public view returns (bool) {
        return _entryFeesPaid[auctionID_][participant_];
    }

    function hasWithdrawnEntryFee(bytes32 auctionID_, address participant_) public view returns (bool) {
        return _entryFeesWithdrawn[auctionID_][participant_];
    }

    function payEntryFee(bytes32 auctionID_) 
        external 
        payable 
        onlyWhenNotOwner 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(getEntryFee(auctionID_) > 0, "There is no entry fee at this auction!");
        require(msg.value == getEntryFee(auctionID_), "The paid entry fee value does not match the specified amount!");
        require(!hasPaidEntryFee(auctionID_, msg.sender), "This address has already paid the entry fee!");

        _entryFeesPaid[auctionID_][msg.sender] = true;
        emit EntryFeePaid(auctionID_, msg.sender, msg.value);

        return true;
    }

    function withdrawEntryFee(bytes32 auctionID_) 
        external 
        onlyWhenNotOwner 
        onlyIfAuctionExists(auctionID_) 
        returns (bool) 
    {
        require(isCancelled(auctionID_) || (block.number > auctionEndBlock(auctionID_)), "Entry fee cannot be withdrawn while the auction is running!");
        require(getEntryFee(auctionID_) > 0, "There is no entry fee at this auction!");
        require(hasPaidEntryFee(auctionID_, msg.sender), "This address has not paid entry fee!");
        require(!hasWithdrawnEntryFee(auctionID_, msg.sender), "This address has already withdrawn the entry fee!");

        if(payable(msg.sender).send(getEntryFee(auctionID_))) {
            _entryFeesWithdrawn[auctionID_][msg.sender] = true;
            emit EntryFeeWithdrawn(auctionID_, msg.sender, getEntryFee(auctionID_));
            return true;
        } else {
            revert("Withdrawal of entry fee has failed!");
        }
    }
}