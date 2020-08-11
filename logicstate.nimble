# TODO:
# change binary name [this](https://github.com/nim-lang/nimble/issues/515) resolved

# Package

version       = "0.1.0"
author        = "Fahmi Akbar Wildana"
description   = "A language for describing a statemachine"
license       = "UPL-1.0"
srcDir        = "src"
bin           = @["main"]



# Dependencies

requires "nim >= 1.2.4"
requires "npeg >= 0.22.2", "noise >= 0.1.3", "grim >= 0.2.0"
