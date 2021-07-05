## It Ed Hello Ed It Or

import parsecfg
import fidget
from strutils import strip, splitWhitespace, startsWith, countLines, intToStr, parseFloat
from os import expandTilde, fileExists
from osproc import execProcess
from typography/textboxes import typeCharacters

const DefaultTitle = "It Ed. Hello."
const DefaultTab = "    "
const DefaultRegularFont = "/usr/share/fonts/TTF/DejaVuSans.ttf"
const DefaultItalicFont = "/usr/share/fonts/TTF/DejaVuSans-Oblique.ttf"
const DefaultBoldFont = "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf"
const DefaultSizeFont = "14.0"
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
      dirty: int32
      msg: string
      fileName: string
      commandValue: string
      editorText: string
      statusValue: string

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
    dirty: 0,
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
      fill ItEdCfg.colors.secondary
      strokeWeight 1
      stroke ItEdCfg.colors.border

      text "command":
        box 2, 2, parent.box.w, 19
        fill ItEdCfg.colors.text
        font ItEdCfg.fonts.regular.name, ItEdCfg.fonts.size, 400.0, 15, hLeft, vTop
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
                else:
                  discard
  
  proc renderStatus(view: var View) =
    frame "status":
      box 0, parent.box.h-19, parent.box.w, 19
      fill ItEdCfg.colors.secondary
      strokeWeight 1
      stroke ItEdCfg.colors.border

      text "status":
        box 2, 2, parent.box.w, 19
        fill ItEdCfg.colors.text
        font ItEdCfg.fonts.regular.name, ItEdCfg.fonts.size, 400.0, 15, hLeft, vTop
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
        font ItEdCfg.fonts.regular.name, ItEdCfg.fonts.size, 400.0, 15, hLeft, vTop
        highlightColor ItEdCfg.colors.highlight
        multiline true
        binding view.editorText
        onInput:
          inc view.dirty
          for buttonIdx in 0..<buttonDown.len:
            let button = Button(buttonIdx)
            if buttonDown[button]:
              case button
                of Button.TAB:
                  textBox.typeCharacters(ItEdCfg.tab)
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
