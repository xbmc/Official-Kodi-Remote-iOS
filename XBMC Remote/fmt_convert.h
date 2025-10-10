//
//  fmt_convert.h
//  Kodi Remote
//
//  Created by Buschmann on 14.11.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

@interface NSString (fmt)

+ (NSString*)fmtFormatted:(NSString*)format defaultFormat:(NSString*)defaultFormat intValue:(int)value;
+ (NSString*)fmtFormatted:(NSString*)format defaultFormat:(NSString*)defaultFormat floatValue:(float)value;

@end

