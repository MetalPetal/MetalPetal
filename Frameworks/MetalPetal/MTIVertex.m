//
//  MTIStructs.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIVertex.h"

MTIVertex MTIVertexMake(float x, float y, float z, float w, float u, float v) {
    return (MTIVertex){
        .position = { x, y, z, w },
        .textureCoordinate = { u, v }
    };
}

/*
MTLVertexDescriptor * MTIVertexCreateMTLVertexDescriptor(void) {
    static MTLVertexDescriptor *vertexDescriptor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        vertexDescriptor = [[MTLVertexDescriptor alloc] init];
        vertexDescriptor.attributes[0].offset = 0;
        vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
        vertexDescriptor.attributes[0].bufferIndex = 0;
        
        vertexDescriptor.attributes[1].offset = 0;
        vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
        vertexDescriptor.attributes[1].bufferIndex = 0;
        
        vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
        vertexDescriptor.layouts[0].stride = sizeof(MTIVertex);
    });
    return [vertexDescriptor copy];
}
*/

@implementation MTIVertices
@synthesize bufferData = _bufferData;
@synthesize primitiveType = _primitiveType;
@synthesize vertexCount = _vertexCount;

- (instancetype)initWithVertices:(const MTIVertex *)vertices count:(NSInteger)count {
    return [self initWithVertices:vertices count:count primitiveType:MTLPrimitiveTypeTriangleStrip];
}

- (instancetype)initWithVertices:(const MTIVertex *)vertices count:(NSInteger)count primitiveType:(MTLPrimitiveType)primitiveType {
    if (self = [super init]) {
        _vertexCount = count;
        _bufferData = [NSData dataWithBytes:vertices length:count * sizeof(MTIVertex)];
        _primitiveType = primitiveType;
    }
    return self;
}
- (const MTIVertex *)buffer {
    return _bufferData.bytes;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end

