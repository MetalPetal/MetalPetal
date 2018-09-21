//
//  MTIImagePromiseDebug.m
//  MetalPetal
//
//  Created by Yu Ao on 23/11/2017.
//

#import "MTIImagePromiseDebug.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage+Promise.h"
#import <QuartzCore/QuartzCore.h>

#if TARGET_OS_IPHONE
#define MTIFont UIFont
#else
#define MTIFont NSFont
#endif

NSString * MTIImagePromiseDebugIdentifierForObject(id object) {
    return [[NSString stringWithFormat:@"%p",object] stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString:@""];
}

@interface MTIImagePromiseDebugInfo ()

@property (nonatomic,readonly) MTITextureDimensions dimensions;
@property (nonatomic,readonly) MTIAlphaType alphaType;

@end

@implementation MTIImagePromiseDebugInfo

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise type:(MTIImagePromiseType)type content:(id)content {
    if (self = [super init]) {
        _identifier = MTIImagePromiseDebugIdentifierForObject(promise);
        _type = type;
        _content = content;
        _title = NSStringFromClass(promise.class);
        _dimensions = promise.dimensions;
        _alphaType = promise.alphaType;
    }
    return self;
}

- (CALayer *)layerRepresentation {
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    const CGFloat contentPadding = 10;
    
    const CGFloat sourceBackgroundColorValues[] = {0.93, 0.94, 0.95, 1.0};
    const CGFloat sourceBorderColorValues[] = {0.74, 0.76, 0.78, 1.0};

//    const CGFloat processorBackgroundColorValues[] = {0.95, 0.87, 0.71, 1.0};
//    const CGFloat processorBorderColorValues[] = {0.84, 0.76, 0.58, 1.0};

    const CGFloat processorBackgroundColorValues[] = {1.0, 0.8, 0.0, 1.0};
    const CGFloat processorBorderColorValues[] = {1.0, 0.66, 0.0, 1.0};
    
    const CGFloat foregroundColorValues[] = {0.17, 0.17, 0.17, 1.0};
    
    CGColorRef backgroundColor;
    CGColorRef borderColor;
    CGColorRef foregroundColor = CGColorCreate(colorspace, foregroundColorValues);
    switch (self.type) {
        case MTIImagePromiseTypeSource:
            backgroundColor = CGColorCreate(colorspace, sourceBackgroundColorValues);
            borderColor = CGColorCreate(colorspace, sourceBorderColorValues);
            break;
        case MTIImagePromiseTypeProcessor:
            backgroundColor = CGColorCreate(colorspace, processorBackgroundColorValues);
            borderColor = CGColorCreate(colorspace, processorBorderColorValues);
            break;
        default:
            break;
    }
    
    CALayer *baseLayer = [[CALayer alloc] init];
    baseLayer.frame = CGRectMake(0, 0, 300, 100);
    baseLayer.borderWidth = 2;
    baseLayer.cornerRadius = 5;
    baseLayer.backgroundColor = backgroundColor;
    baseLayer.borderColor = borderColor;
    baseLayer.masksToBounds = YES;
    
    CALayer *titleBackgroundLayer = [[CALayer alloc] init];
    titleBackgroundLayer.frame = CGRectMake(0, 0, baseLayer.bounds.size.width, 24);
    titleBackgroundLayer.backgroundColor = borderColor;
    [baseLayer addSublayer:titleBackgroundLayer];
    
    CATextLayer *titleLayer = [[CATextLayer alloc] init];
    titleLayer.fontSize = 12;
    titleLayer.string = self.title;
    titleLayer.foregroundColor = foregroundColor;
    CGSize titleLayerPreferredSize = [titleLayer preferredFrameSize];
    titleLayer.frame = CGRectMake(contentPadding, (titleBackgroundLayer.bounds.size.height - titleLayerPreferredSize.height)/2.0, titleLayerPreferredSize.width, titleLayerPreferredSize.height);
    [titleBackgroundLayer addSublayer:titleLayer];
    
    CATextLayer *contentTextLayer = [[CATextLayer alloc] init];
    contentTextLayer.fontSize = 10;
    NSString *content = @"";
    content = [content stringByAppendingFormat:@"[%@x%@x%@] Alpha: %@\n",@(self.dimensions.width),@(self.dimensions.height),@(self.dimensions.depth),MTIAlphaTypeGetDescription(self.alphaType)];
    content = [content stringByAppendingString:@"\n"];
    content = [content stringByAppendingString:[self.content debugDescription] ?: @""];
    contentTextLayer.string = content;
    contentTextLayer.foregroundColor = foregroundColor;
    [baseLayer addSublayer:contentTextLayer];
    CGSize contentTextLayerPreferredSize;// = [contentTextLayer preferredFrameSize];
    contentTextLayerPreferredSize = [content boundingRectWithSize:CGSizeMake(baseLayer.frame.size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [MTIFont systemFontOfSize:10]} context:nil].size;
    contentTextLayer.wrapped = YES;
    contentTextLayer.frame = CGRectMake(contentPadding, CGRectGetMaxY(titleBackgroundLayer.frame) + contentPadding, contentTextLayerPreferredSize.width, contentTextLayerPreferredSize.height);
    
    baseLayer.frame = CGRectMake(0, 0, baseLayer.frame.size.width, CGRectGetMaxY(contentTextLayer.frame) + contentPadding * 2);
    
    CGColorRelease(foregroundColor);
    CGColorRelease(backgroundColor);
    CGColorRelease(borderColor);
    CGColorSpaceRelease(colorspace);
    
    return baseLayer;
}

- (id)debugQuickLookObject {
    return [self layerRepresentation];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; %@>",self.class, self, self.content];
}

@end

@implementation MTIImagePromiseDebugInfo (RenderGraph)

+ (CALayer *)layerRepresentationOfRenderGraphForPromise:(id<MTIImagePromise>)promise promiseLayerTable:(NSMutableDictionary *)promiseLayerTable {
    CALayer *generatedLayer = promiseLayerTable[promise];
    if (generatedLayer) {
        return generatedLayer;
    }
    
    CALayer *container = [[CALayer alloc] init];
    
    CALayer *rootLayer = promise.debugInfo.layerRepresentation;
    
    [container addSublayer:rootLayer];
    
    promiseLayerTable[promise] = rootLayer;
    
    CGFloat x = 0;
    CGFloat y = CGRectGetMaxY(rootLayer.frame) + 60;
    CGFloat maxHeight = CGRectGetMaxY(rootLayer.frame);
    CGFloat maxWidth = CGRectGetMaxX(rootLayer.frame);
    for (MTIImage *image in promise.dependencies) {
        CALayer *layer = promiseLayerTable[image.promise];
        if (!layer) {
            layer = [self layerRepresentationOfRenderGraphForPromise:image.promise promiseLayerTable:promiseLayerTable];
            CGRect frame = layer.frame;
            frame.origin.x = x;
            frame.origin.y = y;
            layer.frame = frame;
            
            x = CGRectGetMaxX(layer.frame) + 40;
            
            [container addSublayer:layer];
            
            if (CGRectGetMaxY(layer.frame) > maxHeight) {
                maxHeight = CGRectGetMaxY(layer.frame);
            }
            
            if (CGRectGetMaxX(layer.frame) > maxWidth) {
                maxWidth = CGRectGetMaxX(layer.frame);
            }
        }
    }
    container.frame = CGRectMake(0, 0, maxWidth, maxHeight);
    return container;
}

+ (void)makeConnectionForPromise:(id<MTIImagePromise>)promise path:(CGMutablePathRef)path container:(CALayer *)container promiseLayerTable:(NSMutableDictionary *)promiseLayerTable {
    CALayer *rootLayer = promiseLayerTable[promise];
    for (MTIImage *image in promise.dependencies) {
        [self makeConnectionForPromise:image.promise path:path container:container promiseLayerTable:promiseLayerTable];
        
        CALayer *layer = promiseLayerTable[image.promise];
        CGRect rootLayerFrame = [rootLayer convertRect:rootLayer.bounds toLayer:container];
        CGRect layerFrame = [layer convertRect:layer.bounds toLayer:container];
        CGPoint fromPoint = CGPointMake(CGRectGetMidX(layerFrame), CGRectGetMinY(layerFrame));
        CGPoint toPoint = CGPointMake(CGRectGetMidX(rootLayerFrame), CGRectGetMaxY(rootLayerFrame));
        
        CGPoint direction = CGPointMake((NSInteger)((toPoint.x - fromPoint.x)/10.0), (NSInteger)((toPoint.y - fromPoint.y)/10.0));
        if (direction.y > 0) {
            if (direction.x > 0) {
                toPoint = CGPointMake(CGRectGetMinX(rootLayerFrame), CGRectGetMidY(rootLayerFrame));
            } else if (direction.x < 0) {
                toPoint = CGPointMake(CGRectGetMaxX(rootLayerFrame), CGRectGetMidY(rootLayerFrame));
            }
        }
        
        CGPathMoveToPoint(path, nil, fromPoint.x, fromPoint.y);
        CGPathAddLineToPoint(path, nil, toPoint.x, toPoint.y);
        
        CGFloat arrowWidth = 4;
        CGFloat arrowHeight = 10;
        CGFloat angle = atan2f(toPoint.y - fromPoint.y, toPoint.x - fromPoint.x);
        CGFloat angleAdjustment = atan2f(arrowWidth, -arrowHeight);
        CGFloat distance = hypotf(arrowWidth, arrowHeight);
        
        CGPoint arrowPointA = CGPointMake(toPoint.x + cosf(angle - angleAdjustment) * distance, toPoint.y + sinf(angle - angleAdjustment) * distance);
        CGPoint arrowPointB = CGPointMake(toPoint.x + cosf(angle + angleAdjustment) * distance, toPoint.y + sinf(angle + angleAdjustment) * distance);
        CGPathMoveToPoint(path, nil, toPoint.x, toPoint.y);
        CGPathAddLineToPoint(path, nil, arrowPointA.x, arrowPointA.y);
        CGPathMoveToPoint(path, nil, toPoint.x, toPoint.y);
        CGPathAddLineToPoint(path, nil, arrowPointB.x, arrowPointB.y);
        
        CGRect fromRect = CGRectMake(fromPoint.x - 2, fromPoint.y - 2, 4, 4);
        CGPathAddEllipseInRect(path, nil, fromRect);
    }
}

+ (CALayer *)layerRepresentationOfRenderGraphForPromise:(id<MTIImagePromise>)promise {
    NSMutableDictionary *promiseLayerTable = [NSMutableDictionary dictionary];
    
    CALayer *container = [self layerRepresentationOfRenderGraphForPromise:promise promiseLayerTable:promiseLayerTable];
    
    CAShapeLayer *linkLayer = [[CAShapeLayer alloc] init];
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    [self makeConnectionForPromise:promise path:path container:container promiseLayerTable:promiseLayerTable];
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    const CGFloat foregroundColorValues[] = {0.20, 0.29, 0.37, 0.75};
    CGColorRef foregroundColor = CGColorCreate(colorspace, foregroundColorValues);
    
    linkLayer.frame = container.bounds;
    linkLayer.path = path;
    linkLayer.lineWidth = 2;
    linkLayer.lineCap = kCALineCapRound;
    linkLayer.lineJoin = kCALineJoinRound;
    linkLayer.strokeColor = foregroundColor;
    
    [container addSublayer:linkLayer];
    
    CGPathRelease(path);
    CGColorRelease(foregroundColor);
    CGColorSpaceRelease(colorspace);
    
    return container;
}

@end
