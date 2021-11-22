//
//  MTIFilterFunctionDescriptor.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIFunctionDescriptor : NSObject <NSCopying>

@property (nonatomic, copy, readonly, nullable) NSURL *libraryURL;

@property (nonatomic, copy, readonly) NSString *name;

@property (nonatomic, copy, readonly, nullable) MTLFunctionConstantValues *constantValues;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithName:(NSString *)name;

- (instancetype)initWithName:(NSString *)name libraryURL:(nullable NSURL *)URL;

- (instancetype)initWithName:(NSString *)name constantValues:(nullable MTLFunctionConstantValues *)constantValues libraryURL:(nullable NSURL *)URL NS_DESIGNATED_INITIALIZER;

- (MTIFunctionDescriptor *)functionDescriptorWithConstantValues:(nullable MTLFunctionConstantValues *)constantValues;

@end

NS_ASSUME_NONNULL_END
