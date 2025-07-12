# BitForesight Protocol

## Overview

BitForesight is a next-generation decentralized Bitcoin price prediction platform built on Stacks Layer 2. The protocol transforms Bitcoin price speculation into a transparent, community-driven prediction market where users can leverage their market insights by staking STX tokens on Bitcoin's future price movements.

## Key Features

- **Oracle-Verified Settlements**: Automated market resolution using trusted price oracles
- **Dynamic Liquidity Pools**: Separate pools for bullish and bearish predictions
- **Algorithmic Reward Distribution**: Proportional rewards based on pool contributions
- **Bulletproof Security**: Leverages Bitcoin's proof-of-work consensus through Stacks Layer 2
- **Transparent Governance**: Administrative controls with clear access management

## System Architecture

### Core Components

1. **Prediction Markets**: Time-bound markets with opening and closing block heights
2. **Stake Management**: Escrow system for STX token deposits
3. **Oracle Integration**: External price feed integration for settlement
4. **Reward Distribution**: Automated payout system for winning participants
5. **Administrative Layer**: Protocol governance and configuration management

### Contract Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    BitForesight Protocol                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │ Market Creation │    │ Oracle System   │                │
│  │                 │    │                 │                │
│  │ • Initialize    │    │ • Price Feed    │                │
│  │ • Configure     │    │ • Settlement    │                │
│  │ • Validate      │    │ • Verification  │                │
│  └─────────────────┘    └─────────────────┘                │
│           │                       │                        │
│           ▼                       ▼                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              Prediction Engine                          │ │
│  │                                                         │ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │ │
│  │ │   Bullish   │  │   Bearish   │  │  Positions  │      │ │
│  │ │    Pool     │  │    Pool     │  │   Registry  │      │ │
│  │ └─────────────┘  └─────────────┘  └─────────────┘      │ │
│  └─────────────────────────────────────────────────────────┘ │
│           │                       │                        │
│           ▼                       ▼                        │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │ Reward System   │    │ Treasury Mgmt   │                │
│  │                 │    │                 │                │
│  │ • Calculate     │    │ • Fee Collection│                │
│  │ • Distribute    │    │ • Withdrawal    │                │
│  │ • Track Claims  │    │ • Escrow       │                │
│  └─────────────────┘    └─────────────────┘                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### Market Lifecycle

1. **Market Creation**
   - Admin initializes market with Bitcoin price snapshot
   - Sets opening and closing block heights
   - Assigns unique market ID

2. **Prediction Phase**
   - Users submit forecasts ("bull" or "bear")
   - STX tokens transferred to contract escrow
   - Pool balances updated dynamically

3. **Settlement Phase**
   - Oracle provides final Bitcoin price
   - Market resolved based on price movement
   - Winning direction determined

4. **Reward Distribution**
   - Winners claim proportional rewards
   - Protocol fees deducted automatically
   - Positions marked as claimed

### Data Structures

#### Prediction Markets

```clarity
{
  initial-btc-price: uint,     // Opening price snapshot
  final-btc-price: uint,       // Settlement price
  bullish-pool: uint,          // Total bullish stakes
  bearish-pool: uint,          // Total bearish stakes
  market-open-height: uint,    // Opening block height
  market-close-height: uint,   // Closing block height
  is-resolved: bool            // Settlement status
}
```

#### Participant Positions

```clarity
{
  price-direction: string,     // "bull" or "bear"
  staked-amount: uint,         // STX tokens committed
  rewards-claimed: bool        // Payout status
}
```

## Core Functions

### Market Management

- `initialize-prediction-market`: Create new prediction markets
- `settle-market-outcome`: Resolve markets with oracle data
- `get-market-data`: Retrieve market information

### User Operations

- `submit-forecast`: Submit price predictions with stakes
- `claim-forecast-rewards`: Withdraw winnings from resolved markets
- `get-participant-position`: Query user positions

### Administrative Controls

- `update-oracle-endpoint`: Modify authorized oracle address
- `adjust-min-stake`: Update minimum participation threshold
- `modify-fee-rate`: Adjust protocol fee percentage
- `withdraw-protocol-fees`: Extract accumulated fees

## Security Features

### Access Control

- Admin-only functions protected by sender verification
- Oracle authorization required for market settlement
- Participant validation for all user operations

### Input Validation

- Comprehensive parameter checking
- Balance verification before transfers
- Time-based market access controls

### Error Handling

- Standardized error codes (ERR-100 through ERR-106)
- Graceful failure modes
- Clear error messaging

## Economic Model

### Fee Structure

- Configurable protocol fee (default: 2%)
- Minimum stake threshold (default: 1 STX)
- Dynamic reward calculation based on pool ratios

### Reward Calculation

```
Total Reward = (User Stake × Total Pool) ÷ Winning Pool
Net Payout = Total Reward - Protocol Fee
```

## Deployment Requirements

### Prerequisites

- Stacks blockchain node access
- Oracle service integration
- Administrative wallet setup

### Configuration

- Set oracle endpoint address
- Configure minimum stake threshold
- Define protocol fee rate
- Initialize market parameters

## Usage Examples

### Creating a Market

```clarity
(initialize-prediction-market 
  u50000    ;; BTC price: $50,000
  u100      ;; Opens at block 100
  u200      ;; Closes at block 200
)
```

### Submitting a Prediction

```clarity
(submit-forecast 
  u1        ;; Market ID
  "bull"    ;; Price direction
  u1000000  ;; Stake: 1 STX
)
```

### Claiming Rewards

```clarity
(claim-forecast-rewards u1)  ;; Market ID
```

## Technical Specifications

- **Language**: Clarity
- **Blockchain**: Stacks Layer 2
- **Token**: STX
- **Oracle**: Configurable endpoint
- **Precision**: Micro-STX (uSTX) units

## License

This protocol is provided as-is for educational and development purposes. Please ensure compliance with applicable regulations in your jurisdiction before deployment.
