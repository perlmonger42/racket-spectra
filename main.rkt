#lang br/quicklang
(module reader br
  (require spectra/reader)
  (provide read-syntax get-info)

  (define (get-info port src-mod src-line src-col src-pos)
    (define (handle-query key default)
      (case key
        [(color-lexer)
         (dynamic-require 'spectra/colorer 'spectra-colorer)]
        [(drracket:indentation)
         (dynamic-require 'spectra/indenter 'indent-spectra)]
        [(drracket:toolbar-buttons)
         (dynamic-require 'spectra/buttons 'button-list)]
        [else default]))
    handle-query))
