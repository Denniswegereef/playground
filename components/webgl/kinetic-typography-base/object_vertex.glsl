varying vec4 vPosition;
varying vec2 vUv;
varying vec3 vPos;

uniform float u_time;
uniform vec2 u_pixels;

void main(){
  vUv = uv;
  vec3 pos = position;
  vPos = pos;

  gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}
