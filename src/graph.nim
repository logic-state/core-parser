import tables, hashes, strformat

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

proc `$`(ro: Node): string =
  result = &"(name: {ro.name}, transitions: {ro.transitions})"

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

proc add(node: Node, key: Event, val: Node) =
  node.transitions.add(key, val)

type
  Diagram* {.pure.} = enum
    TransitionTable, Multidigraph

  StateDiagram* = object
    case diagram: Diagram
    of TransitionTable:
      table: Table[State, Table[Event, State]]
    of Multidigraph:
      graph: Node # should I store it as a seq[Node]
                  # to handle orphan Nodes?


proc addEdge*(transition: var StateDiagram,
              current: string, next: string, trigger: string) =
  case transition.diagram:
  of TransitionTable:
    if current.State in transition.table:
      transition.table[current.State].add(trigger.Event, next.State)
    else:
      transition.table.add(current.State,
                          {trigger.Event: next.State}.toTable)
  of Multidigraph:
    if transition.graph != nil:
      if next.State in transition.graph:
        transition.graph[current.State]
          .add(trigger.Event, transition.graph[next.State])
      else:
        transition.graph[current.State].add(trigger.Event, next.State)
    else:
      transition.graph = Node(name: current.State,
                              transitions: {
                                trigger.Event: Node(name: next.State)
                              }.toTable)

when isMainModule:
  when defined(graph):
    var fsm = StateDiagram(diagram: Multidigraph)
  else:
    var fsm = StateDiagram(diagram: TransitionTable)

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
           "F".State in fsm.graph   # print true, and compile fine
    of TransitionTable:
      echo "It's just 2D hashtable, there is no recursion in it"
      echo '\n', fsm
