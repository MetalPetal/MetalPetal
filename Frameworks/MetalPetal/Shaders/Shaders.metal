//
//  ImageShaders.metal
//  Metal2D
//
//  Created by Kaz Yoshikawa on 12/22/15.
//
//

#include <metal_stdlib>
#include "MTIShaderLib.h"

using namespace metal;
using namespace metalpetal;

vertex VertexOut passthroughVertexShader(
    const device VertexIn * vertices [[ buffer(0) ]],
	uint vid [[ vertex_id ]]
) {
	VertexOut outVertex;
	VertexIn inVertex = vertices[vid];
    outVertex.position = inVertex.position;
	outVertex.textureCoordinate = inVertex.textureCoordinate;
	return outVertex;
}

fragment float4 passthroughFragmentShader(
	VertexOut vertexIn [[ stage_in ]],
	texture2d<float, access::sample> colorTexture [[ texture(0) ]],
	sampler colorSampler [[ sampler(0) ]]
) {
    return colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
}

fragment float4 unpremultiplyAlpha(
                            VertexOut vertexIn [[ stage_in ]],
                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                            sampler colorSampler [[ sampler(0) ]]
                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    return unpremultiply(textureColor);
}

fragment float4 premultiplyAlpha(
                                   VertexOut vertexIn [[ stage_in ]],
                                   texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                   sampler colorSampler [[ sampler(0) ]]
                                   ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    return premultiply(textureColor);
}

fragment float4 colorMatrixProjection(
                                 VertexOut vertexIn [[ stage_in ]],
                                 texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                 sampler colorSampler [[ sampler(0) ]],
                                 constant MTIColorMatrix & colorMatrix [[ buffer(0) ]]
                                 ) {
    return colorTexture.sample(colorSampler, vertexIn.textureCoordinate) * colorMatrix.matrix + colorMatrix.bias;
}

METAL_FUNC float4 colorLookup2DSquareImp(float4 color,
                                         int dimension,
                                         float intensity,
                                         texture2d<float, access::sample> lutTexture,
                                         sampler lutSamper) {
    int row = round(sqrt((float)dimension));
    float blueColor = color.b * (dimension - 1);
    
    int2 quad1;
    quad1.y = floor(floor(blueColor) / row);
    quad1.x = floor(blueColor) - (quad1.y * row);
    
    int2 quad2;
    
    quad2.y = floor(ceil(blueColor) / row);
    quad2.x = ceil(blueColor) - (quad2.y * row);;
    
    float2 texPos1;
    texPos1.x = (quad1.x * (1.0/row)) + 0.5/lutTexture.get_width() + ((1.0/row - 1.0/lutTexture.get_width()) * color.r);
    texPos1.y = (quad1.y * (1.0/row)) + 0.5/lutTexture.get_height() + ((1.0/row - 1.0/lutTexture.get_height()) * color.g);
    
    float2 texPos2;
    texPos2.x = (quad2.x * (1.0/row)) + 0.5/lutTexture.get_width() + ((1.0/row - 1.0/lutTexture.get_width()) * color.r);
    texPos2.y = (quad2.y * (1.0/row)) + 0.5/lutTexture.get_height() + ((1.0/row - 1.0/lutTexture.get_height()) * color.g);
    
    float4 newColor1 = lutTexture.sample(lutSamper, texPos1);
    float4 newColor2 = lutTexture.sample(lutSamper, texPos2);
    
    float4 newColor = mix(newColor1, newColor2, float(fract(blueColor)));
    
    float4 finalColor = mix(color, float4(newColor.rgb, color.a), intensity);
    
    return finalColor;
}

fragment float4 colorLookup2DSquare (
                            VertexOut vertexIn [[stage_in]],
                            texture2d<float, access::sample> sourceTexture [[texture(0)]],
                            texture2d<float, access::sample> lutTexture [[texture(1)]],
                            sampler colorSampler [[sampler(0)]],
                            sampler lutSamper [[sampler(1)]],
                            constant int & dimension [[buffer(0)]],
                            constant float & intensity [[ buffer(1) ]]
                            )
{
    float2 sourceCoord = vertexIn.textureCoordinate;
    float4 color = sourceTexture.sample(colorSampler,sourceCoord);
    return colorLookup2DSquareImp(color,dimension,intensity,lutTexture,lutSamper);
}

fragment float4 colorLookup512x512Blend(VertexOut vertexIn [[ stage_in ]],
                                texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                sampler colorSampler [[ sampler(0) ]],
                                texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                sampler overlaySampler [[ sampler(1) ]],
                                constant float &intensity [[buffer(0)]]
                                ) {
    float2 sourceCoord = vertexIn.textureCoordinate;
    float4 color = colorTexture.sample(colorSampler,sourceCoord);
    return colorLookup2DSquareImp(color,64,intensity,overlayTexture,overlaySampler);
}

fragment float4 multilayerCompositeColorLookup512x512Blend(
                                                   VertexOut vertexIn [[ stage_in ]],
                                                   float4 currentColor [[color(0)]],
                                                   constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                   texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                   sampler colorSampler [[ sampler(0) ]],
                                                   texture2d<float, access::sample> maskTexture [[ texture(1) ]],
                                                   sampler maskSampler [[ sampler(1) ]]
                                                   ) {
    float intensity = 1.0;
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(colorSampler, vertexIn.textureCoordinate);
        intensity *= maskColor.r;
    }
    intensity *= parameters.opacity;
    return colorLookup2DSquareImp(currentColor,64,intensity,colorTexture,colorSampler);
}

fragment float4 colorLookup2DHorizontalStrip(
                                     VertexOut vertexIn [[stage_in]],
                                     texture2d<float, access::sample> sourceTexture [[texture(0)]],
                                     texture2d<float, access::sample> lutTexture [[texture(1)]],
                                     sampler colorSampler [[sampler(0)]],
                                     sampler lutSamper [[sampler(1)]],
                                     constant int & dimension [[buffer(0)]],
                                     constant float & intensity [[ buffer(1) ]]
                                     )
{
    float2 sourceCoord = vertexIn.textureCoordinate;
    float4 textureColor = sourceTexture.sample(colorSampler,sourceCoord);
    
    float blueColor = textureColor.b * (dimension - 1);
    
    float2 quad1;
    quad1.x = floor(blueColor);
    quad1.y = 0.0;
    
    float2 quad2;
    quad2.x = ceil(blueColor);
    quad2.y = 0.0;
    
    float widthForQuard  = 1.0/dimension;
    float heightForQuard = 1.0;
    float pixelWidthOnX  = 1.0/lutTexture.get_width();
    float pixelWidthOnY  = 1.0/lutTexture.get_height();
    
    float2 texPos1;
    texPos1.x = (quad1.x*widthForQuard)  + (0.5*pixelWidthOnX) + ((widthForQuard - pixelWidthOnX)  * textureColor.r);
    texPos1.y = (quad1.y*heightForQuard) + (0.5*pixelWidthOnY) + ((heightForQuard - pixelWidthOnY) * textureColor.g);
    
    float2 texPos2;
    texPos2.x = (quad2.x*widthForQuard)  + (0.5*pixelWidthOnX) + ((widthForQuard - pixelWidthOnX)  * textureColor.r);
    texPos2.y = (quad2.y*heightForQuard) + (0.5*pixelWidthOnY) + ((heightForQuard - pixelWidthOnY) * textureColor.g);
    
    float4 newColor1 = lutTexture.sample(lutSamper, texPos1);
    float4 newColor2 = lutTexture.sample(lutSamper, texPos2);
    
    float4 newColor = mix(newColor1, newColor2, float(fract(blueColor)));
    
    float4 finalColor = mix(textureColor, float4(newColor.rgb, textureColor.a), intensity);
    
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
    outVertex.textureCoordinate = inVertex.textureCoordinate;
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
                                     constant int &maskComponent [[ buffer(0) ]],
                                     constant bool &usesOneMinusMaskValue [[ buffer(1) ]]) {
    float4 overlayColor = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 maskColor = maskTexture.sample(maskSampler, vertexIn.textureCoordinate);
    float maskValue = maskColor[maskComponent];
    float4 baseColor = baseTexture.sample(baseSampler, vertexIn.textureCoordinate);
    return mix(baseColor, overlayColor, usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue);
}

fragment float4 vibranceAdjust(
                               VertexOut vertexIn [[stage_in]],
                               texture2d<float, access::sample> sourceTexture [[texture(0)]],
                               sampler sourceSampler [[sampler(0)]],
                               constant  float & amount [[ buffer(0) ]],
                               constant  float4 & vibranceVector [[ buffer(1) ]],
                               constant  bool & avoidsSaturatingSkinTones [[ buffer(2) ]]
                               ) {
    float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
    return amount > 0 ?
    (avoidsSaturatingSkinTones ? adjustVibranceWhileKeepingSkinTones(textureColor, vibranceVector) : adjustVibrance(textureColor, amount))
    : adjustSaturation(textureColor, amount);
}
