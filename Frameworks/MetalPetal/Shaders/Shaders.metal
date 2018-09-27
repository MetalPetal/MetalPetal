//
//  Shaders.metal
//  MetalPetal
//
//

#include <metal_stdlib>
#include "MTIShaderLib.h"

using namespace metal;

namespace metalpetal {

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
        return colorLookup2DSquareLUT(color,dimension,intensity,lutTexture,lutSamper);
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
        return colorLookup2DSquareLUT(color,64,intensity,overlayTexture,overlaySampler);
    }

    #if __HAVE_COLOR_ARGUMENTS__
    
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
        return colorLookup2DSquareLUT(currentColor,64,intensity,colorTexture,colorSampler);
    }
    
    #endif
    
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
        return colorLookup2DStripLUT(textureColor, dimension, true, intensity, lutTexture, lutSamper);
    }
    
    fragment float4 colorLookup2DVerticalStrip(
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
        return colorLookup2DStripLUT(textureColor, dimension, false, intensity, lutTexture, lutSamper);
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

    fragment float4 rToMonochrome(
                            VertexOut vertexIn [[stage_in]],
                            texture2d<float, access::sample> sourceTexture [[texture(0)]],
                            sampler sourceSampler [[sampler(0)]],
                            constant bool & invert [[buffer(0)]],
                            constant bool & convertSRGBToLinear [[buffer(1)]]
                           ) {
        float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
        if (convertSRGBToLinear) {
            textureColor.r = sRGBToLinear(textureColor.r);
        }
        return float4(float3(invert ? 1.0 - textureColor.r : textureColor.r),1.0);
    }
    
    fragment float4 rgToMonochrome(
                            VertexOut vertexIn [[stage_in]],
                            texture2d<float, access::sample> sourceTexture [[texture(0)]],
                            sampler sourceSampler [[sampler(0)]],
                            constant int & alphaChannelIndex [[buffer(0)]],
                            constant bool & unpremultiplyAlpha [[buffer(1)]],
                            constant bool & convertSRGBToLinear [[buffer(2)]]
                            ) {
        float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
        float alpha = textureColor[alphaChannelIndex];
        float color = textureColor[1 - alphaChannelIndex] / (unpremultiplyAlpha ? max(alpha,0.00001) : 1.0);
        if (convertSRGBToLinear) {
            color = sRGBToLinear(color);
        }
        return float4(float3(color),alpha);
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

    namespace usm {
        
        METAL_FUNC float3 rgb2yuv(float3 color) {
            float y =  0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
            float u = -0.147 * color.r - 0.289 * color.g + 0.436 * color.b;
            float v =  0.615 * color.r - 0.515 * color.g - 0.100 * color.b;
            return float3(y, u, v);
        }
        
        METAL_FUNC float3 yuv2rgb(float3 color) {
            float y = color.r; float u = color.g; float v = color.b;
            float r = y + 1.14 * v;
            float g = y - 0.39 * u - 0.58 * v;
            float b = y + 2.03 * u;
            return float3(r, g, b);
        }
        
        fragment float4 usmSecondPass(
                                             VertexOut vertexIn [[stage_in]],
                                             texture2d<float, access::sample> sourceTexture [[texture(0)]],
                                             texture2d<float, access::sample> blurTexture [[texture(1)]],
                                             sampler sourceSampler [[sampler(0)]],
                                             sampler blurSampler [[sampler(1)]],
                                             constant float &scale [[buffer(0)]],
                                             constant float &threshold [[buffer(1)]]) {
            float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
            float4 blurColor = blurTexture.sample(blurSampler, vertexIn.textureCoordinate);
            float3 textureYUV = rgb2yuv(textureColor.rgb);
            float3 blurYUV = rgb2yuv(blurColor.rgb);
            if (abs(textureYUV.r - blurYUV.r) < threshold) {
                return textureColor;
            }
            float sharpenY = textureYUV.r*(1+scale) - scale*blurYUV.r;
            float3 temp = yuv2rgb(float3(sharpenY, textureYUV.gb));
            return float4(temp, textureColor.a);
        }
    }
    
    kernel void histogramDisplayFindMax(
                                        texture2d<uint, access::read> sourceTexture [[texture(0)]],
                                        texture2d<uint, access::write> outTexture [[texture(1)]],
                                        uint2 gid [[ thread_position_in_grid ]]) {
        if (gid.x > 0 || gid.y > 0) {
            return;
        }
        uint4 maximum = 0;
        for (ushort x = 0; x < sourceTexture.get_width(); x += 1) {
            for (ushort channel = 0; channel < 4; channel += 1) {
                uint v = sourceTexture.read(uint2(x, channel)).r;
                maximum[channel] = v > maximum[channel] ? v : maximum[channel];
            }
        }
        outTexture.write(maximum, uint2(0, 0));
    }
    
    fragment float4 histogramDisplay(VertexOut vertexIn [[stage_in]],
                                     texture2d<uint, access::read> sourceTexture [[texture(0)]],
                                     texture2d<uint, access::read> maxValueTexture [[texture(1)]]) {
        float x = vertexIn.textureCoordinate.x * sourceTexture.get_width();
        ushort indexP = floor(x);
        ushort indexN = ceil(x);
        float factor = fract(x);
        
        uint rP = sourceTexture.read(uint2(indexP, 0)).r;
        uint rN = sourceTexture.read(uint2(indexN, 0)).r;
        float rValue = mix(float(rP), float(rN), factor);
        
        uint gP = sourceTexture.read(uint2(indexP, 1)).r;
        uint gN = sourceTexture.read(uint2(indexN, 1)).r;
        float gValue = mix(float(gP), float(gN), factor);
        
        uint bP = sourceTexture.read(uint2(indexP, 2)).r;
        uint bN = sourceTexture.read(uint2(indexN, 2)).r;
        float bValue = mix(float(bP), float(bN), factor);
        
        uint4 maxValue = maxValueTexture.read(uint2(0,0));
        float3 height = float3(rValue, gValue, bValue)/float3(max(max(maxValue.r, maxValue.g),maxValue.b));
        bool3 fill = vertexIn.textureCoordinate.y > 1.0 - height;
        return float4(float3(fill), 1.0);
    }
    
    kernel void colorLookupTable2DSquareTo3D(texture2d<float, access::read> sourceTexture [[texture(0)]],
                                             texture3d<float, access::write> outTexture [[texture(1)]],
                                             constant int & dimension [[buffer(0)]],
                                             uint3 gid [[ thread_position_in_grid ]]) {
        if (gid.x < outTexture.get_width() &&
            gid.y < outTexture.get_height() &&
            gid.z < outTexture.get_depth()) {
            uint rows = uint(round(sqrt((float)dimension)));
            uint index = gid.z;
            uint tx = gid.x + (index % rows) * dimension;
            uint ty = gid.y + (index / rows) * dimension;
            outTexture.write(sourceTexture.read(uint2(tx, ty)), gid);
        }
    }
    
    kernel void colorLookupTable2DStripVerticalTo3D(texture2d<float, access::read> sourceTexture [[texture(0)]],
                                             texture3d<float, access::write> outTexture [[texture(1)]],
                                             constant int & dimension [[buffer(0)]],
                                             uint3 gid [[ thread_position_in_grid ]]) {
        if (gid.x < outTexture.get_width() &&
            gid.y < outTexture.get_height() &&
            gid.z < outTexture.get_depth()) {
            uint index = gid.z;
            uint tx = gid.x;
            uint ty = gid.y + index * dimension;
            outTexture.write(sourceTexture.read(uint2(tx, ty)), gid);
        }
    }
    
    kernel void colorLookupTable2DStripHorizontalTo3D(texture2d<float, access::read> sourceTexture [[texture(0)]],
                                             texture3d<float, access::write> outTexture [[texture(1)]],
                                             constant int & dimension [[buffer(0)]],
                                             uint3 gid [[ thread_position_in_grid ]]) {
        if (gid.x < outTexture.get_width() &&
            gid.y < outTexture.get_height() &&
            gid.z < outTexture.get_depth()) {
            uint index = gid.z;
            uint tx = gid.x + index * dimension;
            uint ty = gid.y;
            outTexture.write(sourceTexture.read(uint2(tx, ty)), gid);
        }
    }
    
    fragment float4 colorLookup3D(VertexOut vertexIn [[stage_in]],
                                  texture2d<float, access::sample> sourceTexture [[texture(0)]],
                                  texture3d<float, access::sample> lutTexture [[texture(1)]],
                                  sampler colorSampler [[sampler(0)]],
                                  sampler lutSamper [[sampler(1)]],
                                  constant float & intensity [[ buffer(1) ]]) {
        float2 sourceCoord = vertexIn.textureCoordinate;
        float4 color = sourceTexture.sample(colorSampler,sourceCoord);
        uint dimension = lutTexture.get_width();
        float4 destColor = lutTexture.sample(lutSamper, ((color.rgb * (dimension - 1)) + 0.5)/dimension);
        return float4(mix(color.rgb, destColor.rgb, intensity), color.a);
    }
    
    /*
    fragment float4 histogramDisplay(VertexOut vertexIn [[stage_in]],
                                     texture2d<uint, access::sample> sourceTexture [[texture(0)]],
                                     sampler sourceSampler [[sampler(0)]],
                                     texture2d<uint, access::read> maxValueTexture [[texture(1)]]) {
        uint rValue = sourceTexture.sample(sourceSampler, float2(vertexIn.textureCoordinate.x, 0.5/4.0)).r;
        uint gValue = sourceTexture.sample(sourceSampler, float2(vertexIn.textureCoordinate.x, 1.5/4.0)).r;
        uint bValue = sourceTexture.sample(sourceSampler, float2(vertexIn.textureCoordinate.x, 2.5/4.0)).r;
        uint4 maxValue = maxValueTexture.read(uint2(0,0));
        float3 height = float3(rValue, gValue, bValue)/float3(max(max(maxValue.r, maxValue.g),maxValue.b));
        bool3 fill = vertexIn.textureCoordinate.y > 1.0 - height;
        return float4(float3(fill), 1.0);
        //return float4(float3(value.rgb)/float3(maxValue.rgb), 1.0);
    }
    */
    
    namespace definition {
        
        float4 meaningBlur(float4 im, float4 b) {
            float4 result = im;
            float thresh = 0.1;
            float g1 = max(max(im.r, im.g), im.b);
            float g2 = dot(b.rgb, float3(1.0 / 3.0));
            float diff = max(g2 - g1, -1.0);
            diff = smoothstep(0.1 - thresh, 0.1 + thresh, diff);
            result.rgb = mix(im.rgb, b.rgb, diff + 0.5);
            return result;
        }
        
        fragment float4 clarity(VertexOut vertexIn [[stage_in]],
                                texture2d<float, access::sample> sourceTexture [[texture(0)]],
                                texture2d<float, access::sample> blurTexture [[texture(1)]],
                                sampler sourceSampler [[sampler(0)]],
                                sampler blurSampler [[sampler(1)]],
                                constant float &intensity) {
            float4 s = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
            
            float4 b = blurTexture.sample(blurSampler, vertexIn.textureCoordinate);
            b = meaningBlur(s, b);
            
            float sl = (s.r + s.g + s.b);
            float bl = (b.r + b.g + b.b);
            float dl = sl + (sl - bl) * intensity;
            float mult = dl / max(sl, 0.0001);
            mult = 1.571 * (mult - 1.0);
            mult = mult / (1.0 + abs(mult));
            mult += 1.0;
            mult = clamp(mult, 1.0 - 0.5 * abs(intensity), 1.0 + 1.0 * abs(intensity));
            s.rgb = s.rgb * mult;
            return s;
        }
    }
}
