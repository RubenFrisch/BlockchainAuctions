// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract TimelockCountdownTimerController {

    uint256 private constant _DELAY = 10 days;

    uint256 private _queueTime;

    event TimelockQueueStarted();

    modifier timelocked(uint256 blockTimestampAtCall_) {
        require(getQueueTime() > 0, "Queue not initiated!");
        require(blockTimestampAtCall_ >= (getQueueTime() + getDelay()), "Timelocked, wait!");
        _;
    }

    function getDelay() public pure returns (uint256) {
        return _DELAY;
    }

    function getQueueTime() public view returns (uint256) {
        return _queueTime;
    }

    function _resetQueue() internal {
        delete _queueTime;
    }

    function _startQueue() internal {
        _queueTime = block.timestamp;
        emit TimelockQueueStarted();
    }

    function startQueue() external virtual returns (bool);

    /*
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