# 50.054 Static Semantics


## Learning Outcomes

1. Explain what static semantics is.
1. Apply type checking rules to verify the type correctness property of a program.
1. Explain the relation between type system and operational semantics.


## What is static semantics?

While dynamic semantics defines the run-time behavior of the given program, static semantics defines the compile-time properties of the given program.

For example, a *statically correct* program, must satisfy some properties

1. all uses of variables in it must be defined somewhere earlier. 
1. all the use of variables, the types must be matching with the expected type in the context.
1. ... 


Here is a statically correct SIMP program,

```java
x = 0;
y = input;
if y > x {
    y = 0;
}
return y;
```

because it satifies the first two properties. 

The following program is not statically correct.

```java
x = 0;
y = input;
if y + x { // type error
    x = z; // the use of an undefined variable z
}
return x;
```

Static checking is to rule out the statically incorrect programs.

## Type Checking for Lambda Calculus

To illustrate the proocess of type checking, we consider adding types to the lambda calculus language. 

Recall the lambda calculus syntax, with the following adaptation
$$
\begin{array}{rccl}
 {\tt (Lambda\ Terms)} & t & ::= & x \mid \lambda x:T.t \mid t\ t \mid let\ x:T =\ t\ in\ t \mid  if\ t\ then\ t\ else\ t \mid t\ op\ t \mid c \mid fix\ t \\
 {\tt (Builtin\ Operators)} & op & ::= & + \mid - \mid * \mid / \mid\ == \\
 {\tt (Builtin\ Constants)} & c & ::= & 0 \mid 1 \mid ... \mid true \mid false \\
 {\tt (Types)} & T & ::= & int \mid bool \mid T \rightarrow T \\ 
 {\tt (Type\ Environments)} & \Gamma & \subseteq & (x \times T)
\end{array}
$$

The difference is that the lambda abstraction $\lambda x:T.t$ now carries a *type annotation* of the lambda-bound variable. (Similar observation applies to let-binding) $T$ is a type symbol which can be $int$ or $bool$ or a function type $T \rightarrow T$. The $\rightarrow$ type operator is right associative, i.e. $T_1 \rightarrow T_2 \rightarrow T_3$ is parsed as $T_1 \rightarrow (T_2 \rightarrow T_3)$. Let's call this extended version of lambda calculus as *Simply Typed Lambda Calculus*.

Note that all the existing definitions for dynamic semantics of lambda calculus can be brought-forward (and extended) to support Simply Typed Lambda Calculus. We omit the details.

We formalize the type-checking process in a **relation** $\Gamma \vdash t : T$, where $\Gamma$ is a mapping from variables to types.
We write $dom(\Gamma)$ to denote the domain of $\Gamma$, i.e. $\{ X \mid (x,T) \in \Gamma \}$. We assume for all $x \in dom(\Gamma)$, there exists only one entry of $(x,T) \in \Gamma$.

Since $\Gamma \vdash t : T$ is relation, what type-checking attempts to verify is the following. *Given a type environment $\Gamma$ and lambda term $t$ and a type $T$, $t$ can be given a type $T$ under $\Gamma$*.

$$
\begin{array}{cc}
{\tt (lctInt)} & \begin{array}{c} \\
                      c\ {\tt is\ an\ integer}
                      \\ \hline
                      \Gamma \vdash c : int
                      \end{array} \\ 
{\tt (lctBool)} & \begin{array}{c} \\
                      c\in \{ true, false\}
                      \\ \hline
                      \Gamma \vdash c : bool
                      \end{array}
\end{array}
$$
The rule ${\tt (lctInt)}$ checks whether the given constant value is an integer.
The rule ${\tt (lctBool)}$ checks whether the given constant value is a boolean.

$$
\begin{array}{cc}
{\tt (lctVar)} & \begin{array}{c} 
               (x, T) \in \Gamma  \\
               \hline
               \Gamma \vdash x : T 
               \end{array} 
\end{array}
$$
In rule ${\tt (lctVar)}$, we type check a variable $x$ against a type $T$, which is only valid where $(x,T)$ can be found in the type environment $\Gamma$.

$$
\begin{array}{cc}
{\tt (lctLam)} & \begin{array}{c}
               \Gamma \oplus (x, T) \vdash t : T'  \\
               \hline
               \Gamma \vdash \lambda x : T.t :T' 
               \end{array} 
\end{array}
$$
In rule ${\tt (lctLam)}$, we type check a lambda abstraction against a type $T'$. This is only valid if the body of the lambda expression $t$ has type $T'$ under the extended type environment $\Gamma \oplus (x, T)$.
$$
\begin{array}{cc}
{\tt (lctApp)} & \begin{array}{c}
               \Gamma \vdash t_1 : T_1 \rightarrow T_2 \ \ \ \
               \Gamma \vdash t_2 : T_1 \\
               \hline
               \Gamma \vdash  t_1\ t_2 :T_2 
               \end{array} 
\end{array}
$$
In rule ${\tt (lctApp)}$, we type check a function application, applying $t_1$ to $t_2$, against a type $T_2$. This is only valid if $t_1$ is having type $T_1 \rightarrow T_2$ and $t_2$ is having type $T_1$.

$$
\begin{array}{cc}
{\tt (lctLet)} & \begin{array}{c}
               \Gamma \vdash t_1 : T_1 \ \ \ \
               \Gamma \oplus (x, T_1) \vdash t_2 : T_2 \\
               \hline
               \Gamma \vdash  let\ x:T_1 = t_1\ in\ t_2 :T_2 
               \end{array} 
\end{array}
$$
In rule ${\tt (lctLet)}$, we type check a let binding, $let\ x:T_1 = t_1\ in\ t_2$ against type $T_2$. This is only valid if $t_1$ has type $T_1$ and $t_2$ has type $T_2$ under the extended environment  $\Gamma \oplus (x, T_1)$.

$$
\begin{array}{cc}
{\tt (lctIf)} & \begin{array}{c}
               \Gamma \vdash t_1 : bool \ \ \ \Gamma \vdash t_2 : T \ \ \ \ \Gamma \vdash t_3 : T \\
               \hline
               \Gamma \vdash  if\ t_1\ then\ t_2\ else\ t_3 : T 
               \end{array}
\end{array}
$$
In rule ${\tt (lctIf)}$, we type check a if-then-else expression against type $T$. This is only valid if 
$t_1$ has type $bool$ and both $t_1$ and $t_2$ have type $T$.

$$
\begin{array}{cc}
{\tt (lctOp1)} & \begin{array}{c}
               \Gamma \vdash t_1 : int \ \ \ \Gamma \vdash t_2 : int \ \ \ op\in\{+,-,*,/\} \\
               \hline
               \Gamma \vdash  t_1\ op\ t_2 : int 
               \end{array} \\ \\ 
{\tt (lctOp2)} & \begin{array}{c}
               \Gamma \vdash t_1 : int \ \ \ \Gamma \vdash t_2 : int \\
               \hline
               \Gamma \vdash  t_1\ ==\ t_2 : bool 
               \end{array} \\ \\ 
{\tt (lctOp3)} & \begin{array}{c}
               \Gamma \vdash t_1 : bool \ \ \ \Gamma \vdash t_2 : bool \\
               \hline
               \Gamma \vdash  t_1\ ==\ t_2 : bool 
               \end{array} \\ \\ 
\end{array}
$$

The above three rules type check the binary operations. ${\tt (lctOp1)}$ handles the case where the $op$ is an arithmatic operation, which requires both operands having type $int$. ${\tt (lctOp2)}$ and ${\tt (lctOp3)}$ handle the case where $op$ is the equality test. In this case, the types of the operands must agree.


$$
\begin{array}{cc}
{\tt (lctFix)} & \begin{array}{c}
                \Gamma \vdash t : (T_1 \rightarrow T_2) \rightarrow T_1 \rightarrow T_2
                \\  \hline
                \Gamma \vdash fix\ t:T_1 \rightarrow T_2
               \end{array} 
\end{array}
$$

The last rule ${\tt (lctFix)}$ type checks the fix operator application against the type $T_1 \rightarrow T_2$. We enforce that the argument $t$ must be a fixed point function of type $(T_1 \rightarrow T_2) \rightarrow T_1 \rightarrow T_2$.


For example, we would like to type check the following simply typed lambda term.

$$
fix\ (\lambda f:int\rightarrow int.(\lambda x:int. (if\ x == 0\ then\ 1\ else\ (f\ (x-1))* x)))
$$
against the type $int \rightarrow int$

We added the optional parantheses for readability. 


We find the the following type checking derivation (proof tree).

Let `Γ` be the initial type environment.

```haskell
Γ⊕(f:int->int)⊕(x:int)|- x:int (lctVar)
Γ⊕(f:int->int)⊕(x:int)|- 0:int (lctInt)
---------------------------------------(lctOp2)  [sub tree 1]   [sub tree 2]
Γ⊕(f:int->int)⊕(x:int)|- x == 0: bool
------------------------------------------------------------------------------- (lctIf)
Γ⊕(f:int->int)⊕(x:int)|-if x == 0 then 1 else (f (x-1))*x:int
--------------------------------------------------------------------(lctLam)
Γ⊕(f:int->int)|-λx:int.(if x == 0 then 1 else (f (x-1))*x):int->int
--------------------------------------------------------------------------------(lctLam)
Γ |- λf:int->int.(λx:int.(if x == 0 then 1 else (f (x-1))*x)):(int->int)->int->int
---------------------------------------------------------------------------------(lctFix)
Γ |- fix (λf:int->int.(λx:int.(if x == 0 then 1 else (f (x-1))*x))):int->int
```

Let `Γ1=Γ⊕(f:int->int)⊕(x:int)`
Where [sub tree 1] is 

```haskell 
Γ1|- 1:int (lctInt)
```

and [sub tree 2] is 
```haskell
                           Γ1|-x:int (lctVar) 
                           Γ1|-1:int (lctInt)
                           -----------------(lctOp1)
Γ1|- f:int->int (lctVar)   Γ1|- x-1:int 
-------------------------------------------------(lctApp)  
Γ1|- f (x-1):int                                           Γ1 |- x:int (lctVar)
-------------------------------------------------------------------------(lctOp1)
Γ1|- (f (x-1))*x:int
```


Another (counter) example which shows that we can't type check the following program 

$$
let\ x:int = 1\ in\ (if\ x\ then\ x\ else\ 0)
$$

against the type $int$.

```haskell 
                   fail, no proof exists
                   ---------------------- 
                   Γ⊕(x:int)|- x:bool
                   ----------------------------------(lctIf)
Γ|-1:int (lctInt)  Γ⊕(x:int)|-if x then x else 0:int
--------------------------------------------------------(lctLet)
Γ|- let x:int = 1 in (if x then x else 0):int
```


### Property 1 - Uniqueness
The following property states that if a lambda term is typable, its type must be unique.

Let $t$ be a simply typed lambda calculus term. Let $\Gamma$ be a type environment such that for all $x \in fv(t)$, $x \in dom(\Gamma)$.
Let $T$ and $T'$ be types such that $\Gamma \vdash t : T$ and $\Gamma \vdash t:T'$.
Then $T$ and $T'$ must be the same.

Where $dom(\Gamma)$ refers to the domain of $\Gamma$, i.e. all the variables being mapped.

### Property 2 - Progress
The second property states that if a closed lambda term is typeable under the empty type environment, it must be runnable and not getting stuck.

Let $t$ be a simply typed lambda calculus term such that $fv(t) = \{\}$. 
Let $T$ be a type such that $\{\} \vdash t : T$.
Then $t$ is either a value or there exists some $t'$ such that $t \longrightarrow t'$.

### Property 3 - Preservation
The third property states that the type of a lambda term does not change over evaluation.

Let $t$ and $t'$ be simply typed lambda calculus terms such that $t \longrightarrow t'$. Let $T$ be a type and $\Gamma$ be a type environment such that $\Gamma \vdash t:T$.
Then $\Gamma \vdash t':T$.


## Type Checking for SIMP 

We consider the type checking for SIMP programs.

Recall the syntax rules for SIMP

$$
\begin{array}{rccl}
(\tt Statement) & S & ::= & X = E ; \mid return\ X ; \mid nop; \mid if\ E\ \{ \overline{S} \}\ else\ \{ \overline{S} \} \mid while\ E\ \{ \overline{S} \} \\
(\tt Expression) & E & ::= & E\ OP\ E \mid X \mid C  \\
(\tt Statements) & \overline{S} & ::= & S \mid S\ \overline{S} \\
(\tt Operator) & OP & ::= & + \mid - \mid * \mid / \mid < \mid > \mid == \\ 
(\tt Constant) & C & ::= & 0 \mid 1 \mid 2 \mid ... \mid true \mid false \\ 
(\tt Variable) & X & ::= & a \mid b \mid c \mid d \mid ... \\ 
 {\tt (Types)} & T & ::= & int \mid bool  \\ 
 {\tt (Type\ Environments)} & \Gamma & \subseteq & (x \times T)
\end{array}
$$

We reuse the same symbol $\Gamma$ to denote a type environments mapping SIMP variables to constant values. $T$ to denote a type. 
We define two different relations, 

1. $\Gamma \vdash E : T$, which type-checks a SIMP expresion $E$ against a type $T$ under $\Gamma$.
1. $\Gamma \vdash \overline{S}$, which type-checks a SIMP statement sequence $\overline{S}$ under $\Gamma$.

### Type checking rules for SIMP Expressions

$$
\begin{array}{rc}
{\tt (tVar)} & \begin{array}{c}
                (X,T) \in \Gamma
                \\ \hline
                \Gamma \vdash X : T
                \end{array} \\ \\ 
{\tt (tInt)} & \begin{array}{c}
                c\ {\tt is\ an\ integer}
                \\ \hline
                \Gamma \vdash c : int
                \end{array} \\ \\ 
{\tt (tBool)} & \begin{array}{c}
                c \in \{true,false\}
                \\ \hline
                \Gamma \vdash c : bool
                \end{array} \\ \\ 
{\tt (tOp1)} & \begin{array}{c}
                \Gamma \vdash E_1:int \ \ \ \Gamma \vdash E_2:int\ \ \ OP \in \{ +, -, *, / \}
                \\ \hline
                \Gamma \vdash E_1\ OP\ E_2 : int
                \end{array} \\ \\ 
{\tt (tOp2)} & \begin{array}{c}
                \Gamma \vdash E_1:int \ \ \ \Gamma \vdash E_2:int\ \ \ OP \in \{ ==, <, >\}
                \\ \hline
                \Gamma \vdash E_1\ OP E_2 : bool
                \end{array} \\ \\
{\tt (tOp3)} & \begin{array}{c}
                \Gamma \vdash E_1:bool \ \ \ \Gamma \vdash E_2:bool
                \\ \hline
                \Gamma \vdash E_1\ ==\ E_2 : bool
                \end{array}  
\end{array}
$$

The set of rules for type checking SIMP expressions are similar to those found in lambda calclus. We skip the explanation.

### Type Checking rules for SIMP Statements

The typing rules for statement is in form of $\Gamma \vdash \overline{S}$ instead of  $\Gamma \vdash \overline{S} : T$, this is because
 statements do not return a value (except for return statement, which returns a value for the entire program.)


$$
\begin{array}{rc}
{\tt (tSeq)} & \begin{array}{c}
                \Gamma \vdash S \ \ \  \Gamma \vdash \overline{S}
                \\ \hline
                \Gamma \vdash S \overline{S}
               \end{array}
\end{array}
$$

The ${\tt (tSeq)}$ rule type checks a non empty sequence of statement $S \overline{S}$ under the type environment $\Gamma$.  It is typeable (a proof exists) iff if $S$ is typeable under $\Gamma$ and $\overline{S}$ is typeable under $\Gamma$.



$$
\begin{array}{rc}
{\tt (tAssign)} & \begin{array}{c}
                \Gamma \vdash E : T \ \ \  \Gamma \vdash X : T
                \\ \hline
                \Gamma \vdash X = E 
               \end{array}
\end{array}
$$

The ${\tt (tAssign)}$ rule type checks an assignment statement $X = E$ under $\Gamma$. It is typeable if both $X$ and $E$ are typeable under $\Gamma$ respectively and their types agree.

$$
\begin{array}{rc} 
{\tt (tReturn)} & \begin{array}{c}
                \Gamma \vdash X : T
                \\ \hline
                \Gamma \vdash return\ X 
               \end{array} \\ \\ 
{\tt (tNop)} & \Gamma \vdash nop 
\end{array}
$$

The ${\tt (tReturn)}$ rule type checks the return statement. It is typeable, if the variable $X$ is typeable.
The ${\tt (tNop)}$ rule type checks the nop statement, which is always typeable.

$$
\begin{array}{rc} 
{\tt (tIf)} & \begin{array}{c}
                \Gamma \vdash E:bool \ \ \ \Gamma \vdash \overline{S_1} \ \ \ \Gamma \vdash \overline{S_2}
                \\ \hline
                \Gamma \vdash if\ E\ \{\overline{S_1}\}\ else\ \{ \overline{S_2} \} 
               \end{array} \\ \\ 
{\tt (tWhile)} & \begin{array}{c}
                \Gamma \vdash E:bool \ \ \ \Gamma \vdash \overline{S}
                \\ \hline
                \Gamma \vdash while\ E\ \{\overline{S}\} 
               \end{array} 
\end{array}
$$
The ${\tt (tIf)}$ rule type checks the if-else statement, $if\ E\ \{\overline{S_1}\}\ else\ \{ \overline{S_2} \}$. 
It is typeable if $E$ has type $bool$ under $\Gamma$ and both then- and else- branches are typeable under the $\Gamma$.
The ${\tt (tWhile)}$ rule type checks the while statement in a similar way.


We say that a SIMP program $\overline{S}$ is typeable under $\Gamma$, i.e. it type checks with $\Gamma$ iff $\Gamma \vdash \overline{S}$.
On the other hand, we say that a SIMP program $\overline{S}$ is not typeable, i.e. it does not type check, iff there exists no $\Gamma$ such that $\Gamma \vdash \overline{S}$. 


Let $\Gamma = \{ (input, int), (x,int), (s,int) \}$, we consider the type checking derivation of 

$$x = input; s = 0; while\ s<x\ \{ s = s + 1;\}\ return\ s;$$


```java
                              Γ |- s:int (tVar)
                              Γ |- 0:int (tInt) 
Γ |- input:int (tVar)         -----------------(tAssign)   [sub tree 1]
Γ |- x:int (tVar)             Γ |- s=0  
------------------(tAssign)   --------------------------------------(tSeq)
Γ |- x=input;                 Γ |- s=0; while s<x { s = s + 1;} return s; 
---------------------------------------------------------------------(tSeq)
Γ |- x=input; s=0; while s<x { s = s + 1;} return s;
```

Where [sub tree 1] is


```java
                                          Γ |- 0:int (tInt)
                                          Γ |- s:int (tVar)
Γ |- s:int (tVar)                         -----------------(tOp1)
Γ |- x:int (tVar)      Γ |-s:int (tVar)   Γ |- s+1:int 
--------------(tOp2)   -------------------------------(tAssign)
Γ |- s<x:bool          Γ |- s = s + 1                   Γ |- s:int (tVar)
---------------------------------------------(tWhile)  ---------------(tReturn)
Γ |- while s<x { s = s + 1;}                            Γ |- return s
--------------------------------------------------------------------(tSeq)
Γ |- while s<x { s = s + 1;} return s; 
```


Note that the following two programs are not typeable.

```java
// untypeable 1
x = 1;
y = 0;
if x {
    y = 0; 
} else {
    y = 1;
}
return y;
```
The above is untypeable because we use x of type `int` in a context where it is also expected as `bool`.

```java
// untypeable 2
x = input;
if (x > 1) {
    y = true;
} else {
    y = 0;
}
return y;
```

The above is unteable because we can't find a type environment which has both `(y,int)` and `(y,bool)`.

So far these two "counter" examples are bad programs. However we also note that our type system is too *conservative*.

```java
// untypeable 3
x = input;
if (x > 1) {
    if ( x * x * x < x * x) {
        y = true;
    } else {
        y = 1;
    }
} else {
    y = 0;
}
return y;
```

Even though we note that when `x > 1`, we have `x * x * x < x * x == false` hence the statement `y = true` is not executed. Our type system still rejects this program.
We will discuss this issue in details in the upcoming units.

Let's connect the type-checking rules for SIMP with it dynamic semantics.

### Definition 4 - Type and Value Environments Consistency

We say $\Gamma \vdash \Delta$ iff for all $(X,c) \in \Delta$ we have $(X,T) \in \Gamma$ and $\Gamma \vdash c : T$. 

It means the type environments and value environments are consistent.

### Property 5 - Progress
The following property says that a well typed SIMP program must not be stuck until it reachs the return statement.

Let $\overline{S}$ be a SIMP statement sequence. Let $\Gamma$ be a type environment such that $\Gamma \vdash \overline{S}$.
Then $\overline{S}$ is either 
1. a return statement, or 
1. a sequence of statements, and there exist $\Delta$, $\Delta'$ and $\overline{S'}$ such that $\Gamma \vdash \Delta$ and $(\Delta, \overline{S}) \longrightarrow (\Delta', \overline{S'})$.


### Property 6 - Preservation
The following property says that the evaluation of a SIMP program does not change its typeability.

Let $\Delta$, $\Delta'$ be value environments.
Let $\overline{S}$ and $\overline{S'}$ be SIMP statement sequences such that $(\Delta, \overline{S}) \longrightarrow (\Delta', \overline{S'})$. 
Let $\Gamma$ be a type environment such that $\Gamma \vdash \Delta$ and $\Gamma \vdash \overline{S}$.
Then $\Gamma \vdash \Delta'$ and $\Gamma \vdash \overline{S'}$.


