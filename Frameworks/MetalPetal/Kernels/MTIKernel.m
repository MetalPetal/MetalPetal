//
//  MTIKernel.m
//  Pods
//
//  Created by YuAo on 02/07/2017.
//
//

#import "MTIKernel.h"
#import "MTIDefer.h"
#import "MTIVector.h"
#import "MTIError.h"
#import "MTIBuffer.h"

@implementation MTIArgumentsEncoder

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
                #if TARGET_OS_IPHONE
                if (@available(iOS 11.0, *)) {
                    [(id<MTLRenderCommandEncoder>)encoder setTileBytes:bytes length:length atIndex:index];
                }
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
                #if TARGET_OS_IPHONE
                if (@available(iOS 11.0, *)) {
                    [(id<MTLRenderCommandEncoder>)encoder setTileBuffer:buffer offset:0 atIndex:index];
                }
                #endif
            } else {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unsupported command encoder." userInfo:nil];
            }
            break;
        default:
            break;
    }
}

+ (BOOL)encodeArguments:(NSArray<MTLArgument *> *)arguments values:(NSDictionary<NSString *,id> *)parameters functionType:(MTLFunctionType)functionType encoder:(id<MTLCommandEncoder>)encoder error:(NSError * __autoreleasing *)inOutError {
    
    for (MTLArgument *argument in arguments) {
        if (argument.type != MTLArgumentTypeBuffer) {
            continue;
        }
        id value = parameters[argument.name];
        if (value) {
            if ([value isKindOfClass:[NSValue class]]) {
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
                        *inOutError = MTIErrorCreate(MTIErrorDataBufferSizeMismatch, (@{@"Argument": argument, @"Value": value}));
                    }
                    return NO;
                }
                MTIArgumentsEncoderEncodeBytes(functionType, encoder, valuePtr, size, argument.index);
            }else if ([value isKindOfClass:[NSData class]]) {
                NSData *data = (NSData *)value;
                MTIArgumentsEncoderEncodeBytes(functionType, encoder, data.bytes, data.length, argument.index);
            }else if ([value isKindOfClass:[MTIVector class]]) {
                MTIVector *vector = (MTIVector *)value;
                MTIArgumentsEncoderEncodeBytes(functionType, encoder, vector.bytes, vector.byteLength, argument.index);
            }else if ([value isKindOfClass:[MTIDataBuffer class]]) {
                MTIDataBuffer *dataBuffer = (MTIDataBuffer *)value;
                id<MTLBuffer> buffer = [dataBuffer bufferForDevice:encoder.device];
                MTIArgumentsEncoderEncodeBuffer(functionType, encoder, buffer, argument.index);
            } else {
                if (inOutError != nil) {
                    *inOutError = MTIErrorCreate(MTIErrorParameterDataTypeNotSupported, (@{@"Argument": argument, @"Value": value}));
                }
                return NO;
            }
        }
    }
    
    return YES;
}

@end
