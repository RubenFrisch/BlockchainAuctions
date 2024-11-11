// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "Cancellable.sol";

/*
*English auction: parameterized open outcry ascending bid, the direction of the price adjustion is always unfavorable for the bidders
*Reserve price: the minimum acceptable price set by the seller, if not reached by the end of the auction, the auction is invalid. The reserve price is always revealed in this auction implementation
*NR auction: an absolute no-reserve auction, the seller does not require a minimum price to be reached at the end of the auction for it to be valid
*Starting price: a starting price is usually requested in case of a NR auction
*The difference between reserve price and starting price lies in the fact that bids that do not reach the starting price are rejected, a reserve price on the other hand is evaluated at the end of the auction and affects withdraws instead of bids
*Bid increment: the minimum increment of bids, the highest bid can only be displaced if the given bid is increased by the bid increment on top of the highest bid amount
*Private information sharing: bids and identities are completely transparent, this allows for more intense competition, and potentially higher selling price, bid visibility is open
*Scottish auction: time interval auction is possible by the proper adjustment of the starting and ending block numbers during auction initialization
*Speed auction: short time interval, extremely intense bidding, speed is the most defining dimension
*Time interval auction: vast time interval, slow and strategic bidding
*Single attribute auction: bids only have one attribute, the price
*Forward auction: multiple buyers, single seller
*Winner selection: single highest bidder wins
*The auctioneer/owner of the auction cannot participate in the bidding phase
*/

contract AuctionLogic is Cancellable {

    //State variables
    mapping(address => uint256) private _bidAmountsOfBidders; //Accounting mapping data structure, where we assign the sum of the placed bids to the address (key: address of the participant, value: sum of the bids made by that address)
    uint256 private _auctionHighestBidAmount; //The highest bid
    address private _auctionWinner; //Thw winner of the auction
    uint256 private _auctionStartBlock; //At this block number the auction begins (*passed at auction construction)
    uint256 private _auctionEndBlock; //At this block number the auction ends (*passed at auction construction)
    bool private _cancellationProcessAccepted; //2-step auction cancellation mechanism
    uint256 private _startingPrice; //Starting price of the auctionized item/service (optional, pass 0 as an argument to the constructor to ignore) (*passed at auction construction)
    uint256 private _bidIncrement; //Bid increment (optional, pass 0 as an argument to the constructor to ignore) (*passed at auction construction)
    bool private _closedAuction; //In a closed auction, only whitelisted participants are eligible of placing bids (*passed at auction construction)
    mapping(address => bool) private _whitelistedParticipants; //In case of a closed auction, this mapping data structure is used to store eligible addresses by assigning a true literal to the address key
    uint256 private _reservePrice; //Reserve price in case when a reserve-auction is required (optional, pass 0 as an argument to the constructor to ignore) (*passed at auction construction)

    //Events for logging
    event BidPlacedSuccessfully(address bidder_, uint256 previousHighestBidAmount_, uint256 newHighestBidAmount_);
    event WithdrewSuccessfully(address entity_, uint256 withdrawAmount_);

    //Parameterized constructor for flexible auction creation with built in validity checks to save gas and prevent invalid auctions to be created
    constructor(
        uint256 auctionStartBlock_,
        uint256 auctionEndBlock_,
        uint256 startingPrice_,
        uint256 bidIncrement_,
        uint256 reservePrice_,
        bool closedAuction_
        )
    {

        require(auctionStartBlock_ >= block.number, "INVALID AUCTION CONTRACT INITIALIZATION: starting block must not be lower than the current block! An auction cannot start in the past.");
        require(auctionStartBlock_ < auctionEndBlock_, "INVALID AUCTION CONTRACT INITIALIZATION: ending block must be higher than starting block!");
        require(startingPrice_ >= 0, "INVALID AUCTION CONTRACT INITIALIZATION: starting price must be equal or greater than 0!");
        require(bidIncrement_ >= 0, "INVALID AUCTION CONTRACT INITIALIZATION: bid increment must be equal or greater than 0!");
        require(reservePrice_ >= 0, "INVALID AUCTION CONTRACT INITIALIZATION: reserve price must be equal or greater than 0!");

        _auctionStartBlock = auctionStartBlock_;
        _auctionEndBlock = auctionEndBlock_;
        _startingPrice = startingPrice_;
        _bidIncrement = bidIncrement_;
        _reservePrice = reservePrice_;
        _closedAuction = closedAuction_;
    }

    //Modifiers to enforce critical auction logic
    modifier onlyWhenNotOwner {
        require(msg.sender != owner(), "TRANSACTION ERROR: the owner must not participate in the auction!"); //Enforce that the modifier function will only execute if the transaction sender is not the owner itself
        _;
    }

    modifier onlyWhenAfterStartBlock {
        require(auctionStartBlock() <= block.number, "TRANSACTION ERROR: the auction has not started yet!"); //Enforce that the modified function will only execute if the auction has started
        _;
    }

    modifier onlyWhenBeforeEndBlock {
        require(block.number <= auctionEndBlock(), "TRANSACTION ERROR: the auction has ended!"); //Enforce that the modified function will only execute if the auction has not ended yet
        _;
    }

    //Getter functions for private state variables for clean access and context encapsulation
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

    function getBidAmountOfBidder(address bidder_) public view virtual returns (uint256) {
        return _bidAmountsOfBidders[bidder_];
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

    function closedAuction() public view virtual returns (bool) {
        return _closedAuction;
    }

    function reservePrice() public view virtual returns (uint256) {
        return _reservePrice;
    }

    //Auction cancellation process functions, 2-step cancellation mechanism ensures that no accidental auction cancellation is going to occur due to user error
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

    //Closed auction participant whitelisting functions
    function addParticipantToWhitelist(address participant_) public virtual onlyOwner returns (bool) {
        require(closedAuction(), "TRANSACTION ERROR: adding participants to an auction is only available when it is a closed auction, limited to a selected amount of unique whitelisted bidders!");
        require(block.number < auctionStartBlock(), "TRANSACTION ERROR: adding participants to a closed auction is only possible before the auction starts.");
        //There is no need to check if passed participant is the owner itself, as the owner won't be able to call placeBid() thanks to the onlyWhenNotOwner modifier

        _whitelistedParticipants[participant_] = true;

        return true;
    }

    function addMultipleParticipantsToWhitelist(address[] memory participants_) public virtual onlyOwner returns (bool) {
        require(closedAuction(), "TRANSACTION ERROR: adding participants to an auction is only available when it is a closed auction, limited to a selected amount of unique whitelisted bidders!");
        require(block.number < auctionStartBlock(), "TRANSACTION ERROR: adding participants to a closed auction is only possible before the auction starts.");

        for(uint i = 0; i < participants_.length ; i++) {
            _whitelistedParticipants[participants_[i]] = true;
        }

        return true;
    }

    function isWhitelisted(address participant_) internal virtual returns (bool) {
        return _whitelistedParticipants[participant_];
    }

    //Bid placing functionality
    function placeBid() public virtual payable onlyWhenNotOwner whenNotCancelled onlyWhenAfterStartBlock onlyWhenBeforeEndBlock returns (bool) {
        //Check if the function call's value is higher than 0, if not, revert the transaction
        require(msg.value > 0, "TRANSACTION ERROR: bid must be higher than 0!");
        
        //Check in case the auction is closed that the sender's address is whitelisted by the owner
        if(closedAuction()) {
            require(isWhitelisted(msg.sender), "TRANSACTION ERROR: you must be a whitelisted participant in order to place a bid in this closed auction!");
        }

        //Calculate the current call's bid sum amount by adding the msg.sender's value stored and the current call's value, because the msg.sender might have placed bids before the new bid
        uint256 thisBid = _bidAmountsOfBidders[msg.sender] + msg.value;
        
        //We must check if the total bid of the user is equal or greater than the starting price. Checking this condition solely on msg.value would be a mistake due to bids with a purpose of increasing an already existing bid
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
    
    //Bid withdraw functionality
    function withdraw() public virtual returns (bool) {
        //We must check if the auction has already ended due to regular ending or by cancellation done by the owner, if neither of the two possible auction ending is in effect, we revert the transaction
        if(!cancelled() && auctionEndBlock() > block.number) {
            revert("TRANSACTION ERROR: withdrawing is only allowed after the auction ends or in rare cases when cancelled by the auction owner!");
        }
        
        //If the auction has been cancelled, then the expected behaviour of the withdraw function should be that every bidder can withdraw freely from the contract, even the winner
        if(cancelled()) {
            uint256 withdrawAmount = _bidAmountsOfBidders[msg.sender];
            _bidAmountsOfBidders[msg.sender] -= withdrawAmount; //Optimistic balance update, we revert state changes if the ether send operation fails
            if(payable(msg.sender).send(withdrawAmount)) {
                emit WithdrewSuccessfully(msg.sender, withdrawAmount);
                return true;
            } else {
                revert("TRANSACTION ERROR: withdraw failed!");
            }
        } else if(auctionHighestBidAmount() < reservePrice()) { //The auction did not reach the desired reserve price of the seller, therefore every participant can withdraw their placed bids, there is no winner
            uint256 withdrawAmount = _bidAmountsOfBidders[msg.sender];
            _bidAmountsOfBidders[msg.sender] -= withdrawAmount;
            if(payable(msg.sender).send(withdrawAmount)) {
                emit WithdrewSuccessfully(msg.sender, withdrawAmount);
                return true;
            } else {
                revert("TRANSACTION ERROR: withdraw failed!");
            }
        } else { //The auction ended normally without getting cancelled by the owner AND reached the reserve price desired by the seller
            if(msg.sender == owner()) { //The owner is able to withdraw the _auctionWinner's bid, which is the amount of _auctionHighestBidAmount
                uint256 withdrawAmount = auctionHighestBidAmount();
                _auctionHighestBidAmount = 0;
                if(payable(msg.sender).send(withdrawAmount)) {
                    emit WithdrewSuccessfully(msg.sender, withdrawAmount);
                    return true;
                } else {
                    revert("TRANSACTION ERROR: withdraw failed!");
                }
            } else if(msg.sender == auctionWinner()) { //Thw winner of the auction should not be able to withdraw anything, because the funds are reserved for the owner
                revert("The winner is not able to withdraw from the auction! The auction winner's funds are locked and reserved for the owner of the auction!");
            } else { //If the transaction sender is NOT the owner and is NOT the auction winner, then proceed with normal withdraw process (bidders who lost can withdraw their bid funds freely)
                uint256 withdrawAmount = _bidAmountsOfBidders[msg.sender];
                _bidAmountsOfBidders[msg.sender] -= withdrawAmount;
                if(payable(msg.sender).send(withdrawAmount)) {
                    emit WithdrewSuccessfully(msg.sender, withdrawAmount);
                    return true;
                } else {
                    revert("TRANSACTION ERROR: withdraw failed!");
                }
            }
        }
    }
}