/* globals CodeMirror */
(function() {
  var editorEl = document.querySelector("#editor");
  var formEl = document.querySelector("#form");
  var evalEl = document.querySelector("#eval-button");
  var editor = CodeMirror.fromTextArea(editorEl, {
    lineNumbers: true,
    mode: "scheme"
  });

  editor.setValue(`\
(define (fib n)
  (if (< n 2)
      n
      (+ (fib (- n 2))
         (fib (- n 1)))))

(fib 8)`);

  evalEl.addEventListener("click", function() {
    formEl.submit();
  });
})();
