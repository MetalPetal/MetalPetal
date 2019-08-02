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
