const Stats = require('stats.js/build/stats.min.js')

export default {
  data () {
    return {
      gui: null,
      folder: null,
      stats: null,
      mouse: {
        x: 0.0,
        y: 0.0,
        normalize: {
          x: 0.0,
          y: 0.0
        }
      }
    }
  },

  mounted () {
    this._setupEventListenersBase()
  },

  beforeDestroy () {
    // if (!this.isDevelopment()) return

    document.querySelector('#stats').remove()
    this.gui.destroy()

    window.removeEventListener('mousemove', this._updateMouseValuesBase)
  },

  methods: {
    _setupEventListenersBase () {
      this._mouseMoveHandlerBase()
    },

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
    },

    _updateMouseValuesBase (event) {
      // normalized device cordinates
      const { clientX, clientY } = event

      const xNormalized = (clientX / window.innerWidth) * 2 - 1
      const yNormalized = (clientY / window.innerHeight) * 2 - 1

      this.mouse = {
        x: clientX,
        y: clientY,
        normalize: {
          x: xNormalized,
          y: yNormalized
        },
        ...event
      }
    },

    // Handlers
    _mouseMoveHandlerBase () {
      window.addEventListener('mousemove', this._updateMouseValuesBase)
    }
  }
}
