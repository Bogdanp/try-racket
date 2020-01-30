#lang racket/base

(require (for-syntax racket/base
                     racket/file
                     racket/path
                     syntax/parse)
         koyo/flash
         koyo/haml
         koyo/l10n
         koyo/preload
         koyo/profiler
         koyo/url
         koyo/xexpr
         racket/format
         racket/runtime-path
         web-server/http
         xml
         (prefix-in config: "../config.rkt"))

(provide
 static-uri
 container
 page)

(define-syntax known-static-files
  (let* ([current-dir (build-path (syntax-source #'here) 'up)]
         [static-path (simplify-path (build-path current-dir 'up 'up "static"))])
    (map (lambda (p)
           (find-relative-path static-path p))
         (find-files (compose1 not directory-exists?) static-path))))

(define-syntax (static-uri stx)
  (syntax-parse stx
    [(static-uri path:string)
     (unless (member (string->path (syntax->datum #'path))
                     (syntax-local-value #'known-static-files))
       (raise-syntax-error 'static-uri (format "static file ~v not found" (syntax->datum #'path))))

     #'(let ([p (format "/static/~a?rev=~a" path config:version)])
         (track-preload-dependency! p)
         p)]))

(define (container . content)
  (haml (.container (@ content))))

(define (nav . items)
  (haml
   (.nav
    ([:up-nav ""])
    (container
     (haml (.nav__items (@ items)))))))

(define (nav-item uri label)
  (haml
   (:li.nav__item
    (:a
     ([:href uri]
      [:up-alias uri])
     label))))

(define (page . content)
  ;; profile-write is called inside a different thread so we have to
  ;; grab the current profile here and then pass it in to ensure that
  ;; the right profile gets rendered.
  (define profile (current-profile))

  (with-timing 'template "page"
    (define page
      (haml
       (:html
        (:head
         (:meta ([:charset "utf-8"]))

         (:title "Try Racket")
         (:link ([:rel "stylesheet"] [:href (static-uri "css/screen.css")])))
        (:body
         (.content (@ content))))))

    (response
     200
     #"OK"
     (current-seconds)
     #"text/html; charset=utf-8"
     (make-preload-headers)
     (lambda (out)
       (parameterize ([current-output-port out])
         (displayln "<!doctype html>")
         (write-xml/content (xexpr->xml page))
         (profile-write profile))))))
