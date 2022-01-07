//
//  VersionCheck.m
//  Kodi Remote
//
//  Created by Andree Buschmann on 13.10.22.
//  Copyright © 2022 Team Kodi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import "VersionCheck.h"

@implementation VersionCheck

+ (BOOL)evaluateComparisonRequest:(VersionComparisonType)compare againstComparison:(NSComparisonResult)comparison {
    BOOL result;
    switch (compare) {
        case earlierThan:
            result = comparison == NSOrderedAscending;
            break;
        case earlierOrSameAs:
            result = comparison != NSOrderedDescending;
            break;
        case sameAs:
            result = comparison == NSOrderedSame;
            break;
        case laterOrSameAs:
            result = comparison != NSOrderedAscending;
            break;
        case laterThan:
            result = comparison == NSOrderedDescending;
            break;
        default:
            NSAssert(NO, @"evaluateComparisonRequest: unknown comparison mode %d", compare);
            break;
    }
    return result;
}

+ (BOOL)compareVersion:(int)major minor:(int)minor patch:(int)patch compare:(VersionComparisonType)compare targetVersion:(NSString*)targetVersion {
    NSUInteger num = [targetVersion componentsSeparatedByString:@"."].count;
    NSString *systemVersion = @"";
    switch (num) {
        case 3:
            systemVersion = [NSString stringWithFormat:@".%d", patch];
        case 2:
            systemVersion = [NSString stringWithFormat:@".%d%@", minor, systemVersion];
        case 1:
            systemVersion = [NSString stringWithFormat:@"%d%@", major, systemVersion];
            break;
        default:
            NSAssert(NO, @"compareVersion: called with non supported version string.");
        break;
    }
    NSComparisonResult comparisonResult = [systemVersion compare:targetVersion options:NSNumericSearch];
    return [VersionCheck evaluateComparisonRequest:compare againstComparison:comparisonResult];
}

+ (BOOL)isAPIVersion:(VersionComparisonType)compare version:(NSString*)targetVersion {
    return [self compareVersion:AppDelegate.instance.APImajorVersion
                          minor:AppDelegate.instance.APIminorVersion
                          patch:AppDelegate.instance.APIpatchVersion
                        compare:compare
                  targetVersion:targetVersion];
}

+ (BOOL)isKodiVersion:(VersionComparisonType)compare version:(NSString*)targetVersion {
    return [self compareVersion:AppDelegate.instance.serverVersion
                          minor:AppDelegate.instance.serverMinorVersion
                          patch:0
                        compare:compare
                  targetVersion:targetVersion];
}

+ (BOOL)hasRecordingIdPlaylistSupport {
    // Since API 12.7.0 Kodi server can handle Playlist.Insert and Playlist.Add for recordingid.
    return (AppDelegate.instance.APImajorVersion == 12 && AppDelegate.instance.APIminorVersion >= 7) || AppDelegate.instance.APImajorVersion > 12;
}

@end
