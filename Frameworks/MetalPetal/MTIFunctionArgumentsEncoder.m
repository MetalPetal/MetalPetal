//
//  MTIFunctionArgumentsEncoder.m
//  MetalPetal
//
//  Created by YuAo on 2020/7/11.
//

#import "MTIFunctionArgumentsEncoder.h"
#import "MTIDefer.h"
#import "MTIVector.h"
#import "MTIError.h"
#import "MTIBuffer.h"

static inline void MTIArgumentsEncoderEncodeBytes(MTLFunctionType functionType, id<MTLCommandEncoder> encoder, const void * bytes, NSUInteger length, NSUInteger index) {
    switch (functionType) {
        case MTLFunctionTypeFragment:
            [(id<MTLRenderCommandEncoder>)encoder setFragmentBytes:bytes length:length atIndex:index];
            break;
        case MTLFunctionTypeVertex:
            [(id<MTLRenderCommandEncoder>)encoder setVertexBytes:bytes length:length atIndex:index];
            break;
        case MTLFunctionTypeKernel:
            if ([encoder conformsToProtocol:@protocol(MTLComputeCommandEncoder)]) {
                [(id<MTLComputeCommandEncoder>)encoder setBytes:bytes length:length atIndex:index];
            } else if ([encoder conformsToProtocol:@protocol(MTLRenderCommandEncoder)]) {
                #if TARGET_OS_IPHONE && !TARGET_OS_MACCATALYST && !TARGET_OS_TV
                [(id<MTLRenderCommandEncoder>)encoder setTileBytes:bytes length:length atIndex:index];
                #endif
            } else {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unsupported command encoder." userInfo:nil];
            }
            break;
        default:
            break;
    }
}

static inline void MTIArgumentsEncoderEncodeBuffer(MTLFunctionType functionType, id<MTLCommandEncoder> encoder, id<MTLBuffer> buffer, NSUInteger index) {
    switch (functionType) {
        case MTLFunctionTypeFragment:
            [(id<MTLRenderCommandEncoder>)encoder setFragmentBuffer:buffer offset:0 atIndex:index];
            break;
        case MTLFunctionTypeVertex:
            [(id<MTLRenderCommandEncoder>)encoder setVertexBuffer:buffer offset:0 atIndex:index];
            break;
        case MTLFunctionTypeKernel:
            if ([encoder conformsToProtocol:@protocol(MTLComputeCommandEncoder)]) {
                [(id<MTLComputeCommandEncoder>)encoder setBuffer:buffer offset:0 atIndex:index];
            } else if ([encoder conformsToProtocol:@protocol(MTLRenderCommandEncoder)]) {
                #if TARGET_OS_IPHONE && !TARGET_OS_MACCATALYST && !TARGET_OS_TV
                [(id<MTLRenderCommandEncoder>)encoder setTileBuffer:buffer offset:0 atIndex:index];
                #endif
            } else {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unsupported command encoder." userInfo:nil];
            }
            break;
        default:
            break;
    }
}

__attribute__((objc_subclassing_restricted))
@interface MTIFunctionArgumentEncodingProxyImplementation: NSObject <MTIFunctionArgumentEncodingProxy>

@property (nonatomic) BOOL used;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong, readonly) id<MTLCommandEncoder> encoder;
@property (nonatomic, strong, readonly) MTLArgument *argument;
@property (nonatomic, readonly) MTLFunctionType functionType;

@end

@implementation MTIFunctionArgumentEncodingProxyImplementation

- (instancetype)initWithEncoder:(id<MTLCommandEncoder>)encoder functionType:(MTLFunctionType)functionType argument:(MTLArgument *)argument {
    if (self = [super init]) {
        _encoder = encoder;
        _functionType = functionType;
        _argument = argument;
        _used = NO;
        _error = nil;
    }
    return self;
}

- (void)encodeBytes:(const void *)bytes length:(NSUInteger)length {
    NSAssert(_encoder != nil, @"An encoding proxy can only encode/reportError once.");
    if (_encoder) {
        if (length != _argument.bufferDataSize) {
            _error = MTIErrorCreate(MTIErrorParameterDataSizeMismatch, (@{@"Argument": _argument}));
            _used = YES;
        } else {
            MTIArgumentsEncoderEncodeBytes(_functionType, _encoder, bytes, length, _argument.index);
            _used = YES;
        }
        _encoder = nil;
        _argument = nil;
    }
}

- (void)invalidate {
    _encoder = nil;
    _argument = nil;
}

@end

@implementation MTIFunctionArgumentsEncoder

+ (BOOL)encodeArguments:(NSArray<MTLArgument *> *)arguments values:(NSDictionary<NSString *,id> *)parameters functionType:(MTLFunctionType)functionType encoder:(id<MTLCommandEncoder>)encoder error:(NSError * __autoreleasing *)inOutError {
    
    for (MTLArgument *argument in arguments) {
        if (argument.type != MTLArgumentTypeBuffer) {
            continue;
        }
        id value = parameters[argument.name];
        if (!value) {
            continue;
        }
        if ([value isKindOfClass:[NSNumber class]]) {
            NSNumber *number = value;
            switch (argument.bufferDataType) {
                case MTLDataTypeBool: {
                    bool b = (bool)number.boolValue;
                    NSAssert(sizeof(b) == argument.bufferDataSize, @"");
                    MTIArgumentsEncoderEncodeBytes(functionType, encoder, &b, sizeof(b), argument.index);
                } break;
                case MTLDataTypeInt: {
                    int i = number.intValue;
                    NSAssert(sizeof(i) == argument.bufferDataSize, @"");
                    MTIArgumentsEncoderEncodeBytes(functionType, encoder, &i, sizeof(i), argument.index);
                } break;
                case MTLDataTypeUInt: {
                    unsigned int i = number.unsignedIntValue;
                    NSAssert(sizeof(i) == argument.bufferDataSize, @"");
                    MTIArgumentsEncoderEncodeBytes(functionType, encoder, &i, sizeof(i), argument.index);
                } break;
                case MTLDataTypeChar: {
                    char c = number.charValue;
                    NSAssert(sizeof(c) == argument.bufferDataSize, @"");
                    MTIArgumentsEncoderEncodeBytes(functionType, encoder, &c, sizeof(c), argument.index);
                } break;
                case MTLDataTypeUChar: {
                    unsigned char c = number.unsignedCharValue;
                    NSAssert(sizeof(c) == argument.bufferDataSize, @"");
                    MTIArgumentsEncoderEncodeBytes(functionType, encoder, &c, sizeof(c), argument.index);
                } break;
                case MTLDataTypeShort: {
                    short s = number.shortValue;
                    NSAssert(sizeof(s) == argument.bufferDataSize, @"");
                    MTIArgumentsEncoderEncodeBytes(functionType, encoder, &s, sizeof(s), argument.index);
                } break;
                case MTLDataTypeUShort: {
                    unsigned short s = number.unsignedShortValue;
                    NSAssert(sizeof(s) == argument.bufferDataSize, @"");
                    MTIArgumentsEncoderEncodeBytes(functionType, encoder, &s, sizeof(s), argument.index);
                } break;
                case MTLDataTypeFloat: {
                    float f = number.floatValue;
                    NSAssert(sizeof(f) == argument.bufferDataSize, @"");
                    MTIArgumentsEncoderEncodeBytes(functionType, encoder, &f, sizeof(f), argument.index);
                } break;
                case MTLDataTypeHalf: {
                    float f = number.floatValue;
                    __fp16 h = f;
                    NSAssert(sizeof(h) == argument.bufferDataSize, @"");
                    MTIArgumentsEncoderEncodeBytes(functionType, encoder, &h, sizeof(h), argument.index);
                } break;
                default: {
                    if (inOutError != nil) {
                        *inOutError = MTIErrorCreate(MTIErrorParameterDataTypeMismatch, (@{@"Argument": argument, @"Value": value}));
                    }
                    return NO;
                } break;
            }
        } else if ([value isKindOfClass:[NSValue class]]) {
            NSValue *nsValue = (NSValue *)value;
            NSUInteger size;
            NSGetSizeAndAlignment(nsValue.objCType, &size, NULL);
            void *valuePtr = malloc(size);
            [nsValue getValue:valuePtr];
            @MTI_DEFER {
                free(valuePtr);
            };
            if (argument.bufferDataSize != size) {
                if (inOutError != nil) {
                    *inOutError = MTIErrorCreate(MTIErrorParameterDataSizeMismatch, (@{@"Argument": argument, @"Value": value}));
                }
                return NO;
            }
            MTIArgumentsEncoderEncodeBytes(functionType, encoder, valuePtr, size, argument.index);
        } else if ([value isKindOfClass:[NSData class]]) {
            NSData *data = (NSData *)value;
            MTIArgumentsEncoderEncodeBytes(functionType, encoder, data.bytes, data.length, argument.index);
        } else if ([value isKindOfClass:[MTIVector class]]) {
            MTIVector *vector = (MTIVector *)value;
            MTIArgumentsEncoderEncodeBytes(functionType, encoder, vector.bytes, vector.byteLength, argument.index);
        } else if ([value isKindOfClass:[MTIDataBuffer class]]) {
            MTIDataBuffer *dataBuffer = (MTIDataBuffer *)value;
            id<MTLBuffer> buffer = [dataBuffer bufferForDevice:encoder.device];
            MTIArgumentsEncoderEncodeBuffer(functionType, encoder, buffer, argument.index);
        } else {
            static Class<MTIFunctionArgumentEncoding> SIMDValueEncoder;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                Class encoder = NSClassFromString(@"MTISIMDArgumentEncoder");
                if ([encoder conformsToProtocol:@protocol(MTIFunctionArgumentEncoding)]) {
                    SIMDValueEncoder = encoder;
                }
            });
            if (SIMDValueEncoder) {
                MTIFunctionArgumentEncodingProxyImplementation *proxy = [[MTIFunctionArgumentEncodingProxyImplementation alloc] initWithEncoder:encoder functionType:functionType argument:argument];
                NSError *encoderError;
                [SIMDValueEncoder encodeValue:value argument:argument proxy:proxy error:&encoderError];
                NSError *error = encoderError ?: proxy.error;
                if (error) {
                    if (inOutError != nil) {
                        *inOutError = error;
                    }
                    return NO;
                }
                if (!proxy.used) {
                    [proxy invalidate];
                    if (inOutError != nil) {
                        *inOutError = MTIErrorCreate(MTIErrorUnsupportedParameterType, (@{@"Argument": argument, @"Value": value}));
                    }
                    return NO;
                }
            } else {
                if (inOutError != nil) {
                    *inOutError = MTIErrorCreate(MTIErrorUnsupportedParameterType, (@{@"Argument": argument, @"Value": value}));
                }
                return NO;
            }
        }
    }
    
    return YES;
}

@end
