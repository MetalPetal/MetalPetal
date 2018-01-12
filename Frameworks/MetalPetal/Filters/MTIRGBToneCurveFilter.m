//
//  MTIRGBToneCurveFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 12/01/2018.
//

#import "MTIRGBToneCurveFilter.h"
#import "MTIImage.h"

@interface MTIRGBToneCurveFilter () {
    float _redCurve[256];
    float _greenCurve[256];
    float _blueCurve[256];
    float _RGBCurve[256];
}

@property (nonatomic, strong) MTIImage *toneCurveImage;

@end

@implementation MTIRGBToneCurveFilter
@synthesize inputImage = _inputImage;
@synthesize outputPixelFormat = _outputPixelFormat;
@synthesize inputRGBCompositeControlPoints = _inputRGBCompositeControlPoints;
@synthesize inputRedControlPoints = _inputRedControlPoints;
@synthesize inputGreenControlPoints = _inputGreenControlPoints;
@synthesize inputBlueControlPoints = _inputBlueControlPoints;

- (instancetype)init {
    if (self = [super init]) {
        _intensity = 1.0;
        _inputRedControlPoints = @[];
        _inputGreenControlPoints = @[];
        _inputBlueControlPoints = @[];
        _inputRGBCompositeControlPoints = @[];
        for (int i = 0; i < 255; i += 1) {
            _redCurve[i] = i;
            _greenCurve[i] = i;
            _blueCurve[i] = i;
            _RGBCurve[i] = i;
        }
    }
    return self;
}

- (NSArray<NSValue *> *)defaultCurveControlPoints {
    return @[[NSValue valueWithCGPoint:CGPointMake(0, 0)],
             [NSValue valueWithCGPoint:CGPointMake(0.5, 0.5)],
             [NSValue valueWithCGPoint:CGPointMake(1, 1)]];
}

- (void)setInputRedControlPoints:(NSArray<NSValue *> *)inputRedControlPoints {
    _inputRedControlPoints = [inputRedControlPoints copy];
    [self updateCurve:_redCurve withControlPoints:_inputRedControlPoints];
    _toneCurveImage = nil;
}

- (void)setInputGreenControlPoints:(NSArray<NSValue *> *)inputGreenControlPoints {
    _inputGreenControlPoints = [inputGreenControlPoints copy];
    [self updateCurve:_greenCurve withControlPoints:_inputGreenControlPoints];
    _toneCurveImage = nil;
}

- (void)setInputBlueControlPoints:(NSArray<NSValue *> *)inputBlueControlPoints {
    _inputBlueControlPoints = [inputBlueControlPoints copy];
    [self updateCurve:_blueCurve withControlPoints:_inputBlueControlPoints];
    _toneCurveImage = nil;
}

- (void)setInputRGBCompositeControlPoints:(NSArray<NSValue *> *)inputRGBCompositeControlPoints {
    _inputRGBCompositeControlPoints = [inputRGBCompositeControlPoints copy];
    [self updateCurve:_RGBCurve withControlPoints:_inputRGBCompositeControlPoints];
    _toneCurveImage = nil;
}

- (void)updateCurve:(float[256])curve withControlPoints:(NSArray<NSValue *> *)controlPoints {
    
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    if (!_toneCurveImage) {
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
        _toneCurveImage = [[MTIImage alloc] initWithBitmapData:[NSData dataWithBytes:toneCurveByteArray length:256 * 4] width:256 height:1 bytesPerRow:256 * 4 pixelFormat:MTLPixelFormatBGRA8Unorm alphaType:MTIAlphaTypeAlphaIsOne];
    }
    return self.inputImage;
}

@end
