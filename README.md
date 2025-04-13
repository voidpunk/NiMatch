# NiMatch

This tiny package provides a Rust-like match construct for Nim. I wrote it essentially because I prefer the Rust match clear and concise syntax to the Nim ugly case of syntax. It doesn't implement all the functionalities of real Rust match construct though (at least not yet).

The library is divided into a "safe" and "unsafe" implementation:
- nimatch/safe: the match macro raise a compile-time 
error if the catchall branch is missing, this ensure that all possible cases are covered. The only exception where catchall branch remain optional is with bool type.
- nimatch/unsafe: the match macro raise a run-time error if the subject of the match construct isn't covered in the branches, but the catchall branch is optional.

The code is organized this way due to some limitations of Nim language: getType and getTypeInst only work in a typed macro, but they don't work in a compile-time proc. [RFC#44](https://github.com/nim-lang/RFCs/issues/44) This makes it impossible, or at least very difficult, to implement a real rust-like match syntax which checks for exhaustive coverage of enums or other types in branches, and requires a catchall branch only if not all of them are covered, and render the construct more like a modified and improved (imo) case of construct.


## safe

As in Rust match, you can directly bind the result of the match construct to a variable, the type of the variable must match with the type of the branches (which needs to be the same for all).

Unlike Rust, commas and parentheses aren't used, but indentation is required. The range syntax is the one of Nim, and the or syntax too is the same used in Nim case of, with the difference that parentheses are required. This improved coherence with Nim and provides a better syntax.

```nim
import nimatch

let result = match 3:
  1 => "one"
  2..4 => "two to four" # equivalent to Rust "2..=4"
  (5, 6, 7) => "five, six, seven" # equivalent to Rust "5 | 6 | 7"
  _ => "all the other numbers"
echo result
# two to four 
```
If the catchall case is missing (and the match is against a type different from bool) a compile-time error is raised: `Error: Match expression is not exhaustive. You must include a catch-all '_' branch.`

The construct can also be used in a similar to Nim case of to just call a function in each branch. The following examples, drawn from [Nim by Example](https://nim-by-example.github.io/case), are completely equivalent. 

```nim
import nimatch

case "charlie":
  of "alfa":
    echo "A"
  of "bravo":
    echo "B"
  of "charlie":
    echo "C"
  else:
    echo "Unrecognized letter"

match "charlie":
  "alfa" => echo "A"
  "bravo" => echo "B"
  "charlie" => echo "C"
  _ => echo "Unrecognized letter"

case 'h':
  of 'a', 'e', 'i', 'o', 'u':
    echo "Vowel"
  of '\127'..'\255':
    echo "Unknown"
  else:
    echo "Consonant"

match 'h':
  ('a', 'e', 'i', 'o', 'u') => echo "Vowel"
  '\127'..'\255' => echo "Unknown"
  _ => echo "Consonant"

proc positiveOrNegative(num: int): string =
  result = case num:
    of low(int).. -1:
      "negative"
    of 0:
      "zero"
    of 1..high(int):
      "positive"
    else:
      "impossible"

proc positiveOrNegative(num: int): string =
  result = match num:
    low(int).. -1 => "negative"
    0 => "zero"
    1..high(int) => "positive"
    _ => "impossible"
```

Since the bool type has only two variants, unlike as enum, it is possible to determine at compile time if they are all covered. Therefore, it's the only type that doesn't require a catchall branch.

```nim
match false:
  true  => doThis()
  false => doThat()
```

## Unsafe

It's pretty much the same as safe, but the catchall branch is optional in match against any type. An exception is raised at run-time only if the subject of the match isn't covered in any of the branches: `Error: unhandled exception: Non-exhaustive match and no branch matched [ValueError]`.

```nim
import nimatch/unsafe

match "yes":
  ("y", "yes) => doSomething()
  ("n", "no") => doNothing()

proc getSeqNum(sequence: seq): int =
  result = match sequence:
    @[1, 2, 3] => 1
    @[4, 5, 6] => 2
    @[7, 8]    => 3
    @[9]       => 4

echo getSeqNum(@[7, 8])
# 3
```

For more examples you can peek at the library tests.