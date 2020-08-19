import graph, parser, generator, drawing
import strformat, sugar

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
      let loc = input[0..e.matchLen].countLines
      type Pad {.pure.} = enum Explain, Cause, Problem
      template pad(ty: Pad): string =
        let fullpad = ' '.repeat(($max(loc, e.cause+1)).len)
        case ty:
        of Explain: fullpad
        of Cause: ' '.repeat(fullpad.len - ($e.cause).len)
        of Problem: ' '.repeat(fullpad.len - ($loc).len)

      echo &"{pad(Cause)}{e.cause+1}| ",
           input.splitLines[e.cause]
      echo &"{pad(Problem)}{loc}| ",
           input[e.matchLen..e.matchMax].strip(chars = {'\c', '\n'})
      echo &"{pad(Explain)}= ", e.msg
    except SyntaxError as e:
      echo e.msg
