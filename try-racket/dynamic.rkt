#lang racket/base

(require component
         koyo/flash
         koyo/logging
         koyo/server
         koyo/session
         racket/contract
         "components/app.rkt"
         "components/playground.rkt"
         (prefix-in config: "config.rkt"))

;; System ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-system prod
  [app (flashes playground sessions) make-app]
  [flashes (sessions) make-flash-manager]
  [playground () make-playground]
  [server (app) (compose1 (make-server-factory #:host config:http-host
                                               #:port config:http-port) app-dispatcher)]
  [sessions (make-session-manager-factory #:cookie-name config:session-cookie-name
                                          #:cookie-secure? #f
                                          #:shelf-life config:session-shelf-life
                                          #:secret-key config:session-secret-key
                                          #:store (make-memory-session-store #:file-path "/tmp/try-racket-session.ss"))])


;; Interface ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide
 prod-system
 start)

(define/contract (start)
  (-> (-> void?))

  (define stop-logger
    (start-logger
     #:levels `((app                  . ,config:log-level)
                (mail-adapter         . ,config:log-level)
                (memory-session-store . ,config:log-level)
                (server               . ,config:log-level)
                (session              . ,config:log-level)
                (system               . ,config:log-level))))

  (system-start prod-system)

  (lambda ()
    (system-stop prod-system)
    (stop-logger)))


(module+ main
  (define stop (start))
  (with-handlers ([exn:break? (lambda _
                                (stop)
                                (sync/enable-break (system-idle-evt)))])
    (sync/enable-break never-evt)))
