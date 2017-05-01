# Simple Task Manager in Racket

## Cassandra Cooper
### April 30, 2017

# Overview
This project provides a simple system for managing tasks. Aside from basic interactions, this system provides an auto-generated daily todo list, based on task priorities, due dates, and expected duration. 

The task data storage is stored in JSON file to allow for easy syncing across devices via a web service. The majority of the interactions involve adjusting task objects in this file, which are structured as a set of properties. 

Due to the functional nature of the project, the JSON file is rewritten in its entirety every time a change is made. Thus is it unideal for very large task sets, but should be fine for personal or small group use.

**Authorship Note:** All code described in the excerpts below was written by myself, though the project was completed with the assistance of Chris Guyott (@cguyott)

# Libraries Used
The project requires three libraries:

'''
(require json)
(require racket/tcp)
(require racket/date)
'''

* The '''json''' library provides parsing and writting of the task list as a json file
* The '''racket/tcp''' library is used to facilitate syncing via a web service
* The '''racket/date''' library is used to handle due dates for tasks in a sensible manner that preserves timezone data

# Key Code Excerpts

Below is a discussion of several key procedures used on the client side of the project. The discussion highlights ways in which these excerpts embody the ideas taught in UMass Lowell's COMP.3010 Organization of Programming Languages course.

All excerpt code below is written by myself.

## 1. Functionally creating objects, rather than using assignment to mutate them

Tasks are created by the '''makeTask''' procedure, which simply takes a list of fields which should have non-default values

'''
(define (makeTask fields)
  (changeTaskObject emptyTask fields))
'''

The '''changeTaskObject''' procedure takes a task and a list of fields to change, and then goes through every supported field and checks for it in the list to modify. If the field it present, we take the new value. Otherwise we keep the previous one.

'''
(define (changeTaskObject task fields)
  (make-immutable-hasheq
   (map (lambda (key)
          (let ([field (filter (lambda (k) (equal? (car k) key)) fields)])
            (if (null? field) ; if the field is being changed, take the new one. else use the old one.
                (cons key (hash-ref task key))
                (car field))))
        taskFields)))
'''

Since '''makeTask''' changes fields in an empty task, constructed below, we know all tasks will have every valid field. This uses a map from the list of valid fields to a list of key value pairs, initializing all fields to an empty string. 

'''
(define emptyTask
  (make-immutable-hasheq
   (map (lambda (key)
          (cons key ""))
        taskFields)))
'''

## 2. Successive filtering to sort a subset of a list

In order to construct the daily task list, we need to first sort by priority and due date. The '''sortByPriorityDue''' procedure facilitates this, and abstracts the functionality, meaning additional ordering by other fields can easily be added.

'''
(define (sortByPriorityDue tasks)
  (append (sort (filter (lambda (x) (equal? "very high" (hash-ref x 'priority))) tasks) < #:key (lambda (x) (hash-ref x 'due)))
          (sort (filter (lambda (x) (equal? "high" (hash-ref x 'priority))) tasks) < #:key (lambda (x) (hash-ref x 'due)))
          (sort (filter (lambda (x) (equal? "medium" (hash-ref x 'priority))) tasks) < #:key (lambda (x) (hash-ref x 'due)))
          (sort (filter (lambda (x) (equal? "low" (hash-ref x 'priority))) tasks) < #:key (lambda (x) (hash-ref x 'due)))
          (sort (filter (lambda (x) (equal? "very low" (hash-ref x 'priority))) tasks) < #:key (lambda (x) (hash-ref x 'due)))))
'''

## 3. Recursively construct a sublist of variable length using tail recursion

Once we have sorted the list, we recursively walk through it to pull enough entries to fill the user's desired working hours. This is done by the '''getTasksForNHours''' procedure. A differently sorted list could be passed to produce a daily list that puts emphasis on different fields.

The iteration procedure first checks if we have passed our desired hour limit. If so, we return our list. Otherwise, we call the iteration again, adding the current task to the list and adding the number of hours it's expected to take to the current hours count. 

Before initiating the loop, we filter out all tasks without a specified duration.

'''
(define (getTasksForNHours hours tasks)
  (define (iter desiredHours currentHours allTasks newTasks)
    (if (or (< desiredHours currentHours) (null? allTasks))
        newTasks
        (iter desiredHours
              (+ currentHours
                 (hash-ref (car allTasks) 'duration))
              (cdr allTasks)
              (cons (car allTasks) newTasks))))
  (let ([durationTasks (filter (lambda (x) (number? (hash-ref x 'duration))) tasks)])
    (iter hours 0 durationTasks '())))
'''

## 4. Procedural abstraction for dealing with dates

Currently, dates are implemented using the racket/date library, but other libraries exist to provide additional support and functionality. In case this extra functionality is ever needed, access to the three date fields we care about (day, month, year), as well as the creation and display of dates, is all encapsulated in simple procedures provided by the main client module.

'''
(provide dateString)
(provide simpleMakeDate)
(provide getDay)
(provide getMonth)
(provide getYear)
'''

Date creation gets timezone information from the current date, and then sets most other info to 0 before converting to a Unix time stamp:

'''
(define (simpleMakeDate day month year)
  (date->seconds (make-date 0 0 0 day month year 0 0 (date-dst? (current-date)) (date-time-zone-offset (current-date)))))
'''

All accessors currently just wrap accessors to the date struct:

'''
(define (getDay seconds)
  (date-day (seconds->date seconds)))

'''