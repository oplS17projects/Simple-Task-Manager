#lang racket

(require racket/gui)
(require json)
(require "task-client.rkt")

; main window
(define frame (new frame%
                   [label "Task Manager"]
                   [width 500]
                   [height 500]))

; horizontal panel to split interaction buttons and task list
(define panel (new horizontal-panel% [parent frame]))

; vertical panel for interaction buttons
(define functions (new vertical-panel%
                       [parent panel]))
;vertical panel for task list
(define tasks (new vertical-panel%
                   [parent panel]))

;clears all tasks from the panel (this does not delete them)
(define (clearTaskPanel)
  (send tasks change-children (lambda (l) '())))

; add a single task to the task display panel
(define (displaySingleTask task)
  (new message%
       [parent tasks]
       [label (string-append "Task: " (hash-ref task 'name))]))

;Add all current tasks to the task display panel
(define (listTasks)
  (define (iter list)
    (if (null? list)
        (void)
        (begin
          (displaySingleTask (car list))
          (iter (cdr list)))))
  (begin
    (clearTaskPanel) 
    (iter (hash-ref (readTaskList) 'tasks))))

;function that adds all interaction buttons to the interactions panel
(define (draw-buttons)
  (begin
    (new button% ; Button to add a task
         [parent functions]
         [label "Add Task"]
         [callback (lambda (button event)
                     (launchAddTaskDialog))])
    (new button% ; Button to clear all tasks
         [parent functions]
         [label "Clear Tasks"]
         [callback (lambda (button event)
                     (begin
                       (overrideTaskList)
                       (clearTaskPanel)))])))

; Launch the dialog box to add a task
(define (launchAddTaskDialog)
  (begin
    (define addTaskDialog (instantiate dialog% ("Add Task"))) ; main dialog object
    (define nameBox (new text-field% ; text field for task name
         [parent addTaskDialog]
         [label "Task Name"]))
    (define dueBox (new text-field% ; text field for task due date
         [parent addTaskDialog]
         [label "Due Date"]))
    (define buttonPanel (new horizontal-panel% ; panel to hold buttons
                             [parent addTaskDialog]
                             [alignment '(center center)]))
    (new button% ; button to add task
         [parent buttonPanel]
         [label "Add Task"]
         [callback (lambda (button event)
                     (begin
                       (addTask
                        'auto
                        (list
                         (cons 'name (send nameBox get-value))))
                       (listTasks)
                       (send addTaskDialog show #f)))])
    (new button% ; button to cancel operation
         [parent buttonPanel]
         [label "Cancel"]
         [callback (lambda (button event)
                     (send addTaskDialog show #f))])
    (send addTaskDialog show #t)))

;function to launch the gui
(define (start-gui)
  (begin
    (draw-buttons)
    (listTasks)
    (send frame show #t)))
