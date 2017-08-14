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
@class MTIContext;

/// A kernel must be stateless.

@protocol MTIKernel <NSObject>

- (nullable id)newKernelStateWithContext:(MTIContext *)context error:(NSError **)error NS_SWIFT_NAME(makeKernelState(context:));

@end

FOUNDATION_EXPORT BOOL MTIEncodeArgumentsWithEncoder(NSArray<MTLArgument *>* arguments,
                              NSDictionary<NSString *, id> * parameters,
                              id<MTLCommandEncoder> encoder,
                              MTLFunctionType functionType,
                              NSError * _Nullable __autoreleasing *inOutError);
NS_ASSUME_NONNULL_END
