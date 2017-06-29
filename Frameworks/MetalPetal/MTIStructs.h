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

NS_ASSUME_NONNULL_BEGIN

struct MTIVertex {
    float x, y, z, w, u, v;
};
typedef struct MTIVertex MTIVertex;

struct MTIUniforms {
    matrix_float4x4 modelViewProjectionMatrix;
};
typedef struct MTIUniforms MTIUniforms;


@interface MTIVertices : NSObject

@property (nonatomic,readonly) const MTIVertex *buffer NS_RETURNS_INNER_POINTER;

@property (nonatomic,readonly) NSInteger count;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithVertices:(const MTIVertex * _Nonnull)vertices count:(NSInteger)count NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
