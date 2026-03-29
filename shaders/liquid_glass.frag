#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec2 uOffset;
uniform vec2 uScreenSize;
uniform sampler2D uTexture;

out vec4 fragColor;

float sdfRect(vec2 center, vec2 size, vec2 p, float r) {
vec2 q = abs(p - center) - size;
return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

vec3 getNormal(float sd, float thickness) {
    float dx = dFdx(sd);
    float dy = dFdy(sd);
    float n_cos = max(thickness + sd, 0.0) / thickness;
    return normalize(vec3(dx * n_cos, dy * n_cos, sqrt(1.0 - n_cos * n_cos)));
}

float heightAtSd(float sd, float t) {
    if (sd >= 0.0) return 0.0;
    if (sd < -t) return t;
    float x = t + sd;
    return sqrt(t * t - x * x);
}

void main() {
    vec2 local = FlutterFragCoord().xy;

    vec2 localF  = vec2(local.x, uSize.y - local.y);
    vec2 offsetF = vec2(uOffset.x, uScreenSize.y - uOffset.y - uSize.y);
    vec2 global  = localF + offsetF;
    vec2 uv      = global / uScreenSize;

    float radius    = 28.0;
    float thickness = 18.0;
    float ior       = 1.45;
    float baseH     = thickness * 10.0;

    vec2  center = uSize * 0.5;
    float sd     = sdfRect(center, uSize * 0.5 - vec2(radius), local, radius);

    if (sd > 1.0) {
        fragColor = vec4(0.0);
        return;
    }

    vec3 normal     = getNormal(sd, thickness);
    vec3 incident   = vec3(0.0, 0.0, -1.0);
    vec3 refractVec = refract(incident, normal, 1.0 / ior);
    vec3 reflectVec = reflect(incident, normal);

    float h    = heightAtSd(sd, thickness);
    float rLen = (h + baseH) / max(dot(vec3(0.0, 0.0, -1.0), refractVec), 0.001);

    vec2 refractUV  = (global + refractVec.xy * rLen) / uScreenSize;
    vec4 refractCol = texture(uTexture, refractUV);

    // Блик только на краях (где нормаль отклонена)
    float edgeFactor = pow(1.0 - normal.z, 6); // резкий только на краях
    float c = clamp(abs(reflectVec.x - reflectVec.y), 0.0, 1.0) * edgeFactor;
    vec4 reflectCol = vec4(c, c, c, 1.0);

    // Рефракция — основа, почти без примесей в центре
    vec4 color = mix(refractCol, reflectCol, edgeFactor * 0.8);

    // Тонкая белая обводка по краю (имитация стекла)
    float rimLight = smoothstep(-thickness, -thickness * 0.05, sd)
                     * (1.0 - smoothstep(-thickness * 0.05, 0.0, sd));
    color.rgb += vec3(rimLight * 0.05);

    // Alpha: полностью непрозрачен внутри, мягкий край
    float alpha = 1.0 - smoothstep(-1.5, 1.0, sd);
    fragColor = vec4(color.rgb, alpha);
}