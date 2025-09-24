
;; =====================================================
;; STACKs-VERIFY: DECENTRALIZED IDENTITY & REPUTATION ORACLE
;; =====================================================

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_IDENTITY_EXISTS (err u402))
(define-constant ERR_IDENTITY_NOT_FOUND (err u403))
(define-constant ERR_INVALID_CREDENTIAL (err u404))
(define-constant ERR_CREDENTIAL_EXPIRED (err u405))
(define-constant ERR_INSUFFICIENT_REPUTATION (err u406))

;; Data Variables
(define-data-var contract-owner principal CONTRACT_OWNER)
(define-data-var next-identity-id uint u1)

;; Identity Structure
(define-map identities
    { identity-id: uint }
    {
        owner: principal,
        created-at: uint,
        updated-at: uint,
        reputation-score: uint,
        is-verified: bool,
        metadata-hash: (string-ascii 64),
    }
)

;; Principal to Identity ID mapping
(define-map principal-to-identity
    { owner: principal }
    { identity-id: uint }
)

;; Read-only functions
(define-read-only (get-identity (identity-id uint))
    (map-get? identities { identity-id: identity-id })
)

(define-read-only (get-identity-by-principal (owner principal))
    (match (map-get? principal-to-identity { owner: owner })
        identity-data (get-identity (get identity-id identity-data))
        none
    )
)

;; Core Identity Management Functions
(define-public (create-identity (metadata-hash (string-ascii 64)))
    (let (
            (identity-id (var-get next-identity-id))
            (current-block stacks-block-height)
        )
        ;; Check if identity already exists
        (asserts! (is-none (map-get? principal-to-identity { owner: tx-sender }))
            ERR_IDENTITY_EXISTS
        )
        ;; Create identity record
        (map-set identities { identity-id: identity-id } {
            owner: tx-sender,
            created-at: current-block,
            updated-at: current-block,
            reputation-score: u0,
            is-verified: false,
            metadata-hash: metadata-hash,
        })
        ;; Map principal to identity
        (map-set principal-to-identity { owner: tx-sender } { identity-id: identity-id })
        ;; Increment identity counter
        (var-set next-identity-id (+ identity-id u1))
        (ok identity-id)
    )
)

(define-public (update-identity-metadata (metadata-hash (string-ascii 64)))
    (let (
            (identity-lookup (unwrap! (map-get? principal-to-identity { owner: tx-sender })
                ERR_IDENTITY_NOT_FOUND
            ))
            (identity-id (get identity-id identity-lookup))
            (current-identity (unwrap! (get-identity identity-id) ERR_IDENTITY_NOT_FOUND))
        )
        (map-set identities { identity-id: identity-id }
            (merge current-identity {
                metadata-hash: metadata-hash,
                updated-at: stacks-block-height,
            })
        )
        (ok true)
    )
)
