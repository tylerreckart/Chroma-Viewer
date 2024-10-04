#include <metal_stdlib>
using namespace metal;

constant float PI = 3.14159265359;

struct VertexOut {
    float4 position [[position]];
    float2 coord;
};

// Vertex function for the full-screen quad
vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
    float2 positions[] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2(-1.0,  1.0),
        float2( 1.0, -1.0),
        float2( 1.0,  1.0)
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.coord = positions[vertexID] * 0.5 + 0.5; // Normalize to [0, 1] range for fragment shader use

    return out;
}

// Simple Perlin-like noise function
float hash(float2 p) {
    p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
    return fract(sin(p.x) * 43758.5453123);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);

    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    float2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Utility function for applying kaleidoscope effect
float2 kaleidoscope(float2 coord, int segments) {
    float angle = atan2(coord.y - 0.5, coord.x - 0.5);
    float radius = length(coord - float2(0.5, 0.5));
    float segmentAngle = 2.0 * PI / float(segments);
    angle = fmod(angle, segmentAngle);
    return float2(cos(angle) * radius + 0.5, sin(angle) * radius + 0.5);
}

// Blending modes
float3 blendMultiply(float3 base, float3 blend) {
    return base * blend;
}

float3 blendScreen(float3 base, float3 blend) {
    return 1.0 - (1.0 - base) * (1.0 - blend);
}

float3 blendOverlay(float3 base, float3 blend) {
    return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), step(0.5, base));
}

float3 blendDifference(float3 base, float3 blend) {
    return abs(base - blend);
}

float3 blendHardLight(float3 base, float3 blend) {
    return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), step(0.5, blend));
}

float3 blendColorBurn(float3 base, float3 blend) {
    return 1.0 - (1.0 - base) / (blend + 0.001);
}

// Fragment function for the harmonious fluid-like gradient effect with optional distortion, Perlin noise, and kaleidoscopic warp
fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant float4 &gradientColor [[buffer(0)]],
                              constant float &time [[buffer(1)]],
                              constant float &colorMixFactor [[buffer(2)]],
                              constant float &baseHueOffset [[buffer(3)]],
                              constant float &redComponent [[buffer(4)]],
                              constant float &greenComponent [[buffer(5)]],
                              constant float &blueComponent [[buffer(6)]],
                              constant float &brightnessMultiplier [[buffer(7)]],
                              constant float &animationShapeFactor [[buffer(8)]],
                              constant bool &distortionMode [[buffer(9)]],
                              constant float &distortionRatio [[buffer(10)]],
                              constant float &distortionShape [[buffer(11)]],
                              constant float &distortionFrequencyRelation [[buffer(12)]],
                              constant float &chaosFactor [[buffer(13)]],
                              constant bool &perlinMode [[buffer(14)]],
                              constant float &perlinIntensity [[buffer(15)]],
                              constant float &perlinScale [[buffer(16)]],
                              constant float &perlinFrequency [[buffer(17)]],
                              constant bool &kaleidoscopeMode [[buffer(18)]],
                              constant int &kaleidoscopeSegments [[buffer(19)]],
                              constant float &warpIntensity [[buffer(20)]],
                              constant float &twistIntensity [[buffer(21)]],
                              constant int &perlinBlendMode [[buffer(22)]]) {

    float2 coord = in.coord;

    // Apply kaleidoscope effect if enabled
    if (kaleidoscopeMode) {
        coord = kaleidoscope(coord, kaleidoscopeSegments);
    }

    // Apply twisting and warping
    float angle = atan2(coord.y - 0.5, coord.x - 0.5) + twistIntensity * warpIntensity * sin(time);
    float radius = length(coord - float2(0.5, 0.5));
    coord = float2(cos(angle) * radius + 0.5, sin(angle) * radius + 0.5);

    // Wrap coordinates to keep them in [0, 1] range
    coord = clamp(coord, 0.0, 1.0);

    // Create a fluid-like evolving pattern using the modified coordinates
    float xMovement = sin(time * 0.5 * animationShapeFactor + coord.x * 5.0) * 0.5 + cos(time * 0.3 * animationShapeFactor + coord.y * 4.0) * 0.5;
    float yMovement = cos(time * 0.4 * animationShapeFactor + coord.y * 5.0) * 0.5 + sin(time * 0.6 * animationShapeFactor + coord.x * 3.0) * 0.5;

    float baseHue = 0.5 + 0.5 * sin(time * 0.2); // Base hue evolving smoothly
    float hueOffset1 = baseHue + baseHueOffset;  // Use baseHueOffset to adjust harmony
    float hueOffset2 = baseHue - baseHueOffset;  // Second analogous color

    float r = mix(gradientColor.r * redComponent, (0.5 + 0.5 * sin(time * 0.2 + xMovement)) * hueOffset1, colorMixFactor) * brightnessMultiplier * 1.5;
    float g = mix(gradientColor.g * greenComponent, (0.5 + 0.5 * sin(time * 0.3 + yMovement)) * hueOffset2, colorMixFactor) * brightnessMultiplier * 1.5;
    float b = mix(gradientColor.b * blueComponent, (0.5 + 0.5 * sin(time * 0.4 + xMovement + yMovement)) * baseHue, colorMixFactor) * brightnessMultiplier * 1.5;

    // Ensure the colors stay in the valid range [0, 1]
    r = clamp(r, 0.0, 1.0);
    g = clamp(g, 0.0, 1.0);
    b = clamp(b, 0.0, 1.0);

    float3 baseColor = float3(r, g, b);

    // Apply Perlin noise on top of the final image if perlinMode is enabled
    if (perlinMode) {
        float noiseValue = noise(coord * perlinScale + time * perlinFrequency);
        noiseValue = noiseValue * 0.5 + 0.5; // Normalize noise to [0, 1] range
        float3 noiseColor = float3(noiseValue) * perlinIntensity;

        switch (perlinBlendMode) {
            case 0: // Normal
                baseColor += noiseColor;
                break;
            case 1: // Multiply
                baseColor = blendMultiply(baseColor, noiseColor);
                break;
            case 2: // Screen
                baseColor = blendScreen(baseColor, noiseColor);
                break;
            case 3: // Overlay
                baseColor = blendOverlay(baseColor, noiseColor);
                break;
            case 4: // Difference
                baseColor = blendDifference(baseColor, noiseColor);
                break;
            case 5: // Hard Light
                baseColor = blendHardLight(baseColor, noiseColor);
                break;
            case 6: // Color Burn
                baseColor = blendColorBurn(baseColor, noiseColor);
                break;
        }

        baseColor = clamp(baseColor, 0.0, 1.0);
    }

    return float4(baseColor, 1.0);
}
