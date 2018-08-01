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
#import "MTIImage+Promise.h"
#import "MTIError.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIMultilayerCompositeKernel.h"
#import "MTIPrint.h"
#import "MTIRenderGraphOptimization.h"
#import "MTIImagePromiseDebug.h"
#import "MTIContext+Internal.h"

@interface MTIImageRenderingDependencyGraph ()

@property (nonatomic,strong) NSMapTable<id<MTIImagePromise>,NSMutableArray<id<MTIImagePromise>> *> *promiseDenpendentsTable;

@end

@implementation MTIImageRenderingDependencyGraph

- (instancetype)init {
    if (self = [super init]) {
        _promiseDenpendentsTable = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory|NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory];
    }
    return self;
}

- (void)addDependenciesForImage:(MTIImage *)image {
    __auto_type dependencies = image.promise.dependencies;
    for (MTIImage *dependency in dependencies) {
        __auto_type dependents = [self.promiseDenpendentsTable objectForKey:dependency.promise];
        if (!dependents) {
            dependents = [NSMutableArray arrayWithObject:image.promise];
            [self.promiseDenpendentsTable setObject:dependents forKey:dependency.promise];
            
            [self addDependenciesForImage:dependency];
        } else {
            [dependents addObject:image.promise];
        }
    }
}

- (NSInteger)dependentCountForPromise:(id<MTIImagePromise>)promise {
    return [self.promiseDenpendentsTable objectForKey:promise].count;
}

- (void)removeDependent:(id<MTIImagePromise>)dependent forPromise:(id<MTIImagePromise>)promise {
    __auto_type dependents = [self.promiseDenpendentsTable objectForKey:promise];
    NSAssert(dependents, @"");
    NSAssert([dependents containsObject:dependent], @"");
    NSUInteger index = [dependents indexOfObject:dependent];
    [dependents removeObjectAtIndex:index];
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

@interface MTIPersistImageResolutionHolder : NSObject

@property (nonatomic,strong) MTIImagePromiseRenderTarget *renderTarget;

@end

@implementation MTIPersistImageResolutionHolder

- (instancetype)initWithRenderTarget:(MTIImagePromiseRenderTarget *)renderTarget {
    if (self = [super init]) {
        _renderTarget = renderTarget;
        [renderTarget retainTexture];
    }
    return self;
}

- (void)dealloc {
    [_renderTarget releaseTexture];
}

@end


MTIContextPromiseAssociatedValueTableName const MTIContextPromiseRenderTargetTable = @"MTIContextPromiseRenderTargetTable";
MTIContextImageAssociatedValueTableName const MTIContextImagePersistentResolutionHolderTable = @"MTIContextImagePersistentResolutionHolderTable";

@interface MTIImageRenderingContext ()

@property (nonatomic,strong) MTIImageRenderingDependencyGraph *dependencyGraph;

@property (nonatomic,strong) NSHashTable<id<MTIImagePromise>> *resolvedPromises;

@end

@implementation MTIImageRenderingContext

- (void)dealloc {
    if (self.commandBuffer.status == MTLCommandBufferStatusNotEnqueued || self.commandBuffer.status == MTLCommandBufferStatusEnqueued) {
        [self.commandBuffer commit];
    }
}

- (instancetype)initWithContext:(MTIContext *)context {
    if (self = [super init]) {
        _context = context;
        _commandBuffer = [context.commandQueue commandBuffer];
        _resolvedPromises = [NSHashTable hashTableWithOptions:NSHashTableWeakMemory|NSHashTableObjectPointerPersonality];
    }
    return self;
}

- (id<MTIImagePromiseResolution>)resolutionForImage:(MTIImage *)image error:(NSError * _Nullable __autoreleasing *)inOutError {
    if (image == nil) {
        [NSException raise:NSInvalidArgumentException format:@"%@: Application is requesting a resolution of a nil image.", self];
    }
 
    BOOL isRootImage = NO;
    id<MTIImagePromise> promise = image.promise;

    if (!self.dependencyGraph) {
        //If we don't have the dependency graph, we're processing the root image.
        isRootImage = YES;
        
        if (self.context.isRenderGraphOptimizationEnabled) {
            id<MTIImagePromise> optimizedPromise = [MTIRenderGraphOptimizer promiseByOptimizingRenderGraphOfPromise:promise];
            promise = optimizedPromise;
            
            MTIImageRenderingDependencyGraph *dependencyGraph = [[MTIImageRenderingDependencyGraph alloc] init];
            MTIImage *optimizedImage = [[MTIImage alloc] initWithPromise:optimizedPromise samplerDescriptor:image.samplerDescriptor cachePolicy:image.cachePolicy];
            [dependencyGraph addDependenciesForImage:optimizedImage];
            self.dependencyGraph = dependencyGraph;
        } else {
            MTIImageRenderingDependencyGraph *dependencyGraph = [[MTIImageRenderingDependencyGraph alloc] init];
            [dependencyGraph addDependenciesForImage:image];
            self.dependencyGraph = dependencyGraph;
        }
    }
    
    MTIImageRenderingDependencyGraph *dependencyGraph = self.dependencyGraph;

    MTIImagePromiseRenderTarget *renderTarget = nil;
    if ([self.resolvedPromises containsObject:promise]) {
        //resolved
        renderTarget = [self.context valueForPromise:promise inTable:MTIContextPromiseRenderTargetTable];
        NSAssert(renderTarget != nil, @"");
        NSAssert(renderTarget.texture != nil, @"");
    } else {
        renderTarget = [self.context valueForPromise:promise inTable:MTIContextPromiseRenderTargetTable];
        BOOL renderTargetIsValid = NO;
        if ([renderTarget retainTexture]) {
            NSAssert(renderTarget != nil, @"");
            NSAssert(renderTarget.texture != nil, @"");
            renderTargetIsValid = YES;
        }
        if (!renderTargetIsValid) {
            //Resolve promise
            NSError *error;
            renderTarget = [promise resolveWithContext:self error:&error];
            if (error) {
                if (inOutError) {
                    *inOutError = error;
                }
                [renderTarget releaseTexture];
                
                if (isRootImage) {
                    MTIPrint(@"An error occurred while resolving promise: %@ for image: %@.\n%@",promise,image,error);
                    //Clean up
                    for (id<MTIImagePromise> promise in self.resolvedPromises) {
                        if ([self.dependencyGraph dependentCountForPromise:promise] != 0) {
                            MTIImagePromiseRenderTarget *target = [self.context valueForPromise:promise inTable:MTIContextPromiseRenderTargetTable];
                            [target releaseTexture];
                        }
                    }
                }
                
                return nil;
            }
            NSAssert(renderTarget != nil, @"");
            NSAssert(renderTarget.texture != nil, @"");
            [self.context setValue:renderTarget forPromise:promise inTable:MTIContextPromiseRenderTargetTable];
        }
        [self.resolvedPromises addObject:promise];
    }
    
    if (image.cachePolicy == MTIImageCachePolicyPersistent) {
        MTIPersistImageResolutionHolder *persistResolution = [self.context valueForImage:image inTable:MTIContextImagePersistentResolutionHolderTable];
        if (!persistResolution) {
            persistResolution = [[MTIPersistImageResolutionHolder alloc] initWithRenderTarget:renderTarget];
            [self.context setValue:persistResolution forImage:image inTable:MTIContextImagePersistentResolutionHolderTable];
        } else {
            [persistResolution.renderTarget retainTexture];
        }
    }
    
    if (isRootImage) {
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
}

@end

@interface MTIImageBuffer () <MTIImagePromise>

@property (nonatomic, strong, readonly) MTIPersistImageResolutionHolder *resolution;

@property (nonatomic, weak, readonly) MTIContext *context;

@end

@implementation MTIImageBuffer
@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

+ (MTIImage *)renderedBufferForImage:(MTIImage *)targetImage inContext:(MTIContext *)context {
    MTIPersistImageResolutionHolder *persistResolution = [context valueForImage:targetImage inTable:MTIContextImagePersistentResolutionHolderTable];
    if (!persistResolution) {
        return nil;
    }
    return [[MTIImage alloc] initWithPromise:[[MTIImageBuffer alloc] initWithPersistImageResolutionHolder:persistResolution alphaType:targetImage.alphaType context:context] samplerDescriptor:targetImage.samplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSArray<MTIImage *> *)dependencies {
    return @[];
}

- (instancetype)initWithPersistImageResolutionHolder:(MTIPersistImageResolutionHolder *)holder alphaType:(MTIAlphaType)alphaType context:(MTIContext *)context {
    if (self = [super init]) {
        _dimensions = (MTITextureDimensions){holder.renderTarget.texture.width,holder.renderTarget.texture.height,holder.renderTarget.texture.depth};
        _alphaType = alphaType;
        _resolution = holder;
        _context = context;
    }
    return self;
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)error {
    NSParameterAssert(renderingContext.context == self.context);
    [_resolution.renderTarget retainTexture];
    return _resolution.renderTarget;
}


- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies {
    NSParameterAssert(dependencies.count == 0);
    return self;
}

- (MTIImagePromiseDebugInfo *)debugInfo {
    return [[MTIImagePromiseDebugInfo alloc] initWithPromise:self type:MTIImagePromiseTypeSource content:self.resolution];
}

@end

