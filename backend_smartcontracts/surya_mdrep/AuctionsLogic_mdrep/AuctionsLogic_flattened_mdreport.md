## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| AuctionsLogic_flattened.sol | ced929cfc1436e5dc2f41298f0da01534765a584 |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
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
| **CancellableAuctionController** | Implementation |  |||
| └ | isCancellable | Public ❗️ |   |NO❗️ |
| └ | isCancelled | Public ❗️ |   |NO❗️ |
| └ | _configureAsCancellableAuction | Internal 🔒 | 🛑  | |
| └ | configureAsCancellableAuction | External ❗️ | 🛑  |NO❗️ |
| └ | _cancelAuction | Internal 🔒 | 🛑  | |
| └ | cancelAuction | External ❗️ | 🛑  |NO❗️ |
||||||
| **WhitelistAuctionController** | Implementation |  |||
| └ | closedAuction | Public ❗️ |   |NO❗️ |
| └ | _configureAsClosedAuction | Internal 🔒 | 🛑  | |
| └ | configureAsClosedAuction | External ❗️ | 🛑  |NO❗️ |
| └ | isWhitelisted | Public ❗️ |   |NO❗️ |
| └ | _whitelistParticipants | Internal 🔒 | 🛑  | |
| └ | whitelistParticipants | External ❗️ | 🛑  |NO❗️ |
||||||
| **EntryFeeController** | Implementation |  |||
| └ | getEntryFee | Public ❗️ |   |NO❗️ |
| └ | hasPaidEntryFee | Public ❗️ |   |NO❗️ |
| └ | hasWithdrawnEntryFee | Public ❗️ |   |NO❗️ |
| └ | _setEntryFee | Internal 🔒 | 🛑  | |
| └ | setEntryFee | External ❗️ | 🛑  |NO❗️ |
| └ | _payEntryFee | Internal 🔒 | 🛑  | |
| └ | payEntryFee | External ❗️ |  💵 |NO❗️ |
| └ | _withdrawEntryFee | Internal 🔒 | 🛑  | |
| └ | withdrawEntryFee | External ❗️ | 🛑  |NO❗️ |
||||||
| **CircuitBreakerEmergencyController** | Implementation |  |||
| └ | isPaused | Public ❗️ |   |NO❗️ |
| └ | _turnEmergencyPauseOn | Internal 🔒 | 🛑  | onlyWhenNotPaused |
| └ | turnEmergencyPauseOn | External ❗️ | 🛑  |NO❗️ |
| └ | _turnEmergencyPauseOff | Internal 🔒 | 🛑  | onlyWhenPaused |
| └ | turnEmergencyPauseOff | External ❗️ | 🛑  |NO❗️ |
||||||
| **BlacklistAuctionController** | Implementation |  |||
| └ | isBlacklistAuction | Public ❗️ |   |NO❗️ |
| └ | isBlacklistedParticipant | Public ❗️ |   |NO❗️ |
| └ | _configureAsBlacklistedAuction | Internal 🔒 | 🛑  | |
| └ | configureAsBlacklistedAuction | External ❗️ | 🛑  |NO❗️ |
| └ | _blacklistParticipants | Internal 🔒 | 🛑  | |
| └ | blacklistParticipants | External ❗️ | 🛑  |NO❗️ |
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
| **AuctionERC721** | Implementation | ERC721, ERC721URIStorage, ERC721Burnable, OwnershipController |||
| └ | <Constructor> | Public ❗️ | 🛑  | ERC721 |
| └ | safeMint | Public ❗️ | 🛑  | onlyOwner |
| └ | tokenURI | Public ❗️ |   |NO❗️ |
| └ | supportsInterface | Public ❗️ |   |NO❗️ |
||||||
| **AuctionsLogic** | Implementation | OwnershipController, CancellableAuctionController, WhitelistAuctionController, BlacklistAuctionController, EntryFeeController, CircuitBreakerEmergencyController |||
| └ | createNewAuction | External ❗️ | 🛑  | onlyOwner onlyWhenNotPaused onlyIfAuctionDoesNotExist |
| └ | bid | External ❗️ |  💵 | onlyWhenNotOwner onlyWhenNotPaused onlyIfAuctionExists whenNotCancelled onlyAfterStartBlock onlyBeforeEndBlock |
| └ | withdrawBid | External ❗️ | 🛑  | onlyIfAuctionExists |
| └ | auctionExists | Public ❗️ |   |NO❗️ |
| └ | auctionHighestBidAmount | Public ❗️ |   |NO❗️ |
| └ | auctionWinner | Public ❗️ |   |NO❗️ |
| └ | auctionStartBlock | Public ❗️ |   |NO❗️ |
| └ | auctionEndBlock | Public ❗️ |   |NO❗️ |
| └ | getBidAmountOfBidder | Public ❗️ |   |NO❗️ |
| └ | startingPrice | Public ❗️ |   |NO❗️ |
| └ | bidIncrement | Public ❗️ |   |NO❗️ |
| └ | reservePrice | Public ❗️ |   |NO❗️ |
| └ | contractETHBalance | External ❗️ |   |NO❗️ |
| └ | ownerWithdrew | Public ❗️ |   |NO❗️ |
| └ | auctionSnipeInterval | Public ❗️ |   |NO❗️ |
| └ | auctionSnipeBlocks | Public ❗️ |   |NO❗️ |
| └ | nftContractAddress | Public ❗️ |   |NO❗️ |
| └ | nftTokenID | Public ❗️ |   |NO❗️ |
| └ | getIPFS | External ❗️ |   |NO❗️ |
| └ | isSmartContract | Internal 🔒 |   | |
| └ | configureAsCancellableAuction | External ❗️ | 🛑  | onlyOwner onlyWhenNotPaused onlyIfAuctionExists onlyBeforeStartBlock |
| └ | cancelAuction | External ❗️ | 🛑  | onlyOwner onlyWhenNotPaused onlyIfAuctionExists onlyAfterStartBlock onlyBeforeEndBlock |
| └ | onERC721Received | External ❗️ |   |NO❗️ |
| └ | configureAsClosedAuction | External ❗️ | 🛑  | onlyOwner onlyWhenNotPaused onlyIfAuctionExists onlyBeforeStartBlock |
| └ | whitelistParticipants | External ❗️ | 🛑  | onlyOwner onlyWhenNotPaused onlyIfAuctionExists onlyBeforeStartBlock |
| └ | setEntryFee | External ❗️ | 🛑  | onlyOwner onlyWhenNotPaused onlyIfAuctionExists onlyBeforeStartBlock |
| └ | payEntryFee | External ❗️ |  💵 | onlyWhenNotOwner onlyWhenNotPaused onlyIfAuctionExists onlyBeforeStartBlock |
| └ | withdrawEntryFee | External ❗️ | 🛑  | onlyWhenNotOwner onlyIfAuctionExists |
| └ | turnEmergencyPauseOn | External ❗️ | 🛑  | onlyOwner onlyWhenNotPaused |
| └ | turnEmergencyPauseOff | External ❗️ | 🛑  | onlyOwner onlyWhenPaused |
| └ | configureAsBlacklistedAuction | External ❗️ | 🛑  | onlyOwner onlyWhenNotPaused onlyIfAuctionExists onlyBeforeStartBlock |
| └ | blacklistParticipants | External ❗️ | 🛑  | onlyOwner onlyWhenNotPaused onlyIfAuctionExists onlyBeforeStartBlock |


### Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |
