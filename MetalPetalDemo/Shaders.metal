//
//  Shaders.metal
//  MetalPetalDemo
//
//  Created by Yu Ao on 2019/1/26.
//  Copyright © 2019 MetalPetal. All rights reserved.
//

#include "MTIShaderLib.h"
#include "BouncingBallTypes.h"
#include <metal_stdlib>
using namespace metal;

struct ColoredVertex {
    float4 position [[position]];
    float4 color;
};

vertex ColoredVertex demoColoredVertex (const device ColoredVertex * vertices [[ buffer(0) ]], uint vid [[ vertex_id ]], uint instance [[instance_id]]) {
    ColoredVertex vout;
    vout = vertices[vid];
    vout.position *= float4(0.5, 0.5, 1.0, 1.0);
    vout.position += 0.5 * float4(sin(float(instance/18.0 * 3.14159)), cos(float(instance/18.0 * 3.14159)), 0, 0);
    return vout;
}

fragment float4 demoColoredFragment(ColoredVertex vertexIn [[ stage_in ]]) {
    return vertexIn.color;
}

fragment float4 tintBrush(metalpetal::VertexOut vertexIn [[ stage_in ]],
                          texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                          sampler colorSampler [[ sampler(0) ]],
                          constant float4 &color [[ buffer(0) ]]) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    textureColor.rgb = color.rgb;
    textureColor.a *= color.a;
    return textureColor;
}

fragment float4 magicTintBrushIconGenerator(metalpetal::VertexOut vertexIn [[ stage_in ]]) {
    return float4(vertexIn.textureCoordinate.x, vertexIn.textureCoordinate.y, 1, 1);
}


kernel void bouncingBallCompute(texture2d<float, access::write> outTexture [[texture(0)]],
                                device ParticleData * data [[buffer(0)]],
                                uint gid [[thread_position_in_grid]]) {
    constexpr float tickTime = 0.016 * 10;
    constexpr float g = 9.8;
    auto d = data[gid];
    d.position.y = d.position.y + d.speed.y * tickTime;
    if (d.position.y >= 1024 - d.size/2) {
        d.position.y = 1024 - d.size/2;
        d.speed.y = -d.speed.y * 0.9; //energy loss
    }
    float drag = (abs(d.speed.y) * d.size) / 100.0;
    d.speed.y = d.speed.y + tickTime * (g - drag);
    data[gid] = d;
}
    
struct BouncingBallVertex {
    float4 position [[position]];
    float size [[point_size]];
    float4 color;
};

vertex BouncingBallVertex bouncingBallVertex(const device ParticleData * data [[ buffer(0) ]], uint vid [[ vertex_id ]], uint instance [[instance_id]]) {
    BouncingBallVertex vout;
    vout.position = float4(0,0,0,1);
    float2 p =  data[instance].position / float2(1024,1024);
    p.y = 1.0 - p.y;
    vout.position.xy = (p - 0.5) * 2;
    vout.size = data[instance].size;
    vout.color = float4(1,vout.size/48.0, 1.0 - vout.size/48.0,1);
    return vout;
}

fragment float4 bouncingBallFragment(BouncingBallVertex vertexIn [[ stage_in ]], float2 pointCoord [[point_coord]]) {
    if (distance(pointCoord, float2(0.5,0.5)) < 0.5) {
        return vertexIn.color;
    } else {
        discard_fragment();
    }
}
