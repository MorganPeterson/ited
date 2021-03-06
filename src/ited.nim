## It Ed or Hello.
## Write something for fun and profit.
##

import parsecfg
import docopt
import fidget
from strutils import strip, splitWhitespace, startsWith, countLines, intToStr, parseFloat, split, find, rfind
from os import expandTilde, fileExists
from osproc import execProcess
from typography/textboxes import typeCharacters, setCursor, adjustScroll, cut, text
from fidget/opengl/base import exit

## default values to keep you safe
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
      ## global variable object
      dirty: bool
      msg: string
      cursorPos: int
      fileName: string
      commandValue: string
      editorText: string
      statusValue: string
      editorNode: Node
      statusNode: Node

    Colors = ref object of RootObj
      ## configurable colors for the app
      primary: string
      secondary: string
      highlight: string
      text: string
      border: string

    Font = ref object of RootObj
      ## font name and location in local file system
      name: string
      url: string

    Fonts = ref object of RootObj
      ## All of our fonts and their size
      regular: Font
      italic: Font
      bold: Font
      size: float32

    Config = ref object of RootObj
      ## holds our configuration file
      title: string
      tab: string
      fonts: Fonts
      colors: Colors

  # initialize the main view
  var mainView = View(
    dirty: false,
    cursorPos: 0,
    msg: "",
    fileName: "",
    commandValue: "",
    editorText: "",
    statusValue: "")

  proc loadCfg(): Config =
    ## load configuration file function
    var cfg: parsecfg.Config

    # check if local file or system file exists and load it if it does
    if fileExists(DefaultConfigDirHome):
      cfg = loadConfig(DefaultConfigDirHome)
    elif fileExists(DefaultConfigDirEtc):
      cfg = loadConfig(DefaultConfigDirEtc)
    else:
      cfg = newConfig()

    # final configuration
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

  # load the config if there is one
  let ItEdCfg = loadCfg()

  # now that we have the configuration we can load the fonts and set the title
  loadFontAbsolute(ItEdCfg.fonts.regular.name, ItEdCfg.fonts.regular.url)
  loadFontAbsolute(ItEdCfg.fonts.italic.name, ItEdCfg.fonts.italic.url)
  loadFontAbsolute(ItEdCfg.fonts.bold.name, ItEdCfg.fonts.bold.url)
  setTitle(ItEdCfg.title)

  proc cmdHandler(view: var View) =
    ## handles all the commands sent from the user in the command line
    let cmd = textBox.cut()
    view.editorText = textBox.text()

    # get out of here empty commands
    if cmd.len < 1:
      view.msg = "empty command"
      return

    try:
      let checkCmd = cmd.splitWhitespace(1)
      case checkCmd[0]
        of "w":
          # open a file for writing
          if checkCmd.len > 1:
            var fn: string
            for c in 1..(checkCmd.len-1):
              fn = fn & checkCmd[c]
            writefile(fn, view.editorText)
          else:
            writefile(view.fileName, view.editorText)
          view.dirty = false
          view.msg = "written"
        of "o":
          # open a file for reading
          if checkCmd.len > 1:
            var fn: string
            for c in 1..(checkCmd.len-1):
              fn = fn & checkCmd[c]
            view.editorText = readfile(fn)
            view.fileName = fn
            view.cursorPos = 1
          view.dirty = false
          view.msg = ""
          keyboard.focus(view.statusNode)
        of "/", "?":
          # search one way or the other but never both
          var searchString: string
          for c in 1..(checkCmd.len-1):
            searchString = searchString & checkCmd[c]
          if checkCmd[0] == "/":
            view.cursorPos = view.editorText.find(searchString, start=Natural(view.cursorPos))
            view.cursorPos = view.cursorPos - cmd.len
          elif checkCmd[0] == "?":
            view.cursorPos = view.cursorPos - cmd.len
            view.cursorPos = view.editorText.rfind(searchString, last=Natural(view.cursorPos))
          textBox.setCursor(view.cursorPos)
          textBox.selector = view.cursorPos + searchString.len
          textBox.adjustScroll()
        of "q":
          exit()
          quit()
        else:
          # if not writing then go to command line
          view.editorText = execProcess(cmd)
          view.cursorPos = 1
          keyboard.focus(view.statusNode)
    except:
      view.msg = getCurrentExceptionMsg()
      discard
    finally:
      # meow! meow! King Friday! Save my file name.
      if cmd.startsWith("cat"):
        view.fileName = cmd[3..^1].strip(leading=true)
        view.msg = ""
        view.cursorPos = 1
      view.dirty = false

  proc computeStatusLine(view: var View): string =
    ## create our string for the status line
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
      box 1, 1, parent.box.w-2, parent.box.h-20
      fill ItEdCfg.colors.primary
      clipContent true # get our scolling in order

      text "editorText":
        box 2, 2, parent.box.w-4, parent.box.h-2
        fill ItEdCfg.colors.text
        font ItEdCfg.fonts.regular.name, ItEdCfg.fonts.size, DefaultWeightFont, DefaultHeightFont, hLeft, vTop
        highlightColor ItEdCfg.colors.highlight
        multiline true
        binding view.editorText
        onRightClick:
          # click the command, padre!
          view.cmdHandler()
        onInput:
          # looking for them custom buttons
          for buttonIdx in 0..<buttonDown.len:
            let button = Button(buttonIdx)
            if buttonDown[button]:
              view.cursorPos = textBox.cursor
              # check if the user dirtied the text
              case button
                of Button.SPACE..Button.GRAVE_ACCENT, Button.ENTER..Button.BACKSPACE, Button.DELETE, Button.KP_0..Button.KP_EQUAL:
                  view.dirty = true
                else:
                  discard

  proc renderView(view: var View) =
    ## render our editor view
    component "ited":
      box root.box
      fill "#FFFFFF"

      view.renderEditor()
      view.renderStatus()
      view.editorNode = root.nodes[0].nodes[0].nodes[0]
      view.statusNode = root.nodes[0].nodes[1].nodes[0]
                
  proc drawMain() =
    renderView(mainView)

  proc main() =
    let doc = """
It Ed.

Usage:
  ited <file>

Options:
  -h --help   Show this screen.
  --version   Show version.
"""
    let args = docopt(doc, version="ited 0.2.1")

    if args["<file>"]:
      let f = $args["<file>"]
      try:
        if os.fileExists(f):
          mainView.editorText = readfile(f)
          mainView.fileName = f
          mainView.cursorPos = 1
        elif os.dirExists(f):
          mainView.editorText = execProcess("ls " & f)
        else:
          return 
      except:
        let e = getCurrentException()
        let msg = getCurrentExceptionMsg()
        echo repr(e) & ": " & msg
        return

    startFidget(drawMain)

main()
