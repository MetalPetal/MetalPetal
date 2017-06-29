//
//  MTIFilter.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIFilter.h"
#import "MTIVertex.h"
#import "MTIImageRenderingContext.h"
#import "MTIImage.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTIImageRenderingReceipt.h"

@interface MTIFilter ()

@property (nonatomic,copy) MTIFilterFunctionDescriptor *vertexFunctionDescriptor;

@property (nonatomic,copy) MTIFilterFunctionDescriptor *fragmentFunctionDescriptor;

@end

@implementation MTIFilter

- (instancetype)init {
   return [self initWithVertexFunctionDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:@"image_vertex"]
                      fragmentFunctionDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:@"image_fragment"]];
}

- (instancetype)initWithVertexFunctionDescriptor:(MTIFilterFunctionDescriptor *)vertexFunctionDescriptor fragmentFunctionDescriptor:(MTIFilterFunctionDescriptor *)fragmentFunctionDescriptor {
    if (self = [super init]) {
        _vertexFunctionDescriptor = vertexFunctionDescriptor.copy;
        _fragmentFunctionDescriptor = fragmentFunctionDescriptor.copy;
    }
    return self;
}

- (MTIImage *)outputImage {
    return nil;
}

- (MTIImage *)applyWithInputImages:(NSArray<MTIImage *> *)images
                        parameters:(NSArray *)parameters
           outputTextureDescriptor:(MTLTextureDescriptor *)outputTextureDescriptor {
    MTIImageRenderingReceiptBuilder *builder = [[MTIImageRenderingReceiptBuilder alloc] init];
    builder.inputImages = images;
    builder.vertexFunctionDescriptor = self.vertexFunctionDescriptor;
    builder.fragmentFunctionDescriptor = self.fragmentFunctionDescriptor;
    builder.fragmentFunctionParameters = parameters;
    builder.textureDescriptor = outputTextureDescriptor;
    return [[MTIImage alloc] initWithPromise:[[MTIImageRenderingReceipt alloc] initWithBuilder:builder]];
}

@end
