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

  var resultExpr: NimNode
  if catchAllBody.isNil:
    # If there's no catch-all, raise error at runtime if nothing matches
    resultExpr = quote do:
      raise newException(ValueError, "Non-exhaustive match and no branch matched")
  else:
    resultExpr = catchAllBody

  for i in countdown(patternsAndBodies.len - 1, 0):
    let (cond, body) = patternsAndBodies[i]
    resultExpr = quote do:
      if `cond`: `body` else: `resultExpr`

  result = quote do:
    (proc(): auto =
      let `subjectSym` = `subject`
      `resultExpr`
    )()