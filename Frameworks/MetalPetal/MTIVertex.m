//
//  MTIStructs.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIVertex.h"
#import "MTIHasher.h"
#import "MTIBuffer.h"

MTIVertex MTIVertexMake(float x, float y, float z, float w, float u, float v) {
    return (MTIVertex){
        .position = { x, y, z, w },
        .textureCoordinate = { u, v }
    };
}

BOOL MTIVertexEqualToVertex(MTIVertex v1, MTIVertex v2) {
    return simd_equal(v1.position, v2.position) && simd_equal(v1.textureCoordinate, v2.textureCoordinate);
}

@protocol MTIVertexBuffer <NSObject>

- (instancetype)initWithContents:(const void *)bytes length:(NSUInteger)length;

@property (nonatomic, readonly) const void *contents;

@property (nonatomic, readonly) NSUInteger length;

- (void)encodeToVertexBufferAtIndex:(NSUInteger)index withCommandEncoder:(id<MTLRenderCommandEncoder>)commandEncoder;

@end

@interface MTIMallocDataBuffer : NSObject <MTIVertexBuffer> {
    void * _memory;
}
@end

@implementation MTIMallocDataBuffer
@synthesize length = _length;

- (void)dealloc {
    free(_memory);
}

- (instancetype)initWithContents:(const void *)bytes length:(NSUInteger)length {
    if (self = [super init]) {
        _memory = malloc(length);
        memcpy(_memory, bytes, length);
        _length = length;
    }
    return self;
}

- (const void *)contents {
    return _memory;
}

- (id<MTLBuffer>)bufferForDevice:(id<MTLDevice>)device {
    return [device newBufferWithBytes:_memory length:_length options:0];
}

- (void)encodeToVertexBufferAtIndex:(NSUInteger)index withCommandEncoder:(id<MTLRenderCommandEncoder>)commandEncoder {
    [commandEncoder setVertexBytes:_memory length:_length atIndex:index];
}

@end

@interface MTIDataBuffer (MTIVertexBuffer) <MTIVertexBuffer>

@end

@implementation MTIDataBuffer (MTIVertexBuffer)

- (instancetype)initWithContents:(const void *)bytes length:(NSUInteger)length {
    return [self initWithBytes:bytes length:length options:0];
}

- (const void *)contents {
    __block const void *_contents;
    [self unsafeAccess:^(void * _Nonnull contents, NSUInteger length) {
        _contents = contents;
    }];
    return _contents;
}

- (void)encodeToVertexBufferAtIndex:(NSUInteger)index withCommandEncoder:(id<MTLRenderCommandEncoder>)commandEncoder {
    [commandEncoder setVertexBuffer:[self bufferForDevice:commandEncoder.device] offset:0 atIndex:index];
}

@end

@interface MTIVertices ()

@property (nonatomic, readonly, strong) id<MTIVertexBuffer> vertexBuffer;
@property (nonatomic, readonly, strong) MTIDataBuffer *indexBuffer;

@end

@implementation MTIVertices

- (instancetype)initWithVertices:(const MTIVertex *)vertices count:(NSUInteger)count primitiveType:(MTLPrimitiveType)primitiveType {
    if (self = [super init]) {
        NSParameterAssert(count > 0);
        _vertexCount = count;
        _primitiveType = primitiveType;
        NSUInteger bufferLength = count * sizeof(MTIVertex);
        if (bufferLength < 4096) {
            _vertexBuffer = [[MTIMallocDataBuffer alloc] initWithContents:vertices length:bufferLength];
        } else {
            _vertexBuffer = [[MTIDataBuffer alloc] initWithContents:vertices length:bufferLength];
        }
        NSAssert(_vertexBuffer, @"Cannot allocate memory for MTIVertices, vertexCount: %@.", @(count));
        _indexBuffer = nil;
        _indexCount = 0;
    }
    return self;
}

- (instancetype)initWithVertexBuffer:(MTIDataBuffer *)vertexBuffer vertexCount:(NSUInteger)vertexCount indexBuffer:(MTIDataBuffer *)indexBuffer indexCount:(NSUInteger)indexCount primitiveType:(MTLPrimitiveType)primitiveType {
    if (self = [super init]) {
        NSParameterAssert(vertexCount > 0);
        NSParameterAssert(vertexBuffer.length == vertexCount * sizeof(MTIVertex));
        NSParameterAssert(indexBuffer.length == indexCount * sizeof(uint32_t));
        _vertexCount = vertexCount;
        _indexCount = indexCount;
        _primitiveType = primitiveType;
        _vertexBuffer = vertexBuffer;
        _indexBuffer = indexBuffer;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSUInteger)hash {
    MTIHasher hasher = MTIHasherMake(0);
    for (NSUInteger index = 0; index < _vertexCount; index += 1) {
        MTIVertex v = ((MTIVertex *)_vertexBuffer.contents)[index];
        MTIHasherCombine(&hasher, v.position.x);
        MTIHasherCombine(&hasher, v.position.y);
        MTIHasherCombine(&hasher, v.position.z);
        MTIHasherCombine(&hasher, v.position.w);
        MTIHasherCombine(&hasher, v.textureCoordinate.x);
        MTIHasherCombine(&hasher, v.textureCoordinate.y);
    }
    for (NSUInteger index = 0; index < _indexCount; index += 1) {
        uint32_t i = ((uint32_t *)_vertexBuffer.contents)[index];
        MTIHasherCombine(&hasher, i);
    }
    return MTIHasherFinalize(&hasher);
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[MTIVertices class]]) {
        MTIVertices *other = object;
        if (_vertexCount == other -> _vertexCount && _indexCount == other -> _indexCount) {
            BOOL equal = YES;
            
            for (NSUInteger index = 0; index < _vertexCount; index += 1) {
                MTIVertex v1 = ((MTIVertex *)_vertexBuffer.contents)[index];
                MTIVertex v2 = ((MTIVertex *)other -> _vertexBuffer.contents)[index];
                if (!MTIVertexEqualToVertex(v1, v2)) {
                    equal = NO;
                    break;
                }
            }
            
            if (!equal) {
                return NO;
            }
            
            for (NSUInteger index = 0; index < _indexCount; index += 1) {
                uint32_t i1 = ((uint32_t *)_indexBuffer.contents)[index];
                uint32_t i2 = ((uint32_t *)other -> _indexBuffer.contents)[index];
                if (i1 != i2) {
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

- (void)encodeDrawCallWithCommandEncoder:(id<MTLRenderCommandEncoder>)commandEncoder context:(id<MTIGeometryRenderingContext>)context {
    //assuming buffer bounded to index 0.
    [_vertexBuffer encodeToVertexBufferAtIndex:0 withCommandEncoder:commandEncoder];
    if (_indexBuffer) {
        [commandEncoder drawIndexedPrimitives:_primitiveType indexCount:_indexCount indexType:MTLIndexTypeUInt32 indexBuffer:[_indexBuffer bufferForDevice:commandEncoder.device] indexBufferOffset:0];
    } else {
        [commandEncoder drawPrimitives:_primitiveType vertexStart:0 vertexCount:_vertexCount];
    }
}

@end

@implementation MTIDataBuffer (MTIVertices)

+ (instancetype)dataBufferWithMTIVertices:(const MTIVertex *)vertices count:(NSUInteger)count {
    return [[self alloc] initWithBytes:vertices length:count * sizeof(MTIVertex) options:0];
}

+ (instancetype)dataBufferWithUInt32Indexes:(const uint32_t *)indexes count:(NSUInteger)count {
    return [[self alloc] initWithBytes:indexes length:count * sizeof(uint32_t) options:0];
}

@end
