;; SafeForge Deployer Contract

;; Constants
(define-constant err-deploy-failed (err u200))
(define-constant err-invalid-contract (err u201))

;; Data vars
(define-map deployed-contracts
  { contract-id: uint }
  {
    owner: principal,
    template-id: uint,
    status: (string-ascii 20)
  }
)

;; Deploy management
(define-public (deploy-contract (contract-id uint) (template-id uint))
  (let (
    (template (unwrap! (contract-call? .safe-forge-core get-template template-id) err-invalid-contract))
  )
    (begin
      (asserts! (is-template-valid template) err-invalid-contract)
      (ok (map-set deployed-contracts
        {contract-id: contract-id}
        {
          owner: tx-sender,
          template-id: template-id,
          status: "deployed"
        }
      ))
    )
  )
)

(define-private (is-template-valid (template {name: (string-ascii 64), validated: bool, owner: principal}))
  (get validated template)
)
