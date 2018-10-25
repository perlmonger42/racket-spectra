#lang br
(require spectra/parser
         spectra/tokenizer
         brag/support
         rackunit)

(check-equal?
 (parse-to-datum
  (apply-tokenizer-maker make-tokenizer "// line commment\n"))
 '(spectra-program (spectra-token (whitespace "\n"))))

(check-equal?
 (parse-to-datum
  (apply-tokenizer-maker make-tokenizer "fn f { Φ = (1+√5)/2 }"))
 '(spectra-program
    (spectra-token (keyword fn))
    (spectra-token (identifier f))
    (spectra-token (punctuation |{|))
    (spectra-token (identifier Φ))
    (spectra-token (punctuation =))
    (spectra-token (punctuation |(|))
    (spectra-token (literal 1))
    (spectra-token (operator +))
    (spectra-token (unexpected "√"))
    (spectra-token (literal 5))
    (spectra-token (punctuation |)|))
    (spectra-token (operator /))
    (spectra-token (literal 2))
    (spectra-token (punctuation |}|))
    ))
 
; (check-equal?
;  (parse-to-datum
;   (apply-tokenizer-maker make-tokenizer "hi"))
;  '(spectra-program
;    (spectra-char "h")
;    (spectra-char "i")))
; 
; (check-equal?
;  (parse-to-datum
;   (apply-tokenizer-maker make-tokenizer
;                          "hi\n// comment\n@$ 42 $@"))
; 
;  '(spectra-program
;    (spectra-char "h")
;    (spectra-char "i")
;    (spectra-char "\n")
;    (spectra-sexp " 42 ")))
