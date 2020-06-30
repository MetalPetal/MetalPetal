//
//  MTIMPSDefinitionFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 2018/8/21.
//

#import <MTIFilter.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIMPSDefinitionFilter : NSObject <MTIUnaryFilter>

@property (nonatomic) float intensity;

@end

NS_ASSUME_NONNULL_END
