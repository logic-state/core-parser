import graph, parser, generator, drawing


proc print(fsm: StateDiagram) =
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


when isMainModule:
  import noise, terminal, strutils

  var repl = Noise.init()
  repl.setPrompt("> ")

  var fsm = StateDiagram(diagram:
    when defined(graph): Multidigraph
    else: TransitionTable)

  while isAtty(stdin) and repl.readLine():
    let line = repl.getLine
    discard fsm.parse(line)

    fsm.print()
    when promptHistory:
      if line.len > 0: repl.historyAdd(line)

  if not isAtty(stdin):
    for line in stdin.readAll.splitLines:
      discard fsm.parse(line)
    fsm.print()
