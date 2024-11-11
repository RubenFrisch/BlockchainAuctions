## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| OwnershipController_flattened.sol | c2163641dfc629082ab76b4a0ab444253c6b1454 |


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


### Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |
