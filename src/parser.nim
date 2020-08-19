import tables, unicode, sequtils, sugar
import npeg, npeg/lib/utf8

import graph


type
  SyntaxError* = NPegException
  #Cause = object # reserved until NPeg support accessing
  #                 matchLen/Max in codeblock
  #  matchLen*, matchMax*: Natural
  SemanticError* = object of CatchableError
    cause*: Natural #linenumber
    matchLen*, matchMax*: Natural

  Track = Table[State, Table[Event, Natural]]

  Arrow {.pure.} = enum
    Forward, Backward, Bidirectional


proc parse*(graph: var StateDiagram, input: string) =
  var
    loc: Natural # workaround since matchLen/Max not in NPeg codeblock 😞
    track: Track
    error = new SemanticError
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

  let parser = peg "result":
    Newline <- {'\c', '\n'}: loc += 1    #TODO: make PR for adding this in NPeg
    state(format) <- *Blank * format * *Blank
    event(format) <- *Blank * '@' * *Blank * format

    comment <- '#' * *(utf8.any - {'\c', '\n'})
    tIdent <- +( (Alpha * ?Digit) | '_') # any non-space case
    tOps <- arrow.bidirectional | arrow.forward | arrow.backward |
            E"must be one of ->, <-, <->"

    result <- +( *(comment|Newline) * transition)


    transition <- transient * >?event( > tIdent|E"missing event name"):
      let trigger = if $1 == "": "" else: $2

      if track.hasKeyOrPut(current.State, {trigger.Event: loc}.toTable):
        track[current.State].add(trigger.Event, loc)

      if current.State in g.transient or
         track[current.State].len > 1 and trigger == "":
        error.cause =
          if trigger != "": track[current.State]["".Event]
          else: toSeq(track[current.State].values)[1]
        error.msg =
          "state with transient transition must not have another transition"
        when not defined(hoisting): fail()
      if trigger.Event in g[current]:
        error.cause = track[current.State][trigger.Event]
        error.msg = "a state must not have transitions with the same event"
        when not defined(hoisting): fail()

      g.addEdge(current, next, trigger)
      if direction == Bidirectional:
        g.addEdge(next, current, trigger)


    transient <- state( > tIdent) * tOps *
                 state( > tIdent|E"missing state name"):
      case direction:
        of Forward, Bidirectional: (current, next) = ($1, $2)
        of Backward: (current, next) = ($2, $1)


  let p = parser.match(input)
  if p.ok: graph = g
  if error.msg != "":
    error.matchLen = p.matchLen
    error.matchMax = p.matchMax
    raise error
