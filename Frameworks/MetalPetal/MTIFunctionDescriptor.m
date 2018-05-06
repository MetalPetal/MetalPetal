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
        _constantValues = nil;
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name constantValues:(MTLFunctionConstantValues *)constantValues libraryURL:(NSURL *)URL {
    if (self = [super init]) {
        _name = [name copy];
        _libraryURL = [URL copy];
        _constantValues = [constantValues copy];
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
    if ([descriptor.name isEqualToString:self.name] &&
        ((descriptor.libraryURL == nil && self.libraryURL == nil) || [descriptor.libraryURL isEqual:self.libraryURL])) {
        if (@available(iOS 10.0, *)) {
            if ((descriptor.constantValues == nil && self.constantValues == nil) || [descriptor.constantValues isEqual:self.constantValues]) {
                return YES;
            } else {
                return NO;
            }
        } else {
            return YES;
        }
    } else {
        return NO;
    }
}

- (NSUInteger)hash {
    if (@available(iOS 10.0, *)) {
        return self.name.hash ^ self.libraryURL.hash ^ self.constantValues.hash;
    } else {
        return self.name.hash ^ self.libraryURL.hash;
    }
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSString *)description {
    if (@available(iOS 10_0, *)) {
        return [NSString stringWithFormat:@"<%@: %p; name = %@; constantValues = %@; libraryURL = %@>",self.class, self, self.name, self.constantValues, self.libraryURL];
    } else {
        return [NSString stringWithFormat:@"<%@: %p; name = %@; libraryURL = %@>",self.class, self, self.name, self.libraryURL];
    }
}

@end
