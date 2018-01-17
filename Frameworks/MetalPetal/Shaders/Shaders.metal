//
//  Shaders.metal
//  MetalPetal
//
//

#include <metal_stdlib>
#include "MTIShaderLib.h"

using namespace metal;
using namespace metalpetal;

vertex VertexOut passthroughVertex(
    const device VertexIn * vertices [[ buffer(0) ]],
	uint vid [[ vertex_id ]]
) {
	VertexOut outVertex;
	VertexIn inVertex = vertices[vid];
    outVertex.position = inVertex.position;
	outVertex.textureCoordinate = inVertex.textureCoordinate;
	return outVertex;
}

fragment float4 passthrough(
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

typedef struct {
    float4 color [[color(1)]];
} ColorAttachmentOneOutput;

fragment ColorAttachmentOneOutput passthroughToColorAttachmentOne(
                                          VertexOut vertexIn [[ stage_in ]],
                                          texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                          sampler colorSampler [[ sampler(0) ]]
                                          ) {
    ColorAttachmentOneOutput output;
    output.color = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    return output;
}

fragment ColorAttachmentOneOutput unpremultiplyAlphaToColorAttachmentOne(
                                   VertexOut vertexIn [[ stage_in ]],
                                   texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                   sampler colorSampler [[ sampler(0) ]]
                                   ) {
    ColorAttachmentOneOutput output;
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    output.color = unpremultiply(textureColor);
    return output;
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
                                                   float4 maskColor [[color(1)]],
                                                   constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                   texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                   sampler colorSampler [[ sampler(0) ]]
                                                   ) {
    float intensity = 1.0;
    if (parameters.hasCompositingMask) {
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
                               constant float & amount [[ buffer(0) ]],
                               constant float4 & vibranceVector [[ buffer(1) ]],
                               constant bool & avoidsSaturatingSkinTones [[ buffer(2) ]],
                               constant float3 & grayColorTransform [[ buffer(3) ]]
                               ) {
    float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
    return amount > 0 ?
    (avoidsSaturatingSkinTones ? adjustVibranceWhileKeepingSkinTones(textureColor, vibranceVector) : adjustVibrance(textureColor, amount, grayColorTransform))
    : adjustSaturation(textureColor, amount, grayColorTransform);
}

fragment float4 rToGray(
                        VertexOut vertexIn [[stage_in]],
                        texture2d<float, access::sample> sourceTexture [[texture(0)]],
                        sampler sourceSampler [[sampler(0)]],
                        constant bool & invert [[buffer(0)]]
                       ) {
    float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
    return float4(float3(invert ? 1.0 - textureColor.r : textureColor.r),1.0);
}

fragment float4 chromaKeyBlend(
                              VertexOut vertexIn [[stage_in]],
                              texture2d<float, access::sample> sourceTexture [[texture(0)]],
                              texture2d<float, access::sample> backgroundTexture [[texture(1)]],
                              sampler sourceSampler [[sampler(0)]],
                              sampler backgroundSampler [[sampler(1)]],
                              constant float4 &color [[buffer(0)]],
                              constant float &thresholdSensitivity [[buffer(1)]],
                              constant float &smoothing [[buffer(2)]]) {
    float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
    float4 textureColor2 = backgroundTexture.sample(backgroundSampler, vertexIn.textureCoordinate);
    
    float maskY = 0.2989 * color.r + 0.5866 * color.g + 0.1145 * color.b;
    float maskCr = 0.7132 * (color.r - maskY);
    float maskCb = 0.5647 * (color.b - maskY);
    
    float Y = 0.2989 * textureColor.r + 0.5866 * textureColor.g + 0.1145 * textureColor.b;
    float Cr = 0.7132 * (textureColor.r - Y);
    float Cb = 0.5647 * (textureColor.b - Y);
    
    float blendValue = 1.0 - smoothstep(thresholdSensitivity, thresholdSensitivity + smoothing, distance(float2(Cr, Cb), float2(maskCr, maskCb)));
    
    return mix(textureColor, textureColor2, blendValue);
}

fragment float4 pixellate(VertexOut vertexIn [[stage_in]],
                        texture2d<float, access::sample> sourceTexture [[texture(0)]],
                        sampler sourceSampler [[sampler(0)]],
                        constant float2 &scale [[buffer(0)]]
                        ) {
    float2 textureSize = float2(sourceTexture.get_width(), sourceTexture.get_height());
    float2 textureCoordinate = vertexIn.textureCoordinate * textureSize;
    float2 samplePos = textureCoordinate - fmod(textureCoordinate, scale) + scale * 0.5;
    return sourceTexture.sample(sourceSampler, samplePos/textureSize);
}

fragment float4 rgbToneCurveAdjust(
                               VertexOut vertexIn [[stage_in]],
                               texture2d<float, access::sample> sourceTexture [[texture(0)]],
                               texture2d<float, access::sample> toneCurveTexture [[texture(1)]],
                               sampler sourceSampler [[sampler(0)]],
                               sampler toneCurveSampler [[sampler(1)]],
                               constant float &intensity [[buffer(0)]]) {
    float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
    float r = toneCurveTexture.sample(toneCurveSampler, float2((textureColor.r * 255.0 + 0.5)/256.0, 0.5)).r;
    float g = toneCurveTexture.sample(toneCurveSampler, float2((textureColor.g * 255.0 + 0.5)/256.0, 0.5)).g;
    float b = toneCurveTexture.sample(toneCurveSampler, float2((textureColor.b * 255.0 + 0.5)/256.0, 0.5)).b;
    return mix(textureColor, float4(r,g,b,textureColor.a), intensity);
}

namespace metalpetal {
    namespace colorhalftone {
        float2x2 rotm(float r) {
            float cr = cos(r);
            float sr = sin(r);
            return float2x2(float2(cr,-sr), float2(sr,cr));
        }
        
        float4 rgb2cmyki(float3 c) {
            float k = max(max(c.r, c.g), c.b);
            return min(float4(c.rgb / k, k), 1.0);
        }
        
        float3 cmyki2rgb(float4 c)
        {
            return c.rgb * c.a;
        }
        
        float4 halftone(float2 fc, float2x2 m, float radius, float dotSize, float2 center, texture2d<float, access::sample> sourceTexture, sampler sourceSampler) {
            float2 px = m * fc;
            float2 smp = ((px - fmod(px, radius)) + 0.5 * radius) * m;
            float s = min(length(fc - smp) / (dotSize * 0.5 * radius), 1.0);
            float2 pt = smp + center;
            float2 textureSize = float2(sourceTexture.get_width(),sourceTexture.get_height());
            float3 texc = sourceTexture.sample(sourceSampler,pt/textureSize).rgb;
            texc = pow(texc, float3(2.2)); /* Gamma decode. */
            float4 c = rgb2cmyki(texc);
            return c+s;
        }
    }
}

fragment float4 colorHalftone(
                               VertexOut vertexIn [[stage_in]],
                               texture2d<float, access::sample> sourceTexture [[texture(0)]],
                               sampler sourceSampler [[sampler(0)]],
                               constant int &mode [[buffer(0)]],
                               constant float &radius [[buffer(1)]],
                               constant float4 &angles [[buffer(2)]],
                               constant float2 &center [[buffer(3)]]) {
    //https://www.shadertoy.com/view/Mdf3Dn
    using namespace metalpetal::colorhalftone;
    
    constexpr float dotSize = 1.48;
    constexpr float SST = 0.999;
    constexpr float SSQ = 0.5;
    
    float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
    
    float2 textureSize = float2(sourceTexture.get_width(),sourceTexture.get_height());
    float2 fc = vertexIn.textureCoordinate * textureSize - center;

    float2x2 mc = rotm(angles.x);
    float2x2 mm = rotm(angles.y);
    float2x2 my = rotm(angles.z);
    float2x2 mk = rotm(angles.w);
    
    float4 v;
    if (mode == 0) {
        v = float4(halftone(fc, mc, radius, dotSize, center, sourceTexture, sourceSampler).r,
                   halftone(fc, mm, radius, dotSize, center, sourceTexture, sourceSampler).g,
                   halftone(fc, my, radius, dotSize, center, sourceTexture, sourceSampler).b,
                   halftone(fc, mk, radius, dotSize, center, sourceTexture, sourceSampler).a);
    } else {
        v = float4(float3(halftone(fc, mk, radius, dotSize, center, sourceTexture, sourceSampler).a), 1.0);
    }
    float4 ssv = smoothstep(SST-SSQ, SST+SSQ, v);
    float3 c = cmyki2rgb(ssv);
    c = pow(c, float3(1.0/2.2)); // Gamma encode.
    return float4(c, textureColor.a);
}
