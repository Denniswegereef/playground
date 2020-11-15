varying vec2 vUv;
varying vec4 vPosition;

uniform float u_time;
uniform float u_progress;
uniform sampler2D u_tex;
uniform sampler2D u_texture2;
uniform vec4 u_resolution;

float rows = 5.0;

float hash1(float p) {
	vec2 p2 = fract(p * vec2(5.3983, 5.4427));
    p2 += dot(p2.yx, p2.xy + vec2(21.5351, 14.3137));
	return fract(p2.x * p2.y * 95.4337);
}

void main(){
  vec2 newUV = vUv;
  newUV.x -= 0.5;
  newUV.x *= 0.25 * u_resolution.x / u_resolution.y;
  newUV.x += 0.5;

  float stepY = 0.5 + ceil(newUV.y * rows) / rows;

  float scroll = (u_time * 0.01) * (0.5 + hash1(stepY));

  float sides = 2.0 * length(vUv.x - 0.5);
  float masking = step(0.9, sides);
  float shade = 10.0 * (sides - 0.9) * masking;
  shade = pow(shade, 5.0);

  newUV = (newUV - vec2(0.5, stepY - 0.1)) * vec2(1.0 + 0.1 * shade, 1.0 + 0.1 * shade) + vec2(0.5, stepY - 0.1);

  newUV.x = mod(newUV.x - scroll + u_progress + hash1(stepY), 1.0);

  newUV = fract(newUV * rows);
  vec4 texture = texture2D(u_tex, newUV);
  gl_FragColor = vec4(vUv, 0.0, 1.0);
  gl_FragColor = texture;
  // gl_FragColor = vec4(step);
  // gl_FragColor = vec4(newUV.x, newUV.y, 0.0, 1.0);
}
