;; SatVerse Phase 2 - Enhanced Social Features (Compact Version)
;; Branch: feature/enhanced-social

;; REPUTATION CONTRACT (reputation.clar)

;; Data Maps
(define-map user-reputation principal 
  {
    score: uint,
    posts-created: uint,
    likes-received: uint,
    last-updated: uint
  })

;; Constants
(define-constant POINTS-NEW-POST u10)
(define-constant POINTS-RECEIVED-LIKE u5)
(define-constant POINTS-JOIN-COMMUNITY u20)

;; Public Functions
(define-public (update-reputation (user principal) (event-type (string-ascii 20)) (points uint))
  (let 
    (
      (current-rep (default-to 
        { score: u0, posts-created: u0, likes-received: u0, last-updated: u0 }
        (map-get? user-reputation user)))
    )
    (map-set user-reputation user 
      (merge current-rep {
        score: (+ (get score current-rep) points),
        last-updated: block-height
      }))
    (ok true)))

;; Read-only Functions
(define-read-only (get-reputation (user principal))
  (default-to 
    { score: u0, posts-created: u0, likes-received: u0, last-updated: u0 }
    (map-get? user-reputation user)))

(define-read-only (get-reputation-rank (user principal))
  (let ((rep-data (get-reputation user)))
    (if (>= (get score rep-data) u500) "Expert" 
    (if (>= (get score rep-data) u200) "Veteran"
    (if (>= (get score rep-data) u50) "Member" "Newbie")))))

;; =============================================================================
;; COMMUNITIES CONTRACT (communities.clar)
;; =============================================================================

;; Data Maps
(define-map communities uint 
  {
    name: (string-ascii 50),
    description: (string-utf8 200),
    creator: principal,
    created-at: uint,
    member-count: uint
  })

(define-map community-members 
  { community-id: uint, member: principal }
  { joined-at: uint })

(define-map community-posts uint 
  {
    community-id: uint,
    author: principal,
    content: (string-utf8 300),
    created-at: uint,
    likes: uint
  })

;; Data Variables
(define-data-var next-community-id uint u1)
(define-data-var next-community-post-id uint u1)

;; Constants
(define-constant ERR-COMMUNITY-NOT-FOUND (err u3001))
(define-constant ERR-NOT-MEMBER (err u3002))
(define-constant ERR-ALREADY-MEMBER (err u3003))

;; Public Functions
(define-public (create-community 
  (name (string-ascii 50)) 
  (description (string-utf8 200)))
  (let 
    (
      (community-id (var-get next-community-id))
      (creator tx-sender)
    )
    (map-set communities community-id {
      name: name,
      description: description,
      creator: creator,
      created-at: block-height,
      member-count: u1
    })
    
    ;; Creator automatically joins
    (map-set community-members 
      { community-id: community-id, member: creator }
      { joined-at: block-height })
    
    (var-set next-community-id (+ community-id u1))
    (ok community-id)))

(define-public (join-community (community-id uint))
  (let 
    (
      (member tx-sender)
      (community-data (unwrap! (map-get? communities community-id) ERR-COMMUNITY-NOT-FOUND))
      (member-key { community-id: community-id, member: member })
    )
    (asserts! (is-none (map-get? community-members member-key)) ERR-ALREADY-MEMBER)
    
    (map-set community-members member-key { joined-at: block-height })
    
    ;; Increment member count
    (map-set communities community-id 
      (merge community-data { 
        member-count: (+ (get member-count community-data) u1) 
      }))
    
    ;; Update reputation - remove for now, will be handled externally
    (ok true)))

(define-public (create-community-post 
  (community-id uint)
  (content (string-utf8 300)))
  (let 
    (
      (post-id (var-get next-community-post-id))
      (author tx-sender)
      (member-key { community-id: community-id, member: author })
    )
    ;; Check if user is member
    (asserts! (is-some (map-get? community-members member-key)) ERR-NOT-MEMBER)
    
    (map-set community-posts post-id {
      community-id: community-id,
      author: author,
      content: content,
      created-at: block-height,
      likes: u0
    })
    
    (var-set next-community-post-id (+ post-id u1))
    
    ;; Update reputation - remove for now, will be handled externally
    (ok post-id)))

(define-public (like-community-post (post-id uint))
  (let 
    (
      (post-data (unwrap! (map-get? community-posts post-id) ERR-COMMUNITY-NOT-FOUND))
      (post-author (get author post-data))
    )
    (map-set community-posts post-id 
      (merge post-data { 
        likes: (+ (get likes post-data) u1) 
      }))
    
    ;; Update author's reputation - remove for now, will be handled externally
    (ok true)))

;; Read-only Functions
(define-read-only (get-community (community-id uint))
  (map-get? communities community-id))

(define-read-only (is-community-member (community-id uint) (user principal))
  (is-some (map-get? community-members { community-id: community-id, member: user })))

(define-read-only (get-community-post (post-id uint))
  (map-get? community-posts post-id))

;; =============================================================================
;; ENHANCED SOCIAL CONTRACT (enhanced-social.clar)
;; =============================================================================

;; Data Maps - Enhanced from Phase 1
(define-map enhanced-posts uint 
  {
    author: principal,
    content: (string-utf8 280),
    created-at: uint,
    likes: uint,
    reposts: uint
  })

(define-map post-reposts { post-id: uint, user: principal } bool)

;; Data Variables
(define-data-var next-enhanced-post-id uint u1)

;; Constants
(define-constant ERR-POST-NOT-FOUND (err u4001))
(define-constant ERR-ALREADY-REPOSTED (err u4002))

;; Public Functions
(define-public (create-enhanced-post (content (string-utf8 280)))
  (let 
    (
      (post-id (var-get next-enhanced-post-id))
      (author tx-sender)
    )
    (map-set enhanced-posts post-id {
      author: author,
      content: content,
      created-at: block-height,
      likes: u0,
      reposts: u0
    })
    
    (var-set next-enhanced-post-id (+ post-id u1))
    
    ;; Update reputation - remove for now, will be handled externally
    (ok post-id)))

(define-public (repost (original-post-id uint))
  (let 
    (
      (user tx-sender)
      (post-data (unwrap! (map-get? enhanced-posts original-post-id) ERR-POST-NOT-FOUND))
      (repost-key { post-id: original-post-id, user: user })
    )
    (asserts! (is-none (map-get? post-reposts repost-key)) ERR-ALREADY-REPOSTED)
    
    (map-set post-reposts repost-key true)
    (map-set enhanced-posts original-post-id 
      (merge post-data { 
        reposts: (+ (get reposts post-data) u1) 
      }))
    (ok true)))

(define-public (like-enhanced-post (post-id uint))
  (let 
    (
      (post-data (unwrap! (map-get? enhanced-posts post-id) ERR-POST-NOT-FOUND))
      (post-author (get author post-data))
    )
    (map-set enhanced-posts post-id 
      (merge post-data { 
        likes: (+ (get likes post-data) u1) 
      }))
    
    ;; Update author's reputation - remove for now, will be handled externally
    (ok true)))

;; Read-only Functions
(define-read-only (get-enhanced-post (post-id uint))
  (map-get? enhanced-posts post-id))

(define-read-only (has-reposted (post-id uint) (user principal))
  (is-some (map-get? post-reposts { post-id: post-id, user: user })))
