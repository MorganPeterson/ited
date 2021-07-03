import strutils
import sequtils
import fidget
import typography/textboxes

when isMainModule:
  loadFont("Inconsolata", "Inconsolata-Regular.ttf")
  setTitle("It Ed. Hello.")

  type
    View = ref object of RootObj
      commandValue: string
    Commands = array[2, string]

  var editorText: string = ""
  let AvailableCommands: Commands = ["open", "write"]

  proc readAFile(fn: string): string =
    result = readFile(fn)

  proc cmdRightClickHandler() =
    var cmd: string
    var arg: array[1, string]

    let command = textBox.cut()
    
    if command.len > 0:
      for word in split(command):
        if AvailableCommands.anyIt(it == word):
          cmd = word
        else:
          arg[0] = word
      if cmd == "open":
        try:
          editorText = readAFile(arg[0])
        except IOError:
          echo "IO Error"
      elif cmd == "write":
        writeFile(arg[0], editorText)

  proc renderView(view: var View) =
    frame "view":
      box 0, 0, parent.box.w, parent.box.h
      itemSpacing 10

      rectangle "commandContainer":
        box 1, 1, parent.box.w-2, 19
        fill "#FFFFEA"
        strokeWeight 1
        stroke "#000000"

        text "command":
          font "Inconsolata", 13.0, 400.0, 17, hLeft, vTop
          box 2, 1, parent.box.w-2, 19
          fill "#000000"
          highlightColor "#AEEEEE"
          multiline false
          binding view.commandValue
          onRightClick:
            cmdRightClickHandler()

      rectangle "workarea":
        box 1, 19, parent.box.w-2, parent.box.h-20
        strokeWeight 1
        stroke "#000000"
        fill "#FFFFEA"

        text "editor":
          font "Inconsolata", 13.0, 400.0, 13, hLeft, vTop
          box 2, 2, parent.box.w, parent.box.h
          fill "#000000"
          highlightColor "#AEEEEE"
          multiline true
          binding editorText
  
  var mainView = View(commandValue: "")

  proc drawMain() =
    group "editor":
      box 0, 0, parent.box.w, parent.box.h
      fill "#FFFFFF"

      renderView(mainView)

  proc main() =
    startFidget(drawMain)

main()
