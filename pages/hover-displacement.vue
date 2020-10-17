<template>
  <section class="container">
    <Canvas ref="canvas" />
  </section>
</template>

<script>
import debounce from 'lodash.debounce'

import base from '~/mixins/base.js'
import Canvas from '~/components/webgl/canvas.vue'
import fragmentShader from '~/components/webgl/hover-displacement/fragment.glsl'
import vertexShader from '~/components/webgl/hover-displacement/vertex.glsl'

const THREE = require('three')
const { gsap } = require('gsap')

const FOV = 50
const CAMERA_DISTANCE = 50
const PLANE_WIDTH_SEGMENTS = 90
const PLANE_ASPECT_RATIO = 9 / 16
const TEXTURE_WIDTH = 2126
const TEXTURE_HEIGHT = 1393
const BACKGROUND_COLOR = '#000f14'

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
      raycaster: null,
      gui: null,
      window: {
        height: 0,
        width: 0
      },
      uniforms: {
        u_time: { type: 'f', value: 0.0 },
        u_resolution: { type: 'v2', value: { x: 0.0, y: 0.0 } },
        u_hover: { type: 'f', value: 0.0 },
        u_texture: { type: 't', value: '' },
        u_intersect: { type: 'v2', value: { x: 0.0, y: 0.0 } },
        u_ratio: { type: 'v2', value: { x: 0.0, y: 0.0 } },
        u_hoverRadius: { type: 'f', value: 0.35 },
        u_speed: { type: 'f', value: 0.6 },
        u_amplitude: { type: 'f', value: 10.0 }
      },
      intersected: null,
      mouse: {
        x: 0,
        y: 0
      }
    }
  },

  mounted () {
    this.enableStats()

    this._setupRenderer()
    this._setupCamera()
    this._setupRayCaster()

    this._setupScreenDimensions()
    this._createScene()

    // this._setupTimelines()

    this._setUpEventListeners()

    this.enableGUI()
    this._setupGUI()
  },

  beforeDestroy () {
    gsap.ticker.remove(this._renderScene)
    window.removeEventListener('resize', this.$data.resize)
    window.removeEventListener('mousemove', this._updateMousePositions)
  },

  methods: {
    // SETUP
    _setUpEventListeners () {
      this._tickHandler()
      this._resizeHandler()
      this._mouseMoveHandler()
    },

    _setupRenderer () {
      this.renderer = new THREE.WebGLRenderer({ canvas: this.$refs.canvas.$el, powerPreference: 'high-performance', antialias: true })
    },

    _setupCamera () {
      this.aspect = this.window.width / this.window.height
      this.camera = new THREE.PerspectiveCamera(FOV, this.aspect, 1, 1000)
      this.camera.position.z = CAMERA_DISTANCE
    },

    _setupRayCaster () {
      this.raycaster = new THREE.Raycaster()
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

    _getVisibleDimensionsAtZDepth (depth = 0) {
      // Compensate for cameras not positioned at z=0
      const cameraOffset = this.camera.position.z

      if (depth < cameraOffset) depth -= cameraOffset
      else depth += cameraOffset

      // Vertical fov in radians
      const vFOV = (this.camera.fov * Math.PI) / 180

      // Math.abs to ensure the result is always positive
      const visibleHeight = 2 * Math.tan(vFOV / 2) * Math.abs(depth)
      const visibleWidth = visibleHeight * this.camera.aspect

      return {
        visibleHeight,
        visibleWidth
      }
    },

    // SCENE
    _createPlane () {
      const textureLoader = new THREE.TextureLoader()
      const texture = require('~/assets/images/hover-displacement.png')

      const loadedTexture = textureLoader.load(texture, (t) => {
        t.wrapT = t.wrapS = THREE.RepeatWrapping
        t.anisotropy = 0
        t.magFilter = THREE.LinearFilter
        t.minFilter = THREE.LinearFilter
      })

      const { visibleWidth } = this._getVisibleDimensionsAtZDepth()

      const planeWidth = visibleWidth / 2
      const planeHeight = planeWidth * PLANE_ASPECT_RATIO

      const ratio = new THREE.Vector2(
        Math.min(planeWidth / planeHeight / (TEXTURE_WIDTH / TEXTURE_HEIGHT), 1.0),
        Math.min(planeHeight / planeWidth / (TEXTURE_HEIGHT / TEXTURE_WIDTH), 1.0)
      )

      this.uniforms.u_texture.value = loadedTexture
      this.uniforms.u_ratio.value = ratio

      const planeMaterial = new THREE.ShaderMaterial({
        uniforms: this.uniforms,
        side: THREE.DoubleSide,
        vertexShader,
        fragmentShader
      })

      const planeGeometry = new THREE.PlaneBufferGeometry(planeWidth, planeHeight, PLANE_WIDTH_SEGMENTS, Math.round(PLANE_WIDTH_SEGMENTS * PLANE_ASPECT_RATIO))

      return new THREE.Mesh(planeGeometry, planeMaterial)
    },

    _createScene () {
      this.scene.background = new THREE.Color(BACKGROUND_COLOR)

      this.plane = this._createPlane()
      this.scene.add(this.plane)
    },

    _renderScene () {
      this.stats.begin()

      this.uniforms.u_time.value = this.clock.getElapsedTime()

      this._updateValues()
      this.renderer.render(this.scene, this.camera)

      this.stats.end()
    },

    _updateValues () {},

    _updateIntersected () {
      this.raycaster.setFromCamera(this.mouse.normalize, this.camera)

      const intersects = this.raycaster.intersectObject(this.plane, false)

      if (intersects.length > 0) {
        document.body.style.cursor = 'pointer'

        const intersectObject = intersects[0].object

        if (this.intersected === intersectObject) {
          this.uniforms.u_intersect.value.x = intersects[0].uv.x
          this.uniforms.u_intersect.value.y = intersects[0].uv.y

          gsap.to(intersectObject.position, 0.35, { x: this.mouse.normalize.x, y: this.mouse.normalize.y })
        } else if (this.intersected !== intersectObject) {
          // Start intersecting
          this.intersected = intersectObject

          gsap.to(intersectObject.material.uniforms.u_hover, { value: 0.5, duration: 0.35 })
          gsap.to(intersectObject.scale, { x: 1.05, y: 1.05, ease: 'power1.out', duration: 0.6 })
        }
      } else {
        // not intersecting anymore
        document.body.style.cursor = 'auto'

        if (this.intersected) {
          gsap.to(this.intersected.position, { x: 0.0, y: 0.0, duration: 0.35 })
          gsap.to(this.intersected.scale, { x: 1.0, y: 1.0, ease: 'power1.out', duration: 0.6 })
          gsap.to(this.intersected.material.uniforms.u_hover, { value: 0.0, duration: 0.35 })

          this.intersected = null
        }
      }
    },

    _resizeScreen () {
      this.window.width = window.innerWidth
      this.window.height = window.innerHeight

      this.renderer.setSize(this.window.width, this.window.height)

      this.camera.aspect = this.window.width / this.window.height
      this.camera.updateProjectionMatrix()

      this.scene.remove(this.plane)
      this._createScene()

      this.gui.destroy()
      this.enableGUI()
      this._setupGUI()
    },

    _updateMouse (event) {
      this._updateIntersected()
    },

    _setupGUI () {
      this.gui.add(this.uniforms.u_hoverRadius, 'value', 0, 1).name('Radius')
      this.gui.add(this.uniforms.u_amplitude, 'value', 1, 30).name('Amplitude')
      this.gui.add(this.uniforms.u_speed, 'value', 0, 4).name('Speed')
    },

    // HANDLERS
    _tickHandler () {
      gsap.ticker.add(this._renderScene)
    },

    _mouseMoveHandler () {
      window.addEventListener('mousemove', this._updateMouse)
    },

    _resizeHandler () {
      this.$data.resize = debounce(this._resizeScreen.bind(this), 250)
      window.addEventListener('resize', this.$data.resize)
    }
  }
}
</script>
