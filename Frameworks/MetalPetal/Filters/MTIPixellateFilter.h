//
//  MTIPixellateFilter.h
//  Pods
//
//  Created by Yu Ao on 08/01/2018.
//

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIUnaryImageRenderingFilter.h>
#else
#import "MTIUnaryImageRenderingFilter.h"
#endif

__attribute__((objc_subclassing_restricted))
@interface MTIPixellateFilter : MTIUnaryImageRenderingFilter

@property (nonatomic) CGSize scale;

@end
