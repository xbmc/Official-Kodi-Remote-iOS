//
//  fmt_convert.m
//  Kodi Remote
//
//  Created by Buschmann on 14.11.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "fmt_convert.h"

#include <fmt/core.h>
#include <string>

@implementation NSString (fmt)

+ (NSString*)fmtFormatted:(NSString*)format defaultFormat:(NSString*)defaultFormat intValue:(int)value {
    try {
        const std::string formatted = fmt::format(format.UTF8String, value);
        // not sure if `length` param should be +1 to account for the terminating 0-character
        return [[NSString alloc] initWithBytes:formatted.data() length:formatted.size() encoding:NSUTF8StringEncoding];
    }
    catch (const std::exception &exc) {
        NSLog(@"generic format error: %s", exc.what());
    }
    return [NSString stringWithFormat:defaultFormat, value];
}

+ (NSString*)fmtFormatted:(NSString*)format defaultFormat:(NSString*)defaultFormat floatValue:(float)value {
    try {
        const std::string formatted = fmt::format(format.UTF8String, value);
        // not sure if `length` param should be +1 to account for the terminating 0-character
        return [[NSString alloc] initWithBytes:formatted.data() length:formatted.size() encoding:NSUTF8StringEncoding];
    }
    catch (const std::exception &exc) {
        NSLog(@"generic format error: %s", exc.what());
    }
    return [NSString stringWithFormat:defaultFormat, value];
}

@end
