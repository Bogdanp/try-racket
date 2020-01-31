#lang racket/base

(require component
         racket/logging
         racket/match
         racket/port
         racket/sandbox)

(provide
 make-playground
 playground?
 playground-eval)

(define SANDBOX-TTL (* 10 60 1000))

(struct sandbox (deadline evaluator inp outp))

(define (make-sandbox)
  (define-values (inp outp) (make-pipe))
  (parameterize ([sandbox-eval-limits '(60 64)]
                 [sandbox-namespace-specs (append (sandbox-namespace-specs)
                                                  (list 'pict))]
                 [sandbox-output outp])
    (sandbox 0 (make-evaluator 'racket) inp outp)))

(define (sandbox-extend-deadline s)
  (struct-copy sandbox s [deadline (+ (current-inexact-milliseconds) SANDBOX-TTL)]))

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

(define (playground-sandbox/session p id)
  (call-with-semaphore (playground-sema p)
    (lambda ()
      (define s (hash-ref! (playground-sandboxes p) id make-sandbox))
      (begin0 s
        (hash-update! (playground-sandboxes p) id sandbox-extend-deadline)))))

(define (playground-eval p id e)
  (match-define (sandbox _ evaluator inp outp)
    (playground-sandbox/session p id))
  (values
   (evaluator e)
   (port->bytes-avail! inp)))

(define MAX-OUTPUT-SIZE (* 1 1024 1024))

(define (port->bytes-avail! in)
  (call-with-output-bytes
   (lambda (out)
     (define buf (make-bytes (* 1024 16)))
     (let loop ([total-read 0])
       (define n-read (read-bytes-avail!* buf in))
       (unless (or (eof-object? n-read)
                   (zero? n-read))
         (when (< total-read MAX-OUTPUT-SIZE)
           (display (subbytes buf 0 n-read) out))
         (loop (+ total-read n-read)))))))
