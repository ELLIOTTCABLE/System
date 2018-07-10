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

      hyperStatusLine: {
         fontSize: 10

       , dirtyColor: '#B5BD68' // eighties-0E
       , aheadColor: '#04C975' // eighties-0B
      },

      hyperBorder: {
         borderColors: ['#8ABEB7', '#80B6AD']
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

    , 'hyper-aurora'
    , 'hyperterm-bold-tab'
    , 'hyperborder'

  //, 'hyperterm-focus-reporting'      // Pending brianc/hyperterm-focus-reporting#1

    , 'hyper-tabs-enhanced'
    , 'hyper-statusline'
   ]
}
