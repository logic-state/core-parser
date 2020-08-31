import strutils, sequtils, sugar

# Reserved for the linter
# grammar "case": 
#   pascal <- +(Upper * *Alpha)
#   camel <- +(Lower * *Alpha)
#   snake <- +(Lower * ?'_' * Lower)
#   hyphen <- +(Lower * ?'-' * Lower)


proc compact(s: string): string =
  ## remove all space and underscore
  s.replace(" ").replace("_")


proc camelCase*(s: string): string =
  result = if ' ' in s or '_' in s:
    s.split({' ', '_'}).map(w => w.capitalizeAscii).join.compact else: s
  result[0] = result[0].toLowerAscii


proc snake_case*(s: string): string =
  if ' ' in s: return s.replace(' ', '_')
  result.add(s[0].toLowerAscii)
  for i in 1..<s.len:
    if s[i] in {'A'..'Z'}:
      result.add('_' & s[i].toLowerAscii)
    else: result.add(s[i])


proc PascalCase*(s: string): string =
  if ' ' in s or '_' in s:
    s.split({' ', '_'}).map(w => w.capitalizeAscii).join.compact
  else: s.capitalizeAscii
