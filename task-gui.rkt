#lang racket

(require racket/gui)
(require "task-client.rkt")

; main window
(define frame (new frame%
                   [label "Task Manager"]
                   [width 800]
                   [height 800]))

; horizontal panel to split interaction buttons and task list
(define panel (new horizontal-panel% [parent frame]))

; vertical panel for interaction buttons
(define functions (new vertical-panel%
                       [parent panel]))
;vertical panel for task list
(define tasks (new vertical-panel%
                   [parent panel]))

;radio box for tracking which tasks we display
(define displayType (void))

;clears all tasks from the panel (this does not delete them)
(define (clearTaskPanel)
  (send tasks change-children (lambda (l) '())))

; add a single task to the task display panel
(define (displaySingleTask task)
  (let ([taskPanel (new vertical-panel%
                        [parent tasks])])
    (begin
      (new message%
           [parent taskPanel]
           [label (string-append "Task: " (hash-ref task 'name))])
      (new message%
           [parent taskPanel]
           [label (string-append "Due: " (dateString (hash-ref task 'due)))])
      (new message%
           [parent taskPanel]
           [label (string-append "Priority: " (hash-ref task 'priority))])
      (new message%
           [parent taskPanel]
           [label (string-append "Duration: " (number->string (hash-ref task 'duration)))])
      (new button%
           [parent taskPanel]
           [label "edit"]
           [callback (lambda (button event)
                       (launchEditTaskDialog task))])
      (new button%
           [parent taskPanel]
           [label "delete"]
           [callback (lambda (button event)
                       (begin
                         (deleteTask (hash-ref task 'ID))
                         (listTasks)))])
       )))
  

; Shows all or todays tasks based on current setting
(define (listTasks)
  (if (equal? "All Tasks" (send displayType get-item-label (send displayType get-selection)))
      (listAllTasks)
      (listTodaysTasks)))

; Add all current tasks to the task display panel
(define (listAllTasks)
  (begin
    (clearTaskPanel) 
    (showTasks (hash-ref (readTaskList) 'tasks))))

; Add all tasks chosen for today (based on priority and amount of time to work each day) to the display panel
(define (listTodaysTasks)
  (begin
    (clearTaskPanel)
    (showTasks (getTodaysTasks))))

; add tasks in given list to the task display panel
(define (showTasks list)
  (if (null? list)
      (void)
      (begin
        (displaySingleTask (car list))
        (showTasks (cdr list)))))

;function that adds all interaction buttons to the interactions panel
(define (draw-buttons)
  (begin
    (send functions change-children (lambda (l) '()))
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
                       (clearTaskPanel)))])
    (set! displayType (new radio-box% ; Radio button to choose display method for tasks
         [parent functions]
         [label "Display"]
         [choices (list "All Tasks" "Today's Tasks")]
         [callback (lambda (button event)
                     (listTasks))]))
    (new text-field%
         [parent functions]
         [label "Working Hours"]
         [callback (lambda (field event)
                     (begin
                       (changeWorkHours (string->number (send field get-value)))
                       (listTasks)))])))

; Launch the dialog box to add a task
(define (launchAddTaskDialog)
  (begin
    (define addTaskDialog (instantiate dialog% ("Add Task"))) ; main dialog object
    (define nameBox (new text-field% ; text field for task name
                         [parent addTaskDialog]
                         [label "Task Name"]))
    (define dueDayBox (new text-field% ; text field for task due date
                           [parent addTaskDialog]
                           [label "Due Day"]))
    (define dueMonthBox (new text-field% ; text field for task due date
                             [parent addTaskDialog]
                             [label "Due Month"]))
    (define dueYearBox (new text-field% ; text field for task due date
                            [parent addTaskDialog]
                            [label "Due Year"]))
    (define priorityBox (new combo-field% ; text field for task due date
                             [parent addTaskDialog]
                             [label "Priority"]
                             [choices (list "very high" "high" "medium" "low" "very low")]
                             [init-value "medium"]))
    (define durationBox (new text-field% ; text field for task due date
                             [parent addTaskDialog]
                             [label "Duration"]))

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
                         (cons 'name (send nameBox get-value))
                         (cons 'due (simpleMakeDate
                                     (string->number (send dueDayBox get-value))
                                     (string->number (send dueMonthBox get-value))
                                     (string->number (send dueYearBox get-value))))
                         (cons 'priority (send priorityBox get-value))
                         (cons 'duration (string->number (send durationBox get-value)))))
                       (listTasks)
                       (send addTaskDialog show #f)))])
    (new button% ; button to cancel operation
         [parent buttonPanel]
         [label "Cancel"]
         [callback (lambda (button event)
                     (send addTaskDialog show #f))])
    (send addTaskDialog show #t)))

; launch dialog to edit a task
(define (launchEditTaskDialog task)
  (begin
    (define editTaskDialog (instantiate dialog% ("Edit Task"))) ; main dialog object
    (define nameBox (new text-field% ; text field for task name
                         [parent editTaskDialog]
                         [label "Task Name"]))
    (define dueDayBox (new text-field% ; text field for task due date
                           [parent editTaskDialog]
                           [label "Due Day"]))
    (define dueMonthBox (new text-field% ; text field for task due date
                             [parent editTaskDialog]
                             [label "Due Month"]))
    (define dueYearBox (new text-field% ; text field for task due date
                            [parent editTaskDialog]
                            [label "Due Year"]))
    (define priorityBox (new combo-field% ; text field for task due date
                             [parent editTaskDialog]
                             [label "Priority"]
                             [choices (list "very high" "high" "medium" "low" "very low")]
                             [init-value "medium"]))
    (define durationBox (new text-field% ; text field for task due date
                             [parent editTaskDialog]
                             [label "Duration"]))
    ; initialize fields
    (send nameBox set-value (hash-ref task 'name))
    (send dueDayBox set-value (number->string (getDay (hash-ref task 'due))))
    (send dueMonthBox set-value (number->string (getMonth (hash-ref task 'due))))
    (send dueYearBox set-value (number->string (getYear (hash-ref task 'due))))
    (send priorityBox set-value (hash-ref task 'priority))
    (send durationBox set-value (number->string (hash-ref task 'duration)))
    
    (define buttonPanel (new horizontal-panel% ; panel to hold buttons
                             [parent editTaskDialog]
                             [alignment '(center center)]))
    (new button% ; button to add task
         [parent buttonPanel]
         [label "edit Task"]
         [callback (lambda (button event)
                     (begin
                       (editTask
                        (hash-ref task 'ID)
                        (list
                         (cons 'name (send nameBox get-value))
                         (cons 'due (simpleMakeDate
                                     (string->number (send dueDayBox get-value))
                                     (string->number (send dueMonthBox get-value))
                                     (string->number (send dueYearBox get-value))))
                         (cons 'priority (send priorityBox get-value))
                         (cons 'duration (string->number (send durationBox get-value)))))
                       (listTasks)
                       (send editTaskDialog show #f)))])
    (new button% ; button to cancel operation
         [parent buttonPanel]
         [label "Cancel"]
         [callback (lambda (button event)
                     (send editTaskDialog show #f))])
    (send editTaskDialog show #t)))

;function to launch the gui
(define (start-gui)
  (begin
    (draw-buttons)
    (listTasks)
    (send frame show #t)))
