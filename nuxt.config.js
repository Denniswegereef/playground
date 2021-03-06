export default {
  mode: 'universal',
  /*
   ** Headers of the page
   */
  head: {
    title: 'Playground',
    meta: [
      { charset: 'utf-8' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      {
        hid: 'description',
        name: 'description',
        content: process.env.npm_package_description || ''
      }
    ],
    link: [{ rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' }]
  },
  /*
   ** Customize the progress-bar color
   */
  loading: { color: '#fff' },
  /*
   ** Global CSS
   */
  css: [
    '~/scss/main.scss'
  ],

  styleResources: {
    scss: ['~/scss/*.scss']
  },
  /*
   ** Plugins to load before mounting the App
   */
  plugins: [],
  /*
   ** Nuxt.js dev-modules
   */
  buildModules: [
    // Doc: https://github.com/nuxt-community/eslint-module
    '@nuxtjs/eslint-module',
    '@nuxtjs/style-resources',
    '@nuxtjs/svg'
  ],
  /*
   ** Nuxt.js modules
   */
  modules: [
    // Doc: https://github.com/nuxt-community/dotenv-module
    '@nuxtjs/dotenv'
  ],

  /*
   ** Build configuration
   */
  build: {
    /*
     ** You can extend webpack config here
     */
    transpile: [
      'three'
    ],
    extend (config, { isDev, isClient }) {
      // config.module.rules.push({ test: /\.(glsl|vs|fs|vert|frag)$/, loader: 'glslify-loader', exclude: /(node_modules)/ })
      // config.module.rules.push({ test: /\.(glsl|vs|fs|vert|frag)$/, loader: 'glslify-loader', exclude: /(node_modules)/ })
      config.module.rules.push({ test: /\.glsl$/, use: ['webpack-glsl-loader', 'glslify-loader'], exclude: /(node_modules)/ })
    }
  },
  server: {
    host: '0.0.0.0'
  }
}
