// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "OwnershipController.sol";

/// @title ERC-721 NFT token contract implementation
/// @author Ruben Frisch (Óbuda University - John von Neumann Faculty of Informatics, Business Informatics MSc)
/// @notice ERC-721 NFT token contract implementation with advanced URI management, NFT token burning, auto-incrementing NFT token IDs, and ownership control
/// @dev ERC-721 NFT token contract implementation with advanced URI management, NFT token burning, auto-incrementing NFT token IDs, and ownership control
contract AuctionERC721 is 
    ERC721, 
    ERC721URIStorage, 
    ERC721Burnable, 
    OwnershipController 
{
    
    /// @dev Stores the token ID number for the next NFT (storage variable used for the auto-incremented NFT token ID feature)
    uint256 private _nextTokenId;

    /// @dev Constructor that initializes the ERC721 base contract, sets the name and symbol of the NFT collection
    constructor()
        ERC721("AuctionERC721", "ANFT")
    {}

    /// @dev Mints a new NFT token to an address and sets the specified URI and auto-incremented token ID
    /// @notice Mints a new NFT token to an address with the specified URI and auto-incremented token ID
    /// @param to_ Address that will receive the minted NFT
    /// @param uri_ The URI of the minted NFT
    /// @custom:requirement-modifier Only the owner can mint new NFTs
    function safeMint(address to_, string memory uri_) 
        public 
        onlyOwner 
    {
        uint256 tokenId = _nextTokenId++; //Current value of _nextTokenId is assigned to tokenId, and then _nextTokenId is incremented by 1 for the next mint
        _safeMint(to_, tokenId);
        _setTokenURI(tokenId, uri_);
    }

    /// @dev Retrieves the URI associated with the specific NFT token with tokenID_
    /// @dev Overrides both the ERC721 and ERC721URIStorage versions of the tokenURI function (multiple inheritance)
    /// @dev C3 linearization algorithm resolves the multiple inheritance, where the inheritance order is ERC721URIStorage first, then ERC721 second
    /// @dev Looks for tokenURI function in ERC721URIStorage first, If it finds the implementation there, it will call that function. If not implemented, call tokenURI from ERC721 base contract
    /// @notice Retrieves the URI associated with the specific NFT token with tokenID_
    /// @param tokenID_ The token ID of the NFT to be retrieved the token URI for
    /// @return Returns the URI (Uniform Resource Identifier) of the NFT with tokenId_
    function tokenURI(uint256 tokenID_) 
        public 
        view 
        override(ERC721, ERC721URIStorage) //C3 linearization multiple inheritance
        returns (string memory) 
    {
        return super.tokenURI(tokenID_);
    }

    /// @dev Checks whether the contract supports a specific interface or not
    /// @dev Implementation of the supportsInterface function, which is part of the ERC-165 standard
    /// @dev ERC-165 standard allows smart contracts to declare which interfaces they support
    /// @dev Interfaces have identifiers, which is the first 4 bytes of the Keccak-256 hash of an interface's signature
    /// @dev The interface ID of ERC721 is 0x80ac58cd
    /// @dev If one of the base contracts implements the interface, the function returns true
    /// @dev Uses multiple inheritance which is resolved by C3 linearization, ERC721URIStorage is looked up first, then ERC721
    /// @notice Checks whether the contract supports a specific interface or not
    /// @param interfaceID_ The interface identifier (first 4 bytes of the Keccak-256 hash of an interface's signature
    /// @return Returns a boolean literal indicating whether the contract supports the specified interface or not
    function supportsInterface(bytes4 interfaceID_) 
        public 
        view 
        override(ERC721, ERC721URIStorage) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceID_);
    }
}