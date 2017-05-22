module.exports = {
   config: {
      // default font size in pixels for all tabs
      fontSize: 11,

      // font family with optional fallbacks
      fontFamily: 'Knack, Menlo, "DejaVu Sans Mono", '
       + 'Consolas, "Lucida Console", monospace',

      // terminal cursor background color and opacity (hex, rgb, hsl, hsv, hwb or cmyk)
      cursorColor: 'rgba(248,28,229,0.8)',

      // `BEAM` for |, `UNDERLINE` for _, `BLOCK` for █
      cursorShape: 'BLOCK',

      // set to true for blinking cursor
      cursorBlink: true,

      // border color (window, tabs)
      borderColor: '#FFCC66',

      // custom css to embed in the main window
      css: '',

      // custom css to embed in the terminal window
      termCSS: '',

      // set to `true` (without backticks) if you're using a Linux setup that doesn't show native menus
      // default: `false` on Linux, `true` on Windows (ignored on macOS)
      showHamburgerMenu: '',

      // set to `false` if you want to hide the minimize, maximize and close buttons
      // additionally, set to `'left'` if you want them on the left, like in Ubuntu
      // default: `true` on windows and Linux (ignored on macOS)
      showWindowControls: '',

      // custom padding (css format, i.e.: `top right bottom left`)
      padding: '12px 14px',

      base16: {
         scheme: 'eighties'
      },

      hyperStatusLine: {
        fontSize: 13,
      },

      hyperBorder: {
         borderWidth: '2px'
       , borderAngle: '120deg',
      },

      // the shell to run when spawning a new session (i.e. /usr/local/bin/fish)
      // if left empty, your system's login shell will be used by default
      // make sure to use a full path if the binary name doesn't work
      // (e.g `C:\\Windows\\System32\\bash.exe` instead of just `bash.exe`)
      // if you're using powershell, make sure to remove the `--login` below
      shell: '',

      // for setting shell arguments (i.e. for using interactive shellArgs: ['-i'])
      // by default ['--login'] will be used
      shellArgs: ['--login'],

      // for environment variables
      env: {},

      // set to false for no bell
      bell: 'SOUND',

      // if true, selected text will automatically be copied to the clipboard
      copyOnSelect: false

      // if true, on right click selected text will be copied or pasted if no
      // selection is present (true by default on Windows)
      // quickEdit: true

      // URL to custom bell
      // bellSoundURL: 'http://example.com/bell.mp3',

      // for advanced config flags please refer to https://hyper.is/#cfg
   },

   // a list of plugins to fetch and install from npm
   // format: [@org/]project[#version]
   // examples:
   //   `hyperpower`
   //   `@company/project`
   //   `project#1.0.1`
   plugins: [
      'hypercwd'
    , 'hyperterm-alternatescroll'
  //, 'hyperterm-focus-reporting'

  //, 'hyper-statusline'
  //, 'hyper-tabs-enhanced'

    , 'hypersixteen'
    , 'hyperborder'
    , 'hyperterm-bold-tab'
   ],

   // in development, you can create a directory under
   // `~/.hyper_plugins/local/` and include it here
   // to load it and avoid it being `npm install`ed
   localPlugins: []
}
