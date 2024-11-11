// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "Cancellable.sol";

contract AuctionLogic is Cancellable {

    mapping(address => uint256) private _bidAmountsOfBidders;
    uint256 private _auctionHighestBidAmount;
    address private _auctionWinner;
    uint256 private _auctionStartBlock;
    uint256 private _auctionEndBlock;
    bytes32 private _auctionIdentifier;
    bool private _cancellationProcessAccepted;
    uint256 private _startingPrice; //optional auction parameter, pass 0 to the constructor if it is not required for the auction
    uint256 private _bidIncrement; //optional auction parameter, pass 0 to the constructor if it is not required for the auction
    //Note, that constructor overloading is not supported by Solidity, therefore we must still pass all arguments even if it is marked as optional

    event BidPlacedSuccessfully(address bidder, uint256 previousHighestBidAmount, uint256 newHighestBidAmount);


    constructor(uint256 auctionStartBlock_, uint256 auctionEndBlock_, bytes32 auctionIdentifier_, uint256 startingPrice_, uint256 bidIncrement_) {
        require(auctionStartBlock_ >= block.number, "INVALID AUCTION CONTRACT INITIALIZATION: starting block must not be lower than the current block! An auction cannot start in the past.");
        require(auctionStartBlock_ < auctionEndBlock_, "INVALID AUCTION CONTRACT INITIALIZATION: ending block must be higher than starting block!");
        require(startingPrice_ >= 0, "INVALID AUCTION CONTRACT INITIALIZATION: starting price must be equal or greater than 0!");
        require(bidIncrement_ >= 0, "INVALID AUCTION CONTRACT INITIALIZATION: bid increment must be equal or greater than 0!");

        _auctionStartBlock = auctionStartBlock_;
        _auctionEndBlock = auctionEndBlock_;
        _auctionIdentifier = auctionIdentifier_;
        _startingPrice = startingPrice_;
        _bidIncrement = bidIncrement_;
    }

    modifier onlyWhenNotOwner {
        require(msg.sender != owner(), "TRANSACTION ERROR: the owner must not participate in the auction!");
        _;
    }

    modifier onlyWhenAfterStartBlock {
        require(auctionStartBlock() <= block.number, "TRANSACTION ERROR: the auction has not started yet!");
        _;
    }

    modifier onlyWhenBeforeEndBlock {
        require(block.number <= auctionEndBlock(), "TRANSACTION ERROR: the auction has ended!");
        _;
    }

    function auctionHighestBidAmount() public view virtual returns (uint256) {
        return _auctionHighestBidAmount;
    }

    function auctionWinner() public view virtual returns (address) {
        return _auctionWinner;
    }

    function auctionStartBlock() public view virtual returns (uint256) {
        return _auctionStartBlock;
    }

    function auctionEndBlock() public view virtual returns (uint256) {
        return _auctionEndBlock;
    }

    function auctionIdentifier() public view virtual returns (bytes32) {
        return _auctionIdentifier;
    }

    function getBidAmountOfBidder(address bidder) public view virtual returns (uint256) {
        return _bidAmountsOfBidders[bidder];
    }

    function cancellationProcessAccepted() public view virtual returns (bool) {
        return _cancellationProcessAccepted;
    }

    function startingPrice() public view virtual returns (uint256) {
        return _startingPrice;
    }

    function bidIncrement() public view virtual returns (uint256) {
        return _bidIncrement;
    }

    function startAuctionCancellationProcess() public virtual override onlyOwner onlyWhenAfterStartBlock onlyWhenBeforeEndBlock {
        require(!cancellationProcessAccepted(), "TRANSACTION WARNING: the auction cancellation process has already begun!");
        _cancellationProcessAccepted = true;
    }

    function resetAuctionCancellationProcess() public virtual override onlyOwner onlyWhenAfterStartBlock onlyWhenBeforeEndBlock {
        require(cancellationProcessAccepted(), "TRANSACTION WARNING: the auction cancellation process is not initiated!");
        _cancellationProcessAccepted = false;
    }

    function cancelAuction2Step() public virtual override onlyOwner onlyWhenAfterStartBlock onlyWhenBeforeEndBlock {
        require(cancellationProcessAccepted(), "TRANSACTION ERROR: the auction cancellation process must be initiated before the process can be completed to ensure that no accidental cancellation could occur!");
        super._cancelAuction();
    }

    function putBid() public virtual payable onlyWhenNotOwner whenNotCancelled onlyWhenAfterStartBlock onlyWhenBeforeEndBlock returns (bool) {
        //Check if the function call's value is higher than 0, if not, revert the transaction
        require(msg.value > 0, "TRANSACTION ERROR: bid must be higher than 0!");
        
        //Calculate the current call's bid sum amount by adding the msg.sender's value stored and the current call's value, because the msg.sender might have placed bids before the new bid
        uint256 thisBid = _bidAmountsOfBidders[msg.sender] + msg.value;
        
        //We must check if the total bid of the user is equal or greater than the starting price. Checking this condition solely on msg.value would be a mistake due to increase bids, which would fail
        require(thisBid >= startingPrice(), "TRANSACTION ERROR: the total bid must be higher than the starting price!");

        //We must make sure that the first bid does NOT have to pass the requirement of being greater than the highest bid + bid increment. First bid should only be equal or greater than the starting price
        uint256 highestBidPlusIncrement = 0;
        if(auctionHighestBidAmount() != 0) {
            highestBidPlusIncrement = auctionHighestBidAmount() + bidIncrement();
        }

        //Check if the current bid is higher than the highest winning bid plus the set bid increment, if it is, we need to update our storage variables accordingly
        //For the first bid, the highestBidPlusIncrement variable will always be 0, but the following code only executes if the thisBid >= startingPrice() condition is satisfied
        require(thisBid > highestBidPlusIncrement, "TRANSACTION ERROR: bid must be higher than the sum of the highest winning bid and the bid increment!");
        uint256 previousHighestBidAmount = auctionHighestBidAmount();
        _auctionHighestBidAmount = thisBid;
        _bidAmountsOfBidders[msg.sender] = thisBid;

        //The msg.sender might just wishing to increase his winning bid to a higher amount, in this case we should not rewrite the storage variable and waste gas
        if(auctionWinner() != msg.sender) {
            _auctionWinner = msg.sender;
        }

        emit BidPlacedSuccessfully(msg.sender, previousHighestBidAmount, thisBid);
        return true;
    }
    
    function withdraw() public virtual returns (bool) {
        //We must check if the auction has already ended due to regular ending or by cancellation done by the owner, if neither of the two possible auction ending is in effect, we revert the transaction
        if(!cancelled() && auctionEndBlock() > block.number) {
            revert("TRANSACTION ERROR: withdrawing is only allowed after the auction ends or in rare cases cancelled by the owner!");
        }
        
        //If the auction has been cancelled, then the expected behaviour of the withdraw function should be that every bidder can withdraw freely from the contract, even the winner
        if(cancelled()) {
            uint256 withdrawAmount = _bidAmountsOfBidders[msg.sender];
            if(payable(msg.sender).send(withdrawAmount)) {
                _bidAmountsOfBidders[msg.sender] -= withdrawAmount;
                return true;
            }
        } //The auction ended normally without getting cancelled by the owner
        else {
            if(msg.sender == owner()) { //The owner is able to withdraw the _auctionWinner's bid, which is the amount of _auctionHighestBidAmount
                uint256 withdrawAmount = auctionHighestBidAmount();
                if(payable(msg.sender).send(withdrawAmount)) {
                    _auctionHighestBidAmount = 0;
                    return true;
                }
            } else if(msg.sender == auctionWinner()) { //Thw winner of the auction should not be able to withdraw anything, because the funds are reserved for the owner
                revert("The winner is not able to withdraw from the auction! The auction winner's funds are locked and reserved for the owner of the auction!");
            } else { //If the transaction sender is NOT the owner and is NOT the auction winner, then proceed with normal withdraw process (bidders who lost)
                uint256 withdrawAmount = _bidAmountsOfBidders[msg.sender];
                if(payable(msg.sender).send(withdrawAmount)) {
                    _bidAmountsOfBidders[msg.sender] -= withdrawAmount;
                    return true;
                }
            }
        }
        return false;
    }
}