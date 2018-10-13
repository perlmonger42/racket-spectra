#lang br
(require brag/support syntax-color/racket-lexer
         racket/contract)
(provide
 (contract-out
  [color-spectra
   (input-port? exact-nonnegative-integer? boolean?
                . -> . (values
                        (or/c string? eof-object?)
                        symbol?
                        (or/c symbol? #f)
                        (or/c exact-positive-integer? #f)
                        (or/c exact-positive-integer? #f)
                        exact-nonnegative-integer?
                        boolean?))]))

(define spectra-lexer
  ; the syntax-coloring lexer should return 5 values for each token:
  ; (values lexeme color-category parenthesis-shape start-position end-position)
  (lexer
   [(eof) (values lexeme 'eof #f #f #f)]
   [(:or "@$" "$@")
    (values lexeme 'parenthesis
            (if (equal? lexeme "@$") '|(| '|)|)
            (pos lexeme-start) (pos lexeme-end))]
   [(from/to "//" "\n")
    (values lexeme 'comment #f
            (pos lexeme-start) (pos lexeme-end))]
   [any-char
    (values lexeme 'string #f
            (pos lexeme-start) (pos lexeme-end))]))

(define (color-spectra port offset racket-coloring-mode?)
  (cond
    [(or (not racket-coloring-mode?)
         (equal? (peek-string 2 0 port) "$@"))
     (define-values (str cat paren start end)
       (spectra-lexer port))
     (define switch-to-racket-mode (equal? str "@$"))
     (values str cat paren start end 0 switch-to-racket-mode)]
    [else
     (define-values (str cat paren start end)
       (racket-lexer port))
     (values str cat paren start end 0 #t)]))

(module+ test
  (require rackunit)
  (check-equal? (values->list
                 (color-spectra (open-input-string "x") 0 #f))
                (list "x" 'string #f 1 2 0 #f)))

(module+ test
  (define test-input (open-input-string "//comment\n[@$7$@]"))
  (check-equal? (values->list
                 (color-spectra test-input 0 #f))
                '("//comment\n" comment #f 1 11 0 #f))
  (check-equal? (values->list
                 (color-spectra test-input 0 #f))
                '("[" string #f 11 12 0 #f))
  (check-equal? (values->list
                 (color-spectra test-input 0 #f))
                '("@$" parenthesis |(| 12 14 0 #t))
  (check-equal? (values->list
                 (color-spectra test-input 0 #f))
                '("7" string #f 14 15 0 #f))
  (check-equal? (values->list
                 (color-spectra test-input 0 #f))
                '("$@" parenthesis |)| 15 17 0 #f))
  (check-equal? (values->list
                 (color-spectra test-input 0 #f))
                '("]" string #f 17 18 0 #f))
  (check-equal? (values->list
                 (color-spectra test-input 0 #f))
                `(,eof eof #f #f #f 0 #f))
  (check-equal? (values->list
                 (color-spectra test-input 0 #f))
                `(,eof eof #f #f #f 0 #f)))
