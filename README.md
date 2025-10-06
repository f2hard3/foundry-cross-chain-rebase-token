# Cross-Chain Rebase Token Example

This repository demonstrates a cross-chain rebase token system using Chainlink CCIP and Foundry. It includes Solidity smart contracts, deployment scripts, and integration tests for bridging tokens between EVM-compatible chains.

## Features

- **RebaseToken**: An ERC20-compatible token with rebase functionality.
- **RebaseTokenPool**: A pool contract for managing cross-chain token transfers.
- **Vault**: A vault contract for secure token storage.
- **Cross-Chain Bridging**: Uses Chainlink CCIP for secure token bridging.
- **Deployment Scripts**: Foundry scripts for deploying and bridging tokens.
- **Comprehensive Tests**: Foundry and Go-based integration tests.

## Repository Structure

```
.
├── src/                   # Solidity contracts
│   ├── RebaseToken.sol
│   ├── RebaseTokenPool.sol
│   ├── Vault.sol
│   └── interfaces/
├── script/                # Foundry deployment scripts
│   ├── BridgeTokens.s.sol
│   ├── ConfigurePool.s.sol
│   └── Deployer.s.sol
├── test/                  # Foundry Solidity tests
│   ├── CrossChain.t.sol
│   └── RebaseToken.t.sol
├── lib/                   # External dependencies (Chainlink CCIP, OpenZeppelin, etc.)
├── broadcast/             # Foundry broadcast files
├── cache/                 # Foundry build cache
├── .env                   # Environment variables
├── foundry.toml           # Foundry configuration
└── README.md              # This file
```

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/) (see `foundry.toml`)
- Node.js and npm (for some scripts and dependencies)
- Go (for integration tests in `lib/ccip`)

### Installation

1. **Clone the repository:**

   ```sh
   git clone <repo-url>
   cd foundry-cross-chain-rebase-token
   ```

2. **Install Foundry:**

   ```sh
   foundryup
   ```

3. **Install dependencies:**

   ```sh
   forge install
   ```

4. **Set up environment variables:**
   Copy `.env.example` to `.env` and fill in the required values.

### Building Contracts

```sh
forge build
```

### Running Tests

**Solidity tests:**

```sh
forge test
```

**Integration tests (Go):**

```sh
cd lib/ccip
go test ./...
```

### Deploying Contracts

Use the provided Foundry scripts in the `script/` directory. For example, to bridge tokens:

```sh
forge script script/BridgeTokens.s.sol --rpc-url <RPC_URL> --broadcast --private-key <PRIVATE_KEY> --sig "run(address,uint64,address,address,uint256,address)" <args>
```

Replace `<args>` with the required parameters:

- `receiverAddress`
- `destinationChainSelector`
- `routerAddress`
- `tokenToSendAddress`
- `amountToSend`
- `linkTokenAddress`

### Bridging Tokens

The [`BridgeTokensScript`](script/BridgeTokens.s.sol) script demonstrates how to bridge tokens using Chainlink CCIP. It prepares a CCIP message, approves the router to spend tokens, and sends the message to the destination chain.

## License

This project is licensed under the MIT License.

## Acknowledgements

- [Chainlink CCIP](https://chain.link/ccip)
- [Foundry](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)
