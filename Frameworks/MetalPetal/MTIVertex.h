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
#import "MTIGeometry.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT MTIVertex MTIVertexMake(float x, float y, float z, float w, float u, float v) NS_SWIFT_NAME(MTIVertex.init(x:y:z:w:u:v:));
FOUNDATION_EXPORT BOOL MTIVertexEqualToVertex(MTIVertex v1, MTIVertex v2) NS_SWIFT_NAME(MTIVertex.isEqual(self:to:));


/// A MTIGeometry implementation. A MTIVertices contains MTIVertex data structures. It is designed to handle small amount of vertices. A MTIVertices bounds its contents to the vertex buffer with index of 0. The shader receives a MTIVertices' contents as `MTIVertex *`. e.g. `const device MTIVertex * vertices [[ buffer(0) ]]`.
@interface MTIVertices : NSObject <MTIGeometry>

@property (nonatomic,readonly) NSUInteger vertexCount;

@property (nonatomic,readonly) MTLPrimitiveType primitiveType;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithVertices:(const MTIVertex * _Nonnull)vertices count:(NSInteger)count primitiveType:(MTLPrimitiveType)primitiveType NS_DESIGNATED_INITIALIZER NS_REFINED_FOR_SWIFT;

+ (instancetype)squareVerticesForRect:(CGRect)rect;

+ (instancetype)verticallyFlippedSquareVerticesForRect:(CGRect)rect;

@property (nonatomic, class, readonly, strong) MTIVertices *fullViewportSquareVertices;

@end


NS_ASSUME_NONNULL_END
