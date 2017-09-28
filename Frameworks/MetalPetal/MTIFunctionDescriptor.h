//
//  MTIFilterFunctionDescriptor.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTIFunctionDescriptor : NSObject <NSCopying>

@property (nonatomic, copy, readonly, nullable) NSURL *libraryURL;

@property (nonatomic, copy, readonly) NSString *name;

@property (nonatomic, copy, readonly, nullable) MTLFunctionConstantValues *constantValues NS_AVAILABLE(10_12, 10_0);

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithName:(NSString *)name;

- (instancetype)initWithName:(NSString *)name libraryURL:(nullable NSURL *)URL NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithName:(NSString *)name constantValues:(nullable MTLFunctionConstantValues *)constantValues libraryURL:(nullable NSURL *)URL NS_AVAILABLE(10_12, 10_0) NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
