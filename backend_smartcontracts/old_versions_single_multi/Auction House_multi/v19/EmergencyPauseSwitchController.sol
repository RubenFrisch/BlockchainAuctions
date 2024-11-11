// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Emergency pause controller contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract enables the emergency pause feature
/// @dev This contract enables the emergency pause feature
abstract contract EmergencyPauseSwitchController {

     // <<< STATE VARIABLES >>>
    /// @dev Indicates whether the auction system's emergency pause is enabled (true) or not (false)
    bool private _paused;

     // <<< EVENTS >>>
    /// @dev Event for logging when the emergency pause feature has been toggled on
    /// @notice Event for logging when the emergency pause feature has been toggled on
    /// @param blockNumber_ The block number when the system's emergency pause has been enabled
    event EmergencyPauseTurnedOn(uint256 blockNumber_);

    /// @dev Event for logging when the emergency pause feature has been toggled off
    /// @notice Event for logging when the emergency pause feature has been toggled off
    /// @param blockNumber_ The block number when the system's emergency pause has been disabled
    event EmergencyPauseTurnedOff(uint256 blockNumber_);

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
        emit EmergencyPauseTurnedOn(block.number);
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
        emit EmergencyPauseTurnedOff(block.number);
    }

    /// @dev Turns emergency pause off
    /// @notice Turns emergency pause off
    /// @return Returns true boolean if the emergency pause has been disabled successfully
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be executed by the internal function '_turnEmergencyPauseOff'
    function turnEmergencyPauseOff() external virtual returns (bool);
}