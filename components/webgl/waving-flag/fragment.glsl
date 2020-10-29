// uniform vec2 u_resolution;
varying vec2 vUv;
varying float vWave;

uniform float u_time;
uniform sampler2D u_tex;

void main(){
  // vec3 texture = texture2D(u_tex, vUv).rgb;

  float wave = vWave * 0.01;
  float r = texture2D(u_tex, vUv).r;
  float g = texture2D(u_tex, vUv).g;
  float b = texture2D(u_tex, vUv + wave).b;

  vec3 texture = vec3(r, g, b);

  gl_FragColor = vec4(texture, 1.0);
}
