// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract EntryFeeManager {

    /// @dev Stores the entry fee of the respective auction
    mapping(bytes32 => uint256) private _entryfee;

    /// @dev Indicates whether an address has paid the entry fee or not of the respective auction
    mapping(bytes32 => mapping(address => bool)) private _entryFeesPaid;

    /// @dev Indicates whether an address has withdrawn the entry fee or not of the respective auction
    mapping(bytes32 => mapping(address => bool)) private _entryFeesWithdrawn;

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

    



}