//
//  NSString+Extensions.m
//  Kodi Remote
//
//  Created by Buschmann on 05.04.26.
//  Copyright © 2026 Team Kodi. All rights reserved.
//

#import "NSString+Extensions.h"

@import CommonCrypto;

@implementation NSString (Extensions)

- (NSString*)SHA256String {
    const char *utf8chars = [self UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(utf8chars, (CC_LONG)strlen(utf8chars), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x", result[i]];
    }
    return ret;
}

- (NSString*)stripRegEx:(NSString*)regExp {
    // Returns unchanged string, if regExp is nil.
    if (!regExp) {
        return self;
    }
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regExp options:NSRegularExpressionCaseInsensitive error:NULL];
    NSString *textOut = [regex stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:@""];
    return textOut;
}

- (NSString*)stripBBandHTML {
    NSString *textOut = self;
    
    // Strip html, <x>, whereas x is not ""
    textOut = [textOut stripRegEx:@"<[^>]+>"];
    
    // Strip BB code, [x] [/x], whereas x = b,u,i,s,center,left,right,url,img and spaces
    textOut = [textOut stripRegEx:@"\\[/?(b|u|i|s|center|left|right|url|img)\\]"];
    
    // Strip BB code, [x=anything] [/x], whereas x = font,size,color,url and spaces
    textOut = [textOut stripRegEx:@"\\[/?(font|size|color|url)(=[^]]+)?\\]"];
    
    return textOut;
}

@end
