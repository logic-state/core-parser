import tables, strformat, strutils, sugar
import graph, utils


proc tsInterface(machine: StateDiagram): string =
  for current, transition in machine.traverse:
    result &= &"export interface {current.PascalCase} {{"
    for trigger, next in transition.pairs:
      if trigger != "":
        result &= (&"\n{trigger.camelCase}(): {next.PascalCase}").indent(2)
    result.add("\n}\n")

proc jsCode(machine: StateDiagram, typescript: bool = false): string =
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
    result.add("\n}\n")


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


proc generate*(machine: StateDiagram,
               format: Format,
               into: Implementation,
              ): string {.raises:
                [GeneratorError, ValueError].} =
  assert machine.diagram == TransitionTable
  let errMsg = &"can't generate {format} as {into}"

  case into:
  of TypeState:
    case format:
    of TypescriptInterface: machine.tsInterface
    of JavascriptCode: machine.jsCode
    of TypescriptCode: machine.jsCode(typescript = true)
    else: raise newException(GeneratorError, errMsg)
  else: raise newException(GeneratorError, errMsg)

