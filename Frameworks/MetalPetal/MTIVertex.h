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

FOUNDATION_EXPORT MTIVertex MTIVertexMake(float x, float y, float z, float w, float u, float v) NS_SWIFT_NAME(MTIVertex.init(x:y:z:w:u:v:));

//FOUNDATION_EXPORT MTLVertexDescriptor * MTIVertexCreateMTLVertexDescriptor(void);

@interface MTIVertices : NSObject

@property (nonatomic,readonly) const MTIVertex *buffer NS_RETURNS_INNER_POINTER;

@property (nonatomic,readonly) NSInteger count;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithVertices:(const MTIVertex * _Nonnull)vertices count:(NSInteger)count NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
