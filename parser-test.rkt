#lang br
(require spectra/parser
         spectra/tokenizer
         brag/support
         rackunit)

(check-equal?
 (parse-to-datum
  (apply-tokenizer-maker make-tokenizer "// line commment\n"))
 '(spectra-program))
(check-equal?
 (parse-to-datum
  (apply-tokenizer-maker make-tokenizer "@$ 42 $@"))
 '(spectra-program (spectra-sexp " 42 ")))
(check-equal?
 (parse-to-datum
  (apply-tokenizer-maker make-tokenizer "hi"))
 '(spectra-program
   (spectra-char "h")
   (spectra-char "i")))
(check-equal?
 (parse-to-datum
  (apply-tokenizer-maker make-tokenizer
                         "hi\n// comment\n@$ 42 $@"))
 '(spectra-program
   (spectra-char "h")
   (spectra-char "i")
   (spectra-char "\n")
   (spectra-sexp " 42 ")))
