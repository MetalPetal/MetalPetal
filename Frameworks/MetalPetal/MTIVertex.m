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

@interface MTIVertices ()

@property (nonatomic) void *memory;

@end

@implementation MTIVertices

- (instancetype)initWithVertices:(const MTIVertex *)vertices count:(NSInteger)count {
    if (self = [super init]) {
        _count = count;
        _memory = calloc(count, sizeof(MTIVertex));
        memcpy(_memory, vertices, count * sizeof(MTIVertex));
        _buffer = _memory;
    }
    return self;
}

- (void)dealloc {
    if (_memory) {
        free(_memory);
    }
}

@end
