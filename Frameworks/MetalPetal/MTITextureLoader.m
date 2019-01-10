//
//  MTITextureLoader.m
//  MetalPetal
//
//  Created by Yu Ao on 2019/1/10.
//

#import "MTITextureLoader.h"

@implementation MTKTextureLoader (MTITextureLoader)

+ (instancetype)newTextureLoaderWithDevice:(id<MTLDevice>)device {
    return [[MTKTextureLoader alloc] initWithDevice:device];
}

@end
