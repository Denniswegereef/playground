<template>
  <section class="container">
    <Canvas ref="canvas" />
  </section>
</template>

<script>
import debounce from 'lodash.debounce'

import base from '~/mixins/base.js'
import Canvas from '~/components/webgl/canvas.vue'
import fragmentShader from '~/components/webgl/wave-motion/fragment.glsl'
import vertexShader from '~/components/webgl/wave-motion/vertex.glsl'

// import lerp from '~/helpers/lerp'

const THREE = require('three')
const { gsap } = require('gsap')

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
      gui: null,
      timelines: {
        progress: gsap.timeline({ paused: true })
      },
      window: {
        height: 0,
        width: 0
      },
      uniforms: {
        u_time: { type: 'float', value: 0.0 },
        u_tex: { type: 'sampler2D', value: '' },
        u_resolution: { value: { x: 0.0, y: 0.0 } },
        u_noise_frequency: { type: 'float', value: 3.5 },
        u_noise_amplitude: { type: 'float', value: 0.15 },
        u_wave_strenght: { type: 'float', value: 0.2 },
        u_duration: { type: 'float', value: 1.2 },
        u_progress: { type: 'float', value: 0.0 }
      },
      intersected: null
    }
  },

  mounted () {
    this.enableStats()

    this._setupRenderer()
    this._setupCamera()
    this._setupRayCaster()

    this._setupScreenDimensions()
    this._setupEventListeners()
    this._setupTimelines()

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
    },

    _setupCamera () {
      this.camera = new THREE.PerspectiveCamera(35, this.window.width / this.window.height, 1, 1000)
      this.camera.position.z = 1.5
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

    _setupRayCaster () {
      this.raycaster = new THREE.Raycaster()
    },

    _setupEventListeners () {
      this._tickHandler()
      this._resizeHandler()
      this._mouseMoveHandler()
    },

    _setupTimelines () {
      const tl = this.timelines.progress
      tl.to(this.uniforms.u_progress, { value: 1.0, ease: 'Power2.easeOut', duration: this.uniforms.u_duration.value })
    },

    // SCENE
    _createPlane () {
      const textureLoader = new THREE.TextureLoader()
      const texture = require('~/assets/images/wave-motion.png')
      const loadedTexture = textureLoader.load(texture)

      this.uniforms.u_tex.value = loadedTexture

      const geometry = new THREE.PlaneGeometry(0.4, 0.6, 16, 16)

      const shaderMaterial = new THREE.ShaderMaterial({
        uniforms: this.uniforms,
        vertexShader,
        fragmentShader
      })

      return new THREE.Mesh(geometry, shaderMaterial)
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

    _updateMouse () {
      this._updateIntersected()
    },

    _updateIntersected () {
      this.raycaster.setFromCamera(this.mouse.normalize, this.camera)
      const intersects = this.raycaster.intersectObject(this.plane, false)

      if (intersects.length > 0) {
        const intersectObject = intersects[0].object
        if (this.intersected === intersectObject) this._raycasterCasting(intersectObject)
        else if (this.intersected !== intersectObject) {
          this._raycasterStart()
          this.intersected = intersectObject
        }
      } else if (this.intersected) {
        this._raycasterStop()
        this.intersected = null
      }
    },

    _raycasterStart () {
      this.timelines.progress.play()
      document.body.style.cursor = 'pointer'
      gsap.to(this.plane.scale, { x: 1.1, y: 1.1, duration: 0.8 })
    },

    _raycasterStop () {
      this.timelines.progress.reverse()
      document.body.style.cursor = 'auto'
      this.planeRotate = false
      gsap.to(this.plane.rotation, { x: 0.0, y: 0.0, duration: 0.3 })
      gsap.to(this.plane.scale, { x: 1.0, y: 1.0, duration: 0.3 })
    },

    _raycasterCasting () {},

    _setupGUI () {
      this.gui.add(this.camera.position, 'z', 1, 20).name('Camera Z').step(0.1)
      this.gui.add(this.uniforms.u_noise_frequency, 'value', 0, 15).name('nFrequency').step(0.05)
      this.gui.add(this.uniforms.u_noise_amplitude, 'value', 0, 1.5).name('nAmplitude').step(0.05)
      this.gui.add(this.uniforms.u_wave_strenght, 'value', 0, 1).name('RGb Strenght').step(0.05)

      const guiFolderTiming = this.gui.addFolder('Timing')
      guiFolderTiming.add(this.uniforms.u_progress, 'value', 0, 1).name('Progress').step(0.05).listen()
      guiFolderTiming.add(this.uniforms.u_duration, 'value', 0, 5).name('Duration').step(0.1).listen().onChange(this._updateTimelines)
      guiFolderTiming.open()
    },

    _updateTimelines () {
      this.timelines.progress = gsap.timeline({ paused: true })
      this._setupTimelines()
    },

    // HANDLERS
    _tickHandler () {
      gsap.ticker.add(this._renderScene)
    },

    _mouseMoveHandler () {
      window.addEventListener('mousemove', this._updateMouse)
    },

    _resizeHandler () {
      this.$data.resize = debounce(this._setupScreenDimensions.bind(this), 250)
      window.addEventListener('resize', this.$data.resize)
    }
  }
}
</script>
