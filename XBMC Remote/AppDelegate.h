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

#define PHONE_MENU_HEIGHT 50
#define PHONE_MENU_INFO_HEIGHT 44
#define PAD_MENU_HEIGHT 50
#define PAD_MENU_TABLE_WIDTH 300

/* UI items are designed for this screen width */
#define IPHONE_SCREEN_DESIGN_HEIGHT 568.0
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
- (void)triggerLocalNetworkPrivacyAlert;
- (void)sendWOL:(NSString*)MAC withPort:(NSInteger)WOLport;
- (NSURL*)getServerJSONEndPoint;
- (NSDictionary*)getServerHTTPHeaders;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CustomNavigationController *navigationController;

@property (nonatomic, strong) ViewControllerIPad *windowController;

@property (strong, nonatomic) NSString *dataFilePath;
@property (strong, nonatomic) NSString *libraryCachePath;
@property (strong, nonatomic) NSString *epgCachePath;

@property (nonatomic, strong) NSMutableArray *arrayServerList;

@property (nonatomic, strong) mainMenu *playlistArtistAlbums;
@property (nonatomic, strong) mainMenu *playlistMovies;
@property (nonatomic, strong) mainMenu *playlistMusicVideos;
@property (nonatomic, strong) mainMenu *playlistTvShows;
@property (nonatomic, strong) mainMenu *playlistPVR;
@property (nonatomic, strong) mainMenu *xbmcSettings;
@property (nonatomic, strong) NSMutableArray *rightMenuItems;
@property (nonatomic, strong) NSMutableArray *nowPlayingMenuItems;
@property (nonatomic, strong) NSMutableArray *remoteControlMenuItems;
@property (nonatomic, assign) BOOL serverOnLine;
@property (nonatomic, assign) BOOL serverTCPConnectionOpen;
@property (nonatomic, assign) int serverVersion;
@property (nonatomic, assign) int serverMinorVersion;
@property (nonatomic, assign) int serverVolume;
@property (strong, nonatomic) NSString *serverName;
@property (nonatomic, assign) int APImajorVersion;
@property (nonatomic, assign) int APIminorVersion;
@property (nonatomic, assign) int APIpatchVersion;
@property (nonatomic, assign) BOOL isIgnoreArticlesEnabled;
@property (nonatomic, assign) BOOL isGroupSingleItemSetsEnabled;
@property (nonatomic, copy) NSArray *KodiSorttokens;
@property (nonatomic, strong) GlobalData *obj;

@end
