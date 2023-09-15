# 50.054 - Instroduction to Scala

## Learning Outcomes

By the end of this class, you should be able to

* Develop simple implementation in Scala using List, Conditional, and Recursion
* Model problems and design solutions using Algebraic Datatype and Pattern Matching
* Compile and execute simple Scala programs

## What is Scala?

Scala is a hybrid programming language which combines Object Oriented Paradigm and Functional Programming Paradigm. Scala has many backends, including JVM, node.js and native.

Scala is widely used in the industry and the research communities. There many industry projects and open source projects were implemented mainly in Scala, e.g. Apache Spark, Kafka, Akka, Play! and etc.
For more details in how Scala is used in the real-world business, you may refer to the following for further readings.

* [Scala at Scale at Databricks](https://databricks.com/blog/2021/12/03/scala-at-scale-at-databricks.html?fbclid=IwAR01bOskVdPzhA902W2qXlP8MX4yV4iKqCbszT5gnOhko6yV6AKZHBGb09w)
* [Why Scala is seeing a renewed interest for developing enterprise software](https://www.forbes.com/sites/forbestechcouncil/2021/12/22/why-scala-is-seeing-a-renewed-interest-for-developing-enterprise-software/?sh=3c0ada4f6c1f)
* [Who is using Scala, Akka and Play framework](https://alvinalexander.com/scala/whos-using-scala-akka-play-framework/)
* [Type-safe Tensor](https://arxiv.org/pdf/1710.06892.pdf)

## Scala Hello World

Let's say we have a Scala file named `HelloWorld.scala`

```scala
println("hello world")
```

We can execute it via either

```bash
scala HelloWorld.scala
```

or to compile it then run

```bash
scalac HelloWorld.scala && scala HelloWorld
```

Although in the cohort problems, we are going to rely on a Scala project manager called `sbt` to build, execute and test our codes.

## Scala OOP vs Java OOP

If you know Object Oriented Programming, you already know 70% of Scala.

Consider the following Java code snippet

```java
interface FlyBehavior {
    void fly();
}

abstract class Bird {
    private String species;
    private FlyBehavior fb;
    public Bird(String species, FlyBehavior fb) {
        this.species = species;
        this.fb = fb;
    }
    public String getSpecies() { return this.species; }
    public void fly() { return this.fb.fly(); }
}

class Duck extends Bird {
    public Duck() {
        super("Duck", new FlyBehavior() {
            @override
            void fly() {
                System.out.println("I can't fly");
            }
        })
    }
}

class BlueJay extends Bird {
    public BlueJay() {
        super("BlueJay", new FlyBehavior() {
            @override
            void fly() {
                System.out.println("Swwooshh!");
            }
        })
    }
}
```

We define an abstract class `Bird` which has two member attributes, `species` and `fb`. We adopt the Strategy design pattern to delegate the fly behavior of the bird through an interface `FlyBehavior`.

Scala has the equivalence of language features as Java. The language has much concise syntax. In the following we implement the same logic in Scala.

```scala
trait FlyBehavior { 
    def fly()
}

abstract class Bird(species:String, fb:FlyBehavior) { 
    def getSpecies():String = this.species
    def fly():Unit = this.fb.fly()
}

class Duck extends Bird("Duck", new FlyBehavior() {
    override def fly() = println("I can't fly")
})

class BlueJay extends Bird("BlueJay", new FlyBehavior() {
    override def fly() = println("Swwooshh!")
})
```

In Scala, we prefer inline constructors. A `trait` is the Scala equivalent of Java's interface. Similar to Python, methods start with `def`. A method's return type comes after the method name declaration. Type annotations follow their  arguments instead of preceding them. Method bodies are defined after an equality sign. The `return` keyword is optional; the last expression will be returned as the result. The Java style of method body definition is also supported, i.e. the `getSpecies()` method can be defined as follows:

```scala
def getSpecies():String { return this.species }
```

Being a JVM language, Scala allows us to import and invoke Java libraries in Scala code.

```scala
import java.util.LinkedList
val l = new java.util.LinkedList[String]()
```

Keyword `val` defines an immutable variable, and `var` defines a mutable variable.

## Functional Programming in Scala at a glance

In this module, we focus and utilise mostly the functional programming feature of Scala.

|   | Lambda Calculus | Scala |
|---|---|---|
| Variable | $x$ | `x` |
| Constant | $c$ | `1`, `2`, `true`, `false` |
| Lambda abstraction| $\lambda x.t$  |  `(x:T) => e`  |
| Function application | $t_1\ t_2$  |  `e1(e2)`  |
| Conditional          | $if\ t_1\ then\ t_2\ else\ t_3$ | `if (e1) { e2 } else { e3 }` |
| Let Binding          | $let\ x = t_1\ in\ t_2$ | `val x = e1 ; e2` |

where `T` denotes a type and `:T` denotes a type annotation. `e`, `e1`, `e2` and `e3` denote expressions.

Similar to other mainstream languages, defining recursion in Scala is straight-forward, we just
make reference to the recursive function name in its body.

```scala
def fac(x:Int):Int = { 
    if (x == 0) { 1 } else { x*fac(x-1) }
}

val result = fac(10)
```

### Scala Strict and Lazy Evaluation

Let `f` be a non-terminating function
```scala
def f(x:Int):Int = f(x)
```
The following shows that the function application in Scala is using strict evaluation.
```scala
def g(x:Int):Int = 1
g(f(1)) // it does not terminate
```
On the other hand, the following code is terminating. 
```scala
def h(x: => Int):Int = 1
h(f(1)) // it terminates!
```
The type annotation `: => Int` after `x` states that the argument `x` is passed in by name (lazy evaluation), not by value (strict evaluation).

### List Data type

We consider a commonly used builtin data type in Scala, the list data type. In Scala, the following define some list values.

1. `Nil` - an empty list.
2. `List()` - an empty list.
3. `List(1,2)` - an integer list contains two values.
4. `List("a")` - an string list contains one value.
5. `1::List(2,3)` - prepends a value `1` to a list containing `2` and `3`.
6. `List("hello") ++ List("world")` - concatenating two string lists.

To iterate through the items in a list, we can use a for-loop:

```scala
def sum(l:List[Int]):Int = {
    var s = 0
    for (i <- l) {
        s = s+i
    }
    s
}
```

which is very similar to what we could implement in Java or Python.

However, we are more interested in using the functional programming features in Scala:

```scala
def sum(l:List[Int]):Int = {
    l match {
        case Nil => 0
        case (hd::tl) => hd + sum(tl)
    }
}
```

in which `l match {case Nil => 0; case (hd::tl) => hd+sum(tl) }` denotes a pattern-matching expression in Scala. It is similar to the switch statement found in other main stream languages, except that it has more *perks*.

In this expression, we pattern match the input list `l` against two list patterns, namely:

* `Nil` the empty list, and
* `(hd::tl)` the non-empty list

> Note that here `Nil` and `hd::tl` are not list values, because they are appearing after a `case` keyword and on the left of a thick arrow `=>`.

Pattern cases are visited from top to bottom (or left to right). In this example, we first check whether the input list `l` is an empty list. If it is empty, the sum of an empty list must be `0`. 

If the input list `l` is not an empty list, it must have at least one element. The pattern `(hd::tl)` extracts the first element of the list and binds it to a local variable `hd` and the remainder (which is the sub list formed by taking away the first element from `l`) is bound to `hd`. We often call `hd` as the head of the list and `tl` as the tail. We would like to remind that `hd` is storing a single integer in this case, and `tl` is capturing a list of integers.

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

```scala
def reverse(l:List[Int]):List[Int] = l match {
    case Nil => Nil
    case (hd::tl) => reverse(tl) ++ List(hd)
}
```

The function `reverse` takes a list of integers and generates a new list which is in the reverse order of the orginal one. We apply a similar strategy to break down the problem into two sub-problems via the `match` expression.

* When the input list `l` is an empty list, we return an empty list. The reverse of an empty list is an empty list
* When the input `l` is not empty, we make use of the pattern `(hd::tl)` to extract the head and the tail of the list

We apply `reverse` recursively to the tail and then concatenate it with a list containing the head.

You may notice that the same `reverse` function can be applied to lists of any element type, and not just integers, as long as all elements in a list share the same type. Therefore, we can rewrite the `reverse` function into a generic version as follows:

```scala
def reverse[A](l:List[A]):List[A] = l match {
    case Nil => Nil
    case (hd::tl) => reverse(tl) ++ List(hd)
}
```

Note that the first `[A]` denotes a type argument, with which we specify that the element type of the list is `A` (any possible type). The type argument is resolved when we apply `reverse` to a actual argument. For instance in `reverse(List(1,2,3))` the Scala compiler will resolve `A=Int` and in `reverse(List("a","b"))` it will resolve `A=String`.

#### A Note on Recursion

Note that recursive calls to `reverse` will incur additional memory space in the machine in form of additional function call frames on the call stack.

A call stack frame has to created to "save" the state of function execution such as local variables. As nested recursive calls are being built up, the machine might run out of memory. This is also known as Stack Overflow Error.

While simple recursions that make a few tens of or hundreds of nested calls won't harm a lot, we need to rethink when we note that a recursion is going to be executed for a large number of iterations. One way to address this issue is to rewrite non-tail recursion into tail-recursion.

A tail-recursion is a recursive function in which the recursive call occurs at the last instruction. 

For instance, the `reverse()` function presented earlier is not. The following variant is a tail recursion

```scala
def reverse[A](l:List[A]):List[A] = {
    def go(i:List[A], o:List[A]) : List[A] = i match {
        case Nil => o
        case (x::xs) => go(xs, x::o)
    }
    go(l,Nil)
}
```

In the above definition, we rely on a inner function `go` which is a recursive function. In `go`, the recursion take places at the last instruction in the `(x::xs)` case. The trick is to
pass around an accumulated output `o` in each recursive call.

Some compilers such as GHC can detect a tail recursive function, but it will not rewrite into a form which no stack is required. 

As compiler technology evolves, many modern FP language compilers are able to detect a subset of non-tail recursions and automatically transform them into the tail recursive version. 

However Scala does not automatically re-write a non-tail recursion into a tail recursion. Instead it offers a check:

```scala
import scala.annotation.tailrec

def reverse[A](l:List[A]):List[A] = {
    @tailrec
    def go(i:List[A], o:List[A]) : List[A] = i match {
        case Nil => o
        case (x::xs) => go(xs, x::o)
    }
    go(l,Nil)
}
```

The annotation `tailrec` is to hint to the Scala compiler that `go` should be compiled in a way that no stack frame should be created. If the compiler fails to do that, it will complain. In the absence of the `tailrec` annotation, the compiler will still try to optimize the tail recursion. 

If we apply the `tailrec` annotation to a non-tail recursive function, Scala will complain.

```scala
@tailrec
def reverse[A](l:List[A]):List[A] = l match {
    case Nil => Nil
    case (hd::tl) => reverse(tl) ++ List(hd)
}
```

The following error is reported:
```scala
-- Error: ----------------------------------------------------------------------
4 |    case (hd::tl) => reverse(tl) ++ List(hd)
  |                     ^^^^^^^^^^^
  |                 Cannot rewrite recursive call: it is not in tail position
1 error found
```

### Map, Fold and Filter

Consider the following function

```scala
def addToEach(x:Int, l:List[Int]):List[Int] = l match {
    case Nil => Nil
    case (y::ys) => {
        val yx = y+x
        yx::addToEach(x,ys)
    }
}
```

It takes two inputs, an integer `x` and an integer list `l`, and adds `x` to every element in `l` and put the results in the output list.

For instance `addToEach(1, List(1,2,3))` yields `List(2,3,4)`.

The above can rewritten by using a generic library method shipped with Scala.

```scala
def addToEach(x:Int, l:List[Int]):List[Int] = l.map(y=>y+x)
```

The method `map` is a method of the list class that takes an function as input argument and applies it to all elements in the list object.

Note that the above is same as

```scala
def addToEach(x:Int, l:List[Int]):List[Int] = {
    def addX(y:Int):Int = y+x
    l.map(addX)
}
```

We can observe that the input list and the output list of the `map` method must be of the same type and have the same length.

Recall in the `sum` function introduced in the earlier section. It takes a list of integers and "collapses" them into one number by summation. We can rewrite it using a fold function.

```scala
def sum(l:List[Int]):Int = l.foldLeft(0)((acc,x)=> acc+x)
```

The `foldLeft` method takes a base accumulator, and a binary function as inputs, and aggregates the elements from the list using the binary function.  In particular, the binary aggreation function assumes the first argument is the accumulator.

Besides `foldLeft`, there exists a `foldRight` method, in which the binary aggregation function expects the second argument is the accumulator.

```scala
def sum(l:List[Int]):Int = l.foldRight(0)((x,acc)=> x+acc)
```

So what is the difference between `foldLeft` and `foldRight`?  What happen if you run the following? Can you explain the difference?

```scala
val l = List("a","better","world", "by", "design")
l.foldLeft("")((acc,x) => (acc+" "+x)) 
l.foldRight("")((x,acc) => (x+" "+acc))
```

Note that `+` is an overloaded operator. In the above it concatenates two string values.

Intuitively, `l.foldLeft("")((acc,x) => (acc+" "+x))` aggregates the list of words using the aggregation function by nesting the recursive calls to the left.

```scala
((((""+" "+"a")+" "+"better")+" "+"world")+" "+"by")+" "+"design"
```

where `l.foldRight("")((x,acc) => (x+" "+acc))` aggregates the list of words by nesting the recursive calls to the right.

```scala
"a"+" "+("better"+" "+("world"+" "+("by"+" "+("design"+" "+""))))
```

The method `filter` takes a boolean test function and applies it to the elements in the list, keeping those whose test result is true and dropping those whose result is false.

```scala
val l = List(1,2,3,4)
def even(x:Int):Boolean = x%2==0
l.filter(even)
```

returns `List(2,4)`.

```scala
val l = List('a','1','0','d')
l.filter((c:Char) => c.isDigit)
```

returns `List('1','0')`.

With `map`, `foldLeft` and `filter`, we can express the implementation of algorithms in a concise and elegant way. For instance, the following function implements the quicksort algorithm:

```scala
def qsort(l:List[Int]):List[Int] = l match {
    case Nil => Nil
    case List(x) => List(x)
    case (p::rest) => {
        val ltp = rest.filter( x => x < p)
        val gep = rest.filter( x => !(x < p))
        qsort(ltp) ++ List(p) ++ qsort(gep)
    }
}
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

### flatMap and for-comprehension

There is a variant of `map` method, consider

```scala
val l = (1 to 5).toList
l.map( i => if (i%2 ==0) { List(i) } else { Nil })
```

would yield

```scala
List(List(), List(2), List(), List(4), List())
```

We would like to get rid of the nested lists and flatten the outer list. 

One possibility is to:

```scala
l.flatMap( i => if (i%2 ==0) { List(i) } else { Nil })
```

Like `map`, `flatMap` applies its parameter function  to every element in the list. Unlike `map`, `flatMap` expects the parameter function produces a list, thus
it will join all the sub-lists into one list.

With `map` and `flatMap`, we can define complex list transformation operations like the following:

```scala
def listProd[A,B](la:List[A], lb:List[B]):List[(A,B)] = 
    la.flatMap( a => lb.map(b => (a,b)))

val l2 = List('a', 'b', 'c')
listProd(l, l2)
```

which produces:

```scala
List((1,a), (1,b), (1,c), (2,a), (2,b), (2,c), (3,a), (3,b), (3,c), (4,a), (4,b), (4,c), (5,a), (5,b), (5,c))
```

Note that Scala supports list comprehension via the `for ... yield` construct. We could re-express `listProd` as follows:

```scala
def listProd2[A,B](la:List[A], lb:List[B]):List[(A,B)] = 
    for {
        a <- la
        b <- lb
    } yield (a,b)
```

The Scala compiler desugars:

```scala
for { x1 <- e1;  x2 <- e2; ...; xn <- en } yield e
````
into:

```scala
e1.flatMap( x1 => e2.flatMap(x2 =>  .... en.map( xn => e) ...))
```

The above syntactic sugar not only works for the list data type but any data type with `flatMap` and `map` defined (as we will see in the upcoming lessons).

In its general form, we refer to it as *for-comprehension*.
One extra note to take is that the for-comprehension should not be confused with the for-loop statement exists in the imperative style programming in Scala.

```scala
var sum = 0
for (i <- 1 to 10)
{sum = sum + i}
println(sum)
```

### The Algebraic Datatype

Like many other languages, Scala supports user defined data type.
From an earlier section, we have discussed how to use classes and traits in Scala to define data types, making using of the OOP concepts that we have learned.

This style of defining data types using abstraction and encapsulation is also known as the abstract datatype.

In this section, we consider an alternative, the Algebraic Datatype.

Consider the following EBNF of a math expression.

$$
\begin{array}{rccl}
{\tt (Math Exp)} & e & ::= & e + e \mid e - e \mid  e * e \mid e / e \mid c \\
{\tt (Constant)} & c & ::= & ... \mid -1 \mid 0 \mid 1 \mid ...
\end{array}
$$

And we would like to implement a function `eval()` which evaluates a ${\tt (Math Exp)}$ to a value.

If we were to implement the above with OOP, we would probably use inheritance to extend subclasses of ${\tt (Math Exp)}$, and use if-else statements with `instanceof` to check for a specific subclass instance. Alternative, we can also rely on visitor pattern or delegation.

It turns out that using Abstract Datatypes to model the above result in some engineering overhead.

* Firstly, encapsulation and abstract tend to hide the underlying structure of the given object (in this case, the ${\tt Math Exp})$ terms)
* Secondly, using inheritance to model the sum of data types is not perfect (Note: the "sum" here refers to having a fixed set of alternatives of a datatype, not the summation for numerical values)
  * For instance, there is no way to stop users of the library code from extending new instances of ${\tt (MathExp)}$

The algebraic datatype is an answer to these issues. In essence, it is a type of data structure that consists of products and sums.

In Scala 3, it is recommended to use `enum` for Algebraic datatypes.

```scala
enum MathExp:
    case Plus(e1:MathExp, e2:MathExp)
    case Minus(e1:MathExp, e2:MathExp)
    case Mult(e1:MathExp, e2:MathExp)
    case Div(e1:MathExp, e2:MathExp)
    case Const(v:Int)
end MathExp
```

In the above the `MathExp` (`enum`) datatype, there are exactly 5 alternatives. Let's take at look at one case, for instance `Plus(e1:MathExp, e2:MathExp)`, which states that a plus expression has two operands, both of which are of type `MathExp`.

Note that the `end MathExp` is optional, as long as there is an extra line.
Alternatively, we can use `{ }`.

```scala
enum MathExp {
    case Plus(e1:MathExp, e2:MathExp)
    case Minus(e1:MathExp, e2:MathExp)
    case Mult(e1:MathExp, e2:MathExp)
    case Div(e1:MathExp, e2:MathExp)
    case Const(v:Int)
}
```

We can represent the math expression `(1+2) * 3` as
`MathExp.Mult(MathExp.Plus(MathExp.Const(1), MathExp.Const(2)), MathExp.Const(3))`.  Note that we call `Plus(_,_)` , `Minus(_,_)`, `Mult(_,_)`, `Div(_,_)` and `Const(_)` "data constructors", as we use them to construct values of the `enum` algebraic datatype `MathExp`.

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

```scala
def eval(e:MathExp):Int = e match {
    case MathExp.Plus(e1, e2)  => eval(e1) + eval(e2)
    case MathExp.Minus(e1, e2) => eval(e1) - eval(e2)
    case MathExp.Mult(e1, e2)  => eval(e1) * eval(e2)
    case MathExp.Div(e1, e2)   => eval(e1) / eval(e2)
    case MathExp.Const(i)      => i
}
```

In Scala, the `enum`` Algebraic datatype can be accessed (destructured) via pattern matching.

If we run:

```scala
eval(MathExp.Mult(MathExp.Plus(MathExp.Const(1), MathExp.Const(2)), MathExp.Const(3)))
```

we get `9` as result.

Let's consider another example where we can implement some real-world data structures using the algebraic datatype.

Suppose for experimental purposes, we would like to re-implement the list datatype in Scala (even though a builtin one already exists). For simplicity, let's consider a monomorphic version (no generic) version. 

> We will look into the generic version in the next lesson

In the following we consider the specification of the `MyList` data type in EBNF:

$$
\begin{array}{rccl}
{\tt (MyList)} & l & ::= & Nil \mid Cons(i,l) \\
{\tt (Int)} & i & ::= & 1 \mid 2 \mid   ...
\end{array}
$$

And we implement using `enum` in Scala:

```scala
enum MyList {
    case Nil
    case Cons(x:Int, xs:MyList)
}
```

Next we implement the `map` function based on the following specification

$$
map(f, l) = \left [ \begin{array}{ll}
            Nil & if\ l = Nil\\
            Cons(f(hd), map(f, tl)) & if\ l = Cons(hd, tl)
            \end{array} \right .
$$

Then we could implement the map function

```scala
def mapML(f:Int=>Int, l:MyList):MyList = l match {
    case MyList.Nil => MyList.Nil
    case MyList.Cons(hd, tl) => MyList.Cons(f(hd), mapML(f,tl))
}
```

Running `mapML(x => x+1, MyList.Cons(1,MyList.Nil))` yields
`MyList.Cons(2,MyList.Nil)`.

But hang on a second! The `map` method from the Scala built-in list is a method of a list object, not a stand-alone function.

In Scala 3, `enum` allows us to package the method inside `enum` values.

```scala
enum MyList {
    case Nil
    case Cons(x:Int, xs:MyList)
    def mapML(f:Int=>Int):MyList = this match {
        case MyList.Nil => MyList.Nil
        case MyList.Cons(hd, tl) => MyList.Cons(f(hd), tl.mapML(f))
    }
}
```

Running:

```scala
val l = MyList.Cons(1, MyList.Nil)
l.mapML(x=> x+1)
```

yields the same output as above.

## Summary

In this lesson, we have discussed

* Scala's OOP vs Java's OOP
* Scala's FP vs Lambda Calculus
* How to use the `List` datatype to model and manipulate collections of multiple values.
* How to use the Algebraic data type to define user customized data type to solve complex problems.
