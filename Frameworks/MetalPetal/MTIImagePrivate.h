//
//  MTIImagePrivate.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIImage.h"
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTIImageResolveResult : NSObject

@property (nonatomic, strong, nullable, readonly) id<MTLTexture> texture;

@property (nonatomic, copy, nullable, readonly) NSError *error;

- (instancetype)initWithTexture:(_Nullable id<MTLTexture>)texture error:(NSError * _Nullable)error;

@end

@interface MTIImage (Private)


@end

NS_ASSUME_NONNULL_END
