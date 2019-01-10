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

#include <map>
#include <vector>

class MTIImageRenderingDependencyGraph {

private:
    std::map<__unsafe_unretained id<MTIImagePromise>, std::vector<__unsafe_unretained id<MTIImagePromise>>> _promiseDenpendentsCountTable;
    
public:
    
    void addDependenciesForImage(MTIImage *image) {
        auto dependencies = image.promise.dependencies;
        for (MTIImage *dependency in dependencies) {
            auto promise = dependency.promise;
            if (_promiseDenpendentsCountTable.count(promise) == 0) {
                //Using array here, because a promise may have two or more identical dependents.
                _promiseDenpendentsCountTable[promise].push_back(image.promise);
                this -> addDependenciesForImage(dependency);
            } else {
                _promiseDenpendentsCountTable[promise].push_back(image.promise);
            }
        }
    }
    
    NSInteger dependentCountForPromise(id<MTIImagePromise> promise) const {
        NSCAssert(_promiseDenpendentsCountTable.count(promise) > 0, @"Promise: %@ is not in this dependency graph.", promise);
        return _promiseDenpendentsCountTable.at(promise).size();
    }
    
    void removeDependentForPromise(id<MTIImagePromise> dependent, id<MTIImagePromise> promise) {
        auto dependents = _promiseDenpendentsCountTable[promise];
        NSUInteger position = NSNotFound;
        for (NSUInteger index = 0; index < dependents.size(); index += 1) {
            if (dependents[index] == dependent) {
                position = index;
                break;
            }
        }
        NSCAssert(position != NSNotFound, @"");
        if (position != NSNotFound) {
            dependents.erase(dependents.begin() + position);
            _promiseDenpendentsCountTable[promise] = dependents;
        }
    }
};

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

NSString * const MTIContextPromiseRenderTargetTableName = @"MTIContextPromiseRenderTargetTable";

NSString * const MTIContextImagePersistentResolutionHolderTableName = @"MTIContextImagePersistentResolutionHolderTable";

MTIContextPromiseAssociatedValueTableName const MTIContextPromiseRenderTargetTable = MTIContextPromiseRenderTargetTableName;

MTIContextImageAssociatedValueTableName const MTIContextImagePersistentResolutionHolderTable = MTIContextImagePersistentResolutionHolderTableName;

@interface MTIImageRenderingContext () {
    std::map<__unsafe_unretained id<MTIImagePromise>, MTIImagePromiseRenderTarget __strong *> _resolvedPromises;
    MTIImageRenderingDependencyGraph *_dependencyGraph;
}

@end

@implementation MTIImageRenderingContext

- (void)dealloc {
    delete _dependencyGraph;
    
    if (self.commandBuffer.status == MTLCommandBufferStatusNotEnqueued || self.commandBuffer.status == MTLCommandBufferStatusEnqueued) {
        [self.commandBuffer commit];
    }
}

- (instancetype)initWithContext:(MTIContext *)context {
    if (self = [super init]) {
        _context = context;
        _commandBuffer = [context.commandQueue commandBuffer];
        _dependencyGraph = NULL;
    }
    return self;
}

- (id<MTIImagePromiseResolution>)resolutionForImage:(MTIImage *)image error:(NSError * __autoreleasing *)inOutError {
    if (image == nil) {
        [NSException raise:NSInvalidArgumentException format:@"%@: Application is requesting a resolution of a nil image.", self];
    }
 
    BOOL isRootImage = NO;
    id<MTIImagePromise> promise = image.promise;

    if (!_dependencyGraph) {
        //If we don't have the dependency graph, we're processing the root image.
        isRootImage = YES;
        
        _dependencyGraph = new MTIImageRenderingDependencyGraph();
        if (self.context.isRenderGraphOptimizationEnabled) {
            id<MTIImagePromise> optimizedPromise = [MTIRenderGraphOptimizer promiseByOptimizingRenderGraphOfPromise:promise];
            promise = optimizedPromise;
            
            MTIImage *optimizedImage = [[MTIImage alloc] initWithPromise:optimizedPromise samplerDescriptor:image.samplerDescriptor cachePolicy:image.cachePolicy];
            _dependencyGraph -> addDependenciesForImage(optimizedImage);
        } else {
            _dependencyGraph -> addDependenciesForImage(image);
        }
    }

    MTIImagePromiseRenderTarget *renderTarget = nil;
    if (_resolvedPromises.count(promise) > 0) {
        renderTarget = _resolvedPromises.at(promise);
        //Do not need to retain the render target, because it is created or retained during in this rendering context from location [A] or [B].
        //Promise resolved.
        NSAssert(renderTarget != nil, @"");
        NSAssert(renderTarget.texture != nil, @"");
    } else {
        //Maybe the context has a resolved promise. (The image has a persistent cache policy)
        renderTarget = [self.context valueForPromise:promise inTable:MTIContextPromiseRenderTargetTable];
        if ([renderTarget retainTexture]) {
            //Got the render target from the context, we need to retain the texture here, texture ref-count +1. [A]
            //If we don't retain the texture, there will be an over-release error at location [C].
            //The cached render target is valid.
            NSAssert(renderTarget != nil, @"");
            NSAssert(renderTarget.texture != nil, @"");
        } else {
            //All caches miss. Resolve promise.
            NSError *error;
            renderTarget = [promise resolveWithContext:self error:&error];
            //New render target got from promise resolving, texture ref-count is 1. [B]
            if (error) {
                if (inOutError) {
                    *inOutError = error;
                }
                
                //Failed. Release texture if we got the render target.
                [renderTarget releaseTexture];
                
                if (isRootImage) {
                    MTIPrint(@"An error occurred while resolving promise: %@ for image: %@.\n%@",promise,image,error);
                    //Clean up
                    for (auto entry : _resolvedPromises) {
                        if (_dependencyGraph -> dependentCountForPromise(entry.first) != 0) {
                            [entry.second releaseTexture];
                        }
                    }
                }
                
                return nil;
            }
            
            //Make sure the render target is valid.
            NSAssert(renderTarget != nil, @"");
            NSAssert(renderTarget.texture != nil, @"");
           
            if (image.cachePolicy == MTIImageCachePolicyPersistent) {
                //Share the render result with the context.
                [self.context setValue:renderTarget forPromise:promise inTable:MTIContextPromiseRenderTargetTable];
            }
        }
        _resolvedPromises[promise] = renderTarget;
    }
    
    if (image.cachePolicy == MTIImageCachePolicyPersistent) {
        MTIPersistImageResolutionHolder *persistResolution = [self.context valueForImage:image inTable:MTIContextImagePersistentResolutionHolderTable];
        if (!persistResolution) {
            //Create a holder for the render taget. Retain the texture. Preventing the texture from being reused at location [C]
            //When the MTIPersistImageResolutionHolder deallocates, it releases the texture.
            persistResolution = [[MTIPersistImageResolutionHolder alloc] initWithRenderTarget:renderTarget];
            [self.context setValue:persistResolution forImage:image inTable:MTIContextImagePersistentResolutionHolderTable];
        }
    }
    
    if (isRootImage) {
        return [[MTITransientImagePromiseResolution alloc] initWithTexture:renderTarget.texture invalidationHandler:^(id consumer) {
            //Root render result is consumed, releasing the texture.
            [renderTarget releaseTexture];
        }];
    } else {
        return [[MTITransientImagePromiseResolution alloc] initWithTexture:renderTarget.texture invalidationHandler:^(id consumer){
            self -> _dependencyGraph -> removeDependentForPromise(consumer, promise);
            if (self -> _dependencyGraph -> dependentCountForPromise(promise) == 0) {
                //Nothing depends on this render result, releasing the texture. [C]
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

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)error {
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

