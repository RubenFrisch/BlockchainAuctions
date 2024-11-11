## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| AuctionsLogic.sol | bf850b77719ec5b88e8f876048f599c8329cd261 |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
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
