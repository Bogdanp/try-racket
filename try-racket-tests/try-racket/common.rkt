#lang racket/base

(require db
         koyo/session
         rackunit/text-ui

         (prefix-in config: try-racket/config))


;; sessions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide
 make-test-session-manager)

(define (make-test-session-manager)
  ((make-session-manager-factory #:cookie-name config:session-cookie-name
                                 #:shelf-life config:session-shelf-life
                                 #:secret-key config:session-secret-key
                                 #:store (make-memory-session-store))))
