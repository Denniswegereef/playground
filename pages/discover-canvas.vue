<template>
  <section class="container">
    <RangeSlider ref="rangeSlider" @inputHandler="_rangeInputHandler" @changeHandler="_rangeChangeHandler" />
    <Canvas ref="canvas" />
  </section>
</template>

<script>
import debounce from 'lodash.debounce'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls'

import base from '~/mixins/base.js'
import Canvas from '~/components/webgl/canvas.vue'
import RangeSlider from '~/components/range-slider.vue'
import fragmentShader from '~/components/webgl/discover-canvas/fragment.glsl'
import vertexShader from '~/components/webgl/discover-canvas/vertex.glsl'
import modulo from '~/helpers/modulo'

import offscreen from '~/helpers/offscreen'

const THREE = require('three')
const { gsap } = require('gsap')

const API_URL = `https://www.rijksmuseum.nl/api/en/usersets/222667-monsters?key=${process.env.RIJKS_API_KEY}&format=json&ps=10`
const CAMERA_POSITION_Z = 6
const GROUP_TO_LEFT = -1

const IMAGES_AMOUNT = 8

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

export default {
  components: {
    Canvas,
    RangeSlider
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
      rangeSlider: {
        value: 0.0
      },
      ratios: [],
      slide: {
        speed: 100,
        fullWidth: null
      }
    }
  },

  mounted () {
    this.enableStats()

    this._setupRenderer()
    this._setupCamera()

    this._setupScreenDimensions()
    this._setUpEventListeners()

    this._loadImages()

    this.enableGUI()
    this._setupGUI()
  },

  beforeDestroy () {
    gsap.ticker.remove(this._renderScene)
    window.removeEventListener('resize', this.$data.resize)
    window.removeEventListener('mousemove', this._updateMousePositions)
  },

  methods: {
    _loadImages () {
      const images = []

      const manager = new THREE.LoadingManager()
      const textureLoader = new THREE.TextureLoader(manager)

      manager.onLoad = (a) => {
        this._createScene(images)
      }

      for (let i = 0; i < IMAGES_AMOUNT; i++) {
        const texture = require(`~/assets/images/discover-canvas/${i}.jpg`)
        const image = textureLoader.load(texture)
        images.push(image)
      }
    },
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

    _createPlaneGeometry (item, index) {
      const uniforms = {
        u_time: { type: 'f', value: 0.0 },
        u_resolution: { type: 'v2', value: { x: 0.0, y: 0.0 } },
        u_tex: { type: 'sampler2D', value: '' }
      }

      uniforms.u_tex.value = item

      uniforms.u_resolution.value.x = this.window.width
      uniforms.u_resolution.value.y = this.window.height

      const geometry = new THREE.PlaneBufferGeometry(1, item.image.height / item.image.width, 1, 1)

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

    _createScene (items) {
      const planes = []

      for (let i = 0; i < items.length; i++) {
        const position = GRID_POSITIONING[modulo(i, 3)]

        const item = items[i]

        const plane = this._createPlaneGeometry(item, i)

        plane.position.x = (i * 1.2) + GROUP_TO_LEFT
        plane.position.y = position.y
        plane.position.z = position.z

        planes.push(plane)
      }

      this.group = new THREE.Group()
      for (let i = 0; i < planes.length; i++) this.group.add(planes[i])
      // this.group.position.x = GROUP_TO_LEFT
      this.groupBoudingBox = new THREE.Box3().setFromObject(this.group)

      this.slide.fullWidth = this.groupBoudingBox.max.x + GROUP_TO_LEFT

      this.scene.add(this.group)
    },

    _renderScene () {
      this.stats.begin()

      this._updateValues()
      this.controls.update()
      this.renderer.render(this.scene, this.camera)

      this.stats.end()
    },

    _updateValues () {
      if (!this.group) return

      this._controlMouseSlider()
      this._checkInViewMeshes()
    },

    _controlMouseSlider () {
      if (Math.abs(this.group.position.x) > this.groupBoudingBox.max.x + GROUP_TO_LEFT && this.mouse.normalize.x > 0) return
      if (this.group.position.x > 0 && this.mouse.normalize.x < 0) return

      if (this.mouse.normalize.x < -0.3 || this.mouse.normalize.x > 0.3) this.group.position.x = (this.group.position.x - (this.mouse.normalize.x / this.slide.speed))

      this._updateSliderPosition(Math.abs(this.group.position.x) / (this.groupBoudingBox.max.x + GROUP_TO_LEFT))
    },

    _checkInViewMeshes () {
      for (let i = 0; i < this.group.children.length; i++) offscreen(this.group.children[i], this.camera) ? this.group.children[i].visible = true : this.group.children[i].visible = false
    },

    _updateSliderPosition (amount) {
      this.$refs.rangeSlider.changeValueHandler(amount)

      this.rangeSlider.value = Math.abs(this.group.position.x) / (this.groupBoudingBox.max.x + GROUP_TO_LEFT) * amount
      this.group.position.x = (this.groupBoudingBox.max.x + GROUP_TO_LEFT) * (amount * -1.0)
    },

    _setupGUI () {
      this.gui.add(this.slide, 'speed', 0, 300.0).name('speed').step(1)
    },

    // HANDLERS
    _tickHandler () {
      gsap.ticker.add(this._renderScene)
    },

    _rangeInputHandler (value) {
      this._updateSliderPosition(value)
    },

    _rangeChangeHandler () {
      // console.log('done')
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
