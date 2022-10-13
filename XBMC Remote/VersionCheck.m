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

+ (BOOL)hasRecordingIdPlaylistSupport {
    // Since API 12.7.0 Kodi server can handle Playlist.Insert and Playlist.Add for recordingid.
    return (AppDelegate.instance.APImajorVersion == 12 && AppDelegate.instance.APIminorVersion >= 7) || AppDelegate.instance.APImajorVersion > 12;
}

@end
