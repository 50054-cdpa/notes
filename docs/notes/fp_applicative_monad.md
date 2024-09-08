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

We find that `Functor Maybe` `Applicative Maybe` instances are in the prelude  as follows

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
2. Homomorphism: `(pure f) <*> (pure x)` $\equiv$ `pure (f x)`
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

One difference is that we can use the record name in the record data type as an pseudo update function.

```hs
tom = Staff 1 "hr" 500000
happierTom = tom{salary=(salary tom)*2} -- ^ a new staff with same id and dept and doubled salary.
```

Now we are ready to write some query in Haskell list monad. Given a table of data, 
```hs
staffData = [
    Staff 1 "HR" 50000,
    Staff 2 "IT" 40000,
    Staff 3 "SALES" 100000,
    Staff 4 "IT" 60000
    ]
```

We can use the follow query to retrieve all the staff ids whose salary is more than 50000.

```hs
query :: [Staff] -> [Int]
query table = do
    staff <- table           -- from  staff
    if salary staff > 50000  -- where salary > 50000
    then return (sid staff)  -- select sid
    else []
```


### Reader Monad

Next we consider the `Reader` Monad.  `Reader` Monad denotes a shared input environment used by multiple computations. Once shared, this environment stays immutable.

For example, suppose we would like to implement some test with a sequence of API calls. Most of these API calls are having the same host IP. We can set the host IP as part of the reader's environment.




First let's consider the reader data type
```hs
-- mtl definition with monomorphication, please don't execute it.
data Reader r a = Reader {run :: r -> a}
```

It denotes a computation that takes the reference (shared) environment `r` and produces some result `a`.


Then we provide the necessarily implementation to qualify `Reader r` as a `Monad` instance.

```hs
-- mtl definition with monomorphication, please don't execute it.
data Reader r a = Reader {run :: r -> a}
instance Functor (Reader r) where 
    -- fmap :: (a -> b) -> Reader r a -> Reader r b
    fmap f ra = Reader ( \r ->
        let a = run ra r
        in f a ) 

instance Applicative (Reader r) where 
    -- pure :: a -> Reader r a 
    pure a = Reader (\_ -> a)
    -- (<*>) :: Reader r (a -> b) -> Reader r a -> Reader r b 
    rf <*> ra = Reader (\r ->
        let f = run rf r
            a = run ra r
        in f a)

instance Monad (Reader r) where
    -- (>>=) :: Reader r a -> (a -> Reader r b) -> Reader r b
    ra >>= g = Reader (\r ->
        let a = run ra r
            rb = g a
        in run rb r)
```

* `fmap` function takes a function `f` and a reader `ra` and returns a reader whose computation function takes an input referenced object `r` and runs `ra` with r to obtain `a`, then applly `f` to `a`.
* `pure` function takes a value of type `a` and wraps it into a reader object whose computation function is returning the input value ignoring the referenced object `r`. 
* The app function (`<*>`) takes a reader `rf` that produces function(s), and a reader that produces value `a`. It returns a reader whose computation function takes a referenced object `r` and run `rf` with `ra` with it to produce the function `f` and the value `a`. Finally it applies `f` to `a`.
* The bind function (`>>=`) takes a reader `ra` and a function `g`, it returns a reader whose computation function takes a referenced object `r` and run `ra` with `r` to obtained `a`, next it applies `g` to `a` to generate the reader `rb`, finally, it runs `rb` with `r`.


We consider the `MonadReader` type class definition as follows,

```hs
-- mtl definition, please don't execute it.
class Monad m => MonadReader r m | m -> r where
    -- | Retrieves the monad environment.
    ask   :: m r
    ask = reader id

    -- | Executes a computation in a modified environment.
    local :: (r -> r) -- ^ The function to modify the environment.
          -> m a      -- ^ Reader to run in the modified environment.
          -> m a
```

We provide the implementation for `MonadReader r (Reader r)`.

```hs
-- mtl definition with monomorphication, please don't execute it.
instance MonadReader r (Reader r) where
    -- ask :: Reader r r
    ask = Reader (\r -> r)
    -- local :: (r -> r) -> Reader r a -> Reader r a
    local f ra = Reader (\r -> 
        let t = f r
        in run ra t)
```

The following example shows how Reader Monad can be used in making several API calls (computation) to the same API server (shared input
`https://127.0.0.1/`). 
For authentication we need to call the authentication server `https://127.0.0.10/` temporarily. 

```hs
import Debug.Trace (trace)
data API = API {url::String} 

call :: String -> Reader API () 
call path = do 
    api <- ask
    -- we use trace to simulate the api call
    -- the actual one requires IO monad to be wrapped
    io <- trace ("calling " ++ url api ++ path) (return ())
    return () 


authServer = API "https://127.0.0.10/"
apiServer = API "https://127.0.0.1/"

test1 :: Reader API () 
test1 = do 
    a <- local (\_ -> authServer) (call "auth")
    t <- call "time"
    j <- call "job"
    a `seq` t `seq` j `seq` return ()
```

Calling `run test1 apiServer` yields the following debugging messages.

```
calling https://127.0.0.10/auth
calling https://127.0.0.1/time
calling https://127.0.0.1/job
```

### State Monad

Next we consider the `State` Monad. 
A `State` Monad allows programmers capture and manipulate stateful computation without using assignment and mutable variable. One advantage of doing so is that program has full control of the state without having direct access to the computer memory. In a typeful language like haskell, the type system segregates the pure computation from the stateful computation. This greatly simplify software verification and debugging.

We consider the following state data type 

```hs
-- mtl definition with monomorphication, please don't execute it.
data State s a = State {run :: s -> (a, s)}
```

It denotes a computation that takes the state environment `s` and produces some result `a` and the updated state envrionment.


Then we provide the necessarily implementation to qualify `State s` as a `Monad` instance.

```hs
-- mtl definition with monomorphication, please don't execute it.
instance Functor (State s) where 
    -- fmap :: (a -> b) -> State s a -> State s b
    fmap f sa = State (\s -> 
        case run sa s of 
            (a, s1) -> (f a, s1))

instance Applicative (State s) where 
    -- pure :: a -> State s a
    pure a = State (\s -> (a, s))
    -- (<*>) :: State s (a -> b) -> State s a -> State s b
    sf <*> sa = State (\s -> 
        case run sf s of 
            (f, s1) -> case run sa s1 of 
                (a, s2) -> (f a, s2))

instance Monad (State s) where 
    -- (>>=) :: State s a -> (a -> State s b) -> State s b
    sa >>= f = State (\s -> 
        case run sa s of 
            (a, s1) ->  run (f a) s1)
```


* The `fmap` function takes a function `f` and a state object `sa` and returns a state object whose computation takes a state `s` and runs `sa` with `s` to copmute the result value `a` and the updated state `s1`. Finally, it returns the result of applying `f` to `a` and `s1`.
* The `pure` function takes a value of type `a` and return a `State` object by wrapping a lambda which takes a state `s` and returns back the same state `s` with the input value.
* The app function (`<*>`) takes a state object `sf` and a state object `sa`, its returned value is a state object that expects an input state `s` and run `sf` with `s` to extract the underlying function `f` with the updated state `s1`, then it runs `sa` with `s1` to extract the result `a` and the updated state `s2`. Finally, it returns the result of applying `f` to `a` and the updated state `s2`.
* In the bind function (`>>=`), we take a computation `sa` of type `State s a`, i.e. a stateful computation over state type `s` and return a result of type `a`. In addition, we take a function that expects input of type `a` and returns a stateful computation `State s b`. We return
a `State` object contains a function that takes the input state `s`, and running with `sa` to retrieve
the result `a` and the updated state `s1`, finally, the function run the state monad `f a` with `s1` to
compute `b` and the output state.


We consider the `MonadState` type class definition as follows,

```hs
-- mtl definition, please don't execute it.
class Monad m => MonadState s m | m -> s where
    -- | Return the state from the internals of the monad.
    get :: m s
    get = state (\s -> (s, s))
    -- | Replace the state inside the monad.
    put :: s -> m ()
    put s = state (\_ -> ((), s))
```
where `get` is the query function that accesses the current state, 
`put` is the setter function which "updates" the state by returning a (potentially new) state.

We provide the implementation for `MonadState s (State s)`.

```hs
instance MonadState s (State s) where
    -- get :: State s s
    get = State (\s -> (s,s)) 
    -- put :: s -> State s ()
    put s = State (\_ -> ((), s))
```

Let's consider the following example 

```hs
data Counter = Counter {c::Int} deriving Show

incr :: State Counter () 
incr = do 
    Counter c <- get
    put (Counter (c+1))


app :: State Counter Int
app = do 
    incr
    incr 
    Counter c <- get 
    return c
```

In the above we define the state environment as an integer counter. Monadic function `incr` increase the counter in the state. The `deriving` keyword generate the type class instance `Show Counter` automatically. Running `run app (Counter 0)` yields `(2, Counter {c = 2})`.


## Monad Laws

Similar to Functor and Applicative, all instances of Monad must satisfy the following
three Monad Laws.

1. Left Identity: `(return a) >>= f` $\equiv$ `f a`
2. Right Identity: `m >>= return` $\equiv$ `m`
3. Associativity: `(m >>= f) >>= g` $\equiv$ `m >>= (\x -> ((f x) >>= g))`

* Intutively speaking, a bind operation is to *extract* results of type `a` from its first argument with type `m a` and apply `f` to the extracted results.
* Left identity law enforces that binding a lifted value to `f`, is the same as applying `f` to the unlifted value directly, because the lifting and the *extraction* of the bind cancel each other.
* Right identity law enforces that binding a lifted value to `return`,  is the same as the lifted value, because *extracting* results from `m` and `return` cancel each other.
* The Associativity law enforces that binding a lifted value `m` to `f` then to `g` is the same as binding `m` to a monadic bind composition `\x -> ((f x) >>= g)`

## Summary

In this lesson we have discussed the following

1. A derived type class is a type class that extends from another one.
2. An Applicative Functor is a sub-class of Functor, with the methods `pure` and `<*>`.
3. The four laws for Applicative Functor.
4. A Monad Functor is a sub-class of Applicative Functor, with the method `>>=`.
5. The three laws of Monad Functor.
6. A few commonly used Monad such as, List Monad, Option Monad, Reader Monad and State Monad.

## Extra Materials (You don't need to know these to finish the project nor to score well in the exams)

### Writer Monad

The dual of the `Reader` Monad is the `Writer` Monad, which has the following definition.

```hs
-- mtl definition, please don't execute it.
data Writer w a = Writer { run :: (a,w) }

instance Functor (Writer w) where 
    -- fmap :: (a -> b) -> Write w a -> Writer w b
    fmap f (Writer (a,w)) = Writer (f a, w)

instance Monoid w => Applicative (Writer w) where 
    -- pure :: a -> Writer w a
    pure a = Writer (a, mempty)
    -- (<*>) :: Writer w (a -> b) -> Writer w a -> Writer w b
    (Writer (f,w1)) <*> (Writer (a,w2)) = Writer (f a, w1 <> w2)

instance Monoid w => Monad (Writer w) where 
    -- (>>=) :: Writer w a -> (a -> Writer w b) -> Writer w b
    (Writer (a,w)) >>= f = case f a of 
        (Writer (b, w')) -> (Writer (b, w <> w'))
```

A writer object stores the result and writer output state object which can be empty (via `mempty`) 
and extended (via `<>`). For simplicity, we can think of `mempty` is the default empty state,
for example, empty list `[]`, and `<>` is the append operation like `++`. For details about the `Monoid` type class refer to 
```url
https://hackage.haskell.org/package/base-4.16.3.0/docs/Prelude.html#g:9
```

The type class definition of `MonadWriter` is given in the `mtl` package as follows

```hs 
-- mtl definition, please don't execute it.
class (Monoid w, Monad m) => MonadWriter w m | m -> w where
    -- | 'tell' w is an action that produces the output w
    tell   :: w -> m ()
    -- | 'listen' m is an action that executes the action m and adds
    -- its output to the value of the computation.
    listen :: m a -> m (a, w)
    -- | 'pass' m is an action that executes the action m, which
    -- returns a value and a function, and returns the value, applying
    -- the function to the output.
    pass   :: m (a, w -> w) -> m a

instance Monoid w => MonadWriter w (Writer w) where 
    -- tell :: w -> Writer w ()
    tell w = Writer ((),w)
    -- listen :: Writer w a -> Writer w (a, w)
    listen (Writer (a,w)) = Writer ((a,w),w)
    -- pass :: Writer w (a, w -> w) -> Writer w a
    pass (Writer ((a, f), w)) = Writer (a, f w)
```

With these we are above to define a simple logger app as follows,

```hs
data LogEntry = LogEntry {msg::String} deriving Show 

logger :: String -> Writer [LogEntry] () 
logger s = tell [LogEntry s]

app :: Writer [LogEntry] Int
app = do 
    logger "start"
    x <- return (1 + 1)
    logger ("the result is " ++ show x)
    logger ("done")
    return x
```

Running `run app` yields 

```hs
(2,[LogEntry {msg = "start"},LogEntry {msg = "the result is 2"},LogEntry {msg = "done"}])
```

### Monad Transformer


In the earlier exection, we encounter our `State` datatype to record the computation in a state monad. 
What about the following, can it be use as a state datatype for a state monad? 

```hs
data MyState s a = MyState {run' :: s -> Maybe (a,s)}
```

The difference between this class and the `State` class we've seen earlier is that the execution method `run'` yields result of type `Maybe (s,a)` instead of `(s,a)` which means that it can potentially fail.

It is ascertained that `MyState` is also a Monad, and it is a kind of special State Monad.

```hs
instance Functor (MyState s) where 
    -- fmap :: (a -> b) -> MyState s a -> MyState s b
    fmap f sa = MyState (\s -> 
        case run' sa s of 
            Nothing -> Nothing
            Just (a, s1) -> Just (f a, s1))

instance Applicative (MyState s) where 
    -- pure :: a -> MyState s a
    pure a = MyState (\s -> Just (a, s))
    -- (<*>) :: MyState s (a -> b) -> MyState s a -> MyState s b
    sf <*> sa = MyState (\s -> 
        case run' sf s of 
            Nothing -> Nothing 
            Just (f, s1) -> case run' sa s1 of 
                Nothing -> Nothing 
                Just (a, s2) -> Just (f a, s2))

instance Monad (MyState s) where 
    -- (>>=) :: MyState s a -> (a -> MyState s b) -> MyState s b
    sa >>= f = MyState (\s -> 
        case run' sa s of 
            Nothing -> Nothing 
            Just (a, s1) ->  run' (f a) s1)

instance MonadState s (MyState s) where
    -- get :: MyState s s
    get = MyState (\s -> Just (s,s)) 
    -- put :: s -> MyState s ()
    put s = MyState (\_ -> Just ((), s))
```

Besides "stuffing-in" an `Maybe` type, one could use an `Either` type and etc. Is there a way to generalize this by parameterizing?
Seeking the answer to this question leads us to *Monad Transformer*.

We begin by parameterizing the `Option` functor in `MyState`

```hs
-- mtl definition, please don't execute it.
data StateT s m a = StateT {run :: s -> m (a, s)}

instance Monad m => Functor (StateT s m) where 
    -- fmap :: (a -> b) -> StateT s m a -> StateT s m b
    fmap f sma = StateT (\s -> do 
        (a,s1) <- run sma s
        return (f a, s1))

instance Monad m => Applicative (StateT s m) where  
    -- pure :: a -> StateT s m a
    pure a = StateT (\s -> return (a, s))
    -- (<*>) :: StateT s m (a -> b) -> StateT s m a -> StateT s m b
    smf <*> sma = StateT (\s -> do 
        (f, s1) <- run smf s
        (a, s2) <- run sma s1  
        return (f a, s2))

instance Monad m => Monad (StateT s m) where 
    -- (>>=) :: StateT s m a -> (a -> StateT s m b) -> StateT s m b
    sma >>= f = StateT (\s -> do 
        (a, s1) <- run sma s 
        run (f a) s1)

instance Monad m => MonadState s (StateT s m) where
    -- get :: StateT s m s
    get = StateT (\s -> return (s,s)) 
    -- put :: s -> StateT s m ()
    put s = StateT (\_ -> return ((), s))
```

In the above it is largely similar to `MyState` datatype, except that we parameterize `Maybe` by a type parameter `m`. As we observe from the type class instances that follow, `m` must be an instance of `Monad`, (which means `m` could be `Maybe`, `Either String`, and etc.)

Let `m` be `Maybe`, which is a Monad instance, we can replace `MonadState s (MyState s)` in terms of `MonadState s (StateT s m) ` and `Monad Maybe`.

```hs
type MyState s a = StateT s Maybe a
```

If we want to have a version with `Either String`, we could define

```hs
type MyState2 s a = StateT s (Either String) a
```

What about the original *vanilla* `State` Monad? Can we redefine it interms of `StateT`? 

We could introduce the `Identity` Monad.

```hs
-- mtl definition, please don't execute it.
data Identity a = Identity a 

instance Functor Identity where 
    -- fmap :: (a -> b) -> Identity a -> Identity b 
    fmap f (Identity a) = Identity (f a) 

instance Applicative Identity where 
    -- pure :: a -> Identity a
    pure a = Identity a
    -- (<*>) :: Identity (a -> b) -> Identity a -> Identity b
    (Identity f) <*> (Identity a) = Identity (f a)

instance Monad Identity where 
    -- (>>=) :: Identity a -> (a -> Identity b) -> Identity b
    (Identity a) >>= f = f a

type State s a = StateT s Identity a
```

One advantage of having Monad Transformer is that now we can create new Monad by composition of existing Monad Transformers. We are able to segregate and interweave methods from different Monad serving different purposes.

Similarly we could generalize the `Reader` Monad  to its transformer variant.

```haskell
-- mtl definition, please don't execute it.
data ReaderT r m a = ReaderT { run' :: r -> m a }

instance Monad m => Functor (ReaderT r m) where 
    -- fmap :: (a -> b) -> ReaderT r m a -> ReaderT r m b
    fmap f rma = ReaderT (\r -> do 
        a <- run' rma r
        return (f a))

instance Monad m => Applicative (ReaderT r m)  where  
    -- pure :: a -> ReaderT r m a
    pure a = ReaderT (\r -> return a)
    -- (<*>) :: ReaderT r m (a -> b) -> ReaderT r m a -> ReaderT r m b
    rmf <*> rma = ReaderT (\r -> do 
        f <- run' rmf r
        a <- run' rma r  
        return (f a))

instance Monad m => Monad (ReaderT r m) where 
    -- (>>=) :: ReaderT r m a -> (a -> ReaderT r m b) -> ReaderT r m b
    rma >>= f = ReaderT (\r -> do 
        a <- run' rma r 
        run' (f a) r)


instance Monad m => MonadReader r (ReaderT r m) where
    -- ask :: ReaderT r m r
    ask = ReaderT (\r -> return r)
    -- local :: (r -> r) -> ReaderT r m a -> ReaderT r m a
    local f rma = ReaderT (\r -> 
        let t = f r
        in run' rma t)

type Reader r a = ReaderT r Identity a
```

Note that the order of how Monad Transfomers being stacked up makes a difference,

For instance, can you explain what the difference between the following two monad object types is?

```hs
type ReaderState r s a = ReaderT r (StateT s Identity) a  
type StateReader r s a = StateT s (ReaderT r Identity) a
```
