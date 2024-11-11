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

    /// @dev Event for logging when all the signatures was reset
    /// @notice Event for logging when all the signatures was reset
    event SignaturesReset();

    /// @dev 
    event SignatureCollectionAndExpiryCountdownStarted();

    event SignaturesExpiredAndReset();



     // <<< CONSTRUCTOR >>>
    constructor() {
        require(_signers.length == _TOTAL_SIGNERS);
        for(uint8 i = 0; i < _TOTAL_SIGNERS; i++) {
            require(_signers[i] != address(0));
            _isSigner[_signers[i]] = true;
        }
    }



     // <<< MODIFIERS >>>
    modifier onlySigner {
        require(isSigner(msg.sender), "Not a signer!");
        _;
    }




    modifier multiSignatureGuard {
        require(currentSignatureCount() >= _REQUIRED_SIGNATURES, "Not enough signatures!");
        require(block.timestamp <= getSignatureExpiryTime(), "Signatures have expired!");
        _;
        _resetAllSignatures();
    }




     // <<< READ FUNCTIONS >>>

    function currentSignatureCount() public view returns (uint8) {
        return _currentSignatureCount;
    }

    function isSigner(address signer_) public view returns (bool) {
        return _isSigner[signer_];
    }

    function hasSigned(address signer_) public view returns (bool) {
        return _hasSigned[signer_];
    }

    function getSignatureExpiryTime() public view returns (uint256) {
        return _signatureExpiryTime;
    }





     // <<< CORE MULTI SIGNATURE GUARD FUNCTIONS >>>

    function _resetAllSignatures() internal {
        delete _currentSignatureCount;
        for(uint8 i = 0; i < _TOTAL_SIGNERS; i++) {
            _hasSigned[_signers[i]] = false;
        }
        emit SignaturesReset();
    }




    function registerSignature() external onlySigner returns (bool) {
        if(currentSignatureCount() == 0) {
            _signatureExpiryTime = block.timestamp + _SIGNATURE_VALIDITY_TIME;
            emit SignatureCollectionAndExpiryCountdownStarted();
        }
        
        if(block.timestamp > getSignatureExpiryTime()) {
            _resetAllSignatures();
            _signatureExpiryTime = block.timestamp + _SIGNATURE_VALIDITY_TIME;
            emit SignaturesExpiredAndReset();
        }
        
        require(!hasSigned(msg.sender));
        _hasSigned[msg.sender] = true;
        _currentSignatureCount++;

        emit SignatureRegistered(msg.sender);
        return true;
    }
}