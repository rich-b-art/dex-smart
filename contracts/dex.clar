;; title: Decentralized Exchange (DEX) Smart Contract
;; summary: A Clarity smart contract for a decentralized exchange (DEX) that allows users to create liquidity pools, add liquidity, swap tokens, and remove liquidity.
;; description: 
;; This smart contract implements a decentralized exchange (DEX) on the Stacks blockchain using the Clarity language. It defines the necessary data structures, error codes, and core functions to manage liquidity pools, facilitate token swaps, and handle liquidity provision and removal. The contract ensures secure and efficient token transactions by enforcing strict checks and balances, including slippage protection and deadline constraints.

;; Define token trait
(use-trait ft-trait 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sip-010-trait.sip-010-trait)


;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INSUFFICIENT-BALANCE (err u1001))
(define-constant ERR-INVALID-PAIR (err u1002))
(define-constant ERR-INVALID-AMOUNT (err u1003))
(define-constant ERR-POOL-ALREADY-EXISTS (err u1004))
(define-constant ERR-POOL-NOT-FOUND (err u1005))
(define-constant ERR-SLIPPAGE-TOO-HIGH (err u1006))
(define-constant ERR-DEADLINE-EXPIRED (err u1007))
(define-constant ERR-ZERO-LIQUIDITY (err u1008))

;; Data Variables
(define-data-var contract-owner principal tx-sender)

;; Data Variables
(define-data-var contract-owner principal tx-sender)
(define-map pools 
    { token-x: principal, token-y: principal }
    { liquidity-total: uint,
      balance-x: uint,
      balance-y: uint,
      fee-rate: uint })

(define-map liquidity-providers
    { pool-id: { token-x: principal, token-y: principal },
      provider: principal }
    { liquidity-provided: uint,
      rewards-claimed: uint })

(define-map orders
    uint
    { maker: principal,
      token-x: principal,
      token-y: principal,
      amount-x: uint,
      target-y: uint,
      expires-at: uint })


;; Getters
(define-read-only (get-pool-details (token-x principal) (token-y principal))
    (map-get? pools { token-x: token-x, token-y: token-y }))

(define-read-only (get-provider-liquidity 
    (token-x principal) 
    (token-y principal) 
    (provider principal))
    (map-get? liquidity-providers
        { pool-id: { token-x: token-x, token-y: token-y },
          provider: provider }))

;; Price calculation functions
(define-private (calculate-price (amount-in uint) (reserve-in uint) (reserve-out uint))
    (let ((amount-with-fee (* amount-in u997)))
        (/ (* amount-with-fee reserve-out)
           (+ (* reserve-in u1000) amount-with-fee))))

(define-private (get-deposit-amounts (amount-a uint) (amount-b uint) (reserve-a uint) (reserve-b uint))
    (let ((ratio-a (/ (* amount-a u1000000) reserve-a))
          (ratio-b (/ (* amount-b u1000000) reserve-b)))
        (if (< ratio-a ratio-b)
            (tuple 
                (optimal-a amount-a)
                (optimal-b (/ (* amount-a reserve-b) reserve-a)))
            (tuple 
                (optimal-a (/ (* amount-b reserve-a) reserve-b))
                (optimal-b amount-b)))))

;; Core functions
(define-public (create-pool (token-x principal) (token-y principal) (initial-x uint) (initial-y uint))
    (let ((pool (get-pool-details token-x token-y)))
        (asserts! (is-eq (get-pool-details token-x token-y) none) ERR-POOL-ALREADY-EXISTS)
        (asserts! (> initial-x u0) ERR-INVALID-AMOUNT)
        (asserts! (> initial-y u0) ERR-INVALID-AMOUNT)
        
        ;; Transfer initial liquidity
        (try! (contract-call? token-x transfer initial-x tx-sender (as-contract tx-sender)))
        (try! (contract-call? token-y transfer initial-y tx-sender (as-contract tx-sender)))
        
        ;; Create pool
        (map-set pools 
            { token-x: token-x, token-y: token-y }
            { liquidity-total: (sqrt (* initial-x initial-y)),
              balance-x: initial-x,
              balance-y: initial-y,
              fee-rate: u300 }) ;; 0.3% fee
        (ok true)))

(define-public (add-liquidity 
    (token-x principal) 
    (token-y principal) 
    (amount-x uint) 
    (amount-y uint)
    (min-liquidity uint)
    (deadline uint))
    (let ((pool (unwrap! (get-pool-details token-x token-y) ERR-POOL-NOT-FOUND))
          (current-block-height block-height))
        
        ;; Checks
        (asserts! (<= current-block-height deadline) ERR-DEADLINE-EXPIRED)
        (asserts! (> amount-x u0) ERR-INVALID-AMOUNT)
        (asserts! (> amount-y u0) ERR-INVALID-AMOUNT)
        
        (let ((optimal-amounts (get-deposit-amounts 
                amount-x 
                amount-y 
                (get balance-x pool) 
                (get balance-y pool))))
            
            ;; Transfer tokens to contract
            (try! (contract-call? token-x transfer 
                (get optimal-a optimal-amounts) 
                tx-sender 
                (as-contract tx-sender)))
            (try! (contract-call? token-y transfer 
                (get optimal-b optimal-amounts) 
                tx-sender 
                (as-contract tx-sender)))
            
            ;; Calculate new liquidity tokens
            (let ((new-liquidity (/ (* (get optimal-a optimal-amounts) 
                                     (get liquidity-total pool))
                                  (get balance-x pool))))
                
                (asserts! (>= new-liquidity min-liquidity) ERR-SLIPPAGE-TOO-HIGH)
                
                ;; Update pool state
                (map-set pools 
                    { token-x: token-x, token-y: token-y }
                    (merge pool {
                        liquidity-total: (+ (get liquidity-total pool) new-liquidity),
                        balance-x: (+ (get balance-x pool) (get optimal-a optimal-amounts)),
                        balance-y: (+ (get balance-y pool) (get optimal-b optimal-amounts))
                    }))
                
                ;; Update provider state
                (let ((provider-state (get-provider-liquidity token-x token-y tx-sender)))
                    (map-set liquidity-providers
                        { pool-id: { token-x: token-x, token-y: token-y },
                          provider: tx-sender }
                        { liquidity-provided: (+ (default-to u0 
                            (get liquidity-provided provider-state)) new-liquidity),
                          rewards-claimed: (default-to u0 
                            (get rewards-claimed provider-state)) }))
                    
                    (ok new-liquidity)))))