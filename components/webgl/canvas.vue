<template>
  <canvas ref="canvas" class="canvas" />
</template>

<script>
import debounce from 'lodash.debounce'

export default {
  data () {
    return {
      drawCanvas: {
        color: '#FF0000',
        show: false
      }
    }
  },

  mounted () {
    this._setupEventListeners()
    this._setCanvasDimensions()
    if (this.drawCanvas.show) this._colorCanvas()
  },

  beforeDestroy () {
    window.removeEventListener('resize', this.setCanvasFunction)
  },

  methods: {
    _setupEventListeners () {
      this._resizeHandler()
    },

    _colorCanvas () {
      const context = this.$refs.canvas.getContext('2d')
      context.clearRect(0, 0, this.$refs.canvas.width, this.$refs.canvas.height)
      context.fillStyle = this.drawCanvas.color
      context.fillRect(0, 0, this.$refs.canvas.width, this.$refs.canvas.height)
    },

    _setCanvasDimensions () {
      this.$refs.canvas.width = window.innerWidth
      this.$refs.canvas.height = window.innerHeight

      if (this.drawCanvas.show) this._colorCanvas()
    },

    _canvasResize () {
      this._setCanvasDimensions()
      this.$emit('canvasResizeHandler')
    },

    /*
    Handlers
    */
    _resizeHandler () {
      this.setCanvasFunction = debounce(this._canvasResize.bind(this), 250)
      window.addEventListener('resize', this.setCanvasFunction)
    }
  }
}
</script>

<style lang="scss" scoped>
.canvas {
  position: absolute;
  top: 0;
  left: 0;

  width: 100%;
  height: 100vh;

  // pointer-events: none;
}
</style>
