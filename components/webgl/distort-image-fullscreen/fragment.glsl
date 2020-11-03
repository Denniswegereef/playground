varying vec2 vUv;
varying vec4 vPosition;

uniform float u_time;
uniform vec2 u_mouse;
uniform float u_progress;
uniform sampler2D u_texture1;
uniform sampler2D u_texture2;
uniform vec4 u_resolution;

void main(){
  vec2 newUV = (vUv - vec2(0.5)) * u_resolution.zw + vec2(0.5);
  vec4 color = texture2D(u_texture1, newUV);

  float mouseDist = length(vUv - u_mouse) * 2.0;

  gl_FragColor = vec4(u_progress, 0.0, 0.0, 1.0);
  gl_FragColor = vec4(mouseDist, 0.0, 0.0, 1.0);
  gl_FragColor = vec4(color.r, color.g, color.b, 1.0);
}
