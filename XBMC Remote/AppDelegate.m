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
//#import "GlobalData.h"

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
    
//    GlobalData *obj=[GlobalData getInstance];  
//    
//    obj.serverDescription=@"joeHTPC";
//    obj.serverUser=@"xbmc";
//    obj.serverPass=@"";
//    obj.serverIP= @"10.10.32.16";
//    obj.serverPort=@"8080";
    
    mainMenuItems = [NSMutableArray arrayWithCapacity:1];
    mainMenu *item1 = [[mainMenu alloc] init];
    mainMenu *item2 = [[mainMenu alloc] init];
    mainMenu *item3 = [[mainMenu alloc] init];
    mainMenu *item4 = [[mainMenu alloc] init];
    mainMenu *item5 = [[mainMenu alloc] init];
    mainMenu *item6 = [[mainMenu alloc] init];
    
    item1.subItem = [[mainMenu alloc] init];
    item3.subItem = [[mainMenu alloc] init];
    item3.subItem.subItem = [[mainMenu alloc] init];

    
    item1.mainLabel = @"Music";
    item1.upperLabel = @"Listen to";
    item1.icon = @"icon_home_music.png";
    item1.family = 1;
    item1.enableSection=YES;
    item1.mainMethod=[NSArray arrayWithObjects:@"AudioLibrary.GetAlbums", @"method", nil];
    
    item1.mainParameters=[NSMutableArray arrayWithObjects:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                          [NSDictionary dictionaryWithObjectsAndKeys:
                           @"ascending",@"order",
                           [NSNumber numberWithBool:FALSE],@"ignorearticle",
                           @"label", @"method",
                           nil],@"sort",
                          [NSArray arrayWithObjects:@"year", @"thumbnail", @"artist", nil], @"properties",
                          nil], @"parameters", @"Albums", @"label", nil];
    
    item1.mainFields=[NSDictionary  dictionaryWithObjectsAndKeys:
                      @"albums",@"itemid",
                      @"label", @"row1",
                      @"artist", @"row2",
                      @"year", @"row3",
                      @"runtime", @"row4",
                      @"rating",@"row5",
                      @"albumid",@"row6",
                      [NSNumber numberWithInt:0], @"playlistid",
                      @"albumid",@"row8",
                      @"albumid", @"row9",
                      nil];
    item1.rowHeight=53;
    item1.thumbWidth=53;
    item1.defaultThumb=@"nocover_music.png";
    item1.sheetActions=[NSArray arrayWithObjects:@"Queue", @"Play", nil];
//    
    item1.subItem.mainMethod=[NSArray arrayWithObjects:@"AudioLibrary.GetSongs", @"method", nil]; 
    item1.subItem.mainParameters=[NSMutableArray arrayWithObjects:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                          [NSDictionary dictionaryWithObjectsAndKeys:
                           @"ascending",@"order",
                           [NSNumber numberWithBool:FALSE],@"ignorearticle",
                           @"track", @"method",
                           nil],@"sort",
                          [NSArray arrayWithObjects:@"genre", @"year", @"duration", @"track", @"thumbnail", @"rating", @"playcount", @"artist", @"albumid", @"file", nil], @"properties",
                          nil], @"parameters", @"Songs", @"label", nil];
    item1.subItem.mainFields=[NSDictionary  dictionaryWithObjectsAndKeys:
                         @"songs",@"itemid",
                         @"label", @"row1",
                         @"artist", @"row2",
                         @"year", @"row3",
                         @"duration", @"row4",
                         @"rating",@"row5",
                         @"songid",@"row6",
                         @"track",@"row7",
                         @"albumid",@"row8",
                         [NSNumber numberWithInt:0], @"playlistid",
                         @"songid", @"row9",
                         @"file", @"row10",

                         nil];
    item1.subItem.enableSection=NO;
    item1.subItem.rowHeight=53;
    item1.subItem.thumbWidth=53;
    item1.subItem.defaultThumb=@"nocover_music.png";
    item1.subItem.sheetActions=[NSArray arrayWithObjects: @"Queue", @"Play", nil];//, @"Stream to iPhone"
    item1.subItem.originYearDuration=248;
    item1.subItem.widthLabel=252;
    item1.subItem.showRuntime=YES;

   // item1.subItem.subItem=[[mainMenu alloc] init];
    //item1.subItem.subItem=subItem1;

    item2.mainLabel = @"Movies";
    item2.upperLabel = @"Watch your";
    item2.icon = @"icon_home_movie.png";
    item2.family = 1;
    item2.enableSection=YES;
    item2.mainMethod=[NSArray arrayWithObjects:@"VideoLibrary.GetMovies", @"method", nil];
    item2.mainParameters=[NSMutableArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                          [NSDictionary dictionaryWithObjectsAndKeys:
                           @"ascending",@"order",
                           [NSNumber numberWithBool:FALSE],@"ignorearticle",
                           @"label", @"method",
                           nil],@"sort",
                          
                          [NSArray arrayWithObjects:@"year", @"playcount", @"rating", @"thumbnail", @"genre", @"runtime", @"studio", @"director", @"plot", @"mpaa", @"votes", @"cast", @"file", nil], @"properties",
                          nil], @"parameters", @"Movies", @"label", nil];
//    ["trailer","file","imdbnumber","mpaa","thumbnail","fanart","director","studio","genre","plot","runtime","playcount","rating","year","streamdetails","lastplayed","sorttitle","set","setid"]
    item2.mainFields=[NSDictionary dictionaryWithObjectsAndKeys:
                      @"movies",@"itemid",
                      @"label", @"row1",
                      @"genre", @"row2",
                      @"year", @"row3",
                      @"runtime", @"row4",
                      @"rating",@"row5",
                      @"movieid",@"row6",
                      [NSNumber numberWithInt:1], @"playlistid",
                      @"movieid",@"row8",
                      @"movieid", @"row9",
                      @"director",@"row10",
                      @"studio",@"row11",
                      @"plot",@"row12",
                      @"mpaa",@"row13",
                      @"votes",@"row14",
                      @"votes",@"row15",
                      @"cast",@"row16",
                      @"file",@"row17",

                      nil];
    item2.rowHeight=76;
    item2.thumbWidth=53;
    item2.defaultThumb=@"nocover_movies.png";
    item2.sheetActions=[NSArray arrayWithObjects:@"Queue", @"Play", nil];
    item2.showInfo = YES;
    
    item3.mainLabel = @"TV Shows";
    item3.upperLabel = @"Watch your";
    item3.icon = @"icon_home_tv.png";
    item3.family = 1;
    item3.enableSection=YES;
    item3.mainMethod=[NSArray arrayWithObjects:@"VideoLibrary.GetTVShows", @"method", nil];
    item3.mainParameters=[NSMutableArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                          [NSDictionary dictionaryWithObjectsAndKeys:
                           @"ascending",@"order",
                           [NSNumber numberWithBool:FALSE],@"ignorearticle",
                           @"label", @"method",
                           nil],@"sort",
                          
                          [NSArray arrayWithObjects:@"year", @"playcount", @"rating", @"thumbnail", @"genre", nil], @"properties",
                          nil], @"parameters", @"TV Shows", @"label", nil];
    item3.mainFields=[NSDictionary dictionaryWithObjectsAndKeys:
                      @"tvshows",@"itemid",
                      @"label", @"row1",
                      @"genre", @"row2",
                      @"year", @"row3",
                      @"runtime", @"row4",
                      @"rating",@"row5",
                      @"tvshowid",@"row6",
                      [NSNumber numberWithInt:2], @"playlistid",

                      nil];
    item3.rowHeight=61;
    item3.thumbWidth=320;
    item3.defaultThumb=@"nocover_tvshows.png";
    item3.originLabel=60;
    
    //{"method":"VideoLibrary.GetSeasons","id":1,"jsonrpc":"2.0","params":{"properties":["season","thumbnail"],"tvshowid":3}}
    
    
    item3.subItem.mainMethod=[NSArray arrayWithObjects:@"VideoLibrary.GetSeasons", @"method", nil]; 
    item3.subItem.mainParameters=[NSMutableArray arrayWithObjects:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                   [NSDictionary dictionaryWithObjectsAndKeys:
                                                                    @"ascending",@"order",
                                                                    [NSNumber numberWithBool:FALSE],@"ignorearticle",
                                                                    @"track", @"method",
                                                                    nil],@"sort",
                                                                   
                                                                   [NSArray arrayWithObjects:@"season", @"thumbnail", @"tvshowid", nil], @"properties",
                                                                   nil], @"parameters", @"Seasons", @"label", nil];
    item3.subItem.mainFields=[NSDictionary  dictionaryWithObjectsAndKeys:
                              @"seasons",@"itemid",
                              @"label", @"row1",
                              @"genre", @"row2",
                              @"year", @"row3",
                              @"duration", @"row4",
                              @"rating",@"row5",
                              @"tvshowid",@"row6",
                              @"track",@"row7",
                              @"season",@"row8",
                              [NSNumber numberWithInt:1], @"playlistid",
                              @"tvshowid", @"row9",
                              @"season",@"row15",
                              nil];
    item3.subItem.enableSection=NO;
    item3.subItem.rowHeight=76;
    item3.subItem.thumbWidth=53;
    item3.subItem.defaultThumb=@"nocover_tvshows_episode.png";
    item3.subItem.widthLabel=252;

//    item3.subItem.sheetActions=[NSArray arrayWithObjects:@"Queue", @"Play", nil];
    
    
    //{"method":"VideoLibrary.GetEpisodes","id":2,"jsonrpc":"2.0","params":{"properties":["episode","plot","thumbnail","fanart","playcount","rating","season","runtime","firstaired"],"tvshowid":3}}
    item3.subItem.subItem.mainMethod=[NSArray arrayWithObjects:@"VideoLibrary.GetEpisodes", @"method", nil]; 
    item3.subItem.subItem.mainParameters=[NSMutableArray arrayWithObjects:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                   [NSDictionary dictionaryWithObjectsAndKeys:
                                                                    @"ascending",@"order",
                                                                    [NSNumber numberWithBool:FALSE],@"ignorearticle",
                                                                    @"episode", @"method",
                                                                    nil],@"sort",
                                                                   [NSArray arrayWithObjects:@"episode", @"thumbnail", @"firstaired", @"runtime", @"plot", @"director", @"writer", @"rating", @"showtitle", @"season", @"cast", @"file", nil], @"properties",
                                                                   nil], @"parameters", @"Episodes", @"label", nil];
    item3.subItem.subItem.mainFields=[NSDictionary  dictionaryWithObjectsAndKeys:
                                      @"episodes",@"itemid",
                                      @"label", @"row1",
                                      @"artist", @"row2",
                                      @"firstaired", @"row3",
                                      @"runtime", @"row4",
                                      @"rating",@"row5",
                                      @"episodeid",@"row6",
                                      @"season",@"row7",
                                      @"episodeid",@"row8",
                                      [NSNumber numberWithInt:1], @"playlistid",
                                      @"episodeid", @"row9",
                                      @"plot", @"row10",
                                      @"director", @"row11",
                                      @"writer", @"row12",
                                      @"firstaired", @"row13",
                                      @"showtitle", @"row14",
                                      @"season",@"row15",
                                      @"cast",@"row16",
                                      @"file",@"row17",


                              nil];
    item3.subItem.subItem.enableSection=NO;
    item3.subItem.subItem.rowHeight=53;
    item3.subItem.subItem.thumbWidth=95;
    item3.subItem.subItem.defaultThumb=@"nocover_tvshows_episode.png";
    item3.subItem.subItem.sheetActions=[NSArray arrayWithObjects:@"Queue", @"Play", nil];
    item3.subItem.subItem.originYearDuration=248;
    item3.subItem.subItem.widthLabel=208;
    item3.subItem.subItem.showRuntime=NO;
    item3.subItem.subItem.noConvertTime=YES;
    item3.subItem.subItem.showInfo=YES;

    item4.mainLabel = @"Pictures";
    item4.upperLabel = @"Browse your";
    item4.icon = @"icon_home_picture.png";
    item4.family = 1;
    item4.enableSection=YES;
    item4.thumbWidth=53;
    item4.defaultThumb=@"jewel_dvd.table.png";

    item5.mainLabel = @"Now playing";
    item5.upperLabel = @"See what's";
    item5.icon = @"icon_home_playing.png";
    item5.family = 2;
    
    item6.mainLabel = @"Remote Control";
    item6.upperLabel = @"Use as";
    item6.icon = @"icon_home_remote.png";
    item6.family = 3;
    
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

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
    
//    NSLog(@"OPS! memory low!!!! ");
}


@end
