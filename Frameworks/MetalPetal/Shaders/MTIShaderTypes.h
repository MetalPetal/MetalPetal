//
//  MTIShader.h
//  Pods
//
//  Created by YuAo on 02/07/2017.
//
//

#ifndef MTIShader_h
#define MTIShader_h

#if defined(__cplusplus)

#if __has_include(<metal_stdlib>)

#include <metal_stdlib>

using namespace metal;

#endif

#endif

#import <simd/simd.h>

struct MTIVertex {
    vector_float4 position;
    vector_float2 textureCoordinate;
};
typedef struct MTIVertex MTIVertex;


struct MTICLAHELUTGeneratorInputParameters {
    uint histogramBins;
    uint clipLimit;
    uint totalPixelCountPerTile;
    uint numberOfLUTs;
};
typedef struct MTICLAHELUTGeneratorInputParameters MTICLAHELUTGeneratorInputParameters;


struct MTIMultilayerCompositingLayerShadingParameters {
    float opacity;
    bool contentHasPremultipliedAlpha;
};
typedef struct MTIMultilayerCompositingLayerShadingParameters MTIMultilayerCompositingLayerShadingParameters;

#if defined(__cplusplus)

#if __has_include(<metal_stdlib>)

namespace metalpetal {
    
    typedef ::MTIVertex VertexIn;
    
    struct VertexOut {
        float4 position [[ position ]];
        float2 texcoords;
    };
    
    METAL_FUNC float4 unpremultiply(float4 s) {
        return float4(s.rgb/max(s.a,0.00001), s.a);
    }
    
    METAL_FUNC float4 premultiply(float4 s) {
        return float4(s.rgb * s.a, s.a);
    }
    
    METAL_FUNC float hue2rgb(float p, float q, float t){
        if(t < 0.0) t += 1.0;
        if(t > 1.0) t -= 1.0;
        if(t < 1.0/6.0) return p + (q - p) * 6.0 * t;
        if(t < 1.0/2.0) return q;
        if(t < 2.0/3.0) return p + (q - p) * (2.0/3.0 - t) * 6.0;
        return p;
    }
    
    METAL_FUNC float3 rgb2hsl(float3 inputColor) {
        float3 color = clamp(inputColor,float3(0.0),float3(1.0));
        
        //Compute min and max component values
        float MAX = max(color.r, max(color.g, color.b));
        float MIN = min(color.r, min(color.g, color.b));
        
        //Make sure MAX > MIN to avoid division by zero later
        MAX = max(MIN + 1e-6, MAX);
        
        //Compute luminosity
        float l = (MIN + MAX) / 2.0;
        
        //Compute saturation
        float s = (l < 0.5 ? (MAX - MIN) / (MIN + MAX) : (MAX - MIN) / (2.0 - MAX - MIN));
        
        //Compute hue
        float h = (MAX == color.r ? (color.g - color.b) / (MAX - MIN) : (MAX == color.g ? 2.0 + (color.b - color.r) / (MAX - MIN) : 4.0 + (color.r - color.g) / (MAX - MIN)));
        h /= 6.0;
        h = (h < 0.0 ? 1.0 + h : h);
        
        return float3(h, s, l);
    }
    
    METAL_FUNC float3 hsl2rgb(float3 inputColor) {
        float3 color = clamp(inputColor,float3(0.0),float3(1.0));
        
        float h = color.r;
        float s = color.g;
        float l = color.b;
        
        float r,g,b;
        if(s <= 0.0){
            r = g = b = l;
        }else{
            float q = l < 0.5 ? (l * (1.0 + s)) : (l + s - l * s);
            float p = 2.0 * l - q;
            r = hue2rgb(p, q, h + 1.0/3.0);
            g = hue2rgb(p, q, h);
            b = hue2rgb(p, q, h - 1.0/3.0);
        }
        return float3(r,g,b);
    }
    
    //source over blend
    METAL_FUNC float4 normalBlend(float4 Cb, float4 Cs) {
        float4 dst = premultiply(Cb);
        float4 src = premultiply(Cs);
        return unpremultiply(src + dst * (1.0 - src.a));
    }

    METAL_FUNC float4 blendBaseAlpha(float4 Cb, float4 Cs, float4 B) {
        float4 Cr = float4((1 - Cb.a) * Cs.rgb + Cb.a * B.rgb, Cs.a);
        return normalBlend(Cb, Cr);
    }
    
    
    // multiply
    METAL_FUNC float4 multiplyBlend(float4 Cb, float4 Cs) {
        float4 B = clamp(float4(Cb.rgb * Cs.rgb, Cs.a), float4(0), float4(1));
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // overlay
    METAL_FUNC float overlayBlendSingleChannel(float b, float f ) {
                return f < 0.5f ? (2 * f * b) : (1 - 2 * (1 - f) * (1 - b));
    }
    
    METAL_FUNC float4 overlayBlend(float4 Cb, float4 Cs) {
        float4 B =  float4(overlayBlendSingleChannel(Cb.r, Cs.r), overlayBlendSingleChannel(Cb.g, Cs.g), overlayBlendSingleChannel(Cb.b, Cs.b), Cs.a);
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    //hardLight
    METAL_FUNC float4 hardLightBlend(float4 Cb, float4 Cs) {
        return overlayBlend(Cs, Cb);
    }
    
     //  softLight
    METAL_FUNC float softLightBlendSingleChannel(float b, float f) {
        return f < 0.5? ((2 * f * b) + pow(f, 2) * (1 - 2 * b)) : (2 * f * (1 - b) + sqrt(f) * (2 * b - 1));
    }
                         
    METAL_FUNC float4 softLightBlend(float4 Cb, float4 Cs) {
        float4 B = float4(softLightBlendSingleChannel(Cb.r, Cs.r), softLightBlendSingleChannel(Cb.g, Cs.g), softLightBlendSingleChannel(Cb.b, Cs.b), Cs.a);
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // screen
    METAL_FUNC float4 screenBlend(float4 Cb, float4 Cs) {
        float4 White = float4(1.0);
        float4 B = White - ((White - Cs) * (White - Cb));
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // darken
    METAL_FUNC float4 darkenBlend(float4 Cb, float4 Cs) {
        float4 B = float4(min(Cs.r, Cb.r), min(Cs.g, Cb.g), min(Cs.b, Cb.b), Cs.a);
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // lighten
    METAL_FUNC float4 lightenBlend(float4 Cb, float4 Cs) {
        float4 B = float4(max(Cs.r, Cb.r), max(Cs.g, Cb.g), max(Cs.b, Cb.b), Cs.a);
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // colorDodge
    METAL_FUNC float colorDodgeBlendSingleChannel(float b, float f) {
         if  (b == 0) return 0;
        else if (f == 1) return 1;
        else return min(1.0, b / (1 - f));
    }
    METAL_FUNC float4 colorDodgeBlend(float4 Cb, float4 Cs) {
        float4 B = float4(colorDodgeBlendSingleChannel(Cb.r, Cs.r), colorDodgeBlendSingleChannel(Cb.g, Cs.g), colorDodgeBlendSingleChannel(Cb.b, Cs.b), Cs.a);
        return blendBaseAlpha(Cb, Cs, B);
    }

    // colorBurn
    METAL_FUNC float colorBurnBlendSingleChannel(float b, float f) {
        if  (b == 1) return 1;
        else if (f == 0) return 0;
        else return min(1.0, (1 - b) / f);
    }
    METAL_FUNC float4 colorBurnBlend(float4 Cb, float4 Cs) {
        float4 B = float4(colorBurnBlendSingleChannel(Cb.r, Cs.r), colorBurnBlendSingleChannel(Cb.g, Cs.g), colorBurnBlendSingleChannel(Cb.b, Cs.b), Cs.a);
        return blendBaseAlpha(Cb, Cs, B);
    }
    // difference
    METAL_FUNC float4 differenceBlend(float4 Cb, float4 Cs) {
        float4 B = float4(abs(Cb.rgb - Cs.rgb), Cs.a);
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // exclusion
    METAL_FUNC float4 exclusionBlend(float4 Cb, float4 Cs) {
        float4 B = float4(Cb.rgb + Cs.rgb - 2 * Cb.rgb * Cs.rgb, Cs.a);
        return blendBaseAlpha(Cb, Cs, B);
    }
}

#endif

#endif

#endif /* MTIShader_h */
