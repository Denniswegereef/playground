<template>
  <section class="container">
    <Canvas ref="canvas" />
  </section>
</template>

<script>
import debounce from 'lodash.debounce'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls'

import base from '~/mixins/base.js'
import Canvas from '~/components/webgl/canvas.vue'
import fragmentShader from '~/components/webgl/bmfont/fragment.glsl'
import vertexShader from '~/components/webgl/bmfont/vertex.glsl'

const THREE = require('three')
const { gsap } = require('gsap')
const loadFont = require('load-bmfont')
const createGeometry = require('~/plugins/three-bmfont-text/index')
// const MSDFShader = require('~/plugins/three-bmfont-text/shaders/msdf')

const FONT_PATH = {
  FNT: '/fonts/canela/CanelaText-Regular.fnt',
  PNG: '/fonts/canela/CanelaText-Regular.png'
}

export default {
  components: {
    Canvas
  },

  mixins: [base],

  data () {
    return {
      scene: new THREE.Scene(),
      clock: new THREE.Clock(),
      loader: new THREE.TextureLoader(),
      camera: null,
      renderer: null,
      gui: null,
      window: {
        height: 0,
        width: 0
      },
      uniforms: {
        u_time: { type: 'f', value: 0.0 },
        u_opacity: { type: 'f', value: 1.0 },
        u_color: { type: 'v3', value: { x: 0.0, y: 0.0, z: 0.0 } },
        u_resolution: { value: { x: 0.0, y: 0.0 } },
        u_tex: { type: 'sampler2D', value: '' },
        u_uv_distance: { type: 'f', value: 110.0 },
        u_speed: { type: 'f', value: 1.5 },
        u_smoothness: { type: 'f', value: 50.0 },
        u_frequency1: { type: 'f', value: 1.035 },
        u_amplitude1: { type: 'f', value: 10.0 },
        u_frequency2: { type: 'f', value: 0.025 },
        u_amplitude2: { type: 'f', value: 70.0 }
      },
      geometry: {}
    }
  },

  mounted () {
    this.enableStats()

    this._setupRenderer()
    this._setupCamera()

    this._setupFonts()

    this._setupScreenDimensions()
    this._setUpEventListeners()

    this._createScene()

    this.enableGUI()
    this._setupGUI()
  },

  beforeDestroy () {
    gsap.ticker.remove(this._renderScene)
    window.removeEventListener('resize', this.$data.resize)
  },

  methods: {
    // SETUP

    _setupRenderer () {
      this.renderer = new THREE.WebGLRenderer({ canvas: this.$refs.canvas.$el })
      this.renderer.setClearColor(0x000000, 1)
    },

    _setupCamera () {
      this.camera = new THREE.PerspectiveCamera(35, this.window.width / this.window.height, 1, 1000)
      this.camera.position.z = 500

      this.controls = new OrbitControls(this.camera, this.$refs.canvas.$el)
      this.controls.enableDamping = true
    },

    _setupFonts () {
      const self = this

      loadFont(FONT_PATH.FNT, (err, font) => {
        if (err) return

        console.log(this)

        self.geometry = createGeometry({
          font,
          text: 'Playground',
          // width: 300,
          align: 'right'
        })

        this.loader.load(FONT_PATH.PNG, (texture) => {
          this._createFontGeometry(self.geometry, texture)
        })
      })
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
    },

    _setUpEventListeners () {
      this._tickHandler()
      this._resizeHandler()
    },

    // SCENE

    _createFontGeometry (geometry, texture) {
      console.log(texture)
      this.uniforms.u_tex.value = texture

      const material = new THREE.ShaderMaterial({
        fragmentShader,
        vertexShader,
        side: THREE.DoubleSide,
        uniforms: this.uniforms
      })

      this.mesh = new THREE.Mesh(geometry, material)
      this.mesh.position.set(-80, 0, 0)
      this.mesh.rotation.set(Math.PI, 0, 0)
      this.scene.add(this.mesh)
    },

    _createScene () {},

    _renderScene () {
      this.stats.begin()

      this.uniforms.u_time.value = this.clock.getElapsedTime()
      this.controls.update()
      this._updateValues()
      this.renderer.render(this.scene, this.camera)

      this.stats.end()
    },

    _updateValues () {

    },

    _setupGUI () {
      this.gui.add(this.uniforms.u_uv_distance, 'value', 0, 1500).name('UV Distance').step(1.0).listen()
      this.gui.add(this.uniforms.u_speed, 'value', 0, 5).name('Speed').step(0.01).listen()
      this.gui.add(this.uniforms.u_smoothness, 'value', 0.1, 100).name('Smoothness').step(0.01).listen()
      this.gui.add(this.uniforms.u_frequency1, 'value', 0.01, 25).name('Frequency 1').step(0.01).listen()
      this.gui.add(this.uniforms.u_amplitude1, 'value', 0, 200).name('Amplitude 1').step(0.01).listen()
      this.gui.add(this.uniforms.u_frequency2, 'value', 0.01, 25).name('Frequency 2').step(0.01).listen()
      this.gui.add(this.uniforms.u_amplitude2, 'value', 0, 200).name('Amplitude 2').step(0.01).listen()
    },

    // HANDLERS
    _tickHandler () {
      gsap.ticker.add(this._renderScene)
    },

    _resizeHandler () {
      this.$data.resize = debounce(this._setupScreenDimensions.bind(this), 250)
      window.addEventListener('resize', this.$data.resize)
    }
  }
}
</script>
