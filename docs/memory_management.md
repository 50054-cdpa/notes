# 50.054 - Memory Management

## Learning Outcomes

1. Extend PA to support function call and array operations
1. Extend the dynamic semantics to model the run-time memory operations
1. Describe activation records
1. Extend SIMP to support function call and array operations
1. Describe the challenges of memory management
1. Apply linear type system to static semantics


## Extending Pseudo Assembly

So far, we have been dealing with a toy language without function call nor complex data structure. We consider extending the [Pseudo Assembly language syntax](./ir_pseudo_assembly.md#pseudo-assembly) as follows




$$
\begin{array}{rccl}
(\tt Instruction)   & i   & ::= & ... \mid begin\ f\ d \mid call\ f\ s \mid d \leftarrow alloc\ s \mid free\ s \mid  d \leftarrow deref\ s \\ 
\end{array}
$$

Besides the existing instructions, we include

* $begin\ f\ d$ - denotes the start of a function name $f$ ($f$ is a variable) and the formal argument (operand) $d$. 
* $call\ f\ s$ - denotes a function invocation of $f$ with actual argument $s$.
* $d \leftarrow alloc\ s$ - denotes the memory allocation. It allocates $s$ bytes of unoccupied memory and assigns the reference address to $d$. 
* $free\ s$ - deallocates the allocated memory at address stored in $s$. 
* $d \leftarrow deref\ s$ - dereferences the value at the memory address stored in $s$ and copies it to $d$. 


### Extending PA Operational Semantics

We extend the operational semantics of Pseudo Assembly defined in [here](./dynamic_semantics.md#operational-semantics-of-pseudo-assembly). Instead of mixing the temp variable-to-constant mappings and register-to-constant mappings in $L$, we move the register-to-constant mappings in $R$. 


$$
\begin{array}{rccl}
(\tt PA\ Stack\ Frame) & L & \subseteq & (t \times c) \\ 
(\tt PA\ Register\ Environment) & R & \subseteq & (r \times c) \\ 
(\tt PA\ Heap\ Memory) & H & \subseteq & (loc \times loc) \\ 
(\tt Heap\ Address) & loc & ::= & loc(1) \mid ... \mid loc(n) \\ 
(\tt PA\ Memory\ Environment) & M & ::= & (\overline{L}, \overline{l}, H, R) 
\end{array}
$$

* $H$ - denotes a set of address tuples. The first address in the tuple denotes the starting address of the allocated memory in the heap (inclusive) and the second one denotes the ending address (exclusive). 
* $M$ - a tuple of 4 items. A stack of stack frames $\overline{L}$, a stack of function invocation labels $\overline{l}$ (a sequence of labels marking the function calling instructions), the heap and the register environment. $\overline{L}$ and $\overline{l}$ should have the same size. Given an index $i$, the $i$-th elements in $\overline{L}$ and $\overline{l}$ form the *activation record*.

The small step operational semantic rules in shape $P \vdash (L, li) \longrightarrow (L, li)$ introduced in our earlier [class](./dynamic_semantics.md#operational-semantics-of-pseudo-assembly) are modified to have shape of $P \vdash (M, li) \longrightarrow (M, li)$.  

We highlight the important rules


$$
\begin{array}{cc}
{\tt (pAlloc)} &  \begin{array}{c}
        M = (L:\overline{L}, \overline{l}, H, R) \ \ \ \ 
        findfree(H,L(s)) = loc \\ 
        M' = (L\oplus(d,loc):\overline{L}, \overline{l}, H\cup[(loc, loc+L(s))], R)
        \\ \hline
        P \vdash (M, l: d \leftarrow alloc\ s) \longrightarrow (M', P(l+1))  
        \end{array} \\ \\ 
{\tt (pFree)} & \begin{array}{c}
        M = (L:\overline{L}, \overline{l}, H,R) \ \ \ \ loc = L(s) \\ 
        H'\cup[(loc,loc')] = H \ \ \ \ 
        M' = (L:\overline{L}, \overline{l}, H', R) \\ \hline
        P \vdash (M, l: free\ s) \longrightarrow (M', P(l+1))
        \end{array} \\ \\ 

{\tt (pDeref)} & \begin{array}{c}
        M = (L:\overline{L}, \overline{l}, H,R) \ \ \ \ loc = L(s) \\ 
        \exist (loc_1, loc_2) \in H. loc_1 \leq loc \lt loc_2 \\ 
        v = bytetoint(loc) \ \ \ M' = (L\oplus(d,v):\overline{L}, \overline{l}, H, R)
        \\ \hline
        P \vdash ( M, l: d \leftarrow deref\ s) \longrightarrow (M', P(l+1))
        \end{array}
\end{array}
$$

* The rule $(\tt pAlloc)$ defines the memory allocation routine. Given the asking size, $L(s)$, we make use of the run-time built-in function $findfree()$ to locate the starting address of the free memory region. We save the starting address in $d$, and add the allocated region $(loc, loc+L(s))$ to $H$ for book-keeping. 
* The rule $(\tt pFree)$ defines the memory deallocation routine. Given the starting address of the memory to be freed $loc$, we remove the pair $(loc, loc')$ from $H$.
* The rule $(\tt pDeref)$ defines the memory de-reference operation. Given the de-referenced address $loc$, we ensure the address is in $H$. We call a builtin function $bytetoint(loc)$ to read the byte from the given address and convert it into integer constant. We store the converted value into the stack frame and move onto the next instruction. 

$$
\begin{array}{rc}
{\tt (pCall)} &  \begin{array}{c}
        l': begin\ f\ d \in P \ \ \ M = (L:\overline{L}, \overline{l}, H, R) \\ 
        M' = (\{(d, L(s))\}:L:\overline{L}, l:\overline{l}, H, R)
        \\ \hline
        P \vdash (M, l: d \leftarrow call\ f\ s) \longrightarrow (M', P(l'+1))  
        \end{array} \\ \\ 

{\tt (pBegin)} & \begin{array}{c}
        (l':ret) \in P \ \ \ \forall (l'':ret) \in P: l''>= l \implies l'' >= l'
        \\ \hline
        P \vdash (M, l:begin\ f\ d) \longrightarrow (M, P(l'+1)) 
        \end{array} \\ \\ 
{\tt (pRet1)} &  \begin{array}{c}
        M = (L':L:\overline{L}, l':\overline{l}, H, R)\ \ \ 
        l': d \leftarrow call\ f\ s \in P \\  
        R' = R - {r_{ret}} \ \ \ 
        M' = (L\oplus(d,R(r_{ret})):\overline{L}, \overline{l}, H, R')
        \\ \hline
        P \vdash (M, l:ret) \longrightarrow (M', P(l'+1))  
        \end{array} \\ \\ 
{\tt (pRet2)} &  \begin{array}{c}
        M = (\overline{L}, [], H, R)\ \ \ 
        \\ \hline
        P \vdash (M, l:ret) \longrightarrow exit()
        \end{array} \\ \\ 
\end{array}
$$

* The rule $(\tt pCall)$ handles the function call instruction. In this case, we search for the begin statement of the callee. We push the new stack frame into the stack with the binding of the input argument. We push the caller's label into the labels stack. The executation context is shifted to the function body instruction. 
* The rule $(\tt pBegin)$ processes the begin instruction. Since it is the defining the function, we skip the function body and move to the instruction that follows the return instruction. 
* The rule $(\tt pRet1)$ manages the termination of a function call. We pop the stack frame and the top label $l'$ from the stack. We search for the caller instruction by the label $l'$. We update the caller's stack frame with the returned value of the function call. 
* The rule ${\tt pRet2}$ defines the termination of the entire program.

We omit the rest of rules as we need to change the $L$ to $M = (L:\overline{L}, \overline{l}, H, R)$.

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
P |- ([[]], [], [], []), 1: begin plus1 x  ---> # (pBegin)
P |- ([[]], [], [], []), 5: z <- call plus1 0 ---> # (pCall) 
P |- ([[(x,0)],[]],[5], [], []), 2: y <- x + 1 ---> # (pOp)
P |- ([[(x,0),(y,1)],[]],[5], [], []), 3: rret <- y ---> # (pTempVar)
P |- ([[(x,0),(y,1)],[]],[5], [], [(rret,1]), 4: ret  ---> # (pRet1)
P |- ([[(z,1)]],[], [], []), 6: rret <- z # (pTempVar) 
P |- ([[(z,1)]],[], [], [(rret,1)]) 7: ret # (pRet2)
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



## Extending SIMP with functions and array