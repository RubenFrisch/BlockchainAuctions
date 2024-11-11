// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract Cancellable {
    
    /// @dev Indicates whether a cancellable auction has been cancalled or not
    mapping(bytes32 => bool) private _cancelled;
    
    /// @dev Indicates whether an auction is cancellable or not
    mapping(bytes32 => bool) private _cancelSwitch;

    event AuctionCancelled(bytes32 indexed auctionID_, address owner_);
    event AuctionConfiguredAsCancellable(bytes32 indexed auctionID_, address owner_);

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




    function isCancellable(bytes32 auctionID_) public view returns (bool) {
        return _cancelSwitch[auctionID_];
    }

    function _configureAsCancellableAuction(bytes32 auctionID_) internal {
        _cancelSwitch[auctionID_] = true;
        emit AuctionConfiguredAsCancellable(auctionID_, msg.sender);
    }

    function configureAsCancellableAuction(bytes32 auctionID_) external virtual returns (bool);
}