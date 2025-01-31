;; SafeForge Core Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-template (err u101))
(define-constant err-unauthorized (err u102))

;; Data vars
(define-map templates 
  { template-id: uint }
  { 
    name: (string-ascii 64),
    validated: bool,
    owner: principal
  }
)

(define-map permissions
  { user: principal }
  { can-deploy: bool, is-admin: bool }
)

;; Permission management
(define-public (set-permissions (user principal) (can-deploy bool) (is-admin bool))
  (begin
    (asserts! (is-owner) err-owner-only)
    (ok (map-set permissions {user: user} {can-deploy: can-deploy, is-admin: is-admin}))
  )
)

;; Template management  
(define-public (add-template (template-id uint) (name (string-ascii 64)))
  (begin
    (asserts! (is-authorized) err-unauthorized)
    (ok (map-set templates 
      {template-id: template-id}
      {
        name: name,
        validated: false,
        owner: tx-sender
      }
    ))
  )
)

(define-public (validate-template (template-id uint))
  (begin
    (asserts! (is-admin) err-unauthorized)
    (ok (map-set templates
      {template-id: template-id}
      (merge (unwrap! (map-get? templates {template-id: template-id}) err-invalid-template)
        {validated: true})
    ))
  )
)

;; Helper functions
(define-private (is-owner)
  (is-eq tx-sender contract-owner)
)

(define-private (is-admin)
  (get is-admin (default-to {can-deploy: false, is-admin: false}
    (map-get? permissions {user: tx-sender})))
)

(define-private (is-authorized)
  (get can-deploy (default-to {can-deploy: false, is-admin: false}
    (map-get? permissions {user: tx-sender})))
)
