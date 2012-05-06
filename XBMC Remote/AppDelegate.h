//
//  AppDelegate.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ViewControllerIPad;


@interface AppDelegate : UIResponder <UIApplicationDelegate>{
    NSString *dataFilePath;
	NSMutableArray *arrayServerList;
    NSFileManager *fileManager;
	NSString *documentsDir;
}

+ (AppDelegate *) instance;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UINavigationController *navigationController;

@property (nonatomic, retain) ViewControllerIPad *windowController;


@property (retain, nonatomic) NSString *dataFilePath;

@property (nonatomic, retain) NSMutableArray *arrayServerList;

@property (retain, nonatomic) NSFileManager *fileManager;

@property (retain, nonatomic) NSString *documentsDir;

-(void)saveServerList;

@end
