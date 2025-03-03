;; SafeForge Core Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-template (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-paused (err u103))
(define-constant err-version-exists (err u104))
(define-constant err-cooldown-active (err u105))
(define-constant err-template-archived (err u106))

;; Data vars
(define-data-var contract-paused bool false)

;; Enhanced template tracking
(define-map templates 
  { template-id: uint }
  { 
    name: (string-ascii 64),
    validated: bool,
    owner: principal,
    created-at: uint,
    version: uint,
    validation-criteria: (string-ascii 256),
    last-modified: uint,
    is-archived: bool
  }
)

(define-map template-versions
  { template-id: uint, version: uint }
  {
    code-hash: (buff 32),
    changes: (string-ascii 256),
    created-at: uint,
    validator: (optional principal),
    validation-date: (optional uint)
  }
)

(define-map permissions
  { user: principal }
  { can-deploy: bool, is-admin: bool, deploy-limit: uint, last-deployment: (optional uint) }
)

;; Events
(define-data-var event-counter uint u0)

(define-private (emit-event (event-type (string-ascii 20)) (data (string-ascii 256)))
  (begin
    (var-set event-counter (+ (var-get event-counter) u1))
    (print {event-id: (var-get event-counter), type: event-type, data: data, timestamp: block-height})
  )
)

;; Permission management
(define-public (set-permissions (user principal) (can-deploy bool) (is-admin bool) (deploy-limit uint))
  (begin
    (asserts! (is-owner) err-owner-only)
    (emit-event "SET_PERMISSIONS" (concat (to-ascii user) ": deploy="))
    (ok (map-set permissions 
      {user: user} 
      {can-deploy: can-deploy, is-admin: is-admin, deploy-limit: deploy-limit, last-deployment: none}))
  )
)

;; Template management  
(define-public (add-template (template-id uint) (name (string-ascii 64)) (validation-criteria (string-ascii 256)))
  (begin
    (asserts! (is-authorized) err-unauthorized)
    (asserts! (not (var-get contract-paused)) err-paused)
    (emit-event "ADD_TEMPLATE" (concat "Template: " name))
    (ok (map-set templates 
      {template-id: template-id}
      {
        name: name,
        validated: false,
        owner: tx-sender,
        created-at: block-height,
        version: u1,
        validation-criteria: validation-criteria,
        last-modified: block-height,
        is-archived: false
      }
    ))
  )
)

(define-public (archive-template (template-id uint))
  (let ((template (unwrap! (map-get? templates {template-id: template-id}) err-invalid-template)))
    (begin
      (asserts! (or (is-owner) (is-template-owner template-id)) err-unauthorized)
      (emit-event "ARCHIVE_TEMPLATE" (concat "Template: " (get name template)))
      (ok (map-set templates
        {template-id: template-id}
        (merge template {is-archived: true})))
    )
  )
)

[... rest of the contract remains unchanged ...]
