import sets, tables, unicode, sequtils, sugar
import npeg, npeg/lib/utf8

import graph, error


type
  Track = Table[State, Table[Event, Natural]]

  Arrow {.pure.} = enum
    Forward, Backward, Bidirectional


proc parse*(graph: var StateDiagram, input: string) =
  var
    loc: Natural = 1 # workaround since matchLen/Max not in NPeg codeblock 😞
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

      proc errCheck(current: string) = # TODO: refactor this
        if track.hasKeyOrPut(current.State, {trigger.Event: loc}.toTable):
          track[current.State].add(trigger.Event, loc)
        if current.State in g.transient or
           track[current.State].len > 1 and trigger == "":
          let events = toSeq(track[current.State].keys)
            .map(e => e.string).toHashSet
          if g.error.hasKeyOrPut(current.State, events):
            g.error[current.State].incl(events)
          let lines = toSeq(track[current.State].values)
          error.addCause(current.State, errTransient, lines)
        if trigger.Event in g[current]:
          if g.error.hasKeyOrPut(current.State, [trigger].toHashSet):
            g.error[current.State].incl(trigger)
          let line = track[current.State][trigger.Event]
          error.addCause(current.State, errSameEvent, [line, loc].toSeq)

      if next in current and trigger == "":
        if g.error.hasKeyOrPut(next.State, [trigger].toHashSet):
          g.error[next.State].incl(trigger)
        error.addCause(next.State, errInfiniteLoop, [loc].toSeq)

      errCheck(current)
      if direction == Bidirectional:
        errCheck(next)

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
  if error.causes.len > 0:
    raise error
