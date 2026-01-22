import std/os
import std/osproc
import std/random
import std/strutils
import std/sequtils
import std/sugar

import semver
import util/str

const
  loremIpsum = @["lorem", "ipsum", "dolor", "sit", "amet", "consectetur",
  "adipiscing", "elit", "morbi", "efficitur", "libero", "vitae", "congue",
  "blandit", "orci", "sem", "semper", "purus", "ac", "mattis", "eros", "mi",
  "quis", "magna", "mauris", "id", "turpis", "iaculis", "pulvinar", "ut",
  "porta", "dui", "duis", "faucibus", "augue", "eget", "laoreet", "etiam",
  "eu", "a", "metus", "scelerisque", "bibendum", "non", "lacus", "sed",
  "feugiat", "nibh", "suscipit", "ante", "in", "hac", "habitasse", "platea",
  "dictumst", "cras", "cursus", "lectus", "finibus", "rhoncus", "quam",
  "justo", "tincidunt", "urna", "et", "integer", "fringilla", "at", "odio",
  "consequat", "suspendisse", "interdum", "nulla", "gravida", "pellentesque",
  "pharetra", "velit", "elementum", "vulputate", "maximus", "nisi", "nunc",
  "nullam", "sapien", "posuere", "dictum", "praesent", "dapibus",
  "sollicitudin", "vivamus", "venenatis", "risus", "varius", "donec",
  "aliquam", "quisque", "pretium", "commodo", "nec", "vel", "condimentum",
  "nisl", "facilisis", "tristique", "euismod", "est", "fusce", "volutpat",
  "enim", "lacinia", "hendrerit", "accumsan", "mollis", "imperdiet", "tempor",
  "ullamcorper", "porttitor", "diam", "tellus", "vestibulum", "neque",
  "sodales", "class", "aptent", "taciti", "sociosqu", "ad", "litora",
  "torquent", "per", "conubia", "nostra", "inceptos", "himenaeos", "nam",
  "auctor", "phasellus", "eleifend", "ultricies", "dignissim", "rutrum"]

randomize()

let commitFile = joinPath(getCurrentDir(), "commit.txt")


# ...
func times [T](amount: int, f: () -> T): seq[T] =
  var a: seq[int] = @[]
  for i in 0..amount:
    a.add(0)

  return a.map((_) => f())

proc execCmd (cmd: string, panicOnError = true): (string, int) =
  let (output, exitCode) = execCmdEx(cmd)

  if panicOnError and exitCode > 0:
    let co = if len(output) > 0: format("; got:\n\n$1", output) else: ""
    let msg = format("command '$1' failed with return code $2", cmd, exitCode) & co

    raise newException(Defect, msg)

  return (output, exitCode)


# ...
proc getIpsumWord (): string =
  loremIpsum[rand(len(loremIpsum) - 1)]

proc getCommitBody (): string =
  var words: seq[string] = @[]
  words.add(getIpsumWord().capitalizeAscii())

  var c = 0
  let t = rand(32..64)
  for i in 1..t:
    let word = getIpsumWord()
    let length = len(word) + 1

    c += length
    if c < 60:
      words.add(word)
      continue

    words.add(word & "\n")
    c = 0

  return words.join(" ").split("\n").mapIt(it.strip()).join("\n") & "."

proc getCommitMessage (): string =
  var phrase = rand(3..9)
    .times(() => getIpsumWord() & (if rand(6) == 0: "," else: ""))
    .join(" ")

  if len(phrase) > 79:
    phrase = phrase[0..79]

  if phrase.endsWith(","):
    phrase = phrase[0..(len(phrase) - 2)]

  return phrase

proc runCommitCommand (withLongerMessage: bool): (string, string) =
  let msg = getCommitMessage()
  let fullMsg = if withLongerMessage: (msg & "\n\n" & getCommitBody()) else: msg

  commitFile.writeFile(fullMsg)
  discard execCmd("git commit --allow-empty --file " & commitFile)
  commitFile.removeFile()

  let (hash, _) = execCmd("git rev-parse HEAD")

  return (hash, msg)

proc commit (withLongerMessage: bool = false) =
  proc limit (t: string, v: int): string =
    if len(t) > v: t.replace("\n", " ").substring(0, v - 1) else: t

  let (hash, msg) = runCommitCommand(withLongerMessage)

  echo format(
    " * $1 $2 $3",
    toBrightCyanColor("COMMITED:"),
    toBoldStyle(format("[$1]", hash.substring(0, 6))),
    msg.limit(99)
  )

proc newSemanticTag (): string =
  let (t, _) = execCmd("git tag --sort=-creatordate")
  let tags = t.strip().split("\n")

  var lastTag = tags[0].strip()
  if lastTag == "":
      lastTag = "0.1.0"

  let s = parseVersion(lastTag)
  var
    major = s.major
    minor = s.minor
    patch = s.patch

  let chance = rand(1..20)

  if chance mod 5 == 0:
    major += 1
    minor = 0
    patch = 0
  elif chance mod 2 == 0:
    minor += 1
    patch = 0
  else:
    patch += 1

  let newVer = "v" & $newVersion(major, minor, patch)
  discard execCmd("git tag " & newVer)

  return newVer

# ...
proc main () =
  let commitAmount = rand(10..20)

  echo ""
  for i in 1..commitAmount:
    # commit with longer message on the last iteration
    commit(withLongerMessage = (i == commitAmount))

  let tag = newSemanticTag()

  echo ""
  successMessage(format(" > commited $1 times", commitAmount))
  successMessage(format(" > closed at tag $1", tag))

when isMainModule:
  main()
