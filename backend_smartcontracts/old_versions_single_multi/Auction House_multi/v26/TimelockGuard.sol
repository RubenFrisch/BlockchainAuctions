// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Timelock guard contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract enables the timelock guard feature to enhance the security of critial operations
/// @dev This contract enables the timelock guard feature to enhance the security of critical operations
abstract contract TimelockGuard {

     // <<< STATE VARIABLES >>>
    /// @dev Constant that stores the time duration of the timelock delay (can be changed, no side-effects) (default: 10 days)
    uint256 private constant _DELAY = 10 days;

    /// @dev Constant that stores the time duration of the grace period (can be changed, no side-effects) (default: 1 days)
    uint256 private constant _GRACE_PERIOD = 1 days;

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
        require(getQueueTime() > 0, "Queue not initiated!");
        require(blockTimestampAtCall_ >= (getQueueTime() + _DELAY), "Timelocked, wait!");
        require(blockTimestampAtCall_ <= (getQueueTime() + _DELAY + _GRACE_PERIOD), "Grade period expired!");
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