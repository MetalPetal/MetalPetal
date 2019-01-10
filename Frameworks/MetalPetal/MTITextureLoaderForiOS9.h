//
//  MTKTextureLoaderExtension.h
//  Pods
//
//  Created by Yu Ao on 06/12/2017.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import "MTITextureLoader.h"

#if TARGET_OS_IPHONE

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief A custom implemented texture loader for iOS 9, which loads images without filpping them vertically. This matches the behavior of `MTKTextureLoader` on iOS 10 and above.
 
 @discussion To use this texture loader, assgin MTITextureLoaderForiOS9WithImageOrientationFix.class to MTIContextOptions.defaultTextureLoaderClass on iOS 9 only.
 
 @code
 if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_9_x_Max) {
    MTIContextOptions.defaultTextureLoaderClass = MTITextureLoaderForiOS9WithImageOrientationFix.class;
 }
*/

NS_CLASS_DEPRECATED_IOS(9_0, 10_0, "Use MTKTextureLoader instead.") __TVOS_PROHIBITED
@interface MTITextureLoaderForiOS9WithImageOrientationFix : NSObject <MTITextureLoader>

@end

NS_ASSUME_NONNULL_END

#endif
