import npeg, graph
import tables, strformat, strutils, algorithm, sequtils

type
  # reserved until NPeg support accessing matchLen/Max in codeblock
  #Cause = object
  #  matchLen*, matchMax*: Natural
  ErrorType* = enum
    errTransient, errSameEvent, errInfiniteLoop

  SyntaxError* = NPegException
  SemanticError* = object of CatchableError
    causes*: Table[State, Table[ErrorType, seq[Natural]]]


proc addCause*(error: ref SemanticError,
               state: State, kind: ErrorType, lines: seq[Natural]) =
  if error.causes.hasKeyOrPut(state, toTable {kind: lines}):
    if error.causes[state].hasKeyOrPut(kind, lines):
      error.causes[state][kind].add(lines)
  error.causes[state][kind] = error.causes[state][kind].deduplicate().sorted


proc pad(number: Natural, c = ' '): string = c.repeat(($number).len)

proc `$`(kind: ErrorType): string =
  case kind:
  of errTransient:
    "is transient state. It must not have another transition"
  of errSameEvent:
    "state must not have transitions with the same event"
  of errInfiniteLoop:
    "state is looping. Loop transition must be triggered by event"

proc explain*(e: ref SemanticError, source: string): string =
  for state in e.causes.keys:
    for kind, lines in e.causes[state].pairs:
      let fullpad = lines.max.pad('~')
      #result &= &"{fullpad}:{state}:{fullpad}\n"
      for line in lines:
        let pad = ' '.repeat(fullpad.len - line.pad.len)
        let code = source.splitLines[line - 1]
        result &= &"{line}{pad}| {code}\n"
      result &= &"{fullpad}=`{state}` {$kind}\n\n"
  result.strip

