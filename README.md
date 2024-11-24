# Stacks DEX Smart Contract

A decentralized exchange (DEX) implementation on the Stacks blockchain using Clarity smart contracts. This DEX enables users to create liquidity pools, provide liquidity, execute token swaps, and manage liquidity positions.

## Table of Contents

- [Stacks DEX Smart Contract](#stacks-dex-smart-contract)
	- [Table of Contents](#table-of-contents)
	- [Overview](#overview)
	- [Features](#features)
	- [Contract Architecture](#contract-architecture)
		- [Data Structures](#data-structures)
	- [Core Functions](#core-functions)
		- [Pool Management](#pool-management)
		- [Trading](#trading)
		- [Read-Only Functions](#read-only-functions)
	- [Error Handling](#error-handling)
	- [Getting Started](#getting-started)
		- [Prerequisites](#prerequisites)
		- [Usage Example](#usage-example)
	- [Security Considerations](#security-considerations)
	- [Technical Specifications](#technical-specifications)
	- [Testing](#testing)
	- [Contributing](#contributing)
	- [License](#license)

## Overview

This smart contract implements an automated market maker (AMM) decentralized exchange that follows the constant product formula (x \* y = k). It supports SIP-010 compliant fungible tokens and includes essential features like liquidity provision, token swapping, and liquidity removal with built-in security measures.

## Features

- **Liquidity Pool Creation**: Create new trading pairs for SIP-010 compliant tokens
- **Liquidity Management**: Add and remove liquidity with slippage protection
- **Token Swapping**: Execute token swaps with configurable slippage tolerance
- **Fee System**: 0.3% fee on all trades (customizable)
- **Deadline Protection**: Transaction deadline enforcement to prevent stale trades
- **Automatic Price Discovery**: Based on constant product formula
- **Provider Tracking**: Complete liquidity provider position tracking

## Contract Architecture

### Data Structures

1. **Pools Map**

```clarity
{
    token-x: principal,
    token-y: principal,
    liquidity-total: uint,
    balance-x: uint,
    balance-y: uint,
    fee-rate: uint
}
```

2. **Liquidity Providers Map**

```clarity
{
    pool-id: { token-x: principal, token-y: principal },
    provider: principal,
    liquidity-provided: uint,
    rewards-claimed: uint
}
```

## Core Functions

### Pool Management

1. `create-pool`

   - Creates a new liquidity pool for token pair
   - Parameters: token-x, token-y, initial-x, initial-y
   - Returns: (response bool uint)

2. `add-liquidity`

   - Adds liquidity to an existing pool
   - Parameters: token-x, token-y, amount-x, amount-y, min-liquidity, deadline
   - Returns: (response uint uint)

3. `remove-liquidity`
   - Removes liquidity from a pool
   - Parameters: token-x, token-y, liquidity, min-amount-x, min-amount-y, deadline
   - Returns: (response (tuple (amount-x uint) (amount-y uint)) uint)

### Trading

1. `swap-exact-tokens`
   - Executes a token swap with exact input amount
   - Parameters: token-x, token-y, amount-in, min-amount-out, deadline
   - Returns: (response uint uint)

### Read-Only Functions

1. `get-pool-details`

   - Retrieves pool information
   - Parameters: token-x, token-y
   - Returns: (optional pool-data)

2. `get-provider-liquidity`
   - Gets provider's liquidity position
   - Parameters: token-x, token-y, provider
   - Returns: (optional provider-data)

## Error Handling

The contract includes comprehensive error codes:

| Code | Description          |
| ---- | -------------------- |
| 1000 | Not authorized       |
| 1001 | Insufficient balance |
| 1002 | Invalid pair         |
| 1003 | Invalid amount       |
| 1004 | Pool already exists  |
| 1005 | Pool not found       |
| 1006 | Slippage too high    |
| 1007 | Deadline expired     |
| 1008 | Zero liquidity       |

## Getting Started

### Prerequisites

- Stacks blockchain environment
- SIP-010 compliant tokens
- Clarity CLI tools

### Usage Example

```clarity
;; Create a new pool
(contract-call? .dex create-pool token-x token-y u1000000 u1000000)

;; Add liquidity
(contract-call? .dex add-liquidity token-x token-y u100000 u100000 u99000 u100)

;; Perform swap
(contract-call? .dex swap-exact-tokens token-x token-y u10000 u9900 u100)
```

## Security Considerations

1. **Slippage Protection**: All trading functions include minimum output parameters
2. **Deadline Mechanism**: Prevents stale transactions
3. **Balance Checks**: Comprehensive balance verification before operations
4. **Authorization**: Strict ownership and access controls
5. **Integer Overflow Protection**: Built-in Clarity protection against overflow
6. **Liquidity Provider Safety**: Minimum liquidity thresholds and proper tracking

## Technical Specifications

- **Contract Language**: Clarity
- **Token Standard**: SIP-010
- **Minimum Liquidity**: Dynamic based on pool size
- **Fee Structure**: 0.3% trading fee
- **Price Calculation**: Constant product formula (x \* y = k)
- **Slippage Protection**: Configurable minimum output amounts
- **Transaction Deadline**: Block height-based expiration

## Testing

To run the test suite:

1. Clone the repository
2. Install dependencies
3. Run test command:

```bash
clarinet console
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
