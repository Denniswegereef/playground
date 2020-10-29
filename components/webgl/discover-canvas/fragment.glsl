// uniform float u_time;
// uniform vec2 u_resolution;
varying vec2 vUv;

uniform sampler2D u_tex;

void main(){
  vec3 texture = texture2D(u_tex, vUv).rgb;
  gl_FragColor = vec4(texture, 1.0);
}
