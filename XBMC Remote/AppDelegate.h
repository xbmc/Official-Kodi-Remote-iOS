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
    NSMutableArray *mainMenuItems;
    NSMutableArray *arrayServerList;
    GlobalData *obj;
}

#define PHONE_MENU_HEIGHT 50
#define PHONE_MENU_INFO_HEIGHT 44
#define PAD_MENU_HEIGHT 50
#define PAD_MENU_TABLE_WIDTH 300
#define PAD_REMOTE_WIDTH (MIN(GET_MAINSCREEN_HEIGHT, GET_MAINSCREEN_WIDTH) / 2)

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

/* UI layout constants */
#define FILEMODE_ROW_HEIGHT 44
#define FILEMODE_THUMB_WIDTH 44

#define LIVETV_ROW_HEIGHT 76
#define LIVETV_THUMB_WIDTH 64
#define LIVETV_THUMB_WIDTH_SMALL 48
#define CHANNEL_EPG_ROW_HEIGHT 82

#define DEFAULT_ROW_HEIGHT 53
#define DEFAULT_THUMB_WIDTH 53
#define PORTRAIT_ROW_HEIGHT 76

#define SETTINGS_ROW_HEIGHT 65
#define SETTINGS_THUMB_WIDTH_BIG 65
#define SETTINGS_THUMB_WIDTH 44

#define EPISODE_THUMB_WIDTH 95

#define FULLSCREEN_LABEL_HEIGHT 20

/* Global definition for player id */
#define PLAYERID_UNKNOWN -1
#define PLAYERID_MUSIC 0
#define PLAYERID_VIDEO 1
#define PLAYERID_PICTURES 2

/* Global definition of view tags */
#define XIB_MAIN_MENU_CELL_ICON 1
#define XIB_MAIN_MENU_CELL_TITLE 3
#define XIB_MAIN_MENU_CELL_ARROW_RIGHT 5
#define SHARED_CELL_ACTIVTYINDICATOR 8
#define SHARED_CELL_RECORDING_ICON 104

#define WOL_PORT 9

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
@property (nonatomic, strong) NSArray *globalSearchMenuLookup;
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
