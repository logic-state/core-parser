import strutils


proc normalize(s: string): string =
  s.replace(" ").replace("_")


proc camelCase*(s: string): string =
  result = s.normalize
  result[0] = result[0].toLowerAscii


proc PascalCase*(s: string): string =
  result = s.normalize
  result[0] = result[0].toUpperAscii
