//
//  MTICVPixelBufferPool.m
//  MetalPetal
//
//  Created by Yu Ao on 2018/12/7.
//

#import "MTICVPixelBufferPool.h"

NSString * const MTICVPixelBufferPoolErrorDomain = @"MTICVPixelBufferPoolErrorDomain";

static void MTICVPixelBufferPoolIsOutOfBuffer(MTICVPixelBufferPool *pool) {
    NSLog(@"%@: Pool is out of buffers. Create a symbolic breakpoint of MTICVPixelBufferPoolIsOutOfBuffer to debug.",pool);
}

static NSString * MTICVPixelBufferPoolFourCharCodeToString(FourCharCode code) {
    char bytes[5] = {
        (code >> 24) & 0xff,
        (code >> 16) & 0xff,
        (code >> 8) & 0xff,
        code & 0xff,
        0
    };
    NSString *string = [NSString stringWithCString:bytes encoding:NSASCIIStringEncoding];
    return [string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
}

@interface MTICVPixelBufferPool ()

@property (nonatomic,readonly) CVPixelBufferPoolRef pool;

@end

@implementation MTICVPixelBufferPool

- (void)dealloc {
    CVPixelBufferPoolRelease(_pool);
}

- (CVPixelBufferPoolRef)internalPool {
    return _pool;
}

- (instancetype)initWithCVPixelBufferPool:(CVPixelBufferPoolRef)pixelBufferPool {
    if (self = [super init]) {
        _pool = CVPixelBufferPoolRetain(pixelBufferPool);
        _poolAttributes = (__bridge NSDictionary *)CVPixelBufferPoolGetAttributes(pixelBufferPool);
        _pixelBufferAttributes = (__bridge NSDictionary *)CVPixelBufferPoolGetPixelBufferAttributes(pixelBufferPool);
        _pixelBufferWidth = [_pixelBufferAttributes[(id)kCVPixelBufferWidthKey] integerValue];
        _pixelBufferHeight = [_pixelBufferAttributes[(id)kCVPixelBufferHeightKey] integerValue];
        _minimumBufferCount = [_poolAttributes[(id)kCVPixelBufferPoolMinimumBufferCountKey] integerValue];
        _pixelFormatType = [_pixelBufferAttributes[(id)kCVPixelBufferPixelFormatTypeKey] unsignedIntValue];
        _pixelFormatDescription = MTICVPixelBufferPoolFourCharCodeToString(_pixelFormatType);
    }
    return self;
}

- (instancetype)initWithPoolAttributes:(NSDictionary *)poolAttributes pixelBufferAttributes:(NSDictionary *)pixelBufferAttributes error:(NSError * __autoreleasing *)error {
    CVPixelBufferPoolRef pool = NULL;
    CVReturn result = CVPixelBufferPoolCreate(kCFAllocatorDefault, (__bridge CFDictionaryRef _Nullable)(poolAttributes), (__bridge CFDictionaryRef _Nullable)(pixelBufferAttributes), &pool);
    if (result != kCVReturnSuccess || !pool) {
        if (error) {
            *error = [NSError errorWithDomain:MTICVPixelBufferPoolErrorDomain code:result userInfo:@{}];
        }
        return nil;
    }
    id instance = [self initWithCVPixelBufferPool:pool];
    CVPixelBufferPoolRelease(pool);
    return instance;
}

- (instancetype)initWithPixelBufferWidth:(size_t)width pixelBufferHeight:(size_t)height pixelFormatType:(OSType)pixelFormatType minimumBufferCount:(NSUInteger)minimumBufferCount error:(NSError * __autoreleasing *)error {
    return [self initWithPoolAttributes:@{(id)kCVPixelBufferPoolMinimumBufferCountKey: @(minimumBufferCount)}
                  pixelBufferAttributes:@{(id)kCVPixelBufferPixelFormatTypeKey : @(pixelFormatType),
                                          (id)kCVPixelBufferWidthKey : @(width),
                                          (id)kCVPixelBufferHeightKey : @(height),
                                          (id)kCVPixelBufferIOSurfacePropertiesKey : @{ /*empty dictionary*/ }}
                                  error:error];
}

- (CVPixelBufferRef)newPixelBufferWithAllocationThreshold:(NSUInteger)allocationThreshold error:(NSError * __autoreleasing *)error {
    if (allocationThreshold == 0) {
        allocationThreshold = _minimumBufferCount;
    }
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, self.pool, (__bridge CFDictionaryRef)(@{(id)kCVPixelBufferPoolAllocationThresholdKey:@(allocationThreshold)}),&pixelBuffer);
    if (err != kCVReturnSuccess) {
        if (error) {
            *error = [NSError errorWithDomain:MTICVPixelBufferPoolErrorDomain code:err userInfo:@{}];
        }
        if (err == kCVReturnWouldExceedAllocationThreshold) {
            MTICVPixelBufferPoolIsOutOfBuffer(self);
        }
    }
    return pixelBuffer;
}

- (void)flush:(CVPixelBufferPoolFlushFlags)flags {
    CVPixelBufferPoolFlush(_pool, flags);
}

@end
