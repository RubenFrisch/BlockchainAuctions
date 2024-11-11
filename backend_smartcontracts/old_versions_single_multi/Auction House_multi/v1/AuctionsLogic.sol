// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "Cancellable.sol";
import "AuctionERC721.sol";

contract AuctionsLogic is Cancellable {

    // <<<< State variables >>>>
    mapping(bytes32 => bool) _auctionID;
    mapping(bytes32 => mapping(address => uint256)) private _bidAmountsOfBidders;
    mapping(bytes32 => uint256) private _auctionHighestBidAmount;
    mapping(bytes32 => address) private _auctionWinner;
    mapping(bytes32 => uint256) private _auctionStartBlock;
    mapping(bytes32 => uint256) private _auctionEndBlock;
    mapping(bytes32 => uint256) private _startingPrice;
    mapping(bytes32 => uint256) private _bidIncrement;
    mapping(bytes32 => bool) private _closedAuction;
    mapping(bytes32 => mapping(address => bool)) private _whitelistedParticipants;
    mapping(bytes32 => uint256) private _reservePrice;
    mapping(bytes32 => bool) private _ownerWithdrew;
    mapping(bytes32 => uint256) private _entryfee;
    mapping(bytes32 => mapping(address => bool)) private _entryFeesOfParticipants;
    mapping(bytes32 => mapping(address => bool)) private _entryFeeWithdrawn;
    mapping(bytes32 => uint256) private _auctionSnipeInterval;
    mapping(bytes32 => uint256) private _auctionSnipeBlocks;
    mapping(bytes32 => string) private _ipfs;
    mapping(bytes32 => AuctionERC721) private _nftContractAddress;
    mapping(bytes32 => uint256) private _nftTokenID;

    // <<<< Events for logging >>>>
    event NewAuctionCreated(bytes32 indexed auctionID_, address owner_);
    event BidPlacedSuccessfully(bytes32 indexed auctionID_, address bidder_, uint256 previousHighestBidAmount_, uint256 newHighestBidAmount_);
    event WithdrewSuccessfully(bytes32 indexed auctionID_, address entity_, uint256 withdrawAmount_);
    event PaidEntryFeeSuccessfully(bytes32 indexed auctionID_, address entity_, uint256 paidEntryFeeAmount_);
    event WithdrewEntryFeeSuccessfully(bytes32 indexed auctionID_, address entity_, uint256 withdrawnEntryFeeAmount_);
    event AuctionSnipePreventionMechanismTriggered(bytes32 indexed auctionID_, address bidder_);

    // <<<< Function modifiers >>>>
    modifier onlyIfAuctionExists(bytes32 auctionID_) {
        require(_auctionID[auctionID_], "Auction does not exist with this ID!");
        _;
    }

    modifier onlyIfAuctionDoesNotExist(bytes32 auctionID_) {
        require(!_auctionID[auctionID_], "Auction already exists with this ID!");
        _;
    }

    modifier onlyAfterStartBlock(bytes32 auctionID_) {
        require(_auctionStartBlock[auctionID_] <= block.number, "The auction has not started yet!");
        _;
    }

    modifier onlyBeforeEndBlock(bytes32 auctionID_) {
        require(block.number <= _auctionEndBlock[auctionID_], "The auction has already ended!");
        _;
    }




    // <<<< New auction assembly >>>>
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
    ) external onlyOwner onlyIfAuctionDoesNotExist(auctionID_) {
        require(auctionStartBlock_ < auctionEndBlock_, "Auction must start before it ends!");
        require(auctionStartBlock_ >= block.number, "Auction must not start at a past block!");
        require(startingPrice_ >= 0, "Starting price must not be negative!");
        require(bidIncrement_ >= 0, "Bid increment must not be negative!");
        require(reservePrice_ >= 0, "Reserve price must not be negative!");
        require(auctionSnipeInterval_ >= 0, "Snipe protection interval must not be negative!");
        require(auctionSnipeInterval_ < (auctionEndBlock_ - auctionStartBlock_),"Invalid snipe protection interval!");
        require(auctionSnipeBlocks_ >= 0, "Snipe protection block count must not be negative!");
        require(isSmartContract(nftContractAddress_), "Address is not a smart contract!");
        require(AuctionERC721(nftContractAddress_).supportsInterface(type(IERC721).interfaceId), "Contract does not implement the IERC721 interface!");

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
    }







    // <<<< Read functions >>>>
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

    function getBidAmountOfBidder(bytes32 auctionID_, address bidder_) external view returns (uint256) {
        return _bidAmountsOfBidders[auctionID_][bidder_];
    }

    function startingPrice(bytes32 auctionID_) public view returns (uint256) {
        return _startingPrice[auctionID_];
    }

    function bidIncrement(bytes32 auctionID_) public view returns (uint256) {
        return _bidIncrement[auctionID_];
    }

    function closedAuction(bytes32 auctionID_) public view returns (bool) {
        return _closedAuction[auctionID_];
    }

    function isWhiteListed(bytes32 auctionID_, address participant_) public view returns (bool) {
        return _whitelistedParticipants[auctionID_][participant_];
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

    function entryFee(bytes32 auctionID_) public view returns (uint256) {
        return _entryfee[auctionID_];
    }

    function hasPaidEntryFee(bytes32 auctionID_, address participant_) public view returns (bool) {
        return _entryFeesOfParticipants[auctionID_][participant_];
    }

    function hasWithdrawnEntryFee(bytes32 auctionID_, address participant_) public view returns (bool) {
        return _entryFeeWithdrawn[auctionID_][participant_];
    }

    function auctionSnipeInterval(bytes32 auctionID_) public view returns (uint256) {
        return _auctionSnipeInterval[auctionID_];
    }

    function auctionSnipeBlocks(bytes32 auctionID_) public view returns (uint256) {
        return _auctionSnipeBlocks[auctionID_];
    }

    function ipfs(bytes32 auctionID_) external view returns (string memory) {
        return _ipfs[auctionID_];
    }

    function nftContractAddress(bytes32 auctionID_) public view returns (AuctionERC721) {
        return _nftContractAddress[auctionID_];
    }

    function nftTokenID(bytes32 auctionID_) public view returns (uint256) {
        return _nftTokenID[auctionID_];
    }














    // <<<< Auction cancellation functionality >>>>
    function cancelAuction(bytes32 auctionID_) external override onlyOwner onlyIfAuctionExists(auctionID_) onlyAfterStartBlock(auctionID_) onlyBeforeEndBlock(auctionID_) {
        super._cancelAuction(auctionID_);
        _nftContractAddress[auctionID_].burn(_nftTokenID[auctionID_]);
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
} 