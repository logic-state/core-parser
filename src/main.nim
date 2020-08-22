import graph, parser, generator, drawing, error
import strformat, tables, sequtils, sugar

proc print(fsm: StateDiagram) =
  when defined(debug):
    echo fsm

  when defined(dot):
    echo fsm.draw(Graphviz)
  when defined(tsCode):
    echo fsm.generate(into = TypeState,
                    format = TypescriptCode)
  when defined(jsCode):
    echo fsm.generate(into = TypeState,
                    format = JavascriptCode)
  when defined(tsInterface):
    echo fsm.generate(into = TypeState,
                    format = TypescriptInterface)


when isMainModule:
  import noise, terminal, strutils

  var repl = Noise.init()
  repl.setPrompt("> ")

  var fsm = StateDiagram(diagram:
    when defined(graph): Multidigraph
    else: TransitionTable)

  while isAtty(stdin) and repl.readLine():
    let input = repl.getLine
    fsm.parse(input)

    fsm.print()
    when promptHistory:
      if input.len > 0: repl.historyAdd(input)

  if not isAtty(stdin):
    let input = stdin.readAll
    try:
      fsm.parse(input)
      fsm.print()
    except SemanticError as e:
      when defined(debug): echo fsm
      when defined(dot):
        echo fsm.draw(Graphviz)
      else:
        echo e.explain(input)
    except SyntaxError as e:
      when defined(debug): echo fsm
      echo e.msg
