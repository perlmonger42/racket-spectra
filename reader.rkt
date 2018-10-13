#lang br/quicklang
(require spectra/tokenizer spectra/parser racket/contract)

(provide (contract-out
          [read-syntax (any/c input-port? . -> . syntax?)] ))

(define (read-syntax path port)
  (define parse-tree (parse path (make-tokenizer port)))
  (define module-datum `(module spectra-module spectra/expander
                          ,parse-tree) )
  (datum->syntax #f module-datum) )
