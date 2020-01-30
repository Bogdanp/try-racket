#lang racket/base

(require component
         racket/logging
         racket/sandbox)

(provide
 make-playground
 playground?
 playground-eval)

(struct sandbox (deadline evaluator))

(define (make-sandbox)
  (parameterize ([sandbox-eval-limits '(60 64)])
    (sandbox 0 (make-evaluator 'racket/base))))

(define (sandbox-extend-deadline s)
  (struct-copy sandbox s [deadline (+ (current-inexact-milliseconds)
                                      (* 30 60 1000))]))

(struct playground (sema sandboxes janitor)
  #:methods gen:component
  [(define (component-start p)
     (struct-copy playground p [janitor (make-janitor p)]))

   (define (component-stop _)
     (playground (make-hash) #f))])

(define (make-playground)
  (playground (make-semaphore 1) (make-hash) #f))

(define-logger janitor)

(define (make-janitor p)
  (define sandboxes (playground-sandboxes p))
  (thread
   (lambda _
     (let loop ()
       (with-handlers ([exn:fail? (lambda (e)
                                    (log-janitor-error "~a" (exn-message e)))])
         (call-with-semaphore (playground-sema p)
           (lambda ()
             (cleanup-sandboxes! sandboxes))))
       (sleep 60)
       (loop)))))

(define (cleanup-sandboxes! sandboxes)
  (for ([(id s) (in-hash sandboxes)])
    (when (< (sandbox-deadline s) (current-inexact-milliseconds))
      (hash-remove! sandboxes id))))

(define (playground-evaluator/session p id)
  (call-with-semaphore (playground-sema p)
    (lambda ()
      (define s (hash-ref! (playground-sandboxes p) id make-sandbox))
      (begin0 (sandbox-evaluator s)
        (hash-update! (playground-sandboxes p) id sandbox-extend-deadline)))))

(define (playground-eval p id e)
  ((playground-evaluator/session p id) e))
