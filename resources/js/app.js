/* globals ace */
(function() {
  var inputEl = document.querySelector("#e");
  var editorEl = document.querySelector("#editor");
  var formEl = document.querySelector("#form");
  var evalEl = document.querySelector("#eval-button");
  var editor = ace.edit(editorEl, {
    mode: "ace/mode/scheme"
  });

  editor.setValue(`\
(define (fib n)
  (if (< n 2)
      n
      (+ (fib (- n 2))
         (fib (- n 1)))))

(fib 8)
`);
  editor.clearSelection();

  evalEl.addEventListener("click", function() {
    inputEl.value = editor.getValue();
    formEl.submit();
  });
})();
