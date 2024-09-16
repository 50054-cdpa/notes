# 50.054 - Introduction to Haskell

## Learning Outcomes

By the end of this class, you should be able to

* Develop simple implementation in Haskell using List, Conditional, and Recursion
* Model problems and design solutions using Algebraic Datatype and Pattern Matching
* Compile and execute simple Haskell programs

## What is Haskell?

Haskell is one of the only purely and lazy function programming languages. 

Haskell is widely used in the industry and the research communities. There many industry projects and open source projects were implemented mainly in Haskell, e.g. Pandoc, Mu, Idris, Elm and etc. There are many other languages are strongly influenced by Haskell, e.g. Scala, Rust and even Python.
For more details in how Haskell is used in the real-world business, you may refer to the following for further readings.

* [Haskell in Production: Standard Chartered](https://serokell.io/blog/haskell-in-production-standard-chartered)
* [Haskell in Production: Microsoft](https://github.com/Microsoft/bond)
* [Who is using Haskell](https://wiki.haskell.org/Haskell_in_industry)

## Haskell Hello World

Let's say we have a Haskell file named `HelloWorld.hs`

```haskell
main = print "hello world"
```

We can execute it via either

```bash
runghc HelloWorld.hs
```

or to compile it then run

```bash
ghc HelloWorld.hs && ./HelloWorld
```

In the cohort problems, we are going to rely on a Haskell project manager named `cabal` to build, execute and test our codes.


## Functional Programming in Haskell at a glance

In this module, we focus and utilise mostly the functional programming feature of Haskell.

|   | Lambda Calculus | Haskell |
|---|---|---|
| Variable | $x$ | `x` |
| Constant | $c$ | `1`, `2`, `True`, `False` |
| Lambda abstraction| $\lambda x.t$  |  `\x->t`  |
| Function application | $t_1\ t_2$  |  `t1 t2`  |
| Conditional          | $if\ t_1\ then\ t_2\ else\ t_3$ | `if t1 then t2 else t3` |
| Let Binding          | $let\ x = t_1\ in\ t_2$ | `let x = t1 in t2` |
| Recursion            | $let\ f = (\mu g.\lambda x.g\ x)\ in\ f\ 1$| `let f x = f x in f 1` |


Similar to other mainstream languages, defining recursion in Haskell is straight-forward, we just
make reference to the recursive function name in its body.

```hs
fac :: Int -> Int 
fac x = if x == 0 
        then 1 
        else x * fac (x-1)

fac 10
```

where `fac :: Int -> Int` denotes a type annotation to the function `fac`, which is optional in Haskell.
The Haskell compiler will always reconstruct (infer) the missing type annotation.

### Haskell Strict and Lazy Evaluation

Let `f` be a non-terminating function

```hs 
f x = f x
```

The following shows that the function application in Haskell is using lazy evaluation.

```hs
g x = 1
g (f 1) -- terminates with 1 
```

To force the argument to be strictly evaluate before the function, 

```hs 
let x = f 1 
in seq x (g x) -- does not terminate
```

where `seq` is a builtin GHC function that forces its first argument to be reduced before its second argument. By applying it we achieve certain level of strict evaluation.

### List Data type

We consider a commonly used builtin data type in Haskell, the list data type. In Haskell, the following define some list values.

1. `[]` - an empty list.
1. `[1,2]` - a list contains two numerical values.
1. `["a"]` - an string list contains one value.
1. `1:[2,3]` - prepends a value `1` to a list containing `2` and `3`.
1. `["hello"] ++ ["world"]` - concatenating two string lists.

To iterate through the items in a list, we can use pattern matching in Haskell. 

```hs
sum :: [Int] -> Int 
sum l = case l of 
    { [] -> 0
    ; hd:tl -> hd + sum tl
    }
```

in which `case l of { [] -> 0; hd:tl -> hd + sum tl}` denotes a pattern-matching expression in Haskell. It is similar to the switch statement found in other main stream languages, except that it has more *perks*.

In this expression, we pattern match the input list `l` against two list patterns, namely:

* `[]` the empty list, and
* `hd:tl` the non-empty list

> Note that here `[]` and `hd:tl` are not list values, because they are appearing after a `case ... of` keyword and on the left of an arrow `->`.

When there is no confusion, we could drop the `{ }` and the `;` in the case patterns, e.g. 

```hs
sum :: [Int] -> Int 
sum l = case l of 
    [] -> 0
    hd:tl -> hd + sum tl
```

Pattern cases are visited from top to bottom (or left to right). In this example, we first check whether the input list `l` is an empty list. If it is empty, the sum of an empty list must be `0`. 

If the input list `l` is not an empty list, it must have at least one element. The pattern `hd:tl` extracts the first element of the list and binds it to a local variable `hd` and the remainder (which is the sub list formed by taking away the first element from `l`) is bound to `hd`. We often call `hd` as the head of the list and `tl` as the tail. We would like to remind that `hd` is storing a single integer in this case, and `tl` is capturing a list of integers.

If the case pattern is the outer most expression in a function body, we could rewrite it as follows,

```hs
sum :: [Int] -> Int 
sum [] = 0
sum (hd:tl) = hd + sum tl 
```



One advantage of implementing the `sum` function in FP style is that it is much closer to its math specification.

$$
\begin{array}{rl}
sum(l) = & \left [
    \begin{array}{ll}
    0 & {l\ is\ empty} \\
    head(l)+sum(tail(l)) & {otherwise}
    \end{array} \right .
\end{array}
$$

Let's consider another example.

```hs
reverse :: [Int] -> [Int] 
reverse l = case l of 
    [] -> [] 
    hd:tl -> reverse tl ++ [hd]
```

The function `reverse` takes a list of integers and generates a new list which is in the reverse order of the orginal one. We apply a similar strategy to break down the problem into two sub-problems via the `match` expression.

* When the input list `l` is an empty list, we return an empty list. The reverse of an empty list is an empty list
* When the input `l` is not empty, we make use of the pattern `hd:tl` to extract the head and the tail of the list

We apply `reverse` recursively to the tail and then concatenate it with a list containing the head.

You may notice that the same `reverse` function can be applied to lists of any element type, and not just integers, as long as all elements in a list share the same type. Therefore, we can rewrite the `reverse` function into a generic version as follows:

```hs
reverse :: [a] -> [a] 
reverse l = case l of 
    [] -> [] 
    hd:tl -> reverse tl ++ [hd]
```

Note that the optional type annotation contains a type parameter (type variable) `a`, with which we specify that the element type of the list is `a` (any possible type). The type parameter is resolved when we apply `reverse` to a actual argument. For instance in `reverse [1,2,3]` the Haskell compiler will resolve `a=Int` assuming `1, 2, 3` are integers and in `reverse ["a","b"]` it will resolve `a=String`.

#### A Note on Recursion

Note that recursive calls to `reverse` will incur additional memory space in the machine in form of additional function call frames on the call stack.

A call stack frame has to created to "save" the state of function execution such as local variables. As nested recursive calls are being built up, the machine might run out of memory. This is also known as Stack Overflow Error.

While simple recursions that make a few tens of or hundreds of nested calls won't harm a lot, we need to rethink when we note that a recursion is going to be executed for a large number of iterations. One way to address this issue is to rewrite non-tail recursion into tail-recursion.

A tail-recursion is a recursive function in which the recursive call occurs at the last instruction. 

For instance, the `reverse` function presented earlier is not. The following variant is a tail recursion

```hs
reverse l = go l [] 
    where go [] acc = acc
          go (hd:tl) acc = go tl (hd:acc)
```

In the above definition, we rely on an inner function `go` which is recursively defined. In `go`, the recursion take places at the last instruction in the `(hd:tl)` case. The trick is to
pass around an accumulated output `acc` in each recursive call.


As compiler technology evolves, many modern FP language compilers are able to detect a subset of non-tail recursions and automatically transform them into the tail recursive version. 

However Haskell does not automatically re-write a non-tail recursion into a tail recursion, and leaves it as a programmer's task.


### Map, Fold and Filter

Consider the following function

```hs
addToEach :: Int -> [Int] -> [Int]
addToEach x [] = []
addtoEach x (y:ys) = 
    let yx = y + x 
    in yx : (addToEach x ys)
```

It takes two inputs, an integer `x` and an integer list `l`, and adds `x` to every element in `l` and put the results in the output list.

For instance `addToEach 1  [1,2,3]` yields `[2,3,4]`.

The above can rewritten by using a generic library function shipped with Haskell.

```hs
addToEach x l = map (\y -> y + x) l
```

The method `map` is a method of the list class that takes a function as input argument and applies it to all elements in the list object.

We can observe that the input list and the output list of the `map` method must be of the same type and have the same length.

Recall in the `sum` function introduced in the earlier section. It takes a list of integers and "collapses" them into one number by summation. We can rewrite it using a fold function.

```hs
sum :: [Int] -> Int 
sum l = foldl (\acc x -> acc + x) 0 l 
```

The `foldl` method takes a binary function and a base accumulator as inputs, and aggregates the elements from the list using the binary function.  In particular, the binary aggreation function assumes the first argument is the accumulator.

Besides `foldl`, there exists a `foldr` method, in which the binary aggregation function expects the second argument is the accumulator.

```hs
sum l = foldr (\x acc -> x + acc) 0 l 
```

So what is the difference between `foldl` and `foldr`?  What happen if you run the following? Can you explain the difference?

```hs
l = ["a","better","world", "by", "design"]
foldl (\acc x -> acc ++ " " ++ x) "" l 
foldr (\x acc -> x ++ " " ++ acc) "" l 
```

Note that in Haskell, a string is represented as a list of characters. 
Since `++` is the list concatenation operator, in the above it concatenates two string values.

Intuitively, `foldl (\acc x -> acc ++ " " ++ x) "" l` aggregates the list of words using the aggregation function by nesting the recursive calls to the left.

```hs
(((("" ++ " " ++ "a") ++ " " ++ "better") ++ " " ++ "world") ++ " " ++ "by") ++ " " ++ "design"
```

where `foldr (\x acc -> x ++ " " ++ acc) "" l` aggregates the list of words by nesting the recursive calls to the right.

```hs
"a" ++ " " ++ ( "better" ++ " " ++ ("world" ++ " " ++ ("by" ++ " " ++ ("design" ++ " " ++""))))
```

The method `filter` takes a boolean test function and applies it to the elements in the list, keeping those whose test result is true and dropping those whose result is false.

```hs
l = [1,2,3,4]

even :: Int -> Bool
even x = x `mod` 2 == 0 

filter even l 
```

returns `[2,4]`.

> Note: in Haskell, `mod` is a prelude function (predefined function). `mod x y` that computes the remainder of the division of `x / y`. When we enclose a binary function with `` in Haskell, we can use it in an infix notation.

```hs
l = ['a','1','0','d']
filter Data.Char.isDigit l
```

returns `['1','0']`.

Note that `isDigit` is a function defined in the module `Data.Char`.

With `map`, `foldLeft` and `filter`, we can express the implementation of algorithms in a concise and elegant way. For instance, the following function implements the quicksort algorithm:

```hs
qsort :: [Int] -> [Int] 
qsort [] = []
qsort [x] = [x] 
qsort (p:rest) = 
    let ltp = filter (< p) rest
        gep = filter (>= p) rest 
    in qsort ltp ++ [p] ++ qsort gep
```

which resembles the math specification

$$
\begin{array}{cc}
qsort(l) = & \left[
    \begin{array}{ll}
    l & |l| < 2 \\
    qsort(\{x|x \in l \wedge x < head(l) \}) \uplus \{head(l)\} \uplus qsort(\{x|x\in l \wedge \neg(x < head(l)) \}) & otherwise
    \end{array} \right .
\end{array}
$$

where $\uplus$ unions two bags and maintains the order.

### concatMap and list-comprehension

There is a variant of `map` method, consider

```hs
l = [1 .. 5]

foo :: Int -> [Int]
foo i = if i `mod` 2 == 0
        then [i]
        else []

map foo l 
```
would yield
```hs
[[], [2], [], [4], []]
```

We would like to get rid of the nested lists and flatten the outer list. 

One possibility is to:

```hs
concat (map foo l)
```
where `concat` is a function that "joins" the sub lists in a list of lists via `++`. 


Alternatively, we can use `concatMap` directly.

```hs
concatMap foo l
```

Like `map`, `concatMap` applies its parameter function  to every element in the list. Unlike `map`, `concatMap` expects the parameter function produces a list, thus
it will join all the sub-lists into one list.

With `map` and `concatMap`, we can define complex list transformation operations like the following:

```hs
listProd :: [a] -> [b] -> [(a,b)]
listProd la lb = concatMap (\a -> map (\b -> (a,b)) lb) la

l2 = ['a', 'b', 'c']
listProd l l2
```

which produces:

```hs
[(1,'a'),(1,'b'),(1,'c'),(2,'a'),(2,'b'),(2,'c'),(3,'a'),(3,'b'),(3,'c'),(4,'a'),(4,'b'),(4,'c')]
```

Note that Haskell supports list comprehension via the `[ ... | ... ] ... yield` construct. We could re-express `listProd` as follows:

```hs
listProd2 :: [a] -> [b] -> [(a,b)]
listProd2 la lb = [ (a,b) | a <- la, b <- lb] 
```

The Haskell compiler desugars list comprehension expressions:


```hs
[ e | x1 <- e1,  x2 <- e2, ..., xn <- en ] 
```

into:


```hs
concatMap (\x1 -> concatMap (\x2 -> ... map (\xn -> e) ... ) e2) e1
```


> **A forward reference note**. Some of you probably have read about monad operation may find that the above can be rewritten using a do-notation syntax, e.g.  
>```hs
> listProd3 :: [a] -> [b] -> [(a,b)]
> listProd3 la lb = do { a <- la; b <- lb; return (a,b) }
>```
> which behaves the same and will be desugared into the same form with `concatMap` and `map`. This is because the monadic functor primitive operation for lists are `map` and `concatMap`. We will discuss this in a few weeks time. 



### Algebraic Datatype

In OOP languages, like Java and C#, we use classes and interfaces to define (abstraction of) data types, making using of the OOP concepts that we have learned.
This style of defining data types using abstraction and encapsulation is also known as the abstract datatype.

Like many other languages, Haskell supports user defined data type. It takes a different approach, Algebraic Datatype.

Consider the following Extended BNF of a math expression.
> In computer science, extended Backus–Naur form (EBNF) is a family of metasyntax notations, any of which can be used to express a context-free grammar. EBNF is used to make a formal description of a formal language such as a computer programming language. [EBNF](https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form#:~:text=In%20computer%20science%2C%20extended%20Backus,as%20a%20computer%20programming%20language).

$$
\begin{array}{rccl}
{\tt (Math Exp)} & e & ::= & e + e \mid e - e \mid  e * e \mid e / e \mid c \\
{\tt (Constant)} & c & ::= & ... \mid -1 \mid 0 \mid 1 \mid ...
\end{array}
$$

And we would like to implement a function `eval` which evaluates a ${\tt (Math Exp)}$ to a value.

If we were to implement the above with OOP, we would probably use inheritance to extend subclasses of ${\tt (Math Exp)}$, and use if-else statements with `instanceof` to check for a specific subclass instance. Alternatively, we can also rely on visitor pattern or delegation.

It turns out that using Abstract Datatypes to model the above result in some engineering overhead.

* Firstly, encapsulation and abstract tend to hide the underlying structure of the given object (in this case, the ${\tt Math Exp})$ terms)
* Secondly, using inheritance to model the sum of data types is not perfect (Note: the "sum" here refers to having a fixed set of alternatives of a datatype, not the summation for numerical values)
  * For instance, there is no way to stop users of the library code from extending new instances of ${\tt (MathExp)}$

The algebraic datatype is an answer to these issues. In essence, it is a type of data structure that consists of products and sums.

In Haskell, we use `data` to define Algebraic datatypes.

```hs
data MathExp = 
    Plus  MathExp MathExp | 
    Minus MathExp MathExp |
    Mult  MathExp MathExp |
    Div   MathExp MathExp | 
    Const Int
```

In the above the `MathExp` datatype, there are exactly 5 alternatives. Let's take at look at one case, for instance `Plus MathExp MathExp`, which states that a plus expression has two operands, both of which are of type `MathExp`.

Alternatively, we can use the GADT style with `where` keyword.

```hs
{-# LANGUAGE GADTs #-}

data MathExp where
    Plus  :: MathExp -> MathExp -> MathExp
    Minus :: MathExp -> MathExp -> MathExp
    Mult  :: MathExp -> MathExp -> MathExp
    Div   :: MathExp -> MathExp -> MathExp
    Const :: Int -> MathExp
```
`{-# LANGUAGE GADTs #-}` declares a language extension pragma. 


We can represent the math expression `(1+2) * 3` as
`Mult (Plus (Const 1) (Const 2)) (Const 3)`.  Note that we call `Plus` , `Minus`, `Mult`, `Div` and `Const` "data constructors", as we use them to construct values of the algebraic datatype `MathExp`.

Next let's implement an evaluation function based the specification:

$$
eval(e) = \left [ \begin{array}{cl}
                eval(e_1) + eval(e_2) & if\ e = e_1+e_2 \\
                eval(e_1) - eval(e_2) & if\ e = e_1-e_2 \\
                eval(e_1) * eval(e_2) & if\ e = e_1*e_2 \\
                eval(e_1) / eval(e_2) & if\ e = e_1/e_2 \\
                c & if\ e = c
                \end{array}
        \right.
$$

```hs
eval :: MathExp -> Int
eval e = case e of 
    Plus  e1 e2 -> eval e1 + eval e2
    Minus e1 e2 -> eval e1 - eval e2
    Mult  e1 e2 -> eval e1 * eval e2
    Div   e1 e2 -> eval e1 `div` eval e2
    Const i     -> i
```

In Haskell, algebraic datatype values can be accessed (destructured) via pattern matching.

If we run:

```hs
eval (Mult (Plus (Const 1) (Const 2)) (Const 3))
```

we get `9` as result.

Let's consider another example where we can implement some real-world data structures using the algebraic datatype.

Suppose for experimental purposes, we would like to re-implement the list datatype in Haskell (even though a builtin one already exists). For simplicity, let's consider a monomorphic version (no generic) version. 

> We will look into the generic version in the next lesson

In the following we consider the specification of the `MyList` data type in EBNF:

$$
\begin{array}{rccl}
{\tt (MyList)} & l & ::= & Nil \mid Cons(i,l) \\
{\tt (Int)} & i & ::= & 1 \mid 2 \mid   ...
\end{array}
$$

And we implement the above in Haskell:

```hs
data MyList = Nil | Cons Int MyList
```

> Question: Can you redefine the above using `data ... where` in GADT style?


Next we implement the `map` function based on the following specification

$$
map(f, l) = \left [ \begin{array}{ll}
            Nil & if\ l = Nil\\
            Cons(f(hd), map(f, tl)) & if\ l = Cons(hd, tl)
            \end{array} \right .
$$

Then we could implement the map function

```hs
mapML :: (Int -> Int) -> MyList -> MyList 
mapML f Nil          = Nil 
mapML f (Cons hd tl) = Cons (f hd) (mapML f tl)
```

Running `mapML (\x -> x+1) (Cons 1 Nil)` yields
`Cons 2 Nil`.



yields the same output as above.

## Summary

In this lesson, we have discussed

* Haskell's FP vs Lambda Calculus
* How to use the list datatype to model and manipulate collections of multiple values.
* How to use algebraic data type to define user customized data type to solve complex problems.
