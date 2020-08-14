import tables, hashes, strformat, strutils, sugar

type
  Event = distinct string
  State = distinct string

# Is there a syntatic sugar for this 😂, a macro maybe
proc hash(s: Event): Hash {.borrow.}
proc hash(s: State): Hash {.borrow.}
proc `==`(x, y: Event): bool {.borrow.}
proc `==`(x, y: State): bool {.borrow.}
proc `$`(s: Event): string {.borrow.}
proc `$`(s: State): string {.borrow.}


type Node = ref object
  name: State
  transitions: Table[Event, Node]

proc `$`(node: Node): string =
  &"(name: {node.name}, transitions: {node.transitions})"

proc `[]`(node: Node, name: State): Node =
  if node.name != name:
    for n in node.transitions.values:
      result = n[name]
  else: result = node

proc contains(node: Node, name: State): bool =
  if node == nil: return false
  if node.name == name: return true
  for n in node.transitions.values:
    if name in n: return true

proc add(node: Node, key: Event, val: State) =
  node.transitions.add(key, Node(name: val))

proc `[]=`(node: Node, key: Event, val: State) =
  node.transitions[key] = Node(name: val)

proc add(node: Node, key: Event, val: Node) =
  node.transitions.add(key, val)

proc `[]=`(node: Node, key: Event, val: Node) =
  node.transitions[key] = val


type
  Diagram* {.pure.} = enum
    TransitionTable, Multidigraph

  StateDiagram* = object
    case diagram*: Diagram
    of TransitionTable:
      table: Table[State, Table[Event, State]]
    of Multidigraph:
      graph: Node # should I store it as a seq[Node]
                  # to handle orphan Nodes?


iterator pairs*(machine: StateDiagram): (string, Table[string, string]) =
  for current, transition in machine.table.pairs:
    var table = initTable[string, string]()
    for trigger, next in transition.pairs:
      table.add(trigger.string, next.string)
    yield (current.string, table)


proc `$`*(machine: StateDiagram): string =
  &"(diagram: {machine.diagram},\n $1)" % [
    case machine.diagram:
    of TransitionTable: &"table: {machine.table}"
    of Multidigraph: &"graph: {machine.graph}"
  ]


proc addEdge*(transition: var StateDiagram,
              current: string, next: string, trigger: string) =
  case transition.diagram:
  of TransitionTable:
    if current.State in transition.table:
      transition.table[current.State][trigger.Event] = next.State
    else:
      transition.table.add(current.State,
                          {trigger.Event: next.State}.toTable)
  of Multidigraph:
    if transition.graph != nil:
      if next.State in transition.graph:
        transition.graph[current.State][trigger.Event] =
          transition.graph[next.State]
      else:
        transition.graph[current.State][trigger.Event] = next.State
    else:
      transition.graph = Node(name: current.State,
                              transitions: {
                                trigger.Event: Node(name: next.State)
        }.toTable)


when isMainModule:
  var fsm = StateDiagram(diagram:
    when defined(graph): Multidigraph
                            else: TransitionTable)

  fsm.addEdge("A", "B", "C")
  fsm.addEdge("B", "F", "P")
  fsm.addEdge("A", "F", "")

  when defined(cyclic):
    fsm.addEdge("B", "A", "")

  when not defined(cyclic):
    echo '\n', fsm
  else:
    case fsm.diagram
    of Multidigraph:
      echo "TODO: implement isCyclic(n: Node) to avoid infinite recursion"
      echo "\ncontain state F: ",
           "F".State in fsm.graph # print true, and compile fine
    of TransitionTable:
      echo "It's just 2D hashtable, there is no recursion in it"
      echo '\n', fsm
