//
//  MTIGeometryUtilities.h
//  MetalPetal
//
//  Created by Yu Ao on 2019/11/8.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT CGRect MTIMakeRectWithAspectRatioFillRect(CGSize aspectRatio, CGRect boundingRect) NS_SWIFT_NAME(MTIMakeRect(aspectRatio:fillRect:));

FOUNDATION_EXPORT CGRect MTIMakeRectWithAspectRatioInsideRect(CGSize aspectRatio, CGRect boundingRect) NS_SWIFT_NAME(MTIMakeRect(aspectRatio:insideRect:));

NS_ASSUME_NONNULL_END
