//
//  MTITexturePool.m
//  Pods
//
//  Created by YuAo on 01/07/2017.
//
//

#import "MTITexturePool.h"
#import "MTITextureDescriptor.h"
#import "MTIPrint.h"
#import "MTILock.h"
#import "MTIError.h"

#include <vector>

@interface MTIStack<__covariant ObjectType> : NSObject <NSFastEnumeration> {
    std::vector<__strong id> *_items;
}

@property (readonly) NSUInteger count;

- (ObjectType)popObject;

- (void)pushObject:(ObjectType)anObject;

@end

@implementation MTIStack

- (instancetype)init {
    if (self = [super init]) {
        _items = new std::vector<__strong id>();
    }
    return self;
}

- (void)dealloc {
    delete _items;
}

- (NSUInteger)count {
    return _items -> size();
}

- (id)popObject {
    id item = _items -> back();
    _items -> pop_back();
    return item;
}

- (void)pushObject:(id)anObject {
    _items -> push_back(anObject);
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id  _Nullable __unsafe_unretained [])buffer count:(NSUInteger)len {
    if(state -> state == 0) {
        state -> mutationsPtr = (unsigned long *)_items;
        void *items = (void *)_items -> data();
        state -> itemsPtr = (id __unsafe_unretained *)items;
        state -> state = 1;
        return _items -> size();
    } else {
        return 0;
    }
}

@end


@protocol MTITexturePoolInternal <MTITexturePool>

- (void)returnTexture:(id<MTLTexture>)texture textureDescriptor:(MTITextureDescriptor *)textureDescriptor;

@end


@interface MTIReusableTexture ()

@property (nonatomic, strong) id<NSLocking> lock;

@property (nonatomic, copy) MTITextureDescriptor *textureDescriptor;

@property (nonatomic, weak) id<MTITexturePoolInternal> pool;

@property (nonatomic) NSInteger textureReferenceCount;

@property (nonatomic) BOOL valid;

@property (nonatomic, strong) id heap;

@end

@implementation MTIReusableTexture

@synthesize texture = _texture;

- (instancetype)initWithTexture:(id<MTLTexture>)texture descriptor:(MTITextureDescriptor *)descriptor pool:(id<MTITexturePoolInternal>)pool {
    if (self = [super init]) {
        _lock = MTILockCreate();
        _textureReferenceCount = 1;
        _pool = pool;
        _texture = texture;
        _textureDescriptor = [descriptor copy];
        _valid = YES;
        _heap = texture.heap;
    }
    return self;
}

- (id<MTLTexture>)texture {
    [_lock lock];
    __auto_type texture = _texture;
    [_lock unlock];
    return texture;
}

- (BOOL)retainTexture {
    [_lock lock];
    
    if (_valid) {
        if (_textureReferenceCount <= 0) {
            [NSException raise:NSInternalInconsistencyException format:@"Retain a reusable texture after the _textureReferenceCount is less than 1."];
        }
        _textureReferenceCount += 1;
        
        [_lock unlock];
        
        return YES;
    } else {
        
        [_lock unlock];
        
        return NO;
    }
}

- (void)releaseTexture {
    id<MTLTexture> textureToReturn = nil;
    
    [_lock lock];
    
    _textureReferenceCount -= 1;
    
    NSAssert(_textureReferenceCount >= 0, @"Over release a reusable texture.");
    
    if (_textureReferenceCount == 0) {
        textureToReturn = _texture;
        _texture = nil;
        _valid = NO;
    }
    
    [_lock unlock];
    
    if (textureToReturn) {
        [_pool returnTexture:textureToReturn textureDescriptor:_textureDescriptor];
        _heap = nil;
    }
}

- (void)dealloc {
    if (_texture) {
        [_pool returnTexture:_texture textureDescriptor:_textureDescriptor];
    }
}

@end


@interface MTIDeviceTexturePool () <MTITexturePoolInternal>

@property (nonatomic, strong) id<NSLocking> lock;

@property (nonatomic, strong) id<MTLDevice> device;

@property (nonatomic, strong) NSMutableDictionary<MTITextureDescriptor *, MTIStack<id<MTLTexture>> *> *textureCache;

@end

@implementation MTIDeviceTexturePool

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        _lock = MTILockCreate();
        _device = device;
        _textureCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (MTIReusableTexture *)newTextureWithDescriptor:(MTITextureDescriptor *)textureDescriptor error:(NSError * __autoreleasing *)error {
    [_lock lock];

    __auto_type availableTextures = _textureCache[textureDescriptor];
    
    id<MTLTexture> texture = nil;
    
    if (availableTextures.count > 0) {
        texture = [availableTextures popObject];
    }
    
    [_lock unlock];
    
    if (!texture) {
        texture = [textureDescriptor newTextureWithDevice:_device];
        if (!texture) {
            if (error) {
                *error = MTIErrorCreate(MTIErrorFailedToCreateTexture, nil);
            }
            return nil;
        }
        MTIPrint(@"%@: new texture - %@x%@x%@/%@", self, @(textureDescriptor.width), @(textureDescriptor.height), @(textureDescriptor.depth),@(textureDescriptor.pixelFormat));
    }
    
    MTIReusableTexture *reusableTexture = [[MTIReusableTexture alloc] initWithTexture:texture descriptor:textureDescriptor pool:self];
    return reusableTexture;
}

- (void)returnTexture:(id<MTLTexture>)texture textureDescriptor:(MTITextureDescriptor *)textureDescriptor {
    [_lock lock];
    
    __auto_type availableTextures = _textureCache[textureDescriptor];
    if (!availableTextures) {
        availableTextures = [[MTIStack alloc] init];
        _textureCache[textureDescriptor] = availableTextures;
    }
    [availableTextures pushObject:texture];
    
    [_lock unlock];
}

- (void)flush {
    [_lock lock];
    [_textureCache removeAllObjects];
    [_lock unlock];
    MTIPrint(@"%@: flush", self);
}

- (NSUInteger)idleResourceSize {
    [_lock lock];
    NSUInteger __block size = 0;
    [_textureCache enumerateKeysAndObjectsUsingBlock:^(MTITextureDescriptor * _Nonnull key, MTIStack<id<MTLTexture>> * _Nonnull obj, BOOL * _Nonnull stop) {
        for (id<MTLTexture> texture in obj) {
            size += texture.allocatedSize;
        }
    }];
    [_lock unlock];
    return size;
}

- (NSUInteger)idleResourceCount {
    [_lock lock];
    NSUInteger __block count = 0;
    [_textureCache enumerateKeysAndObjectsUsingBlock:^(MTITextureDescriptor * _Nonnull key, MTIStack<id<MTLTexture>> * _Nonnull obj, BOOL * _Nonnull stop) {
        count += obj.count;
    }];
    [_lock unlock];
    return count;
}

+ (instancetype)newTexturePoolWithDevice:(id<MTLDevice>)device {
    return [[self alloc] initWithDevice:device];
}

@end


#import "MTIHasher.h"

NS_AVAILABLE(10_15, 13_0)
@interface MTIHeapTextureReuseKey : NSObject <NSCopying>

@property (nonatomic, readonly) NSUInteger size;
@property (nonatomic, readonly) MTLResourceOptions resourceOptions;

@end

@implementation MTIHeapTextureReuseKey

- (instancetype)initWithSize:(NSUInteger)size resourceOptions:(MTLResourceOptions)resourceOptions {
    if (self = [super init]) {
        _size = size;
        _resourceOptions = resourceOptions;
    }
    return self;
}

- (NSUInteger)hash {
    MTIHasher hasher = MTIHasherMake(0);
    MTIHasherCombine(&hasher, _size);
    MTIHasherCombine(&hasher, _resourceOptions);
    return MTIHasherFinalize(&hasher);
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[MTIHeapTextureReuseKey class]]) {
        return _size == ((MTIHeapTextureReuseKey *)object).size && _resourceOptions == ((MTIHeapTextureReuseKey *)object).resourceOptions;
    }
    return NO;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end

@interface MTIHeapTexturePool () <MTITexturePoolInternal>

@property (nonatomic, strong) id<NSLocking> lock;

@property (nonatomic, strong) id<MTLDevice> device;

@property (nonatomic, strong) NSMutableDictionary<MTIHeapTextureReuseKey *, MTIStack<id<MTLHeap>> *> *heaps;

@end

@implementation MTIHeapTexturePool

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        NSAssert([MTIHeapTexturePool isSupportedOnDevice:device], @"MTIHeapTexturePool is not supported on device: %@. See +[MTIHeapTexturePool isSupportedOnDevice:] for detail.", device);
        _lock = MTILockCreate();
        _device = device;
        _heaps = [NSMutableDictionary dictionary];
    }
    return self;
}

- (MTIReusableTexture *)newTextureWithDescriptor:(MTITextureDescriptor *)textureDescriptor error:(NSError * __autoreleasing *)error {
    [_lock lock];
    
    NSUInteger size = [textureDescriptor heapTextureSizeAndAlignWithDevice:_device].size;
    MTIHeapTextureReuseKey *key = [[MTIHeapTextureReuseKey alloc] initWithSize:size resourceOptions:textureDescriptor.resourceOptions];
    __auto_type availableHeaps = _heaps[key];
    
    id<MTLHeap> heap = nil;
    
    if (availableHeaps.count > 0) {
        heap = [availableHeaps popObject];
    }
    
    [_lock unlock];
    
    if (!heap) {
        MTLHeapDescriptor *heapDescriptor = [[MTLHeapDescriptor alloc] init];
        heapDescriptor.size = key.size;
        heapDescriptor.resourceOptions = key.resourceOptions;
        if (textureDescriptor.hazardTrackingMode == MTLHazardTrackingModeDefault) {
            heapDescriptor.hazardTrackingMode = MTLHazardTrackingModeTracked;
        }
        heap = [_device newHeapWithDescriptor:heapDescriptor];
        if (!heap) {
            if (error) {
                *error = MTIErrorCreate(MTIErrorFailedToCreateHeap, nil);
            }
            return nil;
        }
        MTIPrint(@"%@: new texture - %@x%@x%@/%@", self, @(textureDescriptor.width), @(textureDescriptor.height), @(textureDescriptor.depth),@(textureDescriptor.pixelFormat));
    }
    
    id<MTLTexture> texture = [textureDescriptor newTextureWithHeap:heap];
    if (!texture) {
        if (error) {
            *error = MTIErrorCreate(MTIErrorFailedToCreateTexture, nil);
        }
        return nil;
    }
    
    MTIReusableTexture *reusableTexture = [[MTIReusableTexture alloc] initWithTexture:texture descriptor:textureDescriptor pool:self];
    return reusableTexture;
}

- (void)returnTexture:(id<MTLTexture>)texture textureDescriptor:(MTITextureDescriptor *)textureDescriptor {
    [_lock lock];
    
    NSParameterAssert(texture.heap != nil);
    
    NSUInteger size = [textureDescriptor heapTextureSizeAndAlignWithDevice:_device].size;
    MTIHeapTextureReuseKey *key = [[MTIHeapTextureReuseKey alloc] initWithSize:size resourceOptions:textureDescriptor.resourceOptions];
    __auto_type availableHeaps = _heaps[key];
    if (!availableHeaps) {
        availableHeaps = [[MTIStack alloc] init];
        _heaps[key] = availableHeaps;
    }
    [texture makeAliasable];
    [availableHeaps pushObject:texture.heap];
    
    [_lock unlock];
}

- (void)flush {
    [_lock lock];
    [_heaps removeAllObjects];
    [_lock unlock];
    MTIPrint(@"%@: flush", self);
}

- (NSUInteger)idleResourceSize {
    [_lock lock];
    NSUInteger __block size = 0;
    [_heaps enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, MTIStack<id<MTLHeap>> * _Nonnull obj, BOOL * _Nonnull stop) {
        for (id<MTLHeap> heap in obj) {
            size += heap.currentAllocatedSize;
        }
    }];
    [_lock unlock];
    return size;
}

- (NSUInteger)idleResourceCount {
    [_lock lock];
    NSUInteger __block count = 0;
    [_heaps enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, MTIStack<id<MTLHeap>> * _Nonnull obj, BOOL * _Nonnull stop) {
        count += obj.count;
    }];
    [_lock unlock];
    return count;
}

+ (instancetype)newTexturePoolWithDevice:(id<MTLDevice>)device {
    return [[self alloc] initWithDevice:device];
}

+ (BOOL)isSupportedOnDevice:(id<MTLDevice>)device {
    // https://forums.developer.apple.com/thread/113223
    // This is unfortunately a hardware limitation on pre-A12 devices. Texture resolutions must be padded out to powers of two internally. Non-heap allocations can use virtual memory tricks to minimize this cost but heaps cannot.
    if ([device supportsFamily:MTLGPUFamilyApple5] || [device supportsFamily:MTLGPUFamilyMac1] || [device supportsFamily:MTLGPUFamilyMacCatalyst1]) {
        return YES;
    }
    return NO;
}

@end
