% Pseudo Assembly

# Learning Outcome

By the end of this lesson, you should be able to

1. 


# The SIMP Language

We consider the syntax of the simp language as follows

$$
\begin{array}{rccl}
(\tt Statement) & S & ::= & X = E ; \mid return\ X ; \mid if\ E\ \{ \overline{S} \}\ else\ \{ \overline{S} \} \mid while\ E\ \{ \overline{S} \} \\
(\tt Expression) & E & ::= & E\ OP\ E \mid X \mid C  \\
(\tt Statements) & \overline{S} & ::= & S \mid S\ \overline{S} \\
(\tt Operator) & OP & ::= & + \mid - \mid * \mid / \mid < \mid > \mid == \\ 
(\tt Constant) & C & ::= & 1 \mid 2 \mid ...  \\ 
(\tt Variable) & X & ::= & a \mid b \mid c \mid d \mid ...
\end{array}
$$

For simplicity, we ignore function and procedure. We assume a special variable $input$ serving as the input argument to the program. The rest of the syntax is very similar to Java and C except that the type annotations are omitted. 

For example 

```python
x = input;
s = 0;
c = 0;
while c < x {
    s = c + s;
    c = c + 1;
}
return s;
```

# Pseudo assembly

We consider the Pseudo Assembly language as follows.

$$
\begin{array}{rccl}
(\tt Labeled\ Instruction) & li  & ::= & l : i \\ 
(\tt Instruction)   & i   & ::= & d \leftarrow s \mid d \leftarrow s\ op\ s \mid ret \mid ifn\ s\ goto\ l \mid goto\ l \\ 
(\tt Labeled\ Instructions)   & lis   & ::= & li \mid li\ lis \\ 
(\tt Operand)       & d,s & ::= & r_{ret} \mid c \mid t \\
(\tt Temp\ Var)      & t   & ::= & x \mid y \mid ...  \\
(\tt Label)         & l   & ::= & 1 \mid 2 \mid ... \\
(\tt Operator)      & op  & ::= & + \mid - \mid < \mid > \mid == \mid ... \\ 
(\tt Constant)      & c   & ::= & 1 \mid 2 \mid ... 
\end{array}
$$

where $li$, a labeled instruction, is a label $l$ associated with an instruction $i$. For simplicity, we use positive integers as labels. 
$r_{ret}$ is a special variable for the return statement.

```java
1: x <- input
2: s <- 0
3: c <- 0
4: ifn c < x goto 8
5: s <- c + s
6: c <- c + 1
7: goto 4
8: r <- s
9: ret
```

## Informal Specification of Pseudo Assembly

We assume that statements of a pseudo assembly program are stored in a list. There exists a mapping from labels to the corresponding instructions, 




# Maximal Munch Algorithm

To convert a SIMP program into the pseudo assembly, we could consider the Maximal Munch Algorithm which is described in terms of the set of deduction rules in the following. 

$$
\begin{array}{rc}
{\tt (Assign)} & \begin{array}{c} 
               G_a(x)(e) \vdash lis  \\
               \hline
               G_s(x = e) \vdash lis
               \end{array} \\ 
\end{array}  
$$

In case we have an assignment statement $x = e$, we call a helper function $G_a$ to generate the Peudo Assembly (PA) labeled instructions.

$$
\begin{array}{rc}
{\tt (Return)} & \begin{array}{c}
     G_a(r_{ret})(e) \vdash lis \ \ l\ {\tt is\ a\ fresh\ label} \\
     \hline
     G_s(return\ e) \vdash lis + [ l: ret ]
     \end{array}
\end{array}
$$

In case we have a return statement $return e$, we make use of the same helper function $G_a$ to generate the instructions of assigning $e$ to the special temp variable $r_{ret}$. We then generate a new label $l$, and append $l:ret$ to the instructions.

$$
\begin{array}{rc}
{\tt (Sequence)} & \begin{array}{c} 
               {\tt for}\ l \in \{1,n\} ~~ G_s(S_l) \vdash lis_l \\
               \hline
               G_s(S_1;...;S_n) \vdash lis_1 + ... +  lis_n
               \end{array} 
\end{array}  
$$

In case we have a sequence of statements, we apply $G_s$ recurisvely to the individual statements in order, then we merge all the results by concatenation.


$$
\begin{array}{rl}
     {\tt (If)} & \begin{array}{c}
               t\ {\tt is\ a\ fresh\ var} \\ 
               G_a(t)(E) \vdash lis_0 \\
               l_{If}\ {\tt is\ a\ fresh\ label} \\
               G_s(S_2) \vdash lis_2 \\ 
               l_{EndThen}\ {\tt  is\ a\ fresh\ label} \\  
               l_{Else}\ {\tt is\ the\ next\ label (w/o\ incr)} \\ 
               G_s(S_3) \vdash lis_3 \\ 
               l_{EndElse}\ {\tt is\ a\ fresh\ label} \\
               l_{EndIf}\ {\tt is\ the\ next\ label\ (w/o\ incr)} \\ 
               lis_1 = [l_{If}: ifn\ t\ goto\ l_{Else} ] \\ 
               lis_2' = lis_2 + [l_{EndThen}:goto\ l_{EndIf}] \\ 
               lis_3' = lis_3 + [l_{EndElse}:goto\ l_{EndIf}] \\ 
               \hline  
               G_s(if\ E\ \{S_1\}\ else\ \{S_2\}) \vdash lis_0 + lis_1 + lis_2' + lis_3'               
                \end{array} \\  
\end{array}
$$

In case we have a if-else statement, we 
1. generate a fresh variable $t$, and call $G_a(t)(E)$ to convert the conditional expression into PA instructions.
2. generate a new label $l_{If}$ which serves as a target for the backward jump instruction (generated in a later step).
3. call $G_s(S_2)$ to generate the PA instructions for the then branch.
4. generate a new label $l_{EndThen}$ which is associated with the "end-of-then-branch" goto instruction.
5. peek into the label generator to find out what is the next upcoming label and refer to it as $l_{Else}$. 
6. call $G_s(S_3)$ to generate the PA instructions for the else branch.
7. generate a new label $l_{EndElse}$, which is associated with the "end-of-else-branch" goto instruction. (Note that we can assume the next instruction after this is the end of If, in case of nested if-else.)  
8. peek into the label generator to find out what is the next upcoming label and refer to it as $l_{EndIf}$ (hm.. we contradict ourselves here.))


$$
\begin{array}{rl}
     {\tt (While)} & \begin{array}{c}
                    l_{BWhile}\ {\tt is\ the\ next\ label\ (w/o\ incr)} \\ 
                    t\ {\tt is\ a\ fresh\ var} \\     
                    G_a(t)(E) \vdash lis_0 \\ 
                    l_{While}\ {\tt is\ a\ fresh\ label} \\ 
                    G_s(S) \vdash lis_2\\ 
                    l_{EndBody}\ {\tt is\ a\ fresh\ label} \\  
                    l_{EndWhile}\ {\tt is\ the\ next\ label\ (w/o\ incr)} \\ 
                    lis_1 = [l_{While}: ifn\ t\ goto\ l_{EndWhile}] \\
                    lis_2' = lis_2 + [ l_{EndBody}: goto\ l_{While} ] \\
                    \hline
                    G(while\ E\ \{S\}) \vdash lis_0 + lis_1 + lis_2'           
                \end{array} \\  
\end{array}
$$