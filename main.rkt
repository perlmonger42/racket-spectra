#lang br/quicklang
(module reader br
  (require spectra/reader)
  (provide read-syntax get-info)

  (define (get-info port src-mod src-line src-col src-pos)
    (define (handle-query key default)
      (case key
        [(color-lexer)
         (dynamic-require 'spectra/colorer 'color-spectra)]
        [(drracket:indentation)
         (dynamic-require 'spectra/indenter 'indent-spectra)]
        [else default]))
    handle-query))