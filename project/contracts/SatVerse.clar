;; SatVerse - Bitcoin-native Digital Identity & Social Layer
;; Initial Commit: Core Identity and Social Contracts

;; IDENTITY CONTRACT (identity.clar)


;; Data Maps
(define-map users principal 
  {
    username: (string-ascii 50),
    bio: (string-utf8 200),
    created-at: uint,
    is-verified: bool
  })

(define-map usernames (string-ascii 50) principal)

;; Data Variables
(define-data-var next-user-id uint u1)

;; Constants
(define-constant ERR-USERNAME-EXISTS (err u1001))
(define-constant ERR-USER-NOT-FOUND (err u1002))
(define-constant ERR-INVALID-USERNAME (err u1003))
(define-constant ERR-NOT-AUTHORIZED (err u1004))

;; Private Functions
(define-private (is-valid-username (username (string-ascii 50)))
  (and 
    (>= (len username) u3)
    (<= (len username) u20)))

;; Public Functions
(define-public (register-user (username (string-ascii 50)) (bio (string-utf8 200)))
  (let 
    (
      (caller tx-sender)
      (current-block block-height)
    )
    (asserts! (is-valid-username username) ERR-INVALID-USERNAME)
    (asserts! (is-none (map-get? usernames username)) ERR-USERNAME-EXISTS)
    (asserts! (is-none (map-get? users caller)) ERR-USERNAME-EXISTS)
    
    (map-set users caller {
      username: username,
      bio: bio,
      created-at: current-block,
      is-verified: false
    })
    (map-set usernames username caller)
    (ok true)))

(define-public (update-bio (new-bio (string-utf8 200)))
  (let ((user-data (unwrap! (map-get? users tx-sender) ERR-USER-NOT-FOUND)))
    (map-set users tx-sender (merge user-data { bio: new-bio }))
    (ok true)))

;; Read-only Functions
(define-read-only (get-user (user-principal principal))
  (map-get? users user-principal))

(define-read-only (resolve-username (username (string-ascii 50)))
  (map-get? usernames username))

;; =============================================================================
;; SOCIAL CONTRACT (social.clar)
;; =============================================================================

;; Data Maps
(define-map connections 
  { follower: principal, following: principal } 
  { created-at: uint })

(define-map follower-counts principal uint)
(define-map following-counts principal uint)

(define-map posts uint 
  {
    author: principal,
    content: (string-utf8 280),
    created-at: uint,
    likes: uint
  })

(define-map post-likes { post-id: uint, user: principal } bool)

;; Data Variables
(define-data-var next-post-id uint u1)

;; Constants
(define-constant ERR-ALREADY-FOLLOWING (err u2001))
(define-constant ERR-NOT-FOLLOWING (err u2002))
(define-constant ERR-POST-NOT-FOUND (err u2003))
(define-constant ERR-ALREADY-LIKED (err u2004))

;; Private Functions
(define-private (increment-follower-count (user principal))
  (let ((current-count (default-to u0 (map-get? follower-counts user))))
    (map-set follower-counts user (+ current-count u1))))

(define-private (increment-following-count (user principal))
  (let ((current-count (default-to u0 (map-get? following-counts user))))
    (map-set following-counts user (+ current-count u1))))

(define-private (decrement-follower-count (user principal))
  (let ((current-count (default-to u0 (map-get? follower-counts user))))
    (if (> current-count u0)
      (map-set follower-counts user (- current-count u1))
      true)))

(define-private (decrement-following-count (user principal))
  (let ((current-count (default-to u0 (map-get? following-counts user))))
    (if (> current-count u0)
      (map-set following-counts user (- current-count u1))
      true)))

;; Public Functions
(define-public (follow-user (user-to-follow principal))
  (let 
    (
      (follower tx-sender)
      (connection-key { follower: follower, following: user-to-follow })
    )
    (asserts! (not (is-eq follower user-to-follow)) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? connections connection-key)) ERR-ALREADY-FOLLOWING)
    
    (map-set connections connection-key { created-at: block-height })
    (increment-follower-count user-to-follow)
    (increment-following-count follower)
    (ok true)))

(define-public (unfollow-user (user-to-unfollow principal))
  (let 
    (
      (follower tx-sender)
      (connection-key { follower: follower, following: user-to-unfollow })
    )
    (asserts! (is-some (map-get? connections connection-key)) ERR-NOT-FOLLOWING)
    
    (map-delete connections connection-key)
    (decrement-follower-count user-to-unfollow)
    (decrement-following-count follower)
    (ok true)))

(define-public (create-post (content (string-utf8 280)))
  (let 
    (
      (post-id (var-get next-post-id))
      (author tx-sender)
    )
    (map-set posts post-id {
      author: author,
      content: content,
      created-at: block-height,
      likes: u0
    })
    (var-set next-post-id (+ post-id u1))
    (ok post-id)))

(define-public (like-post (post-id uint))
  (let 
    (
      (user tx-sender)
      (like-key { post-id: post-id, user: user })
      (post-data (unwrap! (map-get? posts post-id) ERR-POST-NOT-FOUND))
    )
    (asserts! (is-none (map-get? post-likes like-key)) ERR-ALREADY-LIKED)
    
    (map-set post-likes like-key true)
    (map-set posts post-id (merge post-data { 
      likes: (+ (get likes post-data) u1) 
    }))
    (ok true)))

;; Read-only Functions
(define-read-only (is-following (follower principal) (following principal))
  (is-some (map-get? connections { follower: follower, following: following })))

(define-read-only (get-follower-count (user principal))
  (default-to u0 (map-get? follower-counts user)))

(define-read-only (get-following-count (user principal))
  (default-to u0 (map-get? following-counts user)))

(define-read-only (get-post (post-id uint))
  (map-get? posts post-id))

(define-read-only (has-liked-post (post-id uint) (user principal))
  (is-some (map-get? post-likes { post-id: post-id, user: user })))
