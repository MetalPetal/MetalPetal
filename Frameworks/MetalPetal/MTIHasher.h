//
//  MTIHasher.h
//  MetalPetal
//
//  Created by Yu Ao on 2019/1/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

struct MTIHasher {
    uint64_t _seed;
    BOOL _finalized;
};
typedef struct MTIHasher MTIHasher;

static inline MTIHasher MTIHasherMake(NSUInteger seed) {
    //MTIHasher is designed to work on 64-bit systems.
    assert(sizeof(NSUInteger) == 8);
    return (MTIHasher){._seed = seed, ._finalized = NO};
}

static inline __attribute__((__overloadable__)) void MTIHasherCombine(MTIHasher *hasher, uint64_t value) {
    //Ref boost::hash_combine
    //Ref https://stackoverflow.com/questions/4948780/magic-number-in-boosthash-combine
    hasher -> _seed ^= value + 0x9e3779b97f4a7c15 + (hasher -> _seed << 6) + (hasher -> _seed >> 2);
}

static inline __attribute__((__overloadable__)) void MTIHasherCombine(MTIHasher *hasher, unsigned int intValue) {
    uint64_t value = intValue;
    MTIHasherCombine(hasher, value);
}

static inline __attribute__((__overloadable__)) void MTIHasherCombine(MTIHasher *hasher, unsigned long intValue) {
    uint64_t value = intValue;
    MTIHasherCombine(hasher, value);
}

static inline __attribute__((__overloadable__)) void MTIHasherCombine(MTIHasher *hasher, double doubleValue) {
    //in .m file: static_assert(sizeof(uint64_t) == sizeof(double), "") 
    uint64_t value = *(uint64_t *)&doubleValue;
    MTIHasherCombine(hasher, value);
}

static inline __attribute__((__overloadable__)) void MTIHasherCombine(MTIHasher *hasher, float floatValue) {
    double doubleValue = floatValue;
    MTIHasherCombine(hasher, doubleValue);
}

static inline __attribute__((__overloadable__)) NSUInteger MTIHasherFinalize(MTIHasher *hasher) {
    NSCParameterAssert(hasher -> _finalized == NO);
    hasher -> _finalized = YES;
    return (NSUInteger)hasher -> _seed;
}

NS_ASSUME_NONNULL_END
