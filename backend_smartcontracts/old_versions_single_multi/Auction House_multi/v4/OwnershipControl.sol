// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract OwnershipControl {
    address private _owner;
    address private _pendingOwner;
    bool private _renounceUnlocked;
    OwnershipChange[] private _ownershipHistory;

    struct OwnershipChange {
        address previousOwner;
        address newOwner;
        uint256 blockNumber;
        bytes32 blockHash;
        uint256 chainID;
    }

    event OwnershipTransferCompleted(address indexed previousOwner_, address indexed newOwner_);
    event TransferOwnershipInitiated(address indexed owner_, address indexed pendingOwner_);
    event RenounceProcessInitiated(address indexed owner_);
    event RenounceProcessTerminated(address indexed owner_);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner(), "Only the owner can call this function!");
        _;
    }

    modifier onlyWhenNotOwner {
        require(msg.sender != owner(), "Caller must not be the owner!");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    function renounceUnlocked() public view returns (bool) {
        return _renounceUnlocked;
    }

    function _transferOwnership(address newOwner_) internal {
        address previousOwner = owner();
        _owner = newOwner_;
        _addEntryToOwnershipHistory(previousOwner, newOwner_);
        emit OwnershipTransferCompleted(previousOwner, newOwner_);
    }

    function _setPendingOwner(address newPendingOwner_) internal {
        _pendingOwner = newPendingOwner_;
    }

    function resetPendingOwner() external onlyOwner returns (bool) {
        delete _pendingOwner;
        return true;
    }

    function _resetPendingOwner() internal {
        delete _pendingOwner;
    }

    function transferOwnership(address newOwner_) external onlyOwner returns (bool) {
        require(newOwner_ != address(0), "The new owner cannot be the zero address!");
        require(newOwner_ != owner(), "The new owner cannot be the current owner!");
        require(newOwner_ != pendingOwner(), "The passed address is already the pending owner!");
        _setPendingOwner(newOwner_);
        emit TransferOwnershipInitiated(owner(), newOwner_);
        return true;
    }

    function acceptOwnership() external returns (bool) {
        require(msg.sender == pendingOwner(), "Only the pending owner can accept the ownership!");
        address sender = msg.sender;
        _transferOwnership(sender);
        _resetPendingOwner();
        return true;
    }

    function startRenounceProcess() external onlyOwner returns (bool) {
        require(!renounceUnlocked(), "Renounce process has been already unlocked!");
        _renounceUnlocked = true;
        emit RenounceProcessInitiated(owner());
        return true;
    }

    function terminateRenounceProcess() external onlyOwner returns (bool) {
        require(renounceUnlocked(), "Renounce process needs to be initiated first!");
        _renounceUnlocked = false;
        emit RenounceProcessTerminated(owner());
        return true;
    }

    function renounceOwnership() external onlyOwner returns (bool) {
        require(renounceUnlocked(), "Renounce process needs to be initiated first!");
        _transferOwnership(address(0));
        _resetPendingOwner();
        return true;
    }

    function _addEntryToOwnershipHistory(address previousOwner_, address newOwner_) internal {
        OwnershipChange memory ownershipChange = OwnershipChange(previousOwner_, newOwner_, block.number, blockhash(block.number), block.chainid);
        _ownershipHistory.push(ownershipChange);
    }

    function getOwnershipHistory() external view returns (OwnershipChange[] memory) {
        return _ownershipHistory;
    }
}