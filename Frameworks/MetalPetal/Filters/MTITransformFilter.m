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

@implementation MTITransformFilter
@synthesize outputPixelFormat = _outputPixelFormat;

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

- (MTIVertices *)verticesForRect:(CGRect)rect {
    CGFloat l = CGRectGetMinX(rect);
    CGFloat r = CGRectGetMaxX(rect);
    CGFloat t = CGRectGetMinY(rect);
    CGFloat b = CGRectGetMaxY(rect);
    
    return [[MTIVertices alloc] initWithVertices:(MTIVertex []){
        { .position = {l, t, 0, 1} , .textureCoordinate = { 0, 1 } },
        { .position = {r, t, 0, 1} , .textureCoordinate = { 1, 1 } },
        { .position = {l, b, 0, 1} , .textureCoordinate = { 0, 0 } },
        { .position = {r, b, 0, 1} , .textureCoordinate = { 1, 0 } }
    } count:4];
}

- (instancetype)init {
    if (self = [super init]) {
        _transform = CATransform3DIdentity;
        _fov = 0.0;
    }
    return self;
}

- (simd_float4)vector:(simd_float4)position matrix:(simd_float4x4)m {
    return position.xxxx * m.columns[0] + position.yyyy * m.columns[1] + position.zzzz * m.columns[2] + position.wwww * m.columns[3];
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
    CGFloat near = -self.inputImage.size.width*0.5/tan(self.fov/2.0);
    CGFloat far = near * 2.0;

    if (self.fov > 0.0) {
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
    MTIRenderPipelineOutputDescriptor *outputDescriptor = [[MTIRenderPipelineOutputDescriptor alloc] initWithDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputImage.size) pixelFormat:MTIPixelFormatUnspecified loadAction:MTLLoadActionClear];
    return [[MTITransformFilter kernel] imagesByDrawingGeometry:[self verticesForRect:CGRectMake(-0.5*inputImageSize.width, -inputImageSize.height*0.5, inputImageSize.width, inputImageSize.height)]
                                                   withTextures:@[self.inputImage]
                                                     parameters:@{@"transformMatrix": [NSData dataWithBytes:&matrix length:sizeof(matrix)]}
                                              outputDescriptors:@[outputDescriptor]].firstObject;
}

+ (nonnull NSSet<NSString *> *)inputParameterKeys {
    return [NSSet set];
}

@end
