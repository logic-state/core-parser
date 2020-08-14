import graph, tables, strformat, strutils, sugar


proc tsInterface(machine: StateDiagram): string =
  for current, transition in machine.pairs:
    result &= &"export interface {current} {{"
    for trigger, next in transition.pairs:
      if trigger != "":
        result &= &"\n\t{trigger}(): {next}"
    result.add("\n}\n")


type
  ConvertError* = object of Exception

  Format* {.pure.} = enum
    TypescriptInterface, TypescriptCode, JavascriptCode
    WASM, WAT,
    RustTrait, RustCode,
    LLVMBytecode, LLVMIR

  Implementation* {.pure.} = enum
    StatePattern, MapLiteral, ConditionalStatement


proc generate*(machine: StateDiagram,
               format: Format,
               into: Implementation,
              ): string {.raises:
                [ConvertError, ValueError].} =
  assert machine.diagram == TransitionTable
  let err = &"can't generate {format} as {into}"
  case into:
  of StatePattern:
    case format:
    of TypescriptInterface: machine.tsInterface
    else: raise newException(ConvertError, err) 
  else: raise newException(ConvertError, err)

