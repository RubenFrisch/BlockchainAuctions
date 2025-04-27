// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AuctionsLogic_flattened.sol";

contract Mock is AuctionsLogic {
    
    function callResetQueue() public {
        _resetQueue();
    }

    function callStartQueue() public {
        _startQueue();
    }

    function timelockedMockFunction() public timelocked(block.timestamp) returns (uint8) {
        return 1;
    }

    function timelockedMockFunctionWhichReverts() public timelocked(block.timestamp) returns (uint8) {
         revert("Forced revert after timelock passed");
    }

    function callStartAndTimelockedInSameBlock() public {
        _startQueue();
        timelockedMockFunction();
    }

    function unprotectedFunction() public returns (uint8) {
        return 1;
    }

    function protectedFunction() public timelocked(block.timestamp) returns (uint8) {
        return 1;
    }

}