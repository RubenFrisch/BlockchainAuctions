// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract BlacklistAuctionController {

    mapping(bytes32 => bool) private _blacklistedAuction;

    mapping(bytes32 => mapping(address => bool)) private _blacklistedParticipants;

    event AuctionConfiguredAsBlacklisted(bytes32 indexed auctionID_);

    event AddedBlacklistedParticipants(bytes32 indexed auctionID_);

    function isBlacklistAuction(bytes32 auctionID_) public view returns (bool) {
        return _blacklistedAuction[auctionID_];
    }

    function isBlacklistedParticipant(bytes32 auctionID_, address participant_) public view returns (bool) {
        return _blacklistedParticipants[auctionID_][participant_];
    }



    function _configureAsBlacklistedAuction(bytes32 auctionID_) internal {
        _blacklistedAuction[auctionID_] = true;
        emit AuctionConfiguredAsBlacklisted(auctionID_);
    }

    function configureAsBlacklistedAuction(bytes32 auctionID_) external virtual returns (bool);




    function _blacklistParticipants(bytes32 auctionID_, address[] memory participants_) internal {
        for(uint256 i = 0; i < participants_.length; i++) {
            _blacklistedParticipants[auctionID_][participants_[i]] = true;
        }
        emit AddedBlacklistedParticipants(auctionID_);
    }


    function blacklistParticipants(bytes32 auctionID_, address[] memory participants_) external virtual returns (bool);

}