//
//  MTIKernel.m
//  Pods
//
//  Created by YuAo on 02/07/2017.
//
//

#import "MTIKernel.h"
#import "MTIDefer.h"
#import "MTIContext.h"
#import "MTIVector.h"
#import "MTIVector+Private.h"
#import "MTIError.h"

BOOL MTIEncodeArgumentsWithEncoder(NSArray<MTLArgument *>* arguments,
              NSDictionary<NSString *, id> * parameters,
              id<MTLCommandEncoder> encoder,
              MTLFunctionType functionType,
              NSError * _Nullable __autoreleasing *inOutError) {
    
    void (^setEncoderWithBytes)(const void * bytes, NSUInteger length, NSUInteger index) = ^(const void * bytes, NSUInteger length, NSUInteger index) {
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
                }
            default:
                break;
        }
    };
    
    for (NSUInteger index = 0; index < arguments.count; index += 1) {
        MTLArgument *argument = arguments[index];
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
                        *inOutError = [NSError errorWithDomain:MTIErrorDomain code:MTIErrorDataBufferSizeMismatch userInfo:@{@"argument": argument, @"value": value}];
                    }
                    return NO;
                }
                setEncoderWithBytes(valuePtr, size, argument.index);
            }else if ([value isKindOfClass:[NSData class]]) {
                NSData *data = (NSData *)value;
                setEncoderWithBytes(data.bytes, data.length, argument.index);
            }else if ([value isKindOfClass:[MTIVector class]]) {
                MTIVector *vector = (MTIVector *)value;
                setEncoderWithBytes(vector.bytes, vector.length, argument.index);
            }else {
                if (inOutError != nil) {
                    *inOutError = [NSError errorWithDomain:MTIErrorDomain code:MTIErrorParameterDataTypeNotSupported userInfo:@{@"argument": argument, @"value": value}];
                }
                return NO;
            }
        }
    }
    
    return YES;
}
