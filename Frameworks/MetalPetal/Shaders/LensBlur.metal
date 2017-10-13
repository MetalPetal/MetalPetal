//
//  LensBlur.metal
//  MetalPetal
//
//  Created by Yu Ao on 13/10/2017.
//

#include <metal_stdlib>
#include "MTIShaderTypes.h"

using namespace metal;
using namespace metalpetal;

float randomize(float3 scale, float seed, float2 position) {
    return fract(sin(dot(float3(position, 0.0) + seed, scale)) * 43758.5453 + seed);
}

float4 sampleWithDelta(texture2d<float, access::sample> texture, sampler textureSampler, float2 position, float2 delta) {
    /* randomize the lookup values to hide the fixed number of samples */
    float offset = randomize(float3(delta, 151.7182), 0.0, position);
    const int samples = 16;
    float4 color = float4(0.0);
    float total = 0.0;
    for (int t = 0.0; t <= samples; t++) {
        float percent = (float(t) + offset) / float(samples);
        color += texture.sample(textureSampler, position + delta * percent);
        total += 1.0;
    }
    return color / total;
}

fragment float4 lensBlurPre(
                             VertexOut vertexIn [[ stage_in ]],
                             texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                             sampler colorSampler [[ sampler(0) ]],
                             constant float & power [[ buffer(0) ]]
                             ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return pow(textureColor, float4(power));
}

fragment float4 lensBlurAlpha(
                              VertexOut vertexIn [[ stage_in ]],
                              texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                              sampler colorSampler [[ sampler(0) ]],
                              texture2d<float, access::sample> maskTexture [[ texture(1) ]],
                              sampler maskSampler [[ sampler(1) ]],
                              constant float2 & delta [[ buffer(0) ]]
                            ) {
    float4 maskColor = maskTexture.sample(maskSampler, vertexIn.texcoords);
    return sampleWithDelta(colorTexture, colorSampler, vertexIn.texcoords, delta * maskColor.r);
}

fragment float4 lensBlurBravo(
                              VertexOut vertexIn [[ stage_in ]],
                              texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                              sampler colorSampler [[ sampler(0) ]],
                              texture2d<float, access::sample> maskTexture [[ texture(1) ]],
                              sampler maskSampler [[ sampler(1) ]],
                              constant float2 & delta0 [[ buffer(0) ]],
                              constant float2 & delta1 [[ buffer(1) ]]
                              ) {
    float4 maskColor = maskTexture.sample(maskSampler, vertexIn.texcoords);
    return (sampleWithDelta(colorTexture, colorSampler, vertexIn.texcoords, delta0 * maskColor.r) + sampleWithDelta(colorTexture, colorSampler, vertexIn.texcoords, delta1 * maskColor.r)) * 0.5;
}

fragment float4 lensBlurCharlie(
                                VertexOut vertexIn [[ stage_in ]],
                                texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                sampler colorSampler [[ sampler(0) ]],
                                texture2d<float, access::sample> colorTexture2 [[ texture(1) ]],
                                sampler colorSampler2 [[ sampler(1) ]],
                                texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                sampler maskSampler [[ sampler(2) ]],
                                constant float2 & delta [[ buffer(0) ]],
                                constant float & power [[ buffer(1) ]]
                              ) {
    float4 maskColor = maskTexture.sample(maskSampler, vertexIn.texcoords);
    float4 textureColor2 = colorTexture2.sample(colorSampler2, vertexIn.texcoords);

    float4 color = (sampleWithDelta(colorTexture, colorSampler, vertexIn.texcoords, delta * maskColor.r) + 2.0 * textureColor2)/3.0;
    return pow(color, float4(power));
}
