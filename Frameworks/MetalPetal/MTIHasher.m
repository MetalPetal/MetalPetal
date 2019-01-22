//
//  MTIHasher.m
//  MetalPetal
//
//  Created by Yu Ao on 2019/1/7.
//

#import "MTIHasher.h"

static_assert(sizeof(uint64_t) == sizeof(double), "");

static_assert(sizeof(NSUInteger) == 8, "MTIHasher is designed to work on 64-bit systems");
