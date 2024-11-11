// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Ownership controller appendage contract
/// @author Ruben Frisch (ÓE-NIK, Business Informatics MSc)
/// @notice This contract enables the safe management and control of access privileges (owner role), by extending the core functionality set
/// @dev This contract contains the logic for safe ownership control
abstract contract OwnershipController {

     // <<< STATE VARIABLES >>>
    /// @dev Stores the current owner's address (admin)
    address private _owner;

    /// @dev Stores the pending (nominated) owner's address
    address private _pendingOwner;

    /// @dev Indicates whether the safe 2-step ownership relinquishment (renounce) process has been initiated (unlocked) or not (locked) by the owner
    bool private _renounceUnlocked;

     // <<< EVENTS >>>
    /// @dev Event for logging the transfer of ownership to a new address (also logs ownership relinquishment to the burn (zero) address)
    /// @notice Event for logging the transfer of ownership to a new address
    /// @param previousOwner_ The address of the previous owner (admin)
    /// @param newOwner_ The address of the new owner (admin)
    event OwnershipTransferCompleted(address indexed previousOwner_, address indexed newOwner_);

    /// @dev Event for logging the initiation of the ownership transfer process (nomination of the new owner)
    /// @notice Event for logging the initiation of the ownership transfer process (nomination of the new owner)
    /// @param owner_ The current owner's address who initiated the transfer of ownership
    /// @param pendingOwner_ The address of the nominated new owner (pending owner)
    event TransferOwnershipInitiated(address indexed owner_, address indexed pendingOwner_);

    /// @dev Event for logging the initiation of the safe 2-step ownership relinquishment (renounce) mechanism
    /// @notice Event for logging the initiation of the safe 2-step mechanism for the ownership relinquishment (renounce) process
    /// @param owner_ The owner's address who initiated the 2-step ownership renounce process
    event RenounceProcessInitiated(address indexed owner_);

    /// @dev Event for logging the termination of the 2-step ownership relinquishment (renounce) process
    /// @notice Event for logging the termination of the 2-step ownership relinquishment (renounce) process
    /// @param owner_ The owner's address who terminated the 2-step ownership renounce process
    event RenounceProcessTerminated(address indexed owner_);

     // <<< CONSTRUCTOR >>>
    /// @dev The constructor runs only once during deployment, setting the owner of the contract to the EOA address (msg.sender) who propagates the contract bytecode registration transaction
    constructor() {
        _transferOwnership(msg.sender);
    }

     // <<< MODIFIERS >>>
    /// @dev This modifier absorbs the associated function's body when the caller is the owner, otherwise it reverts execution
    modifier onlyOwner {
        require(msg.sender == owner(), "Only the owner can call this function!");
        _;
    }

    /// @dev This modifier absorbs the associated function's body when the caller is not the owner, otherwise it reverts execution
    modifier onlyWhenNotOwner {
        require(msg.sender != owner(), "Caller must not be the owner!");
        _;
    }

     // <<< READ FUNCTIONS >>>
    /// @dev Retrieves the current owner's address
    /// @notice Retrieves the current owner's address
    /// @return Returns the address of the owner
    function owner() public view returns (address) {
        return _owner;
    }

    /// @dev Retrieves the pending owner's address
    /// @notice Retrieves the pending owner's address
    /// @return Returns the address of the pending (nominated) owner
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /// @dev Retrieves whether the 2-step ownership relinquishment (renounce) mechanism has been initiated or not
    /// @notice Retrieves whether the 2-step ownership relinquishment (renounce) mechanism has been initiated or not
    /// @return Returns a boolean flag indicating whether the 2-step ownership relinquishment (renounce) mechanism has been initiated or not
    function renounceUnlocked() public view returns (bool) {
        return _renounceUnlocked;
    }

     // <<< CORE OWNERSHIP CONTROL FUNCTIONS >>>
    /// @dev Sets the owner to the new owner
    /// @notice Sets the owner to the new owner
    /// @param newOwner_ The address of the new owner
    function _transferOwnership(address newOwner_) internal {
        address previousOwner = owner();
        _owner = newOwner_;
        emit OwnershipTransferCompleted(previousOwner, newOwner_);
    }

    /// @dev Sets the pending owner to the new pending owner
    /// @notice Sets the pending owner to the new pending owner
    /// @param newPendingOwner_ The address of the new pending owner
    function _setPendingOwner(address newPendingOwner_) internal {
        _pendingOwner = newPendingOwner_;
    }

    /// @dev Resets the pending owner to the default zero address
    /// @notice Resets the pending owner to the default zero address
    /// @return Returns true boolean if the reset of the pending owner was successful
    /// @custom:requirement-modifier Only the owner (admin) can call this function
    function resetPendingOwner() external onlyOwner returns (bool) {
        delete _pendingOwner;
        return true;
    }

    /// @dev Resets the pending owner to the default zero address
    /// @notice Resets the pending owner to the default zero address
    function _resetPendingOwner() internal {
        delete _pendingOwner;
    }

    /// @dev Handles the first step of the 2-step ownership transfer process (nomination phase)
    /// @notice Handles the first step of the 2-step ownership transfer process (nomination phase)
    /// @param newOwner_ The address of the nominated new owner (pending owner)
    /// @return Returns true boolean if the nomination phase of the ownership transfer was successful
    /// @custom:requirement-modifier Only the owner (admin) can call this function
    /// @custom:requirement-body The new owner cannot be the zero (burn) address
    /// @custom:requirement-body The new owner cannot be the current owner
    /// @custom:requirement-body The new owner cannot be the current pending (nominated) owner
    function transferOwnership(address newOwner_) external onlyOwner returns (bool) {
        require(newOwner_ != address(0));
        require(newOwner_ != owner());
        require(newOwner_ != pendingOwner());
        _setPendingOwner(newOwner_);
        emit TransferOwnershipInitiated(owner(), newOwner_);
        return true;
    }

    /// @dev Handles the second step of the 2-step ownership transfer process (acceptance phase)
    /// @notice Handles the second step of the 2-step ownership transfer process (acceptance phase)
    /// @return Returns true boolean if the ownership transfer's acceptance phase was successful
    /// @custom:requirement-body Only the pending owner can accept ownership
    function acceptOwnership() external returns (bool) {
        require(msg.sender == pendingOwner(), "Only the pending owner can accept ownership!");
        address sender = msg.sender;
        _transferOwnership(sender);
        _resetPendingOwner();
        return true;
    }

     // <<< OWNERSHIP RELINQUISHMENT FUNCTIONS >>>
    /// @dev Initiates and unlocks the 2-step ownership relinquishment feature
    /// @notice Initiates and unlocks the 2-step ownership relinquishment feature
    /// @return Returns true boolean if the initiation of the 2-step ownership relinquishment process was successful
    /// @custom:requirement-modifier Only the owner (admin) can call this function
    /// @custom:requirement-body Ownership relinquishment feature must be toggled off (locked)
    function startRenounceProcess() external onlyOwner returns (bool) {
        require(!renounceUnlocked());
        _renounceUnlocked = true;
        emit RenounceProcessInitiated(owner());
        return true;
    }

    /// @dev Terminates the 2-step ownership relinquishment process and locks the feature until it is unlocked again
    /// @notice Terminates the 2-step ownership relinquishment process and locks the feature until it is unlocked again
    /// @return Returns true boolean if the termination of the 2-step ownership relinquishment process was successful
    /// @custom:requirement-modifier Only the owner (admin) can call this function
    /// @custom:requirement-body Ownership relinquishment feature must be toggled on (unlocked)
    function terminateRenounceProcess() external onlyOwner returns (bool) {
        require(renounceUnlocked());
        _renounceUnlocked = false;
        emit RenounceProcessTerminated(owner());
        return true;
    }

    /// @dev Completes the 2-step ownership relinquishment process and renounces the ownership in an irreversible way
    /// @notice Completes the 2-step ownership relinquishment process and renounces the ownership in an irreversible way
    /// @return Returns true boolean if the 2-step ownership relinquishment process was completed successfully
    /// @custom:requirement-modifier Only the owner (admin) can call this function
    /// @custom:requirement-body Ownership relinquishment feature must be toggled on (unlocked) to complete the process
    function renounceOwnership() external onlyOwner returns (bool) {
        require(renounceUnlocked());
        _transferOwnership(address(0));
        _resetPendingOwner();
        return true;
    }
}