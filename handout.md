# 50.054 Compiler Design and Program Analysis Course Handout

## This page will be updated regularly. Sync up often.

## Course Description

This course aims to introduce a new programming paradigm to the learners, Functional programming and the suite of advanced language features and design patterns for software design and development. By building on top of these techniques, the course curates the process of designing a modern compiler, through syntax analysis, intermediate presentation construction, semantic analysis and code generation. More specifically the course focuses on the application of program analysis in areas of program optimization and software security analysis. 


## Module Learning Outcomes

By the end of this module, students are able to

1. Implement software solutions using functional programming language and applying design patterns
1. Define the essential components in a program compilation pipeline
1. Design a compiler for an imperative programming language
1. Optimise the generated machine codes by applying program analysis techniques
1. Detect bugs and security flaws in software by applying program analysis techniques


## Measurable Outcomes

1. Develop a parser for an imperative programming language with assignment, if-else and loop (AKA the source language) using Functional Programming
1. Implement a type checker for the source language
1. Develop a static analyser to eliminate dead codes
1. Implement the register allocation algorithm in the target code generation module
1. Develop a static analyser to identify potential security flaws in the source language


## Topics
1. Functional Programming : Expression, Function, Conditional
1. Functional Programming : List, Algebraic data type and Pattern Matching
1. Functional Programming : Type class
1. Functional Programming : Generic and Functor
1. Functional Programming : Applicative and Monad
1. Syntax analysis: Lexing
1. Syntax analysis: Parsing (LL, LR, SLR)
1. Syntax analysis: Parser Combinator
1. Intermediate Representation: Pseudo-Assembly
1. Intermediate Representation: SSA
1. Semantic analysis: Dynamic Semantics
1. Semantic analysis: Type checking
1. Semantic analysis: Type Inference
1. Semantic analysis: Sign analysis
1. Semantic analysis: Liveness analysis 
1. Code Gen: Instruction selection
1. Code Gen: Register allocation
1. Memory Management


## Resource 

The main resources are lecture slides, tutorial sessions, and online documentations. There are no official textbooks. But the following are useful for reference and deeper understanding of some topics.

1. Compilers: Principles, Techniques, and Tools by Alfred V. Aho, Monica S. Lam, Ravi Sethi, and Jeffrey D. Ullman
1. Modern Compiler Implementation in ML by Andrew W. Appel
1. Types and Programming Languages by Benjamin C. Pierce
1. Static Program Analysis by Anders Møller and Michael I. Schwartzbach
1. Learn you a Haskell for Great Good! - `https://learnyouahaskell.com/`



## Instructors


* Kenny Lu (kenny_lu@sutd.edu.sg) 
    * Office Hour: Wednesday 3:00-4:30pm (please send email to arrange)


## Communication

If you have course/assignment/project related questions, please post it on the dedicated MS teams channel.

## Assessment

* Mid-term 10%
* Project 35%
* Homework 20%
* Final 30%
* Class Participation 5%

## Things you need to prepare

* If you are using Windows 10 or Windows 11, please install ubuntu subsystems
    * [Win10](https://ubuntu.com/tutorials/install-ubuntu-on-wsl2-on-windows-10#1-overview)
    * [Win11](https://ubuntu.com/tutorials/install-ubuntu-on-wsl2-on-windows-11-with-gui-support#1-overview)
* If you are using Linux, it should be perfect.
* If you are using Mac, please install homebrew.
* Install Haskell tools
    1. Install ghcup >= 0.1.30.0 `https://www.haskell.org/ghcup/`
    1. Install ghc >= 9.6.6 (via the `ghcup tui` command)
    1. Install cabal >= 3.10.3.0 (via the `ghcup tui` command)
    1. (Optional) install hls >= 2.7.0.0 (via the `ghcup tui` command)
    1. Install stack >= 2.15.5 (via the `ghcup tui` command)
* IDE: It's your choice, but VSCode works fine.
* You should try test your setup by attempting Homework 1 on your own. 


## Project

The aim of the project is to apply the techniques and concepts taught in this module to develop a simple compiler for the SIMP language. 

You may work as a team (up to max 3 members). Please register your team [here](https://docs.google.com/spreadsheets/d/1oH51zYVGD6ieXwr2Nc8UZxK9q4qMxBMRp-pQxgJCXL8/edit?usp=sharing).  

* Lab 1 (10%, Deadline - 17 Nov 2024 23:59)
* Lab 2 (10%, Deadline - 1  Dec 2024 23:59)
* Lab 3 (15%, Deadline - 15 Dec 2024 23:59)


## Submission Policy and Plagiarism
1. You will do the assignment/project on your own (own teams) and will not copy paste solutions from someone else.
1. You will not post any solutions related to this course to a private/public repository that is accessible by the public/others.
1. Students are allowed to have a private repository for their assignment which no one can access. 
1. For projects, students can only invite their partners as collaborators to a private repository.
1. Failing to follow the Code of Honour will result in failing the course and/or being submitted to the University Disciplinary Committee. The consequences apply to both the person who shares their work and the person who copies the work.

## Schedule
| Week | Session 1 | Session 2 | Session 3 | Assessment |
|---|---|---|---|---|
| 1 | Intro | [FP: Expression, Function, Conditional, Recursion](./fp_intro.md) | [Cohort Problem 1](https://github.com/50054-cdpa/cohort_probs/tree/main/fp_intro), <br/> [Homework 1](https://github.com/50054-cdpa/homework/tree/main/fp_intro) | Homework 1 no submission required. Please refer to the markdown file for instructions. | 
| 2 | [FP: List, Pattern Matching](./fp_haskell.md) | [FP: Algebraic Data Type](./fp_haskell.md) | [Cohort Problem 2](https://github.com/50054-cdpa/cohort_probs/tree/main/fp_haskell), <br/> [Homework 2]() |  |
| 3 | [FP: Generics, GADT](./fp_haskell_poly.md) | [FP: Type Classes, Functor](./fp_haskell_poly.md) | [Cohort Problem 3](https://github.com/50054-cdpa/cohort_probs/tree/main/fp_haskell_poly), <br/> Homework 2 (Cont'd) | Homework 2 5% |
| 4 | [FP: Applicative](./fp_applicative_monad.md) | [FP: Monad](./fp_applicative_monad.md) |  [Cohort Problem 4](https://github.com/50054-cdpa/cohort_probs/tree/main/fp_applicative_monad), <br/> [Homework 3]() |  |
| 5 | [Syntax Analysis: Lexing, Parsing](./syntax_analysis.md) | [Top-down Parsing](./syntax_analysis.md) | [Cohort Problem 5](https://github.com/50054-cdpa/cohort_probs/tree/main/syntax_analysis), <br/> Homework 3 (Cont'd) | Homework 3 5% |
| 6 | [Parser-Combinator](./syntax_analysis_parser_combinator.md) | [IR: Pseudo-Assembly](./ir_pseudo_assembly.md) | [Cohort Problem 5 Cont'd](https://github.com/50054-cdpa/cohort_probs/tree/main/syntax_analysis), <br/> [Homework 4](), <br/> Project Briefing  | [Bottom-up Parsing](./syntax_analysis_2.md) for self-study. it won't show up in exams. | 
| 7 |  |  |  | Homework 4 5% | 
| 8 | [Semantic Analysis](./semantic_analysis.md) <br/> [Dynamic Semantics](./dynamic_semantics.md) | **Mid-term exam** | [Cohort Problem 7](https://github.com/50054-cdpa/cohort_probs/tree/main/dynamic_semantics) | Mid-term 10%  |
| 9 | [Static Semantics for SIMP](./static_semantics.md) | [Static Semantics for Lambda Calculus](./static_semantics_2.md) | [Cohort Problem 8](https://github.com/50054-cdpa/cohort_probs/tree/main/static_semantics), [Homework 5]()  | Project Lab 1 10% |
| 10 | [Name Analysis, SSA](./name_analysis.md) | [Lattice, Sign Analysis](./sign_analysis_lattice.md) | [Cohort Problem 9: Name Analysis]() | | 
| 11 | [Liveness Analysis](./liveness_analysis.md) | [Code Generation](./code_generation.md) | [Cohort Problem 10: Sign Analysis]() | Project Lab 2 10%,  Homework 5 5%  |  
| 12 |  [Information Flow Analysis](./advanced_static_analysis.md) | Memory Management  | [Cohort Problem 11]()  |  |
| 13 | Guest Lecture | | Revision | Project Lab 3 15% |  |
| 14 | |  |  |Final Exam (19 Dec Thu 3:00PM-5:00PM) 30%|



## Make Up and Alternative Assessment
Make ups for Final exam will be administered when there is an official Leave of Absence from OSA. There will be only one make up. There will be no make-up if students miss the make up test. 






