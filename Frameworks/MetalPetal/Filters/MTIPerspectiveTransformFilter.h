//
//  MTIPerspectiveTransformFilter.h
//  GPUImageBeauty
//
//  Created by apple on 2018/8/16.
//  Copyright © 2018年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <MetalPetal/MetalPetal.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTIPerspectiveTransformFilter : NSObject <MTIUnaryFilter>

@property (nonatomic, assign) MTIVerticeRegion verticeRegion;
@property (nonatomic, assign) CGSize backgroundSize;
@property (nonatomic, assign) CGSize outputImageSize;

@end

NS_ASSUME_NONNULL_END
