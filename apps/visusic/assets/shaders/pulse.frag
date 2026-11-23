#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform float u_time;
uniform float u_intensity;
uniform float u_speed;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  float d = distance(uv, vec2(0.5));
  float pulse = 0.5 + 0.5 * sin(u_time * u_speed - d * 12.0);
  vec3 a = vec3(0.49, 0.30, 1.0);
  vec3 b = vec3(0.24, 0.86, 0.59);
  vec3 color = mix(a, b, uv.x) + pulse * u_intensity;
  fragColor = vec4(color, 1.0);
}
