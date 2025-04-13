import
  unittest,
  nimatch


test "match":
  let result = match 3:
    1 => "one"
    2..4 => "two to four"
    (5, 6, 7) => "five, six, seven"
    _ => "all the other numbers"
  check: result == "two to four"