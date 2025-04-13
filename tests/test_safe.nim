import
  unittest,
  nimatch/safe


echo "[TEST: SAFE]"


template shouldNotCompile(code: untyped) =
  static:
    doAssert not compiles(code)


test "int":

  var result = match 1:
    1 => "one"
    2 => "two"
    (3, 4, 5) => "nums"
    _ => "others"
  check: result == "one"

  result = match 4:
    1 => "one"
    2 => "two"
    (3, 4, 5) => "nums"
    _ => "others"
  check: result == "nums"

  result = match 6:
    1 => "one"
    2 => "two"
    (3, 4, 5) => "nums"
    _ => "others"
  check: result == "others"

  shouldNotCompile:
    # missing catchall branch
    result = match 6:
      1 => "one"
      2 => "two"
      (3, 4, 5) => "nums"


test "proc":

  proc echo_1() = echo 1
  proc echo_2() = echo 2
  proc echo_3() = echo "it also works with procs!"
  proc echo_4() = echo 4
  match 3:
    1 => echo_1()
    2 => echo_2()
    (3, 4, 5) => echo_3()
    _ => echo_4()

  proc get_1(): int =  1
  proc get_2(): int =  2
  proc get_3(): int =  3
  proc get_4(): int =  4
  var result = match 3:
    1 => get_1()
    2 => get_2()
    (3, 4, 5) => get_3()
    _ => get_4()
  check: result == 3


test "range":

  var result = match 3:
    0..2 => 1
    3..5 => 2
    6..8 => 3
    _ => 4
  check: result == 2

  result = match 4:
    0..2 => 1
    3..5 => 2
    6..8 => 3
    _ => 4
  check: result == 2

  result = match 5:
    0..2 => 1
    3..5 => 2
    6..8 => 3
    _ => 4
  check: result == 2

  result = match 9:
    0..2 => 1
    3..5 => 2
    6..8 => 3
    _ => 4
  check: result == 4

  shouldNotCompile:
    # missing catchall branch
    result = match 9:
      0..2 => 1
      3..5 => 2
      6..8 => 3


test "string":

  var result = match "n":
    "y" => "yes"
    "n" => "no"
    _ => "invalid"
  check: result == "no"

  result = match "yep":
    "y" => "yes"
    "n" => "no"
    _ => "invalid"
  check: result == "invalid"

  shouldNotCompile:
    # type mismatch
    result = match true:
      "y" => "yes"
      "n" => "no"
      _ => ""


test "char":

  var result = match 'a':
    ('a', 'b') => 1
    _ => 2
  check: result == 1

  result = match 'b':
    ('a', 'b') => 1
    _ => 2
  check: result == 1

  result = match 'z':
    ('a', 'b') => 1
    _ => 2
  check: result == 2

  shouldNotCompile:
    # missing catchall branch
    result = match 'a':
      ('a', 'b') => 1


test "object":

  type Person = object
    name: string
    age: int
  var result = match Person(name: "Peter", age: 20):
    Person(name: "Peter", age: 30) => "Peter"
    Person(name: "Tim", age: 30) => "Tim"
    Person(name: "Peter", age: 20) => "Young Peter"
    _ => "other"
  check: result == "Young Peter"

  shouldNotCompile:
    # type mismatch
    type Animal = object
      name: string
      cute: bool
    result = match Animal(name: "fox", cute: true):
      Person(name: "Peter", age: 30) => "Peter"
      Person(name: "Tim", age: 30) => "Tim"
      Person(name: "Peter", age: 20) => "Young Peter"
      _ => "other"


test "seq":

  var result = match @[1, 2, 3]:
    @[1, 2, 3] => 1
    @[4, 5, 6] => 2
    @[1, 2] => 3
    _ => 4
  check: result == 1

  result = match @[1, 2]:
    @[1, 2, 3] => 1
    @[4, 5, 6] => 2
    @[1, 2] => 3
    _ => 4
  check: result == 3


test "bool":

  var result = match true:
    true => "true"
    false => "false"
    _ => "this doesn't make sense O.o"
  check: result == "true"

  result = match false:
      true => "true"
      false => "false"
  check: result == "false"