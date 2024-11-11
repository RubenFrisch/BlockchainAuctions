// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "OwnershipControl.sol";

abstract contract Cancellable is OwnershipControl {
    
    mapping(bytes32 => bool) _cancelled;

    event AuctionCancelled(bytes32 indexed auctionID_, address owner_);

    modifier whenNotCancelled(bytes32 auctionID_) {
        require(!isCancelled(auctionID_), "The auction is cancelled!");
        _;
    }

    function isCancelled(bytes32 auctionID_) public view returns (bool) {
        return _cancelled[auctionID_];
    }

    function _cancelAuction(bytes32 auctionID_) internal {
        _cancelled[auctionID_] = true;
        emit AuctionCancelled(auctionID_, msg.sender);
    }

    function cancelAuction(bytes32 auctionID_) external virtual returns (bool);
}