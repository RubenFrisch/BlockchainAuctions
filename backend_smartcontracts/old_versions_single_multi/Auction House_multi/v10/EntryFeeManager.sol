// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract EntryFeeManager {

    /// @dev Stores the entry fee of the respective auction
    mapping(bytes32 => uint256) private _entryfee;

    /// @dev Indicates whether an address has paid the entry fee or not of the respective auction
    mapping(bytes32 => mapping(address => bool)) private _entryFeesPaid;

    /// @dev Indicates whether an address has withdrawn the entry fee or not of the respective auction
    mapping(bytes32 => mapping(address => bool)) private _entryFeesWithdrawn;


    event EntryFeeConfigured(bytes32 indexed auctionID_, uint256 entryFeeValue);


    /// @dev Event for logging the payment of entry fees
    /// @notice Event for logging the payment of entry fees
    /// @param auctionID_ The 256 bit hash identifier of the auction that the entry fee is being paid to
    /// @param entity_ The address that paid the entry fee by calling the 'payEntryFee' function
    /// @param paidEntryFeeAmount_ The amount of the entry fee being paid in Wei (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    event EntryFeePaid(bytes32 indexed auctionID_, address entity_, uint256 paidEntryFeeAmount_);

    /// @dev Event for logging the withdrawal of entry fees
    /// @notice Event for logging the withdrawal of entry fees
    /// @param auctionID_ The 256 bit hash identifier of the auction that the entry fee is being withdrawn from
    /// @param entity_ The address that withdrew the entry fee by calling the 'withdrawEntryFee' function
    /// @param withdrawnEntryFeeAmount_ The amount of the entry fee being withdrawn in Wei (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    event EntryFeeWithdrawn(bytes32 indexed auctionID_, address entity_, uint256 withdrawnEntryFeeAmount_);


    function getEntryFee(bytes32 auctionID_) public view returns (uint256) {
        return _entryfee[auctionID_];
    }

    function hasPaidEntryFee(bytes32 auctionID_, address participant_) public view returns (bool) {
        return _entryFeesPaid[auctionID_][participant_];
    }

    function hasWithdrawnEntryFee(bytes32 auctionID_, address participant_) public view returns (bool) {
        return _entryFeesWithdrawn[auctionID_][participant_];
    }




    function _setEntryFee(bytes32 auctionID_, uint256 entryFee_) internal {
        _entryfee[auctionID_] = entryFee_;
        emit EntryFeeConfigured(auctionID_, entryFee_);
    }

    function setEntryFee(bytes32 auctionID_, uint256 entryFee_) external virtual returns (bool);






    function _payEntryFee(bytes32 auctionID_) internal {
        _entryFeesPaid[auctionID_][msg.sender] = true;
        emit EntryFeePaid(auctionID_, msg.sender, msg.value);
    }

    function payEntryFee(bytes32 auctionID_) external payable virtual returns (bool);







    function _withdrawEntryFee(bytes32 auctionID_) internal {
        _entryFeesWithdrawn[auctionID_][msg.sender] = true;
        emit EntryFeeWithdrawn(auctionID_, msg.sender, getEntryFee(auctionID_));
    }

    function withdrawEntryFee(bytes32 auctionID_) external virtual returns (bool);




}