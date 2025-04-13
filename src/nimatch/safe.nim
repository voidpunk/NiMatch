import macros


macro match*(subject: untyped, branches: untyped): untyped =
  let subjectSym = genSym(nskLet, "matchSubject")
  var patternsAndBodies: seq[(NimNode, NimNode)] = @[]
  var catchAllBody: NimNode = nil

  proc extractPatterns(pat: NimNode): seq[NimNode] =
    case pat.kind
    of nnkPar, nnkTupleConstr:
      result = @[]
      for elem in pat:
        result.add(elem)
    of nnkInfix:
      if $pat[0] == "|":
        result = extractPatterns(pat[1]) & extractPatterns(pat[2])
      else:
        result = @[pat]
    else:
      result = @[pat]

  proc buildCond(subjectSym: NimNode, patterns: seq[NimNode]): NimNode =
    result = nil
    for p in patterns:
      let cond =
        if p.kind == nnkInfix and ($p[0] == ".." or $p[0] == "..="):
          newTree(nnkInfix, ident("in"), subjectSym, p)
        else:
          newTree(nnkInfix, ident("=="), subjectSym, p)
      result = if result.isNil: cond else: newTree(nnkInfix, ident("or"), result, cond)
    return result

  for branch in branches:
    if branch.kind != nnkExprColonExpr and branch.kind != nnkInfix:
      error("Each branch must be of the form: pattern => expression", branch)

    let pat = branch[1]
    let body = branch[2]

    if pat.kind == nnkIdent and $pat == "_":
      catchAllBody = body
    else:
      let patterns = extractPatterns(pat)
      let cond = buildCond(subjectSym, patterns)
      patternsAndBodies.add((cond, body))

  if catchAllBody.isNil:
    error("Match expression is not exhaustive. You must include a catch-all '_' branch.")

  # Build the nested if-else tree
  var resultExpr = catchAllBody
  for i in countdown(patternsAndBodies.len - 1, 0):
    let (cond, body) = patternsAndBodies[i]
    resultExpr = quote do:
      if `cond`: `body` else: `resultExpr`

  # Wrap in an IIFE so it can be used as an expression
  result = quote do:
    (proc(): auto =
      let `subjectSym` = `subject`
      `resultExpr`
    )()


macro match*(subject: bool, branches: untyped): untyped =
  let subjectSym = genSym(nskLet, "boolMatchSubject")
  var trueBody, falseBody, catchAllBody: NimNode
  var hasTrue, hasFalse: bool

  for branch in branches:
    if branch.kind != nnkExprColonExpr and branch.kind != nnkInfix:
      error("Each branch must be of the form: pattern => expression", branch)

    let pat = branch[1]
    let body = branch[2]

    case pat.kind
    of nnkIdent:
      let name = $pat
      if name == "true":
        hasTrue = true
        trueBody = body
      elif name == "false":
        hasFalse = true
        falseBody = body
      elif name == "_":
        catchAllBody = body
      else:
        error("Invalid pattern in boolean match: " & name, pat)
    else:
      error("Invalid pattern kind in boolean match", pat)

  if not (hasTrue and hasFalse) and catchAllBody.isNil:
    error("Match on bool must be exhaustive. Provide both `true` and `false`, or use `_`.")

  # Construct the match expression
  var resultExpr: NimNode
  if hasTrue and hasFalse:
    resultExpr = quote do:
      if `subjectSym`: `trueBody` else: `falseBody`
  elif hasTrue:
    resultExpr = quote do:
      if `subjectSym`: `trueBody` else: `catchAllBody`
  elif hasFalse:
    resultExpr = quote do:
      if not `subjectSym`: `falseBody` else: `catchAllBody`
  else:
    resultExpr = catchAllBody

  result = quote do:
    (proc(): auto =
      let `subjectSym` = `subject`
      `resultExpr`
    )()
