// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AuctionsLogic_flattened.sol";

contract MockWithSignerArraySizeMismatch is AuctionsLogic {
    
    //Public getter functions for the private constans state variables:
    function getTotalSignersConstant() public pure returns (uint8) {
        return 7; //Should be equal to the _TOTAL_SIGNERS constant variable
    }

    function getRequiredSignatures() public pure returns (uint8) {
        return 5; //Should be equal to the _REQUIRED_SIGNATURES constant variable
    }

    function getSignatureValidityTime() public pure returns (uint256) {
        return 900; //Should be equal to the _SIGNATURE_VALIDITY_TIME constant variable
    }

    //The signer set with a size of 8 instead of 7 which is should be
    address[8] private _signers = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,
        0x617F2E2fD72FD9D5503197092aC168c91465E7f2,
        0x17F6AD8Ef982297579C203069C1DbfFE4348c372,
        0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678,
        0x168483f64d9C6d1EcF9b849AE677DD3315835CB3 //8th address
    ];

    //Mock constructor to check for size mismatch between _TOTAL_SIGNERS and the size of the _signers array
    constructor() {
        require(_signers.length == getTotalSignersConstant(), "Incorrect number of signers");

        for (uint8 i = 0; i < _signers.length; i++) {
            require(_signers[i] != address(0), "Zero address found");
        }
    }

}