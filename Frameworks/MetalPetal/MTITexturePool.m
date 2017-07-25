//
//  MTITexturePool.m
//  Pods
//
//  Created by YuAo on 01/07/2017.
//
//

#import "MTITexturePool.h"
#import "MTITextureDescriptor.h"
#import <os/lock.h>
#import <pthread/pthread.h>

//https://gist.github.com/steipete/36350a8a60693d440954b95ea6cbbafc

@interface MTILock : NSObject {
    os_unfair_lock _unfairlock;
    pthread_mutex_t _mutex;
}

@end

@implementation MTILock

- (instancetype)init {
    if (self = [super init]) {
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_9_x_Max) {
            _unfairlock = OS_UNFAIR_LOCK_INIT;
        } else {
            pthread_mutex_init(&_mutex, nil);
        }
    }
    return self;
}

- (void)dealloc {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_9_x_Max) {
        
    } else {
        pthread_mutex_destroy(&_mutex);
    }
}

- (void)lock {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_9_x_Max) {
        os_unfair_lock_lock(&_unfairlock);
    } else {
        pthread_mutex_lock(&_mutex);
    }
}

- (void)unlock {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_9_x_Max) {
        os_unfair_lock_unlock(&_unfairlock);
    } else {
        pthread_mutex_unlock(&_mutex);
    }
}

@end

@interface MTITexturePool ()

@property (nonatomic, strong) MTILock *lock;

@property (nonatomic, strong) id<MTLDevice> device;

@property (nonatomic, strong) NSMutableDictionary<MTITextureDescriptor *, NSMutableArray<id<MTLTexture>> *> *textureCache;

- (void)returnTexture:(MTIReusableTexture *)texture;

@end

@interface MTIReusableTexture ()

@property (nonatomic, strong) MTILock *lock;

@property (nonatomic, copy) MTITextureDescriptor *textureDescriptor;

@property (nonatomic, weak) MTITexturePool *pool;

@property (nonatomic) NSInteger textureReferenceCount;

@end

@implementation MTIReusableTexture

- (instancetype)initWithTexture:(id<MTLTexture>)texture descriptor:(MTITextureDescriptor *)descriptor pool:(MTITexturePool *)pool {
    if (self = [super init]) {
        _lock = [[MTILock alloc] init];
        _textureReferenceCount = 1;
        _pool = pool;
        _texture = texture;
        _textureDescriptor = [descriptor copy];
    }
    return self;
}

- (void)retainTexture {
    [_lock lock];
    
    NSAssert(_textureReferenceCount > 0, @"");
    _textureReferenceCount += 1;
    
    [_lock unlock];
}

- (void)releaseTexture {
    BOOL returnTexture = NO;
    
    [_lock lock];
    
    _textureReferenceCount -= 1;
    
    NSAssert(_textureReferenceCount >= 0, @"Over release a reusable texture.");
    
    if (_textureReferenceCount == 0) {
        returnTexture = YES;
    }
    
    [_lock unlock];
    
    if (returnTexture) {
        [self.pool returnTexture:self];
        _texture = nil;
    }
}

- (void)dealloc {
    if (_texture) {
        [_pool returnTexture:self];
    }
}

@end

@implementation MTITexturePool

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        _lock = [[MTILock alloc] init];
        _device = device;
        _textureCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (MTIReusableTexture *)newTextureWithDescriptor:(MTITextureDescriptor *)textureDescriptor {
    [_lock lock];

    __auto_type avaliableTextures = self.textureCache[textureDescriptor];
    
    id<MTLTexture> texture = nil;
    
    if (avaliableTextures.count > 0) {
        texture = [avaliableTextures lastObject];
        [avaliableTextures removeLastObject];
    }
    
    [_lock unlock];
    
    if (!texture) {
        NSLog(@"%@: Created a new texture.",self);
        texture = [self.device newTextureWithDescriptor:[textureDescriptor newMTLTextureDescriptor]];
    }
    
    MTIReusableTexture *reusableTexture = [[MTIReusableTexture alloc] initWithTexture:texture descriptor:textureDescriptor pool:self];
    return reusableTexture;
}

- (void)returnTexture:(MTIReusableTexture *)texture {
    [_lock lock];
    
    __auto_type avaliableTextures = self.textureCache[texture.textureDescriptor];
    if (!avaliableTextures) {
        avaliableTextures = [[NSMutableArray alloc] init];
        self.textureCache[texture.textureDescriptor] = avaliableTextures;
    }
    [avaliableTextures addObject:texture.texture];
    
    [_lock unlock];
}

@end
