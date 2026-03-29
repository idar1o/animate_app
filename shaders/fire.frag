#include <flutter/runtime_effect.glsl>

uniform vec2 resolution;
uniform float time;

out vec4 fragColor;

float noise(vec2 p) {
    return sin(p.x) * sin(p.y);
}

void main() {

    vec2 uv = FlutterFragCoord().xy / resolution;

    // центрируем
    uv = uv * 2.0 - 1.0;

    // движение вверх
    float t = time * 0.8;

    // искажение координат
    float n =
        noise(vec2(uv.x * 3.0, uv.y * 3.0 + t)) +
        noise(vec2(uv.x * 6.0, uv.y * 6.0 + t * 1.5));

    uv.x += n * 0.2;

    // интенсивность огня
    float flame = 1.0 - uv.y * 1.5;

    flame += n * 0.5;

    flame = clamp(flame, 0.0, 1.0);

    // цвет огня
    vec3 color = vec3(
        flame * 1.8,
        flame * flame * 1.2,
        flame * flame * flame * 0.5
    );

    fragColor = vec4(color, 1.0);
}