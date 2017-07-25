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

@interface MTITexturePool () {
    os_unfair_lock _lock;
}

@property (nonatomic, strong) id<MTLDevice> device;

@property (nonatomic, strong) NSMutableDictionary<MTITextureDescriptor *, NSMutableArray<id<MTLTexture>> *> *textureCache;

- (void)returnTexture:(MTIReusableTexture *)texture;

@end

@interface MTIReusableTexture () {
    os_unfair_lock _lock;
}

@property (nonatomic,copy) MTITextureDescriptor *textureDescriptor;

@property (nonatomic,weak) MTITexturePool *pool;

@property (nonatomic) NSInteger textureReferenceCount;

@end

@implementation MTIReusableTexture

- (instancetype)initWithTexture:(id<MTLTexture>)texture descriptor:(MTITextureDescriptor *)descriptor pool:(MTITexturePool *)pool {
    if (self = [super init]) {
        _lock = OS_UNFAIR_LOCK_INIT;
        _textureReferenceCount = 1;
        _pool = pool;
        _texture = texture;
        _textureDescriptor = [descriptor copy];
    }
    return self;
}

- (void)retainTexture {
    os_unfair_lock_lock(&_lock);
    
    NSAssert(_textureReferenceCount > 0, @"");
    _textureReferenceCount += 1;
    
    os_unfair_lock_unlock(&_lock);
    
}

- (void)releaseTexture {
    BOOL returnTexture = NO;
    
    os_unfair_lock_lock(&_lock);
    
    _textureReferenceCount -= 1;
    
    NSAssert(_textureReferenceCount >= 0, @"Over release a reusable texture.");
    
    if (_textureReferenceCount == 0) {
        returnTexture = YES;
    }
    
    os_unfair_lock_unlock(&_lock);
    
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
        _lock = OS_UNFAIR_LOCK_INIT;
        _device = device;
        _textureCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (MTIReusableTexture *)newTextureWithDescriptor:(MTITextureDescriptor *)textureDescriptor {
    os_unfair_lock_lock(&_lock);

    __auto_type avaliableTextures = self.textureCache[textureDescriptor];
    
    id<MTLTexture> texture = nil;
    
    if (avaliableTextures.count > 0) {
        texture = [avaliableTextures lastObject];
        [avaliableTextures removeLastObject];
    }
    
    os_unfair_lock_unlock(&_lock);
    
    if (!texture) {
        NSLog(@"%@: Created a new texture.",self);
        texture = [self.device newTextureWithDescriptor:[textureDescriptor newMTLTextureDescriptor]];
    }
    
    MTIReusableTexture *reusableTexture = [[MTIReusableTexture alloc] initWithTexture:texture descriptor:textureDescriptor pool:self];
    return reusableTexture;
}

- (void)returnTexture:(MTIReusableTexture *)texture {
    os_unfair_lock_lock(&_lock);
    
    __auto_type avaliableTextures = self.textureCache[texture.textureDescriptor];
    if (!avaliableTextures) {
        avaliableTextures = [[NSMutableArray alloc] init];
        self.textureCache[texture.textureDescriptor] = avaliableTextures;
    }
    [avaliableTextures addObject:texture.texture];
    
    os_unfair_lock_unlock(&_lock);
}

@end
