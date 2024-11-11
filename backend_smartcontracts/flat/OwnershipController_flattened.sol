// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Timelock guard contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract enables the timelock guard feature to enhance the security of critial operations
/// @dev This contract enables the timelock guard feature to enhance the security of critical operations
abstract contract TimelockGuard {

     // <<< STATE VARIABLES >>>
    /// @dev Constant that stores the time duration of the timelock delay (can be changed, no side-effects) (default: 10 days)
    uint256 private constant _DELAY = 10 days;

    /// @dev Constant that stores the time duration of the grace period (can be changed, no side-effects) (default: 1 days)
    uint256 private constant _GRACE_PERIOD = 1 days;

    /// @dev Stores the timestamp of the queue that has been initiated
    uint256 private _queueTime;

     // <<< EVENTS >>>
    /// @dev Event for logging when a new timelock queue was started
    /// @notice Event for logging when a new timelock queue was started
    event TimelockQueueStarted();

    /// @dev Event for logging when the timelock queue was reset
    /// @notice Event for logging when the timelock queue was reset
    event TimeLockQueueReset();

     // <<< MODIFIERS >>>
    /// @dev This modifier absorbs the associated function's body when all of the timelock guard requirements are met, otherwise it reverts execution
    /// @notice This modifier absorbs the associated function's body when all of the timelock guard requirements are met, otherwise it reverts execution
    /// @param blockTimestampAtCall_ The timestamp when the function call was made
    /// @custom:requirement-body A queue must be started before a timelock guarded function can be executed
    /// @custom:requirement-body The timestamp at the call must be greater or equal than the queue time + delay
    /// @custom:requirement-body The timestamp at the call must be less or equal than the queue time + delay + grace period
    modifier timelocked(uint256 blockTimestampAtCall_) {
        require(getQueueTime() > 0, "Queue not initiated!");
        require(blockTimestampAtCall_ >= (getQueueTime() + _DELAY), "Timelocked, wait!");
        require(blockTimestampAtCall_ <= (getQueueTime() + _DELAY + _GRACE_PERIOD), "Grade period expired!");
        _;
        _resetQueue();
    }

     // <<< READ FUNCTIONS >>>
    /// @dev Retrieves the queue timestamp
    /// @notice Retrieves the queue timestamp
    /// @return Returns the queue timestamp in epoch seconds
    function getQueueTime() public view returns (uint256) {
        return _queueTime;
    }

     // <<< TIMELOCK GUARD CORE FUNCTIONS >>>
    /// @dev Resets the current timelock countdown queue
    /// @notice Resets the current timelock countdown queue
    function _resetQueue() internal {
        delete _queueTime;
        emit TimeLockQueueReset();
    }

    /// @dev Starts a new timelock countdown queue
    /// @notice Starts a new timelock countdown queue
    function _startQueue() internal {
        _queueTime = block.timestamp;
        emit TimelockQueueStarted();
    }

    /// @dev Starts a new timelock countdown queue
    /// @notice Starts a new timelock countdown queue
    /// @return Returns true boolean flag if the queue was started successfully
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be done by the internal function '_startQueue'
    function startQueue() external virtual returns (bool);
}
// File: MultiSignatureGuard.sol


pragma solidity >=0.8.0;

/// @title Multi signature guard contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract enables the multi signature guard feature to enhance the security of critical operations
/// @dev This contract enables the multi signature guard feature to enhance the security of critical operations
abstract contract MultiSignatureGuard {

     // <<< STATE VARIABLES >>>
    /// @dev Stores the total number of signers (uint8: [0;(2**8)-1)]) (default: 7)
    uint8 private constant _TOTAL_SIGNERS = 7;

    /// @dev Stores the minimum number of signatures required for multi signature guarded function execution (fault tolerant signature threshold) (uint8: [0;(2**8)-1)]) (default: 5)
    uint8 private constant _REQUIRED_SIGNATURES = 5;

    /// @dev Stores the validity time duration of signatures (default: 15 minutes)
    uint256 private constant _SIGNATURE_VALIDITY_TIME = 15 minutes;

    /// @dev Stores the expiration time of signatures (block.timestamp at signing + _SIGNATURE_VALIDITY_TIME)
    uint256 private _signatureExpiryTime;

    /// @dev Stores the total number of unique valid signatures during collection
    uint8 private _currentSignatureCount;

    /// @dev Stores whether an address is a signer or not
    mapping(address => bool) private _isSigner;
    
    /// @dev Stores whether a signer has already signed in the current signature collection session or not
    mapping(address => bool) private _hasSigned;
    
    /// @dev Constant, fixed-size address array that stores all the valid signers
    address[7] private _signers = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,
        0x617F2E2fD72FD9D5503197092aC168c91465E7f2,
        0x17F6AD8Ef982297579C203069C1DbfFE4348c372,
        0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678
    ];

     // <<< EVENTS >>>
    /// @dev Event for logging when a valid signature is made
    /// @notice Event for logging when a valid signature is made
    /// @param signer_ The address of the signer that made the signature
    event SignatureRegistered(address signer_);

    /// @dev Event for logging when signatures are reset
    /// @notice Event for logging when signatures are reset
    event SignaturesReset();

    /// @dev Event for logging when signature validity countdown starts
    /// @notice Event for logging when signature validity countdown starts
    event SignatureValidityTimeCountdownStarted();

    /// @dev Event for logging when signatures are expired and reset
    /// @notice Event for logging when signatures are expired and reset
    event SignaturesExpiredAndReset();

     // <<< CONSTRUCTOR >>>
    /// @dev The constructor will run once during initial contract deployment, setting the valid signer set
    /// @custom:requirement-body The number of signers must be equal to the total signers constant
    /// @custom:requirement-body There must be no zero (burn) address in the valid signer set
    constructor() {
        require(_signers.length == _TOTAL_SIGNERS);
        for(uint8 i = 0; i < _TOTAL_SIGNERS; i++) {
            require(_signers[i] != address(0));
            _isSigner[_signers[i]] = true;
        }
    }

     // <<< MODIFIERS >>>
    /// @dev This modifier absorbs the associated function's body when the caller is a signer
    modifier onlySigner {
        require(isSigner(msg.sender), "Not a signer!");
        _;
    }

    /// @dev This modifier absorbs the associated function's body when the conditions of the multi signature guard security scheme are fulfilled
    /// @custom:requirement-body The number of valid signatures collected from signers must be greater or equal than the configured signature threshold
    /// @custom:requirement-body Signatures must not be expired
    modifier multiSignatureGuard {
        require(currentSignatureCount() >= _REQUIRED_SIGNATURES, "Not enough signatures!");
        require(block.timestamp <= getSignatureExpiryTime(), "Signatures have expired!");
        _;
        _resetAllSignatures();
    }

     // <<< READ FUNCTIONS >>>
    /// @dev Retrieves the current signature count
    /// @notice Retrieves the current signature count
    /// @return Returns the current signature count
    function currentSignatureCount() public view returns (uint8) {
        return _currentSignatureCount;
    }

    /// @dev Evaluates whether an address is in the valid signer set or not
    /// @notice Evaluates whether an address is in the valid signer set or not
    /// @param signer_ The address to be evaluated
    /// @return Returns a boolean literal indicating whether the passed address is a signer or not
    function isSigner(address signer_) public view returns (bool) {
        return _isSigner[signer_];
    }

    /// @dev Evaluates whether a signer has signed or not
    /// @notice Evaluates whether a signer has signed or not
    /// @param signer_ The address to be evaluated
    /// @return Returns a boolean literal indicating whether the passed address has signed or not
    function hasSigned(address signer_) public view returns (bool) {
        return _hasSigned[signer_];
    }

    /// @dev Retrieves the current signature expiry timestamp
    /// @notice Retrieves the current signature expiry timestamp
    /// @return Returns the current signature expiry timestamp
    function getSignatureExpiryTime() public view returns (uint256) {
        return _signatureExpiryTime;
    }

     // <<< CORE MULTI SIGNATURE FUNCTIONS >>>
    /// @dev Resets all signatures by setting the current signature count to 0 and invalidating all signatures made by signers
    /// @notice Resets all signatures by setting the current signature count to 0 and invalidating all signatures made by signers
    function _resetAllSignatures() internal {
        delete _currentSignatureCount;
        for(uint8 i = 0; i < _TOTAL_SIGNERS; i++) {
            _hasSigned[_signers[i]] = false;
        }
        emit SignaturesReset();
    }

    /// @dev Registers a valid signature if all conditions are fulfilled, manages the signature expiry mechanism
    /// @notice Registers a valid signature if all conditions are fulfilled, manages the signature expiry mechanism
    /// @return Returns true boolean literal if the signature registration was successful
    /// @custom:requirement-modifier The caller must be a signer
    /// @custom:requirement-body A signer can only sign once (in the same signature collection session)
    function registerSignature() external onlySigner returns (bool) {
        if(currentSignatureCount() == 0) {
            _signatureExpiryTime = block.timestamp + _SIGNATURE_VALIDITY_TIME;
            emit SignatureValidityTimeCountdownStarted();
        }
        
        if(block.timestamp > getSignatureExpiryTime()) {
            _resetAllSignatures();
            emit SignaturesExpiredAndReset();
            _signatureExpiryTime = block.timestamp + _SIGNATURE_VALIDITY_TIME;
            emit SignatureValidityTimeCountdownStarted();
        }
        
        require(!hasSigned(msg.sender));
        _hasSigned[msg.sender] = true;
        _currentSignatureCount++;

        emit SignatureRegistered(msg.sender);
        return true;
    }
}
// File: OwnershipController.sol


pragma solidity >=0.8.0;



/// @title Ownership controller contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract enables the safe control of ownership
/// @dev This contract enables the safe control of ownership
abstract contract OwnershipController is 
    TimelockGuard, 
    MultiSignatureGuard 
{

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
    event OwnershipTransferInitiated(address indexed owner_, address indexed pendingOwner_);

    /// @dev Event for logging the initiation of the safe 2-step ownership relinquishment (renounce) mechanism
    /// @notice Event for logging the initiation of the safe 2-step mechanism for the ownership relinquishment (renounce) process
    /// @param owner_ The owner's address who initiated the 2-step ownership renounce process
    event RenounceProcessInitiated(address indexed owner_);

    /// @dev Event for logging the termination of the 2-step ownership relinquishment (renounce) process
    /// @notice Event for logging the termination of the 2-step ownership relinquishment (renounce) process
    /// @param owner_ The owner's address who terminated the 2-step ownership renounce process
    event RenounceProcessTerminated(address indexed owner_);

    /// @dev Event for logging the completion of a social guardian ownership recovery process
    /// @notice Event for logging the completion of a social guardian ownership recovery process
    event SocialGuardianRecoveryCompleted();

     // <<< CONSTRUCTOR >>>
    /// @dev The constructor runs only once during deployment, setting the owner of the contract to the EOA address (msg.sender) who signs and propagates the contract bytecode registration transaction
    constructor() {
        _transferOwnership(msg.sender);
    }

     // <<< MODIFIERS >>>
    /// @dev This modifier absorbs the associated function's body when the caller is the owner, otherwise it reverts execution
    modifier onlyOwner {
        require(msg.sender == owner(), "Only owner!");
        _;
    }

    /// @dev This modifier absorbs the associated function's body when the caller is not the owner, otherwise it reverts execution
    modifier onlyWhenNotOwner {
        require(msg.sender != owner());
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

    /// @dev Starts a new timelock countdown queue
    /// @notice Starts a new timelock countdown queue
    /// @return Returns true boolean flag if the queue was started successfully
    /// @custom:requirement-modifier Only the owner (admin) can call this function
    /// @custom:requirement-modifier Multi signature guard protected function (unexpired valid signature threshold must be reached)
    function startQueue() external override onlyOwner multiSignatureGuard returns (bool) {
        super._startQueue();
        return true;
    }

    /// @dev Initiates a social recovery by a trusted guardian to regain ownership control in case of a lost or compromised private key
    /// @notice Initiates a social recovery by a trusted guardian to regain ownership control in case of a lost or compromised private key
    /// @param newOwner_ The address of the new owner for the replacement of the current owner
    /// @return Returns a true boolean flag if the social recovery process was completed successfully
    /// @custom:requirement-modifier Only one of the signers can call this function
    /// @custom:requirement-modifier Timelock guard protected function (timelock delay period must be passed and must be within the grace period)
    /// @custom:requirement-modifier Multi signature guard protected function (unexpired valid signature threshold must be reached)
    function socialGuardianRecovery(address newOwner_) external onlySigner timelocked(block.timestamp) multiSignatureGuard returns (bool) {
        _transferOwnership(newOwner_);
        _resetPendingOwner();
        emit SocialGuardianRecoveryCompleted();
        return true;
    }

    /// @dev Handles the first step of the 2-step ownership transfer process (nomination phase)
    /// @notice Handles the first step of the 2-step ownership transfer process (nomination phase)
    /// @param newOwner_ The address of the nominated new owner (pending owner)
    /// @return Returns true boolean if the nomination phase of the ownership transfer was successful
    /// @custom:requirement-modifier Only the owner (admin) can call this function
    /// @custom:requirement-modifier Timelock guard protected function (timelock delay period must be passed and must be within the grace period)
    /// @custom:requirement-modifier Multi signature guard protected function (unexpired valid signature threshold must be reached)
    /// @custom:requirement-body The new owner cannot be the zero (burn) address
    /// @custom:requirement-body The new owner cannot be the current owner
    /// @custom:requirement-body The new owner cannot be the current pending (nominated) owner
    function transferOwnership(address newOwner_) external onlyOwner timelocked(block.timestamp) multiSignatureGuard returns (bool) {
        require(newOwner_ != address(0));
        require(newOwner_ != owner());
        require(newOwner_ != pendingOwner());
        _setPendingOwner(newOwner_);
        emit OwnershipTransferInitiated(owner(), newOwner_);
        return true;
    }

    /// @dev Handles the second step of the 2-step ownership transfer process (acceptance phase)
    /// @notice Handles the second step of the 2-step ownership transfer process (acceptance phase)
    /// @return Returns true boolean if the ownership transfer's acceptance phase was successful
    /// @custom:requirement-body Only the pending owner can accept ownership
    function acceptOwnership() external returns (bool) {
        require(msg.sender == pendingOwner());
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
    /// @custom:requirement-modifier Timelock guard protected function (timelock delay period must be passed and must be within the grace period)
    /// @custom:requirement-modifier Multi signature guard protected function (unexpired valid signature threshold must be reached)
    /// @custom:requirement-body Ownership relinquishment feature must be toggled off (locked)
    function startRenounceProcess() external onlyOwner timelocked(block.timestamp) multiSignatureGuard returns (bool) {
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