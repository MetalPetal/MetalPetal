//
//  MTIOverlayBlendFilter.h
//  Pods
//
//  Created by YuAo on 30/07/2017.
//
//

#import <Foundation/Foundation.h>
#import "MTIFilter.h"

@class MTIImage;

@interface MTIOverlayBlendFilter : NSObject <MTIFilter>

@property (nonatomic,strong,nullable) MTIImage *inputBackgroundImage;

@property (nonatomic,strong,nullable) MTIImage *inputForegroundImage;

@end
