//
//  MTKTextureLoaderExtension.h
//  Pods
//
//  Created by Yu Ao on 06/12/2017.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

#if TARGET_OS_IPHONE

MTK_EXTERN MTKTextureLoaderOption __nonnull const MTIMTKTextureLoaderOptionOverrideImageOrientation_iOS9;

@interface MTIMTKTextureLoaderExtensions: NSObject

/// MTKTextureLoaderOption + @{ MTIMTKTextureLoaderOptionOverrideImageOrientation_iOS9: @4 }
@property (nonatomic,class) BOOL automaticallyFlipsTextureOniOS9;

@end

#endif
