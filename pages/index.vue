<template>
  <div class="home">
    <ul class="home__list">
      <li v-for="item in $router.options.routes" :key="item.path" class="home__list-item">
        <nuxt-link
          :to="item.path"
          :prefetch="false"
          class="button home__button">
          {{ item.name }}
        </nuxt-link>
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  data () {
    return {
      routes: []
    }
  }
}
</script>

<style lang="scss" scoped>
.home {
  display: flex;
  align-items: center;
  justify-content: center;

  min-height: 100vh;
  width: 100%;

  text-align: center;
}

.home__list-item {
  padding-bottom: rem(15px);

  &:last-of-type {
    margin: 0;
  }
}
</style>
