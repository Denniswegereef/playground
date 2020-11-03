varying vec4 vPosition;
varying vec2 vUv;

uniform float u_time;
uniform vec2 u_pixels;
uniform float u_progress;
uniform float u_direction;

void main(){
  vec3 pos = position;

  float distance = length(uv - vec2(0.5));
  float maxdistance = length(vec2(0.5));

  float normalizedDistance = distance / maxdistance;

  float stickTo = normalizedDistance;
  float stickOut = -normalizedDistance;

  float stickEffect = mix(stickTo, stickOut, u_direction);

  float vTraingleProgress = min(2.0 * u_progress, 2.0 * (1.0 - u_progress));
  float zOffset = 2.0;
  float zProgress = mix(clamp(2.0 * u_progress, 0.0, 1.0), clamp(1.0 - 2.0 * (1.0 - u_progress), 0.0, 1.0), u_direction);

  pos.z += zOffset * (stickEffect * vTraingleProgress - zProgress);

  pos.z += u_progress * sin(distance * 10.0 + u_time * 2.0) * 0.2;

  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}
