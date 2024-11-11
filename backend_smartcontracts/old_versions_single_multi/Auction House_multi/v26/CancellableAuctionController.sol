// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Cancellable auction controller contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract enables cancellable auctions
/// @dev This contract enables cancellable auctions
abstract contract CancellableAuctionController {

     // <<< STATE VARIABLES >>>
    /// @dev Indicates whether an auction is cancellable or not
    mapping(bytes32 => bool) private _cancelSwitch;

    /// @dev Indicates whether a cancellable auction was cancalled or not
    mapping(bytes32 => bool) private _cancelled;

     // <<< EVENTS >>>
    /// @dev Event for logging when an auction has been configured as cancellable
    /// @notice Event for logging when an auction has been configured as cancellable
    /// @param auctionID_ The 256 bit hash identifier of the auction
    event AuctionConfiguredAsCancellable(bytes32 indexed auctionID_);

    /// @dev Event for logging when an auction has been cancelled
    /// @notice Event for logging when an auction has been cancelled
    /// @param auctionID_ The 256 bit hash identifier of the auction
    event AuctionCancelled(bytes32 indexed auctionID_);

     // <<< MODIFIERS >>>
    /// @dev This modifier absorbs the associated function's body when an auction is not cancelled, otherwise it reverts execution
    /// @param auctionID_ The 256 bit hash identifier of the auction
    modifier whenNotCancelled(bytes32 auctionID_) {
        require(!isCancelled(auctionID_), "Auction is cancelled!");
        _;
    }

     // <<< READ FUNCTIONS >>>
    /// @dev Retrieves whether a specific auction is cancellable (true) or not cancellable (false)
    /// @notice Retrieves whether a specific auction is cancellable (true) or not cancellable (false)
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a boolean flag indicating whether an auction is cancellable (true) or not cancellable (false)
    function isCancellable(bytes32 auctionID_) public view returns (bool) {
        return _cancelSwitch[auctionID_];
    }

    /// @dev Retrieves whether a specific cancellable auction is cancelled (true) or not cancelled (false)
    /// @notice Retrieves whether a specific cancellable auction is cancelled (true) or not cancelled (false)
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a boolean flag indicating whether a cancellable auction is cancelled (true) or not cancelled (false)
    function isCancelled(bytes32 auctionID_) public view returns (bool) {
        return _cancelled[auctionID_];
    }

     // <<< CORE CANCELLABLE AUCTION CONTROLLER FUNCTIONS >>>
    /// @dev Configures an auction as cancellable
    /// @notice Configures an auction as cancellable
    /// @param auctionID_ The 256 bit hash identifier of the auction
    function _configureAsCancellableAuction(bytes32 auctionID_) internal {
        _cancelSwitch[auctionID_] = true;
        emit AuctionConfiguredAsCancellable(auctionID_);
    }

    /// @dev Configures an auction as cancellable
    /// @notice Configures an auction as cancellable
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a true boolean literal if the configuration of an auction as cancellable was successful
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be executed by the internal function '_configureAsCancellableAuction'
    function configureAsCancellableAuction(bytes32 auctionID_) external virtual returns (bool);

    /// @dev Cancels a cancellable auction
    /// @notice Cancels a cancellable auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    function _cancelAuction(bytes32 auctionID_) internal {
        _cancelled[auctionID_] = true;
        emit AuctionCancelled(auctionID_);
    }

    /// @dev Cancels a cancellable auction
    /// @notice Cancels a cancellable auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a true boolean literal if the auction was cancelled successfully
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be executed by the internal function '_cancelAuction'
    function cancelAuction(bytes32 auctionID_) external virtual returns (bool);
}