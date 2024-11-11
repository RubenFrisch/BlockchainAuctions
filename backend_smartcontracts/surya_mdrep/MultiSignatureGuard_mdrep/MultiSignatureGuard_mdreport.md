## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| MultiSignatureGuard.sol | cfa2825b6a736728f277a91f9907ea2a18b5a7fe |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **MultiSignatureGuard** | Implementation |  |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | currentSignatureCount | Public ❗️ |   |NO❗️ |
| └ | isSigner | Public ❗️ |   |NO❗️ |
| └ | hasSigned | Public ❗️ |   |NO❗️ |
| └ | getSignatureExpiryTime | Public ❗️ |   |NO❗️ |
| └ | _resetAllSignatures | Internal 🔒 | 🛑  | |
| └ | registerSignature | External ❗️ | 🛑  | onlySigner |


### Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |
