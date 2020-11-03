varying vec2 vUv;
varying vec4 vPosition;

uniform float u_time;
uniform vec2 u_mouse;
uniform float u_mouse_speed;
uniform float u_progress;
uniform sampler2D u_texture1;
uniform sampler2D u_texture2;
uniform vec4 u_resolution;

void main(){
  float normSpeed = clamp(u_mouse_speed, 0.0, 1.0);

  vec2 newUV = (vUv - vec2(0.5)) * u_resolution.zw + vec2(0.5);

  vec4 color = texture2D(u_texture1, newUV);

  float mouseDist = length(vUv - u_mouse) * 2.0;

  float circle = smoothstep(0.6 * normSpeed, 0.0, mouseDist);
  float r = texture2D(u_texture1, newUV + 0.1 * 0.5 * circle * normSpeed).r;
  float g = texture2D(u_texture1, newUV + 0.1 * 0.3 * circle * normSpeed).g;
  float b = texture2D(u_texture1, newUV + 0.1 * 0.1 * circle * normSpeed).b;

  gl_FragColor = vec4(u_progress, 0.0, 0.0, 1.0);
  gl_FragColor = vec4(circle, 0.0, 0.0, 1.0);
  gl_FragColor = vec4(r, g, b, 1.0);
}
