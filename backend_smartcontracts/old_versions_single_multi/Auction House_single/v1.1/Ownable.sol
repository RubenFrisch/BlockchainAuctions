// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

abstract contract Ownable {

    address private _owner;

    mapping(address => OwnerData) private _ownerMap;

    struct OwnerData {
        uint256 _ownerBlockNumber;
        uint256 _ownerBlockTimestamp;
        bytes32 _ownerBlockhash;
    }
    

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        _transferOwnership(msg.sender);
    }


    modifier onlyOwner() {
        _checkOwner();
        _;
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "TRANSACTION DENIED: only the owner has the right to call this function!");
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "TRANSACTION ERROR: only non-zero address arguments are allowed with normal ownership transfers!");
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        _addOwnerToMap();
        emit OwnershipTransferred(oldOwner, newOwner);
    }


    function _addOwnerToMap() internal virtual {
        uint256 ownerBlockNumber = block.number;
        uint256 ownerBlockTimestamp = block.timestamp;
        bytes32 ownerBlockhash = blockhash(ownerBlockNumber);

        _ownerMap[owner()] = OwnerData(ownerBlockNumber, ownerBlockTimestamp, ownerBlockhash);
    }


    function getOwnerData(address ownerAddress) public view onlyOwner returns (OwnerData memory) {
        return (_ownerMap[ownerAddress]);
    }
}