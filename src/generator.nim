import tables, strformat, strutils, sugar
import graph, utils


type
  GeneratorError* = object of CatchableError

  Format* {.pure.} = enum
    TypescriptInterface, TypescriptCode, JavascriptCode
    WASM, WAT,
    GDScript, Python,
    RustTrait, RustCode,
    LLVMBytecode, LLVMIR

  Implementation* {.pure.} = enum
    TypeState, StatePattern, Collection, ConditionalStatement

# TODO: use template engine instead of doing it procedurally

proc tsInterface(machine: StateDiagram,
                 implementation: Implementation): string =
  for current, transition in machine.traverse:
    result &= &"export interface {current.PascalCase} {{"
    for trigger, next in transition.pairs:
      if trigger != "":
        result &= (&"\n{trigger.camelCase}(): {next.PascalCase}").indent(2)
    result.add("\n}\n\n")
  result.strip

proc jsCode(machine: StateDiagram,
            format: Format,
            implementation: Implementation): string {.raises:
              [GeneratorError, ValueError].} =
  let typescript = format == TypescriptCode
  case implementation:

  of TypeState:
    for current, transition in machine.traverse:
      result &= &"export class {current.PascalCase} {{"
      for trigger, next in transition.pairs:
        if trigger != "":
          let retTy = if typescript: &": {next.PascalCase}" else: ""
          result &= (&"\n{trigger.camelCase}(){retTy} {{").indent(2)
          result &= (&"\n// side-effect" &
                    &"\nreturn new {next.PascalCase}()"
            ).indent(4)
          result &= "\n}".indent(2)
      result.add("\n}\n\n")

  of StatePattern:
    let `!` = if typescript: "!" else: ""
    var
      ievent = "interface IEvent {"
      context = "class Context " &
        (if typescript:
          "implements IEvent {\n" &
          "constructor(public state?: State) {}"
          .indent(2) else: "{")
      astate = "class State " &
        (if typescript:
          "implements IEvent {\n" &
          "constructor(public context?: Context) {}"
          .indent(2) else:
          "{\n" & "constructor(ctx) { this.context = ctx }"
          .indent(2))
    if typescript: astate = "abstract " & astate

    for trigger in machine.events:
      let fn = trigger.camelCase
      ievent &= (&"\n{fn}(): void").indent(2)
      context &= (&"\n{fn}() {{ this.state{`!`}.{fn}() }}").indent(2)
      astate &=
        (if typescript: &"\nabstract {fn}(): void" else: &"\n{fn}() {{}}")
        .indent(2)
    ievent.add("\n}\n"); context.add("\n}\n"); astate.add("\n}\n")

    for current, transition in machine.traverse(skipTransientState = true):
      result &= &"export class {current.PascalCase} extends State {{\n"

      proc genHandler(trigger: string): string =
        if trigger in transition:
          let next = transition[trigger]
          result &= (&"{trigger.camelCase}() {{").indent(2) & '\n' &
          (&"""// side-effect
          this.context{`!`}.state = new {next.PascalCase}(this.context)
          """).strip.unindent.indent(4) & "\n}".indent(2) & '\n'
        else:
          result &= (&"{trigger.camelCase}() {{}}").indent(2) & '\n'

      if typescript:
        for trigger in machine.events: result &= genHandler(trigger)
      else:
        for trigger in transition.keys: result &= genHandler(trigger)

      result.stripLineEnd; result.add("\n}\n\n")
    result = context & '\n' & astate & '\n' & result
    if typescript: result = ievent & '\n' & result
    result &= "export function " &
    (if typescript: "init(state: State): Context" else: "init(state)") &
    " {\n" & """
    let ctx = new Context()
    state.context = ctx
    ctx.state = state
    return ctx
    """.strip.unindent.indent(2) & "\n}"

  else: raise newException(GeneratorError,
        &"can't generate {format} as {implementation}")
  result.strip


proc generate*(machine: StateDiagram,
               format: Format,
               into: Implementation,
              ): string {.raises:
                [GeneratorError, ValueError].} =
  assert machine.diagram == TransitionTable
  let errMsg = &"can't generate {format} as {into}"

  case format:
  of TypescriptInterface: machine.tsInterface(into)
  of JavascriptCode, TypescriptCode: machine.jsCode(format, into)
  else: raise newException(GeneratorError, errMsg)
