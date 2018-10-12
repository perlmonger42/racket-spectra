#lang br/quicklang
(require json)

(define-macro (spectra-mb PARSE-TREE)
  #'(#%module-begin
     (define result-string PARSE-TREE)
     (define validated-jsexpr (string->jsexpr result-string))
     (display result-string)))
(provide (rename-out [spectra-mb #%module-begin]))

(define-macro (spectra-char CHAR-TOK-VALUE)
  #'CHAR-TOK-VALUE)
(provide spectra-char)

(define-macro (spectra-program SEXP-OR-JSON-STR ...)
  #'(string-trim (string-append SEXP-OR-JSON-STR ...)))
(provide spectra-program)

(define-macro (spectra-sexp SEXP-STR)
  (with-pattern ([SEXP-DATUM (format-datum '~a #'SEXP-STR)])
    #'(jsexpr->string SEXP-DATUM)))
(provide spectra-sexp)
