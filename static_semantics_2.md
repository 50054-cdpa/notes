# 50.054 Static Semantics for Lambda Calculus


## Learning Outcomes

1. Apply type checking algorithm to type check a simply typed lambda calculus expression.
1. Apply Hindley Milner algorithm to type check lambda calculus expressions.
1. Apply Algorithm W to infer type for lambda calculus.



## Type Checking for Lambda Calculus

To illustrate the proocess of type checking for lambda calculus, we consider adding types and type annotations to the lambda calculus language. 

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
                      \end{array} \\ \\  
{\tt (lctBool)} & \begin{array}{c} 
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
               \Gamma \vdash \lambda x : T.t :T \rightarrow T' 
               \end{array} 
\end{array}
$$
In rule ${\tt (lctLam)}$, we type check a lambda abstraction against a type $T\rightarrow T'$. This is only valid if the body of the lambda expression $t$ has type $T'$ under the extended type environment $\Gamma \oplus (x, T)$.
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

Let $t$ be a simply typed lambda calculus term. Let $\Gamma$ be a type environment such that for all $x \in fv(t)$, $x \in dom(\Gamma)$. Let $T$ and $T'$ be types such that $\Gamma \vdash t : T$ and $\Gamma \vdash t:T'$.
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

### Issue with let-binding

The current type checking rules for Simply-typed Lambda Calculus fails to type check the following lambda calculus term.

$$
\begin{array}{l}
let\ f = \lambda x:\alpha.x \\
in\ let\ g = \lambda x:int.\lambda y:bool.x \\ 
\ \ \ \ in\ (g\ (f\ 1)\ (f\ true))
\end{array}
$$

Where $\alpha$ denotes some generic type.
This is due to the fact that we can only give one type to `f`, either $Int \rightarrow Int$ or $Bool \rightarrow Bool$ but not both.


To type check the above program we need to get rid of the type annotations to the let binding (as well as lambda abstraction). This leads us to the *Hindley-Milner* Type System.

### Hindley Milner Type System 

We define the lambda calculus syntax for Hindley Milner Type System as follows

$$
\begin{array}{rccl}
 {\tt (Lambda\ Terms)} & t & ::= & x \mid \lambda x.t \mid t\ t \mid let\ x =\ t\ in\ t \mid  if\ t\ then\ t\ else\ t \mid t\ op\ t \mid c \mid fix\ t \\
 {\tt (Builtin\ Operators)} & op & ::= & + \mid - \mid * \mid / \mid\ == \\
 {\tt (Builtin\ Constants)} & c & ::= & 0 \mid 1 \mid ... \mid true \mid false \\
 {\tt (Types)} & T & ::= & int \mid bool \mid T \rightarrow T \mid \alpha \\ 
 {\tt (Type Scheme)} & \sigma & ::= & \forall \alpha. T \mid T \\ 
 {\tt (Type\ Environments)} & \Gamma & \subseteq & (x \times \sigma ) \\
 {\tt (Type\ Substitution)} & \Psi & ::= & [T/\alpha] \mid [] \mid \Psi \circ \Psi 
\end{array}
$$

In the above grammar rules, we remove the type annotations from the lambda abstraction and let binding. Our type inference algorithm should be able to recover them.  We add the type variable directly to the type $T$ rule instead of introducing the $\hat{T}$ rule for conciseness. We introduce a type scheme term $\sigma$ which is required for polymorphic types.  


We describe the Hindley Milner Type Checking rules as follows


$$
\begin{array}{rc}
{\tt (hmInt)} & \begin{array}{c} \\
                      c\ {\tt is\ an\ integer}
                      \\ \hline
                      \Gamma \vdash c : int
                      \end{array} \\ \\ 
{\tt (hmBool)} & \begin{array}{c} 
                      c\in \{ true, false\}
                      \\ \hline
                      \Gamma \vdash c : bool
                      \end{array}
\end{array}
$$
The rules for constants remain unchanged. 

$$
\begin{array}{rc}
{\tt (hmVar)} & \begin{array}{c}
                (x,\sigma) \in \Gamma
                \\ \hline
                \Gamma \vdash x : \sigma
                \end{array} 
\end{array}
$$

The rule for variable is adjusted to use type signatures instead of types.


$$
\begin{array}{rc}
{\tt (hmLam)} & \begin{array}{c}
               \Gamma \oplus (x, T) \vdash t : T'  \\
               \hline
               \Gamma \vdash \lambda x.t :T\rightarrow T' 
               \end{array} \\ \\ 
{\tt (hmApp)} & \begin{array}{c}
               \Gamma \vdash t_1 : T_1 \rightarrow T_2 \ \ \ \
               \Gamma \vdash t_2 : T_1 \\
               \hline
               \Gamma \vdash  t_1\ t_2 :T_2 
               \end{array} 
\end{array}
$$

In rule ${\tt (hmLam)}$ we type check the lambda abstraction against $T\rightarrow T'$. It is largely the same as the ${\tt (lctLam)}$ rule for simply typed lambda calculus, except that there is no type annotation to the lambda bound variable $x$.
The rule ${\tt (hmApp)}$ is exactly the same as ${\tt (lctApp)}$. 

$$
\begin{array}{rc}
{\tt (hmFix)} & \begin{array}{c}
                (fix,\forall \alpha. (\alpha\rightarrow \alpha)\rightarrow \alpha)\in \Gamma
                \\ \hline 
                \Gamma \vdash fix:\forall \alpha. (\alpha\rightarrow \alpha) \rightarrow \alpha
                \end{array}
\end{array}
$$
To type check the $fix$ operator, we assume that $fix$ is predefined in the language library and its type is given in the initial type environment $\Gamma_{init}$.


$$
\begin{array}{rc}
{\tt (hmIf)} & \begin{array}{c}
                \Gamma \vdash t_1 : bool \ \ \ 
                \Gamma \vdash t_2 : \sigma \ \ \ 
                \Gamma \vdash t_3 : \sigma 
                \\ \hline
                \Gamma \vdash if\ t_1\ \{ t_2\}\ else \{ t_3 \}: \sigma
               \end{array} \\ \\ 
\end{array}
$$
We made minor adjustment to the rule handling if-else expression, by replacing $T$ with $\sigma$.

$$
\begin{array}{rc}
{\tt (hmOp1)} & \begin{array}{c}
               \Gamma \vdash t_1 : int \ \ \ \Gamma \vdash t_2 : int \ \ \ op\in\{+,-,*,/\} \\
               \hline
               \Gamma \vdash  t_1\ op\ t_2 : int 
               \end{array} \\ \\ 
{\tt (hmOp2)} & \begin{array}{c}
               \Gamma \vdash t_1 : int \ \ \ \Gamma \vdash t_2 : int \\
               \hline
               \Gamma \vdash  t_1\ ==\ t_2 : bool 
               \end{array} \\ \\ 
{\tt (hmOp3)} & \begin{array}{c}
               \Gamma \vdash t_1 : bool \ \ \ \Gamma \vdash t_2 : bool \\
               \hline
               \Gamma \vdash  t_1\ ==\ t_2 : bool 
               \end{array} \\ \\  
\end{array}
$$
The type checking rules for binary operation remain unchanged.

$$
\begin{array}{rc}
{\tt (hmLet)} & \begin{array}{c}
               \Gamma \vdash t_1 : \sigma_1 \ \ \ \
               \Gamma \oplus (x, \sigma_1) \vdash t_2 : T_2 \\
               \hline
               \Gamma \vdash  let\ x = t_1\ in\ t_2 :T_2 
               \end{array} \\ \\ 
{\tt (hmInst)} & \begin{array}{c}
                \Gamma \vdash t : \sigma_1 \ \ \ \ \sigma_1 \sqsubseteq \sigma_2
                \\ \hline
                \Gamma \vdash t : \sigma_2
                \end{array} \\ \\ 
{\tt (hmGen)} & \begin{array}{c}
                \Gamma \vdash t : \sigma \ \ \ \ \alpha \not\in ftv(\Gamma)
                \\ \hline 
                \Gamma \vdash t : \forall \alpha.\sigma
                \end{array}
\end{array}
$$
In the rule ${\tt (hmLet)}$, we first type check $t_1$ againt $\sigma_1$, which is a type scheme, which allows $t_1$ to have a generic type. Under the extended type environment $\Gamma \oplus (x, \sigma_1)$ we type-check $t_2$. 

For the ${\tt (hmLet)}$ rule to work as intended, we need two more rules, namely, ${\tt (hmInst)}$ and ${\tt (hmGen)}$. In rule ${\tt (hmInst)}$ we allow a term $t$ to be type-checked against $\sigma_2$, provided we can type check it against $\sigma_1$ and $\sigma_1 \sqsubseteq \sigma_2$.



#### Definition - Type Instances
Let $\sigma_1$ and $\sigma_2$ be type schemes. We say $\sigma_1 \sqsubseteq \sigma_2$ iff $\sigma_1 = \forall \alpha. \sigma_1'$ and there exists a type subsitution $\Psi$ such that $\Psi(\sigma_1') = \sigma_2$.


In otherwords, we say $\sigma_1$ is more general that $\sigma_2$ and $\sigma_2$ is a type instance of $\sigma_1$.

Finally the rule ${\tt (hmGen)}$ generalizes existing type to type schemes. In this rule, if a term $t$ can be type-checked against a type scheme $\sigma$, then $t$ can also be type-checked against $\forall \alpha.\sigma$ if $\alpha$ is not a free type variable in $\Gamma$.

The type variable function $ftv()$ can be defined similar to the $fv()$ function we introduced for lambda caculus. 

$$
\begin{array}{rcl}
ftv(\alpha) & = & \{\alpha \} \\ 
ftv(int) & = & \{ \} \\
ftv(bool) & = & \{ \} \\
ftv(T_1 \rightarrow T_2) & = & ftv(T_1) \cup ftv(T_2) \\
ftv(\forall \alpha.\sigma) & = & ftv(\sigma) - \{ \alpha \} 
\end{array}
$$

$ftv()$ is also overloaded to extra free type variables from a type environment.

$$
\begin{array}{rcl}
ftv(\Gamma) & = & \{ \alpha \mid (x,\sigma) \in \Gamma \wedge \alpha \in ftv(\sigma) \}
\end{array}
$$


The application of a type substitution can be defined as 

$$
\begin{array}{rcll}
[] \sigma & = & \sigma \\ 
[T/\alpha] int & = & int \\
[T/\alpha] bool & = & bool \\ 
[T/\alpha] \alpha & = & T \\
[T/\alpha] \beta & = & \beta & \beta \neq \alpha \\ 
[T/\alpha] T_1 \rightarrow T_2 & = & ([T/\alpha] T_1) \rightarrow ([T/\alpha] T_2) \\ 
[T/\alpha] \forall \beta. \sigma & = & \forall \beta. ([T/\alpha]\sigma) & \beta \neq \alpha \wedge \beta \not \in ftv(T) \\ 
(\Psi_1 \circ \Psi_2)\sigma & = & \Psi_1 (\Psi_2 (\sigma))
\end{array}
$$

In case of applying a type subtitution to a type scheme, we need to check whether the quantified type variable $\beta$ is in conflict with the type substitution. In case of conflict, a renaming operation simiilar to $\alpha$ renaming will be applied to $\forall \beta. \sigma$. 

#### Example

Let's consider the type-checking derivation of our running (counter) example. 

Let `Γ = {}` and `Γ1 = {(f,∀α.α->α)}`.

```haskell
                           -------------------(hmVar)
                           Γ1⊕(x,β)⊕(y,γ)|-x:β 
                           --------------------(hmLam)
                           Γ1⊕(x,β)|-λy.x:γ->β
------------(hmVar)        -------------------(hmLam)
Γ⊕(x,α)|-x:α               Γ1|-λx.λy.x:β->γ->β   γ,β∉ftv(Γ1)
------------(hmLam)        --------------------------(hmGen)
Γ|-λx.x:α->α  	α∉ftv(Γ)   Γ1|-λx.λy.x:∀β.∀γ.β->γ->β          [subtree 1]
-----------------(hmGen)   -------------------------------------------(hmLet)
Γ|-λx.x:∀α.α->α            Γ1|-let g = λx.λy.x in (g (f 1) (f true)):int    
------------------------------------------------------------------- (hmLet)
Γ|-let f = λx.x in (let g = λx.λy.x in (g (f 1) (f true)):int
```

Let `Γ2 = {(f,∀α.α->α), (g,∀β.∀γ.β->γ->β)}`, we find [subtree 1] is as follows


```haskell
--------------------(hmVar)
Γ2|-g:∀β.∀γ.β->γ->β     ∀β.∀γ.β->γ->β ⊑ ∀γ.int->γ->int
----------------------------------(hmInst)
Γ2|-g:∀γ.int->γ->int                       [subtree 3]
-----------------------------------------------(hmApp)
Γ2|-g (f 1):∀γ.γ->int                      ∀γ.γ->int ⊑ bool->int 
-------------------------------------------------(hmInst)    
Γ2|-g (f 1):bool->int                                   [subtree 2]
---------------------------------------------------------------(hmApp)
Γ2|-g (f 1) (f true):int
```

Where [subtree 2] is as follows

```haskell
--------------(hmVar)
Γ2|-f:∀α.α->α ∀α.α->α ⊑ bool->bool
-------------------(hmInst)       ----------------(hmBool)
Γ2|-f:bool->bool                  Γ2|-true:bool
----------------------------------------------------(hmApp)
Γ2|-f true:bool
```

Where [subtree 3] is as follows

```haskell
--------------(hmVar)
Γ2|-f:∀α.α->α ∀α.α->α ⊑ int->int
-------------------(hmInst)       ----------------(hmInt)
Γ2|-f:int->int                    Γ2|-1:int
---------------------------------------------------(hmApp)
Γ2|-f 1:int
```

As we can observe, through the use of rules of ${\tt (hmGen)}$ and ${\tt (hmVar)}$, we are able to give let-bound variables `f` and `g` some generic types (AKA parametric polymorphic types). Through rules ${\tt (hmApp)}$ and ${\tt (hmInst)}$ we are able to "instantiate" these polymoprhic types to the appropriate monomorphic types depending on the contexts.


### Property 4 - Uniqueness
The following property states that if a lambda term is typable, its type scheme must be unique modulo type variable renaming.

Let $t$ be a lambda calculus term. Let $\Gamma$ be a type environment such that for all $x \in fv(t)$, $x \in dom(\Gamma)$. Let $\sigma$ and $\sigma'$ be type schemes such that $\Gamma \vdash t : \sigma$ and $\Gamma \vdash t:\sigma'$.
Then $\sigma$ and $\sigma'$ must be the same modulo type variable renaming.

For instance, we say type schemes $\forall \alpha.\alpha \rightarrow int$ and $\forall \beta.\beta \rightarrow int$ are the same modulo type variable renaming. But type schemes $\forall \alpha.\alpha \rightarrow bool$ and $\forall \beta.\beta \rightarrow int$ are not the same.


### Property 5 - Progress
The Progress property is valid for Hindley Milner type checking.

Let $t$ be a lambda calculus term such that $fv(t) = \{\}$. 
Let $\sigma$ be a type scheme such that $\Gamma_{init} \vdash t : \sigma$.
Then $t$ is either a value or there exists some $t'$ such that $t \longrightarrow t'$.

### Property 6 - Preservation
The Presevation property is also held for Hindley Milner type checking.

Let $t$ and $t'$ be lambda calculus terms such that $t \longrightarrow t'$. Let $\sigma$ be a type scheme and $\Gamma$ be a type environment such that $\Gamma \vdash t:\sigma$.
Then $\Gamma \vdash t':\sigma$.

## Type Inference for Lambda Calculus 

To infer the type environment as well as the type for lambda calculus term, we need an algorithm called *Algorithm W*.

The algorithm is described in a deduction rule system of shape $\Gamma, t \vDash T, \Psi$, which reads as given input type environment $\Gamma$ and a lambda term $t$, the algorithm infers the type $T$ and type substitution $\Psi$.

$$
\begin{array}{rc}
{\tt (wInt)} & \begin{array}{c}
                c\ {\tt is\ an\ integer} 
                \\ \hline 
               \Gamma, c \vDash int, [] 
               \end{array} \\ \\
{\tt (wBool)} & \begin{array}{c}
                c\in \{true,false \} 
                \\ \hline 
               \Gamma, c \vDash bool, [] 
               \end{array}
\end{array}
$$

The rules for integer and boolean constants are straight forward. We omit the explanation.




$$
\begin{array}{rc}
{\tt (wVar)} & \begin{array}{c}
                (x,\sigma) \in \Gamma \ \ \ inst(\sigma) = T
                \\ \hline 
               \Gamma, x \vDash T, [] 
               \end{array} \\ \\
{\tt (wFix)} & \begin{array}{c}
                (fix,\forall \alpha. (\alpha\rightarrow \alpha)\rightarrow \alpha) \in \Gamma \ \ \ inst(\forall \alpha. (\alpha\rightarrow \alpha)\rightarrow \alpha) = T
                \\ \hline 
               \Gamma, fix \vDash T, [] 
               \end{array}
\end{array}
$$

The rule ${\tt (wVar)}$ infers the type for a variable by looking it up from the input type environment $\Gamma$.
Same observation applies to ${\tt (wFix)}$ since we assume that $fix$ is pre-defined in the initial type environment $\Gamma_{init}$, which serves as the starting input.



$$
\begin{array}{rc}
{\tt (wLam)} & \begin{array}{c}
                \alpha_1 = newvar \ \ \ \Gamma \oplus (x,\alpha_1), t \vDash T, \Psi
                \\ \hline
                \Gamma, \lambda x.t \vDash : \Psi(\alpha_1 \rightarrow T ), \Psi
                \end{array}
\end{array}
$$

The rule ${\tt (wLam)}$ infers the type for a lambda abstraction by "spawning" a fresh skolem type variable $\alpha_1$ which is reserved for the lambda bound variable $x$. Under the extended type environment $\Gamma \oplus (x,\alpha_1)$ it infers the body of the lambda extraction $t$ to have type $T$ and the type substitution $\Psi$. The inferred type of the entire lambda abstraction is therefore $\Psi(\alpha_1 \rightarrow T)$. The reason is that while infering the type for the lambda body, we might obtain substitution that grounds $\alpha_1$. For instance $\lambda x. x + 1$ will ground $x$'s skolem type variable to $int$.


$$
\begin{array}{rc}
{\tt (wApp)} & \begin{array}{c}
                \Gamma, t_1 \vDash T_1, \Psi_1\ \ \ \ \Psi_1(\Gamma), t_2 \vDash T_2, \Psi_2\ \ \\ \alpha_3 = newvar\ \ \ \Psi_3 = mgu(\Psi_2(T_1), T_2 \rightarrow \alpha_3) 
                \\ \hline
                \Gamma, (t_1\ t_2) \vDash \Psi_3(\alpha_3), \Psi_3 \circ \Psi_2 \circ \Psi_1 
               \end{array}
\end{array}
$$

The rule ${\tt (wApp)}$ infers the type for a function application $t_1\ t_2$. We first apply the inference recursively to $t_1$, producing a type $T_1$ and a type substitution $\Psi_1$. Next we apply $\Psi_1$ to $\Gamma$ hoping to ground some of the type variables inside and use it to infer $t_2$'s type as $T_2$ with a subsitution $\Psi_2$. To denote the type of the application, we generate a fresh skolem type variable $\alpha_3$ reserved for this term. We perform a unification between $\Psi_2(T_1)$ (hoping $\Psi_2$ will ground some more type variables in $T_1$), and $T_2 \rightarrow \alpha_3$. If the unifcation is successful, it will result in another type substitution $\Psi_3$. $\Psi_3$ can potentially ground the type variable $\alpha_3$. At last we return $\Psi_3(\alpha_3)$ as the inferred type and composing all three substitutions as the resulted substitution.


$$
\begin{array}{rc}
{\tt (wLet)} & \begin{array}{c}
                \Gamma, t_1 \vDash T_1, \Psi_1 \\ \Psi_1(\Gamma) \oplus (x, gen(\Psi_1(\Gamma), T_1)), t_2 \vDash T_2, \Psi_2
                \\ \hline
                \Gamma, let\ x=t_1\ in\ t_2 \vDash T_2, \Psi_2 \circ \Psi_1
             \end{array}
\end{array}
$$

The ${\tt (wLet)}$ rule infers a type for the let binding. We first infer the type $T_1$ and type substitutions $\Psi_1$. By applying $\Psi_1$ to $\Gamma$ we hope to ground some type variables in $\Gamma$. We apply a helper function $gen$ to generalize $T_1$ w.r.t $\Psi_1(\Gamma)$, and use it as the type for $x$ to infer $t_2$ type. Finally, we return $T_2$ as the inferred type and $\Psi_2 \circ \Psi_1$ as the type substitutions. 


$$
\begin{array}{rc}
{\tt (wOp1)} & \begin{array}{c}
                op \in \{+,-,*,/\} \\ 
                \Gamma, t_1 \vDash T_1, \Psi_1 \ \ \ \Psi_1(\Gamma), t_2 \vDash T_2, \Psi_2 \\ 
                mgu(\Psi_2(T_1), T_2, int) = \Psi_3   
                \\ \hline 
                \Gamma, t_1\ op\ t_2 \vDash int, \Psi_3 \circ \Psi_2 \circ \Psi_1 
                \end{array} \\ \\ 
{\tt (wOp2)} & \begin{array}{c}
                \Gamma, t_1 \vDash T_1, \Psi_1 \ \ \ \Psi_1(\Gamma), t_2 \vDash T_2, \Psi_2 \\ 
                mgu(\Psi_2(T_1), T_2) = \Psi_3   
                \\ \hline 
                \Gamma, t_1\ ==\ t_2 \vDash bool, \Psi_3 \circ \Psi_2 \circ \Psi_1 
                \end{array}
\end{array}
$$
The rule ${\tt (wOp1)}$ handles the type inference for arithmetic binary operation. The result type must be $int$. In the premises, we infer the type of the left operand $t_1$ to be $T_1$ with a type substitution $\Psi_1$. We apply $\Psi_1$ to $\Gamma$ hoping to ground some type variables. We continue to infer the right operand $t_2$ with a type $T_2$ and $\Psi_2$. Finally we need to unify 
$\Psi_2(T_1)$, $T_2$ and $int$ to form $\Psi_3$. Note that we don't need to apply $\Psi_1$ to $T_2$ during the unification, because $T_2$ is infered from $\Psi_1(\Gamma)$, i.e. type variables in $T_2$ is either already in the domain of $\Psi_1(\Gamma)$, or it is enirely fresh, i.e. not in $T_1$ and $\Psi_1$. We return $\Psi_3 \circ \Psi_2 \circ \Psi_1$ as the final substitution. 

In rule ${\tt (wOp2)}$, the binary operator is an equality check. It works similar to the rule ${\tt (wOp1)}$ except that we return $bool$ as the result type, and we do not include $int$ as the additional operand when unifying the the types of $\Psi_2(T_1)$ and $T_2$. 

$$
\begin{array}{rc}
{\tt (wIf)} & \begin{array}{c}
                \Gamma, t_1 \vDash T_1, \Psi_1\ \ \
                \Psi_1' = mgu(bool, T_1) \circ \Psi_1 \\
                \Psi_1'(\Gamma),t_2 \vDash T_2, \Psi_2 \ \ \
                \Psi_1'(\Gamma),t_3 \vDash T_3, \Psi_3 \\
                \Psi_4 = mgu(\Psi_3(T_2), \Psi_2(T_3)) 
                \\ \hline
                \Gamma, if\ t_1\ then\ t_2\ else\ t_3 \vDash \Psi_4(\Psi_3(T_2)),  \Psi_4 \circ \Psi_3 \circ \Psi_2 \circ \Psi_1'
              \end{array}
\end{array}
$$

In the rule ${\tt (wIf)}$, we infer the type of $if\ t_1\ then\ t_2\ else\ t_3$. In the premises, we first infer the type of $t_1$ to be type $T_1$ and type subsitution $\Psi_1$. Since $t_1$ is used as a condition expression, we define a refined substitution $\Psi_1'$ by unifing $bool$ with $T_1$ and composing the result with $\Psi_1$. We then apply $\Psi_1'$ to $\Gamma$ and infer $t_2$ and $t_3$. 
Finally we unify the returned types from both branches, i.e. $\Psi_3(T_2)$ and $\Psi_2(T_3)$. Note that we have to cross apply the type substitutions to ground some type variables. We return $\Psi_4(\Psi_2(T_2))$ as the overall inferred type and $\Psi_4 \circ \Psi_3 \circ \Psi_2 \circ \Psi_1'$ as the overall type substitution. 

### Helper functions

We find the list of helper functions defined in Algorithm W.

#### Type Substitution 

$$
\begin{array}{rcl}
\Psi(\Gamma)  &= & \{ (x,\Psi(\sigma)) \mid (x,\sigma) \in \Gamma \} \\ 
\Psi_2 \circ \Psi_1 (\Gamma) & = &  \Psi_2( \Psi_1 (\Gamma))
\end{array}
$$

Alternatively, the composition of type substitution can also be defined as 

$$
\Psi_2 \circ \Psi_1 = [\Psi_2(\sigma)/\alpha \mid (\sigma/\alpha) \in \Psi_1] \cup [\sigma/\alpha \mid (\sigma/\alpha) \in \Psi_2 \wedge (\sigma/\alpha) \not\in \Psi_1]
$$

#### Type Instantiation

$$
\begin{array}{rcl}
inst(T) & = & T \\
inst(\forall \alpha.\sigma) & = & \lbrack\beta_1/\alpha\rbrack(inst(\sigma))\ where\ \beta_1=newvar \\
\end{array}
$$

The type instantation function instantiate a type scheme. In case of a simple type $T$, it returns $T$. In case it is a polymorphic type scheme $\forall \alpha.\sigma$, we generate a new skolem type variable $\beta_1$ and replace all the occurances of $\alpha$ in $inst(\sigma)$. In some literature, these skolem type variables are called the unification type variables as they are created for the purpose of unification.


#### Type Generalization

$$
\begin{array}{rcl}
gen(\Gamma, T) & = & \forall \overline{\alpha}.T\ \ where\ \overline{\alpha} = ftv(T) - ftv(\Gamma)
\end{array}
$$


The type generation function turns a type $T$ into a type scheme if there exists some free type variable in $T$ but not in $ftv(\Gamma)$, i.e. skolem variables. 


#### Type Unification 

$$
\begin{array}{rcl}
mgu(\alpha, T) & = & [T/\alpha] \\ 
mgu(T, \alpha) & = & [T/\alpha] \\ 
mgu(int, int) & = & [] \\ 
mgu(bool, bool) & = & [] \\ 
mgu(T_1 \rightarrow T_2 , T_3\rightarrow T_4) & = & let\ \Psi_1 = mgu(T_1, T_3)\ \\ 
&  & in\ \ let\ \Psi_2 = mgu(\Psi_1(T_2), \Psi_1(T_4)) \\
&  & \ \ \ \ \ in\ \Psi_2 \circ \Psi_1
\end{array}
$$

The type unification process is similar to the one described for SIMP program type inference, except that we included an extra case for function type unification. In the event of unifying two function types $T_1 \rightarrow T_2$ and $T_3 \rightarrow T_4$, we first unify the argument types $T_1$ and $T_3$ then apply the result to $T_2$ and $T_4$ and unify them.

### Examples

Let's consider some examples 

#### Example 1 $\lambda x.x$

Let $\Gamma = \{(fix,\forall \alpha. (\alpha \rightarrow \alpha) \rightarrow \alpha)\}$

```haskell
           (x,α1)∈Γ⊕(x,α1)  inst(α1)=α1
           ----------------------------(wVar)
α1=newvar  Γ⊕(x,α1),x|=α1,[]
------------------------------------------(wLam)
Γ,λx.x|= α1->α1, []
```

#### Example 2 $\lambda x.\lambda y.x$

```haskell 
                     (x,β1)∈Γ⊕(x,β1)⊕(y,γ1) inst(β1)=β1
                     --------------------------------(wVar)
           γ1=newvar Γ⊕(x,β1)⊕(y,γ1),x|= β1,[]
           --------------------------------------(wLam)
β1=newvar  Γ⊕(x,β1),λy.x|=γ1->β1,[]
-------------------------------------------------(wLam)
Γ,λx.λy.x|= β1->γ1->β1,[]
```



#### Example 3 $let\ f=\lambda x.x\ in\ (let\ g=\lambda x.\lambda y.x\ in\ g\ (f\ 1)\ (f\ true))$

```haskell
[Example 1]
-------------------
Γ,λx.x|= α1->α1, []   gen(Γ,α1->α1)=∀α.α->α  [subtree 1]
------------------------------------------------------------------(wLet)
Γ,let f=λx.x in (let g=λx.λy.x in g (f 1) (f true))|= int, Ψ3○[bool/γ2,int/δ1]
```

Let `Γ1 =Γ⊕(f,∀α.α->α)`, where [subtree 1] is 

```haskell
[Example 2]
--------------------------   
Γ1,λx.λy.x|= β1->γ1->β1,[]  gen(Γ1,β1->γ1->β1)=∀β.∀γ.β->γ->β [subtree 2] 
-------------------------------------------------------------------------------(wLet)
Γ1,let g=λx.λy.x in g (f 1) (f true)|=int, Ψ3○[bool/γ2,int/δ1]○[]
```

Let `Γ2 =Γ⊕(f,∀α.α->α)⊕(g,∀β.∀γ.β->γ->β)`, where [subtree 2] is


```haskell                  
[subtree 3]  [subtree 5] δ1=newvar  mgu(γ2->int,bool->δ1)=[bool/γ2,int/δ1]
--------------------------------------------------------------------------(wApp)
Γ2, g (f 1) (f true)|= [bool/γ2,int/δ1](δ1), Ψ3○[bool/γ2,int/δ1]
```

Where [subtree 3] is

```haskell
(g,∀β.∀γ.β->γ->β)∈Γ2                 ε1=newvar
inst(∀β.∀γ.β->γ->β)=β2->γ2->β2       mgu(β2->γ2->β2,int->ε1)=[int/β2,γ2->int/ε1]
--------------------------(wVar)    
Γ2, g|=β2->γ2->β2, []        [subtree 4]
---------------------------------------------------------------------(wApp)
Γ2, g (f 1)|= [int/β2,γ2->int/ε1](ε1),[int/β2,γ2->int/ε1]○[int/ζ1,int/α2]
```


Where [subtree 4] is 

```haskell
(f,∀α.α->α)∈Γ2 
inst(∀α.α->α)=α2->α2                      ζ1=newvar
-----------------(wVar) ------------(wInt)    
Γ2, f|=α2->α2,[]        Γ2,1|=int,[]      mgu(α2->α2,int->ζ1)=[int/ζ1,int/α2]
---------------------------------------------------------------------(wApp)
[](Γ2),f 1|= [int/ζ1,int/α2](ζ1), [int/ζ1,int/α2]
```

Let `Ψ3=[int/β2,γ2->int/ε1]○[int/ζ1,int/α2]`, note that `Ψ3(Γ2) =Γ2`,  where [subtree 5] is 

```haskell
(f,∀α.α->α)∈Γ2
inst(∀α.α->α)=α3->α3                      η1=newvar
----------------(wVar) ----------(wBool) 
Γ2,f|=α3->α3, []       Γ2,true|=bool,[]   mgu(α3->α3,bool->η1)=[bool/α3,bool/η1]
-----------------------------------------------------------------------[wApp]
Γ2,f true|=[bool/α3,bool/η1](α3),[bool/α3,bool/η1]
```


### Property 7: Type Inference Soundness
The following property states that the type and subsitution generated by Algorithm W is able to type check the lambda calculus term in Hindley Milners' type system.

Let $t$ be a lambda calculus term and $\Gamma_{init}$ is a initial type environment and $\Gamma_{init}, t \vDash T, \Psi$. Then $\Gamma \vdash t:gen(\Gamma_{init},\Psi(T))$. 

### Property 8: Principality 
The following property states that the type generated by Algorithm W is the principal type.

Let $t$ be a lambda calculus term and $\Gamma_{init}$ is a initial type environment and $\Gamma_{init}, t \vDash T, \Psi$.
Then $gen(\Gamma_{init}, \Psi(T))$ is the most general type scheme to type check $t$. 
