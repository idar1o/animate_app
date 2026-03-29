#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 iResolution;
uniform float iTime;

out vec4 fragColor;

void main() {

    vec2 uv = FlutterFragCoord().xy / iResolution;

    float color =
        sin(uv.x * 10.0 + iTime) +
        sin(uv.y * 10.0 + iTime) +
        sin((uv.x + uv.y) * 10.0 + iTime);

    color /= 3.0;

    fragColor = vec4(
        0.5 + 0.5*sin(color + 0.0),
        0.5 + 0.5*sin(color + 2.0),
        0.5 + 0.5*sin(color + 4.0),
        1.0
    );
}