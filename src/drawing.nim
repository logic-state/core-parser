import tables, strformat, strutils, sugar
import graph, utils


proc graphviz(machine: StateDiagram): string =
  result &= "digraph {"
  for current, transition in machine.pairs:
    for trigger, next in transition.pairs:
      if trigger != "":
        result &= (&"\n{current} -> {next} [label={trigger}]").indent(2)
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

