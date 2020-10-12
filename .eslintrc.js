module.exports = {
  root: true,
  env: {
    browser: true,
    node: true
  },
  parserOptions: {
    parser: 'babel-eslint'
  },
  extends: [
    '@nuxtjs',
    'plugin:nuxt/recommended'
  ],
  plugins: [],
  // add your custom rules here
  rules: {
    curly: [2, "multi"],
    "vue/html-closing-bracket-newline": [1, {
      "singleline": "never",
      "multiline": "never"
    }],
    'vue/no-v-html': 0
  }
}
