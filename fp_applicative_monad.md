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
class 

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
    (<$>) :: t (a -> b) -> t a -> t b
```

Note that we "fix" the `map` for `Applicative` in the type class level in this case. (i.e. we are following the first approach.)

```haskell
given listApplicative:Applicative[List] = new Applicative[List] {
    def pure[A](a:A):List[A] = List(a) 
    def ap[A, B](ff: List[A => B])(fa: List[A]):List[B] = 
        ff.map( f => fa.map(f)).flatten
}
```

Recall that ```flatten``` flattens a list of lists.

Alternatively, we can define the `ap` method of the `Applicative[List]` instance `flatMap`. Given `l` is a list,
`l.flatMap(f)` is the same as `l.map(f).flatten`.

```haskell
    def ap[A, B](ff: List[A => B])(fa: List[A]):List[B] = 
        ff.flatMap( f => fa.map(f))
```

Recall that haskell compiler desugars expression of shape

```haskell
e1.flatMap( v1 => e2.flatMap( v2 => ... en.map(vn => e ... )))
```

into

```haskell
for {
    v1 <- e1
    v2 <- e2
    ...
    vn <- en
} yield (e)
```

Hence we can rewrite the `ap` method of the `Applicative[List]` instance as

```haskell
    def ap[A, B](ff: List[A => B])(fa: List[A]):List[B] = 
        for {
            f <- ff
            a <- fa 
        } yield (f(a))
```

It is not suprising the following produces the same results as the functor instance.

```haskell
listApplicative.map(l)((x:Int) => x + 1)
```

What about `pure` and `ap`? when can we use them?

Let's consider the following contrived example. Suppose we would like to apply two sets of operations to elements from `l`, each operation will produce its own set of results, and the inputs do not depend on the output of the other set. i.e. If the two set of operations, are `(x:Int)=> x+1` and `(y:Int)=>y*2`.

```haskell
val intOps= List((x:Int)=>x+1, (y:Int)=>y*2)
listApplicative.ap(intOps)(l)
```

we get

```haskell
List(2, 3, 4, 2, 4, 6)
```

as the result.

Let's consider another example. Recall that `Option[A]` algebraic datatype which captures a value of type `A` could be potentially empty.

We define the `Applicative[Option]` instance as follows

```haskell
given optApplicative:Applicative[Option] = new Applicative[Option] {
    def pure[A](v:A):Option[A] = Some(v)
    def ap[A,B](ff:Option[A=>B])(fa:Option[A]):Option[B]  = ff match {
        case None => None
        case Some(f) => fa match {
            case None => None
            case Some(a) => Some(f(a))
        }
    }
}
```

In the above Applicative instance, the `ap` method takes a optional operation and optional value as inputs, tries to apply the operation to the value when both of them are present, otherwise, signal an error by returning `None`. This allows us to focus on the high-level function-value-input-output relation and abstract away the details of handling potential absence of function or value.

Recall the builtin `Option` type is defined as follows,

```haskell
// no need to run this.
enum Option[+A] {
    case None
    case Some(v)
    def map[B](f:A=>B):Option[B] = this match {
        case None => None 
        case Some(v) => Some(f(v))
    }
    def flatMap[B](f:A=>Option[B]):Option[B] = this match {
        case None => None 
        case Some(v) => f(v) match {
            case None => None 
            case Some(u) => Some(u) 
        }
    }
}
```

Hence `optApplicative` can be simplified as 

```haskell
given optApplicative:Applicative[Option] = new Applicative[Option] {
    def pure[A](v:A):Option[A] = Some(v)
    def ap[A,B](ff:Option[A=>B])(fa:Option[A]):Option[B] = 
        ff.flatMap(f => fa.map(f)) // same as listApplicative
}
```

or 
```haskell
given optApplicative:Applicative[Option] = new Applicative[Option] {
    def pure[A](v:A):Option[A] = Some(v)
    def ap[A,B](ff:Option[A=>B])(fa:Option[A]):Option[B] = for 
    {
        f <- ff
        a <- fa
    } yield f(a) // same as listApplicative
}
```

### Applicative Laws

Like Functor laws, every Applicative instance must follow the Applicative laws to remain computationally predictable.

1. Identity: `ap(pure(x=>x))` $\equiv$ `x=>x`
2. Homomorphism: `ap(pure(f))(pure(x))` $\equiv$ `pure(f(x))`
3. Interchange: `ap(u)(pure(y))` $\equiv$ `ap(pure(f=>f(y)))(u)`
4. Composition: `ap(ap(ap(pure(f=>f.compose))(u))(v))(w)` $\equiv$ `ap(u)(ap(v)(w))`

* Identity law states that applying a lifted identity function of type `A=>A` is same as an identity function of type `F[A] => F[A]` where `F` is the applicative functor.
* Homomorphism says that applying a lifted function (which has type `A=>A` before being lifted) to a lifted value, is equivalent to applying the unlifted function to the unlifted value directly and then lift the result.
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

```haskell

enum MathExp {
    case Plus(e1:MathExp, e2:MathExp)
    case Minus(e1:MathExp, e2:MathExp)
    case Mult(e1:MathExp, e2:MathExp)
    case Div(e1:MathExp, e2:MathExp)
    case Const(v:Int)
}

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

In which we use `Option[A]` to capture the potential div-by-zero error.
One issue with the above is that it is very verbose, we lose some readability of the code thus, it takes us a while to migrate to `Either[A,B]` if we want to have better error messages. Monad is a good application here.

Let's consider the type class definition of `Monad[F[_]]`.

```haskell
trait Monad[F[_]] extends Applicative[F] {
    def bind[A,B](fa:F[A])(f:A => F[B]):F[B]
    def pure[A](v:A):F[A]
    def ap[A, B](ff: F[A => B])(fa: F[A]): F[B] = 
        bind(ff)((f:A=>B) => bind(fa)((a:A)=> pure(f(a))))
}

given optMonad:Monad[Option] = new Monad[Option] {
    def bind[A,B](fa:Option[A])(f:A=>Option[B]):Option[B] = fa match {
        case None => None
        case Some(a) => f(a)
    }
    def pure[A](v:A):Option[A] = Some(v)
}
```

The `eval` function can be re-expressed using `Monad[Option]`.

```haskell
def eval(e:MathExp)(using m:Monad[Option]):Option[Int] = e match {
    case MathExp.Plus(e1, e2)  => 
        m.bind(eval(e1))( v1 => {
            m.bind(eval(e2))( {v2 => m.pure(v1+v2)})
        })        
    case MathExp.Minus(e1, e2) =>         
        m.bind(eval(e1))( v1 => {
            m.bind(eval(e2))( {v2 => m.pure(v1-v2)})
        }) 
    case MathExp.Mult(e1, e2)  =>
        m.bind(eval(e1))( v1 => {
            m.bind(eval(e2))( {v2 => m.pure(v1*v2)})
        }) 
    case MathExp.Div(e1, e2)   => 
        m.bind(eval(e1))( v1 => {
            m.bind(eval(e2))( {v2 => if (v2 == 0) {None} else {m.pure(v1/v2)}})
        }) 
    case MathExp.Const(i)      => m.pure(i)
}
```

It certainly reduces the level of verbosity, but the readability is worsened.
Thankfully, we can make use of for comprehension since `Option` has the member functions `flatMap` and `map` defined.

Recall that haskell desugars `for {...} yield` expression into `flatMap` and `map`.

Thus the above can be rewritten as

```haskell
def eval(e:MathExp)(using m:Monad[Option]):Option[Int] = e match {
    case MathExp.Plus(e1, e2)  => for {
        v1 <- eval(e1)
        v2 <- eval(e2)
    } yield (v1+v2) 
    case MathExp.Minus(e1, e2) => for {
        v1 <- eval(e1)
        v2 <- eval(e2)
    } yield (v1-v2) 
    case MathExp.Mult(e1, e2)  => for {
        v1 <- eval(e1)
        v2 <- eval(e2)
    } yield (v1*v2) 
    case MathExp.Div(e1, e2)   => for {
        v1 <- eval(e1)
        v2 <- eval(e2)
        if (v2 !=0)
    } yield (v1/v2) 
    case MathExp.Const(i)      => m.pure(i)
}
```

Now the readability is restored.

Another advantage of coding with `Monad` is that its abstraction allows us to switch underlying data structure without major code change.

Suppose we would like to use `Either[String, A]` or some other equivalent as return type of `eval` function to support better error message. But before that, let's consider some subclasses of the `Applicative` and the `Monad` type classes.

```haskell
trait ApplicativeError[F[_], E] extends Applicative[F] {
    def raiseError[A](e:E):F[A]
}

trait MonadError[F[_], E] extends Monad[F] with ApplicativeError[F, E] {
    override def raiseError[A](e:E):F[A]
}   

type ErrMsg = String
```

In the above, we define an extension to the `Applicative` type class, named `ApplicativeError` which expects an extra type class parameter `E` that denotes an error. The `raiseError` method takes a value of type `E` and returns the Applicative result.

Similarly, we extend `Monad` type class with `MonadError` type class. Next we include the following type class instance to include `Option` as one f the `MonadError` functor.

```haskell
given optMonadError:MonadError[Option, ErrMsg] = new MonadError[Option, ErrMsg] {
    def raiseError[A](e:ErrMsg):Option[A] = None
    def bind[A,B](fa:Option[A])(f:A=>Option[B]):Option[B] = fa match {
        case None => None
        case Some(a) => f(a)
    }
    def pure[A](v:A):Option[A] = Some(v)
}
```

Next, we adjust the `eval` function to takes in a `MonadError` context instead of a `Monad` context. In addition, we make the error signal more explicit by calling the `raiseError()` method from the `MonadError` type class context.

```haskell
def eval2(e:MathExp)(using m:MonadError[Option, ErrMsg]):Option[Int] = e match {
    case MathExp.Plus(e1, e2)  => for {
        v1 <- eval2(e1)
        v2 <- eval2(e2)
    } yield (v1+v2) 
    case MathExp.Minus(e1, e2) => for {
        v1 <- eval2(e1)
        v2 <- eval2(e2)
    } yield (v1-v2) 
    case MathExp.Mult(e1, e2)  => for {
        v1 <- eval2(e1)
        v2 <- eval2(e2)
    } yield (v1*v2) 
    case MathExp.Div(e1, e2)   => for {
        v1 <- eval2(e1)
        v2 <- eval2(e2)
        _  <- if (v2 ==0) {m.raiseError("div by zero encountered.")} else { m.pure(())}
    } yield (v1/v2) 
    case MathExp.Const(i)      => m.pure(i)
}
```

Now let's try to refactor the code to make use of `Either[ErrMsg, A]` as the functor instead of `Option[A]`.

```haskell
enum Either[+A, +B] {
    case Left(v: A)
    case Right(v: B)
    // to support for comprehension
    def flatMap[C>:A,D](f: B => Either[C,D]):Either[C,D] = this match {
        case Left(a) => Left(a)
        case Right(b) => f(b)
    }
    def map[D](f:B => D):Either[A,D] = this match {
        case Right(b) => Right(f(b))
        case Left(e) => Left(e)
    }
} 
```

In the above, we have to define `flatMap` and `map` member functions for `Either` type so that we could make
use of the for comprehension later on. One might argue with the type signature of `flatMap` should be
`flatMap[D](f: B => Either[A,D]):Either[A,D]`. The issue here is that the type variable `A` will appear in both co- and contra-variant positions.  The top-level annotation `+A` is no longer true. Hence we "relax" the type constraint here by introducing a new type variable `C` which has a lower bound of `A` (even though we do not need to upcast the result of the Left alternative.)

```haskell
type EitherErr = [B] =>> Either[ErrMsg,B]
```

In the above we define `Either` algebraic datatype and the type construcor `EitherErr`. `[B] =>> Either[ErrMsg, B]` denotes a type lambda, which means that `EitherErr` is a type constructor (or type function) that takes a type `B` and return an `Either[ErrMsg, B]` type.

Next, we define the type class instance for `MonadError[EitherErr, ErrMsg]`

```haskell
given eitherErrMonad: MonadError[EitherErr, ErrMsg] =
    new MonadError[EitherErr, ErrMsg] {
        import Either.*
        def raiseError[B](e: ErrMsg): EitherErr[B] = Left(e)
        def bind[A, B](
            fa: EitherErr[A]
        )(f: A => EitherErr[B]): EitherErr[B] = fa match {
            case Right(b) => f(b)
            case Left(s)  => Left(s)
        }
        def pure[B](v: B): EitherErr[B] = Right(v)
    }
```

And finally, we refactor the `eval` function by changing its type signature. And its body remains unchanged.

```haskell
def eval3(e:MathExp)(using m:MonadError[EitherErr, ErrMsg]):EitherErr[Int] = e match {
    case MathExp.Plus(e1, e2)  => for {
        v1 <- eval3(e1)
        v2 <- eval3(e2)
    } yield (v1+v2) 
    case MathExp.Minus(e1, e2) => for {
        v1 <- eval3(e1)
        v2 <- eval3(e2)
    } yield (v1-v2) 
    case MathExp.Mult(e1, e2)  => for {
        v1 <- eval3(e1)
        v2 <- eval3(e2)
    } yield (v1*v2) 
    case MathExp.Div(e1, e2)   => for {
        v1 <- eval3(e1)
        v2 <- eval3(e2)
        _  <- if (v2 ==0) {m.raiseError("div by zero encountered.")} else { m.pure(())}
    } yield (v1/v2) 
    case MathExp.Const(i)      => m.pure(i)
}
```

## Commonly used Monads

We have seen the option Monad and the either Monad. Let's consider a few commonly used Monads.

### List Monad

We know that `List` is a Functor and an Applicative.
It is not surprising that `List` is also a Monad.

```haskell
given listMonad:Monad[List] = new Monad[List] {
    def pure[A](v:A):List[A] = List(v)
    def bind[A,B](fa:List[A])(f:A => List[B]):List[B] = 
        fa.flatMap(f)
}
```

With the above instance, we can write list processing method in for comprehension which is similar to query languages.

```haskell
import java.util.Date
import java.util.Calendar
import java.util.GregorianCalendar
import java.text.SimpleDateFormat
case class Staff(id:Int, dob:Date)

def mkStaff(id:Int, dobStr:String):Staff = {
    val sdf = new SimpleDateFormat("yyyy-MM-dd")
    val dobDate = sdf.parse(dobStr)
    Staff(id, dobDate)
}
val staffData = List(
    mkStaff(1, "1076-01-02"),
    mkStaff(2, "1986-07-24")
)

def ageBelow(staff:Staff, age:Int): Boolean = staff match {
    case Staff(id, dob) => {
        val today = new Date()
        val calendar = new GregorianCalendar();
        calendar.setTime(today)
        calendar.add(Calendar.YEAR, -age)
        val ageYearsAgo = calendar.getTime()
        dob.after(ageYearsAgo)
    }
}

def query(data:List[Staff]):List[Staff] = for {
    staff <- data          // from data 
    if ageBelow(staff, 40) // where staff.age < 40
} yield staff              // select *
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
