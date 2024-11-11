// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract EmergencyPauseSwitchController {
     // <<< STATE VARIABLES >>>
    bool private _paused;

     // <<< EVENTS >>>
    event EmergencyPauseTurnedOn();

    event EmergencyPauseTurnedOff();

     // <<< MODIFIERS >>
    modifier onlyWhenNotPaused {
        require(!isPaused(),"Paused!");
        _;
    }

    modifier onlyWhenPaused {
        require(isPaused(),"Not paused!");
        _;
    }

     // <<< READ FUNCTIONS >>
    function isPaused() public view returns (bool) {
        return _paused;
    }

     // <<< CORE PAUSE EMERGENCY SWITCH FUNCTIONS >>>
    function _turnEmergencyPauseOn() internal onlyWhenNotPaused {
         _paused = true;
        emit EmergencyPauseTurnedOn();
    }

    function turnEmergencyPauseOn() external virtual returns (bool);



    function _turnEmergencyPauseOff() internal onlyWhenPaused {
        _paused = false;
        emit EmergencyPauseTurnedOff();
    }

    function turnEmergencyPauseOff() external virtual returns (bool);

}