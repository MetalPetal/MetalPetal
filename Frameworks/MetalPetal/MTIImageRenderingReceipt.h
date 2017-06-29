//
//  MTIImageRenderingReceipt.h
//  Pods
//
//  Created by YuAo on 29/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MTIImagePromise.h"

NS_ASSUME_NONNULL_BEGIN

@class MTIImage, MTIFilterFunctionDescriptor, MTITextureDescriptor;

@interface MTIImageRenderingReceiptBuilder : NSObject

@property (nonatomic,copy) NSArray<MTIImage *> *inputImages;

@property (nonatomic,copy) MTIFilterFunctionDescriptor *vertexFunctionDescriptor;

@property (nonatomic,copy) MTIFilterFunctionDescriptor *fragmentFunctionDescriptor;

@property (nonatomic,copy) NSArray *fragmentFunctionParameters;

@property (nonatomic,copy) MTLTextureDescriptor *textureDescriptor;

@end

@interface MTIImageRenderingReceipt : NSObject <MTIImagePromise>

@property (nonatomic,copy,readonly) NSArray<MTIImage *> *inputImages;

@property (nonatomic,copy,readonly) MTIFilterFunctionDescriptor *vertexFunctionDescriptor;

@property (nonatomic,copy,readonly) MTIFilterFunctionDescriptor *fragmentFunctionDescriptor;

@property (nonatomic,copy,readonly) NSArray *fragmentFunctionParameters;

@property (nonatomic,copy,readonly) MTITextureDescriptor *textureDescriptor;

- (instancetype)initWithBuilder:(MTIImageRenderingReceiptBuilder *)builder;

@end

NS_ASSUME_NONNULL_END
