#lang info
(define collection "spectra")
(define version "1.0")
(define scribblings '(("scribblings/spectra.scrbl")))
(define test-omit-paths '("spectra-test.rkt"))
(define deps '("base"
               "beautiful-racket-lib"
               "brag"
               "draw-lib"
               "gui-lib"
               "rackunit-lib"
               "syntax-color-lib"))
(define build-deps '("racket-doc"
                     "scribble-lib"))
