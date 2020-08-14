import tables, hashes, strformat, strutils, sugar

type
  Event = distinct string
  State = distinct string

# TODO: create template method to make this pretty
proc hash(s: Event): Hash {.borrow.}
proc hash(s: State): Hash {.borrow.}
proc `==`(x, y: Event): bool {.borrow.}
proc `==`(x, y: State): bool {.borrow.}
proc `$`(s: Event): string {.borrow.}
proc `$`(s: State): string {.borrow.}


type
# CyclicTable = Table[State, Table[Event, CyclicTable]] # not yet used
  Node = ref object
    name: State
    transitions: Table[Event, Node]

# TODO: use cyclomatic number to prevent infinite recursion on cyclic transition
proc `$`(node: Node, cyclomatic: int = 0): string =
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
#     graph: CyclicTable # in consideration
    of Multidigraph:
      graph: Node # should I store it as a seq[Node]
                  # to handle orphan Nodes?


proc `$`*(machine: StateDiagram): string =
  &"(diagram: {machine.diagram},\n $1)" % [
    case machine.diagram:
    of TransitionTable: &"table: {machine.table}"
    of Multidigraph: &"graph: {machine.graph}"
  ]


proc transient(machine: StateDiagram): Table[State, State] =
  for current, transition in machine.table.pairs:
    for trigger, next in transition.pairs:
      if trigger == "".Event: result.add(current, next)


iterator pairs*(machine: StateDiagram): (string, Table[string, string]) =
  let transient = machine.transient
  for current, transition in machine.table.pairs:
    var table : Table[string, string]
    for trigger, next in transition.pairs:
      if transient.hasKey(next):
        table.add(trigger.string, transient[next].string)
      else:
        table.add(trigger.string, next.string)
    yield (current.string, table)


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
