//
//  MTILookUpTableFilter.h
//  MetalPetal
//
//  Created by 杨乃川 on 2017/10/12.
//

#import "MTIFilter.h"
NS_ASSUME_NONNULL_BEGIN

@interface MTIColorLookupFilter : NSObject <MTIFilter>
@property (nonatomic, strong, nullable) MTIImage *inputImage;
@property (nonatomic, strong, nullable) MTIImage *inputColorLookupTable;
@end
NS_ASSUME_NONNULL_END
