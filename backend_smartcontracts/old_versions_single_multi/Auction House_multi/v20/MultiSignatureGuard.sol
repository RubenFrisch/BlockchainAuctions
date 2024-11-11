// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


contract MultiSignatureGuard {

     // <<< STATE VARIABLES >>>
    uint8 private constant _TOTAL_SIGNERS = 5;

    uint8 private constant _REQUIRED_SIGNATURES = 3;

    uint256 private constant _SIGNATURE_VALIDITY_TIME = 15 minutes;

    uint256 private _signatureExpiryTime;

    uint8 private _currentSignatureCount;

    mapping(address => bool) private _isSigner;
    
    mapping(address => bool) private _hasSigned;
    
    address[5] private _signers = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,
        0x617F2E2fD72FD9D5503197092aC168c91465E7f2
    ];

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
    function totalSigners() external pure returns (uint8) {
        return _TOTAL_SIGNERS;
    }

    function requiredSignatures() external pure returns (uint8) {
        return _REQUIRED_SIGNATURES;
    }

    function signatureValidityTime() external pure returns (uint256) {
        return _SIGNATURE_VALIDITY_TIME;
    }

    function currentSignatureCount() public view returns (uint8) {
        return _currentSignatureCount;
    }

    function isSigner(address signer_) public view returns (bool) {
        return _isSigner[signer_];
    }

    function hasSigned(address signer_) public view returns (bool) {
        return _hasSigned[signer_];
    }

    function getSigners() external view returns (address[_TOTAL_SIGNERS] memory) {
        return _signers;
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
    }




    function registerSignature() external onlySigner returns (bool) {
        if(currentSignatureCount() == 0) {
            _signatureExpiryTime = block.timestamp + _SIGNATURE_VALIDITY_TIME;
        }
        
        if(block.timestamp > getSignatureExpiryTime()) {
            _resetAllSignatures();
            _signatureExpiryTime = block.timestamp + _SIGNATURE_VALIDITY_TIME;
        }
        
        require(!hasSigned(msg.sender), "Already signed!");
        _hasSigned[msg.sender] = true;
        _currentSignatureCount++;

        return true;
    }



    function remainingTimeBeforeSignatureExpiry() external view returns (uint256) {
        if (block.timestamp > getSignatureExpiryTime()) {
            return 0;
        } else {
            return getSignatureExpiryTime() - block.timestamp;
        }
    }

}