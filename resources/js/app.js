/* globals CodeMirror */
(function() {
  const source =
    localStorage.getItem("source") ||
    `\
(define (fib n)
  (if (< n 2)
      n
      (+ (fib (- n 2))
         (fib (- n 1)))))

(fib 8)`;

  const editorEl = document.querySelector("#editor");
  const formEl = document.querySelector("#form");
  const evalEl = document.querySelector("#eval-button");
  const editor = CodeMirror.fromTextArea(editorEl, {
    lineNumbers: true,
    mode: "scheme"
  });

  editor.setOption("extraKeys", {
    "Ctrl-Enter": function() {
      submit();
    }
  });

  editor.setValue(source);
  editor.on("change", function() {
    localStorage.setItem("source", editorEl.value);
  });

  function submit() {
    formEl.submit();
  }

  evalEl.addEventListener("click", submit);
})();
