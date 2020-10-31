<template>
  <section class="range-slider">
    <input
      ref="rangeSlider"
      v-model="value"
      type="range"
      :min="min"
      :max="max"
      value="0"
      step="any"
      @input="rangeInputHandler"
      @change="rangeChangeHandler">
  </section>
</template>

<script>
export default {
  data () {
    return {
      value: 0.0,
      min: 0,
      max: 1,
      currentValue: 0.0
    }
  },

  methods: {
    changeValueHandler (amount) {
      this.$refs.rangeSlider.value = amount
      this.currentValue = amount
    },

    rangeInputHandler () {
      this.$emit('inputHandler', this.value)
    },

    rangeChangeHandler () {
      this.$emit('changeHandler')
    }
  }
}
</script>

<style lang="scss" scoped>
.range-slider {
  position: fixed;
  bottom: rem(40px);
  left: calc(50% - #{rem(100px)});

  width: rem(200px);

  z-index: 2;
}

$track-color: rgba(255, 255, 255, 0.3);
$thumb-color: #fff;

$thumb-height: rem(15px);
$thumb-width: rem(15px);

$track-height: rem(2px);

@mixin track {
  cursor: default;
  height: $track-height;
  transition: all .2s ease;
  width: 100%;
}

@mixin thumb {
  height: $thumb-height;
  width: $thumb-width;

  border-radius: 100%;

  background: $thumb-color;

  cursor: pointer;
}

[type='range'] {
  -webkit-appearance: none;
  background: transparent;
  margin: $thumb-height / 2 0;
  width: 100%;

  &::-moz-focus-outer {
    border: 0;
  }

  &:focus {
    outline: 0;

    &::-ms-fill-lower,
    &::-webkit-slider-runnable-track,
    &::-ms-fill-upper {
      background: $track-color;
    }
  }

  &::-webkit-slider-runnable-track {
    @include track;
    background: $track-color;
  }

  &::-webkit-slider-thumb {
    @include thumb;
    -webkit-appearance: none;
    margin-top: (($track-height) / 2 - $thumb-height / 2);
  }

  &::-moz-range-track {
    @include track;
    background: $track-color;
    height: $track-height / 2;
  }

  &::-moz-range-thumb {
    @include thumb;
  }

  &::-ms-track {
    @include track;
    background: transparent;
    color: transparent;
  }

  &::-ms-fill-lower {
    // background: $ie-bottom-track-color;
  }

  &::-ms-fill-upper {
    background: $track-color;
  }

  &::-ms-thumb {
    @include thumb;
    margin-top: $track-height / 4;
  }

  &:disabled {
    &::-webkit-slider-thumb,
    &::-moz-range-thumb,
    &::-ms-thumb,
    &::-webkit-slider-runnable-track,
    &::-ms-fill-lower,
    &::-ms-fill-upper {
      cursor: not-allowed;
    }
  }
}
</style>
