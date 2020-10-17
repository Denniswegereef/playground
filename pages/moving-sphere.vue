<template>
  <section class="container">
    <Canvas ref="canvas" />
  </section>
</template>

<script>
import debounce from 'lodash.debounce'

import base from '~/mixins/base.js'
import Canvas from '~/components/webgl/canvas.vue'
import fragmentShader from '~/components/webgl/moving-sphere/fragment.glsl'
import vertexShader from '~/components/webgl/moving-sphere/vertex.glsl'

import lerp from '~/helpers/lerp'

const THREE = require('three')
const { gsap } = require('gsap')

export default {
  components: {
    Canvas
  },

  mixins: [base],

  data () {
    return {
      scene: new THREE.Scene(),
      clock: new THREE.Clock(),
      camera: null,
      renderer: null,
      gui: null,
      window: {
        height: 0,
        width: 0
      },
      uniforms: {
        u_time: { value: 0.0 },
        u_resolution: { value: { x: 0.0, y: 0.0 } },
        u_color_one: { type: 'vec3', value: new THREE.Color('#75dddd') },
        u_color_two: { type: 'vec3', value: new THREE.Color('#aa3e98') },
        u_noise_frequency: { type: 'float', value: 3.5 },
        u_noise_amplitude: { type: 'float', value: 0.15 }
      },
      newValueX: 0.0,
      newValueY: 0.0
    }
  },

  mounted () {
    this.enableStats()

    this._setupRenderer()
    this._setupCamera()

    this._setupScreenDimensions()
    this._setUpEventListeners()

    this._createScene()

    this.enableGUI()
    this._setupGUI()

    console.log(this.window.height / this.window.width)
  },

  beforeDestroy () {
    gsap.ticker.remove(this._renderScene)
    window.removeEventListener('resize', this.$data.resize)
    window.removeEventListener('mousemove', this._updateMousePositions)
  },

  methods: {
    // SETUP

    _setupRenderer () {
      this.renderer = new THREE.WebGLRenderer({ canvas: this.$refs.canvas.$el, alpha: true })
      this.renderer.setClearColor(0x32A8A8, 0)
    },

    _setupCamera () {
      this.camera = new THREE.OrthographicCamera(1, -1, 1, -1, 0.1, 10)
      this.camera.position.z = 1
    },

    _setupScreenDimensions () {
      this.window.width = window.innerWidth
      this.window.height = window.innerHeight

      this.uniforms.u_resolution.value.x = this.window.width
      this.uniforms.u_resolution.value.y = this.window.height

      this.renderer.setSize(this.window.width, this.window.height)
      this.renderer.setPixelRatio(window.devicePixelRatio)

      this.camera.aspect = this.window.width / this.window.height
      this.camera.updateProjectionMatrix()

      // if (this.plane) this.plane.scale.set(this.window.height / this.window.width, 1)
    },

    _setUpEventListeners () {
      this._mouseMoveHandler()
      this._resizeHandler()
      this._tickHandler()
    },

    // SCENE
    _createPlaneGeometry () {
      const geometry = new THREE.PlaneBufferGeometry(this.window.height / this.window.width, 1, 20, 20)

      const shaderMaterial = new THREE.ShaderMaterial({
        uniforms: this.uniforms,
        vertexShader,
        fragmentShader,
        side: THREE.DoubleSide
      })

      return new THREE.Mesh(geometry, shaderMaterial)
    },

    _createScene () {
      // const planePivot = new THREE.Object3D()

      this.plane = this._createPlaneGeometry()
      this.scene.add(this.plane)

      this.plane.rotation.x = 0.2
      this.plane.rotation.y = 0.2
    },

    _renderScene () {
      this.stats.begin()

      this.uniforms.u_time.value = this.clock.getElapsedTime()

      this._updateValues()
      this.renderer.render(this.scene, this.camera)

      this.stats.end()
    },

    _updateValues () {
      this.plane.position.x = lerp(this.plane.position.x, this.newValueX, 0.05)
      this.plane.position.y = lerp(this.plane.position.y, this.newValueY, 0.05)
    },

    _updateMousePositions () {
      this.newValueX = this.mouse.normalize.x * -1
      this.newValueY = this.mouse.normalize.y * -1
    },

    _setupGUI () {
      this.gui.add(this.uniforms.u_noise_frequency, 'value', 0, 15).name('nFrequency').step(0.05)
      this.gui.add(this.uniforms.u_noise_amplitude, 'value', 0, 1.5).name('nAmplitude').step(0.05)
    },

    // HANDLERS
    _tickHandler () {
      gsap.ticker.add(this._renderScene)
    },

    _mouseMoveHandler () {
      window.addEventListener('mousemove', this._updateMousePositions)
    },

    _resizeHandler () {
      this.$data.resize = debounce(this._setupScreenDimensions.bind(this), 250)
      window.addEventListener('resize', this.$data.resize)
    }
  }
}
</script>

<style lang="scss" scoped>
.container {
  width: 100%;
  height: 100vh;

  background: #000;
}
</style>
