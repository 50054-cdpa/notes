# 50.054 - Dynamic Semantics

## Learning Outcomes

1. Explain the small step operational semantics of a programming language.
1. Explain the big step operational semantics of a programming language.
1. Formalize the run-time behavior of a programming language using small step operational semantics.
1. Formalize the run-time behavior of a programming language using big step operational semantics.

Recall that by formalizing the dynamic semantics of a program we are keen to find out

1. How does the program get executed?
1. What does the program compute / return?

## Operational Semantics

Operational Semantics specifies how a program get executed.

For example, in the earlier unit, when studying lambada expression, we made use of the $\beta$-reduction, the substitution and alpha renaming rules to formalize the execution of a simple lambda expression.
As the language grows to include let-binding, conditional expression, we extend the set of rules to include ${\tt (Let)}$, ${\tt (IfI)}$, ${\tt (IfT)}$ and ${\tt (IfF)}$. The set of rules in this example defines the operational semantics of the programming language lambda expression. We can apply these rules to "evaluate" a lambda expression by rewriting it by picking a matching rule (w.r.t to the LHS) and turn it into the form of the RHS. This style of semantics specification is called the *small step* operational semantics as we only specify the intermediate result when we apply a rule.  

As we are going to design and implement a compiler for the SIMP language, it is essential to find out how a SIMP program gets executed.

To formalize the execution of SIMP program, we can define a set of rewriting rules similar to those for lambda calculus. We need to consider different cases.

### Small-Step Operational Semantics of SIMP

Let's try to formalize the Operational Semantics of SIMP language,

$$
\begin{array}{rccl}
(\tt SIMP\ Environment) & \Delta & \subseteq & (X \times c)
\end{array}
$$
We model the memory environment of a SIMP program as pair of variable and values. We write $dom(\Delta)$ to denote the domain of $\Delta$, i.e. $\{ X \mid (X,c) \in \Delta \}$. We assume for all $X \in dom(\Delta)$, there exists only one entry of $(X,c) \in \Delta$.

Given $S$ is a set of pairs, we write $S(x)$ to denote $a$ if $(x,a) \in S$, an error otherwise. We write $S \oplus (x,a)$ to denote $S - \{(x, S(x))\} \cup \{(x, a)\}$. 

We define the operational semantics of SIMP with two sets of rules.

The first set of rules deal with expression.

#### Small Step Operational Semantics of SIMP Expression

The set of small stpe operational semantics for expressions is defined in a relation $\Delta \vdash E \longrightarrow E'$.

$$
{\tt (sVar)} ~~~ \Delta \vdash X \longrightarrow \Delta(X)
$$
The ${\tt (sVar)}$ rule looks up the value of variable $X$ from the memory environment. If the variable is not found, it gets stuck and an error is returned.
$$
\begin{array}{rc}
{\tt (sOp1)} & \begin{array}{c}
        \Delta \vdash E_1 \longrightarrow E_1'  
        \\ \hline
        \Delta \vdash E_1\ OP\ E_2 \longrightarrow E_1'\ OP\ E_2
        \end{array}
\end{array}
$$

$$
\begin{array}{rc}
{\tt (sOp2)} & \begin{array}{c}
        \Delta \vdash E_2 \longrightarrow E_2'  
        \\ \hline
        \Delta \vdash C_1 \ OP\ E_2 \longrightarrow C_1\ OP\ E_2'
        \end{array}
\end{array}
$$

$$
\begin{array}{rc}
{\tt (sOp3)} & \begin{array}{c}
        C_3 = C_1 \ OP\ C_2
        \\ \hline
        \Delta \vdash C_1 \ OP\ C_2 \longrightarrow C_3
        \end{array}
\end{array}
$$

The above three rules handle the binary operation expression.

1. ${\tt (sOp1)}$ matches with the case where both operands are not constant values. It evalues the first operand by one step.  
1. ${\tt (sOp2)}$ matches with the case where the first operand becomes constant, it evaluates the second operand by one step.
1. ${\tt (sOp3)}$ matches with the case where both operands are constant. It returns the result by applying the binary operation to the two constant values.

$$
\begin{array}{rc}
{\tt (sParen1)} & \begin{array}{c}
                 \Delta \vdash E \longrightarrow E'
                 \\ \hline 
                 \Delta \vdash (E) \longrightarrow (E')
                 \end{array} \\ \\
{\tt (sParen2)} & \begin{array}{c}
                 \Delta \vdash (c) \longrightarrow c
                 \end{array}
\end{array}
$$

The rules ${\tt  (sParen1)}$ and ${\tt (sParent2)}$ evaluate an expression enclosed by parantheses. 

#### Small Step Operational Semantics of SIMP statement

The small step operational semantics of statements are defined by the relation
$(\Delta, S) \longrightarrow (\Delta', S')$. The pair of a environment and a statement is called a program configuration.

$$
\begin{array}{cc}
{\tt (sAssign1)} & \begin{array}{c}
     \Delta\vdash E \longrightarrow E'
     \\ \hline
     (\Delta, X = E;) \longrightarrow  (\Delta, X = E';)
     \end{array}
\end{array}
$$

$$
\begin{array}{cc}
{\tt (sAssign2)} & \begin{array}{c}
      \Delta' = \Delta \oplus (X, C)
     \\ \hline
     (\Delta, X = C;) \longrightarrow (\Delta', nop)
     \end{array}
\end{array}
$$
The rules ${\tt (sAssign1)}$ and ${\tt (sAssign2)}$ handle the assignment statements.

1. ${\tt (sAssign1)}$ matches with the case that the RHS of the assignment is not a constant, it evaluates the RHS expression by one step.
1. ${\tt (sAssign2)}$ matches with the case that the RHS is a constant, it updates the environment by setting $C$ as the new value of variable $X$. The statement of the resulting configuration a $nop$.

$$
\begin{array}{cc}
{\tt (sIf1)} & \begin{array}{c}
    \Delta \vdash E \longrightarrow E'
    \\ \hline
    (\Delta, if\ E\ \{\overline{S_1}\}\ else\ \{\overline{S_2}\})
    \longrightarrow (\Delta,  if\ E'\ \{\overline{S_1}\}\ else\ \{\overline{S_2}\})
    \end{array}
\end{array}
$$

$$
\begin{array}{cc}
{\tt (sIf2)} &
    (\Delta, if\ true\ \{\overline{S_1}\}\ else\ \{\overline{S_2}\})
    \longrightarrow (\Delta, \overline{S_1})
\end{array}
$$

$$
\begin{array}{cc}
{\tt (sIf3)} &
    (\Delta, if\ false\ \{\overline{S_1}\}\ else\ \{\overline{S_2}\})
    \longrightarrow (\Delta, \overline{S_2})
\end{array}
$$

The rules ${\tt (sIf1)}$, ${\tt (sIf2)}$ and ${\tt (sIf3)}$ handle the if-else statement.

1. ${\tt (sIf1)}$ matches with the case where the condition expression $E$ is not a constant value. It evaluates $E$ to $E'$ one step.
1. ${\tt (sIf2)}$ matches with the case where the condition expression is $true$, it proceeds to evaluate the statements in the then clauses.
1. ${\tt (sIf3)}$ matches with the case where the condition expression is $false$, it proceeds to evaluate the statements in the else clauses.

$$
\begin{array}{cc}
{\tt (sWhile)} &
    (\Delta, while\ E\ \{\overline{S}\} )
    \longrightarrow (\Delta,  if\ E\ \{\overline{S}; while\ E\ \{\overline{S}\}\}\ else\ \{ nop \})
\end{array}
$$

The rule ${\tt (sWhile)}$ evaluates the while statement by reiwrting it into a if-else statement.

* In the then branch, we unroll the while loop body once followed by the while loop.
* In the else branch, we should exit the while loop thus, a $nop$ statement is used.

$$
{\tt (sNopSeq)} ~~ (\Delta, nop; \overline{S}) \longrightarrow (\Delta, \overline{S})
$$

$$
\begin{array}{cc}
{\tt (sSeq)} & \begin{array}{c}
    S \neq nop\ \ \ (\Delta, S) \longrightarrow (\Delta', S')
    \\ \hline
   (\Delta, S \overline{S}) \longrightarrow (\Delta', S' \overline{S})
   \end{array}
\end{array}
$$

The rules ${\tt (sNopSeq)}$ and ${\tt (sSeq)}$ handle a sequence of statements.

1. ${\tt (sNopSeq)}$ rule handles the special case where the leading statement is a $nop$.
1. ${\tt (Seq)}$ rule handles the case where the leading statement is not a $nop$. It evalues $S$ by one step.

For example,

```python
{(input, 1)},
x = input;
s = 0;
c = 0;
while c < x {
    s = c + s;
    c = c + 1;
}
return s;
---> # using s(Seq)
   {(input,1)}, x = input 
   ---> # (sAssign1) 
   {(input,1)}, x = 1
   ---> # (sAssign2) 
   {(input, 1), (x,1)}, nop
--->
{(input,1), (x,1)},
nop;
s = 0;
c = 0;
while c < x {
    s = c + s;
    c = c + 1;
}
return s;

---> # (sNopSeq)


{(input,1), (x,1)},
s = 0;
c = 0;
while c < x {
    s = c + s;
    c = c + 1;
}
return s;

---> # (sSeq), (sAssign2), (sNoSeq)

{(input,1), (x,1), (s,0)},
c = 0;
while c < x {
    s = c + s;
    c = c + 1;
}
return s;

---> # (sSeq), (sAssign2), (sNoSeq)

{(input,1), (x,1), (s,0), (c,0)},
while c < x {
    s = c + s;
    c = c + 1;
}
return s;
---> # (sSeq) 
    {(input,1), (x,1), (s,0), (c,0)},
    while c < x {
        s = c + s;
        c = c + 1;
    }
    ---> # (sWhile)

    {(input,1), (x,1), (s,0), (c,0)},
    if (c < x) {
        s = c + s;
        c = c + 1;
        while c < x {
            s = c + s;
            c = c + 1;
        }
    } else {
        nop
    }

    ---> # (sIf1)
        {(input,1), (x,1), (s,0), (c,0)}, c < x 
        ---> # (sOp1) 
        {(input,1), (x,1), (s,0), (c,0)}, 0 < x 
        ---> # (sOp2) 
        {(input,1), (x,1), (s,0), (c,0)}, 0 < 1 
        ---> # (sOp3) 
        {(input,1), (x,1), (s,0), (c,0)}, true 
    ---> 
    {(input,1), (x,1), (s,0), (c,0)},
    if true {
        s = c + s;
        c = c + 1;
        while c < x {
            s = c + s;
            c = c + 1;
        }
    } else {
        nop
    }
    ---> # (sIf2)
    {(input,1), (x,1), (s,0), (c,0)},
    s = c + s;
    c = c + 1;
    while c < x {
        s = c + s;
        c = c + 1;
    }
    ---> # (sSeq)
        {(input,1), (x,1), (s,0), (c,0)},
        s = c + s ---> # (sAssign1)
            {(input,1), (x,1), (s,0), (c,0)},
            c + s ---> # (sOp1) 
            0 + s ---> # (sOp2) 
            0 + 0 ---> # (sOp3) 
            0
        {(input,1), (x,1), (s,0), (c,0)},
        s = 0 ---> # (sAssign2)
        {(input,1), (x,1), (s,0), (c,0)},
        nop 
    ---> # (sNopSeq)
    {(input,1), (x,1), (s,0), (c,0)},
    c = c + 1;
    while c < x {
        s = c + s;
        c = c + 1;
    }
    ---> # (sSeq)
        {(input,1), (x,1), (s,0), (c,0)},
        c = c + 1 ---> # (sAssign1)
            {(input,1), (x,1), (s,0), (c,0)},
            c + 1 ---> # (sOp1)
            0 + 1 ---> # (SOp3)
            1
        {(input,1), (x,1), (s,0), (c,0)},
        c = 0 ---> # (sAssign2)
        {(input,1), (x,1), (s,0), (c,1)},
        nop
    ---> # (sNopSeq) 
    {(input,1), (x,1), (s,0), (c,1)},
    while c < x {
        s = c + s;
        c = c + 1;
    }
    ---> # (sWhile)
    {(input,1), (x,1), (s,0), (c,1)},
    if (c < x) {
        s = c + s;
        c = c + 1;
        while c < x {
            s = c + s;
            c = c + 1;
        }
    } else {
        nop
    }
    ---> # (sIf1)
        {(input,1), (x,1), (s,0), (c,1)}, c < x 
        ---> # (sOp1) 
        {(input,1), (x,1), (s,0), (c,1)}, 1 < x 
        ---> # (sOp2) 
        {(input,1), (x,1), (s,0), (c,1)}, 1 < 1 
        ---> # (sOp3) 
        {(input,1), (x,1), (s,0), (c,1)}, false 
    ---> 
    {(input,1), (x,1), (s,0), (c,1)},
    if false {
        s = c + s;
        c = c + 1;
        while c < x {
            s = c + s;
            c = c + 1;
        }
    } else {
        nop
    }
    ---> # (sIf3)
    {(input,1), (x,1), (s,0), (c,1)},
    nop
---> # (sNopSeq)
{(input,1), (x,1), (s,0), (c,1)}
return s;
```

At last the derivation stop at the return statement. We can return the value `0` as result.

### Big Step Operational Semantics

Small step operational semantics defines the run-time behavior of programs step by step (kinda like slow motion.)
Some times we want to define the run-time behaviors by "fast-forwarding" to the result.
This leads us to the big step operatinal semantics.
Big step operatinal semantics in some literature is also called the structural operatial semantics as it leverages on the syntactic structure of the program.

#### Big Step Operational Semantics for SIMP expressions

We define the big step oeprational semantics for SIMP expressions via a relation
$\Delta \vdash E \Downarrow c$, which reads under the memory environment $\Delta$ the expressiopn $E$ is evaluated constant $c$.

We consider the following three rules
$$
{\tt (bConst)} ~~~~ \Delta \vdash c \Downarrow c
$$
In case that the expression is a constant, we return the constant itself.

$$
{\tt (bVar)} ~~~~ \Delta \vdash X \Downarrow \Delta(X)
$$

In case that the expression is a variable $X$, we return the value associated with $X$ in $\Delta$.

$$
\begin{array}{rc}
{\tt (bOp)} & \begin{array}{c}
            \Delta \vdash E_1 \Downarrow c_1 ~~~ \Delta \vdash E_2 \Downarrow c_2 ~~~~
            c_1\ OP\ c_2 = c_3
            \\ \hline
            \Delta \vdash E_1\ OP\ E_2 \Downarrow c_3
            \end{array}
\end{array}
$$

in case that the expression is a binary operation, we evaluate the two operands to values and apply the binary operation to the constant values.

$$
\begin{array}{rc}
{\tt (bParen)} & \begin{array}{c}
                \Delta \vdash E \Downarrow c
                \\ \hline
                \Delta \vdash (E) \Downarrow c
               \end{array}
\end{array}
$$

the last rule ${\tt (bParen)}$ evaluetes an expression enclosed by parantheses.  

#### Big Step Operational Semantics for SIMP statements

We define the big step operational semantics for SIMP statement using a relation $(\Delta, S) \Downarrow \Delta'$, which says the program configuration $(\Delta, S)$ is evaluated to result memory environment $\Delta'$ assuming $S$ is terminating under $\Delta$. Note that big step operational semantics for SIMP statement can only defines the behavior of terminating program configurations.

We consider the following rules
$$
\begin{array}{rc}
{\tt (bAssign)} & \begin{array}{c}
    \Delta \vdash E \Downarrow c
    \\ \hline
    (\Delta, X = E) \Downarrow \Delta \oplus (X, c)
    \end{array}
\end{array}
$$

In case that the statement is an assignment, we evaluate the RHS expression to a constant value $c$ and update the memory environment.

$$
\begin{array}{rc}
{\tt (bIf1)} & \begin{array}{c}
    \Delta \vdash E \Downarrow true ~~~~~~
    (\Delta, \overline{S_1}) \Downarrow \Delta_1
    \\ \hline
    (\Delta, if\ E\ \{ \overline{S_1} \}\ else\ \{ \overline{S_2} \} ) \Downarrow \Delta_1
    \end{array}
\end{array}
$$

$$
\begin{array}{rc}
{\tt (bIf2)} & \begin{array}{c}
    \Delta \vdash E \Downarrow false ~~~~~~
    (\Delta, \overline{S_2}) \Downarrow \Delta_2
    \\ \hline
    (\Delta, if\ E\ \{ \overline{S_1} \}\ else\ \{ \overline{S_2} \} ) \Downarrow \Delta_2
    \end{array}
\end{array}
$$

In case that the statement is an if-else statement, we evaluate $\overline{S_1}$ if the conditional expression is $true$, otherwise evaluate $\overline{S_2}$.

$$
\begin{array}{rc}
{\tt (bWhile1)} & \begin{array}{c}
    \Delta \vdash E \Downarrow true ~~~~~~
    (\Delta, \overline{S}; while\ E\ \{ \overline{S} \}) \Downarrow \Delta'
    \\ \hline
    (\Delta, while\ E\ \{ \overline{S} \}) \Downarrow \Delta'
    \end{array}
\end{array}
$$

$$
\begin{array}{rc}
{\tt (bWhile2)} & \begin{array}{c}
    \Delta \vdash E \Downarrow false
    \\ \hline
    (\Delta, while\ E\ \{ \overline{S} \}) \Downarrow \Delta
    \end{array}
\end{array}
$$

In case that the statment is a while loop. We evaluate the body followed by the while loop again when the loop condition expression is $true$, otherwise, we exit the while loop and return the existing memory environment.

$$
{\tt (bNop)} ~~~~ (\Delta, nop) \Downarrow \Delta
$$

In case that the statement is a noop statement, there is no change to the memory environment.

$$
\begin{array}{rc}
{\tt (bSeq)} & \begin{array}{c}
            (\Delta, S) \Downarrow \Delta' ~~~~ (\Delta', \overline{S}) \Downarrow \Delta''
            \\ \hline
            (\Delta, S \overline{S}) \Downarrow \Delta''
            \end{array}
\end{array}
$$

In case of a sequence of statement, we evaluate the leading statement to an updated environment and use the updated environment to evaluate the following statements.

For example, the following derivation (tree) is the evaluate of our running example using the big step operational semantics. The reason of having a tree derivation as we are evaluating the SIMP program to the final result directly by evaluating its sub components recursively / inductively.

```python
                                   {(input,1),(x,1)} |- 0 ⇓ 0 (bConst)
                                   ---------------------(bAssign)     [sub tree 1]
                                   {(input,1), (x,1)}, 
                                   s = 0; 
{(input,1)} |- input ⇓ 1 (bVar)    ⇓ {(input,1), (x,1), (s,0)}      
---------------- (bAssign)         -------------------------------------------(bSeq)
{(input,1)},                       {(input,1), (x,1)},  
x = input;                         s = 0;
⇓ {(input,1), (x,1)}               c = 0;
                                   while c < x {
                                   s = c + s;
                                   c = c + 1;
                                   }
                                   return s; ⇓ {(input,1), (x,1), (s,0), (c,1)}
---------------------------------------------------------------------------- (bSeq)
{(input, 1)}, 
x = input;
s = 0;
c = 0;
while c < x {
    s = c + s;
    c = c + 1;
}
return s; ⇓ {(input, 1), (x, 1), (s, 0), (c, 1)}
```

where sub derivation`[sub tree 1]` is as follows

```python
                                          
{(input,1), (x,1), (s,0)}              [sub tree 2]  -------------------- (bReturn)
|- 0 ⇓ 0 (bConst)                                    {(input,1), (x,1), (s,0), (c,1)}, 
                                                     return s; ⇓ 
                                                     {(input,1), (x,1), (s,0), (c,1)}
--------------------------(bAssign)   -------------------------------------- (bSeq)
{(input,1), (x,1), (s,0)},            {(input,1), (x,1), (s,0), (c,0)},
c = 0;                                while c < x {s = c + s; c = c + 1;} 
⇓                                     return s; ⇓ {(input,1), (x,1), (s,0), (c,1)}
{(input,1),(x,1),(s,0),(c,0)}                    
---------------------------------------------------------------------------- (bSeq)
{(input,1), (x,1), (s,0)},
c = 0;
while c < x {
    s = c + s;
    c = c + 1;
}
return s;
⇓ {(input,1), (x,1), (s,0), (c,1)}
```

where
`[sub tree 2]` is

```python

{(input,1), (x,1), (s,0), (c,0)} 
|- c ⇓ 0 (bVar)

{(input,1), (x,1), (s,0), (c,0)} 
|- x ⇓ 1 (bVar)

0 < 1  == true                         [sub tree 3]          [sub tree 4]
-------------------------------- (bOp) ---------------------------------- (bSeq)
{(input,1), (x,1), (s,0), (c,0)}       {(input,1), (x,1), (s,0), (c,0)},
|- c < x ⇓ true                         s = c + s; c = c + 1; 
                                        while c < x {s = c + s; c = c + 1;} ⇓
                                        {(input,1), (x,1), (s,0), (c,1)}
-----------------------------------------------------------------------  (bWhile1)
{(input,1), (x,1), (s,0), (c,0)},
while c < x {s = c + s; c = c + 1;} ⇓ {(input,1), (x,1), (s,0), (c,1)}
```

where
`[sub tree 3]` is

```python
{(input, 1), (x, 1), (s, 0), (c, 0)}
|- c ⇓ 0 (bVar)

{(input, 1), (x, 1), (s, 0), (c, 0)}
|- s ⇓ 0 (bVar)

c + s == 0
------------------------------------ (bOp)
{(input, 1), (x, 1), (s, 0), (c, 0)} 
|- c + s ⇓ 0  
------------------------------------- (bAssign)
{(input, 1), (x, 1), (s, 0), (c, 0)},
s = c + s; ⇓
{(input, 1), (x, 1), (s, 0), (c, 0)}
```

where
`[sub tree 4]` is

```python
{(input, 1), (x, 1), (s, 0), (c, 0)}
|- c ⇓ 0 (bVar)

{(input, 1), (x, 1), (s, 0), (c, 0)}
|- 1 ⇓ 1 (bConst)

c + 1 == 1
------------------------------------ (bOp)
{(input, 1), (x, 1), (s, 0), (c, 0)} 
|- c + 1 ⇓ 1  
-------------------------------------- (bAssign)
{(input, 1), (x, 1), (s, 0), (c, 0)},
c = c + 1; ⇓
{(input, 1), (x, 1), (s, 0), (c, 1)}                [sub tree 5]
--------------------------------------------------------------------- (bSeq)
{(input, 1), (x, 1), (s, 0), (c, 0)},
c = c + 1; 
while c < x {s = c + s; c = c + 1;} ⇓ {(input, 1), (x, 1), (s, 0), (c, 1)}
```

where
`[sub tree 5]` is

```python
{(input, 1), (x, 1), (s, 0), (c, 1)} (bVar)
|- c ⇓ 1 

{(input, 1), (x, 1), (s, 0), (c, 1)} (bVar)
|- x ⇓ 1 

1 < 1 == false
------------------------------------ (bOp)
{(input, 1), (x, 1), (s, 0), (c, 1)} 
|- c < x ⇓ false
---------------------------------------------------- (bWhile2)
{(input, 1), (x, 1), (s, 0), (c, 1)}, 
while c < x {s = c + s; c = c + 1;} ⇓
{(input, 1), (x, 1), (s, 0), (c, 1)}
```

### Quick Summary: Small step vs Big Step operational semantics

|  |  Small step operational semantics | Big step operational semantics |
|---|---|---|
| mode | one step of change at a time | many steps of changes at a time |
| derivation | it is linear | it is a tree |
| cons | it is slow-paced and lengthy, requires more rules | it is a fast-forward version, requirews fewer rules |
| pros | it is expressive, supports non-terminiating program | it assumes program is terminating |

#### Formal Results

We use $\longrightarrow^*$ to denote multiple steps of derivation with $\longrightarrow$.

#### Lemma 1 (Agreement of Small Step and Big Step Operational Semantics of SIMP)

Let $\overline{S}$ be a SIMP program, $\Delta$ be a memory environment. Then $\Delta, \overline{S} \Downarrow \Delta'$ iff $(\Delta, \overline{S}) \longrightarrow^* (\Delta', return\ X)$ for some $X$.

Proof of this lemma requires some knowledge which will be discussed in the upcoming classes.

## Operational Semantics of Pseudo Assembly

Next we consider the operational semantics of pseudo assembly.

Let's define the environments required for the rules.

$$
\begin{array}{rccl}
(\tt PA\ Program) & P & \subseteq & (l \times li)  \\
(\tt PA\ Environment) & L & \subseteq & (t \times c) \cup (r \times c)
\end{array}
$$

We use $P$ to denote a PA program, which is a mapping from label to labeled instructions.
We use $L$ to denote a memory environment which is a mapping from temp variable or register to constant values.

### Small Step Operational Semantics of Pseudo Assembly

The dynamic semantics of the pseudo assembly program can be defined using a rule of shape $P \vdash (L, li) \longrightarrow (L', li')$, which reads, given a PA program $P$, the current program context $(L,li)$ is evaluated to $(L', li')$. Note that we use a memory environment and program label instruction pair to denote a program context.

$$
{\tt (pConst)}~~~P \vdash (L, l: d \leftarrow c) \longrightarrow (L \oplus (d,c), P(l+1))
$$
In the ${\tt (pConst)}$ rule, we evaluate an assignment instruction of which the RHS is a constant. We update the value of the LHS in the memory environment as $c$ and move on to the next instruction.
$$
{\tt (pRegister)} ~~~P \vdash (L, l: d \leftarrow r) \longrightarrow (L \oplus (d,L(r)), P(l+1))  
$$

$${\tt (pTempVar)} ~~~P \vdash (L, l: d \leftarrow t) \longrightarrow (L \oplus (d,L(t)), P(l+1))
$$
In the ${\tt (pRegister)}$ and the ${\tt (pTempVar)}$ rules, we evaluate an assignment instruction of which the RHS is a register (or a temp variable). We look up the value of the register (or the temp variable) from the memory environment and use it as the updated value of the LHS in the memory environment. We move on to the next label instruction.

$$
\begin{array}{rc}
{\tt (pOp)} &  \begin{array}{c}
        c_1 = L(s_1) ~~~ c_2 = L(s_2) ~~~ c_3 = c_1\ op\ c_2
        \\ \hline
        P \vdash (L, l: d \leftarrow s_1\ op\ s_2) \longrightarrow (L \oplus (d,c_3), P(l+1))  
        \end{array}
\end{array}
$$

The ${\tt (pOp)}$ rule handles the case where the RHS of the assignment is a binary operation. We first look up the values of the operands from the memory environment. We then apply the binary operation to the values. The result will be used to update the value of the LHS in the memory environment.

$$
\begin{array}{rc}
{\tt (pIfn0)} & \begin{array}{c}
     L(s) = 0
     \\ \hline
     P \vdash (L, l: ifn\ s\ goto\ l') \longrightarrow (L, P(l+1))
     \end{array}
\end{array}
$$

$$
\begin{array}{rc}
{\tt (pIfnNot0)} & \begin{array}{c}
     L(s) \neq  0
     \\ \hline
     P \vdash (L, l: ifn\ s\ goto\ l') \longrightarrow (L, P(l'))
     \end{array}
\end{array}
$$

The rules ${\tt (pIfn0)}$ and ${\tt (pIfnNot0)}$ deal with the conditional jump instruction. We first look up the conditional operand's value in the memory environment. If it is 0, we ignore the jump and move on to the next instruction, otherwiwse, we perform a jump but changing the program context to the target label instruction..

$$
{\tt (pGoto)} ~~ P \vdash (L, l:goto\ l') \longrightarrow (L, P(l'))
$$

The rule ${\tt (pGoto)}$ jumps to to the target label instruction.

Note that there is no rule for $ret$ as the program execution will stop there.
Further more, the set of rules does not mention the scenario in which the look up of a register (or a temp variable) in the environment fails. In these casse, the program exit with an error.

For example, let $P$ be

```js
1: x <- input
2: s <- 0
3: c <- 0
4: t <- c < x 
5: ifn t goto 9
6: s <- c + s
7: c <- c + 1
8: goto 4
9: rret <- s
10: ret
```

and $input = 1$.

We have the following derivation

```java
P |- {(input,1)}, 1: x <- input ---> # (pTempVar)
P |- {(input,1), (x,1)}, 2: s <- 0 ---> # (pConst)
P |- {(input,1), (x,1), (s,0)}, 3: c <- 0 ---> # (pConst)
P |- {(input,1), (x,1), (s,0), (c,0)}, 4: t <- c < x ---> # (pOp)
P |- {(input,1), (x,1), (s,0), (c,0), (t,1)}, 5: ifn t goto 9 ---> # (pIfn0)
P |- {(input,1), (x,1), (s,0), (c,0), (t,1)}, 6: s <- c + s ---> # (pOp)
P |- {(input,1), (x,1), (s,0), (c,0), (t,1)}, 7: c <- c + 1 ---> # (pOp)
P |- {(input,1), (x,1), (s,0), (c,1), (t,1)}, 8: goto 4 ---> # (pGoto)
P |- {(input,1), (x,1), (s,0), (c,1), (t,1)}, 4: t <- c < x ---> # (pOp)
P |- {(input,1), (x,1), (s,0), (c,1), (t,0)}, 5: ifn t goto 9 ---> # (pIfn1)
P |- {(input,1), (x,1), (s,0), (c,1), (t,0)}, 9: rret <- s ---> # (pTempVar)
P |- {(input,1), (x,1), (s,0), (c,1), (t,0), (rret, 0)}, 10: ret
```

### Formal Results

#### Definition: Consistency of the memory environments

Let $\Delta$ be a SIMP memory environment and $L$ be a pseudo assembly memory environment.
We say $\Delta$ is consistent with $L$ (written $\Delta \Vdash L$), iff

1. $\forall (x,v) \in \Delta$, $(x,conv(v)) \in L$, and
1. $\forall (y,u) \in L$, $(y, v) \in \Delta$ where $u=conv(v)$.

#### Lemma: Correctness of the Maximal Munch Algorithm

Let $S$ and $S'$ be SIMP program statements.
Let $\Delta$ and $\Delta'$ be SIMP memory environments such that $(\Delta, S) \longrightarrow (\Delta', S')$.
Let $P$ be a pseudo assembly program such that $G_s(S) = P$.
Let $L$ and $L'$ be pseudo assembly memory enviornments.
Let $\Delta \Vdash L$.
Then we have $P \vdash (L, l:i) \longrightarrow (L', l':i')$ and $\Delta' \Vdash L'$

##### Proof

Since the $S$ could be a non-terminating program, the derivation via small step operational semantics could be infinite. We need a co-inductive proof, which is beyond the scope of this module. We will only discuss about this when we have time.

### What about big step operational semantics of Pseudo Assembly?

As Pseudo Assembly is a flatten language with goto statement, there is no nesting of statement or expression. There is no much value in defining the big step operatnal semantics, i.e. there is no way to "fast-forward" a sub statement / a sub expression per se.

If you are interested in details of big step operational semantics, you may refer to this paper, which presented the operational and denotational semantics with a language with GOTO (more structures than our Pseudo Assembly.)

```
https://link.springer.com/article/10.1007/BF00264536
```

## Denotational Semantics (Optional Materials)

Next we briefly discuss another form of dynamic semantics specification.
Denotational Semantics aims to provide a meaning to a program.
The "meaning" here is to find the result returned by the program.
Now we may argue that is it the same as the big step operational semantics?
There is some difference between the denotational semantics and big step operational semantics. We will defer the discussion and comparison towards the end of this unit.

In denotational semantics, the "meaning" of a program is given by a set of semantic functions.
These functions are mapping program objects from the syntactic domain to *math* objects in the semantic domain.

### Syntactic Domains

In many cases, the syntactic domains are defined by the grammar rules.

For SIMP program, we have the following syntactic domains.

1. $S$ denotes the domain of all valid single statement
1. $E$ denotes the domain of all valid expressions
1. $\overline{S}$ denotes the domain of all valid sequence statements
1. $OP$ denotes the domain of all valid operators.
1. $C$ denotes the domain of all constant values.
1. $X$ denotes the domain of all variables.

### Semantic Domains

1. $Int$ denotes the set of all integers values
1. $Bool$ denotes the set of $\{true, false\}$
1. Given that $D_1$ and $D_2$ are domains, $D_1 \times D_2$ denotes the cartesian product of the two.
1. Given that $D_1$ and $D_2$ are domains, $D_1 \cup D_2$ denotes the union and $D_1 \cap D_2$ denotes the intersection.
1. Given that $D_1$ and $D_2$ are domains, $D_1 \rightarrow D_2$ denotes a functional mapping from domain $D_1$ to domain $D_2$.
    * Note that $D_1 \rightarrow D_2 \rightarrow D_3$ is intepreted as $D_1 \rightarrow (D_2 \rightarrow D_3)$.
1. Given that $D$ is a domain, ${\cal P}(D)$ denots the power set of $D$.

### Denotational Semantics for SIMP expressions

The denotational semantics for the SIMP expression is defined by the following semantic functions.

Let $\Sigma = {\cal P} (X \times (Int\cup Bool))$

$$
\begin{array}{lll}
{\mathbb E}\llbracket \cdot \rrbracket\  :\  E  &\rightarrow&\  \Sigma \rightarrow (Int \cup Bool) \\
{\mathbb E}\llbracket X \rrbracket & = & \lambda\sigma.\sigma(X) \\
{\mathbb E}\llbracket c \rrbracket & = & \lambda\sigma. c \\
{\mathbb E}\llbracket E_1\ OP\ E_2 \rrbracket & = &\lambda\sigma.  {\mathbb E}\llbracket E_1\rrbracket\sigma\ \llbracket OP \rrbracket\  {\mathbb E}\llbracket E_2\rrbracket\sigma\\\
\end{array}
$$

The signature of the semantic function indicates that we map a SIMP expression into a function that takes a memory environment and returns a contant value.

Implicitly, we assume that there exists a builtin semantic function that maps operator symbols to the (actual) semantic operators, i.e., $\llbracket + \rrbracket$ gives us the sum operation among two integers.  Sometimes we omit the parenthesis for function application when there is no ambiguity, e.g. ${\mathbb E}\llbracket E\rrbracket\sigma$ is the short hand for
$({\mathbb E}\llbracket E\rrbracket)(\sigma)$

As we observe, ${\mathbb E}\llbracket \cdot \rrbracket$ takes an object from the expression syntactic domain and a memory store object from the domain of $\Sigma$, returns a value frmo the union of $Int$ and $Bool$ semantic domains.

### Denotational Semantics for SIMP statements

To define the denotational semantics, we need some extra preparation, in order to support non-terminating programs.

Let $\bot$ be a special element, called *undefined*, that denotes failure or divergence.
Let $f$ and $g$ be functions, we define
$$
\begin{array}{rcl}
f \circ_\bot g & = & \lambda \sigma. \left [ \begin{array}{cc}
                  \bot & g(\sigma) = \bot \\
                  f(g(\sigma)) & otherwise
                 \end{array} \right .
\end{array}
$$
which is a function composition that propogates $\bot$ if present.
Now we define the semantic function for SIMP statements.
$$
\begin{array}{lll}
{\mathbb S}\llbracket \cdot \rrbracket :   \overline{S}  & \rightarrow\ & \Sigma \ \rightarrow \ \Sigma \cup \{ \bot \} \\
{\mathbb S} \llbracket  nop \rrbracket& = & \lambda\sigma. \sigma \\
{\mathbb S} \llbracket return\ X \rrbracket& = & \lambda\sigma. \sigma \\
{\mathbb S} \llbracket  X = E \rrbracket& = & \lambda\sigma. \sigma \oplus (X, {\mathbb E}\llbracket E \rrbracket\sigma) \\
{\mathbb S} \llbracket S \overline{S} \rrbracket& = & {\mathbb S} \llbracket \overline{S} \rrbracket \circ_\bot {\mathbb S} \llbracket S \rrbracket\\
{\mathbb S} \llbracket if \ E\ \{\overline{S_1}\} \ else\ \{\overline{S_2} \} \rrbracket& = & \lambda\sigma. \left [ \begin{array}{cc}
                    {\mathbb S} \llbracket \overline{S_1} \rrbracket\sigma  & {\mathbb E}\llbracket E \rrbracket\sigma = true \\
                    {\mathbb S} \llbracket \overline{S_2} \rrbracket\sigma & {\mathbb E}\llbracket E \rrbracket\sigma = false \\
                \end{array} \right . \\
{\mathbb S} \llbracket while \ E\ \{\overline{S}\} \rrbracket& = & fix(F) \\
 {\tt where}\ &  & F= \lambda g.\lambda\sigma. \left [ \begin{array}{cc}
                    (g \circ_\bot {\mathbb S} \llbracket \overline{S} \rrbracket)(\sigma)  & {\mathbb E}\llbracket E \rrbracket\sigma = true \\
                    \sigma & {\mathbb E}\llbracket E \rrbracket\sigma = false \\
                \end{array} \right . \\
\end{array}
$$

The signature of the semantic function indicates that we map a SIMP statement into a function that takes a memory environment and returns another memory environment or divergence.

In case of $nop$ and return statement, the semantic function returns an identiy function.
In case of an assignment, the semantic function takes an memory environment object and update the binding of $X$ to the meaning of $E$.
In case of sequence statements, the semantic function returns a $\bot$-function composition of the semantic function of the leading statement and the semantic function of the the trailing statements.
In case of if-else statement, the semantic function returns the semantics of the then or the else branch statement depending on the meaning of the condition expression.
In case of while statement, the semantic function returns a fixed point function. This is due to the fact that the underlying domain theory framework we are using does not support recursion. Hence a fixed point operator $fix$ is used, which is kind of like recursion, (as we learnd in lambda caluclus), and it is more expresive as it gives a fixed term notiation for a sequence of infinitely many function objects applications. To help our understanding, we give a **cheating version** as if recursive function is supported in the underlying domain theory framework and we are allow to refer to a function application as a name function, we would have

$$
\begin{array}{lll}
{\mathbb S} \llbracket while \ E\ \{\overline{S}\} \rrbracket& = & \lambda\sigma. \left \{ \begin{array}{cc}
                    ({\mathbb S} \llbracket while \ E\ \{\overline{S}\}\rrbracket  \circ_\bot {\mathbb S} \llbracket \overline{S} \rrbracket)(\sigma)  & {\mathbb E}\llbracket E \rrbracket\sigma = true \\
                    \sigma & {\mathbb E}\llbracket E \rrbracket\sigma = false \\
                \end{array} \right . \\
\end{array}
$$
which means the function $g$ in the earlier version is a recursive reference to ${\mathbb S} \llbracket while \ E\ \{\overline{S}\} \rrbracket$

For example, let $\sigma = \{ (input, 1)\}$

$$
\begin{array}{ll}
& {\mathbb S} \llbracket x=input; s = 0; c=0; while\ c < x \{s = c + s; c = c + 1;\}return\ s; \rrbracket \sigma \\
= & ({\mathbb S} \llbracket s = 0; c=0; while\ c < x \{s = c + s; c = c + 1;\}return\ s; \rrbracket \circ_\bot {\mathbb S} \llbracket x=input \rrbracket) (\sigma) \\
= & {\mathbb S} \llbracket s = 0; c=0; while\ c < x \{s = c + s; c = c + 1;\}return\ s; \rrbracket \sigma_1 \\
= & ({\mathbb S} \llbracket c=0; while\ c < x \{s = c + s; c = c + 1;\}return\ s; \rrbracket \circ_\bot {\mathbb S} \llbracket s=0 \rrbracket) (\sigma_1) \\
= & {\mathbb S} \llbracket c=0; while\ c < x \{s = c + s; c = c + 1;\}return\ s; \rrbracket \sigma_2 \\
= & ({\mathbb S} \llbracket while\ c < x \{s = c + s; c = c + 1;\}return\ s; \rrbracket \circ_\bot {\mathbb S} \llbracket c=0 \rrbracket) (\sigma_2) \\
= & {\mathbb S} \llbracket while\ c < x \{s = c + s; c = c + 1;\}return\ s; \rrbracket \sigma_3 \\
= & ({\mathbb S} \llbracket return\ s; \rrbracket \circ_\bot {\mathbb S} \llbracket while\ c < x \{s = c + s; c = c + 1;\} \rrbracket) (\sigma_3) \\
= & ({\mathbb S} \llbracket return\ s; \rrbracket \circ_\bot {\mathbb S} \llbracket while\ c < x \{s = c + s; c = c + 1;\} \rrbracket \circ_\bot{\mathbb S} \llbracket s = c + s; c = c + 1; \rrbracket) (\sigma_3) \\
= & ({\mathbb S} \llbracket return\ s; \rrbracket \circ_\bot {\mathbb S} \llbracket while\ c < x \{s = c + s; c = c + 1;\} \rrbracket)(\sigma_4) \\
= & {\mathbb S} \llbracket return\ s; \rrbracket\sigma_4 \\
= & \sigma_4
\end{array}
$$

where
$$
\begin{array}{l}
\sigma_1 = \sigma \oplus (x,1) = \{ (input,1), (x,1) \} \\
\sigma_2 = \sigma_1 \oplus (s,0)  = \{ (input,1), (x,1), (s,0) \} \\
\sigma_3 = \sigma_2 \oplus (c,0)  = \{ (input,1), (x,1), (s,0), (c,0) \}\\
\sigma_4 = \sigma_3 \oplus (s,0) \oplus (c,1)  = \{ (input,1), (x,1), (s,0), (c,1) \}\\
\end{array}
$$

Let's consider another example of a non-terminating program, we can't use the *cheating version* here as it would gives the infinite sequence of function compositions.
Let $\sigma = \{(input, true)\}$

$$
\begin{array}{ll}
& {\mathbb S} \llbracket while\ input \{nop;\}return\ input; \rrbracket \sigma \\
= & fix(F) \sigma \\
= & \bot
\end{array}
$$

where

$$
\begin{array}{l}
F = \lambda g.\lambda\sigma. \left [ \begin{array}{cc}
                    (g \circ_\bot {\mathbb S} \llbracket nop \rrbracket)(\sigma)  & {\mathbb E}\llbracket input \rrbracket\sigma = true \\
                    \sigma & {\mathbb E}\llbracket input \rrbracket\sigma = false \\
                \end{array} \right . \\
\end{array}
$$

Since ${\mathbb E}\llbracket input \rrbracket\sigma$ is always $true$,

$$
F = \lambda g.\lambda\sigma.(g \circ_\bot {\mathbb S} \llbracket nop \rrbracket)(\sigma)  
$$

With some math proof, we find that $fix(F)$ is function of type $\Sigma \rightarrow \bot$. We won't be able to discuss the proof until we look into lattice theory in the upcoming classes.

In simple term, using the $fix$ operator to define the while statement denotational semantics allows us to "collapse" the infinite sequence of function composition/application into a fixed point, which is a non-terminating function.

### Denotational Semantics vs Big Step operational Semantics vs Small Step Semantics

|   | support non-terminating programs  | don't support non-terminating programs  |
|---|---|---|
| focused on the step by step derivation | Small Step Operational Semantics |   |
| focused on the returned results |  Denotational Semantics | Big Step Operational Semantics

Denotational Semantics is often used characterizing programming language model in a compositional way. It allows us to relates syntax objects to semantic objects. For example, if we want to argue that two languages are equivalent, we can map their syntax objects into the same semantic objects. We could also use denotational semantics to reason about concurrency.

#### Extra readings for denotational semantics

```
https://web.eecs.umich.edu/~weimerw/2008-615/lectures/weimer-615-07.pdf
https://homepage.divms.uiowa.edu/~slonnegr/plf/Book/Chapter9.pdf
```
