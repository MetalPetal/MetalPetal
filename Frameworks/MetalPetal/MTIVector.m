//
//  MTIVector.m
//  Pods
//
//  Created by yi chen on 2017/7/25.
//
//

#import "MTIVector.h"

@interface MTIVector ()

@property (nonatomic, copy, readonly) NSData *data;

@end

@implementation MTIVector

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)initWithIntValues:(const int *)values count:(NSUInteger)count {
    if (self = [super init]) {
        NSParameterAssert(values);
        NSParameterAssert(count > 0);
        _count = count;
        _data = [NSData dataWithBytes:values length:count * sizeof(int)];
        _scalarType = MTIVectorScalarTypeInt;
    }
    return self;
}

- (instancetype)initWithFloatValues:(const float *)values count:(NSUInteger)count {
    if (self = [super init]) {
        NSParameterAssert(values);
        NSParameterAssert(count > 0);
        _count = count;
        _data = [NSData dataWithBytes:values length:count * sizeof(float)];
        _scalarType = MTIVectorScalarTypeFloat;
    }
    return self;
}

- (instancetype)initWithUIntValues:(const uint *)values count:(NSUInteger)count {
    if (self = [super init]) {
        NSParameterAssert(values);
        NSParameterAssert(count > 0);
        _count = count;
        _data = [NSData dataWithBytes:values length:count * sizeof(uint)];
        _scalarType = MTIVectorScalarTypeUInt;
    }
    return self;
}

+ (instancetype)vectorWithFloatValues:(const float *)values count:(NSUInteger)count {
    return [[MTIVector alloc] initWithFloatValues:values count:count];
}

+ (instancetype)vectorWithIntValues:(const int *)values count:(NSUInteger)count {
    return [[MTIVector alloc] initWithIntValues:values count:count];
}

+ (instancetype)vectorWithUIntValues:(const uint *)values count:(NSUInteger)count {
    return [[MTIVector alloc] initWithUIntValues:values count:count];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    NSData *data = [coder decodeObjectOfClass:[NSData class] forKey:@"data"];
    NSNumber *scalarTypeValue = [coder decodeObjectOfClass:[NSNumber class] forKey:@"scalarType"];
    if (data == nil || scalarTypeValue == nil) {
        return nil;
    }
    switch ([scalarTypeValue integerValue]) {
        case MTIVectorScalarTypeFloat:
            return [self initWithFloatValues:data.bytes count:data.length/sizeof(float)];
        case MTIVectorScalarTypeInt:
            return [self initWithIntValues:data.bytes count:data.length/sizeof(int)];
        case MTIVectorScalarTypeUInt:
            return [self initWithUIntValues:data.bytes count:data.length/sizeof(uint)];
        default:
            return nil;
    }
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_data forKey:@"data"];
    [coder encodeObject:@(_scalarType) forKey:@"scalarType"];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSUInteger)hash {
    return _data.hash;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[MTIVector class]]) {
        MTIVector *other = object;
        if (self.count != other.count) {
            return NO;
        }
        return [_data isEqual:other -> _data];
    } else {
        return NO;
    }
}

+ (instancetype)vectorWithX:(float)X Y:(float)Y {
    float values[2] = {X, Y};
    return [[self alloc] initWithFloatValues:values count:2];
}

+ (instancetype)vectorWithCGPoint:(CGPoint)p {
    float values[2] = {(float)p.x, (float)p.y};
    return [[self alloc] initWithFloatValues:values count:2];
}

- (CGPoint)CGPointValue {
    if (self.count == 2 && self.scalarType == MTIVectorScalarTypeFloat) {
        const float * bytes = self.bytes;
        return CGPointMake(bytes[0], bytes[1]);
    }
    return CGPointZero;
}

+ (instancetype)vectorWithCGSize:(CGSize)s {
    float values[2] = {(float)s.width, (float)s.height};
    return [[self alloc] initWithFloatValues:values count:2];
}

- (CGSize)CGSizeValue {
    if (self.count == 2 && self.scalarType == MTIVectorScalarTypeFloat) {
        const float * bytes = self.bytes;
        return CGSizeMake(bytes[0], bytes[1]);
    }
    return CGSizeZero;
}

+ (instancetype)vectorWithCGRect:(CGRect)r {
    float values[4] = {(float)r.origin.x, (float)r.origin.y, (float)r.size.width, (float)r.size.height};
    return [[self alloc] initWithFloatValues:values count:4];
}

- (CGRect)CGRectValue {
    if (self.count == 4 && self.scalarType == MTIVectorScalarTypeFloat) {
        const float * bytes = self.bytes;
        return CGRectMake(bytes[0], bytes[1], bytes[2], bytes[3]);
    }
    return CGRectZero;
}

@end

@implementation MTIVector (Contents)

- (NSUInteger)byteLength {
    return _data.length;
}

- (const void *)bytes {
    return _data.bytes;
}

@end
