//
//  ImageShaders.metal
//  Metal2D
//
//  Created by Kaz Yoshikawa on 12/22/15.
//
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
	packed_float4 position [[ attribute(0) ]];
	packed_float2 texcoords [[ attribute(1) ]];
};

struct VertexOut {
	float4 position [[ position ]];
	float2 texcoords;
};

struct Uniforms {
	float4x4 modelViewProjectionMatrix;
};

vertex VertexOut image_vertex(
	device VertexIn * vertices [[ buffer(0) ]],
	constant Uniforms & uniforms [[ buffer(1) ]],
	uint vid [[ vertex_id ]]
) {
	VertexOut outVertex;
	VertexIn inVertex = vertices[vid];
	outVertex.position = uniforms.modelViewProjectionMatrix * float4(inVertex.position);
	outVertex.texcoords = inVertex.texcoords;
	return outVertex;
}

fragment float4 image_fragment(
	VertexOut vertexIn [[ stage_in ]],
	//constant Uniforms & uniforms [[ buffer(0) ]],
	texture2d<float, access::sample> colorTexture [[ texture(0) ]],
	sampler colorSampler [[ sampler(0) ]]
) {
	return colorTexture.sample(colorSampler, vertexIn.texcoords);
}

fragment float4 image_color_invert(
    VertexOut vertexIn [[ stage_in ]],
    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
    sampler colorSampler [[ sampler(0) ]]
) {
    float3 color = float3(1.0) - colorTexture.sample(colorSampler, vertexIn.texcoords).rgb;
    return float4(color, 1.0);
}
