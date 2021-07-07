//
//  AppDelegate.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GlobalData.h"
#import "mainMenu.h"
#import "ECSlidingViewController.h"
#import "CustomNavigationController.h"

@class ViewControllerIPad;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
	NSMutableArray *arrayServerList;
    GlobalData *obj;
}

#define PAD_MENU_HEIGHT 50
#define PAD_MENU_INFO_HEIGHT 18
#define PAD_MENU_TABLE_WIDTH 300

/* UI items are designed for this screen width */
#define IPHONE_SCREEN_DESIGN_WIDTH 320.0
#define IPAD_SCREEN_DESIGN_WIDTH 476.0

#define PHONE_TV_SHOWS_BANNER_HEIGHT 59
#define PHONE_TV_SHOWS_POSTER_HEIGHT 76

#define PHONE_TV_SHOWS_BANNER_WIDTH IPHONE_SCREEN_DESIGN_WIDTH
#define PHONE_TV_SHOWS_POSTER_WIDTH 53

#define PAD_TV_SHOWS_BANNER_HEIGHT 88
#define PAD_TV_SHOWS_POSTER_HEIGHT 76

#define PAD_TV_SHOWS_BANNER_WIDTH IPAD_SCREEN_DESIGN_WIDTH
#define PAD_TV_SHOWS_POSTER_WIDTH 53

+ (AppDelegate*)instance;

- (void)saveServerList;
- (void)clearAppDiskCache;
- (void)sendWOL:(NSString*)MAC withPort:(NSInteger)WOLport;
- (NSURL*)getServerJSONEndPoint;
- (NSDictionary*)getServerHTTPHeaders;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CustomNavigationController *navigationController;

@property (nonatomic, retain) ViewControllerIPad *windowController;

@property (retain, nonatomic) NSString *dataFilePath;
@property (retain, nonatomic) NSString *libraryCachePath;
@property (retain, nonatomic) NSString *epgCachePath;

@property (nonatomic, retain) NSMutableArray *arrayServerList;

@property (nonatomic, retain) mainMenu *playlistArtistAlbums;
@property (nonatomic, retain) mainMenu *playlistMovies;
@property (nonatomic, retain) mainMenu *playlistTvShows;
@property (nonatomic, retain) mainMenu *xbmcSettings;
@property (nonatomic, retain) NSMutableArray *rightMenuItems;
@property (nonatomic, retain) NSMutableArray *nowPlayingMenuItems;
@property (nonatomic, retain) NSMutableArray *remoteControlMenuItems;
@property (nonatomic, assign) BOOL serverOnLine;
@property (nonatomic, assign) BOOL serverTCPConnectionOpen;
@property (nonatomic, assign) int serverVersion;
@property (nonatomic, assign) int serverMinorVersion;
@property (nonatomic, assign) int serverVolume;
@property (retain, nonatomic) NSString *serverName;
@property (nonatomic, assign) int APImajorVersion;
@property (nonatomic, assign) int APIminorVersion;
@property (nonatomic, assign) int APIpatchVersion;
@property (nonatomic, assign) BOOL isIgnoreArticlesEnabled;
@property (nonatomic, assign) BOOL isGroupSingleItemSetsEnabled;
@property (nonatomic, copy) NSArray *KodiSorttokens;
@property (nonatomic, retain) GlobalData *obj;

@end
