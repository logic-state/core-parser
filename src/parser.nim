import sets, tables, strformat, unicode, sequtils, sugar
import npeg, npeg/lib/utf8

import graph, error


type
  Track = Table[State, Table[Event, Natural]]

  Transition {.pure.} = enum
    Normal, Loop, Bidirectional


proc parse*(diagram: var StateDiagram, input: string) =
  var
    loc: Natural = 1 # TODO: remove this and use NPeg @n in codeblock to get the match index
    track: Track
    error = new SemanticError
    currents: seq[string]
    next: string
    direction: Transition
    g = diagram

  grammar "arrow": # I wonder if NPeg can pass value like pom-rs 🤔
    forward <- +'-' * '>' * >?'>':
      direction = if $1 == "": Normal else: Loop
    backward <- '<' * >?'<' * +'-':
      direction = if $1 == "": Normal else: Loop
    bidirectional <- '<' * +'-' * '>':
      direction = Bidirectional

  let parser = peg "result":
    # TODO: make PR for adding Newline in NPeg since Nim has this by default
    Newline <- {'\c', '\n'}: loc += 1 
    state(format) <- *Blank * format * *Blank
    event(format) <- *Blank * '@' * *Blank * format
    sep(sep, value) <- +(value * ?(*Blank * sep * *Blank))

    comment <- '#' * *(utf8.any - {'\c', '\n'})
    ident <- +((Alpha * ?Digit)|'_') # any non-space case

    result <- +( *(comment|Newline) * transition): # reset temp value
      (currents, next) = (newSeq[string](), "")


    transition <- transient * >?event( > ident|E"missing event name"):
      let trigger = if $1 == "": "" else: $2

      # TODO: refactor this. Also fully use SemanticError and remove every err-related tmp-val
      proc errCheck(current: string) =
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

      if next in currents and trigger == "":
        if g.error.hasKeyOrPut(next.State, [trigger].toHashSet):
          g.error[next.State].incl(trigger)
        error.addCause(next.State, errInfiniteLoop, [loc].toSeq)

      case direction:
        of Bidirectional, Loop: errCheck(next)
        else: discard
      for current in currents:
        errCheck(current)
        g.addEdge(current, next, trigger)
        if direction == Bidirectional: g.addEdge(next, current, trigger)
      if direction == Loop: g.addEdge(next, next, trigger)


    transient <- forward|bidirectional|backward

    # TODO: prevent same states by using back references
    forward <- state(sep(',', >ident)) * arrow.forward * state( >ident * !','):
      for c in capture[1..^2]: currents.add(c.s)
      next = capture[^1].s
    backward <- state( >ident * !',') * arrow.backward * state(sep(',', >ident)):
      for c in capture[2..^1]: currents.add(c.s)
      next = capture[1].s
    bidirectional <- state( >ident * !',') * arrow.bidirectional * state( >ident * !','):
      currents.add($1) ; next = $2


  let p = parser.match(input)
  if p.ok: diagram = g
  else: raise newException(SyntaxError, &"Syntax error at {p.matchLen}:{p.matchMax}")
  if error.causes.len > 0:
    raise error
