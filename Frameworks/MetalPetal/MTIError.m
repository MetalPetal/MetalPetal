//
//  MTIError.m
//  Pods
//
//  Created by YuAo on 10/08/2017.
//
//

#import "MTIError.h"

NSString * const MTIErrorDomain = @"MTIErrorDomain";

NSError * _MTIErrorCreate(MTIError code, NSString *defaultDescription, NSDictionary *userInfo) {
    if (userInfo[NSLocalizedDescriptionKey] == nil) {
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:userInfo];
        info[NSLocalizedDescriptionKey] = defaultDescription;
        return [NSError errorWithDomain:MTIErrorDomain code:code userInfo:info];
    } else {
        return [NSError errorWithDomain:MTIErrorDomain code:code userInfo:userInfo];
    }
}
