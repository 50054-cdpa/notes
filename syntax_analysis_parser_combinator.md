# 50.054 - Top-down recursive parsing using Parser Combinators

## Learning Outcome 

By the end of this class, you should be able to 

* Implement a top-down recursive parser with backtracking
* Implement a top-down recursive parser with on-demand backtracking 


## (Recap) Top-down parsing


In this secion we are going to focus on implementing Top-down parser.

Recall the grammar of a math expression. 

```
<<grammar 4>> 
E::= T + E
E::= T
T::= T * F 
T::= F
F::= i    
```


### Abstract Syntax Tree 
To implement top-down parsing, we first consider how to represent a parse tree in Haskell. 
It's natural to implement the parse trees in terms of some algebraic datatype. 
The Grammar 4 can be encoded with the following Haskell data type.

```hs
data Exp = TermExp Term | PlusExp Term Exp 
    deriving (Show, Eq) 

data Term = FactorTerm Factor | MultTerm Term Factor 
    deriving (Show, Eq)

data Factor = Factor Int
    deriving (Show, Eq)
```

### Left Recursion Elimination

Recall Grammar 4 defined above contains some left recursion. 

To eliminate the left recursion, we apply the same trick by rewriting left recursive grammar rules
$$
\begin{array}{rcl}
N & ::= & N\alpha_1 \\
& ... & \\
N & ::= & N\alpha_n \\
N & ::= & \beta_1 \\ 
& ... & \\
N & ::= & \beta_m 
\end{array}
$$

into

$$
\begin{array}{rcl}
N & ::= & \beta_1 N' \\
& ... & \\
N & ::= & \beta_m N' \\
N' & ::= & \alpha_1 N' \\ 
& ... & \\
N' & ::= & \alpha_n N' \\
N' & ::= & \epsilon
\end{array}
$$

Grammar 4 can be rewritten into

```
E  ::= T + E
E  ::= T
T  ::= FT'
T' ::= *FT'
T' ::= epsilon
F  ::=i
```

None of the production rules above contains common leading terminal symbols, hence there is no need to apply left-factorization.

Note that in the above Grammar 4 with left recursion eliminated, the only rules affected are thos with non-terminal `T`,

Hence we only need to added the following enum type

### Additional Abstract Syntax Tree


We could model it using Algebraic data type.
```hs
data TermLE = TermLE Factor TermLEP 

data TermLEP = MultTermLEP Factor TermLEP | Eps 
```

The main idea is when parsing a `Term`, instead of parsing directly, we parse a `TermLE` then convert it back to `Term`.


```hs
[IntTok 1, PlusTok, IntTok 2, AsterixTok, IntTok 3]
```
A parser method `parseExp` should generate

```hs
PlusExp (FactorTerm (Factor 1)) (TermExp (MultTerm (FactorTerm (Factor 2)) (Factor 3)))
```
where 

* sub term `IntTok 1` was first parsed as `TermLE (Factor 1) Eps` then converted to `FactorTerm (Factor 1)`, and 
* sub term `IntTok 2, AsterixTok, IntTok 3` was first parsed as `TermLE (Factor 2) (MultTerm (Factor 3) Eps)` and converted to `MultTerm (Factor 2) (Factor 3)`.



### Parser Combinator with Backtracking

We consider implementing the naive top-down recursive parser in Haskell. 
Let's start with the simplest cases. Let's say we would like to write a parsing function that takes a list of lexical tokens and "consumes" a token, then return the rest.

```hs
data Result a = Failed String | Ok a 

item :: [LToken] -> Result (LToken,[LToken])
item [] = Failed "item is called with an empty input"
item (t:ts) = Ok (t,ts)
```
We define a variant of the `Maybe` datatype, `Result` which is either a failure with an error message, or an "Ok" result. The `item` function is what we would like to implement. It returns the extracted leading token with the rest of input if the input is non-empty, and signals a failure otherwise. 

Apply the same idea we could define a conditional parsing function.

```hs
sat :: [LToken] -> (LToken -> Bool) -> Result (LToken,[LToken])
sat [] _ = Failed "sat is called with an empty input"
sat (t:ts) p = if p t
    then Ok (t,ts) 
    else Failed "sat is called with an input that does not satisfy the input predicate."
```

We may want to combine these basic parsing functions to form a larger parsing task, e.g.

```hs
aBitMoreComplexParser :: [LToken] -> Result (LToken,[LToken])
aBitMoreComplexParser toks = case item toks of 
    { Failed msg -> Failed msg 
    ; Ok (_, toks2) -> sat toks2 (\t -> case t of 
          { AsterixTok -> True
          ; _          -> False}) "Expecting an asterix."
    }
```


In the above, we define a parsing task which skips the first token and searches for the following asterix. We could imagine that to build a practical parser, we would need many of the basic parsing functions like `sat` and `item`, and combine them.

What we can observe from the above is that there are some similarity between `sat` and `item`, i.e. they both take in a list of tokens and returns the remaining tokens. If we view the lists of tokens as states, we could think of using the State Monad. We would also need this top-down parser to be able to backtrack in case of parsing failures. Recall the `MonadError` type class

```hs
class Monad m => MonadError e m | m -> e where
    throwError :: e -> m a 
    catchError :: m a -> (e -> m a) -> m a
```
We define the `Parser` data type as follows, similar to the `State` case data type in the State Monad, except that we replace the `state` by the (parametric) parser environment type `env` 

```hs
type Error = String 

data Result a = Ok a
    | Failed String
    deriving (Show, Eq)

newtype Parser env a =
    Parser { run :: env -> Result (a, env) }
```
> `newtype` is like a special `data` type definition where there is no alternative.

Next we provide the required type class instances to make `Parser env` into a `MonadError` instance. 

```hs
instance Functor (Parser env) where
    fmap f (Parser ea) = Parser ( \env -> case ea env of
    { Failed err -> Failed err
    ; Ok (a, env1) -> Ok (f a, env1)
    })


instance Applicative (Parser env) where
    pure a = Parser (\env -> Ok (a, env))
    (Parser eab) <*> (Parser ea) = Parser (\env -> case eab env of
        { Failed msg -> Failed msg
        ; Ok (f, env1) -> case ea env1  of
            { Failed msg -> Failed msg
            ; Ok (a, env2) -> Ok (f a, env2)
            }
        })

instance Monad (Parser env) where
    (Parser ea) >>= f = Parser (\env -> case ea env of
        { Failed err   -> Failed err
        ; Ok (a, env1) -> case f a of
            { Parser eb -> eb env1 }
        })

instance MonadError Error (Parser env) where
    throwError msg = Parser (\env ->  Failed msg)
    catchError (Parser ea) handle = Parser (\env -> case ea env of
        { Failed msg -> case handle msg of
            { Parser ea2 -> ea2 env }
        ; Ok v ->  Ok v
        })
```

With the Monad instance in-place, let's consider the "requirements" of the parser environment type `env`. We use the following type class to constraint any implementation of the parser environment must fulfill these requirements. 

```hs
class ParserEnv env tok | env -> tok
    where
        getTokens :: env -> [tok]
        getLine :: env -> Int
        getCol :: env -> Int
        setTokens :: [tok] -> env -> env
        setLine :: Int -> env -> env
        setCol :: Int -> env -> env
        isNextTokNewLine :: env -> Bool
```

Now we can re-define the `item` and `sat` function by making use of the monad (error) abstraction. 

```hs
-- | The `item` combinator unconditionally parse the leading token. 
item :: ParserEnv env tok => Parser env tok
item = Parser (\env ->
    let toks = getTokens env
        ln   = getLine env
        col  = getCol env
    in case toks of
        { [] -> Failed "item is called with an empty token stream."
        ; (c : cs) | isNextTokNewLine env ->
            let env1 = setLine (ln+1) env
                env2 = setCol 1 env1
                env3 = setTokens cs env2
            in Ok (c, env3)
                   | otherwise ->
            let env1 = setCol (col+1) env
                env2 = setTokens cs env1
            in Ok (c, env2)
        })

-- | The `sat` combinator consume the leading token if it satifies the predicate `p`.
sat :: ParserEnv env tok => (tok -> Bool) -> Error -> Parser env tok
sat p dbgMsg = Parser (\env ->
    let toks = getTokens env
        ln   = getLine env
        col  = getCol env
    in case toks of
        { [] -> Failed ("sat is called with an empty token stream at line " ++ show ln ++ ", col " ++ show col ++ ". " ++ dbgMsg)
        ; (c:cs) | p c && isNextTokNewLine env ->
            let env1 = setLine (ln+1) env
                env2 = setCol 1 env1
                env3 = setTokens cs env2
            in Ok (c, env3)
        ; (c:cs) | p c ->
            let env1 = setCol (col+1) env
                env2 = setTokens cs env1
            in Ok (c, env2)
        ; (c:cs) -> Failed ("sat is called with an unsatisfied predicate at line " ++ show ln ++ ", col " ++ show col ++ ". " ++ dbgMsg)
        }
    )
```

The `| condExp` defines a pattern guard in Haskell. For instance, in the `item` function above, the pattern case `(c : cs) | isNextTokNewLine env` is triggered 
when the incoming tokens `toks` are of shape `c:cs` and the `isNextTokenNewLine env` is `True`. Compared to the naive version of `item` defined earlier, this version abstracts away the details of the tokens retrieval and update. It also handles the book-keeping of the current token position in the source file. Like-wise `sat` function is updated to support the same features. 


More importantly, we could define more generic and useful combinators

```hs
choice :: Parser env a -> Parser env a -> Parser env a
choice p q = catchError p (\e -> q)
```

The `choice` combinator takes two parsers `p` and `q`. It tries to run `p`. In case `p` fails, it backtracks (by restoring the original state) and runs `q`. 


Now we can make use of `choice` to define an `optional` combinator
```hs
optional :: Parser env a -> Parser env (Either () a)
optional pa =
    let p1 = Right <$> pa
        p2 = return (Left ())
    in choice p1 p2
```

`optional` takes a parser `pa` and tries to execute it with the current input. If it fails, it restores the original state and returns `()`.


Let's try to write a parser for the simple arithmetic expression 

Recall the nice property of a top-down parser is that the parser is correspondent to the top-down traversal of the production rules.

We provide the concrete definition of the parser environment data type as follows,

```hs
data PEnv = PEnv { toks:: [LToken]} deriving (Show, Eq) 

instance ParserEnv PEnv LToken where
    getCol penv           = -1 -- ^ not in used. 
    getLine penv          = -1 -- ^ not in used. 
    setTokens ts penv     = penv{toks= ts}
    setLine _ penv        = penv -- ^ not in used.
    setCol _ penv         = penv -- ^ not in used. 
    isNextTokNewLine penv = False -- ^ not in used. 
    getTokens             = toks   
```

Recall the grammar 4 of Math expression with left recursion.

```
E::= T + E
E::= T
T::= T * F 
T::= F
F::= i    
```


```scala
def parseExp:Parser[LToken, Exp] = 
    choice(parsePlusExp)(parseTermExp)

def parsePlusExp:Parser[LToken, Exp] = for {
    t <- parseTerm
    plus <- parsePlusTok
    e <- parseExp
} yield PlusExp(t, e)

def parseTermExp:Parser[LToken, Exp] = for {
    t <- parseTerm
} yield TermExp(t)
```

Up to this point we are ok as production rules with `E` on the LHS are not left recursive.
It gets tricky when paarsing `T` which contains left recursion. Recall the modified grammar of 
`T` having left-recursion eliminated.

```
T  ::= FT'  
T' ::= *FT'
T' ::= epsilon
```

In terms of Scala enum type, we refer to them as `TermLE` and `TermLEP`.
Hence the parser `parserTerm` has to be defined in terms of `parseTermLE`, then 
convert the result of `TermLE` back to `Term`

```hs
parseTerm :: Parser PEnv Term 
parseTerm = do 
    tle <- parseTermLE 
    return (fromTermLE tle) 
```

Where `parseTermLE` can be implemented using parsec, 

```hs
parseTermLE :: Parser PEnv TermLE 
parseTermLE = do 
    f  <- parseFactor
    tp <- parseTermP 
    return (TermLE f tp)

parseTermP :: Parser PEnv TermLEP 
parseTermP = do 
    omt <- optional parseMultTermP
    case omt of 
        Left _ -> return Eps
        Right t -> return t


parseMultTermP :: Parser PEnv TermLEP 
parseMultTermP = do 
    asterix <- parseAsterixTok 
    f       <- parseFactor
    tp      <- parseTermP 
    return (MultTermLEP f tp)

parseFactor :: Parser PEnv Factor 
parseFactor = do 
    i <- parseIntTok 
    f <- justOrFail i ( \ itok -> case itok of 
        { IntTok v -> Just (Factor v)
        ; _ -> Nothing 
        }) "parseFactor fail: expect to parse an integer token but it is not an integer."
    return f


parsePlusTok :: Parser PEnv LToken
parsePlusTok = sat ( \x -> case x of 
    { PlusTok -> True
    ; _       -> False
    }) "parsePlusTok failed, expecting a plus token."

parseAsterixTok :: Parser PEnv LToken 
parseAsterixTok = sat ( \x -> case x of 
    AsterixTok -> True
    _          -> False ) "parseAsterixTok failed, expecting an asterix token."


parseIntTok :: Parser PEnv LToken 
parseIntTok = sat ( \x -> case x of 
    IntTok v -> True
    _        -> False ) "parseIntTok failed, expecting an integer token."
```

Finally the `TermLE` to `Term` conversion is an inversed in order traversal, as the parse tree of `TermLE`

```
    T
   / \
  f   T'
     /|\
    * f T'
       /|\
      * f T'
          |
         eps
```

and the parse tree of `Term` is

```
        T
       /|\
      T * f
     /| \
    T * f 
    |
    f
```

The implementation can be found as follows,

```hs
fromTermLE :: TermLE -> Term 
fromTermLE (TermLE f tep) = fromTermLEP (FactorTerm f) tep 

fromTermLEP :: Term -> TermLEP -> Term 
fromTermLEP t1 Eps = t1 
fromTermLEP t1 (MultTermLEP f2 tp2) = 
    let t2 = MultTerm t1 f2
    in fromTermLEP t2 tp2

```

And here is some test cases

```hs
it "test parse 1+2*3" $
    let toks = [IntTok 1, PlusTok, IntTok 2, AsterixTok, IntTok 3]
        result = run parseExp (PEnv toks) 
        expected = Ok (PlusExp (FactorTerm (Factor 1)) (TermExp (MultTerm (FactorTerm (Factor 2)) (Factor 3))), PEnv [])
    in result `shouldBe` expected
```
