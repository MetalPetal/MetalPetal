//
//  MTIUnaryImageFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 10/10/2017.
//

#import "MTIUnaryImageFilter.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIFilterUtilities.h"

@implementation MTIUnaryImageFilter
@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)kernel {
    static NSMutableDictionary *kernels;
    static NSLock *kernelsLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernels = [NSMutableDictionary dictionary];
        kernelsLock = [[NSLock alloc] init];
    });
    
    NSString *fragmentFunctionName = [self fragmentFunctionName];
    
    [kernelsLock lock];
    MTIRenderPipelineKernel *kernel = kernels[fragmentFunctionName];
    if (!kernel) {
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:fragmentFunctionName]];
        kernels[fragmentFunctionName] = kernel;
    }
    [kernelsLock unlock];
    
    return kernel;
}

- (MTIImage *)outputImage {
    if (!_inputImage) {
        return nil;
    }
    return [self.class imageByProcessingImage:_inputImage withInputParameters:MTIFilterGetParametersDictionary(self) outputPixelFormat:_outputPixelFormat rotation:_inputRotation];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image withInputParameters:(NSDictionary<NSString *,id> *)parameters outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    return [self imageByProcessingImage:image withInputParameters:parameters outputPixelFormat:outputPixelFormat rotation:MTIImageOrientationUp];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image withInputParameters:(NSDictionary<NSString *,id> *)parameters outputPixelFormat:(MTLPixelFormat)outputPixelFormat rotation:(MTIImageOrientation)rotation {
    CGSize size = image.size;
    if ([MTIUnaryImageFilter shouldSwipeWidthAndHeightWhenRotatingToOrientation:rotation]) {
        size.width = image.size.height;
        size.height = image.size.width;
    }
    MTIRenderPipelineOutputDescriptor *outputDescriptor = [[MTIRenderPipelineOutputDescriptor alloc] initWithDimensions:MTITextureDimensionsMake2DFromCGSize(size) pixelFormat:outputPixelFormat];
    MTIVertices *geometry = [MTIUnaryImageFilter verticesForDrawingInRect:CGRectMake(-1, -1, 2, 2) rotation:rotation];
    return [[self kernel] imagesByDrawingGeometry:geometry
                                     withTextures:@[image]
                                       parameters:parameters
                                outputDescriptors:@[outputDescriptor]].firstObject;
}

+ (NSSet<NSString *> *)inputParameterKeys {
    return [NSSet set];
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
    } count:4];
}

@end

@implementation MTIUnaryImageFilter (SubclassingHooks)

+ (NSString *)fragmentFunctionName {
    return MTIFilterPassthroughFragmentFunctionName;
}

@end
