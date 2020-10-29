<template>
  <section class="container">
    <Canvas ref="canvas" />
  </section>
</template>

<script>
import debounce from 'lodash.debounce'

import base from '~/mixins/base.js'
import Canvas from '~/components/webgl/canvas.vue'
import fragmentShader from '~/components/webgl/bmfont/fragment.glsl'
import vertexShader from '~/components/webgl/bmfont/vertex.glsl'

const THREE = require('three')
const { gsap } = require('gsap')
const loadFont = require('load-bmfont')
const createGeometry = require('~/plugins/three-bmfont-text/index')

const FONT_PATH = {
  FNT: '/fonts/canela/CanelaText-Regular.fnt',
  PNG: '/fonts/canela/CanelaText-Regular.ttf'
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
      camera: null,
      renderer: null,
      gui: null,
      window: {
        height: 0,
        width: 0
      },
      uniforms: {
        u_time: { value: 0.0 },
        u_resolution: { value: { x: 0.0, y: 0.0 } }
      }
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
      this.renderer.setClearColor(0x32A8A8, 1)
    },

    _setupCamera () {
      this.camera = new THREE.PerspectiveCamera(35, this.window.width / this.window.height, 1, 1000)
      this.camera.position.z = 150
    },

    _setupFonts () {
      console.log(createGeometry, loadFont)
      console.log(FONT_PATH)

      loadFont(FONT_PATH.FNT, (err, font) => {
        if (err) return
        console.log(font)
        // const geometry = createGeometry({
        //   font,
        //   text: 'BMFONT TEST'
        // })
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

    _createIcosahedronGeometry () {
      const geometry = new THREE.IcosahedronGeometry(20, 4)

      const shaderMaterial = new THREE.ShaderMaterial({
        uniforms: this.uniforms,
        vertexShader,
        fragmentShader,
        side: THREE.DoubleSide,
        wireframe: true
      })

      this.icosahedron = new THREE.Mesh(geometry, shaderMaterial)

      this.scene.add(this.icosahedron)
    },

    _createScene () {
      this._createIcosahedronGeometry()
    },

    _renderScene () {
      this.stats.begin()

      this.uniforms.u_time.value = this.clock.getElapsedTime()
      this._updateValues()
      this.renderer.render(this.scene, this.camera)

      this.stats.end()
    },

    _updateValues () {
      if (!this.icosahedron) return

      this.icosahedron.rotation.x += 0.02
      this.icosahedron.rotation.y += 0.01
    },

    _setupGUI () {
      const folder = this.gui.addFolder('Folder')
      folder.open()
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
