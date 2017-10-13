//
//  MTIOverlayBlendFilter.h
//  Pods
//
//  Created by YuAo on 30/07/2017.
//
//

#import "MTIFilter.h"

@class MTIImage;

NS_ASSUME_NONNULL_BEGIN

@interface MTIOverlayBlendFilter : NSObject <MTIFilter>

@property (nonatomic,strong,nullable) MTIImage *inputBackgroundImage;

@property (nonatomic,strong,nullable) MTIImage *inputForegroundImage;

@end

NS_ASSUME_NONNULL_END
