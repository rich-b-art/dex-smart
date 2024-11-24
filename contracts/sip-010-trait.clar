;; title: SIP-010 Trait Definition
;; summary: Defines the standard interface for fungible tokens in the Clarity language.
;; description: 
;; This contract defines the SIP-010 trait, which establishes a standard interface for fungible tokens in the Clarity language. 
;; The trait includes functions for transferring tokens, querying balances, retrieving token metadata, and more. 
;; Implementing this trait ensures compatibility with other contracts and tools that interact with fungible tokens on the Stacks blockchain.

;; SIP-010 Trait Definition
(define-trait sip-010-trait
    (
        ;; Transfer from the caller to a new principal
        (transfer (uint principal principal (optional (buff 34))) (response bool uint))

        ;; Get the token balance of owner
        (get-balance (principal) (response uint uint))

        ;; Get the total supply of tokens
        (get-total-supply () (response uint uint))

        ;; Get the token name
        (get-name () (response (string-ascii 32) uint))

        ;; Get the token symbol
        (get-symbol () (response (string-ascii 32) uint))

        ;; Get the number of decimals
        (get-decimals () (response uint uint))

        ;; Get the URI for token metadata
        (get-token-uri () (response (optional (string-utf8 256)) uint))
    )
)