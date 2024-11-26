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
(\tt Instruction)   & i   & ::= & ... \mid begin\ f\ d \mid end \mid call\ f\ s \mid d \leftarrow alloc\ s \mid free\ s \mid  d \leftarrow deref\ s \\ 
\end{array}
$$

Besides the existing instructions, we include

* $begin\ f\ d$ - denotes the start of a function name $f$ ($f$ is a variable) and the formal argument (operand) $d$. 
* $end$ - marks the end of a function.
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
        P \vdash (M, l: d \leftarrow call\ f\ s) \longrightarrow (M', P(l'))  
        \end{array} \\ \\ 

{\tt (pBegin)} & P \vdash (M, l:begin\ f\ d) \longrightarrow (M, P(l+1)) \\ \\ 

{\tt (pEnd)} &  \begin{array}{c}
        M = (L':L:\overline{L}, l':\overline{l}, H, R)\ \ \ 
        l': d \leftarrow call\ f\ s \in P \\  
        M' = (L\oplus(d,R(r_{ret})):\overline{L}, \overline{l}, H, R)
        \\ \hline
        P \vdash (M, l:end) \longrightarrow (M', P(l'+1))  
        \end{array} \\ \\ 
\end{array}
$$

* The rule $(\tt pCall)$ handles the function call instruction. In this case, we search for the begin statement of the callee. We push the new stack frame into the stack with the binding of the input argument. We push the caller's label into the labels stack. The executation context is shifted to the begin instruction. 
* The rule $(\tt pBegin)$ processes the begin instruction. We move to the following instruction. 
* The rule $(\tt pEnd)$ manages the termination of a function call. We pop the stack frame and the top label $l'$ from the stack. We search for the caller instruction by the label $l'$. We update the caller's stack frame with the returned value of the function call. 


> TODO: talk about how multi param is handled, how the temp variables are reference in the actual target byte code.


## Extending SIMP with functions and array