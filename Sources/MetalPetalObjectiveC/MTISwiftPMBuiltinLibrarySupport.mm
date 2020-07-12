#import "MTISwiftPMBuiltinLibrarySupport.h"
#import "MTILibrarySource.h"
#import <Metal/Metal.h>

static const char *MTIBuiltinLibrarySource = R"mtirawstring(
//
//  MTIShader.h
//  Pods
//
//  Created by YuAo on 02/07/2017.
//
//

#ifndef MTIShader_h
#define MTIShader_h

#if __METAL_MACOS__ || __METAL_IOS__

#include <metal_stdlib>

using namespace metal;

#endif /* __METAL_MACOS__ || __METAL_IOS__ */

#import <simd/simd.h>

struct MTIVertex {
    vector_float4 position;
    vector_float2 textureCoordinate;
};
typedef struct MTIVertex MTIVertex;

struct MTIColorMatrix {
    matrix_float4x4 matrix;
    vector_float4 bias;
};
typedef struct MTIColorMatrix MTIColorMatrix;

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
    bool hasCompositingMask;
    int compositingMaskComponent;
    bool usesOneMinusMaskValue;
    vector_float4 tintColor;
};
typedef struct MTIMultilayerCompositingLayerShadingParameters MTIMultilayerCompositingLayerShadingParameters;

#if __METAL_MACOS__ || __METAL_IOS__

namespace metalpetal {
    
    typedef ::MTIVertex VertexIn;
    
    typedef struct {
        float4 position [[ position ]];
        float2 textureCoordinate;
    } VertexOut;
    
    // GLSL mod func for metal
    template <typename T, typename _E = typename enable_if<is_floating_point<typename make_scalar<T>::type>::value>::type>
    METAL_FUNC T mod(T x, T y) {
        return x - y * floor(x/y);
    }
    
    template <typename T, typename _E = typename enable_if<is_floating_point<T>::value>::type>
    METAL_FUNC T sRGBToLinear(T c) {
        return (c <= 0.04045f) ? c / 12.92f : powr((c + 0.055f) / 1.055f, 2.4f);
    }
    
    METAL_FUNC float3 sRGBToLinear(float3 c) {
        return float3(sRGBToLinear(c.r), sRGBToLinear(c.g), sRGBToLinear(c.b));
    }
    
    template <typename T, typename _E = typename enable_if<is_floating_point<T>::value>::type>
    METAL_FUNC T linearToSRGB(T c) {
        return (c < 0.0031308f) ? (12.92f * c) : (1.055f * powr(c, 1.f/2.4f) - 0.055f);
    }
    
    METAL_FUNC float3 linearToSRGB(float3 c) {
        return float3(linearToSRGB(c.r), linearToSRGB(c.g), linearToSRGB(c.b));
    }
    
    template <typename T, typename _E = typename enable_if<is_floating_point<T>::value>::type>
    METAL_FUNC T ITUR709ToLinear(T c) {
#if __METAL_IOS__
        return powr(c, 1.961);
#else
        return c < 0.081 ? 0.222 * c : powr(0.91 * c + 0.09, 2.222);
#endif
    }
    
    METAL_FUNC float3 ITUR709ToLinear(float3 c) {
        return float3(ITUR709ToLinear(c.r), ITUR709ToLinear(c.g), ITUR709ToLinear(c.b));
    }
    
    METAL_FUNC float4 unpremultiply(float4 s) {
        return float4(s.rgb/max(s.a,0.00001), s.a);
    }
    
    METAL_FUNC float4 premultiply(float4 s) {
        return float4(s.rgb * s.a, s.a);
    }
    
    template <typename T, typename _E = typename enable_if<is_floating_point<T>::value>::type>
    METAL_FUNC T hue2rgb(T p, T q, T t){
        if(t < 0.0) {
            t += 1.0;
        }
        if(t > 1.0) {
            t -= 1.0;
        }
        if(t < 1.0/6.0) {
            return p + (q - p) * 6.0 * t;
        }
        if(t < 1.0/2.0) {
            return q;
        }
        if(t < 2.0/3.0) {
            return p + (q - p) * (2.0/3.0 - t) * 6.0;
        }
        return p;
    }
    
    METAL_FUNC float3 rgb2hsl(float3 inputColor) {
        float3 color = saturate(inputColor);
        
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
    
    METAL_FUNC half3 rgb2hsl(half3 inputColor) {
        half3 color = saturate(inputColor);
        
        //Compute min and max component values
        half MAX = max(color.r, max(color.g, color.b));
        half MIN = min(color.r, min(color.g, color.b));
        
        //Make sure MAX > MIN to avoid division by zero later
        MAX = max(MIN + 1e-6h, MAX);
        
        //Compute luminosity
        half l = (MIN + MAX) / 2.0h;
        
        //Compute saturation
        half s = (l < 0.5h ? (MAX - MIN) / (MIN + MAX) : (MAX - MIN) / (2.0h - MAX - MIN));
        
        //Compute hue
        half h = (MAX == color.r ? (color.g - color.b) / (MAX - MIN) : (MAX == color.g ? 2.0h + (color.b - color.r) / (MAX - MIN) : 4.0h + (color.r - color.g) / (MAX - MIN)));
        h /= 6.0h;
        h = (h < 0.0h ? 1.0h + h : h);
        
        return half3(h, s, l);
    }
    
    METAL_FUNC float3 hsl2rgb(float3 inputColor) {
        float3 color = saturate(inputColor);
        
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
    
    METAL_FUNC half3 hsl2rgb(half3 inputColor) {
        half3 color = saturate(inputColor);
        
        half h = color.r;
        half s = color.g;
        half l = color.b;
        
        half r,g,b;
        if(s <= 0.0h){
            r = g = b = l;
        }else{
            half q = l < 0.5h ? (l * (1.0h + s)) : (l + s - l * s);
            half p = 2.0h * l - q;
            r = hue2rgb(p, q, h + 1.0h/3.0h);
            g = hue2rgb(p, q, h);
            b = hue2rgb(p, q, h - 1.0h/3.0h);
        }
        return half3(r,g,b);
    }
    
    METAL_FUNC float lum(float4 C) {
        return 0.299 * C.r + 0.587 * C.g + 0.114 * C.b;
    }
    
    //source over blend
    METAL_FUNC float4 normalBlend(float4 Cb, float4 Cs) {
        float4 dst = premultiply(Cb);
        float4 src = premultiply(Cs);
        return unpremultiply(src + dst * (1.0 - src.a));
    }

    METAL_FUNC float4 blendBaseAlpha(float4 Cb, float4 Cs, float4 B) {
        float4 Cr = float4((1 - Cb.a) * Cs.rgb + Cb.a * saturate(B.rgb), Cs.a);
        return normalBlend(Cb, Cr);
    }
    
    // multiply
    METAL_FUNC float4 multiplyBlend(float4 Cb, float4 Cs) {
        float4 B = saturate(float4(Cb.rgb * Cs.rgb, Cs.a));
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // overlay
    METAL_FUNC float overlayBlendSingleChannel(float b, float s ) {
        return b < 0.5f ? (2 * s * b) : (1 - 2 * (1 - b) * (1 - s));
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
    METAL_FUNC float softLightBlendSingleChannelD(float b) {
        return b <= 0.25? (((16 * b - 12) * b + 4) * b): sqrt(b);
    }
    
    METAL_FUNC float softLightBlendSingleChannel(float b, float s) {
        return s < 0.5? (b - (1 - 2 * s) * b * (1 - b)) : (b + (2 * s - 1) * (softLightBlendSingleChannelD(b) - b));
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
    
    // darkerColor
    METAL_FUNC float4 darkerColorBlend(float4 Cb, float4 Cs) {
        float4 B;
        if (lum(Cs) < lum(Cb)) {
            B = Cs;
        } else {
            B = Cb;
        }
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // lighten
    METAL_FUNC float4 lightenBlend(float4 Cb, float4 Cs) {
        float4 B = float4(max(Cs.r, Cb.r), max(Cs.g, Cb.g), max(Cs.b, Cb.b), Cs.a);
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // lighterColor
    METAL_FUNC float4 lighterColorBlend(float4 Cb, float4 Cs) {
        float4 B;
        if (lum(Cs) > lum(Cb)) {
            B = Cs;
        } else {
            B = Cb;
        }
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // colorBurn
    METAL_FUNC float colorBurnBlendSingleChannel(float b, float f) {
        if (b == 1) {
            return 1;
        } else if (f == 0) {
            return 0;
        } else {
            return 1.0 - min(1.0, (1 - b) / f);
        }
    }
    
    METAL_FUNC float4 colorBurnBlend(float4 Cb, float4 Cs) {
        float4 B = float4(colorBurnBlendSingleChannel(Cb.r, Cs.r), colorBurnBlendSingleChannel(Cb.g, Cs.g), colorBurnBlendSingleChannel(Cb.b, Cs.b), Cs.a);
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // colorDodge
    METAL_FUNC float colorDodgeBlendSingleChannel(float b, float f) {
        if (b == 0) {
            return 0;
        } else if (f == 1) {
            return 1;
        } else {
            return min(1.0, b / (1 - f));
        }
    }
    METAL_FUNC float4 colorDodgeBlend(float4 Cb, float4 Cs) {
        float4 B = float4(colorDodgeBlendSingleChannel(Cb.r, Cs.r), colorDodgeBlendSingleChannel(Cb.g, Cs.g), colorDodgeBlendSingleChannel(Cb.b, Cs.b), Cs.a);
        return blendBaseAlpha(Cb, Cs, B);
    }

    // pinLight
    METAL_FUNC float pinLightBlendSingleChannel(float b, float s) {

        if (s > 0.5) {
            return max(b , 2 * (s - 0.5));
        } else {
            return min(b, 2 * s);
        }
    }
    
    METAL_FUNC float4 pinLightBlend(float4 Cb, float4 Cs) {
        float4 B = float4(pinLightBlendSingleChannel(Cb.r, Cs.r), pinLightBlendSingleChannel(Cb.g, Cs.g), pinLightBlendSingleChannel(Cb.b, Cs.b), Cs.a);
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // vividLight
    METAL_FUNC float vividLightBlendSingleChannel(float b, float s) {
        if (s <= 0.5) {
            if (s == 0) {
                return s;
            }
            return 1 - (1 - b) / (2 * s);
        } else {
            if (s == 1) {
                return s;
            }
            return b / (2 * (1 - s));
        }
    }
    
    METAL_FUNC float4 vividLightBlend(float4 Cb, float4 Cs) {
        float4 B = float4(vividLightBlendSingleChannel(Cb.r, Cs.r), vividLightBlendSingleChannel(Cb.g, Cs.g), vividLightBlendSingleChannel(Cb.b, Cs.b), Cs.a);
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // hardMix
    METAL_FUNC float hardMixBlendSingleChannel(float b, float s) {
        if (b < 1 - s) {
            return 0;
        } else if (b == 1 - s) {
            return 0.5;
        } else {
            return 1;
        }
    }
    
    METAL_FUNC float4 hardMixBlend(float4 Cb, float4 Cs) {

        float4 B = float4(hardMixBlendSingleChannel(Cb.r, Cs.r), hardMixBlendSingleChannel(Cb.g, Cs.g), hardMixBlendSingleChannel(Cb.b, Cs.b), Cs.a);
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
    
    // divide
    METAL_FUNC float divideBlendSingleChannel(float b, float f) {
        if (f == 0) {
            return 1;
        } else {
            return min(b / f, 1.0);
        }
    }
    METAL_FUNC float4 divideBlend(float4 Cb, float4 Cs) {
        float4 B = float4(divideBlendSingleChannel(Cb.r, Cs.r), divideBlendSingleChannel(Cb.g, Cs.g), divideBlendSingleChannel(Cb.b, Cs.b), Cs.a);
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // add also linearDodge
    METAL_FUNC float4 addBlend(float4 Cb, float4 Cs) {
        float4 B = min(Cb + Cs, 1.0);
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    METAL_FUNC float4 linearDodgeBlend(float4 Cb, float4 Cs) {
        return addBlend(Cb,Cs);
    }
    
    // subtract
    METAL_FUNC float4 subtractBlend(float4 Cb, float4 Cs) {
        float4 B = Cb - Cs;
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // linearBurn
    METAL_FUNC float4 linearBurnBlend(float4 Cb, float4 Cs) {
        float4 B = max(Cb + Cs - 1, 0);
        return blendBaseAlpha(Cb, Cs, B);
    }

    //Linear Light
    METAL_FUNC float4 linearLightBlend(float4 Cb, float4 Cs) {
        float4 B  = Cb + 2.0 * Cs - 1.0;
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    //---
    // non-separable blend
    METAL_FUNC float4 clipColor(float4 C) {
        float l = lum(C);
        float  n = min(C.r, min(C.g, C.b));
        float x = max(C.r, max(C.g, C.b));
        if (n < 0) {
            return float4((l + ((C.rgb - l) * l) / (l - n)), C.a);
        }
        if (x > 1.) {
            return float4(l + (((C.rgb - l) * (1. - l)) / (x - l)), C.a);
        }
        return C;
    }
    
    METAL_FUNC float4 setLum(float4 C, float l) {
        float d = l - lum(C);
        return clipColor(float4(C.rgb + d, C.a ));
    }
    
    METAL_FUNC float sat(float4 C) {
        float n = min(C.r, min(C.g, C.b));
        float x = max(C.r, max(C.g, C.b));
        return x - n;
    }
    
    METAL_FUNC float mid(float cmin, float cmid, float cmax, float s) {
        return ((cmid - cmin) * s) / (cmax - cmin);
    }
    
    METAL_FUNC float4 setSat(float4 C, float s) {
        if (C.r > C.g) {
            if (C.r > C.b) {
                if (C.g > C.b) {
                    C.g = mid(C.b, C.g, C.r, s);
                    C.b = 0.0;
                } else {
                    C.b = mid(C.g, C.b, C.r, s);
                    C.g = 0.0;
                }
                C.r = s;
            } else {
                C.r = mid(C.g, C.r, C.b, s);
                C.b = s;
                C.r = 0.0;
            }
        } else if (C.r > C.b) {
            C.r = mid(C.b, C.r, C.g, s);
            C.g = s;
            C.b = 0.0;
        } else if (C.g > C.b) {
            C.b = mid(C.r, C.b, C.g, s);
            C.g = s;
            C.r = 0.0;
        } else if (C.b > C.g) {
            C.g = mid(C.r, C.g, C.b, s);
            C.b = s;
            C.r = 0.0;
        } else {
            C = float4(0.0);
        }
        return C;
    }
    
    // hue
    METAL_FUNC float4 hueBlend(float4 Cb, float4 Cs) {
        float4 B = setLum(setSat(Cs, sat(Cb)), lum(Cb));
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // saturation
    METAL_FUNC float4 saturationBlend(float4 Cb, float4 Cs) {
        float4 B = setLum(setSat(Cb, sat(Cs)), lum(Cb));
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // color
    METAL_FUNC float4 colorBlend(float4 Cb, float4 Cs) {
        float4 B = setLum(Cs, lum(Cb));
        return blendBaseAlpha(Cb, Cs, B);
    }
    
     // luminosity
    METAL_FUNC float4 luminosityBlend(float4 Cb, float4 Cs) {
        float4 B = setLum(Cb, lum(Cs));
        return blendBaseAlpha(Cb, Cs, B);
    }
    
    // Vibrance
    METAL_FUNC float4 adjustVibranceWhileKeepingSkinTones(float4 pixel0, float4 vvec) {
        float4 pixel = clamp(pixel0, 0.0001, 0.9999);
        float4 pdelta = pixel0 - pixel;
        float gray = (pixel.r + pixel.g + pixel.b) * 0.33333;
        float gi   = 1.0 / gray;
        float gii  = 1.0 / (1.0 - gray);
        float3 rgbsat = max((pixel.rgb - gray) * gii, (gray - pixel.rgb) * gi);
        float sat = max(max(rgbsat.r, rgbsat.g), rgbsat.b);
        float skin = min(pixel.r - pixel.g, pixel.g * 2.0 - pixel.b) * 4.0 * (1.0 - rgbsat.r) * gi;
        skin = 0.15 + clamp(skin, 0.0, 1.0) * 0.7;
        float boost = dot(vvec,float4(1.0, sat, sat*sat, sat*sat*sat)) * (1.0 - skin);
        pixel = clamp(pixel + (pixel - gray) * boost, 0.0, 1.0);
        pixel.a = pixel0.a;
        pixel.rgb += pdelta.rgb;
        return pixel;
    }
    
    METAL_FUNC float4 adjustVibrance(float4 colorInput, float vibrance, float3 grayColorTransform) {
        float luma = dot(grayColorTransform, colorInput.rgb); //calculate luma (grey)
        float max_color = max(colorInput.r, max(colorInput.g,colorInput.b)); //Find the strongest color
        float min_color = min(colorInput.r, min(colorInput.g,colorInput.b)); //Find the weakest color
        float color_saturation = max_color - min_color; //The difference between the two is the saturation
        float4 color = colorInput;
        color.rgb = mix(float3(luma), color.rgb, (1.0 + (vibrance * (1.0 - (sign(vibrance) * color_saturation))))); //extrapolate between luma and original by 1 + (1-saturation) - current
        //color.rgb = mix(vec3(luma), color.rgb, 1.0 + (1.0 - pow(color_saturation, 1.0 - (1.0 - vibrance))) ); //pow version
        return color; //return the result
        //return color_saturation.xxxx; //Visualize the saturation
    }
    
    METAL_FUNC float4 adjustSaturation(float4 textureColor, float saturation, float3 grayColorTransform) {
        /*
        float4 pixel = clamp(textureColor, 0.0001, 0.9999);
        float4 pdelta = textureColor - pixel;
        float gray = (pixel.r + pixel.g + pixel.b) * 0.33333;
        float gi   = 1.0 / gray;
        float gii  = 1.0 / (1.0 - gray);
        float3 rgbsat = max((pixel.rgb - gray) * gii, (gray - pixel.rgb) * gi);
        float sat = max(max(rgbsat.r, rgbsat.g), rgbsat.b);
        float skin = min(pixel.r - pixel.g, pixel.g * 2.0 - pixel.b) * 4.0 * (1.0 - rgbsat.r) * gi;
        skin = 0.15 + clamp(skin, 0.0, 1.0) * 0.7;
        float boost = ((sat * (sat - 1.0) + 1.0) * saturation) * (1.0-skin);
        pixel = clamp(pixel + (pixel - gray) * boost, 0.0, 1.0);
        pixel.a = textureColor.a;
        pixel.rgb += pdelta.rgb;
        return pixel;
        */
        float luma = dot(grayColorTransform, textureColor.rgb); //calculate luma (grey)
        return float4(mix(float3(luma), textureColor.rgb, saturation + 1.0), textureColor.a);
    }
    
    METAL_FUNC float4 colorLookup2DSquareLUT(float4 color,
                                             int dimension,
                                             float intensity,
                                             texture2d<float, access::sample> lutTexture,
                                             sampler lutSamper) {
        float row = round(sqrt((float)dimension));
        float blueColor = color.b * (dimension - 1);
        
        float2 quad1;
        quad1.y = floor(floor(blueColor) / row);
        quad1.x = floor(blueColor) - (quad1.y * row);
        
        float2 quad2;
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
    
    
    METAL_FUNC float4 colorLookup2DStripLUT(float4 color,
                                            int dimension,
                                            bool isHorizontal,
                                            float intensity,
                                            texture2d<float, access::sample> lutTexture,
                                            sampler lutSamper) {
        float4 textureColor = color;
        float blueColor = textureColor.b * (dimension - 1);
        
        float2 quad1;
        quad1.x = isHorizontal ? floor(blueColor) : 0.0;
        quad1.y = isHorizontal ? 0.0 : floor(blueColor);
        
        float2 quad2;
        quad2.x = isHorizontal ? ceil(blueColor) : 0.0;
        quad2.y = isHorizontal ? 0.0 : ceil(blueColor);
        
        float widthForQuard  = isHorizontal ? 1.0/dimension : 1.0;
        float heightForQuard = isHorizontal ? 1.0 : 1.0/dimension;
        float pixelWidthOnX  = 1.0/lutTexture.get_width();
        float pixelWidthOnY  = 1.0/lutTexture.get_height();
        
        float2 texPos1;
        texPos1.x = (quad1.x * widthForQuard)  + (0.5 * pixelWidthOnX) + ((widthForQuard - pixelWidthOnX)  * textureColor.r);
        texPos1.y = (quad1.y * heightForQuard) + (0.5 * pixelWidthOnY) + ((heightForQuard - pixelWidthOnY) * textureColor.g);
        
        float2 texPos2;
        texPos2.x = (quad2.x * widthForQuard)  + (0.5 * pixelWidthOnX) + ((widthForQuard - pixelWidthOnX)  * textureColor.r);
        texPos2.y = (quad2.y * heightForQuard) + (0.5 * pixelWidthOnY) + ((heightForQuard - pixelWidthOnY) * textureColor.g);
        
        float4 newColor1 = lutTexture.sample(lutSamper, texPos1);
        float4 newColor2 = lutTexture.sample(lutSamper, texPos2);
        
        float4 newColor = mix(newColor1, newColor2, float(fract(blueColor)));
        
        float4 finalColor = mix(textureColor, float4(newColor.rgb, textureColor.a), intensity);
        
        return finalColor;
    }
}

#endif /* __METAL_MACOS__ || __METAL_IOS__ */

#endif /* MTIShader_h */

//
// This is an auto-generated source file.
//

#include <metal_stdlib>



using namespace metal;
using namespace metalpetal;

namespace metalpetal {

fragment float4 normalBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = normalBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 darkenBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = darkenBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 multiplyBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = multiplyBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 colorBurnBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = colorBurnBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 linearBurnBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = linearBurnBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 darkerColorBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = darkerColorBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 lightenBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = lightenBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 screenBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = screenBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 colorDodgeBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = colorDodgeBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 addBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = addBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 lighterColorBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = lighterColorBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 overlayBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = overlayBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 softLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = softLightBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 hardLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = hardLightBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 vividLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = vividLightBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 linearLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = linearLightBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 pinLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = pinLightBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 hardMixBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = hardMixBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 differenceBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = differenceBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 exclusionBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = exclusionBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 subtractBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = subtractBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 divideBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = divideBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 hueBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = hueBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 saturationBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = saturationBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 colorBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = colorBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 luminosityBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = luminosityBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

}
//
//  CLAHE.metal
//  MetalPetal
//
//  Created by YuAo on 14/10/2017.
//




using namespace metal;

namespace metalpetal {
    namespace clahe {
        fragment half CLAHERGB2Lightness(VertexOut vertexIn [[ stage_in ]],
                                texture2d<half, access::sample> colorTexture [[ texture(0) ]],
                                sampler colorSampler [[ sampler(0) ]],
                                constant float2 & scale [[buffer(0)]]
                                ) {
            half4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate * scale);
            half3 hsl = rgb2hsl(textureColor.rgb);
            return hsl.b;
        }

        kernel void CLAHEGenerateLUT(
                                   texture2d<float, access::write> outTexture [[texture(0)]],
                                   device uint * histogramBuffer [[buffer(0)]],
                                   constant MTICLAHELUTGeneratorInputParameters & parameters [[buffer(1)]],
                                   uint gid [[thread_position_in_grid]]
                                   ) {
            if (gid >= parameters.numberOfLUTs) {
                return;
            }
            
            device uint *l = histogramBuffer + gid * parameters.histogramBins;
            const uint histSize = parameters.histogramBins;
            
            uint clipped = 0;
            for (uint i = 0; i < histSize; ++i) {
                if(l[i] > parameters.clipLimit) {
                    clipped += (l[i] - parameters.clipLimit);
                    l[i] = parameters.clipLimit;
                }
            }
            
            const uint redistBatch = clipped / histSize;
            uint residual = clipped - redistBatch * histSize;
            
            for (uint i = 0; i < histSize; ++i) {
                l[i] += redistBatch;
            }
            
            if (residual != 0) {
                const uint residualStep = max(histSize / residual, (uint)1);
                for (uint i = 0; i < histSize && residual > 0; i += residualStep, residual--) {
                    l[i]++;
                }
            }
            
            uint sum = 0;
            const float lutScale = (histSize - 1) / float(parameters.totalPixelCountPerTile);
            for (uint index = 0; index < histSize; ++index) {
                sum += l[index];
                outTexture.write(round(sum * lutScale)/255.0, uint2(index, gid));
            }
        }

        METAL_FUNC half CLAHELookup(texture2d<half, access::sample> lutTexture, sampler lutSamper, float index, float x) {
            //lutTexture is R8, no alpha.
            return lutTexture.sample(lutSamper, float2(x, (index + 0.5)/lutTexture.get_height())).r;
        }
        
        fragment half4 CLAHEColorLookup (
                                    VertexOut vertexIn [[stage_in]],
                                    texture2d<half, access::sample> sourceTexture [[texture(0)]],
                                    texture2d<half, access::sample> lutTexture [[texture(1)]],
                                    sampler colorSampler [[sampler(0)]],
                                    sampler lutSamper [[sampler(1)]],
                                    constant float2 & tileGridSize [[ buffer(0) ]]
                                   )
        {
            float2 sourceCoord = vertexIn.textureCoordinate;
            half4 color = sourceTexture.sample(colorSampler,sourceCoord);
            half3 hslColor = rgb2hsl(color.rgb);
            
            float txf = sourceCoord.x * tileGridSize.x - 0.5;
            
            float tx1 = floor(txf);
            float tx2 = tx1 + 1.0;
            
            float xa_p = txf - tx1;
            float xa1_p = 1.0 - xa_p;
            
            tx1 = max(tx1, 0.0);
            tx2 = min(tx2, tileGridSize.x - 1.0);
            
            float tyf = sourceCoord.y * tileGridSize.y - 0.5;
            
            float ty1 = floor(tyf);
            float ty2 = ty1 + 1.0;
            
            float ya = tyf - ty1;
            float ya1 = 1.0 - ya;
            
            ty1 = max(ty1, 0.0);
            ty2 = min(ty2, tileGridSize.y - 1.0);
            
            float srcVal = hslColor.b;
            float x = (srcVal * 255.0 + 0.5)/lutTexture.get_width();
            
            half lutPlane1_ind1 = CLAHELookup(lutTexture, lutSamper, ty1 * tileGridSize.x + tx1, x);
            half lutPlane1_ind2 = CLAHELookup(lutTexture, lutSamper, ty1 * tileGridSize.x + tx2, x);
            half lutPlane2_ind1 = CLAHELookup(lutTexture, lutSamper, ty2 * tileGridSize.x + tx1, x);
            half lutPlane2_ind2 = CLAHELookup(lutTexture, lutSamper, ty2 * tileGridSize.x + tx2, x);
            
            half res = (lutPlane1_ind1 * xa1_p + lutPlane1_ind2 * xa_p) * ya1 + (lutPlane2_ind1 * xa1_p + lutPlane2_ind2 * xa_p) * ya;
            
            half3 r = half3(hslColor.r, hslColor.g, res);
            
            half3 rgbResult = hsl2rgb(r);
            return half4(rgbResult, color.a);
        }
    }
}

//
//  ColorConversionShaders.metal
//  Pods
//
//  Created by jichuan on 2017/7/19.
//
//

#include <metal_stdlib>
#include <simd/simd.h>



using namespace metal;

namespace metalpetal {
    namespace yuv2rgbconvert {
        typedef struct {
            packed_float2 position;
            packed_float2 texcoord;
        } Vertex;

        typedef struct {
            float3x3 matrix;
            float3 offset;
        } ColorConversion;

        typedef struct {
            float4 position [[ position ]];
            float2 texcoord;
        } Varyings;

        vertex Varyings colorConversionVertex(const device Vertex * verticies [[ buffer(0) ]],
                                              unsigned int vid [[ vertex_id ]]) {
            Varyings out;
            Vertex v = verticies[vid];
            out.position = float4(float2(v.position), 0.0, 1.0);
            out.texcoord = v.texcoord;
            return out;
        }

        fragment float4 colorConversionFragment(Varyings in [[ stage_in ]],
                                               texture2d<float, access::sample> yTexture [[ texture(0) ]],
                                               texture2d<float, access::sample> cbcrTexture [[ texture(1) ]],
                                               constant ColorConversion &colorConversion [[ buffer(0) ]],
                                               constant bool &convertToLinearRGB [[ buffer(1) ]]) {
            constexpr sampler s(address::clamp_to_edge, filter::linear);
            float3 ycbcr = float3(yTexture.sample(s, in.texcoord).r, cbcrTexture.sample(s, in.texcoord).rg);
            float3 rgb = colorConversion.matrix * (ycbcr + colorConversion.offset);
            return float4(float3(convertToLinearRGB ? sRGBToLinear(rgb) : rgb), 1.0);
        }

        kernel void colorConversion(uint2 gid [[ thread_position_in_grid ]],
                                    texture2d<float, access::read> yTexture [[ texture(0) ]],
                                    texture2d<float, access::read> cbcrTexture [[ texture(1) ]],
                                    texture2d<float, access::write> outTexture [[ texture(2) ]],
                                    constant ColorConversion &colorConversion [[ buffer(0) ]]) {
            
            uint2 cbcrCoordinates = uint2(gid.x / 2, gid.y / 2); // half the size because we are using a 4:2:0 chroma subsampling
            float y = yTexture.read(gid).r;
            float2 cbcr = cbcrTexture.read(cbcrCoordinates).rg;
            
            float3 ycbcr = float3(y, cbcr);
            float3 rgb = colorConversion.matrix * (ycbcr + colorConversion.offset);
            
            outTexture.write(float4(float3(rgb), 1.0), gid);
        }
    }
}

//
//  Halftone.metal
//  MetalPetal
//
//  Created by Yu Ao on 18/01/2018.
//




using namespace metal;
using namespace metalpetal;

namespace metalpetal {
    namespace halftone {
        float2x2 rotm(float r) {
            float cr = cos(r);
            float sr = sin(r);
            return float2x2(float2(cr,-sr),
                            float2(sr,cr));
        }
        
        float2 samplePosition(float2 textureCoordinate, float2x2 m, float scale) {
            float2 rotatedTextureCoordinate = m * textureCoordinate;
            return (rotatedTextureCoordinate - mod(rotatedTextureCoordinate, float2(scale)) + scale * 0.5) * m;
        }
        
        float halftoneIntensity(float2 textureCoordinate, float2 samplePos, float scale, float3 grayColorTransform, texture2d<float, access::sample> sourceTexture, sampler sourceSampler) {
            float2 textureSize = float2(sourceTexture.get_width(), sourceTexture.get_height());
            float4 textureColor = sourceTexture.sample(sourceSampler, samplePos/textureSize);
            float grayscale = dot(textureColor.rgb, grayColorTransform);
            float d = scale * 1.414214 * (1.0 - grayscale);
            float d1 = distance(textureCoordinate + float2(-0.25), samplePos);
            float d2 = distance(textureCoordinate + float2(0.25, -0.25), samplePos);
            float d3 = distance(textureCoordinate + float2(-0.25, 0.25), samplePos);
            float d4 = distance(textureCoordinate + float2(0.25), samplePos);
            return dot(float4(float4(d1,d2,d3,d4) < float4(d/2.0)), float4(0.25));
        }
        
        float3 halftoneIntensityRGB(float2 textureCoordinate, float2 samplePos, float scale, texture2d<float, access::sample> sourceTexture, sampler sourceSampler) {
            float2 textureSize = float2(sourceTexture.get_width(), sourceTexture.get_height());
            float4 textureColor = sourceTexture.sample(sourceSampler, samplePos/textureSize);
            float3 c = textureColor.rgb;
            float3 d = scale * 1.414214 * (1.0 - c);
            float d1 = distance(textureCoordinate + float2(-0.25), samplePos);
            float d2 = distance(textureCoordinate + float2(0.25, -0.25), samplePos);
            float d3 = distance(textureCoordinate + float2(-0.25, 0.25), samplePos);
            float d4 = distance(textureCoordinate + float2(0.25), samplePos);
            return float3(dot(float4(float4(d1,d2,d3,d4) < float4(d.r/2.0)), float4(0.25)),
                          dot(float4(float4(d1,d2,d3,d4) < float4(d.g/2.0)), float4(0.25)),
                          dot(float4(float4(d1,d2,d3,d4) < float4(d.b/2.0)), float4(0.25)));
        }
        
        float2 neighborSamplePosition(float2 textureCoordinate, float2 samplePosition, float scale, float2x2 m) {
            float2 p = (textureCoordinate - samplePosition) * m;
            float2 direction = (p.y > p.x) ? ( -p.x > p.y ? float2(-1, 0) : float2(0, 1)) : (-p.y > p.x ? float2(0, -1) : float2(1, 0));
            return samplePosition + (m * direction) * scale;
        }
        
        
        fragment float4 colorHalftone(VertexOut vertexIn [[stage_in]],
                                      texture2d<float, access::sample> sourceTexture [[texture(0)]],
                                      sampler sourceSampler [[sampler(0)]],
                                      constant float &scale [[buffer(1)]],
                                      constant float4 &angles [[buffer(2)]],
                                      constant bool &singleAngleMode [[buffer(3)]]) {
            using namespace metalpetal::halftone;
            constexpr sampler customSampler(coord::normalized, address::clamp_to_edge, filter:: linear);
            
            float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
            
            float2 textureSize = float2(sourceTexture.get_width(), sourceTexture.get_height());
            float2 textureCoordinate = vertexIn.textureCoordinate * textureSize;
            
            float3 intensityRGB;
            float3 intensityNeighborRGB;
            if (singleAngleMode) {
                float2x2 m = rotm(angles.x);
                float2 samplePos = samplePosition(textureCoordinate, m, scale);
                intensityRGB = halftoneIntensityRGB(textureCoordinate, samplePos, scale, sourceTexture, customSampler);
                intensityNeighborRGB = halftoneIntensityRGB(textureCoordinate, neighborSamplePosition(textureCoordinate, samplePos, scale, m), scale, sourceTexture, customSampler);
            } else {
                float2x2 mr = rotm(angles.x);
                float2x2 mg = rotm(angles.y);
                float2x2 mb = rotm(angles.z);
                
                float2 samplePositionR = samplePosition(textureCoordinate, mr, scale);
                float2 samplePositionG = samplePosition(textureCoordinate, mg, scale);
                float2 samplePositionB = samplePosition(textureCoordinate, mb, scale);
                
                intensityRGB = float3(halftoneIntensityRGB(textureCoordinate, samplePositionR, scale, sourceTexture, customSampler).r,
                                      halftoneIntensityRGB(textureCoordinate, samplePositionG, scale, sourceTexture, customSampler).g,
                                      halftoneIntensityRGB(textureCoordinate, samplePositionB, scale, sourceTexture, customSampler).b);
                
                intensityNeighborRGB = float3(halftoneIntensityRGB(textureCoordinate, neighborSamplePosition(textureCoordinate, samplePositionR, scale, mr), scale, sourceTexture, customSampler).r,
                                              halftoneIntensityRGB(textureCoordinate, neighborSamplePosition(textureCoordinate, samplePositionG, scale, mg), scale, sourceTexture, customSampler).g,
                                              halftoneIntensityRGB(textureCoordinate, neighborSamplePosition(textureCoordinate, samplePositionB, scale, mb), scale, sourceTexture, customSampler).b);
            }
            float3 i = (1.0 - intensityRGB) * (1 - intensityNeighborRGB);
            return float4(i, textureColor.a);
        }
        
        fragment float4 dotScreen(
                                  VertexOut vertexIn [[stage_in]],
                                  texture2d<float, access::sample> sourceTexture [[texture(0)]],
                                  sampler sourceSampler [[sampler(0)]],
                                  constant float &scale [[buffer(0)]],
                                  constant float &angle [[buffer(1)]],
                                  constant float3 &grayColorTransform [[buffer(2)]]) {
            using namespace metalpetal::halftone;
            constexpr sampler customSampler(coord::normalized, address::clamp_to_edge, filter:: linear);
            
            float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
            
            float2x2 m = rotm(angle);
            float2 textureSize = float2(sourceTexture.get_width(), sourceTexture.get_height());
            float2 textureCoordinate = vertexIn.textureCoordinate * textureSize;
            float2 rotatedTextureCoordinate = m * textureCoordinate;
            float2 samplePos = (rotatedTextureCoordinate - mod(rotatedTextureCoordinate, float2(scale)) + scale * 0.5) * m;
            float intensity = halftoneIntensity(textureCoordinate, samplePos, scale, grayColorTransform, sourceTexture, customSampler);
            float2 samplePosNeighbor = neighborSamplePosition(textureCoordinate, samplePos, scale, m);
            float intensityNeighbor = halftoneIntensity(textureCoordinate, samplePosNeighbor, scale, grayColorTransform, sourceTexture, customSampler);
            float i = (1.0 - intensity) * (1.0 - intensityNeighbor);
            return float4(float3(i),textureColor.a);
        }
    }
}


//
//  HighPassSkinSmoothing.metal
//  MetalPetal
//
//  Created by Yu Ao on 15/01/2018.
//



using namespace metal;

namespace metalpetal {

    fragment float4 highPassSkinSmoothingGBChannelOverlay(
                            VertexOut vertexIn [[stage_in]],
                            texture2d<float, access::sample> sourceTexture [[texture(0)]],
                            sampler sourceSampler [[sampler(0)]]
                            ) {
        float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
        textureColor.rgb = textureColor.rgb * pow(2.0, -1.0);
        return overlayBlend(float4(float3(textureColor.g), 1.0), float4(float3(textureColor.b), 1.0));
    }

    fragment float4 highPassSkinSmoothingMaskProcessAndComposite(
                                                                    VertexOut vertexIn [[stage_in]],
                                                                    texture2d<float, access::sample> sourceTexture [[texture(0)]],
                                                                    sampler sourceSampler [[sampler(0)]],
                                                                    texture2d<float, access::sample> bgChannelOverlayTexture [[texture(1)]],
                                                                    sampler bgChannelOverlayTextureSampler [[sampler(1)]],
                                                                    texture2d<float, access::sample> blurredBGChannelOverlayTexture [[texture(2)]],
                                                                    sampler blurredBGChannelOverlayTextureSampler [[sampler(2)]],
                                                                    texture2d<float, access::sample> toneCurveLUT [[texture(3)]],
                                                                    sampler toneCurveLUTSampler [[sampler(3)]],
                                                                    constant float &amount [[buffer(0)]]
                                                                    ) {
        float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
        
        float r = toneCurveLUT.sample(toneCurveLUTSampler, float2((textureColor.r * 255.0 + 0.5)/256.0, 0.5)).r;
        float g = toneCurveLUT.sample(toneCurveLUTSampler, float2((textureColor.g * 255.0 + 0.5)/256.0, 0.5)).g;
        float b = toneCurveLUT.sample(toneCurveLUTSampler, float2((textureColor.b * 255.0 + 0.5)/256.0, 0.5)).b;
        float4 toneCurvedColor = mix(textureColor, float4(r,g,b,textureColor.a), amount);

        float4 bgChannelOverlayColor = bgChannelOverlayTexture.sample(bgChannelOverlayTextureSampler, vertexIn.textureCoordinate);
        float4 blurredBGChannelOverlayColor = blurredBGChannelOverlayTexture.sample(blurredBGChannelOverlayTextureSampler, vertexIn.textureCoordinate);
        
        float3 mask = bgChannelOverlayColor.rgb - blurredBGChannelOverlayColor.rgb + float3(0.5);
        mask = hardLightBlend(float4(mask, 1.0), float4(mask, 1.0)).rgb;
        mask = hardLightBlend(float4(mask, 1.0), float4(mask, 1.0)).rgb;
        mask = hardLightBlend(float4(mask, 1.0), float4(mask, 1.0)).rgb;
        
        float k = 255.0 / (164.0 - 75.0);
        float maskValue = clamp((mask.r - 75.0 / 255.0) * k, 0.0, 1.0);

        return mix(toneCurvedColor, textureColor, maskValue);
    }
    
}

//
//  LensBlur.metal
//  MetalPetal
//
//  Created by Yu Ao on 13/10/2017.
//

#include <metal_stdlib>



using namespace metal;

namespace metalpetal {
    namespace hexagonalbokeh {
        METAL_FUNC float randomize(float3 scale, float seed, float2 position) {
            return fract(sin(dot(float3(position, 0.0) + seed, scale)) * 43758.5453 + seed);
        }
        
        METAL_FUNC float4 sampleWithDelta(texture2d<float, access::sample> texture, sampler textureSampler, float2 position, float2 delta) {
            /* randomize the lookup values to hide the fixed number of samples */
            float offset = randomize(float3(delta, 151.7182), 0.0, position);
            constexpr int samples = 16;
            float3 color = float3(0.0);
            float blurAmount = 0;
            for (int t = 0.0; t <= samples; t++) {
                float percent = (float(t) + offset) / float(samples);
                float4 textureColor = texture.sample(textureSampler, position + delta * percent);
                blurAmount += textureColor.a;
                textureColor *= textureColor.a;
                color += textureColor.rgb;
            }
            return blurAmount < 0.01 ? texture.sample(textureSampler, position) : float4(color / blurAmount, 1.0);
        }
        
        fragment float4 hexagonalBokehBlurPre(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(1) ]],
                                    sampler maskSampler [[ sampler(1) ]],
                                    constant float & power [[ buffer(0) ]],
                                    constant int &maskComponent [[ buffer(1) ]],
                                    constant bool &usesOneMinusMaskValue [[ buffer(2) ]]) {
            float coc = maskTexture.sample(maskSampler, vertexIn.textureCoordinate)[maskComponent];
            float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
            textureColor.rgb = pow(textureColor.rgb, float3(power));
            return float4(textureColor.rgb, usesOneMinusMaskValue ? 1.0 - coc : coc);
        }
        
        typedef struct {
            float4 vertical [[color(0)]];
            float4 diagonal [[color(1)]];
        } HexagonalBokehBlurAlphaPassOutput;
        
        fragment HexagonalBokehBlurAlphaPassOutput hexagonalBokehBlurAlpha(VertexOut vertexIn [[ stage_in ]],
                                                       texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                       sampler colorSampler [[ sampler(0) ]],
                                                       constant float2 & delta0 [[ buffer(0) ]],
                                                       constant float2 & delta1 [[ buffer(1) ]]) {
            float coc = colorTexture.sample(colorSampler, vertexIn.textureCoordinate).a;
            float4 color1 = sampleWithDelta(colorTexture, colorSampler, vertexIn.textureCoordinate, delta0 * coc);
            float4 color2 = sampleWithDelta(colorTexture, colorSampler, vertexIn.textureCoordinate, delta1 * coc);
            HexagonalBokehBlurAlphaPassOutput output;
            output.vertical = float4(color1.rgb, coc);
            output.diagonal = float4((color2 + color1).rgb, coc);
            return output;
        }
        
        fragment float4 hexagonalBokehBlurBravoCharlie(VertexOut vertexIn [[ stage_in ]],
                                             texture2d<float, access::sample> verticalTexture [[ texture(0) ]],
                                             sampler verticalSampler [[ sampler(0) ]],
                                             texture2d<float, access::sample> diagonalTexture [[ texture(1) ]],
                                             sampler diagonalSampler [[ sampler(1) ]],
                                             constant float2 & delta0 [[ buffer(0) ]],
                                             constant float2 & delta1 [[ buffer(1) ]],
                                             constant float & power [[ buffer(2) ]]) {
            float coc = verticalTexture.sample(verticalSampler, vertexIn.textureCoordinate).a;
            float coc2 = diagonalTexture.sample(diagonalSampler, vertexIn.textureCoordinate).a;
            float4 color = (sampleWithDelta(verticalTexture, verticalSampler, vertexIn.textureCoordinate, delta0 * coc) +
                            sampleWithDelta(diagonalTexture, diagonalSampler, vertexIn.textureCoordinate, delta1 * coc2)) * (1.0/3.0);
            color.rgb = pow(color.rgb, float3(power));
            return float4(color.rgb, 1.0);
        }
    }
    
    
}



//
// This is an auto-generated source file.
//

#include <metal_stdlib>





#ifndef TARGET_OS_SIMULATOR
    #error TARGET_OS_SIMULATOR not defined. Check <TargetConditionals.h>
#endif

using namespace metal;
using namespace metalpetal;

namespace metalpetal {

vertex VertexOut multilayerCompositeVertexShader(
                                        const device VertexIn * vertices [[ buffer(0) ]],
                                        constant float4x4 & transformMatrix [[ buffer(1) ]],
                                        constant float4x4 & orthographicMatrix [[ buffer(2) ]],
                                        uint vid [[ vertex_id ]]
                                        ) {
    VertexOut outVertex;
    VertexIn inVertex = vertices[vid];
    outVertex.position = inVertex.position * transformMatrix * orthographicMatrix;
    outVertex.textureCoordinate = inVertex.textureCoordinate;
    return outVertex;
}

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeNormalBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return normalBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeNormalBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return normalBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeDarkenBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return darkenBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeDarkenBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return darkenBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeMultiplyBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return multiplyBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeMultiplyBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return multiplyBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeColorBurnBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return colorBurnBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeColorBurnBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return colorBurnBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeLinearBurnBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return linearBurnBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeLinearBurnBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return linearBurnBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeDarkerColorBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return darkerColorBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeDarkerColorBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return darkerColorBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeLightenBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return lightenBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeLightenBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return lightenBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeScreenBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return screenBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeScreenBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return screenBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeColorDodgeBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return colorDodgeBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeColorDodgeBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return colorDodgeBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeAddBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return addBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeAddBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return addBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeLighterColorBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return lighterColorBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeLighterColorBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return lighterColorBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeOverlayBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return overlayBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeOverlayBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return overlayBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeSoftLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return softLightBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeSoftLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return softLightBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeHardLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return hardLightBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeHardLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return hardLightBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeVividLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return vividLightBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeVividLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return vividLightBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeLinearLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return linearLightBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeLinearLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return linearLightBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositePinLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return pinLightBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositePinLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return pinLightBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeHardMixBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return hardMixBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeHardMixBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return hardMixBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeDifferenceBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return differenceBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeDifferenceBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return differenceBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeExclusionBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return exclusionBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeExclusionBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return exclusionBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeSubtractBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return subtractBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeSubtractBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return subtractBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeDivideBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return divideBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeDivideBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return divideBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeHueBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return hueBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeHueBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return hueBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeSaturationBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return saturationBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeSaturationBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return saturationBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeColorBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return colorBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeColorBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return colorBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeLuminosityBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return luminosityBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeLuminosityBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.tintColor.a != 0) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return luminosityBlend(backgroundColor,textureColor);
}

#endif

}
//
//  Shaders.metal
//  MetalPetal
//
//

#include <metal_stdlib>





#ifndef TARGET_OS_SIMULATOR
    #error TARGET_OS_SIMULATOR not defined. Check <TargetConditionals.h>
#endif

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
    
    fragment float4 unpremultiplyAlphaWithSRGBToLinearRGB(
                                       VertexOut vertexIn [[ stage_in ]],
                                       texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                       sampler colorSampler [[ sampler(0) ]]
                                       ) {
        float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
        textureColor = unpremultiply(textureColor);
        return float4(sRGBToLinear(textureColor.rgb), textureColor.a);
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
    
    fragment float4 convertSRGBToLinearRGB(VertexOut vertexIn [[ stage_in ]],
                                 texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                 sampler colorSampler [[ sampler(0) ]]) {
        float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
        textureColor.rgb = sRGBToLinear(textureColor.rgb);
        return textureColor;
    }
    
    fragment float4 convertLinearRGBToSRGB(VertexOut vertexIn [[ stage_in ]],
                                 texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                 sampler colorSampler [[ sampler(0) ]]) {
        float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
        textureColor.rgb = linearToSRGB(textureColor.rgb);
        return textureColor;
    }
    
    fragment float4 convertITUR709RGBToLinearRGB(VertexOut vertexIn [[ stage_in ]], texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                 sampler colorSampler [[ sampler(0) ]]) {
        float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
        textureColor.rgb = ITUR709ToLinear(textureColor.rgb);
        return textureColor;
    }
    
    fragment float4 convertITUR709RGBToSRGB(VertexOut vertexIn [[ stage_in ]], texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                 sampler colorSampler [[ sampler(0) ]]) {
        float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
        textureColor.rgb = ITUR709ToLinear(textureColor.rgb);
        textureColor.rgb = linearToSRGB(textureColor.rgb);
        return textureColor;
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

    #if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
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
            intensity *= maskColor[parameters.compositingMaskComponent];
        }
        intensity *= parameters.opacity;
        return colorLookup2DSquareLUT(currentColor,64,intensity,colorTexture,colorSampler);
    }
    
    #else
    
    fragment float4 multilayerCompositeColorLookup512x512Blend(
                                                               VertexOut vertexIn [[ stage_in ]],
                                                               texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                               texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                               constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                               texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                               sampler colorSampler [[ sampler(0) ]],
                                                               constant float2 & viewportSize [[buffer(1)]]
                                                               ) {
        constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
        float2 location = vertexIn.position.xy / viewportSize;
        float4 backgroundColor = backgroundTexture.sample(s, location);
        float intensity = 1.0;
        if (parameters.hasCompositingMask) {
            float4 maskColor = maskTexture.sample(s, location);
            float maskValue = maskColor[parameters.compositingMaskComponent];
            intensity *= maskValue;
        }
        intensity *= parameters.opacity;
        return colorLookup2DSquareLUT(backgroundColor,64,intensity,colorTexture,colorSampler);
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
        overlayColor.a = overlayColor.a * (usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue);
        return normalBlend(baseColor, overlayColor);
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
    
    fragment float4 bulgeDistortion(VertexOut vertexIn [[stage_in]],
                                    texture2d<float, access::sample> sourceTexture [[texture(0)]],
                                    sampler sourceSampler [[sampler(0)]],
                                    constant float & scale [[ buffer(0) ]],
                                    constant float & radius [[ buffer(1) ]],
                                    constant float2 & center [[ buffer(2) ]]) {
        float2 textureSize = float2(sourceTexture.get_width(), sourceTexture.get_height());
        float2 textureCoordinate = vertexIn.textureCoordinate;
        
        float2 texturePixelCoordinate = textureCoordinate * textureSize;
        float dist = distance(texturePixelCoordinate, center);
        
        if (dist < radius) {
            texturePixelCoordinate -= center;
            float percent = 1.0 - ((radius - dist) / radius) * scale;
            percent = percent * percent;
            
            texturePixelCoordinate = texturePixelCoordinate * percent;
            texturePixelCoordinate += center;
            
            textureCoordinate = texturePixelCoordinate / textureSize;
        }
        
        return sourceTexture.sample(sourceSampler, textureCoordinate);
    }
    
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
    
    #if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

    fragment float4 roundCorner(VertexOut vertexIn [[stage_in]],
                                         constant float & radius [[buffer(0)]],
                                         constant float2 & center [[buffer(1)]],
                                         float4 currentColor [[ color(0) ]]) {
        //4xAA
        float2 samplePoint1 = vertexIn.textureCoordinate + float2(-0.25, -0.25);
        float2 samplePoint2 = vertexIn.textureCoordinate + float2(0.25, 0.25);
        float2 samplePoint3 = vertexIn.textureCoordinate + float2(0.25, -0.25);
        float2 samplePoint4 = vertexIn.textureCoordinate + float2(-0.25, 0.25);
        float4 inRadius = float4(bool4(distance(samplePoint1, center) < radius,
                                       distance(samplePoint2, center) < radius,
                                       distance(samplePoint3, center) < radius,
                                       distance(samplePoint4, center) < radius));
        float alpha = dot(inRadius, 0.25);
        float4 result = currentColor;
        result.a *= alpha;
        return result;
    }
    
    #else
    
    fragment float4 roundCorner(VertexOut vertexIn [[stage_in]],
                                constant float4 & radius [[buffer(0)]],
                                texture2d<float, access::sample> sourceTexture [[texture(0)]],
                                sampler sourceSampler [[sampler(0)]]) {
        float2 textureCoordinate = vertexIn.textureCoordinate * float2(sourceTexture.get_width(), sourceTexture.get_height());
        //lt rt rb lb
        float2 lt = float2(radius[0], radius[0]);
        float2 rt = float2(sourceTexture.get_width() - radius[1], radius[1]);
        float2 rb = float2(sourceTexture.get_width() - radius[2], sourceTexture.get_height() - radius[2]);
        float2 lb = float2(radius[3], sourceTexture.get_height() - radius[3]);
        
        float r;
        float2 center;
        if (textureCoordinate.x < lt.x && textureCoordinate.y < lt.y) {
            center = lt;
            r = radius[0];
        } else if (textureCoordinate.x > rt.x && textureCoordinate.y < rt.y) {
            center = rt;
            r = radius[1];
        } else if (textureCoordinate.x > rb.x && textureCoordinate.y > rb.y) {
            center = rb;
            r = radius[2];
        } else if (textureCoordinate.x < lb.x && textureCoordinate.y > lb.y) {
            center = lb;
            r = radius[3];
        } else {
            return sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
        }
        
        //4xAA
        float2 samplePoint1 = textureCoordinate + float2(-0.25, -0.25);
        float2 samplePoint2 = textureCoordinate + float2(0.25, 0.25);
        float2 samplePoint3 = textureCoordinate + float2(0.25, -0.25);
        float2 samplePoint4 = textureCoordinate + float2(-0.25, 0.25);
        float4 inRadius = float4(bool4(distance(samplePoint1, center) < r,
                                       distance(samplePoint2, center) < r,
                                       distance(samplePoint3, center) < r,
                                       distance(samplePoint4, center) < r));
        float f = dot(inRadius, 0.25);
        float4 result = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
        result.a *= f;
        return result;
    }
    
    #endif
}

)mtirawstring";

NSURL * _MTISwiftPMBuiltinLibrarySourceURL(void) {
    static NSURL *url;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *targetConditionals = [NSString stringWithFormat:@"#ifndef TARGET_OS_SIMULATOR\n#define TARGET_OS_SIMULATOR %@\n#endif",@(TARGET_OS_SIMULATOR)];
        NSString *librarySource = [targetConditionals stringByAppendingString:[NSString stringWithCString:MTIBuiltinLibrarySource encoding:NSUTF8StringEncoding]];
        MTLCompileOptions *options = [[MTLCompileOptions alloc] init];
        options.fastMathEnabled = YES;
        options.languageVersion = MTLLanguageVersion1_2;
        url = [MTILibrarySourceRegistration.sharedRegistration registerLibraryWithSource:librarySource compileOptions:options];
    });
    return url;
}