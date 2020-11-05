varying vec2 vUv;
// We passed this one
uniform float u_time;
uniform float u_frequency1;
uniform float u_amplitude1;
uniform float u_frequency2;
uniform float u_amplitude2;

void main() {
  vUv = uv;

  vec3 p = vec3(position.x, position.y, position.z);
  // Oscillate vertices up/down
  p.y += (sin(p.x * u_frequency1 + u_time) * 0.5 + 0.5) * u_amplitude1;

  // Oscillate vertices inside/outside
  p.z += (sin(p.x * u_frequency2 + u_time) * 0.5 + 0.5) * u_amplitude2;

  gl_Position = projectionMatrix * modelViewMatrix * vec4(p, 1.0);
}
