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
;; Governance proposals
(define-map proposals
  { proposal-id: uint }
  {
    title: (string-ascii 64),
    description: (string-utf8 512),
    proposer: principal,
    proposal-type: uint,
    created-at: uint,
    voting-ends-at: uint,
    execution-delay-until: uint,
    votes-for: uint,
    votes-against: uint,
    votes-abstain: uint,
    status: (string-ascii 10), ;; "active", "approved", "rejected", "executed", "cancelled"
    executed-at: (optional uint),
    strategy-id: (optional uint), ;; For strategy proposals
    parameter-key: (optional (string-ascii 30)), ;; For parameter change proposals
    parameter-value: (optional uint), ;; For parameter change proposals
    assets-affected: (list 10 (string-ascii 20)), ;; For asset allocation proposals
    transaction-data: (optional (string-utf8 512)), ;; For manual transaction proposals
    dca-schedule-id: (optional uint), ;; For DCA schedule proposals
    voters: (list 100 principal)
  }
)

;; Votes cast by members
(define-map votes
  { proposal-id: uint, voter: principal }
  {
    vote: (string-ascii 7), ;; "for", "against", or "abstain"
    voting-power: uint,
    vote-cast-at: uint
  }
)

;; DCA (Dollar-Cost Averaging) schedules
(define-map dca-schedules
  { schedule-id: uint }
  {
    name: (string-ascii 64),
    source-asset: (string-ascii 20),
    target-asset: (string-ascii 20),
    amount-per-period: uint,
    period-length: uint, ;; In blocks
    last-execution: uint,
    next-execution: uint,
    total-periods: uint,
    periods-executed: uint,
    created-at: uint,
    creator: principal,
    status: (string-ascii 10), ;; "active", "paused", "completed", "cancelled"
    average-price: uint,
    total-spent: uint,
    total-acquired: uint
  }
)

;; Rebalancing operations
(define-map rebalance-operations
  { rebalance-id: uint }
  {
    initiated-at: uint,
    completed-at: (optional uint),
    initiator: principal,
    status: (string-ascii 10), ;; "active", "completed", "failed"
    actions: (list 20 {
      asset-id: (string-ascii 20),
      action: (string-ascii 10), ;; "buy", "sell"
      amount: uint,
      value-stx: uint,
      completed: bool
    }),
    starting-portfolio-value: uint,
    ending-portfolio-value: uint,
    gas-cost: uint
  }
)

;; Performance reports
(define-map performance-reports
  { report-id: uint }
  {
    title: (string-ascii 64),
    generated-at: uint,
    period-start: uint,
    period-end: uint,
    total-value-start: uint,
    total-value-end: uint,
    performance-bp: int,
    assets-performance: (list 20 {
      asset-id: (string-ascii 20),
      value-start: uint,
      value-end: uint,
      performance-bp: int
    }),
    transactions-count: uint,
    gas-spent: uint,
    strategy-id: (optional uint)
  }
)
;; DAO parameters that can be changed via governance
(define-map dao-parameters
  { param-key: (string-ascii 30) }
  { 
    param-value: uint,
    param-type: (string-ascii 10), ;; "uint", "principal", "bool"
    last-updated: uint,
    updater: principal,
    description: (string-ascii 64)
  }
)

;; Initialize the DAO treasury
(define-public (initialize 
  (name (string-ascii 64))
  (dao-token principal)
  (guardian-address principal))
  
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    ;; Set initial parameters
    (var-set treasury-name name)
    (var-set dao-token-contract dao-token)
    (var-set guardian guardian-address)
    
    ;; Initialize default parameters
    (map-set dao-parameters
      { param-key: "quorum-threshold" }
      {
        param-value: u10,
        param-type: "uint",
        last-updated: block-height,
        updater: tx-sender,
        description: "Percentage of total token supply needed for quorum"
      }
    )
    
    (map-set dao-parameters
      { param-key: "voting-period" }
      {
        param-value: u1008,
        param-type: "uint",
        last-updated: block-height,
        updater: tx-sender,
        description: "Voting period duration in blocks (7 days)"
      }
    )
    
    (map-set dao-parameters
      { param-key: "execution-delay" }
      {
        param-value: u144,
        param-type: "uint",
        last-updated: block-height,
        updater: tx-sender,
        description: "Delay before approved proposals can be executed (1 day)"
      }
    )
    
    (map-set dao-parameters
      { param-key: "minimum-proposal-threshold" }
      {
        param-value: u100000000,
        param-type: "uint",
        last-updated: block-height,
        updater: tx-sender,
        description: "Minimum tokens required to submit a proposal"
      }
    )
    
    (map-set dao-parameters
      { param-key: "rebalance-threshold" }
      {
        param-value: u1000,
        param-type: "uint",
        last-updated: block-height,
        updater: tx-sender,
        description: "Threshold for auto-rebalancing (10%)"
      }
    )
    
    (map-set dao-parameters
      { param-key: "max-risk-score" }
      {
        param-value: u7,
        param-type: "uint",
        last-updated: block-height,
        updater: tx-sender,
        description: "Maximum portfolio risk score (1-10)"
      }
    )
    
    (map-set dao-parameters
      { param-key: "fees-bp" }
      {
        param-value: u50,
        param-type: "uint",
        last-updated: block-height,
        updater: tx-sender,
        description: "Treasury management fees in basis points (0.5%)"
      }
    )
    
    (ok true)
  )
)

;; Register a new asset with the treasury
(define-public (register-asset
  (asset-id (string-ascii 20))
  (name (string-ascii 40))
  (token-type (string-ascii 10))
  (contract (optional principal))
  (oracle principal)
  (risk-score uint)
  (decimals uint))
  
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (var-get emergency-shutdown)) err-emergency-shutdown)
    (asserts! (is-none (map-get? assets { asset-id: asset-id })) err-asset-exists)
    
    ;; Validate parameters
    (asserts! (or (is-eq token-type "stx") 
                (is-eq token-type "ft") 
                (is-eq token-type "nft") 
                (is-eq token-type "btc")) 
              err-invalid-parameters)
    (asserts! (and (>= risk-score u1) (<= risk-score u10)) err-invalid-parameters)
    
    ;; If token is FT or NFT, contract must be provided
    (asserts! (or (is-eq token-type "stx") 
                (is-eq token-type "btc") 
                (is-some contract)) 
              err-invalid-parameters)
    
    ;; Create asset entry
    (map-set assets
      { asset-id: asset-id }
      {
        name: name,
        token-type: token-type,
        contract: contract,
        oracle: oracle,
        current-price: u0,
        last-price-update: block-height,
        historical-prices: (list),
        risk-score: risk-score,
        current-allocation: u0,
        target-allocation: u0,
        balance: u0,
        value-stx: u0,
        decimals: decimals,
        last-rebalance: block-height,
        performance-7d: (to-int 0),
        performance-30d: (to-int 0),
        performance-90d: (to-int 0),
        enabled: true
      }
    )
    
    (ok asset-id)
  )
)

;; Update asset price from oracle
(define-public (update-asset-price (asset-id (string-ascii 20)) (price uint))
  (let (
    (oracle tx-sender)
    (asset (unwrap! (map-get? assets { asset-id: asset-id }) err-asset-not-found))
  )
    ;; Validate oracle
    (asserts! (is-eq oracle (get oracle asset)) err-not-authorized)
    (asserts! (not (var-get emergency-shutdown)) err-emergency-shutdown)
    
    ;; Update asset with new price
    (let (
      (historical-prices (get historical-prices asset))
      (updated-history (if (>= (len historical-prices) u30)
                         (add-price-to-history (buff-to-list (list-to-buff historical-prices) u1 u29) price)
                         (append historical-prices { price: price, block-height: block-height })))
      (old-price (get current-price asset))
      (balance (get balance asset))
      (value-stx (if (> price u0) (* balance price) u0))
    )
      ;; Update performances if we have an old price
      (let (
        (perf-7d (if (and (> old-price u0) (> (len updated-history) u7))
                   (calculate-performance price (get price (unwrap-panic (element-at updated-history u7))))
                   (get performance-7d asset)))
        (perf-30d (if (and (> old-price u0) (> (len updated-history) u30))
                    (calculate-performance price (get price (unwrap-panic (element-at updated-history u29))))
                    (get performance-30d asset)))
        (perf-90d (if (and (> old-price u0) (> (len updated-history) u30))
                    ;; Use oldest available price for 90d if we don't have 90 days of data
                    (calculate-performance price (get price (unwrap-panic (element-at updated-history (- (len updated-history) u1)))))
                    (get performance-90d asset)))
      )
        (map-set assets
          { asset-id: asset-id }
          (merge asset {
            current-price: price,
            last-price-update: block-height,
            historical-prices: updated-history,
            value-stx: value-stx,
            performance-7d: perf-7d,
            performance-30d: perf-30d,
            performance-90d: perf-90d
          })
        )
        
        ;; Check if rebalancing is needed
        (let (
          (rebalance-needed (check-rebalancing-needed))
        )
          (if (is-ok rebalance-needed)
            (match (unwrap-panic rebalance-needed)
              true (try! (auto-rebalance))
              false (ok true)
            )
            (ok true)
          )
        )
      )
    )
  )
)

;; Helper to add price to history
(define-private (add-price-to-history 
  (history (list 30 { price: uint, block-height: uint }))
  (new-price uint))
  
  (append history { price: new-price, block-height: block-height })
)

;; Calculate performance between two prices
(define-private (calculate-performance (new-price uint) (old-price uint))
  (if (> old-price u0)
    (to-int (/ (* (- new-price old-price) u10000) old-price))
    (to-int 0)
  )
)

;; Create an investment strategy
(define-public (create-strategy
  (name (string-ascii 64))
  (description (string-utf8 256))
  (allocations (list 20 { asset-id: (string-ascii 20), allocation-bp: uint })))
  
  (let (
    (creator tx-sender)
    (strategy-id (var-get next-strategy-id))
  )
    (asserts! (not (var-get emergency-shutdown)) err-emergency-shutdown)
    
    ;; Validate allocations
    (asserts! (> (len allocations) u0) err-invalid-parameters)
    
    ;; Check allocation total is 10000 (100%)
    (let (
      (total-allocation (fold add-allocation u0 allocations))
    )
      (asserts! (is-eq total-allocation u10000) err-invalid-parameters)
      
      ;; Calculate strategy risk profile
      (let (
        (risk-profile (calculate-strategy-risk allocations))
      )
        ;; Validate risk is within maximum
        (asserts! (<= risk-profile (var-get max-risk-score)) err-risk-exceeded)
        
        ;; Create strategy
        (map-set strategies
          { strategy-id: strategy-id }
          {
            name: name,
            description: description,
            risk-profile: risk-profile,
            allocations: allocations,
            creator: creator,
            created-at: block-height,
            last-modified: block-height,
            approved: false,
            active: false,
            performance-all-time: (to-int 0),
            start-value: u0,
            current-value: u0
          }
        )
        
        ;; Increment strategy counter
        (var-set next-strategy-id (+ strategy-id u1))
        
        (ok {
          strategy-id: strategy-id,
          risk-profile: risk-profile
        })
      )
    )
  )
)

;; Helper to add allocation percentages
(define-private (add-allocation 
  (total uint) 
  (allocation { asset-id: (string-ascii 20), allocation-bp: uint }))
  
  (+ total (get allocation-bp allocation))
)

;; Calculate strategy risk profile based on asset allocations
(define-private (calculate-strategy-risk 
  (allocations (list 20 { asset-id: (string-ascii 20), allocation-bp: uint })))
  
  (let (
    (weighted-risk (fold add-weighted-risk u0 allocations))
  )
    ;; Divide by 10000 (100%) to get average risk
    (/ weighted-risk u10000)
  )
)

;; Helper to calculate weighted risk
(define-private (add-weighted-risk 
  (total uint) 
  (allocation { asset-id: (string-ascii 20), allocation-bp: uint }))
  
  (let (
    (asset-id (get asset-id allocation))
    (allocation-bp (get allocation-bp allocation))
    (asset (map-get? assets { asset-id: asset-id }))
  )
    (if (is-some asset)
      (+ total (* allocation-bp (get risk-score (unwrap-panic asset))))
      total
    )
  )
)

;; Submit a proposal
(define-public (submit-proposal
  (title (string-ascii 64))
  (description (string-utf8 512))
  (proposal-type uint)
  (strategy-id (optional uint))
  (parameter-key (optional (string-ascii 30)))
  (parameter-value (optional uint))
  (assets-affected (list 10 (string-ascii 20)))
  (transaction-data (optional (string-utf8 512)))
  (dca-schedule-id (optional uint)))
  
  (let (
    (proposer tx-sender)
    (proposal-id (var-get next-proposal-id))
    (voting-period (var-get voting-period))
    (execution-delay (var-get execution-delay))
    (proposal-threshold (var-get minimum-proposal-threshold))
  )
    (asserts! (not (var-get emergency-shutdown)) err-emergency-shutdown)
    
    ;; Validate proposal type
    (asserts! (< proposal-type u5) err-invalid-parameters)
    
    ;; Check if proposer has enough tokens
    (let (
      (proposer-balance (unwrap! (contract-call? (var-get dao-token-contract) get-balance proposer) err-transaction-failed))
    )
      (asserts! (>= proposer-balance proposal-threshold) err-not-enough-votes)
      
      ;; Validate proposal-specific parameters
      (if (is-eq proposal-type u1) ;; Strategy Change
        (asserts! (and (is-some strategy-id) 
                      (is-some (map-get? strategies { strategy-id: (unwrap-panic strategy-id) }))) 
                  err-strategy-not-found)
        true
      )
      
      (if (is-eq proposal-type u2) ;; Parameter Change
        (asserts! (and (is-some parameter-key) 
                      (is-some parameter-value) 
                      (is-some (map-get? dao-parameters { param-key: (unwrap-panic parameter-key) }))) 
                  err-invalid-parameters)
        true
      )
      
      (if (is-eq proposal-type u3) ;; DCA Schedule
        (if (is-some dca-schedule-id)
          (asserts! (is-some (map-get? dca-schedules { schedule-id: (unwrap-panic dca-schedule-id) })) 
                   err-schedule-not-found)
          true
        )
        true
      )
      
      ;; Create proposal
      (map-set proposals
        { proposal-id: proposal-id }
        {
          title: title,
          description: description,
          proposer: proposer,
          proposal-type: proposal-type,
          created-at: block-height,
          voting-ends-at: (+ block-height voting-period),
          execution-delay-until: (+ (+ block-height voting-period) execution-delay),
          votes-for: u0,
          votes-against: u0,
          votes-abstain: u0,
          status: "active",
          executed-at: none,
          strategy-id: strategy-id,
          parameter-key: parameter-key,
          parameter-value: parameter-value,
          assets-affected: assets-affected,
          transaction-data: transaction-data,
          dca-schedule-id: dca-schedule-id,
          voters: (list)
        }
      )
      
      ;; Increment proposal counter
      (var-set next-proposal-id (+ proposal-id u1))
      
      (ok proposal-id)
    )
  )
)

;; Cast a vote on a proposal
(define-public (cast-vote
  (proposal-id uint)
  (vote (string-ascii 7)))
  
  (let (
    (voter tx-sender)
    (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-proposal-not-found))
    (voting-power-result (contract-call? (var-get dao-token-contract) get-balance voter))
  )
    (asserts! (not (var-get emergency-shutdown)) err-emergency-shutdown)
    
    ;; Check if voting period is still active
    (asserts! (< block-height (get voting-ends-at proposal)) err-voting-period-ended)
    
    ;; Validate vote type
    (asserts! (or (is-eq vote "for") (is-eq vote "against") (is-eq vote "abstain")) err-invalid-parameters)
    
    ;; Check if voter has already voted
    (asserts! (is-none (find-voter (get voters proposal) voter)) err-vote-already-cast)
    
    ;; Get voting power
    (let (
      (voting-power (unwrap! voting-power-result err-transaction-failed))
    )
      (asserts! (> voting-power u0) err-not-enough-votes)
      
      ;; Record the vote
      (map-set votes
        { proposal-id: proposal-id, voter: voter }
        {
          vote: vote,
          voting-power: voting-power,
          vote-cast-at: block-height
        }
      )
      
      ;; Update proposal vote counts
      (let (
        (updated-votes-for (if (is-eq vote "for") (+ (get votes-for proposal) voting-power) (get votes-for proposal)))
        (updated-votes-against (if (is-eq vote "against") (+ (get votes-against proposal) voting-power) (get votes-against proposal)))
        (updated-votes-abstain (if (is-eq vote "abstain") (+ (get votes-abstain proposal) voting-power) (get votes-abstain proposal)))
        (updated-voters (append (get voters proposal) voter))
      )
        (map-set proposals
          { proposal-id: proposal-id }
          (merge proposal {
            votes-for: updated-votes-for,
            votes-against: updated-votes-against,
            votes-abstain: updated-votes-abstain,
            voters: updated-voters
          })
        )
        
        (ok {
          proposal-id: proposal-id,
          vote: vote,
          voting-power: voting-power
        })
      )
    )
  )
)

;; Helper to find if a voter has voted
(define-private (find-voter (voters (list 100 principal)) (target principal))
  (index-of voters target)
)

;; Finalize a proposal after voting period ends
(define-public (finalize-proposal (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-proposal-not-found))
    (quorum-threshold (var-get quorum-threshold))
  )
    (asserts! (not (var-get emergency-shutdown)) err-emergency-shutdown)
    
    ;; Check if voting period has ended
    (asserts! (>= block-height (get voting-ends-at proposal)) err-voting-period-active)
    
    ;; Check that proposal is still active
    (asserts! (is-eq (get status proposal) "active") err-proposal-already-executed)
    
    ;; Get total token supply
    (let (
      (total-supply-result (contract-call? (var-get dao-token-contract) get-total-supply))
      (total-votes (+ (+ (get votes-for proposal) (get votes-against proposal)) (get votes-abstain proposal)))
    )
      (match total-supply-result
        total-supply (let (
                        (quorum-requirement (/ (* total-supply quorum-threshold) u100))
                      )
                      ;; Check if quorum was reached
                      (if (>= total-votes quorum-requirement)
                        ;; Check if proposal passed (more votes for than against)
                        (if (> (get votes-for proposal) (get votes-against proposal))
                          (map-set proposals
                            { proposal-id: proposal-id }
                            (merge proposal { status: "approved" })
                          )
                          (map-set proposals
                            { proposal-id: proposal-id }
                            (merge proposal { status: "rejected" })
                          )
                        )
                        ;; Not enough votes to reach quorum
                        (map-set proposals
                          { proposal-id: proposal-id }
                          (merge proposal { status: "rejected" })
                        )
                      )
                      (ok { proposal-id: proposal-id, status: (get status proposal) })
                     )
        error (err err-transaction-failed)
      )
    )
  )
)

;; Execute an approved proposal after the execution delay
(define-public (execute-proposal (proposal-id uint))
  (let (
    (executor tx-sender)
    (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-proposal-not-found))
  )
    (asserts! (not (var-get emergency-shutdown)) err-emergency-shutdown)
    
    ;; Check if proposal is approved
    (asserts! (is-eq (get status proposal) "approved") err-proposal-not-approved)
    
    ;; Check if execution delay has passed
    (asserts! (>= block-height (get execution-delay-until proposal)) err-voting-period-active)
    
    ;; Check that proposal hasn't been executed yet
    (asserts! (is-none (get executed-at proposal)) err-proposal-already-executed)
    
    ;; Execute proposal based on type
    (let (
      (proposal-type (get proposal-type proposal))
      (result (execute-proposal-by-type proposal-id proposal-type proposal))
    )
      (if (is-ok result)
        (begin
          ;; Update proposal status to executed
          (map-set proposals
            { proposal-id: proposal-id }
            (merge proposal {
              status: "executed",
              executed-at: (some block-height)
            })
          )