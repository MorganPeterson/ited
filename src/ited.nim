## It Ed Hello Ed It Or

import osproc
import fidget
import typography/textboxes
from strutils import strip, splitWhitespace, startsWith, countLines, intToStr
from os import expandTilde

proc loadFont(name: string, pathOrUrl: string) =
  echo pathOrUrl
  loadFontAbsolute(name, pathOrUrl)

when isMainModule:
  loadFont("IBM Plex Sans", expandTilde("~/.local/bin/data/IBMPlexSans-Regular.ttf"))
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

  proc cmdHandler(view: var View) =
    ## try to execute as os program
    let cmd = view.commandValue.strip()

    # get out of here empty commands
    if cmd.len < 1:
      view.msg = "empty command"
      return

    try:
      let checkCmd = cmd.splitWhitespace(1)
      # if we are writing out to a file
      if checkCmd[0] == "w":
        if checkCmd.len > 1:
          var fn: string
          for c in 1..(checkCmd.len-1):
            fn = fn & checkCmd[c]
            writefile(fn, view.editorText)
        else:
          writefile(view.fileName, view.editorText)
        view.dirty = 0
        view.msg = "written"
      else:
        # if not writing then go to command line
        view.editorText = execProcess(cmd)
    except:
      view.msg = getCurrentExceptionMsg()
      discard
    finally:
      # meow! meow! King Friday! Save my file name.
      if cmd.startsWith("cat"):
        view.fileName = cmd[3..^1].strip(leading=true)
        view.msg = ""

  proc computeStatusLine(view: var View): string =
    ## create our string from the status
    let lines = view.editorText.countLines().intToStr() & "L | "
    let words = view.editorText.splitWhitespace().len.intToStr() & "W | "
    let chars = view.editorText.len.intToStr() & "C "
    let fn = "[ " & view.fileName & " ] "
    let dy = "[ " & view.dirty.intToStr() & " ] "
    result = dy & fn & lines & words & chars & " " & view.msg

  proc computeCmdWidths(view: var View, pWidth: float32) =
    ## compute our status line dimensions
    view.cmdWidth = pWidth / 2
    view.statusXPos = view.cmdWidth
    view.statusWidth = (view.cmdWidth)-2

  proc renderView(view: var View) =
    ## render our editor view
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
                
  var mainView = View(
    dirty: 0,
    msg: "",
    fileName: "",
    commandValue: "",
    editorText: "",
    statusValue: "")

  proc drawMain() =
    group "ited":
      box 0, 0, parent.box.w, parent.box.h
      fill "#FFFFFF"

      renderView(mainView)

  proc main() =
    startFidget(drawMain)

main()
