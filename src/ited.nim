import osproc
import strutils
import sequtils
import fidget
import typography/textboxes

when isMainModule:
  loadFont("IBM Plex Sans", "IBMPlexSans-Regular.ttf")
  setTitle("It Ed. Hello.")

  type
    View = ref object of RootObj
      dirty: int32
      msg: string
      fileName: string
      commandValue: string
      editorText: string
      statusValue: string

  const AvailableCommands: array[3, string] = ["o", "w", "c"]

  proc cmdRightClickHandler(view: var View) =
    var cmd: string
    var arg: string

    let command = textBox.copy().strip()
    
    if command.len > 0:
      for word in split(command):
        if AvailableCommands.anyIt(it == word):
          cmd = word
        else:
          arg = word
      case cmd
        of AvailableCommands[0]:
          # open - read file
          try:
            view.editorText = readFile(arg)
            view.fileName = arg
            view.dirty = 0
            view.msg = "Open Success"
          except IOError:
            view.msg = "Open Failed"
            discard
        of AvailableCommands[1]:
          # write - write to file
          try:
            writeFile(arg, view.editorText)
            view.dirty = 0
            view.msg = "Write Success"
          except IOError:
            view.msg = "Write Failed"
            discard
        of AvailableCommands[2]:
          # close - remove text from buffer
          view.editorText = ""
          view.dirty = 0
          view.fileName = ""
        else:
          # try to execute as os program
          try:
            view.editorText = execProcess(command)
          except:
            discard

  proc computeStatusLine(view: var View): string =
    let lines = view.editorText.countLines().intToStr() & "L | "
    let words = view.editorText.count(' ').intToStr() & "W | "
    let chars = view.editorText.len.intToStr() & "C "
    let fn = "[ " & view.fileName & " ] "
    let dy = "[ " & view.dirty.intToStr() & " ] "
    result = dy & fn & lines & words & chars & " " & view.msg

  proc renderView(view: var View) =
    frame "view":
      box 0, 0, parent.box.w, parent.box.h

      rectangle "commandContainer":
        box 0, 0, parent.box.w, 19
        fill "#AEEEEE"
        strokeWeight 1
        stroke "#000000"

        text "command":
          box 2, 2, parent.box.w-2, 19
          fill "#000000"
          font "IBM Plex Sans", 14.0, 400.0, 15, hLeft, vTop
          highlightColor "#888ACA"
          multiline false
          binding view.commandValue
          onRightClick:
            view.cmdRightClickHandler()

        text "status":
          box parent.box.w / 2, 2, (parent.box.w / 2)-2, 19
          fill "#000000"
          font "IBM Plex Sans", 14.0, 400.0, 15, hLeft, vTop
          multiline false
          characters view.computeStatusLine()
          textAutoResize tsWidthAndHeight
          layoutAlign laStretch

      frame "workarea":
        box 1, 18, parent.box.w-2, parent.box.h-19

        rectangle "editorContainer":
          box 0, 0, parent.box.w, parent.box.h
          fill "#FFFFEA"
          scrollBars true
          
          text "editor":
            box 2, 2, parent.box.w-2, parent.box.h-2
            fill "#000000"
            font "IBM Plex Sans", 14.0, 400.0, 15, hLeft, vTop
            highlightColor "#888ACA"
            multiline true
            binding view.editorText
            onInput:
              inc view.dirty
        
  var mainView = View(commandValue: "", editorText: "")

  proc drawMain() =
    group "editor":
      box 0, 0, parent.box.w, parent.box.h
      fill "#FFFFFF"

      renderView(mainView)

  proc main() =
    startFidget(drawMain)

main()
