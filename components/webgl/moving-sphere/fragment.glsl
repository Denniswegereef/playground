// https://www.shadertoy.com/view/Mt2XDK

varying vec2 vUv;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec3 u_color_one;
uniform vec3 u_color_two;

float circle(in vec2 _st, in float _radius){
  vec2 dist = _st-vec2(0.5);
  return 1.0 - smoothstep(_radius-(_radius * 0.874), _radius + (_radius * -0.242), dot(dist, dist) * 4.232);
}

void main(){
  vec2 uv = vUv.xy;

  float currentAngle = -(u_time * 36.0);

  vec2 origin = vec2(0.5, 0.5);
  uv -= origin;

  float angle = radians(90.0) - radians(currentAngle) + atan(uv.y, uv.x);
  float len = length(uv);
  uv = vec2(cos(angle) * len, sin(angle) * len) + origin;

  float mask = mix(0.0, 1.0, smoothstep(0.0, 1.0, uv.x));

  float distanceFromLight = length(uv - origin);

  vec3 color = vec3(circle(uv, 1.5));
  gl_FragColor = vec4(mix(u_color_one, u_color_two, smoothstep(0.0, 1.0, uv.y)), 1.0) * color.r;
}
