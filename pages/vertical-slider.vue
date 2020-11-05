<template>
  <section class="container">
    <div ref="block" class="block" />
    <div v-for="(item, index) in 5" :key="index" ref="line" class="line" :class="`line-${index}`"/>
    <Canvas ref="canvas" @canvasResizeHandler="_resizeScreenHandler" />
  </section>
</template>

<script>
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls'

import base from '~/mixins/base.js'
import Canvas from '~/components/webgl/canvas.vue'
import fragmentShader from '~/components/webgl/vertical-slider/fragment.glsl'
import vertexShader from '~/components/webgl/vertical-slider/vertex.glsl'

const THREE = require('three')
const { gsap } = require('gsap')

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
      camera: null,
      renderer: null,
      gui: null,
      paused: false,
      orbitControls: false,
      window: { height: 0, width: 0 },
      uniforms: {
        u_time: { type: 'f', value: 0.0 },
        u_resolution: { type: 'v4', value: new THREE.Vector4() },
        uvRate1: { type: 'v2', value: new THREE.Vector2(1, 1) }
      },
      speed: 0,
      position: 0,
      rounded: 0
    }
  },

  mounted () {
    document.body.style.overflow = 'hidden'

    console.log(this.$refs.line)

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
    document.body.style.overflow = ''
    gsap.ticker.remove(this._renderScene)
    document.removeEventListener('visibilitychange', this._changeVisibilityStatus)
    document.removeEventListener('wheel', this._userScrolling)
  },

  methods: {
    _setUpEventListeners () {
      this._tickHandler()
      this._wheelHandler()
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

      const shaderMaterial = new THREE.ShaderMaterial({
        uniforms: this.uniforms,
        vertexShader,
        fragmentShader,
        extensions: { derivatives: '#extension GL_OES_standard_derivatives : enable' },
        side: THREE.DoubleSide
      })

      return new THREE.Mesh(geometry, shaderMaterial)
    },

    _createScene () {
      this.plane = this._createPlaneGeometry()

      // this.scene.add(this.plane)
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

    _useFrame () {
      this.position += this.speed
      this.speed *= 0.8

      this.rounded = Math.round(this.position)

      const diff = (this.rounded - this.position)
      // console.log(diff)

      this.position += Math.sign(diff) * (Math.abs(diff) ** 0.7) * 0.015

      this.$refs.block.style.transform = `translate(0, ${this.position * 100}px)`
    },

    _userScrolling (event) {
      this.speed += event.deltaY * 0.0003
    },

    /*
    ** MISCELLANEOUS
    */

    _setupGUI () {
      this.gui.add(this.uniforms.u_time, 'value').name('Time').step(0.1).listen()
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

    _wheelHandler () {
      document.addEventListener('wheel', this._userScrolling)
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

<style lang="scss" scoped>
.block {
  position: absolute;
  top: rem(100px);
  left: rem(100px);

  height: rem(100px);
  width: rem(100px);

  background: red;

  z-index: 3;
}

.line {
  position: absolute;
  left: rem(75px);
  top: rem(100px);

  height: rem(2px);
  width: rem(200px);

  background: #fff;

  z-index: 3;
}

@for $i from 0 through 5 {
  .line-#{$i} {
    top: rem(100px) + (rem(100px) * $i);
  }
}
</style>
