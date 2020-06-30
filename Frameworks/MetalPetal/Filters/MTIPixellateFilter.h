//
//  MTIPixellateFilter.h
//  Pods
//
//  Created by Yu Ao on 08/01/2018.
//

#import <MTIUnaryImageRenderingFilter.h>

__attribute__((objc_subclassing_restricted))
@interface MTIPixellateFilter : MTIUnaryImageRenderingFilter

@property (nonatomic) CGSize scale;

@end
