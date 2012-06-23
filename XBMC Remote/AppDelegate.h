//
//  AppDelegate.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GlobalData.h"

@class ViewControllerIPad;

@interface AppDelegate : UIResponder <UIApplicationDelegate>{
    NSString *dataFilePath;
	NSMutableArray *arrayServerList;
    NSFileManager *fileManager;
	NSString *documentsDir;
    GlobalData *obj;
}

+ (AppDelegate *) instance;

-(void)saveServerList;
-(void)wake:(NSString *)macAddress;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UINavigationController *navigationController;

@property (nonatomic, retain) ViewControllerIPad *windowController;

@property (retain, nonatomic) NSString *dataFilePath;

@property (nonatomic, retain) NSMutableArray *arrayServerList;

@property (nonatomic, retain) NSDictionary *playlistArtistAlbums;

@property (retain, nonatomic) NSFileManager *fileManager;

@property (retain, nonatomic) NSString *documentsDir;

@property (nonatomic, assign) BOOL serverOnLine;

@property (nonatomic, assign) int serverVersion;

@property (nonatomic, retain) GlobalData *obj;

@end
