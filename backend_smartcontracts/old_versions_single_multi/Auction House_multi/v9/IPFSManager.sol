// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract IPFSManager {

    /// @dev Stores the IPFS metadata reference string of the respective auction
    mapping(bytes32 => string) private _ipfs;

    event addedIPFS(bytes32 indexed auctionID_);

    function getIPFS(bytes32 auctionID_) external view returns (string memory) {
        return _ipfs[auctionID_];
    }

    function _setIPFS(bytes32 auctionID_, string memory ipfs_) internal {
        _ipfs[auctionID_] = ipfs_;
        emit addedIPFS(auctionID_);
    }

    function setIPFS(bytes32 auctionID_, string memory ipfs_) external virtual returns (bool);
}