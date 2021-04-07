//
//  Shaders.metal
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/3.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
#include "ShaderTypes.h"

using namespace metal;
using namespace metalpetal;

fragment float4 rgUVGradient(VertexOut vertexIn [[ stage_in ]]) {
    return float4(vertexIn.textureCoordinate.x, vertexIn.textureCoordinate.y, 0, 1);
}

fragment float4 rgUVB1Gradient(VertexOut vertexIn [[ stage_in ]]) {
    return float4(vertexIn.textureCoordinate.x, vertexIn.textureCoordinate.y, 1, 1);
}

fragment float4 radialGradient(VertexOut vertexIn [[ stage_in ]]) {
    return float4(float3(1.0 - smoothstep(0.3, 0.8, distance(vertexIn.textureCoordinate, float2(0.5,0.5)))), 1);
}

fragment float4 imagePow(VertexOut vertexIn [[stage_in]],
                         texture2d<float, access::sample> sourceTexture [[texture(0)]],
                         sampler sourceSampler [[sampler(0)]],
                         constant float &value [[buffer(0)]]
                         ) {
    float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
    return float4(pow(textureColor.rgb, value), 1.0);
}


fragment float4 imageConvolution(
                                 VertexOut vertexIn [[stage_in]],
                                 texture2d<float, access::sample> sourceTexture [[texture(0)]],
                                 sampler sourceSampler [[sampler(0)]],
                                 texture2d<float, access::sample> maskTexture [[texture(1)]],
                                 sampler maskSampler [[sampler(1)]],
                                 texture2d<float, access::sample> kernelTexture [[texture(2)]],
                                 sampler kernelSampler [[sampler(2)]],
                                 constant float &radius [[buffer(0)]],
                                 constant float &brightness [[buffer(1)]]
                                 ) {
    float maskValue = 1.0 - maskTexture.sample(maskSampler, vertexIn.textureCoordinate).r;
    float currentRadius = maskValue * radius;
    if (currentRadius == 0) {
        return sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
    } else {
        float3 color = float3(0);
        float kernelValueSum = 0;
        for (int offsetX = -currentRadius; offsetX < currentRadius; offsetX += 1) {
            for (int offsetY = -currentRadius; offsetY < currentRadius; offsetY += 1) {
                float2 sampleOffset = float2(offsetX, offsetY) / float2(sourceTexture.get_width(), sourceTexture.get_height());
                float maskValue = 1.0 - maskTexture.sample(maskSampler, vertexIn.textureCoordinate + sampleOffset).r;
                float kernelValue = kernelTexture.sample(kernelSampler, float2((offsetX + currentRadius)/currentRadius/2, 1.0 - (offsetY + currentRadius)/currentRadius/2)).r * maskValue;
                color += sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate + sampleOffset).rgb * kernelValue;
                kernelValueSum += kernelValue;
            }
        }
        color = color / kernelValueSum * (1.0 + (brightness - 1.0) * maskValue);
        return float4(color, 1);
    }
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
    if (distance(pointCoord, float2(0.5,0.5)) >= 0.5) {
        discard_fragment();
    }
    return vertexIn.color;
}
