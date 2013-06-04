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

@class ViewControllerIPad;

@interface AppDelegate : UIResponder <UIApplicationDelegate>{
	NSMutableArray *arrayServerList;
    GlobalData *obj;
}

/*
 *  System Versioning Preprocessor Macros
 */

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


+ (AppDelegate *) instance;

-(void)saveServerList;
-(void)clearAppDiskCache;
-(void)wake:(NSString *)macAddress;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UINavigationController *navigationController;

@property (nonatomic, retain) ViewControllerIPad *windowController;

@property (retain, nonatomic) NSString *dataFilePath;
@property (retain, nonatomic) NSString *libraryCachePath;

@property (nonatomic, retain) NSMutableArray *arrayServerList;

@property (nonatomic, retain) mainMenu *playlistArtistAlbums;
@property (nonatomic, retain) mainMenu *playlistMovies;
@property (nonatomic, retain) mainMenu *playlistTvShows;
@property (nonatomic, retain) NSMutableArray *rightMenuItems;
@property (nonatomic, retain) NSMutableArray *nowPlayingMenuItems;
@property (nonatomic, retain) NSMutableArray *remoteControlMenuItems;
@property (nonatomic, assign) BOOL serverOnLine;
@property (nonatomic, assign) BOOL serverTCPConnectionOpen;
@property (nonatomic, assign) int serverVersion;
@property (nonatomic, assign) int serverMinorVersion;
@property (nonatomic, assign) int serverVolume;
@property (retain, nonatomic) NSString *serverName;
@property (nonatomic, retain) GlobalData *obj;

@end
