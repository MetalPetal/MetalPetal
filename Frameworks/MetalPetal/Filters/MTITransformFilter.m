//
//  MTITransformFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 28/10/2017.
//

#import "MTITransformFilter.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTITransform.h"
#import "MTIRenderPassOutputDescriptor.h"

@implementation MTITransformFilter
@synthesize outputPixelFormat = _outputPixelFormat;
@synthesize inputImage = _inputImage;

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"imageTransformVertexShader"]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughFragmentFunctionName]
                                                                  vertexDescriptor:nil
                                                              colorAttachmentCount:1
                                                             alphaTypeHandlingRule:MTIAlphaTypeHandlingRule.passthroughAlphaTypeHandlingRule];
    });
    return kernel;
}

- (instancetype)init {
    if (self = [super init]) {
        _transform = CATransform3DIdentity;
        _fieldOfView = 0.0;
    }
    return self;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    
    if (CATransform3DIsIdentity(self.transform)) {
        return self.inputImage;
    }
    
    simd_float4x4 matrix;
    CGSize inputImageSize = CGSizeMake(self.inputImage.size.width, self.inputImage.size.height);
    CGFloat near = -self.inputImage.size.width*0.5/tan(self.fieldOfView/2.0);
    CGFloat far = near * 2.0;

    if (self.fieldOfView > 0.0) {
        CATransform3D transformToCameraCoordinates = CATransform3DMakeTranslation(0, 0, near);
        CATransform3D combinedTransform = CATransform3DConcat(self.transform, transformToCameraCoordinates);
        simd_float4x4 transformMatrix = MTIMakeTransformMatrixFromCATransform3D(combinedTransform);
        simd_float4x4 perspectiveMatrix = MTIMakePerspectiveMatrix(-inputImageSize.width*0.5, inputImageSize.width*0.5,
                                                                   -inputImageSize.height*0.5, inputImageSize.height*0.5,
                                                                   near, far);
        matrix = simd_mul(transformMatrix, perspectiveMatrix);
    }else {
        simd_float4x4 transformMatrix = MTIMakeTransformMatrixFromCATransform3D(self.transform);
        simd_float4x4 orthographicMatrix = MTIMakeOrthographicMatrix(-inputImageSize.width*0.5, inputImageSize.width*0.5,
                                                                     -inputImageSize.height*0.5, inputImageSize.height*0.5,
                                                                     near, far);
        matrix = simd_mul(transformMatrix, orthographicMatrix);
    }
    MTIRenderPassOutputDescriptor *outputDescriptor = [[MTIRenderPassOutputDescriptor alloc] initWithDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputImage.size) pixelFormat:MTIPixelFormatUnspecified loadAction:MTLLoadActionClear];
    
    MTIRenderCommand *command = [[MTIRenderCommand alloc] initWithKernel:MTITransformFilter.kernel geometry:[MTIVertices squareVerticesForRect:CGRectMake(-0.5*inputImageSize.width, -inputImageSize.height*0.5, inputImageSize.width, inputImageSize.height)] images:@[self.inputImage] parameters:@{@"transformMatrix": [NSData dataWithBytes:&matrix length:sizeof(matrix)]}];
    return [MTIRenderCommand imagesByPerformingRenderCommands:@[command]
                                            outputDescriptors:@[outputDescriptor]].firstObject;
}

@end
