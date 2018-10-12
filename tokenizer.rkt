#lang br/quicklang
(require brag/support racket/contract)

(provide
 (contract-out
  [make-tokenizer (input-port? . -> . (-> spectra-token?))] ) )

(define (spectra-token? x)
  (or (eof-object? x) (string? x) (token-struct? x)) )

(define (make-tokenizer port)
  (define (next-token)
    (define spectra-lexer
      (lexer
       [(from/to "//" "\n") (next-token)]
       [(from/to "@$" "$@")
        (token 'SEXP-TOK (trim-ends "@$" lexeme "$@"))]
       [any-char (token 'CHAR-TOK lexeme)]))
    (spectra-lexer port))
  next-token)
