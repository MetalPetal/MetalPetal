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

#if defined(__cplusplus)

#if __has_include(<metal_stdlib>)

namespace metalpetal {
    
    typedef ::MTIVertex VertexIn;
    
    struct VertexOut {
        float4 position [[ position ]];
        float2 texcoords;
    };
    
    METAL_FUNC float4 unpremultiply(float4 s) {
        return s.a > 0 ? float4(s.rgb/s.a, s.a) : float4(0);
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
    
    METAL_FUNC float4 rgb2hsl(float4 inputColor) {
        float4 color = clamp(inputColor,float4(0.0),float4(1.0));
        
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
        
        return float4(h, s, l, color.a);
    }
    
    METAL_FUNC float4 hsl2rgb(float4 inputColor) {
        float4 color = clamp(inputColor,float4(0.0),float4(1.0));
        
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
        return float4(r,g,b,color.a);
    }
    
    //source over blend
    METAL_FUNC float4 normalBlend(float4 Cb, float4 Cf) {
        float4 dst = premultiply(Cb);
        float4 src = premultiply(Cf);
        return unpremultiply(src + dst * (1.0 - src.a));
    }
    
    //untested
    METAL_FUNC float4 multiplyBlend(float4 Cb, float4 Cs) {
        float3 B = clamp(Cb.rgb * Cs.rgb, float3(0), float3(1));
        return normalBlend(Cb, float4(B, Cs.a));
    }
    
    //unimplemented
    METAL_FUNC float4 hardLightBlend(float4 Cb, float4 Cs) {
        return Cs;
    }
    
}

#endif

#endif

#endif /* MTIShader_h */
