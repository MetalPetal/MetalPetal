//
//  MTITexturePool.m
//  Pods
//
//  Created by YuAo on 01/07/2017.
//
//

#import "MTITexturePool.h"
#import "MTITextureDescriptor.h"

@interface MTITexturePool ()

@property (nonatomic, strong) id<MTLDevice> device;

@property (nonatomic, strong) NSMutableDictionary<MTLTextureDescriptor *, NSMutableArray<id<MTLTexture>> *> *textureCache;

- (void)returnTexture:(MTIReusableTexture *)texture;

@end

@interface MTIReusableTexture ()

@property (nonatomic,copy) MTLTextureDescriptor *textureDescriptor;

@property (nonatomic,weak) MTITexturePool *pool;

@property (nonatomic) NSInteger textureReferenceCount;

@end

@implementation MTIReusableTexture

- (instancetype)initWithTexture:(id<MTLTexture>)texture descriptor:(MTLTextureDescriptor *)descriptor pool:(MTITexturePool *)pool {
    if (self = [super init]) {
        _textureReferenceCount = 1;
        _pool = pool;
        _texture = texture;
        _textureDescriptor = [descriptor copy];
    }
    return self;
}

- (void)retainTexture {
    @synchronized (self) {
        _textureReferenceCount += 1;
    }
}

- (void)releaseTexture {
    @synchronized (self) {
        _textureReferenceCount -= 1;
        NSAssert(_textureReferenceCount >= 0, @"Over release a reusable texture.");
        if (_textureReferenceCount == 0) {
            [self.pool returnTexture:self];
            _texture = nil;
        }
    }
}

@end


@implementation MTITexturePool

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        _device = device;
        _textureCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (MTIReusableTexture *)newTextureWithDescriptor:(MTLTextureDescriptor *)textureDescriptor {
    @synchronized (self) {
        __auto_type avaliableTextures = self.textureCache[textureDescriptor];
        if (avaliableTextures.count > 0) {
            id<MTLTexture> texture = [avaliableTextures lastObject];
            [avaliableTextures removeLastObject];
            MTIReusableTexture *reusableTexture = [[MTIReusableTexture alloc] initWithTexture:texture descriptor:textureDescriptor pool:self];
            return reusableTexture;
        } else {
            NSLog(@"[New Texture]");
            id<MTLTexture> texture = [self.device newTextureWithDescriptor:textureDescriptor];
            MTIReusableTexture *reusableTexture = [[MTIReusableTexture alloc] initWithTexture:texture descriptor:textureDescriptor pool:self];
            return reusableTexture;
        }
    }
}

- (void)returnTexture:(MTIReusableTexture *)texture {
    @synchronized (self) {
        __auto_type avaliableTextures = self.textureCache[texture.textureDescriptor];
        if (!avaliableTextures) {
            avaliableTextures = [[NSMutableArray alloc] init];
            self.textureCache[texture.textureDescriptor] = avaliableTextures;
        }
        [avaliableTextures addObject:texture.texture];
    }
}

@end

#import <objc/runtime.h>

@interface MTIImagePromiseDeallocationHandler : NSObject

@property (nonatomic,copy) void(^action)(void);

@end

@implementation MTIImagePromiseDeallocationHandler

- (instancetype)initWithAction:(void(^)(void))action {
    if (self = [super init]) {
        _action = [action copy];
    }
    return self;
}

- (void)attachToPromise:(id<MTIImagePromise>)promise {
    objc_setAssociatedObject(promise, (__bridge const void *)(self), self, OBJC_ASSOCIATION_RETAIN);
}

- (void)dealloc {
    self.action();
}

@end

@implementation MTITexturePool (MTIImagePromiseRenderTarget)

- (id<MTLTexture>)newRenderTargetForPromise:(id<MTIImagePromise>)promise {
    MTIReusableTexture *reusableTexture = [self newTextureWithDescriptor:[promise.textureDescriptor newMTLTextureDescriptor]];
    [[[MTIImagePromiseDeallocationHandler alloc] initWithAction:^{
        [reusableTexture releaseTexture];
    }] attachToPromise:promise];
    return reusableTexture.texture;
}

@end
