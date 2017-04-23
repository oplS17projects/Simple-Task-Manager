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
                    'priority
                    'duration))

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
            (hash-ref taskList 'nextID)
            (hash-ref taskList 'workHours))
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
        (hash-ref taskList 'nextID)
        (hash-ref taskList 'workHours))
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
    (write 'Task: )
    (write (hash-ref Task 'name))
    (write ', Due: )
    (write (hash-ref Task 'due))
    (write ', Duration: )
    (write (hash-ref Task 'duration))
    (write 'hours)
    (write ', Priority: )
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
(define (makeTaskList taskPairs id workHours)
  (make-immutable-hasheq
   (list
    (cons 'nextID id)
    (cons 'workHours workHours)
    (cons 'tasks taskPairs))))

; Create a new task with specified fields and add it to the task list. Write result in json file.
; the id can either be a numerical ID, or the 'auto symbol, which will automatically generate an id based on the task list
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
            (hash-ref taskList 'nextID))
        (hash-ref taskList 'workHours))
       out)
      (close-output-port out))))

; Create a new empty task list
(define (overrideTaskList)
  (let ([out (open-output-file taskFile #:exists 'truncate)])
    (begin
      (write-json (makeTaskList '() 0 8) out)
      (close-output-port out))))

; sort by due date, grab tasks until duration totals to certain value
; once we add tags, we can filter our certain tags pretty trivially before sorting 
(define (getTodaysTasks)
  (let ([taskList (readTaskList)])
    (getTasksForNHours (hash-ref taskList 'workHours)
                       (sort (hash-ref taskList 'tasks) < #:key (lambda (x) (hash-ref x 'due))))))

; Extract tasks until total duration hours reaches/exceeds given value. Skip tasks with no duration
(define (getTasksForNHours hours tasks)
  (define (iter desiredHours currentHours allTasks newTasks)
    (if (or (< currentHours desiredHours) (null? allTasks))
        newTasks
        (if (equal? "" (hash-ref (car allTasks) 'duration))
            (iter desiredHours currentHours (cdr allTasks) newTasks)
            (iter desiredHours
                  (+ currentHours
                     (hash-ref (car allTasks) 'duration))
                  (cdr allTasks)
                  (cons (car allTasks) newTasks)))))
  (iter hours 0 tasks '()))
        

; Code for testing
(define (tests)
  (begin (overrideTaskList)
         (addTask 'auto (list (cons 'name "OPL Exploration 1") (cons 'due "12 Mar 17") (cons 'priority "high") (cons 'duration 3)))
         (addTask 'auto (list (cons 'name "OPL Partner Declarations") (cons 'due "19 Mar 17") (cons 'priority "low") (cons 'duration 4)))
         (addTask 'auto (list (cons 'name "OPL Exploration 2") (cons 'due "26 Mar 17") (cons 'priority "medium") (cons 'duration 2)))
         (editTask 1 (list (cons 'priority "very high") (cons 'duration 1)))
         (getTodaysTasks)))

; Connects to the uml cs server and defines in and out and input and output ports
;(define-values (in out) (tcp-connect "cs.uml.edu" 23))

; Procedure for sending current tasks to server
;(define (sync-up)
;  (write (list 'sync-up (readTaskList)) out))

; Procedure for replacing current tasks with those on the server
;(define (sync-down-override)
;  ((write (list 'sync-down-override) out)
;  (overrideTaskList (read in))))
