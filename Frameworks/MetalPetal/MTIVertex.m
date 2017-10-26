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

BOOL MTIVertexEqualToVertex(MTIVertex v1, MTIVertex v2) {
    return simd_equal(v1.position, v2.position) && simd_equal(v1.textureCoordinate, v2.textureCoordinate);
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

@interface MTIVertices () {
    void *_memory;
}

@end

@implementation MTIVertices
@synthesize primitiveType = _primitiveType;
@synthesize vertexCount = _vertexCount;
@synthesize bufferLength = _bufferLength;

- (instancetype)initWithVertices:(const MTIVertex *)vertices count:(NSInteger)count {
    return [self initWithVertices:vertices count:count primitiveType:MTLPrimitiveTypeTriangleStrip];
}

- (instancetype)initWithVertices:(const MTIVertex *)vertices count:(NSInteger)count primitiveType:(MTLPrimitiveType)primitiveType {
    if (self = [super init]) {
        _vertexCount = count;
        _primitiveType = primitiveType;
        NSUInteger bufferLength = count * sizeof(MTIVertex);
        void *memory = malloc(bufferLength);
        memcpy(memory, vertices, bufferLength);
        _bufferLength = bufferLength;
        _memory = memory;
    }
    return self;
}

- (void)dealloc {
    free(_memory);
}

- (const void *)bufferBytes {
    return _memory;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[MTIVertices class]]) {
        MTIVertices *other = object;
        if (_bufferLength == other -> _bufferLength) {
            BOOL equal = YES;
            for (NSUInteger index = 0; index < _bufferLength/sizeof(MTIVertex); index += 1) {
                MTIVertex v1 = ((MTIVertex *)_memory)[index];
                MTIVertex v2 = ((MTIVertex *)other -> _memory)[index];
                if (!MTIVertexEqualToVertex(v1, v2)) {
                    equal = NO;
                    break;
                }
            }
            return equal;
        }
        return NO;
    } else {
        return NO;
    }
}

@end

