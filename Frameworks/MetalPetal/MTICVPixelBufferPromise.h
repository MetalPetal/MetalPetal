//
//  MTICVPixelBufferPromise.h
//  Pods
//
//  Created by YuAo on 21/07/2017.
//
//

#import <Foundation/Foundation.h>
#import "MTIImagePromise.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTICVPixelBufferPromise : NSObject <MTIImagePromise>

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
