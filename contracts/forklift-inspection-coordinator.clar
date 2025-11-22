;; Forklift Inspection Coordinator
;; Document pre-shift checks, identify equipment defects, remove unsafe trucks, track repairs, and ensure operator safety

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-invalid-severity (err u104))
(define-constant err-equipment-out-of-service (err u105))
(define-constant err-already-exists (err u106))
(define-constant err-invalid-input (err u107))

;; Equipment status types
(define-constant status-operational u1)
(define-constant status-out-of-service u2)
(define-constant status-under-repair u3)

;; Defect severity levels
(define-constant severity-minor u1)
(define-constant severity-major u2)
(define-constant severity-critical u3)

;; Data Variables
(define-data-var inspection-counter uint u0)
(define-data-var defect-counter uint u0)
(define-data-var repair-counter uint u0)
(define-data-var equipment-counter uint u0)

;; Data Maps

;; Equipment registry
(define-map equipment-registry
  { equipment-id: (string-ascii 50) }
  {
    status: uint,
    last-inspection-date: uint,
    defect-count: uint,
    total-inspections: uint,
    registered-at: uint,
    is-active: bool
  }
)

;; Inspection records
(define-map inspections
  { inspection-id: uint }
  {
    equipment-id: (string-ascii 50),
    operator: principal,
    inspection-date: uint,
    brakes-ok: bool,
    steering-ok: bool,
    lights-ok: bool,
    horn-ok: bool,
    tires-ok: bool,
    forks-ok: bool,
    hydraulics-ok: bool,
    overall-result: bool,
    notes: (string-utf8 500)
  }
)

;; Defect reports
(define-map defects
  { defect-id: uint }
  {
    equipment-id: (string-ascii 50),
    inspection-id: uint,
    severity: uint,
    description: (string-utf8 500),
    component: (string-ascii 100),
    reported-date: uint,
    reported-by: principal,
    is-resolved: bool,
    resolved-date: (optional uint)
  }
)

;; Repair orders
(define-map repair-orders
  { repair-id: uint }
  {
    equipment-id: (string-ascii 50),
    defect-id: uint,
    priority: uint,
    assigned-to: (optional principal),
    created-date: uint,
    completed-date: (optional uint),
    is-completed: bool,
    verification-notes: (string-utf8 500)
  }
)

;; Operator records
(define-map operator-records
  { operator: principal }
  {
    certification-number: (string-ascii 50),
    certification-expiry: uint,
    total-inspections: uint,
    defects-found: uint,
    is-certified: bool,
    registered-date: uint
  }
)

;; Equipment to operator mapping (current assignment)
(define-map equipment-assignments
  { equipment-id: (string-ascii 50) }
  { 
    operator: (optional principal),
    assigned-at: (optional uint)
  }
)

;; Read-only functions

;; Get equipment details
(define-read-only (get-equipment (equipment-id (string-ascii 50)))
  (ok (map-get? equipment-registry { equipment-id: equipment-id }))
)

;; Get inspection details
(define-read-only (get-inspection (inspection-id uint))
  (ok (map-get? inspections { inspection-id: inspection-id }))
)

;; Get defect details
(define-read-only (get-defect (defect-id uint))
  (ok (map-get? defects { defect-id: defect-id }))
)

;; Get repair order details
(define-read-only (get-repair-order (repair-id uint))
  (ok (map-get? repair-orders { repair-id: repair-id }))
)

;; Get operator details
(define-read-only (get-operator (operator principal))
  (ok (map-get? operator-records { operator: operator }))
)

;; Get equipment assignment
(define-read-only (get-equipment-assignment (equipment-id (string-ascii 50)))
  (ok (map-get? equipment-assignments { equipment-id: equipment-id }))
)

;; Get current counters
(define-read-only (get-inspection-counter)
  (ok (var-get inspection-counter))
)

(define-read-only (get-defect-counter)
  (ok (var-get defect-counter))
)

(define-read-only (get-repair-counter)
  (ok (var-get repair-counter))
)

;; Check if equipment is operational
(define-read-only (is-equipment-operational (equipment-id (string-ascii 50)))
  (match (map-get? equipment-registry { equipment-id: equipment-id })
    equipment (ok (is-eq (get status equipment) status-operational))
    (ok false)
  )
)

;; Public functions

;; Register new equipment
(define-public (register-equipment (equipment-id (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? equipment-registry { equipment-id: equipment-id })) err-already-exists)
    
    (map-set equipment-registry
      { equipment-id: equipment-id }
      {
        status: status-operational,
        last-inspection-date: u0,
        defect-count: u0,
        total-inspections: u0,
        registered-at: block-height,
        is-active: true
      }
    )
    (var-set equipment-counter (+ (var-get equipment-counter) u1))
    (ok true)
  )
)

;; Register operator
(define-public (register-operator 
  (operator principal)
  (certification-number (string-ascii 50))
  (certification-expiry uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> certification-expiry block-height) err-invalid-input)
    
    (map-set operator-records
      { operator: operator }
      {
        certification-number: certification-number,
        certification-expiry: certification-expiry,
        total-inspections: u0,
        defects-found: u0,
        is-certified: true,
        registered-date: block-height
      }
    )
    (ok true)
  )
)

;; Submit inspection
(define-public (submit-inspection
  (equipment-id (string-ascii 50))
  (brakes-ok bool)
  (steering-ok bool)
  (lights-ok bool)
  (horn-ok bool)
  (tires-ok bool)
  (forks-ok bool)
  (hydraulics-ok bool)
  (notes (string-utf8 500)))
  (let
    (
      (inspection-id (+ (var-get inspection-counter) u1))
      (overall-result (and brakes-ok (and steering-ok (and lights-ok (and horn-ok (and tires-ok (and forks-ok hydraulics-ok)))))))
      (equipment-data (unwrap! (map-get? equipment-registry { equipment-id: equipment-id }) err-not-found))
      (operator-data (map-get? operator-records { operator: tx-sender }))
    )
    
    ;; Verify operator is certified
    (asserts! (is-some operator-data) err-unauthorized)
    (asserts! (get is-certified (unwrap-panic operator-data)) err-unauthorized)
    
    ;; Create inspection record
    (map-set inspections
      { inspection-id: inspection-id }
      {
        equipment-id: equipment-id,
        operator: tx-sender,
        inspection-date: block-height,
        brakes-ok: brakes-ok,
        steering-ok: steering-ok,
        lights-ok: lights-ok,
        horn-ok: horn-ok,
        tires-ok: tires-ok,
        forks-ok: forks-ok,
        hydraulics-ok: hydraulics-ok,
        overall-result: overall-result,
        notes: notes
      }
    )
    
    ;; Update equipment record
    (map-set equipment-registry
      { equipment-id: equipment-id }
      (merge equipment-data {
        last-inspection-date: block-height,
        total-inspections: (+ (get total-inspections equipment-data) u1),
        status: (if overall-result status-operational status-out-of-service)
      })
    )
    
    ;; Update operator record
    (map-set operator-records
      { operator: tx-sender }
      (merge (unwrap-panic operator-data) {
        total-inspections: (+ (get total-inspections (unwrap-panic operator-data)) u1)
      })
    )
    
    (var-set inspection-counter inspection-id)
    (ok inspection-id)
  )
)

;; Report defect
(define-public (report-defect
  (equipment-id (string-ascii 50))
  (inspection-id uint)
  (severity uint)
  (description (string-utf8 500))
  (component (string-ascii 100)))
  (let
    (
      (defect-id (+ (var-get defect-counter) u1))
      (equipment-data (unwrap! (map-get? equipment-registry { equipment-id: equipment-id }) err-not-found))
      (operator-data (unwrap! (map-get? operator-records { operator: tx-sender }) err-unauthorized))
    )
    
    ;; Validate severity
    (asserts! (or (is-eq severity severity-minor) (or (is-eq severity severity-major) (is-eq severity severity-critical))) err-invalid-severity)
    
    ;; Create defect record
    (map-set defects
      { defect-id: defect-id }
      {
        equipment-id: equipment-id,
        inspection-id: inspection-id,
        severity: severity,
        description: description,
        component: component,
        reported-date: block-height,
        reported-by: tx-sender,
        is-resolved: false,
        resolved-date: none
      }
    )
    
    ;; Update equipment defect count
    (map-set equipment-registry
      { equipment-id: equipment-id }
      (merge equipment-data {
        defect-count: (+ (get defect-count equipment-data) u1),
        status: (if (is-eq severity severity-critical) status-out-of-service (get status equipment-data))
      })
    )
    
    ;; Update operator defects found
    (map-set operator-records
      { operator: tx-sender }
      (merge operator-data {
        defects-found: (+ (get defects-found operator-data) u1)
      })
    )
    
    (var-set defect-counter defect-id)
    (ok defect-id)
  )
)

;; Create repair order
(define-public (create-repair-order
  (equipment-id (string-ascii 50))
  (defect-id uint)
  (priority uint))
  (let
    (
      (repair-id (+ (var-get repair-counter) u1))
      (defect-data (unwrap! (map-get? defects { defect-id: defect-id }) err-not-found))
    )
    
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (get equipment-id defect-data) equipment-id) err-invalid-input)
    
    (map-set repair-orders
      { repair-id: repair-id }
      {
        equipment-id: equipment-id,
        defect-id: defect-id,
        priority: priority,
        assigned-to: none,
        created-date: block-height,
        completed-date: none,
        is-completed: false,
        verification-notes: u""
      }
    )
    
    (var-set repair-counter repair-id)
    (ok repair-id)
  )
)

;; Complete repair
(define-public (complete-repair
  (repair-id uint)
  (verification-notes (string-utf8 500)))
  (let
    (
      (repair-data (unwrap! (map-get? repair-orders { repair-id: repair-id }) err-not-found))
      (defect-data (unwrap! (map-get? defects { defect-id: (get defect-id repair-data) }) err-not-found))
      (equipment-data (unwrap! (map-get? equipment-registry { equipment-id: (get equipment-id repair-data) }) err-not-found))
    )
    
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (get is-completed repair-data)) err-invalid-input)
    
    ;; Mark repair as completed
    (map-set repair-orders
      { repair-id: repair-id }
      (merge repair-data {
        is-completed: true,
        completed-date: (some block-height),
        verification-notes: verification-notes
      })
    )
    
    ;; Mark defect as resolved
    (map-set defects
      { defect-id: (get defect-id repair-data) }
      (merge defect-data {
        is-resolved: true,
        resolved-date: (some block-height)
      })
    )
    
    ;; Update equipment status to operational if all critical defects resolved
    (map-set equipment-registry
      { equipment-id: (get equipment-id repair-data) }
      (merge equipment-data {
        status: status-operational
      })
    )
    
    (ok true)
  )
)

;; Update equipment status
(define-public (update-equipment-status
  (equipment-id (string-ascii 50))
  (new-status uint))
  (let
    (
      (equipment-data (unwrap! (map-get? equipment-registry { equipment-id: equipment-id }) err-not-found))
    )
    
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (or (is-eq new-status status-operational) (or (is-eq new-status status-out-of-service) (is-eq new-status status-under-repair))) err-invalid-status)
    
    (map-set equipment-registry
      { equipment-id: equipment-id }
      (merge equipment-data { status: new-status })
    )
    
    (ok true)
  )
)

;; Assign equipment to operator
(define-public (assign-equipment
  (equipment-id (string-ascii 50))
  (operator principal))
  (let
    (
      (equipment-data (unwrap! (map-get? equipment-registry { equipment-id: equipment-id }) err-not-found))
      (operator-data (unwrap! (map-get? operator-records { operator: operator }) err-not-found))
    )
    
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (get is-certified operator-data) err-unauthorized)
    (asserts! (is-eq (get status equipment-data) status-operational) err-equipment-out-of-service)
    
    (map-set equipment-assignments
      { equipment-id: equipment-id }
      {
        operator: (some operator),
        assigned-at: (some block-height)
      }
    )
    
    (ok true)
  )
)

;; Unassign equipment
(define-public (unassign-equipment (equipment-id (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-some (map-get? equipment-registry { equipment-id: equipment-id })) err-not-found)
    
    (map-set equipment-assignments
      { equipment-id: equipment-id }
      {
        operator: none,
        assigned-at: none
      }
    )
    
    (ok true)
  )
)

;; Deactivate equipment
(define-public (deactivate-equipment (equipment-id (string-ascii 50)))
  (let
    (
      (equipment-data (unwrap! (map-get? equipment-registry { equipment-id: equipment-id }) err-not-found))
    )
    
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set equipment-registry
      { equipment-id: equipment-id }
      (merge equipment-data { 
        is-active: false,
        status: status-out-of-service
      })
    )
    
    (ok true)
  )
)

