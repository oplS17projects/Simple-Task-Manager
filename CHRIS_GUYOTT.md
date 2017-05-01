# Simple Task Manager

## Chris Guyott
### April 30, 2017

# Overview
This program stores and displays task objects that have names, due dates, durations, and priorities. There are procedures to modify,
add, sort, and search stored tasks. These tasks can also be synced to a server on a different machine.

# Libraries Used
The code uses three libraries:

```
(require json)
(require racket/tcp)
(require racket/date)
```

* The ```json``` library allows tasks to be represented and transmitted as json objects.
* The ```tcp``` library allows the client and server portions of the program to interface.
* The ```date``` library is used to track the current date and compare it to the due dates of tasks.

# Key Code Excerpts

Here is a discussion of the most essential procedures, including a description of how they embody ideas from 
UMass Lowell's COMP.3010 Organization of Programming languages course.

Three examples are shown and they are individually numbered. 

## 1. TCP Connection

The following code connects sets up the listener on the server:

```
(define listener (tcp-listen 8080))
(define-values (in out) (tcp-accept listener))
 ```
 
 The tricky part of this code was the ```tcp-accept``` function returns an input port and an output port. I figured out that you can
 use  ```define-values``` to bind a symbol to each return value.
 
## 2. Syncing From Server to Client

This is the code for loading the tasks stored on the server to the client:
```
(define (sync-down-override)
  (write-json (string->jsexpr "{\"sync-down-override\":0}") out)
  (flush-output out)
  (overrideTaskList)
  (updateTaskList (map (lambda (n)(hash->list n)) (hash-ref (read-json in) 'tasks))))
```
The first line converts the string ```"{\"sync-down-override\":0}"``` to a json object and the next line flushes the output buffer,
sending it to the server. The next two lines clear the task and load the new one recieved from the server.

More relevant to concepts we discussed in class is the map call that is passed as the argument to ```updateTaskList```. This procedure
accepts a list as an argument and the expression ```(hash-ref (read-json in) 'tasks)``` produces a list of hash tables. The map applies
an anonymous procedure that converts each hash table to a list and evaluates as a list of lists which ```updateTaskList``` accepts.

## 3. Server Loop

This is the loop the server runs to respond to messages from the client.

```
(define (loop)
  (let ([input (read-json in)])
    (cond
      [(eof-object? input) #t]
      [(equal? (jsexpr->string input) "{\"sync-down-override\":0}") (begin (write-json (readTaskList) out) (flush-output out))]
      [(equal? (jsexpr->string input) "{\"clear\":0}") (overrideTaskList)]
      [(equal? (jsexpr->string input) "{\"quit\":0}") (begin (close-input-port in) (close-output-port out) (exit 0))]
      [else (updateTaskList (map (lambda (n)(hash->list n)) (hash-ref input 'tasks)))])
  (loop)))
```
The main part I want to discuss about this is the system for determining what the server needs to do. At the beginning of the loop a
json object is read in. If the client wants to sync down, clear the tasks on the server, or quit, this json object is the given string
(i.e. ```"{\"sync-down-override\":0}"```) converted into a json object and passed through tcp. When it is transformed into a string with
```jsexpr->string``` it matches one of the first three cases of the cond statement. The last case is for when the client wants to sync
it's tasks up to the server. In this case, the client simply

This code segment also has a call to ```updateTaskList``` that is identical to the one in the previous statement that handles the case
where the tasks are synced up to the server. In this case the client sends it's set of tasks as json and the server saves it.

I got the idea for how to implement this from the message passing we learned in class, where you pass a symbol that acts as a message
so the code on the recieving end knows what to do.
