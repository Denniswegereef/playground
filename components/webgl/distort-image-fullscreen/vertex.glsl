varying vec4 vPosition;
varying vec2 vUv;

uniform float u_time;
uniform vec2 u_pixels;

void main(){
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
