//
//  MTIGeometry.h
//  Pods
//
//  Created by Yu Ao on 2018/5/6.
//

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MTIGeometry <NSObject, NSCopying>

@property (nonatomic,readonly) NSUInteger vertexCount;

@property (nonatomic,readonly) MTLPrimitiveType primitiveType;

@property (nonatomic,readonly) const void *bufferBytes NS_RETURNS_INNER_POINTER;
@property (nonatomic,readonly) NSUInteger bufferLength;

@end

NS_ASSUME_NONNULL_END

