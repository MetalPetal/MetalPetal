//
//  MTIKernel.h
//  Pods
//
//  Created by YuAo on 02/07/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT MTLPixelFormat const MTIKernelPixelFormatDontCare;

@class MTIContext;

/// A kernel must be stateless.

@protocol MTIKernel <NSObject>

- (nullable id)newKernelStateWithContext:(MTIContext *)context pixelFormat:(MTLPixelFormat)pixelFormat error:(NSError **)error NS_SWIFT_NAME(makeKernelState(context:outputPixelFormat:));

@end

@interface MTIArgumentsEncoder : NSObject

+ (BOOL)encodeArguments:(NSArray<MTLArgument *>*)arguments
                 values:(NSDictionary<NSString *, id> *)parameters
           functionType:(MTLFunctionType)functionType
                encoder:(id<MTLCommandEncoder>)encoder
                  error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
