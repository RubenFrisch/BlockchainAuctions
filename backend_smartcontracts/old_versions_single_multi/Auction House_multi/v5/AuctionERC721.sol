// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "OwnershipControl.sol";

contract AuctionERC721 is ERC721, ERC721URIStorage, ERC721Burnable, OwnershipControl {
    uint256 private _nextTokenId;   //Variable that auto-increments after every NFT minted

    constructor()
        ERC721("AuctionERC721", "ANFT") //Set NFT contract name and symbol
    {}

    //Mint NFT and set the token URI a the same time, with tokenId auto-increment feature
    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // Compiler requires the following overrides due to multi-inheritance from ERC721 and ERC721URIStorage base abstract contracts
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}