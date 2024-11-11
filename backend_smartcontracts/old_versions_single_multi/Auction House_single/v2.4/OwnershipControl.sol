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

    event OwnershipTransferCompleted(address indexed previousOwner, address indexed newOwner);
    event TransferOwnershipInitiated(address indexed owner, address indexed pendingOwner);
    event RenounceProcessInitiated(address indexed owner);
    event RenounceProcessTerminated(address indexed owner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner(), "Transaction FAILED: Only the owner can call this function!");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    function renounceUnlocked() public view virtual returns (bool) {
        return _renounceUnlocked;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address previousOwner = owner();
        _owner = newOwner;
        _addEntryToOwnershipHistory(previousOwner, newOwner);
        emit OwnershipTransferCompleted(previousOwner, newOwner);
    }

    function _setPendingOwner(address newPendingOwner) internal virtual {
        _pendingOwner = newPendingOwner;
    }

    function resetPendingOwner() external virtual onlyOwner returns (bool) {
        delete _pendingOwner;
        return true;
    }

    function _resetPendingOwner() internal virtual {
        delete _pendingOwner;
    }

    function transferOwnership(address newOwner) external virtual onlyOwner returns (bool) {
        require(newOwner != address(0), "Transaction FAILED: The new owner cannot be the zero (burn) address!");
        require(newOwner != owner(), "Transaction FAILED: The new owner cannot be the current owner!");
        require(newOwner != pendingOwner(), "Transaction FAILED: The passed address is already the pending owner!");
        _setPendingOwner(newOwner);
        emit TransferOwnershipInitiated(owner(), newOwner);
        return true;
    }

    function acceptOwnership() external virtual returns (bool) {
        require(msg.sender == pendingOwner(), "Transaction FAILED: Only the pending owner can accept ownership!");
        address sender = msg.sender;
        _transferOwnership(sender);
        _resetPendingOwner();
        return true;
    }

    function startRenounceProcess() external virtual onlyOwner returns (bool) {
        require(!renounceUnlocked(), "Transaction FAILED: Renounce process is already unlocked!");
        _renounceUnlocked = true;
        emit RenounceProcessInitiated(owner());
        return true;
    }

    function terminateRenounceProcess() external virtual onlyOwner returns (bool) {
        require(renounceUnlocked(), "Transaction FAILED: Renounce process was not initiated!");
        _renounceUnlocked = false;
        emit RenounceProcessTerminated(owner());
        return true;
    }

    function renounceOwnership() external virtual onlyOwner returns (bool) {
        require(renounceUnlocked(), "Transaction FAILED: Renounce process was not initiated!");
        _transferOwnership(address(0));
        _resetPendingOwner();
        return true;
    }

    function _addEntryToOwnershipHistory(address previousOwner, address newOwner) internal virtual {
        OwnershipChange memory ownershipChange = OwnershipChange(previousOwner, newOwner, block.number, blockhash(block.number), block.chainid);
        _ownershipHistory.push(ownershipChange);
    }

    function getOwnershipHistory() external view returns (OwnershipChange[] memory) {
        return _ownershipHistory;
    }
}