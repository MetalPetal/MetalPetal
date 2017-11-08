//
//  ImageShaders.metal
//  Metal2D
//
//  Created by Kaz Yoshikawa on 12/22/15.
//
//

#include <metal_stdlib>
#include "MTIShaderTypes.h"

using namespace metal;
using namespace metalpetal;

vertex VertexOut passthroughVertexShader(
    const device VertexIn * vertices [[ buffer(0) ]],
	uint vid [[ vertex_id ]]
) {
	VertexOut outVertex;
	VertexIn inVertex = vertices[vid];
    outVertex.position = inVertex.position;
	outVertex.texcoords = inVertex.textureCoordinate;
	return outVertex;
}

fragment float4 passthroughFragmentShader(
	VertexOut vertexIn [[ stage_in ]],
	texture2d<float, access::sample> colorTexture [[ texture(0) ]],
	sampler colorSampler [[ sampler(0) ]]
) {
    return colorTexture.sample(colorSampler, vertexIn.texcoords);
}

fragment float4 unpremultiplyAlpha(
                            VertexOut vertexIn [[ stage_in ]],
                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                            sampler colorSampler [[ sampler(0) ]]
                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return unpremultiply(textureColor);
}

fragment float4 premultiplyAlpha(
                                   VertexOut vertexIn [[ stage_in ]],
                                   texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                   sampler colorSampler [[ sampler(0) ]]
                                   ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return premultiply(textureColor);
}

fragment float4 colorMatrixProjection(
                                 VertexOut vertexIn [[ stage_in ]],
                                 texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                 sampler colorSampler [[ sampler(0) ]],
                                 constant MTIColorMatrix & colorMatrix [[ buffer(0) ]]
                                 ) {
    return colorTexture.sample(colorSampler, vertexIn.texcoords) * colorMatrix.matrix + colorMatrix.bias;
}

fragment float4 colorLookup512x512 (
                            VertexOut vertexIn [[stage_in]],
                            texture2d<float, access::sample> sourceTexture [[texture(0)]],
                            texture2d<float, access::sample> lutTexture [[texture(1)]],
                            sampler colorSampler [[sampler(0)]],
                            sampler lutSamper [[sampler(1)]],
                            constant float & intensity [[ buffer(0) ]]
                            )
{
    float2 sourceCoord = vertexIn.texcoords;
    float4 color = sourceTexture.sample(colorSampler,sourceCoord);
    
    float blueColor = color.b * 63;
    
    int2 quad1;
    quad1.y = floor(floor(blueColor) / 8.0);
    quad1.x = floor(blueColor) - (quad1.y * 8.0);
    
    int2 quad2;
    
    quad2.y = floor(ceil(blueColor) / 8.0);
    quad2.x = ceil(blueColor) - (quad2.y * 8.0);;
    
    float2 texPos1;
    texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * color.r);
    texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * color.g);
    
    float2 texPos2;
    texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * color.r);
    texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * color.g);
    
    float4 newColor1 = lutTexture.sample(lutSamper, texPos1);
    float4 newColor2 = lutTexture.sample(lutSamper, texPos2);
    
    float4 newColor = mix(newColor1, newColor2, float(fract(blueColor)));
    
    float4 finalColor = mix(color, float4(newColor.rgb, color.w), intensity);
    
    return finalColor;
}

vertex VertexOut imageTransformVertexShader(
                                       const device VertexIn * vertices [[ buffer(0) ]],
                                       constant float4x4 & transformMatrix [[ buffer(1) ]],
                                       uint vid [[ vertex_id ]]
                                       ) {
    VertexOut outVertex;
    VertexIn inVertex = vertices[vid];
    outVertex.position = inVertex.position * transformMatrix;
    outVertex.position.z = 0.0;
    outVertex.texcoords = inVertex.textureCoordinate;
    return outVertex;
}

fragment float4 blendWithMask(
                                     VertexOut vertexIn [[stage_in]],
                                     texture2d<float, access::sample> overlayTexture [[texture(0)]],
                                     texture2d<float, access::sample> maskTexture [[texture(1)]],
                                     texture2d<float, access::sample> baseTexture [[texture(2)]],
                                     sampler overlaySampler [[sampler(0)]],
                                     sampler maskSampler [[sampler(1)]],
                                     sampler baseSampler [[sampler(2)]],
                                     constant int &maskComponent [[ buffer(0) ]]) {
    float4 overlayColor = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 maskColor = maskTexture.sample(maskSampler, vertexIn.texcoords);
    float4 baseColor = baseTexture.sample(baseSampler, vertexIn.texcoords);
    return mix(baseColor, overlayColor, maskColor[maskComponent]);
}

fragment float4 vibranceAdjust(
                               VertexOut vertexIn [[stage_in]],
                               texture2d<float, access::sample> sourceTexture [[texture(0)]],
                               sampler sourceSampler [[sampler(0)]],
                               constant  float & amount [[ buffer(0) ]],
                               constant  float4 & vibranceVector [[ buffer(1) ]],
                               constant  bool & avoidsSaturatingSkinTones [[ buffer(2) ]]
                               ) {
    float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.texcoords);
    return amount > 0 ?
    (avoidsSaturatingSkinTones ? adjustVibranceWhileKeepingSkinTones(textureColor, vibranceVector) : adjustVibrance(textureColor, amount))
    : adjustSaturation(textureColor, amount);
}
