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
#import "MTIVector.h"

static simd_float4x4 transformMatrix(CGSize imageSize, CGRect viewport, float fieldOfView, CATransform3D transform) {
    simd_float4x4 matrix;
    if (fieldOfView > 0.0) {
        CGFloat near = -imageSize.width*0.5/tan(fieldOfView/2.0);
        CGFloat far = near * 2.0;
        CATransform3D transformToCameraCoordinates = CATransform3DMakeTranslation(0, 0, near);
        CATransform3D combinedTransform = CATransform3DConcat(transform, transformToCameraCoordinates);
        simd_float4x4 transformMatrix = MTIMakeTransformMatrixFromCATransform3D(combinedTransform);
        simd_float4x4 perspectiveMatrix = MTIMakePerspectiveMatrix(CGRectGetMinX(viewport), CGRectGetMaxX(viewport),
                                                                   CGRectGetMinY(viewport), CGRectGetMaxY(viewport),
                                                                   near, far);
        matrix = simd_mul(transformMatrix, perspectiveMatrix);
    } else {
        simd_float4x4 transformMatrix = MTIMakeTransformMatrixFromCATransform3D(transform);
        simd_float4x4 orthographicMatrix = MTIMakeOrthographicMatrix(CGRectGetMinX(viewport), CGRectGetMaxX(viewport),
                                                                     CGRectGetMinY(viewport), CGRectGetMaxY(viewport),
                                                                     0, 1);
        matrix = simd_mul(transformMatrix, orthographicMatrix);
    }
    return matrix;
}

@implementation MTITransformFilter
@synthesize outputPixelFormat = _outputPixelFormat;
@synthesize inputImage = _inputImage;

- (instancetype)init {
    if (self = [super init]) {
        _transform = CATransform3DIdentity;
        _fieldOfView = 0.0;
    }
    return self;
}

- (MTITransformFilterViewport)defaultViewport {
    if (!self.inputImage) {
        MTITransformFilterViewport viewport = {0};
        return viewport;
    }
    CGSize inputImageSize = self.inputImage.size;
    CGRect imageRect = CGRectMake(-0.5*inputImageSize.width, -inputImageSize.height*0.5, inputImageSize.width, inputImageSize.height);
    return imageRect;
}

- (MTITransformFilterViewport)minimumEnclosingViewport {
    if (!self.inputImage) {
        MTITransformFilterViewport viewport = {0};
        return viewport;
    }

    CGRect imageRect = self.defaultViewport;
    
    simd_float4 tl = simd_make_float4(CGRectGetMinX(imageRect), CGRectGetMinY(imageRect), 0, 1);
    simd_float4 tr = simd_make_float4(CGRectGetMaxX(imageRect), CGRectGetMinY(imageRect), 0, 1);
    simd_float4 bl = simd_make_float4(CGRectGetMinX(imageRect), CGRectGetMaxY(imageRect), 0, 1);
    simd_float4 br = simd_make_float4(CGRectGetMaxX(imageRect), CGRectGetMaxY(imageRect), 0, 1);
    simd_float4 points[4] = {tl, tr, bl, br};

    simd_float4x4 matrix = transformMatrix(self.inputImage.size, imageRect, self.fieldOfView, self.transform);

    for (NSUInteger i = 0; i < 4; i += 1) {
        points[i] = simd_mul(points[i], matrix);
        points[i] /= points[i].w;
        points[i] *= simd_make_float4(imageRect.size.width/2, imageRect.size.height/2, 0, 0);
    }
    
    float minX = FLT_MAX;
    float minY = FLT_MAX;
    float maxX = FLT_MIN;
    float maxY = FLT_MIN;
    for (NSUInteger i = 0; i < 4; i += 1) {
        minX = MIN(minX, points[i].x);
        minY = MIN(minY, points[i].y);
        maxX = MAX(maxX, points[i].x);
        maxY = MAX(maxY, points[i].y);
    }
    return CGRectMake(minX, minY, maxX-minX, maxY-minY);
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    
    CGSize inputImageSize = self.inputImage.size;
    CGRect imageRect = CGRectMake(-0.5*inputImageSize.width, -inputImageSize.height*0.5, inputImageSize.width, inputImageSize.height);
    
    MTITransformFilterViewport viewport = self.viewport;
    if (viewport.size.width * viewport.size.height == 0) {
        viewport = self.defaultViewport;
    }
    
    simd_float4 tl = simd_make_float4(CGRectGetMinX(imageRect), CGRectGetMinY(imageRect), 0, 1);
    simd_float4 tr = simd_make_float4(CGRectGetMaxX(imageRect), CGRectGetMinY(imageRect), 0, 1);
    simd_float4 bl = simd_make_float4(CGRectGetMinX(imageRect), CGRectGetMaxY(imageRect), 0, 1);
    simd_float4 br = simd_make_float4(CGRectGetMaxX(imageRect), CGRectGetMaxY(imageRect), 0, 1);
    
    simd_float4x4 matrix = transformMatrix(inputImageSize, viewport, self.fieldOfView, self.transform);
    
    tl = simd_mul(tl, matrix);
    tr = simd_mul(tr, matrix);
    bl = simd_mul(bl, matrix);
    br = simd_mul(br, matrix);
    
    MTIVertices *geomerty = [[MTIVertices alloc] initWithVertices:(MTIVertex []){
        { .position = {tl.x, tl.y, 0, tl.w} , .textureCoordinate = { 0, 1 } },
        { .position = {tr.x, tr.y, 0, tr.w} , .textureCoordinate = { 1, 1 } },
        { .position = {bl.x, bl.y, 0, bl.w} , .textureCoordinate = { 0, 0 } },
        { .position = {br.x, br.y, 0, br.w} , .textureCoordinate = { 1, 0 } }
    } count:4 primitiveType:MTLPrimitiveTypeTriangleStrip];
    
    MTIRenderPassOutputDescriptor *outputDescriptor = [[MTIRenderPassOutputDescriptor alloc] initWithDimensions:MTITextureDimensionsMake2DFromCGSize(viewport.size) pixelFormat:MTIPixelFormatUnspecified loadAction:MTLLoadActionClear];
    MTIRenderCommand *command = [[MTIRenderCommand alloc] initWithKernel:MTIRenderPipelineKernel.passthroughRenderPipelineKernel geometry:geomerty images:@[self.inputImage] parameters:@{}];
    return [MTIRenderCommand imagesByPerformingRenderCommands:@[command]
                                            outputDescriptors:@[outputDescriptor]].firstObject;
}

@end
