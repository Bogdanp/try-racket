#lang racket/base

(require koyo/haml
         koyo/session
         racket/contract
         racket/sandbox
         threading
         web-server/http
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
         "Run")))
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
  (define res
    (with-handlers ([exn:fail:resource? (lambda _ 'error)])
      (and~> (request-bindings/raw req)
             (bindings-assq #"e" _)
             (binding:form-value)
             (bytes->string/utf-8)
             (playground-eval playground (current-session-id) _))))

  (page
   #:skip-profile? #t
   (haml
    (.eval-output
     (:pre (format "~s" res))))))
