//
//  MTIMask.h
//  MetalPetal
//
//  Created by Yu Ao on 14/11/2017.
//

#import <Foundation/Foundation.h>
#import "MTIColor.h"

NS_ASSUME_NONNULL_BEGIN

@class MTIImage;

typedef NS_ENUM(NSInteger, MTIMaskMode) {
    MTIMaskModeNormal = 0,
    MTIMaskModeOneMinusMaskValue
};

@interface MTIMask : NSObject <NSCopying>

@property (nonatomic, strong, readonly) MTIImage *content;

@property (nonatomic, readonly) MTIColorComponent component;

@property (nonatomic, readonly) MTIMaskMode mode;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithContent:(MTIImage *)content component:(MTIColorComponent)component mode:(MTIMaskMode)mode NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithContent:(MTIImage *)content;

@end

NS_ASSUME_NONNULL_END
