// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Multi signature guard contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract enables the multi signature guard feature to enhance the security of critical operations
/// @dev This contract enables the multi signature guard feature to enhance the security of critical operations
contract MultiSignatureGuard {

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