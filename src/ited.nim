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
      editorText: string
    Commands = array[3, string]

  let AvailableCommands: Commands = ["open", "write", "close"]

  proc cmdRightClickHandler(view: var View) =
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
          view.editorText = readFile(arg[0])
          view.commandValue = ""
        except IOError:
          view.commandValue = "IO Error"
      elif cmd == "write":
        try:
          writeFile(arg[0], view.editorText)
          view.commandValue = ""
        except IOError:
          view.commandValue = "IO Error"
      elif cmd == "close":
          view.commandValue = ""
          view.editorText = ""

  proc renderView(view: var View) =
    frame "view":
      box 0, 0, parent.box.w, parent.box.h

      rectangle "commandContainer":
        box 1, 0, parent.box.w-2, 19
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
            view.cmdRightClickHandler()

      frame "workarea":
        box 1, 18, parent.box.w-2, parent.box.h-19

        rectangle "editorContainer":
          box 0, 0, parent.box.w, parent.box.h
          strokeWeight 1
          stroke "#000000"
          fill "#FFFFEA"

          text "editor":
            font "Inconsolata", 13.0, 400.0, 13, hLeft, vTop
            box 2, 2, parent.box.w, parent.box.h
            fill "#000000"
            highlightColor "#AEEEEE"
            multiline true
            binding view.editorText
  
  var mainView = View(commandValue: "", editorText: "")

  proc drawMain() =
    group "editor":
      box 0, 0, parent.box.w, parent.box.h
      fill "#FFFFFF"

      renderView(mainView)

  proc main() =
    startFidget(drawMain)

main()
