#include <metal_stdlib>
using namespace metal;

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

// Utility function for Perlin noise (simple implementation)
float perlin_noise(float2 p) {
    return sin(p.x * p.y);
}

// Fragment function for the harmonious fluid-like gradient effect with optional distortion and Perlin noise
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
                              constant float &perlinFrequency [[buffer(17)]]) {

    // Create the fluid-like evolving gradient pattern
    float xMovement = sin(time * 0.5 * animationShapeFactor + in.coord.x * 5.0) * 0.5 + cos(time * 0.3 * animationShapeFactor + in.coord.y * 4.0) * 0.5;
    float yMovement = cos(time * 0.4 * animationShapeFactor + in.coord.y * 5.0) * 0.5 + sin(time * 0.6 * animationShapeFactor + in.coord.x * 3.0) * 0.5;

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

    float4 baseColor = float4(r, g, b, 1.0);

    // Apply distortion on top of the final image if distortionMode is enabled
    if (distortionMode) {
        float distortion = sin(in.coord.x * distortionShape + time * distortionFrequencyRelation) * chaosFactor * distortionRatio;
        float2 distortedCoord = in.coord + float2(distortion, distortion);
        distortedCoord = clamp(distortedCoord, 0.0, 1.0);
        baseColor.rgb += float3(abs(distortion), abs(distortion), abs(distortion));
    }

    // Apply Perlin noise on top of the final image if perlinMode is enabled
    if (perlinMode) {
        float noise = perlin_noise(in.coord * perlinScale + time * perlinFrequency);
        noise = noise * 0.5 + 0.5; // Normalize noise to [0, 1] range
        baseColor.rgb += float3(noise, noise, noise) * perlinIntensity;
        baseColor.rgb = clamp(baseColor.rgb, 0.0, 1.0);
    }

    return baseColor;
}
