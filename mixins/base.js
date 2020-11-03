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
        previous: { x: 0.0, y: 0.0 },
        normalize: { x: 0.0, y: 0.0 },
        uv: { x: 0.0, y: 0.0 }
      },
      mousePrevious: { x: 0, y: 0.0 },
      mouseSpeed: 0.0
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

    updateMouseSpeed () {
      const movementX = Math.abs(this.mouse.x - this.mousePrevious.x)
      const movementY = Math.abs(this.mouse.y - this.mousePrevious.y)

      this.mouseSpeed = Math.sqrt(movementX * movementX + movementY * movementY) / 50

      this.mousePrevious.x = this.mouse.x
      this.mousePrevious.y = this.mouse.y
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
        uv: {
          x: clientX / window.innerWidth,
          y: 1 - clientY / window.innerHeight
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
