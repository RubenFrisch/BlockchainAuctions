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


    function cancelled() public view virtual returns (bool) {
        return _cancelled;
    }


    function _cancelAuction() internal virtual {
        _cancelled = true;
        emit AuctionCancelled(msg.sender);
    }


    function startAuctionCancellationProcess() public virtual;


    function resetAuctionCancellationProcess() public virtual;


    function cancelAuction2Step() public virtual;
}