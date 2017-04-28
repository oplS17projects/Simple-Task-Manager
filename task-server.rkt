#lang racket

(require json)
(require racket/tcp)

; File path to store json data in
(define taskFile "tasks")

; Read the task list from the json file
(define (readTaskList)
  (call-with-input-file taskFile read-json))

; Create a new task object
(define (makeTask name due)
  (make-immutable-hasheq
   (list
    (cons 'name name)
    (cons 'due due))))

; Create a new task list object
(define (makeTaskList taskPairs)
  (make-immutable-hasheq
   (list
    (cons
     'tasks
     taskPairs))))

; Create a new task list to override the existing one in json file
(define (overrideTaskList taskPairs)
  (let ([out (open-output-file taskFile #:exists 'truncate)])
    (begin
      (write-json (makeTaskList taskPairs) out)
      (close-output-port out))))

; Sets up ports
(define listener (tcp-listen 8080))
(define-values (in out) (tcp-accept listener))

(define (loop)
  (let ([input (read in)])
    (cond
      [(eof-object? input) #t]
      [(eqv? (car input) 'sync-up) (overrideTaskList (cadr input))]
      [(eqv? (car input) 'sync-down-override) (begin (write (readTaskList) out) (flush-output out))]
      [(eqv? (car input) 'quit) (begin (close-input-port in) (close-output-port out) (exit 0))]
      [else #t]))
  (loop))