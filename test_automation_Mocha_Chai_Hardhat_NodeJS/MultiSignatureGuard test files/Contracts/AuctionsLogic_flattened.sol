// SPDX-License-Identifier: MIT

// File: TimelockGuard.sol


pragma solidity >=0.8.0;

/// @title Timelock guard contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract enables the timelock guard feature to enhance the security of critial operations
/// @dev This contract enables the timelock guard feature to enhance the security of critical operations
abstract contract TimelockGuard {

     // <<< STATE VARIABLES >>>
    /// @dev Constant that stores the time duration of the timelock delay (can be changed, no side-effects) (default: 10 days)
    uint256 private constant _DELAY = 30 seconds;

    /// @dev Constant that stores the time duration of the grace period (can be changed, no side-effects) (default: 1 days)
    uint256 private constant _GRACE_PERIOD = 60 seconds;

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
        require(getQueueTime() > 0);
        require(blockTimestampAtCall_ >= (getQueueTime() + _DELAY));
        require(blockTimestampAtCall_ <= (getQueueTime() + _DELAY + _GRACE_PERIOD));
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
    uint256 private constant _SIGNATURE_VALIDITY_TIME = 900 seconds;

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
        require(currentSignatureCount() >= _REQUIRED_SIGNATURES);
        require(block.timestamp <= getSignatureExpiryTime());
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
    function socialGuardianRecovery(address newOwner_) external onlySigner multiSignatureGuard returns (bool) {
        require(owner() != address(0));
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
// File: CancellableAuctionController.sol


pragma solidity >=0.8.0;

/// @title Cancellable auction controller contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract enables cancellable auctions
/// @dev This contract enables cancellable auctions
abstract contract CancellableAuctionController {

     // <<< STATE VARIABLES >>>
    /// @dev Indicates whether an auction is cancellable or not
    mapping(bytes32 => bool) private _cancelSwitch;

    /// @dev Indicates whether a cancellable auction was cancalled or not
    mapping(bytes32 => bool) private _cancelled;

     // <<< EVENTS >>>
    /// @dev Event for logging when an auction has been configured as cancellable
    /// @notice Event for logging when an auction has been configured as cancellable
    /// @param auctionID_ The 256 bit hash identifier of the auction
    event AuctionConfiguredAsCancellable(bytes32 indexed auctionID_);

    /// @dev Event for logging when an auction has been cancelled
    /// @notice Event for logging when an auction has been cancelled
    /// @param auctionID_ The 256 bit hash identifier of the auction
    event AuctionCancelled(bytes32 indexed auctionID_);

     // <<< MODIFIERS >>>
    /// @dev This modifier absorbs the associated function's body when an auction is not cancelled, otherwise it reverts execution
    /// @param auctionID_ The 256 bit hash identifier of the auction
    modifier whenNotCancelled(bytes32 auctionID_) {
        require(!isCancelled(auctionID_), "Auction is cancelled!");
        _;
    }

     // <<< READ FUNCTIONS >>>
    /// @dev Retrieves whether a specific auction is cancellable (true) or not cancellable (false)
    /// @notice Retrieves whether a specific auction is cancellable (true) or not cancellable (false)
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a boolean flag indicating whether an auction is cancellable (true) or not cancellable (false)
    function isCancellable(bytes32 auctionID_) public view returns (bool) {
        return _cancelSwitch[auctionID_];
    }

    /// @dev Retrieves whether a specific cancellable auction is cancelled (true) or not cancelled (false)
    /// @notice Retrieves whether a specific cancellable auction is cancelled (true) or not cancelled (false)
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a boolean flag indicating whether a cancellable auction is cancelled (true) or not cancelled (false)
    function isCancelled(bytes32 auctionID_) public view returns (bool) {
        return _cancelled[auctionID_];
    }

     // <<< CORE CANCELLABLE AUCTION CONTROLLER FUNCTIONS >>>
    /// @dev Configures an auction as cancellable
    /// @notice Configures an auction as cancellable
    /// @param auctionID_ The 256 bit hash identifier of the auction
    function _configureAsCancellableAuction(bytes32 auctionID_) internal {
        _cancelSwitch[auctionID_] = true;
        emit AuctionConfiguredAsCancellable(auctionID_);
    }

    /// @dev Configures an auction as cancellable
    /// @notice Configures an auction as cancellable
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a true boolean literal if the configuration of an auction as cancellable was successful
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be executed by the internal function '_configureAsCancellableAuction'
    function configureAsCancellableAuction(bytes32 auctionID_) external virtual returns (bool);

    /// @dev Cancels a cancellable auction
    /// @notice Cancels a cancellable auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    function _cancelAuction(bytes32 auctionID_) internal {
        _cancelled[auctionID_] = true;
        emit AuctionCancelled(auctionID_);
    }

    /// @dev Cancels a cancellable auction
    /// @notice Cancels a cancellable auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a true boolean literal if the auction was cancelled successfully
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be executed by the internal function '_cancelAuction'
    function cancelAuction(bytes32 auctionID_) external virtual returns (bool);
}
// File: WhitelistAuctionController.sol


pragma solidity >=0.8.0;

/// @title Whitelist auction controller contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract enables whitelist (closed) auctions
/// @dev This contract enables whitelist (closed) auctions
abstract contract WhitelistAuctionController {
    
     // <<< STATE VARIABLES >>>
    /// @dev Indicates whether an auction is a whitelist auction or not
    mapping(bytes32 => bool) private _closedAuction;

    /// @dev Indicates whether an address is whitelisted or not in the respective whitelist auction
    mapping(bytes32 => mapping(address => bool)) private _whitelistedParticipants;
    
     // <<< EVENTS >>>
    /// @dev Event for logging the configuration of an auction as closed (whitelisted)
    /// @notice Event for logging the configuration of an auction as closed (whitelisted)
    /// @param auctionID_ The 256 bit hash identifier of the auction that was configured as closed (whitelisted)
    event AuctionConfiguredAsClosed(bytes32 indexed auctionID_);

    /// @dev Event for logging the whitelisting of participants
    /// @notice Event for logging the whitelisting of participants
    /// @param auctionID_ The 256 bit hash identifier of the closed (whitelisted) auction that the whitelisted participants has been registered to
    event AddedWhitelistedParticipants(bytes32 indexed auctionID_);

     // <<< CONFIGURATION FUNCTIONS >>>
    /// @dev Determines whether an auction is closed (whitelisted) or not, accesses the '_closedAuction' storage variable
    /// @notice Determines whether an auction is closed (whitelisted) or not
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Boolean flag indicating whether the auction is closed (true) or not (false)
    function closedAuction(bytes32 auctionID_) public view returns (bool) {
        return _closedAuction[auctionID_];
    }

    /// @dev Sets an auction to closed (whitelisted)
    /// @notice Sets an auction to closed (whitelisted)
    /// @param auctionID_ The 256 bit hash identifier of the auction
    function _configureAsClosedAuction(bytes32 auctionID_) internal {
        _closedAuction[auctionID_] = true;
        emit AuctionConfiguredAsClosed(auctionID_);
    }

    /// @dev Configure an auction as closed (whitelisted)
    /// @notice Configure an auction as closed (whitelisted)
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns true if the auction has been configured successfully as a closed (whitelisted) auction
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be executed by the internal function '_configureAsClosedAuction'
    function configureAsClosedAuction(bytes32 auctionID_) external virtual returns (bool);

     // <<< CORE WHITELISTING FUNCTIONS >>>
    /// @dev Checks whether an address is whitelisted or not at a certain closed (whitelisted) auction
    /// @notice Checks whether an address is whitelisted or not at a certain closed (whitelisted) auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participant_ The address of the participant we want to check whether it is whitelisted or not
    /// @return Boolean flag indicating whether the address is whitelisted (true) or not (false)
    function isWhitelisted(bytes32 auctionID_, address participant_) public view returns (bool) {
        return _whitelistedParticipants[auctionID_][participant_];
    }

    /// @dev Whitelists an array of addresses to be eligible for participation in a closed (whitelisted) auction
    /// @notice Whitelists a group of users to be eligible for participation in a closed (whitelisted) auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participants_ The array of addresses to be whitelisted
    function _whitelistParticipants(bytes32 auctionID_, address[] memory participants_) internal {
        for(uint256 i = 0; i < participants_.length; i++ ) {
            _whitelistedParticipants[auctionID_][participants_[i]] = true;
        }
        emit AddedWhitelistedParticipants(auctionID_);
    }

    /// @dev Whitelists an array of addresses to be eligible for participation in a closed (whitelisted) auction
    /// @notice Whitelists a group of users to be eligible for participation in a closed (whitelisted) auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participants_ The array of addresses to be whitelisted
    /// @return Returns true if the whitelisting of the passed addresses was successful
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be done by the internal function '_whitelistParticipants'
    function whitelistParticipants(bytes32 auctionID_, address[] memory participants_) external virtual returns (bool);
}
// File: EntryFeeController.sol


pragma solidity >=0.8.0;

/// @title Entry fee controller contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract enables the configuration and management of the entry fee feature for auctions
/// @dev This contract enables the configuration and management of the entry fee feature for auctions
abstract contract EntryFeeController {

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
// File: CircuitBreakerEmergencyController.sol


pragma solidity >=0.8.0;

/// @title Emergency circuit breaker controller contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract enables the emergency pause feature
/// @dev This contract enables the emergency pause feature
abstract contract CircuitBreakerEmergencyController {

     // <<< STATE VARIABLES >>>
    /// @dev Indicates whether the auction system's emergency pause is enabled (true) or not (false)
    bool private _paused;

     // <<< EVENTS >>>
    /// @dev Event for logging when the emergency pause feature has been toggled on
    /// @notice Event for logging when the emergency pause feature has been toggled on
    event EmergencyPauseTurnedOn();

    /// @dev Event for logging when the emergency pause feature has been toggled off
    /// @notice Event for logging when the emergency pause feature has been toggled off
    event EmergencyPauseTurnedOff();

     // <<< MODIFIERS >>>
    /// @dev This modifier absorbs the associated function's body when the system is not paused, otherwise it reverts execution
    modifier onlyWhenNotPaused {
        require(!isPaused(), "Paused!");
        _;
    }

    /// @dev This modifier absorbs the associated function's body when the system is paused, otherwise it reverts execution
    modifier onlyWhenPaused {
        require(isPaused(), "Not paused!");
        _;
    }

     // <<< READ FUNCTIONS >>>
    /// @dev Retrieves whether the system is currently paused (true) or not paused (false)
    /// @notice Retrieves whether the system is currently paused (true) or not paused (false)
    /// @return Returns a boolean flag indicating whether the system is paused (true) or not paused (false)
    function isPaused() public view returns (bool) {
        return _paused;
    }

     // <<< CORE EMERGENCY PAUSE CONTROLLER FUNCTIONS >>>
    /// @dev Turns emergency pause on
    /// @notice Turns emergency pause on
    /// @custom:requirement-modifier This function will only execute if the emergency pause is disabled
    function _turnEmergencyPauseOn() internal onlyWhenNotPaused {
         _paused = true;
        emit EmergencyPauseTurnedOn();
    }

    /// @dev Turns emergency pause on
    /// @notice Turns emergency pause on
    /// @return Returns true boolean if the emergency pause has been enabled successfully
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be executed by the internal function '_turnEmergencyPauseOn'
    function turnEmergencyPauseOn() external virtual returns (bool);

    /// @dev Turns emergency pause off
    /// @notice Turns emergency pause off
    /// @custom:requirement-modifier This function will only execute if the emergency pause is enabled
    function _turnEmergencyPauseOff() internal onlyWhenPaused {
        _paused = false;
        emit EmergencyPauseTurnedOff();
    }

    /// @dev Turns emergency pause off
    /// @notice Turns emergency pause off
    /// @return Returns true boolean if the emergency pause has been disabled successfully
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be executed by the internal function '_turnEmergencyPauseOff'
    function turnEmergencyPauseOff() external virtual returns (bool);
}
// File: BlacklistAuctionController.sol


pragma solidity >=0.8.0;

/// @title Blacklist auction controller contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract enables blacklist auctions
/// @dev This contract enables blacklist auctions
abstract contract BlacklistAuctionController {

     // <<< STATE VARIABLES >>>
    /// @dev Indicates whether an auction is configured as a blacklist auction or not
    mapping(bytes32 => bool) private _blacklistedAuction;

    /// @dev Indicates whether an address is blacklisted or not at a specific auction
    mapping(bytes32 => mapping(address => bool)) private _blacklistedParticipants;

     // <<< EVENTS >>>
    /// @dev Event for logging the configuration of blacklist auctions
    /// @notice Event for logging the configuration of blacklist auctions
    /// @param auctionID_ The 256 bit hash identifier of the auction
    event AuctionConfiguredAsBlacklisted(bytes32 indexed auctionID_);

    /// @dev Event for logging the blacklisting of participants
    /// @notice Event for logging the blacklisting of participants
    /// @param auctionID_ The 256 bit hash identifier of the auction
    event AddedBlacklistedParticipants(bytes32 indexed auctionID_);

     // <<< READ FUNCTIONS >>>
    /// @dev Retrieves whether an auction is configured as a blacklist auction or not
    /// @notice Retrieves whether an auction is configured as a blacklist auction or not
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a boolean flag that indicates whether an auction is configured as a blacklist auction or not
    function isBlacklistAuction(bytes32 auctionID_) public view returns (bool) {
        return _blacklistedAuction[auctionID_];
    }

    /// @dev Retrieves whether a participant is blacklisted or not at a blacklist auction
    /// @notice Retrieves whether a participant is blacklisted or not at a blacklist auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participant_ The address of the participant
    /// @return Returns a boolean flag indicating whether the participant is blacklisted or not at the specified blacklist auction
    function isBlacklistedParticipant(bytes32 auctionID_, address participant_) public view returns (bool) {
        return _blacklistedParticipants[auctionID_][participant_];
    }

     // <<< CORE BLACKLIST AUCTION FUNCTIONS >>>
    /// @dev Configures a blacklist auction
    /// @notice Configures a blacklist auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    function _configureAsBlacklistedAuction(bytes32 auctionID_) internal {
        _blacklistedAuction[auctionID_] = true;
        emit AuctionConfiguredAsBlacklisted(auctionID_);
    }

    /// @dev Configures a blacklist auction
    /// @notice Configures a blacklist auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns true boolean literal if the blacklist auction configuration was successful
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be executed by the internal function '_configureAsBlacklistedAuction'
    function configureAsBlacklistedAuction(bytes32 auctionID_) external virtual returns (bool);

    /// @dev Blacklists an array of addresses (participants) at the specified blacklist auction
    /// @notice Blacklists an array of addresses (participants) at the specified blacklist auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participants_ The addresses (participants) to be blacklisted at the specified blacklist auction
    function _blacklistParticipants(bytes32 auctionID_, address[] memory participants_) internal {
        for(uint256 i = 0; i < participants_.length; i++) {
            _blacklistedParticipants[auctionID_][participants_[i]] = true;
        }
        emit AddedBlacklistedParticipants(auctionID_);
    }

    /// @dev Blacklists an array of addresses (participants) at the specified blacklist auction
    /// @notice Blacklists an array of addresses (participants) at the specified blacklist auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participants_ The addresses (participants) to be blacklisted at the specified blacklist auction
    /// @return Returns true boolean literal if the addresses (participants) were successfully blacklisted at the specified auction
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be executed by the internal function '_blacklistParticipants'
    function blacklistParticipants(bytes32 auctionID_, address[] memory participants_) external virtual returns (bool);
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts (last updated v5.1.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;


/**
 * @dev Required interface of an ERC-721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC-721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC-721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.20;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

/**
 * @title ERC-721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC-721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/interfaces/draft-IERC6093.sol


// OpenZeppelin Contracts (last updated v5.1.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC-20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC-721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in ERC-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC-1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Utils.sol


// OpenZeppelin Contracts (last updated v5.3.0) (token/ERC721/utils/ERC721Utils.sol)

pragma solidity ^0.8.20;



/**
 * @dev Library that provide common ERC-721 utility functions.
 *
 * See https://eips.ethereum.org/EIPS/eip-721[ERC-721].
 *
 * _Available since v5.1._
 */
library ERC721Utils {
    /**
     * @dev Performs an acceptance check for the provided `operator` by calling {IERC721Receiver-onERC721Received}
     * on the `to` address. The `operator` is generally the address that initiated the token transfer (i.e. `msg.sender`).
     *
     * The acceptance call is not executed and treated as a no-op if the target address doesn't contain code (i.e. an EOA).
     * Otherwise, the recipient must implement {IERC721Receiver-onERC721Received} and return the acceptance magic value to accept
     * the transfer.
     */
    function checkOnERC721Received(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    // Token rejected
                    revert IERC721Errors.ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-IERC721Receiver implementer
                    revert IERC721Errors.ERC721InvalidReceiver(to);
                } else {
                    assembly ("memory-safe") {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/utils/Panic.sol


// OpenZeppelin Contracts (last updated v5.1.0) (utils/Panic.sol)

pragma solidity ^0.8.20;

/**
 * @dev Helper library for emitting standardized panic codes.
 *
 * ```solidity
 * contract Example {
 *      using Panic for uint256;
 *
 *      // Use any of the declared internal constants
 *      function foo() { Panic.GENERIC.panic(); }
 *
 *      // Alternatively
 *      function foo() { Panic.panic(Panic.GENERIC); }
 * }
 * ```
 *
 * Follows the list from https://github.com/ethereum/solidity/blob/v0.8.24/libsolutil/ErrorCodes.h[libsolutil].
 *
 * _Available since v5.1._
 */
// slither-disable-next-line unused-state
library Panic {
    /// @dev generic / unspecified error
    uint256 internal constant GENERIC = 0x00;
    /// @dev used by the assert() builtin
    uint256 internal constant ASSERT = 0x01;
    /// @dev arithmetic underflow or overflow
    uint256 internal constant UNDER_OVERFLOW = 0x11;
    /// @dev division or modulo by zero
    uint256 internal constant DIVISION_BY_ZERO = 0x12;
    /// @dev enum conversion error
    uint256 internal constant ENUM_CONVERSION_ERROR = 0x21;
    /// @dev invalid encoding in storage
    uint256 internal constant STORAGE_ENCODING_ERROR = 0x22;
    /// @dev empty array pop
    uint256 internal constant EMPTY_ARRAY_POP = 0x31;
    /// @dev array out of bounds access
    uint256 internal constant ARRAY_OUT_OF_BOUNDS = 0x32;
    /// @dev resource error (too large allocation or too large array)
    uint256 internal constant RESOURCE_ERROR = 0x41;
    /// @dev calling invalid internal function
    uint256 internal constant INVALID_INTERNAL_FUNCTION = 0x51;

    /// @dev Reverts with a panic code. Recommended to use with
    /// the internal constants with predefined codes.
    function panic(uint256 code) internal pure {
        assembly ("memory-safe") {
            mstore(0x00, 0x4e487b71)
            mstore(0x20, code)
            revert(0x1c, 0x24)
        }
    }
}

// File: @openzeppelin/contracts/utils/math/SafeCast.sol


// OpenZeppelin Contracts (last updated v5.1.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.20;

/**
 * @dev Wrappers over Solidity's uintXX/intXX/bool casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }

    /**
     * @dev Cast a boolean (false or true) to a uint256 (0 or 1) with no jump.
     */
    function toUint(bool b) internal pure returns (uint256 u) {
        assembly ("memory-safe") {
            u := iszero(iszero(b))
        }
    }
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v5.3.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;



/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Return the 512-bit addition of two uint256.
     *
     * The result is stored in two 256 variables such that sum = high * 2²⁵⁶ + low.
     */
    function add512(uint256 a, uint256 b) internal pure returns (uint256 high, uint256 low) {
        assembly ("memory-safe") {
            low := add(a, b)
            high := lt(low, a)
        }
    }

    /**
     * @dev Return the 512-bit multiplication of two uint256.
     *
     * The result is stored in two 256 variables such that product = high * 2²⁵⁶ + low.
     */
    function mul512(uint256 a, uint256 b) internal pure returns (uint256 high, uint256 low) {
        // 512-bit multiply [high low] = x * y. Compute the product mod 2²⁵⁶ and mod 2²⁵⁶ - 1, then use
        // the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = high * 2²⁵⁶ + low.
        assembly ("memory-safe") {
            let mm := mulmod(a, b, not(0))
            low := mul(a, b)
            high := sub(sub(mm, low), lt(mm, low))
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, with a success flag (no overflow).
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
        unchecked {
            uint256 c = a + b;
            success = c >= a;
            result = c * SafeCast.toUint(success);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with a success flag (no overflow).
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
        unchecked {
            uint256 c = a - b;
            success = c <= a;
            result = c * SafeCast.toUint(success);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with a success flag (no overflow).
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
        unchecked {
            uint256 c = a * b;
            assembly ("memory-safe") {
                // Only true when the multiplication doesn't overflow
                // (c / a == b) || (a == 0)
                success := or(eq(div(c, a), b), iszero(a))
            }
            // equivalent to: success ? c : 0
            result = c * SafeCast.toUint(success);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a success flag (no division by zero).
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
        unchecked {
            success = b > 0;
            assembly ("memory-safe") {
                // The `DIV` opcode returns zero when the denominator is 0.
                result := div(a, b)
            }
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a success flag (no division by zero).
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
        unchecked {
            success = b > 0;
            assembly ("memory-safe") {
                // The `MOD` opcode returns zero when the denominator is 0.
                result := mod(a, b)
            }
        }
    }

    /**
     * @dev Unsigned saturating addition, bounds to `2²⁵⁶ - 1` instead of overflowing.
     */
    function saturatingAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        (bool success, uint256 result) = tryAdd(a, b);
        return ternary(success, result, type(uint256).max);
    }

    /**
     * @dev Unsigned saturating subtraction, bounds to zero instead of overflowing.
     */
    function saturatingSub(uint256 a, uint256 b) internal pure returns (uint256) {
        (, uint256 result) = trySub(a, b);
        return result;
    }

    /**
     * @dev Unsigned saturating multiplication, bounds to `2²⁵⁶ - 1` instead of overflowing.
     */
    function saturatingMul(uint256 a, uint256 b) internal pure returns (uint256) {
        (bool success, uint256 result) = tryMul(a, b);
        return ternary(success, result, type(uint256).max);
    }

    /**
     * @dev Branchless ternary evaluation for `a ? b : c`. Gas costs are constant.
     *
     * IMPORTANT: This function may reduce bytecode size and consume less gas when used standalone.
     * However, the compiler may optimize Solidity ternary operations (i.e. `a ? b : c`) to only compute
     * one branch when needed, making this function more expensive.
     */
    function ternary(bool condition, uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            // branchless ternary works because:
            // b ^ (a ^ b) == a
            // b ^ 0 == b
            return b ^ ((a ^ b) * SafeCast.toUint(condition));
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return ternary(a > b, a, b);
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return ternary(a < b, a, b);
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            Panic.panic(Panic.DIVISION_BY_ZERO);
        }

        // The following calculation ensures accurate ceiling division without overflow.
        // Since a is non-zero, (a - 1) / b will not overflow.
        // The largest possible result occurs when (a - 1) / b is type(uint256).max,
        // but the largest value we can obtain is type(uint256).max - 1, which happens
        // when a = type(uint256).max and b = 1.
        unchecked {
            return SafeCast.toUint(a > 0) * ((a - 1) / b + 1);
        }
    }

    /**
     * @dev Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     *
     * Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            (uint256 high, uint256 low) = mul512(x, y);

            // Handle non-overflow cases, 256 by 256 division.
            if (high == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return low / denominator;
            }

            // Make sure the result is less than 2²⁵⁶. Also prevents denominator == 0.
            if (denominator <= high) {
                Panic.panic(ternary(denominator == 0, Panic.DIVISION_BY_ZERO, Panic.UNDER_OVERFLOW));
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [high low].
            uint256 remainder;
            assembly ("memory-safe") {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                high := sub(high, gt(remainder, low))
                low := sub(low, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly ("memory-safe") {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [high low] by twos.
                low := div(low, twos)

                // Flip twos such that it is 2²⁵⁶ / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from high into low.
            low |= high * twos;

            // Invert denominator mod 2²⁵⁶. Now that denominator is an odd number, it has an inverse modulo 2²⁵⁶ such
            // that denominator * inv ≡ 1 mod 2²⁵⁶. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv ≡ 1 mod 2⁴.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2⁸
            inverse *= 2 - denominator * inverse; // inverse mod 2¹⁶
            inverse *= 2 - denominator * inverse; // inverse mod 2³²
            inverse *= 2 - denominator * inverse; // inverse mod 2⁶⁴
            inverse *= 2 - denominator * inverse; // inverse mod 2¹²⁸
            inverse *= 2 - denominator * inverse; // inverse mod 2²⁵⁶

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2²⁵⁶. Since the preconditions guarantee that the outcome is
            // less than 2²⁵⁶, this is the final result. We don't need to compute the high bits of the result and high
            // is no longer required.
            result = low * inverse;
            return result;
        }
    }

    /**
     * @dev Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        return mulDiv(x, y, denominator) + SafeCast.toUint(unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0);
    }

    /**
     * @dev Calculates floor(x * y >> n) with full precision. Throws if result overflows a uint256.
     */
    function mulShr(uint256 x, uint256 y, uint8 n) internal pure returns (uint256 result) {
        unchecked {
            (uint256 high, uint256 low) = mul512(x, y);
            if (high >= 1 << n) {
                Panic.panic(Panic.UNDER_OVERFLOW);
            }
            return (high << (256 - n)) | (low >> n);
        }
    }

    /**
     * @dev Calculates x * y >> n with full precision, following the selected rounding direction.
     */
    function mulShr(uint256 x, uint256 y, uint8 n, Rounding rounding) internal pure returns (uint256) {
        return mulShr(x, y, n) + SafeCast.toUint(unsignedRoundsUp(rounding) && mulmod(x, y, 1 << n) > 0);
    }

    /**
     * @dev Calculate the modular multiplicative inverse of a number in Z/nZ.
     *
     * If n is a prime, then Z/nZ is a field. In that case all elements are inversible, except 0.
     * If n is not a prime, then Z/nZ is not a field, and some elements might not be inversible.
     *
     * If the input value is not inversible, 0 is returned.
     *
     * NOTE: If you know for sure that n is (big) a prime, it may be cheaper to use Fermat's little theorem and get the
     * inverse using `Math.modExp(a, n - 2, n)`. See {invModPrime}.
     */
    function invMod(uint256 a, uint256 n) internal pure returns (uint256) {
        unchecked {
            if (n == 0) return 0;

            // The inverse modulo is calculated using the Extended Euclidean Algorithm (iterative version)
            // Used to compute integers x and y such that: ax + ny = gcd(a, n).
            // When the gcd is 1, then the inverse of a modulo n exists and it's x.
            // ax + ny = 1
            // ax = 1 + (-y)n
            // ax ≡ 1 (mod n) # x is the inverse of a modulo n

            // If the remainder is 0 the gcd is n right away.
            uint256 remainder = a % n;
            uint256 gcd = n;

            // Therefore the initial coefficients are:
            // ax + ny = gcd(a, n) = n
            // 0a + 1n = n
            int256 x = 0;
            int256 y = 1;

            while (remainder != 0) {
                uint256 quotient = gcd / remainder;

                (gcd, remainder) = (
                    // The old remainder is the next gcd to try.
                    remainder,
                    // Compute the next remainder.
                    // Can't overflow given that (a % gcd) * (gcd // (a % gcd)) <= gcd
                    // where gcd is at most n (capped to type(uint256).max)
                    gcd - remainder * quotient
                );

                (x, y) = (
                    // Increment the coefficient of a.
                    y,
                    // Decrement the coefficient of n.
                    // Can overflow, but the result is casted to uint256 so that the
                    // next value of y is "wrapped around" to a value between 0 and n - 1.
                    x - y * int256(quotient)
                );
            }

            if (gcd != 1) return 0; // No inverse exists.
            return ternary(x < 0, n - uint256(-x), uint256(x)); // Wrap the result if it's negative.
        }
    }

    /**
     * @dev Variant of {invMod}. More efficient, but only works if `p` is known to be a prime greater than `2`.
     *
     * From https://en.wikipedia.org/wiki/Fermat%27s_little_theorem[Fermat's little theorem], we know that if p is
     * prime, then `a**(p-1) ≡ 1 mod p`. As a consequence, we have `a * a**(p-2) ≡ 1 mod p`, which means that
     * `a**(p-2)` is the modular multiplicative inverse of a in Fp.
     *
     * NOTE: this function does NOT check that `p` is a prime greater than `2`.
     */
    function invModPrime(uint256 a, uint256 p) internal view returns (uint256) {
        unchecked {
            return Math.modExp(a, p - 2, p);
        }
    }

    /**
     * @dev Returns the modular exponentiation of the specified base, exponent and modulus (b ** e % m)
     *
     * Requirements:
     * - modulus can't be zero
     * - underlying staticcall to precompile must succeed
     *
     * IMPORTANT: The result is only valid if the underlying call succeeds. When using this function, make
     * sure the chain you're using it on supports the precompiled contract for modular exponentiation
     * at address 0x05 as specified in https://eips.ethereum.org/EIPS/eip-198[EIP-198]. Otherwise,
     * the underlying function will succeed given the lack of a revert, but the result may be incorrectly
     * interpreted as 0.
     */
    function modExp(uint256 b, uint256 e, uint256 m) internal view returns (uint256) {
        (bool success, uint256 result) = tryModExp(b, e, m);
        if (!success) {
            Panic.panic(Panic.DIVISION_BY_ZERO);
        }
        return result;
    }

    /**
     * @dev Returns the modular exponentiation of the specified base, exponent and modulus (b ** e % m).
     * It includes a success flag indicating if the operation succeeded. Operation will be marked as failed if trying
     * to operate modulo 0 or if the underlying precompile reverted.
     *
     * IMPORTANT: The result is only valid if the success flag is true. When using this function, make sure the chain
     * you're using it on supports the precompiled contract for modular exponentiation at address 0x05 as specified in
     * https://eips.ethereum.org/EIPS/eip-198[EIP-198]. Otherwise, the underlying function will succeed given the lack
     * of a revert, but the result may be incorrectly interpreted as 0.
     */
    function tryModExp(uint256 b, uint256 e, uint256 m) internal view returns (bool success, uint256 result) {
        if (m == 0) return (false, 0);
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            // | Offset    | Content    | Content (Hex)                                                      |
            // |-----------|------------|--------------------------------------------------------------------|
            // | 0x00:0x1f | size of b  | 0x0000000000000000000000000000000000000000000000000000000000000020 |
            // | 0x20:0x3f | size of e  | 0x0000000000000000000000000000000000000000000000000000000000000020 |
            // | 0x40:0x5f | size of m  | 0x0000000000000000000000000000000000000000000000000000000000000020 |
            // | 0x60:0x7f | value of b | 0x<.............................................................b> |
            // | 0x80:0x9f | value of e | 0x<.............................................................e> |
            // | 0xa0:0xbf | value of m | 0x<.............................................................m> |
            mstore(ptr, 0x20)
            mstore(add(ptr, 0x20), 0x20)
            mstore(add(ptr, 0x40), 0x20)
            mstore(add(ptr, 0x60), b)
            mstore(add(ptr, 0x80), e)
            mstore(add(ptr, 0xa0), m)

            // Given the result < m, it's guaranteed to fit in 32 bytes,
            // so we can use the memory scratch space located at offset 0.
            success := staticcall(gas(), 0x05, ptr, 0xc0, 0x00, 0x20)
            result := mload(0x00)
        }
    }

    /**
     * @dev Variant of {modExp} that supports inputs of arbitrary length.
     */
    function modExp(bytes memory b, bytes memory e, bytes memory m) internal view returns (bytes memory) {
        (bool success, bytes memory result) = tryModExp(b, e, m);
        if (!success) {
            Panic.panic(Panic.DIVISION_BY_ZERO);
        }
        return result;
    }

    /**
     * @dev Variant of {tryModExp} that supports inputs of arbitrary length.
     */
    function tryModExp(
        bytes memory b,
        bytes memory e,
        bytes memory m
    ) internal view returns (bool success, bytes memory result) {
        if (_zeroBytes(m)) return (false, new bytes(0));

        uint256 mLen = m.length;

        // Encode call args in result and move the free memory pointer
        result = abi.encodePacked(b.length, e.length, mLen, b, e, m);

        assembly ("memory-safe") {
            let dataPtr := add(result, 0x20)
            // Write result on top of args to avoid allocating extra memory.
            success := staticcall(gas(), 0x05, dataPtr, mload(result), dataPtr, mLen)
            // Overwrite the length.
            // result.length > returndatasize() is guaranteed because returndatasize() == m.length
            mstore(result, mLen)
            // Set the memory pointer after the returned data.
            mstore(0x40, add(dataPtr, mLen))
        }
    }

    /**
     * @dev Returns whether the provided byte array is zero.
     */
    function _zeroBytes(bytes memory byteArray) private pure returns (bool) {
        for (uint256 i = 0; i < byteArray.length; ++i) {
            if (byteArray[i] != 0) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * This method is based on Newton's method for computing square roots; the algorithm is restricted to only
     * using integer operations.
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        unchecked {
            // Take care of easy edge cases when a == 0 or a == 1
            if (a <= 1) {
                return a;
            }

            // In this function, we use Newton's method to get a root of `f(x) := x² - a`. It involves building a
            // sequence x_n that converges toward sqrt(a). For each iteration x_n, we also define the error between
            // the current value as `ε_n = | x_n - sqrt(a) |`.
            //
            // For our first estimation, we consider `e` the smallest power of 2 which is bigger than the square root
            // of the target. (i.e. `2**(e-1) ≤ sqrt(a) < 2**e`). We know that `e ≤ 128` because `(2¹²⁸)² = 2²⁵⁶` is
            // bigger than any uint256.
            //
            // By noticing that
            // `2**(e-1) ≤ sqrt(a) < 2**e → (2**(e-1))² ≤ a < (2**e)² → 2**(2*e-2) ≤ a < 2**(2*e)`
            // we can deduce that `e - 1` is `log2(a) / 2`. We can thus compute `x_n = 2**(e-1)` using a method similar
            // to the msb function.
            uint256 aa = a;
            uint256 xn = 1;

            if (aa >= (1 << 128)) {
                aa >>= 128;
                xn <<= 64;
            }
            if (aa >= (1 << 64)) {
                aa >>= 64;
                xn <<= 32;
            }
            if (aa >= (1 << 32)) {
                aa >>= 32;
                xn <<= 16;
            }
            if (aa >= (1 << 16)) {
                aa >>= 16;
                xn <<= 8;
            }
            if (aa >= (1 << 8)) {
                aa >>= 8;
                xn <<= 4;
            }
            if (aa >= (1 << 4)) {
                aa >>= 4;
                xn <<= 2;
            }
            if (aa >= (1 << 2)) {
                xn <<= 1;
            }

            // We now have x_n such that `x_n = 2**(e-1) ≤ sqrt(a) < 2**e = 2 * x_n`. This implies ε_n ≤ 2**(e-1).
            //
            // We can refine our estimation by noticing that the middle of that interval minimizes the error.
            // If we move x_n to equal 2**(e-1) + 2**(e-2), then we reduce the error to ε_n ≤ 2**(e-2).
            // This is going to be our x_0 (and ε_0)
            xn = (3 * xn) >> 1; // ε_0 := | x_0 - sqrt(a) | ≤ 2**(e-2)

            // From here, Newton's method give us:
            // x_{n+1} = (x_n + a / x_n) / 2
            //
            // One should note that:
            // x_{n+1}² - a = ((x_n + a / x_n) / 2)² - a
            //              = ((x_n² + a) / (2 * x_n))² - a
            //              = (x_n⁴ + 2 * a * x_n² + a²) / (4 * x_n²) - a
            //              = (x_n⁴ + 2 * a * x_n² + a² - 4 * a * x_n²) / (4 * x_n²)
            //              = (x_n⁴ - 2 * a * x_n² + a²) / (4 * x_n²)
            //              = (x_n² - a)² / (2 * x_n)²
            //              = ((x_n² - a) / (2 * x_n))²
            //              ≥ 0
            // Which proves that for all n ≥ 1, sqrt(a) ≤ x_n
            //
            // This gives us the proof of quadratic convergence of the sequence:
            // ε_{n+1} = | x_{n+1} - sqrt(a) |
            //         = | (x_n + a / x_n) / 2 - sqrt(a) |
            //         = | (x_n² + a - 2*x_n*sqrt(a)) / (2 * x_n) |
            //         = | (x_n - sqrt(a))² / (2 * x_n) |
            //         = | ε_n² / (2 * x_n) |
            //         = ε_n² / | (2 * x_n) |
            //
            // For the first iteration, we have a special case where x_0 is known:
            // ε_1 = ε_0² / | (2 * x_0) |
            //     ≤ (2**(e-2))² / (2 * (2**(e-1) + 2**(e-2)))
            //     ≤ 2**(2*e-4) / (3 * 2**(e-1))
            //     ≤ 2**(e-3) / 3
            //     ≤ 2**(e-3-log2(3))
            //     ≤ 2**(e-4.5)
            //
            // For the following iterations, we use the fact that, 2**(e-1) ≤ sqrt(a) ≤ x_n:
            // ε_{n+1} = ε_n² / | (2 * x_n) |
            //         ≤ (2**(e-k))² / (2 * 2**(e-1))
            //         ≤ 2**(2*e-2*k) / 2**e
            //         ≤ 2**(e-2*k)
            xn = (xn + a / xn) >> 1; // ε_1 := | x_1 - sqrt(a) | ≤ 2**(e-4.5)  -- special case, see above
            xn = (xn + a / xn) >> 1; // ε_2 := | x_2 - sqrt(a) | ≤ 2**(e-9)    -- general case with k = 4.5
            xn = (xn + a / xn) >> 1; // ε_3 := | x_3 - sqrt(a) | ≤ 2**(e-18)   -- general case with k = 9
            xn = (xn + a / xn) >> 1; // ε_4 := | x_4 - sqrt(a) | ≤ 2**(e-36)   -- general case with k = 18
            xn = (xn + a / xn) >> 1; // ε_5 := | x_5 - sqrt(a) | ≤ 2**(e-72)   -- general case with k = 36
            xn = (xn + a / xn) >> 1; // ε_6 := | x_6 - sqrt(a) | ≤ 2**(e-144)  -- general case with k = 72

            // Because e ≤ 128 (as discussed during the first estimation phase), we know have reached a precision
            // ε_6 ≤ 2**(e-144) < 1. Given we're operating on integers, then we can ensure that xn is now either
            // sqrt(a) or sqrt(a) + 1.
            return xn - SafeCast.toUint(xn > a / xn);
        }
    }

    /**
     * @dev Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + SafeCast.toUint(unsignedRoundsUp(rounding) && result * result < a);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 x) internal pure returns (uint256 r) {
        // If value has upper 128 bits set, log2 result is at least 128
        r = SafeCast.toUint(x > 0xffffffffffffffffffffffffffffffff) << 7;
        // If upper 64 bits of 128-bit half set, add 64 to result
        r |= SafeCast.toUint((x >> r) > 0xffffffffffffffff) << 6;
        // If upper 32 bits of 64-bit half set, add 32 to result
        r |= SafeCast.toUint((x >> r) > 0xffffffff) << 5;
        // If upper 16 bits of 32-bit half set, add 16 to result
        r |= SafeCast.toUint((x >> r) > 0xffff) << 4;
        // If upper 8 bits of 16-bit half set, add 8 to result
        r |= SafeCast.toUint((x >> r) > 0xff) << 3;
        // If upper 4 bits of 8-bit half set, add 4 to result
        r |= SafeCast.toUint((x >> r) > 0xf) << 2;

        // Shifts value right by the current result and use it as an index into this lookup table:
        //
        // | x (4 bits) |  index  | table[index] = MSB position |
        // |------------|---------|-----------------------------|
        // |    0000    |    0    |        table[0] = 0         |
        // |    0001    |    1    |        table[1] = 0         |
        // |    0010    |    2    |        table[2] = 1         |
        // |    0011    |    3    |        table[3] = 1         |
        // |    0100    |    4    |        table[4] = 2         |
        // |    0101    |    5    |        table[5] = 2         |
        // |    0110    |    6    |        table[6] = 2         |
        // |    0111    |    7    |        table[7] = 2         |
        // |    1000    |    8    |        table[8] = 3         |
        // |    1001    |    9    |        table[9] = 3         |
        // |    1010    |   10    |        table[10] = 3        |
        // |    1011    |   11    |        table[11] = 3        |
        // |    1100    |   12    |        table[12] = 3        |
        // |    1101    |   13    |        table[13] = 3        |
        // |    1110    |   14    |        table[14] = 3        |
        // |    1111    |   15    |        table[15] = 3        |
        //
        // The lookup table is represented as a 32-byte value with the MSB positions for 0-15 in the last 16 bytes.
        assembly ("memory-safe") {
            r := or(r, byte(shr(r, x), 0x0000010102020202030303030303030300000000000000000000000000000000))
        }
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + SafeCast.toUint(unsignedRoundsUp(rounding) && 1 << result < value);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + SafeCast.toUint(unsignedRoundsUp(rounding) && 10 ** result < value);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 x) internal pure returns (uint256 r) {
        // If value has upper 128 bits set, log2 result is at least 128
        r = SafeCast.toUint(x > 0xffffffffffffffffffffffffffffffff) << 7;
        // If upper 64 bits of 128-bit half set, add 64 to result
        r |= SafeCast.toUint((x >> r) > 0xffffffffffffffff) << 6;
        // If upper 32 bits of 64-bit half set, add 32 to result
        r |= SafeCast.toUint((x >> r) > 0xffffffff) << 5;
        // If upper 16 bits of 32-bit half set, add 16 to result
        r |= SafeCast.toUint((x >> r) > 0xffff) << 4;
        // Add 1 if upper 8 bits of 16-bit half set, and divide accumulated result by 8
        return (r >> 3) | SafeCast.toUint((x >> r) > 0xff);
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + SafeCast.toUint(unsignedRoundsUp(rounding) && 1 << (result << 3) < value);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// File: @openzeppelin/contracts/utils/math/SignedMath.sol


// OpenZeppelin Contracts (last updated v5.1.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;


/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Branchless ternary evaluation for `a ? b : c`. Gas costs are constant.
     *
     * IMPORTANT: This function may reduce bytecode size and consume less gas when used standalone.
     * However, the compiler may optimize Solidity ternary operations (i.e. `a ? b : c`) to only compute
     * one branch when needed, making this function more expensive.
     */
    function ternary(bool condition, int256 a, int256 b) internal pure returns (int256) {
        unchecked {
            // branchless ternary works because:
            // b ^ (a ^ b) == a
            // b ^ 0 == b
            return b ^ ((a ^ b) * int256(SafeCast.toUint(condition)));
        }
    }

    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return ternary(a > b, a, b);
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return ternary(a < b, a, b);
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // Formula from the "Bit Twiddling Hacks" by Sean Eron Anderson.
            // Since `n` is a signed integer, the generated bytecode will use the SAR opcode to perform the right shift,
            // taking advantage of the most significant (or "sign" bit) in two's complement representation.
            // This opcode adds new most significant bits set to the value of the previous most significant bit. As a result,
            // the mask will either be `bytes32(0)` (if n is positive) or `~bytes32(0)` (if n is negative).
            int256 mask = n >> 255;

            // A `bytes32(0)` mask leaves the input unchanged, while a `~bytes32(0)` mask complements it.
            return uint256((n + mask) ^ mask);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v5.3.0) (utils/Strings.sol)

pragma solidity ^0.8.20;




/**
 * @dev String operations.
 */
library Strings {
    using SafeCast for *;

    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;
    uint256 private constant SPECIAL_CHARS_LOOKUP =
        (1 << 0x08) | // backspace
            (1 << 0x09) | // tab
            (1 << 0x0a) | // newline
            (1 << 0x0c) | // form feed
            (1 << 0x0d) | // carriage return
            (1 << 0x22) | // double quote
            (1 << 0x5c); // backslash

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev The string being parsed contains characters that are not in scope of the given base.
     */
    error StringsInvalidChar();

    /**
     * @dev The string being parsed is not a properly formatted address.
     */
    error StringsInvalidAddressFormat();

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            assembly ("memory-safe") {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                assembly ("memory-safe") {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its checksummed ASCII `string` hexadecimal
     * representation, according to EIP-55.
     */
    function toChecksumHexString(address addr) internal pure returns (string memory) {
        bytes memory buffer = bytes(toHexString(addr));

        // hash the hex part of buffer (skip length + 2 bytes, length 40)
        uint256 hashValue;
        assembly ("memory-safe") {
            hashValue := shr(96, keccak256(add(buffer, 0x22), 40))
        }

        for (uint256 i = 41; i > 1; --i) {
            // possible values for buffer[i] are 48 (0) to 57 (9) and 97 (a) to 102 (f)
            if (hashValue & 0xf > 7 && uint8(buffer[i]) > 96) {
                // case shift by xoring with 0x20
                buffer[i] ^= 0x20;
            }
            hashValue >>= 4;
        }
        return string(buffer);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }

    /**
     * @dev Parse a decimal string and returns the value as a `uint256`.
     *
     * Requirements:
     * - The string must be formatted as `[0-9]*`
     * - The result must fit into an `uint256` type
     */
    function parseUint(string memory input) internal pure returns (uint256) {
        return parseUint(input, 0, bytes(input).length);
    }

    /**
     * @dev Variant of {parseUint-string} that parses a substring of `input` located between position `begin` (included) and
     * `end` (excluded).
     *
     * Requirements:
     * - The substring must be formatted as `[0-9]*`
     * - The result must fit into an `uint256` type
     */
    function parseUint(string memory input, uint256 begin, uint256 end) internal pure returns (uint256) {
        (bool success, uint256 value) = tryParseUint(input, begin, end);
        if (!success) revert StringsInvalidChar();
        return value;
    }

    /**
     * @dev Variant of {parseUint-string} that returns false if the parsing fails because of an invalid character.
     *
     * NOTE: This function will revert if the result does not fit in a `uint256`.
     */
    function tryParseUint(string memory input) internal pure returns (bool success, uint256 value) {
        return _tryParseUintUncheckedBounds(input, 0, bytes(input).length);
    }

    /**
     * @dev Variant of {parseUint-string-uint256-uint256} that returns false if the parsing fails because of an invalid
     * character.
     *
     * NOTE: This function will revert if the result does not fit in a `uint256`.
     */
    function tryParseUint(
        string memory input,
        uint256 begin,
        uint256 end
    ) internal pure returns (bool success, uint256 value) {
        if (end > bytes(input).length || begin > end) return (false, 0);
        return _tryParseUintUncheckedBounds(input, begin, end);
    }

    /**
     * @dev Implementation of {tryParseUint-string-uint256-uint256} that does not check bounds. Caller should make sure that
     * `begin <= end <= input.length`. Other inputs would result in undefined behavior.
     */
    function _tryParseUintUncheckedBounds(
        string memory input,
        uint256 begin,
        uint256 end
    ) private pure returns (bool success, uint256 value) {
        bytes memory buffer = bytes(input);

        uint256 result = 0;
        for (uint256 i = begin; i < end; ++i) {
            uint8 chr = _tryParseChr(bytes1(_unsafeReadBytesOffset(buffer, i)));
            if (chr > 9) return (false, 0);
            result *= 10;
            result += chr;
        }
        return (true, result);
    }

    /**
     * @dev Parse a decimal string and returns the value as a `int256`.
     *
     * Requirements:
     * - The string must be formatted as `[-+]?[0-9]*`
     * - The result must fit in an `int256` type.
     */
    function parseInt(string memory input) internal pure returns (int256) {
        return parseInt(input, 0, bytes(input).length);
    }

    /**
     * @dev Variant of {parseInt-string} that parses a substring of `input` located between position `begin` (included) and
     * `end` (excluded).
     *
     * Requirements:
     * - The substring must be formatted as `[-+]?[0-9]*`
     * - The result must fit in an `int256` type.
     */
    function parseInt(string memory input, uint256 begin, uint256 end) internal pure returns (int256) {
        (bool success, int256 value) = tryParseInt(input, begin, end);
        if (!success) revert StringsInvalidChar();
        return value;
    }

    /**
     * @dev Variant of {parseInt-string} that returns false if the parsing fails because of an invalid character or if
     * the result does not fit in a `int256`.
     *
     * NOTE: This function will revert if the absolute value of the result does not fit in a `uint256`.
     */
    function tryParseInt(string memory input) internal pure returns (bool success, int256 value) {
        return _tryParseIntUncheckedBounds(input, 0, bytes(input).length);
    }

    uint256 private constant ABS_MIN_INT256 = 2 ** 255;

    /**
     * @dev Variant of {parseInt-string-uint256-uint256} that returns false if the parsing fails because of an invalid
     * character or if the result does not fit in a `int256`.
     *
     * NOTE: This function will revert if the absolute value of the result does not fit in a `uint256`.
     */
    function tryParseInt(
        string memory input,
        uint256 begin,
        uint256 end
    ) internal pure returns (bool success, int256 value) {
        if (end > bytes(input).length || begin > end) return (false, 0);
        return _tryParseIntUncheckedBounds(input, begin, end);
    }

    /**
     * @dev Implementation of {tryParseInt-string-uint256-uint256} that does not check bounds. Caller should make sure that
     * `begin <= end <= input.length`. Other inputs would result in undefined behavior.
     */
    function _tryParseIntUncheckedBounds(
        string memory input,
        uint256 begin,
        uint256 end
    ) private pure returns (bool success, int256 value) {
        bytes memory buffer = bytes(input);

        // Check presence of a negative sign.
        bytes1 sign = begin == end ? bytes1(0) : bytes1(_unsafeReadBytesOffset(buffer, begin)); // don't do out-of-bound (possibly unsafe) read if sub-string is empty
        bool positiveSign = sign == bytes1("+");
        bool negativeSign = sign == bytes1("-");
        uint256 offset = (positiveSign || negativeSign).toUint();

        (bool absSuccess, uint256 absValue) = tryParseUint(input, begin + offset, end);

        if (absSuccess && absValue < ABS_MIN_INT256) {
            return (true, negativeSign ? -int256(absValue) : int256(absValue));
        } else if (absSuccess && negativeSign && absValue == ABS_MIN_INT256) {
            return (true, type(int256).min);
        } else return (false, 0);
    }

    /**
     * @dev Parse a hexadecimal string (with or without "0x" prefix), and returns the value as a `uint256`.
     *
     * Requirements:
     * - The string must be formatted as `(0x)?[0-9a-fA-F]*`
     * - The result must fit in an `uint256` type.
     */
    function parseHexUint(string memory input) internal pure returns (uint256) {
        return parseHexUint(input, 0, bytes(input).length);
    }

    /**
     * @dev Variant of {parseHexUint-string} that parses a substring of `input` located between position `begin` (included) and
     * `end` (excluded).
     *
     * Requirements:
     * - The substring must be formatted as `(0x)?[0-9a-fA-F]*`
     * - The result must fit in an `uint256` type.
     */
    function parseHexUint(string memory input, uint256 begin, uint256 end) internal pure returns (uint256) {
        (bool success, uint256 value) = tryParseHexUint(input, begin, end);
        if (!success) revert StringsInvalidChar();
        return value;
    }

    /**
     * @dev Variant of {parseHexUint-string} that returns false if the parsing fails because of an invalid character.
     *
     * NOTE: This function will revert if the result does not fit in a `uint256`.
     */
    function tryParseHexUint(string memory input) internal pure returns (bool success, uint256 value) {
        return _tryParseHexUintUncheckedBounds(input, 0, bytes(input).length);
    }

    /**
     * @dev Variant of {parseHexUint-string-uint256-uint256} that returns false if the parsing fails because of an
     * invalid character.
     *
     * NOTE: This function will revert if the result does not fit in a `uint256`.
     */
    function tryParseHexUint(
        string memory input,
        uint256 begin,
        uint256 end
    ) internal pure returns (bool success, uint256 value) {
        if (end > bytes(input).length || begin > end) return (false, 0);
        return _tryParseHexUintUncheckedBounds(input, begin, end);
    }

    /**
     * @dev Implementation of {tryParseHexUint-string-uint256-uint256} that does not check bounds. Caller should make sure that
     * `begin <= end <= input.length`. Other inputs would result in undefined behavior.
     */
    function _tryParseHexUintUncheckedBounds(
        string memory input,
        uint256 begin,
        uint256 end
    ) private pure returns (bool success, uint256 value) {
        bytes memory buffer = bytes(input);

        // skip 0x prefix if present
        bool hasPrefix = (end > begin + 1) && bytes2(_unsafeReadBytesOffset(buffer, begin)) == bytes2("0x"); // don't do out-of-bound (possibly unsafe) read if sub-string is empty
        uint256 offset = hasPrefix.toUint() * 2;

        uint256 result = 0;
        for (uint256 i = begin + offset; i < end; ++i) {
            uint8 chr = _tryParseChr(bytes1(_unsafeReadBytesOffset(buffer, i)));
            if (chr > 15) return (false, 0);
            result *= 16;
            unchecked {
                // Multiplying by 16 is equivalent to a shift of 4 bits (with additional overflow check).
                // This guarantees that adding a value < 16 will not cause an overflow, hence the unchecked.
                result += chr;
            }
        }
        return (true, result);
    }

    /**
     * @dev Parse a hexadecimal string (with or without "0x" prefix), and returns the value as an `address`.
     *
     * Requirements:
     * - The string must be formatted as `(0x)?[0-9a-fA-F]{40}`
     */
    function parseAddress(string memory input) internal pure returns (address) {
        return parseAddress(input, 0, bytes(input).length);
    }

    /**
     * @dev Variant of {parseAddress-string} that parses a substring of `input` located between position `begin` (included) and
     * `end` (excluded).
     *
     * Requirements:
     * - The substring must be formatted as `(0x)?[0-9a-fA-F]{40}`
     */
    function parseAddress(string memory input, uint256 begin, uint256 end) internal pure returns (address) {
        (bool success, address value) = tryParseAddress(input, begin, end);
        if (!success) revert StringsInvalidAddressFormat();
        return value;
    }

    /**
     * @dev Variant of {parseAddress-string} that returns false if the parsing fails because the input is not a properly
     * formatted address. See {parseAddress-string} requirements.
     */
    function tryParseAddress(string memory input) internal pure returns (bool success, address value) {
        return tryParseAddress(input, 0, bytes(input).length);
    }

    /**
     * @dev Variant of {parseAddress-string-uint256-uint256} that returns false if the parsing fails because input is not a properly
     * formatted address. See {parseAddress-string-uint256-uint256} requirements.
     */
    function tryParseAddress(
        string memory input,
        uint256 begin,
        uint256 end
    ) internal pure returns (bool success, address value) {
        if (end > bytes(input).length || begin > end) return (false, address(0));

        bool hasPrefix = (end > begin + 1) && bytes2(_unsafeReadBytesOffset(bytes(input), begin)) == bytes2("0x"); // don't do out-of-bound (possibly unsafe) read if sub-string is empty
        uint256 expectedLength = 40 + hasPrefix.toUint() * 2;

        // check that input is the correct length
        if (end - begin == expectedLength) {
            // length guarantees that this does not overflow, and value is at most type(uint160).max
            (bool s, uint256 v) = _tryParseHexUintUncheckedBounds(input, begin, end);
            return (s, address(uint160(v)));
        } else {
            return (false, address(0));
        }
    }

    function _tryParseChr(bytes1 chr) private pure returns (uint8) {
        uint8 value = uint8(chr);

        // Try to parse `chr`:
        // - Case 1: [0-9]
        // - Case 2: [a-f]
        // - Case 3: [A-F]
        // - otherwise not supported
        unchecked {
            if (value > 47 && value < 58) value -= 48;
            else if (value > 96 && value < 103) value -= 87;
            else if (value > 64 && value < 71) value -= 55;
            else return type(uint8).max;
        }

        return value;
    }

    /**
     * @dev Escape special characters in JSON strings. This can be useful to prevent JSON injection in NFT metadata.
     *
     * WARNING: This function should only be used in double quoted JSON strings. Single quotes are not escaped.
     *
     * NOTE: This function escapes all unicode characters, and not just the ones in ranges defined in section 2.5 of
     * RFC-4627 (U+0000 to U+001F, U+0022 and U+005C). ECMAScript's `JSON.parse` does recover escaped unicode
     * characters that are not in this range, but other tooling may provide different results.
     */
    function escapeJSON(string memory input) internal pure returns (string memory) {
        bytes memory buffer = bytes(input);
        bytes memory output = new bytes(2 * buffer.length); // worst case scenario
        uint256 outputLength = 0;

        for (uint256 i; i < buffer.length; ++i) {
            bytes1 char = bytes1(_unsafeReadBytesOffset(buffer, i));
            if (((SPECIAL_CHARS_LOOKUP & (1 << uint8(char))) != 0)) {
                output[outputLength++] = "\\";
                if (char == 0x08) output[outputLength++] = "b";
                else if (char == 0x09) output[outputLength++] = "t";
                else if (char == 0x0a) output[outputLength++] = "n";
                else if (char == 0x0c) output[outputLength++] = "f";
                else if (char == 0x0d) output[outputLength++] = "r";
                else if (char == 0x5c) output[outputLength++] = "\\";
                else if (char == 0x22) {
                    // solhint-disable-next-line quotes
                    output[outputLength++] = '"';
                }
            } else {
                output[outputLength++] = char;
            }
        }
        // write the actual length and deallocate unused memory
        assembly ("memory-safe") {
            mstore(output, outputLength)
            mstore(0x40, add(output, shl(5, shr(5, add(outputLength, 63)))))
        }

        return string(output);
    }

    /**
     * @dev Reads a bytes32 from a bytes array without bounds checking.
     *
     * NOTE: making this function internal would mean it could be used with memory unsafe offset, and marking the
     * assembly block as such would prevent some optimizations.
     */
    function _unsafeReadBytesOffset(bytes memory buffer, uint256 offset) private pure returns (bytes32 value) {
        // This is not memory safe in the general case, but all calls to this private function are within bounds.
        assembly ("memory-safe") {
            value := mload(add(buffer, add(0x20, offset)))
        }
    }
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts (last updated v5.1.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC-165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.20;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC-721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Errors {
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    mapping(uint256 tokenId => address) private _owners;

    mapping(address owner => uint256) private _balances;

    mapping(uint256 tokenId => address) private _tokenApprovals;

    mapping(address owner => mapping(address operator => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _requireOwned(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId, _msgSender());
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireOwned(tokenId);

        return _getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        transferFrom(from, to, tokenId);
        ERC721Utils.checkOnERC721Received(_msgSender(), from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     *
     * IMPORTANT: Any overrides to this function that add ownership of tokens not tracked by the
     * core ERC-721 logic MUST be matched with the use of {_increaseBalance} to keep balances
     * consistent with ownership. The invariant to preserve is that for any address `a` the value returned by
     * `balanceOf(a)` must be equal to the number of tokens such that `_ownerOf(tokenId)` is `a`.
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns the approved address for `tokenId`. Returns 0 if `tokenId` is not minted.
     */
    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `owner`'s tokens, or `tokenId` in
     * particular (ignoring whether it is owned by `owner`).
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view virtual returns (bool) {
        return
            spender != address(0) &&
            (owner == spender || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    /**
     * @dev Checks if `spender` can operate on `tokenId`, assuming the provided `owner` is the actual owner.
     * Reverts if:
     * - `spender` does not have approval from `owner` for `tokenId`.
     * - `spender` does not have approval to manage all of `owner`'s assets.
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view virtual {
        if (!_isAuthorized(owner, spender, tokenId)) {
            if (owner == address(0)) {
                revert ERC721NonexistentToken(tokenId);
            } else {
                revert ERC721InsufficientApproval(spender, tokenId);
            }
        }
    }

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * NOTE: the value is limited to type(uint128).max. This protect against _balance overflow. It is unrealistic that
     * a uint256 would ever overflow from increments when these increments are bounded to uint128 values.
     *
     * WARNING: Increasing an account's balance using this function tends to be paired with an override of the
     * {_ownerOf} function to resolve the ownership of the corresponding tokens so that balances and ownership
     * remain consistent with one another.
     */
    function _increaseBalance(address account, uint128 value) internal virtual {
        unchecked {
            _balances[account] += value;
        }
    }

    /**
     * @dev Transfers `tokenId` from its current owner to `to`, or alternatively mints (or burns) if the current owner
     * (or `to`) is the zero address. Returns the owner of the `tokenId` before the update.
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that
     * `auth` is either the owner of the token, or approved to operate on the token (by the owner).
     *
     * Emits a {Transfer} event.
     *
     * NOTE: If overriding this function in a way that tracks balances, see also {_increaseBalance}.
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual returns (address) {
        address from = _ownerOf(tokenId);

        // Perform (optional) operator check
        if (auth != address(0)) {
            _checkAuthorized(from, auth, tokenId);
        }

        // Execute the update
        if (from != address(0)) {
            // Clear approval. No need to re-authorize or emit the Approval event
            _approve(address(0), tokenId, address(0), false);

            unchecked {
                _balances[from] -= 1;
            }
        }

        if (to != address(0)) {
            unchecked {
                _balances[to] += 1;
            }
        }

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        return from;
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner != address(0)) {
            revert ERC721InvalidSender(address(0));
        }
    }

    /**
     * @dev Mints `tokenId`, transfers it to `to` and checks for `to` acceptance.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        ERC721Utils.checkOnERC721Received(_msgSender(), address(0), to, tokenId, data);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal {
        address previousOwner = _update(address(0), tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        } else if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking that contract recipients
     * are aware of the ERC-721 standard to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is like {safeTransferFrom} in the sense that it invokes
     * {IERC721Receiver-onERC721Received} on the receiver, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `tokenId` token must exist and be owned by `from`.
     * - `to` cannot be the zero address.
     * - `from` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _safeTransfer(from, to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeTransfer-address-address-uint256-}[`_safeTransfer`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        ERC721Utils.checkOnERC721Received(_msgSender(), from, to, tokenId, data);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that `auth` is
     * either the owner of the token, or approved to operate on all tokens held by this owner.
     *
     * Emits an {Approval} event.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address to, uint256 tokenId, address auth) internal {
        _approve(to, tokenId, auth, true);
    }

    /**
     * @dev Variant of `_approve` with an optional flag to enable or disable the {Approval} event. The event is not
     * emitted in the context of transfers.
     */
    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal virtual {
        // Avoid reading the owner unless necessary
        if (emitEvent || auth != address(0)) {
            address owner = _requireOwned(tokenId);

            // We do not use _isAuthorized because single-token approvals should not be able to call approve
            if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
                revert ERC721InvalidApprover(auth);
            }

            if (emitEvent) {
                emit Approval(owner, to, tokenId);
            }
        }

        _tokenApprovals[tokenId] = to;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Requirements:
     * - operator can't be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (operator == address(0)) {
            revert ERC721InvalidOperator(operator);
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` doesn't have a current owner (it hasn't been minted, or it has been burned).
     * Returns the owner.
     *
     * Overrides to ownership logic should be done to {_ownerOf}.
     */
    function _requireOwned(uint256 tokenId) internal view returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return owner;
    }
}

// File: @openzeppelin/contracts/interfaces/IERC165.sol


// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC165.sol)

pragma solidity ^0.8.20;


// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC721.sol)

pragma solidity ^0.8.20;


// File: @openzeppelin/contracts/interfaces/IERC4906.sol


// OpenZeppelin Contracts (last updated v5.1.0) (interfaces/IERC4906.sol)

pragma solidity ^0.8.20;



/// @title ERC-721 Metadata Update Extension
interface IERC4906 is IERC165, IERC721 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol


// OpenZeppelin Contracts (last updated v5.3.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.20;





/**
 * @dev ERC-721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is IERC4906, ERC721 {
    using Strings for uint256;

    // Interface ID as defined in ERC-4906. This does not correspond to a traditional interface ID as ERC-4906 only
    // defines events and does not include any external function.
    bytes4 private constant ERC4906_INTERFACE_ID = bytes4(0x49064906);

    // Optional mapping for token URIs
    mapping(uint256 tokenId => string) private _tokenURIs;

    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == ERC4906_INTERFACE_ID || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via string.concat).
        if (bytes(_tokenURI).length > 0) {
            return string.concat(base, _tokenURI);
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Emits {IERC4906-MetadataUpdate}.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
        emit MetadataUpdate(tokenId);
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol


// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.20;



/**
 * @title ERC-721 Burnable Token
 * @dev ERC-721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        _update(address(0), tokenId, _msgSender());
    }
}

// File: AuctionERC721.sol


// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;





/// @title ERC-721 NFT token contract implementation
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice ERC-721 NFT token contract implementation with advanced URI management, NFT token burning, auto-incrementing NFT token IDs, and ownership control
/// @dev ERC-721 NFT token contract implementation with advanced URI management, NFT token burning, auto-incrementing NFT token IDs, and ownership control
contract AuctionERC721 is 
    ERC721, 
    ERC721URIStorage, 
    ERC721Burnable, 
    OwnershipController 
{
    
    /// @dev Stores the token ID number for the next NFT (storage variable used for the auto-incremented NFT token ID feature)
    uint256 private _nextTokenId;

    /// @dev Constructor that initializes the ERC721 base contract, sets the name and symbol of the NFT collection
    constructor()
        ERC721("AuctionERC721", "ANFT")
    {}

    /// @dev Mints a new NFT token to an address and sets the specified URI and auto-incremented token ID
    /// @notice Mints a new NFT token to an address with the specified URI and auto-incremented token ID
    /// @param to_ Address that will receive the minted NFT
    /// @param uri_ The URI of the minted NFT
    /// @custom:requirement-modifier Only the owner can mint new NFTs
    function safeMint(address to_, string memory uri_) 
        public 
        onlyOwner 
    {
        uint256 tokenId = _nextTokenId++; //Current value of _nextTokenId is assigned to tokenId, and then _nextTokenId is incremented by 1 for the next mint
        _safeMint(to_, tokenId);
        _setTokenURI(tokenId, uri_);
    }

    /// @dev Retrieves the URI associated with the specific NFT token with tokenID_
    /// @dev Overrides both the ERC721 and ERC721URIStorage versions of the tokenURI function (multiple inheritance)
    /// @dev C3 linearization algorithm resolves the multiple inheritance, where the inheritance order is ERC721URIStorage first, then ERC721 second
    /// @dev Looks for tokenURI function in ERC721URIStorage first, If it finds the implementation there, it will call that function. If not implemented, call tokenURI from ERC721 base contract
    /// @notice Retrieves the URI associated with the specific NFT token with tokenID_
    /// @param tokenID_ The token ID of the NFT to be retrieved the token URI for
    /// @return Returns the URI (Uniform Resource Identifier) of the NFT with tokenId_
    function tokenURI(uint256 tokenID_) 
        public 
        view 
        override(ERC721, ERC721URIStorage) //C3 linearization multiple inheritance
        returns (string memory) 
    {
        return super.tokenURI(tokenID_);
    }

    /// @dev Checks whether the contract supports a specific interface or not
    /// @dev Implementation of the supportsInterface function, which is part of the ERC-165 standard
    /// @dev ERC-165 standard allows smart contracts to declare which interfaces they support
    /// @dev Interfaces have identifiers, which is the first 4 bytes of the Keccak-256 hash of an interface's signature
    /// @dev The interface ID of ERC721 is 0x80ac58cd
    /// @dev If one of the base contracts implements the interface, the function returns true
    /// @dev Uses multiple inheritance which is resolved by C3 linearization, ERC721URIStorage is looked up first, then ERC721
    /// @notice Checks whether the contract supports a specific interface or not
    /// @param interfaceID_ The interface identifier (first 4 bytes of the Keccak-256 hash of an interface's signature
    /// @return Returns a boolean literal indicating whether the contract supports the specified interface or not
    function supportsInterface(bytes4 interfaceID_) 
        public 
        view 
        override(ERC721, ERC721URIStorage) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceID_);
    }
}
// File: AuctionsLogic.sol


pragma solidity >=0.8.0;








/// @title Auction core implementation contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract facilitates the registration, configuration and management of all processes of decentralized parametric auctions
/// @dev This contract facilitates the registration, configuration and management of all processes of decentralized parametric auctions
contract AuctionsLogic is 
    OwnershipController, 
    CancellableAuctionController, 
    WhitelistAuctionController, 
    BlacklistAuctionController, 
    EntryFeeController, 
    CircuitBreakerEmergencyController
{

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

    /// @dev Stores the IPFS metadata reference string of the respective auction
    mapping(bytes32 => string) private _ipfs;

     // <<< EVENTS >>>
    /// @dev Event for logging the registration of new auctions
    /// @notice Event for logging the registration of new auctions
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being initialized
    event NewAuctionRegistered(bytes32 indexed auctionID_);

    /// @dev Event for logging bids
    /// @notice Event for logging bids
    /// @param auctionID_ The 256 bit hash identifier of the auction that the bid was placed for
    /// @param bidder_ The address of the bidder
    /// @param newHighestBidAmount_ The amount of the bid in Wei (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    event BidPlaced(bytes32 indexed auctionID_, address bidder_, uint256 newHighestBidAmount_);

    /// @dev Event for logging bid withdrawals
    /// @notice Event for logging bid withdrawals
    /// @param auctionID_ The 256 bit hash identifier of the auction that the bid was withdrawn from
    /// @param entity_ The address which initiated the bid withdrawal
    /// @param withdrawAmount_ The amount of the withdrawal in Wei (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    event BidWithdrawn(bytes32 indexed auctionID_, address entity_, uint256 withdrawAmount_);

    /// @dev Event for logging snipe prevention mechanism triggers
    /// @notice Event for logging snipe prevention mechanism triggers
    /// @param auctionID_ The 256 bit hash identifier of the auction at which the snipe prevention mechanism was triggered
    /// @param bidder_ The address of the bidder who triggered the snipe prevention mechanism
    event SnipePreventionTriggered(bytes32 indexed auctionID_, address bidder_);

     // <<< MODIFIERS >>>
    /// @dev This modifier absorbs the associated function's body when the auction does exist, otherwise it reverts execution
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being evaluated
    modifier onlyIfAuctionExists(bytes32 auctionID_) {
        require(auctionExists(auctionID_), "Auction does not exist!");
        _;
    }

    /// @dev This modifier absorbs the associated function's body when the auction does not exist, otherwise it reverts execution
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being evaluated
    modifier onlyIfAuctionDoesNotExist(bytes32 auctionID_) {
        require(!auctionExists(auctionID_), "Auction already exists!");
        _;
    }

    /// @dev This modifier absorbs the associated function's body when the specified auction's starting block number is less or equal compared to the current block number in the context of the function call, otherwise it reverts execution
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being evaluated
    modifier onlyAfterStartBlock(bytes32 auctionID_) {
        require(auctionStartBlock(auctionID_) <= block.number, "Auction has not started!");
        _;
    }

    /// @dev This modifier absorbs the associated function's body when the specified auction's ending block number is greater or equal compared to the current block number in the context of the function call, otherwise it reverts execution
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being evaluated
    modifier onlyBeforeEndBlock(bytes32 auctionID_) {
        require(block.number <= auctionEndBlock(auctionID_), "Auction has ended!");
        _;
    }

    /// @dev This modifier absorbs the associated function's body when the specified auction's starting block is greater than the current block number in the context of the function call, otherwise it reverts execution
    /// @param auctionID_ The 256 bit hash identifier of the auction that is being evaluated
    modifier onlyBeforeStartBlock(bytes32 auctionID_) {
        require(block.number < auctionStartBlock(auctionID_), "Auction is running!");
        _;
    }

     // <<< AUCTION REGISTRATION FUNCTIONALITY >>>
    /// @dev Registers and configures a new parametric auction
    /// @notice Registers and configures a new parametric auction
    /// @param auctionID_ The 256 bit hash identifier (pass with 0x prefix, hexadeciaml encoding, recommended hash function is SHA256 or Keccak256) of the auction
    /// @param auctionStartBlock_ The block number where the auction will start
    /// @param auctionEndBlock_ The block number where the auction will end
    /// @param startingPrice_ The starting price in Wei (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    /// @param bidIncrement_ The bid increment value in Wei (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    /// @param reservePrice_ The reserve price in Wei (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    /// @param auctionSnipeInterval_ The snipe prevention mechanism's activation interval value
    /// @param auctionSnipeBlocks_ The snipe prevention mechanism's auction duration expansion value
    /// @param nftContractAddress_ The address of the IERC-721 complient NFT smart contract
    /// @param nftTokenID_ The ID number of the NFT token that represents the item to be sold
    /// @param ipfs_ The IPFS auction metadata URL string
    /// @return Returns a true boolean literal if the auction registration was successful
    /// @custom:requirement-modifier Only the owner can register new auctions
    /// @custom:requirement-modifier New auctions cannot be registered while the system is paused by the emergency circuit breaker
    /// @custom:requirement-modifier The auction ID must be unique (auctions with the same ID must not exist)
    /// @custom:requirement-body The auction start block must be lower than the auction end block
    /// @custom:requirement-body The auction start block must be at least of the value of the current block number
    /// @custom:requirement-body The starting price must be greater or equal to 0
    /// @custom:requirement-body The bid increment value must be greater or equal to 0
    /// @custom:requirement-body The reserve price must be greater or equal to 0
    /// @custom:requirement-body The snipe prevention mechanism's activation interval value must be greater or equal to 0
    /// @custom:requirement-body The snipe prevention mechanism's activation interval value must be lower than the total duration of the auction
    /// @custom:requirement-body The snipe prevention mechanism's auction duration expansion value must be greater or equal to 0
    /// @custom:requirement-body The NFT contract address must be a smart contract
    /// @custom:requirement-body The NFT contract address must support the IERC721 interface
    /// @custom:requirement-body The NFT with the passed token ID must be owned by the auction smart contract
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
        uint256 nftTokenID_,
        string memory ipfs_
    ) 
        external 
        onlyOwner 
        onlyWhenNotPaused 
        onlyIfAuctionDoesNotExist(auctionID_) 
        returns (bool) 
    {
        require(auctionStartBlock_ < auctionEndBlock_);
        require(auctionStartBlock_ >= block.number);
        require(startingPrice_ >= 0);
        require(bidIncrement_ >= 0);
        require(reservePrice_ >= 0);
        require(auctionSnipeInterval_ >= 0);
        require(auctionSnipeInterval_ < (auctionEndBlock_ - auctionStartBlock_));
        require(auctionSnipeBlocks_ >= 0);
        require(isSmartContract(nftContractAddress_));
        require(AuctionERC721(nftContractAddress_).supportsInterface(type(IERC721).interfaceId));
        require(AuctionERC721(nftContractAddress_).ownerOf(nftTokenID_) == address(this));

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
        _ipfs[auctionID_] = ipfs_;

        emit NewAuctionRegistered(auctionID_);
        return true;
    }

     // <<< BID FUNCTIONALITY >>>
    /// @dev Places a bid on an auction
    /// @notice Places a bid on an auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a true boolean literal if the bid was successful
    /// @custom:requirement-modifier The owner cannot place bids
    /// @custom:requirement-modifier Bids cannot be placed while the system is paused by the emergency circuit breaker
    /// @custom:requirement-modifier Bids can only be placed for registered auctions
    /// @custom:requirement-modifier Bids cannot be placed on cancelled auctions
    /// @custom:requirement-modifier Bids can only be placed on auctions that have already started
    /// @custom:requirement-modifier Bids can only be placed on auctions that have not ended yet
    /// @custom:requirement-body The bid's value must be greater than 0
    /// @custom:requirement-body If there is an entry fee configured for the auction, it must be paid in order to participate in the bidding process
    /// @custom:requirement-body If it is a blacklist auction and the address is blacklisted, then the caller will not be able to participate in bidding
    /// @custom:requirement-body If it is a whitelist auction and the address is not whitelisted, then the caller will not be able to participate in bidding
    /// @custom:requirement-body The total bid of the participant must be greater or equal to the starting price of the auction
    /// @custom:requirement-body The total bid of the participant must be greater or equal to the highest bid + the bid increment
    function bid(bytes32 auctionID_) 
        external 
        payable 
        onlyWhenNotOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        whenNotCancelled(auctionID_) 
        onlyAfterStartBlock(auctionID_) 
        onlyBeforeEndBlock(auctionID_) 
        returns (bool) 
    {
        require(msg.value > 0);

        if(getEntryFee(auctionID_) != 0) {
            require(hasPaidEntryFee(auctionID_, msg.sender));
        }

        if(isBlacklistAuction(auctionID_)) {
            require(!isBlacklistedParticipant(auctionID_, msg.sender));
        }

        if(closedAuction(auctionID_)) {
            require(isWhitelisted(auctionID_, msg.sender));
        }

        uint256 totalBid = msg.value + getBidAmountOfBidder(auctionID_, msg.sender);

        require(totalBid >= startingPrice(auctionID_));

        if(auctionHighestBidAmount(auctionID_) != 0) {
            require(totalBid >= (auctionHighestBidAmount(auctionID_) + bidIncrement(auctionID_)));
        }

        _bidAmountsOfBidders[auctionID_][msg.sender] = totalBid;
        _auctionHighestBidAmount[auctionID_] = totalBid;

        if(msg.sender != auctionWinner(auctionID_)) {
            _auctionWinner[auctionID_] = msg.sender;
        }

        if(auctionSnipeInterval(auctionID_) > 0 && auctionSnipeBlocks(auctionID_) > 0) {
            if((auctionEndBlock(auctionID_) - block.number) <= auctionSnipeInterval(auctionID_)) { 
                _auctionEndBlock[auctionID_] += auctionSnipeBlocks(auctionID_);
                emit SnipePreventionTriggered(auctionID_, msg.sender);
            }
        }

        emit BidPlaced(auctionID_, msg.sender, totalBid);
        return true;
    }

     // <<< BID WITHDRAWAL FUNCTIONALITY >>>
    /// @dev Withdraws a bid from an aucttion
    /// @notice Withdraws a bid from an aucttion
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a true boolean literal if the bid withdrawal was successful
    /// @custom:requirement-modifier Bid withdrawal requests can only be submitted to registered auctions
    /// @custom:requirement-body Bid withdrawals can only be submitted when the auction is either cancelled or has ended naturally
    /// @custom:requirement-body The owner can only withdraw the winning bid once from an auction
    /// @custom:requirement-body The winner of the auction can only withdraw the prize NFT once
    function withdrawBid(bytes32 auctionID_) 
        external 
        onlyIfAuctionExists(auctionID_) 
        returns (bool) 
    {
        require(isCancelled(auctionID_) || (block.number > auctionEndBlock(auctionID_)), "Auction is running!");

        if(isCancelled(auctionID_) || (auctionHighestBidAmount(auctionID_) < reservePrice(auctionID_))) {
            uint256 withdrawBidAmount = getBidAmountOfBidder(auctionID_, msg.sender);
            _bidAmountsOfBidders[auctionID_][msg.sender] -= withdrawBidAmount;
            if(payable(msg.sender).send(withdrawBidAmount)) {
                emit BidWithdrawn(auctionID_, msg.sender, withdrawBidAmount);
                return true;
            } else {
                revert();
            }
        } else if(msg.sender == owner()) {
            require(!ownerWithdrew(auctionID_));
            uint256 withdrawBidAmount = auctionHighestBidAmount(auctionID_);
            _bidAmountsOfBidders[auctionID_][auctionWinner(auctionID_)] -= withdrawBidAmount;
            _ownerWithdrew[auctionID_] = true;
            if(payable(msg.sender).send(withdrawBidAmount)) {
                emit BidWithdrawn(auctionID_, msg.sender, withdrawBidAmount);
                return true;
            } else {
                revert();
            }
        } else if(msg.sender == auctionWinner(auctionID_)) {
            require(nftContractAddress(auctionID_).ownerOf(nftTokenID(auctionID_)) == address(this));
            nftContractAddress(auctionID_).safeTransferFrom(address(this), auctionWinner(auctionID_), nftTokenID(auctionID_));
            return true;
        } else {
            uint256 withdrawBidAmount = getBidAmountOfBidder(auctionID_, msg.sender);
            _bidAmountsOfBidders[auctionID_][msg.sender] -= withdrawBidAmount;
            if(payable(msg.sender).send(withdrawBidAmount)) {
                emit BidWithdrawn(auctionID_, msg.sender, withdrawBidAmount);
                return true;
            } else {
                revert();
            }
        }
    }

     // <<< READ FUNCTIONS >>>
    /// @dev Retrieves the boolean value associated with the passed auction ID
    /// @notice Retrieves the boolean value associated with the passed auction ID
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a boolean literal that indicates whether the auction is registered or not
    function auctionExists(bytes32 auctionID_) public view returns (bool) {
        return _auctionID[auctionID_];
    }

    /// @dev Retrieves the amount of the current highest bid in the specific auction
    /// @notice Retrieves the amount of the current highest bid in the specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the amount of the current highest bid in WEI (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    function auctionHighestBidAmount(bytes32 auctionID_) public view returns (uint256) {
        return _auctionHighestBidAmount[auctionID_];
    }

    /// @dev Retrieves the current auction winnner's address from the specific auction
    /// @notice Retrieves the current auction winnner's address from the specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the address of the current auction winner
    function auctionWinner(bytes32 auctionID_) public view returns (address) {
        return _auctionWinner[auctionID_];
    }

    /// @dev Retrieves the start block number where the specific auction begins
    /// @notice Retrieves the starting block number of the specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the start block number where the auction starts
    function auctionStartBlock(bytes32 auctionID_) public view returns (uint256) {
        return _auctionStartBlock[auctionID_];
    }

    /// @dev Retrieves the end block number where the specific auction ends
    /// @notice Retrieves the end block number where the specific auction ends
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the end block number where the auction ends
    function auctionEndBlock(bytes32 auctionID_) public view returns (uint256) {
        return _auctionEndBlock[auctionID_];
    }

    /// @dev Retrieves the bid amount of a bidder from a specific auction
    /// @notice Retrieves the bid amount of a bidder from a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param bidder_ The address of the bidder
    /// @return Returns the bid amount of a bidder from a specific auction
    function getBidAmountOfBidder(bytes32 auctionID_, address bidder_) public view returns (uint256) {
        return _bidAmountsOfBidders[auctionID_][bidder_];
    }

    /// @dev Retrieves the starting price of a specific auction
    /// @notice Retrieves the starting price of a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the starting price of the auction in WEI (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    function startingPrice(bytes32 auctionID_) public view returns (uint256) {
        return _startingPrice[auctionID_];
    }

    /// @dev Retrieves the bid increment value of a specific auction
    /// @notice Retrieves the bid increment value of a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the bid increment value of the auction in WEI (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    function bidIncrement(bytes32 auctionID_) public view returns (uint256) {
        return _bidIncrement[auctionID_];
    }

    /// @dev Retrieves the reserve price of a specific auction
    /// @notice Retrieves the reserve price of a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the reserve price of the auction in WEI (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    function reservePrice(bytes32 auctionID_) public view returns (uint256) {
        return _reservePrice[auctionID_];
    }

    /// @dev Retrieves the ETH balance of the contract itself (funds from committed bids and collected entry fees)
    /// @notice Retrieves the ETH balance of the contract itself (funds from committed bids and collected entry fees)
    /// @return Returns the ETH balance of the smart contract in WEI (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    function contractETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @dev Retrieves whether the owner has withdrawn from the specific auction or not
    /// @notice Retrieves whether the owner has withdrawn from the specific auction or not
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a boolean literal that indicates whether the owner has withdrawn from the specified auction or not
    function ownerWithdrew(bytes32 auctionID_) public view returns (bool) {
        return _ownerWithdrew[auctionID_];
    }

    /// @dev Retrieves the auction snipe interval of a specific auction
    /// @notice Retrieves the auction snipe interval of a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the auction snipe interval of the auction
    function auctionSnipeInterval(bytes32 auctionID_) public view returns (uint256) {
        return _auctionSnipeInterval[auctionID_];
    }

    /// @dev Retrieves the auction snipe block count of a specific auction
    /// @notice Retrieves the auction snipe block count of a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the auction snipe block count of the auction
    function auctionSnipeBlocks(bytes32 auctionID_) public view returns (uint256) {
        return _auctionSnipeBlocks[auctionID_];
    }

    /// @dev Retrieves the NFT contract address associated with a specific auction
    /// @notice Retrieves the NFT contract address associated with a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the NFT contract address of the auction
    function nftContractAddress(bytes32 auctionID_) public view returns (AuctionERC721) {
        return _nftContractAddress[auctionID_];
    }

    /// @dev Retrieves the NFT token ID of a specific auction
    /// @notice Retrieves the NFT token ID of a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the NFT token ID of the auction
    function nftTokenID(bytes32 auctionID_) public view returns (uint256) {
        return _nftTokenID[auctionID_];
    }

    /// @dev Retrieves the IPFS of a specific auction
    /// @notice Retrieves the IPFS of a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the IPFS string of the auction
    function getIPFS(bytes32 auctionID_) external view returns (string memory) {
        return _ipfs[auctionID_];
    }

     // <<< ADDRESS BYTECODE SIZE CHECKER >>>
    /// @dev Checks whether the passed address is a smart contract or not by evaluating the size of the code stored at the specified address
    /// @dev Inline assembly is used for higher gas efficiency, extcodesize is an EVM opcode that checks and returns the bytecode size of the address, in case of an EOA, the size will be 0
    /// @notice Checks whether the passed address is a smart contract or not by evaluating the size of the code stored at the specified address
    /// @param address_ The address to be checked whether if it is an EOA (externally owned account) or a smart contract
    /// @return Returns a boolean literal indicating whether the passed address is a smart contract or not
    function isSmartContract(address address_) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(address_) 
        }
        return (size > 0);
    }

     // <<< CANCELLABLE AUCTION FUNCTIONALITY >>>
    /// @dev Configures an auction as cancellable
    /// @notice Configures an auction as cancellable
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a true boolean literal if the configuration of an auction as cancellable was successful
    /// @custom:requirement-modifier Only the owner can call this function
    /// @custom:requirement-modifier This function will only execute if the contracts are not paused by the emergency circuit breaker
    /// @custom:requirement-modifier Only an existing (registered) auction can be configured as a cancellable auction
    /// @custom:requirement-modifier An auction can only be configured when it hasn't started yet
    /// @custom:requirement-body Only a non-cancellable auction can be configured as cancellable (prevents additional wasted computation and gas)
    function configureAsCancellableAuction(bytes32 auctionID_) 
        external 
        override 
        onlyOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(!isCancellable(auctionID_));
        super._configureAsCancellableAuction(auctionID_);
        return true;
    }

    /// @dev Cancels a cancellable auction and burns the NFT
    /// @notice Cancels a cancellable auction and burns the NFT
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a true boolean literal if the auction was cancelled successfully
    /// @custom:requirement-modifier Only the owner can call this function
    /// @custom:requirement-modifier This function will only execute if the contracts are not paused by the emergency circuit breaker
    /// @custom:requirement-modifier Only an existing (registered) auction can be cancelled
    /// @custom:requirement-modifier A cancellable auction can only be cancelled once the auction has started
    /// @custom:requirement-modifier A cancellable auction can only be cancelled before it ends
    /// @custom:requirement-body Only a cancellable auction can be cancalled (needs to be configured as cancellable before the auction starts)
    function cancelAuction(bytes32 auctionID_) 
        external 
        override 
        onlyOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        onlyAfterStartBlock(auctionID_) 
        onlyBeforeEndBlock(auctionID_)  
        returns (bool) 
    {
        require(isCancellable(auctionID_));
        super._cancelAuction(auctionID_);
        nftContractAddress(auctionID_).burn(nftTokenID(auctionID_));
        return true;
    }

     // <<< ERC-721 RECEIVER INTERFACE >>>
    /// @dev Ensures that the auction contract receiving the ERC-721 token is capable of handling ERC-721 NFT tokens (safeTranfer eligibility to prevent accidental NFT token loss)
    /// @dev Prevents accidental transfers to contracts that don't know how to process them and are not IERC-721 complient
    /// @dev When the ERC-721 token is transferred to the auction contracct with the safeTransferFrom method, it needs to implement the onERC721Received function to accept the token
    /// @dev Computes the 4 byte Keccak-256 hash of the function signature (name and parameter list data types) to generate a selector hash, then truncates it to the first 4 bytes to form a selector
    /// @dev The function will always return 0x150b7a02
    /// @dev The safeTransferFrom function from the ERC-721 contract will require the recipient (to parameter) to implement the onERC721Received function
    /// @dev For a successful safeTransferFrom execution, the called onERC721Received return value must be equal to the hardcoded selector hash in the ERC-721 contract (IERC721Receiver.onERC721Received.selector)
    /// @notice Ensures that the auction contract receiving the ERC-721 token is capable of handling ERC-721 NFT tokens
    /// @custom:param-unnamed _operator The address which called `safeTransferFrom` function
    /// @custom:param-unnamed _from The address which previously owned the token
    /// @custom:param-unnamed _tokenId The NFT identifier which is being transferred
    /// @custom:param-unnamed _data Additional data with no specified format
    /// @return Returns the function selector (first 4 bytes of the Keccak-256 hash of the function signature (name + parameter list data types))
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

     // <<< WHITELIST FUNCTIONALITY >>>
    /// @dev Configure an auction as closed (whitelisted)
    /// @notice Configure an auction as closed (whitelisted)
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns true if the auction has been configured successfully as a closed (whitelisted) auction
    /// @custom:requirement-modifier Only the owner can call this function
    /// @custom:requirement-modifier This function will only execute if the contracts are not paused by the emergency circuit breaker
    /// @custom:requirement-modifier Only an existing (registered) auction can be configured as a whitelist auction
    /// @custom:requirement-modifier An auction can only be configured when it hasn't started yet
    /// @custom:requirement-body Only an auction that is not yet a whitelist auction can be configured as one (prevents additional wasted computation and gas)
    function configureAsClosedAuction(bytes32 auctionID_) 
        external 
        override 
        onlyOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(!closedAuction(auctionID_));
        super._configureAsClosedAuction(auctionID_);
        return true;
    }

    /// @dev Whitelists an array of addresses to be eligible for participation in a closed (whitelisted) auction
    /// @notice Whitelists a group of users to be eligible for participation in a closed (whitelisted) auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participants_ The array of addresses to be whitelisted
    /// @return Returns true if the whitelisting of the passed addresses was successful
    /// @custom:requirement-modifier Only the owner can call this function
    /// @custom:requirement-modifier This function will only execute if the contracts are not paused by the emergency circuit breaker
    /// @custom:requirement-modifier Only an existing (registered) auction can have whitelisted participants
    /// @custom:requirement-modifier Participants can only be whitelisted for a whitelist auction before it starts running
    /// @custom:requirement-body Participants can only be whitelisted if the auction is configured as a whitelist auction
    function whitelistParticipants(bytes32 auctionID_, address[] memory participants_) 
        external 
        override 
        onlyOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(closedAuction(auctionID_));
        super._whitelistParticipants(auctionID_, participants_);
        return true;
    }

     // <<< ENTRY FEE FUNCTIONALITY >>>
    /// @dev Sets the entry fee for a specific auction
    /// @notice Sets the entry fee for a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param entryFee_ The amount of the entry fee in WEI (1000000000000000000 Wei = 1 Ether = 1000000000 Gwei)
    /// @return Returns true boolean literal if the entry fee has been successfully set
    /// @custom:requirement-modifier Only the owner can call this function
    /// @custom:requirement-modifier This function will only execute if the contracts are not paused by the emergency circuit breaker
    /// @custom:requirement-modifier Only an existing (registered) auction can have an entry fee
    /// @custom:requirement-modifier Entry fee can only be set before the auction begins
    /// @custom:requirement-body The passed entry fee argument must be greater than 0
    function setEntryFee(bytes32 auctionID_, uint256 entryFee_) 
        external 
        override 
        onlyOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(entryFee_ > 0);
        super._setEntryFee(auctionID_, entryFee_);
        return true;
    }

    /// @dev Manages the internal accounting of entry fee payments
    /// @notice Manages the internal accounting of entry fee payments
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns true boolean literal if the entry fee has been successfully paid
    /// @custom:requirement-modifier Only non-owner accounts can pay entry fee
    /// @custom:requirement-modifier This function will only execute if the contracts are not paused by the emergency circuit breaker
    /// @custom:requirement-modifier Only an existing (registered) auction can receive entry fee payments
    /// @custom:requirement-modifier Entry fee can only be paid before the auction begins
    /// @custom:requirement-body The entry fee configured for the specified auction must be greater than 0 (meaning that it is an entry fee gated auction)
    /// @custom:requirement-body The value of the function call must be equal to the configured entry fee in order to accept an entry fee payment
    /// @custom:requirement-body The entry fee can only be paid once by the same account at the specified auction
    function payEntryFee(bytes32 auctionID_) 
        external 
        override 
        payable 
        onlyWhenNotOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(getEntryFee(auctionID_) > 0);
        require(msg.value == getEntryFee(auctionID_));
        require(!hasPaidEntryFee(auctionID_, msg.sender));

        super._payEntryFee(auctionID_);
        return true;
    }

    /// @dev Manages the internal accounting of entry fee withdrawals
    /// @notice Manages the internal accounting of entry fee withdrawals
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns true if the entry fee withdrawal was successful
    /// @custom:requirement-modifier Only non-owner accounts can withdraw the entry fee
    /// @custom:requirement-modifier Only from existing auctions can the entry fee be withdrawn
    /// @custom:requirement-body The entry fee can only be withdrawn when the auction is either cancelled or the duration elapsed naturally
    /// @custom:requirement-body Entry fee can only be withdrawn from an auction that has an entry fee configured
    /// @custom:requirement-body Only participants who paid the entry fee can withdraw it
    /// @custom:requirement-body Entry fee can only be withdrawn once from the specific auction by an account
    function withdrawEntryFee(bytes32 auctionID_) 
        external 
        override 
        onlyWhenNotOwner 
        onlyIfAuctionExists(auctionID_) 
        returns (bool) 
    {
        require(isCancelled(auctionID_) || (block.number > auctionEndBlock(auctionID_)));
        require(getEntryFee(auctionID_) > 0);
        require(hasPaidEntryFee(auctionID_, msg.sender));
        require(!hasWithdrawnEntryFee(auctionID_, msg.sender));

        if(payable(msg.sender).send(getEntryFee(auctionID_))) {
            super._withdrawEntryFee(auctionID_);
            return true;
        } else {
            revert();
        }
    }

     // <<< EMERGENCY CIRCUIT BREAKER FUNCTIONALITY >>>
    /// @dev Turns emergency pause on
    /// @notice Turns emergency pause on
    /// @return Returns true boolean if the emergency pause has been enabled successfully
    /// @custom:requirement-modifier Only the owner can turn on the circuit breaker emergency
    /// @custom:requirement-modifier Emergency can only be enabled if if was previously disabled
    function turnEmergencyPauseOn() 
        external 
        override 
        onlyOwner 
        onlyWhenNotPaused 
        returns (bool) 
    {
        super._turnEmergencyPauseOn();
        return true;
    }

    /// @dev Turns emergency pause off
    /// @notice Turns emergency pause off
    /// @return Returns true boolean if the emergency pause has been disabled successfully
    /// @custom:requirement-modifier Only the owner can turn off the circuit breaker emergency
    /// @custom:requirement-modifier Emergency can only be disabled if if was previously enabled
    function turnEmergencyPauseOff() 
        external 
        override 
        onlyOwner 
        onlyWhenPaused 
        returns (bool) 
    {
        super._turnEmergencyPauseOff();
        return true;
    }

     // <<< BLACKLIST FUNCTIONALITY >>>
    /// @dev Configures a blacklist auction
    /// @notice Configures a blacklist auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns true boolean literal if the blacklist auction configuration was successful
    /// @custom:requirement-modifier Only the owner can configure an auction as a blacklist auction
    /// @custom:requirement-modifier Blacklist auction configuration is only possible when the contracts are not paused by the emergency circuit breaker
    /// @custom:requirement-modifier Only a registered (existing) auction can be configured as a blacklist auction
    /// @custom:requirement-modifier An auction can only be configured as a blacklist auction before it begins
    /// @custom:requirement-body Only a non-blacklist auction can be configured as a blacklist auction (save gas)
    function configureAsBlacklistedAuction(bytes32 auctionID_) 
        external 
        override 
        onlyOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(!isBlacklistAuction(auctionID_));
        super._configureAsBlacklistedAuction(auctionID_);
        return true;
    }

    /// @dev Blacklists an array of addresses (participants) at the specified blacklist auction
    /// @notice Blacklists an array of addresses (participants) at the specified blacklist auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participants_ The addresses (participants) to be blacklisted at the specified blacklist auction
    /// @return Returns true boolean literal if the addresses (participants) were successfully blacklisted at the specified auction
    /// @custom:requirement-modifier Only the owner can blacklist addresses
    /// @custom:requirement-modifier Blacklisting addresses is only possible when the contracts are not paused by the emergency circuit breaker
    /// @custom:requirement-modifier Only at a registered (existing) auction can addresses be blacklisted
    /// @custom:requirement-modifier Blacklisting is only possible before the auction begins
    /// @custom:requirement-body Only at an auction that was configured as a blacklist auction can addresses be blacklisted
    function blacklistParticipants(bytes32 auctionID_, address[] memory participants_) 
        external 
        override 
        onlyOwner 
        onlyWhenNotPaused 
        onlyIfAuctionExists(auctionID_) 
        onlyBeforeStartBlock(auctionID_) 
        returns (bool) 
    {
        require(isBlacklistAuction(auctionID_));
        super._blacklistParticipants(auctionID_, participants_);
        return true;
    }
}