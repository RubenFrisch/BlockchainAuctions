// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract WhitelistedAuction {
    
    /// @dev Indicates whether an auction is initialized as a closed auction or not
    mapping(bytes32 => bool) private _closedAuction;

    /// @dev Indicates whether an address is whitelisted or not for the respective closed auction
    mapping(bytes32 => mapping(address => bool)) private _whitelistedParticipants;
    
    event AuctionConfiguredAsClosed(bytes32 indexed auctionID_);
    event AddedWhitelistedParticipants(bytes32 indexed auctionID_);

    function closedAuction(bytes32 auctionID_) public view returns (bool) {
        return _closedAuction[auctionID_];
    }

    function _configureAsClosedAuction(bytes32 auctionID_) internal {
        _closedAuction[auctionID_] = true;
        emit AuctionConfiguredAsClosed(auctionID_);
    }

    function configureAsClosedAuction(bytes32 auctionID_) external virtual returns (bool);




    function isWhitelisted(bytes32 auctionID_, address participant_) public view returns (bool) {
        return _whitelistedParticipants[auctionID_][participant_];
    }

    function _whitelistParticipants(bytes32 auctionID_, address[] memory participants_) internal {
        for(uint256 i = 0; i < participants_.length; i++ ) {
            _whitelistedParticipants[auctionID_][participants_[i]] = true;
        }
        emit AddedWhitelistedParticipants(auctionID_);
    }

    function whitelistParticipants(bytes32 auctionID_, address[] memory participants_) external virtual returns (bool);
}