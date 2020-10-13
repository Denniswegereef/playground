import Stats from 'stats.js/build/stats.min'

export default {
  data () {
    return {
      gui: null,
      folder: null,
      stats: null
    }
  },

  beforeDestroy () {
    if (!this.isDevelopment()) return

    document.querySelector('#stats').remove()
    this.gui.destroy()
  },

  methods: {
    enableGUI () {
      const dat = require('dat.gui')
      this.gui = new dat.GUI({ autoPlace: true })
    },

    enableStats () {
      this.stats = new Stats()
      this.stats.showPanel(0)
      document.body.appendChild(this.stats.dom).id = 'stats'
    },

    isDevelopment () {
      return process.env.NODE_ENV !== 'production'
    }
  }
}
