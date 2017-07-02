//
//  MTIKernel.h
//  Pods
//
//  Created by YuAo on 02/07/2017.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MTIContext;

@protocol MTIKernel <NSObject>

- (nullable id)newKernelStateWithContext:(MTIContext *)context error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
