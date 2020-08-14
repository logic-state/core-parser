import graph, tables, strformat, strutils, sugar


proc tsInterface(machine: StateDiagram): string =
  for current, transition in machine.pairs:
    result &= &"export interface {current} {{"
    for trigger, next in transition.pairs:
      if trigger != "":
        result &= &"\n\t{trigger}(): {next}"
    result.add("\n}\n")

proc jsCode(machine: StateDiagram, typescript: bool = false): string =
  for current, transition in machine.pairs:
    result &= &"export class {current} {{"
    for trigger, next in transition.pairs:
      if trigger != "":
        let returnType = if typescript: &": {next}" else: ""
        result &= &"\n\t{trigger}(){returnType} {{" &
          "\n\t\t// side-effect" &
          &"\n\t\treturn new {next}()" &
        "\n\t}}"
    result.add("\n}\n")

type
  ConvertError* = object of Exception

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
                [ConvertError, ValueError].} =
  assert machine.diagram == TransitionTable
  let errMsg = &"can't generate {format} as {into}"
  case into:
  of TypeState:
    case format:
    of TypescriptInterface: machine.tsInterface
    of JavascriptCode: machine.jsCode
    of TypescriptCode: machine.jsCode(typescript=true)
    else: raise newException(ConvertError, errMsg)
  else: raise newException(ConvertError, errMsg)

