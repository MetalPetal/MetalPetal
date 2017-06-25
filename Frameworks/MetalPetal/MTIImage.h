//
//  MTIImage.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface MTIImage : NSObject

@property (nonatomic,readonly) CGRect extent;

@property (nonatomic,copy,readonly) MTLSamplerDescriptor *samplerDescriptor;

- (instancetype)imageWithSamplerDescriptor:(MTLSamplerDescriptor *)samplerDescriptor;

@end
