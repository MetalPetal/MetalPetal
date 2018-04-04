//
//  MTICoreImageRendering.h
//  Pods
//
//  Created by Yu Ao on 04/04/2018.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTICIImageRenderingOptions : NSObject <NSCopying>

@property (nullable, nonatomic, readonly) CGColorSpaceRef colorSpace;

@property (getter=isFlipped, readonly) BOOL flipped;

@property (nonatomic, readonly) MTLPixelFormat destinationPixelFormat;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDestinationPixelFormat:(MTLPixelFormat)pixelFormat colorSpace:(nullable CGColorSpaceRef)colorSpace flipped:(BOOL)flipped NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, class, readonly) MTICIImageRenderingOptions *defaultOptions;

@end

@interface MTICIImageCreationOptions: NSObject <NSCopying>

@property (nonatomic, nullable, readonly) CGColorSpaceRef colorSpace;

@property (getter=isFlipped, readonly) BOOL flipped;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithColorSpace:(nullable CGColorSpaceRef)colorSpace flipped:(BOOL)flipped NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, class, readonly) MTICIImageCreationOptions *defaultOptions;

@end

NS_ASSUME_NONNULL_END
