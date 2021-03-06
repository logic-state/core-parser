import graph, parser, generator, drawing, error
import strformat, tables, sequtils, sugar

proc print(fsm: StateDiagram) =
  when defined(debug): echo fsm

  var
    implementation: generator.Implementation
    format: generator.Format

  when defined(statepatt): implementation = StatePattern
  elif defined(typestate): implementation = TypeState
  elif defined(record): implementation = Record
  elif defined(condstmt): implementation = ConditionalStatement

  when defined(jsCode): format = JavascriptCode
  elif defined(tsCode): format = TypescriptCode
  elif defined(tsInterface):
    format = TypescriptInterface
  elif defined(rsTrait):
    (implementation, format) = (TypeState, RustTrait)
  elif defined(rsCode): format = RustCode
  elif defined(gdscript):
    (implementation, format) = (StatePattern, GDScript)

  when defined(dot): echo fsm.draw(Graphviz)
  else: echo fsm.generate(format, implementation)


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
      when defined(dot):
        echo fsm.draw(Graphviz)
      else: echo e.msg
