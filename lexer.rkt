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

(define-lex-abbrev digits (:+ (char-set "0123456789")))
(define-lex-abbrev alpha (:or alphabetic "_"))
(define-lex-abbrev alnum (:or alphabetic numeric "_"))
(define-lex-abbrev ident (:seq alpha (:* alnum) (:? (char-set "!?"))))

; Should handle \\, \qq[...] and \<string-delimiter>.
; For now, just \\ and \'.
(define-lex-abbrev q-str (:seq
  "'"
  (:*
    (:or (:~ "'" "\\")
         (:seq "\\" "\\")
         (:seq "\\" "'")
    )
  )
  "'"))
(define-lex-abbrev q-str-err (:seq
  "'"
  (:*
    (:or (:~ "'" "\\")
         (:seq "\\" "\\")
         (:seq "\\" "\"")
    )
  )
  ))

; For now, just like '' strings. Later, we need to allow
; for interpolations and standard escape sequences.
(define-lex-abbrev qq-str (:seq
  "\""
  (:*
    (:or (:~ "\"" "\\")
         (:seq "\\" "\\")
         (:seq "\\" "\"")
    )
  )
  "\""))
(define-lex-abbrev qq-str-err (:seq
  "\""
  (:*
    (:or (:~ "\"" "\\")
         (:seq "\\" "\\")
         (:seq "\\" "\"")
    )
  )
  ))

(define-lex-abbrev keywords
  (:or "fn" "var"
       "if" "while"
       "return"
       ))
(define-lex-abbrev operators
  (:or "=" ";" "+" "{" "}"
       ":" "," "(" ")" "//" "/*" "*/"
       "==" "!="
       "+" "-" "/" "*"
       "++"))

(define spectra-lexer
  (lexer-srcloc
   ["\n" (token 'NEWLINE lexeme)]
   [(:+ whitespace) (token 'WHITESPACE lexeme #:skip? #t)]
   [(from/stop-before "//" "\n") (token 'COMMENT lexeme #:skip? #t)]
   [(from/to "｢" "｣") ; no escapes, no interpolation
    (token 'RAW-STRING-LITERAL
           (substring lexeme 1 (sub1 (string-length lexeme))))]
   [(:seq "｢"  (complement (:seq any-string "｣")))
    (token 'RAW-STRING-LITERAL-EOF
           (substring lexeme 1 (string-length lexeme)))]
   [q-str
    (token 'Q-STRING-LITERAL
           (substring lexeme 1 (sub1 (string-length lexeme))))]
   [q-str-err ; missing close '
    (token 'Q-STRING-LITERAL-EOF
           (substring lexeme 1 (string-length lexeme)))]
   [qq-str
    (token 'QQ-STRING-LITERAL
           (substring lexeme 1 (sub1 (string-length lexeme))))]
   [qq-str-err ; missing close "
    (token 'QQ-STRING-LITERAL-EOF
           (substring lexeme 1 (string-length lexeme)))]
   [keywords (token lexeme (string->symbol lexeme))]
   [operators (token lexeme (string->symbol lexeme))]
   [digits (token 'INTEGER-LITERAL (string->number lexeme))]
   [(:or (:seq (:? digits) "." digits) (:seq digits "."))
    (token 'REAL-LITERAL (string->number lexeme))]
   [(:seq ident (:* (:seq (:or "'" "-") ident)))
    (token 'IDENTIFIER (string->symbol lexeme))]
   [any-char (token 'UNEXPECTED-CHAR lexeme)]))

;;; From /Users/thom/Library/Racket/7.0/pkgs/brag/brag/support.rkt:
; (provide from/to)
; (define-lex-trans from/to
;   (λ(stx)
;     (syntax-case stx ()
;       [(_ OPEN CLOSE)
;        #'(:seq (from/stop-before OPEN CLOSE) CLOSE)])))
; 
; (provide from/stop-before)
; (define-lex-trans from/stop-before
;   (λ(stx)
;     (syntax-case stx ()
;       [(_ OPEN CLOSE)
;        ;; (:seq any-string CLOSE any-string) pattern makes it non-greedy
;        #'(:seq OPEN (complement (:seq any-string CLOSE any-string)))])))

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
    (lex "'abc'\"lmnop\"''")
    (list (srcloc-token (token 'Q-STRING-LITERAL "abc")
                        (srcloc 'string 1 0 1 5))
          (srcloc-token (token 'QQ-STRING-LITERAL "lmnop")
                        (srcloc 'string 1 5 6 7))
          (srcloc-token (token 'Q-STRING-LITERAL "")
                        (srcloc 'string 1 12 13 2))
          ))
  (check-equal?
    (lex "// nothing to see here\n")
    (list (srcloc-token (token 'COMMENT "// nothing to see here" #:skip? #t)
                        (srcloc 'string 1 0 1 22))
          (srcloc-token (token 'NEWLINE "\n")
                        (srcloc 'string 1 22 23 1))))
  (check-equal?
    (lex "42   3.14159 'sample string")
    (list (srcloc-token (token 'INTEGER-LITERAL 42)
                        (srcloc 'string 1 0 1 2))
          (srcloc-token (token 'WHITESPACE "   " #:skip? #t)
                        (srcloc 'string 1 2 3 3))
          (srcloc-token (token 'REAL-LITERAL 3.14159)
                        (srcloc 'string 1 5 6 7))
          (srcloc-token (token 'WHITESPACE " " #:skip? #t)
                        (srcloc 'string 1 12 13 1))
          (srcloc-token (token 'Q-STRING-LITERAL-EOF "sample string")
                        (srcloc 'string 1 13 14 14))
     )
  )
  (check-equal?
    (lex "what's-this-fancy-thing?")
    (list (srcloc-token (token 'IDENTIFIER '|what's-this-fancy-thing?|)
                        (srcloc 'string 1 0 1 24))
    )
  )
  (check-equal?
    (lex "xy\n//pqr\nz")
    (list (srcloc-token (token 'IDENTIFIER 'xy)
                        (srcloc 'string 1 0 1 2))
          (srcloc-token (token 'NEWLINE "\n")
                        (srcloc 'string 1 2 3 1))
          (srcloc-token (token 'COMMENT "//pqr" #:skip? #t)
                        (srcloc 'string 2 0 4 5))
          (srcloc-token (token 'NEWLINE "\n")
                        (srcloc 'string 2 5 9 1))
          (srcloc-token (token 'IDENTIFIER 'z)
                        (srcloc 'string 3 0 10 1))
    )
  )
  (check-equal?
    (lex "π=355/113")
    (list (srcloc-token (token 'IDENTIFIER 'π)
                        (srcloc 'string 1 0 1 1))
          (srcloc-token (token '= '=)
                        (srcloc 'string 1 1 2 1))
          (srcloc-token (token 'INTEGER-LITERAL 355)
                        (srcloc 'string 1 2 3 3))
          (srcloc-token (token '/ '/)
                        (srcloc 'string 1 5 6 1))
          (srcloc-token (token 'INTEGER-LITERAL 113)
                        (srcloc 'string 1 6 7 3))
    )
  )
  (check-equal?
    (lex "one-two--three")
    ; kebab-case requires ISOLATED '-' or "'" characters
    (list (srcloc-token (token 'IDENTIFIER 'one-two)
                        (srcloc 'string 1 0 1 7))
          (srcloc-token (token '- '-)
                        (srcloc 'string 1 7 8 1))
          (srcloc-token (token '- '-)
                        (srcloc 'string 1 8 9 1))
          (srcloc-token (token 'IDENTIFIER 'three)
                        (srcloc 'string 1 9 10 5))
    )
  )
)
