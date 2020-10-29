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
import fragmentShader from '~/components/webgl/discover-canvas/fragment.glsl'
import vertexShader from '~/components/webgl/discover-canvas/vertex.glsl'
import modulo from '~/helpers/modulo'

// import randomRange from '~/helpers/randomRange'
// import lerp from '~/helpers/lerp'
const CAMERA_POSITION_Z = 6

const GRID_POSITIONING = [
  {
    x: 0,
    y: 0,
    z: -0.02
  },
  {
    x: 0,
    y: -0.1,
    z: -0.5
  },
  {
    x: 0,
    y: 0.6,
    z: 1.5
  }
]

const THREE = require('three')
const { gsap } = require('gsap')

const API_URL = `https://www.rijksmuseum.nl/api/en/usersets/222667-monsters?key=${process.env.RIJKS_API_KEY}&format=json&ps=10`

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
      uniforms: [],
      planeOptions: {
        amount: 10,
        distance: 0.2
      },
      slide: {
        speed: 100
      }
    }
  },

  mounted () {
    console.log(API_URL)
    this.enableStats()

    this._setupRenderer()
    this._setupCamera()

    this._setupScreenDimensions()
    this._setUpEventListeners()

    this._createScene()

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

    _setupRenderer () {
      this.renderer = new THREE.WebGLRenderer({ canvas: this.$refs.canvas.$el })
      this.renderer.setClearColor(0x0C011B, 1)
    },

    _setupCamera () {
      this.camera = new THREE.PerspectiveCamera(35, this.window.width / this.window.height, 1, 1000)
      this.camera.position.z = CAMERA_POSITION_Z
      this.controls = new OrbitControls(this.camera, this.$refs.canvas.$el)
      this.controls.enableDamping = true
      this.controls.dampingFactor = 0.08
      this.controls.rotateSpeed = 0.20
      this.controls.autoRotate = false
      this.controls.update()
    },

    _setupScreenDimensions () {
      this.window.width = window.innerWidth
      this.window.height = window.innerHeight

      this.camera.aspect = this.window.width / this.window.height
      this.camera.updateProjectionMatrix()

      this.renderer.setSize(this.window.width, this.window.height)
      this.renderer.setPixelRatio(window.devicePixelRatio)
    },

    _setUpEventListeners () {
      this._tickHandler()
      this._mouseMoveHandler()
      this._resizeHandler()
    },

    // SCENE

    _createPlaneGeometry (item) {
      const uniforms = {
        u_time: { type: 'f', value: 0.0 },
        u_resolution: { type: 'v2', value: { x: 0.0, y: 0.0 } },
        u_tex: { type: 'sampler2D', value: '' }
      }

      const fullWidth = item.image.width
      const fullHeight = item.image.height

      const ratio = fullHeight / fullWidth

      const textureLoader = new THREE.TextureLoader()
      const loadedTexture = textureLoader.load(item.image.cdnUrl)
      uniforms.u_tex.value = loadedTexture

      uniforms.u_resolution.value.x = this.window.width
      uniforms.u_resolution.value.y = this.window.height

      const geometry = new THREE.PlaneBufferGeometry(1, ratio, 1, 1)

      const shaderMaterial = new THREE.ShaderMaterial({
        uniforms,
        vertexShader,
        fragmentShader,
        side: THREE.DoubleSide
      })

      return new THREE.Mesh(geometry, shaderMaterial)
    },

    async _getData () {
      const data = await fetch(API_URL).then(async response => await response.json())
      return data.userSet
    },

    async _createScene () {
      const data = await this._getData()
      // console.log(data)

      const planes = []

      for (let i = 0; i < data.setItems.slice(1, 10).length; i++) {
        const position = GRID_POSITIONING[modulo(i, 3)]

        console.log(position.y)

        const item = data.setItems[i]
        const plane = this._createPlaneGeometry(item)
        plane.position.x = i * 1.2
        plane.position.y = position.y
        plane.position.z = position.z
        // plane.position.z = randomRange(1, 3)

        planes.push(plane)
      }

      this.group = new THREE.Group()
      for (let i = 0; i < planes.length; i++) this.group.add(planes[i])
      this.group.position.x = -1
      this.scene.add(this.group)
    },

    _renderScene () {
      this.stats.begin()

      // this.uniforms.u_time.value = this.clock.getElapsedTime()
      this._updateValues()
      this.controls.update()
      this.renderer.render(this.scene, this.camera)

      this.stats.end()
    },

    _updateValues () {
      if (this.mouse.normalize.x < -0.3 || this.mouse.normalize.x > 0.3) this.group.position.x = (this.group.position.x - (this.mouse.normalize.x / this.slide.speed))
    },

    _updateMousePositions () {
      console.log(this.mouse.normalize.x)
    },

    _setupGUI () {
      this.gui.add(this.slide, 'speed', 0, 300.0).name('speed').step(1)
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
