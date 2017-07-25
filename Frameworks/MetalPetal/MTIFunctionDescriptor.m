//
//  MTIFilterFunctionDescriptor.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIFunctionDescriptor.h"

@interface MTIFunctionDescriptor ()

@end

@implementation MTIFunctionDescriptor

- (instancetype)initWithName:(NSString *)name {
    return [self initWithName:name libraryURL:nil];
}

- (instancetype)initWithName:(NSString *)name libraryURL:( NSURL * _Nullable )URL {
    if (self = [super init]) {
        _name = name;
        _libraryURL = [URL copy];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    if (![object isKindOfClass:[MTIFunctionDescriptor class]]) {
        return NO;
    }
    MTIFunctionDescriptor *descriptor = object;
    if ([descriptor.name isEqualToString:self.name] && ((descriptor.libraryURL == nil && self.libraryURL == nil) || [descriptor.libraryURL isEqual:self.libraryURL])) {
        return YES;
    } else {
        return NO;
    }
}

- (NSUInteger)hash {
    return self.name.hash ^ self.libraryURL.hash;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
