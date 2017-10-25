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
                                 constant MTIColorMatrix & colorMatrixValue [[ buffer(0) ]]
                                 ) {
    return colorTexture.sample(colorSampler, vertexIn.texcoords) * colorMatrixValue.matrix + colorMatrixValue.bias;
}

fragment float4 colorLookup512x512 (
                            VertexOut vertexIn [[stage_in]],
                            texture2d<float, access::sample> sourceTexture [[texture(0)]],
                            texture2d<float, access::sample> lutTexture [[texture(1)]],
                            sampler colorSampler [[sampler(0)]],
                            sampler lutSamper [[sampler(1)]]
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
    
    float4 finalColor = mix(color, float4(newColor.rgb, color.w), float(1));
//    if (vertexIn.texcoords.x > 0.5) return color;
    return finalColor;
}
