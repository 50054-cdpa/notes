# 50.054 - Applicative and Monad

## Learning Outcomes

1. Describe and define derived type class
2. Describe and define Applicative Functors
3. Describe and define Monads
4. Apply Monad to in design and develop highly modular and resusable software.

## Derived Type Class

Recall that in our previous lesson, we encountered the `Eq` and `Ord` type classes from the Haskell prelude.

```hs
-- prelude definitions, please don't execute it.
class Eq a where 
    (==) :: a -> a -> Bool 

data Ordering = LT | EQ | GT

class Eq a => Ord a where 
    compare              :: a -> a -> Ordering
    (<), (<=), (>), (>=) :: a -> a -> Bool
    max, min             :: a -> a -> a

    compare x y = if x == y then EQ
                  else if x <= y then LT
                  else GT

    x <= y = case compare x y of { GT -> False; _ -> True }
    x >= y = y <= x
    x > y = not (x <= y)
    x < y = not (y <= x)

    max x y = if x <= y then y else x
    min x y = if x <= y then x else y
    {-# MINIMAL compare | (<=) #-}    
```
In the above,  the `Eq` type class is a super class of the `Ord` type class, because any instance of `Ord` type class should also be an instance of the `Ord` (by some type class instance declaration),

We also say `Ord` is a derived type class of `Eq`.

In addition, we find some default implementations of the member functions of `Ord` in the type class body. Minimally, we only need provide the implementation for either `compare` or `(<=)` in an instance of the `Ord` type class.

Let's consider some instances

```hs
module DerivedTypeClass where

data BTree a = Empty | 
    Node a (BTree a) (BTree a) -- ^ a node with a value and the left and right sub trees.


instance Eq a => Eq (BTree a) where 
    (==) Empty Empty = True 
    (==) (Node v1 l1 r1) (Node v2 l2 r2) = v1 == v2 && l1 == l2 && r1 == r2
    (==) _ _ = False 

instance Ord a => Ord (BTree a) where
    compare Empty Empty = EQ 
    compare (Node v1 l1 r1) (Node v2 l2 r2) = 
        case compare v1 v2 of 
            EQ -> case compare l1 l2 of 
                EQ -> compare r1 r2
                o  -> o
            o  -> o
    compare Empty (Node _ _ _) = LT 
    compare (Node _ _ _) Empty = GT

Node 1 Empty (Node 2 Empty Empty) <= Node 1 (Node 2 Empty Empty) Empty -- True
```


## Functor (Recap)

Recall from the last lesson, we make use of the `Functor` type class to define generic programming style of data processing.

```hs
-- prelude definitions, please don't execute it.
class Functor t where 
    fmap :: (a -> b) -> t a -> t b

instance Functor List where 
    fmap f l = map f l
```

```hs
-- our user defined instance Functor BTree
instance Functor BTree where 
    fmap f Empty = Empty
    fmap f (Node v lft rgt) = 
        Node (f v) (fmap f lft) (fmap f rgt)
```


## Applicative Functor

The `Applicative` Functor is a derived type class of `Functor`, which is defined as follows

```hs
-- prelude definitions, please don't execute it.
class Functor t => Applicative t where 
    pure :: a -> t a
    (<*>) :: t (a -> b) -> t a -> t b
    -- some optional member functions omitted
```

We will come to the member functions `pure` and `(<*>)` shortly. Since `Applicative` is a derived type class of 
`Eq`, type instance of `Applicative a` must be also an instance of `Ord a`. 

For example, we consider the predefined instance of `Applicative List` instance from the prelude. 

```hs
-- prelude definitions, please don't execute it.
instance Applicative List where 
    -- pure :: a -> [a]
    pure x = [x]
    -- (<*>) :: List (a -> b) -> [a] -> [b]
    (<*>) fs as = [ f a | f <- fs, a <- as ]
```

In the `pure` function, we take the input argument `a` and enclose it in a list.
In the `(<*>)` function, (it read as "app"), we encounter a list of functions of type `a -> b` and 
a list of values of type `a`. We apply list comprehension to extract every function elements in `fs` and 
apply it to every value element in `as`. 
If we were to consider the alternative implementation of `<*>` for list, we could use `concatMap` and `map`. 

> Can you try to translate the above list comprehension into an equivalent Haskell expression using `concatMap` and `map`?

Note that since we have defined `Functor List` in the earlier section, we don't need to repeat.

Let's consider some example that uses `Applicative List`. Imagine we have a set of different operations and a set of data. The operation in the set should operate independently. We want to apply all the operations to all the data. We can use the `<*>` operation.

```hs
intOps = [\x -> x + 1, \y -> y * 2]
ints   = [1, 2, 3]
intOps <*> ints -- ^ yields [2,3,4,2,4,6]
```


Let's consider another example. Recall that `Maybe a` algebraic datatype which captures a value of type `a` could be potentially empty.

We find that `Functor Maybe` `Applicative Maybe` are in the prelude  the `Applicative[Option]` instance as follows

```hs
-- prelude definitions, please don't execute it.
instance Functor Maybe where 
    fmap f Nothing  = Nothing 
    fmap f (Just x) = Just (f x)


instance Applicative Maybe where 
    pure x = Just x 
    (<*>) Nothing _ = Nothing
    (<*>) _ Nothing = Nothing 
    (<*>) (Just f) (Just x) = Just (f x)
```

In the above Applicative instance, the `<*>` function takes a optional operation and optional value as inputs, tries to apply the operation to the value when both of them are present, otherwise, signal an error by returning `Nothing`. This allows us to focus on the high-level function-value-input-output relation and abstract away the details of handling potential absence of function or value.


### Applicative Laws

Like Functor laws, every Applicative instance must follow the Applicative laws to remain computationally predictable.

1. Identity: `(<*>) (pure \x->x)` $\equiv$ `\x->x`
2. Homomorphism: `(pure f) <*> (pure x))` $\equiv$ `pure (f x)`
3. Interchange: `u <*> (pure y)` $\equiv$ `(pure (\f->f y)) <*> u`
4. Composition: `(((pure (.))) <*> u) <*> v) <*> w` $\equiv$ `u <*> (v <*> w)`


* Identity law states that applying a lifted identity function of type `a->a` is same as an identity function of type `t a -> t a` where `t` is an applicative functor.
* Homomorphism says that applying a lifted function (which has type `a->a` before being lifted) to a lifted value, is equivalent to applying the unlifted function to the unlifted value directly and then lift the result.
 * To understand Interchange law let's consider the following equation
$$
u\ y \equiv (\lambda f.(f\ y))\ u
$$
    * Interchange law says that the above equation remains valid when $u$ is already lifted, as long as we also lift $y$. 

* To understand the Composition law, we consider the following equation in lambda calculus

$$
(((\lambda f.(\lambda g.(f \circ g)))\ u)\ v)\ w \equiv u\ (v\ w)
$$

$$
\begin{array}{rl}
(\underline{((\lambda f.(\lambda g.(f \circ g)))\ u)}\ v)\ w & \longrightarrow_{\beta} \\ 
(\underline{(\lambda g.(u \circ g))\ v})\ w & \longrightarrow_{\beta} \\ 
(u\circ v)\ w & \longrightarrow_{\tt composition} \\ 
u\ (v\ w)
\end{array}
$$

The Composition Law says that the above equation remains valid when $u$, $v$ and $w$ are lifted, as long as we also lift $\lambda f.(\lambda g.(f \circ g))$.

#### Cohort Exercise

show that any applicative functor satisfying the above laws also satisfies the Functor Laws

## Monad

Monad is one of the essential coding/design pattern for many functional programming languages. It enables us to develop high-level resusable code and decouple code dependencies and generate codes by (semi-) automatic code-synthesis. FYI, Monad is a derived type class of Applicative thus Functor.

Let's consider a motivating example.  Recall that in the earlier lesson, we came across the following example.

```hs
data MathExp = 
    Plus  MathExp MathExp | 
    Minus MathExp MathExp |
    Mult  MathExp MathExp |
    Div   MathExp MathExp | 
    Const Int


eval :: MathExp -> Maybe Int 
eval (Plus e1 e2) = case eval e1 of 
    Nothing -> Nothing 
    Just v1 -> case eval e2 of 
        Nothing -> Nothing 
        Just v2 -> Just (v1 + v2)
eval (Minus e1 e2) = case eval e1 of 
    Nothing -> Nothing 
    Just v1 -> case eval e2 of 
        Nothing -> Nothing 
        Just v2 -> Just (v1 - v2)
eval (Mult e1 e2) = case eval e1 of 
    Nothing -> Nothing 
    Just v1 -> case eval e2 of 
        Nothing -> Nothing 
        Just v2 -> Just (v1 * v2)
eval (Div e1 e2) = case eval e1 of 
    Nothing -> Nothing 
    Just v1 -> case eval e2 of 
        Nothing -> Nothing
        Just 0  -> Nothing 
        Just v2 -> Just (v1 `div` v2)
eval (Const v) = Just v 
```

In which we use `Maybe` to capture the potential div-by-zero error.
One issue with the above is that it is very verbose, we lose some readability of the code thus, it takes us a while to migrate to `Either a b` if we want to have better error messages. Monad is a good application here.

Let's consider the type class definition of `Monad m`.

```hs
-- prelude definitions, please don't execute it.
class Applicative m => Monad m where 
    (>>=) :: m a -> (a -> m b) -> m b
    -- optional
    return :: a -> a
    return = pure
    (>>) :: m a -> m b -> m b
    (>>) m k = m >>= \_ -> k 
```
As suggested by the above definition, `Monad` is a derived type class of `Applicative`. The minimal requirement of a Monad instance is to implement the `(>>=)` (pronounced as "bind") function besides the obligation from `Applicative` and `Functor`.

> In the history of Haskell, `Monad` was not defined not as a derived type class of `Applicative` and `Functor`. It was reported and resolved since GHC version 7.10 onwards. Such approach was adopted by other language and systems.

Let's take a look at the `Monad Maybe` instance provided by the Haskell prelude.
```hs
instance Monad Maybe where
    (>>=) Nothing _ = Nothing 
    (>>=) (Just a) f = f a 
```

The `eval` function can be re-expressed using `Monad Maybe`.

```haskell
eval :: MathExp -> Maybe Int 
eval (Plus e1 e2) = 
    (eval e1) >>= (\v1 -> (eval e2) >>= (\v2 -> return (v1 + v2)))
eval (Minus e1 e2) = 
    (eval e1) >>= (\v1 -> (eval e2) >>= (\v2 -> return (v1 - v2)))
eval (Mult e1 e2) = 
    (eval e1) >>= (\v1 -> (eval e2) >>= (\v2 -> return (v1 - v2)))
eval (Div e1 e2) = 
    (eval e1) >>= (\v1 -> (eval e2) >>= (\v2 -> 
        if v2 == 0
        then Nothing
        else return (v1 `div` v2)))
eval (Const i) = return i
```

It certainly reduces the level of verbosity, but the readability is worsened.
Thankfully, we can make use of a `do` syntactic sugar provided by Haskell.

In Haskell expression 
```hs
do 
{ v1 <- e1
; v2 <- e2
...
; vn <- en 
; return e
}
```
is automatically desugared into 

```hs
e1 >>= (\v1 -> e2 >>= (\v2 -> ... en >>= (\vn -> return e)))
```

Hence we can rewrite the above `eval` function as 

```hs
eval :: MathExp -> Maybe Int 
eval (Plus e1 e2) = do 
    v1 <- eval e1 
    v2 <- eval e2 
    return (v1 + v2)
eval (Minus e1 e2) = do 
    v1 <- eval e1
    v2 <- eval e2 
    return (v1 - v2)
eval (Mult e1 e2) = do 
    v1 <- eval e1
    v2 <- eval e2 
    return (v1 * v2)
eval (Div e1 e2) = do 
    v1 <- eval e1
    v2 <- eval e2 
    if v2 == 0 
    then Nothing 
    else return (v1 `div` v2)
eval (Const i) = return i
```

Now the readability is restored.

Another advantage of coding with `Monad` is that its abstraction allows us to switch underlying data structure without major code change.

Suppose we would like to use `Either String a` or some other equivalent as return type of `eval` function to support better error message. But before that, let's consider some subclasses of the `Monad` type classes provided in the Haskell standard library `mtl`.

```hs
-- mtl definition, please don't execute it.
class Monad m => MonadError e m | m -> e where
    throwError :: e -> m a 
    catchError :: m a -> (e -> m a) -> m a
```

In the above, we define a derived type class of `Monad`, called `MonadError e m` where `m` is the Monadic functor and `e` is the error type. The additional declaration `| m -> e` denotes a *functional depenedency* between the instances of `m` and `e`. (You can think of it in terms of database FDs.)
It says that whenever we fix a concrete instance of `m`, we can uniquely identify the corresponding instance of `e`.  The member function `throwErrow` takes an error message and injects into the Monad result. Function `catchError` runs an monad computation `m a`. In case of error, it applies the 2nd argument, a function of type `e -> m a` to handle it. You can think of  `catchError` is the `try ... catch` equivalent in `MonadError`. 



Similarly, we extend `Monad` type class with `MonadError` type class. Next we examine type class instance `MonadError () Maybe`. We use `()` (pronounced as "unit") as the error type as we can't really propogate error message in `Maybe` other than `Nothing`.

```hs
-- mtl definition, please don't execute it.
instance MonadError () Maybe where 
    throwError _ = Nothing 
    catchError ma handle = case ma of 
        Nothing -> handle () 
        Just v  -> Just v
```

Next, we adjust the `eval` function to takes in a `MonadError` context instead of a `Monad` context. In addition, we make the error signal more explicit by calling the `throwError` function from the `MonadError` type class.

```hs
eval :: MathExp -> Maybe Int 
eval (Plus e1 e2) = do 
    v1 <- eval e1 
    v2 <- eval e2 
    return (v1 + v2)
eval (Minus e1 e2) = do 
    v1 <- eval e1
    v2 <- eval e2 
    return (v1 - v2)
eval (Mult e1 e2) = do 
    v1 <- eval e1
    v2 <- eval e2 
    return (v1 * v2)
eval (Div e1 e2) = do 
    v1 <- eval e1
    v2 <- eval e2 
    if v2 == 0 
    then throwError ()
    else return (v1 `div` v2)
eval (Const i) = return i
```

Now let's try to refactor the code to make use of `Either String Int` as the functor instead of `Maybe Int`.

```hs
-- mtl definition, please don't execute it.
instance MonadError String (Either String) where 
    throwError msg = Left msg 
    catchError ma handle = case ma of 
        Left msg -> handle msg
        Right v  -> Right v
```
In the above, we define `MonadError String (Either String)` instance, which satisfies the functional dependency set by the type class as `Either String` functionally determines `String`. 

> Note that the concept of currying is applicable to the type constructors. `Either` has kind `* -> * -> *` therefore `Either String` has kind `* -> *`.

Now we can refactor the `eval` function by changing its type signature. And its body remains unchanged (almost).

```hs
eval :: MathExp -> Either String Int 
eval (Plus e1 e2) = do 
    v1 <- eval e1 
    v2 <- eval e2 
    return (v1 + v2)
eval (Minus e1 e2) = do 
    v1 <- eval e1
    v2 <- eval e2 
    return (v1 - v2)
eval (Mult e1 e2) = do 
    v1 <- eval e1
    v2 <- eval e2 
    return (v1 * v2)
eval (Div e1 e2) = do 
    v1 <- eval e1
    v2 <- eval e2 
    if v2 == 0 
    then throwError "division by zero error."
    else return (v1 `div` v2)
eval (Const i) = return i
```

## Commonly used Monads

We have seen the option Monad and the either Monad. Let's consider a few commonly used Monads.

### List Monad

We know that `List` is a Functor and an Applicative.
It is not surprising that `List` is also a Monad.

```hs
-- prelude definitions, please don't execute it.

flip :: (a -> b -> c) -> b -> a -> c
flip f b a = f a b

instance Monad List where 
    -- (>>=) :: [a] -> (a -> [b]) -> [b]
    (>>=) as f = flip concatMap as f
```

As we can observe from above, the bind function for List monad is a variant of `concatMap`.

With the above instance, we can write list processing method in for comprehension which is similar to query languages (as an alternative to list comprehension).

We define a scheme of a staff record using the following datatype.
```hs
data Staff = Staff {sid::Int, dept::String, salary::Int}
```

Note that using `{}` on the right hand side of a data type definition denotes a record style datatype. 
The components of the record data type are associated with field names. 

The names of the record fields can be used as getter fnuctions.
The above is almost the same as an algebraic data type 

```hs
data Staff = Staff Int String Int

sid :: Staff -> Int
sid (Staff id _ _) = id 

dept :: Staff -> String
dept (Staff _ d _) = d 

salary :: Staff -> Int 
salary (Staff _ _ s) = s
```





```hs
staffData = [
    Staff 1 "HR" 50000,
    Staff 2 "IT" 40000,
    Staff 3 "SALES" 100000,
    Staff 4 "IT" 60000
    ]


query :: [Staff] -> [Int]
query table = do
    staff <- table
    if salary staff > 50000
    then return (sid staff)
    else []
```


### Reader Monad

Next we consider the `Reader` Monad.  `Reader` Monad denotes a shared input environment used by multiple computations. Once shared, this environment stays immutable.

For example, suppose we would like to implement some test with a sequence of API calls. Most of these API calls are having the same host IP. We can set the host IP as part of the reader's environment.

```haskell
case class Reader[R, A] (run: R=>A) { 
    // we need flatMap and map for for-comprehension
    def flatMap[B](f:A =>Reader[R,B]):Reader[R,B] = this match {
        case Reader(ra) => Reader (
            r => f(ra(r)) match {
                case Reader(rb) => rb(r)
            }
        )
    }
    def map[B](f:A=>B):Reader[R, B] = this match {
        case Reader(ra) => Reader (
            r => f(ra(r))
        )
    }
}

type ReaderM = [R] =>> [A] =>> Reader[R, A]

trait ReaderMonad[R] extends Monad[ReaderM[R]] {
    override def pure[A](v:A):Reader[R, A] = Reader (r => v)
    override def bind[A,B](fa:Reader[R, A])(f:A=>Reader[R,B]):Reader[R,B] = fa match {
        case Reader(ra) => Reader (
            r=> f(ra(r)) match {
                case Reader(rb) => rb(r)
            }
        ) 
    }
    def ask:Reader[R,R] = Reader( r => r)
    def local[A](f:R=>R)(r:Reader[R,A]):Reader[R,A] = r match {
        case Reader(ra) => Reader( r => {
            val localR = f(r)
            ra(localR)
        })
    }    
}
```

In the above `Reader[R,A]` case class defines the structure of the Reader type, where `R` denotes the shared information for the computation, (source for reader), `A` denotes the output of the computation. We would like to define `Reader[R,_]` as a Monad instance. To do so, we define a type-curry version of `Reader`, i.e. `ReaderM`.

One crucial observation is that `bind` method in `ReaderMonad` is nearly identical to `flatMap` in `Reader`, with the arguments swapped.

In fact, we can re-express `bind` for all Monads as the `flatMap` in their underlying case class.

```haskell
override def bind[A,B](fa:Reader[R, A])(f:A=>Reader[R,B]):Reader[R,B] = fa.flatMap(f)
```

The following example shows how Reader Monad can be used in making several API calls (computation) to the same API server (shared input
`https://127.0.0.1/`). For authentication we need to call the authentication server `https://127.0.0.10/` temporarily. 

```haskell
case class API(url:String)

given APIReader:ReaderMonad[API] = new ReaderMonad[API] {}

def get(path:String)(using pr:ReaderMonad[API]):Reader[API,Unit] = for {
    r <- pr.ask
    s <- r match {
        case API(url) => pr.pure(println(s"${url}${path}"))
    }
} yield s

def authServer(api:API):API = API("https://127.0.0.10/")

def test1(using pr:ReaderMonad[API]):Reader[API, Unit] = for {
    a <- pr.local(authServer)(get("auth"))
    t <- get("time")
    j <- get("job")
} yield (())


def runtest1():Unit = test1 match {
    case Reader(run) => run(API("https://127.0.0.1/"))
}
```

### State Monad

We consider the `State` Monad. A `State` Monad allows programmers capture and manipulate stateful computation without using assignment and mutable variable. One advantage of doing so is that program has full control of the state without having direct access to the computer memory. In a typeful language like haskell, the type system segregates the pure computation from the stateful computation. This greatly simplify software verification and debugging.

The following we define a `State` case class, which has a member computation `run:S => (S,A)`.

```haskell
case class State[S,A]( run:S=>(S,A)) { 
    def flatMap[B](f: A => State[S,B]):State[S,B] = this match {
        case State(ssa) => State(
            s=> ssa(s) match {
                case (s1,a) => f(a) match {
                    case State(ssb) => ssb(s1)
                }
            }
        )
    }
    def map[B](f:A => B):State[S,B] = this match {
        case State(ssa) => State(
            s=> ssa(s) match {
                case (s1, a) => (s1, f(a))
            }
        )
    }
}
```

As suggested by the type, the computationn `S=>(S,A)`, takes in a state `S` as input and return a tuple of output, consists a new state and the result of the computation.

The State Monad type class is defined as a dervied type class of `Monad[StateM[S]]`.

```haskell
type StateM = [S] =>> [A] =>> State[S,A]

trait StateMonad[S] extends Monad[StateM[S]] {
    override def pure[A](v:A):State[S,A] = State( s=> (s,v))
    override def bind[A,B](
        fa:State[S,A]
        )(
            ff:A => State[S,B]
        ):State[S,B] = fa.flatMap(ff)
    def get:State[S, S] = State(s => (s,s))
    def set(v:S):State[S,Unit] = State(s => (v,()))
}
```

In the `pure` method's default implementation, we takes a value `v` of type `A` and return
a `State` case class oject by wrapping a lambda which takes a state `s` and returns back the same state `s` with the input value `v`. In the default implementation of the `bind` method, we take a computation `fa` of type `State[S,A]`, i.e. a stateful computation over state type `S` and return a result of type `A`. In addition, we take a function that expects input of type `A` and returns a stateful computation `State[S,B]`. We apply `flatMap` of `fa` to `ff`., which can be expanded to

```haskell
fa.flatMap(ff) -->
fa match {
    case State(ssa) => State ( s => {
        ssa(s) match {
            case (s1,a) => ff(a) match {
                case State(ssb) => ssb(s1) 
            }
        }
    })
}

```

In essence it "opens" the computation in `fa` to extract the run function `ssa` which takes a state returns result `A` with the output state. As the output, we construct stateful computation in which a state `s` is taken as input, we immediately apply `s` with `ssa` (i.e. the computation extracted from `fa`) to compute the intermediate state `s1` and the output `a` (of type `A`).  Next we apply `ff` to `a` which returns a Stateful computation `State[S,B]`. We extract the run function from this stateful copmutation, namley `ssb` and apply it to `s1` to continue with the result of the computation. In otherwords, `bind` function chains up a stateful computation  `fa` with a lambda expressoin that consumes the result from `fa` and continue with another stateful copmutation.

The `get` and the `set` methods give us access to the state environment of type `S`.

For instance,

```haskell
case class Counter(c:Int)

given counterStateMonad:StateMonad[Counter] = new StateMonad[Counter]  {
}

def incr(using csm:StateMonad[Counter]):State[Counter,Unit] = for {
    Counter(c) <- csm.get
    _ <- csm.set(Counter(c+1))
} yield ()

def app(using csm:StateMonad[Counter]):State[Counter, Int] = for {
    _ <- incr
    _ <- incr
    Counter(v) <- csm.get
} yield v
```

In the above we define the state environment as an integer counter. Monadic function `incr` increase the counter in the state.

## Monad Laws

Similar to Functor and Applicative, all instances of Monad must satisfy the following
three Monad Laws.

1. Left Identity: `bind(pure(a))(f)` $\equiv$ `f(a)`
2. Right Identity: `bind(m)(pure)` $\equiv$ `m`
3. Associativity: `bind(bind(m)(f))(g)` $\equiv$ `bind(m)(x => bind(f(x))(g))`

* Intutively speaking, a `bind` operation is to *extract* results of type `A` from its first argument with type `F[A]` and apply `f` to the extracted results.
* Left identity law enforces that binding a lifted value to `f`, is the same as applying `f` to the unlifted value directly, because the lifting and the *extraction* of the bind cancel each other.
* Right identity law enforces that binding a lifted value to `pure`,  is the same as the lifted value, because *extracting* results from `m` and `pure` cancel each other.
* The Associativity law enforces that binding a lifted value `m` to `f` then to `g` is the same as binding `m` to a monadic bind composition `(x => bind(f(x)(g)))`

## Summary

In this lesson we have discussed the following

1. A derived type class is a type class that extends from another one.
2. An Applicative Functor is a sub-class of Functor, with the methods `pure` and `ap`.
3. The four laws for Applicative Functor.
4. A Monad Functor is a sub-class of Applicative Functor, with the method `bind`.
5. The three laws of Monad Functor.
6. A few commonly used Monad such as, List Monad, Option Monad, Reader Monad and State Monad.

## Extra Materials

### Writer Monad

The dual of the `Reader` Monad is the `Writer` Monad, which has the following definition.

```haskell
// inspired by https://kseo.github.io/posts/2017-01-21-writer-monad.html
trait Monoid[A]{ // We omitted the super class SemiRing[A]
    def mempty:A
    def mappend:A => A => A
}

given listMonoid[A]:Monoid[List[A]] = new Monoid[List[A]] {
    def mempty:List[A] = Nil
    def mappend:List[A]=>List[A]=>List[A] = 
        (l1:List[A])=>(l2:List[A]) => l1 ++ l2 
}

case class Writer[W,A]( run: (W,A))(using mw:Monoid[W]) {
    def flatMap[B](f:A => Writer[W,B]):Writer[W,B] = this match {
        case Writer((w,a)) => f(a) match {
            case Writer((w2,b)) => Writer((mw.mappend(w)(w2), b))
        } 
    }
    def map[B](f:A=>B):Writer[W, B] = this match {
        case Writer((w,a)) => Writer((w, f(a)))
    }
}
```

Similar to the `Reader` Monad, in the above we define a case class `Writer`, which has a member value `run` that returns a tuple of `(W,A)`.  The subtle difference is that the writer memory `W` has to be an instance of the `Monoid` type class, in which `mempty` and `mappend` operations are defined.

```haskell
type WriterM = [W] =>> [A] =>> Writer[W,A] 

trait WriterMonad[W] extends Monad[WriterM[W]] {
    implicit def W0:Monoid[W]
    override def pure[A](v: A): Writer[W, A] = Writer((W0.mempty, v))
    override def bind[A, B](
        fa: Writer[W, A]
    )(f: A => Writer[W, B]): Writer[W, B] = fa match {
        case Writer((w, a)) =>
            f(a) match {
                case Writer((w2, b)) => {
                    Writer((W0.mappend(w)(w2), b))
                }
            }
    }
    def tell(w: W): Writer[W, Unit] = Writer((w, ()))
    def pass[A](ma: Writer[W, (A, W => W)]): Writer[W, A] = ma match {
        case Writer((w, (a, f))) => Writer((f(w), a))
    }
}
```

In the above we define `WriterMonad` to be a derived type class of `Monad[WriterM[W]]`. For a similar reason,
we need to include the type class `Monoid[W]` to ensure that `mempty` and `mappend` are defined on `W`. Besides the `pure` and `bind` members, we introduce `tell` and `pass`. `tell` writes the given argument into the writer's memory. `pass` execute a given computation which returns a value of type `A` and a memory update function `W=>W`, and return a `Writer` whose memory is updated by applied the update function to the memory.

In the following we define a simple application with logging mechanism using the `Writer` Monad.

```haskell
case class LogEntry(msg:String)

given logWriterMonad:WriterMonad[List[LogEntry]] = new WriterMonad[List[LogEntry]] {
    override def W0:Monoid[List[LogEntry]] = new Monoid[List[LogEntry]] {
        override def mempty = Nil
        override def mappend = (x:List[LogEntry]) => (y:List[LogEntry]) => x ++ y
    }
}

def logger(m: String)(using
    wm: WriterMonad[List[LogEntry]]
): Writer[List[LogEntry], Unit] = wm.tell(List(LogEntry(m)))

def app(using
    wm: WriterMonad[List[LogEntry]]
): Writer[List[LogEntry], Int] = for {
    _ <- logger("start")
    x <- wm.pure(1 + 1)
    _ <- logger(s"result is ${x}")
    _ <- logger("done")
} yield x

def runApp(): Int = app match {
    case Writer((w, i)) => {
        println(w)
        i
    }
}
```

### Monad Transformer

Is the following class a Monad?

```haskell
case class MyState[S,A]( run:S=>Option[(S,A)]) 
```

The difference between this class and the `State` class we've seen earlier is that the execution method `run` yields result of type `Option[(S,A)]` instead of `(S,A)` which means that it can potentially fail.

It is ascertained that `MyState` is also a Monad, and it is a kind of special State Monad.

```haskell
case class MyState[S, A](run: S => Option[(S, A)]) {
    def flatMap[B](f: A => MyState[S, B]): MyState[S, B] = this match {
        case MyState(ssa) =>
            MyState(s =>
                ssa(s) match {
                    case None => None
                    case Some((s1, a)) =>
                        f(a) match {
                            case MyState(ssb) => ssb(s1)
                        }
                }
            )
    }
    def map[B](f: A => B): MyState[S, B] = this match {
        case MyState(ssa) =>
            MyState(s =>
                ssa(s) match {
                    case None          => None
                    case Some((s1, a)) => Some((s1, f(a)))
                }
            )
    }
}

type MyStateM = [S] =>> [A] =>> MyState[S,A]

trait MyStateMonad[S] extends Monad[MyStateM[S]] {
    override def pure[A](v:A):MyState[S,A] = MyState( s=> Some((s,v)))
    override def bind[A,B](
        fa:MyState[S,A]
        )(
            ff:A => MyState[S,B]
        ):MyState[S,B] = fa.flatMap(ff)
    def get:MyState[S, S] = MyState(s => Some((s,s)))
    def set(v:S):MyState[S,Unit] = MyState(s => Some((v,())))
}
```

Besides "stuffing-in" an `Option` type, one could use an `Either` type and etc. Is there a way to generalize this by parameterizing?
Seeking the answer to this question leads us to *Monad Transformer*.

We begin by parameterizing the `Option` functor in `MyState`

```haskell
case class StateT[S, M[_], A](run: S => M[(S, A)])(using m:Monad[M]) {
    def flatMap[B](f: A => StateT[S, M, B]): StateT[S, M, B] = this match {
        case StateT(ssa) =>
            StateT(s => m.bind(ssa(s))
                (sa => sa match {
                    case (s1,a) => f(a) match {
                        case StateT(ssb) => ssb(s1)
                        }
                    }
                )
            ) 
        }
    
    def map[B](f: A => B): StateT[S, M, B] = this match {
        case StateT(ssa) =>
            StateT(s => m.bind(ssa(s))
                (sa => sa match {
                    case (s1, a) => m.pure((s1, f(a)))
                })
            )
    }
}
```

In the above it is largely similar to `MyState` class, except that we parameterize `Option` by a type parameter `M`. `M[_]` indicates that it is of kind `*=>*`. `(using m:Monad[M])` further contraints `M` must be an instance of Monad, so that we could make use of the `bind` and `pure` from `M`'s Monad instance.

Naturally, we can define a derived type class called `StateTMonad`.

```haskell
type StateTM = [S] =>> [M[_]] =>> [A] =>> StateT[S, M, A]

trait StateTMonad[S,M[_]] extends Monad[StateTM[S][M]]  {
    implicit def M0:Monad[M]
    override def pure[A](v: A): StateT[S, M, A] = StateT(s => M0.pure((s, v)))
    override def bind[A, B](
        fa: StateT[S, M, A]
    )(
        ff: A => StateT[S, M, B]
    ): StateT[S, M, B] = fa.flatMap(ff)
    def get: StateT[S, M, S] = StateT(s => M0.pure((s, s)))
    def set(v: S): StateT[S, M, Unit] = StateT(s => M0.pure(v, ()))
}
```

Given that `Option` is a Monad, we can redefine `MyStateMonad`  in terms of `StateTMonad` and `optMonad`.

```haskell
trait StateOptMonad[S] extends StateTMonad[S, Option] { 
    override def M0 = optMonad
}
```

What about the original *vanilla* `State` Monad? We could introduce an Identity Monad.

```haskell
case class Identity[A](run:A) {
    def flatMap[B](f:A=>Identity[B]):Identity[B] = this match {
        case Identity(a) => f(a)
    }
    def map[B](f:A=>B):Identity[B] = this match {
        case Identity(a) => Identity(f(a))
    }
}

given identityMonad:Monad[Identity] = new Monad[Identity] {
    override def pure[A](v:A):Identity[A] = Identity(v)
    override def bind[A,B](fa:Identity[A])(f: A => Identity[B]):Identity[B] = fa.flatMap(f)
}
```

Then we can re-define the vanilla `State` Monad as follows, (in fact like many existing Monad libraries out there.)

```haskell
trait StateIdentMonad[S] extends StateTMonad[S, Identity] { // same as StateMonad
    override def M0 = identityMonad
}
```

One advantage of having Monad Transformer is that now we can create new Monad by composition of existing Monad Transformers. We are able to segregate and interweave methods from different Monad serving different purposes.

Similarly we could generalize the `Reader` Monad  to its transformer variant.

```haskell
case class ReaderT[R, M[_], A](run: R => M[A])(using m:Monad[M]) {
    def flatMap[B](f: A => ReaderT[R, M, B]):ReaderT[R, M, B] = this match {
        case ReaderT(ra) => ReaderT( r => m.bind(ra(r))
            ( a => f(a) match {
            case ReaderT(rb) => rb(r)
            }))
    }
    def map[B](f: A => B):ReaderT[R, M, B] = this match {
        case ReaderT(ra) => ReaderT( r => m.bind(ra(r))
            ( a => m.pure(f(a))))
    }
}


type ReaderTM = [R] =>>[M[_]] =>> [A] =>> ReaderT[R, M, A]

trait ReaderTMonad[R,M[_]] extends Monad[ReaderTM[R][M]] {
    implicit def M0:Monad[M]
    override def pure[A](v: A): ReaderT[R, M, A] = ReaderT(r => M0.pure(v))
    override def bind[A, B](
        fa: ReaderT[R, M, A]
    )(f: A => ReaderT[R, M, B]): ReaderT[R, M, B] = fa.flatMap(f)
    def ask: ReaderT[R, M, R] = ReaderT(r => M0.pure(r))
    def local[A](f: R => R)(r: ReaderT[R, M, A]): ReaderT[R, M, A] = r match {
        case ReaderT(ra) =>
            ReaderT(r => {
                val localR = f(r)
                ra(localR)
            })
    }
}

trait ReaderIdentMonad[R] extends ReaderTMonad[R, Identity] { // same as ReaderMonad
    override def M0 = identityMonad
}
```

Note that the order of how Monad Transfomers being stacked up makes a difference,

For instance, can you explain what is the difference between the following two?

```haskell
trait ReaderStateIdentMonad[R, S] extends ReaderTMonad[R, StateTM[S][Identity]] {
    override def M0:StateIdentMonad[S] = new StateIdentMonad[S]{}
}

trait StateReaderIdentMonad[S, R] extends StateTMonad[S, ReaderTM[R][Identity]] {
    override def M0:ReaderIdentMonad[R] = new ReaderIdentMonad[R]{}
}

```
