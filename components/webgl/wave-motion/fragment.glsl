varying vec2 vUv;
varying float vWave;

uniform sampler2D u_tex;
uniform float u_wave_strenght;

void main () {
  float wave = vWave * u_wave_strenght;
  float r = texture2D(u_tex, vUv - wave).r;
  float g = texture2D(u_tex, vUv).g;
  float b = texture2D(u_tex, vUv + wave).b;

  vec3 texture = vec3(r, g, b);
  // vec3 texture = texture2D(u_tex, vUv + wave).rgb;
  gl_FragColor = vec4(texture, 1.0);
}
