//
//  MTIFilterFunctionDescriptor.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIFilterFunctionDescriptor.h"

@implementation MTIFilterFunctionDescriptor

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

@end
