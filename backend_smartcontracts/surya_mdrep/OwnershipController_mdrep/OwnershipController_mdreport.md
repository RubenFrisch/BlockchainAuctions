## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| OwnershipController.sol | 942d757b4897a5258221d70a9263fb8d5dbf571c |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
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
