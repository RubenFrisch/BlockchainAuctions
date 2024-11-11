// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title IPFS manager abstract contract appendage
/// @author Ruben Frisch (ÓE-NIK, Business Informatics MSc)
/// @notice This contract enables the management of IPFS data for auctions
/// @dev This contract enables the management of IPFS data for auctions
abstract contract IPFSManager {

     // <<< STATE VARIABLES >>>
    /// @dev Stores the IPFS metadata reference string of the respective auction
    mapping(bytes32 => string) private _ipfs;

     // <<< EVENTS >>>
    /// @dev Event for logging the configuration of IPFS data for an auction
    /// @notice Event for logging the configuration of IPFS data for an auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    event IPFSConfigured(bytes32 indexed auctionID_);

     // <<< READ FUNCTIONS >>>
    /// @dev Retrieves the IPFS of a specific auction
    /// @notice Retrieves the IPFS of a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @return Returns the IPFS string associated with the specific auction
    function getIPFS(bytes32 auctionID_) external view returns (string memory) {
        return _ipfs[auctionID_];
    }

     // <<< IPFS MANAGEMENT CORE FUNCTIONS >>>
    /// @dev Sets the IPFS for a specific auction
    /// @notice Sets the IPFS for a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param ipfs_ The IPFS string
    function _setIPFS(bytes32 auctionID_, string memory ipfs_) internal {
        _ipfs[auctionID_] = ipfs_;
        emit IPFSConfigured(auctionID_);
    }

    /// @dev Sets the IPFS for a specific auction
    /// @notice Sets the IPFS for a specific auction
    /// @param auctionID_ The 256 bit hash identifier of the auction
    /// @param ipfs_ The IPFS string
    /// @return Returns true boolean if the IPFS configuration was successful
    /// @custom:virtual This function should be overriden in the child contract, with access control, execution preconditions, and other checks implemented
    /// @custom:virtual The storage modification should be done by the internal function '_setIPFS'
    function setIPFS(bytes32 auctionID_, string memory ipfs_) external virtual returns (bool);
}