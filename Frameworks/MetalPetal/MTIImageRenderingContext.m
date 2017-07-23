//
//  MTIImageRenderingContext.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIImageRenderingContext.h"
#import "MTIContext.h"
#import "MTIImage.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTIVertex.h"
#import "MTIRenderPipeline.h"
#import "MTIFilter.h"
#import "MTIDrawableRendering.h"
#import "MTIImage+Promise.h"
#import "MTITexturePool.h"
#import "MTITextureDescriptor.h"
#import "MTIWeakToStrongObjectsMapTable.h"
@import AVFoundation;

@interface MTIImageRenderingDependencyGraph : NSObject

@property (nonatomic,weak,readonly) MTIImageRenderingContext *renderingContext;

@property (nonatomic,strong) NSMapTable<id<MTIImagePromise>,NSHashTable<id<MTIImagePromise>> *> *promiseDenpendentsTable;

@end

@implementation MTIImageRenderingDependencyGraph

- (instancetype)initWithContext:(MTIImageRenderingContext *)renderingContext {
    if (self = [super init]) {
        _renderingContext = renderingContext;
        _promiseDenpendentsTable = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory|NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory];
    }
    return self;
}

- (void)dealloc {
#warning not implemented
    //for promise in resolvedPromise table
    //if promise.refCount > 1
    //renderTarget releaseTexture
}

- (void)addDependenciesForImage:(MTIImage *)image {
    __auto_type dependencies = image.promise.dependencies;
    for (MTIImage *dependency in dependencies) {
        NSHashTable *dependents = [self.promiseDenpendentsTable objectForKey:dependency.promise];
        if (!dependents) {
            dependents = [NSHashTable hashTableWithOptions:NSMapTableStrongMemory|NSMapTableObjectPointerPersonality];
        }
        [dependents addObject:image.promise];
        [self addDependenciesForImage:dependency];
    }
}

- (NSInteger)dependentCountForPromise:(id<MTIImagePromise>)promise {
    return [self.promiseDenpendentsTable objectForKey:promise].count;
}

- (void)removeDependent:(id<MTIImagePromise>)dependent forPromise:(id<MTIImagePromise>)promise {
    NSHashTable *dependents = [self.promiseDenpendentsTable objectForKey:promise];
    NSAssert(dependents, @"");
    NSAssert([dependents containsObject:dependent], @"");
    [dependents removeObject:dependent];
}

@end

@interface MTITransientImagePromiseResolution: NSObject <MTIImagePromiseResolution>

@property (nonatomic,copy) void (^invalidationHandler)(id);

@end

@implementation MTITransientImagePromiseResolution

@synthesize texture = _texture;

- (instancetype)initWithTexture:(id<MTLTexture>)texture invalidationHandler:(void (^)(id))invalidationHandler {
    if (self = [super init]) {
        _invalidationHandler = [invalidationHandler copy];
        _texture = texture;
    }
    return self;
}

- (void)markAsConsumedBy:(id)consumer {
    self.invalidationHandler(consumer);
    self.invalidationHandler = nil;
}

- (void)dealloc {
    NSAssert(self.invalidationHandler == nil, @"");
}

@end

NSString * const MTIContextPromiseRenderTargetTable = @"MTIContextPromiseRenderTargetTable";
NSString * const MTIContextImagePersistentResolutionTable = @"MTIContextImagePersistentResolutionTable";

@interface MTIImageRenderingContext ()

@property (nonatomic,strong) MTIImageRenderingDependencyGraph *dependencyGraph;

@property (nonatomic,strong) NSHashTable<id<MTIImagePromise>> *resolvedPromises;

@end

@implementation MTIImageRenderingContext

- (instancetype)initWithContext:(MTIContext *)context {
    if (self = [super init]) {
        _context = context;
        _commandBuffer = [context.commandQueue commandBuffer];
        _resolvedPromises = [NSHashTable hashTableWithOptions:NSHashTableWeakMemory|NSHashTableObjectPointerPersonality];
    }
    return self;
}

- (id<MTIImagePromiseResolution>)resolutionForImage:(MTIImage *)image error:(NSError * _Nullable __autoreleasing *)inOutError {
    if (!self.dependencyGraph) {
        //create dependency graph
        MTIImageRenderingDependencyGraph *dependencyGraph = [[MTIImageRenderingDependencyGraph alloc] initWithContext:self];
        [dependencyGraph addDependenciesForImage:image];
        self.dependencyGraph = dependencyGraph;
    }
    
    MTIImageRenderingDependencyGraph *dependencyGraph = self.dependencyGraph;
    id<MTIImagePromise> promise = image.promise;
    
    MTIImagePromiseRenderTarget *renderTarget = nil;
    if ([self.resolvedPromises containsObject:promise]) {
        //resolved
        renderTarget = [self.context valueForPromise:promise inTable:MTIContextPromiseRenderTargetTable];
        NSAssert(renderTarget != nil, @"");
        NSAssert(renderTarget.texture != nil, @"");
    } else {
        renderTarget = [self.context valueForPromise:promise inTable:MTIContextPromiseRenderTargetTable];
        if (renderTarget.texture) {
            [renderTarget retainTexture];
        } else {
            NSError *error;
            renderTarget = [promise resolveWithContext:self error:&error];
            if (error) {
                if (inOutError) {
                    *inOutError = error;
                }
                return nil;
            }
            NSAssert(renderTarget != nil, @"");
            NSAssert(renderTarget.texture != nil, @"");
            [self.context setValue:renderTarget forPromise:promise inTable:MTIContextPromiseRenderTargetTable];
        }
        [self.resolvedPromises addObject:promise];
    }
    
    BOOL isGraphOutput = NO;
    NSInteger dependentCount = [self.dependencyGraph dependentCountForPromise:promise];
    if (dependentCount == 0) {
        //final output
        isGraphOutput = YES;
    }
   
    switch (image.cachePolicy) {
        case MTIImageCachePolicyPersistent: {
            #warning not implemented
            return nil;
        } break;
        case MTIImageCachePolicyTransient: {
            if (isGraphOutput) {
                return [[MTITransientImagePromiseResolution alloc] initWithTexture:renderTarget.texture invalidationHandler:^(id consumer) {
                    [renderTarget releaseTexture];
                }];
            } else {
                return [[MTITransientImagePromiseResolution alloc] initWithTexture:renderTarget.texture invalidationHandler:^(id consumer){
                    [dependencyGraph removeDependent:consumer forPromise:promise];
                    if ([dependencyGraph dependentCountForPromise:promise] == 0) {
                        [renderTarget releaseTexture];
                    }
                }];
            }
        } break;
        default: {
            if (inOutError) {
                *inOutError = [NSError errorWithDomain:MTIContextErrorDomain code:MTIContextErrorUnsupportedImageCachePolicy userInfo:@{}];
            }
            return nil;
        } break;
    }
}

@end

