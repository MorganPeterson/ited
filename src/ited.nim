## It Ed Hello Ed It Or

import fidget
from strutils import strip, splitWhitespace, startsWith, countLines, intToStr
from osproc import execProcess
from typography/textboxes import typeCharacters

when isMainModule:
  loadFontAbsolute("IBM Plex Sans", "/usr/share/fonts/TTF/IBMPlexSans-Regular.ttf")
  setTitle("It Ed. Hello.")

  type
    View = ref object of RootObj
      dirty: int32
      msg: string
      fileName: string
      commandValue: string
      editorText: string
      statusValue: string
  
  var mainView = View(
    dirty: 0,
    msg: "",
    fileName: "",
    commandValue: "",
    editorText: "",
    statusValue: "")

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

  proc renderCmd(view: var View) =
    frame "command":
      box 0, 0, parent.box.w, 19
      fill "#AEEEEE"
      strokeWeight 1
      stroke "#000000"

      text "command":
        box 2, 2, parent.box.w, 19
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
  
  proc renderStatus(view: var View) =
    frame "status":
      box 0, parent.box.h-19, parent.box.w, 19
      fill "#AEEEEE"
      strokeWeight 1
      stroke "#000000"

      text "status":
        box 2, 2, parent.box.w, 19
        fill "#000000"
        font "IBM Plex Sans", 14.0, 400.0, 15, hLeft, vTop
        multiline false
        characters view.computeStatusLine()
        textAutoResize tsHeight
        layoutAlign laStretch

  proc renderEditor(view: var View) =
    frame "editor":
      box 1, 18, parent.box.w-2, parent.box.h-38
      fill "#FFFFEA"
      clipContent true

      text "editorText":
        box 2, 2, parent.box.w-4, parent.box.h-2
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

  proc renderView(view: var View) =
    ## render our editor view
    component "ited":
      box root.box
      fill "#FFFFFF"

      view.renderCmd()
      view.renderEditor()
      view.renderStatus()
                
  proc drawMain() =
    renderView(mainView)

  proc main() =
    startFidget(drawMain)

main()
