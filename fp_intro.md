# 50.054 - Introduction to functional programming

## Learning Outcomes

By the end of this lesson, you should be able to:

* Characterize functional programming
* Comprehend, evaluate lambda terms
* Differentiate different evaluation strategies
* Implement simple algorithms using Lambda Calculus

## What is Functional programming?

Functional programming as suggested by its name, is a programming paradigm in which functions are first class values.
In the ideal model of FP, computations are stateless. Variables are bound once and remain unchanged afterwards. Computation is performed
by rewriting the current expression into the (reduced) expression via evaluation rules.

## How FP differs from other programming languages?

The main differences were listed in the earlier section.

However many modern program languages (including those are not FP) adopted many "features" from the functional programming paradigm. It has been proven that the FP coding style improves code qualities in many aspects.

Consider the following two different implementations of the insertion sort algorithm (assuming that the readers having prior knowledge of Python and insertion sort algorithm):

```python
def isort(vals):
   for i in range(1, len(vals)):
      curr = i   
      for j in range(i, 0, -1):
         # scan backward to insert vals[curr] into the right pos
         if vals[curr] > vals[j-1]:
            vals[curr], vals[j-1] = vals[j-1], vals[curr]
            curr = j-1
   return vals
```

```python
def isort2(vals):
   def insert(x, xs):
      # invarant: xs is already sorted in descending order
      if len(xs) > 0:
         if x > xs[0]:
            return [x] + xs
         else:
            return [xs[0]] + insert(x, xs[1:])
      else:
         return [x]
   def isort_sub(sorted, to_be_sorted):
      # invariant sorted is already sorted in descending order
      if len(to_be_sorted) > 0:
         val = to_be_sorted[0]
         to_be_sorted_next = to_be_sorted[1:]
         sorted_next = insert(val, sorted)
         return isort_sub(sorted_next, to_be_sorted_next)
      else:
         return sorted
   return isort_sub([], vals)
```

`isort` is implemented in the imperative style; the way we are familiar with.

`isort2` is implemented in a functional programming style, we've seen it but we are not too familar with it.
We probably won't code in `isort2` in Python, because:

1. it is lengthy
2. it is less efficient, as it involves recursion (function call stack is building up) and there are too many list slicing and concatenation operations.

But why are people are interested in FP? The reason is that the invariant of `isort` is much harder to derive compared to `isort2`
in which the nested functions' parameters are the subject of the invariants, and the variables in `isort2` are mostly immutable, i.e.
they don't change over execution, and we won't need symbolic execution or variable renaming.

Furthermore in some FP languages with advanced typing systems such as type constraints and dependent types, these invariants in `isort2`
can be expressed as type constraints, which can be verified by the compiler.

What about the inefficiency? Most of the FP compilers handle recursions with care and are able to optimize them into efficient code.
Data structure in FP are inductively defined, and optimizations such as shallow cloning are used to avoid data structure reconstruction.

In fact many modern FP languagues are quite fast. For example:

* <https://benchmarksgame-team.pages.debian.net/benchmarksgame/fastest/ghc-clang.html>
* <https://thume.ca/2019/04/29/comparing-compilers-in-rust-haskell-c-and-python/>

## Why FP in Compiler Design?

Implementing a compiler requires rigorous software design and engineering principles. Bugs arising from a compiler have severe implication in softwares developed in the language that it compiles.

To establish correctness results, testing is not sufficient to eliminate errors in the compilers. When designing a compiler, we often begin with formal reasoning with mathematical foundation as the specification. As we learn later in this module, these specifications are presented in a form in which resembles the data structures and accessor methods found in many functional programming languages. Thus, it is arguably easier to implement the given specification in function programs compared to other programming paradigms.

One key difference is that in FP, there is no for-loop or while-loop. Iteration has to be implemented via recursive functions.

This implies that loop invariances are not constraints among the input and output of these recurisve function.

In many main stream functional programming languages, such as Ocaml, Haskell and Scala are shipped with powerful type systems which allow us to express some of the properties of the algorithms in terms of type constraints, by doing so, these (invariant) properties are verifiable by the compilers of function programming languages.

## Lambda Calculus

*Lambda Calculus* is the minimal core of many functional programming languages.
It consists of the *Lambda expression* and the *evaluation rule(s)*.

### Lambda Expression

> [This comic gives a very easy way to understand Lambda Expressions](https://imgur.com/gallery/XBHub)

The valid syntax of lambda expression is described as the following EBNF ([Extended Backus Naur Form](https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form)) grammar:

$$
\begin{array}{rccl}
 {\tt (Lambda\ Terms)} & t & ::= & x \mid \lambda x.t \mid t\ t
\end{array}
$$

Where:

* Each line denotes a grammar rule
* The left hand side (LHS) of the `::=` is a non-terminal symbol, in this case $t$ is a non-terminal symbol.
* The RHS of the `::=` is a set of alternatives, separated by `|`. Each alternative denote a possible outcome of expanding the LHS non-terminal. In this case $t$ has three possibilities, i.e. $x$, $\lambda x.t$ or $t\ t$.
* $x$ denotes a variable,
* $\lambda x.t$ denotes a lambda abstraction.
  * Within a lambda abstraction,  $x$ is the bound variable (c.f. formal argument of the function)
and $t$ is the body.
* $t\ t$ denotes a function application.

For example, the following are three instances of $t$.

1. $x$
1. $\lambda x.x$
1. $(\lambda x.x)\ y$

Note that given a lambda term, there might be multiple ways of parsing (interpreting) it. For instance,
Given $\lambda x.x\ \lambda y.y$, we could interpret it as either

1. $(\lambda x.x)\ (\lambda y.y)$, or
2. $\lambda x.(x\ \lambda y.y)$

As a convention, in the absence of parentheses, we take 2 as the default interpretation. We should include parentheses whenever ambiguity arise as much as we can.

### Evaluation Rules

Lambda calculus is very simple and elegant. To execute (or we often say "to evaluate") a given lambda term, we apply the evaluation rules to rewrite the term.

There are only two rules to consider.

Each rule is defined via a reduction relation $t \longrightarrow t'$, which reads as $t$ is reduced to $t'$ by a step.

#### Beta Reduction

$$
\begin{array}{rl}
{\tt (\beta\ reduction)} & (\lambda x.t_1)\ t_2 \longrightarrow [t_2/x] t_1
\end{array}
$$

What's new here is the term $[t_2/x]$, which is a meta term, which
refers to a substitution. $[t_2/x]t_1$ denotes the application of the
substitution $[t_2/x]$ to $t_1$, Informally speaking it means we
replace every occurrence of the formal argument $x$ in $t_1$ with $t_2$.

For instance, recall our earlier example:

$$
\begin{array}{rl}
(\lambda x.x)\ (\lambda y.y) &
\longrightarrow_{\scriptsize {\tt (\beta\ reduction)}} \\
\lbrack(\lambda y.y)/x \rbrack x & \longrightarrow _{\scriptsize {\tt (substitution)}} \\
\lambda y.y
\end{array}
$$

It is common understanding in programming that there are scopes of
variables. We can reuse the same name for different variables in
different scopes without affecting the meanings of the program.
Consider a variant of our running example:

$$
 (\lambda x.x)\ {\tt (\lambda x. x)}
$$

Here, we use a different font type for variables named $x$ in different scopes.
$x$ is bound in the first lambda abstraction and  
${\tt x}$ is bound in the second lambda abstraction. It behaves the
same as the original running example except for the name of the
variable in the second lambda abstraction.

To formally define the substitution operation used in the
$\beta$ reduction rule, we need to compute the free variables,
i.e. variables that are not bound.

$$
\begin{array}{rcl}
fv(x) & = & \{x\}\\
fv(\lambda x.t) & = & fv(t) - \{x\} \\
fv(t_1\ t_2) & = & fv(t_1) \cup fv(t_2)
\end{array}
$$

For instance.

$$
\begin{array}{rcl}
fv(\lambda x.x) & = & fv(x) - \{x\} \\
                & = & \{ \}
\end{array}
$$

$$
\begin{array}{rcl}
fv(\lambda x.x\ (\lambda z.y\ z)) & = & fv(x\ (\lambda z.y\ z)) - \{x\}
\\
   & = & (\{x\} \cup fv(\lambda z.y\ z)) - \{x\} \\
   & = & (\{x\} \cup (fv(y\ z) - \{z\})) - \{x\} \\
   & = & (\{x\} \cup ((\{y\} \cup \{z\}) - \{z\})) - \{x\} \\
   & = & (\{x\} \cup (\{y, z\} - \{z\})) - \{x\} \\
   & = & \{ y \}
\end{array}
$$

One common error we often encounter is *capturing the free variables*.

Consider:

$$
(\lambda x. \lambda y.x\ y)\ ({\tt y}\ w)
$$

Note:

$$
fv((\lambda x. \lambda y.x\ y)\ ({\tt y}\ w)) =  \{ {\tt y}, w \}
$$

Thus:

$$
\begin{array}{rl}
(\lambda x. \lambda y.x\ y)\ ({\tt y}\ w) & \longrightarrow \\
\lbrack({\tt y}\ w)/x\rbrack \lambda y.x\ y & \longrightarrow  \\
\lambda y. ({\tt y}\ w)\ y
\end{array}
$$

Error! We captured the free variable ${\tt y}$ in the lambda
abstraction accidentally via substitution.
Now the free variable ${\tt y}$ is "mixed up" with the lambda bound variable $y$ by mistake.

#### Substitution and Alpha Renaming

In the following we consider all the possible cases for subsititution

$$
\begin{array}{rcll}
 \lbrack t_1 / x \rbrack x & = & t_1 \\
 \lbrack t_1 / x \rbrack y & = & y & {\tt if}\  x \neq y \\
 \lbrack t_1 / x \rbrack (t_2\ t_3) & = & \lbrack t_1 / x \rbrack t_2\
 \lbrack t_1 / x \rbrack t_3 & \\
 \lbrack t_1 / x \rbrack \lambda y.t_2 & = & \lambda y. \lbrack t_1 / x
 \rbrack t_2 & {\tt if}\  y\neq x\  {\tt and}\  y \not \in fv(t_1)
\end{array}
$$

In case  

$$
y\neq x\  {\tt and} \ y \not \in fv(t_1)
$$

is not satified, we need to rename the lambda bound variables that are clashing. Recall:

$$
(\lambda x. \lambda y.x\ y)\ ({\tt y}\ w)
$$

We rename the inner lambda bound variable $y$ to $z$:

$$
(\lambda x. \lambda z.x\ z)\ ({\tt y}\ w)
$$

to avoid clashing, prior applying the $\beta$ reduction.
The renaming operation is also known as the $\alpha$ renaming.

### Evaluation strategies

So far we have three rules (roughly)  $\beta $ reduction, substitution, and  $\alpha $ renaming.

Given a lambda term, in order to evaluate it, we need to identify places that we can apply these rules.

We call a (sub-)expression of shape $(\lambda x.t_1)\ t_2$ a *redex*.

The task is to look for redexes in a lambda term and rewrite them by applying  $\beta$ reduction and substitution, and sometimes  $\alpha$ renaming to avoid capturing free variables.

But in what order shall we apply these rules?

There are two mostly known strategies

1. Inner-most, leftmost - Applicative Order Reduction (AOR)
2. Outer-most, leftmost - Normal Order Reduction (NOR)

Consider $(\lambda x. ((\lambda x. x)\ x))\ (\lambda y.y)$,

* AOR:

$$
\begin{array}{rll}
(\lambda x. (\underline{(\lambda x. x)\ x}))\ (\lambda y.y)  &
\longrightarrow_{\tt (\beta\ reduction)} &\\
\underline{(\lambda x.x)\ (\lambda y.y)}  & \longrightarrow_{\tt (\beta\ reduction)} \\
\lambda y.y
\end{array}
$$

* NOR:

$$
\begin{array}{rl}
\underline{(\lambda x. ((\lambda x. x)\ x))}\ (\lambda y.y)  &
\longrightarrow_{\tt(\alpha)} \\
\underline{(\lambda z. [z/x]((\lambda x.x)\ x))}\ (\lambda y.y) & \longrightarrow_{\tt (substitution)} \\
\underline{(\lambda z. ((\lambda x. x)\ z))\ (\lambda y.y)}  &
\longrightarrow_{\tt(\beta)} \\  
\underline{(\lambda x. x)\ (\lambda y.y)} &
\longrightarrow_{\tt (\beta)}  \\
\lambda y.y
\end{array}
$$

#### Interesting Notes

1. Some connection with real world languages:
   * Call By Value semantics (CBV, found in C, C++, etc.) is like AOR except that we do not evaluate under lambda abstractions.
   * Call By Name semantics (CBN, found in Haskell, etc.) is like NOR except that we do not evaluate under lambda abstractions.

2. AOR or NOR, which one is better?
   * By Church-Rosser Theorem, if a lambda term can be evaluated in
  two different ways and both ways terminate, both will yield the same
  result.
   * Recall our earlier example.
   * So how can it be non-terminating? Consider:

    $$
    \begin{array}{rl}
    (\lambda x.x\ x)\ (\lambda x.x\ x) & \longrightarrow
    \\
    \lbrack(\lambda x.x\ x)/x\rbrack (x\ x) & \longrightarrow
    \\
    (\lambda x.x\ x)\ (\lambda x.x\ x)  & \longrightarrow
    \\
    ...
    \end{array}
    $$

3. NOR seems computationally more expensive, but is also more likely to terminate than AOR. Consider how
    $((\lambda x.\lambda y.x)\ x)\  ((\lambda x.x\ x)\ (\lambda x.x\ x))$ terminates in NOR with $x$, but diverges in AOR.
4. NOR can be used to evaluate terms that deals with infinite data.

### Let Binding

Let-binding allows us to introduce local (immutable) variables.

#### Approach 1 - extending the syntax and evaluation rules

We extend the syntax with let-binding:

$$
\begin{array}{rccl}
 {\tt (Lambda\ Terms)} & t & ::= & x \mid \lambda x.t \mid t\ t \mid let\ x=\ t\ in\ t
\end{array}
$$

and the evaluation rule:

$$
\begin{array}{rl}
{\tt (Let)} & let\ x=t_1\ in\ t_2 \longrightarrow [t_1/x]t_2 \\ \\
\end{array}
$$

and the substitution rule and the free variable function $fv()$:

$$
\begin{array}{rcl}
\lbrack t_1 / x \rbrack let\ y = t_2\ in\ t_3 & = & let\ y = \lbrack t_1 / x \rbrack t_2\ in\ \lbrack t_1 / x \rbrack t_3 & {\tt if}\  y\neq x\  {\tt and}\  y \not \in fv(t_1) \\
\end{array} 
$$
$$
\begin{array}{rcl}
fv(let\ x=t_1\ in\ t_2) & = & (fv(t_1) - \{x\}) \cup fv(t_2) \\
\end{array}
$$

Note that the alpha renaming should be applied when name clash arises.



#### Approach 2 - desugaring

In the alternative approach, we could use a pre-processing step to desugar the let-binding into an application. In compiler context, *desugaring* refers to the process of rewriting the source code from some high-level form to the core language.

We can rewrite:

$$
let\ x=t_1\ in\ t_2
$$

into:

$$
(\lambda x.t_2)\ t_1
$$

where $x \not\in fv(t_1)$.

> What happen if $x \in fv(t_1)$? It forms a recursive definition. We will look into recursion in a later section.

### Conditional Expression

A language is pretty much useless without conditional $if\ t_1\ then\ t_2\ else\ t_3$. There are at least
two different ways of incorporating conditional expression in our lambda term language.

#### Approach 1 - Extending the syntax and the evaluation rules

We could extend the grammar

$$
\begin{array}{rccl}
 {\tt (Lambda\ Terms)} & t & ::= & x \mid \lambda x.t \mid t\ t \mid let\ x=\ t\ in\ t \mid  if\ t\ then\ t\ else\ t \mid t\ op\ t \mid c \\
 {\tt (Builtin\ Operators)} & op & ::= & + \mid - \mid * \mid / \mid\ == \\
 {\tt (Builtin\ Constants)} & c & ::= & 0 \mid 1 \mid ... \mid true \mid false
\end{array}
$$

and the evaluation rules

$$
\begin{array}{rc}
{\tt (\beta\ reduction)} & (\lambda x.t_1)\ t_2 \longrightarrow [t_2/x] t_1 \\ \\
{\tt (ifI)} & \begin{array}{c}
               t_1 \longrightarrow t_1'  \\
               \hline
               if\ t_1\ then\ t_2\ else\ t_3 \longrightarrow if\ t_1'\ then\ t_2\ else\ t_3
               \end{array} \\ \\
{\tt (ifT)} &  if\ true\ then\ t_2\ else\ t_3 \longrightarrow t_2 \\ \\
{\tt (ifF)} &  if\ false\ then\ t_2\ else\ t_3 \longrightarrow t_3 \\ \\
{\tt (OpI1)} & \begin{array}{c}
                t_1 \longrightarrow t_1' \\
                \hline
                t_1\ op\ t_2\  \longrightarrow t_1'\ op\ t_2
                \end{array} \\ \\
{\tt (OpI2)} & \begin{array}{c}
                t_2 \longrightarrow t_2' \\
                \hline
                c_1\ op\ t_2\  \longrightarrow c_1\ op\ t_2'
                \end{array} \\ \\
{\tt (OpC)} &  \begin{array}{c}
                invoke\ low\ level\ call\  op(c_1, c_2) = c_3 \\
                \hline  
                c_1\ op\ c_2\  \longrightarrow c_3
                \end{array} \\ \\
                ...
\end{array}
$$

In the above we use a horizontal line to separate complex deduction rules that have some premise. The relations and statement written above the horizontal line are called the **premises**, and the relation the written below is called the **conclusion**. The conclusion holds if the premises are valid.

* The rule ${\tt (ifI)}$ states that if we can evaluate  $t_1$ to  $t_1'$, then  $if\ t_1\ then\ t_2\ else\ t_3$ can be evaluated to  $if\ t_1' \ then\ t_2\ else\ t_3$. In otherwords, for us to reduce $if\ t_1\ then\ t_2\ else\ t_3$ to $if\ t_1' \ then\ t_2\ else\ t_3$, a pre-condition is to reduce $t_1$ to $t_1'$. 
* The rule  ${\tt (ifT)}$ states that if the conditional expression is $true$, the entire term is evaluated to the then-branch.
* The rule  ${\tt (ifF)}$ is similar. Rules  ${\tt (OpI1)}$ and ${\tt (OpI2)} $ are similar to rule ${\tt (IfI)}$.
* The rule  ${\tt (OpC)}$ invokes the built-in low level call to apply the binary operation to the two operands  $c_1$ and  $c_2$.  

The substitution rules and free variable function $fv()$ also extended too
$$
\begin{array}{rcll}
 \lbrack t_1 / x \rbrack c & = & c \\ 
   \lbrack t_1 / x \rbrack t_2\ op\ t_3 & = & (\lbrack t_1 / x \rbrack t_2)\ op\ (\lbrack t_1 / x \rbrack t_3) \\ 
  \lbrack t_1 / x \rbrack if\ t_2\ then\ t_3\ else\ t_4 & = & if\ \lbrack t_1 / x \rbrack t_2\ then\ \lbrack t_1 / x \rbrack t_3\ else\ \lbrack t_1 / x \rbrack t_4 \\ 
\end{array}
$$
$$
\begin{array}{rcl}
fv(t_1\ op\ t_2) & = & fv(t_1) \cup fv(t_2) \\ 
fv(if\ t_1\ then\ t_2\ else\ t_3) & = & fv(t_1) \cup fv(t_2) \cup fv(t_3) \\
fv(c) & = & \{\} \\
\end{array}
$$
Let's consider an example:

$$
\begin{array}{rl}
(\lambda x.if\ x==0\ then\  0\  else\  10/x)\ 2 & \longrightarrow_{\scriptsize {\tt \beta}} \\
\lbrack 2/x \rbrack if\ x==0\ then\  0\  else\  10/x & \longrightarrow_{\scriptsize {\tt (substitution)}} \\
if\ 2==0\ then\  0\  else\  10/2 & \longrightarrow_{\scriptsize {\tt (IfI)}} \\
if\ false\ then\ 0\  else\  10/2 & \longrightarrow_{\scriptsize {\tt (IfF)}} \\
10/2 & \longrightarrow_{\scriptsize {\tt (OpC)}} \\
5
\end{array}
$$

#### Approach 2 - Church Encoding

Instead of extending the syntax and evaluation rules, we could encode the conditional expression in terms of the basic lambda terms.

Thanks to [Church-encoding](https://en.wikipedia.org/wiki/Church_encoding) (discovered by Alonzo Church), we can encode boolean data and if-then-else using Lambda Calculus.

Let's define:

* $true$ as $\lambda x.\lambda y.x$
* $false$ as $\lambda x.\lambda y.y$
* $ite$ (read as if-then-else) as $\lambda e_1. \lambda e_2. \lambda e_3. e_1\ e_2\ e_3$

We assume the function application is left associative,
i.e. $e_1\ e_2\ e_3 \equiv  (e_1\ e_2)\ e_3$.
For example,

$$
\begin{array}{rl}
ite\ true\ w\ z & = \\
(\lambda e_1. \lambda e_2. \lambda e_3. e_1\ e_2\ e_3)\ true\ w\ z &
\longrightarrow \\
true\ w\ z & =  \\
(\lambda x.\lambda y.x)\ w\ z & \longrightarrow  \\
w
\end{array}
$$

### Recursion

To make our language turing complete, we need to support loops. The way to perform loops in lambda calculus is via recursion.

Similar to the conditional expression, there are at least two ways of introducing recursion to our language.

#### Approach 1 - Extending the syntax and the evaluation rules

We extend the syntax with a mu-abstraction ($\mu$):

$$
\begin{array}{rccl}
 {\tt (Lambda\ Terms)} & t & ::= & ... \mid \mu f.t
\end{array}
$$

and the evaluation rules:

$$
\begin{array}{rl}
{\tt (\beta\ reduction)} & (\lambda x.t_1)\ t_2 \longrightarrow [t_2/x] t_1 \\
{\tt (NOR)} & \begin{array}{c}
                t_1 \longrightarrow t_1' \\
                \hline
                t_1\ t_2 \longrightarrow t_1'\ t_2
                \end{array} \\
{\tt (unfold)} & \mu f.t \longrightarrow [(\mu f.t)/f] t  \\
\end{array}
$$

Note that we include the  ${\tt (NOR)} $ rule into our evaluation rules to fix the evaluation strategy, and we only reduce the redexes that are *not* inside a lambda abstraction, otherwise the program does not terminate.

We include the following cases for the free variable function $fv()$ and the substitution
$$
\begin{array}{rcl}
fv(\mu f.t) & = & fv(t) - \{f\}
\end{array}
$$
and 
$$
\begin{array}{rcl}
 \lbrack t_1 / x \rbrack \mu f.t_2 & = & \mu f.\lbrack t_1 / x \rbrack t_2 & {\tt if}\  f\neq x\  {\tt and}\  f \not \in fv(t_1)
\end{array}
$$

For instance:

$$
\begin{array}{rl}
(\mu f.\lambda x.if\ x==1\ then\ 1\ else\ x*(f\ (x-1)))\ 3 & \longrightarrow_{\scriptsize {\tt(NOR)+(unfold)}} \\
(\lbrack (\mu f.\lambda x.if\ x==1\ then\ 1\ else\ x*(f\ (x-1)))/f \rbrack \lambda x.if\ x==1\ then\ 1\ else\ x*(f\ (x-1)))\ 3 & \longrightarrow_{\scriptsize {\tt (substitution) + (\alpha)}} \\
(\lambda x.if\ x==1\ then\ 1\ else\ x*((\mu f.\lambda y.if\ y==1\ then\ 1\ else\ f\ (y-1))\ (x-1)))\ 3 & \longrightarrow_{\scriptsize {\tt (\beta)}} \\
\lbrack 3/x \rbrack if\ x==1\ then\ 1\ else\ x*((\mu f.\lambda y.if\ y==1\ then\ 1\ else\ f\ (y-1))\ (x-1)) & \longrightarrow_{\scriptsize {\tt (substitution)}} \\
if\ 3==1\ then\ 1\ else\ 3*((\mu f.\lambda y.if\ y==1\ then\ 1\ else\ f\ (y-1))\ (3-1)) & \longrightarrow_{\scriptsize {\tt (ifI)+(OpC)}} \\
if\ false\ then\ 1\ else\ 3*((\mu f.\lambda y.if\ y==1\ then\ 1\ else\ f\ (y-1))\ (3-1)) & \longrightarrow_{\scriptsize {\tt (ifF)}} \\
3*((\mu f.\lambda y.if\ y==1\ then\ 1\ else\ f\ (y-1))\ (3-1)) & \longrightarrow_{\scriptsize {\tt (OpI2)}} \\
... \\
3*(2*1)
\end{array}
$$

Another important point to note is that the set of rewriting rules we have gathered so far ${\tt (\beta-reduction)}$, ${\tt (NOR)}$, ${\tt (unfold)}$, ${\tt (IfT)}$, ${\tt (IfF)}$, ${\tt (IfI)}$, ${\tt (OpC)}$, ${\tt (OpI2)}$ and ${\tt (OpI1)}$ are syntax-directed, i.e. the LHS of the $\longrightarrow$ in the conclusion, which is AKA the head of the rule is unique if we try to rules in this specific order. A clear advantage of this is that we can view this deduction rule system as an algorithm, i.e. an implementation that resembles this specification exists. We will see this in the later part of this course. 

#### Approach 2 - Church Encoding

Alternatively,
recursion can be encoded using the fix-pointer combinator (AKA  $Y $-combinator). Let $Y $ be

$$
\lambda f.((\lambda y. (f\ (y\ y)))~(\lambda x.(f\ (x\ x))))
$$

We find that for any function $g$, we have
$Y\ g = g\ (Y\ g)$.

We will work on the derivation during exercise.

Let's try to implement the factorial function over natural numbers:

$$
\begin{array}{cc}
   fac(n) = \left [
         \begin{array}{ll}
            1 &  {if}~ n = 0 \\
            n*fac(n-1) & {otherwise}
         \end{array} \right .
\end{array}
$$

Our goal is to look for a fixpoint function $Fac$ such that
$Y\ Fac \longrightarrow Fac\ (Y\ Fac)$ and $Y\ Fac$ implements
the above definition.

Let $Fac$ be

$$
\begin{array}{c}
 \lambda fac. \lambda n. ite\ (iszero\ n)\ one\ (mul\ n\ (fac\ (pred\ n)))
\end{array}
$$

where $iszero$ tests whether a number is 0 in Church Encoding. $mul$ multiplies two
numbers. $pred$ takes a number and return its predecessor in natural
number order. Then $Y\ Fac$ will be the implementation of the factorial function
described above.

#### Discussion 1

How to define the following?

* $one$
* $iszero$
* $mul$
* $pred$


#### Discussion 2

The current evaluation strategy presented resembles the call-by-need semantics, in which the function arguments are not evaluated until they are needed. What modification will be required if we want to implement a call-by-value semantics (AKA. strict evaluation)?

> We will work on the two topics discussed above during the cohort class.

## Summary

We have covered

* Syntax (lambda terms) and Semantics ($\beta$ reduction, substitution, $\alpha$ renaming).
* Evaluation strategies, their properties and connection to real world programming
* Extending lambda calculus to support conditional and loop
  * Via language extension (we will use)
  * Via Church encoding (fun but not very pragmatic in our context)
