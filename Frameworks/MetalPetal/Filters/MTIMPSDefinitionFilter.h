//
//  MTIMPSDefinitionFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 2018/8/21.
//

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIFilter.h>
#else
#import "MTIFilter.h"
#endif

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIMPSDefinitionFilter : NSObject <MTIUnaryFilter>

@property (nonatomic) float intensity;

@end

NS_ASSUME_NONNULL_END
