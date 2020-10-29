#pragma glslify: snoise = require(glsl-noise/classic/3d)

varying vec2 vUv;
varying float vWave;

uniform float u_time;
uniform float u_depth;
uniform float u_noise_amplitude;

void main(){
  vUv = uv;
  vec3 pos = position;
  float displacement = snoise((u_depth) * pos + u_time);

  if (pos.y < 0.8) {
    float waveX2 = (pos.x * u_noise_amplitude + displacement);
    pos.z += waveX2 / 10.0;
  }

  for(int i = 0; i < 10; ++i) {
    float i_float = float(i);

    if (pos.y < (i_float / 10.0) && pos.x > (i_float / 10.0)) {
      // float waveX2 = (pos.x * u_noise_amplitude + displacement);
      pos.z += i_float / 100.0;
    }
  }

  // vWave = pos.z;


  gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}
