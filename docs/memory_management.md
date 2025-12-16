# 50.054 - Memory Management

## Learning Outcomes

1. Extend PA to support function call and array operations
1. Extend the dynamic semantics to model the run-time memory operations
1. Define activation records
1. Extend SIMP to support function call and array operations
1. Describe the challenges of memory management
1. Apply linear type system to ensure memory saftey in SIMP.


## Pseudo Assembly (Extended)

So far, we have been dealing with a toy language without function call nor complex data structure. We consider extending the [Pseudo Assembly language syntax](./ir_pseudo_assembly.md#pseudo-assembly) as follows




$$
\begin{array}{rccl}
(\tt Instruction)   & i   & ::= & ... \mid begin\ f\ d \mid call\ f\ s \mid d \leftarrow alloc\ s \mid free\ s  \\ 
& &  & \mid  d \leftarrow ref\ s \mid deref\ s\ s\\ 
\end{array}
$$

Besides the existing instructions, we include

* $begin\ f\ d$ - denotes the start of a function name $f$ ($f$ is a variable) and the formal argument (operand) $d$. 
* $call\ f\ s$ - denotes a function invocation of $f$ with actual argument $s$.
* $d \leftarrow alloc\ s$ - denotes the memory allocation. It allocates $s$ bytes of unoccupied memory and assigns the reference address to $d$. 
* $free\ s$ - deallocates the allocated memory at address stored in $s$. 
* $d \leftarrow ref\ s$ - references the value at the memory address stored in $s$ and copies it to $d$. 
* $deref\ s_1\ s_2$ - dereferences the memory location stored in $s_1$ and updates with the value of $s_2$. 


### Operational Semantics for Extended PA

We extend the operational semantics of Pseudo Assembly defined in [here](./dynamic_semantics.md#operational-semantics-of-pseudo-assembly). Instead of mixing the temp variable-to-constant mappings and register-to-constant mappings in $L$, we move the register-to-constant mappings in $R$. 


$$
\begin{array}{rccl}
(\tt PA\ Stack\ Frame) & L & \subseteq & (t \times c) \\ 
(\tt PA\ Register\ Environment) & R & \subseteq & (r \times c) \\ 
(\tt PA\ Heap\ Registry) & G & \subseteq & (loc \times loc ) \\ 
(\tt PA\ Heap\ Memory) & H & \subseteq & (loc \times c) \\ 
(\tt Heap\ Address) & loc & ::= & loc(1) \mid ... \mid loc(n) \\ 
(\tt PA\ Memory\ Environment) & M & ::= & (\overline{L}, \overline{l}, H, G, R) 
\end{array}
$$

* $G$ - denotes a set of address tuples. The first address in the tuple denotes the starting address of the allocated memory in the heap (inclusive) and the second one denotes the ending address (exclusive).
* $H$ - denotes the mapping from addresses to constants. $G$ and $H$ together model the run-time heap memory
* $M$ - a tuple of 5 items. A stack of stack frames $\overline{L}$, a stack of function invocation labels $\overline{l}$ (a sequence of labels marking the function calling instructions), the heap and the register environment. $\overline{L}$ and $\overline{l}$ should have the same size. Given an index $i$, the $i$-th elements in $\overline{L}$ and $\overline{l}$ form the *activation record*.

The small step operational semantic rules in shape $P \vdash (L, li) \longrightarrow (L, li)$ introduced in our earlier [class](./dynamic_semantics.md#operational-semantics-of-pseudo-assembly) are modified to have shape of $P \vdash (M, li) \longrightarrow (M, li)$.  

We highlight the important rules


$$
\begin{array}{cc}
{\tt (pAlloc)} &  \begin{array}{c}
        M = (L:\overline{L}, \overline{l}, H, G, R) \ \ \ \ 
        findfree(G,L(s)) = loc \\ 
        H' = H\cup[(loc + i, 0) \mid i \in \{0, L(s)-1\}] \ \ \ G' = G \cup[(loc, loc+L(s))] \\ 
        M' = (L\oplus(d,loc):\overline{L}, \overline{l}, H', G',  R)
        \\ \hline
        P \vdash (M, l: d \leftarrow alloc\ s) \longrightarrow (M', P(l+1))  
        \end{array} \\ \\ 
{\tt (pFree)} & \begin{array}{c}
        M = (L:\overline{L}, \overline{l}, H, G, R) \ \ \ \ loc = L(s) \\ 
        G'\cup[(loc,loc')] = G \ \ \ \ H' = H - \{ loc, ..., loc' \} \ \ \ \
        M' = (L:\overline{L}, \overline{l}, H', G', R) \\ \hline
        P \vdash (M, l: free\ s) \longrightarrow (M', P(l+1))
        \end{array} \\ \\ 
{\tt (pRef)} & \begin{array}{c}
        M = (L:\overline{L}, \overline{l}, H, G, R) \ \ \ \ loc = L(s) \\ 
        \exists (loc_1, loc_2) \in G. loc_1 \leq loc < loc_2 \\ 
        v = H(loc) \ \ \ M' = (L\oplus(d,v):\overline{L}, \overline{l}, H, G, R)
        \\ \hline
        P \vdash ( M, l: d \leftarrow ref\ s) \longrightarrow (M', P(l+1))
        \end{array} \\ \\ 
{\tt (pDeref)} & \begin{array}{c} 
        M = (L:\overline{L}, \overline{l}, H,G, R) \ \ \ \ loc = L(s_1) \\
        \exists (loc_1, loc_2) \in G. loc_1 \leq loc < loc_2 \\ 
        H' = H \oplus (loc, L(s_2)) \ \ \ M' = (L:\overline{L}, \overline{l}, H', G, R)\\ \hline
        P \vdash (M ,l: deref\ s_1\ s_2) \longrightarrow (M', P(l+1))
        \end{array}
\end{array} 
$$

* The rule $(\tt pAlloc)$ defines the memory allocation routine. Given the asking size, $L(s)$, we make use of the run-time built-in function $findfree()$ to locate the starting address of the free memory region. We save the starting address in $d$, and "zero-out" the allocated region addresses ranging from $loc$ to $loc+L(s)$. 
* The rule $(\tt pFree)$ defines the memory deallocation routine. Given the starting address of the memory to be freed $loc$, we remove the pair $(loc, loc')$ from $G$ and the keys in the range $(loc, loc')$  from $H$.
* The rule $(\tt pRef)$ defines the memory reference operation. Given the referenced address $loc$, we ensure the address is in $G$ (which implies it is in $H$). We store the value $H(loc)$  into the stack frame and move onto the next instruction. 
* The rule $(\tt pDeref)$ defines the memory deference operation. Given the dereferenced address $loc$, we ensure the address is in $G$ (which implies it is in $H$). We update the value in $H$ at location $loc$ to $L(s_2)$.


$$
\begin{array}{rc}
{\tt (pCall)} &  \begin{array}{c}
        l': begin\ f\ d' \in P \ \ \ M = (L:\overline{L}, \overline{l}, H, G, R) \\ 
        M' = (\{(d', L(s))\}:L:\overline{L}, l:\overline{l}, H, G, R)
        \\ \hline
        P \vdash (M, l: d \leftarrow call\ f\ s) \longrightarrow (M', P(l'+1))  
        \end{array} \\ \\ 
{\tt (pBegin)} & \begin{array}{c}
        (l':ret) \in P \ \ \ \forall (l'':ret) \in P: l''>= l \implies l'' >= l'
        \\ \hline
        P \vdash (M, l:begin\ f\ d) \longrightarrow (M, P(l'+1)) 
        \end{array} \\ \\ 
{\tt (pRet1)} &  \begin{array}{c}
        M = (L':L:\overline{L}, l':\overline{l}, H, G, R)\ \ \ 
        l': d \leftarrow call\ f\ s \in P \\  
        R' = R - {r_{ret}} \ \ \ 
        M' = (L\oplus(d,R(r_{ret})):\overline{L}, \overline{l}, H, G, R')
        \\ \hline
        P \vdash (M, l:ret) \longrightarrow (M', P(l'+1))  
        \end{array} \\ \\ 
{\tt (pRet2)} &  \begin{array}{c}
        M = (\overline{L}, [], H, G, R)\ \ \ 
        \\ \hline
        P \vdash (M, l:ret) \longrightarrow exit(R(r_{ret}))
        \end{array} 
\end{array}
$$

* The rule $(\tt pCall)$ handles the function call instruction. In this case, we search for the begin statement of the callee. We push the new stack frame into the stack with the binding of the input argument. We push the caller's label into the labels stack. The executation context is shifted to the function body instruction. 
* The rule $(\tt pBegin)$ processes the begin instruction. Since it is the defining the function, we skip the function body and move to the instruction that follows the return instruction. 
* The rule $(\tt pRet1)$ manages the termination of a function call. We pop the stack frame and the top label $l'$ from the stack. We search for the caller instruction by the label $l'$. We update the caller's stack frame with the returned value of the function call. 
* The rule ${\tt pRet2}$ defines the termination of the entire program.

We omit the rest of rules as we need to change the $L$ to $M = (L:\overline{L}, \overline{l}, H, G, R)$.

For example given a PA program 

```java
// PA1
1: begin plus1 x
2: y    <- x + 1
3: rret <- y
4: ret
5: z    <- call plus1 0 
6: rret <- z
7: ret
```

We have the following derivation

```java
P |- ([[]], [], [], [], []), 1: begin plus1 x  ---> # (pBegin)
P |- ([[]], [], [], [], []), 5: z <- call plus1 0 ---> # (pCall) 
P |- ([[(x,0)],[]],[5], [], [], []), 2: y <- x + 1 ---> # (pOp)
P |- ([[(x,0),(y,1)],[]],[5], [], [], []), 3: rret <- y ---> # (pTempVar)
P |- ([[(x,0),(y,1)],[]],[5], [], [], [(rret,1)], 4: ret  ---> # (pRet1)
P |- ([[(z,1)]],[], [], [], []), 6: rret <- z ---> # (pTempVar) 
P |- ([[(z,1)]],[], [], [], [(rret,1)]) 7: ret ---> # (pRet2)
P |- exit()
```


### (Optional Content) Call Stack Design in Target Platform 

The call stack in the target platform is often implemented as a sequence of memory locations. The bottom of the stack has the lowest address of the entire stack and the top of the stack has the highest address (at a particular point in time.)

|   |
|---|
|frame for `main()`|
|frame for `plus1(x)`|
| ... |

If we zoom into the frame for `plus1(x)` 

| address | content |
|---|---|
| fp-4 | param x | 
| fp | caller label/return address | 
| fp+4 | tempvar y |

the frame pointer `fp` marks the memory address where ther caller's label/address is stored. If we subtract the parameter size offset from `fp`, say `fp-4`, we can access the paramter `x` and if we add the variable size offset to `fp`, we access the temp variables, in this case we can statically determine the size of the call frame, as 3 * 4 bytes. As a convention, the `begin` instruction in the target code is associated with the frame size required by this function.  When we make a function call in the target code, we have to push the parameter into the call stack one by one. 

i.e. the instruction `5` in the above example `PA1` should be broken into 

```java
5.1 param 0
5.2 call plus1
5.3 popframe 12
```

* At 5.1, we push the actual argument as the parameter `x`. 
* At 5.2, we call the function and shift the program counter to the starting label/address of the function body.
* When the function terminates, we jump back to 5.2, then at 5.3, we pop the stack frame based on its size.

In case a function has multiple parameters, the parameters are pushed from 
right to left. 

For example, if we have a `min(x,y)` function which has no local variable and we call `min(-10,9)`, we generate the following target code

```java
1: param 9
2: param -10
3: call min
4: popframe 12
```

### Another example with heap memory access

The following PA program is an example of using the memory from the heap. 

```java
// PA2 
1:  begin range x 
2:  s <- 4 * x
3:  a <- alloc s
4:  i <- 0
5:  t <- i < x 
6:  ifn t goto 11
7:  ai <- a + i
8:  deref ai i 
9:  i <- i + 1
10: goto 5
11: rret <- a
12: ret
13: r <- call range 3
14: y <- ref r 2
15: free r
16: rret <- y
17: ret
```

Instructions 1-12 define the `range(x)` function, which initializes an array with the given size `x` and the values are from `0` to `x`. Lines 13-14 invoke the function and access the 3rd element. Line 15 frees the memory.

#### Cohort Exercise 
As an exercise, can you work out the derivation of "running" the above program `PA2` using the operational semantics?


## SIMP (extended with function and array)


We consider syntax of the [SIMP language](./ir_pseudo_assembly.md#the-simp-language) extended with function and array.

$$
\begin{array}{rccl}
(\tt Statement) & S & ::= & ... \mid X[E] = E  \mid free\ X \\ 
(\tt Expression) & E & ::= & ... \mid f(E) \mid T[E] \mid X[E] \\
(\tt Function\ Declaration) & D & ::= & func\ f\ (x:T)\ T\ \{\overline{S}\} \\ 
(\tt Constant) & C & ::= & 0 \mid 1 \mid 2 \mid ... \mid true \mid false \\ 
(\tt Type) & T & ::= & ... \mid [T] \mid T \rightarrow T \mid unit \\ 
(\tt Value) & V & ::= & C \mid D \mid (loc, loc) \mid unit \\
(\tt Program) & P & ::= & \overline{D};\overline{S}
\end{array}
$$

New statement syntax includes:

* $X[E] = E$ - denotes an array element assignment statement
* $free\ X$ - dellocate the array referenced by variable $X$. 

New expression syntax includes

* $f(E)$ - function application, where $f$ is a function name (a special variable)
* $T[E]$ - array initialization, where $T$ is the element type of the array and $E$ denotes the size of the array.
* $X[E]$ - array element dereference, where $X$ is an array and $E$ is the element index. 

Function declaration syntax includes

* $func\ f\ (x:T)\ T\ \{\overline{S}\}$ - $f$ is the function name; $(x:T)$ is the formal parameter and its type. The second $T$ is the return type. $\overline{S}$ is the body.

New type sytanx includes

* $[T]$ - array type
* $T \rightarrow T$ - function type
* $unit$ - the type has only one value $unit$ (its role is similar to the $void$ type in Java and C)

Value syntax includes

* $C$ - constant
* $D$ - declaration
* $(loc, loc)$ - memory segment, the first item is the starting address (inclusive) and the second item is the ending address (exclusive)
* $unit$ - the only value for the $unit$ type.

A SIMP program is a sequence of function declarations followed by a sequence of statements. 

For example, the following SIMP program is equivalent to Pseudo Assembly program `PA1` introduced earlier.

```java
// SIMP1 
func plus1 (x:int) int {
    y = x + 1;
    return y;
}
z = plus1(0);
return z;
```

The following SIMP program is equivalent to Pseudo Assembly program `PA2`

```java
// SIMP2 array enumeration
func range(x:int) [int] {
    a = int[x];
    i = 0;
    while i < x {
        a[i] = i;
        i = i + 1;
    }
    return a;
}
r = range(3); 
y = r[2];
free r;
return y;
```



## Operational Semantic of extended SIMP

For brevity, we consider the big step operational semantics of extended SIMP by extending the [rules](./dynamic_semantics.md#big-step-operational-semantics).


$$
\begin{array}{rccl}
(\tt SIMP\ Var\ Environment) & \Delta & \subseteq & (X \times V) \\ 
(\tt SIMP\ Obj\ Environment) & \rho & \subseteq & (loc \times V)
\end{array}
$$

First and foremost, in the extended SIMP, values include function declarations, memory tuples and unit, besides constants. Hence the $\Delta$ environment maps variables to values. 
Besides the variable environment $\Delta$, we define the object (heap) environment $\rho$ as a mapping from memory location to values.

### Big Step Operational Semantics for extended SIMP expression

The rules of shape $\Delta \vdash E \Downarrow C$ have to be adapted to the shape of $\overline{\Delta} \vdash (\rho, E) \Downarrow (\rho', V)$, where $\overline{\Delta}$ is the stack of variable environments.

For example, the $(\tt bVar)$ rule is updated as follows

$$
{\tt (bVar)} ~~~~ \Delta:\overline{\Delta} \vdash (\rho, X) \Downarrow (\rho,\Delta(X))
$$

The rest of the rules can be easily adapted to the new scheme. Now we consider cases for the new syntax.

$$
{\tt (bApp)} ~~~~ \begin{array}{c}
        \overline{\Delta} \vdash (\rho, E_2) \Downarrow (\rho_2,V_2) \\ 
        (f, func\ f\ (x:T_1)T_2 \{\overline{S}\}) \in \overline{\Delta} \\ 
        \Delta =  \{(x,V_2)\} \ \ \ (\Delta:\overline{\Delta}, \rho_2, \overline{S}) \Downarrow (\Delta':\overline{\Delta'}, \rho_3, return\ y) \ \ \ (y, V)\in \Delta'
        \\ \hline
        \overline{\Delta} \vdash (\rho, f(E_2)) \Downarrow (\rho_3, V)
        \end{array}
$$


In case of a function application, we first evaluate the function argument into a value. We search for the function definition from the variable environment $\overline{\Delta}$ (in the order from the top frame to the bottom frame). A new variable environment (frame) $\Delta$ is created to store the binding between the function's formal argument and the actual argument. We then call the statement evaluation rules (to be discussed shortly) to run the body the of the function.  Finally, we retrieve the returned value from the call.

$$
{\tt (bArrInst)} ~~~~ \begin{array}{c}
        \overline{\Delta} \vdash (\rho, E_2) \Downarrow (\rho_1,V_2) \\ 
        \forall x \in [m, m+V_2). loc(x) \not\in dom(\rho) \\ 
        V = default(T) \ \ \
        \rho' = \rho \cup \{ (loc(x), V) \mid x \in [m, m+V_2) \} 
        \\ \hline
        \overline{\Delta} \vdash (\rho, T[E_2]) \Downarrow (\rho', (loc(m), loc(m+V_2)))
        \end{array}
$$

In case of an array instantiation, we first evaluate the size argument into a value (must be an integer constant).
We find a sequence of unsused memory locations $loc(m)$ to $loc(m+V_2)$ and initialize the value to the default value. 


$$
{\tt (bArrRef)} ~~~~ \begin{array}{c}
        (X, (loc(m_1), loc(m_2))) \in \Delta \\
        \Delta:\overline{\Delta} \vdash (\rho, E_2) \Downarrow (\rho_2, V_2) \ \ \ \
        m_1 + V_2 < m_2
        \\ \hline
        \Delta:\overline{\Delta} \vdash (\rho, X[E_2]) \Downarrow (\rho_2, \rho_2(loc(m_1 + V_2))
        \end{array}
$$

In case of an array reference, we lookup the memory location boundaries of $X$, then
we evaluate $E_2$ into a constant (integer) $V_2$. If the index is within the boundary, we lookup 
the value associated with the address. 

### Big Step Operational Semantics for extended SIMP statement

Similarly, to support the change of SIMP statement,
 we adapt the big step oeprational semantics rule of shape $(\Delta, S) \Downarrow \Delta$ to shape $(\overline{\Delta}, \rho, S) \Downarrow (\overline{\Delta'}, \rho', S')$

For example the assignment statement rule is updated as follows

$$
\begin{array}{rc}
{\tt (bAssign)} & \begin{array}{c}
    \Delta:\overline{\Delta} \vdash (\rho,E) \Downarrow (\rho',V)
    \\ \hline
    (\Delta:\overline{\Delta}, \rho, X = E) \Downarrow (\Delta \oplus (X, V):\overline{\Delta}, \rho', nop)
    \end{array}
\end{array}
$$

 We focus on the new rules and omit the rest of the rules

$$
\begin{array}{rc}
{\tt (bArrDeref)} & \begin{array}{c}
    \Delta:\overline{\Delta} \vdash (\rho,E_1) \Downarrow (\rho_1,V_1) \ \ \ \ 
    \Delta:\overline{\Delta} \vdash (\rho_1,E_2) \Downarrow (\rho_2,V_2) \\ 
    (X, (loc(m_1), loc(m_2))) \in \Delta \ \ \ m_1 + V_1 < m_2 \\ 
    \rho_3 = \rho_2 \oplus (loc(m_1 + V_1), V_2)
    \\ \hline
    (\Delta:\overline{\Delta}, \rho, X[E_1] = E_2) \Downarrow (\Delta:\overline{\Delta}, \rho_3, nop)
    \end{array}
\end{array}
$$

In case of array deference, we first compute the index argument into an integer constant $V_1$. We lookup the memory range $(loc(m_1), loc(m_2))$ of $X$ and ensure that the $m_1 + V_1$ is within range. Evaluating $E_2$ yields the value to be assigned to the memory location $loc(m_1 + V_1)$. Finally we return the updated object memory environment.

$$
\begin{array}{rc}
{\tt (bFree)} & \begin{array}{c}
    (X, (loc(m_1), loc(m_2))) \in \Delta \ \ \ \ \ 
    \rho' \cup \{ (loc(x),V) \mid x \in [m_1, m_2)\} = \rho
    \\ \hline
    (\Delta:\overline{\Delta}, \rho, free\ X) \Downarrow (\Delta - ((X, (loc(m_1), loc(m_2)))):\overline{\Delta}, \rho', nop)
    \end{array}
\end{array}
$$

In case of free statement, we ensure that the argument is a variable that holding some reference to the object envrionment.  We remove the memory assignment from $\rho$ and remove $X$ from $\Delta$. 
(In some system, $X$ is not removed from $\Delta$, which causes the "double-freeing" error.)


### Big Step Operational Semantics for extended SIMP Program

$$
\begin{array}{rc}
{\tt (bProg)} & \begin{array}{c}
        \Delta' = \Delta \oplus(f, func\ f\ (X:T_1)T_2\{\overline{S'}\}) \\
        (\Delta':\overline{\Delta}, \rho, \overline{D};\overline{S}) \Downarrow (\overline{\Delta''}, \rho', return\ X)
        \\ \hline
        (\Delta:\overline{\Delta}, \rho, func\ f\ (X:T_1)T_2\{\overline{S}\}; \overline{D};\overline{S}) \Downarrow (\overline{\Delta''}, \rho', return\ X)
        \end{array} \\ \\ 
{\tt (bSeq)} & \begin{array}{c}
        (\overline{\Delta}, \rho, S) \Downarrow (\overline{\Delta}', \rho', nop) \\
        (\overline{\Delta'}, \rho', \overline{S}) \Downarrow (\overline{\Delta''}, \rho'', return\ X)
        \\ \hline
        \overline{\Delta}, \rho, S;\overline{S}) \Downarrow (\overline{\Delta''}, \rho'', return\ X)
        \end{array}
\end{array}
$$

The above two rules define the execution of a SIMP program and statement sequences. The rule $(\tt bProg)$ records the variable $f$ to function definition binding in $\Delta'$ and we use $\Delta':\overline{\Delta}$ to evaluate the rest of the evaluation. 
The rule $(\tt bSeq)$ evaluates the first statement until it becomes $nop$ and moves on the the rest of the statement.



For example, running the `SIMP1` program yields the following

```python
[{plus1: func plus1 (...)}] |- ({} 0) ⇓ ({},0) (bConst)

(plus1: func plus1 (...)) in {plus1: func plus1 (...)}  [sub tree 1]
--------------------------------------------------------------(bApp)
[{plus1: func plus1 (...)}] |- ({}, plus1(0)) ⇓ ({},1) 
--------------------------------------------------------------------(bAssign)    
[{plus1: func plus1 (...)}], {}, z = plus1(0); ⇓ [{plus1: func plus1 (...), z:1}], {}, nop;    
-------------------------------------------------------------------------(bSeq)
[{plus1, func plus1 (...)}], {}, z = plus1(0); return z; ⇓ [{plus1: func plus1 (...), z:1}], {}, return z
---------------------------------------------------------------------------- (bProg)
[],{}, 
func plus1 (x:int) int {
    y = x + 1;
    return y;
}
z = plus1(0);
return z; ⇓ [{plus1: func plus1 (...), z:1}], {}, return z
```

where sub derivation`[sub tree 1]` is as follows

```python
[{x:0}, {plus1: func plus1 (...)}] |- ({}, x) ⇓ ({}, 0) (bVar)

[{x:0}, {plus1: func plus1 (...)}] |- ({}, 1) ⇓ ({}, 1) (bConst)
------------------------------------------------------------ (bOp)
[{x:0}, {plus1: func plus1 (...)}] |- ({}, x + 1) ⇓ ({}, 1)
-------------------------------------------------------------------------(bAssign)
[{x:0}, {plus1: func plus1 (...)}], {}, y = x + 1; ⇓ [{x:0,y:1}, {plus1: func plus1 (...)}], nop
---------------------------------------------------------------------------------------------(bSeq)
[{x:0}, {plus1: func plus1 (...)}], {}, y = x + 1; return y; 
⇓ [{x:0,y:1}, {plus1: func plus1 (...)}], {}, return y;
```

#### Cohort Exercise 
As an exercise, can you work out the derivation of "running" the program `SIMP2` using the big step operational semantics?




## SIMP to PA conversion (Extended)


We consider the update to the [maximal munch algorithm](./ir_pseudo_assembly.md#maximal-munch-algorithm-v2). 

$$ 
\begin{array}{rc}
{\tt (m2App)} & \begin{array}{c} 
          G_e(E_2) \vdash (\hat{e_2}, \check{e_2} ) \\ 
          t \ {\tt is\ a\ fresh\ variable} \\
          l \ {\tt is\ a\ fresh\ label} 
          \\ \hline
          G_e(f(E_2)) \vdash (t, \check{e_2} + [l: t\leftarrow call\ f\ \hat{e}]) 
          \end{array} 
\end{array}  
$$

The ${\tt (m2App)}$ rule converts a function application expression to PA instructions.

$$ 
\begin{array}{rc}
{\tt (m2ArrRef)} & \begin{array}{c} 
          G_e(E_2) \vdash (\hat{e_2}, \check{e_2} ) \\ 
          t, t' \ {\tt are\ fresh\ variables} \\
          l, l' \ {\tt are\ fresh\ labels} 
          \\ \hline
          G_e(X[E_2]) \vdash (t', \check{e_2} + [l: t\leftarrow X + \hat{e_2}, l': t' \leftarrow deref\ t]) 
          \end{array} 
\end{array}  
$$

The ${\tt (m2ArrRef)}$ rule converts an array reference expression to PA instructions.


$$ 
\begin{array}{rc}
{\tt (m2ArrInst)} & \begin{array}{c} 
          G_e(E_2) \vdash (\hat{e_2}, \check{e_2} ) \ \ \ c \ {\tt is\ the size\ of\ } T\\ 
          t, t' \ {\tt are\ fresh\ variables} \\
          l, l' \ {\tt are\ fresh\ labels} 
          \\ \hline
          G_e(T[E_2]) \vdash (t', \check{e_2} + [l: t\leftarrow c * \hat{e_2}, l': t' \leftarrow alloc\ t]) 
          \end{array} 
\end{array}  
$$

The ${\tt (m2ArrInst)}$ rule converts an array instanstiation expression to PA instructions. Note that we assume that
we can assess the size of $T$ in bytes.

$$ 
\begin{array}{rc}
{\tt (m2ArrDeref)} & \begin{array}{c} 
          G_e(E_1) \vdash (\hat{e_1}, \check{e_2}) \ \ \ \ G_e(E_2) \vdash (\hat{e_2}, \check{e_2}) \\
          l, l'  {\tt\ are\ fresh\ labels}  \ \ \ t \ {\tt is\ a fresh\ variable} \\ \hline
          G_s(X[E_1] = E_2) \vdash \check{e_1} + \check{e_2} + [l: t \leftarrow X + \hat{e_1}, l': deref\ t\ \hat{e_2}]
          \end{array} 
\end{array}  
$$

The ${\tt (m2ArrDeref)}$ rule converts an array derference assignment statement to PA instructions. 


$$ 
\begin{array}{rc}
{\tt (m2FuncDecl)} & \begin{array}{c} 
          l  {\tt\ is\ a fresh\ label} \ \ \ G_s(\overline{S}) \vdash lis
          \\ \hline
          G_d(func\ f(X:T_1)T_2 \{\overline{S}\}) \vdash [l:begin\ f\ x] + lis 
          \end{array} 
\end{array}  
$$

The ${\tt (m2FuncDecl)}$ rule converts a function declaration into PA instructions.

Applying the above algorithm to `SIMP1` yields `PA1` and applying to `SIMP2` produces `PA2`. 


## Extend SIMP Type checking

We consider extending the [static semantic (type checking)](./static_semantics.md#type-checking-for-simp) of SIMP to support function and array.

### Type Checking SIMP Expression (Extended) 

Let's consider the type checking rules for the new SIMP expressions. Overall the type rule shape remains unchanged. Recall

$$
\begin{array}{rc}
{\tt (tArrRef)} & \begin{array}{c} 
          (X, [T]) \in \Gamma \ \ \ \ \Gamma \vdash E_2 : int
          \\ \hline
          \Gamma \vdash X[E_2] : T 
          \end{array} 
\end{array}  
$$

In the rule $(\tt tArrRef)$ we type check memory reference expression. We validate $X$'s type is an array type and $E_2$'s type must be an $int$ type.


$$
\begin{array}{rc}
{\tt (tArrInst)} & \begin{array}{c} 
          \Gamma \vdash E_2 : int
          \\ \hline
          \Gamma \vdash T[E_2] : [T] 
          \end{array} 
\end{array}  
$$

The rule $(\tt tArrInst)$ defines the type checking for array instantiation. The entire expression is of type $[T]$ if the size argument $E_2$ is of type $int$.

$$
\begin{array}{rc}
{\tt (tApp)} & \begin{array}{c} 
          \Gamma \vdash f : T_1 \rightarrow T_2 \ \ \ \ \Gamma \vdash E_2 : T_1
          \\ \hline
          \Gamma \vdash f(E_2) : T_2
          \end{array} 
\end{array}  
$$

The rule $(\tt tApp)$ defines the type checking for function application. The entire expression is of type 
$T_2$ if $f$ has type $T_1 \rightarrow T_2$ and $E_2$ has type $T_1$.

$$
\begin{array}{rc}
{\tt (tUnit)} & \begin{array}{c} 
          \Gamma \vdash unit : unit
          \end{array} 
\end{array}
$$

The rule $(\tt tUnit)$ defines the type checking for unit value.

### Type Checking SIMP Statement (Extended) 


For the extended SIMP statement type checking, we need to adjust the typing rules of shape $\Gamma \vdash S$ to $\Gamma \vdash S : T$. 

We adjust the typing rules for the standard statements as follows.

$$
\begin{array}{rc}
{\tt (tAssign)} & \begin{array}{c} 
          \Gamma \vdash E : T \ \ \ \ \Gamma \vdash X : T
          \\ \hline
          \Gamma \vdash X = E : unit
          \end{array} \\ \\ 
{\tt (tNop)} & \begin{array}{c} 
          \Gamma \vdash nop : unit
          \end{array} \\ \\ 
{\tt (tReturn)} & \begin{array}{c} 
          \Gamma \vdash X : T
          \\ \hline
          \Gamma \vdash return\ X: T
          \end{array} \\ \\ 
{\tt (tSeq)} & \begin{array}{c} 
          \Gamma \vdash S : T \ \ \ \ \Gamma \vdash \overline{S}:T' 
          \\ \hline
          \Gamma \vdash S;\overline{S}: T'
          \end{array} \\ \\ 
{\tt (tIf)} & \begin{array}{c} 
          \Gamma \vdash E : bool \ \ \ \ \Gamma \vdash \overline{S_1}:T \ \ \ \  \Gamma \vdash \overline{S_2}:T
          \\ \hline
          \Gamma \vdash if\ E\ \{\overline{S_1}\}\ else\ \{\overline{S_2}\}: T
          \end{array} \\ \\ 
{\tt (tWhile)} & \begin{array}{c} 
          \Gamma \vdash E : bool \ \ \ \ \Gamma \vdash \overline{S}:T 
          \\ \hline
          \Gamma \vdash while\ E\ \{\overline{S}\} : T
          \end{array} \\ \\ 
\end{array} 
$$

The assignment statement and nop statement are of type $unit$. The return statement  has type $T$ if the return variable $X$ has type $T$. The head and the tail of a sequence of statements are typed indepdently. The two alternatives of an if statement should share the smae time. (In fact, we can be more specific to state that the type of if and while are $unit$, though it is unnecessarily here.)


We turn into the typing for new syntax.

$$
\begin{array}{rc}
{\tt (tFree)} & \begin{array}{c} 
          \Gamma \vdash X : [T]
          \\ \hline
          \Gamma \vdash free\ X: unit
          \end{array}
\end{array}
$$

The free statement has type $unit$ provided the variable $X$ is having type $[T]$.


$$
\begin{array}{rc}
{\tt (tArrDeref)} & \begin{array}{c} 
          \Gamma \vdash E_1 : int \ \ \ \ \Gamma \vdash X:[T] \ \ \ \Gamma \vdash E_2:T
          \\ \hline
          \Gamma \vdash X[E_1] = E_2: unit
          \end{array} 
\end{array}  
$$

The array dereference statement has type $unit$ if the index expression $E_1$ has type $int$, $X$ has type $[T]$ and the right hand side $E_2$ has type $T$.



### Type Checking SIMP Declaration (Extended) 


$$
\begin{array}{rc}
{\tt (tFuncDecl)} & \begin{array}{c} 
          \Gamma \oplus(f:T_1 \rightarrow T_2)\oplus(X:T_1) \vdash \overline{S}:T_2
          \\ \hline
          \Gamma \vdash func\ f(X:T_1)T_2 \{ \overline{S} \}: T_1 \rightarrow T_2
          \end{array} \\ \\ 
{\tt (tProg)} & \begin{array}{c} 
          {\tt for\ } i \in [1,n] \ \ \
          \Gamma_i \vdash D_i : T_i \ \ \
          \Gamma \vdash \overline{S}:T
          \\ \hline
          \Gamma \vdash D_1;...;D_n;\overline{S}: T
          \end{array} \
\end{array} 
$$

In rule $(\tt tFuncDecl)$, we type check the function declaration by extending the type environment with the type of $f$ and the formal argument $X$ and type check the body.
In rule $(\tt tProg)$, we type check the function declarations independently from the main program statement $\overline{S}$.


### Example 

We find the type checking derivation of the program `SIMP1`


Let `Γ1= {(y,int)}` and `Γ={(plus1,int->int),(z,int)}`
```python
Γ1⊕(plus1,int->int)⊕(x,int) |- 1 :int(tConst)

(x:int) ∈ Γ1⊕(plus1,int->int)⊕(x,int)
-------------------------------------(tVar)
Γ1⊕(plus1,int->int)⊕(x,int) |- x :int        (y:int)∈Γ1
-------------------------------------(tOp) -----------------------------------(tVar)
Γ1⊕(plus1,int->int)⊕(x,int) |- x + 1       Γ1⊕(plus1,int->int)⊕(x,int) |-y:int 
-----------------------------------------------------------------------------(tAssign)
Γ1⊕(plus1,int->int)⊕(x,int) |- y = x + 1:unit        [sub tree 2]                             
----------------------------------------------------------------------------------------- (tSeq)
Γ1⊕(plus1,int->int)⊕(x,int) |- y = x + 1; return y;:int
------------------------------------------------------------- (tFuncDecl)
Γ1 |- func plus1 (x:int) int {
    y = x + 1;
    return y;                            [sub tree 3]
} : int -> int         
---------------------------------------------------------------------------- (tProg)
Γ |- func plus1 (x:int) int {
    y = x + 1;
    return y;
}
z = plus1(0);
return z; :int 
```

where [sub tree 2] is 

```python
y:int ∈ Γ1
---------------------------------------(tVar)
 Γ1⊕(plus1,int->int)⊕(x,int) |- y:int 
----------------------------------------------------------- (tReturn)
Γ1⊕(plus1,int->int)⊕(x,int) |- return y;:int
```

[sub tree 3] is

```python
Γ |- 0:int (tConst)

(plus1,int->int) ∈ Γ
----------------------(tVar)
Γ |- plus1:int -> int             (z,int) ∈ Γ
--------------------------(tApp)  -------(tVar)
Γ |- plus1(0):int                 Γ |- z:int       (z,int) ∈ Γ
----------------------------------------(tAssign)  -------(tVar)
Γ |- z=plus1(0);:unit                              Γ |- z:int
----------------------------------------------------------- (tReturn)
Γ |- z=plus1(0);return z;:int
```


### Cohort Exercise

As an exercise, apply the type checking rule to `SIMP2`.


### Cohort Exercise 

As an exercise, develop a type inference algorithm for the extended SIMP.

## Run-time errors caused by illegal memory operations

There are several issues arising with the memory management.

### Double-freeing 

As motivated earlier, in some system, the operational semantics of the `free x` statement does not remove the variable `x` in the stack frame, which causes a double free error. For example

```java
// SIMP3 
func f(x:int) int {
    t = int[x];
    free t;
    free t; // run-time error, as t's reference is no longer valid.
    return x; 
}
y = f(1);
return y;
```

### Missing free

On the other hand, missing free statement after array initialization might cause memory leak. 

```java
// SIMP4
func f(x:int) int {
    t = int[x];
    return 1; // unfreed memory unless garbage-collected.
}
y = f(1);
return y;
```

### Array out of bound

Another common error is array out of bound access. 

```java
// SIMP5
func f(x:int) int {
    t = int[x];
    t[1] = 0; // array out of bound might arise
    free t;
    return 0; 
}
y = f(1);
return y;
```

Note that all these three examples are well-typed in the current type checking system. The array out of bound error can be detected via dependent type system (recall GADT example in [some earlier class](./fp_scala_poly.md#generalized-algebraic-data-type)). The other two kinds of errors can be flagged out using Linear Type system.

## Linear Type System

Linear Type was inspired by the linear logic proposed by Jean-Yves Girard. 

Linear Type System is a popular static semantic design choice to ensure memory safety. It has strong influences in languages such as Cyclone and Rust. 

The basic principal is that 

1. each variable has only one entry in a type environment $\Gamma$ (same as the normal type system)
1. after a variable's type assignment from some type environment $\Gamma$ is used in some proof derivation, it will be removed from $\Gamma$. 


### Type Checking Expression using Linear Type System

The linear typing rules for SIMP expression are in the form of $\Gamma \vdash E : T, \Gamma'$ which reads as "we type check $E$ to have type $T$ under $\Gamma$, after that $\Gamma$ becomes $\Gamma'$.


$$
\begin{array}{rc}
{\tt (ltVar)} & \begin{array}{c} 
          \Gamma'\oplus(X,T) = \Gamma
          \\ \hline
          \Gamma \vdash X : T, \Gamma' 
          \end{array} 
\end{array}
$$

The above rule type checks the variable $X$ to have type $T$, this is valid if we can find $(X,T)$ in the type environment $\Gamma$, and we remove that entry from $\Gamma$ to produce $\Gamma'$.


$$
\begin{array}{rc}
{\tt (ltArrInst)} & \begin{array}{c} 
          \Gamma \vdash E:int, \Gamma'
          \\ \hline
          \Gamma \vdash T[E] : [T], \Gamma' 
          \end{array} 
\end{array}
$$

The array instantion expression is treated as before except that the post-checking type environment is taken into consideration. 


$$
\begin{array}{rc}
{\tt (ltApp)} & \begin{array}{c} 
          \Gamma \vdash E_2:T_1, \Gamma' \ \ \ \ (f, T_1\rightarrow T_2) \in \Gamma'
          \\ \hline
          \Gamma \vdash f(E_2) : T_2, \Gamma' 
          \end{array}  
\end{array}
$$

When type checking the function application expression, we linearly type-check the argument $E_2$ to have type $T_1$ and we check the function $f$ is having the function type $T_1 \rightarrow T_2)$ in the update type environment. (Note that unlike other system, we do not remove the type assignment for functions after "use", so that a function can be reused.)


$$
\begin{array}{rc}
{\tt (ltArrRef)} & \begin{array}{c} 
          \Gamma \vdash E_2:int, \Gamma' \ \ \ \ (X, [T]) \in \Gamma'
          \\ \hline
          \Gamma \vdash X[E_2] : T, \Gamma' 
          \end{array}  
\end{array}
$$

Similarly, when type checking the array reference expression, we linearly type check the index expression against type $int$, and we check the array variable $X$ is in the type environment $\Gamma'$ without removing it. 

We omit the linearly typing rules for the rest of expressions as they contain no surprise. 

#### Cohort Exercise
Work out the linear typing rules for $C$, $unit$, $(E)$ and $E\ op\ E$.


### Type Checking Statement using Linear Type System

The linear typing rules for SIMP statements are in the form of $\Gamma \vdash S : T, \Gamma'$ which reads as "we type check $S$ to have type $T$ under $\Gamma$, after that $\Gamma$ becomes $\Gamma'$.



$$
\begin{array}{rc}
{\tt (ltAssign)} & \begin{array}{c} 
          \Gamma \vdash E:T, \Gamma' 
          \\ \hline
          \Gamma \vdash X = E : unit, \Gamma' \oplus(X,T) 
          \end{array} 
\end{array}
$$

In rule $(\tt ltAssign)$ we type check the assignment statement, we first type check the RHS expression, and we "transfer" the ownership of type $T$ to $X$ in the resulting environment. For example, in an assignment statement, $X = Y$, $Y$'s type is transferred to $X$, and $Y$'s type assignment is no longer accessible after this statement. Hence the following programming is not typeable in the linear type system. 


```java
// SIMP6
x = 1;
y = x;
z = x;
```


$$
\begin{array}{rc}
{\tt (ltNop)} & 
          \Gamma \vdash nop : unit, \Gamma 
\end{array}
$$

Typing $Nop$ does not change the type environment.  


$$
\begin{array}{rc}
{\tt (ltArrDeref)} & \begin{array}{c} 
          \Gamma \vdash E_2:T, \Gamma_1 \ \ \ \Gamma_1 \vdash E_1:int, \Gamma_2 \\ (X,[T]) \in \Gamma_2 
          \\ \hline
          \Gamma \vdash X[E_1] = E_2 : unit, \Gamma_2
          \end{array} 
\end{array}
$$

In case of array dereference statement, we type check the RHS expression. With the updated type environemnt $Gamma_1$ we type check the index expression $E_1$ having type $int$. Finally we make sure that $X$ is an array type in $\Gamma_2$ without removing it.

$$
\begin{array}{rc}
{\tt (ltFree)} & \begin{array}{c} 
          \Gamma \vdash X:[T], \Gamma' 
          \\ \hline
          \Gamma \vdash free\ X: unit, \Gamma'
          \end{array} 
\end{array}
$$

When type checking the free statement, $X$'s type must be an array type. (Note that $(X,[T]))$ will be removed.)


$$
\begin{array}{rc}
{\tt (ltReturn)} & \begin{array}{c} 
          \Gamma \vdash X:T, \Gamma' 
          \\ \hline
          \Gamma \vdash return\ X: T, \Gamma'
          \end{array} 
\end{array}
$$

Return statement carries the type of the variable being returned. After that, the type assignment of $X$ will be removed. 


$$
\begin{array}{rc}
{\tt (ltIf)} & \begin{array}{c} 
          \Gamma \vdash E_1:bool, \Gamma_1 \\ 
          \Gamma_1 \vdash \overline{S_1} : T, \Gamma_2 \\  
          \Gamma_1 \vdash \overline{S_2} : T, \Gamma_2 
          \\ \hline
          \Gamma \vdash if\ E_1\ \{\overline{S_1}\}\ else\ \{\overline{S_2}\} : T, \Gamma_2
          \end{array} 
\end{array}
$$

In the rule $(\tt ltIf)$, we first type check the condition expression $E_1$ against $bool$. We then type check the then and else statements under the same type $T$ and resulting type environment $\Gamma_2$. 



$$
\begin{array}{rc}
{\tt (ltWhile)} & \begin{array}{c} 
          \Gamma \vdash E:bool, \Gamma_1 \\ 
          \Gamma_1 \vdash \overline{S} : T, \Gamma_1  
          \\ \hline
          \Gamma \vdash while\ E\ \{\overline{S}\} : T, \Gamma_1
          \end{array} 
\end{array}
$$

The typing rule $(\tt ltWhile)$ is similar to $(\tt ltIf)$, except that the type environments "before" and "after" the while body should be unchanged to ensure linearity.




$$
\begin{array}{rc}
{\tt (ltSeq)} & \begin{array}{c} 
          \Gamma \vdash S:T, \Gamma_1 \\ 
          \Gamma_1 \vdash \overline{S} : T', \Gamma_2  
          \\ \hline
          \Gamma \vdash S;\overline{S}:T', \Gamma_2
          \end{array} 
\end{array}
$$

In the rule $(\tt ltSeq)$, we type check a sequence of statements by propogating the updated type environments from top to bottom (left to right).


### Type Checking SIMP Declaration using Linear Type System 


$$
\begin{array}{rc}
{\tt (ltFuncDecl)} & \begin{array}{c} 
          \Gamma \oplus(f:T_1 \rightarrow T_2)\oplus(X:T_1) \vdash \overline{S}:T_2, \Gamma\oplus(f:T_1 \rightarrow T_2)
          \\ \hline
          \Gamma \vdash func\ f(X:T_1)T_2 \{ \overline{S} \}: T_1 \rightarrow T_2, \Gamma
          \end{array} \\ \\ 
{\tt (ltProg)} & \begin{array}{c} 
          {\tt for\ } i \in [1,n] \ \ \
          \{\} \vdash D_i : T_i, \Gamma_i \ \ \
          \Gamma \vdash \overline{S}:T,\Gamma'
          \\ \hline
          \Gamma \vdash D_1;...;D_n;\overline{S}: T,\Gamma'
          \end{array} 
\end{array} 
$$

When type checking a function declaration, we extend the type environemnt with the function's type assignment and its argument type assignment, then type check the body. The additional requirement is that the resulting environment must be exactly the same as $\Gamma\oplus(f:T_1 \rightarrow T_2)$ to maintain linearity. 

In $(\tt ltPRog)$, we type check the function declaration idependently with an empty type environment then type check the main statement sequence left to right. 



#### Rejecting `SIMP3` via linear type system
Let's apply the linear type checking rules type check the function `f` from  our earlier example `SIMP3`.

```python
{(f,int->int),(x,int)} |- x : int (ltVar), {(f,int->int)} (ltVar)
--------------------------------------------------------(ltAssign)
{(f,int->int),(x,int)} |- t = int[x] :unit, {(f,int->int),(t,[int])} [sub tree 5]
-----------------------------------------------------------------(ltSeq)
{(f,int->int),(x,int)} |- t = int[x]; free t; free t; return x; : ???, ???
----------------------------------------------------- (ltFuncDecl)
{} |- func f(x:int) int {
    t = int[x];
    free t;
    free t; 
    return x; 
} : ???, ???
```

[sub tree 5] is as follows


```python

{(f,int->int),(t,[int])} |- t : [int], {(f,int->int)} (ltVar) 
----------------------------------------------------------- (ltFree)
{(f,int->int),(t,[int])} |- free t : unit, {(f,int->int)}   [sub tree 6]
---------------------------------------------------------- (ltSeq)
{(f,int->int),(t,[int])} |- free t; free t; return x; : ???, ???
```

[sub tree 6] is as follows

```python

we get stuck here. t's type has been "consumed" 
---------------------------- (ltFree)
{(f,int->int)} |- free t : ???, ???
-------------------------------------------- (ltSeq)
{(f,int->int)} |- free t; return x; : ???, ???
```

Since the type checking fails, `SIMP3` will be rejected by the linear type system. 

#### Rejecting `SIMP4` via linear type system

Let's try to type check `SIMP4`.

```python
{(f,int->int),(x,int)} |- x : int (ltVar), {(f,int->int)} (ltVar)
--------------------------------------------------------(ltAssign)
{(f,int->int),(x,int)} |- t = int[x] :unit, {(f,int->int),(t,[int])} [sub tree 7]
-----------------------------------------------------------------(ltSeq)
{(f,int->int),(x,int)} |- t = int[x]; return 1;:int, {(f,int->int),(t,[int])} we get stuck  
----------------------------------------------------- (ltFuncDecl)
{} |- func f(x:int) int {
    t = int[x];
    return 1;
} : int, ??? 
```

where [sub tree 7] is as follows


```python
{(f,int->int),(t,[int])} |- 1 : int, {(f,int->int),(t,[int])}
----------------------------------------------------- (ltReturn)
{(f,int->int),(t,[int])} |- return 1; : int, {(f,int->int),(t,[int])}
```

The above program fails to type check as the result type environment of the $(\tt ltFuncDelc)$ rule is not matching with the input type environment. 



### Make linear type system practical

The linear type checking is a proof-of-concept that we could use it to detect run-time errors related to memory management. 

The current system is still naive. 

1. We probably need to apply the linearity restriction to heap object such as array but not to primitive values such as `int` and `bool`. For example, the following program will not type check

```java
func square (x:int):int {
    y = x * x;
    return y;
}
```

2. Typing rules will become complex if we consider nested arrays. 

3. We need a type inference algorithm, which should reject `SIMP3`. But for `SIMP4`, its type constraints should identify the missing `free` statement and let the compiler insert the statement on behalf of the programmers. 

We leave these as future work. 