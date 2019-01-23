//
//  MTIStructs.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIVertex.h"
#import "MTIHasher.h"

MTIVertex MTIVertexMake(float x, float y, float z, float w, float u, float v) {
    return (MTIVertex){
        .position = { x, y, z, w },
        .textureCoordinate = { u, v }
    };
}

BOOL MTIVertexEqualToVertex(MTIVertex v1, MTIVertex v2) {
    return simd_equal(v1.position, v2.position) && simd_equal(v1.textureCoordinate, v2.textureCoordinate);
}

@interface MTIVertices () {
    void *_memory;
}

@property (nonatomic,readonly) NSUInteger bufferLength;

@end

@implementation MTIVertices

- (instancetype)initWithVertices:(const MTIVertex *)vertices count:(NSInteger)count primitiveType:(MTLPrimitiveType)primitiveType {
    if (self = [super init]) {
        NSParameterAssert(count > 0);
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

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSUInteger)hash {
    MTIHasher hasher = MTIHasherMake(0);
    for (NSUInteger index = 0; index < _vertexCount; index += 1) {
        MTIVertex v = ((MTIVertex *)_memory)[index];
        MTIHasherCombine(&hasher, v.position.x);
        MTIHasherCombine(&hasher, v.position.y);
        MTIHasherCombine(&hasher, v.position.z);
        MTIHasherCombine(&hasher, v.position.w);
        MTIHasherCombine(&hasher, v.textureCoordinate.x);
        MTIHasherCombine(&hasher, v.textureCoordinate.y);
    }
    return MTIHasherFinalize(&hasher);
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

+ (instancetype)squareVerticesForRect:(CGRect)rect {
    CGFloat l = CGRectGetMinX(rect);
    CGFloat r = CGRectGetMaxX(rect);
    CGFloat t = CGRectGetMinY(rect);
    CGFloat b = CGRectGetMaxY(rect);
    return [[MTIVertices alloc] initWithVertices:(MTIVertex []){
        { .position = {l, t, 0, 1} , .textureCoordinate = { 0, 1 } },
        { .position = {r, t, 0, 1} , .textureCoordinate = { 1, 1 } },
        { .position = {l, b, 0, 1} , .textureCoordinate = { 0, 0 } },
        { .position = {r, b, 0, 1} , .textureCoordinate = { 1, 0 } }
    } count:4 primitiveType:MTLPrimitiveTypeTriangleStrip];
}

+ (instancetype)verticallyFlippedSquareVerticesForRect:(CGRect)rect {
    CGFloat l = CGRectGetMinX(rect);
    CGFloat r = CGRectGetMaxX(rect);
    CGFloat t = CGRectGetMinY(rect);
    CGFloat b = CGRectGetMaxY(rect);
    return [[MTIVertices alloc] initWithVertices:(MTIVertex []){
        { .position = {l, t, 0, 1} , .textureCoordinate = { 0, 0 } },
        { .position = {r, t, 0, 1} , .textureCoordinate = { 1, 0 } },
        { .position = {l, b, 0, 1} , .textureCoordinate = { 0, 1 } },
        { .position = {r, b, 0, 1} , .textureCoordinate = { 1, 1 } }
    } count:4 primitiveType:MTLPrimitiveTypeTriangleStrip];
}

+ (instancetype)fullViewportSquareVertices {
    static MTIVertices *vertices;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        vertices = [MTIVertices squareVerticesForRect:CGRectMake(-1, -1, 2, 2)];
    });
    return vertices;
}

- (void)encodeDrawCallWithCommandEncoder:(id<MTLRenderCommandEncoder>)commandEncoder renderPipeline:(MTIRenderPipeline *)pipeline {
    //assuming buffer bounded to index 0.
    if (self.bufferLength > 0) {
        if (self.bufferLength < 4096) {
            //The setVertexBytes:length:atIndex: method is the best option for binding a very small amount (less than 4 KB) of dynamic buffer data to a vertex function. This method avoids the overhead of creating an intermediary MTLBuffer object. Instead, Metal manages a transient buffer for you.
            [commandEncoder setVertexBytes:_memory length:_bufferLength atIndex:0];
        } else {
            id<MTLBuffer> buffer = [commandEncoder.device newBufferWithBytes:_memory length:_bufferLength options:0];
            [commandEncoder setVertexBuffer:buffer offset:0 atIndex:0];
        }
    }
    [commandEncoder drawPrimitives:_primitiveType vertexStart:0 vertexCount:_vertexCount];
}

@end

