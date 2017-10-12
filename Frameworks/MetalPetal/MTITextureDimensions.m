//
//  MTITextureDimensions.m
//  Pods
//
//  Created by Yu Ao on 11/10/2017.
//

#import "MTITextureDimensions.h"

MTITextureDimensions MTITextureDimensionsMake2DFromCGSize(CGSize size) {
    return (MTITextureDimensions){.width = size.width, .height = size.height, .depth = 1};
}

BOOL MTITextureDimensionsEqualToTextureDimensions(MTITextureDimensions a, MTITextureDimensions b) {
    return a.width == b.width && a.height == b.height && a.depth == b.depth;
}
