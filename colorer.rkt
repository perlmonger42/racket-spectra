#lang br
(require spectra/lexer brag/support syntax-color/racket-lexer
         racket/contract)
(provide
 (contract-out
  [spectra-colorer
   (input-port? exact-nonnegative-integer? any/c
                . -> . (values
                        (or/c eof-object? string? symbol? number?)
                        symbol?
                        (or/c symbol? #f)
                        (or/c exact-positive-integer? #f)
                        (or/c exact-positive-integer? #f)
                        exact-nonnegative-integer?
                        any/c))]))

(define (spectra-colorer port offset context_info)
  (define (handle-lexer-error excn)
    (define excn-srclocs (exn:fail:read-srclocs excn))
    (srcloc-token (token 'ERROR) (car excn-srclocs)))
  (define srcloc-tok
    (with-handlers ([exn:fail:read? handle-lexer-error])
                   (spectra-lexer port)))
  (match srcloc-tok
    [(? eof-object?) (values srcloc-tok 'eof #f #f #f 0 'context-info)]
    [else
      (match-define
        (srcloc-token
          (token-struct type val _ _ _ _ _)
          (srcloc _ _ _ posn span)) srcloc-tok)
      (define start posn)
      (define end (+ start span))
      (match-define (list cat paren)
        (match type
          [(or 'RAW-STRING-LITERAL 'Q-STRING-LITERAL
               'QQ-STRING-LITERAL)
           '(string #f)]
          ['COMMENT '(comment #f)]
          [(or '|(| '|{| '|[|)
           '(parenthesis |(|)]
          [(or '|)| '|}| '|]|)
                   '(parenthesis |)|)]
          [(or '|=| '|;| '|+| '|:| '|,|
               '|+| '|-| '|/| '|*|
               '|++|
               '|==| '|!=| '|<| '|<=| '|>| '|>=|)
           '(operator #f)]
          [(or 'ERROR 'RAW-STRING-LITERAL-EOF
               'Q-STRING-LITERAL-EOF 'QQ-STRING-LITERAL-EOF)
           '(error #f)]
          [else (match val
                  [(? number?) '(constant #f)]
                  [(? symbol?) '(symbol #f)]
                  [else '(no-color #f)])]))
      (values val cat paren start end 0 'context-info)]))

(module+ test
  (require rackunit)
  (check-equal? (values->list
                  (spectra-colorer (open-input-string "x") 0 #f))
                '(x symbol #f 1 2 0 context-info)))

(module+ test
  (define test-input (open-input-string "//comment\n[({7})]"))
  (check-equal? (values->list
                 (spectra-colorer test-input 0 #f))
                '("//comment" comment #f 1 10 0 context-info))
  (check-equal? (values->list
                 (spectra-colorer test-input 0 #f))
                '("\n" no-color #f 10 11 0 context-info))
  (check-equal? (values->list
                 (spectra-colorer test-input 0 #f))
                '(|[| parenthesis |(| 11 12 0 context-info))
  (check-equal? (values->list
                 (spectra-colorer test-input 0 #f))
                '(|(| parenthesis |(| 12 13 0 context-info))
  (check-equal? (values->list
                 (spectra-colorer test-input 0 #f))
                '(|{| parenthesis |(| 13 14 0 context-info))
  (check-equal? (values->list
                 (spectra-colorer test-input 0 #f))
                '(7 constant #f 14 15 0 context-info))
  (check-equal? (values->list
                 (spectra-colorer test-input 0 #f))
                '(|}| parenthesis |)| 15 16 0 context-info))
  (check-equal? (values->list
                 (spectra-colorer test-input 0 #f))
                '(|)| parenthesis |)| 16 17 0 context-info))
  (check-equal? (values->list
                 (spectra-colorer test-input 0 #f))
                '(|]| parenthesis |)| 17 18 0 context-info))
  (check-equal? (values->list
                 (spectra-colorer test-input 0 #f))
                `(,eof eof #f #f #f 0 context-info))
  (check-equal? (values->list
                 (spectra-colorer test-input 0 #f))
                `(,eof eof #f #f #f 0 context-info)))
