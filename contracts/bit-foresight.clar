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