// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract EmergencyPauseController {
     // <<< STATE VARIABLES >>>
    bool private _paused;

     // <<< EVENTS >>>
    event EmergencyPauseEngaged(uint256 indexed blockNumber_);

    event EmergencyPauseLifted(uint256 indexed blockNumber_);

     // <<< MODIFIERS >>
    modifier onlyWhenNotPaused {
        require(!paused(),"Emergency pause is engaged!");
        _;
    }

    
    modifier onlyWhenPaused {
        require(paused(),"Emergency pause is engaged!");
        _;
    }

    function paused() public view returns (bool) {
        return _paused;
    }



}