;; SafeForge Core Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-template (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-paused (err u103))
(define-constant err-version-exists (err u104))

;; Data vars
(define-data-var contract-paused bool false)

(define-map templates 
  { template-id: uint }
  { 
    name: (string-ascii 64),
    validated: bool,
    owner: principal,
    created-at: uint,
    version: uint,
    validation-criteria: (string-ascii 256)
  }
)

(define-map template-versions
  { template-id: uint, version: uint }
  {
    code-hash: (buff 32),
    changes: (string-ascii 256),
    created-at: uint
  }
)

(define-map permissions
  { user: principal }
  { can-deploy: bool, is-admin: bool, deploy-limit: uint }
)

;; Permission management
(define-public (set-permissions (user principal) (can-deploy bool) (is-admin bool) (deploy-limit uint))
  (begin
    (asserts! (is-owner) err-owner-only)
    (ok (map-set permissions 
      {user: user} 
      {can-deploy: can-deploy, is-admin: is-admin, deploy-limit: deploy-limit}))
  )
)

;; Contract pause functionality
(define-public (set-pause-state (paused bool))
  (begin
    (asserts! (is-owner) err-owner-only)
    (ok (var-set contract-paused paused))
  )
)

;; Template management  
(define-public (add-template (template-id uint) (name (string-ascii 64)) (validation-criteria (string-ascii 256)))
  (begin
    (asserts! (is-authorized) err-unauthorized)
    (asserts! (not (var-get contract-paused)) err-paused)
    (ok (map-set templates 
      {template-id: template-id}
      {
        name: name,
        validated: false,
        owner: tx-sender,
        created-at: block-height,
        version: u1,
        validation-criteria: validation-criteria
      }
    ))
  )
)

(define-public (update-template-version 
  (template-id uint) 
  (code-hash (buff 32)) 
  (changes (string-ascii 256)))
  (let (
    (current-template (unwrap! (map-get? templates {template-id: template-id}) err-invalid-template))
    (new-version (+ (get version current-template) u1))
  )
    (begin
      (asserts! (is-template-owner template-id) err-unauthorized)
      (asserts! (not (var-get contract-paused)) err-paused)
      (map-set template-versions
        {template-id: template-id, version: new-version}
        {
          code-hash: code-hash,
          changes: changes,
          created-at: block-height
        }
      )
      (ok (map-set templates
        {template-id: template-id}
        (merge current-template {version: new-version})))
    )
  )
)

(define-public (validate-template (template-id uint))
  (begin
    (asserts! (is-admin) err-unauthorized)
    (asserts! (not (var-get contract-paused)) err-paused)
    (ok (map-set templates
      {template-id: template-id}
      (merge (unwrap! (map-get? templates {template-id: template-id}) err-invalid-template)
        {validated: true})))
  )
)

;; Read-only functions
(define-read-only (get-template (template-id uint))
  (map-get? templates {template-id: template-id})
)

(define-read-only (get-template-version (template-id uint) (version uint))
  (map-get? template-versions {template-id: template-id, version: version})
)

;; Helper functions
(define-private (is-owner)
  (is-eq tx-sender contract-owner)
)

(define-private (is-admin)
  (get is-admin (default-to {can-deploy: false, is-admin: false, deploy-limit: u0}
    (map-get? permissions {user: tx-sender})))
)

(define-private (is-authorized)
  (get can-deploy (default-to {can-deploy: false, is-admin: false, deploy-limit: u0}
    (map-get? permissions {user: tx-sender})))
)

(define-private (is-template-owner (template-id uint))
  (let ((template (unwrap! (map-get? templates {template-id: template-id}) false)))
    (is-eq tx-sender (get owner template))
  )
)
