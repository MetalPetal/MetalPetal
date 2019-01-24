//
//  MTIBuffer.h
//  MetalPetal
//
//  Created by Yu Ao on 2019/1/22.
//

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

/// A GPU mutable data buffer. You can pass a `MTIDataBuffer` instance to multiple processing units, they can all read and write the buffer's content. However, accessing a `MTIDataBuffer`'s contents using CPU is not safe. You must ensure all the GPU reads/writes to this buffer is completed. e.g. call a render task's waitUntilCompleted. For one `MTIDataBuffer` instance, one and only one underlaying `MTLBuffer` will be created for one GPU device.
@interface MTIDataBuffer : NSObject

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initWithBytes:(const void *)bytes
                                length:(NSUInteger)length
                               options:(MTLResourceOptions)options;

- (nullable instancetype)initWithData:(NSData *)data options:(MTLResourceOptions)options;

- (nullable instancetype)initWithLength:(NSUInteger)length options:(MTLResourceOptions)options NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) NSUInteger length;

@property (nonatomic, readonly) MTLResourceOptions options;

- (nullable id<MTLBuffer>)bufferForDevice:(id<MTLDevice>)device NS_SWIFT_NAME(buffer(for:));

/// Accessing contents from CPU is unsafe.
- (void)unsafeAccess:(void (NS_NOESCAPE ^)(void *contents, NSUInteger length))block;

@end

NS_ASSUME_NONNULL_END
