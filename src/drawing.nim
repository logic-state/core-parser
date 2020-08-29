import sets, tables, strformat, strutils, sugar
import graph, utils


proc graphviz(machine: StateDiagram): string =
  result &= "digraph {"
  for current, transition in machine.traverse(skipTransientTransition = false):
    for trigger, next in transition.pairs:
      let trigger = # TODO: simplify this if statement
        if trigger in machine.error.getOrDefault(current.State):
          &"[label=\"{trigger}\" color=red]"
        elif trigger != "": &"[label={trigger}]"
        else: &""
      result &= (&"\n{current} -> {next} {trigger}").indent(2)
  result &= "\n}"


type
  DrawingError* = object of Defect

# only open-source, please don't include freeware nor propietary one
  Format* {.pure.} = enum
    Graphviz, Mermaid, PlantUML, Smcat


proc draw*(machine: StateDiagram, format: Format): string {.raises:
  [DrawingError, ValueError].} =
  assert machine.diagram == TransitionTable

  case format:
  of Graphviz: machine.graphviz
  else: raise newException(DrawingError, &"{format} not yet implemented")

