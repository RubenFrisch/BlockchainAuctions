// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "OwnershipControl.sol";

abstract contract Cancellable is OwnershipControl {
    
    bool private _cancelled;

    event AuctionCancelled(address indexed owner_);

    modifier whenNotCancelled {
        require(!cancelled(), "TRANSACTION ERROR: the auction is cancelled!");
        _;
    }

    function cancelled() public view returns (bool) {
        return _cancelled;
    }

    function _cancelAuction() internal {
        _cancelled = true;
        emit AuctionCancelled(msg.sender);
    }

    function startAuctionCancellationProcess() external virtual;
    function resetAuctionCancellationProcess() external virtual;
    function cancelAuction2Step() external virtual;
}