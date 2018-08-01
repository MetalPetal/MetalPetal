//
//  MTIImageProperties.h
//  Pods
//
//  Created by YuAo on 2018/6/22.
//

#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTIImageProperties : NSObject <NSCopying>

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initWithImageSource:(CGImageSourceRef)imageSource index:(NSUInteger)index NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCGImage:(CGImageRef)image NS_DESIGNATED_INITIALIZER;

- (nullable instancetype)initWithImageAtURL:(NSURL *)URL;

@property (nonatomic, readonly) CGImageAlphaInfo alphaInfo;
@property (nonatomic, readonly) CGImageByteOrderInfo byteOrderInfo;
@property (nonatomic, readonly) BOOL floatComponents;
@property (nonatomic, readonly, nullable) CGColorSpaceRef colorSpace;

@property (nonatomic, readonly) NSUInteger pixelWidth;
@property (nonatomic, readonly) NSUInteger pixelHeight;

@property (nonatomic, readonly) CGImagePropertyOrientation orientation;

// Width and height with orientation applied.
@property (nonatomic, readonly) NSUInteger displayWidth;
@property (nonatomic, readonly) NSUInteger displayHeight;

@property (nonatomic, copy, readonly) NSDictionary *properties;

@end

NS_ASSUME_NONNULL_END
