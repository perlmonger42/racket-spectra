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
  (port-count-lines! port)
  (define (next-token)
    (define spectra-lexer
      (lexer
       [(from/to "//" "\n") (next-token)]
       [(from/to "@$" "$@")
        (token 'SEXP-TOK (trim-ends "@$" lexeme "$@")
               #:position (+ (pos lexeme-start) 2)
               #:line (line lexeme-start)
               #:column (+ (col lexeme-start) 2)
               #:span (- (pos lexeme-end) (pos lexeme-start) 4))]
       [any-char (token 'CHAR-TOK lexeme
                        #:position (pos lexeme-start)
                        #:line (line lexeme-start)
                        #:column (col lexeme-start)
                        #:span (- (pos lexeme-end) (pos lexeme-start)))]))
    (spectra-lexer port))
  next-token)

(module+ test
  (check-equal?
   (apply-tokenizer-maker make-tokenizer "// comment\n")
   empty)
  (check-equal?
   (apply-tokenizer-maker make-tokenizer "@$ (+ 6 7) $@")
   (list (token 'SEXP-TOK " (+ 6 7) "
                #:position 3
                #:line 1
                #:column 2
                #:span 9)))
  (check-equal?
   (apply-tokenizer-maker make-tokenizer "hi")
   (list (token 'CHAR-TOK "h"
                #:position 1
                #:line 1
                #:column 0
                #:span 1)
         (token 'CHAR-TOK "i"
                #:position 2
                #:line 1
                #:column 1
                #:span 1)))
  (check-equal?
   (apply-tokenizer-maker make-tokenizer "//x\ny\nz")
   (list (token-struct 'CHAR-TOK "y" 5 2 0 1 #f)
         (token-struct 'CHAR-TOK "\n" 6 2 1 1 #f)
         (token-struct 'CHAR-TOK "z" 7 3 0 1 #f))))
