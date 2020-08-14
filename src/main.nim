import graph, parser, generator

when isMainModule:
  var fsm = StateDiagram(diagram:
    when defined(graph): Multidigraph
                            else: TransitionTable)

  while true:
    stdout.write "> "
    doAssert fsm.parse(stdin.readLine()).ok

    when defined(tsCode):
      echo fsm.generate(into=TypeState,
                      format=TypescriptCode)
    when defined(jsCode):
      echo fsm.generate(into=TypeState,
                      format=JavascriptCode)
    when defined(tsInterface):
      echo fsm.generate(into=TypeState,
                      format=TypescriptInterface)
