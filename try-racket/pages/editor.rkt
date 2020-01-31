#lang racket/base

(require json
         koyo/haml
         koyo/json
         koyo/session
         net/base64
         racket/contract
         racket/format
         racket/match
         racket/sandbox
         threading
         web-server/http
         web-server/private/util
         "../components/playground.rkt"
         "../components/template.rkt")

(provide
 editor-page
 eval-page)

(define/contract (editor-page _)
  (-> request? response?)
  (page
   (haml
    (.editor
     (:form
      ([:action "/eval"]
       [:class "editor__form"]
       [:id "form"]
       [:method "POST"]
       [:target "eval"])
      (:textarea#editor
       ([:id "e"]
        [:name "e"]
        [:type "hidden"])))
     (.editor__eval
      (:ul.editor__eval__toolbar
       (:li
        (:button
         ([:id "eval-button"])
         "▶ Run")))
      (:iframe
       ([:id "eval"]
        [:name "eval"])))
     (:link ([:rel "stylesheet"]
             [:href (static-uri "vendor/codemirror.css")]))
     (:script ([:src (static-uri "vendor/codemirror.js")]))
     (:script ([:src (static-uri "vendor/codemirror-scheme.js")]))
     (:script ([:src (static-uri "js/app.js")]))))))

(define/contract ((eval-page playground) req)
  (-> playground? (-> request? response?))
  (define-values (render-exn render-result)
    (case (response-format req)
      [(json) (values render-exn/json render-result/json)]
      [else   (values render-exn/html render-result/html)]))

  (with-handlers ([exn? render-exn])
    (define st (current-inexact-milliseconds))
    (define-values (res out)
      (and~> (request-bindings/raw req)
             (bindings-assq #"e" _)
             (binding:form-value)
             (bytes->string/utf-8)
             (playground-eval playground (current-session-id) _)))

    (render-result res out (- (current-inexact-milliseconds) st))))

(define (response-format req)
  (match (headers-assq* #"accept" (request-headers/raw req))
    [(header _ (regexp #"application/json")) 'json]
    [(header _ (regexp #"text/html")) 'html]
    [_ 'html]))

(define (render-exn/html e)
  (page
   #:skip-profile? #t
   (haml
    (.eval-output.error
     (:pre (exn->string e))))))

(define (render-result/html res out duration)
  (page
   #:skip-profile? #t
   (haml
    (.eval-output
     (:pre (format "~a" out))
     (unless (void? res)
       (haml (:pre (format "~s" res))))
     (.eval-timing
      (:small "Done after "
              (~r #:precision 3 duration)
              " ms"))))))

(define (render-exn/json e)
  (response/json
   #:code 400
   (hasheq 'error (exn->string e))))

(define (render-result/json res out duration)
  (response/json
   (hasheq 'output (bytes->string/utf-8 (base64-encode out #""))
           'result (cond
                     [(void? res) (json-null)]
                     [else (format "~s" res)])
           'duration duration)))
