varying vec2 vUv;

uniform float u_hover;
uniform float u_time;
uniform vec2 u_intersect;

uniform float u_hoverRadius;
uniform float u_amplitude;
uniform float u_speed;

void main() {
  vUv = uv;
  vec4 _plane = modelMatrix * vec4(position, 1.0);

  if (u_hover > 0.0) {
    float _wave = u_hover * u_amplitude * sin(u_speed * (position.x + position.y + u_time));
    float _dist = length(uv - u_intersect);
    float _inCircle = 1.0 - (clamp(_dist, 0.0, u_hoverRadius) / u_hoverRadius);
    float _distort = _inCircle * _wave;

    _plane.z += _distort;
  }

  gl_Position = projectionMatrix * modelViewMatrix * _plane;
}
