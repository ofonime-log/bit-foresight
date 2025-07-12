;; Title: BitForesight Protocol
;; Summary: Next-Generation Decentralized Bitcoin Price Prediction Platform
;; Description: A cutting-edge DeFi protocol that transforms Bitcoin price 
;;              speculation into a transparent, community-driven prediction
;;              market. Built on Stacks Layer 2, BitForesight enables users
;;              to leverage their market insights by staking STX tokens on
;;              Bitcoin's future price movements. The protocol features
;;              oracle-verified settlements, dynamic liquidity pools, and
;;              algorithmic reward distribution that incentivizes accurate
;;              forecasting while maintaining bulletproof security through
;;              Bitcoin's proof-of-work consensus.

;; PROTOCOL CONSTANTS

;; Contract Governance
(define-constant PROTOCOL_ADMIN tx-sender)

;; Error Code System
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100)) ;; Access control violation
(define-constant ERR-RESOURCE-NOT-FOUND (err u101)) ;; Missing market/prediction data
(define-constant ERR-INVALID-FORECAST (err u102)) ;; Malformed prediction parameters
(define-constant ERR-MARKET-INACTIVE (err u103)) ;; Market outside active window
(define-constant ERR-REWARD-CLAIMED (err u104)) ;; Duplicate payout attempt
(define-constant ERR-INSUFFICIENT-FUNDS (err u105)) ;; Inadequate STX balance
(define-constant ERR-INVALID-INPUT (err u106)) ;; Parameter validation failure

;; PROTOCOL STATE

;; Oracle Integration Settings
(define-data-var price-oracle-endpoint principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Market Economics Configuration
(define-data-var min-participation-threshold uint u1000000) ;; 1 STX minimum (uSTX)
(define-data-var protocol-fee-rate uint u2) ;; 2% fee on rewards
(define-data-var global-market-index uint u0) ;; Market ID generator

;; DATA STRUCTURES

;; Prediction Market Schema
;; Comprehensive market state including price points, stakes, and timing
(define-map prediction-markets
  uint ;; Market identifier
  {
    initial-btc-price: uint, ;; Opening Bitcoin price snapshot
    final-btc-price: uint, ;; Settlement price (post-resolution)
    bullish-pool: uint, ;; Total STX staked on price increase
    bearish-pool: uint, ;; Total STX staked on price decrease
    market-open-height: uint, ;; Block height when market opens
    market-close-height: uint, ;; Block height when market closes
    is-resolved: bool, ;; Market settlement status
  }
)

;; Participant Position Registry
;; Individual user positions across prediction markets
(define-map participant-positions
  {
    market-id: uint, ;; Associated market identifier
    participant: principal, ;; User wallet address
  }
  {
    price-direction: (string-ascii 4), ;; Forecast: "bull" or "bear"
    staked-amount: uint, ;; STX tokens committed
    rewards-claimed: bool, ;; Payout status tracker
  }
)

;; CORE PROTOCOL FUNCTIONS

;; Initialize New Prediction Market
;; Creates a new Bitcoin price forecasting market with specified parameters
(define-public (initialize-prediction-market
    (btc-price uint)
    (open-height uint)
    (close-height uint)
  )
  (let ((new-market-id (var-get global-market-index)))
    ;; Administrative access validation
    (asserts! (is-eq tx-sender PROTOCOL_ADMIN) ERR-UNAUTHORIZED-ACCESS)
    ;; Input parameter validation
    (asserts! (> close-height open-height) ERR-INVALID-INPUT)
    (asserts! (> btc-price u0) ERR-INVALID-INPUT)
    ;; Market initialization with default state
    (map-set prediction-markets new-market-id {
      initial-btc-price: btc-price,
      final-btc-price: u0,
      bullish-pool: u0,
      bearish-pool: u0,
      market-open-height: open-height,
      market-close-height: close-height,
      is-resolved: false,
    })
    ;; Increment global market counter
    (var-set global-market-index (+ new-market-id u1))
    (ok new-market-id)
  )
)

;; Submit Market Prediction
;; Enables users to stake STX tokens on Bitcoin price direction forecasts
(define-public (submit-forecast
    (market-id uint)
    (direction (string-ascii 4))
    (stake-amount uint)
  )
  (let (
      (market-data (unwrap! (map-get? prediction-markets market-id) ERR-RESOURCE-NOT-FOUND))
      (current-height stacks-block-height)
    )
    ;; Market activity window validation
    (asserts!
      (and
        (>= current-height (get market-open-height market-data))
        (< current-height (get market-close-height market-data))
      )
      ERR-MARKET-INACTIVE
    )
    ;; Forecast parameter validation
    (asserts! (or (is-eq direction "bull") (is-eq direction "bear"))
      ERR-INVALID-FORECAST
    )
    (asserts! (>= stake-amount (var-get min-participation-threshold))
      ERR-INVALID-FORECAST
    )
    (asserts! (<= stake-amount (stx-get-balance tx-sender))
      ERR-INSUFFICIENT-FUNDS
    )
    ;; Transfer stake to contract escrow
    (try! (stx-transfer? stake-amount tx-sender (as-contract tx-sender)))
    ;; Register participant position
    (map-set participant-positions {
      market-id: market-id,
      participant: tx-sender,
    } {
      price-direction: direction,
      staked-amount: stake-amount,
      rewards-claimed: false,
    })
    ;; Update market pool balances
    (map-set prediction-markets market-id
      (merge market-data {
        bullish-pool: (if (is-eq direction "bull")
          (+ (get bullish-pool market-data) stake-amount)
          (get bullish-pool market-data)
        ),
        bearish-pool: (if (is-eq direction "bear")
          (+ (get bearish-pool market-data) stake-amount)
          (get bearish-pool market-data)
        ),
      })
    )
    (ok true)
  )
)

;; Settle Market with Oracle Data
;; Oracle-authorized function to finalize Bitcoin price and resolve market outcomes
(define-public (settle-market-outcome
    (market-id uint)
    (settlement-price uint)
  )
  (let ((market-data (unwrap! (map-get? prediction-markets market-id) ERR-RESOURCE-NOT-FOUND)))
    ;; Oracle authorization verification
    (asserts! (is-eq tx-sender (var-get price-oracle-endpoint))
      ERR-UNAUTHORIZED-ACCESS
    )
    ;; Market closure timing validation
    (asserts! (>= stacks-block-height (get market-close-height market-data))
      ERR-MARKET-INACTIVE
    )
    (asserts! (not (get is-resolved market-data)) ERR-MARKET-INACTIVE)
    (asserts! (> settlement-price u0) ERR-INVALID-INPUT)
    ;; Finalize market with settlement data
    (map-set prediction-markets market-id
      (merge market-data {
        final-btc-price: settlement-price,
        is-resolved: true,
      })
    )
    (ok true)
  )
)

;; Claim Forecasting Rewards
;; Enables winning participants to claim proportional rewards from resolved markets
(define-public (claim-forecast-rewards (market-id uint))
  (let (
      (market-data (unwrap! (map-get? prediction-markets market-id) ERR-RESOURCE-NOT-FOUND))
      (position-data (unwrap!
        (map-get? participant-positions {
          market-id: market-id,
          participant: tx-sender,
        })
        ERR-RESOURCE-NOT-FOUND
      ))
    )
    ;; Settlement and claim validation
    (asserts! (get is-resolved market-data) ERR-MARKET-INACTIVE)
    (asserts! (not (get rewards-claimed position-data)) ERR-REWARD-CLAIMED)
    (let (
        ;; Determine winning direction based on price movement
        (winning-direction (if (> (get final-btc-price market-data)
            (get initial-btc-price market-data)
          )
          "bull"
          "bear"
        ))
        (total-pool (+ (get bullish-pool market-data) (get bearish-pool market-data)))
        (winning-pool (if (is-eq winning-direction "bull")
          (get bullish-pool market-data)
          (get bearish-pool market-data)
        ))
      )
      ;; Verify participant backed winning direction
      (asserts! (is-eq (get price-direction position-data) winning-direction)
        ERR-INVALID-FORECAST
      )
      (let (
          ;; Calculate proportional rewards and protocol fee
          (total-reward (/ (* (get staked-amount position-data) total-pool) winning-pool))
          (protocol-fee (/ (* total-reward (var-get protocol-fee-rate)) u100))
          (net-payout (- total-reward protocol-fee))
        )
        ;; Distribute rewards to participant
        (try! (as-contract (stx-transfer? net-payout (as-contract tx-sender) tx-sender)))
        ;; Transfer protocol fee to admin
        (try! (as-contract (stx-transfer? protocol-fee (as-contract tx-sender) PROTOCOL_ADMIN)))
        ;; Mark position as claimed
        (map-set participant-positions {
          market-id: market-id,
          participant: tx-sender,
        }
          (merge position-data { rewards-claimed: true })
        )
        (ok net-payout)
      )
    )
  )
)

;; READ-ONLY DATA ACCESS

;; Retrieve Market Data
;; Returns complete market information for external queries
(define-read-only (get-market-data (market-id uint))
  (map-get? prediction-markets market-id)
)

;; Retrieve Participant Position
;; Returns user's position data for specified market
(define-read-only (get-participant-position
    (market-id uint)
    (participant principal)
  )
  (map-get? participant-positions {
    market-id: market-id,
    participant: participant,
  })
)

;; Get Protocol Treasury Balance
;; Returns total STX held in protocol escrow
(define-read-only (get-protocol-treasury)
  (stx-get-balance (as-contract tx-sender))
)

;; Get Protocol Configuration
;; Returns current protocol parameters for transparency
(define-read-only (get-protocol-settings)
  {
    oracle-endpoint: (var-get price-oracle-endpoint),
    minimum-stake: (var-get min-participation-threshold),
    fee-rate: (var-get protocol-fee-rate),
    total-markets: (var-get global-market-index),
  }
)