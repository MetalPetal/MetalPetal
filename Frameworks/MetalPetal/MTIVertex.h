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
#import "MTIShaderTypes.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MTIGeometry <NSObject, NSCopying>

@property (nonatomic,copy,readonly) NSData *bufferData;

@property (nonatomic,readonly) NSUInteger vertexCount;

@property (nonatomic,readonly) MTLPrimitiveType primitiveType;

@end

FOUNDATION_EXPORT MTIVertex MTIVertexMake(float x, float y, float z, float w, float u, float v) NS_SWIFT_NAME(MTIVertex.init(x:y:z:w:u:v:));

@interface MTIVertices : NSObject <MTIGeometry>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithVertices:(const MTIVertex * _Nonnull)vertices count:(NSInteger)count; //MTLPrimitiveTypeTriangleStrip

- (instancetype)initWithVertices:(const MTIVertex * _Nonnull)vertices count:(NSInteger)count primitiveType:(MTLPrimitiveType)primitiveType NS_DESIGNATED_INITIALIZER NS_REFINED_FOR_SWIFT;

@end


NS_ASSUME_NONNULL_END
