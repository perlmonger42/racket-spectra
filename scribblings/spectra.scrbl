#lang scribble/manual
@defmodulelang[spectra]

@title{spectra: Yet Another General-Purpose Programming Language}
@author{Thom Boyer}

@section{Introduction}
Spectra provides a wide range of implementation techniques.

@section{Example Documentation for @racketmodname[jsonic]}


This is a domain-specific language
that relies on the @racketmodname[json] library.

In particular, the @racket[jsexpr->string] function.

If we start with this:

@verbatim|{
#lang jsonic
[
  @$ 'null $@,
  @$ (* 6 7) $@,
  @$ (= 2 (+ 1 1)) $@
]
}|

We'll end up with this:

@verbatim{
[
  null,
  42,
  true
]
}