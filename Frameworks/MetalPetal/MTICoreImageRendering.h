//
//  MTICoreImageRendering.h
//  Pods
//
//  Created by Yu Ao on 04/04/2018.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Metal/Metal.h>
#import <CoreImage/CoreImage.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTICIImageRenderingOptions : NSObject <NSCopying>

@property (nullable, nonatomic, readonly) CGColorSpaceRef colorSpace;

@property (getter=isFlipped, readonly, nonatomic) BOOL flipped;

@property (nonatomic, readonly) MTLPixelFormat destinationPixelFormat;

@property (nonatomic, readonly) CIRenderDestinationAlphaMode alphaMode;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDestinationPixelFormat:(MTLPixelFormat)pixelFormat colorSpace:(nullable CGColorSpaceRef)colorSpace flipped:(BOOL)flipped;

- (instancetype)initWithDestinationPixelFormat:(MTLPixelFormat)pixelFormat alphaMode:(CIRenderDestinationAlphaMode)alphaMode colorSpace:(nullable CGColorSpaceRef)colorSpace flipped:(BOOL)flipped NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, class, readonly) MTICIImageRenderingOptions *defaultOptions;

@end

__attribute__((objc_subclassing_restricted))
@interface MTICIImageCreationOptions: NSObject <NSCopying>

@property (nonatomic, nullable, readonly) CGColorSpaceRef colorSpace;

@property (getter=isFlipped, readonly, nonatomic) BOOL flipped;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithColorSpace:(nullable CGColorSpaceRef)colorSpace flipped:(BOOL)flipped NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, class, readonly) MTICIImageCreationOptions *defaultOptions;

@end

NS_ASSUME_NONNULL_END
