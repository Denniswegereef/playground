<template>
  <section class="container">
    <Canvas ref="canvas" />
  </section>
</template>

<script>
import debounce from 'lodash.debounce'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'

import base from '~/mixins/base.js'
import Canvas from '~/components/webgl/canvas.vue'
import fragmentShader from '~/components/webgl/waving-flag/fragment.glsl'
import vertexShader from '~/components/webgl/waving-flag/vertex.glsl'

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
        u_depth: { type: 'float', value: -0.1 },
        u_noise_amplitude: { type: 'float', value: -0.1 },
        u_tex: { type: 'sampler2D', value: '' }
      }
    }
  },

  mounted () {
    console.log(OrbitControls)
    this.enableStats()

    this._setupRenderer()
    this._setupCamera()

    this._setupScreenDimensions()

    this._createScene()
    this._setUpEventListeners()

    this._createWave()

    this.enableGUI()
    this._setupGUI()
    console.log(this.camera, this.$refs.canvas.$el)
    this.controls = new OrbitControls(this.camera, this.$refs.canvas.$el)
    this.controls.update()
  },

  beforeDestroy () {
    gsap.ticker.remove(this._renderScene)
    window.removeEventListener('resize', this.$data.resize)
  },

  methods: {
    // SETUP

    _setupRenderer () {
      this.window.width = window.innerWidth
      this.window.height = window.innerHeight

      this.renderer = new THREE.WebGLRenderer({ canvas: this.$refs.canvas.$el })
      this.renderer.setClearColor(0x32A8A8, 1)
      this.renderer.setSize(this.window.width, this.window.height)
      this.renderer.setPixelRatio(window.devicePixelRatio)
    },

    _setupCamera () {
      this.camera = new THREE.PerspectiveCamera(35, this.window.width / this.window.height, 1, 1000)
      this.camera.position.z = 2
      this.camera.aspect = this.window.width / this.window.height
      this.camera.updateProjectionMatrix()
      this.scene.add(this.camera)

      // this.camera.position.set(0, 20, 100)
      // this.camera.rotation.x = -0.1
      // this.camera.rotation.y = 0.4
      // this.plane.rotation.y = 0.4
    },

    _setupScreenDimensions () {
      this.window.width = window.innerWidth
      this.window.height = window.innerHeight

      this.uniforms.u_resolution.value.x = this.window.width
      this.uniforms.u_resolution.value.y = this.window.height

      this.renderer.setSize(this.window.width, this.window.height)
      this.renderer.setPixelRatio(window.devicePixelRatio)
    },

    _setUpEventListeners () {
      this._tickHandler()
      this._resizeHandler()
    },

    // SCENE

    _createPlaneGeometry () {
      const geometry = new THREE.PlaneBufferGeometry(1, 1, 80, 80)

      const textureLoader = new THREE.TextureLoader()
      const texture = require('~/assets/images/waving-flag.png')
      const loadedTexture = textureLoader.load(texture)

      this.uniforms.u_tex.value = loadedTexture

      const shaderMaterial = new THREE.ShaderMaterial({
        uniforms: this.uniforms,
        vertexShader,
        fragmentShader,
        side: THREE.DoubleSide
      })

      return new THREE.Mesh(geometry, shaderMaterial)
    },

    _createCylinderGeometry () {
      const geometry = new THREE.CylinderBufferGeometry(0.2, 0.2, 50, 5, 5)
      const material = new THREE.MeshBasicMaterial({ color: 0xFFFF00 })

      return new THREE.Mesh(geometry, material)
    },

    _createWave () {
      // gsap.to(this.uniforms.u_depth, { value: 0.8, duration: 2.5, yoyo: true, repeat: -1 })
    },

    _createScene () {
      this.plane = this._createPlaneGeometry()
      this.plane.rotation.x = -0.1
      this.plane.rotation.y = 0.4

      this.cilinder = this._createCylinderGeometry()
      this.cilinder.rotation.x = -0.1
      this.cilinder.rotation.y = 0.4

      // this.scene.add(this.cilinder)
      this.scene.add(this.plane)
    },

    _renderScene () {
      this.stats.begin()

      this.uniforms.u_time.value = this.clock.getElapsedTime()
      this._updateValues()
      this.controls.update()
      this.renderer.render(this.scene, this.camera)

      this.stats.end()
    },

    _updateValues () {
      // if (!this.icosahedron) return

      // this.plane.rotation.x += 0.02
      // this.plane.rotation.y += 0.01
    },

    _setupGUI () {
      this.gui.add(this.uniforms.u_depth, 'value', -1.0, 2.0).name('Depth').step(0.0001).listen()
      this.gui.add(this.uniforms.u_noise_amplitude, 'value', -2, 2).name('test').step(0.001)
      // this.gui.add(this.uniforms.u_noise_amplitude, 'value', 0, 1.5).name('nAmplitude').step(0.05)
      this.gui.add(this.cilinder.rotation, 'x', 0, 360.0).name('x rotate').step(0.05)
      this.gui.add(this.cilinder.rotation, 'y', 0, 360.0).name('y rotate').step(0.05)
      this.gui.add(this.cilinder.rotation, 'z', 0, 360.0).name('z rotate').step(0.05)
      this.gui.add(this.cilinder.position, 'x', 0, 360.0).name('x position').step(0.05)
      this.gui.add(this.cilinder.position, 'y', 0, 360.0).name('y position').step(0.05)
      this.gui.add(this.cilinder.position, 'z', 0, 360.0).name('z position').step(0.05)
      this.gui.add(this.camera.position, 'z', 10, 150).name('Camera z').step(1)
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
