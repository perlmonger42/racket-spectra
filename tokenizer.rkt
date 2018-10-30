#lang br/quicklang
(require brag/support racket/contract spectra/lexer)

(provide
 (contract-out
  [make-tokenizer (input-port? . -> . (-> spectra-token?))] ) )

(define (make-tokenizer port [path #f])
  (port-count-lines! port)
  (lexer-file-path path)
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
    (list (srcloc-token (token 'COMMENT "// comment" #:skip? #t)
                        (srcloc 'string 1 0 1 10))
          (srcloc-token (token 'NEWLINE "\n")
                        (srcloc 'string 1 10 11 1))))
  (check-equal?
    (apply-tokenizer-maker make-tokenizer "｢raw \\\\ string \\n｣")
    (list (srcloc-token (token 'RAW-STRING-LITERAL "raw \\\\ string \\n")
                        (srcloc 'string 1 0 1 18))))
  (check-equal?
    (apply-tokenizer-maker make-tokenizer "｢raw \\\\ string \\n oops!")
    (list (srcloc-token (token 'RAW-STRING-LITERAL-EOF
                               "raw \\\\ string \\n oops!")
                        (srcloc 'string 1 0 1 23))))
  (check-equal?
    (apply-tokenizer-maker make-tokenizer "kebab-case: isn't that pretty?")
    (list (srcloc-token (token 'IDENTIFIER 'kebab-case)
                        (srcloc 'string 1 0 1 10))
          (srcloc-token (token ': ':)
                        (srcloc 'string 1 10 11 1))
          (srcloc-token (token 'WHITESPACE " " #:skip? #t)
                        (srcloc 'string 1 11 12 1))
          (srcloc-token (token 'IDENTIFIER '|isn't|)
                        (srcloc 'string 1 12 13 5))
          (srcloc-token (token 'WHITESPACE " " #:skip? #t)
                        (srcloc 'string 1 17 18 1))
          (srcloc-token (token 'IDENTIFIER 'that)
                        (srcloc 'string 1 18 19 4))
          (srcloc-token (token 'WHITESPACE " " #:skip? #t)
                        (srcloc 'string 1 22 23 1))
          (srcloc-token (token 'IDENTIFIER 'pretty?)
                        (srcloc 'string 1 23 24 7))
          ))
)
