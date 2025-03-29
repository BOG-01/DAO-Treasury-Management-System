;;; DAO Treasury Management System
;; A comprehensive treasury management system for DAOs

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-asset-exists (err u102))
(define-constant err-asset-not-found (err u103))
(define-constant err-insufficient-funds (err u104))
(define-constant err-invalid-parameters (err u105))
(define-constant err-strategy-exists (err u106))
(define-constant err-strategy-not-found (err u107))
(define-constant err-proposal-exists (err u108))
(define-constant err-proposal-not-found (err u109))
(define-constant err-vote-already-cast (err u110))
(define-constant err-voting-period-ended (err u111))
(define-constant err-voting-period-active (err u112))
(define-constant err-proposal-not-approved (err u113))
(define-constant err-proposal-already-executed (err u114))
(define-constant err-allocation-exceeded (err u115))
(define-constant err-risk-exceeded (err u116))
(define-constant err-schedule-exists (err u117))
(define-constant err-schedule-not-found (err u118))
(define-constant err-rebalance-in-progress (err u119))
(define-constant err-strategy-in-use (err u120))
(define-constant err-emergency-shutdown (err u121))
(define-constant err-not-enough-votes (err u122))
(define-constant err-insufficient-quorum (err u123))
(define-constant err-asset-allocation-mismatch (err u124))
(define-constant err-transaction-failed (err u125))
(define-constant err-oracle-error (err u126))

;; DAO parameters
(define-data-var treasury-name (string-ascii 64) "DAO Treasury")
(define-data-var dao-token-contract principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.governance-token)
(define-data-var next-proposal-id uint u1)
(define-data-var next-strategy-id uint u1)
(define-data-var next-schedule-id uint u1)
(define-data-var next-report-id uint u1)
(define-data-var emergency-shutdown bool false)
(define-data-var quorum-threshold uint u10) ;; 10% of total token supply
(define-data-var voting-period uint u1008) ;; 7 days at 144 blocks/day
(define-data-var execution-delay uint u144) ;; 1 day delay after approval
(define-data-var minimum-proposal-threshold uint u100000000) ;; Requires 1 token to propose (assuming 8 decimals)
(define-data-var rebalance-threshold uint u1000) ;; 10% threshold for auto-rebalance
(define-data-var max-risk-score uint u7) ;; Maximum portfolio risk score (1-10)
(define-data-var dca-executor principal contract-owner)
(define-data-var rebalance-executor principal contract-owner)
(define-data-var fees-bp uint u50) ;; 0.5% fee in basis points
(define-data-var guardian principal contract-owner) ;; Emergency guardian

;; Proposal types
;; 0 = Asset Allocation, 1 = Strategy Change, 2 = Parameter Change, 3 = DCA Schedule, 4 = Manual Transaction
(define-data-var proposal-types (list 5 (string-ascii 20)) (list "Asset Allocation" "Strategy Change" "Parameter Change" "DCA Schedule" "Manual Transaction"))

;; Supported assets 
(define-map assets
  { asset-id: (string-ascii 20) }
  {
    name: (string-ascii 40),
    token-type: (string-ascii 10), ;; "stx", "ft", "nft", "btc"
    contract: (optional principal),
    oracle: principal,
    current-price: uint, ;; Price in STX with 8 decimals
    last-price-update: uint,
    historical-prices: (list 30 { price: uint, block-height: uint }),
    risk-score: uint, ;; 1-10 risk score (higher is riskier)
    current-allocation: uint, ;; Current allocation in basis points
    target-allocation: uint, ;; Target allocation in basis points
    balance: uint, ;; Current balance
    value-stx: uint, ;; Value in STX with 8 decimals
    decimals: uint,
    last-rebalance: uint,
    performance-7d: int, ;; 7-day performance in basis points (+/-)
    performance-30d: int, ;; 30-day performance in basis points (+/-)
    performance-90d: int, ;; 90-day performance in basis points (+/-)
    enabled: bool
  }
)

;; Investment strategies
(define-map strategies
  { strategy-id: uint }
  {
    name: (string-ascii 64),
    description: (string-utf8 256),
    risk-profile: uint, ;; 1-10 risk score (higher is riskier)
    allocations: (list 20 { asset-id: (string-ascii 20), allocation-bp: uint }),
    creator: principal,
    created-at: uint,
    last-modified: uint,
    approved: bool,
    active: bool,
    performance-all-time: int, ;; Basis points
    start-value: uint, ;; STX value when strategy started
    current-value: uint ;; Current STX value
  }
)
