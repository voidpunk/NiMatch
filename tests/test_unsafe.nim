import
  unittest,
  NiMatch/unsafe


echo "[TEST: UNSAFE]"


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

  expect(ValueError):
    discard match 6:
      1 => "one"
      2 => "two"
      (3, 4, 5) => "nums"


test "proc":

  proc echo_1() = echo 1
  proc echo_2() = echo 2
  proc echo_3() = echo "it also works with procs!"
  match 3:
    1 => echo_1()
    2 => echo_2()
    (3, 4, 5) => echo_3()

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
    (3, 4, 5) => 2
    6..8 => 3
    _ => 4
  check: result == 2

  result = match 5:
    0..2 => 1
    3..5 => 2
    6..8 => 3
  check: result == 2

  expect(ValueError):
    discard match 9:
      0..2 => 1
      3..5 => 2
      6..8 => 3


test "string":

  var result = match "n":
    "y" => "yes"
    "n" => "no"
    _ => "invalid"
  check: result == "no"

  result = match "y":
    "y" => "yes"
    "n" => "no"
    _ => "invalid"
  check: result == "yes"

  shouldNotCompile:
    # type mismatch
    result = match true:
      "y" => "yes"
      "n" => "no"


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

  expect(ValueError):
    discard match @[1]:
      @[1, 2, 3] => 1
      @[4, 5, 6] => 2
      @[1, 2] => 3


test "bool":

  var result = match true:
    true => "true"
    false => "false"
  check: result == "true"

