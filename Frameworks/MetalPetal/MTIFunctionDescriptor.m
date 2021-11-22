//
//  MTIFilterFunctionDescriptor.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIFunctionDescriptor.h"
#import "MTIHasher.h"

@interface MTIFunctionDescriptor ()

@property (nonatomic, readonly) NSUInteger cachedHashValue;

@end

@implementation MTIFunctionDescriptor

- (instancetype)initWithName:(NSString *)name {
    return [self initWithName:name libraryURL:nil];
}

- (instancetype)initWithName:(NSString *)name libraryURL:( NSURL * _Nullable )URL {
    return [self initWithName:name constantValues:nil libraryURL:URL];
}

- (instancetype)initWithName:(NSString *)name constantValues:(MTLFunctionConstantValues *)constantValues libraryURL:(NSURL *)URL {
    if (self = [super init]) {
        _name = [name copy];
        _libraryURL = [URL copy];
        _constantValues = [constantValues copy];
        
        MTIHasher hasher = MTIHasherMake(0);
        MTIHasherCombine(&hasher, _name.hash);
        MTIHasherCombine(&hasher, _libraryURL.hash);
        MTIHasherCombine(&hasher, _constantValues.hash);
        _cachedHashValue = MTIHasherFinalize(&hasher);
    }
    return self;
}

- (MTIFunctionDescriptor *)functionDescriptorWithConstantValues:(MTLFunctionConstantValues *)constantValues {
    return [[MTIFunctionDescriptor alloc] initWithName:_name constantValues:constantValues libraryURL:_libraryURL];
}

- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    
    if (![object isKindOfClass:[MTIFunctionDescriptor class]]) {
        return NO;
    }
    
    MTIFunctionDescriptor *descriptor = object;
    if (
        [descriptor -> _name isEqualToString:_name] &&
        ((descriptor -> _libraryURL == nil && _libraryURL == nil) || [descriptor -> _libraryURL isEqual:_libraryURL]) &&
        ((descriptor -> _constantValues == nil && _constantValues == nil) || [descriptor -> _constantValues isEqual:_constantValues])
    ) {
        return YES;
    } else {
        return NO;
    }
}

- (NSUInteger)hash {
    return _cachedHashValue;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; name = %@; constantValues = %@; libraryURL = %@>",self.class, self, self.name, self.constantValues, self.libraryURL];
}

@end
