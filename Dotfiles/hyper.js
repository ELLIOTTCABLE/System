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

      // custom css to embed in the main window
      css: '',

      // custom css to embed in the terminal window
      termCSS: '',

      base16: {
         scheme: 'eighties'
      },

      hyperStatusLine: {
         fontSize: 10

       , dirtyColor: '#cc99cc' // eighties-0E
       , aheadColor: '##99cc99' // eighties-0B
      },

      hyperBorder: {
         borderColors: ['#99cc99', '#66cccc']
       , borderWidth: '3px'
       , borderAngle: '120deg'
       , animate: true
      },

      hyperTabs: {
         trafficButtons: true
       , tabIconsColored: true
      }
   },

   plugins: [
      'hypercwd'

    , 'hypersixteen'
    , 'hyperterm-bold-tab'
    , 'hyperborder'

  //, 'hyperterm-alternatescroll'      // Pending lkzhao/hyperterm-alternatescroll#11
  //, 'hyperterm-focus-reporting'      // Pending brianc/hyperterm-focus-reporting#1

    , 'hyper-tabs-enhanced'
    , 'hyper-statusline'
   ]
}