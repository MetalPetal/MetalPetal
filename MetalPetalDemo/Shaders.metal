//
//  Shaders.metal
//  MetalPetalDemo
//
//  Created by Yu Ao on 2019/1/26.
//  Copyright © 2019 MetalPetal. All rights reserved.
//

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

