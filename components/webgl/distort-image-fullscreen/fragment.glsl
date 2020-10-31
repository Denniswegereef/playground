varying vec2 vUv;
varying vec4 vPosition;

uniform float u_time;
uniform float u_progress;
uniform sampler2D u_texture1;
uniform sampler2D u_texture2;
uniform vec4 u_resolution;

void main(){
  gl_FragColor = vec4(vUv, 0.0, 1.0);
}
