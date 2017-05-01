#lang racket

(require json)
(require racket/tcp)
(require racket/date)

; File path to store json data in
(define taskFile "server-tasks")

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
  (displayTaskList (hash-ref (readTaskList) 'tasks)))

(define (displayTodaysTasks)
  (displayTaskList (getTodaysTasks)))

; Display the given task list
(define (displayTaskList list)
  (if (null? list)
      (void)
      (begin
        (writeTaskObject (car list))
        (displayTaskList (cdr list)))))

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
    (let ([due (hash-ref Task 'due)])
      (if (equal? "" due)
          (write "")
          (write (dateString due))))
    (write ', Duration: )
    (write (hash-ref Task 'duration))
    (write 'hours)
    (write ', Priority: )
    (writeln (hash-ref Task 'priority))))

; pulls string to display a date
(define (dateString seconds)
  (date->string (seconds->date seconds)))

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

; change desired working hours of a task list
(define (changeWorkHours hours)
  (let ([taskList (readTaskList)]
        [out (open-output-file taskFile #:exists 'truncate)])
    (begin
      (write-json (makeTaskList (hash-ref taskList 'tasks) (hash-ref taskList 'nextID) hours) out)
      (close-output-port out))))

; Create a new task with specified fields and add it to the task list. Write result in json file.
; the id can either be a numerical ID, or the 'auto symbol, which will automatically generate an id based on the task list
(define (addTask id fields)
  (let ([taskList (readTaskList)]
        [out (open-output-file taskFile #:exists 'truncate)])
    (begin
      (write-json
       (makeTaskList
        (cons ; add new task to list of existing tasks
         (let ([filteredFields (filter (lambda (x) (not (equal? (car x) 'ID))) fields)])
           (makeTask
            (cons
             (cons 'ID (if (equal? id 'auto) ; if an ID is provided, use it. Otherwise generate automatically
                           (hash-ref taskList 'nextID)
                           id))
             fields)))
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
    (reverse (getTasksForNHours (hash-ref taskList 'workHours)
                       (sortByPriorityDue (hash-ref taskList 'tasks))))))

(define (sortByPriorityDue tasks)
  (append (sort (filter (lambda (x) (equal? "very high" (hash-ref x 'priority))) tasks) < #:key (lambda (x) (hash-ref x 'due)))
          (sort (filter (lambda (x) (equal? "high" (hash-ref x 'priority))) tasks) < #:key (lambda (x) (hash-ref x 'due)))
          (sort (filter (lambda (x) (equal? "medium" (hash-ref x 'priority))) tasks) < #:key (lambda (x) (hash-ref x 'due)))
          (sort (filter (lambda (x) (equal? "low" (hash-ref x 'priority))) tasks) < #:key (lambda (x) (hash-ref x 'due)))
          (sort (filter (lambda (x) (equal? "very low" (hash-ref x 'priority))) tasks) < #:key (lambda (x) (hash-ref x 'due)))))

; Extract tasks until total duration hours reaches/exceeds given value. Skip tasks with no duration
(define (getTasksForNHours hours tasks)
  (define (iter desiredHours currentHours allTasks newTasks)
    (if (or (< desiredHours currentHours) (null? allTasks))
        newTasks
        (if (equal? "" (hash-ref (car allTasks) 'duration))
            (iter desiredHours currentHours (cdr allTasks) newTasks)
            (iter desiredHours
                  (+ currentHours
                     (hash-ref (car allTasks) 'duration))
                  (cdr allTasks)
                  (cons (car allTasks) newTasks)))))
  (let ([durationTasks (filter (lambda (x) (number? (hash-ref x 'duration))) tasks)])
    (iter hours 0 durationTasks '())))

; Creates a date object without caring about time, day of the week, or day of the year, and auto-filling some fields
(define (simpleMakeDate day month year)
  (date->seconds (make-date 0 0 0 day month year 0 0 (date-dst? (current-date)) (date-time-zone-offset (current-date)))))

; Updates tasks in a task list
(define (updateTaskList tasks)
  (let ([hours (hash-ref (readTaskList) 'workHours)])
    (begin
      (overrideTaskList)
      (map (lambda (x) (addTask 'auto x)) tasks)
      (changeWorkHours hours))))

; Sets up ports
(define listener (tcp-listen 8080))
(define-values (in out) (tcp-accept listener))

(overrideTaskList)

(define (loop)
  (let ([input (read-json in)])
    (cond
      [(eof-object? input) #t]
      [(equal? (jsexpr->string input) "{\"sync-down-override\":0}") (begin (write-json (readTaskList) out) (flush-output out))]
      [(equal? (jsexpr->string input) "{\"clear\":0}") (overrideTaskList)]
      [(equal? (jsexpr->string input) "{\"quit\":0}") (begin (close-input-port in) (close-output-port out) (exit 0))]
      [else (updateTaskList (map (lambda (n)(hash->list n)) (hash-ref input 'tasks)))])
  (loop)))
(loop)