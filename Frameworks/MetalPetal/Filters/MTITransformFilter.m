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
    
    simd_float4x4 transformMatrix = MTIMakeTransformMatrixFromCATransform3D(self.transform);
    simd_float4x4 orthographicMatrix = MTIMakeOrthographicMatrix(-self.inputImage.size.width/2.0, self.inputImage.size.width/2.0, -self.inputImage.size.height/2.0, self.inputImage.size.height/2.0, -1, 1.0);
    
    /*
    simd_float4x4 perspectiveMatrix = MTIMakePerspectiveMatrix(-self.inputImage.size.width/2.0, self.inputImage.size.width/2.0, -self.inputImage.size.height/2.0, self.inputImage.size.height/2.0, 1.0, 960.0/2.0);

    MTIVertices *v = [self verticesForRect:CGRectMake(-self.inputImage.size.width/2.0, -self.inputImage.size.height/2.0, self.inputImage.size.width, self.inputImage.size.height)];
    simd_float4 position = ((MTIVertex *)v.bufferBytes)[0].position;
    simd_float4 p1 = [self vector:position matrix:simd_transpose(transformMatrix)];
    simd_float4 p2 = [self vector:p1 matrix:simd_transpose(perspectiveMatrix)];
    NSLog(@"P1: %@,%@,%@,%@",@(p1.x),@(p1.y),@(p1.z),@(p1.w));
    NSLog(@"P2: %@,%@,%@,%@",@(p2.x/p2.w),@(p2.y/p2.w),@(p2.z/p2.w),@(p2.w/p2.w));
    NSAssert(p2.w == -p1.z, @"");
    */
    
    MTIRenderPipelineOutputDescriptor *outputDescriptor = [[MTIRenderPipelineOutputDescriptor alloc] initWithDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputImage.size) pixelFormat:MTIPixelFormatUnspecified loadAction:MTLLoadActionClear];
    return [[MTITransformFilter kernel] imagesByDrawingGeometry:[self verticesForRect:CGRectMake(-self.inputImage.size.width/2.0, -self.inputImage.size.height/2.0, self.inputImage.size.width, self.inputImage.size.height)]
                                                   withTextures:@[self.inputImage]
                                                     parameters:@{@"transformMatrix": [NSData dataWithBytes:&transformMatrix length:sizeof(transformMatrix)],
                                                                  @"orthographicMatrix": [NSData dataWithBytes:&orthographicMatrix length:sizeof(orthographicMatrix)]}
                                              outputDescriptors:@[outputDescriptor]].firstObject;
}

+ (nonnull NSSet<NSString *> *)inputParameterKeys {
    return [NSSet set];
}

@end
