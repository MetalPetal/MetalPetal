//
//  MTIUSMSharpenFilter.h
//  MetalPetal
//
//  Created by yi chen on 2018/2/7.
//

#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIMPSUnsharpMaskFilter : NSObject  <MTIUnaryFilter>

@property (nonatomic) float scale; //(0, 1]. Default is 0.5.
@property (nonatomic) float radius;
@property (nonatomic) float threshold; //[0, 1). Default is 0.

@end

NS_ASSUME_NONNULL_END
