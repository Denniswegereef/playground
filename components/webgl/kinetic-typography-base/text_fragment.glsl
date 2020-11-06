uniform float u_opacity;
uniform vec3 u_color;
uniform sampler2D u_tex;
varying vec2 vUv;

uniform float u_time;

float median(float r, float g, float b) {
  return max(min(r, g), min(max(r, g), b));
}


void main() {
  // This is the code that comes to produce msdf
  vec3 tex = texture2D(u_tex, vUv).rgb;
  float sigDist = median(tex.r, tex.g, tex.b) - 0.5;
  float alpha = clamp(sigDist/fwidth(sigDist) + 0.5, 0.0, 1.0);

  gl_FragColor = vec4(vec3(1.0), alpha * u_opacity);
  if (gl_FragColor.a < 0.0001) discard;
}