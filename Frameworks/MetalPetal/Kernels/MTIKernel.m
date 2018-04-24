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

@implementation MTIArgumentsEncoder

+ (BOOL)encodeArguments:(NSArray<MTLArgument *> *)arguments values:(NSDictionary<NSString *,id> *)parameters functionType:(MTLFunctionType)functionType encoder:(id<MTLCommandEncoder>)encoder error:(NSError * _Nullable __autoreleasing *)inOutError {
    
    void (^encodeBytes)(const void * bytes, NSUInteger length, NSUInteger index) = ^(const void * bytes, NSUInteger length, NSUInteger index) {
        switch (functionType) {
            case MTLFunctionTypeFragment:
                if ([encoder conformsToProtocol:@protocol(MTLRenderCommandEncoder)]) {
                    [(id<MTLRenderCommandEncoder>)encoder setFragmentBytes:bytes length:length atIndex:index];
                }
                break;
            case MTLFunctionTypeVertex:
                if ([encoder conformsToProtocol:@protocol(MTLRenderCommandEncoder)]) {
                    [(id<MTLRenderCommandEncoder>)encoder setVertexBytes:bytes length:length atIndex:index];
                }
                break;
            case MTLFunctionTypeKernel:
                if ([encoder conformsToProtocol:@protocol(MTLComputeCommandEncoder)]) {
                    [(id<MTLComputeCommandEncoder>)encoder setBytes:bytes length:length atIndex:index];
                } else if ([encoder conformsToProtocol:@protocol(MTLRenderCommandEncoder)]) {
                    if (@available(iOS 11.0, *)) {
                        [(id<MTLRenderCommandEncoder>)encoder setTileBytes:bytes length:length atIndex:index];
                    }
                }
                break;
            default:
                break;
        }
    };
    
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
                encodeBytes(valuePtr, size, argument.index);
            }else if ([value isKindOfClass:[NSData class]]) {
                NSData *data = (NSData *)value;
                encodeBytes(data.bytes, data.length, argument.index);
            }else if ([value isKindOfClass:[MTIVector class]]) {
                MTIVector *vector = (MTIVector *)value;
                encodeBytes(vector.data.bytes, vector.data.length, argument.index);
            }else {
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
