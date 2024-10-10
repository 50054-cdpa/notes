# 50.054 - Code Generation

## Learning Outcomes

1. Name the difference among the target code platforms
1. Apply SSA-based register allocation to generate 3-address code from Pseudo Assembly
1. Handle register spilling
1. Implement the target code generation to WASM bytecode given a Pseudo Assembly Program


## Recap Compiler Pipeline

```mermaid
graph LR
A[Lexing] -->B[Parsing] --> C[Semantic Analysis] --> D[Optimization] --> E[Target Code Generation]
D --> C
```

For Target Code Generation, we consider some IR as input, the target code (executable) as the output.


## Instruction Selection

Instruction selection is a process of choosing the target platform on which the language to be executed. 

There are mainly 3 kinds of target platforms.

* 3-address instruction
    * RISC (Reduced Instruction Set Computer) architecture. E.g. Apple PowerPC, ARM, Pseudo Assembly
* 2-address instruction
    * CISC (Complex Instruction Set Computer) architecture. E.g. Intel x86
* 1-address instruction
    * Stack machine. E.g. JVM


### Assembly code vs Machine code

Note that the instruction formats mentioned here are the human-readable representations of the target code. The actual target code (machine code) is in binary format.

### 3-address instruction 

In 3-address instruction target platform, each instruction is set to use 3 addresses in maximum.
For instance, the Pseudo Assembly we studied earlier is a kind of 3-address instruction without the hardware restriction.

For instance in 3 address instruction, we have instructions that look like 

```
x <- 1
y <- 2
r <- x + y
```

where `r`, `x` and `y` are registers . Alternatively, in some other 3 address instruction format, we express the code fragement above in a prefix notation, 


```
load x 1
load y 2
add r x y
```

The advantage of having more register (addresses) per instruction allows us to huge room of code optimization while keeping a relative simple and small set of instructions (for instance, consider our Pseudo Assembly has a simple set.)

### 2-address instruction 

In 2-address instruction target platform, each instruction has maximum 2 addresses. As a result, some of the single line instruction in 3-address instruction has to be encoded as multiple instructions in 2 address platform. For example, to add `x` and `y` and store the result in `r`, we have to write

```
load x 1
load y 2
add x y
```

in the 3rd instruction we add the values stored in registers `x` and `y`. The sum will be stored in `x`. In the last statement, we move the result from `x` to `r`.

As the result, we need fewer registers (in minimum) to carry out operations. On the other hands, the set of instructions in 2-address instruction are often more complex.

### 1-address instruction 

In the exterem case, we find some target platform has only 1 address instruction. This kind of target is also known as the P-code (P for Pascal) or the stack machine code. 

For example for the same program, we need t9o encode it in 1-address instruction as follows

```
push 1
push 2
add 
store r
```
In the first instruction, we push the constant 1 to the left operand register (or the 1st register). In the second instruction, we push the constant 2 to the right oeprand register (the 2nd register). In the 3rd instruction, we apply the add operation to sum up the two registers and the result is stored in the first register. The 2nd register is cleared (or popped). In the last instruction, we pop the result from the first register store it in a temporary variable `r`

The benefit of 1 address intruction is having a minimum and uniform requirement for the hardware. It requrest the least amount registers, for example, JVM has only 3 registers. On the other hand, its instruction set is the most complex.


## From PA to 3-address target platform

In this section, we consider generating code for a target platform that using 3-address instruciton.

### Register Allocation Problem

Let's consider the register allocation problem. Recall that in Pseudo Assembly, we have unlimited temporary variables and registers. Among all the examples of PA we seen so far, we did not use any register except for the return register `rret`.

Such an assumption is no longer valid in the code generation phase. We face two major constraints.

1. Most of the operations can be only applied to registers, not to temporary variables. Operands from temporary variables need to be loaded to some registers before the application of the operation.
1. The number of registers is finite and often limited. This implies that we can't possibly load all the temporary variables to registers. At some point, we need to unload the content of some register to the temporary variable to make room for the next operation.

For example, the following PA program 

```java
// PA1
1: x <- inpput
2: y <- x + 1
3: z <- y + 1
4: w <- y * z
5: rret <- w
6: ret
```
has to be translated into

```java
1: r0 <- input
2: r1 <- r0 + 1
3: r2 <- r1 + 1
4: r3 <- r1 * r2
5: rret <- r3
6: ret
```

assuming we have 4 other registers `r0`, `r1`, `r2` and `r3`, besides `rret`. We can map the PA variables `{x : r0, y : r1, z : r2, w : r3}`

When we only have 3 other registers excluding `rret` we need to offload some result into some temporary variable. The offloading of the result from registers to temporary variables is also known as *register spilling*.


```java
1: r0 <- input
2: r1 <- r0 + 1
3: r2 <- r1 + 1
4: x  <- r0
5: r0 <- r1 * r2
6: rret <- r0
7: ret
```

The above program will work within the hardware constraint (3 extra registers besides `rret`). Now the register allocation, `{x : r0, y : r1, z : r2}` is only valid for instructions `1-4` and the alloction for instructions `5-7` is `{w : r0, y : r1, z: r2}`.


As we can argue, we could avoid the offloading by mapping `w` to `rret` since it is the one being retured. 

```java
1: r0 <- input
2: r1 <- r0 + 1
3: r2 <- r1 + 1
4: rret <- r1 * r2
5: ret
```
However this option is not always possible, as the following the `w` might not be returned variable in some other examples.

We could also avoid the offloading by exploiting the liveness analysis, that `x` is not live from instruction `3` onwards, hence we should not even save the result of `r0` to the temporary variable `x`.

```java
1: r0 <- input
2: r1 <- r0 + 1
3: r2 <- r1 + 1
4: r0 <- r1 * r2
5: rret <- r0
6: ret
```
However this option is not always possible, as in some other situation `x` is needed later.

The Register Allocation Problem is then define as follows.

Given a program $p$, and $k$ registers, find an optimal register assignment so that the register spilling is minimized.

### Interference Graph

To solve the register allocation problem, we define a data structure called *the interference graph.* 

Two temporary variables are *interferring* each other when they are both "live" at the same time in a program.  In the following we include the liveness analysis result as the comments in the program `PA1`.


```java
// PA1
1: x <- inpput // {input}
2: y <- x + 1  // {x}
3: z <- y + 1  // {y}
4: w <- y * z  // {y,z}
5: rret <- w   // {w}
6: ret         // {}
```


We conclude that `y` and `z` are interfering each other. Hence they should not be sharing the same register. 


```mermaid 
graph TD;
    input
    x
    y --- z
    w 
```

From the graph we can tell that "at peak" we need two registers concurrently, hence the above program can be translated to the target code using 2 registers excluding the `rret` register. 

For example we annotate the graph with the mapped registers `r0` and `r1` 

```mermaid 
graph TD;
    input["input(r0)"]
    x["x(r0)"]
    y["y(r0)"] --- z["z(r1)"]
    w["w(r0)"]
```

And we can generate the following output 

```java
1: r0 <- inpput   
2: r0 <- r0 + 1  
3: r1 <- r0 + 1  
4: r0 <- r0 * r1  
5: rret <- r0   
6: ret         
```



### Graph Coloring Problem

From the above example, we find that we can recast the register allocation problem into a graph coloring problem. 


The graph coloring problem is defined as follows.

Given a undirected graph, and $k$ colors, find a coloring plan in which no adjacent vertices sharing the same color, if possible. 

Unfortunately, this problem is *NP-complete* in general. No efficient algorithm is known.

Fortunatley, we do know a subset of graphs in which a polynomial time coloring algorithm exists. 

#### Chordal Graph

A graph $G = (V,E)$ is *chordal* if, for all cycle $v_1,...,v_n$ in $G$ with $n > 3$ there exists an edge $(v_i,v_j) \in E$ and $i, j \in \{1,...,n\}$ such that $(v_i, v_j)$ is not part of the cycle.

For example, the following graph

```mermaid
graph TD
    v1 --- v2 --- v3 --- v4 --- v1
    v2 --- v4
```

is chordal, because of $(v_2,v_4)$.

The following graph 


```mermaid
graph TD
    v1 --- v2 --- v3 --- v4 --- v1
```

is not chordal, or *chordless*.

It is a known result that a the coloring problem of chordal graphs can be solved in polynomial time.


#### An Example 

Consider the following PA program with the variable liveness result as comments

```java
// PA2
1: a <- 0           // {}
2: b <- 1           // {a}
3: c <- a + b       // {a, b}
4: d <- b + c       // {b, c}
5: a <- c + d       // {c, d}
6: e <- 2           // {a}
7: d <- a + e       // {a, e}
8: r_ret <- e + d   // {e, d}
9: ret 
```

We observe the interference graph 

```mermaid
graph TD
    a --- b --- c --- d 
    a --- e --- d
```
and find that it is chordless.


#### SSA saves the day!

With some research breakthroughs in 2002-2006, it was proven that programs in SSA forms are always having chordal interference graph.

For example, if we apply SSA conversion to `PA2`

We have the following

```java
// PA_SSA2
1: a1 <- 0           // {}
2: b1 <- 1           // {a1}
3: c1 <- a1 + b1     // {a1, b1}
4: d1 <- b1 + c1     // {b1, c1}
5: a2 <- c1 + d1     // {c1, d1}
6: e1 <- 2           // {a2}
7: d2 <- a2 + e1     // {a2, e1}
8: r_ret <- e1 + d2  // {e1, d2}
9: ret 
```

The liveness analysis algorithm can be adapted to SSA with the following adjustment.

We define the $join(s_i)$ function as follows

$$
join(s_i) = \bigsqcup_{v_j \in succ(v_i)} \Theta_{i,j}(s_j) 
$$

where $\Theta_{i,j}$ is a variable substitution derived from phi assignment of the labeled instruction at $j : \overline{\phi}\ instr$. 

$$
\begin{array}{rcl}
\Theta_{i,j} & = & \{ (t_i/t_k) \mid t_k = phi(..., i : t_i, ...) \in \overline{\phi} \}
\end{array}
$$

The monotonic functions can be defined by the following cases.

* case $l: \overline{\phi}\ ret$, $s_l = \{\}$
* case $l: \overline{\phi}\ t \leftarrow src$, $s_l = join(s_l) - \{ t \} \cup var(src)$
* case $l: \overline{\phi}\ t \leftarrow src_1\ op\ src_2$, $s_l = join(s_l) - \{t\} \cup var(src_1) \cup var(src_2)$
* case $l: \overline{\phi}\ r \leftarrow src$, $s_l = join(s_l) \cup var(src)$
* case $l: \overline{\phi}\ r \leftarrow src_1\ op\ src_2$, $s_l = join(s_l) \cup var(src_1) \cup var(src_2)$
* case $l: \overline{\phi}\ ifn\ t\ goto\ l'$, $s_l = join(s_l) \cup \{ t \}$
* other cases: $s_l = join(s_l)$


Now the interference graph of the `PA_SSA2` is as follows

```mermaid
graph TD;
    a1 --- b1 --- c1 --- d1
    a2 --- e1 --- d2
```
which is chordal.

#### Coloring Interference Graph generated from SSA

According to the findings of Budimlic's work and Hack's work, coloring the interference graph generated from an SSA program in in-order traversal of dominator tree gives us the optimal coloring. 

> In Hack's paper, it was discussed that the *elimination* step should be done in the post-order traveral of the dominator tree. From graph coloring problem, we know that the order of coloring is the reverse of the vertex eliminiation order.

In the context of PA, the in-order traversal of the dominator tree is always the same order of the instructions being labeled (assuming we generate the PA using the maximal munch algorithm introduced in the earlier lesson.)

Therefore we can color the above graph as follows,

```mermaid
graph TD;
    a1("a1(r0)") --- b1("b1(r1)") --- c1("c1(r0)") --- d1("d1(r1)")
    a2("a2(r0)") --- e1("e1(r1)") --- d2("d2(r0)")
```

From now onwards until the next section (JVM Bytecode generatoin), we assume that program to be register-allocated must be in SSA form.

Given that the program interference graph is chordal, the register allocation can be computed in polymomial type.

Instead of using building the interference graph, we consider using the live range table of an SSA program, 

In the following table (of `PA_SSA2`), the first row contains the program labels and the first column defines the variables and the last column is the allocated register. An `*` in a cell `(x, l)` represent variable `x` is live at program location `l`.


|var| 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |reg|
|---|---|---|---|---|---|---|---|---|---|---|
|a1 |   | * | * |   |   |   |   |   |   |r0 |
|b1 |   |   | * | * |   |   |   |   |   |r1 |
|c1 |   |   |   | * | * |   |   |   |   |r0 |
|d1 |   |   |   |   | * |   |   |   |   |r1 |
|a2 |   |   |   |   |   | * | * |   |   |r0 |
|e1 |   |   |   |   |   |   | * | * |   |r1 |
|d2 |   |   |   |   |   |   |   | * |   |r0 |   

At any point, (any column), the number of `*` denotes the number of live variables concurrently. The above tables show that at any point in-time, the peak of the register usage is `2` (in some literature, it is also known as the chromatic of the interference graph). Therefore, minimumally we need 2 registers to allocate the above program without spilling.


#### Register Spilling

However register spilling is avoidable due to program complexity and limit of hardware. 

Let's consider another example 

```java
// PA3
1: x <- 1       // {}
2: y <- x + 1   // {x}
3: z <- x * x   // {x,y}
4: w <- y * x   // {x,y,z}
5: u <- z + w   // {z,w}
6: r_ret <- u   // {u}  
7: ret          // {}
```

The SSA form is identical to the above, since there is no variable re-assignment.
In the comment, we include the result of the liveness analysis.


|var| 1 | 2 | 3 | 4 | 5 | 6 | 7 |reg|
|---|---|---|---|---|---|---|---|---|
| x |   | * | * | * |   |   |   |   | 
| y |   |   | * | * |   |   |   |   |
| z |   |   |   | * | * |   |   |   |
| w |   |   |   |   | * |   |   |   |
| u |   |   |   |   |   | * |   |   |

From the live range table able, we find that at peak i.e. instruction `4`, there are 3 live variables currently. We would need three registers for the allocation.

What if we only have two registers? Clearly, we need to "sacrifice" some live variable at instruction `4`, by spilling it back to the temporary variable
and reloading before it is needed again. But which one shall we "sacrifice"? There are a few options here.

1. Spill the least urgently needed live variable. Recall that the liveness analysis is a may analaysis, its result is an over-approximation. Some live variables might not be needed at this point.
1. Spill the live variable that interfere the most. This option works for the bruteforce searching coloring algorithm, the idea was to reduce the level of interference so that the remaining graph without this variable can be colored. 


For now let's take the first option. Suppose we extend the liveness analysis to keep track of the label where a variable is marked live.

```java
// PA3
1: x <- 1       // {}
2: y <- x + 1   // {x(3)}
3: z <- x * x   // {x(3),y(4)}
4: w <- y * x   // {x(4),y(4),z(5)}
5: u <- z + w   // {z(5),w(5)}
6: r_ret <- u   // {u(6)}  
7: ret          // {}
```

From the above results, we can conclude that at instruction `4`, we should sacrifice the live variable `z`, because `z` is marked live at label `5` which is needed in the instruction one-hop away in the CFG, compared to `x` and `y` which are marked live at label `4`. In other words, `z` is not as urgently needed compared to `x` and `y`. 


|var| 1 | 2 | 3 | 4 | 5 | 6 | 7 |reg|
|---|---|---|---|---|---|---|---|---|
| x |   | * | * | * |   |   |   |r0 | 
| y |   |   | * | * |   |   |   |r1 |
| z |   |   |   | - | * |   |   |   |
| w |   |   |   |   | * |   |   |   |
| u |   |   |   |   |   | * |   |   |

From the above, we find that the graph is colorable again. However register spilling requires some extra steps. First at label `3`, variable is `z` is some register, either `r0` or `r1`,
assuming in the target code operation `*` can use the same register for both operands and the result. We encounter another problem. To spill `z` (from the register) to the temporary variable, we need to figure out which other live variable to be swapped out so that the spilling can be done. Let's illustrate using the same example. 

```java
// PA3_REG
1: r0 <- 1        // x is r0
2: r1 <- r0 + 1   // y is r1
3: ?? <- r0 * r0  // what register should hold the result of x * x, before spilling it to `z`?
```
where the comments indicate what happens after the label instruction is excuted.

There are two option here

1. `??` is `r1`. It implies that we need to spill `r1` to `y` first after instruction `2` and then spill `r1` to `z` after instruction `3`, and load `y` back to `r1` after instruction `3` before instruction `4.`
1. `??` is `r0`. It implies that we need to spill `r0` to `z` first after instruction `2` and then spill `r0` to `z` after instruction `3`, and load `x` back to `r0` after instruction `3` before instruction `4.`

In this particular example, both options are equally good (or equally bad). In general, we can apply the heuristic of choosing the conflicting variable whose live range ends earlier, hopefully the main subject of spilling (`z` in this example) is not needed until then. 

Now let's say we pick the first option, the register allocation continues 


|var| 1 | 2 | 3 | 4 | 5 | 6 | 7 |reg|
|---|---|---|---|---|---|---|---|---|
| x |   | * | * | * |   |   |   |r0 | 
| y |   |   | * | * |   |   |   |r1 |
| z |   |   |   | - | * |   |   |r1 |
| w |   |   |   |   | * |   |   |r0 |
| u |   |   |   |   |   | * |   |r1 |

where `-` indicates taht `z` is being spilled from `r1` before label `4` and it needs to be loaded back to `r1` before label `5`. 
And the complete code of `PA3_REG` is as follows


```java
// PA3_REG
1: r0 <- 1        // x is r0
2: r1 <- r0 + 1   // y is r1
   y  <- r1       // temporarily save y
3: r1 <- r0 * r0  // z is r1 
   z  <- r1       // spill to z
   r1 <- y        // y is r1
4: r0 <- r1 * r0  // w is r0 (x,y are dead afterwards)
   r1 <- z        // z is r1
5: r1 <- r1 + r0  // u is r1 (z,w are dead afterwards)
6: r_ret <- r1
7: ret
```
In the above, assume that in the target platform, a label can be associated with a sequence of instructions, (which is often the case).

> As an exercise, work out what if we save `x` temporarily instead of `y` at label `2`.


#### Register allocation for phi assignments

What remains to address is the treatment of the phi assignments.

Let's consider a slightly bigger example. 

```js
// PA4
1: x <- input   // {input}
2: s <- 0       // {x}
3: c <- 0       // {s,x}
4: b <- c < x   // {c,s,x}
5: ifn b goto 9 // {b,c,s,x}
6: s <- c + s   // {c,s,x}
7: c <- c + 1   // {c,s,x}
8: goto 4       // {c,s,x}
9: r_ret <- s   // {s}
10: ret         // {}
```
In the above we find a sum program with liveness analysis results included as comments.

Let's convert it into SSA.

```js
// PA_SSA4
1: x1 <- input1  // {input1(1)}
2: s1 <- 0       // {x1(4)}
3: c1 <- 0       // {s1(4),x1(4)}
4: c2 <- phi(3:c1, 8:c3)
   s2 <- phi(3:s1, 8:s3)
   b1 <- c2 < x1 // {c2(4),s2(6,9),x1(4)}
5: ifn b1 goto 9 // {b1(5),c2(6),s2(6,9),x1(4)}
6: s3 <- c2 + s2 // {c2(6),s2(6),x1(4)}
7: c3 <- c2 + 1  // {c2(7),s3(4),x1(4)}
8: goto 4        // {c3(4),s3(4),x1(4)}
9: r_ret <- s2   // {s2(9)}
10: ret          // {}
```
We put the liveness analysis results as comments. 

There are a few options of handling phi assignments.

1. Treat them like normal assignment, i.e. translate them back to move instruction (refer to "SSA back to Pseudo Assembly" in the name analysis lesson.) This is the most conservative approach definitely work, but not necessary giving us optimized code
1. Ensure the variables in the phi assignments sharing the same registers. 

Let's consider the first approach 

##### Conservative approach 

When we translate the SSA back to PA


```js
// PA_SSA_PA4
1: x1 <- input1  // {input1(1)}
2: s1 <- 0       // {x1(4)}
3: c1 <- 0       // {s1(3.1),x1(4)}
3.1: c2 <- c1     
     s2 <- s1    // {s1(3.1),x1(4),c1(3.1)}
4: b1 <- c2 < x1 // {c2(4),s2(6,9),x1(4)}
5: ifn b1 goto 9 // {b1(5),c2(6),s2(6,9),x1(4)}
6: s3 <- c2 + s2 // {c2(6),s2(6),x1(4)}
7: c3 <- c2 + 1  // {c2(7),s3(7.1),x1(4)}
7.1: c2 <- c3
     s2 <- s3    // {s3(7.1),x1(4),c3(7.1)}
8: goto 4        // {c2(4),s2(6,9),x1(4)}
9: r_ret <- s2   // {s2(9)}
10: ret          // {}
```

It is clear that the program is allocatable without spilling with 4 registers. Let's challenge ourselves with just 3 registers.

|var   | 1 | 2 | 3 |3.1| 4 | 5 | 6 | 7 |7.1| 8 | 9 |10 |reg|
|---   |---|---|---|---|---|---|---|---|---|---|---|---|---|
|input1| * |   |   |   |   |   |   |   |   |   |   |   |r0 |
|x1    |   | * | * | * | * | - | - | - | - | - |   |   |r1 |
|s1    |   |   | * | * |   |   |   |   |   |   |   |   |r2 |
|c1    |   |   |   | * |   |   |   |   |   |   |   |   |r0 |
|s2    |   |   |   |   | * | * | * |   |   | * | * |   |r2 |
|c2    |   |   |   |   | * | * | * | * |   | * |   |   |r0 |
|b1    |   |   |   |   |   | * |   |   |   |   |   |   |r1 |   
|s3    |   |   |   |   |   |   |   | * | * |   |   |   |r2 |   
|c3    |   |   |   |   |   |   |   |   | * |   |   |   |r0 |   


At the peak of the live variables, i.e. instruction `5`, we realize that `x1` is live but not urgently needed until `4` which is 5-hop away from the current location. Hence we spill it from register `r1` to the temporary variable to free up `r1`.  Registers are allocated by the next available in round-robin manner.

```js
// PA4_REG1
1: r0 <- input1  // input is r0
   r1 <- r0      // x1 is r1
2: r2 <- 0       // s1 is r2
3: r0 <- 0       // c1 is r0
                 // c2 is r0 
                 // s2 is r2
                 // no need to load r1 from x1
                 // b/c x1 is still active in r1
                 // from 3 to 4
4: x1 <- r1      // spill r1 to x1
   r1 <- r0 < r1 // b1 is r1
5: ifn r1 goto 9 // 
6: r2 <- r0 + r2 // s3 is r2
7: r0 <- r0 + 1  // c3 is r0
                 // c2 is r0
                 // s2 is r2
8: r1 <- x1      // restore r1 from x1
   goto 4        // b/c x1 is inactive but needed in 4
9: r_ret <- r2   // 
10: ret          // 
```

What if at instruction `7`, we allocate `r1` to `s3` instead of `r2`? Thanks to some indeterminism, we could have a slightly different register allocation as follows


|var   | 1 | 2 | 3 |3.1| 4 | 5 | 6 | 7 |7.1| 8 | 9 |10 |reg|
|---   |---|---|---|---|---|---|---|---|---|---|---|---|---|
|input1| * |   |   |   |   |   |   |   |   |   |   |   |r0 |
|x1    |   | * | * | * | * | - | - | - | - | - |   |   |r1 |
|s1    |   |   | * | * |   |   |   |   |   |   |   |   |r2 |
|c1    |   |   |   | * |   |   |   |   |   |   |   |   |r0 |
|s2    |   |   |   |   | * | * | * |   |   | * | * |   |r2 |
|c2    |   |   |   |   | * | * | * | * |   | * |   |   |r0 |
|b1    |   |   |   |   |   | * |   |   |   |   |   |   |r1 |   
|s3    |   |   |   |   |   |   |   | * | * |   |   |   |**r1** |   
|c3    |   |   |   |   |   |   |   |   | * |   |   |   |**r2** |   



```js
// PA4_REG2
1: r0 <- input1  // input is r0
   r1 <- r0      // x1 is r1
2: r2 <- 0       // s1 is r2
3: r0 <- 0       // c1 is r0
                 // c2 is r0 
                 // s2 is r2
                 // no need to load r1 from x1
                 // b/c x1 is still active in r1
                 // from 3 to 4
4: x1 <- r1      // spill r1 to x1
   r1 <- r0 < r1 // b1 is r1
5: ifn r1 goto 9 // 
6: r1 <- r0 + r2 // s3 is r1
7: r2 <- r0 + 1  // c3 is r2
7.1: r0 <- r2    // c2 is r0  
     r2 <- r1    // s2 is r2
8: r1 <- x1      // restore r1 from x1 
   goto 4        // b/c x1 is inactive but needed in 4
9: r_ret <- s2   
10: ret          
```

In this case we have to introduce some additional register shuffling at `7.1`. Compared to `PA4_REG1`, this result is less efficient.


##### Register coalesced approach - Ensure the variables in the phi assignments sharing the same registers

Note that we should not enforce the variable on the LHS of a phi assignment to share the same register as the operands on the RHS.
Otherwise, we could lose the chordal graph property of SSA. 

What we could construct the live range table as follow.

|var   | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |10 |reg|
|---   |---|---|---|---|---|---|---|---|---|---|---|
|input1| * |   |   |   |   |   |   |   |   |   |r0 |
|x1    |   | * | * | * | - | - | - | - |   |   |r1 |
|s1    |   |   | * |   |   |   |   |   |   |   |r2 |
|c1    |   |   |   |   |   |   |   |   |   |   |r0 |
|s2    |   |   |   | * | * | * |   |   | * |   |r2 |
|c2    |   |   |   | * | * | * | * |   |   |   |r0 |
|b1    |   |   |   |   | * |   |   |   |   |   |r1 |   
|s3    |   |   |   |   |   |   | * | * |   |   |r2 |   
|c3    |   |   |   |   |   |   |   | * |   |   |r0 |  

Although from the above we find `c1` seems to be always dead, but it is not, because its value is merged into c2 in label `4`. This is because in our SSA language, the phi assignment is not an instruction alone while liveness analysis is performed on per instruction level.

We also take note we want to `c1` and `c3` to share the same register, and `s1` and `s3`to share the same register. Hence we can allocate the 3 registers according to the above plan. In this case, we have the same result as the first attempt in the conservative approach `PA4_REG1`.

Note that this approach is not guanranteed to produce more efficient results than the conversvative approach. 


#### Summary so far

To sum up the code generation process from PA to 3-address target could be carried out as follows,

1. Convert the PA program into a SSA.
1. Perform Liveness Analysis on the SSA. 
1. Generate the live range table based on the liveness analysis results.
1. Allocate registers based on the live range table. Detect potential spilling.
1. Depending on the last approach, either
    1. convert SSA back to PA and generate the target code according to the live range table, or 
    1. generate the target code from SSA with register coalesced for the phi assignment operands.


#### Further Reading for SSA-based Register Allocation

* https://compilers.cs.uni-saarland.de/papers/ssara.pdf
* https://dl.acm.org/doi/10.1145/512529.512534


## WASM bytecode (reduced set)

In this section, we consider the generated Web Assembly (WASM) codes from PA. 

$$
\begin{array}{rccl}
(\tt WASM\ Instructions) & wis & ::= & [] \mid wi;wis\\ 
(\tt WASM\ Instruction) & wi & ::= & pi \mid bi \\ 
(\tt Plain\ Instruction) & pi & ::= & nop \mid br\ L \mid brIf\ L \mid return \mid get\ n \mid set\ n \mid \\ 
& & & const\ c \mid add \mid sub \mid mul \mid eq \mid lt \\
(\tt Block\ Instruction) & bi & ::= & block \{ wis \} \mid loop \{ wis \} \mid if \{wis\} else \{wis\} \\ 
(\tt WASM\ vars) & n & ::= & 1 \mid 2 \mid ... \\ 
(\tt constant) & c & ::= & -32768 \mid ... \mid 0 \mid ... \mid 32767 
\end{array}
$$

As mentioned, WASM has 3 registers

1. a register for the first operand and result
1. a register for the second operand
1. a register for controlling the state of the stack operation (we can't used.)

Technically speaking we only have 2 registers.

An Example of WASM byte codes is illustrated as follows

Supposed we have a PA program as follows,
```js
1: x <- input
2: s <- 0
3: c <- 0
4: b <- c < x
5: ifn b goto 9
6: s <- c + s
7: c <- c + 1
8: goto 4
9: _ret_r <- s
10: ret
```

For ease of reasoning, we assume that we map PA temporary variables to WASM variables with the same names. 

```wasm
get input
set x
const 0
set s
const 0
set c
get c
get x
lt
if {
    loop {
        block {
            get s
            get c
            add
            set s
            get c
            const 1
            add
            set c
        }
        get c
        get x
        lt
        if {
            br 1
        } else { }
    }
} else { }
get s
return
```

## WASM bytecode operational semantics 

To describe the operational semantics of WASM bytecodes, we define the following meta symbols.

$$
\begin{array}{rccl}
(\tt WASM\ Environment) & \Delta & \subseteq & n \times c \\ 
(\tt Value\ Stack) & S & = & \_,\_ \mid c,\_ \mid c,c  \\ 
(\tt Block\ Instruction\ Stack) & B & = & [] \mid (bi,wis);B
\end{array}
$$

 $\Delta$ is local environment that maps WASM variables to constants. $S$ is a 2-slot stack where the left slot is the bottom ($r_0$) and the right slot is the top ($r_1$). $\_$ denotes that a slot is vacant. $B$ is a many-slot stack. Each stack frame captures the current block instruction and its following instructions. We assume that the size of $B$ is unbounded. 

We can decribe the operational semantics of WASM byte codes using the follow rule form


$$ 
(\Delta, S, wis, B) \longrightarrow (\Delta', S', wis', B')
$$

The rule rewrites a configuration $(\Delta, S, wis, B)$ to the next configuration $(\Delta', S', wis', B')$, where $\Delta$ and $\Delta'$ are the current and the next states of the local environment, $S$ and $S'$ are the current and the next states of the value stack, $wis$ and $wis'$ are the currrent and next sets of instructions to be processed,
$B$ and $B'$ are the current and the next states of the block stack.

$$
\begin{array}{rc}
(\tt get1) & (\Delta, \_, \_, get\ n; wis, B) \longrightarrow (\Delta, \Delta(n), \_, wis, B) \\ \\ 
(\tt get2) & (\Delta, c, \_, get\ n; wis, B) \longrightarrow (\Delta, c, \Delta(n), wis, B) \\ \\ 
(\tt const1) & (\Delta, \_, \_, const\ c;wis, B) \longrightarrow (\Delta, c, \_, wis, B) \\ \\ 
(\tt const2) & (\Delta, c_0, \_, cosnt\ c_1;wis, B) \longrightarrow (\Delta, c_0, c_1, wis, B)
\end{array}
$$

The rules $(\tt get1)$ and  $(\tt get2)$ handles the loading variable's content to the stack registers. 
The rules $(\tt const1)$ and  $(\tt const2)$ handles the loading constant to the stack registers. 


$$
\begin{array}{rc}
(\tt set) & (\Delta, c, \_, set\ n;wis, B) \longrightarrow (\Delta \oplus(n,c), \_, \_, wis, B) \\ \\ 
\end{array}
$$

The rule $(\tt set)$ processes the $set\ n$ instruction by popping the register $r_0$ from the stack and store its content with variable $n$ in $\Delta$.

$$
\begin{array}{rc}
(\tt add) & (\Delta, c_0, c_1, add;wis, B) \longrightarrow (\Delta, c_0+c_1, \_, wis, B) \\ \\ 
(\tt sub) & (\Delta, c_0, c_1, sub;wis, B) \longrightarrow (\Delta, c_0-c_1, \_, wis, B) \\ \\ 
(\tt mul) & (\Delta, c_0, c_1, mul;wis, B) \longrightarrow (\Delta, c_0*c_1, \_, wis, B)  
\end{array}
$$

The rules $(\tt add)$, $(\tt sub)$ and $(\tt mul)$ process the binary operation assuming both registers in the stack holding some constants. The result of the computation is stored in $r_0$ while $r_1$ becomes empty.

$$
\begin{array}{rc}
(\tt eq1) & \begin{array}{c} 
                c_0 == c_1 
                \\ \hline
                (\Delta, c_0, c_1, eq;wis, B) \longrightarrow (\Delta, 1, \_, wis, B) 
                \end{array} \\ \\
(\tt eq2) & \begin{array}{c} 
                c_0 \neq c_1 
                \\ \hline
                (\Delta, c_0, c_1, eq;wis, B) \longrightarrow (\Delta , 0, \_, wis, B) 
                \end{array} \\ \\ 
(\tt lt1) & \begin{array}{c} 
                c_0 < c_1 
                \\ \hline
                (\Delta, c_0, c_1, lt;wis, B) \longrightarrow (\Delta, 1, \_, wis, B) 
                \end{array} \\ \\
(\tt lt2) & \begin{array}{c} 
                c_0 >= c_1 
                \\ \hline
                (\Delta, c_0, c_1, lt;wis, B) \longrightarrow (\Delta , 0, \_, wis, B) 
                \end{array} \\ \\ 
\end{array}
$$

The rules $(\tt eq1)$, $(\tt eq2)$, ${\tt lt1}$ and $(\tt lt2)$ process the boolean operation assuming both registers in the stack holding some constants. The result of the computation is stored in $r_0$ while $r_1$ becomes empty.

The next set of rules evaluate by pushing block instructions to the block instruction stack. 

$$
\begin{array}{cc}
(\tt block) & (\Delta, r_0, r_1, block \{wis\};wis', B) \longrightarrow (\Delta, r_0, r_1, wis, (block\{wis\}, wis');B) \\ \\ 
(\tt loop) & (\Delta, r_0, r_1, loop \{wis\};wis', B) \longrightarrow (\Delta, r_0, r_1, wis, (loop\{wis\}, wis');B) \\ \\ 
(\tt ifT) &   (\Delta, 1, \_, if\{wis\} else\{wis'\};wis'', B) \longrightarrow (\Delta, \_, \_, wis, (block \{wis\}, wis''); B) 
\\ \\ 
(\tt ifF) &   (\Delta, 0, \_, if\{wis\} else\{wis'\};wis'', B) \longrightarrow (\Delta, \_, \_, wis', (block \{wis'\}, wis''); B) 
\end{array}
$$


* The rule $(\tt block)$ processes a sequence of instructions starting with a block instruction. It proceeds by evaluating the body of the block instruction and pushing the block instruction and its following instructions into the block instruction stack. 
* The rule ${\tt loop}$ works in a similar manner. 
* The rules $(\tt ifT)$ and $(\tt ifF)$ handle the if-instruction. Depending on the value residing in register `0` in the value stack, it proceeds with evaluating the then-instructions or the else-instructions, by pushing the to-be-evaluated instruction and the following instructions into the block instruction stack as a "block instruction".  


The next set of rules evaluate by popping the top of the block instruction stack.


$$
\begin{array}{cc}
(\tt br0Block) &  (\Delta, r_0, r_1, br\ 0,(block \{wis'\}, wis'');B) \longrightarrow (\Delta, r_0, r_1, wis'', B) 
\\ \\ 
(\tt br0Loop) &  (\Delta, r_0, r_1, br\ 0,(loop \{wis'\}, wis'');B) \longrightarrow (\Delta, r_0, r_1, wis', (loop \{wis'\}, wis'');B) 
\\ \\ 
(\tt brN) &  (\Delta, r_0, r_1, br\ n,(bi, wis);B) \longrightarrow (\Delta, r_0, r_1, br\ (n-1), B) \\ \\ 
(\tt brIfT0Block) &  (\Delta, 1, \_, brIf\ 0;wis,(block \{wis'\}, wis'');B) \longrightarrow (\Delta, \_, \_, wis'', B) \\ \\ 
(\tt brIfT0Loop) &  (\Delta, 1, \_, brIf\ 0;wis,(loop \{wis'\}, wis'');B) \longrightarrow (\Delta, \_, \_, wis', (loop \{wis'\}, wis'');B) 
\\ \\ 
(\tt brIfTN) &  (\Delta, 1, \_, brIf\ n;wis,(bi, wis');B) \longrightarrow (\Delta, 1, \_, brIf\ (n-1), B) \\ \\ 
(\tt brIfF) & (\Delta, 0, \_, brIf\ _;wis, B) \longrightarrow (\Delta, \_, \_, wis, B)
\end{array}
$$

* The rules $(\tt br0Block)$ and $(\tt br0Loop)$ handle the case in which a branch instruction is applied with `0`. 

    1. When the top of the block instruction stack is a block instruction, the computation proceeds with the "continuation" of the block instruction, namely $wis''$. 
    1. When the top of hte stack is a loop instruction, the computation proceeds by going through another iteration of the loop. 

* The rule $(\tt brN)$ handle the case in which the branch instruction's operaand is a positive integer $n$, the computation proceeds by evaluating the branch operation with $n-1$ with the top of the block instruction stack removed.  

* The rules $(\tt brIfT0Block)$ and $(\tt brIfT0Loop)$ process the conditional branch instructions in the similar with as $(\tt br0Block)$ and $(\tt br0Loop)$, except that they are applicable only when the register 0 is storing the value `1`. 
* The rule $(\tt brIfTN)$ is similar to $(\tt brN)$, excep that it is applicable when the register 0 is having value `1`.
* The rule $(\tt brIfF)$ is applied when the register `0` is having value `0` and skips the the conditional branch.



The last set of rules handle the no-op and empty instruction sequence. 

$$
\begin{array}{cc}
(\tt Nop) &  (\Delta, r_0, r_1, nop;wis,B) \longrightarrow (\Delta, r_0, r_1, wis, B) \\ \\ 
(\tt empty) & (\Delta, r_0, r_1, [], (bi, wis');B ) \longrightarrow (\Delta, r_0, r_1, wis', B)
\end{array}
$$

The $(\tt Nop)$ rule skip the $nop$ instruction. The $(\tt empty)$ rule denotes the end of the current sequence and proceeds with the "following" instructions in the block instruction stack. 


## Conversion from PA to WASM bytecodes

A simple conversion from PA to WASM bytecodes can be described using the following deduction system.

Let $M$ be a mapping from PA temporary variables to WASM local variables.

We have three types of rules.

* $M \vdash lis \Rightarrow wis$, converts a sequence of PA labeled instructions to a sequence of WASM bytecode instructions.
* $M \vdash_{src} s \Rightarrow wis$, converts a PA (source) operand into a sequence of WASM bytecode instructions.
* $M(t)$, converts a PA variable into a WASM variable. 

### Converting PA labeled instructions

$$
\begin{array}{rl}
    {\tt (wReturn)} & \begin{array}{c}
                M \vdash_{src} s \Rightarrow wis_1 \\
                \hline
                M \vdash l_1:rret \leftarrow s;  l_2: ret \Rightarrow wis_1 + [return] 
            \end{array} \\   
\end{array}
$$

The rule ${\tt (wReturn)}$ convers the PA return instructions. It first converts the operand $s$ into a sequence of WASM instructions $wis_1$. At this stage, the content of $s$ must have been loaded to the register 0. Next we invoke the WASM $return$.


$$
\begin{array}{rl}
    {\tt (wMove)} & \begin{array}{c}
                M \vdash_{src} s \Rightarrow wis_1\ M \vdash lis \Rightarrow wis_2\\
                \hline
                M \vdash l: t \leftarrow s;  lis \Rightarrow wis_1 + [set\ M(t) ] +wis_2 
            \end{array} \\   
\end{array}
$$


The rule ${\tt (wMove)}$ handles the case of a move instruction. In this case we make use of the auxiliary rule $M \vdash s \Rightarrow wis_1$ to convert the operand $s$ into a loading instruction in WASM bytecodes. The content of $s$ should be now in the regstier. We make use of $get\ M(t)$ to transfer the value into the WASM variable $M(t)$. Details fo these auxiliary functions can be found in the next subsection. Using recursion, we convert the instructions sequence $lis$ into $wis_2$. 
                        

$$
\begin{array}{rc}
     {\tt (wEqLoop)} & \begin{array}{c}
                    (l_3-1):goto\ l_4 \in lis' \\ l_4 == l_1 \\ lis_1, lis_2 = split(l_3, lis') \\  
                    M \vdash_{src} s_1 \Rightarrow wis_1 \ \ \ M \vdash_{src} s_2 \Rightarrow wis_2 \\
                    M \vdash lis_1 \Rightarrow wis_3 \ \ \ M \vdash lis_2 \Rightarrow wis_4 \\ 
                    \hline
                    M, L \vdash l_1:t \leftarrow s_1 == s_2; l_2:ifn\ t\ goto\ l_3 ; lis \Rightarrow \\ 
                     wis_1 + wis_2 + [eq, if \{ loop \{ wis_3 + wis_1 + wis_2 + [ eq, brIf\ 0 ] \} \} else \{ nop \}] + wis_4
                \end{array} 
\\ \\
     {\tt (wEqIf)} & \begin{array}{c}
                    (l_3-1):goto\ l_4 \in lis' \\ l_4 \neq l_1 \\ 
                    lis_1, lis_2 = split(l_3, lis') \\ 
                    lis_3, lis_4 = split(l_4, lis_2) \\  
                    M \vdash_{src} s_1 \Rightarrow wis_1 \ \ \ M \vdash_{src} s_2 \Rightarrow wis_2 \\
                    M \vdash lis_1 \Rightarrow wis_3 \ \ \ M \vdash lis_2 \Rightarrow wis_4 \ \ \ M \vdash lis_4 \Rightarrow wis_5 \\ 
                    \hline
                    M, L \vdash l_1:t \leftarrow s_1 == s_2; l_2:ifn\ t\ goto\ l_3 ; lis' \Rightarrow \\ 
                     wis_1 + wis_2 + [eq, if \{ wis_3 \} else \{ wis_4 \}] + wis_5
                \end{array} 
\end{array}
$$                            

The rules ${\tt (wEqLoop)}$ and ${\tt (wEqIf)}$ deal with the scenarios in which the leading PA instructions are an equality test followed by a conditional jump. There are two sub cases. 

1. When the target of the condional jump, $l_3$ has an preceding instruction is a $goto\ l_4$ where $l_4$ is the label of the equality test. We conclude that this PA sequence is translated from a loop in the source SIMP program.  We apply an auxilary function $split(l_3, lis')$ to split $lis'$ into two sub sequences $lis_1$ and $lis_2$ by $l_3$, $lis_1$ must be the body of the loop. and $lis_2$ are the following instructions after the loop. We compile operands of the equality test into $wis_1$ and $wis_2$. We concatenate an $eq$ instruction with a $if$ nested $loop$ block. $wis_3$ is the compiled WASM codes of the loop body, and $wis_4$ is the compiled codes of the instructions following the loop.
2. When the target of the condition jump, $l_3$ has a preceding instruction is a $goto\ l_4$ where the l_4$ is not the label of the equality test. We conclude that this PA sequence is translated from a if-else statement from the source SIMP program and $l_4$ should be the end of loop. This is because our maximal munch algorithm is structure-preserving, i.e. we insert jumping labels at the end of the then and else branches. 


$$
\begin{array}{rc}
     {\tt (wEq)} & \begin{array}{c}
                    M \vdash_{src} s_1 \Rightarrow wis_1 \ \ \ M \vdash_{src} s_2 \Rightarrow wis_2 \\
                    M \vdash lis' \Rightarrow wis_3 \ \ \ head(lis')  \texttt{is not an } ifn\ \texttt{instruction} \\ 
                    \hline
                    M, L \vdash l_1:t \leftarrow s_1 == s_2; lis' \Rightarrow \\ 
                     wis_1 + wis_2 + [eq] + wis_3
                \end{array} 
\end{array}
$$

The rule $(\tt wEq)$ handles a normal equality test which is not followed by a conditional jump.


$$
\begin{array}{rc}
     {\tt (wLtLoop)} & \begin{array}{c}
                    (l_3-1):goto\ l_4 \in lis' \\ l_4 == l_1 \\ lis_1, lis_2 = split(l_3, lis') \\  
                    M \vdash_{src} s_1 \Rightarrow wis_1 \ \ \ M \vdash_{src} s_2 \Rightarrow wis_2 \\
                    M \vdash lis_1 \Rightarrow wis_3 \ \ \ M \vdash lis_2 \Rightarrow wis_4 \\ 
                    \hline
                    M, L \vdash l_1:t \leftarrow s_1 < s_2; l_2:ifn\ t\ goto\ l_3 ; lis \Rightarrow \\ 
                     wis_1 + wis_2 + [lt, if \{ loop \{ wis_3 + wis_1 + wis_2 + [ eq, brIf\ 0 ] \} \} else \{ nop \}] + wis_4
                \end{array} 
\\ \\
     {\tt (wLtIf)} & \begin{array}{c}
                    (l_3-1):goto\ l_4 \in lis' \\ l_4 \neq l_1 \\ 
                    lis_1, lis_2 = split(l_3, lis') \\ 
                    lis_3, lis_4 = split(l_4, lis_2) \\  
                    M \vdash_{src} s_1 \Rightarrow wis_1 \ \ \ M \vdash_{src} s_2 \Rightarrow wis_2 \\
                    M \vdash lis_1 \Rightarrow wis_3 \ \ \ M \vdash lis_2 \Rightarrow wis_4 \ \ \ M \vdash lis_4 \Rightarrow wis_5 \\ 
                    \hline
                    M, L \vdash l_1:t \leftarrow s_1 < s_2; l_2:ifn\ t\ goto\ l_3 ; lis' \Rightarrow \\ 
                     wis_1 + wis_2 + [lt, if \{ wis_3 \} else \{ wis_4 \}] + wis_5
                \end{array} 
\\ \\ 
     {\tt (wLt)} & \begin{array}{c}                     
                    M \vdash_{src} s_1 \Rightarrow wis_1 \ \ \ M \vdash_{src} s_2 \Rightarrow wis_2 \\
                    M \vdash lis' \Rightarrow wis_3 \ \ \ head(lis')  \texttt{is not an } ifn\ \texttt{instruction}\\ 
                    \hline
                    M, L \vdash l_1:t \leftarrow s_1 < s_2; lis' \Rightarrow \\ 
                     wis_1 + wis_2 + [lt] + wis_3
                \end{array} 
\end{array}
$$

The above rules ${\tt (wLtLoop)}$, ${\tt (wLtIf)}$ and ${\tt (wLt)}$ handle the less than test. They are similar to their equality test counter-parts described earlier. 

$$
\begin{array}{rc}
     {\tt (wPlus)} & \begin{array}{c}
                    M \vdash_{src} s_1 \Rightarrow wis_1 \ \ \ M \vdash_{src} s_2 \Rightarrow wis_2 \ \ \ M \vdash lis' \Rightarrow wis_3 \\
                    \hline
                    M \vdash l:t \leftarrow s_1 + s_2; lis' \Rightarrow wis_1 + wis_2 + [add, set\ M(t)] + wis_3
                \end{array} \\ \\  
     {\tt (wMinus)} & \begin{array}{c}
                    M \vdash_{src} s_1 \Rightarrow wis_1 \ \ \ M \vdash_{src} s_2 \Rightarrow wis_2 \ \ \ M \vdash lis' \Rightarrow wis_3 \\
                    \hline
                    M \vdash l:t \leftarrow s_1 - s_2; lis' \Rightarrow wis_1 + wis_2 + [sub, set\ M(t)] + wis_3
                \end{array} \\ \\  
     {\tt (wMult)} & \begin{array}{c}
                    M \vdash_{src} s_1 \Rightarrow wis_1 \ \ \ M \vdash_{src} s_2 \Rightarrow wis_2 \ \ \ M \vdash lis' \Rightarrow wis_3 \\
                    \hline
                    M \vdash l:t \leftarrow s_1 * s_2; lis' \Rightarrow wis_1 + wis_2 + [mul, set\ M(t)] + wis_3
                \end{array} \\ \\  
    {\tt (wGoto)} & \begin{array}{c}
                     M \vdash lis' \Rightarrow wis \\
                    \hline
                    M \vdash l: goto\ l'; lis' \Rightarrow wis
                \end{array} \\ \\  
\end{array}
$$

Lastly, the rules ${\tt (wPlus)}$, ${\tt (wMinus)}$ and  ${\tt (wMult)}$ convert the binary arithmetic operations. ${\tt (wGoto)}$ skips the goto instruction, which should be handled by the other rules. 





### Converting PA Source Operands

$$
\begin{array}{rl}
{\tt (Const)} & M \vdash_{src} c \Rightarrow [const\ c] \\ \\ 
{\tt (Var)} & M \vdash_{src} t \Rightarrow [get\ M(t)] \\ \\ 
\end{array}
$$


## Optimizing WASM bytecode 

Though it is limited, there is room to optimize the WASM bytecode. For example, 

From the following SIMP program 


```js
r = (1 + 2) * 3
```

we generate the following PA code via the Maximal Munch

```js
1: t <- 1 + 2
2: r <- t * 3  
```

In turn if we apply the above PA to JVM bytecode conversion

```js
const 1
const 2
add
get t 
set t
const 3
mul
get r 
```
As observe, the `get t` followed by `set t` are rundandant, because `t` is not needed later (dead).

```js
const 1
const 2
add
const 3
mul
get r 
```

This can either be done via 

1. Liveness analysis on PA level or 
2. Generate WASM byte code directly from SIMP.
    * This requires the expression of SIMP assignment to be left nested. 
    * The conversion is beyond the scope of this module.


### Prettier WASM syntax - Folded Expression

WASM supports a prettier syntax, known as folded expression. 


$$
\begin{array}{rccl}
(\tt Plain\ Instruction (Folded)) & pi & ::= & nop \mid br\ L \mid brIf\ L \mid return\ oi \mid set\ n\ oi \mid oi \\ 
(\tt Operand\ Instruction) & oi & ::= & get\ n \mid const\ c \mid add\ oi\ oi \mid sub\ oi\ oi  \mid mul\ oi\ oi  \mid eq\ oi\ oi  \mid lt\ oi\ oi  \\ 
(\tt Block\ Instruction (Folded)) & bi & ::= & block \{ wis \} \mid loop \{ wis \} \mid if\ oi \{wis\} else \{wis\} \\ 
\end{array}
$$

The earlier WASM example can be rewritten as the following in folded expression form.

```wasm
set x (get input)
set s (const 0)
set c (const 0)
if (lt (get c) (get x)) {
    loop {
        block {            
            set s (add (get s) (get c))
            set c (add (get c) (const 1))
        }
        if (lt (get c) (get x)) {
            br 1
        } else { }
    }
} else { }
return (get s)
```
which is closer to source program. 

In the project, we'll find the PA to WASM conversion rules being re-phrased into the folded expression form.

#### Further Reading for WASM bytecode generation

* https://webassembly.org/
* https://developer.mozilla.org/en-US/docs/WebAssembly/Reference

### Summary for WASM bytecode generation

* To generate WASM bytecode w/o optimization can be done via deduction system
* To optimize WASM bytecode, we could apply liveness analysis to eliminate redundant store-then-load sequence.