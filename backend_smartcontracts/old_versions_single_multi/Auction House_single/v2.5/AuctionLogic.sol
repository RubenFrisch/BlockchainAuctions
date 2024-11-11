// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "Cancellable.sol";

/*
*English auction: parameterized open outcry ascending bid, the direction of the price adjustion is always unfavorable for the bidders
*Reserve price: the minimum acceptable price set by the seller, if not reached by the end of the auction, the auction is invalid. The reserve price is always revealed in this auction implementation
*NR auction: in an absolute no-reserve auction, the seller does not require a minimum price to be reached at the end of the auction for it to be valid
*Starting price: a starting price is usually requested in case of a NR auction
*The difference between reserve price and starting price lies in the fact that bids that do not reach the starting price are rejected, a reserve price on the other hand is evaluated at the end of the auction and affects withdraws instead of bids
*Bid increment: the minimum increment of bids, the highest bid can only be displaced if the given bid is increased by the bid increment on top of the highest bid amount
*Private information sharing: bids and identities are completely transparent, this allows for more intense competition, and potentially higher selling price, bid visibility is open
*Scottish auction: time interval auction is possible by the proper adjustment of the starting and ending block numbers during auction initialization
*Speed auction: short time interval, speed is the most defining attribute
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
    uint256 private immutable _auctionStartBlock; //At this block number the auction begins (*passed at auction construction)
    uint256 private _auctionEndBlock; //At this block number the auction ends (*passed at auction construction)
    bool private _cancellationProcessAccepted; //2-step auction cancellation mechanism
    uint256 private immutable _startingPrice; //Starting price of the auctionized item/service (pass 0 as an argument to the constructor to ignore) (*passed at auction construction)
    uint256 private immutable _bidIncrement; //Bid increment (pass 0 as an argument to the constructor to ignore) (*passed at auction construction)
    bool private immutable _closedAuction; //In a closed auction, only whitelisted participants are eligible to place bids (*passed at auction construction)
    mapping(address => bool) private _whitelistedParticipants; //In case of a closed auction, this mapping data structure is used to store eligible addresses by assigning a true literal to the address key
    uint256 private immutable _reservePrice; //Reserve price in case when a reserve-auction is required (pass 0 as an argument to the constructor to ignore) (*passed at auction construction)
    bool private _ownerWithdrew; //Indicates whether the owner has already withdrawn or not
    uint256 private immutable _entryFee; //Entry fee for auction participants, pass 0 to constructor to turn off the entry fee feature (*passed at auction construction)
    mapping(address => bool) private _entryFeesOfParticipants; //Accounting mapping data structure, where we store whether a participant has paid the entry fee or not (key: address of the participant, value: boolean, paid the entry fee or not)
    mapping(address => bool) private _entryFeeWithdrawn; //Accounting mapping data structure, where we store whether a participant has withdrawn the entry fee or not (Key: address of the participant, value: boolean, withdrawn the entry fee or not)
    uint256 private immutable _auctionSnipeProtectionActivationInterval; //Protective mechanism against auction sniping, pass 0 to constructor to turn off this feature (*passed at auction construction)
    uint256 private immutable _auctionSnipeProtectionNumOfBlocks; //Protective mechanism against auction sniping, pass 0 to constructor to turn off this feature (*passed at auction construction)
    string private _ipfs; //To store IPFS auction metadata

    //Events for logging
    event BidPlacedSuccessfully(address indexed bidder_, uint256 indexed previousHighestBidAmount_, uint256 indexed newHighestBidAmount_);
    event WithdrewSuccessfully(address indexed entity_, uint256 indexed withdrawAmount_);
    event PaidEntryFeeSuccessfully(address indexed entity_, uint256 indexed paidEntryFeeAmount_);
    event WithdrewEntryFeeSuccessfully(address indexed entity_, uint256 indexed withdrawnEntryFeeAmount_);
    event AuctionSnipePreventionMechanismTriggered(address indexed bidder_);

    //Parameterized constructor for flexible auction creation with built in validity checks to save gas and prevent invalid auctions
    constructor(
        uint256 auctionStartBlock_,
        uint256 auctionEndBlock_,
        uint256 startingPrice_,
        uint256 bidIncrement_,
        uint256 reservePrice_,
        bool closedAuction_,
        uint256 entryFee_,
        uint256 auctionSnipeProtectionActivationInterval_,
        uint256 auctionSnipeProtectionNumOfBlocks_
    )
    {
        require(auctionStartBlock_ >= block.number, "INVALID AUCTION CONTRACT INITIALIZATION: starting block must not be lower than the current block! An auction cannot start in the past.");
        require(auctionStartBlock_ < auctionEndBlock_, "INVALID AUCTION CONTRACT INITIALIZATION: ending block must be higher than starting block!");
        require(startingPrice_ >= 0, "INVALID AUCTION CONTRACT INITIALIZATION: starting price must be equal or greater than 0!");
        require(bidIncrement_ >= 0, "INVALID AUCTION CONTRACT INITIALIZATION: bid increment must be equal or greater than 0!");
        require(reservePrice_ >= 0, "INVALID AUCTION CONTRACT INITIALIZATION: reserve price must be equal or greater than 0!");
        require(entryFee_ >= 0, "INVALID AUCTION CONTRACT INITIALIZATION: entry fee must be equal or greater than 0!");
        require(auctionSnipeProtectionActivationInterval_ < (auctionEndBlock_ - auctionStartBlock_), "INVALID AUCTION CONTRACT INITIALIZATION: the auction snipe protection interval must be less than the whole duration of the auction!");
        require(auctionSnipeProtectionActivationInterval_ >= 0, "INVALID AUCTION CONTRACT INITIALIZATION: snipe activation interval must be equal or greater than 0!");
        require(auctionSnipeProtectionNumOfBlocks_ >= 0, "INVALID AUCTION CONTRACT INITIALIZATION: number of snipe protection blocks must be equal or greater than 0!");

        _auctionStartBlock = auctionStartBlock_;
        _auctionEndBlock = auctionEndBlock_;
        _startingPrice = startingPrice_;
        _bidIncrement = bidIncrement_;
        _reservePrice = reservePrice_;
        _closedAuction = closedAuction_;
        _entryFee = entryFee_;
        _auctionSnipeProtectionActivationInterval = auctionSnipeProtectionActivationInterval_;
        _auctionSnipeProtectionNumOfBlocks = auctionSnipeProtectionNumOfBlocks_;
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
    function auctionHighestBidAmount() public view returns (uint256) {
        return _auctionHighestBidAmount;
    }

    function auctionWinner() public view returns (address) {
        return _auctionWinner;
    }

    function auctionStartBlock() public view returns (uint256) {
        return _auctionStartBlock;
    }

    function auctionEndBlock() public view returns (uint256) {
        return _auctionEndBlock;
    }

    function getBidAmountOfBidder(address bidder_) external view returns (uint256) {
        return _bidAmountsOfBidders[bidder_];
    }

    function cancellationProcessAccepted() public view returns (bool) {
        return _cancellationProcessAccepted;
    }

    function startingPrice() public view returns (uint256) {
        return _startingPrice;
    }

    function bidIncrement() public view returns (uint256) {
        return _bidIncrement;
    }

    function closedAuction() public view returns (bool) {
        return _closedAuction;
    }

    function reservePrice() public view returns (uint256) {
        return _reservePrice;
    }

    function contractETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function ownerWithdrew() public view returns (bool) {
        return _ownerWithdrew;
    }

    function entryFee() public view returns (uint256) {
        return _entryFee;
    }

    function auctionSnipeProtectionActivationInterval() public view returns (uint256) {
        return _auctionSnipeProtectionActivationInterval;
    }

    function auctionSnipeProtectionNumOfBlocks() public view returns (uint256) {
        return _auctionSnipeProtectionNumOfBlocks;
    }

    function getIPFS() external view returns (string memory) {
        return _ipfs;
    }

    function setIPFS(string memory ipfs_) external onlyOwner returns (bool) {
        require(block.number < auctionStartBlock(), "TRANSACTION ERROR: settings the ipfs is only possible before the auction starts!");
        _ipfs = ipfs_;
        return true;
    }

    //Auction cancellation process functions, 2-step cancellation mechanism ensures that no accidental auction cancellation is going to occur due to user error
    function startAuctionCancellationProcess() external override onlyOwner onlyWhenAfterStartBlock onlyWhenBeforeEndBlock {
        require(!cancellationProcessAccepted(), "TRANSACTION WARNING: the auction cancellation process has already begun!");
        _cancellationProcessAccepted = true;
    }

    function resetAuctionCancellationProcess() external override onlyOwner onlyWhenAfterStartBlock onlyWhenBeforeEndBlock {
        require(cancellationProcessAccepted(), "TRANSACTION WARNING: the auction cancellation process is not initiated!");
        _cancellationProcessAccepted = false;
    }

    function cancelAuction2Step() external override onlyOwner onlyWhenAfterStartBlock onlyWhenBeforeEndBlock {
        require(cancellationProcessAccepted(), "TRANSACTION ERROR: the auction cancellation process must be initiated before the process can be completed to ensure that no accidental cancellation could occur!");
        super._cancelAuction();
    }

    //Closed private auction participant whitelisting functions
    function addParticipantToWhitelist(address participant_) external onlyOwner returns (bool) {
        require(closedAuction(), "TRANSACTION ERROR: adding participants to an auction is only available when it is a closed auction, limited to a selected amount of unique whitelisted bidders!");
        require(block.number < auctionStartBlock(), "TRANSACTION ERROR: adding participants to a closed auction is only possible before the auction starts.");
        //There is no need to check if passed participant is the owner itself, as the owner won't be able to call placeBid() thanks to the onlyWhenNotOwner modifier

        _whitelistedParticipants[participant_] = true;

        return true;
    }

    function addMultipleParticipantsToWhitelist(address[] memory participants_) external onlyOwner returns (bool) {
        require(closedAuction(), "TRANSACTION ERROR: adding participants to an auction is only available when it is a closed auction, limited to a selected amount of unique whitelisted bidders!");
        require(block.number < auctionStartBlock(), "TRANSACTION ERROR: adding participants to a closed auction is only possible before the auction starts.");

        for(uint i = 0; i < participants_.length ; i++) {
            _whitelistedParticipants[participants_[i]] = true;
        }

        return true;
    }

    function isWhitelisted(address participant_) public view returns (bool) {
        return _whitelistedParticipants[participant_];
    }

    //Bid placing functionality
    function placeBid() external payable onlyWhenNotOwner whenNotCancelled onlyWhenAfterStartBlock onlyWhenBeforeEndBlock returns (bool) {
        //Check if the function call's value is higher than 0, if not, revert the transaction (prevent further computation in case msg.value was forgotten by the caller
        require(msg.value > 0, "TRANSACTION ERROR: bid must be higher than 0!");
        
        //If there is an entry fee set, check whether the bidder has payed the entry fee or not
        if(entryFee() != 0) {
            require(hasPaidEntryFee(msg.sender), "TRANSACTION ERROR: the entry fee was not paid by the account!");
        }

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
        require(thisBid >= highestBidPlusIncrement, "TRANSACTION ERROR: bid must be greater or equal than the sum of the highest winning bid and the bid increment!");
        uint256 previousHighestBidAmount = auctionHighestBidAmount();
        _auctionHighestBidAmount = thisBid;
        _bidAmountsOfBidders[msg.sender] = thisBid;

        //The msg.sender might just wishing to increase his winning bid to a higher amount, in this case we should not rewrite the storage variable and waste gas
        if(auctionWinner() != msg.sender) {
            _auctionWinner = msg.sender;
        }

        //Only evaluate the auction sniping protection mechanism if the bid was successful to prevent auction postponing with invalid bids
        if(auctionSnipeProtectionActivationInterval() > 0 && auctionSnipeProtectionNumOfBlocks() > 0) { //Check if the feature is turned on or not
            if((auctionEndBlock() - block.number) <= auctionSnipeProtectionActivationInterval()) { 
                //Why not check if the result of the subtraction is lower than 0? Due to the modifiers, it is guaranteed that this code path will only be executed if the auction is still in progress
                //Otherwise, it would yield a bug, when after the auction has been concluded, the snipe prevention mechanism would extend the auction beyond its original ending block
                //Extend auction in case the number of blocks left at this winning bid is less or equal than the set snipe protection activation interval
                _auctionEndBlock += auctionSnipeProtectionNumOfBlocks(); //Add configured number of blocks to the end to the auction to extend it and prevent sniping
                emit AuctionSnipePreventionMechanismTriggered(msg.sender);
            }
        }

        emit BidPlacedSuccessfully(msg.sender, previousHighestBidAmount, thisBid);
        return true;
    }
    
    //Bid withdraw functionality
    function withdraw() external returns (bool) {
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
                revert("TRANSACTION ERROR: Withdraw failed!");
            }
        } else { //The auction ended normally without getting cancelled by the owner AND reached the reserve price desired by the seller
            if(msg.sender == owner()) { //The owner is able to withdraw the _auctionWinner's bid, which is the amount of _auctionHighestBidAmount
                if(!ownerWithdrew()) { //The owner can withdraw only once
                    uint256 withdrawAmount = auctionHighestBidAmount();
                    _bidAmountsOfBidders[auctionWinner()] -= withdrawAmount;
                    _ownerWithdrew = true;
                    if(payable(msg.sender).send(withdrawAmount)) {
                        emit WithdrewSuccessfully(msg.sender, withdrawAmount);
                        return true;
                    } else {
                        revert("TRANSACTION ERROR: Withdraw failed!");
                    }
                } else {
                    revert("TRANSACTION ERROR: Owner has already withdrawn!");
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
   
    //Entry fee functionality
    function hasPaidEntryFee(address participant_) public view returns (bool) {
        return _entryFeesOfParticipants[participant_];
    }

    function hasWithdrawnEntryFee(address participant_) public view returns (bool) {
        return _entryFeeWithdrawn[participant_];
    }

    function payEntryFee() external payable onlyWhenNotOwner returns (bool) {
        //Owner should not be able to pay entry fee, modifier enforces that criteria
        require(block.number < auctionStartBlock(), "TRANSACTION ERROR: paying the entry fee is only possible before the auction starts!"); //Entry fee must be paid before the auction has started
        require(entryFee() > 0, "TRANSACTION ERROR: there is no entry fee associated with this auction!"); //If the entry fee is zero, participants do not have to pay anything to participate in the auction
        require(msg.value == entryFee(), "TRANSACTION ERROR: the entry fee must be exactly the amount of the set entry fee!"); //Prevent entry fee overpayment by only accepting the exact amount of entry fee set
        require(!hasPaidEntryFee(msg.sender), "TRANSACTION ERROR: this account has already paid the entry fee!"); //Prevent participants paying the entry fee multiple times

        _entryFeesOfParticipants[msg.sender] = true; //Record that the sender has paid the entry fee
        emit PaidEntryFeeSuccessfully(msg.sender, entryFee());

        return true;
    }

    function withdrawEntryFee() external onlyWhenNotOwner returns (bool) {
        //Owner should not be able to pay entry fee, modifier enforces that criteria
        //We must check if the auction has already ended due to regular ending or by cancellation done by the owner, if neither of the two possible auction ending is in effect, we revert the transaction
        if(!cancelled() && auctionEndBlock() > block.number) {
            revert("TRANSACTION ERROR: withdrawing is only allowed after the auction ends or in rare cases when cancelled by the auction owner!");
        }

        require(entryFee() > 0, "TRANSACTION ERROR: there was no entry fee associated with this auction!"); //If the entry fee is zero, participants do not have to pay anything to participate in the auction
        require(hasPaidEntryFee(msg.sender), "TRANSACTION ERROR: This account has not payed the entry fee!"); //We must make sure that only those accounts can withdraw that payed the entry fee before
        require(!hasWithdrawnEntryFee(msg.sender), "TRANSACTION ERROR: This account has already withdrawn the entry fee!"); //Check whether the sender has payed the entry fee or not

        if(payable(msg.sender).send(entryFee())) {
            _entryFeeWithdrawn[msg.sender] = true; //Record that the sender has withdrawn the entry fee
            emit WithdrewEntryFeeSuccessfully(msg.sender, entryFee());
            return true;
        } else {
            revert("TRANSACTION ERROR: Withdraw failed!");
        }
    }
}