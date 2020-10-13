<template>
  <div>test</div>
</template>

<script>
import base from '~/mixins/base.js'
import fragmentShader from '~/components/webgl//hover-displacement/fragment.glsl'

const THREE = require('three')

export default {
  mixins: [base],

  mounted () {
    console.log(this._isDevelopment())
    console.log(process.env.NODE_ENV, THREE)
    console.log(fragmentShader)
  }
}
</script>
