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

// Utility function to generate random values based on input coordinates
float random(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

// Improved kaleidoscope function to ensure even slicing into segments
float2 kaleidoscope(float2 coord, int segments) {
    float2 center = float2(0.5, 0.5);
    float2 offset = coord - center;

    // Calculate the polar coordinates (radius and angle)
    float radius = length(offset);
    float angle = atan2(offset.y, offset.x);

    // Calculate the segment angle for even division
    float segmentAngle = 2.0 * PI / float(segments);

    // Wrap the angle to ensure it stays within the bounds of a single segment
    float wrappedAngle = fmod(angle + PI, segmentAngle) - segmentAngle * 0.5;

    // Reflect the angle to create symmetry within each segment
    wrappedAngle = abs(wrappedAngle);
    
    // Convert back to Cartesian coordinates
    float2 newCoord = float2(cos(wrappedAngle), sin(wrappedAngle)) * radius + center;
    return newCoord;
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

// Fragment function for fluid-like gradient effect with optional distortion, noise noise, glitch, kaleidoscopic warp
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
                              constant float &amplitude [[buffer(9)]],
                              constant float &pitch [[buffer(10)]],
                              constant bool &distortionMode [[buffer(11)]],
                              constant float &distortionRatio [[buffer(12)]],
                              constant float &distortionShape [[buffer(13)]],
                              constant float &distortionFrequencyRelation [[buffer(14)]],
                              constant float &chaosFactor [[buffer(15)]],
                              constant bool &noiseMode [[buffer(16)]],
                              constant float &noiseIntensity [[buffer(17)]],
                              constant float &noiseScale [[buffer(18)]],
                              constant float &noiseFrequency [[buffer(19)]],
                              constant bool &kaleidoscopeMode [[buffer(20)]],
                              constant int &kaleidoscopeSegments [[buffer(21)]],
                              constant float &warpIntensity [[buffer(22)]],
                              constant float &twistIntensity [[buffer(23)]],
                              constant int &noiseBlendMode [[buffer(24)]],
                              constant bool &glitchMode [[buffer(25)]],
                              constant float &glitchFrequency [[buffer(26)]],
                              constant float &glitchSize [[buffer(27)]],
                              constant float &colorShiftSpeed [[buffer(28)]]) {

    float2 coord = in.coord;

    // Apply glitch effect if enabled
    if (glitchMode) {
        float glitchX = (random(float2(coord.x * glitchFrequency, time)) - 0.5) * glitchSize;
        float glitchY = (random(float2(coord.y * glitchFrequency, time)) - 0.5) * glitchSize;

        coord += float2(glitchX, glitchY) * 0.05; // Reduce glitch intensity by using a small factor
        coord = clamp(coord, 0.0, 1.0);
    }
    
    if (kaleidoscopeMode) {
        coord = kaleidoscope(coord, kaleidoscopeSegments);
        // Apply twisting and warping, influenced by amplitude and pitch
    }
    float angle = atan2(coord.y - 0.5, coord.x - 0.5) + (kaleidoscopeMode ? twistIntensity * warpIntensity : 0) * sin(time + pitch * 0.01);
    float radius = length(coord - float2(0.5, 0.5));
    radius += amplitude * animationShapeFactor * 5; // Scale radius by amplitude to make visuals react to sound
    coord = float2(cos(angle) * radius + 0.5, sin(angle) * radius + 0.5);
    coord = clamp(coord, 0.0, 1.0); // Ensure coordinates stay within bounds

    // Smoothly blend hue based on time, coordinates, and pitch
    float baseHue = sin(time * 2.0 + coord.x * 4.0 + coord.y * 4.0 + pitch * 5) * 0.5 + (0.5 + baseHueOffset) * colorShiftSpeed;
    baseHue = fract(baseHue); // Keep hue value between 0.0 and 1.0

    // Calculate base color using smooth gradient interpolation
    float3 color1 = float3(redComponent * 0.9, greenComponent * 0.5, blueComponent * 0.2); // Warm color
    float3 color2 = float3(redComponent * 0.2, greenComponent * 0.5, blueComponent * 0.9); // Cool color
    float3 baseColor = mix(color1, color2, baseHue * (colorMixFactor * 2.0));

    // Apply brightness adjustments using amplitude
    baseColor *= (brightnessMultiplier + amplitude * 0.5); // Increase brightness scaling by amplitude for greater reactivity

    // Apply noise if enabled
    if (noiseMode) {
        float noiseValue = random(coord * noiseScale + time * noiseFrequency);
        noiseValue = noiseValue * 0.5 + 0.5; // Normalize noise to [0, 1] range
        float3 noiseColor = float3(noiseValue) * noiseIntensity;

        // Blend based on the selected mode
        switch (noiseBlendMode) {
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
    }

    // Ensure brightness is stable and consistent
    baseColor = clamp(baseColor, 0.2, 1.0); // Keep brightness between 0.2 and 1.0

    return float4(baseColor, 1.0);
}
