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

vertex VertexOut passthroughVertexShader(
    const device VertexIn * vertices [[ buffer(0) ]],
	//constant float4x4 & modelViewProjectionMatrix [[ buffer(1) ]],
	uint vid [[ vertex_id ]]
) {
	VertexOut outVertex;
	VertexIn inVertex = vertices[vid];
    outVertex.position = inVertex.position; //modelViewProjectionMatrix * float4(inVertex.position);
	outVertex.texcoords = inVertex.texcoords;
	return outVertex;
}

fragment float4 passthroughFragmentShader(
	VertexOut vertexIn [[ stage_in ]],
	texture2d<float, access::sample> colorTexture [[ texture(0) ]],
	sampler colorSampler [[ sampler(0) ]]
) {
	return colorTexture.sample(colorSampler, vertexIn.texcoords);
}



fragment float4 colorInvert(
    VertexOut vertexIn [[ stage_in ]],
    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
    sampler colorSampler [[ sampler(0) ]]
) {
    float3 color = float3(1.0) - colorTexture.sample(colorSampler, vertexIn.texcoords).rgb;
    return float4(color, 1.0);
}

fragment float4 saturationAdjust(
    VertexOut vertexIn [[ stage_in ]],
    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
    sampler colorSampler [[ sampler(0) ]],
    constant float & saturation [[ buffer(0) ]]
) {
    const float3 luminanceWeighting = float3(0.2125, 0.7154, 0.0721);
    
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float luminance = dot(textureColor.rgb, luminanceWeighting);
    float3 greyScaleColor = float3(luminance);
    return float4(mix(greyScaleColor, textureColor.rgb, saturation), textureColor.a);
}
