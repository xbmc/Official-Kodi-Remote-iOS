//
//  AppDelegate.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import "AppDelegate.h"
#import "mainMenu.h"
#import "MasterViewController.h"

@implementation AppDelegate

NSMutableArray *mainMenuItems;

@synthesize window = _window;
@synthesize navigationController = _navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

    MasterViewController *masterViewController = [[MasterViewController alloc] initWithNibName:@"MasterViewController" bundle:nil];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    mainMenuItems = [NSMutableArray arrayWithCapacity:1];
    mainMenu *item1 = [[mainMenu alloc] init];
    mainMenu *item2 = [[mainMenu alloc] init];
    mainMenu *item3 = [[mainMenu alloc] init];
    mainMenu *item4 = [[mainMenu alloc] init];
    mainMenu *item5 = [[mainMenu alloc] init];
    mainMenu *item6 = [[mainMenu alloc] init];
    
    item1.mainLabel = @"Music";
    item1.upperLabel = @"Listen to";
    item1.icon = @"icon_home_music.png";
    
    item2.mainLabel = @"Movies";
    item2.upperLabel = @"Watch your";
    item2.icon = @"icon_home_movie.png";
    
    item3.mainLabel = @"TV Shows";
    item3.upperLabel = @"Watch your";
    item3.icon = @"icon_home_tv.png";
    
    item4.mainLabel = @"Pictures";
    item4.upperLabel = @"Browse your";
    item4.icon = @"icon_home_picture.png";
    
    item5.mainLabel = @"Now Playing";
    item5.upperLabel = @"See what's";
    item5.icon = @"icon_home_playing.png";
    
    item6.mainLabel = @"Remote Control";
    item6.upperLabel = @"Use as";
    item6.icon = @"icon_home_remote.png";
    
    [mainMenuItems addObject:item1];
    [mainMenuItems addObject:item2];
    [mainMenuItems addObject:item3];
    [mainMenuItems addObject:item4];
    [mainMenuItems addObject:item5];
    [mainMenuItems addObject:item6];
    masterViewController.mainMenu =mainMenuItems;
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
