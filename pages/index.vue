<template>
  <div class="home">
    <ul class="home__list">
      <li v-for="item in filteredRoutes" :key="item.path" class="home__list-item">
        <nuxt-link
          :to="item.path"
          :prefetch="false"
          class="button home__button">
          {{ item.name | formatName }}
        </nuxt-link>
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  filters: {
    formatName (string) {
      return (string.charAt(0).toUpperCase() + string.slice(1)).replace(/-/g, ' ')
    }
  },

  data () {
    return {
      filteredRoutes: []
    }
  },

  beforeMount () {
    this.filteredRoutes = this.$router.options.routes.filter(item => item.name !== 'index')
  },

  mounted () {
    console.log(this)
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
    padding: 0;
  }
}
</style>
