//
//  MTIFilterFunctionDescriptor.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTIFunctionDescriptor : NSObject <NSCopying>

@property (nonatomic, copy, readonly, nullable) NSURL *libraryURL;

@property (nonatomic, copy, readonly) NSString *name;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithName:(NSString *)name;

- (instancetype)initWithName:(NSString *)name libraryURL:( NSURL * _Nullable )URL NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
