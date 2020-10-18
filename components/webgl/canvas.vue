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
    window.removeEventListener('resize', this.$data.setCanvasFunction)
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

    /*
    Handlers
    */
    _resizeHandler () {
      this.$data.setCanvasFunction = debounce(this._setCanvasDimensions.bind(this), 250)
      window.addEventListener('resize', this.$data.setCanvasFunction)
    }
  }
}
</script>

<style lang="scss" scoped>
.canvas {
  position: fixed;
  top: 0;
  left: 0;

  width: 100%;
  height: 100vh;

  pointer-events: none;
}
</style>
