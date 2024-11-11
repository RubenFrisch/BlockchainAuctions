// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Entry fee manager contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract enables the configuration and management of the entry fee feature for auctions
/// @dev This contract enables the configuration and management of the entry fee feature for auctions
abstract contract EntryFeeManager {

     // <<< STATE VARIABLES >>>
    /// @dev Stores the entry fee of the respective auction
    mapping(bytes32 => uint256) private _entryfee;

    /// @dev Indicates whether an address has paid the entry fee or not for the respective auction
    mapping(bytes32 => mapping(address => bool)) private _entryFeesPaid;

    /// @dev Indicates whether an address has withdrawn the entry fee or not for the respective auction
    mapping(bytes32 => mapping(address => bool)) private _entryFeesWithdrawn;

     // <<< EVENTS >>>
    /// @dev Event for logging the configuration of the entry fee for a specific auction
    /// @notice Event for logging the configuration of the entry fee for a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction that the entry fee is being configured for
    /// @param entryFeeValue_ The set entry fee amount in WEI (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    event EntryFeeConfigured(bytes32 indexed auctionID_, uint256 entryFeeValue_);

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

     // <<< READ FUNCTIONS >>>
    /// @dev Retrieves the entry fee set for the specific auction
    /// @notice Retrieves the entry fee set for the specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the entry fee amount for the specific auction in Wei (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    function getEntryFee(bytes32 auctionID_) public view returns (uint256) {
        return _entryfee[auctionID_];
    }

    /// @dev Retrieves the boolean logical value indicating whether the address has paid the entry fee or not for the specific auction
    /// @notice Retrieves the boolean logical value indicating whether the address has paid the entry fee or not for the specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participant_ The address of the participant to be checked
    /// @return Returns a boolean literal that indicates whether the address has paid the entry fee for the specific auction or not
    function hasPaidEntryFee(bytes32 auctionID_, address participant_) public view returns (bool) {
        return _entryFeesPaid[auctionID_][participant_];
    }

    /// @dev Retrieves the boolean logical value indicating whether the address has withdrawn the entry fee or not from the specific auction
    /// @notice Retrieves the boolean logical value indicating whether the address has withdrawn the entry fee or not from the specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participant_ The address of the participant to be checked
    /// @return Returns a boolean literal that indicates whether the address has withdrawn the entry fee from the specific auction or not
    function hasWithdrawnEntryFee(bytes32 auctionID_, address participant_) public view returns (bool) {
        return _entryFeesWithdrawn[auctionID_][participant_];
    }

     // <<< CORE ENTRY FEE MANAGER FUNCTIONS >>>
    /// @dev Sets the entry fee for a specific auction
    /// @notice Sets the entry fee for a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param entryFee_ The amount of the entry fee in WEI (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    function _setEntryFee(bytes32 auctionID_, uint256 entryFee_) internal {
        _entryfee[auctionID_] = entryFee_;
        emit EntryFeeConfigured(auctionID_, entryFee_);
    }

    /// @dev Sets the entry fee for a specific auction
    /// @notice Sets the entry fee for a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param entryFee_ The amount of the entry fee in WEI (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    /// @return Returns true boolean literal if the entry fee has been successfully set
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be done by the internal function '_setEntryFee'
    function setEntryFee(bytes32 auctionID_, uint256 entryFee_) external virtual returns (bool);

    /// @dev Manages the internal accounting of entry fee payments
    /// @notice Manages the internal accounting of entry fee payments
    /// @param auctionID_ The 256 bit hash identifier of the auction
    function _payEntryFee(bytes32 auctionID_) internal {
        _entryFeesPaid[auctionID_][msg.sender] = true;
        emit EntryFeePaid(auctionID_, msg.sender, msg.value);
    }

    /// @dev Manages the internal accounting of entry fee payments
    /// @notice Manages the internal accounting of entry fee payments
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns true boolean literal if the entry fee has been successfully paid
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be done by the internal function '_payEntryFee'
    function payEntryFee(bytes32 auctionID_) external payable virtual returns (bool);

    /// @dev Manages the internal accounting of entry fee withdrawals
    /// @notice Manages the internal accounting of entry fee withdrawals
    /// @param auctionID_ The 256 bit hash identifier of the auction
    function _withdrawEntryFee(bytes32 auctionID_) internal {
        _entryFeesWithdrawn[auctionID_][msg.sender] = true;
        emit EntryFeeWithdrawn(auctionID_, msg.sender, getEntryFee(auctionID_));
    }

    /// @dev Manages the internal accounting of entry fee withdrawals
    /// @notice Manages the internal accounting of entry fee withdrawals
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns true if the entry fee withdrawal was successful
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be done by the internal function '_withdrawEntryFee'
    function withdrawEntryFee(bytes32 auctionID_) external virtual returns (bool);
}