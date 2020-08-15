import graph, parser, generator, drawing

when isMainModule:
  var fsm = StateDiagram(diagram:
    when defined(graph): Multidigraph
                            else: TransitionTable)

  while true:
    stderr.write "> "
    doAssert fsm.parse(stdin.readLine()).ok

    when defined(debug):
      echo fsm

    when defined(dot):
      echo fsm.draw(Graphviz)
    when defined(tsCode):
      echo fsm.generate(into=TypeState,
                      format=TypescriptCode)
    when defined(jsCode):
      echo fsm.generate(into=TypeState,
                      format=JavascriptCode)
    when defined(tsInterface):
      echo fsm.generate(into=TypeState,
                      format=TypescriptInterface)
