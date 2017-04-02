# Simple Task Manager

### Statement
Describe your project. Why is it interesting? Why is it interesting to you personally? What do you hope to learn? 

### Analysis

We will be using data abstraction, object-orientation and state modification in the implementation of task objects. These objects will store information like time, location, date, and tags that can be modified, displayed and shared by other parts of the program. We will use filter to select a subset of all tasks to display and map to transform the task data objects to objects that can be used by the gui.

<!--
Explain what approaches from class you will bring to bear on the project.

Be explicit about the techiques from the class that you will use. For example:

- Will you use data abstraction? How?
- Will you use recursion? How?
- Will you use map/filter/reduce? How? 
- Will you use object-orientation? How?
- Will you use functional approaches to processing your data? How?
- Will you use state-modification approaches? How? (If so, this should be encapsulated within objects. `set!` pretty much should only exist inside an object.)
- Will you build an expression evaluator, like we did in the symbolic differentatior and the metacircular evaluator?
- Will you use lazy evaluation approaches?

The idea here is to identify what ideas from the class you will use in carrying out your project. 

**Your project will be graded, in part, by the extent to which you adopt approaches from the course into your implementation, _and_ your discussion about this.**
-->

### External Technologies

This program will be able to connect with a server to sync across multiple systems or devices. It will use JSON to pass the data between the server and client.

<!--
You are encouraged to develop a project that connects to external systems. For example, this includes systems that:

- retrieve information or publish data to the web
- generate or process sound
- control robots or other physical systems
- interact with databases

If your project will do anything in this category (not only the things listed above!), include this section and discuss.
-->

<!--
### Data Sets or other Source Materials
If you will be working with existing data, where will you get those data from? (Dowload from a website? Access in a database? Create in a simulation you will build? ...)

How will you convert your data into a form usable for your project?  

If you are pulling data from somewhere, actually go download it and look at it before writing the proposal. Explain in some detail what your plan is for accomplishing the necessary processing.

If you are using some other starting materials, explain what they are. Basically: anything you plan to use that isn't code.
-->

### Deliverable and Demonstration

At completion we will be able to display a schedule and add/remove tasks from it. We will also be able to filter based on tags or task types and set priorities for tasks.

This program will store and display user inputted data. We can show it working but adding, removing or modifying data through the program.
<!--
Explain exactly what you'll have at the end. What will it be able to do at the live demo?

What exactly will you produce at the end of the project? A piece of software, yes, but what will it do? Here are some questions to think about (and answer depending on your application).

Will it run on some data, like batch mode? Will you present some analytical results of the processing? How can it be re-run on different source data?

Will it be interactive? Can you show it working? This project involves a live demo, so interactivity is good.
-->

### Evaluation of Results
We have divided our goals for this program into core objectives and stretch goals.
# Core
Basic Task management system
-task object
-priority
-deadline
-expected duration (total)
-expected time remaining
-basic interface (GUI/REPL)
-auto-gen daily TODO list
-server for cross device syncing

# Stretch
-better features for multi-user systems
 -group tasks
  -shared task ownership
   -some way to check status of other people's tasks
   -some way to set someone else's task as 'blocking' one of your tasks
   -create/assign tasks for other people
   -sub tasks
   -ordered and unordered
-daily to-do options
 -based on day of the week
 -skip a task for today and get a new one
 -get tasks from different 'categories' on different days (i.e. don't get work tasks on the weekend)
-additional task options
 -put a task on hold (set period of time or indefinitely)
 -time slice options (good for large tasks)
 -ongoing tasks with no real time estimate
 -only one sub-task per day option
 -automatically increase priority of tasks that are due soon or overdue
 -some options/hardcoded control on maximum amount to increase by
 -'flexible' option that gives a date range instead of a single due date
 -reminders
 -GUI
  
Once we complete our core objectives then we will have completed the core of our project, however there are many additional components that we would like to implement. How many of these are actually implemented will depend on how difficult the core objectives are and how viable each stretch objective is.
<!--
How will you know if you are successful? 
If you include some kind of _quantitative analysis,_ that would be good.
-->

## Architecture Diagram
Upload the architecture diagram you made for your slide presentation to your repository, and include it in-line here.

Create several paragraphs of narrative to explain the pieces and how they interoperate.

## Schedule
Explain how you will go from proposal to finished product. 

There are three deliverable milestones to explicitly define, below.

The nature of deliverables depend on your project, but may include things like processed data ready for import, core algorithms implemented, interface design prototyped, etc. 

You will be expected to turn in code, documentation, and data (as appropriate) at each of these stages.

Write concrete steps for your schedule to move from concept to working system. 

### First Milestone (Sun Apr 9)
Which portion of the work will be completed (and committed to Github) by this day? 

### Second Milestone (Sun Apr 16)
Which portion of the work will be completed (and committed to Github) by this day?  

### Public Presentation (Mon Apr 24, Wed Apr 26, or Fri Apr 28 [your date to be determined later])
What additionally will be completed before the public presentation?

## Group Responsibilities
Here each group member gets a section where they, as an individual, detail what they are responsible for in this project. Each group member writes their own Responsibility section. Include the milestones and final deliverable.

Please use Github properly: each individual must make the edits to this file representing their own section of work.

**Additional instructions for teams of three:** 
* Remember that you must have prior written permission to work in groups of three (specifically, an approved `FP3` team declaration submission).
* The team must nominate a lead. This person is primarily responsible for code integration. This work may be shared, but the team lead has default responsibility.
* The team lead has full partner implementation responsibilities also.
* Identify who is team lead.

In the headings below, replace the silly names and GitHub handles with your actual ones.

### Susan Scheme @susanscheme
will write the....

### Leonard Lambda @lennylambda
will work on...

### Frank Funktions @frankiefunk 
Frank is team lead. Additionally, Frank will work on...   
