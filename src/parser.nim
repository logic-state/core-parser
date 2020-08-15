import tables, unicode, sequtils, sugar
import npeg, npeg/lib/utf8

import graph


type Arrow {.pure.} = enum
  Forward, Backward, Bidirectional


proc parse*(graph: var StateDiagram, input: string): MatchResult[char] =
  var
    current, next: string
    direction: Arrow
    g = graph

  grammar "arrow": # I wonder if NPeg can pass value like pom-rs 🤔
    forward <- +'-' * '>':
      direction = Forward
    backward <- '<' * +'-':
      direction = Backward
    bidirectional <- '<' * +'-' * '>':
      direction = Bidirectional

  let parser = peg "transition":
    state(format) <- *utf8.space * format * *utf8.space
    event(format) <- *utf8.space * '@' * *utf8.space * format
    tIdent <- +( (Alpha * ?Digit) | '_' )
    tOps <- arrow.bidirectional | arrow.forward | arrow.backward

    transition <- transient * >?event( > tIdent) * !1:
      let event = if $1 == "": "" else: $2
      g.addEdge(current, next, event)
      if direction == Bidirectional:
        g.addEdge(next, current, event)

    transient <- state( > tIdent) * tOps * state( > tIdent):
      case direction:
        of Forward, Bidirectional: (current, next) = ($1, $2)
        of Backward: (current, next) = ($2, $1)

  result = parser.match(input); graph = g
