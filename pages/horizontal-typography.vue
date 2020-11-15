<template>
  <section class="container">
    <Canvas ref="canvas" @canvasResizeHandler="_resizeScreenHandler" />
  </section>
</template>

<script>
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls'

import base from '~/mixins/base.js'
import Canvas from '~/components/webgl/canvas.vue'
import fragmentShader from '~/components/webgl/horizontal-typography/fragment.glsl'
import vertexShader from '~/components/webgl/horizontal-typography/vertex.glsl'

const THREE = require('three')
const { gsap } = require('gsap')

const IMAGE = require('~/assets/images/horizontal-text.png')

const IMAGE_ASPECT = 853 / 1280
const RENDERER_COLOR = 0x0C0C0C

// Ortho
const CAMERA_NEAR = -1000
const CAMERA_FAR = 1000
const FRUSTUM_SIZE = 1

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
      paused: false,
      orbitControls: true,
      window: { height: 0, width: 0 },
      uniforms: {
        u_time: { type: 'f', value: 0.0 },
        u_progress: { type: 'f', value: 0.0 },
        u_tex: { type: 'sampler2D', value: '' },
        u_resolution: { type: 'v4', value: new THREE.Vector4() },
        uvRate1: { type: 'v2', value: new THREE.Vector2(1, 1) }
      }
    }
  },

  mounted () {
    this.enableStats()

    this._createScene()

    this._setupScreenDimensions()
    this._imageAspectCover()

    this._setupCamera()
    this._setupRenderer()
    this._updateCamera()
    this._updateRenderer()

    this._setSceneDimensions()

    this._setUpEventListeners()

    this.enableGUI()
    this._setupGUI()
  },

  beforeDestroy () {
    gsap.ticker.remove(this._renderScene)
    document.removeEventListener('visibilitychange', this._changeVisibilityStatus)
  },

  methods: {
    _setUpEventListeners () {
      this._tickHandler()
      this._visibilitychangeHandler()
    },

    /*
    ** SCENE SETUP
    */

    _setupRenderer () {
      this.renderer = new THREE.WebGLRenderer({ canvas: this.$refs.canvas.$el })
      this.renderer.setClearColor(RENDERER_COLOR, 1)
    },

    _setupCamera () {
      this.camera = new THREE.OrthographicCamera(FRUSTUM_SIZE / -2, FRUSTUM_SIZE / 2, FRUSTUM_SIZE / 2, FRUSTUM_SIZE / -2, CAMERA_NEAR, CAMERA_FAR)
      // this.camera = new THREE.PerspectiveCamera(CAMERA_FOV, this.window.width / this.window.height, CAMERA_NEAR, CAMERA_FAR)
      this.camera.position.set(0, 0, 2)

      if (!this.orbitControls) return
      this.controls = new OrbitControls(this.camera, this.$refs.canvas.$el)
      this.controls.enableDamping = true
    },

    _setupScreenDimensions () {
      this.window.width = window.innerWidth
      this.window.height = window.innerHeight

      this.uniforms.u_resolution.value.x = this.window.width
      this.uniforms.u_resolution.value.y = this.window.height
    },

    _setSceneDimensions () {
      // this.window.width / this.window.height > 1 ? this.plane.scale.x = this.camera.aspect : this.plane.scale.y = 1 / this.camera.aspect
    },

    _imageAspectCover () {
      const { height, width } = this.window
      const checkRatio = height / width > IMAGE_ASPECT

      this.uniforms.u_resolution.value.z = checkRatio ? (width / height) * IMAGE_ASPECT : 1
      this.uniforms.u_resolution.value.w = checkRatio ? 1 : (height / width) / IMAGE_ASPECT
    },

    _updateCamera () {
      this.camera.aspect = this.window.width / this.window.height
      this.camera.updateProjectionMatrix()
    },

    _updateRenderer () {
      this.renderer.setSize(this.window.width, this.window.height)
      this.renderer.setPixelRatio(window.devicePixelRatio)
    },

    /*
    ** SCENE CREATION
    */

    _createPlaneGeometry () {
      const geometry = new THREE.PlaneGeometry(1, 1, 1, 1)
      const texture = this.loader.load(IMAGE)
      texture.magFilter = THREE.NearestFilter
      texture.minFilter = THREE.NearestFilter
      this.uniforms.u_tex.value = texture

      // this.uniforms.u_tex.value.magFilter = THREE.NearestFilter

      const shaderMaterial = new THREE.ShaderMaterial({
        uniforms: this.uniforms,
        vertexShader,
        fragmentShader,
        // wireframe: true,
        extensions: { derivatives: '#extension GL_OES_standard_derivatives : enable' },
        side: THREE.DoubleSide
      })

      return new THREE.Mesh(geometry, shaderMaterial)
    },

    _createScene () {
      this.plane = this._createPlaneGeometry()

      this.scene.add(this.plane)
    },

    _renderScene () {
      if (this.paused) return

      this.stats.begin()
      this.uniforms.u_time.value = this.clock.getElapsedTime()
      this._useFrame()
      if (this.orbitControls) this.controls.update()
      this.renderer.render(this.scene, this.camera)
      this.stats.end()
    },

    /*
    ** SCENE ANIMATION
    */

    _useFrame () {},

    /*
    ** MISCELLANEOUS
    */

    _setupGUI () {
      this.gui.add(this.uniforms.u_time, 'value').name('Time').step(0.1).listen()
      this.gui.add(this.uniforms.u_progress, 'value', 0, 1).name('Progress').listen()
    },

    _changeVisibilityStatus () {
      document.hidden ? this.paused = true : this.paused = false
    },

    /*
    ** HANDLERS
    */

    _tickHandler () {
      gsap.ticker.add(this._renderScene)
    },

    _visibilitychangeHandler () {
      document.addEventListener('visibilitychange', this._changeVisibilityStatus)
    },

    _resizeScreenHandler () {
      this._setupScreenDimensions()

      this._updateCamera()
      this._updateRenderer()

      this._imageAspectCover()
      this._setSceneDimensions()
    }
  }
}
</script>
