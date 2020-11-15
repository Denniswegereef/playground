<template>
  <section class="container">
    <Canvas ref="canvas" @canvasResizeHandler="_resizeScreenHandler" />
  </section>
</template>

<script>
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls'

import base from '~/mixins/base.js'
import Canvas from '~/components/webgl/canvas.vue'

import objectFragmentShader from '~/components/webgl/kinetic-typography-wave/object_fragment.glsl'
import objectVertexShader from '~/components/webgl/kinetic-typography-wave/object_vertex.glsl'
import textFragmentShader from '~/components/webgl/kinetic-typography-wave/text_fragment.glsl'
import textVertexShader from '~/components/webgl/kinetic-typography-wave/text_vertex.glsl'

const THREE = require('three')
const { gsap } = require('gsap')

const loadFont = require('load-bmfont')
const createGeometry = require('~/plugins/three-bmfont-text/index')

// const IMAGE_ASPECT = 853 / 1280
const RENDERER_COLOR = 0x000000
const RENDER_TARGER_COLOR = new THREE.Color(0x000000)

const CAMERA_FOV = 70
const CAMERA_NEAR = 0.0001
const CAMERA_FAR = 1000

const CAMERA_Z = 1.7

const TEXT = 'PLAYGROUND'

const FONT_PATH = {
  FNT: '/fonts/momument/MonumentExtended-Black.fnt',
  PNG: '/fonts/momument/MonumentExtended-Black.png'
}

export default {
  components: {
    Canvas
  },

  mixins: [base],

  data () {
    return {
      scene: new THREE.Scene(),
      renderTargetScene: new THREE.Scene(),
      clock: new THREE.Clock(),
      loader: new THREE.TextureLoader(),
      camera: null,
      renderer: null,
      gui: null,
      paused: false,
      orbitControls: true,
      window: { height: 0, width: 0 },
      uniforms: {
        text: {
          u_time: { type: 'f', value: 0.0 },
          u_opacity: { type: 'f', value: 0.5 },
          u_tex: { type: 'sampler2D', value: '' },
          u_resolution: { type: 'v4', value: new THREE.Vector4() }
        },
        object: {
          u_time: { type: 'f', value: 0.0 },
          u_mouse: { type: 'v2', value: { x: 0.25, y: 0.0 } },
          u_tex: { type: 'sampler2D', value: '' },
          u_resolution: { type: 'v4', value: new THREE.Vector4() }
        }
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
    this._createRenderTarget()
    this._updateRenderTarget()

    this._setSceneDimensions()

    this._setUpEventListeners()

    this.enableGUI()
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
      this.renderer = new THREE.WebGLRenderer({ canvas: this.$refs.canvas.$el, antialias: true })
      this.renderer.setClearColor(RENDERER_COLOR, 1)
    },

    _setupCamera () {
      this.camera = new THREE.PerspectiveCamera(CAMERA_FOV, this.window.width / this.window.height, CAMERA_NEAR, CAMERA_FAR)
      this.camera.position.set(0, 0, CAMERA_Z)
      this.camera.rotation.set(0.2, 0, 0)

      if (!this.orbitControls) return
      this.controls = new OrbitControls(this.camera, this.$refs.canvas.$el)
      this.controls.enableDamping = true
    },

    _setupScreenDimensions () {
      this.window.width = window.innerWidth
      this.window.height = window.innerHeight

      this.uniforms.text.u_resolution.value.x = this.window.width
      this.uniforms.text.u_resolution.value.y = this.window.height

      this.uniforms.object.u_resolution.value.x = this.window.width
      this.uniforms.object.u_resolution.value.y = this.window.height
    },

    _setSceneDimensions () {
      // this.window.width / this.window.height > 1 ? this.plane.scale.x = this.camera.aspect : this.plane.scale.y = 1 / this.camera.aspect
    },

    _imageAspectCover () {
      // const { height, width } = this.window
      // const checkRatio = height / width > IMAGE_ASPECT

      // this.uniforms.u_resolution.value.z = checkRatio ? (width / height) * IMAGE_ASPECT : 1
      // this.uniforms.u_resolution.value.w = checkRatio ? 1 : (height / width) / IMAGE_ASPECT
    },

    _updateCamera () {
      this.camera.aspect = this.window.width / this.window.height
      this.camera.updateProjectionMatrix()
    },

    _updateRenderer () {
      this.renderer.setSize(this.window.width, this.window.height)
      this.renderer.setPixelRatio(window.devicePixelRatio)
    },

    _createRenderTarget () {
      this.renderTarget = new THREE.WebGLRenderTarget()
      this.renderTargetCamera = new THREE.PerspectiveCamera(45, 1, 0.1, 1000)
      this.renderTargetCamera.position.z = 2.5
      this.renderTargetScene.background = RENDER_TARGER_COLOR
    },

    _updateRenderTarget () {
      this.renderTarget.setSize(this.window.width, this.window.height)
    },

    /*
    ** SCENE CREATION
    */

    _createFontGeometry () {
      return new Promise((resolve, reject) => {
        loadFont(FONT_PATH.FNT, (err, font) => {
          if (err) return reject(err)

          const geometry = createGeometry({
            font,
            text: TEXT
          })

          const texture = this.loader.load(FONT_PATH.PNG)
          this.uniforms.text.u_tex.value = texture

          const material = new THREE.ShaderMaterial({
            fragmentShader: textFragmentShader,
            vertexShader: textVertexShader,
            side: THREE.DoubleSide,
            uniforms: this.uniforms.text
          })

          const mesh = new THREE.Mesh(geometry, material)

          mesh.position.set(-1.00, -0.1, 0)
          mesh.rotation.set(Math.PI, 0, 0)
          mesh.scale.set(0.005, 0.025, 1)

          resolve(mesh)
        })
      })
    },

    _createPlaneGeometry () {
      const geometry = new THREE.PlaneGeometry(2, 1 + this.window.height / this.window.width, 50, 50)

      this.uniforms.object.u_tex.value = this.renderTarget.texture

      const shaderMaterial = new THREE.ShaderMaterial({
        vertexShader: objectVertexShader,
        fragmentShader: objectFragmentShader,
        uniforms: this.uniforms.object,
        extensions: { derivatives: '#extension GL_OES_standard_derivatives : enable' }
      })

      const mesh = new THREE.Mesh(geometry, shaderMaterial)
      mesh.scale.set(3, 3, 1)

      return mesh
    },

    async _createScene () {
      this.fontMesh = await this._createFontGeometry()
      this.renderTargetScene.add(this.fontMesh)

      this.planeMesh = this._createPlaneGeometry()

      this.scene.add(this.planeMesh)

      this.uniforms.object.u_mouse.value.x = 0.25

      this._setupGUI()
    },

    _renderScene () {
      if (this.paused) return

      this.stats.begin()

      const getElapsedTime = this.clock.getElapsedTime()
      this.uniforms.text.u_time.value = getElapsedTime
      this.uniforms.object.u_time.value = getElapsedTime

      this._useFrame()

      if (this.orbitControls) this.controls.update()
      this.renderer.setRenderTarget(this.renderTarget)
      this.renderer.render(this.renderTargetScene, this.renderTargetCamera)
      this.renderer.setRenderTarget(null)
      this.renderer.render(this.scene, this.camera)
      this.stats.end()
    },

    /*
    ** SCENE ANIMATION
    */

    _useFrame () {
      this.uniforms.object.u_mouse.value = this.mouse.uv
    },

    /*
    ** MISCELLANEOUS
    */

    _setupGUI () {
      this.gui.add(this.uniforms.text.u_time, 'value').name('Time').step(0.1).listen()
      // this.gui.add(this.boxMesh.rotation, 'x', -10, 10).name('X').step(0.01).listen()
      // this.gui.add(this.boxMesh.rotation, 'y', -10, 10).name('Y').step(0.01).listen()
      // this.gui.add(this.boxMesh.rotation, 'z', -10, 10).name('Z').step(0.01).listen()
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
