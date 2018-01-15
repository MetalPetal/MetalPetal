//
//  MTIRGBToneCurveFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 12/01/2018.
//

#import "MTIRGBToneCurveFilter.h"
#import "MTIImage.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import <Accelerate/Accelerate.h>

@interface MTIRGBToneCurveFilter () {
    float _redCurve[256];
    float _greenCurve[256];
    float _blueCurve[256];
    float _RGBCurve[256];
}

@property (nonatomic) BOOL toneCurveColorLookupImageIsDirty;

@end

@implementation MTIRGBToneCurveFilter
@synthesize toneCurveColorLookupImage = _toneCurveColorLookupImage;
@synthesize inputImage = _inputImage;
@synthesize outputPixelFormat = _outputPixelFormat;

- (instancetype)init {
    if (self = [super init]) {
        _intensity = 1.0;
        _redControlPoints = @[];
        _greenControlPoints = @[];
        _blueControlPoints = @[];
        _RGBCompositeControlPoints = @[];
        float zero = 0;
        vDSP_vfill(&zero, _redCurve, 1, 256);
        vDSP_vfill(&zero, _greenCurve, 1, 256);
        vDSP_vfill(&zero, _blueCurve, 1, 256);
        vDSP_vfill(&zero, _RGBCurve, 1, 256);
    }
    return self;
}

- (void)setRedControlPoints:(NSArray<MTIVector *> *)redControlPoints {
    _redControlPoints = [redControlPoints copy];
    [self updatePreparedSplineCurve:_redCurve withControlPoints:_redControlPoints];
    _toneCurveColorLookupImageIsDirty = YES;
}

- (void)setGreenControlPoints:(NSArray<MTIVector *> *)greenControlPoints {
    _greenControlPoints = [greenControlPoints copy];
    [self updatePreparedSplineCurve:_greenCurve withControlPoints:_greenControlPoints];
    _toneCurveColorLookupImageIsDirty = YES;
}

- (void)setBlueControlPoints:(NSArray<MTIVector *> *)blueControlPoints {
    _blueControlPoints = [blueControlPoints copy];
    [self updatePreparedSplineCurve:_blueCurve withControlPoints:_blueControlPoints];
    _toneCurveColorLookupImageIsDirty = YES;
}

- (void)setRGBCompositeControlPoints:(NSArray<MTIVector *> *)RGBCompositeControlPoints {
    _RGBCompositeControlPoints = [RGBCompositeControlPoints copy];
    [self updatePreparedSplineCurve:_RGBCurve withControlPoints:_RGBCompositeControlPoints];
    _toneCurveColorLookupImageIsDirty = YES;
}

- (void)updatePreparedSplineCurve:(float[256])curve withControlPoints:(NSArray<MTIVector *> *)controlPoints {
    if (controlPoints.count > 1) {
        // Sort the array.
        NSArray<MTIVector *> *sortedPoints = [controlPoints sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            float x1 = [a CGPointValue].x;
            float x2 = [b CGPointValue].x;
            return x1 > x2;
        }];
        
        const NSInteger n = sortedPoints.count;
        
        // Convert from (0, 1) to (0, 255).
        CGPoint convertedPoints[n];
        for (NSInteger i = 0; i < n; i++){
            CGPoint point = [[sortedPoints objectAtIndex:i] CGPointValue];
            point.x = point.x * 255;
            point.y = point.y * 255;
            convertedPoints[i] = point;
        }
        
        //-------------
        //secondDerivative
        double matrix[n][3];
        double result[n];
        matrix[0][1]=1;
        // What about matrix[0][1] and matrix[0][0]? Assuming 0 for now (Brad L.)
        matrix[0][0]=0;
        matrix[0][2]=0;
        
        for(int i=1;i<n-1;i++) {
            CGPoint P1 = convertedPoints[i-1];
            CGPoint P2 = convertedPoints[i];
            CGPoint P3 = convertedPoints[i+1];
            
            matrix[i][0]=(double)(P2.x-P1.x)/6;
            matrix[i][1]=(double)(P3.x-P1.x)/3;
            matrix[i][2]=(double)(P3.x-P2.x)/6;
            result[i]=(double)(P3.y-P2.y)/(P3.x-P2.x) - (double)(P2.y-P1.y)/(P2.x-P1.x);
        }
        
        // What about result[0] and result[n-1]? Assuming 0 for now (Brad L.)
        result[0] = 0;
        result[n-1] = 0;
        
        matrix[n-1][1]=1;
        // What about matrix[n-1][0] and matrix[n-1][2]? For now, assuming they are 0 (Brad L.)
        matrix[n-1][0]=0;
        matrix[n-1][2]=0;
        
        // solving pass1 (up->down)
        for(NSInteger i = 1; i < n; i++) {
            double k = matrix[i][0]/matrix[i-1][1];
            matrix[i][1] -= k*matrix[i-1][2];
            matrix[i][0] = 0;
            result[i] -= k*result[i-1];
        }
        // solving pass2 (down->up)
        for(NSInteger i = n-2; i >= 0; i--) {
            double k = matrix[i][2]/matrix[i+1][1];
            matrix[i][1] -= k*matrix[i+1][0];
            matrix[i][2] = 0;
            result[i] -= k*result[i+1];
        }
        
        double sd[n];
        for(NSInteger i = 0; i < n; i++) {
            sd[i]=result[i]/matrix[i][1];
        }
        
        //-------------
        void(^curvePoint)(CGPoint point) = ^(CGPoint point) {
            CGPoint newPoint = point;
            CGPoint origPoint = CGPointMake(newPoint.x, newPoint.x);
            float distance = sqrt(pow((origPoint.x - newPoint.x), 2.0) + pow((origPoint.y - newPoint.y), 2.0));
            if (origPoint.y > newPoint.y) {
                distance = -distance;
            }
            curve[(int)point.x] = distance;
        };
        
        for(NSInteger i = 0; i < n-1; i++) {
            CGPoint cur = convertedPoints[i];
            CGPoint next = convertedPoints[i+1];
            
            for(int x = cur.x; x < (int)next.x; x++) {
                double t = (double)(x-cur.x)/(next.x-cur.x);
                
                double a = 1-t;
                double b = t;
                double h = next.x-cur.x;
                
                double y= a*cur.y + b*next.y + (h*h/6)*( (a*a*a-a)*sd[i]+ (b*b*b-b)*sd[i+1] );
                
                if (y > 255.0) {
                    y = 255.0;
                } else if (y < 0.0) {
                    y = 0.0;
                }
                curvePoint(CGPointMake(x, y));
            }
        }
        
        // The above always misses the last point because the last point is the last next, so we approach but don't equal it.
        curvePoint(convertedPoints[n-1]);
        
        // If we have a first point like (0.3, 0) we'll be missing some points at the beginning
        // that should be 0.
        if (convertedPoints[0].x > 0) {
            for (int i = convertedPoints[0].x; i >= 0; i -= 1) {
                CGPoint newCGPoint = CGPointMake(i, 0);
                curvePoint(newCGPoint);
            }
        }
        
        if (convertedPoints[n-1].x < 255) {
            for (int i = convertedPoints[n-1].x + 1; i <= 255; i += 1) {
                CGPoint newCGPoint = CGPointMake(i, 255);
                curvePoint(newCGPoint);
            }
        }
    } else {
        float zero = 0;
        vDSP_vfill(&zero, curve, 1, 256);
    }
}

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"rgbToneCurveAdjust"]];
    });
    return kernel;
}

- (MTIImage *)toneCurveColorLookupImage {
    if (_toneCurveColorLookupImageIsDirty) {
        uint8_t toneCurveByteArray[256 * 4];
        for (NSUInteger currentCurveIndex = 0; currentCurveIndex < 256; currentCurveIndex++) {
            // BGRA for upload to texture
            uint8_t b = fmin(fmax(currentCurveIndex + _blueCurve[currentCurveIndex], 0), 255);
            toneCurveByteArray[currentCurveIndex * 4] = fmin(fmax(b + _RGBCurve[b], 0), 255);
            
            uint8_t g = fmin(fmax(currentCurveIndex + _greenCurve[currentCurveIndex], 0), 255);
            toneCurveByteArray[currentCurveIndex * 4 + 1] = fmin(fmax(g + _RGBCurve[g], 0), 255);
            
            uint8_t r = fmin(fmax(currentCurveIndex + _redCurve[currentCurveIndex], 0), 255);
            toneCurveByteArray[currentCurveIndex * 4 + 2] = fmin(fmax(r + _RGBCurve[r], 0), 255);
            
            toneCurveByteArray[currentCurveIndex * 4 + 3] = 255;
        }
        _toneCurveColorLookupImage = [[MTIImage alloc] initWithBitmapData:[NSData dataWithBytes:toneCurveByteArray length:256 * 4] width:256 height:1 bytesPerRow:256 * 4 pixelFormat:MTLPixelFormatBGRA8Unorm alphaType:MTIAlphaTypeAlphaIsOne];
        _toneCurveColorLookupImageIsDirty = NO;
    }
    return _toneCurveColorLookupImage;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    return [MTIRGBToneCurveFilter.kernel applyToInputImages:@[self.inputImage, self.toneCurveColorLookupImage]
                                                 parameters:@{@"intensity": @(self.intensity)}
                                    outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(_inputImage.size)
                                          outputPixelFormat:_outputPixelFormat];
}

@end
