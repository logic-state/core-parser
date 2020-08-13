import graph, parser

when isMainModule:
  var fsm = StateDiagram(diagram:
    when defined(graph): Multidigraph
                            else: TransitionTable)

  while true:
    stdout.write "> "
    doAssert fsm.parse(stdin.readLine()).ok
    echo fsm
