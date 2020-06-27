//
//  MTIRenderGraphMerge.h
//  MetalPetal
//
//  Created by Yu Ao on 20/11/2017.
//

#import <MTIImagePromise.h>

NS_ASSUME_NONNULL_BEGIN

@class MTIImage;

__attribute__((objc_subclassing_restricted))
@interface MTIRenderGraphNode: NSObject

@property (nonatomic, strong, nullable) NSMutableArray<MTIRenderGraphNode *> *inputs;

@property (nonatomic, strong, nullable) MTIImage *image;

@property (nonatomic, readonly) NSInteger uniqueDependentCount;

@end

__attribute__((objc_subclassing_restricted))
@interface MTIRenderGraphOptimizer : NSObject

+ (id<MTIImagePromise>)promiseByOptimizingRenderGraphOfPromise:(id<MTIImagePromise>)promise;

@end

NS_ASSUME_NONNULL_END
