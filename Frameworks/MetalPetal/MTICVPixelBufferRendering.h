//
//  MTICVPixelBufferRendering.h
//  MetalPetal
//
//  Created by Yu Ao on 08/04/2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MTICVPixelBufferRenderingAPI) {
    MTICVPixelBufferRenderingAPIDefault = 1,
    MTICVPixelBufferRenderingAPIMetalPetal = 1,
    MTICVPixelBufferRenderingAPICoreImage = 2
};

@interface MTICVPixelBufferRenderingOptions: NSObject <NSCopying>

@property (nonatomic, readonly) MTICVPixelBufferRenderingAPI renderingAPI;

@property (nonatomic, readonly) BOOL sRGB; //An option for treating the pixel buffer data as sRGB image data. Specifying whether to create the texture with an sRGB (gamma corrected) pixel format.

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithRenderingAPI:(MTICVPixelBufferRenderingAPI)renderingAPI sRGB:(BOOL)sRGB NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, class, readonly) MTICVPixelBufferRenderingOptions *defaultOptions;

@end

NS_ASSUME_NONNULL_END
