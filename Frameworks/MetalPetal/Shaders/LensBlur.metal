//
//  LensBlur.metal
//  MetalPetal
//
//  Created by Yu Ao on 13/10/2017.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"

using namespace metal;
using namespace metalpetal;

METAL_FUNC float randomize(float3 scale, float seed, float2 position) {
    return fract(sin(dot(float3(position, 0.0) + seed, scale)) * 43758.5453 + seed);
}

METAL_FUNC float4 sampleWithDelta(texture2d<float, access::sample> texture, sampler textureSampler, float2 position, float2 delta) {
    /* randomize the lookup values to hide the fixed number of samples */
    float offset = randomize(float3(delta, 151.7182), 0.0, position);
    const int samples = 16;
    float4 color = float4(0.0);
    for (int t = 0.0; t <= samples; t++) {
        float percent = (float(t) + offset) / float(samples);
        color += texture.sample(textureSampler, position + delta * percent);
    }
    return color / float(samples);
}

fragment float4 lensBlurPre(
                             VertexOut vertexIn [[ stage_in ]],
                             texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                             sampler colorSampler [[ sampler(0) ]],
                             constant float & power [[ buffer(0) ]]
                             ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    textureColor.rgb = pow(textureColor.rgb, float3(power));
    return textureColor;
}

typedef struct {
    float4 vertical [[color(0)]];
    float4 diagonal [[color(1)]];
} LensBlurAlphaPassOutput;

fragment LensBlurAlphaPassOutput lensBlurAlpha(
                              VertexOut vertexIn [[ stage_in ]],
                              texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                              sampler colorSampler [[ sampler(0) ]],
                              texture2d<float, access::sample> maskTexture [[ texture(1) ]],
                              sampler maskSampler [[ sampler(1) ]],
                              constant float2 & delta0 [[ buffer(0) ]],
                              constant float2 & delta1 [[ buffer(1) ]]
                            ) {
    float4 maskColor = maskTexture.sample(maskSampler, vertexIn.textureCoordinate);
    float4 color1 = sampleWithDelta(colorTexture, colorSampler, vertexIn.textureCoordinate, delta0 * maskColor.r);
    float4 color2 = sampleWithDelta(colorTexture, colorSampler, vertexIn.textureCoordinate, delta1 * maskColor.r);
    LensBlurAlphaPassOutput output;
    output.vertical = color1;
    output.diagonal = color2 + color1;
    return output;
}

fragment float4 lensBlurBravoCharlie(VertexOut vertexIn [[ stage_in ]],
                           texture2d<float, access::sample> verticalTexture [[ texture(0) ]],
                           sampler verticalSampler [[ sampler(0) ]],
                           texture2d<float, access::sample> diagonalTexture [[ texture(1) ]],
                           sampler diagonalSampler [[ sampler(1) ]],
                           texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                           sampler maskSampler [[ sampler(2) ]],
                           texture2d<float, access::sample> colorTexture [[ texture(3) ]],
                           sampler colorSampler [[ sampler(3) ]],
                           constant float2 & delta0 [[ buffer(0) ]],
                           constant float2 & delta1 [[ buffer(1) ]],
                           constant float & power [[ buffer(2) ]]) {
    float4 maskColor = maskTexture.sample(maskSampler, vertexIn.textureCoordinate);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 color = (sampleWithDelta(verticalTexture, verticalSampler, vertexIn.textureCoordinate, delta0 * maskColor.r) + sampleWithDelta(diagonalTexture, diagonalSampler, vertexIn.textureCoordinate, delta1 * maskColor.r)) * 0.5;
    color.rgb = pow(color.rgb, float3(power));
    color.a = textureColor.a;
    return color;
}
