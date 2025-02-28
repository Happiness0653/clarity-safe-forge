;; SafeForge Deployer Contract

;; Constants
(define-constant err-deploy-failed (err u200))
(define-constant err-invalid-contract (err u201))
(define-constant err-deploy-limit (err u202))

;; Data vars
(define-map deployed-contracts
  { contract-id: uint }
  {
    owner: principal,
    template-id: uint,
    template-version: uint,
    status: (string-ascii 20),
    deployed-at: uint,
    configuration: (string-ascii 256)
  }
)

(define-map deployment-counts
  { user: principal }
  { count: uint }
)

;; Deploy management
(define-public (deploy-contract 
  (contract-id uint) 
  (template-id uint)
  (configuration (string-ascii 256)))
  (let (
    (template (unwrap! (contract-call? .safe-forge-core get-template template-id) err-invalid-contract))
    (deploy-count (default-to {count: u0} (map-get? deployment-counts {user: tx-sender})))
    (user-permissions (unwrap! (contract-call? .safe-forge-core get-permissions tx-sender) err-invalid-contract))
  )
    (begin
      (asserts! (is-template-valid template) err-invalid-contract)
      (asserts! (< (get count deploy-count) (get deploy-limit user-permissions)) err-deploy-limit)
      (map-set deployment-counts 
        {user: tx-sender}
        {count: (+ (get count deploy-count) u1)})
      (ok (map-set deployed-contracts
        {contract-id: contract-id}
        {
          owner: tx-sender,
          template-id: template-id,
          template-version: (get version template),
          status: "deployed",
          deployed-at: block-height,
          configuration: configuration
        }
      ))
    )
  )
)

(define-public (update-deployment-status (contract-id uint) (new-status (string-ascii 20)))
  (let ((deployment (unwrap! (map-get? deployed-contracts {contract-id: contract-id}) err-invalid-contract)))
    (begin
      (asserts! (is-eq tx-sender (get owner deployment)) err-invalid-contract)
      (ok (map-set deployed-contracts
        {contract-id: contract-id}
        (merge deployment {status: new-status})))
    )
  )
)

(define-private (is-template-valid (template {name: (string-ascii 64), validated: bool, owner: principal, version: uint}))
  (get validated template)
)
