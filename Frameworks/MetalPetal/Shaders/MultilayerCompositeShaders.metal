#include <metal_stdlib>
#include "MTIShaderTypes.h"

using namespace metal;
using namespace metalpetal;

vertex VertexOut multilayerCompositeVertexShader(
                                        const device VertexIn * vertices [[ buffer(0) ]],
                                        constant float4x4 & transformMatrix [[ buffer(1) ]],
                                        constant float4x4 & orthographicMatrix [[ buffer(2) ]],
                                        uint vid [[ vertex_id ]]
                                        ) {
    VertexOut outVertex;
    VertexIn inVertex = vertices[vid];
    outVertex.position = transformMatrix * inVertex.position * orthographicMatrix;
    outVertex.texcoords = inVertex.textureCoordinate;
    return outVertex;
}

fragment float4 multilayerCompositeNormalBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant float & opacity [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    textureColor.a *= opacity;
    return normalBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeMultiplyBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant float & opacity [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    textureColor.a *= opacity;
    return multiplyBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeHardLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant float & opacity [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    textureColor.a *= opacity;
    return hardLightBlend(currentColor,textureColor);
}

