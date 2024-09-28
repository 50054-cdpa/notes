# 50.054 - Parametric Polymorphism and Adhoc Polymorphism 


## Learning Outcomes

By this end of this lesson, you should be able to 

* develop parametrically polymorphic Haskell code using Generic, Algebraic Datatype
* safely mix parametric polymoprhism with adhoc polymoprhism (overloading) using type classes 
* develop generic programming style code using `Functor` type class.
* make use of `Maybe` and `Either` to handle and manipulate errors and exceptions. 


## Currying

In functional programming, we could rewrite a function with multiple arguments into a function that takes the first argument and returns another function that takes the remaining arguments.

For example,

```hs
sum :: (Int,Int) -> Int
sum (x,y) = x + y
```

can be rewritten into 

```hs
sum_curry :: Int -> Int -> Int 
sum_curry x y = x + y
```

These two functions are equivalent except that

1. Their invocations are different, e.g. 

```hs
sum (1,2)
sum_curry 1 2
```

2. It is easier to reuse the curried version to define other function, e.g.

```hs
plus1 :: Int -> Int 
plus1 x = sum_curry 1 x
```

## Function Composition



In math, let $g$ and $f$ be functions, then

$$
(g \circ f)(x) \equiv g(f(x))
$$


In Haskell, there exists a prelude function (predefined function) `(.)` which composes two functions 

```hs
-- prelude definitions, please don't execute it.
(.) :: (b -> c) -> (a -> b) -> a -> c 
(.) g f = \x -> g (f x)
```

For example

```hs
f x = 2 * x + 3 
g x = x * x 

(.) g f 2 == g (f 2)
```

In Haskell, the symbols enclosed in a pair of parenthesis are user-defined infix operators. Hence `(.) g f 2` in the above can be rewritten as 

```hs
(g . f) 2
```

> Note we have to put extra parathenses, since function applications are left associated, without the paranthesis 
`g . f 2` will be parsed as `((g .) f) 2` by Haskell which is ill-typed.

## Generics

Generics is also known as type variables. It enables a language to support parametric polymoprhism. 

### Polymorphic functions

Recall that the `reverse` function introduced in the last lesson

```hs
reverse :: [Int] -> [Int] 
reverse l = case l of 
    [] -> [] 
    hd:tl -> reverse tl ++ [hd]
```

We argue that the same implementation should work for all lists regardless of their elements' type. Thus, we would replace `Int` by a type variable `a`.

```hs
reverse :: [a] -> [a] 
reverse l = case l of 
    [] -> [] 
    hd:tl -> reverse tl ++ [hd]

```

### Polymorphic Algebraic Datatype


Recall that the following Algebraic Datatype from the last lesson. 

```hs
data MyList = Nil | Cons Int MyList

mapML f Nil          = Nil 
mapML f (Cons hd tl) = Cons (f hd) (mapML f tl)
```

Same observation applies. `MyList` could have a generic element type `a` instead of `Int` and `mapML` should remains unchanged.


```hs
data MyList a = Nil | Cons a MyList
-- mapML definition remains unchanged
```

After the update,  `MyList` does represent a type, but a type constructor. This is because 
`MyList` itself is not a type, but `MyList Int`, `MyList String` or `MyList a` are types. 


## Type class

Suppose we would like to convert some of the Haskell values to JSON strings,
we could rely on overloading.

```hs
toJS :: Int -> String 
toJS v = show v

toJS :: String -> String 
toJS v = "'" ++ v ++ "'"

toJS :: Bool -> String 
toJS True = "true"
toJS False = "false" 
```
> `show` is a prelude function that converts values to string.

However the above is rejected by ghc. 

```hs
 Multiple declarations of ‘toJS’
```

We could give different names to the different versions of `toJS` but this s


```hs
intToJS :: Int -> String 
intToJS v = show v

strToJS :: String -> String 
strToJS v = "'" ++ v ++ "'"

boolToJS :: Bool -> String 
boolToJS True = "true"
boolToJS False = "false" 
```

This becomes hard to manage as we consider complex datatype.

```hs
data Contact = Email String | Phone String 

contactToJS :: Contact -> String 
contactToJS (Email e) = "{'email': " ++ strToJS e ++"}"
contactToJS (Phone ph) = "{'Phone': " ++ strToJS ph ++"}"
```

For now, let's bear with this cumbersomeness and continue to extend our `toJS` funcitons to handle
the follwing data types

```hs 
data Team   =  Team [Person]
data Person =  Person String [Contact]

teamToJS :: Team -> String 
teamToJS (Team members) = "{'team':{ 'members' : " ++  personsToJS members ++  "}}"

personToJS :: Person -> String 
personToJS (Person name contacts) = 
    "{'person':{ 'name':" ++ strToJS name ++ ", 'contacts':" ++ contactsToJS contacts ++ "}}"

personsToJS :: [Person] -> String
personsToJS persons = 
    let ps = map personToJS persons
    in "[" ++ interleave "," ps ++ "]"

interleave :: String -> [String] -> String
interleave del [] = []
interleave del [x] = x
interleave del (x:xs) = x ++ del ++ interleave del xs

contactsToJS :: [Contact] -> String 
contactsToJS contacts = 
    let cs = map contactToJS contacts 
    in "[" ++ interleave "," cs ++ "]" 
```

The second issue is that the `personsToJS` and `contactsToJS` are the identical modulo the variable names (and the types). Can we combine two into one?

```hs
listToJS :: (a -> String) -> [a] -> String 
listToJS f l = 
    let xs = map f l 
    in "[" ++ interleave "," xs ++ "]" 

personsToJS l = listToJS personToJS l
contactsToJS l = listToJS contactToJS l
```

The issue is partially resolved, because `listToJS` expects a function argument of type `a -> String` although 
by specification, we want to restrict it to be one of the `toJS` functions we defined earlier, but we can't enforce it.

At this stage with have many different versions of `toJS` with different implementations and different shapes of type signature. It is a not a good approach to manage software.

One solution to address these issues is to use *type class*.

```hs
{-# LANGUAGE FlexibleInstances #-}

class JS a where 
    toJS :: a -> String 
```

In the above, we define a type class `JS` via the `class ... where` keywords. 
If this is the first time you encounter Haskell type class, you could treat it as the Haskell way of definining an interface in Java.  In the above definition, we define an type class `JS a` which says whatever type `a` could be in `JS a` shoud have an obligational implementation of `toJS :: a -> String`.  
> The GHC pragma `{-# LANGUAGE FlexibleInstances #-}` indicates that we need to enable the flexible-insances extension to support `JS String` (which is `JS [Char]`). Without this pragma, we can't define complex type expression type class instances that involving a type constructor being applied to non type variables.

Using `instance ... where` keywords, we define some type class instances (concrete implementation) of `JS a` as follows

```hs
instance JS Int where 
    toJS v = show v

instance {-# OVERLAPS #-} JS String where 
    toJS v = "'" ++ v ++ "'"

instance JS Bool where 
    toJS True = "true"
    toJS False = "false" 

instance JS Contact where 
    toJS (Email e) = "{'email': " ++ toJS e ++"}"
    toJS (Phone ph) = "{'Phone': " ++ toJS ph ++"}"

instance JS Person where 
    toJS (Person name contacts) = 
        "{'person':{ 'name':" ++ toJS name ++ ", 'contacts':" ++ toJS contacts ++ "}}"

instance JS Team where 
    toJS (Team members) = "{'team':{ 'members' : " ++  toJS members ++  "}}"

instance JS b => JS [b] where 
    toJS as = 
        let xs = map toJS l 
        in "[" ++ interleave "," xs ++ "]" 
```
In each instance, we "specialize" the type parameter `a` in `JS a` with another more concreate type. In the body of the instance, we provide the concrete implementation of the `toJS` function with the specific type. 

* One alarming thing is that the `JS [b]` instance is overlapping with `JS String`, because in Haskell `String` is a type alias of `[Char]`. Hence we argue that `JS [Char]` is overlapping with `JS [b]`. Hence we need to add an instance pragma `{-# OVERLAPS #-}` to tell the ghc compiler to try apply `JS [Char]` whenever possible, otherwise, try `JS [b]`. 
* Another "magical" thing of Haskell type class is that the use of the `toJS` function is overloaded based on the type context which can be automatically resolved by the compiler. For example, in the body of the `JS Team` instance, the use `toJS members` is resolved to the isntance `JS [Person]` which will be given by the instances `JS [b]` and `JS Person`. 
* Thirdly, the `JS [b]` instance, relies on a context, namely `JS b =>`. The context `JS b` introduces an "type level assumption" under which the use of `toJS` in `map toJS l` must be well-defined given `l` has type `[b]` and `JS b` has been assumed existing. 

Finally, we can test the code, 

```hs
myTeam = Team [ Person "kenny" [Email "kenny_lu@sutd.edu.sg"], 
    Person "simon" [Email "simon_perrault@sutd.edu.sg"]]

toJS myTeam 
```
yields

```javascript
'team':{ 'members':['person':{ 'name':'kenny',  'contacts':['email': 'kenny_lu@sutd.edu.sg'] },'person':{ 'name':'simon',  'contacts':['email': 'simon_perrault@sutd.edu.sg'] }] }
```


Note that when we call a function that requires a type class context, we do not need to provide the argument for the type class instance. 

```hs
printAsJSON :: JS a => a -> IO () 
printAsJSON v = print (toJS v)

printAsJSON myTeam
```

Type class enables us to develop modular and resusable codes. It is related to a topic of *Generic Programming*. In computer programming, generic programming refers to the coding approach which an instance of code is written once and used for many different types/instances of values/objects.


In the next few section, we consider some common patterns in FP that are promoting generic programming.


## Functor

Recall that we have a `map` method for list datatype. 

```hs
l = [1,2,3]
map (\x -> x + 1) l
```

Can we make `map` to work for other data type? For example

```hs
data BTree a = Empty | 
    Node a (BTree a) (BTree a) -- ^ a node with a value and the left and right sub trees.
```

It turns out that extending `map` to different datatypes is similar to `toJS` function that we implemented earlier. We consider using a type class for this purpose. The following is a prelude type class in GHC.


```hs
-- prelude definitions, please don't execute it.
class Functor t where 
    fmap :: (a -> b) -> t a -> t b
```

In the above type class definition, `t` denotes a type parameter of kind `* -> *`. A *kind* is a type of types. In the above, `* -> *` it means `Functor`'s argument must be a type constructor. For instance, it could be `MyList` or `BTree` and etc, but not `Int` and `Bool`. (C.f. In the type class `JS`, the type argument has kind `*`.)

The following is a prelude type class instance for `Functor List` (or as short-hand `Functor []`) 
```hs
-- prelude definitions, please don't execute it.
instance Functor [] where 
    fmap f l = map f l
```

For the `BTree` data type, we need to provide the type class instance as follows,

```hs
instance Functor BTree where 
    fmap f Empty = Empty
    fmap f (Node v lft rgt) = 
        Node (f v) (fmap f lft) (fmap f rgt)
```

Some examples

```hs
l = [1,2,3]
fmap (\x -> x + 1) l 
-- yields [2,3,4]

t = Node 2 (Node 1 Empty Empty) (Node 3 Empty Empty)
fmap (\x -> x + 1) t
-- yields Node 3 (Node 2 Empty Empty) (Node 4 Empty Empty)
```

### Functor Laws

All instances of functor must obey a set of mathematic laws for their computation to be predictable.

Let `i` be a functor instance
1. Identity: `\i-> fmap \x->x i` $\equiv$ `\y -> y`. When performing the mapping operation, if the values in the functor are mapped to themselves, the result will be an unmodified functor.
2. Composition Morphism: `\i-> fmap (f . g) i` $\equiv$ `(\i -> fmap f i) . (\j -> fmap g j)`. If two sequential mapping operations are performed one after the other using two functions, the result should be the same as a single mapping operation with one function that is equivalent to applying the first function to the result of the second.


## Foldable

Similarly we find a prelude type class `Foldable` for `foldl` and `foldr` operations

```hs
-- prelude definitions, please don't execute it.
class Foldable t where 
    foldl :: (b -> a -> b) -> b -> t a -> b
    foldr :: (a -> b -> b) -> b -> t a -> b


instance Foldable List where 
    foldl f acc [] = acc 
    foldl f acc (x:xs) = foldl f (f acc x) xs
    foldr f acc [] = acc
    foldr f acc (x:xs) = f x (foldr f acc xs)
```

As for the `BTree` datatype, we need to define the instance as follows

```hs
instance Foldable BTree where 
    foldl f acc Empty = acc
    foldl f acc (Node v lft rgt) = 
        let acc1 = f acc v
            acc2 = foldl f acc1 lft
        in foldl f acc2 rgt
    foldr f acc Empty = acc
    foldr f acc (Node v lft rgt) = 
        f v (foldr f (foldr f acc rgt) lft)

foldl (\x y -> x + y) 0 l -- yields 6
foldl (\x y -> x + y) 0 t -- yields 6
```


## Maybe and Either

Recall in the earlier lesson, we encountered the following example. 

```hs
data MathExp = 
    Plus  MathExp MathExp | 
    Minus MathExp MathExp |
    Mult  MathExp MathExp |
    Div   MathExp MathExp | 
    Const Int

eval :: MathExp -> Int
eval e = case e of 
    Plus  e1 e2 -> eval e1 + eval e2
    Minus e1 e2 -> eval e1 - eval e2
    Mult  e1 e2 -> eval e1 * eval e2
    Div   e1 e2 -> eval e1 `div` eval e2
    Const i     -> i
```

An error occurs when we try to evalue a `MathExp` which contains a division by zero sub-expression. Executing 

```hs
eval (Div (Const 1)  (Minus (Const 2) (Const 2)))
```
yields

```hs
*** Exception: divide by zero
```


Like other main stream languages, we could use `try-catch` statement to handle the exception. 
One downside of this approach is that at compile type it is hard to track the unhandled exceptions.

A more fine-grained approach is to use algebraic datatype to "inform" the compiler (and other programmers who use this function and datatypes) that this function is not always producing an integer as the result.

Consider the following prelude Haskell datatype `Maybe`

```hs
-- prelude definitions, please don't execute it.
data Maybe a = None | Just a
```

```hs
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

When we execute `eval (Div (Const 1)  (Minus (Const 2) (Const 2)))`, 
we get `Nothing` as the result instead of the exception. One advantage of this is that whoever is using `eval` function has to respect that its return type is `Maybe Int` instead of just `Int` therefore, a `case` pattern matching must be applied before using the result to look out for potential `Nothing` value.

There are still two drawbacks. Firstly, the updated version of the `eval` function is much more verbose compared to the original *unsafe* version. We will address this issue in the next lesson. Secondly, we lose the chance of reporting where the division by zero has occured. Let's address the second issue.

We could instead of using `Maybe`, use the `Either` datatype, which is also defined in the prelude.

```hs
-- prelude definitions, please don't execute it.
data Either a b = Left a | Right b
```

We adjust the definition as follows

```hs
type ErrMsg = String
eval :: MathExp -> Either ErrMsg Int 
eval (Plus e1 e2) = case eval e1 of 
    Left err -> Left err 
    Right v1 -> case eval e2 of 
        Left err -> Left err 
        Right v2 -> Right (v1 + v2)
eval (Minus e1 e2) = case eval e1 of 
    Left err -> Left err 
    Right v1 -> case eval e2 of 
        Left err -> Left err 
        Right v2 -> Right (v1 - v2)
eval (Mult e1 e2) = case eval e1 of 
    Left err -> Left err 
    Right v1 -> case eval e2 of 
        Left err -> Left err 
        Right v2 -> Right (v1 * v2)
eval (Div e1 e2) = case eval e1 of 
    Left err -> Left err 
    Right v1 -> case eval e2 of 
        Left err -> Left err 
        Right 0  -> Left ("div by zero caused by " ++ show (Div e1 e2))
        Right v2 -> Right (v1 `div` v2)
eval (Const v) = Right v 
```

To make `show (Div e1 e2)` to works, we need to make the `MathExp` type as an instance of the `Show` type class or
a quick fix

```hs
data MathExp = ...
    deriving Show -- auto derive the Show instance for this data type.
```

Executing `eval (Div (Const 1)  (Minus (Const 2) (Const 2)))` yields

```hs
Left "div by zero caused by Div (Const 1) (Minus (Const 2) (Const 2))"
```

## Summary

In this lesson, we have discussed 

* how to develop parametrically polymorphic haskell code using Generic, Algebraic Datatype
* how to safely mix parametric polymoprhism with adhoc polymoprhism (overloading) using type classes 
* how to develop generic programming style code using `Functor` type class.
* how to make use of `Maybe` and `Either` to handle and manipulate errors and exceptions. 


## Appendix

### Generalized Algebraic Data Type

Generalized Algebraic Data Type is an extension to Algebraic Data Type, in which each case extends a more specific version of the top level algebraic data type. Consider the following example.

Firstly, we need some type acrobatics to encode nature numbers on the level of type. 

```hs
data Zero = Zero 
data Succ a = Succ a  
```

We use these two data types to encode natural numbers, 

```hs
Zero             -- as 0
Succ Zero        -- as 1
Succ (Succ Zero) -- as 2
```

Next we define our GADT `SList s a` which is a generic list of elements `a` and with size `s`. 

```hs
data SList s a where 
    Nil  :: SList Zero a                        -- ^ additional type constraint, s = Zero
    Cons :: a -> SList n a -> SList (Succ n) a  -- ^ additional type constraint, s = (Succ n) for some n
```

In the first subcase `Nil`, it is declared with the type of `SList Zero a` which indicates on type level that the list is empty. In the second case `Cons`, we define it to have the type `SList (Succ n) a` for some natural number `n`. This indicates on the type level that the list is non-empty. 

Having these information lifted to the type level allows us to define a type safe `head` function.

```hs
head :: SList (Succ n) a -> a 
head (Cons hd tl) = hd 
```

Compiling `head Nil` yields a type error. 

Similarly we can define a size-aware function `snoc` which add an element at the tail of a list. 

```hs
snoc :: a -> SList n a -> SList (Succ n) a 
snoc v nil          = Cons v nil
snoc v (Cons hd tl) = Cons hd (snoc v tl)
```

If for some reason, we replace the 2nd clause of `snoc` with 

```hs
snoc v (Cons hd tl) = snoc v tl
```
It will result in a compilation error. 