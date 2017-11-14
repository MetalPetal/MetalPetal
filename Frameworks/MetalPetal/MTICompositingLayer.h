//
//  MTICompositingLayer.h
//  MetalPetal
//
//  Created by Yu Ao on 14/11/2017.
//

#import <Foundation/Foundation.h>
#import "MTIBlendModes.h"

NS_ASSUME_NONNULL_BEGIN

@class MTIImage;

@interface MTICompositingLayer: NSObject

@property (nonatomic, strong, readonly) MTIImage *content;

@property (nonatomic, readonly) CGRect contentRegion; //pixel

@property (nonatomic, strong, readonly, nullable) MTIImage *compositingMask;

@property (nonatomic, readonly) CGPoint position; //pixel

@property (nonatomic, readonly) CGSize size; //pixel

@property (nonatomic, readonly) CGFloat rotation; //rad

@property (nonatomic, readonly) CGFloat opacity;

@property (nonatomic, copy, readonly) MTIBlendMode blendMode;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithContent:(MTIImage *)content
                       position:(CGPoint)position
                           size:(CGSize)size
                       rotation:(CGFloat)rotation
                        opacity:(CGFloat)opacity
                      blendMode:(MTIBlendMode)blendMode;

- (instancetype)initWithContent:(MTIImage *)content
                  contentRegion:(CGRect)contentRegion
                compositingMask:(nullable MTIImage *)compositingMask
                       position:(CGPoint)position
                           size:(CGSize)size
                       rotation:(CGFloat)rotation
                        opacity:(CGFloat)opacity
                      blendMode:(MTIBlendMode)blendMode NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

