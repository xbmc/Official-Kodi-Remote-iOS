//
//  VersionCheck.h
//  Kodi Remote
//
//  Created by Andree Buschmann on 13.10.22.
//  Copyright © 2022 Team Kodi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

@interface VersionCheck : NSObject

+ (BOOL)hasRecordingIdPlaylistSupport;
+ (BOOL)hasGroupSingleItemSetsSupport;
+ (BOOL)hasSortTokenReadSupport;
+ (BOOL)hasPvrSortSupport;

@end
