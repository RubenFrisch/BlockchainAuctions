## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| CircuitBreakerEmergencyController.sol | f61f251fa5103126fac3db5350205445cebfa26a |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **CircuitBreakerEmergencyController** | Implementation |  |||
| └ | isPaused | Public ❗️ |   |NO❗️ |
| └ | _turnEmergencyPauseOn | Internal 🔒 | 🛑  | onlyWhenNotPaused |
| └ | turnEmergencyPauseOn | External ❗️ | 🛑  |NO❗️ |
| └ | _turnEmergencyPauseOff | Internal 🔒 | 🛑  | onlyWhenPaused |
| └ | turnEmergencyPauseOff | External ❗️ | 🛑  |NO❗️ |


### Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |
