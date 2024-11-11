## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| AuctionERC721_flattened.sol | 3d3946575122886ce14fc68689c2baff02ceefce |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **IERC165** | Interface |  |||
| └ | supportsInterface | External ❗️ |   |NO❗️ |
||||||
| **IERC721** | Interface | IERC165 |||
| └ | balanceOf | External ❗️ |   |NO❗️ |
| └ | ownerOf | External ❗️ |   |NO❗️ |
| └ | safeTransferFrom | External ❗️ | 🛑  |NO❗️ |
| └ | safeTransferFrom | External ❗️ | 🛑  |NO❗️ |
| └ | transferFrom | External ❗️ | 🛑  |NO❗️ |
| └ | approve | External ❗️ | 🛑  |NO❗️ |
| └ | setApprovalForAll | External ❗️ | 🛑  |NO❗️ |
| └ | getApproved | External ❗️ |   |NO❗️ |
| └ | isApprovedForAll | External ❗️ |   |NO❗️ |
||||||
| **IERC721Receiver** | Interface |  |||
| └ | onERC721Received | External ❗️ | 🛑  |NO❗️ |
||||||
| **IERC721Metadata** | Interface | IERC721 |||
| └ | name | External ❗️ |   |NO❗️ |
| └ | symbol | External ❗️ |   |NO❗️ |
| └ | tokenURI | External ❗️ |   |NO❗️ |
||||||
| **Context** | Implementation |  |||
| └ | _msgSender | Internal 🔒 |   | |
| └ | _msgData | Internal 🔒 |   | |
| └ | _contextSuffixLength | Internal 🔒 |   | |
||||||
| **Math** | Library |  |||
| └ | tryAdd | Internal 🔒 |   | |
| └ | trySub | Internal 🔒 |   | |
| └ | tryMul | Internal 🔒 |   | |
| └ | tryDiv | Internal 🔒 |   | |
| └ | tryMod | Internal 🔒 |   | |
| └ | max | Internal 🔒 |   | |
| └ | min | Internal 🔒 |   | |
| └ | average | Internal 🔒 |   | |
| └ | ceilDiv | Internal 🔒 |   | |
| └ | mulDiv | Internal 🔒 |   | |
| └ | mulDiv | Internal 🔒 |   | |
| └ | sqrt | Internal 🔒 |   | |
| └ | sqrt | Internal 🔒 |   | |
| └ | log2 | Internal 🔒 |   | |
| └ | log2 | Internal 🔒 |   | |
| └ | log10 | Internal 🔒 |   | |
| └ | log10 | Internal 🔒 |   | |
| └ | log256 | Internal 🔒 |   | |
| └ | log256 | Internal 🔒 |   | |
| └ | unsignedRoundsUp | Internal 🔒 |   | |
||||||
| **SignedMath** | Library |  |||
| └ | max | Internal 🔒 |   | |
| └ | min | Internal 🔒 |   | |
| └ | average | Internal 🔒 |   | |
| └ | abs | Internal 🔒 |   | |
||||||
| **Strings** | Library |  |||
| └ | toString | Internal 🔒 |   | |
| └ | toStringSigned | Internal 🔒 |   | |
| └ | toHexString | Internal 🔒 |   | |
| └ | toHexString | Internal 🔒 |   | |
| └ | toHexString | Internal 🔒 |   | |
| └ | equal | Internal 🔒 |   | |
||||||
| **ERC165** | Implementation | IERC165 |||
| └ | supportsInterface | Public ❗️ |   |NO❗️ |
||||||
| **IERC20Errors** | Interface |  |||
||||||
| **IERC721Errors** | Interface |  |||
||||||
| **IERC1155Errors** | Interface |  |||
||||||
| **ERC721** | Implementation | Context, ERC165, IERC721, IERC721Metadata, IERC721Errors |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | supportsInterface | Public ❗️ |   |NO❗️ |
| └ | balanceOf | Public ❗️ |   |NO❗️ |
| └ | ownerOf | Public ❗️ |   |NO❗️ |
| └ | name | Public ❗️ |   |NO❗️ |
| └ | symbol | Public ❗️ |   |NO❗️ |
| └ | tokenURI | Public ❗️ |   |NO❗️ |
| └ | _baseURI | Internal 🔒 |   | |
| └ | approve | Public ❗️ | 🛑  |NO❗️ |
| └ | getApproved | Public ❗️ |   |NO❗️ |
| └ | setApprovalForAll | Public ❗️ | 🛑  |NO❗️ |
| └ | isApprovedForAll | Public ❗️ |   |NO❗️ |
| └ | transferFrom | Public ❗️ | 🛑  |NO❗️ |
| └ | safeTransferFrom | Public ❗️ | 🛑  |NO❗️ |
| └ | safeTransferFrom | Public ❗️ | 🛑  |NO❗️ |
| └ | _ownerOf | Internal 🔒 |   | |
| └ | _getApproved | Internal 🔒 |   | |
| └ | _isAuthorized | Internal 🔒 |   | |
| └ | _checkAuthorized | Internal 🔒 |   | |
| └ | _increaseBalance | Internal 🔒 | 🛑  | |
| └ | _update | Internal 🔒 | 🛑  | |
| └ | _mint | Internal 🔒 | 🛑  | |
| └ | _safeMint | Internal 🔒 | 🛑  | |
| └ | _safeMint | Internal 🔒 | 🛑  | |
| └ | _burn | Internal 🔒 | 🛑  | |
| └ | _transfer | Internal 🔒 | 🛑  | |
| └ | _safeTransfer | Internal 🔒 | 🛑  | |
| └ | _safeTransfer | Internal 🔒 | 🛑  | |
| └ | _approve | Internal 🔒 | 🛑  | |
| └ | _approve | Internal 🔒 | 🛑  | |
| └ | _setApprovalForAll | Internal 🔒 | 🛑  | |
| └ | _requireOwned | Internal 🔒 |   | |
| └ | _checkOnERC721Received | Private 🔐 | 🛑  | |
||||||
| **IERC4906** | Interface | IERC165, IERC721 |||
||||||
| **ERC721URIStorage** | Implementation | IERC4906, ERC721 |||
| └ | supportsInterface | Public ❗️ |   |NO❗️ |
| └ | tokenURI | Public ❗️ |   |NO❗️ |
| └ | _setTokenURI | Internal 🔒 | 🛑  | |
||||||
| **ERC721Burnable** | Implementation | Context, ERC721 |||
| └ | burn | Public ❗️ | 🛑  |NO❗️ |
||||||
| **TimelockGuard** | Implementation |  |||
| └ | getQueueTime | Public ❗️ |   |NO❗️ |
| └ | _resetQueue | Internal 🔒 | 🛑  | |
| └ | _startQueue | Internal 🔒 | 🛑  | |
| └ | startQueue | External ❗️ | 🛑  |NO❗️ |
||||||
| **MultiSignatureGuard** | Implementation |  |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | currentSignatureCount | Public ❗️ |   |NO❗️ |
| └ | isSigner | Public ❗️ |   |NO❗️ |
| └ | hasSigned | Public ❗️ |   |NO❗️ |
| └ | getSignatureExpiryTime | Public ❗️ |   |NO❗️ |
| └ | _resetAllSignatures | Internal 🔒 | 🛑  | |
| └ | registerSignature | External ❗️ | 🛑  | onlySigner |
||||||
| **OwnershipController** | Implementation | TimelockGuard, MultiSignatureGuard |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | owner | Public ❗️ |   |NO❗️ |
| └ | pendingOwner | Public ❗️ |   |NO❗️ |
| └ | renounceUnlocked | Public ❗️ |   |NO❗️ |
| └ | _transferOwnership | Internal 🔒 | 🛑  | |
| └ | _setPendingOwner | Internal 🔒 | 🛑  | |
| └ | resetPendingOwner | External ❗️ | 🛑  | onlyOwner |
| └ | _resetPendingOwner | Internal 🔒 | 🛑  | |
| └ | startQueue | External ❗️ | 🛑  | onlyOwner multiSignatureGuard |
| └ | socialGuardianRecovery | External ❗️ | 🛑  | onlySigner timelocked multiSignatureGuard |
| └ | transferOwnership | External ❗️ | 🛑  | onlyOwner timelocked multiSignatureGuard |
| └ | acceptOwnership | External ❗️ | 🛑  |NO❗️ |
| └ | startRenounceProcess | External ❗️ | 🛑  | onlyOwner timelocked multiSignatureGuard |
| └ | terminateRenounceProcess | External ❗️ | 🛑  | onlyOwner |
| └ | renounceOwnership | External ❗️ | 🛑  | onlyOwner |
||||||
| **AuctionERC721** | Implementation | ERC721, ERC721URIStorage, ERC721Burnable, OwnershipController |||
| └ | <Constructor> | Public ❗️ | 🛑  | ERC721 |
| └ | safeMint | Public ❗️ | 🛑  | onlyOwner |
| └ | tokenURI | Public ❗️ |   |NO❗️ |
| └ | supportsInterface | Public ❗️ |   |NO❗️ |


### Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |
