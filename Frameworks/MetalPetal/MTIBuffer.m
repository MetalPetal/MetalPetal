//
//  MTIBuffer.m
//  MetalPetal
//
//  Created by Yu Ao on 2019/1/22.
//

#import "MTIBuffer.h"
#import "MTILock.h"
#import "MTIDefer.h"
#import <mach/mach.h>

@interface MTIPageAlignedBuffer : NSObject

@property (nonatomic, readonly) void * contents;
@property (nonatomic, readonly) vm_size_t size;
@property (nonatomic, readonly) vm_address_t address;

@end

@implementation MTIPageAlignedBuffer

- (void)dealloc {
    if (_contents && (_size != 0)) {
        vm_deallocate(mach_task_self(), _address, _size);
    }
}

- (instancetype)initWithLength:(NSUInteger)length {
    if (self = [super init]) {
        _size = 0;
        _contents = NULL;
        vm_size_t pageSize = 0;
        kern_return_t pageSizeRequestResult = host_page_size(mach_host_self(), &pageSize);
        if (pageSizeRequestResult != 0) {
            return nil;
        }
        vm_address_t address;
        vm_size_t size = (length + (pageSize - 1))/pageSize * pageSize;
        kern_return_t result = vm_allocate(mach_task_self(), &address, size, VM_FLAGS_ANYWHERE);
        if (result != 0) {
            return nil;
        }
        _contents = (void *)address;
        _address = address;
        _size = size;
    }
    return self;
}

@end

@interface MTIDataBuffer ()

@property (nonatomic, strong) MTIPageAlignedBuffer *alignedBuffer;

@property (nonatomic, strong) NSMapTable<id<MTLDevice>, id<MTLBuffer>> *bufferCache;

@property (nonatomic, strong) id<MTILocking> bufferCacheLock;

@end

@implementation MTIDataBuffer

- (instancetype)initWithBytes:(const void *)bytes length:(NSUInteger)length options:(MTLResourceOptions)options {
    if (self = [self initWithLength:length options:options]) {
        memcpy(_alignedBuffer.contents, bytes, length);
    }
    return self;
}

- (instancetype)initWithLength:(NSUInteger)length options:(MTLResourceOptions)options {
    if (self = [super init]) {
        _alignedBuffer = [[MTIPageAlignedBuffer alloc] initWithLength:length];
        if (!_alignedBuffer) {
            return nil;
        }
        _length = length;
        _options = options;
        _bufferCache = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality | NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsObjectPointerPersonality | NSPointerFunctionsStrongMemory];
        _bufferCacheLock = MTILockCreate();
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data options:(MTLResourceOptions)options {
    return [self initWithBytes:data.bytes length:data.length options:options];
}

- (id<MTLBuffer>)bufferForDevice:(id<MTLDevice>)device {
    [_bufferCacheLock lock];
    @MTI_DEFER {
        [self -> _bufferCacheLock unlock];
    };
    
    id<MTLBuffer> buffer = [_bufferCache objectForKey:device];
    if (buffer) {
        return buffer;
    }
    
    id alignedBuffer = _alignedBuffer;
    buffer = [device newBufferWithBytesNoCopy:_alignedBuffer.contents length:_alignedBuffer.size options:_options deallocator:^(void * _Nonnull pointer, NSUInteger length) {
        [alignedBuffer self];
    }];
    
    if (buffer) {
        [_bufferCache setObject:buffer forKey:device];
    }
    return buffer;
}

- (void)unsafeAccess:(void (NS_NOESCAPE ^)(void * _Nonnull, NSUInteger))block {
    block(_alignedBuffer.contents, _length);
}

@end
