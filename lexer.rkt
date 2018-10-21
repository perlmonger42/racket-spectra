#lang br/quicklang
(require brag/support racket/contract)

(provide
 (contract-out
   [spectra-token? (any/c . -> . boolean?)]
   [spectra-lexer (input-port? . -> . spectra-token?)]))

(module+ test
  (require rackunit))

(define (spectra-token? x)
  (or (eof-object? x) (srcloc-token? x)))

(module+ test
  (check-true (spectra-token? eof))
  (check-true (spectra-token? (srcloc-token 'hi (srcloc #f 1 0 1 2)))))

(define spectra-lexer
  (lexer-srcloc
   [(from/to "//" "\n") (token 'COMMENT lexeme #:skip? #t)]
   [(from/to "@$" "$@")
    (token 'SEXP-TOK (trim-ends "@$" lexeme "$@"))]
   [any-char (token 'CHAR-TOK lexeme)]))

(module+ test
  (require rackunit)
  ; The srcloc fields are:
  ;   source : any/c
  ;   line : (or/c exact-positive-integer? #f)            1-based
  ;   column : (or/c exact-nonnegative-integer? #f)       0-based
  ;   position : (or/c exact-positive-integer? #f)        1-based
  ;   span : (or/c exact-nonnegative-integer? #f)         0-based
  ; In all these tests, the `source` is 'string because the lexer
  ; input is a string (rather than a file, for example).
  (define (lex str)
    (apply-lexer spectra-lexer str))
  (check-equal?
  (check-equal?
   (lex "// nothing to see here\n")
   (list (srcloc-token (token 'COMMENT "// nothing to see here\n" #:skip? #t)
                       (srcloc 'string 1 0 1 23))))
  (check-equal?
   (lex "@$ (equal? 42 (* 7 9)) $@")
   (list (srcloc-token (token 'SEXP-TOK " (equal? 42 (* 7 9)) ")
                       (srcloc 'string 1 0 1 25))))
  (check-equal?
   (lex "xy\n//pqr\nz")
   (list(srcloc-token (token 'CHAR-TOK "x")
                       (srcloc 'string 1 0 1 1))
         (srcloc-token (token 'CHAR-TOK "y")
                       (srcloc 'string 1 1 2 1))
         (srcloc-token (token 'CHAR-TOK "\n")
                       (srcloc 'string 1 2 3 1))
         (srcloc-token (token 'COMMENT "//pqr\n" #:skip? #t)
                       (srcloc 'string 2 0 4 6))
         (srcloc-token (token 'CHAR-TOK "z")
                       (srcloc 'string 3 0 10 1))))))
