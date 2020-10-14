uniform sampler2D u_texture;
uniform vec2 u_ratio;

varying vec2 vUv;

void main () {
  vec2 uv = vec2(
    vUv.x * u_ratio.x + (1.0 - u_ratio.x) * 0.5,
    vUv.y * u_ratio.y + (1.0 - u_ratio.y) * 0.5
  );
  gl_FragColor = texture2D(u_texture, uv);
  // gl_FragColor = vec4(texture2D(u_texture, vUv).rgb, 1.0);
}
