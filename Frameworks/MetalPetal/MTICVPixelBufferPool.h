//
//  MTICVPixelBufferPool.h
//  MetalPetal
//
//  Created by Yu Ao on 2018/12/7.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MTICVPixelBufferPoolErrorDomain;

typedef NS_ERROR_ENUM(MTICVPixelBufferPoolErrorDomain, MTICVPixelBufferPoolError) {
    MTICVPixelBufferPoolErrorNone = kCVReturnSuccess,
    MTICVPixelBufferPoolErrorWouldExceedAllocationThreshold = kCVReturnWouldExceedAllocationThreshold,
    MTICVPixelBufferPoolErrorPoolAllocationFailed = kCVReturnPoolAllocationFailed,
    MTICVPixelBufferPoolErrorInvalidPoolAttributes = kCVReturnInvalidPoolAttributes,
    MTICVPixelBufferPoolErrorRetry = kCVReturnRetry
};

@interface MTICVPixelBufferPool : NSObject

@property (nonatomic, readonly) size_t pixelBufferWidth;
@property (nonatomic, readonly) size_t pixelBufferHeight;

@property (nonatomic, readonly) NSUInteger minimumBufferCount;

@property (nonatomic, readonly) OSType pixelFormatType;

@property (nonatomic, copy, readonly) NSString *pixelFormatDescription;

@property (nonatomic, copy, readonly) NSDictionary *poolAttributes;
@property (nonatomic, copy, readonly) NSDictionary *pixelBufferAttributes;

@property (nonatomic, readonly) CVPixelBufferPoolRef internalPool NS_RETURNS_INNER_POINTER;

- (instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initWithPixelBufferWidth:(size_t)width pixelBufferHeight:(size_t)height pixelFormatType:(OSType)pixelFormatType minimumBufferCount:(NSUInteger)minimumBufferCount error:(NSError **)error;

- (nullable instancetype)initWithPoolAttributes:(NSDictionary *)poolAttributes pixelBufferAttributes:(NSDictionary *)pixelBufferAttributes error:(NSError **)error;

- (instancetype)initWithCVPixelBufferPool:(CVPixelBufferPoolRef)pixelBufferPool NS_DESIGNATED_INITIALIZER;

- (nullable CVPixelBufferRef)newPixelBufferWithAllocationThreshold:(NSUInteger)allocationThreshold error:(NSError **)error CF_RETURNS_RETAINED NS_SWIFT_NAME(makePixelBuffer(allocationThreshold:));

- (void)flush:(CVPixelBufferPoolFlushFlags)flags;

@end

NS_ASSUME_NONNULL_END

