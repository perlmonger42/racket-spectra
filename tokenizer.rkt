#lang br/quicklang
(require brag/support racket/contract spectra/lexer)

(provide
 (contract-out
  [make-tokenizer (input-port? . -> . (-> spectra-token?))] ) )

(define (make-tokenizer port)
  (port-count-lines! port)
  (define (next-token) (spectra-lexer port))
  next-token)

(module+ test
  (require rackunit)
  ; The srcloc fields are:
  ;   source : any/c
  ;   line : (or/c exact-positive-integer? #f)            1-based
  ;   column : (or/c exact-nonnegative-integer? #f)       0-based
  ;   position : (or/c exact-positive-integer? #f)        1-based
  ;   span : (or/c exact-nonnegative-integer? #f)         0-based
  ; The `source` is 'string in all these tests because the lexer
  ; input is a string (rather than a file, for example).
  (check-equal?
   (apply-tokenizer-maker make-tokenizer "// comment\n")
   (list (srcloc-token (token 'COMMENT "// comment\n" #:skip? #t)
                       (srcloc 'string 1 0 1 11))))
  (check-equal?
   (apply-tokenizer-maker make-tokenizer "@$ (+ 6 7) $@")
   (list (srcloc-token (token 'SEXP-TOK " (+ 6 7) ")
                       (srcloc 'string 1 0 1 13))))
  (check-equal?
   (apply-tokenizer-maker make-tokenizer "hi")
   (list (srcloc-token (token 'CHAR-TOK "h")
                       (srcloc 'string 1 0 1 1))
         (srcloc-token (token 'CHAR-TOK "i")
                       (srcloc 'string 1 1 2 1))))

  (check-equal?
   (apply-tokenizer-maker make-tokenizer "//x\ny\nz")
   (list (srcloc-token (token 'COMMENT "//x\n" #:skip? #t)
                       (srcloc 'string 1 0 1 4))
         (srcloc-token (token 'CHAR-TOK "y")
                       (srcloc 'string 2 0 5 1))
         (srcloc-token (token 'CHAR-TOK "\n")
                       (srcloc 'string 2 1 6 1))
         (srcloc-token (token 'CHAR-TOK "z")
                       (srcloc 'string 3 0 7 1)))))
