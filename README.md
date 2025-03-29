# DAO Treasury Management System

A comprehensive treasury management system built on Clarity for DAOs to manage multi-asset portfolios with governance, risk management, and automated strategies.

## Overview

This smart contract system enables DAOs to collectively manage their treasury assets with sophisticated financial strategies while maintaining decentralized governance. It leverages Clarity's predictable execution and Bitcoin integration capabilities to provide a secure, transparent, and efficient treasury management solution.

## Key Features

### Multi-Asset Portfolio Management
- Support for diverse assets (STX, BTC, fungible tokens)
- Real-time price tracking through oracles
- Portfolio composition analytics and allocation tracking
- Risk scoring for assets and overall portfolio

### Risk-Adjusted Investment Strategies
- Create and propose predefined investment strategies
- Risk profile calculation for strategies
- Validation against DAO risk tolerance parameters
- Performance tracking for strategies over time

### Proposal and Voting System
- Comprehensive governance for treasury decisions
- Multiple proposal types (asset allocation, strategy changes, parameter updates)
- Configurable voting periods and quorum requirements
- Time-delayed execution for security

### Performance Analytics and Reporting
- Historical performance tracking for assets and strategies
- Customizable reporting periods
- Comparison against benchmarks
- Gas and transaction cost tracking

### Dollar-Cost Averaging and Rebalancing
- Automated DCA schedules for gradually building positions
- Configurable rebalancing thresholds
- Automatic or governance-approved rebalancing
- Cost-optimized execution of trades

## Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) for local development and testing
- A Stacks wallet for deployment and management
- Access to price oracles for asset pricing

### Deployment
1. Deploy the contract to the Stacks blockchain:
```bash
clarinet deploy --network=mainnet
```

2. Initialize the DAO treasury with basic parameters:
```clarity
(contract-call? .dao-treasury-management initialize 
  "MyDAO Treasury" 
  'SP2ZNGJ85ENDY6QRHQ5P2D4FXKGZWCKTB2T0Z55KS.my-governance-token
  'SP2ZNGJ85ENDY6QRHQ5P2D4FXKGZWCKTB2T0Z55KS.guardian)
```

3. Register assets that the treasury will manage:
```clarity
(contract-call? .dao-treasury-management register-asset 
  "stx" 
  "Stacks Token" 
  "stx" 
  none 
  'SP2ZNGJ85ENDY6QRHQ5P2D4FXKGZWCKTB2T0Z55KS.stx-price-oracle 
  u3 
  u8)
```

## Usage Examples

### Creating an Investment Strategy
```clarity
(contract-call? .dao-treasury-management create-strategy
  "Conservative BTC-STX Strategy"
  "A low-risk strategy with 70% STX and 30% BTC allocation"
  (list 
    { asset-id: "stx", allocation-bp: u7000 }
    { asset-id: "btc", allocation-bp: u3000 }
  ))
```

### Submitting a Strategy Proposal
```clarity
(contract-call? .dao-treasury-management submit-proposal
  "Implement Conservative BTC-STX Strategy"
  "This proposal will shift our treasury to a more conservative allocation"
  u1  ;; Strategy Change proposal type
  (some u1)  ;; Strategy ID
  none
  none
  (list "stx" "btc")
  none
  none)
```

### Voting on a Proposal
```clarity
(contract-call? .dao-treasury-management cast-vote u1 "for")
```

### Creating a DCA Schedule
```clarity
(contract-call? .dao-treasury-management create-dca-schedule
  "Weekly BTC Accumulation"
  "stx"  ;; Source asset
  "btc"  ;; Target asset
  u10000000  ;; 0.1 STX per period
  u1008  ;; Weekly (7 days)
  u52)  ;; For one year
```

### Generating a Performance Report
```clarity
(contract-call? .dao-treasury-management generate-performance-report
  "Q2 2025 Performance Report"
  u36000  ;; Start block
  u50000  ;; End block
  none)  ;; No specific strategy filter
```

## Governance Process

1. **Proposal Submission**: Any DAO member with sufficient governance tokens can submit a proposal
2. **Voting Period**: Members vote during the configured voting period (default 7 days)
3. **Execution Delay**: Approved proposals have a time delay before execution (default 1 day)
4. **Execution**: After the delay, anyone can trigger the execution of approved proposals

## Security Features

- Emergency shutdown capability for critical situations
- Tiered authorization system with specialized roles
- Timelock delays for major treasury changes
- Guardian role for emergency interventions
- Automated checks for risk tolerance violations

## Architecture

The system consists of several integrated components:
- Asset registry and price oracle integration
- Strategy management system
- Governance and voting mechanism
- DCA and rebalancing automation
- Reporting and analytics

## Extending the System

The contract can be extended by:
1. Implementing custom oracles for specialized assets
2. Adding new proposal types for additional governance capabilities
3. Creating advanced investment strategies
4. Building front-end interfaces for DAO members

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- Built on the Stacks blockchain
- Leverages Clarity's predictability and Bitcoin integration
- Inspired by traditional treasury management systems and DeFi protocols