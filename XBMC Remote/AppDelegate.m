//
//  AppDelegate.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "AppDelegate.h"
#import "mainMenu.h"
#import "MasterViewController.h"
#import "ViewControllerIPad.h"
#import "SDImageCache.h"
//#import "GlobalData.h"

@implementation AppDelegate

NSMutableArray *mainMenuItems;

@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize windowController = _windowController;
@synthesize dataFilePath;
@synthesize arrayServerList;
@synthesize fileManager;
@synthesize documentsDir;
@synthesize serverOnLine;
//@synthesize 

+ (AppDelegate *) instance {
	return (AppDelegate *) [[UIApplication sharedApplication] delegate];
}

#pragma mark -
#pragma mark init

- (id) init {
	if ((self = [super init])) {
        self.fileManager = [NSFileManager defaultManager];
        NSArray *pathslocal = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
        self.documentsDir = [pathslocal objectAtIndex:0];	
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"serverList_saved.dat"];
        [self setDataFilePath:path];
        NSFileManager *fileManager1 = [NSFileManager defaultManager];
        if([fileManager1 fileExistsAtPath:dataFilePath]) {
//            NSLog(@"File 'serverList_saved.dat' trovato. copio contenuto in memoria...");
            NSMutableArray *tempArray;
            tempArray = [NSKeyedUnarchiver unarchiveObjectWithFile:dataFilePath];
            [self setArrayServerList:tempArray];
        } else {
//            NSLog(@"File 'serverList_saved.dat' non trovato. creo un array vuoto");
            arrayServerList = [[NSMutableArray alloc] init];
        }
    }
	return self;
	
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
//    NSLog(@"PLATFORM %@", [[UIDevice currentDevice] platformString]);
//    NSLog(@"%@", [UIDevice currentDevice].model );
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    BOOL clearCache=[[userDefaults objectForKey:@"clearcache_preference"] boolValue];
    if (clearCache==YES){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *diskCachePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"ImageCache"];
        [[NSFileManager defaultManager] removeItemAtPath:diskCachePath error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }    
	[userDefaults removeObjectForKey:@"clearcache_preference"];
    
    UIApplication *xbmcRemote = [UIApplication sharedApplication];
    if ([[userDefaults objectForKey:@"lockscreen_preference"] boolValue]==YES){
        xbmcRemote.idleTimerDisabled = YES;
    }
    else {
        xbmcRemote.idleTimerDisabled = NO;
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    
    int thumbWidth;
    int tvshowHeight;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        thumbWidth = 320;
        tvshowHeight = 61;        
    } 
    else {
        thumbWidth = 477;
        tvshowHeight = 91;
    }

    [self.window makeKeyAndVisible];
    
    NSString *filemodeRowHeight= @"42";
    NSString *filemodeRowWidth= @"42";

    
    mainMenuItems = [NSMutableArray arrayWithCapacity:1];
    mainMenu *item1 = [[mainMenu alloc] init];
    mainMenu *item2 = [[mainMenu alloc] init];
    mainMenu *item3 = [[mainMenu alloc] init];
    mainMenu *item4 = [[mainMenu alloc] init];
    mainMenu *item5 = [[mainMenu alloc] init];
    mainMenu *item6 = [[mainMenu alloc] init];
    
    //test new branch
    
    
    item1.subItem = [[mainMenu alloc] init];
    item1.subItem.subItem = [[mainMenu alloc] init];

    item2.subItem = [[mainMenu alloc] init];
    item2.subItem.subItem = [[mainMenu alloc] init];

    item3.subItem = [[mainMenu alloc] init];
    item3.subItem.subItem = [[mainMenu alloc] init];

    item4.subItem = [[mainMenu alloc] init];
    item4.subItem.subItem = [[mainMenu alloc] init];


    item1.mainLabel = @"Music";
    item1.upperLabel = @"Listen to";
    item1.icon = @"icon_home_music.png";
    item1.family = 1;
    item1.enableSection=YES;
    item1.mainButtons=[NSArray arrayWithObjects:@"st_album", @"st_artist", @"st_genre", @"st_filemode", nil];//
    
    item1.mainMethod=[NSMutableArray arrayWithObjects:
                      
                      [NSArray arrayWithObjects:@"AudioLibrary.GetAlbums", @"method", nil],
                      
                      [NSArray arrayWithObjects:@"AudioLibrary.GetArtists", @"method", nil],
                      
                      [NSArray arrayWithObjects:@"AudioLibrary.GetGenres", @"method", nil],
                      
                      [NSArray arrayWithObjects:@"Files.GetSources", @"method", nil],
                      
                      [NSArray arrayWithObjects:@"Files.GetDirectory", @"method", nil],

                      nil];
    item1.mainParameters=[NSArray arrayWithObjects:
                          [NSMutableArray arrayWithObjects:
                           [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             @"ascending",@"order",
                             [NSNumber numberWithBool:FALSE],@"ignorearticle",
                             @"label", @"method",
                             nil],@"sort",
                            [NSArray arrayWithObjects:@"year", @"thumbnail", @"artist",  nil], @"properties",//@"genre", @"description", @"albumlabel", @"fanart",
                            nil], @"parameters", @"Albums", @"label", @"Album", @"wikitype", nil], 

                          [NSMutableArray arrayWithObjects:
                           [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             @"ascending",@"order",
                             [NSNumber numberWithBool:FALSE],@"ignorearticle",
                             @"label", @"method",
                             nil],@"sort",
                            [NSArray arrayWithObjects: @"thumbnail", @"genre", nil], @"properties",
                            nil], @"parameters", @"Artists", @"label", @"nocover_artist.png", @"defaultThumb", @"Artist", @"wikitype",nil], 
                          
                          [NSMutableArray arrayWithObjects:
                           [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             @"ascending",@"order",
                             [NSNumber numberWithBool:FALSE],@"ignorearticle",
                             @"label", @"method",
                             nil],@"sort",
                            [NSArray arrayWithObjects: @"thumbnail", nil], @"properties",
                            nil], @"parameters", @"Genres", @"label", @"nocover_genre.png", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeRowWidth, @"thumbWidth", nil],
                          
                          [NSMutableArray arrayWithObjects:
                           [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             @"ascending",@"order",
                             [NSNumber numberWithBool:FALSE],@"ignorearticle",
                             @"label", @"method",
                             nil],@"sort",
                            @"music", @"media",
                            nil], @"parameters", @"Files", @"label", @"nocover_filemode.png", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeRowWidth, @"thumbWidth", nil],
                          
                          [NSMutableArray arrayWithObjects:
                           [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             @"ascending",@"order",
                             [NSNumber numberWithBool:FALSE],@"ignorearticle",
                             @"label", @"method",
                             nil],@"sort",
                            @"programs", @"media",
                            @"special://home/addons", @"directory",
                            [NSArray arrayWithObjects: @"thumbnail", @"title", nil], @"properties",
                            nil], @"parameters", @"Addons", @"label", @"nocover_filemode.png", @"defaultThumb", @"53", @"rowHeight", @"53", @"thumbWidth", nil],
                          
                          nil];
    
    item1.mainFields=[NSArray arrayWithObjects:
                      [NSDictionary  dictionaryWithObjectsAndKeys:
                       @"albums",@"itemid",
                       @"label", @"row1",
                       @"artist", @"row2",
                       @"year", @"row3",
                       @"fanart", @"row4",
                       @"rating",@"row5",
                       @"albumid",@"row6",
                       [NSNumber numberWithInt:0], @"playlistid",
                       @"albumid",@"row8",
                       @"albumid", @"row9",
                    @"artist", @"row10",
                       nil],
//                      
//                      @"genre", @"row11",                       
//                      @"albumlabel", @"row12",
//                      @"description", @"row13",
                      
                      [NSDictionary  dictionaryWithObjectsAndKeys:
                       @"artists",@"itemid",
                       @"label", @"row1",
                       @"genre", @"row2",
                       @"year", @"row3",
                       @"runtime", @"row4",
                       @"rating",@"row5",
                       @"artistid",@"row6",
                       [NSNumber numberWithInt:0], @"playlistid",
                       @"artistid",@"row8",
                       @"artistid", @"row9",
                       nil],
                      
                      [NSDictionary  dictionaryWithObjectsAndKeys:
                       @"genres",@"itemid",
                       @"label", @"row1",
                       @"genre", @"row2",
                       @"year", @"row3",
                       @"runtime", @"row4",
                       @"rating",@"row5",
                       @"genreid",@"row6",
                       [NSNumber numberWithInt:0], @"playlistid",
                       @"genreid",@"row8",
                       @"genreid", @"row9",
                       nil],
  
                      [NSDictionary  dictionaryWithObjectsAndKeys:
                       @"sources",@"itemid",
                       @"label", @"row1",
                       @"year", @"row2",
                       @"year", @"row3",
                       @"runtime", @"row4",
                       @"rating",@"row5",
                       @"file",@"row6",
                       [NSNumber numberWithInt:0], @"playlistid",
                       @"file",@"row8",
                       @"file", @"row9",
                       nil],
                      
                      [NSDictionary  dictionaryWithObjectsAndKeys:
                       @"files",@"itemid",
                       @"label", @"row1",
                       @"year", @"row2",
                       @"year", @"row3",
                       @"runtime", @"row4",
                       @"fanart",@"row5",
                       @"file",@"row6",
                       [NSNumber numberWithInt:0], @"playlistid",
                       @"file",@"row8",
                       @"file", @"row9",
                       nil],
                      
                      nil];
    item1.rowHeight=53;
    item1.thumbWidth=53;
    item1.defaultThumb=@"nocover_music.png";
    
    item1.sheetActions=[NSArray arrayWithObjects:
                        [NSArray arrayWithObjects:@"Queue", @"Play", @"Search Wikipedia", nil],
                        [NSArray arrayWithObjects:@"Queue", @"Play", @"Search Wikipedia", nil],
                        [NSArray arrayWithObjects:@"Queue", @"Play", nil],
                        [NSArray arrayWithObjects:nil],
                        [NSArray arrayWithObjects:nil],
                        
                        nil];//@"View Details",
//    
    item1.subItem.mainMethod=[NSMutableArray arrayWithObjects:
                              
                              [NSArray arrayWithObjects:@"AudioLibrary.GetSongs", @"method", nil],
                              
                              [NSArray arrayWithObjects:@"AudioLibrary.GetAlbums", @"method", nil],
                              
                              [NSArray arrayWithObjects:@"AudioLibrary.GetAlbums", @"method", nil],
                              
                              [NSArray arrayWithObjects:@"Files.GetDirectory", @"method", nil],
                              
                              [NSArray arrayWithObjects:nil],
                              
                              nil]; 
    item1.subItem.mainParameters=[NSMutableArray arrayWithObjects:
                                  [NSMutableArray arrayWithObjects:
                                   [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"ascending",@"order",
                                     [NSNumber numberWithBool:FALSE],@"ignorearticle",
                                     @"track", @"method",
                                     nil],@"sort",
                                    [NSArray arrayWithObjects:@"genre", @"year", @"duration", @"track", @"thumbnail", @"rating", @"playcount", @"artist", @"albumid", @"file", nil], @"properties",
                                    nil], @"parameters", @"Songs", @"label", nil],
                                  
                                  [NSMutableArray arrayWithObjects:
                                   [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"ascending",@"order",
                                     [NSNumber numberWithBool:FALSE],@"ignorearticle",
                                     @"year", @"method",
                                     nil],@"sort",
                                    [NSArray arrayWithObjects:@"year", @"thumbnail", @"artist", nil], @"properties",
                                    nil], @"parameters", @"Albums", @"label", nil],
                                  
                                  [NSMutableArray arrayWithObjects:
                                   [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"ascending",@"order",
                                     [NSNumber numberWithBool:FALSE],@"ignorearticle",
                                     @"year", @"method",
                                     nil],@"sort",
                                    [NSArray arrayWithObjects:@"year", @"thumbnail", @"artist", nil], @"properties",
                                    nil], @"parameters", @"Albums", @"label", nil],
                                  
                                  [NSMutableArray arrayWithObjects:
                                   [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"ascending",@"order",
                                     [NSNumber numberWithBool:FALSE],@"ignorearticle",
                                     @"label", @"method",
                                     nil],@"sort",
                                    @"music", @"media",
                                    nil], @"parameters", @"Files", @"label", @"nocover_filemode.png", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeRowWidth, @"thumbWidth", nil],
                                  
                                  [NSArray arrayWithObjects:nil],
                                  
                                  nil];
    item1.subItem.mainFields=[NSArray arrayWithObjects:
                              [NSDictionary  dictionaryWithObjectsAndKeys:
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
                               @"artist", @"row11",

                               nil],
                              
                              [NSDictionary  dictionaryWithObjectsAndKeys:
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
                               @"artist", @"row10",
                               nil],
                              
                              [NSDictionary  dictionaryWithObjectsAndKeys:
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
                               @"artist", @"row10",
                               nil],
                              
                              [NSDictionary  dictionaryWithObjectsAndKeys:
                               @"files",@"itemid",
                               @"label", @"row1",
                               @"filetype", @"row2",
                               @"filetype", @"row3",
                               @"filetype", @"row4",
                               @"filetype",@"row5",
                               @"file",@"row6",
                               [NSNumber numberWithInt:0], @"playlistid",
                               @"file",@"row8",
                               @"file", @"row9",
                               @"filetype", @"row10",
                               @"type", @"row11",
                               nil],
                              
                              [NSArray arrayWithObjects:nil],
                              
                              nil];
    item1.subItem.enableSection=NO;
    item1.subItem.rowHeight=53;
    item1.subItem.thumbWidth=53;
    item1.subItem.defaultThumb=@"nocover_music.png";
    item1.subItem.sheetActions=[NSArray arrayWithObjects:
                                [NSArray arrayWithObjects: @"Queue", @"Play", nil],
                                [NSArray arrayWithObjects: @"Queue", @"Play", nil],
                                [NSArray arrayWithObjects: @"Queue", @"Play", nil],
                                [NSArray arrayWithObjects: @"Queue", @"Play", nil],
                                [NSArray arrayWithObjects:nil],
                                nil];//, @"Stream to iPhone"
    item1.subItem.originYearDuration=248;
    item1.subItem.widthLabel=252;
    item1.subItem.showRuntime=[NSArray arrayWithObjects:[NSNumber numberWithBool:YES], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:YES], nil];
    
    item1.subItem.subItem.mainMethod=[NSMutableArray arrayWithObjects:
                                      
                                      [NSArray arrayWithObjects:nil],
                                      
                                      [NSArray arrayWithObjects:@"AudioLibrary.GetSongs", @"method", nil],
                                      
                                      [NSArray arrayWithObjects:@"AudioLibrary.GetSongs", @"method", nil],
                                      
                                      [NSArray arrayWithObjects:@"Files.GetDirectory", @"method", nil],
                                      
                                      nil];
    
    item1.subItem.subItem.mainParameters=[NSMutableArray arrayWithObjects:
                                          
                                          [NSArray arrayWithObjects:nil],
                                          
                                          [NSMutableArray arrayWithObjects:
                                           [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSDictionary dictionaryWithObjectsAndKeys:
                                             @"ascending",@"order",
                                             [NSNumber numberWithBool:FALSE],@"ignorearticle",
                                             @"track", @"method",
                                             nil],@"sort",
                                            [NSArray arrayWithObjects:@"genre", @"year", @"duration", @"track", @"thumbnail", @"rating", @"playcount", @"artist", @"albumid", @"file", nil], @"properties",
                                            nil], @"parameters", @"Songs", @"label", nil], 
                                          
                                          [NSMutableArray arrayWithObjects:
                                           [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSDictionary dictionaryWithObjectsAndKeys:
                                             @"ascending",@"order",
                                             [NSNumber numberWithBool:FALSE],@"ignorearticle",
                                             @"track", @"method",
                                             nil],@"sort",
                                            [NSArray arrayWithObjects:@"genre", @"year", @"duration", @"track", @"thumbnail", @"rating", @"playcount", @"artist", @"albumid", @"file", nil], @"properties",
                                            nil], @"parameters", @"Songs", @"label", nil],
                                          
                                          [NSArray arrayWithObjects:nil],
                                          
                                          nil];
    item1.subItem.subItem.mainFields=[NSArray arrayWithObjects:
                                      
                                      [NSArray arrayWithObjects:nil],
                                      
                                      [NSDictionary  dictionaryWithObjectsAndKeys:
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
                                       @"artist", @"row11",

                                       nil],
                                      
                                      [NSDictionary  dictionaryWithObjectsAndKeys:
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
                                       @"artist", @"row11",

                                       nil],
                                      
                                      [NSArray arrayWithObjects:nil],
                                      
                                      nil];
    item1.subItem.subItem.rowHeight=53;
    item1.subItem.subItem.thumbWidth=53;
    item1.subItem.subItem.defaultThumb=@"nocover_music.png";
    item1.subItem.subItem.sheetActions=[NSArray arrayWithObjects:
                                        [NSArray arrayWithObjects:@"Queue", @"Play", nil],
                                        [NSArray arrayWithObjects:@"Queue", @"Play", nil],
                                        [NSArray arrayWithObjects:@"Queue", @"Play", nil],
                                        nil];
    item1.subItem.subItem.showRuntime=[NSArray arrayWithObjects:[NSNumber numberWithBool:YES], [NSNumber numberWithBool:YES], [NSNumber numberWithBool:YES],[NSNumber numberWithBool:YES], nil];

    item2.mainLabel = @"Movies";
    item2.upperLabel = @"Watch your";
    item2.icon = @"icon_home_movie.png";
    item2.family = 1;
    item2.enableSection=YES;
    item2.mainButtons=[NSArray arrayWithObjects:@"st_movie", @"st_concert", @"st_filemode", nil];//

    item2.mainMethod=[NSMutableArray arrayWithObjects:
                      [NSArray arrayWithObjects:@"VideoLibrary.GetMovies", @"method", nil],
                      
                      [NSArray arrayWithObjects:@"VideoLibrary.GetMusicVideos", @"method", nil],
                      
                      [NSArray arrayWithObjects:@"Files.GetSources", @"method", nil],
                      
                      nil];
    
    item2.mainParameters=[NSMutableArray arrayWithObjects:
                          [NSMutableArray arrayWithObjects:
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             @"ascending",@"order",
                             [NSNumber numberWithBool:FALSE],@"ignorearticle",
                             @"label", @"method",
                             nil],@"sort",
                            [NSArray arrayWithObjects:@"year", @"playcount", @"rating", @"thumbnail", @"genre", @"runtime", @"studio", @"director", @"plot", @"mpaa", @"votes", @"cast", @"file", @"fanart", nil], @"properties",
                            nil], @"parameters", @"Movies", @"label", @"Movie", @"wikitype", nil],
                          
                          [NSMutableArray arrayWithObjects:
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             @"ascending",@"order",
                             [NSNumber numberWithBool:FALSE],@"ignorearticle",
                             @"label", @"method",
                             nil],@"sort",
                            [NSArray arrayWithObjects:@"year", @"playcount", @"thumbnail", @"genre", @"runtime", @"studio", @"director", @"plot", @"file", @"fanart", nil], @"properties",
                            nil], @"parameters", @"Music Videos", @"label", @"Movie", @"wikitype", nil],
                          
                          [NSMutableArray arrayWithObjects:
                           [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            @"video", @"media",
                            nil], @"parameters", @"Files", @"label", @"nocover_filemode.png", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeRowWidth, @"thumbWidth", nil],
                          
                          nil];
    
    item2.mainFields=[NSArray arrayWithObjects:
                      [NSDictionary dictionaryWithObjectsAndKeys:
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
                       @"fanart",@"row7",
                       nil],
                      
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       @"musicvideos",@"itemid",
                       @"label", @"row1",
                       @"genre", @"row2",
                       @"year", @"row3",
                       @"runtime", @"row4",
                       @"rating",@"row5",
                       @"musicvideoid",@"row6",
                       [NSNumber numberWithInt:1], @"playlistid",
                       @"musicvideoid",@"row8",
                       @"musicvideoid", @"row9",
                       @"director",@"row10",
                       @"studio",@"row11",
                       @"plot",@"row12",
                       @"mpaa",@"row13",
                       @"votes",@"row14",
                       @"votes",@"row15",
                       @"cast",@"row16",
                       @"file",@"row17",
                       @"fanart",@"row7",
                       nil],
                      
                      [NSDictionary  dictionaryWithObjectsAndKeys:
                       @"sources",@"itemid",
                       @"label", @"row1",
                       @"year", @"row2",
                       @"year", @"row3",
                       @"runtime", @"row4",
                       @"rating",@"row5",
                       @"file",@"row6",
                       [NSNumber numberWithInt:1], @"playlistid",
                       @"file",@"row8",
                       @"file", @"row9",
                       nil],
                      
                      nil];
    item2.rowHeight=76;
    item2.thumbWidth=53;
    item2.defaultThumb=@"nocover_movies.png";
    item2.sheetActions=[NSArray arrayWithObjects:
                        [NSArray arrayWithObjects:@"Queue", @"Play", @"View Details", nil],
                        [NSArray arrayWithObjects:@"Queue", @"Play", @"View Details", nil],
                        [NSArray arrayWithObjects: nil],
                        nil];
    item2.showInfo = YES;
    
    item2.subItem.mainMethod=[NSMutableArray arrayWithObjects:
                              [NSArray arrayWithObjects: nil],
                              [NSArray arrayWithObjects: nil],
                              [NSArray arrayWithObjects:@"Files.GetDirectory", @"method", nil],
                              nil]; 
    item2.subItem.mainParameters=[NSMutableArray arrayWithObjects:
                                  [NSArray arrayWithObjects: nil],
                                  [NSArray arrayWithObjects: nil],                                
                                  [NSMutableArray arrayWithObjects:
                                   [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"ascending",@"order",
                                     [NSNumber numberWithBool:FALSE],@"ignorearticle",
                                     @"label", @"method",
                                     nil],@"sort",
                                    @"video", @"media",
                                    nil], @"parameters", @"Files", @"label", @"nocover_filemode.png", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeRowWidth, @"thumbWidth", nil],
                                  nil];
    item2.subItem.mainFields=[NSArray arrayWithObjects:
                              [NSDictionary dictionaryWithObjectsAndKeys: nil],
                              [NSDictionary dictionaryWithObjectsAndKeys: nil],
                              [NSDictionary  dictionaryWithObjectsAndKeys:
                               @"files",@"itemid",
                               @"label", @"row1",
                               @"filetype", @"row2",
                               @"filetype", @"row3",
                               @"filetype", @"row4",
                               @"filetype",@"row5",
                               @"file",@"row6",
                               [NSNumber numberWithInt:1], @"playlistid",
                               @"file",@"row8",
                               @"file", @"row9",
                               @"filetype", @"row10",
                               @"type", @"row11",
                               nil],
                              nil];
    item2.subItem.enableSection=NO;
    item2.subItem.rowHeight=76;
    item2.subItem.thumbWidth=53;
    item2.subItem.defaultThumb=@"nocover_filemode.png";
    item2.subItem.sheetActions=[NSArray arrayWithObjects:
                                [NSArray arrayWithObjects: nil],
                                [NSArray arrayWithObjects: nil],
                                [NSArray arrayWithObjects:@"Queue", @"Play", nil],
                                nil];
    item2.subItem.widthLabel=252;
    
    item2.subItem.subItem.mainMethod=[NSMutableArray arrayWithObjects:
                              [NSArray arrayWithObjects: nil],
                              [NSArray arrayWithObjects: nil],
                              [NSArray arrayWithObjects:@"Files.GetDirectory", @"method", nil],
                              nil]; 
    item2.subItem.subItem.mainParameters=[NSMutableArray arrayWithObjects:
                                  [NSArray arrayWithObjects: nil],
                                  [NSArray arrayWithObjects: nil],
                                  [NSArray arrayWithObjects: nil],
                                  
                                  nil];
    item2.subItem.subItem.mainFields=[NSArray arrayWithObjects:
                                      [NSDictionary dictionaryWithObjectsAndKeys: nil],
                                      
                                      [NSDictionary dictionaryWithObjectsAndKeys: nil],
                                      
                                      [NSDictionary dictionaryWithObjectsAndKeys: nil],
                                      
                                      nil];
    item2.subItem.subItem.enableSection=NO;
    item2.subItem.subItem.rowHeight=76;
    item2.subItem.subItem.thumbWidth=53;
    item2.subItem.subItem.defaultThumb=@"nocover_filemode.png";
    item2.subItem.subItem.sheetActions=[NSArray arrayWithObjects:
                                        [NSArray arrayWithObjects: nil],
                                        [NSArray arrayWithObjects: nil],
                                        [NSArray arrayWithObjects:@"Queue", @"Play", nil],
                                        nil];
    item2.subItem.subItem.widthLabel=252;
    

    
    
    item3.mainLabel = @"TV Shows";
    item3.upperLabel = @"Watch your";
    item3.icon = @"icon_home_tv.png";
    item3.family = 1;
    item3.enableSection=YES;
    item3.mainButtons=[NSArray arrayWithObjects:@"st_tv", @"st_filemode", nil];//, @"st_actor", @"st_genre"
    
    

    item3.mainMethod=[NSMutableArray arrayWithObjects:
                      [NSArray arrayWithObjects:@"VideoLibrary.GetTVShows", @"method", nil],
                      
                                            
                      [NSArray arrayWithObjects:@"Files.GetSources", @"method", nil],

                      nil];
    item3.mainParameters=[NSMutableArray arrayWithObjects:
                          [NSMutableArray arrayWithObjects:
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             @"ascending",@"order",
                             [NSNumber numberWithBool:FALSE],@"ignorearticle",
                             @"label", @"method",
                             nil],@"sort",
                            
                            [NSArray arrayWithObjects:@"year", @"playcount", @"rating", @"thumbnail", @"genre", @"studio", @"plot", @"mpaa", @"votes", @"cast", @"premiered", @"episode", @"fanart", nil], @"properties",
                            nil], @"parameters", @"TV Shows", @"label", @"TV Show", @"wikitype",
                           nil],
                          
                                                    
                          [NSMutableArray arrayWithObjects:
                           [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             @"ascending",@"order",
                             [NSNumber numberWithBool:FALSE],@"ignorearticle",
                             @"label", @"method",
                             nil],@"sort",
                            @"video", @"media",
                            nil], @"parameters", @"Files", @"label", @"nocover_filemode.png", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeRowWidth, @"thumbWidth", nil],
                          nil];
    item3.mainFields=[NSArray arrayWithObjects:
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       @"tvshows",@"itemid",
                       @"label", @"row1",
                       @"genre", @"row2",
                       @"blank", @"row3",
                       @"studio", @"row4",
                       @"rating",@"row5",
                       @"tvshowid",@"row6",
                       [NSNumber numberWithInt:2], @"playlistid",
                       @"studio",@"row8",
                       @"plot",@"row9",
                       @"mpaa",@"row10",
                       @"votes",@"row11",
                       @"cast",@"row12",
                       @"premiered",@"row13",
                       @"episode",@"row14",
                       @"fanart",@"row7",
                       nil],
                                            
                      [NSDictionary  dictionaryWithObjectsAndKeys:
                       @"sources",@"itemid",
                       @"label", @"row1",
                       @"year", @"row2",
                       @"year", @"row3",
                       @"runtime", @"row4",
                       @"rating",@"row5",
                       @"file",@"row6",
                       [NSNumber numberWithInt:0], @"playlistid",
                       @"file",@"row8",
                       @"file", @"row9",
                       nil],
                      nil];
    item3.rowHeight=tvshowHeight;
    item3.thumbWidth=thumbWidth;
    item3.defaultThumb=@"nocover_tvshows.png";
    item3.originLabel=60;
    item3.sheetActions=[NSArray arrayWithObjects:
                        [NSArray arrayWithObjects:@"View Details", nil],
                        [NSArray arrayWithObjects:nil],
                        nil];
    
    item3.subItem.mainMethod=[NSMutableArray arrayWithObjects:
                              [NSArray arrayWithObjects:@"VideoLibrary.GetSeasons", @"method", nil],
                              [NSArray arrayWithObjects:@"Files.GetDirectory", @"method", nil],
                              nil]; 
    item3.subItem.mainParameters=[NSMutableArray arrayWithObjects:
                                  [NSMutableArray arrayWithObjects:
                                   [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"ascending",@"order",
                                     [NSNumber numberWithBool:FALSE],@"ignorearticle",
                                     @"track", @"method",
                                     nil],@"sort",
                                    
                                    [NSArray arrayWithObjects:@"season", @"thumbnail", @"tvshowid", nil], @"properties",
                                    nil], @"parameters", @"Seasons", @"label", 
                                   nil],
                                                                    
                                  [NSMutableArray arrayWithObjects:
                                   [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"ascending",@"order",
                                     [NSNumber numberWithBool:FALSE],@"ignorearticle",
                                     @"label", @"method",
                                     nil],@"sort",
                                    @"video", @"media",
                                    nil], @"parameters", @"Files", @"label", @"nocover_filemode.png", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeRowWidth, @"thumbWidth", nil],
                                  nil];
    item3.subItem.mainFields=[NSArray arrayWithObjects:
                              [NSDictionary  dictionaryWithObjectsAndKeys:
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
                               nil],
                              
                                                            
                              [NSDictionary  dictionaryWithObjectsAndKeys:
                               @"files",@"itemid",
                               @"label", @"row1",
                               @"filetype", @"row2",
                               @"filetype", @"row3",
                               @"filetype", @"row4",
                               @"filetype",@"row5",
                               @"file",@"row6",
                               [NSNumber numberWithInt:1], @"playlistid",
                               @"file",@"row8",
                               @"file", @"row9",
                               @"filetype", @"row10",
                               @"type", @"row11",
                               nil],
                              nil];
    item3.subItem.enableSection=NO;
    item3.subItem.rowHeight=76;
    item3.subItem.thumbWidth=53;
    item3.subItem.defaultThumb=@"nocover_tvshows_episode.png";
    item3.subItem.sheetActions=[NSArray arrayWithObjects:
                                [NSArray arrayWithObjects: @"Queue", @"Play", nil],
                                [NSArray arrayWithObjects: @"Queue", @"Play", nil],
                                nil];//, @"Stream to iPhone"

    item3.subItem.widthLabel=252;

//    item3.subItem.sheetActions=[NSArray arrayWithObjects:@"Queue", @"Play", nil];

    item3.subItem.subItem.mainMethod=[NSMutableArray arrayWithObjects:
                                      [NSArray arrayWithObjects:@"VideoLibrary.GetEpisodes", @"method", nil],
                                      [NSArray arrayWithObjects:@"Files.GetDirectory", @"method", nil],
                                      
                                      nil]; 
    item3.subItem.subItem.mainParameters=[NSMutableArray arrayWithObjects:
                                          [NSMutableArray arrayWithObjects:
                                           [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSDictionary dictionaryWithObjectsAndKeys:
                                             @"ascending",@"order",
                                             [NSNumber numberWithBool:FALSE],@"ignorearticle",
                                             @"episode", @"method",
                                             nil],@"sort",
                                            [NSArray arrayWithObjects:@"episode", @"thumbnail", @"firstaired", @"runtime", @"plot", @"director", @"writer", @"rating", @"showtitle", @"season", @"cast", @"file", @"fanart", nil], @"properties",
                                            nil], @"parameters", @"Episodes", @"label", nil],
                                          
                                          [NSArray arrayWithObjects:nil],
                                          
                                          nil];
    item3.subItem.subItem.mainFields=[NSArray arrayWithObjects:
                                      [NSDictionary  dictionaryWithObjectsAndKeys:
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
                                       @"fanart",@"row7",
                                       nil],
                                      
                                      [NSArray arrayWithObjects:nil],
                                      
                                      nil];
    item3.subItem.subItem.enableSection=NO;
    item3.subItem.subItem.rowHeight=53;
    item3.subItem.subItem.thumbWidth=95;
    item3.subItem.subItem.defaultThumb=@"nocover_tvshows_episode.png";
    item3.subItem.subItem.sheetActions=[NSArray arrayWithObjects:
                                        [NSArray arrayWithObjects:@"Queue", @"Play", nil],
                                        [NSArray arrayWithObjects:@"Queue", @"Play", nil],
                                        nil];
    item3.subItem.subItem.originYearDuration=248;
    item3.subItem.subItem.widthLabel=208;
    item3.subItem.subItem.showRuntime=[NSArray arrayWithObjects:[NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], nil];
    item3.subItem.subItem.noConvertTime=YES;
    item3.subItem.subItem.showInfo=YES;

    item4.mainLabel = @"Pictures";
    item4.upperLabel = @"Browse your";
    item4.icon = @"icon_home_picture.png";
    item4.family = 1;
    item4.enableSection=YES;
    item4.mainButtons=[NSArray arrayWithObjects:@"st_filemode", nil];//, @"st_actor", @"st_genre"
    
    
    
    item4.mainMethod=[NSMutableArray arrayWithObjects:
                      
                      
                      
                      [NSArray arrayWithObjects:@"Files.GetSources", @"method", nil],
                      
                      nil];
    item4.mainParameters=[NSMutableArray arrayWithObjects:
                          
                          
                          
                          [NSMutableArray arrayWithObjects:
                           [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             @"ascending",@"order",
                             [NSNumber numberWithBool:FALSE],@"ignorearticle",
                             @"label", @"method",
                             nil],@"sort",
                            @"pictures", @"media",
                            nil], @"parameters", @"Pictures", @"label", @"nocover_filemode.png", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeRowWidth, @"thumbWidth", nil],
                          nil];
    item4.mainFields=[NSArray arrayWithObjects:
                      
                      
                      [NSDictionary  dictionaryWithObjectsAndKeys:
                       @"sources",@"itemid",
                       @"label", @"row1",
                       @"year", @"row2",
                       @"year", @"row3",
                       @"runtime", @"row4",
                       @"rating",@"row5",
                       @"file",@"row6",
                       [NSNumber numberWithInt:2], @"playlistid",
                       @"file",@"row8",
                       @"file", @"row9",
                       nil],
                      nil];
    
    
    item4.thumbWidth=53;
    item4.defaultThumb=@"jewel_dvd.table.png";
    
    item4.subItem.mainMethod=[NSMutableArray arrayWithObjects:
                              [NSArray arrayWithObjects:@"Files.GetDirectory", @"method", nil],
                              nil]; 
    item4.subItem.mainParameters=[NSMutableArray arrayWithObjects:
                                  
                                  
                                  [NSMutableArray arrayWithObjects:
                                   [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"ascending",@"order",
                                     [NSNumber numberWithBool:FALSE],@"ignorearticle",
                                     @"label", @"method",
                                     nil],@"sort",
                                    @"pictures", @"media",
                                    nil], @"parameters", @"Files", @"label", @"nocover_filemode.png", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeRowWidth, @"thumbWidth", nil],
                                  nil];
    item4.subItem.mainFields=[NSArray arrayWithObjects:
                              
                              [NSDictionary  dictionaryWithObjectsAndKeys:
                               @"files",@"itemid",
                               @"label", @"row1",
                               @"filetype", @"row2",
                               @"filetype", @"row3",
                               @"filetype", @"row4",
                               @"filetype",@"row5",
                               @"file",@"row6",
                               [NSNumber numberWithInt:2], @"playlistid",
                               @"file",@"row8",
                               @"file", @"row9",
                               @"filetype", @"row10",
                               @"type", @"row11",
                               nil],
                              nil];
    item4.subItem.enableSection=NO;
    item4.subItem.rowHeight=76;
    item4.subItem.thumbWidth=53;
    item4.subItem.defaultThumb=@"nocover_tvshows_episode.png";
    
    
    item4.subItem.subItem.mainMethod=[NSMutableArray arrayWithObjects:
                                      
                                      [NSArray arrayWithObjects:@"Files.GetDirectory", @"method", nil],
                                      
                                      nil]; 
    item4.subItem.subItem.mainParameters=[NSMutableArray arrayWithObjects:
                                          
                                          
                                          [NSArray arrayWithObjects:nil],
                                          
                                          nil];
    item4.subItem.subItem.mainFields=[NSArray arrayWithObjects:
                                      
                                      
                                      [NSArray arrayWithObjects:nil],
                                      
                                      nil];
        
//    item4.subItem.sheetActions=[NSArray arrayWithObjects: @"Queue", @"Play", nil];//, @"Stream to iPhone"


    item5.mainLabel = @"Now playing";
    item5.upperLabel = @"See what's";
    item5.icon = @"icon_home_playing.png";
    item5.family = 2;
    
    item6.mainLabel = @"Remote Control";
    item6.upperLabel = @"Use as";
    item6.icon = @"icon_home_remote.png";
    item6.family = 3;
    
    
    MasterViewController *masterViewController;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [mainMenuItems addObject:item1];
        [mainMenuItems addObject:item2];
        [mainMenuItems addObject:item3];
        [mainMenuItems addObject:item4];
        [mainMenuItems addObject:item5];
        [mainMenuItems addObject:item6];
        masterViewController = [[MasterViewController alloc] initWithNibName:@"MasterViewController" bundle:nil];
        self.navigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
        self.window.rootViewController = self.navigationController;
        masterViewController.mainMenu =mainMenuItems;

    } else {
        [mainMenuItems addObject:item1];
        [mainMenuItems addObject:item2];
        [mainMenuItems addObject:item3];
        [mainMenuItems addObject:item4];
//        [mainMenuItems addObject:item5];
        [mainMenuItems addObject:item6];
        self.windowController = [[ViewControllerIPad alloc] initWithNibName:@"ViewControllerIPad" bundle:nil];
        self.windowController.mainMenu = mainMenuItems;
        self.window.rootViewController = self.windowController;
        
        

    }
    
//    masterViewController.serverList=[arrayServerList copy];
    
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
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];

    UIApplication *xbmcRemote = [UIApplication sharedApplication];
    if ([[userDefaults objectForKey:@"lockscreen_preference"] boolValue]==YES ){
        xbmcRemote.idleTimerDisabled = YES;
    }
    else {
        xbmcRemote.idleTimerDisabled = NO;

    }
    [[NSNotificationCenter defaultCenter] postNotificationName: @"UIApplicationWillEnterForegroundNotification" object: nil]; 
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

}

- (void)applicationWillTerminate:(UIApplication *)application{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [[SDImageCache sharedImageCache] clearMemory];
}

-(void)saveServerList{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if ([paths count] > 0) { 
        NSString  *dicPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"serverList_saved.dat"];
        [NSKeyedArchiver archiveRootObject:arrayServerList toFile:dicPath];
    }
}
@end
