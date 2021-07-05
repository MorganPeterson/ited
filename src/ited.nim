## It Ed Hello Ed It Or

import parsecfg
import fidget
from strutils import strip, splitWhitespace, startsWith, countLines, intToStr, parseFloat, split, find, rfind
from os import expandTilde, fileExists
from osproc import execProcess
from typography/textboxes import typeCharacters, setCursor, adjustScroll

const DefaultTitle = "It Ed. Hello."
const DefaultTab = "    "
const DefaultRegularFont = "/usr/share/fonts/TTF/DejaVuSans.ttf"
const DefaultItalicFont = "/usr/share/fonts/TTF/DejaVuSans-Oblique.ttf"
const DefaultBoldFont = "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf"
const DefaultSizeFont = "14.0"
const DefaultWeightFont = 400
const DefaultHeightFont = 16
const DefaultColorPrimary = "#FFFFEA"
const DefaultColorSecondary = "#AEEEEE"
const DefaultColorHighlight = "#888ACA"
const DefaultColorText = "#000000"
const DefaultColorBorder = "#000000"
const DefaultConfigDirEtc = "/usr/local/etc/ited/ited.cfg"
const DefaultConfigDirHome = expandTilde("~/.config/ited/ited.cfg")

when isMainModule:
  type
    View = ref object of RootObj
      dirty: bool
      msg: string
      cursorPos: int
      fileName: string
      commandValue: string
      editorText: string
      statusValue: string
      editorNode: Node
      commandNode: Node

    Colors = ref object of RootObj
      primary: string
      secondary: string
      highlight: string
      text: string
      border: string

    Font = ref object of RootObj
      name: string
      url: string

    Fonts = ref object of RootObj
      regular: Font
      italic: Font
      bold: Font
      size: float32

    Config = ref object of RootObj
      title: string
      tab: string
      fonts: Fonts
      colors: Colors

  var mainView = View(
    dirty: false,
    cursorPos: 0,
    msg: "",
    fileName: "",
    commandValue: "",
    editorText: "",
    statusValue: "")

  proc loadCfg(): Config =
    var cfg: parsecfg.Config

    if fileExists(DefaultConfigDirHome):
      cfg = loadConfig(DefaultConfigDirHome)
    elif fileExists(DefaultConfigDirEtc):
      cfg = loadConfig(DefaultConfigDirEtc)
    else:
      cfg = newConfig()

    result = Config(
      title: getSectionValue(cfg, "Common", "Title", DefaultTitle),
      tab: getSectionValue(cfg, "Common", "Tab", DefaultTab),
      fonts: Fonts(
        regular: Font(
          name: "Regular",
          url: getSectionValue(cfg, "Font", "Regular", DefaultRegularFont)
        ),
        italic: Font(
          name: "Italic",
          url: getSectionValue(cfg, "Font", "Italic", DefaultItalicFont)
        ),
        bold: Font(
          name: "Bold",
          url: getSectionValue(cfg, "Font", "Bold", DefaultBoldFont)
        ),
        size: parseFloat(getSectionValue(cfg, "Font", "Size", DefaultSizeFont))
      ),
      colors: Colors(
        primary: getSectionValue(cfg, "Colors", "Primary", DefaultColorPrimary),
        secondary: getSectionValue(cfg, "Colors", "Secondary", DefaultColorSecondary),
        highlight: getSectionValue(cfg, "Colors", "Highlight", DefaultColorHighlight),
        text: getSectionValue(cfg, "Colors", "Text", DefaultColorText),
        border: getSectionValue(cfg, "Colors", "Border", DefaultColorBorder)
      )
    )

  let ItEdCfg = loadCfg()

  loadFontAbsolute(ItEdCfg.fonts.regular.name, ItEdCfg.fonts.regular.url)
  loadFontAbsolute(ItEdCfg.fonts.italic.name, ItEdCfg.fonts.italic.url)
  loadFontAbsolute(ItEdCfg.fonts.bold.name, ItEdCfg.fonts.bold.url)
  setTitle(ItEdCfg.title)

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
        view.dirty = false
        view.msg = "written"
      elif checkCmd[0] == "o":
        if checkCmd.len > 1:
          var fn: string
          for c in 1..(checkCmd.len-1):
            fn = fn & checkCmd[c]
          view.editorText = readfile(fn)
          view.fileName = fn
        view.dirty = false
        view.msg = ""
      elif checkCmd[0] == "/":
        var searchString: string
        for c in 1..(checkCmd.len-1):
          searchString = searchString & checkCmd[c]
        view.cursorPos = view.editorText.find(searchString, start=Natural(view.cursorPos))
        keyboard.focus(view.editorNode)
        textBox.setCursor(view.cursorPos)
        textBox.selector = view.cursorPos + searchString.len
        textBox.adjustScroll()
      elif checkCmd[0] == "?":
        var searchString: string
        for c in 1..(checkCmd.len-1):
          searchString = searchString & checkCmd[c]
        view.cursorPos = view.editorText.rfind(searchString, last=Natural(view.cursorPos))
        keyboard.focus(view.editorNode)
        textBox.setCursor(view.cursorPos)
        textBox.selector = view.cursorPos + searchString.len
        textBox.adjustScroll()
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
      view.dirty = false

  proc computeStatusLine(view: var View): string =
    ## create our string from the status
    var currentLine: string = "1"
    var currentChar: string = "1"
    var isDirty = ""

    if view.editorText.len > 0:
      let lines = view.editorText[0..(view.cursorPos-1)].split("\n")
      currentLine = lines.len.intToStr()
      currentChar = lines[^1].len.intToStr()
    if view.dirty:
      isDirty = "[+]"
    let fn = " " & view.fileName & " "
    result = isDirty & fn & currentLine & ":" & currentChar & " " & view.msg

  proc renderCmd(view: var View) =
    frame "command":
      box 0, 0, parent.box.w, 19
      fill ItEdCfg.colors.secondary
      strokeWeight 1
      stroke ItEdCfg.colors.border

      text "commandText":
        box 2, 2, parent.box.w, 19
        fill ItEdCfg.colors.text
        font ItEdCfg.fonts.regular.name, ItEdCfg.fonts.size, DefaultWeightFont, DefaultHeightFont, hLeft, vTop
        highlightColor ItEdCfg.colors.highlight
        multiline false
        binding view.commandValue
        onInput:
          for buttonIdx in 0..<buttonDown.len:
            let button = Button(buttonIdx)
            if buttonDown[button]:
              case button
                of Button.ENTER:
                  view.cmdHandler()
                of Button.F1:
                  # change focus to editorText
                  keyboard.focus(view.editorNode)
                  textBox.setCursor(view.cursorPos)
                  textBox.adjustScroll()
                else:
                  discard
  
  proc renderStatus(view: var View) =
    frame "status":
      box 0, parent.box.h-19, parent.box.w, 19
      fill ItEdCfg.colors.secondary
      strokeWeight 1
      stroke ItEdCfg.colors.border

      text "statusText":
        box 2, 2, parent.box.w, 19
        fill ItEdCfg.colors.text
        font ItEdCfg.fonts.regular.name, ItEdCfg.fonts.size, DefaultWeightFont, DefaultHeightFont, hLeft, vTop
        multiline false
        characters view.computeStatusLine()
        textAutoResize tsHeight
        layoutAlign laStretch

  proc renderEditor(view: var View) =
    frame "editor":
      box 1, 18, parent.box.w-2, parent.box.h-38
      fill ItEdCfg.colors.primary
      clipContent true

      text "editorText":
        box 2, 2, parent.box.w-4, parent.box.h-2
        fill ItEdCfg.colors.text
        font ItEdCfg.fonts.regular.name, ItEdCfg.fonts.size, DefaultWeightFont, DefaultHeightFont, hLeft, vTop
        highlightColor ItEdCfg.colors.highlight
        multiline true
        binding view.editorText
        onInput:
          for buttonIdx in 0..<buttonDown.len:
            let button = Button(buttonIdx)
            if buttonDown[button]:
              view.cursorPos = textBox.cursor
              case button
                of Button.TAB:
                  textBox.typeCharacters(ItEdCfg.tab)
                of Button.F2:
                  # change focus to commandText
                  keyboard.focus(view.commandNode)
                else:
                  discard

              if button >= Button.SPACE and button <= Button.GRAVE_ACCENT:
                view.dirty = true
              elif button >= Button.ENTER and button <= Button.BACKSPACE:
                view.dirty = true
              elif button == Button.DELETE:
                view.dirty = true
              elif button >= Button.KP_0 and button < Button.KP_EQUAL:
                view.dirty = true

  proc renderView(view: var View) =
    ## render our editor view
    component "ited":
      box root.box
      fill "#FFFFFF"

      view.renderCmd()
      view.renderEditor()
      view.renderStatus()
      view.commandNode = root.nodes[0].nodes[0].nodes[0]
      view.editorNode = root.nodes[0].nodes[1].nodes[0]
                
  proc drawMain() =
    renderView(mainView)

  proc main() =
    startFidget(drawMain)

main()
