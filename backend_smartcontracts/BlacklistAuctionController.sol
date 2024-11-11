// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Blacklist auction controller contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract enables blacklist auctions
/// @dev This contract enables blacklist auctions
abstract contract BlacklistAuctionController {

     // <<< STATE VARIABLES >>>
    /// @dev Indicates whether an auction is configured as a blacklist auction or not
    mapping(bytes32 => bool) private _blacklistedAuction;

    /// @dev Indicates whether an address is blacklisted or not at a specific auction
    mapping(bytes32 => mapping(address => bool)) private _blacklistedParticipants;

     // <<< EVENTS >>>
    /// @dev Event for logging the configuration of blacklist auctions
    /// @notice Event for logging the configuration of blacklist auctions
    /// @param auctionID_ The 256 bit hash identifier of the auction
    event AuctionConfiguredAsBlacklisted(bytes32 indexed auctionID_);

    /// @dev Event for logging the blacklisting of participants
    /// @notice Event for logging the blacklisting of participants
    /// @param auctionID_ The 256 bit hash identifier of the auction
    event AddedBlacklistedParticipants(bytes32 indexed auctionID_);

     // <<< READ FUNCTIONS >>>
    /// @dev Retrieves whether an auction is configured as a blacklist auction or not
    /// @notice Retrieves whether an auction is configured as a blacklist auction or not
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns a boolean flag that indicates whether an auction is configured as a blacklist auction or not
    function isBlacklistAuction(bytes32 auctionID_) public view returns (bool) {
        return _blacklistedAuction[auctionID_];
    }

    /// @dev Retrieves whether a participant is blacklisted or not at a blacklist auction
    /// @notice Retrieves whether a participant is blacklisted or not at a blacklist auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participant_ The address of the participant
    /// @return Returns a boolean flag indicating whether the participant is blacklisted or not at the specified blacklist auction
    function isBlacklistedParticipant(bytes32 auctionID_, address participant_) public view returns (bool) {
        return _blacklistedParticipants[auctionID_][participant_];
    }

     // <<< CORE BLACKLIST AUCTION FUNCTIONS >>>
    /// @dev Configures a blacklist auction
    /// @notice Configures a blacklist auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    function _configureAsBlacklistedAuction(bytes32 auctionID_) internal {
        _blacklistedAuction[auctionID_] = true;
        emit AuctionConfiguredAsBlacklisted(auctionID_);
    }

    /// @dev Configures a blacklist auction
    /// @notice Configures a blacklist auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns true boolean literal if the blacklist auction configuration was successful
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be executed by the internal function '_configureAsBlacklistedAuction'
    function configureAsBlacklistedAuction(bytes32 auctionID_) external virtual returns (bool);

    /// @dev Blacklists an array of addresses (participants) at the specified blacklist auction
    /// @notice Blacklists an array of addresses (participants) at the specified blacklist auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participants_ The addresses (participants) to be blacklisted at the specified blacklist auction
    function _blacklistParticipants(bytes32 auctionID_, address[] memory participants_) internal {
        for(uint256 i = 0; i < participants_.length; i++) {
            _blacklistedParticipants[auctionID_][participants_[i]] = true;
        }
        emit AddedBlacklistedParticipants(auctionID_);
    }

    /// @dev Blacklists an array of addresses (participants) at the specified blacklist auction
    /// @notice Blacklists an array of addresses (participants) at the specified blacklist auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participants_ The addresses (participants) to be blacklisted at the specified blacklist auction
    /// @return Returns true boolean literal if the addresses (participants) were successfully blacklisted at the specified auction
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be executed by the internal function '_blacklistParticipants'
    function blacklistParticipants(bytes32 auctionID_, address[] memory participants_) external virtual returns (bool);
}