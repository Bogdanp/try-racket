#lang info

(define collection "tests")

(define deps '())
(define build-deps '("base"
                     "db-lib"
                     "koyo-lib"
                     "rackunit-lib"

                     "try-racket"))

(define update-implies '("try-racket"))
