module.exports = {
   config: {
      windowSize: [960, 540], // aiming for 135 columns wide, 16:9 ratio

      // font family with optional fallbacks
      fontFamily: '"Input Nerd Font", Knack, Menlo, "DejaVu Sans Mono", '
       + 'Consolas, "Lucida Console", monospace',

      // terminal cursor background color and opacity (hex, rgb, hsl, hsv, hwb or cmyk)
      cursorColor: 'rgba(248,28,229,0.8)',

      // set to true for blinking cursor
      cursorBlink: true,

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

      hyperTabs: {
         trafficButtons: true
       , tabIconsColored: true
      }
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
  //, 'hyperterm-focus-reporting'      // Pending brianc/hyperterm-focus-reporting#1

    , 'hyper-tabs-enhanced'
    , 'hyper-statusline'

    , 'hypersixteen'
    , 'hyperborder'
    , 'hyperterm-bold-tab'
   ]
}
