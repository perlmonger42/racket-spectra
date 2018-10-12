#lang br/quicklang
(require brag/support racket/contract)

(provide
 (contract-out
  [make-tokenizer (input-port? . -> . (-> spectra-token?))] ) )

(module+ test
  (require rackunit))

(define (spectra-token? x)
  (or (eof-object? x) (string? x) (token-struct? x)))

(module+ test
  (check-true (spectra-token? eof))
  (check-true (spectra-token? "a string"))
  (check-true (spectra-token? (token 'A-TOKEN-STRUCT "hi")))
  (check-false (spectra-token? 42)) )

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

(module+ test
  (check-equal?
   (apply-tokenizer-maker make-tokenizer "// comment\n")
   empty)
  (check-equal?
   (apply-tokenizer-maker make-tokenizer "@$ (+ 6 7) $@")
   (list (token-struct 'SEXP-TOK " (+ 6 7) " #f #f #f #f #f)))
  (check-equal?
   (apply-tokenizer-maker make-tokenizer "hi")
   (list (token-struct 'CHAR-TOK "h" #f #f #f #f #f)
         (token-struct 'CHAR-TOK "i" #f #f #f #f #f))))
