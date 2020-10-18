<template>
  <section ref="container" class="container">
    <Canvas ref="canvas" />
    <div v-if="content" class="content">
      <ul class="list">
        <li v-for="(item, index) in content" :key="index" class="list__item">
          <img ref="image" :src="item" alt="" class="image">
          <h2 class="heading">
            {{ text[index] }}
          </h2>
        </li>
      </ul>
    </div>
  </section>
</template>

<script>
// https://threejsfundamentals.org/threejs/lessons/threejs-multiple-scenes.html

import debounce from 'lodash.debounce'

import base from '~/mixins/base.js'
import Canvas from '~/components/webgl/canvas.vue'
import fragmentShader from '~/components/webgl/dom-tracking-basic/fragment.glsl'
import vertexShader from '~/components/webgl/dom-tracking-basic/vertex.glsl'

const THREE = require('three')
const { gsap } = require('gsap')

const IMAGE_PATH = '/images/dom-tracking-basic/'
const IMAGE_AMOUNT = 4
const TEXT = [
  'Senayan, South Jakarta City, Jakarta',
  'Simon Fraser University, Burnaby',
  'Antwerpen Central, Antwerpen',
  'Flatiron District, Manhattan, New York'
]

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
      content: [],
      text: TEXT,
      sceneElements: [],
      uniformsArray: [],
      test: { name: 'test' }
    }
  },

  beforeMount () {
    for (let i = 0; i < IMAGE_AMOUNT; i++) this.content.push(`${IMAGE_PATH}image-${i + 1}.png`)
  },

  mounted () {
    this.enableStats()

    this._setupRenderer()
    this._setUpEventListeners()

    this._createScene()

    this._setupScreenDimensions()

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
      this.renderer = new THREE.WebGLRenderer({ canvas: this.$refs.canvas.$el, alpha: true })
      this.renderer.setClearColor(0x32A8A8, 0)
    },

    _setupScreenDimensions () {
      this.window.width = window.innerWidth
      this.window.height = window.innerHeight

      this.uniformsArray.forEach((item, index) => {
        this.uniformsArray[index].u_resolution.value.x = this.window.width
        this.uniformsArray[index].u_resolution.value.y = this.window.height
      })

      this.renderer.setSize(this.window.width, this.window.height)
      this.renderer.setPixelRatio(window.devicePixelRatio)
    },

    _setUpEventListeners () {
      this._tickHandler()
      this._resizeHandler()
    },

    _createIndividualScene (element, index) {
      const uniforms = {
        u_tex: { value: '' },
        u_time: { value: 0.0 },
        u_resolution: { type: 'v2', value: { x: 0.0, y: 0.0 } }
      }

      const scene = new THREE.Scene()
      const camera = new THREE.OrthographicCamera(1, -1, 1, -1, 0.1, 10)
      camera.position.z = 1

      const textureLoader = new THREE.TextureLoader()
      const loadedTexture = textureLoader.load(element.src)

      uniforms.u_tex.value = loadedTexture

      camera.position.z = 3
      scene.userData.camera = camera

      this.uniformsArray.push(uniforms)

      const geometry = new THREE.PlaneGeometry(2, 2)

      const shaderMaterial = new THREE.ShaderMaterial({
        uniforms: this.uniformsArray[index],
        vertexShader,
        fragmentShader,
        side: THREE.DoubleSide
      })

      scene.add(new THREE.Mesh(geometry, shaderMaterial))

      element.style.opacity = 0

      return scene
    },

    // SCENE

    _createScene () {
      this.$refs.image.forEach((item, index) => {
        this.sceneElements.push(this._createIndividualScene(item, index))
      })
    },

    _renderScene () {
      this.stats.begin()

      const elapsedTime = this.clock.getElapsedTime()

      this.renderer.setScissorTest(false)
      this.renderer.clear()
      this.renderer.setScissorTest(true)

      this._updateValues()

      this.sceneElements.forEach((scene, index) => {
        this.uniformsArray[index].u_time.value = elapsedTime

        const element = this.$refs.image[index]
        const rect = element.getBoundingClientRect()

        if (rect.bottom < 0 || rect.top > this.renderer.domElement.clientHeight || rect.right < 0 || rect > this.renderer.domElement.width) return

        const width = rect.right - rect.left
        const height = rect.bottom - rect.top
        const left = rect.left
        const bottom = this.window.height - rect.bottom

        this.renderer.setViewport(left, bottom, width, height)
        this.renderer.setScissor(left, bottom, width, height)

        const camera = scene.userData.camera

        this.renderer.render(scene, camera)
      })

      this.stats.end()
    },

    _updateValues () {},

    _setupGUI () {},

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

<style lang="scss" scoped>
.content {
  padding: rem(150px) rem(30px);
}

.heading {
  padding-top: rem(5px);

  font-size: rem(11px);

  opacity: 0.7;
}

.list__item {
  margin-bottom: rem(50px);

  &:last-of-type {
    margin-bottom: 0;
  }
}

.image {
  width: 100%;
}

@include mq-regular {
  .content {
    padding: rem(200px) rem(50px);
  }

  .list {
    display: grid;
    grid-template-columns: repeat(5, 1fr);
    grid-template-rows: repeat(6, rem(300px));
  }

  .list__item {
    &:nth-of-type(1) {
      grid-area: 1 / 1 / 3 / 3;
    }

    &:nth-of-type(2) {
      grid-area: 2 / 4 / 4 / 6;

      margin-top: 40%;
    }

    &:nth-of-type(3) {
      grid-area: 4 / 1 / 6 / 3;

      margin-left: 5%;
    }

    &:nth-of-type(4) {
      grid-area: 5 / 4 / 7 / 6;
      margin-right: 20%;
    }
  }
}

@include mq-wide {
  .content {
    width: 90vw;
    max-width: rem(1100px);

    margin: 0 auto;
    padding: rem(300px) 0;
  }
}
</style>
