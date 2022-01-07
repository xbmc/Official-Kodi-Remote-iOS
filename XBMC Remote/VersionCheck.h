//
//  VersionCheck.h
//  Kodi Remote
//
//  Created by Andree Buschmann on 13.10.22.
//  Copyright © 2022 Team Kodi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

typedef enum {
    earlierThan,
    earlierOrSameAs,
    sameAs,
    laterOrSameAs,
    laterThan
} VersionComparisonType;

@interface VersionCheck : NSObject

+ (BOOL)isAPIVersion:(VersionComparisonType)compare version:(NSString*)targetVersion;
+ (BOOL)isKodiVersion:(VersionComparisonType)compare version:(NSString*)targetVersion;
+ (BOOL)hasRecordingIdPlaylistSupport;

@end
