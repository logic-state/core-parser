import strutils, npeg


grammar "case": # Unused. Reserved for the linter
  pascal <- +(Upper * *Alpha)
  camel <- +(Lower * *Alpha)
  snake <- +(Lower * ?'_' * Lower)
  hyphen <- +(Lower * ?'-' * Lower)


proc normalize(s: string): string =
  s.replace(" ").replace("_")


proc camelCase*(s: string): string =
  result = s.normalize
  result[0] = result[0].toLowerAscii


proc PascalCase*(s: string): string =
  result = s.normalize
  result[0] = result[0].toUpperAscii
