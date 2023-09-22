# 50.054 - Parametric Polymorphism and Adhoc Polymorphism 


## Learning Outcomes

By this end of this lesson, you should be able to 

* develop parametrically polymorphic Scala code using Generic, Algebraic Datatype
* safely mix parametric polymoprhism with adhoc polymoprhism (overloading) using type classes 
* develop generic programming style code using `Functor` type class.
* make use of `Option` and `Either` to handle and manipulate errors and exceptions. 


## Currying

In functional programming, we could rewrite a function with multiple arguments into a function that takes the first argument and returns another function that takes the remaining arguments.

For example,

```scala
def sum(x:Int, y:Int):Int = x + y
```

can be rewritten into 

```scala
def sum_curry(x:Int)(y:Int):Int = x + y
```

These two functions are equivalent except that

1. Their invocations are different, e.g. 
```scala
sum(1,2)
sum_curry(1)(2)
```
2. It is easier to reuse the curried version to define other function, e.g.
```scala
def plus1(x:Int):Int = sum_curry(1)(x)
```

## Function Composition

Every function and method in Scala is an object with a `.compose()` method. It works like the mathmethical composition.

In math, let $g$ and $f$ be functions, then

$$
(g \circ f)(x) \equiv g(f(x))
$$


Let `g` and `f` be Scala functions (or methods), then

```scala
g.compose(f)
```
is equivalent to 
```scala
x => g(f(x))
```

For example

```scala
def f(x:Int):Int = 2 * x + 3
def g(x:Int):Int = x * x

assert((g.compose(f))(2) == g(f(2)))
```

## Generics

Generics is also known as type variables. It enables a language to support parametric polymoprhism. 

### Polymorphic functions

Recall that the `reverse` function introduced in the last lesson
```scala
def reverse(l:List[Int]):List[Int] = l match {
    case Nil => Nil
    case (hd::tl) => reverse(tl) ++ List(hd)
}
```

We argue that the same implementation should work for all lists regardless of their elements' type. Thus, we would replace `Int` by a type variable `A`.

```scala
def reverse[A](l:List[A]):List[A] = l match {
    case Nil => Nil
    case (hd::tl) => reverse(tl) ++ List(hd)
}
```

### Polymorphic Algebraic Datatype


Recall that the following Algebraic Datatype from the last lesson. 

```scala
enum MyList {
    case Nil
    case Cons(x:Int, xs:MyList)
}

def mapML(l:MyList, f:Int => Int):MyList = l match {
    case MyList.Nil => MyList.Nil
    case MyList.Cons(hd, tl) => MyList.Cons(f(hd), mapML(tl, f))
}
```

Same observation applies. `MyList` could have a generic element type `A` instead of `Int` and `mapML` should remains unchanged.


```scala
enum MyList[A] {
    case Nil // type error
    case Cons(x:A, xs:MyList[A])
}

def mapML[A,B](l:MyList[A], f:A => B):MyList[B] = l match {
    case MyList.Nil => MyList.Nil
    case MyList.Cons(hd, tl) => MyList.Cons(f(hd), mapML( tl, f))
}
```

The caveat here is that the Scala compiler would complain about the `Nil` case above 

```
-- Error: ----------------------------------------------------------------------
2 |    case Nil
  |    ^^^^^^^^
  |    cannot determine type argument for enum parent class MyList,
  |    type parameter type A is invariant
1 error found
```

To understand that error, we need to understand how Scala desugar the enum datatype.  The above `MyList` datatype is desugared as 

```scala
enum MyList[A] {
    case Nil extends MyList[Nothing] // type error
    case Cons(x:A, xs:MyList[A]) extends MyList[A]
}
```
In which all sub cases within the enum type must be sub-class of the enum type. 
However it is not trivial for `Nil`. It can't be declared as a subtype of `MyList[A]` since type variable `A` is not mentioned in its definition, unlike `Cons(x:A, xs:MyList[A])`. The best we can get is `MyList[Nothing]` where `Nothing` is the subtype of all other types in Scala. (As the dual, `Any` is the supertype of all other types in Scala). We are getting very close. Now we know that `Nil extends MyList[Nothing]`. If we can argue that `MyList[Nothing] extends MyList[A]` then we are all good. For `MyList[Nothing] extends MyList[A]` to hold, 
`A` must be covariant type parameter.

In type system with subtyping, 

*  a type is *covariant* if it preserves the subtyping order when it is applied a type constructor. In the above situation, `MyList[_]` is a type constructor. The type parameter `A` is covarient because we note `Nothing <: A` for all `A`, thus `MyList[Nothing] <: MyList[A]`. 

* a type is *contravariant* if it reverses the subtyping order when it is applied to a type constructor. For instance, given function type `A => Boolean`, the type parameter `A` is contravariant, because for `A <: B`, we have `B => Boolean <: A => Boolean`. (We can use functions of type
`B => Boolean` in the context where a function `A => Boolean` is expected, but not the other way round.)

* a type is *invariant* if it does not preserve nor reverse the subtyping order when it is applied to a type constructor. 

Hence to fix the above type error with the `MyList[A]` datatype, we declared that `A` is covariant, `+A`. 

```scala
enum MyList[+A] {
    case Nil // type error is fixed.
    case Cons(x:A, xs:MyList[A])
}

def mapML[A,B](l:MyList[A])(f:A => B):MyList[B] = l match {
    case MyList.Nil => MyList.Nil
    case MyList.Cons(hd, tl) => MyList.Cons(f(hd), mapML(tl)(f))
}
```
For easy of reasoning, we also rewrite `mapML` into currying style.

Recall that we could make `mapML` function as a method of `MyList`

```scala
enum MyList[+A] {
    case Nil
    case Cons(x:A, xs:MyList[A])
    def mapML[B](f:A=>B):MyList[B] = this match { 
        case MyList.Nil => MyList.Nil
        case MyList.Cons(hd, tl) => MyList.Cons(f(hd), tl.mapML(f))
    }
}
```

* [Scala Variances](https://docs.scala-lang.org/tour/variances.html)




## Type class

Suppose we would like to convert some of the Scala value to JSON string.

We could rely on overloading.

```scala
def toJS(v:Int):String = v.toString
def toJS(v:String):String = s"'${v}'"
def toJS(v:Boolean):String = v.toString
```

Given `v` is a Scala string value, `s"some_prefix ${v} some_suffix"` denotes a Scala string interpolation, which inserts `v`'s content into the "place holder" in the string `"some_prefix ${v} some_suffix"` where the 
`${v}` is the place holder.

However this becomes hard to manage as we consider complex datatype.

```scala
enum Contact {
    case Email(e:String)
    case Phone(ph:String)
}

import Contact.*
def toJS(c:Contact):String = c match {
    case Email(e) => s"'email': ${toJS(e)}" // compilation error
    case Phone(ph) => s"'phone': ${toJS(ph)}" // compilation error
}
```

When we try to define the `toJS` function for `Contact` datatype, we can't make use of the `toJS` function for string value because the compiler is confused that we are trying to make recursive calls. This is the first issue we faced.

Let's pretend that the first issue has been addressed. There's still another issue.

Consider

```scala
case class Person(name:String, contacts:List[Contact])
case class Team(members:List[Person])
```

A `case class` is like a normal class we have seen earlier except that we can apply pattern matching to its values. 
Let's continue to overload `toJS` to handle `Person` and `Team`. 

```scala
def toJS(p:Person):String = p match {
    case Person(name, contacts) => s"'person':{ 'name':${toJS(name)},  'contacts':${toJS(contacts)} }"
}
def toJS(cs:List[Contact]):String = {
    val j = cs.map(c=>toJS(c)).mkString(",")
    s"[${j}]"
}

def toJS(t:Team):String = t match {
    case Team(members) => s"'team':{ 'members':${toJS(members)} }"
}

def toJS(ps:List[Person]):String = {
    val j = ps.map(p=>toJS(p)).mkString(",")
    s"[${j}]"
}
```

The second issue is that the `toJS(cs:List[Contact])` and `toJS(ps:List[Person])` are the identical modulo the variable names. Can we combine two into one?

```scala
def toJS[A](vs:List[A]):String = {
        val j = vs.map(v=>toJS(v)).mkString(",") // compiler error
    s"[${j}]"
}
```
However a compilation error occurs because the compiler is unable to resolve the `toJS[A](v:A)` used in the `.map()`.

It seems that we need to give some extra information to the compiler so that it knows that when we use the above generic `toJS` we are referring to either `Person` or `Contact`, or whatever type that has a `toJS` defined.

One solution to address the two above issues is to use *type class*.
In Scala 3, a type class is defined by a polymoprhic trait and a set of type class instances. 

```scala
trait JS[A] {
    def toJS(v:A):String
}

given toJSInt:JS[Int] = new JS[Int]{ 
    def toJS(v:Int):String = v.toString
}

given toJSString:JS[String] = new JS[String] {
    def toJS(v:String):String = s"'${v}'"
}

given toJSBoolean:JS[Boolean] = new JS[Boolean] {
    def toJS(v:Boolean):String = v.toString
}

given toJSContact(using jsstr:JS[String]):JS[Contact] = new JS[Contact] {
    import Contact.*
    def toJS(c:Contact):String = c match {
        case Email(e) => s"'email': ${jsstr.toJS(e)}" // compilation error is fixed
        case Phone(ph) => s"'phone': ${jsstr.toJS(ph)}" // compilation error is fixed
    }
}

given toJSPerson(using jsstr:JS[String], jsl:JS[List[Contact]]):JS[Person] = new JS[Person] {
    def toJS(p:Person):String = p match {
        case Person(name, contacts) => s"'person':{ 'name':${jsstr.toJS(name)},  'contacts':${jsl.toJS(contacts)} }"
    }
}

given toJSTeam(using jsl:JS[List[Person]]):JS[Team] = new JS[Team] {
    def toJS(t:Team):String = t match {
        case Team(members) => s"'team':{ 'members':${jsl.toJS(members)} }"
    }
}

given toJSList[A](using jsa:JS[A]):JS[List[A]] = new JS[List[A]] {
    def toJS(as:List[A]):String = {
        val j = as.map(a=>jsa.toJS(a)).mkString(",")
        s"[${j}]"
    }
}
```

`given` defines a type class instance. An instance consists of a name and the context parameters (those with `using`) and instance type. In the body of the type class instance, we instantiate an anonymous object that extends type class with the specific type and provide the defintion. We can refer to the particular type class instance by the instance's name. For instance


```scala
import Contact.*
val myTeam = Team( List(
    Person("kenny", List(Email("kenny_lu@sutd.edu.sg"))), 
    Person("simon", List(Email("simon_perrault@sutd.edu.sg")))
))
```

`toJSTeam.toJS(myTeam)` yields

```javascript
'team':{ 'members':['person':{ 'name':'kenny',  'contacts':['email': 'kenny_lu@sutd.edu.sg'] },'person':{ 'name':'simon',  'contacts':['email': 'simon_perrault@sutd.edu.sg'] }] }
```

We can also refer to the type class instance by the instace's type. For example, recall the last two instances. In the context of the `toJSTeam`, we refer to another instance of type `JS[List[Person]]`. Note that none of the defined instances has the required type. Scala is smart enought to synthesize it from the instances of `toJSList` and `toJSPerson`.  Given the required type class instance is `JS[List[Person]]`, the type class resolver finds the instance `toJSList` having type `JS[List[A]]`, and it unifies both and find that `A=Person`. In the context of the instance `toJSList`, `JS[A]` is demanded. We can refine the required instance's type as `JS[Person]`, which is `toJSPerson`.

Note that when we call a function that requires a type class context, we do not need to provide the argument for the type class instance. 

```scala
def printAsJSON[A](v:A)(using jsa:JS[A]):Unit = {
    println(jsa.toJS(v))
}

printAsJSON(myTeam)
```

Type class enables us to develop modular and resusable codes. It is related to a topic of *Generic Programming*. In computer programming, generic programming refers to the coding approach which an instance of code is written once and used for many different types/instances of values/objects.


In the next few section, we consider some common patterns in FP that are promoting generic programming.


## Functor

Recall that we have a `map` method for list datatype. 

```scala
val l = List(1,2,3)
l.map(x => x + 1)
```

Can we make `map` to work for other data type? For example

```scala
enum BTree[+A] {
    case Empty
    case Node(v:A, lft:BTree[A], rgt:BTree[A]) 
}
```

It turns out that extending `map` to different datatypes is similar to `toJS` function that we implemented earlier. We consider introducing a type class for this purpose.


```scala
trait Functor[T[_]] {
    def map[A,B](t:T[A])(f:A => B):T[B]
}
```
In the above type class definition, `T[_]` denotes a polymorphic type that of kind `* => *`. A *kind* is a type of types. In the above, it means `Functor` takes any type constructors `T`. When `T` is instantiated, it could be `List[_]` or `BTree[_]` and etc. (C.f. In the type class `JS[A]`, the type argument has kind `*`.)


```scala
given listFunctor:Functor[List] = new Functor[List] {
    def map[A,B](t:List[A])(f:A => B):List[B] = t.map(f)
}

given btreeFunctor:Functor[BTree] = new Functor[BTree] {
    import BTree.*
    def map[A,B](t:BTree[A])(f:A => B):BTree[B] = t match {
        case Empty => Empty
        case Node(v, lft, rgt) => Node(f(v), map(lft)(f), map(rgt)(f))
    }
}
```

Some example

```scala
val l = List(1,2,3)
listFunctor.map(l)((x:Int) => x + 1)

val t = BTree.Node(2, BTree.Node(1, BTree.Empty, BTree.Empty), BTree.Node(3, BTree.Empty, BTree.Empty))
btreeFunctor.map(t)((x:Int) => x + 1)

```

### Functor Laws

All instances of functor must obey a set of mathematic laws for their computation to be predictable.

Let `i` be a functor instance
1. Identity: `i => map(i)(x => x)` $\equiv$ `x => x`. When performing the mapping operation, if the values in the functor are mapped to themselves, the result will be an unmodified functor.
2. Composition Morphism: `i=> map(i)(f.compose(g))` $\equiv$ `(i => map(i)(f)).compose(j => map(j)(g))`. If two sequential mapping operations are performed one after the other using two functions, the result should be the same as a single mapping operation with one function that is equivalent to applying the first function to the result of the second.


## Foldable

Similarly we can define a `Foldable` type class for generic and overloaded `foldLeft`( and `foldRight`).

```scala
trait Foldable[T[_]]{
    def foldLeft[A,B](t:T[B])(acc:A)(f:(A,B)=>A):A
}

given listFoldable:Foldable[List] = new Foldable[List] {
    def foldLeft[A,B](t:List[B])(acc:A)(f:(A,B)=>A):A = t.foldLeft(acc)(f)
}

given btreeFoldable:Foldable[BTree] = new Foldable[BTree] {
    import BTree.*
    def foldLeft[A,B](t:BTree[B])(acc:A)(f:(A,B)=>A):A = t match {
        case Empty => acc
        case Node(v, lft, rgt) => {
            val acc1 = f(acc,v)
            val acc2 = foldLeft(lft)(acc1)(f)
            foldLeft(rgt)(acc2)(f)
        }
    }
}

listFoldable.foldLeft(l)(0)((x:Int,y:Int) => x + y)
btreeFoldable.foldLeft(t)(0)((x:Int,y:Int) => x + y)
```


## Option and Either

Recall in the earlier lesson, we encountered the following example. 

```scala
enum MathExp {
    case Plus(e1:MathExp, e2:MathExp)
    case Minus(e1:MathExp, e2:MathExp)
    case Mult(e1:MathExp, e2:MathExp)
    case Div(e1:MathExp, e2:MathExp)
    case Const(v:Int)
}

def eval(e:MathExp):Int = e match {
    case MathExp.Plus(e1, e2)  => eval(e1) + eval(e2)
    case MathExp.Minus(e1, e2) => eval(e1) - eval(e2)
    case MathExp.Mult(e1, e2)  => eval(e1) * eval(e2)
    case MathExp.Div(e1, e2)   => eval(e1) / eval(e2)
    case MathExp.Const(i)      => i
}
```

An error occurs when we try to evalue a `MathExp` which contains a division by zero sub-expression. Executing 

```scala
import MathExp.*
eval(Div(Const(1), Minus(Const(2), Const(2))))
```
yields

```
java.lang.ArithmeticException: / by zero
  at rs$line$2$.eval(rs$line$2:5)
  ... 41 elided
```

Like other main stream languages, we could use `try-catch` statement to handle the exception. 


```scala
try {
    import MathExp.*
    eval(Div(Const(1), Minus(Const(2), Const(2))))
}
catch {
    case e:java.lang.ArithmeticException => println("handinging div by zero")
}
```

One downside of this approach is that at compile type it is hard to track the unhandled exceptions, (in particular with the presence of Java unchecked exceptions.)

A more fine-grained approach is to use algebraic datatype to "inform" the compiler (and other programmers who use this function and datatypes).

Consider the following builtin Scala datatype `Option`

```scala
// no need to run this.
enum Option[+A] {
    case None
    case Some(v:A)
}
```

```scala
def eval(e:MathExp):Option[Int] = e match {
    case MathExp.Plus(e1, e2)  => eval(e1) match {
        case None     => None
        case Some(v1) => eval(e2) match {
            case None     => None 
            case Some(v2) => Some(v1 + v2)            
        }
    }
    case MathExp.Minus(e1, e2) => eval(e1) match {
        case None     => None
        case Some(v1) => eval(e2) match {
            case None     => None 
            case Some(v2) => Some(v1 - v2)            
        }
    }
    case MathExp.Mult(e1, e2)  => eval(e1) match {
        case None     => None
        case Some(v1) => eval(e2) match {
            case None     => None 
            case Some(v2) => Some(v1 * v2)            
        }
    }
    case MathExp.Div(e1, e2)   => eval(e1) match {
        case None     => None
        case Some(v1) => eval(e2) match {
            case None     => None 
            case Some(0)  => None
            case Some(v2) => Some(v1 / v2)            
        }
    }
    case MathExp.Const(i)      => Some(i)
}
```

When we execute `eval(Div(Const(1), Minus(Const(2), Const(2))))`, 
we get `None` as the result instead of the exception. One advantage of this is that whoever is using `eval` function has to respect that its return type is `Option[Int]` instead of just `Int` therefore, a `match` must be applied before using the result to look out for potential `None` value.

There are still two drawbacks. Firstly, the updated version of the `eval` function is much more verbose compared to the original *unsafe* version. We will address this issue in the next lesson. Secondly, we lose the chance of reporting where the division by zero has occured. Let's address the second issue.

We could instead of using `Option`, use the `Either` datatype

```scala
// no need to run this, it's builtin
enum Either[+A, +B] {
    case Left(v:A)
    case Right(v:B)
}
```

```scala
type ErrMsg = String

def eval(e: MathExp): Either[ErrMsg,Int] = e match {
    case MathExp.Plus(e1, e2) =>
        eval(e1) match {
            case Left(m) => Left(m)
            case Right(v1) =>
                eval(e2) match {
                    case Left(m) => Left(m)
                    case Right(v2) => Right(v1 + v2)
                }
        }
    case MathExp.Minus(e1, e2) =>
        eval(e1) match {
            case Left(m) => Left(m)
            case Right(v1) =>
                eval(e2) match {
                    case Left(m) => Left(m)
                    case Right(v2) => Right(v1 - v2)
                }
        }
    case MathExp.Mult(e1, e2) =>
        eval(e1) match {
            case Left(m) => Left(m)
            case Right(v1) =>
                eval(e2) match {
                    case Left(m) => Left(m)
                    case Right(v2) => Right(v1 * v2)
                }
        }
    case MathExp.Div(e1, e2) =>
        eval(e1) match {
            case Left(m) => Left(m)
            case Right(v1) =>
                eval(e2) match {
                    case Left(m) => Left(m)
                    case Right(0) =>
                        Left(s"div by zero caused by ${e.toString}")
                    case Right(v2) => Right(v1 / v2)
                }
        }
    case MathExp.Const(i) => Right(i)
}
```

Executing `eval(Div(Const(1), Minus(Const(2), Const(2))))` will yield 

```
Left(div by zero caused by Div(Const(1),Minus(Const(2),Const(2))))
```

## Summary

In this lesson, we have discussed 

* how to develop parametrically polymorphic Scala code using Generic, Algebraic Datatype
* how to safely mix parametric polymoprhism with adhoc polymoprhism (overloading) using type classes 
* how to develop generic programming style code using `Functor` type class.
* how to make use of `Option` and `Either` to handle and manipulate errors and exceptions. 


## Appendix

### Generalized Algebraic Data Type

Generalized Algebraic Data Type is an extension to Algebraic Data Type, in which each case extends a more specific version of the top level algebraic data type. Consider the following example.

Firstly, we need some type acrobatics to encode nature numbers on the level of type. 

```scala
enum Zero {
    case Zero
}
enum Succ[A] {
    case Succ(v:A)
}
```
Next we define our GADT `SList[S,A]` which is a generic list of elements `A` and with size `S`. 

```scala
enum SList[S,+A] {
    case Nil extends SList[Zero,Nothing] // additional type constraint S = Zero
    case Cons[N,A](hd:A, tl:SList[N,A]) extends SList[Succ[N],A]  // add'n type constraint S = Succ[N]
}
```
In the first subcase `Nil`, it is declared with the type of `SList[Zero, Nothing]` which indicates on type level that the list is empty. In the second case `Cons`, we define it to have the type `SList[Succ[N],A]` for some natural number `N`. This indicates on the type level that the list is non-empty. 

Having these information lifted to the type level allows us to define a type safe `head` function.

```scala
import SList.*

def head[A,N](sl:SList[Succ[N],A]):A = sl match {
    case Cons(hd, tl) => hd
}
```

Compiling `head(Nil)` yields a type error. 

Similarly we can define a size-aware function `snoc` which add an element at the tail of a list. 

```scala
def snoc[A,N](v:A, sl:SList[N,A]):SList[Succ[N],A] = sl match {
    case Nil => Cons(v,Nil)
    // case Cons(hd, tl) => snoc(v, tl) will result in compilation error.
    case Cons(hd, tl) => Cons(hd, snoc(v, tl))
}
```