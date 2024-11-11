// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Whitelist auction controller contract
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice This contract enables whitelist (closed) auctions
/// @dev This contract enables whitelist (closed) auctions
abstract contract WhitelistAuctionController {
    
     // <<< STATE VARIABLES >>>
    /// @dev Indicates whether an auction is initialized as a closed (whitelisted) auction or not
    mapping(bytes32 => bool) private _closedAuction;

    /// @dev Indicates whether an address is whitelisted or not for the respective closed (whitelisted) auction
    mapping(bytes32 => mapping(address => bool)) private _whitelistedParticipants;
    
     // <<< EVENTS >>>
    /// @dev Event for logging the configuration of an auction as closed (whitelisted)
    /// @notice Event for logging the configuration of an auction as closed (whitelisted)
    /// @param auctionID_ The 256 bit hash identifier of the auction that was configured as closed (whitelisted)
    event AuctionConfiguredAsClosed(bytes32 indexed auctionID_);

    /// @dev Event for logging the whitelisting of participants
    /// @notice Event for logging the whitelisting of participants
    /// @param auctionID_ The 256 bit hash identifier of the closed (whitelisted) auction that the whitelisted participants has been registered to
    event AddedWhitelistedParticipants(bytes32 indexed auctionID_);

     // <<< CONFIGURATION FUNCTIONS >>>
    /// @dev Determines whether an auction is closed (whitelisted) or not, accesses the '_closedAuction' storage variable
    /// @notice Determines whether an auction is closed (whitelisted) or not
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Boolean flag indicating whether the auction is closed (true) or not (false)
    function closedAuction(bytes32 auctionID_) public view returns (bool) {
        return _closedAuction[auctionID_];
    }

    /// @dev Sets an auction to closed (whitelisted)
    /// @notice Sets an auction to closed (whitelisted)
    /// @param auctionID_ The 256 bit hash identifier of the auction
    function _configureAsClosedAuction(bytes32 auctionID_) internal {
        _closedAuction[auctionID_] = true;
        emit AuctionConfiguredAsClosed(auctionID_);
    }

    /// @dev Configure an auction as closed (whitelisted)
    /// @notice Configure an auction as closed (whitelisted)
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns true if the auction has been configured successfully as a closed (whitelisted) auction
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be executed by the internal function '_configureAsClosedAuction'
    function configureAsClosedAuction(bytes32 auctionID_) external virtual returns (bool);

     // <<< CORE WHITELISTING FUNCTIONS >>>
    /// @dev Checks whether an address is whitelisted or not at a certain closed (whitelisted) auction
    /// @notice Checks whether an address is whitelisted or not at a certain closed (whitelisted) auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participant_ The address of the participant we want to check whether it is whitelisted or not
    /// @return Boolean flag indicating whether the address is whitelisted (true) or not (false)
    function isWhitelisted(bytes32 auctionID_, address participant_) public view returns (bool) {
        return _whitelistedParticipants[auctionID_][participant_];
    }

    /// @dev Whitelists an array of addresses to be eligible for participation in a closed (whitelisted) auction
    /// @notice Whitelists a group of users to be eligible for participation in a closed (whitelisted) auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participants_ The array of addresses to be whitelisted
    function _whitelistParticipants(bytes32 auctionID_, address[] memory participants_) internal {
        for(uint256 i = 0; i < participants_.length; i++ ) {
            _whitelistedParticipants[auctionID_][participants_[i]] = true;
        }
        emit AddedWhitelistedParticipants(auctionID_);
    }

    /// @dev Whitelists an array of addresses to be eligible for participation in a closed (whitelisted) auction
    /// @notice Whitelists a group of users to be eligible for participation in a closed (whitelisted) auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param participants_ The array of addresses to be whitelisted
    /// @return Returns true if the whitelisting of the passed addresses was successful
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be done by the internal function '_whitelistParticipants'
    function whitelistParticipants(bytes32 auctionID_, address[] memory participants_) external virtual returns (bool);
}