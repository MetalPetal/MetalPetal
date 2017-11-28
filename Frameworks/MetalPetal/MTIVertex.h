//
//  MTIStructs.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import <simd/simd.h>
#import <Metal/Metal.h>
#import "MTIShaderLib.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MTIGeometry <NSObject, NSCopying>

@property (nonatomic,readonly) NSUInteger vertexCount;

@property (nonatomic,readonly) MTLPrimitiveType primitiveType;

@property (nonatomic,readonly) const void *bufferBytes NS_RETURNS_INNER_POINTER;
@property (nonatomic,readonly) NSUInteger bufferLength;

@end

FOUNDATION_EXPORT MTIVertex MTIVertexMake(float x, float y, float z, float w, float u, float v) NS_SWIFT_NAME(MTIVertex.init(x:y:z:w:u:v:));
FOUNDATION_EXPORT BOOL MTIVertexEqualToVertex(MTIVertex v1, MTIVertex v2) NS_SWIFT_NAME(MTIVertex.isEqual(self:to:));

@interface MTIVertices : NSObject <MTIGeometry>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithVertices:(const MTIVertex * _Nonnull)vertices count:(NSInteger)count primitiveType:(MTLPrimitiveType)primitiveType NS_DESIGNATED_INITIALIZER NS_REFINED_FOR_SWIFT;

+ (instancetype)squareVerticesForRect:(CGRect)rect;

@end


NS_ASSUME_NONNULL_END
