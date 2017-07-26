//
//  MTIPrint.h
//  Pods
//
//  Created by YuAo on 26/07/2017.
//
//

#import <Foundation/Foundation.h>

#if !defined(MTIPrint)

#if DEBUG

#define MTIPrint(format, ...) do { \
    if (getenv("MTI_PRINT_ENABLED") != NULL) {\
        NSLog(format, ##__VA_ARGS__); \
    }\
} while(0)

#else

#define MTIPrint(format, ...) do { } while(0)

#endif

#endif
