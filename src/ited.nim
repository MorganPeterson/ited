## It Ed Hello Ed It Or

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
      cmdWidth: float32
      statusWidth: float32
      statusXPos: float32
      editorText: string
      statusValue: string

  const AvailableCommands: array[3, string] = ["o", "w", "c"]

  proc cmdHandler(view: var View) =
    var cmd: string
    var arg: string

    let command = view.commandValue
    
    if command.len > 0:
      for word in split(command):
        if AvailableCommands.anyIt(it == word):
          cmd = word.strip()
        else:
          arg = word.strip()
      view.msg = ""
      case cmd
        of AvailableCommands[0]:
          # open - read file
          try:
            view.editorText = readFile(arg)
            view.fileName = arg
            view.dirty = 0
          except:
            view.msg = getCurrentExceptionMsg()
            discard
        of AvailableCommands[1]:
          # write - write to file
          try:
            if arg.len == 0:
              writeFile(view.fileName, view.editorText)
            else:
              writeFile(arg, view.editorText)
            view.dirty = 0
            view.msg = "Written"
          except IOError:
            view.msg = getCurrentExceptionMsg()
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
            view.msg = getCurrentExceptionMsg()
            discard

  proc computeStatusLine(view: var View): string =
    let lines = view.editorText.countLines().intToStr() & "L | "
    let words = view.editorText.count(' ').intToStr() & "W | "
    let chars = view.editorText.len.intToStr() & "C "
    let fn = "[ " & view.fileName & " ] "
    let dy = "[ " & view.dirty.intToStr() & " ] "
    result = dy & fn & lines & words & chars & " " & view.msg

  proc computeCmdWidths(view: var View, pWidth: float32) =
    view.cmdWidth = pWidth / 3
    view.statusXPos = view.cmdWidth
    view.statusWidth = (view.cmdWidth*2)-2

  proc renderView(view: var View) =
    view.computeCmdWidths(parent.box.w)
    
    frame "view":
      box 0, 0, parent.box.w, parent.box.h

      rectangle "commandContainer":
        box 0, 0, parent.box.w, 19
        fill "#AEEEEE"
        strokeWeight 1
        stroke "#000000"

        text "command":
          box 2, 2, view.cmdWidth, 19
          fill "#000000"
          font "IBM Plex Sans", 14.0, 400.0, 15, hLeft, vTop
          highlightColor "#888ACA"
          multiline false
          binding view.commandValue
          onInput:
            for buttonIdx in 0..<buttonDown.len:
              let button = Button(buttonIdx)
              if buttonDown[button]:
                case button
                  of Button.ENTER:
                    view.cmdHandler()
                  else:
                    discard

        text "status":
          box view.statusXPos, 2, view.statusWidth, 19
          fill "#000000"
          font "IBM Plex Sans", 14.0, 400.0, 15, hLeft, vTop
          multiline false
          characters view.computeStatusLine()
          textAutoResize tsHeight
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
              for buttonIdx in 0..<buttonDown.len:
                let button = Button(buttonIdx)
                if buttonDown[button]:
                  case button
                    of Button.TAB:
                      textBox.typeCharacters("  ")
                    else:
                      discard
                
  var mainView = View(commandValue: "", editorText: "")

  proc drawMain() =
    group "editor":
      box 0, 0, parent.box.w, parent.box.h
      fill "#FFFFFF"

      renderView(mainView)

  proc main() =
    startFidget(drawMain)

main()
