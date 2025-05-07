// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AuctionsLogic_flattened.sol";

contract Mock is AuctionsLogic {
    
    function testOnlyOwnerModifier() public view onlyOwner returns (bool) {
        return true;
    }

    function testonlyWhenNotOwnerModifier() public view onlyWhenNotOwner returns (bool) {
        return true;
    }

    function mock_transferOwnership(address newOwner_) public {
        super._transferOwnership(newOwner_);
    }

    function mock_setPendingOwner(address newPendingOwner_) public {
        super._setPendingOwner(newPendingOwner_);
    }

    function getSigners() public pure returns (address[7] memory signers) {
        address[7] memory _signers = [
            0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
            0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
            0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
            0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,
            0x617F2E2fD72FD9D5503197092aC168c91465E7f2,
            0x17F6AD8Ef982297579C203069C1DbfFE4348c372,
            0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678
        ];

        return _signers;
    }

    function getRequiredSignatures() public pure returns (uint8) {
        return 5;
    }
}