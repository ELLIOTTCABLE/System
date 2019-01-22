import * as Oni from "oni-api"

export const activate = (oni: Oni.Plugin.Api) => {
   console.log("config activated")

   // Input
   //
   // Add input bindings here:
   //
   oni.input.bind("<c-enter>", () => console.log("Control+Enter was pressed"))
   oni.input.bind("<m-s-n>", "oni.process.openWindow")

   //
   // Or remove the default bindings here by uncommenting the below line:
   //
   // oni.input.unbind("<c-p>")
}

export const deactivate = (oni: Oni.Plugin.Api) => {
   console.log("config deactivated")
}

export const configuration = {
   activate,

   "ui.colorscheme": "nord",

   "oni.loadInitVim": true,
   "oni.useDefaultConfig": false,

   //"oni.bookmarks": ["~/Documents"],

   "editor.fontSize": "14px",
   "editor.fontFamily": "IosevkaNerdFontComplete-Term",

   "editor.formatting.formatOnSwitchToNormalMode": true,

   // UI customizations
   "ui.animations.enabled": true,
   "ui.fontSmoothing": "auto",

   "commandline.mode": false,

   "tabs.height": "2em",
   "tabs.showIndex": true,

   "experimental.indentLines.enabled": true,

   // This is handled by a Vim plugin
   "autoClosingPairs.enabled": false,
}
