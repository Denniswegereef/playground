<template>
  <section class="container">
    <Canvas ref="canvas" @canvasResizeHandler="_resizeScreen" />
  </section>
</template>

<script>
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls'

import base from '~/mixins/base.js'
import Canvas from '~/components/webgl/canvas.vue'
import fragmentShader from '~/components/webgl/distort-image-fullscreen/fragment.glsl'
import vertexShader from '~/components/webgl/distort-image-fullscreen/vertex.glsl'

const THREE = require('three')
const { gsap } = require('gsap')

const TEXTURE = require('~/assets/images/distort-image-fullscreen.png')

const IMAGE_ASPECT = 853 / 1280
const RENDERER_COLOR = 0x0C0C0C

const CAMERA_FOV = 70
const CAMERA_NEAR = 0.0001
const CAMERA_FAR = 1000

export default {
  components: {
    Canvas
  },

  mixins: [base],

  data () {
    return {
      scene: new THREE.Scene(),
      clock: new THREE.Clock(),
      textureLoader: new THREE.TextureLoader(),
      camera: null,
      renderer: null,
      gui: null,
      paused: false,
      orbitControls: true,
      window: { height: 0, width: 0 },
      targetSpeed: 0,
      uniforms: {
        u_time: { type: 'f', value: 0.0 },
        u_progress: { type: 'f', value: 0.0 },
        u_mouse: { type: 'v2', value: { x: 0.0, y: 0.0 } },
        u_mouse_speed: { type: 'f', value: 0.0 },
        u_direction: { type: 'f', value: 0.0 },
        u_resolution: { type: 'v4', value: new THREE.Vector4() },
        uvRate1: { type: 'v2', value: new THREE.Vector2(1, 1) },
        u_texture1: { type: 't', value: '' }
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
    document.removeEventListener('pointerdown', this._mouseDownCanvas)
    document.removeEventListener('pointerup', this._mouseUpCanvas)
  },

  methods: {
    _setUpEventListeners () {
      this._mouseDownHandler()
      this._mouseUpHandler()
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
      this.camera = new THREE.PerspectiveCamera(CAMERA_FOV, this.window.width / this.window.height, CAMERA_NEAR, CAMERA_FAR)
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
      this.window.width / this.window.height > 1 ? this.plane.scale.x = this.camera.aspect : this.plane.scale.y = 1 / this.camera.aspect
    },

    _imageAspectCover () {
      const { height, width } = this.window
      const checkRatio = height / width > IMAGE_ASPECT

      this.uniforms.u_resolution.value.z = checkRatio ? (width / height) * IMAGE_ASPECT : 1
      this.uniforms.u_resolution.value.w = checkRatio ? 1 : (height / width) / IMAGE_ASPECT
    },

    _updateCamera () {
      const distance = this.camera.position.z
      const height = 1
      this.camera.aspect = this.window.width / this.window.height

      this.camera.fov = 2 * (180 / Math.PI) * Math.atan(height / (2 * distance))
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
      const geometry = new THREE.PlaneGeometry(1, 1, 100, 100)

      this.uniforms.u_texture1.value = this.textureLoader.load(TEXTURE)

      const shaderMaterial = new THREE.ShaderMaterial({
        uniforms: this.uniforms,
        // wireframe: true,
        extensions: { derivatives: '#extension GL_OES_standard_derivatives : enable' },
        side: THREE.DoubleSide,
        fragmentShader,
        vertexShader
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
      this._animateScene()
      if (this.orbitControls) this.controls.update()
      this.renderer.render(this.scene, this.camera)
      this.stats.end()
    },

    /*
    ** SCENE ANIMATION
    */

    _mouseDownCanvas () {
      this.uniforms.u_direction.value = 0
      gsap.to(this.uniforms.u_progress, { value: 1.0, duration: 0.5 })
    },

    _mouseUpCanvas () {
      this.uniforms.u_direction.value = 1
      gsap.to(this.uniforms.u_progress, { value: 0.0, duration: 0.5 })
    },

    _animateScene () {
      this.uniforms.u_mouse.value.x = this.mouse.uv.x
      this.uniforms.u_mouse.value.y = this.mouse.uv.y

      this.updateMouseSpeed()
      this.targetSpeed += 0.1 * (this.mouseSpeed - this.targetSpeed)
      this.uniforms.u_mouse_speed.value = this.targetSpeed
    },

    /*
    ** MISCELLANEOUS
    */

    _setupGUI () {
      this.gui.add(this.uniforms.u_time, 'value').name('Time').step(0.1).listen()
      this.gui.add(this.uniforms.u_progress, 'value').name('Progress').step(0.1).listen()
      this.gui.add(this.uniforms.u_mouse.value, 'x').name('Mouse uv x').step(0.01).listen()
      this.gui.add(this.uniforms.u_mouse.value, 'y').name('Mouse uv y').step(0.01).listen()
      this.gui.add(this.uniforms.u_mouse_speed, 'value').name('Mouse speed').step(0.001).listen()
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

    _mouseDownHandler () {
      document.addEventListener('pointerdown', this._mouseDownCanvas)
    },

    _mouseUpHandler () {
      document.addEventListener('pointerup', this._mouseUpCanvas)
    },

    _visibilitychangeHandler () {
      document.addEventListener('visibilitychange', this._changeVisibilityStatus)
    },

    _resizeScreen () {
      this._setupScreenDimensions()
      this._imageAspectCover()

      this._updateCamera()
      this._updateRenderer()

      this._setSceneDimensions()
    }
  }
}
</script>
