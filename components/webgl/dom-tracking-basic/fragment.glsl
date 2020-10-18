// https://www.shadertoy.com/view/ls3Xzf

varying vec2 vUv;

uniform sampler2D u_tex;
uniform float u_time;

float rand () {
  return fract(sin(u_time) * 1e4);
}

void main() {
  vec2 uv = vUv.xy;

  vec2 uvR = uv;
  vec2 uvB = uv;

  uvR.x = uv.x * 1.0 - rand() * 0.02 * 0.8;
  uvB.y = uv.y * 1.0 + rand() * 0.02 * 0.4;

  if (uv.y < rand() && uv.y > rand() -0.1 && sin(u_time) < 0.0) {
    uv.x = (uv + 0.02 * rand()).x;
  }

  vec3 color;
  color.r = texture2D(u_tex, uvR).r;
  color.g = texture2D(u_tex, uv).g;
  color.b = texture2D(u_tex, uvB).b;

  float scanline = sin( uv.y * 800.0 * rand()) / 30.0;
	color *= 1.0 - scanline;

  float vegDist = length(( 0.5 , 0.5 ) - uv);
  color *= 1.0 - vegDist * 0.6;

  gl_FragColor = vec4(color, 1.0);
}
