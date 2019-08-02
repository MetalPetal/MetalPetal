//
//  MTITextureLoader.h
//  MetalPetal
//
//  Created by Yu Ao on 2019/1/10.
//

#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Abstract interface for texture loader.
@protocol MTITextureLoader <NSObject>

+ (instancetype)newTextureLoaderWithDevice:(id <MTLDevice>)device;

- (nullable id <MTLTexture>)newTextureWithCGImage:(nonnull CGImageRef)cgImage
                                          options:(nullable NSDictionary <MTKTextureLoaderOption, id> *)options
                                            error:(NSError *__nullable *__nullable)error;

- (nullable id <MTLTexture>)newTextureWithContentsOfURL:(nonnull NSURL *)URL
                                                options:(nullable NSDictionary <MTKTextureLoaderOption, id> *)options
                                                  error:(NSError *__nullable *__nullable)error;

- (nullable id <MTLTexture>)newTextureWithName:(nonnull NSString *)name
                                   scaleFactor:(CGFloat)scaleFactor
                                        bundle:(nullable NSBundle *)bundle
                                       options:(nullable NSDictionary <MTKTextureLoaderOption, id> *)options
                                         error:(NSError *__nullable *__nullable)error;

- (nullable id <MTLTexture>)newTextureWithMDLTexture:(nonnull MDLTexture *)texture
                                             options:(nullable NSDictionary <MTKTextureLoaderOption, id> *)options
                                               error:(NSError *__nullable *__nullable)error;

@end

@interface MTKTextureLoader (MTITextureLoader) <MTITextureLoader>

@end

NS_ASSUME_NONNULL_END
