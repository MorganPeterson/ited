import fidget
import typography/textboxes

when isMainModule:
  loadFont("Inconsolata", "Inconsolata-Regular.ttf")
  setTitle("It Ed. Hello.")

  type
    View = ref object of RootObj
      commandValue: string

  proc cmdRightClickHandler() =
    let command = textBox.copy()
    if command.len > 0:
      echo command

  proc renderView(view: var View) =
    frame "view":
      box 0, 0, parent.box.w, parent.box.h
      itemSpacing 10

      rectangle "commandContainer":
        box 1, 1, parent.box.w-2, 22
        fill "#FFFFEA"
        strokeWeight 1
        stroke "#000000"

        text "command":
          font "Inconsolata", 13.0, 400.0, 20, hLeft, vTop
          box 2, 1, parent.box.w-2, 22
          fill "#000000"
          highlightColor "#AEEEEE"
          multiline false
          binding view.commandValue
          onRightClick:
            cmdRightClickHandler()

      rectangle "workarea":
        box 1, 22, parent.box.w-2, parent.box.h-23
        strokeWeight 1
        stroke "#000000"

  var mainView = View(commandValue: "")

  proc drawMain() =
    group "editor":
      box 0, 0, parent.box.w, parent.box.h
      fill "#FFFFFF"

      renderView(mainView)

startFidget(drawMain)
