import tables, unicode, sequtils, sugar

import npeg, npeg/lib/utf8

import grim # this lib is too overkill 😂
#type # TODO: replace grim with this 👇
#  ForeignFunction = distinct string # extern function of another prog-lang which to be generated
#  Value = enum Number, String
#  Event = distinct string
#  State = object
#    name: string
#    vars: Table[string, Value]
#    acts: Table[string, ForeignFunction]
#    transitions: Table[Event, ref State]

grammar "name":
  PascalCase <- +(Upper * *Alpha)
  camelCase <- +(Lower * *Alpha)
  snake_case <- +(Lower * ?'_' * Lower)

type Arrow {.pure.} = enum
  Forward, Backward, Bidirectional

var direction : Arrow
grammar "arrow": # I wonder if NPeg can pass value like pom-rs 🤔
  forward <- +'-' * '>':
    direction = Forward
  backward <- '<' * +'-':
    direction = Backward
  bidirectional <- '<' * +'-' * '>':
    direction = Bidirectional

var
  current, next : string
  graph = newGraph("StateMachine")

let parser* = peg "transition":
  state(format) <- *utf8.space * format * *utf8.space
  event(format) <- *utf8.space * '@' * *utf8.space * format
  tIdent <- name.PascalCase
  tOps <- arrow.bidirectional | arrow.forward | arrow.backward

  transition <- forward * >?event(>tIdent) * !1:
    let
      add = (n: string) => graph.addNode(n)
      event = if $1 == "": "" else: $2
    discard graph.addEdge(add(current), add(next), event)
    if direction == Bidirectional:
       # BUG: grim can't do bidirectional nor unidirectional graph
       discard graph.addEdge(add(next), add(current), event)

  forward <- state(>tIdent) * tOps * state(>tIdent):
    case direction:
      of Forward: (current, next) = ($1, $2)
      of Backward: (current, next) = ($2, $1)
      of Bidirectional: discard


while true:
  stdout.write "> "
  let input = stdin.readLine()

  doAssert parser.match(input).ok
  #echo graph.describe
  graph.saveYaml("result.yaml", true)
