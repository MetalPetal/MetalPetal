//
//  MTIImagePromise.h
//  Pods
//
//  Created by YuAo on 27/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MTIImageRenderingContext.h"
#import "MTIImage.h"
#import "MTIFilterFunctionDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MTIImagePromise <NSObject, NSCopying>

@property (nonatomic,copy,readonly) MTLTextureDescriptor *outputTextureDescriptor;

- (nullable id<MTLTexture>)resolveWithContext:(MTIImageRenderingContext *)context error:(NSError **)error;

@end

@interface MTIImageRenderingReceiptBuilder : NSObject

@property (nonatomic,copy) NSArray<MTIImage *> *inputImages;

@property (nonatomic,copy) MTIFilterFunctionDescriptor *vertexFunctionDescriptor;

@property (nonatomic,copy) MTIFilterFunctionDescriptor *fragmentFunctionDescriptor;

@property (nonatomic,copy) NSArray *fragmentFunctionParameters;

@property (nonatomic,copy) MTLTextureDescriptor *outputTextureDescriptor;

@end

@interface MTIImageRenderingReceipt : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) NSArray<MTIImage *> *inputImages;

@property (nonatomic,copy,readonly) MTIFilterFunctionDescriptor *vertexFunctionDescriptor;

@property (nonatomic,copy,readonly) MTIFilterFunctionDescriptor *fragmentFunctionDescriptor;

@property (nonatomic,copy,readonly) NSArray *fragmentFunctionParameters;

@property (nonatomic,copy,readonly) MTLTextureDescriptor *outputTextureDescriptor;

- (instancetype)initWithBuilder:(MTIImageRenderingReceiptBuilder *)builder;

@end

NS_ASSUME_NONNULL_END

