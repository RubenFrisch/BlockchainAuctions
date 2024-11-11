// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract TimelockCountdownTimerController {

    uint256 private constant _DELAY = 10 days;

    uint256 private constant _GRACE_PERIOD = 1 days;

    uint256 private _queueTime;

    event TimelockQueueStarted();

    event TimeLockQueueReset();

    modifier timelocked(uint256 blockTimestampAtCall_) {
        require(getQueueTime() > 0, "Queue not initiated!");
        require(blockTimestampAtCall_ >= (getQueueTime() + getDelay()), "Timelocked, wait!");
        require(blockTimestampAtCall_ <= (getQueueTime() + getDelay() + getGracePeriod()), "Grade period expired!");
        _;
        _resetQueue();
    }

    function getDelay() public pure returns (uint256) {
        return _DELAY;
    }

    function getGracePeriod() public pure returns (uint256) {
        return _GRACE_PERIOD;
    }

    function getQueueTime() public view returns (uint256) {
        return _queueTime;
    }

    function _resetQueue() internal {
        delete _queueTime;
        emit TimeLockQueueReset();
    }

    function _startQueue() internal {
        _queueTime = block.timestamp;
        emit TimelockQueueStarted();
    }

    function startQueue() external virtual returns (bool);

    /*
    function isTimelockPending() external view returns (bool) {
        return block.timestamp < (getQueueTime() + getDelay());
    }

    function daysUntilTimelockEnds() public view returns (uint256) {
        return ((getQueueTime() + getDelay()) - block.timestamp) / 86400;
    }

    function hoursUntilTimelockEnds() public view returns (uint256) {
        return ((getQueueTime() + getDelay()) - block.timestamp) / 3600;
    }

    function secondsUntilTimelockEnds() public view returns (uint256) {
        return ((getQueueTime() + getDelay()) - block.timestamp);
    }
    */
}