//
//  MTIImagePromiseDebug.h
//  MetalPetal
//
//  Created by Yu Ao on 23/11/2017.
//

#import <Foundation/Foundation.h>
#import "MTIImagePromise.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MTIImagePromiseType) {
    MTIImagePromiseTypeSource,
    MTIImagePromiseTypeProcessor
};

FOUNDATION_EXPORT NSString * MTIImagePromiseDebugIdentifierForObject(id object);

@interface MTIImagePromiseDebugInfo : NSObject

@property (nonatomic,copy,readonly) NSString *identifier;

@property (nonatomic,readonly) MTIImagePromiseType type;

@property (nonatomic,copy,readonly) NSString *title;

@property (nonatomic,strong,readonly,nullable) id content;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise
                           type:(MTIImagePromiseType)type
                        content:(id)content;

@end

@interface MTIImagePromiseDebugInfo (RenderGraph)

+ (CALayer *)layerRepresentationOfRenderGraphForPromise:(id<MTIImagePromise>)promise;

@end

NS_ASSUME_NONNULL_END
