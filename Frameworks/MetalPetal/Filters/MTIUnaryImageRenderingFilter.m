//
//  MTIUnaryImageFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 10/10/2017.
//

#import "MTIUnaryImageRenderingFilter.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIFilterUtilities.h"
#import "MTIRenderPipelineOutputDescriptor.h"

@implementation MTIUnaryImageRenderingFilter
@synthesize outputPixelFormat = _outputPixelFormat;
@synthesize inputImage = _inputImage;

+ (MTIRenderPipelineKernel *)kernel {
    static NSMutableDictionary *kernels;
    static NSLock *kernelsLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernels = [NSMutableDictionary dictionary];
        kernelsLock = [[NSLock alloc] init];
    });
    
    MTIFunctionDescriptor *fragmentFunctionDescriptor = [self fragmentFunctionDescriptor];

    [kernelsLock lock];
    MTIRenderPipelineKernel *kernel = kernels[fragmentFunctionDescriptor];
    if (!kernel) {
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:fragmentFunctionDescriptor
                                                                  vertexDescriptor:nil
                                                              colorAttachmentCount:1
                                                             alphaTypeHandlingRule:[self alphaTypeHandlingRule]];
        kernels[fragmentFunctionDescriptor] = kernel;
    }
    [kernelsLock unlock];
    
    return kernel;
}

- (MTIImage *)outputImage {
    if (!_inputImage) {
        return nil;
    }
    return [self.class imageByProcessingImage:_inputImage rotation:_inputRotation parameters:self.parameters outputPixelFormat:_outputPixelFormat];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image withInputParameters:(NSDictionary<NSString *,id> *)parameters outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    return [self imageByProcessingImage:image rotation:MTIImageOrientationUp parameters:parameters outputPixelFormat:outputPixelFormat];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image rotation:(MTIImageOrientation)rotation parameters:(NSDictionary<NSString *,id> *)parameters outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    CGSize size = image.size;
    if ([MTIUnaryImageRenderingFilter shouldSwipeWidthAndHeightWhenRotatingToOrientation:rotation]) {
        size.width = image.size.height;
        size.height = image.size.width;
    }
    MTIRenderPipelineOutputDescriptor *outputDescriptor = [[MTIRenderPipelineOutputDescriptor alloc] initWithDimensions:MTITextureDimensionsMake2DFromCGSize(size) pixelFormat:outputPixelFormat];
    MTIVertices *geometry = [MTIUnaryImageRenderingFilter verticesForDrawingInRect:CGRectMake(-1, -1, 2, 2) rotation:rotation];
    MTIRenderCommand *command = [[MTIRenderCommand alloc] initWithKernel:self.kernel geometry:geometry images:@[image] parameters:parameters];
    return [MTIRenderCommand imagesByPerformingRenderCommands:@[command]
                                            outputDescriptors:@[outputDescriptor]].firstObject;
}

+ (BOOL)shouldSwipeWidthAndHeightWhenRotatingToOrientation:(MTIImageOrientation)orientation {
    if (orientation == MTIImageOrientationLeft || orientation == MTIImageOrientationRightMirrored || orientation == MTIImageOrientationRight || orientation == MTIImageOrientationLeftMirrored) {
        return YES;
    } else {
        return NO;
    }
}

+ (MTIVertices *)verticesForDrawingInRect:(CGRect)rect rotation:(MTIImageOrientation)orientation {
    simd_float2 *textureCoordinates = NULL;
    switch (orientation) {
        case MTIImageOrientationUnknown:
        case MTIImageOrientationUp:
            textureCoordinates = (simd_float2[]){
                {0, 1},
                {1, 1},
                {0, 0},
                {1, 0}
            };
            break;
        case MTIImageOrientationUpMirrored:
            textureCoordinates = (simd_float2[]){
                {1, 1},
                {0, 1},
                {1, 0},
                {0, 0}
            };
            break;
        case MTIImageOrientationDown:
            textureCoordinates = (simd_float2[]){
                {1, 0},
                {0, 0},
                {1, 1},
                {0, 1}
            };
            break;
        case MTIImageOrientationLeft:
            textureCoordinates = (simd_float2[]){
                {1, 1},
                {1, 0},
                {0, 1},
                {0, 0}
            };
            break;
        case MTIImageOrientationRight:
            textureCoordinates = (simd_float2[]){
                {0, 0},
                {0, 1},
                {1, 0},
                {1, 1}
            };
            break;
        case MTIImageOrientationDownMirrored:
            textureCoordinates = (simd_float2[]){
                {0, 0},
                {1, 0},
                {0, 1},
                {1, 1}
            };
            break;
        case MTIImageOrientationLeftMirrored:
            textureCoordinates = (simd_float2[]){
                {0, 1},
                {0, 0},
                {1, 1},
                {1, 0}
            };
            break;
        case MTIImageOrientationRightMirrored:
            textureCoordinates = (simd_float2[]){
                {1, 0},
                {1, 1},
                {0, 0},
                {0, 1}
            };
            break;
    }
    CGFloat l = CGRectGetMinX(rect);
    CGFloat r = CGRectGetMaxX(rect);
    CGFloat t = CGRectGetMinY(rect);
    CGFloat b = CGRectGetMaxY(rect);
    return [[MTIVertices alloc] initWithVertices:(MTIVertex []){
        { .position = {l, t, 0, 1} , .textureCoordinate = textureCoordinates[0] },
        { .position = {r, t, 0, 1} , .textureCoordinate = textureCoordinates[1] },
        { .position = {l, b, 0, 1} , .textureCoordinate = textureCoordinates[2] },
        { .position = {r, b, 0, 1} , .textureCoordinate = textureCoordinates[3] }
    } count:4 primitiveType:MTLPrimitiveTypeTriangleStrip];
}

@end

@implementation MTIUnaryImageRenderingFilter (SubclassingHooks)

- (NSDictionary<NSString *,id> *)parameters {
    return @{};
}

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughFragmentFunctionName libraryURL:nil];
}

+ (MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule {
    return MTIAlphaTypeHandlingRule.generalAlphaTypeHandlingRule;
}

@end
