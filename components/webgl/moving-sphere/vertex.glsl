#pragma glslify: snoise = require(glsl-noise/classic/3d)

varying vec2 vUv;

uniform float u_time;
uniform float u_noise_frequency;
uniform float u_noise_amplitude;

void main(){
  vUv = uv;

  vec3 pos = position;
  float noiseFreq = u_noise_frequency;
  float noiseAmp = u_noise_amplitude;
  vec3 noisePos = vec3(pos.x * noiseFreq + u_time, pos.y, pos.z);
  pos.z += snoise(noisePos) * noiseAmp;

  gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}
