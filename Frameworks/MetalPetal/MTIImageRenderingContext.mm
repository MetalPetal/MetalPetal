//
//  MTIImageRenderingContext.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIImageRenderingContext+Internal.h"
#import "MTIContext+Internal.h"
#import "MTIImage+Promise.h"
#import "MTIError.h"
#import "MTIPrint.h"
#import "MTIRenderGraphOptimization.h"
#import "MTIImagePromiseDebug.h"

#include <unordered_map>
#include <vector>
#include <memory>
#include <cstdint>

namespace MTIImageRendering {
    struct ObjcPointerIdentityEqual {
        bool operator()(const id s1, const id s2) const {
            return (s1 == s2);
        }
    };
    struct ObjcPointerHash {
        size_t operator()(const id pointer) const {
            auto addr = reinterpret_cast<uintptr_t>(pointer);
            #if SIZE_MAX < UINTPTR_MAX
            addr %= SIZE_MAX; /* truncate the address so it is small enough to fit in a size_t */
            #endif
            return addr;
        }
    };
};

class MTIImageRenderingDependencyGraph {
    
private:
    typedef std::vector<__unsafe_unretained id<MTIImagePromise>> UnsafeUnretainedImagePromises;
    std::unordered_map<__unsafe_unretained id<MTIImagePromise>, std::shared_ptr<UnsafeUnretainedImagePromises>, MTIImageRendering::ObjcPointerHash, MTIImageRendering::ObjcPointerIdentityEqual> _promiseDenpendentsCountTable;
    
public:
    
    void addDependenciesForImage(MTIImage *image) {
        auto dependencies = image.promise.dependencies;
        for (MTIImage *dependency in dependencies) {
            auto promise = dependency.promise;
            if (_promiseDenpendentsCountTable.count(promise) == 0) {
                //Using array here, because a promise may have two or more identical dependents.
                _promiseDenpendentsCountTable.insert(std::make_pair(promise, std::make_shared<UnsafeUnretainedImagePromises>(1, image.promise)));
                this -> addDependenciesForImage(dependency);
            } else {
                _promiseDenpendentsCountTable[promise] -> push_back(image.promise);
            }
        }
    }
    
    NSInteger dependentCountForPromise(id<MTIImagePromise> promise) const {
        NSCAssert(_promiseDenpendentsCountTable.count(promise) > 0, @"Promise: %@ is not in this dependency graph.", promise);
        return _promiseDenpendentsCountTable.at(promise) -> size();
    }
    
    void removeDependentForPromise(id<MTIImagePromise> dependent, id<MTIImagePromise> promise) {
        auto dependents = _promiseDenpendentsCountTable[promise];
        NSCAssert(dependents != nullptr, @"Dependents not found.");
        auto index = dependents -> end();
        for (auto i = dependents -> begin(); i != dependents -> end(); ++i) {
            if (*i == dependent) {
                index = i;
                break;
            }
        }
        NSCAssert(index != dependents -> end(), @"Dependent not found in promise's dependents array.");
        if (index != dependents -> end()) {
            dependents -> erase(index);
        }
    }
};

__attribute__((objc_subclassing_restricted))
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

__attribute__((objc_subclassing_restricted))
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

NSString * const MTIContextImagePersistentResolutionHolderTableName = @"MTIContextImagePersistentResolutionHolderTable";

MTIContextImageAssociatedValueTableName const MTIContextImagePersistentResolutionHolderTable = MTIContextImagePersistentResolutionHolderTableName;

@interface MTIImageRenderingContext () {
    std::unordered_map<__unsafe_unretained id<MTIImagePromise>, MTIImagePromiseRenderTarget __strong *, MTIImageRendering::ObjcPointerHash, MTIImageRendering::ObjcPointerIdentityEqual> _resolvedPromises;
    
    MTIImageRenderingDependencyGraph *_dependencyGraph;
    
    std::unordered_map<__unsafe_unretained MTIImage *, __unsafe_unretained id<MTLTexture>, MTIImageRendering::ObjcPointerHash, MTIImageRendering::ObjcPointerIdentityEqual> _currentDependencyResolutionMap;
    
    std::unordered_map<__unsafe_unretained MTIImage *, __unsafe_unretained id<MTLSamplerState>, MTIImageRendering::ObjcPointerHash, MTIImageRendering::ObjcPointerIdentityEqual> _currentDependencySamplerStateMap;
    
    __unsafe_unretained id<MTIImagePromise> _currentResolvingPromise;
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

- (id<MTLTexture>)resolvedTextureForImage:(MTIImage *)image {
    auto promise = _currentResolvingPromise;
    NSAssert(promise != nil, @"");
    auto result = _currentDependencyResolutionMap[image];
    if (!result || !promise) {
        [NSException raise:NSInternalInconsistencyException format:@"Do not query resolved texture for image which is not the current resolving promise's dependency. (Promise: %@, Image: %@)", promise, image];
    }
    return result;
}

- (id<MTLSamplerState>)resolvedSamplerStateForImage:(MTIImage *)image {
    auto promise = _currentResolvingPromise;
    NSAssert(promise != nil, @"");
    auto result = _currentDependencySamplerStateMap[image];
    if (!result || !promise) {
        [NSException raise:NSInternalInconsistencyException format:@"Do not query resolved sampler state for image which is not the current resolving promise's dependency. (Promise: %@, Image: %@)", promise, image];
    }
    return result;
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
        renderTarget = [self.context renderTargetForPromise:promise];
        if ([renderTarget retainTexture]) {
            //Got the render target from the context, we need to retain the texture here, texture ref-count +1. [A]
            //If we don't retain the texture, there will be an over-release error at location [C].
            //The cached render target is valid.
            NSAssert(renderTarget != nil, @"");
            NSAssert(renderTarget.texture != nil, @"");
        } else {
            //All caches miss. Resolve promise.
            NSError *error = nil;
            
            if (promise.dimensions.width > 0 && promise.dimensions.height > 0 && promise.dimensions.depth > 0) {
                
                NSUInteger dependencyCount = promise.dependencies.count;
                
                id<MTIImagePromiseResolution> inputResolutions[dependencyCount];
                memset(inputResolutions, 0, sizeof inputResolutions);
                
                id<MTLSamplerState> inputSamplerStates[dependencyCount];
                memset(inputSamplerStates, 0, sizeof inputSamplerStates);
                
                std::unordered_map<__unsafe_unretained MTIImage *, __unsafe_unretained id<MTLTexture>, MTIImageRendering::ObjcPointerHash, MTIImageRendering::ObjcPointerIdentityEqual> textureMap;
                
                std::unordered_map<__unsafe_unretained MTIImage *, __unsafe_unretained id<MTLSamplerState>, MTIImageRendering::ObjcPointerHash, MTIImageRendering::ObjcPointerIdentityEqual> samplerStateMap;
                
                for (NSUInteger index = 0; index < dependencyCount; index += 1) {
                    MTIImage *image = promise.dependencies[index];
                    id<MTIImagePromiseResolution> resolution = [self resolutionForImage:image error:&error];
                    if (error) {
                        break;
                    }
                    NSAssert(resolution != nil, @"");
                    inputResolutions[index] = resolution;
                    textureMap[image] = resolution.texture;
                    
                    id<MTLSamplerState> samplerState = [self.context samplerStateWithDescriptor:image.samplerDescriptor error:&error];
                    if (error) {
                        break;
                    }
                    NSAssert(samplerState != nil, @"");
                    inputSamplerStates[index] = samplerState;
                    samplerStateMap[image] = samplerState;
                }
                
                if (!error) {
                    _currentDependencyResolutionMap = textureMap;
                    _currentDependencySamplerStateMap = samplerStateMap;
                    
                    _currentResolvingPromise = promise;
                    
                    renderTarget = [promise resolveWithContext:self error:&error];
                    //New render target got from promise resolving, texture ref-count is 1. [B]
                    
                    _currentResolvingPromise = nil;
                }
                
                for (NSUInteger index = 0; index < dependencyCount; index += 1) {
                    [inputResolutions[index] markAsConsumedBy:promise];
                }
            } else {
                error = MTIErrorCreate(MTIErrorInvalidTextureDimension, nil);
            }
            
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
                [self.context setRenderTarget:renderTarget forPromise:promise];
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


__attribute__((objc_subclassing_restricted))
@interface MTIImageBufferPromise: NSObject <MTIImagePromise>

@property (nonatomic, strong, readonly) MTIPersistImageResolutionHolder *resolution;

@property (nonatomic, weak, readonly) MTIContext *context;

@end

@implementation MTIImageBufferPromise

@synthesize dimensions = _dimensions;
@synthesize alphaType = _alphaType;

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSArray<MTIImage *> *)dependencies {
    return @[];
}

- (instancetype)initWithPersistImageResolutionHolder:(MTIPersistImageResolutionHolder *)holder dimensions:(MTITextureDimensions)dimensions alphaType:(MTIAlphaType)alphaType context:(MTIContext *)context {
    if (self = [super init]) {
        _dimensions = dimensions;
        _alphaType = alphaType;
        _resolution = holder;
        _context = context;
    }
    return self;
}

- (MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * __autoreleasing *)error {
    MTIContext *context = self.context;
    NSParameterAssert(renderingContext.context == context);
    if (renderingContext.context != context) {
        if (error) {
            *error = MTIErrorCreate(MTIErrorCrossContextRendering, nil);
        }
        return nil;
    }
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


@implementation MTIContext (RenderedImageBuffer)

- (MTIImage *)renderedBufferForImage:(MTIImage *)targetImage {
    NSParameterAssert(targetImage.cachePolicy == MTIImageCachePolicyPersistent);
    MTIPersistImageResolutionHolder *persistResolution = [self valueForImage:targetImage inTable:MTIContextImagePersistentResolutionHolderTable];
    if (!persistResolution) {
        return nil;
    }
    return [[MTIImage alloc] initWithPromise:[[MTIImageBufferPromise alloc] initWithPersistImageResolutionHolder:persistResolution dimensions:targetImage.dimensions alphaType:targetImage.alphaType context:self] samplerDescriptor:targetImage.samplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

@end
