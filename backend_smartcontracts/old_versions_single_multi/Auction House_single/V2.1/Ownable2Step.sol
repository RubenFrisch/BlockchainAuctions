// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "Ownable.sol";

abstract contract Ownable2Step is Ownable {

    address private _pendingOwner;

    bool private _renounceProcessAccepted;


    event OwnershipTransferStarted(address indexed previousOwner_, address indexed newOwner_);

    event RenounceOwnershipProcessStarted(address indexed owner_);

    event RenounceOwnershipProcessReset(address indexed owner_);


    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }


    function renounceProcessAccepted() public view virtual returns (bool) {
        return _renounceProcessAccepted;
    }


    function transferOwnership(address newOwner_) public virtual override onlyOwner {
        require(newOwner_ != pendingOwner(), "TRANSACTION WARNING: the pending owner is already set!");
        require(newOwner_ != owner(), "TRANSACTION WARNING: the specified address is already the owner!");
        _pendingOwner = newOwner_;
        emit OwnershipTransferStarted(owner(), newOwner_);
    }


    function _transferOwnership(address newOwner_) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner_);
    }


    function acceptOwnership() public virtual {
        address sender = msg.sender;
        require(pendingOwner() == sender, "TRANSACTION DENIED: only the new pending owner can accept the transfer of ownership!");
        _transferOwnership(sender);
    }


    function resetPendingOwner() public virtual onlyOwner {
        delete _pendingOwner;
    }


    function startRenounceOwnershipProcess() public virtual onlyOwner {
        require(!_renounceProcessAccepted, "TRANSACTION WARNING: the renounce process has already begun!");
        _renounceProcessAccepted = true;
        emit RenounceOwnershipProcessStarted(owner());
    }


    function resetRenounceOwnershipProcess() public virtual onlyOwner {
        require(_renounceProcessAccepted, "TRANSACTION ERROR: the renounce process has not been started.");
        _renounceProcessAccepted = false;
        emit RenounceOwnershipProcessReset(owner());
    }

        
    function renounceOwnership() public virtual override onlyOwner {
        require(_renounceProcessAccepted, "TRANSACTION ERROR: the renounce process must be initiated before it can be completed! This 2-step mechanism is implemented in order to ensure there can be no accidental renounce due to user error.");
        super._transferOwnership(address(0));
    }
}