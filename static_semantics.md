# 50.054 Static Semantics For SIMP


## Learning Outcomes

1. Explain what static semantics is.
1. Apply type checking rules to verify the type correctness property of a SIMP program.
1. Explain the relation between type system and operational semantics.
1. Apply type inference algorithm to generate a type environment given a SIMP program.


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

We use the symbol $\Gamma$ to denote a type environments mapping SIMP variables to types. $T$ to denote a type.
We write $dom(\Gamma)$ to denote the domain of $\Gamma$, i.e. $\{ X \mid (x,T) \in \Gamma \}$. We assume for all $x \in dom(\Gamma)$, there exists only one entry of $(x,T) \in \Gamma$.

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
                \end{array} 
\end{array}
$$
In the rule ${\tt (tVar)}$, we type check the variable $X$ having type $T$ under the type environment $\Gamma$ if we can find the entry $(X,T)$ in $\Gamma$.
$$
\begin{array}{rc}
{\tt (tInt)} & \begin{array}{c}
                c\ {\tt is\ an\ integer}
                \\ \hline
                \Gamma \vdash c : int
                \end{array} \\ \\ 
{\tt (tBool)} & \begin{array}{c}
                c \in \{true,false\}
                \\ \hline
                \Gamma \vdash c : bool
                \end{array} 
\end{array}
$$
In the rule ${\tt (tInt)}$, we type check an integer constant having type $int$. Similarly, we type check a boolean constant having type $bool$. 
$$
\begin{array}{rc}
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
In the rule ${\tt (tOp1)}$, we type check an integer arithmetic operation having type $int$, if both operands can be type-checked against $int$.
In the rule ${\tt (tOp2)}$, we type check an integer comparison operation having type $bool$, if both operands can be type-checked against $int$.
In the rule ${\tt (tOp3)}$, we type check a boolean comparison operation having type $bool$, if both operands can be type-checked against $bool$.
$$
\begin{array}{rc}
{\tt (tParen)} & \begin{array}{c}
                \Gamma \vdash E :T
                \\ \hline
                \Gamma \vdash (E) :T
                \end{array}
\end{array}
$$
Lastly in rule ${\tt (tParen)}$, we type check a parenthesized expression by type-checking the inner expression. 

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

### Definition 1 - Type and Value Environments Consistency

We say $\Gamma \vdash \Delta$ iff for all $(X,c) \in \Delta$ we have $(X,T) \in \Gamma$ and $\Gamma \vdash c : T$. 

It means the type environments and value environments are consistent.

### Property 2 - Progress
The following property says that a well typed SIMP program must not be stuck until it reachs the return statement.

Let $\overline{S}$ be a SIMP statement sequence. Let $\Gamma$ be a type environment such that $\Gamma \vdash \overline{S}$.
Then $\overline{S}$ is either 
1. a return statement, or 
1. a sequence of statements, and there exist $\Delta$, $\Delta'$ and $\overline{S'}$ such that $\Gamma \vdash \Delta$ and $(\Delta, \overline{S}) \longrightarrow (\Delta', \overline{S'})$.


### Property 3 - Preservation
The following property says that the evaluation of a SIMP program does not change its typeability.

Let $\Delta$, $\Delta'$ be value environments.
Let $\overline{S}$ and $\overline{S'}$ be SIMP statement sequences such that $(\Delta, \overline{S}) \longrightarrow (\Delta', \overline{S'})$. 
Let $\Gamma$ be a type environment such that $\Gamma \vdash \Delta$ and $\Gamma \vdash \overline{S}$.
Then $\Gamma \vdash \Delta'$ and $\Gamma \vdash \overline{S'}$.


## What is Type Inference

Type inference is also known as type reconstruction is a static semantics analysis process that aims to reconstruct the missing (or omitted) typing info from the source programs. 

For example, given the Scala program

```scala
def f(x:Int) = x + 1
```

the Scala compiler is able to deduce that the return type of `f` is `Int`. 

Likewise for the following SIMP program

```java
y = y + 1
```
we can also deduce that `y` is a of type `int`.

What we aim to achieve is a sound and systematic process to deduce the omitted type information.

## Type inference for SIMP program

Given a SIMP program $\overline{S}$, the goal of type inference is to find the "best" type environment $\Gamma$ such that $\Gamma \vdash \overline{S}$.

Given that $\Gamma$ is a set of variable to type mappings, the "best" can be defined as the smallest possible set that make $\overline{S}$ typeable. This is also called the most general solution.

### Definition - Most general type (envrionment)

Let $\Gamma$ be type environment and $\overline{S}$ be a sequence of SIMP statements, such that $\Gamma \vdash \overline{S}$. $\Gamma$ is the *most general* type environment iff for all $\Gamma'$ such that $\Gamma' \vdash \overline{S}$ we have $\Gamma \subseteq \Gamma'$.


### Type Inference Rules

We would like to design type inference process using a deduction system. First of all, let's introduce some extra meta syntax terms that serve as intermediate data structures.


$$
\begin{array}{rccl}
{\tt (Extended\ Types)} & \hat{T} & ::=  &\alpha \mid T \\ 
{\tt (Constraints)} & \kappa & \subseteq & (\hat{T} \times \hat{T}) \\ 
{\tt (Type\ Substitution)} & \Psi & ::= & [\hat{T}/\alpha] \mid [] \mid \Psi \circ \Psi 
\end{array}
$$

Where $\alpha$ denotes a type variable. $\kappa$ define a set of pairs of ext types that are supposed to be equal, e.g. $\{ (\alpha, \beta), (\beta, int) \}$ means $\alpha = \beta \wedge \beta = int$.

Type substititution replace type variable to some other type. 

$$
\begin{array}{rcll}
[]\hat{T} & = & \hat{T} \\ 
[\hat{T}/\alpha]\alpha & = & \hat{T} \\  
[\hat{T}/\alpha]\beta & = & \beta & if\ \alpha \neq \beta \\
[\hat{T}/\alpha]T & = & T
\end{array}
$$

Type substiution can be *compositional*.

$$
\begin{array}{rcll}
 (\Psi_1 \circ \Psi_2) \hat{T} & = & \Psi_1(\Psi_2(\hat{T}))
\end{array}
$$

The SIMP type inference rules are defined in terms of a deduction system consists of two type of rule forms. 

### Type Inference Rules for SIMP statements 

The type inference rules for SIMP statements are described in a form of $\overline{S} \vDash \kappa$, which reads give a sequence of statements $\overline{S}$, we generate a set of type constraints $\kappa$. 
$$
\begin{array}{rc}
{\tt (tiNOP)} & nop\vDash \{\} \\ \\ 
{\tt (tiReturn)} & return\ X \vDash \{\}  
\end{array}
$$
The ${\tt (tiNOP)}$ rule handles the $nop$ statement, an empty constraint set is returned.  Similar observation applies to the return statement. 
$$
\begin{array}{rc}
{\tt (tiSeq)} & \begin{array}{c} 
                S \vDash \kappa_1 \ \ \ \ \overline{S} \vDash \kappa_2
                \\ \hline
                S \overline{S} \vDash \kappa_1 \cup \kappa_2 
                \end{array} 
\end{array}
$$
The ${\tt (tiSeq)}$ rule generates the type constraints of a sequence statement $S\overline{S}$. We can do so by first generate the constraints $\kappa_1$ from $S$ and $\kappa_2$ from $\overline{S}$ and union $\kappa_1$ and $\kappa_2$.  
$$
\begin{array}{rc}
{\tt (tiAssign)} &  \begin{array}{c}
                    E \vDash \hat{T}, \kappa 
                    \\ \hline
                    X = E \vDash \{ (\alpha_X, \hat{T}) \} \cup \kappa 
                    \end{array} \\ \\
\end{array}
$$

The inference rule for assignment statement requires the premise $E \vDash \hat{T}, \kappa$, the inference for the expression $E$ returning the type of $E$ and a constraint set $\kappa$, which will be discussed shortly. The ${\tt (tiAssign)}$ rule "calls" the expression inference rule to generate the type $\hat{T}$ and the constraints $\kappa$, it prepends an entry $(\alpha_X,\hat{T})$ to $\kappa$ to ensure that $X$'s type and the type of the assignment's RHS must agree. 

$$
\begin{array}{rc}
{\tt (tiIf)} & \begin{array}{c}
                E \vDash \hat{T_1},\kappa_1 \ \ \ \overline{S_2} \vDash \kappa_2 \ \ \ \ \overline{S_3} \vDash \kappa_3
                \\ \hline
                if\ E\ \{\overline{S_2}\}\ else \{\overline{S_3}\} \vDash \{(\hat{T_1}, bool)\} \cup \kappa_1 \cup \kappa_2 \cup \kappa_3
                \end{array} \\ \\ 
\end{array}
$$
The inference rule for if-else statatement first infers the type of the conditional expression $E$'s type has $\hat{T_1}$ and the constraints $\kappa_1$. $\kappa_2$ and $\kappa_3$ are the constraints inferred from the then- and else-branches. The final result is forming a union of $\kappa_1$, $\kappa_2$ and $\kappa_3$, in addition, requiring $E$'s type must be $bool$. 

$$
\begin{array}{rc}
{\tt (tiWhile)} & \begin{array}{c}
                    E \vDash \hat{T_1}, \kappa_1 \ \ \ \ \overline{S_2} \vDash \kappa_2
                    \\ \hline
                    while\ E\ \{\overline{S_2}\} \vDash \{(\hat{T_1}, bool)\} \cup \kappa_1 \cup \kappa_2
                  \end{array} 
\end{array}
$$

The inference for while statement is very similar to if-else statement. We skip the explanation. 


### Type Inference Rules for SIMP expressions 

The type inference rules for the SIMP expressions are defined in a form of $E \vDash \hat{T}, \kappa$. 


$$
\begin{array}{rc} 
{\tt (tiInt)} & \begin{array}{c}
                c\ {\tt is\ an\ integer}
                \\ \hline
                c \vDash int, \{\}
                \end{array} \\ \\ 
{\tt (tiBool)} & \begin{array}{c}
                c\ \in \{true, false\}
                \\ \hline
                c \vDash bool, \{\}
                \end{array} 
\end{array}
$$

When the expression is an integer constant, we return $int$ as the inferred type and an empty constraint set. Likewise for boolean constant, we return $bool$ and $\{\}$. 


$$
\begin{array}{rc}
{\tt (tiVar)} & X \vDash \alpha_X, \{\} 
\end{array}
$$

The ${\tt (tiVar)}$ rule just generates a "skolem" type variable $\alpha_X$ which is specifically "reserved" for variable $X$. A skolem type variable is a type variable that is free in the current context but it has a specific "purpose".

> For detailed explanation of skolem variable, refer to <https://stackoverflow.com/questions/12719435/what-are-skolems> and <https://en.wikipedia.org/wiki/Skolem_normal_form>.



$$
\begin{array}{rc}
{\tt (tiOp1)} & \begin{array}{c}
                OP \in \{+, -, *, /\} \ \ \ E_1 \vDash \hat{T_1}, \kappa_1\ \ \ \ E_2 \vDash \hat{T_2}, \kappa_2
                \\ \hline
                E_1\ OP\ E_2 \vDash int, \{(\hat{T_1}, int), (\hat{T_2}, int)\} \cup \kappa_1 \cup \kappa_2
                \end{array} \\ \\ 
{\tt (tiOp2)} & \begin{array}{c}
                OP \in \{<, ==\} \ \ \ E_1 \vDash \hat{T_1}, \kappa_1\ \ \ \ E_2 \vDash \hat{T_2}, \kappa_2
                \\ \hline
                E_1\ OP\ E_2 \vDash bool, \{(\hat{T_1}, \hat{T_2})\} \cup \kappa_1 \cup \kappa_2
                \end{array}
\end{array}
$$

The rules ${\tt (tiOp1)}$ and ${\tt (tiOp2)}$ infer the type of binary operation expressions. Note that they can be broken into 6 different rules to be syntax-directed. ${\tt (tiOp1)}$ is applied when the operator is an arithmethic operation, the returned type is $int$ and the inferred constraint set is the union of the constraints inferred from the operands plus the entries of enforcing both $\hat{T_1}$ and $\hat{T_2}$ are $int$. ${\tt (tiOp2)}$ supports the case where the operator is a boolean comparison. 

$$
\begin{array}{rc}
{\tt (tiParen)} & \begin{array}{c}
                  E \vDash \hat{T}, \kappa
                  \\ \hline
                  (E) \vDash \hat{T}, \kappa
                  \end{array}
\end{array}
$$
The inference ruel for parenthesis expression is trivial, we infer the type from the inner expression.

### Unification 

To solve the set of generated type constraints from the above inference rules, we need to use a unification algorithm. 


$$
\begin{array}{rcl}
mgu(int, int) & = & [] \\ 
mgu(bool, bool) & = & [] \\ 
mgu(\alpha, \hat{T}) & = & [\hat{T}/\alpha] \\ 
mgu(\hat{T}, \alpha) & = & [\hat{T}/\alpha] \\
\end{array}
$$

The $mgu(\cdot, \cdot)$ function generates a type substitution that unifies the two arguments. $mgu$ is a short hand for *most general unifier*. Note that $mgu$ function is a partial function, cases that are not mentioned in the above will result in a unification failure. 

At the moment $mgu$ only unifies two extended types. We overload $mgu()$ to apply to a set of constraints as follows

$$
\begin{array}{rcl}
mgu(\{\}) & = & [] \\ 
mgu(\{(\hat{T_1}, \hat{T_2})\} \cup \kappa ) & = & let\ \Psi_1 = mgu(\hat{T_1}, \hat{T_2}) \\ 
& & \ \ \ \ \ \ \kappa'  = \Psi_1(\kappa) \\ 
& & \ \ \ \ \ \ \Psi_2   = mgu(\kappa') \\ 
& & in\  \Psi_2 \circ \Psi_1  
\end{array}
$$

There are two cases.

1. the constraint set is empty, we return the empty (identity) substitution.
1. the constriant set is non-empty, we apply the first version of $mgu$ to unify one entry $(\hat{T_1}, \hat{T_2})$, which yields a subsitution $\Psi_1$. We apply $\Psi_1$ to the rest of the constraints $\kappa$ to obtain $\kappa'$. Next we apply $mgu$ to $\kappa'$ recursively to generate another type substitution $\Psi_2$. The final result is a composition of $\Psi_2$ with $\Psi_1$. 

Note that the choice of the particular entry $(\hat{T_1}, \hat{T_2})$ does not matter, the algorithm will always produce the same result when we apply the final subsitution to all the skolem type variable $\alpha_X$. We see that in an example shortly. 

### An Example

Consider the following SIMP program

```java
x = input;          // (α_x, α_input)      
y = 0;              // (α_y, int)
while (y < x) {     // (α_y, α_x)
    y = y + 1;      // (α_y, int)
}
```

For the ease of access we put the inferred constraint entry as comments next to the statements. The detail derivation of the inference algorithm is as follows


```java
input|=α_input,{} (tiVar)
-------------------------(tiAssign)    [subtree 1]
x=input|={(α_x,α_input)}   
-----------------------------------------------------------------------------(tiSeq)
x=input; y=0; while (y<x) { y=y+1; } return y; |= {(α_x,α_input),(a_y,int),(α_y,α_x)} 
```

Where [subtree 1] is as follows


```java
y|=α_y,{} (tiVar)
0|=int,{} (tiInt)
------------------(tiAssign)   [subtree 2]
y=0|={(α_y,int)}
--------------------------------------------------------(tiSeq)
y=0; while (y<x) { y=y+1; } return y; |= {(a_y,int),(α_y,α_x)} 
```


Where [subtree 2] is as follows

```java
                        y|=α_y,{} (tiVar)
                        1|=int,{} (tiInt)
y|=α_y,{} (tiVar)       --------------(tiOp1)
x|=α_x,{} (tiVar)       y+1|=int,{(a_y,int)}
--------------(tiOp2)  ----------------------(tiAssign)
y<x|=bool,{(α_y,α_x)}  y=y+1|= {(a_y,int)} 
---------------------------------------------(tiWhile) --------------(tiReturn)
while (y<x) { y=y+1; } |= {(α_y,α_x),(a_y,int)}        return y|= {}
---------------------------------------------------------------------(tiSeq)
while (y<x) { y=y+1; } return y; |= {(α_y,α_x),(a_y,int)} 
```

### From Type Substitution to Type Environment

To derive the inferred type environment, we apply the type substitution to all the type variabales we created. 

Let $V(\overline{S})$ denote all the variables used in a SIMP program $\overline{S}$.

Given a type substitution $\Psi$ obtained from the unification step, the type environment $\Gamma$ can be computed as follows,

$$
\Gamma = \{ (X, \Psi(\alpha_X)) | X \in V(\overline{S}) \}
$$


Recall that the set of constraints generated from the running example is 

$$
\{(\alpha_x,\alpha_{input}),(\alpha_{y},int),(\alpha_{y},\alpha_{x})\} 
$$

#### Unification from left to right

Suppose the unification progress pick the entries from left to right

$$
\begin{array}{ll}
mgu(\{(\underline{\alpha_x,\alpha_{input}}),(\alpha_{y},int),(\alpha_{y},\alpha_{x})\}) & \longrightarrow \\ 
let\ \Psi_1 = mgu(\alpha_x,\alpha_{input}) \\ 
\ \ \ \ \ \ \kappa_1 = \Psi_1\{(\alpha_{y},int),(\alpha_{y},\alpha_{x})\} \\ 
\ \ \ \ \ \ \Psi_2 = mgu(\kappa_1) \\
in\ \Psi_2 \circ \Psi_1  & \longrightarrow \\ 
let\ \Psi_1 = [\alpha_{input}/ \alpha_x] \\ 
\ \ \ \ \ \ \kappa_1 = \Psi_1\{(\alpha_{y},int),(\alpha_{y},\alpha_{x})\} \\ 
\ \ \ \ \ \ \Psi_2 = mgu(\kappa_1) \\
in\ \Psi_2 \circ \Psi_1  & \longrightarrow \\ 
let\ \Psi_1 = [\alpha_{input}/ \alpha_x] \\ 
\ \ \ \ \ \ \kappa_1 = \{(\alpha_{y},int),(\alpha_{y},\alpha_{input})\} \\ 
\ \ \ \ \ \ \Psi_2 = mgu(\kappa_1) \\
in\ \Psi_2 \circ \Psi_1 & \longrightarrow 
\end{array}
$$

Where derivation of $mgu(\kappa_1)$ 

$$
\begin{array}{ll}
mgu(\{(\underline{\alpha_{y},int}),(\alpha_{y},\alpha_{input})\}) & \longrightarrow \\ 
let\ \Psi_{21} = mgu(\alpha_{y},int) \\
\ \ \ \ \ \ \kappa_2 = \Psi_{21}\{(\alpha_{y},\alpha_{input})\} \\ 
\ \ \ \ \ \ \Psi_{22} = mgu(\kappa_2) \\ 
in\ \Psi_{22} \circ \Psi_{21} & \longrightarrow \\
let\ \Psi_{21} = [int/\alpha_{y}] \\
\ \ \ \ \ \ \kappa_2 = \Psi_{21}\{(\alpha_{y},\alpha_{input})\} \\ 
\ \ \ \ \ \ \Psi_{22} = mgu(\kappa_2) \\ 
in\ \Psi_{22} \circ \Psi_{21} & \longrightarrow \\
let\ \Psi_{21} = [int/\alpha_{y}] \\
\ \ \ \ \ \ \kappa_2 = \{(int,\alpha_{input})\} \\ 
\ \ \ \ \ \ \Psi_{22} = mgu(\kappa_2) \\ 
in\ \Psi_{22} \circ \Psi_{21} & \longrightarrow \\
let\ \Psi_{21} = [int/\alpha_{y}] \\
\ \ \ \ \ \ \kappa_2 = \{(int,\alpha_{input})\} \\ 
\ \ \ \ \ \ \Psi_{22} = [int/\alpha_{input}] \\ 
in\ \Psi_{22} \circ \Psi_{21} & \longrightarrow \\
[int/\alpha_{input}] \circ [int/\alpha_{y}]
\end{array}
$$
Hence the final result is 

$$ 
[int/\alpha_{input}] \circ [int/\alpha_{y}] \circ [\alpha_{input}/ \alpha_x]
$$

We apply this type substitution to all the variables in the program.

$$
\begin{array}{rl}
([int/\alpha_{input}] \circ [int/\alpha_{y}] \circ [\alpha_{input}/ \alpha_x])\alpha_{input} & = \\  
([int/\alpha_{input}] \circ [int/\alpha_{y}])\alpha_{input} & = \\  
[int/\alpha_{input}]  \alpha_{input} & = \\  
int \\ \\ 
([int/\alpha_{input}] \circ [int/\alpha_{y}] \circ [\alpha_{input}/ \alpha_x])\alpha_{x} & = \\  
([int/\alpha_{input}] \circ [int/\alpha_{y}])\alpha_{input} & = \\  
[int/\alpha_{input}]  \alpha_{input} & = \\  
int \\ \\ 
([int/\alpha_{input}] \circ [int/\alpha_{y}] \circ [\alpha_{input}/ \alpha_x])\alpha_{y} & = \\  
([int/\alpha_{input}] \circ [int/\alpha_{y}]) \alpha_{y} & = \\  
[int/\alpha_{input}] int & = \\  
int \\ \\ 
\end{array}
$$

So we have computed the inferred type environment

$$
\Gamma = \{(input, int), (x, int), (y,int) \}
$$

#### Unification from right to left

Now let's consider a different of order of applying the $mgu$ function to the constraint set. Instead of going from left to right, we solve the constraints from right to left. 

$$
\begin{array}{ll}
mgu(\{(\alpha_x,\alpha_{input}),(\alpha_{y},int),(\underline{\alpha_{y},\alpha_{x}})\}) & \longrightarrow \\ 
let\ \Psi_1 = mgu(\alpha_{y},\alpha_{x}) \\ 
\ \ \ \ \ \ \kappa_1 = \Psi_1\{(\alpha_x,\alpha_{input}),(\alpha_{y},int)\} \\ 
\ \ \ \ \ \ \Psi_2 = mgu(\kappa_1) \\
in\ \Psi_2 \circ \Psi_1  & \longrightarrow \\ 
let\ \Psi_1 = [\alpha_{x}/ \alpha_y] \\ 
\ \ \ \ \ \ \kappa_1 = \Psi_1\{(\alpha_x,\alpha_{input}),(\alpha_{y},int)\} \\ 
\ \ \ \ \ \ \Psi_2 = mgu(\kappa_1) \\
in\ \Psi_2 \circ \Psi_1  & \longrightarrow \\ 
let\ \Psi_1 = [\alpha_{x}/ \alpha_y] \\ 
\ \ \ \ \ \ \kappa_1 = \{(\alpha_x,\alpha_{input}),(\alpha_{x},int)\} \\ 
\ \ \ \ \ \ \Psi_2 = mgu(\kappa_1) \\
in\ \Psi_2 \circ \Psi_1 & \longrightarrow 
\end{array}
$$

Where derivation of $mgu(\kappa_1)$ 

$$
\begin{array}{ll}
mgu(\{(\alpha_x,\alpha_{input}),(\underline{\alpha_{x},int})\}) & \longrightarrow \\ 
let\ \Psi_{21} = mgu(\alpha_{x},int) \\
\ \ \ \ \ \ \kappa_2 = \Psi_{21}\{(\alpha_{x},\alpha_{input})\} \\ 
\ \ \ \ \ \ \Psi_{22} = mgu(\kappa_2) \\ 
in\ \Psi_{22} \circ \Psi_{21} & \longrightarrow \\
let\ \Psi_{21} = [int/\alpha_{x}] \\
\ \ \ \ \ \ \kappa_2 = \Psi_{21}\{(\alpha_{x},\alpha_{input})\} \\ 
\ \ \ \ \ \ \Psi_{22} = mgu(\kappa_2) \\ 
in\ \Psi_{22} \circ \Psi_{21} & \longrightarrow \\
let\ \Psi_{21} = [int/\alpha_{x}] \\
\ \ \ \ \ \ \kappa_2 = \{(int,\alpha_{input})\} \\ 
\ \ \ \ \ \ \Psi_{22} = mgu(\kappa_2) \\ 
in\ \Psi_{22} \circ \Psi_{21} & \longrightarrow \\
let\ \Psi_{21} = [int/\alpha_{x}] \\
\ \ \ \ \ \ \kappa_2 = \{(int,\alpha_{input})\} \\ 
\ \ \ \ \ \ \Psi_{22} = [int/\alpha_{input}] \\ 
in\ \Psi_{22} \circ \Psi_{21} & \longrightarrow \\
[int/\alpha_{input}] \circ [int/\alpha_{x}]
\end{array}
$$

Hence the final result is 

$$ 
[int/\alpha_{input}] \circ [int/\alpha_{x}] \circ [\alpha_{x}/ \alpha_y]
$$

We apply this type substitution to all the variables in the program.

$$
\begin{array}{rl}
([int/\alpha_{input}] \circ [int/\alpha_{x}] \circ [\alpha_{x}/ \alpha_y])\alpha_{input} & = \\  
([int/\alpha_{input}] \circ [int/\alpha_{x}])\alpha_{input} & = \\  
[int/\alpha_{input}]  \alpha_{input} & = \\  
int \\ \\ 
([int/\alpha_{input}] \circ [int/\alpha_{x}] \circ [\alpha_{x}/ \alpha_y])\alpha_{x} & = \\  
([int/\alpha_{input}] \circ [int/\alpha_{x}])\alpha_{x} & = \\  
[int/\alpha_{input}]  int & = \\  
int \\ \\ 
([int/\alpha_{input}] \circ [int/\alpha_{x}] \circ [\alpha_{x}/ \alpha_y])\alpha_{y} & = \\  
([int/\alpha_{input}] \circ [int/\alpha_{x}]) \alpha_{x} & = \\  
[int/\alpha_{input}] int & = \\  
int \\ \\ 
\end{array}
$$

So we have computed the inferred the same type environment

$$
\Gamma = \{(input, int), (x, int), (y,int) \}
$$


In face regardless the order of picking entries from the constraint sets, we compute the same $\Gamma$.  

> If you have time, you can try another order.

### Input's type

In our running example, our inference algorithm is able to infer the program's input type i.e. $\alpha_{input}$.

This is not always possible. Let's consider the following program.

```java
x = input;          // (α_x, α_input)      
y = 0;              // (α_y, int)
while (y < 3) {     // (α_y, int)
    y = y + 1;      // (α_y, int)
}
```

In the genereated constraints, our algorithm can construct the subtitution 

$$[\alpha_{input}/\alpha_x] \circ [int/\alpha_y]$$

Which fails to "ground" type variables $\alpha_{input}$ and $\alpha_x$. 

We may argue that this is an ill-defined program as `input` and `x` are not used in the rest of the program, which should be rejected if we employ some name analysis, (which we will learn in the upcoming lesson). Hence we simply reject this kind of programs. 

Alternatively, we can preset the type of the program, which is a common practice for many program languages. When generating the set of constraint $\kappa$, we manually add an entry $(\alpha_{input}, int)$ assuming the input's type is expected to be $int$. 


### Uninitialized Variable

There is another situatoin in which the inference algorithm fails to ground all the type variables.

```java
x = z;              // (α_x, α_z)      
y = 0;              // (α_y, int)
while (y < 3) {     // (α_y, int)
    y = y + 1;      // (α_y, int)
}
```
in this case, we can't ground $\alpha_x$ and $\alpha_z$ as `z` is not initialized before use. In this case we argue that such a program should be rejected either by the type inference or the name analysis.


### Property 4: Type Inference Soundness
The following property states that the type environment generated from a SIMP program by the type inference algorithm is able to type check the SIMP program.

Let $\overline{S}$ be a SIMP program and $\Gamma$ is a type environment inferred using the described inference algorithm. Then $\Gamma \vdash \overline{S}$. 

### Property 5: Principality 
The following property states that the type environment generated from a SIMP program by the type inference algorithm is a principal type environment.

Let $\overline{S}$ be a SIMP program and $\Gamma$ is a type environment inferred using the described inference algorithm. Then $\Gamma$ is the most general type environment that can type-check $\overline{S}$. 

