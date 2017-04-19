#lang racket

(require json)
(require racket/tcp)

; file path to store json data in
(define taskFile "tasks")

; list of all fields in a task object
(define taskFields (list
                    'name
                    'due
                    'ID
                    'priority))

(define emptyTask
  (make-immutable-hasheq
   (map (lambda (key)
          (cons key ""))
        taskFields)))


; read the task list from the json file
(define (readTaskList)
  (call-with-input-file taskFile read-json))

; Display the entire task list
(define (displayTasks)
  (define (iter list)
    (if (null? list)
        (void)
        (begin
          (writeTaskObject (car list))
          (iter (cdr list)))))
  (iter (hash-ref (readTaskList) 'tasks)))

; Find a task by ID and change the given fields to their values.
; the fields argument is a list of (key, value) pairs to be updated to the given values
(define (editTask id fields)
  (let ([oldTask (getTaskWithID id)])
    (begin
      (deleteTask id) ;delete old version of the task
      (let ([taskList (readTaskList)]
            [out (open-output-file taskFile #:exists 'truncate)])
        (begin
          (write-json ;add new version of task to task list
           (makeTaskList
            (cons (changeTaskObject oldTask fields) (hash-ref taskList 'tasks))
            (hash-ref taskList 'nextID))
           out)
          (close-output-port out))))))


; delete a task with a given ID
(define (deleteTask id)
  (let ([taskList (readTaskList)]
        [out (open-output-file taskFile #:exists 'truncate)])
    (begin
      (write-json
       (makeTaskList
        (filter (lambda (t) (not (taskID? t id))) (hash-ref taskList 'tasks))
        (hash-ref taskList 'nextID))
       out)
      (close-output-port out))))

(define (getTaskWithID id)
  (let ([taskList (readTaskList)])
    (car (filter (lambda (t) (taskID? t id)) (hash-ref taskList 'tasks)))))

; returns true if a task has the same ID as the given ID
(define (taskID? task id)
  (= id (hash-ref task 'ID)))

; Display a single Task object
(define (writeTaskObject Task)
  (begin
    (write "Task: ")
    (write (hash-ref Task 'name))
    (write ", Due: ")
    (write (hash-ref Task 'due))
    (write ", Priority: ")
    (writeln (hash-ref Task 'priority))))

; change the given fields in a task object to the given values
(define (changeTaskObject task fields)
  (make-immutable-hasheq
   (map (lambda (key)
          (let ([field (filter (lambda (k) (equal? (car k) key)) fields)])
            (if (null? field) ; if the field is being changed, take the new one. else use the old one.
                (cons key (hash-ref task key))
                (car field))))
        taskFields)))

; Create a new task object
(define (makeTask fields)
  (changeTaskObject emptyTask fields))

; Create a new task list object
(define (makeTaskList taskPairs id)
  (make-immutable-hasheq
   (list
    (cons 'nextID id)
    (cons 'tasks taskPairs))))

; Create a new task with specified name and date and add it to the task list. Write result in json file.
(define (addTask id fields)
  (let ([taskList (readTaskList)]
        [out (open-output-file taskFile #:exists 'truncate)])
    (begin
      (write-json
       (makeTaskList
        (cons ; add new task to list of existing tasks
         (makeTask
          (cons
           (cons 'ID (if (equal? id 'auto) ; if an ID is provided, use it. Otherwise generate automatically
                         (hash-ref taskList 'nextID)
                         id))
           fields))
         (hash-ref taskList 'tasks))
        (if (equal? id 'auto) ; if we auto-generated the task ID, increment the 'next ID' value on the list object
            (+ (hash-ref taskList 'nextID) 1)
            (hash-ref taskList 'nextID)))
       out)
      (close-output-port out))))

; Create a new task list to override the existing one in json file
(define (overrideTaskList taskPairs)
  (let ([out (open-output-file taskFile #:exists 'truncate)])
    (begin
      (write-json (makeTaskList taskPairs) out)
      (close-output-port out))))

; Connects to the uml cs server and defines in and out and input and output ports
(define-values (in out) (tcp-connect "cs.uml.edu" 23))

; Code for testing
(overrideTaskList (list
                   (makeTask "OPL Exploration 1" "12 Mar 17")
                   (makeTask "OPL Partner Declarations" "19 Mar 17")
                   (makeTask "OPL Exploration 2" "26 Mar 17")))

; Procedure for sending current tasks to server
(define (sync-up)
  (write (list 'sync-up (readTaskList)) out))

; Procedure for replacing current tasks with those on the server
(define (sync-down-override)
  ((write (list 'sync-down-override) out)
  (overrideTaskList (read in))))

