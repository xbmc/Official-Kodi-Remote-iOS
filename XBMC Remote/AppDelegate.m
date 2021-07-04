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
#import "GlobalData.h"
#import "InitialSlidingViewController.h"
#import "UIImageView+WebCache.h"
#import "Utilities.h"

#include <arpa/inet.h>
#include <net/if.h>
#include <ifaddrs.h>

@implementation AppDelegate

NSMutableArray *mainMenuItems;
NSMutableArray *hostRightMenuItems;

@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize windowController = _windowController;
@synthesize dataFilePath;
@synthesize arrayServerList;
@synthesize serverOnLine;
@synthesize serverVersion;
@synthesize serverMinorVersion;
@synthesize obj;
@synthesize playlistArtistAlbums;
@synthesize playlistMovies;
@synthesize playlistTvShows;
@synthesize rightMenuItems;
@synthesize serverName;
@synthesize nowPlayingMenuItems;
@synthesize serverVolume;
@synthesize remoteControlMenuItems;
@synthesize xbmcSettings;

+ (AppDelegate*)instance {
	return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

#pragma mark globals

#define ITEM_MUSIC_PHONE_WIDTH 106.0
#define ITEM_MUSIC_PHONE_HEIGHT 106.0
#define ITEM_MUSIC_PAD_WIDTH 119.0
#define ITEM_MUSIC_PAD_HEIGHT 119.0
#define ITEM_MUSIC_PAD_WIDTH_FULLSCREEN 164.0
#define ITEM_MUSIC_PAD_HEIGHT_FULLSCREEN 164.0

#define ITEM_MOVIE_PHONE_WIDTH 106.0
#define ITEM_MOVIE_PHONE_HEIGHT 151.0
#define ITEM_MOVIE_PAD_WIDTH 119.0
#define ITEM_MOVIE_PAD_HEIGHT 170.0
#define ITEM_MOVIE_PAD_WIDTH_FULLSCREEN 164.0
#define ITEM_MOVIE_PAD_HEIGHT_FULLSCREEN 233.0

#define ITEM_TVSHOW_PHONE_WIDTH 158.0
#define ITEM_TVSHOW_PHONE_HEIGHT (ITEM_TVSHOW_PHONE_WIDTH * 9.0/16.0)
#define ITEM_TVSHOW_PAD_WIDTH 178.0
#define ITEM_TVSHOW_PAD_HEIGHT (ITEM_TVSHOW_PAD_WIDTH * 9.0/16.0)
#define ITEM_TVSHOW_PAD_WIDTH_FULLSCREEN 245.0
#define ITEM_TVSHOW_PAD_HEIGHT_FULLSCREEN (ITEM_TVSHOW_PAD_WIDTH_FULLSCREEN * 9.0/16.0)

#define ITEM_MOVIE_PHONE_HEIGHT_RECENTLY 132.0
#define ITEM_MOVIE_PAD_HEIGHT_RECENTLY 196.0
#define ITEM_MOVIE_PAD_WIDTH_RECENTLY_FULLSCREEN 502.0
#define ITEM_MOVIE_PAD_HEIGHT_RECENTLY_FULLSCREEN 206.0

#pragma mark helper

- (NSDictionary*)itemSizes_Musicfullscreen {
    return @{
        @"iphone": @{
                @"width": @ITEM_MUSIC_PHONE_WIDTH,
                @"height": @ITEM_MUSIC_PHONE_HEIGHT
            },
        @"ipad": @{
                @"width": @ITEM_MUSIC_PAD_WIDTH,
                @"height": @ITEM_MUSIC_PAD_HEIGHT,
                @"fullscreenWidth": @ITEM_MUSIC_PAD_WIDTH_FULLSCREEN,
                @"fullscreenHeight": @ITEM_MUSIC_PAD_HEIGHT_FULLSCREEN
            }
    };
}

- (NSDictionary*)itemSizes_Music {
    return @{
        @"iphone": @{
                @"width": @ITEM_MUSIC_PHONE_WIDTH,
                @"height": @ITEM_MUSIC_PHONE_HEIGHT
            },
        @"ipad": @{
                @"width": @ITEM_MUSIC_PAD_WIDTH,
                @"height": @ITEM_MUSIC_PAD_HEIGHT
            }
    };
}

- (NSDictionary*)itemSizes_Music_insets:(NSString*)inset {
    return @{
        @"iphone": @{
                @"width": @ITEM_MUSIC_PHONE_WIDTH,
                @"height": @ITEM_MUSIC_PHONE_HEIGHT
            },
        @"ipad": @{
                @"width": @ITEM_MUSIC_PAD_WIDTH,
                @"height": @ITEM_MUSIC_PAD_HEIGHT
            },
        @"separatorInset": inset
    };
}

- (NSDictionary*)itemSizes_TVShowsfullscreen_insets:(NSString*)inset {
    return @{
        @"iphone": @{
                @"width": @ITEM_TVSHOW_PHONE_WIDTH,
                @"height": @ITEM_TVSHOW_PHONE_HEIGHT
            },
        @"ipad": @{
                @"width": @ITEM_TVSHOW_PAD_WIDTH,
                @"height": @ITEM_TVSHOW_PAD_HEIGHT,
                @"fullscreenWidth": @ITEM_TVSHOW_PAD_WIDTH_FULLSCREEN,
                @"fullscreenHeight": @ITEM_TVSHOW_PAD_HEIGHT_FULLSCREEN
            },
        @"separatorInset": inset
    };
}

- (NSDictionary*)itemSizes_MovieRecentlyfullscreen {
    return @{
        @"iphone": @{
                @"width": @"fullWidth",
                @"height": @ITEM_MOVIE_PHONE_HEIGHT_RECENTLY
            },
        @"ipad": @{
                @"width": @"fullWidth",
                @"height": @ITEM_MOVIE_PAD_HEIGHT_RECENTLY,
                @"fullscreenWidth": @ITEM_MOVIE_PAD_WIDTH_RECENTLY_FULLSCREEN,
                @"fullscreenHeight": @ITEM_MOVIE_PAD_HEIGHT_RECENTLY_FULLSCREEN
            }
    };
}

- (NSDictionary*)itemSizes_Moviefullscreen {
    return @{
        @"iphone": @{
                @"width": @ITEM_MOVIE_PHONE_WIDTH,
                @"height": @ITEM_MOVIE_PHONE_HEIGHT
            },
        @"ipad": @{
                @"width": @ITEM_MOVIE_PAD_WIDTH,
                @"height": @ITEM_MOVIE_PAD_HEIGHT,
                @"fullscreenWidth": @ITEM_MOVIE_PAD_WIDTH_FULLSCREEN,
                @"fullscreenHeight": @ITEM_MOVIE_PAD_HEIGHT_FULLSCREEN
            }
    };
}

- (NSDictionary*)itemSizes_Movie {
    return @{
        @"iphone": @{
                @"width": @ITEM_MOVIE_PHONE_WIDTH,
                @"height": @ITEM_MOVIE_PHONE_HEIGHT
            },
        @"ipad": @{
                @"width": @ITEM_MOVIE_PAD_WIDTH,
                @"height": @ITEM_MOVIE_PAD_HEIGHT
            }
    };
}

- (NSDictionary*)itemSizes_Movie_insets:(NSString*)inset {
    return @{
        @"iphone": @{
                @"width": @ITEM_MOVIE_PHONE_WIDTH,
                @"height": @ITEM_MOVIE_PHONE_HEIGHT
            },
        @"ipad": @{
                @"width": @ITEM_MOVIE_PAD_WIDTH,
                @"height": @ITEM_MOVIE_PAD_HEIGHT
            },
        @"separatorInset": inset
    };
}

- (NSDictionary*)itemSizes_insets:(NSString*)inset {
    return @{
        @"separatorInset": inset
    };
}

- (NSDictionary*)watchedListenedString {
    return @{
        @"notWatched": LOCALIZED_STR(@"Not listened"),
        @"watchedOneTime": LOCALIZED_STR(@"Listened one time"),
        @"watchedTimes": LOCALIZED_STR(@"Listened %@ times")
    };
}

- (NSArray*)action_queue_to_wiki {
    return @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Play in shuffle mode"),
        LOCALIZED_STR(@"Album Details"),
        LOCALIZED_STR(@"Search Wikipedia")
    ];
}

- (NSArray*)action_queue_to_fmcharts {
    return @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Play in shuffle mode"),
        LOCALIZED_STR(@"Artist Details"),
        LOCALIZED_STR(@"Search Wikipedia"),
        LOCALIZED_STR(@"Search last.fm charts")
    ];
}

- (NSArray*)action_queue_to_shuffle {
    return @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Play in shuffle mode")
    ];
}

- (NSArray*)action_queue_to_play {
    return @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play")
    ];
}

- (NSArray*)action_queue_to_moviedetails {
    return @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Movie Details")
    ];
}

- (NSArray*)action_queue_to_showcontent {
    return @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Play in shuffle mode"),
        LOCALIZED_STR(@"Play in party mode"),
        LOCALIZED_STR(@"Show Content")
    ];
}

- (NSArray*)action_queue_to_musicvideodetails {
    return @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Music Video Details")
    ];
}

- (NSArray*)action_queue_to_episodedetails {
    return @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Episode Details")
    ];
}

- (NSArray*)action_play_to_broadcastdetails {
    return @[
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Record"),
        LOCALIZED_STR(@"Broadcast Details")
    ];
}

- (NSArray*)action_play_to_channelguide {
    return @[
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Record"),
        LOCALIZED_STR(@"Channel Guide")
    ];
}

- (NSDictionary*)modes_icons_empty {
    return @{
        @"modes": @[],
        @"icons": @[]
    };
}

- (NSDictionary*)modes_icons_watched {
    return @{
        @"modes": @[
                @"all",
                @"unwatched",
                @"watched"],
        @"icons": @[
                @"",
                @"icon_not_watched",
                @"icon_watched"]
    };
}

- (NSDictionary*)modes_icons_listened {
    return @{
        @"modes": @[
                @"all",
                @"unwatched",
                @"watched"],
        @"icons": @[
                @"",
                @"icon_not_listened",
                @"icon_listened"]
    };
}

- (NSDictionary*)setColorRed:(double)r Green:(double)g Blue:(double)b {
    return @{
        @"red": @(r),
        @"green": @(g),
        @"blue": @(b)
    };
}

- (NSDictionary*)sortmethod:(NSString*)method order:(NSString*)order ignorearticle:(BOOL)ignore {
    return @{
        @"order": order,
        @"ignorearticle": @(ignore),
        @"method": method
    };
}

#pragma mark -
#pragma mark init

- (id)init {
	if ((self = [super init])) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = paths[0];
        self.dataFilePath = [documentsDirectory stringByAppendingPathComponent:@"serverList_saved.dat"];
        NSFileManager *fileManager1 = [NSFileManager defaultManager];
        if ([fileManager1 fileExistsAtPath:self.dataFilePath]) {
            NSMutableArray *tempArray;
            tempArray = [NSKeyedUnarchiver unarchiveObjectWithFile:self.dataFilePath];
            [self setArrayServerList:tempArray];
        }
        else {
            arrayServerList = [NSMutableArray new];
        }
        NSString *fullNamespace = @"LibraryCache";
        paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        self.libraryCachePath = [paths[0] stringByAppendingPathComponent:fullNamespace];
        if (![fileManager1 fileExistsAtPath:self.libraryCachePath]) {
            [fileManager1 createDirectoryAtPath:self.libraryCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        self.epgCachePath = [paths[0] stringByAppendingPathComponent:@"EPGDataCache"];
//        [[NSFileManager defaultManager] removeItemAtPath:self.epgCachePath error:nil];
        if (![fileManager1 fileExistsAtPath:self.epgCachePath]) {
            [fileManager1 createDirectoryAtPath:self.epgCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
    }
	return self;
	
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    UIApplication *xbmcRemote = [UIApplication sharedApplication];
    if ([[userDefaults objectForKey:@"lockscreen_preference"] boolValue]) {
        xbmcRemote.idleTimerDisabled = YES;
    }
    else {
        xbmcRemote.idleTimerDisabled = NO;
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    int thumbWidth;
    int tvshowHeight;
    NSString *filemodeRowHeight= @"44";
    NSString *filemodeThumbWidth= @"44";
    NSString *livetvThumbWidth= @"64";
    NSString *livetvRowHeight= @"76";
    NSString *channelEPGRowHeight= @"82";


    NSString *filemodeVideoType = @"video";
    NSString *filemodeMusicType = @"music";
    if ([[userDefaults objectForKey:@"fileType_preference"] boolValue]) {
        filemodeVideoType = @"files";
        filemodeMusicType = @"files";
    }
    NSNumber *animationStartBottomScreen = @YES;
    NSNumber *animationStartX = @0;
    
    obj = [GlobalData getInstance];
    
    CGFloat transform = [Utilities getTransformX];
    if (IS_IPHONE) {
        thumbWidth = (int)(PHONE_TV_SHOWS_BANNER_WIDTH * transform);
        tvshowHeight = (int)(PHONE_TV_SHOWS_BANNER_HEIGHT * transform);
        NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                   [UIColor whiteColor], NSForegroundColorAttributeName,
                                                   [UIFont boldSystemFontOfSize:18], NSFontAttributeName, nil];
        [[UINavigationBar appearance] setTitleTextAttributes:navbarTitleTextAttributes];
    }
    else {
        animationStartBottomScreen = @NO;
        animationStartX = @STACKSCROLL_WIDTH;
        thumbWidth = (int)(PAD_TV_SHOWS_BANNER_WIDTH * transform);
        tvshowHeight = (int)(PAD_TV_SHOWS_BANNER_HEIGHT* transform);
    }
    
    [self.window makeKeyAndVisible];
    
    mainMenuItems = [NSMutableArray arrayWithCapacity:1];
    __auto_type menu_Music = [mainMenu new];
    __auto_type menu_Movies = [mainMenu new];
    __auto_type menu_TVShows = [mainMenu new];
    __auto_type menu_Pictures = [mainMenu new];
    __auto_type menu_Favourites = [mainMenu new];
    __auto_type menu_NowPlaying = [mainMenu new];
    __auto_type menu_Remote = [mainMenu new];
    __auto_type menu_Server = [mainMenu new];
    __auto_type menu_LiveTV = [mainMenu new];

    menu_Music.subItem = [mainMenu new];
    menu_Music.subItem.subItem = [mainMenu new];
    menu_Music.subItem.subItem.subItem = [mainMenu new];

    menu_Movies.subItem = [mainMenu new];
    menu_Movies.subItem.subItem = [mainMenu new];
    
    menu_TVShows.subItem = [mainMenu new];
    menu_TVShows.subItem.subItem = [mainMenu new];
    
    menu_Pictures.subItem = [mainMenu new];
    menu_Pictures.subItem.subItem = [mainMenu new];
    
    menu_LiveTV.subItem = [mainMenu new];
    menu_LiveTV.subItem.subItem = [mainMenu new];

    
#pragma mark - Music
    menu_Music.mainLabel = LOCALIZED_STR(@"Music");
    menu_Music.upperLabel = LOCALIZED_STR(@"Listen to");
    menu_Music.icon = @"icon_menu_music";
    menu_Music.family = FamilyDetailView;
    menu_Music.enableSection = YES;
    menu_Music.mainButtons = @[
        @"st_album",
        @"st_artist",
        @"st_genre",
        @"st_filemode",
        @"st_music_recently_added",
        @"st_music_recently_added",
        @"st_music_top100",
        @"st_music_top100",
        @"st_music_recently_played",
        @"st_music_recently_played",
        @"st_songs",
        @"st_addons",
        @"st_playlists",
        @"st_music_roles"];
    
    menu_Music.mainMethod = @[
            @[@"AudioLibrary.GetAlbums", @"method",
              @"AudioLibrary.GetAlbumDetails", @"extra_info_method"],
            @[@"AudioLibrary.GetArtists", @"method",
              @"AudioLibrary.GetArtistDetails", @"extra_info_method"],
            @[@"AudioLibrary.GetGenres", @"method"],
            @[@"Files.GetSources", @"method"],
            @[@"AudioLibrary.GetRecentlyAddedAlbums", @"method",
              @"AudioLibrary.GetAlbumDetails", @"extra_info_method"],
            @[@"AudioLibrary.GetRecentlyAddedSongs", @"method"],
            @[@"AudioLibrary.GetAlbums", @"method",
              @"AudioLibrary.GetAlbumDetails", @"extra_info_method"],
            @[@"AudioLibrary.GetSongs", @"method"],
            @[@"AudioLibrary.GetRecentlyPlayedAlbums", @"method"],
            @[@"AudioLibrary.GetRecentlyPlayedSongs", @"method"],
            @[@"AudioLibrary.GetSongs", @"method"],
            @[@"Files.GetDirectory", @"method"],
            @[@"Files.GetDirectory", @"method"],
            @[@"AudioLibrary.GetRoles", @"method"]
        ];
    
    menu_Music.mainParameters = [@[
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"year",
                        @"thumbnail",
                        @"artist",
                        @"playcount"],
            }, @"parameters",
            @{
                @"properties": @[
                        @"year",
                        @"thumbnail",
                        @"artist",
                        @"genre",
                        @"description",
                        @"albumlabel",
                        @"fanart"],
            }, @"extra_info_parameters",
            @{
                @"label": @[
                        LOCALIZED_STR(@"Album"),
                        LOCALIZED_STR(@"Artist"),
                        LOCALIZED_STR(@"Year"),
                        LOCALIZED_STR(@"Play count")],
                @"method": @[
                        @"label",
                        @"genre",
                        @"year",
                        @"playcount"]
            }, @"available_sort_methods",
            LOCALIZED_STR(@"Albums"), @"label",
            @"Album", @"wikitype",
            @"YES", @"enableCollectionView",
            @"YES", @"enableLibraryCache",
            @"YES", @"enableLibraryFullScreen",
            [self watchedListenedString], @"watchedListenedStrings",
            [self itemSizes_Musicfullscreen], @"itemSizes"
        ],
            
        @[
            @{
                @"sort": [self sortmethod:@"artist" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"thumbnail",
                        @"genre"]
            }, @"parameters",
            @{
                @"properties": @[
                        @"thumbnail",
                        @"genre",
                        @"instrument",
                        @"style",
                        @"mood",
                        @"born",
                        @"formed",
                        @"description",
                        @"died",
                        @"disbanded",
                        @"yearsactive",
                        @"fanart"],
                @"kodiExtrasPropertiesMinimumVersion": @{
                        @"18": @[@"roles"]
                    }
            }, @"extra_info_parameters",
            LOCALIZED_STR(@"Artists"), @"label",
            @"nocover_artist", @"defaultThumb",
            @"Artist", @"wikitype",
            @"YES", @"enableCollectionView",
            @"YES", @"enableLibraryCache",
            @"YES", @"enableLibraryFullScreen",
            [self itemSizes_Musicfullscreen], @"itemSizes"
        ],
                          
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[@"thumbnail"]
            }, @"parameters",
            LOCALIZED_STR(@"Genres"), @"label",
            @"nocover_genre", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth",
            @"YES", @"enableLibraryCache"
        ],
                          
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"music"
            }, @"parameters",
            LOCALIZED_STR(@"Files"), @"label",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth"
        ],
                          
        @[
            @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"year",
                        @"thumbnail",
                        @"artist"]
            }, @"parameters",
            @{
                @"properties": @[
                        @"year",
                        @"thumbnail",
                        @"artist",
                        @"genre",
                        @"description",
                        @"albumlabel",
                        @"fanart"]
            }, @"extra_info_parameters",
           LOCALIZED_STR(@"Added Albums"), @"label",
           @"Album", @"wikitype",
           LOCALIZED_STR(@"Recently added albums"), @"morelabel",
           @"YES", @"enableCollectionView",
           [self itemSizes_Music], @"itemSizes"
        ],
                          
        @[
            @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"genre",
                        @"year",
                        @"duration",
                        @"track",
                        @"thumbnail",
                        @"rating",
                        @"playcount",
                        @"artist",
                        @"album",
                        @"file"]
            }, @"parameters",
           LOCALIZED_STR(@"Added Songs"), @"label",
           LOCALIZED_STR(@"Recently added songs"), @"morelabel"
        ],
                          
        @[
            @{
                @"sort": [self sortmethod:@"playcount" order:@"descending" ignorearticle:NO],
                @"limits": @{
                        @"start": @0,
                        @"end": @100
                    },
                @"properties": @[
                        @"year",
                        @"thumbnail",
                        @"artist",
                        @"playcount"]
            }, @"parameters",
            @{
                @"properties": @[
                        @"year",
                        @"thumbnail",
                        @"artist",
                        @"genre",
                        @"description",
                        @"albumlabel",
                        @"fanart"]
            }, @"extra_info_parameters",
            @{
                @"label": @[
                        LOCALIZED_STR(@"Top 100 Albums"),
                        LOCALIZED_STR(@"Album"),
                        LOCALIZED_STR(@"Artist"),
                        LOCALIZED_STR(@"Year")],
                @"method": @[
                        @"playcount",
                        @"label",
                        @"genre",
                        @"year"]
            }, @"available_sort_methods",
            LOCALIZED_STR(@"Top 100 Albums"), @"label",
            @"Album", @"wikitype",
            LOCALIZED_STR(@"Top 100 Albums"), @"morelabel",
            @"YES", @"enableCollectionView",
            [self itemSizes_Music], @"itemSizes"
        ],
            
        @[
            @{
                @"sort": [self sortmethod:@"playcount" order:@"descending" ignorearticle:NO],
                @"limits": @{
                        @"start": @0,
                        @"end": @100
                    },
                @"properties": @[
                        @"genre",
                        @"year",
                        @"duration",
                        @"track",
                        @"thumbnail",
                        @"rating",
                        @"playcount",
                        @"artist",
                        @"albumid",
                        @"file",
                        @"album"]
            }, @"parameters",
            @{
                @"label": @[
                        LOCALIZED_STR(@"Top 100 Songs"),
                        LOCALIZED_STR(@"Track"),
                        LOCALIZED_STR(@"Title"),
                        LOCALIZED_STR(@"Album"),
                        LOCALIZED_STR(@"Artist"),
                        LOCALIZED_STR(@"Rating"),
                        LOCALIZED_STR(@"Year")],
                @"method": @[
                        @"playcount",
                        @"track",
                        @"label",
                        @"album",
                        @"genre",
                        @"rating",
                        @"year"]
            }, @"available_sort_methods",
            LOCALIZED_STR(@"Top 100 Songs"), @"label",
            LOCALIZED_STR(@"Top 100 Songs"), @"morelabel",
            @5, @"numberOfStars"
        ],
                          
        @[
            @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"year",
                        @"thumbnail",
                        @"artist"]
            }, @"parameters",
            LOCALIZED_STR(@"Played albums"), @"label",
            @"Album", @"wikitype",
            LOCALIZED_STR(@"Recently played albums"), @"morelabel",
            @"YES", @"enableCollectionView",
            [self itemSizes_Music], @"itemSizes"
        ],
                          
        @[
            @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"genre",
                        @"year",
                        @"duration",
                        @"track",
                        @"thumbnail",
                        @"rating",
                        @"playcount",
                        @"artist",
                        @"album",
                        @"file"],
            }, @"parameters",
            LOCALIZED_STR(@"Played songs"), @"label",
            LOCALIZED_STR(@"Recently played songs"), @"morelabel"
        ],
                            
        @[
            @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"genre",
                        @"year",
                        @"duration",
                        @"track",
                        @"thumbnail",
                        @"rating",
                        @"playcount",
                        @"artist",
                        @"album",
                        @"file"]
            }, @"parameters",
            @{
                @"label": @[
                        LOCALIZED_STR(@"Name"),
                        LOCALIZED_STR(@"Rating"),
                        LOCALIZED_STR(@"Year"),
                        LOCALIZED_STR(@"Play count"),
                        LOCALIZED_STR(@"Track"),
                        LOCALIZED_STR(@"Album"),
                        LOCALIZED_STR(@"Artist")],
                @"method": @[
                        @"label",
                        @"rating",
                        @"year",
                        @"playcount",
                        @"track",
                        @"album",
                        @"genre"]
            }, @"available_sort_methods",
            LOCALIZED_STR(@"All songs"), @"label",
            LOCALIZED_STR(@"All songs"), @"morelabel",
            @"YES", @"enableLibraryCache",
            @5, @"numberOfStars",
            [self watchedListenedString], @"watchedListenedStrings"
        ],
                            
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"music",
                @"directory": @"addons://sources/audio",
                @"properties": @[
                        @"thumbnail",
                        @"file"]
            }, @"parameters",
            LOCALIZED_STR(@"Music Add-ons"), @"label",
            LOCALIZED_STR(@"Music Add-ons"), @"morelabel",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth",
            @"YES", @"enableCollectionView",
            [self itemSizes_Music], @"itemSizes"
        ],
                          
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"music",
                @"directory": @"special://musicplaylists",
                @"properties": @[
                        @"thumbnail",
                        @"file",
                        @"artist",
                        @"album",
                        @"duration"],
                @"file_properties": @[
                        @"thumbnail",
                        @"file",
                        @"artist",
                        @"album",
                        @"duration"]
            }, @"parameters",
            LOCALIZED_STR(@"Music Playlists"), @"label",
            LOCALIZED_STR(@"Music Playlists"), @"morelabel",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth",
            @"YES", @"isMusicPlaylist"
        ],
                            
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[@"title"],
            }, @"parameters",
            LOCALIZED_STR(@"Music Roles"), @"label",
            LOCALIZED_STR(@"Music Roles"), @"morelabel",
            @"nocover_genre", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth",
            [self itemSizes_Music], @"itemSizes"
        ]
                            
    ] mutableCopy];
    
    menu_Music.mainFields = @[
        @{
            @"itemid": @"albums",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"fanart",
            @"row5": @"rating",
            @"row6": @"albumid",
            @"row7": @"playcount",
            @"playlistid": @0,
            @"row8": @"albumid",
            @"row9": @"albumid",
            @"row10": @"artist",
            @"row11": @"genre",
            @"row12": @"description",
            @"row13": @"albumlabel",
            @"itemid_extra_info": @"albumdetails"
        },
        
        @{
            @"itemid": @"artists",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"yearsactive",
            @"row4": @"genre",
            @"row5": @"disbanded",
            @"row6": @"artistid",
            @"playlistid": @0,
            @"row8": @"artistid",
            @"row9": @"artistid",
            @"row10": @"formed",
            @"row11": @"artistid",
            @"row12": @"description",
            @"row13": @"instrument",
            @"row14": @"style",
            @"row15": @"mood",
            @"row16": @"born",
            @"row17": @"formed",
            @"row18": @"died",
            @"row20": @"roles",
            @"itemid_extra_info": @"artistdetails"
        },
        
        @{
            @"itemid": @"genres",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"genreid",
            @"playlistid": @0,
            @"row8": @"genreid",
            @"row9": @"genreid"
        },
        
        @{
            @"itemid": @"sources",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @0,
            @"row8": @"file",
            @"row9": @"file"
        },
        
        @{
            @"itemid": @"albums",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"fanart",
            @"row5": @"rating",
            @"row6": @"albumid",
            @"playlistid": @0,
            @"row8": @"albumid",
            @"row9": @"albumid",
            @"row10": @"artist",
            @"row11": @"genre",
            @"row12": @"description",
            @"row13": @"albumlabel",
            @"itemid_extra_info": @"albumdetails"
        },
                      
        @{
            @"itemid": @"songs",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"rating",
            @"row6": @"songid",
            @"row7": @"track",
            @"row8": @"songid",
            @"playlistid": @0,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"artist",
            @"row12": @"album"
        },
                      
        @{
            @"itemid": @"albums",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"fanart",
            @"row5": @"rating",
            @"row6": @"albumid",
            @"playlistid": @0,
            @"row8": @"albumid",
            @"row9": @"albumid",
            @"row10": @"artist",
            @"row11": @"genre",
            @"row12": @"description",
            @"row13": @"albumlabel",
            @"row14": @"playcount",
            @"itemid_extra_info": @"albumdetails"
        },
                      
        @{
            @"itemid": @"songs",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"rating",
            @"row6": @"songid",
            @"row7": @"track",
            @"row8": @"songid",
            @"playlistid": @0,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"artist",
            @"row12": @"album",
            @"row13": @"duration",
            @"row14": @"rating"
        },
                      
        @{
            @"itemid": @"albums",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"fanart",
            @"row5": @"rating",
            @"row6": @"albumid",
            @"playlistid": @0,
            @"row8": @"albumid",
            @"row9": @"albumid",
            @"row10": @"artist"
        },
                      
        @{
            @"itemid": @"songs",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"rating",
            @"row6": @"songid",
            @"row7": @"track",
            @"row8": @"songid",
            @"playlistid": @0,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"artist",
            @"row12": @"album"
        },
                      
        @{
            @"itemid": @"songs",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"rating",
            @"row6": @"songid",
            @"row7": @"track",
            @"row8": @"songid",
            @"playlistid": @0,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"artist",
            @"row12": @"album",
            @"row13": @"playcount"
        },
                      
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @0,
            @"row8": @"file",
            @"row9": @"file"
        },
                      
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"filetype",
            @"row6": @"file",
            @"playlistid": @0,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type"
        },
                      
        @{
            @"itemid": @"roles",
            @"row1": @"title",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"filetype",
            @"row6": @"roleid",
            @"playlistid": @0,
            @"row8": @"roleid",
            @"row9": @"roleid"
        }
    ];
    
    menu_Music.rowHeight = 53;
    menu_Music.thumbWidth = 53;
    menu_Music.defaultThumb = @"nocover_music";
    menu_Music.watchModes = @[
        [self modes_icons_listened],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty]
    ];

    menu_Music.sheetActions = @[
        [self action_queue_to_wiki],
        [self action_queue_to_fmcharts],
        [self action_queue_to_shuffle],
        @[],
        [self action_queue_to_wiki],
        [self action_queue_to_play],
        [self action_queue_to_wiki],
        [self action_queue_to_play],
        [self action_queue_to_wiki],
        [self action_queue_to_play],
        [self action_queue_to_play],
        @[],
        [self action_queue_to_showcontent],
        @[]
    ];
    
    menu_Music.showInfo = @[
        @YES,
        @YES,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO];
    
    menu_Music.subItem.mainMethod = @[
            @[@"AudioLibrary.GetSongs", @"method",
              @"YES", @"albumView"],
            @[@"AudioLibrary.GetAlbums", @"method",
              @"AudioLibrary.GetAlbumDetails", @"extra_info_method"],
            @[@"AudioLibrary.GetAlbums", @"method",
              @"AudioLibrary.GetAlbumDetails", @"extra_info_method"],
            @[@"Files.GetDirectory", @"method"],
            @[@"AudioLibrary.GetSongs", @"method",
              @"YES", @"albumView"],
            @[],
            @[@"AudioLibrary.GetSongs", @"method",
              @"YES", @"albumView"],
            @[],
            @[@"AudioLibrary.GetSongs", @"method",
              @"YES", @"albumView"],
            @[],
            @[],
            @[@"Files.GetDirectory", @"method"],
            @[],
            @[@"AudioLibrary.GetArtists", @"method",
              @"AudioLibrary.GetArtistDetails", @"extra_info_method"]
        ];
    
    menu_Music.subItem.mainParameters = [@[
        @[
            @{
                @"sort": [self sortmethod:@"track" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"genre",
                        @"year",
                        @"duration",
                        @"track",
                        @"thumbnail",
                        @"rating",
                        @"playcount",
                        @"artist",
                        @"albumid",
                        @"file",
                        @"fanart"]
            }, @"parameters",
            @"Songs", @"label"
        ],
        
        @[
            @{
                @"sort": [self sortmethod:@"year" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"year",
                        @"thumbnail",
                        @"artist"]
            }, @"parameters",
            @{
                @"properties": @[
                        @"year",
                        @"thumbnail",
                        @"artist",
                        @"genre",
                        @"description",
                        @"albumlabel",
                        @"fanart"]
            }, @"extra_info_parameters",
            @"Albums", @"label",
            @"Album", @"wikitype",
            @"YES", @"enableCollectionView",
            [self itemSizes_Music], @"itemSizes"
        ],
                                  
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"year",
                        @"thumbnail",
                        @"artist",
                        @"playcount"]
            }, @"parameters",
            @{
                @"properties": @[
                        @"year",
                        @"thumbnail",
                        @"artist",
                        @"genre",
                        @"description",
                        @"albumlabel",
                        @"fanart"]
            }, @"extra_info_parameters",
            @{
                @"label": @[
                        LOCALIZED_STR(@"Album"),
                        LOCALIZED_STR(@"Artist"),
                        LOCALIZED_STR(@"Year"),
                        LOCALIZED_STR(@"Play count")],
                @"method": @[
                        @"label",
                        @"genre",
                        @"year",
                        @"playcount"]
            }, @"available_sort_methods",
            @"Albums", @"label",
            @"Album", @"wikitype",
            @"YES", @"enableCollectionView",
            @"YES", @"enableLibraryCache",
            [self watchedListenedString], @"watchedListenedStrings",
            [self itemSizes_Music], @"itemSizes"
         ],
                                  
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": filemodeMusicType
            }, @"parameters",
            @"Files", @"label",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth"
        ],
                                  
        @[
            @{
                @"sort": [self sortmethod:@"track" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"genre",
                        @"year",
                        @"duration",
                        @"track",
                        @"thumbnail",
                        @"rating",
                        @"playcount",
                        @"artist",
                        @"albumid",
                        @"file",
                        @"fanart"]
            }, @"parameters",
            @"Songs", @"label"
        ],
                                  
        @[],
                                  
        @[
            @{
                @"sort": [self sortmethod:@"track" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"genre",
                        @"year",
                        @"duration",
                        @"track",
                        @"thumbnail",
                        @"rating",
                        @"playcount",
                        @"artist",
                        @"albumid",
                        @"file",
                        @"fanart"]
            }, @"parameters",
            @"Songs", @"label"
        ],
                                  
        @[],
                                  
        @[
            @{
                @"sort": [self sortmethod:@"track" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"genre",
                        @"year",
                        @"duration",
                        @"track",
                        @"thumbnail",
                        @"rating",
                        @"playcount",
                        @"artist",
                        @"albumid",
                        @"file",
                        @"fanart"]
            }, @"parameters",
            @"Songs", @"label"
        ],
                                  
        @[],
        @[],
                                  
        @[
            @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"file_properties": @[@"thumbnail"],
                @"media": @"music"
            }, @"parameters",
            @"Files", @"label",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            @"53", @"thumbWidth",
            @"YES", @"enableCollectionView",
            [self itemSizes_Movie], @"itemSizes"
        ],
        
        @[
            @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"file_properties": @[
                        @"thumbnail",
                        @"artist",
                        @"duration"],
                @"media": @"music"
            }, @"parameters",
            @"Files", @"label",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            @"53", @"thumbWidth"
        ],
                                  
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"thumbnail",
                        @"genre"],
            }, @"parameters",
            @{
                @"properties": @[
                        @"thumbnail",
                        @"genre",
                        @"instrument",
                        @"style",
                        @"mood",
                        @"born",
                        @"formed",
                        @"description",
                        @"died",
                        @"disbanded",
                        @"yearsactive",
                        @"fanart"],
                @"kodiExtrasPropertiesMinimumVersion": @{
                        @"18": @[@"roles"]
                    }
            }, @"extra_info_parameters",
            LOCALIZED_STR(@"Artists"), @"label",
            @"nocover_artist", @"defaultThumb",
            @"Artist", @"wikitype",
            @"YES", @"enableCollectionView",
            [self itemSizes_Musicfullscreen], @"itemSizes"
        ]
                                  
    ] mutableCopy];
    
    menu_Music.subItem.mainFields = @[
        @{
            @"itemid": @"songs",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"rating",
            @"row6": @"songid",
            @"row7": @"track",
            @"row8": @"albumid",
            @"playlistid": @0,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"artist"
        },
                              
        @{
            @"itemid": @"albums",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"fanart",
            @"row5": @"rating",
            @"row6": @"albumid",
            @"playlistid": @0,
            @"row8": @"albumid",
            @"row9": @"albumid",
            @"row10": @"artist",
            @"row11": @"genre",
            @"row12": @"description",
            @"row13": @"albumlabel",
            @"itemid_extra_info": @"albumdetails"
        },
                              
        @{
            @"itemid": @"albums",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"fanart",
            @"row5": @"rating",
            @"row6": @"albumid",
            @"playlistid": @0,
            @"row8": @"albumid",
            @"row9": @"albumid",
            @"row10": @"playcount",
            @"row11": @"genre",
            @"row12": @"description",
            @"row13": @"albumlabel",
            @"itemid_extra_info": @"albumdetails"
        },
                              
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"filetype",
            @"row3": @"filetype",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"file",
            @"playlistid": @0,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type"
        },
                              
        @{
            @"itemid": @"songs",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"rating",
            @"row6": @"songid",
            @"row7": @"track",
            @"row8": @"albumid",
            @"playlistid": @0,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"artist"
        },
                              
        @{},
                              
        @{
            @"itemid": @"songs",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"rating",
            @"row6": @"songid",
            @"row7": @"track",
            @"row8": @"albumid",
            @"playlistid": @0,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"artist"
        },
                              
        @{},
                              
        @{
            @"itemid": @"songs",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"rating",
            @"row6": @"songid",
            @"row7": @"track",
            @"row8": @"albumid",
            @"playlistid": @0,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"artist"
        },
                              
        @{},
        @{},
                              
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"filetype",
            @"row3": @"filetype",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"file",
            @"playlistid": @0,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type"
        },
                              
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"filetype",
            @"row6": @"file",
            @"playlistid": @0,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type"
        },
                              
        @{
            @"itemid": @"artists",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"yearsactive",
            @"row4": @"genre",
            @"row5": @"disbanded",
            @"row6": @"artistid",
            @"playlistid": @0,
            @"row8": @"artistid",
            @"row9": @"artistid",
            @"row10": @"formed",
            @"row11": @"artistid",
            @"row12": @"description",
            @"row13": @"instrument",
            @"row14": @"style",
            @"row15": @"mood",
            @"row16": @"born",
            @"row17": @"formed",
            @"row18": @"died",
            @"row20": @"roles",
            @"itemid_extra_info": @"artistdetails"
        }
    ];
    
    menu_Music.subItem.enableSection = NO;
    menu_Music.subItem.rowHeight = 53;
    menu_Music.subItem.thumbWidth = 53;
    menu_Music.subItem.defaultThumb = @"nocover_music";
    menu_Music.subItem.sheetActions = @[
        [self action_queue_to_play],
        [self action_queue_to_wiki],
        [self action_queue_to_wiki],
        [self action_queue_to_shuffle],
        [self action_queue_to_play],
        [self action_queue_to_play],
        [self action_queue_to_play],
        [self action_queue_to_play],
        [self action_queue_to_play],
        [self action_queue_to_play],
        [self action_queue_to_play],
        [self action_queue_to_play],
        [self action_queue_to_play],
        [self action_queue_to_fmcharts] //, @"Stream to iPhone"
    ];
    
    menu_Music.subItem.originYearDuration = 248;
    menu_Music.subItem.widthLabel = 252;
    menu_Music.subItem.showRuntime = @[
        @YES,
        @NO,
        @NO,
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @NO];
    
    menu_Music.subItem.subItem.mainMethod = @[
            @[],
            @[@"AudioLibrary.GetSongs", @"method",
              @"YES", @"albumView"],
            @[@"AudioLibrary.GetSongs", @"method",
              @"YES", @"albumView"],
            @[@"Files.GetDirectory", @"method"],
            @[],
            @[],
            @[],
            @[],
            @[],
            @[],
            @[],
            @[@"Files.GetDirectory", @"method"],
            @[@"Files.GetDirectory", @"method"],
            @[@"AudioLibrary.GetAlbums", @"method",
              @"AudioLibrary.GetAlbumDetails", @"extra_info_method"]
        ];
    
    menu_Music.subItem.subItem.mainParameters = [@[
                                          
        @[],

        @[
            @{
                @"sort": [self sortmethod:@"track" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"genre",
                        @"year",
                        @"duration",
                        @"track",
                        @"thumbnail",
                        @"rating",
                        @"playcount",
                        @"artist",
                        @"albumid",
                        @"file",
                        @"fanart"]
            }, @"parameters",
            @"Songs", @"label"
        ],
          
        @[
            @{
                @"sort": [self sortmethod:@"track" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"genre",
                        @"year",
                        @"duration",
                        @"track",
                        @"thumbnail",
                        @"rating",
                        @"playcount",
                        @"artist",
                        @"albumid",
                        @"file",
                        @"fanart"],
            }, @"parameters",
           @"Songs", @"label"
        ],
          
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[filemodeRowHeight, @"rowHeight", @"53", @"thumbWidth"],
        @[filemodeRowHeight, @"rowHeight", @"53", @"thumbWidth"],
          
        @[
            @{
                @"sort": [self sortmethod:@"year" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"year",
                        @"thumbnail",
                        @"artist"],
            }, @"parameters",
            @{
                @"properties": @[
                        @"year",
                        @"thumbnail",
                        @"artist",
                        @"genre",
                        @"description",
                        @"albumlabel",
                        @"fanart"]
            }, @"extra_info_parameters",
            @"Albums", @"label",
            @"Album", @"wikitype",
            @"YES", @"enableCollectionView",
            @"roleid", @"combinedFilter",
            [self itemSizes_Music], @"itemSizes"
        ]
                                          
    ] mutableCopy];
    
    menu_Music.subItem.subItem.mainFields = @[
        @{},
      
        @{
            @"itemid":@"songs",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"rating",
            @"row6": @"songid",
            @"row7": @"track",
            @"row8": @"albumid",
            @"playlistid": @0,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"artist"
        },
                                      
        @{
            @"itemid":@"songs",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"rating",
            @"row6": @"songid",
            @"row7": @"track",
            @"row8": @"albumid",
            @"playlistid": @0,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"artist"
        },
          
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
          
        @{
            @"itemid": @"albums",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"fanart",
            @"row5": @"rating",
            @"row6": @"albumid",
            @"playlistid": @0,
            @"row8": @"albumid",
            @"row9": @"albumid",
            @"row10": @"artist",
            @"row11": @"genre",
            @"row12": @"description",
            @"row13": @"albumlabel",
            @"itemid_extra_info": @"albumdetails"
        }
    ];
    
    menu_Music.subItem.subItem.rowHeight = 53;
    menu_Music.subItem.subItem.thumbWidth = 53;
    menu_Music.subItem.subItem.defaultThumb = @"nocover_music";
    menu_Music.subItem.subItem.sheetActions = @[
        [self action_queue_to_play],
        [self action_queue_to_play],//@"Stream to iPhone",
        [self action_queue_to_play],
        @[],
        [self action_queue_to_play],
        [self action_queue_to_play],
        [self action_queue_to_play],
        @[],
        @[],
        @[],
        @[],
        [self action_queue_to_play],
        [self action_queue_to_play],
        [self action_queue_to_wiki]
    ];
    
    menu_Music.subItem.subItem.showRuntime = @[
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @NO];
    
    menu_Music.subItem.subItem.subItem.mainMethod = @[
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[@"AudioLibrary.GetSongs", @"method",
          @"YES", @"albumView"]
    ];
    
    menu_Music.subItem.subItem.subItem.mainParameters = [@[
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[
            @{
                @"sort": [self sortmethod:@"track" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"genre",
                        @"year",
                        @"duration",
                        @"track",
                        @"thumbnail",
                        @"rating",
                        @"playcount",
                        @"artist",
                        @"albumid",
                        @"file",
                        @"fanart"]
            }, @"parameters",
            @"Songs", @"label"
        ]
    ] mutableCopy];
    
    menu_Music.subItem.subItem.subItem.mainFields = @[
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{
            @"itemid": @"songs",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"rating",
            @"row6": @"songid",
            @"row7": @"track",
            @"row8": @"albumid",
            @"playlistid": @0,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"artist"
        }
    ];
    
    menu_Music.subItem.subItem.subItem.rowHeight = 53;
    menu_Music.subItem.subItem.subItem.thumbWidth = 53;
    menu_Music.subItem.subItem.subItem.defaultThumb = @"nocover_music";
    menu_Music.subItem.subItem.subItem.sheetActions = @[
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        [self action_queue_to_play]
    ];
    
    menu_Music.subItem.subItem.subItem.originYearDuration = 248;
    menu_Music.subItem.subItem.subItem.widthLabel = 252;
    menu_Music.subItem.subItem.subItem.showRuntime = @[
        @YES,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
        @NO];

#pragma mark - Movies
    menu_Movies.mainLabel = LOCALIZED_STR(@"Movies");
    menu_Movies.upperLabel = LOCALIZED_STR(@"Watch your");
    menu_Movies.icon = @"icon_menu_movies";
    menu_Movies.family = FamilyDetailView;
    menu_Movies.enableSection = YES;
    menu_Movies.noConvertTime = YES;
    menu_Movies.mainButtons = @[
        @"st_movie",
        @"st_movie_genre",
        @"st_movie_set",
        @"st_movie_recently",
        @"st_music_videos",
        @"st_filemode",
        @"st_addons",
        @"st_playlists"];
    
    menu_Movies.mainMethod = @[
            @[@"VideoLibrary.GetMovies", @"method",
              @"VideoLibrary.GetMovieDetails", @"extra_info_method"],
            @[@"VideoLibrary.GetGenres", @"method"],
            @[@"VideoLibrary.GetMovieSets", @"method"],
            @[@"VideoLibrary.GetRecentlyAddedMovies", @"method",
              @"VideoLibrary.GetMovieDetails", @"extra_info_method"],
            @[@"VideoLibrary.GetMusicVideos", @"method"],
            @[@"Files.GetSources", @"method"],
            @[@"Files.GetDirectory", @"method"],
            @[@"Files.GetDirectory", @"method"]
        ];
    
    menu_Movies.mainParameters = [@[
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"year",
                        @"playcount",
                        @"rating",
                        @"thumbnail",
                        @"genre",
                        @"runtime",
                        @"trailer",
                        @"file",
                        @"dateadded"]
                }, @"parameters",
            @{
                @"properties": @[
                        @"year",
                        @"playcount",
                        @"rating",
                        @"thumbnail",
                        @"genre",
                        @"runtime",
                        @"studio",
                        @"director",
                        @"plot",
                        @"mpaa",
                        @"votes",
                        @"cast",
                        @"file",
                        @"fanart",
                        @"resume",
                        @"trailer"]
            }, @"extra_info_parameters",
            @{
                @"label": @[
                        LOCALIZED_STR(@"Title"),
                        LOCALIZED_STR(@"Year"),
                        LOCALIZED_STR(@"Rating"),
                        LOCALIZED_STR(@"Duration"),
                        LOCALIZED_STR(@"Date added"),
                        LOCALIZED_STR(@"Play count")],
                @"method": @[
                        @"label",
                        @"year",
                        @"rating",
                        @"runtime",
                        @"dateadded",
                        @"playcount"]
            }, @"available_sort_methods",
            LOCALIZED_STR(@"Movies"), @"label",
            @"Movie", @"wikitype",
            @"YES", @"FrodoExtraArt",
            @"YES", @"enableCollectionView",
            @"YES", @"enableLibraryCache",
            @"YES", @"enableLibraryFullScreen",
            [self itemSizes_Moviefullscreen], @"itemSizes"
        ],
              
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"type": @"movie",
                @"properties": @[@"thumbnail"]
            }, @"parameters",
            LOCALIZED_STR(@"Movie Genres"), @"label",
            @"nocover_movie_genre", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth",
            @"YES", @"enableLibraryCache"
        ],
              
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"thumbnail",
                        @"playcount"]
            }, @"parameters",
            @{
                @"label": @[
                        LOCALIZED_STR(@"Name"),
                        LOCALIZED_STR(@"Play count")],
                @"method": @[
                        @"label",
                        @"playcount"]
            }, @"available_sort_methods",
            @"YES", @"FrodoExtraArt",
            @"YES", @"enableCollectionView",
            @"YES", @"enableLibraryCache",
            @"nocover_movie_sets", @"defaultThumb",
            [self itemSizes_Movie], @"itemSizes",
            LOCALIZED_STR(@"Movie Sets"), @"label"
        ],
              
        @[
            @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"year",
                        @"playcount",
                        @"rating",
                        @"thumbnail",
                        @"genre",
                        @"runtime",
                        @"trailer",
                        @"fanart",
                        @"file"]
            }, @"parameters",
            LOCALIZED_STR(@"Added Movies"), @"label",
            @"Movie", @"wikitype",
            @{
                @"properties": @[
                        @"year",
                        @"playcount",
                        @"rating",
                        @"thumbnail",
                        @"genre",
                        @"runtime",
                        @"studio",
                        @"director",
                        @"plot",
                        @"mpaa",
                        @"votes",
                        @"cast",
                        @"file",
                        @"fanart",
                        @"resume",
                        @"trailer"]
                    }, @"extra_info_parameters",
            @"YES", @"FrodoExtraArt",
            @"YES", @"enableCollectionView",
            @"YES", @"collectionViewRecentlyAdded",
            @"YES", @"enableLibraryFullScreen",
            [self itemSizes_MovieRecentlyfullscreen], @"itemSizes"
        ],
              
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"year",
                        @"playcount",
                        @"thumbnail",
                        @"genre",
                        @"runtime",
                        @"studio",
                        @"director",
                        @"plot",
                        @"file",
                        @"fanart",
                        @"resume"]
            }, @"parameters",
            @{
                @"label": @[
                        LOCALIZED_STR(@"Name"),
                        LOCALIZED_STR(@"Year"),
                        LOCALIZED_STR(@"Play count")],
                @"method": @[
                            @"label",
                            @"year",
                            @"playcount"]
            }, @"available_sort_methods",
            LOCALIZED_STR(@"Music Videos"), @"label",
            LOCALIZED_STR(@"Music Videos"), @"morelabel",
            @"Movie", @"wikitype",
            @"YES", @"enableCollectionView",
            @"YES", @"enableLibraryCache",
            @"YES", @"enableLibraryFullScreen",
            [self itemSizes_Moviefullscreen], @"itemSizes"
        ],

        @[
            @{
                @"media": @"video"
            }, @"parameters",
            @"Files", @"label",
            LOCALIZED_STR(@"Files"), @"morelabel",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth"
        ],
              
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
                @"directory": @"addons://sources/video",
                @"properties": @[@"thumbnail"]
            }, @"parameters",
            @"Video Add-ons", @"label",
            LOCALIZED_STR(@"Video Add-ons"), @"morelabel",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth",
            @"YES", @"enableCollectionView",
            [self itemSizes_Music], @"itemSizes"
        ],

        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
                @"directory": @"special://videoplaylists",
                @"properties": @[
                        @"thumbnail",
                        @"file"],
                @"file_properties": @[
                        @"thumbnail",
                        @"file"]
            }, @"parameters",
            LOCALIZED_STR(@"Video Playlists"), @"label",
            LOCALIZED_STR(@"Video Playlists"), @"morelabel",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth",
            @"YES", @"isVideoPlaylist"
        ]
        
    ] mutableCopy];
    
    menu_Movies.mainFields = @[
        @{
            @"itemid": @"movies",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"movieid",
            @"playlistid": @1,
            @"row8": @"movieid",
            @"row9": @"movieid",
            @"row10": @"playcount",
            @"row11": @"trailer",
            @"row12": @"plot",
            @"row13": @"mpaa",
            @"row14": @"votes",
            @"row15": @"studio",
            @"row16": @"cast",
            @"row7": @"file",
            @"row17": @"director",
            @"row18": @"resume",
            @"row19": @"dateadded",
            @"itemid_extra_info": @"moviedetails"
        },
                      
        @{
            @"itemid": @"genres",
            @"row1": @"label",
            @"row2": @"label",
            @"row3": @"disable",
            @"row4": @"disable",
            @"row5": @"disable",
            @"row6": @"genre",
            @"playlistid": @1,
            @"row8": @"genreid"
        },
                      
        @{
            @"itemid": @"sets",
            @"row1": @"label",
            @"row2": @"disable",
            @"row3": @"disable",
            @"row4": @"disable",
            @"row5": @"disable",
            @"row6": @"setid",
            @"playlistid": @1,
            @"row8": @"setid",
            @"row9": @"setid",
            @"row10": @"playcount"
        },

        @{
            @"itemid": @"movies",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"movieid",
            @"playlistid": @1,
            @"row8": @"movieid",
            @"row9": @"movieid",
            @"row10": @"playcount",
            @"row11": @"trailer",
            @"row12": @"plot",
            @"row13": @"mpaa",
            @"row14": @"votes",
            @"row15": @"studio",
            @"row16": @"cast",
            @"row7": @"file",
            @"row17": @"director",
            @"row18": @"resume",
            @"itemid_extra_info": @"moviedetails"
        },
                      
        @{
            @"itemid": @"musicvideos",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"musicvideoid",
            @"playlistid": @1,
            @"row8": @"musicvideoid",
            @"row9": @"musicvideoid",
            @"row10": @"director",
            @"row11": @"studio",
            @"row12": @"plot",
            @"row13": @"playcount",
            @"row14": @"resume",
            @"row15": @"votes",
            @"row16": @"cast",
            @"row7": @"file"
        },
                      
        @{
            @"itemid": @"sources",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @1,
            @"row8": @"file",
            @"row9": @"file"
        },
                      
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @1,
            @"row8": @"file",
            @"row9": @"file"
        },
                      
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"filetype",
            @"row6": @"file",
            @"playlistid": @1,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type"
           //@"row11": @"filetype",
        }
    ];
    
    menu_Movies.rowHeight = 76;
    menu_Movies.thumbWidth = 53;
    menu_Movies.defaultThumb = @"nocover_movies";
    menu_Movies.sheetActions = @[
        [self action_queue_to_moviedetails], //, LOCALIZED_STR(@"Open with VLC")
        @[],
        [self action_queue_to_play],
        [self action_queue_to_moviedetails], //, LOCALIZED_STR(@"Open with VLC"),
        [self action_queue_to_musicvideodetails], //, LOCALIZED_STR(@"Open with VLC")
        @[],
        @[],
        [self action_queue_to_showcontent]
    ];
    
    //    menu_Movies.showInfo = YES;
    menu_Movies.showInfo = @[
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @YES,
        @NO];
    
    menu_Movies.watchModes = @[
        [self modes_icons_watched],
        [self modes_icons_empty],
        [self modes_icons_watched],
        [self modes_icons_watched],
        [self modes_icons_watched],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty]
    ];
    
    menu_Movies.subItem.mainMethod = [@[
        @[],
        @[@"VideoLibrary.GetMovies", @"method",
          @"VideoLibrary.GetMovieDetails", @"extra_info_method"],
        @[@"VideoLibrary.GetMovies", @"method",
          @"VideoLibrary.GetMovieDetails", @"extra_info_method"],
        @[],
        @[],
        @[@"Files.GetDirectory", @"method"],
        @[@"Files.GetDirectory", @"method"],
        @[]
    ] mutableCopy];
    
    menu_Movies.subItem.noConvertTime = YES;

    menu_Movies.subItem.mainParameters = [@[
                                  
        @[],
                                  
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"year",
                        @"playcount",
                        @"rating",
                        @"thumbnail",
                        @"genre",
                        @"runtime",
                        @"trailer",
                        @"file",
                        @"dateadded"]
            }, @"parameters",
            @{
                @"properties": @[
                        @"year",
                        @"playcount",
                        @"rating",
                        @"thumbnail",
                        @"genre",
                        @"runtime",
                        @"studio",
                        @"director",
                        @"plot",
                        @"mpaa",
                        @"votes",
                        @"cast",
                        @"file",
                        @"fanart",
                        @"resume",
                        @"trailer"]
            }, @"extra_info_parameters",
            @{
                @"label": @[
                        LOCALIZED_STR(@"Title"),
                        LOCALIZED_STR(@"Year"),
                        LOCALIZED_STR(@"Rating"),
                        LOCALIZED_STR(@"Duration"),
                        LOCALIZED_STR(@"Date added"),
                        LOCALIZED_STR(@"Play count")],
                @"method": @[
                        @"label",
                        @"year",
                        @"rating",
                        @"runtime",
                        @"dateadded",
                        @"playcount"]
            }, @"available_sort_methods",
            @"Movies", @"label",
            @"Movie", @"wikitype",
            @"nocover_movies", @"defaultThumb",
            @"YES", @"FrodoExtraArt",
            @"YES", @"enableCollectionView",
            @"YES", @"enableLibraryCache",
            [self itemSizes_Movie], @"itemSizes"
        ],
                                  
        @[
            @{
                @"sort": [self sortmethod:@"year" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"year",
                        @"playcount",
                        @"rating",
                        @"thumbnail",
                        @"genre",
                        @"runtime",
                        @"trailer",
                        @"file",
                        @"dateadded"],
            }, @"parameters",
            @{
                @"properties": @[
                        @"year",
                        @"playcount",
                        @"rating",
                        @"thumbnail",
                        @"genre",
                        @"runtime",
                        @"studio",
                        @"director",
                        @"plot",
                        @"mpaa",
                        @"votes",
                        @"cast",
                        @"file",
                        @"fanart",
                        @"resume",
                        @"trailer"]
            }, @"extra_info_parameters",
            @{
                @"label": @[
                        LOCALIZED_STR(@"Title"),
                        LOCALIZED_STR(@"Year"),
                        LOCALIZED_STR(@"Rating"),
                        LOCALIZED_STR(@"Duration"),
                        LOCALIZED_STR(@"Date added"),
                        LOCALIZED_STR(@"Play count")],
                @"method": @[
                        @"label",
                        @"year",
                        @"rating",
                        @"runtime",
                        @"dateadded",
                        @"playcount"]
            }, @"available_sort_methods",
            @"Movies", @"label",
            @"Movie", @"wikitype",
            @"nocover_movies", @"defaultThumb",
            @"YES", @"FrodoExtraArt",
            @"YES", @"enableCollectionView",
            [self itemSizes_Movie], @"itemSizes"
        ],
                                  
        @[],
        @[],
                                  
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": filemodeVideoType
            }, @"parameters",
            @"Files", @"label",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth"
        ],
                                  
        @[
            @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
                @"file_properties": @[@"thumbnail"]
            }, @"parameters",
            @"Video Add-ons", @"label",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth",
            @"YES", @"enableCollectionView",
            [self itemSizes_Music], @"itemSizes"
        ],
                                  
        @[
            @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"file_properties": @[
                        @"year",
                        @"playcount",
                        @"rating",
                        @"thumbnail",
                        @"genre",
                        @"runtime",
                        @"trailer",
                        @"file",
                        @"dateadded",
                        @"uniqueid",
                        @"studio",
                        @"director",
                        @"plot",
                        @"mpaa",
                        @"votes",
                        @"cast",
                        @"fanart",
                        @"resume"],
                @"media": @"video"
            }, @"parameters",
            @"Files", @"label",
            @"nocover_filemode", @"defaultThumb",
            @"76", @"rowHeight",
            @"53", @"thumbWidth",
            @"YES", @"enableCollectionView",
            @"YES", @"FrodoExtraArt",
            [self itemSizes_Movie], @"itemSizes"
        ]
    ] mutableCopy];
    
    menu_Movies.subItem.mainFields = @[
        @{},
                              
        @{
            @"itemid": @"movies",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"movieid",
            @"playlistid": @1,
            @"row8": @"movieid",
            @"row9": @"movieid",
            @"row10": @"playcount",
            @"row11": @"trailer",
            @"row12": @"plot",
            @"row13": @"mpaa",
            @"row14": @"votes",
            @"row15": @"studio",
            @"row16": @"cast",
            @"row7": @"file",
            @"row17": @"director",
            @"row18": @"resume",
            @"row19": @"dateadded",
            @"itemid_extra_info": @"moviedetails"
        },
                              
        @{
            @"itemid": @"movies",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"movieid",
            @"playlistid": @1,
            @"row8": @"movieid",
            @"row9": @"movieid",
            @"row10": @"playcount",
            @"row11": @"trailer",
            @"row12": @"plot",
            @"row13": @"mpaa",
            @"row14": @"votes",
            @"row15": @"studio",
            @"row16": @"cast",
            @"row7": @"file",
            @"row17": @"director",
            @"row18": @"resume",
            @"row19": @"dateadded",
            @"itemid_extra_info": @"moviedetails"
        },
                              
        @{},
        @{},
                              
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"filetype",
            @"row3": @"filetype",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"file",
            @"playlistid": @1,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type"
        },
                              
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"filetype",
            @"row3": @"filetype",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"file",
            @"row7": @"plugin",
            @"playlistid": @1,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type"
        },
                              
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @1,
            @"row8": @"uniqueid",
            @"row9": @"file",
            @"row10": @"playcount",
            @"row11": @"trailer",
            @"row12": @"plot",
            @"row13": @"mpaa",
            @"row14": @"votes",
            @"row15": @"studio",
            @"row16": @"cast",
            @"row7": @"file",
            @"row17": @"director",
            @"row18": @"resume",
            @"row19": @"dateadded"
            //@"itemid_extra_info": @"moviedetails",
        }
    ];
    
    menu_Movies.subItem.enableSection = NO;
    menu_Movies.subItem.rowHeight = 76;
    menu_Movies.subItem.thumbWidth = 53;
    menu_Movies.subItem.defaultThumb = @"nocover_movies";
    menu_Movies.subItem.sheetActions = @[
        @[],
        [self action_queue_to_moviedetails], //, LOCALIZED_STR(@"Open with VLC")
        [self action_queue_to_moviedetails], //, LOCALIZED_STR(@"Open with VLC")
        @[],
        @[],
        [self action_queue_to_play], //, LOCALIZED_STR(@"Open with VLC")
        [self action_queue_to_play],
        [self action_queue_to_moviedetails]
    ];
    
    menu_Movies.subItem.showInfo = @[
        @NO,
        @YES,
        @YES,
        @NO,
        @NO,
        @NO,
        @NO,
        @YES];
    
    menu_Movies.subItem.watchModes = @[
        [self modes_icons_empty],
        [self modes_icons_watched],
        [self modes_icons_watched],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty]
    ];

    menu_Movies.subItem.widthLabel = 252;
    
    menu_Movies.subItem.subItem.noConvertTime = YES;
    menu_Movies.subItem.subItem.mainMethod = [@[
        @[],
        @[],
        @[],
        @[],
        @[],
        @[@"Files.GetDirectory", @"method"],
        @[@"Files.GetDirectory", @"method"],
        @[]
    ] mutableCopy];
    
    menu_Movies.subItem.subItem.mainParameters = [@[
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[filemodeRowHeight, @"rowHeight",
          filemodeThumbWidth, @"thumbWidth"],
        @[]
    ] mutableCopy];
    
    menu_Movies.subItem.subItem.mainFields = @[
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{}
    ];
    
    menu_Movies.subItem.subItem.enableSection = NO;
    menu_Movies.subItem.subItem.rowHeight = 76;
    menu_Movies.subItem.subItem.thumbWidth = 53;
    menu_Movies.subItem.subItem.defaultThumb = @"nocover_filemode";
    menu_Movies.subItem.subItem.sheetActions = @[
        @[],
        @[],
        @[],
        @[],
        @[],
        [self action_queue_to_play],
        [self action_queue_to_play]
    ];
    
    menu_Movies.subItem.subItem.widthLabel = 252;
    
#pragma mark - TV Shows
    menu_TVShows.mainLabel = LOCALIZED_STR(@"TV Shows");
    menu_TVShows.upperLabel = LOCALIZED_STR(@"Watch your");
    menu_TVShows.icon = @"icon_menu_tvshows";
    menu_TVShows.family = FamilyDetailView;
    menu_TVShows.enableSection = YES;
    menu_TVShows.mainButtons = @[
        @"st_tv",
        @"st_tv_recently",
        @"st_filemode",
        @"st_addons"];//@"st_movie_genre",
    
    menu_TVShows.mainMethod = [@[
        @[@"VideoLibrary.GetTVShows", @"method",
          @"VideoLibrary.GetTVShowDetails", @"extra_info_method",
          @"YES", @"tvshowsView"],
        //@[@"VideoLibrary.GetGenres", @"method"],
        @[@"VideoLibrary.GetRecentlyAddedEpisodes", @"method",
          @"VideoLibrary.GetEpisodeDetails", @"extra_info_method"],
        @[@"Files.GetSources", @"method"],
        @[@"Files.GetDirectory", @"method"]
    ] mutableCopy];
    
    menu_TVShows.mainParameters = [@[
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"year",
                        @"playcount",
                        @"rating",
                        @"thumbnail",
                        @"genre",
                        @"studio"]
            }, @"parameters",
            @{
                @"properties": @[
                        @"year",
                        @"playcount",
                        @"rating",
                        @"thumbnail",
                        @"genre",
                        @"studio",
                        @"plot",
                        @"mpaa",
                        @"votes",
                        @"cast",
                        @"premiered",
                        @"episode",
                        @"fanart"]
            }, @"extra_info_parameters",
            @{
                @"label": @[
                        LOCALIZED_STR(@"Title"),
                        LOCALIZED_STR(@"Year"),
                        LOCALIZED_STR(@"Rating")],
                @"method": @[
                        @"label",
                        @"year",
                        @"rating"]
            }, @"available_sort_methods",
            LOCALIZED_STR(@"TV Shows"), @"label",
            @"TV Show", @"wikitype",
            @"YES", @"blackTableSeparator",
            @"YES", @"FrodoExtraArt",
            @"YES", @"enableLibraryCache",
            [self itemSizes_insets:@"0"], @"itemSizes"
        ],
                            
        @[
            @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"episode",
                        @"thumbnail",
                        @"firstaired",
                        @"playcount",
                        @"showtitle",
                        @"file"],
            }, @"parameters",
            @{
                @"properties": @[
                        @"episode",
                        @"thumbnail",
                        @"firstaired",
                        @"runtime",
                        @"plot",
                        @"director",
                        @"writer",
                        @"rating",
                        @"showtitle",
                        @"season",
                        @"cast",
                        @"file",
                        @"fanart",
                        @"playcount",
                        @"resume"]
            }, @"extra_info_parameters",
            LOCALIZED_STR(@"Added Episodes"), @"label",
            @"53", @"rowHeight",
            @"95", @"thumbWidth",
            @"nocover_tvshows_episode", @"defaultThumb",
            @"YES", @"FrodoExtraArt",
            //@"YES", @"enableCollectionView",
            [self itemSizes_TVShowsfullscreen_insets:@"95"], @"itemSizes"
        ],
                            
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"video"
            }, @"parameters",
            LOCALIZED_STR(@"Files"), @"label",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth",
            [self itemSizes_insets:@"53"], @"itemSizes"
        ],
                            
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
                @"directory": @"addons://sources/video",
                @"properties": @[@"thumbnail"]
            }, @"parameters",
            LOCALIZED_STR(@"Video Add-ons"), @"label",
            LOCALIZED_STR(@"Video Add-ons"), @"morelabel",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth",
            @"YES", @"enableCollectionView",
            [self itemSizes_Music_insets:filemodeThumbWidth], @"itemSizes"
        ],
    ] mutableCopy];

    menu_TVShows.mainFields = @[
        @{
            @"itemid": @"tvshows",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"studio",
            @"row5": @"rating",
            @"row6": @"tvshowid",
            @"playlistid": @1,
            @"row8": @"tvshowid",
            @"row9": @"playcount",
            @"row10": @"mpaa",
            @"row11": @"votes",
            @"row12": @"cast",
            @"row13": @"premiered",
            @"row14": @"episode",
            //@"row7": @"fanart",
            @"row15": @"plot",
            @"row16": @"studio",
            @"itemid_extra_info": @"tvshowdetails"
        },
/*
        @{
            @"itemid": @"genres",
            @"row1": @"label",
            @"row2": @"label",
            @"row3": @"disable",
            @"row4": @"disable",
            @"row5": @"disable",
            @"row6": @"genre",
            @"playlistid": @1,
            @"row8": @"genreid",
        },
*/
        @{
            @"itemid": @"episodes",
            @"row1": @"label",
            @"row2": @"showtitle",
            @"row3": @"firstaired",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"episodeid",
            @"row7": @"playcount",
            @"row8": @"episodeid",
            @"playlistid": @1,
            @"row9": @"episodeid",
            @"row10": @"file",
            @"row11": @"director",
            @"row12": @"writer",
            @"row13": @"resume",
            @"row14": @"showtitle",
            @"row15": @"plot",
            @"row16": @"cast",
            @"row17": @"firstaired",
            @"row18": @"season",
            //@"row20": @"file",
            //@"row7": @"file",
            @"itemid_extra_info": @"episodedetails"
        },
                        
        @{
            @"itemid": @"sources",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @1,
            @"row8": @"file",
            @"row9": @"file"
        },
                        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @1,
            @"row8": @"file",
            @"row9": @"file"
        }
    ];
    
    menu_TVShows.rowHeight = tvshowHeight;
    menu_TVShows.thumbWidth = thumbWidth;
    menu_TVShows.defaultThumb = @"nocover_tvshows";
    menu_TVShows.originLabel = 60;
    menu_TVShows.sheetActions = @[
        @[LOCALIZED_STR(@"TV Show Details")],
        //@[],
        [self action_queue_to_episodedetails],
        @[],
        @[]
    ];
    
    menu_TVShows.showInfo = @[
        @NO,
        //@NO,
        @YES,
        @NO,
        @NO];
    
    menu_TVShows.watchModes = @[
        [self modes_icons_watched],
        //[self modes_icons_empty]
        [self modes_icons_watched],
        [self modes_icons_empty],
        [self modes_icons_empty]
    ];
    
    menu_TVShows.subItem.mainMethod = [@[
        @[@"VideoLibrary.GetEpisodes", @"method",
          @"VideoLibrary.GetEpisodeDetails", @"extra_info_method",
          @"YES", @"episodesView",
          @"VideoLibrary.GetSeasons", @"extra_section_method"],
        //@[@"VideoLibrary.GetTVShows", @"method",
        //  @"VideoLibrary.GetTVShowDetails", @"extra_info_method"],
        @[],
        @[@"Files.GetDirectory", @"method"],
        @[@"Files.GetDirectory", @"method"]
    ] mutableCopy];
    
    menu_TVShows.subItem.mainParameters = [@[
        @[
            @{
                @"sort": @{
                        @"order": @"ascending",
                        @"method": @"episode"},
                @"properties": @[
                        @"episode",
                        @"thumbnail",
                        @"firstaired",
                        @"showtitle",
                        @"playcount",
                        @"season",
                        @"tvshowid",
                        @"runtime",
                        @"file"],
            }, @"parameters",
            @{
                @"properties": @[
                        @"episode",
                        @"thumbnail",
                        @"firstaired",
                        @"runtime",
                        @"plot",
                        @"director",
                        @"writer",
                        @"rating",
                        @"showtitle",
                        @"season",
                        @"cast",
                        @"fanart",
                        @"resume",
                        @"playcount",
                        @"file"],
            }, @"extra_info_parameters",
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"season",
                        @"thumbnail",
                        @"tvshowid",
                        @"playcount",
                        @"episode",
                        @"art"]
            }, @"extra_section_parameters",
            @"Episodes", @"label",
            @"YES", @"disableFilterParameter",
            @"YES", @"FrodoExtraArt"
        ],
/*
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"year",
                        @"playcount",
                        @"rating",
                        @"thumbnail",
                        @"genre",
                        @"studio"]
            }, @"parameters",
            @{
                @"properties": @[
                         @"year",
                         @"playcount",
                         @"rating",
                         @"thumbnail",
                         @"genre",
                         @"studio",
                         @"plot",
                         @"mpaa",
                         @"votes",
                         @"cast",
                         @"premiered",
                         @"episode",
                         @"fanart"]
            }, @"extra_info_parameters",
            @"TV Shows", @"label",
            @"TV Show", @"wikitype",
            @tvshowHeight, @"rowHeight",
            @thumbWidth, @"thumbWidth",
            @"YES", @"blackTableSeparator",
            @"YES", @"FrodoExtraArt"
        ],
*/
        @[],
                                    
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": filemodeVideoType
            }, @"parameters",
            @"Files", @"label",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth"
        ],
                                    
        @[
            @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
                @"file_properties": @[@"thumbnail"]
            }, @"parameters",
            @"Video Add-ons", @"label",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth",
            @"YES", @"enableCollectionView",
            [self itemSizes_Music], @"itemSizes"
        ]
    ] mutableCopy];
    
    menu_TVShows.subItem.mainFields = @[
        @{
            @"itemid": @"episodes",
            @"row1": @"label",
            @"row2": @"showtitle",
            @"row3": @"firstaired",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"episodeid",
            @"row7": @"playcount",
            @"row8": @"episodeid",
            @"playlistid": @1,
            @"row9": @"episodeid",
            @"row10": @"season",
            @"row11": @"tvshowid",
            @"row12": @"file",
            @"row13": @"writer",
            @"row14": @"firstaired",
            @"row15": @"showtitle",
            @"row16": @"cast",
            @"row17": @"director",
            @"row18": @"resume",
            @"row19": @"episode",
            @"row20": @"plot",
            @"itemid_extra_info": @"episodedetails",
            @"itemid_extra_section": @"seasons"
        },
/*
        @{
            @"itemid": @"tvshows",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"blank",
            @"row4": @"studio",
            @"row5": @"rating",
            @"row6": @"tvshowid",
            @"playlistid": @1,
            @"row8": @"tvshowid",
            @"row9": @"playcount",
            @"row10": @"mpaa",
            @"row11": @"votes",
            @"row12": @"cast",
            @"row13": @"premiered",
            @"row14": @"episode",
            @"row7": @"fanart",
            @"row15": @"plot",
            @"row16": @"studio",
            @"itemid_extra_info": @"tvshowdetails"
        },
*/
        @[],
                                
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"filetype",
            @"row3": @"filetype",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"file",
            @"playlistid": @1,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type"
        },
                                
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"filetype",
            @"row3": @"filetype",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"file",
            @"row7": @"plugin",
            @"playlistid": @1,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type"
        }
    ];
    
    menu_TVShows.subItem.enableSection = NO;
    menu_TVShows.subItem.rowHeight = 53;
    menu_TVShows.subItem.thumbWidth = 95;
    menu_TVShows.subItem.defaultThumb = @"nocover_tvshows_episode";
    menu_TVShows.subItem.sheetActions = @[
        [self action_queue_to_episodedetails], //, LOCALIZED_STR(@"Open with VLC")
        //@[@"TV Show Details"],
        @[],
        [self action_queue_to_play], //, LOCALIZED_STR(@"Open with VLC")
        [self action_queue_to_play] //, @"Stream to iPhone"
    ];
    
    menu_TVShows.subItem.originYearDuration = 248;
    menu_TVShows.subItem.widthLabel = 208;
    menu_TVShows.subItem.showRuntime = @[
        @NO,
        //@NO,
        @NO,
        @NO,
        @NO];
    
    menu_TVShows.subItem.noConvertTime = YES;
    menu_TVShows.subItem.showInfo = @[
        @YES,
        //@NO,
        @YES,
        @YES,
        @YES];
    
    menu_TVShows.subItem.subItem.mainMethod = [@[
        @[],
        //@[],
        @[],
        @[@"Files.GetDirectory", @"method"],
        @[@"Files.GetDirectory", @"method"]
    ] mutableCopy];
                                        
    menu_TVShows.subItem.subItem.mainParameters = [@[
        @[],
        //@[],
        @[],
        @[],
        @[filemodeRowHeight, @"rowHeight",
          filemodeThumbWidth, @"thumbWidth"]
    ] mutableCopy];
    
    menu_TVShows.subItem.subItem.mainFields = @[
        @[],
        //@[],
        @[],
        @[],
        @[]
    ];
        
    menu_TVShows.subItem.subItem.enableSection = NO;
    menu_TVShows.subItem.subItem.rowHeight = 53;
    menu_TVShows.subItem.subItem.thumbWidth = 95;
    menu_TVShows.subItem.subItem.defaultThumb = @"nocover_tvshows_episode";
    menu_TVShows.subItem.subItem.sheetActions = @[
        @[],
        //@[],
        @[],
        [self action_queue_to_play],
        [self action_queue_to_play]
    ];
        
    menu_TVShows.subItem.subItem.originYearDuration = 248;
    menu_TVShows.subItem.subItem.widthLabel = 208;
    menu_TVShows.subItem.subItem.showRuntime = @[
        @NO,
        //@NO,
        @NO,
        @NO,
        @NO];
        
    menu_TVShows.subItem.subItem.noConvertTime = YES;
    menu_TVShows.subItem.subItem.showInfo = @[
        @YES,
        //@YES,
        @YES,
        @YES,
        @YES];

#pragma mark - Live TV
    menu_LiveTV.mainLabel = LOCALIZED_STR(@"Live TV");
    menu_LiveTV.upperLabel = LOCALIZED_STR(@"Watch");
    menu_LiveTV.icon = @"icon_menu_livetv";
    menu_LiveTV.family = FamilyDetailView;
    menu_LiveTV.enableSection = YES;
    menu_LiveTV.noConvertTime = YES;
    menu_LiveTV.mainButtons = @[
        @"st_livetv",
        @"st_radio",
        @"st_recordings",
        @"st_timers"];
    
    menu_LiveTV.mainMethod = [@[
        @[@"PVR.GetChannelGroups", @"method"],
        @[@"PVR.GetChannelGroups", @"method"],
        @[@"PVR.GetRecordings", @"method",
          @"PVR.GetRecordingDetails", @"extra_info_method"],
        @[@"PVR.GetTimers", @"method",
          @"PVR.GetTimerDetails", @"extra_info_method"]
    ] mutableCopy];
    
    menu_LiveTV.mainParameters = [@[
        @[
            @{
                @"channeltype": @"tv"
            }, @"parameters",
            LOCALIZED_STR(@"Live TV"), @"label",
            LOCALIZED_STR(@"Live TV"), @"morelabel",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth",
            @"YES", @"enableCollectionView",
            [self itemSizes_Music], @"itemSizes"
        ],
                          
        @[
            @{
                @"channeltype": @"radio"
            }, @"parameters",
            LOCALIZED_STR(@"Radio"), @"label",
            LOCALIZED_STR(@"Radio"), @"morelabel",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth",
            @"YES", @"enableCollectionView",
            [self itemSizes_Music], @"itemSizes"
        ],

        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"title",
                        @"starttime",
                        @"endtime",
                        @"plot",
                        @"plotoutline",
                        @"genre",
                        @"playcount",
                        @"resume",
                        @"channel",
                        @"runtime",
                        @"lifetime",
                        @"icon",
                        @"art",
                        @"streamurl",
                        @"file",
                        @"directory"]
                    }, @"parameters",
            @{
                @"properties": @[
                        @"title",
                        @"starttime",
                        @"endtime",
                        @"plot",
                        @"plotoutline",
                        @"genre",
                        @"playcount",
                        @"resume",
                        @"channel",
                        @"runtime",
                        @"lifetime",
                        @"icon",
                        @"art",
                        @"streamurl",
                        @"file",
                        @"directory"]
            }, @"extra_info_parameters",
            @{
                @"label": @[
                        LOCALIZED_STR(@"Title"),
                        LOCALIZED_STR(@"Channel"),
                        LOCALIZED_STR(@"Date"),
                        LOCALIZED_STR(@"Runtime")],
                @"method": @[
                        @"label",
                        @"channel",
                        @"starttime",
                        @"runtime"]
            }, @"available_sort_methods",
            LOCALIZED_STR(@"Recordings"), @"label",
            LOCALIZED_STR(@"Recordings"), @"morelabel",
            @"nocover_channels", @"defaultThumb",
            channelEPGRowHeight, @"rowHeight",
            @"48", @"thumbWidth",
            @"YES", @"enableCollectionView",
            [self itemSizes_Music_insets:@"60"], @"itemSizes"
        ],
                          
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                        @"title",
                        @"summary",
                        @"channelid",
                        @"isradio",
                        @"starttime",
                        @"endtime",
                        @"runtime",
                        @"lifetime",
                        @"firstday",
                        @"weekdays",
                        @"priority",
                        @"startmargin",
                        @"endmargin",
                        @"state",
                        @"file",
                        @"directory"]
                }, @"parameters",
            @{
                @"properties": @[
                        @"title",
                        @"summary",
                        @"starttime",
                        @"endtime",
                        @"runtime",
                        @"lifetime",
                        @"firstday",
                        @"weekdays",
                        @"priority",
                        @"startmargin",
                        @"endmargin",
                        @"state",
                        @"file",
                        @"directory"]
            }, @"extra_info_parameters",
            @{
                @"label": @[
                        LOCALIZED_STR(@"Title"),
                        LOCALIZED_STR(@"Channel"),
                        LOCALIZED_STR(@"Date"),
                        LOCALIZED_STR(@"Runtime")],
                @"method": @[
                        @"label",
                        @"channel",
                        @"starttime",
                        @"runtime"]
            }, @"available_sort_methods",
            LOCALIZED_STR(@"Timers"), @"label",
            LOCALIZED_STR(@"Timers"), @"morelabel",
            @"nocover_timers", @"defaultThumb",
            @"53", @"rowHeight",
            @"53", @"thumbWidth",
            @"YES", @"enableCollectionView",
            [self itemSizes_Music_insets:@"60"], @"itemSizes"
        ]
                          
    ] mutableCopy];
    
    menu_LiveTV.mainFields = @[
        @{
            @"itemid": @"channelgroups",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"channelgroupid",
            @"playlistid": @1,
            @"row8": @"channelgroupid",
            @"row9": @"channelgroupid"
        },
                      
        @{
            @"itemid": @"channelgroups",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"channelgroupid",
            @"playlistid": @1,
            @"row8": @"channelgroupid",
            @"row9": @"channelgroupid"
        },

        @{
            @"itemid": @"recordings",
            @"row1": @"label",
            @"row2": @"plotoutline",
            @"row3": @"plot",
            @"row4": @"runtime",
            @"row5": @"starttime",
            @"row6": @"recordingid",
            @"playlistid": @1,
            @"row8": @"recordingid",
            @"row9": @"recordingid",
            @"row10": @"file",
            @"row11": @"channel",
            @"row12": @"starttime",
            @"row13": @"endtime",
            @"row14": @"playcount",
            @"row15": @"plot",
            @"itemid_extra_info": @"recordingdetails"
        },
                      
        @{
            @"itemid": @"timers",
            @"row1": @"label",
            @"row2": @"summary",
            @"row3": @"plot",
            @"row4": @"plotoutline",
            @"row5": @"starttime",
            @"row6": @"timerid",
            @"playlistid": @1,
            @"row8": @"timerid",
            @"row9": @"timerid",
            @"row10": @"starttime",
            @"row11": @"endtime",
            @"itemid_extra_info": @"timerdetails"
        }
    ];
    
    menu_LiveTV.rowHeight = 76;
    menu_LiveTV.thumbWidth = 53;
    menu_LiveTV.defaultThumb = @"nocover_movies";
    menu_LiveTV.sheetActions = @[
        @[],
        @[],
        [self action_queue_to_play],
        @[LOCALIZED_STR(@"Delete timer")]
    ];
    
    //    menu_LiveTV.showInfo = YES;
    menu_LiveTV.showInfo = @[
        @YES,
        @YES,
        @YES,
        @NO];
    
    menu_LiveTV.watchModes = @[
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_watched],
        [self modes_icons_empty]
    ];
    
    menu_LiveTV.subItem.mainMethod = [@[
        @[@"PVR.GetChannels", @"method",
          @"YES", @"channelListView"],
        @[@"PVR.GetChannels", @"method",
          @"YES", @"channelListView"],
        @[],
        @[]
    ] mutableCopy];
    
    menu_LiveTV.subItem.noConvertTime = YES;
    
    menu_LiveTV.subItem.mainParameters = [@[
        @[
            @{
                @"properties": @[
                        @"thumbnail",
                        @"channel"]
            }, @"parameters",
            @{
                @"17": @[@"isrecording"],
            }, @"kodiExtrasPropertiesMinimumVersion",
            @"Live TV", @"label",
            @"nocover_channels", @"defaultThumb",
            @"YES", @"disableFilterParameter",
            livetvRowHeight, @"rowHeight",
            @"48", @"thumbWidth",
            @"YES", @"enableCollectionView",
            [self itemSizes_Music_insets:@"56"], @"itemSizes"
        ],
                                  
        @[
            @{
                @"properties": @[
                        @"thumbnail",
                        @"channel"]
            }, @"parameters",
            @{
                @"17": @[@"isrecording"]
            }, @"kodiExtrasPropertiesMinimumVersion",
            @"Live TV", @"label",
            @"nocover_channels", @"defaultThumb",
            @"YES", @"disableFilterParameter",
            livetvRowHeight, @"rowHeight",
            @"48", @"thumbWidth",
            @"YES", @"enableCollectionView",
            [self itemSizes_Music_insets:@"56"], @"itemSizes"
        ],
                                  
        @[],
        @[]
    ] mutableCopy];
    
    menu_LiveTV.subItem.mainFields = @[
        @{
            @"itemid": @"channels",
            @"row1": @"channel",
            @"row2": @"starttime",
            @"row3": @"endtime",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"channelid",
            @"playlistid": @1,
            @"row8": @"channelid",
            @"row9": @"isrecording",
            @"row10": @"filetype",
            @"row11": @"type"
        },
                              
        @{
            @"itemid": @"channels",
            @"row1": @"channel",
            @"row2": @"starttime",
            @"row3": @"endtime",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"channelid",
            @"playlistid": @1,
            @"row8": @"channelid",
            @"row9": @"channelid",
            @"row10": @"filetype",
            @"row11": @"type"
        },
                              
        @{},
        @{}
    ];
    
    menu_LiveTV.subItem.enableSection = NO;
    menu_LiveTV.subItem.rowHeight = 76;
    menu_LiveTV.subItem.thumbWidth = [livetvThumbWidth intValue];
    menu_LiveTV.subItem.defaultThumb = @"nocover_channels";
    menu_LiveTV.subItem.sheetActions = @[
        [self action_play_to_channelguide],
        [self action_play_to_channelguide],
        @[],
        @[]
    ];
    
    menu_LiveTV.subItem.showInfo = @[
        @NO,
        @NO,
        @NO,
        @NO];
    
    menu_LiveTV.subItem.watchModes = @[
        [self modes_icons_empty],
        [self modes_icons_empty],
        @{},
        @{}
    ];
    
    menu_LiveTV.subItem.widthLabel = 252;
    menu_LiveTV.subItem.subItem.noConvertTime = YES;
    menu_LiveTV.subItem.subItem.mainMethod = [@[
        @[@"PVR.GetBroadcasts", @"method",
          @"YES", @"channelGuideView"],
        @[@"PVR.GetBroadcasts", @"method",
          @"YES", @"channelGuideView"],
        @[],
        @[]
    ] mutableCopy];
    
    menu_LiveTV.subItem.subItem.mainParameters = [@[
        @[
            @{
                @"properties": @[
                        @"title",
                        @"starttime",
                        @"endtime",
                        @"plot",
                        @"plotoutline",
                        @"progresspercentage",
                        @"isactive",
                        @"hastimer"]
            }, @"parameters",
            @"Live TV", @"label",
            @"icon_video", @"defaultThumb",
            @"YES", @"disableFilterParameter",
            channelEPGRowHeight, @"rowHeight",
            livetvThumbWidth, @"thumbWidth",
            [self itemSizes_Music_insets:@"48"], @"itemSizes",
            @YES, @"forceActionSheet"
        ],
                                            
         @[
            @{
                @"properties": @[
                        @"title",
                        @"starttime",
                        @"endtime",
                        @"plot",
                        @"plotoutline",
                        @"progresspercentage",
                        @"isactive",
                        @"hastimer"]
            }, @"parameters",
            @"Live TV", @"label",
            @"icon_video", @"defaultThumb",
            @"YES", @"disableFilterParameter",
            channelEPGRowHeight, @"rowHeight",
            livetvThumbWidth, @"thumbWidth",
            [self itemSizes_Music_insets:@"48"], @"itemSizes",
            @YES, @"forceActionSheet"
        ],
                                            
        @[],
        @[]
    ] mutableCopy];
    
    menu_LiveTV.subItem.subItem.mainFields = @[
        @{
            @"itemid": @"broadcasts",
            @"row1": @"title",
            @"row2": @"plot",
            @"row3": @"broadcastid",
            @"row4": @"broadcastid",
            @"row5": @"starttime",
            @"row6": @"broadcastid",
            @"playlistid": @1,
            @"row8": @"broadcastid",
            @"row9": @"plotoutline",
            @"row10": @"starttime",
            @"row11": @"endtime",
            @"row12": @"progresspercentage",
            @"row13": @"isactive",
            @"row14": @"title",
            @"row15": @"hastimer"
        },
                                        
        @{
            @"itemid": @"broadcasts",
            @"row1": @"title",
            @"row2": @"plot",
            @"row3": @"broadcastid",
            @"row4": @"broadcastid",
            @"row5": @"starttime",
            @"row6": @"broadcastid",
            @"playlistid": @1,
            @"row8": @"broadcastid",
            @"row9": @"plotoutline",
            @"row10": @"starttime",
            @"row11": @"endtime",
            @"row12": @"progresspercentage",
            @"row13": @"isactive",
            @"row14": @"title",
            @"row15": @"hastimer"
        },
                                        
        @[],
        @[]
    ];
    
    menu_LiveTV.subItem.subItem.enableSection = NO;
    menu_LiveTV.subItem.subItem.rowHeight = 76;
    menu_LiveTV.subItem.subItem.thumbWidth = 53;
    menu_LiveTV.subItem.subItem.defaultThumb = @"nocover_filemode";
    menu_LiveTV.subItem.subItem.sheetActions = @[
        [self action_play_to_broadcastdetails],
        [self action_play_to_broadcastdetails],
        @[],
        @[]
    ];
    
    menu_LiveTV.subItem.subItem.widthLabel = 252;
    menu_LiveTV.subItem.subItem.showInfo = @[
        @YES,
        @YES,
        @YES,
        @YES];

#pragma mark - Pictures
    menu_Pictures.mainLabel = LOCALIZED_STR(@"Pictures");
    menu_Pictures.upperLabel = LOCALIZED_STR(@"Browse your");
    menu_Pictures.icon = @"icon_menu_pictures";
    menu_Pictures.family = FamilyDetailView;
    menu_Pictures.enableSection = YES;
    menu_Pictures.mainButtons = @[
        @"st_filemode",
        @"st_addons"];
    
    menu_Pictures.mainMethod = [@[
        @[@"Files.GetSources", @"method"],
        @[@"Files.GetDirectory", @"method"]
    ] mutableCopy];
    
    menu_Pictures.mainParameters = [@[
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"pictures"
            }, @"parameters",
            LOCALIZED_STR(@"Pictures"), @"label",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth"
        ],
                          
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"pictures",
                @"directory": @"addons://sources/image",
                @"properties": @[@"thumbnail"]
            }, @"parameters",
            LOCALIZED_STR(@"Pictures Add-ons"), @"label",
            LOCALIZED_STR(@"Pictures Add-ons"), @"morelabel",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth",
            @"YES", @"enableCollectionView",
            [self itemSizes_Music], @"itemSizes"
        ]
        
    ] mutableCopy];
    
    menu_Pictures.mainFields = @[
        @{
            @"itemid": @"sources",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @2,
            @"row8": @"file",
            @"row9": @"file"
        },
                      
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @2,
            @"row8": @"file",
            @"row9": @"file"
        }
    ];
    
    menu_Pictures.thumbWidth = 53;
    menu_Pictures.defaultThumb = @"jewel_dvd.table";
    
    menu_Pictures.subItem.mainMethod = [@[
        @[@"Files.GetDirectory", @"method"],
        @[@"Files.GetDirectory", @"method"]
    ] mutableCopy];
    
    menu_Pictures.subItem.mainParameters = [@[
                                  
        @[
            @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"pictures",
                @"file_properties": @[@"thumbnail"]
            }, @"parameters",
            LOCALIZED_STR(@"Files"), @"label",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth"
        ],
                                  
        @[
            @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"media": @"pictures",
                @"file_properties": @[@"thumbnail"]
            }, @"parameters",
            LOCALIZED_STR(@"Video Add-ons"), @"label",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            filemodeThumbWidth, @"thumbWidth"
        ]
                                  
    ] mutableCopy];
    
    menu_Pictures.subItem.mainFields = @[
                              
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"filetype",
            @"row3": @"filetype",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"file",
            @"playlistid": @2,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type"
        },
                              
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"filetype",
            @"row3": @"filetype",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"file",
            @"playlistid": @2,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type"
        }
    ];
    
    menu_Pictures.subItem.enableSection = NO;
    menu_Pictures.subItem.rowHeight = 76;
    menu_Pictures.subItem.thumbWidth = 53;
    menu_Pictures.subItem.defaultThumb = @"nocover_tvshows_episode";
    
    menu_Pictures.subItem.subItem.mainMethod = [@[
        @[@"Files.GetDirectory", @"method"],
        @[@"Files.GetDirectory", @"method"]
    ] mutableCopy];
    
    menu_Pictures.subItem.subItem.mainParameters = [@[
        @[],
        @[]
    ] mutableCopy];
    
    menu_Pictures.subItem.subItem.mainFields = @[
        @[],
        @[]
    ];
    
#pragma mark - Favourites
        menu_Favourites.mainLabel = LOCALIZED_STR(@"Favourites");
        menu_Favourites.upperLabel = LOCALIZED_STR(@"Choose your");
        menu_Favourites.icon = @"icon_menu_favourites";
        menu_Favourites.family = FamilyDetailView;
        menu_Favourites.enableSection = YES;
        menu_Favourites.mainButtons = @[@"st_filemode"];
        
        menu_Favourites.mainMethod = [@[
            @[@"Favourites.GetFavourites", @"method"],
        ] mutableCopy];
        
        menu_Favourites.mainParameters = [@[
            @[
                @{
                    @"properties": @[
                            @"thumbnail",
                            @"path",
                            @"window",
                            @"windowparameter"]
                }, @"parameters",
                LOCALIZED_STR(@"Favourites"), @"label",
                @"nocover_favourites", @"defaultThumb",
                filemodeRowHeight, @"rowHeight",
                filemodeThumbWidth, @"thumbWidth",
                @"YES", @"enableCollectionView",
                [self itemSizes_Music], @"itemSizes",
            ],
        ] mutableCopy];
        
        menu_Favourites.mainFields = @[
            @{
                @"itemid": @"favourites",
                @"row1": @"title",
                @"row2": [NSNull null],
                @"row3": [NSNull null],
                @"row4": [NSNull null],
                @"row5": [NSNull null],
                @"row6": @"title",
                @"row7": @"path",
                @"playlistid": @(-1),
                @"row8": @"type",
                @"row9": @"window",
                @"row10": @"windowparameter"
            },
        ];
        
        menu_Favourites.enableSection = NO;
        menu_Favourites.rowHeight = 53;
        menu_Favourites.thumbWidth = 53;
        menu_Favourites.defaultThumb = @"nocover_filemode";
    
#pragma mark - Now Playing
    menu_NowPlaying.mainLabel = LOCALIZED_STR(@"Now Playing");
    menu_NowPlaying.upperLabel = LOCALIZED_STR(@"See what's");
    menu_NowPlaying.icon = @"icon_menu_playing";
    menu_NowPlaying.family = FamilyNowPlaying;
    
#pragma mark - Remote Control
    menu_Remote.mainLabel = LOCALIZED_STR(@"Remote Control");
    menu_Remote.upperLabel = LOCALIZED_STR(@"Use as");
    menu_Remote.icon = @"icon_menu_remote";
    menu_Remote.family = FamilyRemote;
    
#pragma mark - XBMC Server Management
    menu_Server.mainLabel = LOCALIZED_STR(@"XBMC Server");
    menu_Server.upperLabel = @"";
    menu_Server.icon = @"";
    menu_Server.family = FamilyServer;
    
#pragma mark - Playlist Artist Albums
    playlistArtistAlbums = [menu_Music copy];
    playlistArtistAlbums.subItem.disableNowPlaying = YES;
    playlistArtistAlbums.subItem.subItem.disableNowPlaying = YES;
    
#pragma mark - Plalist Movies
    playlistMovies = [menu_Movies copy];
    playlistMovies.subItem.disableNowPlaying = YES;
    playlistMovies.subItem.subItem.disableNowPlaying = YES;
    
#pragma mark - Playlist TV Shows
    playlistTvShows = [menu_TVShows copy];
    playlistTvShows.subItem.disableNowPlaying = YES;
    playlistTvShows.subItem.subItem.disableNowPlaying = YES;

#pragma mark - XBMC Settings 
    xbmcSettings = [mainMenu new];
    xbmcSettings.subItem = [mainMenu new];
    xbmcSettings.subItem.subItem = [mainMenu new];
    
    xbmcSettings.mainLabel = LOCALIZED_STR(@"XBMC Settings");
    xbmcSettings.icon = @"icon_menu_settings";
    xbmcSettings.family = FamilyDetailView;
    xbmcSettings.enableSection = YES;
    xbmcSettings.rowHeight = 65;
    xbmcSettings.thumbWidth = 44;
    xbmcSettings.disableNowPlaying = YES;
    xbmcSettings.mainButtons = @[
        @"st_filemode",
        @"st_addons",
        @"st_video_addon",
        @"st_music_addon",
        @"st_kodi_action",
        @"st_kodi_window"];
    
    xbmcSettings.mainMethod = [@[
        @[@"Settings.GetSections", @"method"],
        @[@"Addons.GetAddons", @"method"],
        @[@"Addons.GetAddons", @"method"],
        @[@"Addons.GetAddons", @"method"],
        @[@"JSONRPC.Introspect", @"method"],
        @[@"JSONRPC.Introspect", @"method"]
    ] mutableCopy];
    
    xbmcSettings.mainParameters = [@[
                                   
        @[
            @{
                @"level": @"expert"
            }, @"parameters",
            LOCALIZED_STR(@"XBMC Settings"), @"label",
            @"nocover_settings", @"defaultThumb",
            [self itemSizes_insets:@"53"], @"itemSizes",
            animationStartX, @"animationStartX",
            animationStartBottomScreen, @"animationStartBottomScreen"
        ],
                                   
        @[
            @{
                @"type": @"xbmc.addon.executable",
                @"enabled": @YES,
                @"properties": @[
                        @"name",
                        @"version",
                        @"summary",
                        @"thumbnail"]
            }, @"parameters",
             LOCALIZED_STR(@"Programs"), @"label",
             @"nocover_filemode", @"defaultThumb",
             @"65", @"rowHeight",
             @"65", @"thumbWidth",
            [self itemSizes_Music_insets:@"65"], @"itemSizes",
            @"YES", @"enableCollectionView"
        ],
                                   
        @[
            @{
                @"type": @"xbmc.addon.video",
                @"enabled": @YES,
                @"properties": @[
                        @"name",
                        @"version",
                        @"summary",
                        @"thumbnail"]
            }, @"parameters",
            LOCALIZED_STR(@"Video Add-ons"), @"label",
            @"nocover_filemode", @"defaultThumb",
            @"65", @"rowHeight",
            @"65", @"thumbWidth",
            [self itemSizes_Music_insets:@"65"], @"itemSizes",
            @"YES", @"enableCollectionView"
        ],
                                   
        @[
            @{
                @"type": @"xbmc.addon.audio",
                @"enabled": @YES,
                @"properties": @[
                        @"name",
                        @"version",
                        @"summary",
                        @"thumbnail"]
            }, @"parameters",
            LOCALIZED_STR(@"Music Add-ons"), @"label",
            @"nocover_filemode", @"defaultThumb",
            @"65", @"rowHeight",
            @"65", @"thumbWidth",
            [self itemSizes_Music_insets:@"65"], @"itemSizes",
            @"YES", @"enableCollectionView"
        ],
                                   
        @[
            @{
                @"filter": @{
                        @"id": @"Input.ExecuteAction",
                        @"type": @"method"
                    }
            }, @"parameters",
            LOCALIZED_STR(@"Kodi actions"), @"label",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            @"0", @"thumbWidth",
            LOCALIZED_STR(@"Execute a specific action"), @"morelabel",
            [self itemSizes_insets:@"0"], @"itemSizes"
        ],
                                   
        @[
            @{
                @"filter": @{
                        @"id": @"GUI.ActivateWindow",
                        @"type": @"method"
                    }
            }, @"parameters",
            LOCALIZED_STR(@"Kodi windows"), @"label",
            @"nocover_filemode", @"defaultThumb",
            filemodeRowHeight, @"rowHeight",
            @"0", @"thumbWidth",
            LOCALIZED_STR(@"Activate a specific window"), @"morelabel",
            [self itemSizes_insets:@"0"], @"itemSizes"
        ]
                                   
    ] mutableCopy];
    
    xbmcSettings.mainFields = @[
        @{
            @"itemid": @"sections",
            @"row1": @"label",
            @"row2": @"help",
            @"row3": @"id",
            @"row4": @"id",
            @"row5": @"id",
            @"row6": @"id",
            @"playlistid": @2,
            @"row8": @"sectionid",
            @"row9": @"id"
        },
                               
        @{
            @"itemid": @"addons",
            @"row1": @"name",
            @"row2": @"summary",
            @"row3": @"blank",
            @"row4": @"blank",
            @"row5": @"addonid",
            @"row6": @"addonid",
            @"playlistid": @2,
            @"row8": @"addonid",
            @"row9": @"addonid"
        },
                               
        @{
            @"itemid": @"addons",
            @"row1": @"name",
            @"row2": @"summary",
            @"row3": @"blank",
            @"row4": @"blank",
            @"row5": @"addonid",
            @"row6": @"addonid",
            @"playlistid": @2,
            @"row8": @"addonid",
            @"row9": @"addonid"
        },
                               
        @{
            @"itemid": @"addons",
            @"row1": @"name",
            @"row2": @"summary",
            @"row3": @"blank",
            @"row4": @"blank",
            @"row5": @"addonid",
            @"row6": @"addonid",
            @"playlistid": @2,
            @"row8": @"addonid",
            @"row9": @"addonid"
        },
                               
        @{
            @"itemid": @"types",
            @"typename": @"Input.Action",
            @"fieldname": @"enums",
            @"row1": @"name",
            @"row2": @"summary",
            @"row3": @"blank",
            @"row4": @"blank",
            @"row5": @"addonid",
            @"row6": @"addonid",
            @"playlistid": @2,
            @"row8": @"addonid",
            @"row9": @"addonid",
            @"thumbnail": @"default-right-action-icon"
        },
                               
        @{
            @"itemid": @"types",
            @"typename": @"GUI.Window",
            @"fieldname": @"enums",
            @"row1": @"name",
            @"row2": @"summary",
            @"row3": @"blank",
            @"row4": @"blank",
            @"row5": @"addonid",
            @"row6": @"addonid",
            @"playlistid": @2,
            @"row8": @"addonid",
            @"row9": @"addonid",
            @"thumbnail": @"default-right-window-icon"
        }
    ];
    
    xbmcSettings.sheetActions = @[
        @[],
        @[LOCALIZED_STR(@"Execute program"),
          LOCALIZED_STR(@"Add button")],
        @[LOCALIZED_STR(@"Execute video add-on"),
          LOCALIZED_STR(@"Add button")],
        @[LOCALIZED_STR(@"Execute audio add-on"),
          LOCALIZED_STR(@"Add button")],
        @[LOCALIZED_STR(@"Execute action"),
          LOCALIZED_STR(@"Add action button")],
        @[LOCALIZED_STR(@"Activate window"),
          LOCALIZED_STR(@"Add window activation button")]
    ];
    
    xbmcSettings.subItem.disableNowPlaying = YES;
    xbmcSettings.subItem.mainMethod = [@[
        @[@"Settings.GetCategories", @"method"],
        @[],
        @[],
        @[],
        @[],
        @[]
    ] mutableCopy];
    
    xbmcSettings.subItem.mainParameters = [@[
        @[
            LOCALIZED_STR(@"Settings"), @"label",
            @"nocover_filemode", @"defaultThumb",
            @"65", @"rowHeight",
            @"32", @"thumbWidth",
            [self itemSizes_insets:@"40"], @"itemSizes"
        ],

        @[
            @YES, @"forceActionSheet"
        ],

        @[
            @YES, @"forceActionSheet"
        ],

        @[
            @YES, @"forceActionSheet"
        ],

        @[
            @YES, @"forceActionSheet"
        ],

        @[
            @YES, @"forceActionSheet"
        ]
    ] mutableCopy];
    
    xbmcSettings.subItem.mainFields = @[
        @{
            @"itemid": @"categories",
            @"row1": @"label",
            @"row2": @"help",
            @"row3": @"id",
            @"row4": @"id",
            @"row5": @"id",
            @"row6": @"id",
            @"playlistid": @2,
            @"row8": @"categoryid",
            @"row9": @"id"
        },
        @{},
        @{},
        @{},
        @{},
        @{}
    ];
    
    xbmcSettings.subItem.rowHeight = 65;
    xbmcSettings.subItem.thumbWidth = 44;
    
    xbmcSettings.subItem.subItem.disableNowPlaying = YES;
    xbmcSettings.subItem.subItem.mainMethod = [@[
        @[@"Settings.GetSettings", @"method"],
    ] mutableCopy];
    
    xbmcSettings.subItem.subItem.mainParameters = [@[
        @[
            LOCALIZED_STR(@"Settings"), @"label",
            @"nocover_filemode", @"defaultThumb",
            @"65", @"rowHeight",
            @"0", @"thumbWidth",
            [self itemSizes_insets:@"8"], @"itemSizes"
        ]] mutableCopy];
    
    xbmcSettings.subItem.subItem.mainFields = @[
        @{
            @"itemid": @"settings",
            @"row1": @"label",
            @"row2": @"help",
            @"row3": @"type",
            @"row4": @"default",
            @"row5": @"enabled",
            @"row6": @"id",
            @"playlistid": @2,
            @"row7": @"delimiter",
            @"row8": @"id",
            @"row9": @"id",
            @"row10": @"parent",
            @"row11": @"control",
            @"row12": @"value",
            @"row13": @"options",
            @"row14": @"allowempty",
            @"row15": @"addontype",
            @"row16": @"maximum",
            @"row17": @"minimum",
            @"row18": @"step",
            @"row19": @"definition"
        }
    ];
    
    xbmcSettings.subItem.subItem.sheetActions = @[
        @[]
    ];
    
    xbmcSettings.subItem.subItem.rowHeight = 65;
    xbmcSettings.subItem.subItem.thumbWidth = 44;
    
#pragma mark - Host Right Menu
    rightMenuItems = [NSMutableArray arrayWithCapacity:1];
    __auto_type rightItem1 = [mainMenu new];
    rightItem1.mainLabel = LOCALIZED_STR(@"XBMC Server");
    rightItem1.family = FamilyDetailView;
    rightItem1.enableSection = YES;
    rightItem1.mainMethod = @[
        @{
            @"offline": @[
                @{
                    @"label": @"ServerInfo",
                    @"bgColor": [self setColorRed:0.208 Green:0.208 Blue:0.208],
                    @"fontColor": [self setColorRed:0.702 Green:0.702 Blue:0.702],
                    @"hideLineSeparator": @YES
                },
                @{
                    @"label": LOCALIZED_STR(@"Wake On Lan"),
                    @"bgColor": [self setColorRed:0.741 Green:0.141 Blue:0.141],
                    @"fontColor": [self setColorRed:1.0 Green:1.0 Blue:1.0],
                    @"hideLineSeparator": @YES,
                    @"icon": @"icon_power",
                    @"action": @{
                            @"command": @"System.WOL"
                        }
                },
                @{
                    @"label": LOCALIZED_STR(@"LED Torch"),
                    @"icon": @"torch"
                },
            ],
              
            @"utility": @[
                @{
                    @"label": LOCALIZED_STR(@"LED Torch"),
                    @"icon": @"torch"
                }
            ],
              
            @"online": @[
                @{
                    @"label": @"ServerInfo",
                    @"bgColor": [self setColorRed:0.208 Green:0.208 Blue:0.208],
                    @"fontColor": [self setColorRed:0.702 Green:0.702 Blue:0.702],
                    @"hideLineSeparator": @YES
                },
                               
                @{
                    @"label": LOCALIZED_STR(@"Power off System"),
                    @"bgColor": [self setColorRed:0.741 Green:0.141 Blue:0.141],
                    @"fontColor": [self setColorRed:1.0 Green:1.0 Blue:1.00],
                    @"hideLineSeparator": @YES,
                    @"icon": @"icon_power",
                    @"action": @{
                        @"command": @"System.Shutdown",
                        @"message": LOCALIZED_STR(@"Are you sure you want to power off your XBMC system now?"),
                        @"countdown_time": @5,
                        @"cancel_button": LOCALIZED_STR(@"Cancel"),
                        @"ok_button": LOCALIZED_STR(@"Power off")
                    }
                },
                               
                @{
                    @"label": LOCALIZED_STR(@"Hibernate"),
                    @"icon": @"icon_hibernate",
                    @"action": @{
                        @"command": @"System.Hibernate",
                        @"message": LOCALIZED_STR(@"Are you sure you want to hibernate your XBMC system now?"),
                        @"cancel_button": LOCALIZED_STR(@"Cancel"),
                        @"ok_button": LOCALIZED_STR(@"Hibernate")
                    }
                },
                               
                @{
                    @"label": LOCALIZED_STR(@"Suspend"),
                    @"icon": @"icon_sleep",
                    @"action": @{
                        @"command": @"System.Suspend",
                        @"message": LOCALIZED_STR(@"Are you sure you want to suspend your XBMC system now?"),
                        @"cancel_button": LOCALIZED_STR(@"Cancel"),
                        @"ok_button": LOCALIZED_STR(@"Suspend")
                    }
                },
                               
                @{
                    @"label": LOCALIZED_STR(@"Reboot"),
                    @"icon": @"icon_reboot",
                    @"action": @{
                            @"command": @"System.Reboot",
                            @"message": LOCALIZED_STR(@"Are you sure you want to reboot your XBMC system now?"),
                            @"cancel_button": LOCALIZED_STR(@"Cancel"),
                            @"ok_button": LOCALIZED_STR(@"Reboot")
                    }
                },
                               
                @{
                    @"label": LOCALIZED_STR(@"Quit XBMC application"),
                    @"icon": @"icon_exit",
                    @"action": @{
                            @"command": @"Application.Quit",
                            @"message": LOCALIZED_STR(@"Are you sure you want to quit XBMC application now?"),
                            @"cancel_button": LOCALIZED_STR(@"Cancel"),
                            @"ok_button": LOCALIZED_STR(@"Quit")
                    }
                },
                               
                @{
                    @"label": LOCALIZED_STR(@"Update Audio Library"),
                    @"icon": @"icon_update_audio",
                    @"action": @{
                        @"command": @"AudioLibrary.Scan",
                        @"message": LOCALIZED_STR(@"Are you sure you want to update your audio library now?"),
                        @"cancel_button": LOCALIZED_STR(@"Cancel"),
                        @"ok_button": LOCALIZED_STR(@"Update Audio")
                    }
                },

                @{
                    @"label": LOCALIZED_STR(@"Clean Audio Library"),
                    @"icon": @"icon_clean_audio",
                    @"action": @{
                        @"command": @"AudioLibrary.Clean",
                        @"message": LOCALIZED_STR(@"Are you sure you want to clean your audio library now?"),
                        @"cancel_button": LOCALIZED_STR(@"Cancel"),
                        @"ok_button": LOCALIZED_STR(@"Clean Audio")
                    }
                },
                               
                @{
                    @"label": LOCALIZED_STR(@"Update Video Library"),
                    @"icon": @"icon_update_video",
                    @"action": @{
                        @"command": @"VideoLibrary.Scan",
                        @"message": LOCALIZED_STR(@"Are you sure you want to update your video library now?"),
                        @"cancel_button": LOCALIZED_STR(@"Cancel"),
                        @"ok_button": LOCALIZED_STR(@"Update Video")
                    }
                },
                               
                @{
                    @"label": LOCALIZED_STR(@"Clean Video Library"),
                    @"icon": @"icon_clean_video",
                    @"action": @{
                        @"command": @"VideoLibrary.Clean",
                        @"message": LOCALIZED_STR(@"Are you sure you want to clean your video library now?"),
                        @"cancel_button": LOCALIZED_STR(@"Cancel"),
                        @"ok_button": LOCALIZED_STR(@"Clean Video")
                    }
                },

                @{
                    @"label": LOCALIZED_STR(@"Cancel"),
                    @"fontColor": [self setColorRed:0.702 Green:0.702 Blue:0.702],
                },
            ],
        }
    ];
    
    [rightMenuItems addObject:rightItem1];
    
#pragma mark - Now Playing Right Menu
    nowPlayingMenuItems = [NSMutableArray arrayWithCapacity:1];
    __auto_type nowPlayingItem1 = [mainMenu new];
    nowPlayingItem1.mainLabel = @"VolumeControl";
    nowPlayingItem1.family = FamilyNowPlaying;
    nowPlayingItem1.mainMethod = @[
        @{
            @"offline": @[
                @{
                    @"label": @"ServerInfo",
                    @"bgColor": [self setColorRed:0.208 Green:0.208 Blue:0.208],
                    @"fontColor": [self setColorRed:0.702 Green:0.702 Blue:0.702],
                    @"hideLineSeparator": @YES
                }
            ],
                   
            @"online": @[
                @{
                    @"label": @"ServerInfo",
                    @"bgColor": [self setColorRed:0.208 Green:0.208 Blue:0.208],
                    @"fontColor": [self setColorRed:0.702 Green:0.702 Blue:0.702],
                    @"hideLineSeparator": @YES
                },
                @{
                    @"label": @"VolumeControl",
                    @"icon": @"volume"
                },
                @{
                    @"label": LOCALIZED_STR(@"Keyboard"),
                    @"icon": @"keyboard_icon"
                },
                @{
                    @"label": @"RemoteControl"
                }
            ]
        }
    ];
    
    [nowPlayingMenuItems addObject:nowPlayingItem1];
    
#pragma mark - Remote Control Right Menu
    remoteControlMenuItems = [NSMutableArray arrayWithCapacity:1];
    __auto_type remoteControlItem1 = [mainMenu new];
    remoteControlItem1.mainLabel = @"RemoteControl";
    remoteControlItem1.family = FamilyRemote;
    remoteControlItem1.enableSection = YES;

    remoteControlItem1.mainMethod = @[
        @{
            @"offline": @[
                @{
                    @"label": @"ServerInfo",
                    @"bgColor": [self setColorRed:0.208 Green:0.208 Blue:0.208],
                    @"fontColor": [self setColorRed:0.702 Green:0.702 Blue:0.702],
                    @"hideLineSeparator": @YES
                },
                @{
                    @"label": LOCALIZED_STR(@"LED Torch"),
                    @"icon": @"torch"
                }
            ],
                                   
            @"online": @[
                @{
                    @"label": @"ServerInfo",
                    @"bgColor": [self setColorRed:0.208 Green:0.208 Blue:0.208],
                    @"fontColor": [self setColorRed:0.702 Green:0.702 Blue:0.702],
                    @"hideLineSeparator": @YES
                },
                @{
                    @"label": @"VolumeControl",
                    @"icon": @"volume"
                },
                @{
                    @"label": LOCALIZED_STR(@"Keyboard"),
                    @"icon": @"keyboard_icon",
                    @"revealViewTop": @YES
                },
                @{
                    @"label": LOCALIZED_STR(@"Button Pad/Gesture Zone"),
                    @"icon": @"buttons-gestures"
                },
                @{
                    @"label": LOCALIZED_STR(@"Help Screen"),
                    @"icon": @"button_info"
                },
                @{
                    @"label": LOCALIZED_STR(@"LED Torch"),
                    @"icon": @"torch"
                }
            ]
        }
    ];
    
    [remoteControlMenuItems addObject:remoteControlItem1];
    
//    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProximityChangeNotification:) name:UIDeviceProximityStateDidChangeNotification object:nil];

#pragma mark - Build and Initialize menu structure
    
    // Build menu
    [mainMenuItems addObject:menu_Server];
    if ([self isMenuEntryEnabled:@"menu_music"]) {
        [mainMenuItems addObject:menu_Music];
    }
    if ([self isMenuEntryEnabled:@"menu_movies"]) {
        [mainMenuItems addObject:menu_Movies];
    }
    if ([self isMenuEntryEnabled:@"menu_tvshows"]) {
        [mainMenuItems addObject:menu_TVShows];
    }
    if ([self isMenuEntryEnabled:@"menu_pictures"]) {
        [mainMenuItems addObject:menu_Pictures];
    }
    if ([self isMenuEntryEnabled:@"menu_livetv"]) {
        [mainMenuItems addObject:menu_LiveTV];
    }
    if ([self isMenuEntryEnabled:@"menu_favourites"]) {
        [mainMenuItems addObject:menu_Favourites];
    }
    if ([self isMenuEntryEnabled:@"menu_nowplaying"]) {
        [mainMenuItems addObject:menu_NowPlaying];
    }
    if ([self isMenuEntryEnabled:@"menu_remote"]) {
        [mainMenuItems addObject:menu_Remote];
    }
    
    // Initialize controllers
    self.serverName = LOCALIZED_STR(@"No connection");
    if (IS_IPHONE) {
        InitialSlidingViewController *initialSlidingViewController = [[InitialSlidingViewController alloc] initWithNibName:@"InitialSlidingViewController" bundle:nil];
        initialSlidingViewController.mainMenu = mainMenuItems;
        self.window.rootViewController = initialSlidingViewController;
    }
    else {
        self.windowController = [[ViewControllerIPad alloc] initWithNibName:@"ViewControllerIPad" bundle:nil];
        self.windowController.mainMenu = mainMenuItems;
        self.window.rootViewController = self.windowController;
    }
    return YES;
}

- (BOOL)isMenuEntryEnabled:(NSString*)menuItem {
    id menuEnabled = [[NSUserDefaults standardUserDefaults] objectForKey:menuItem];
    return (menuEnabled == nil || [menuEnabled boolValue]);
}

- (NSURL*)getServerJSONEndPoint {
    NSString *serverJSON = [NSString stringWithFormat:@"http://%@:%@/jsonrpc", obj.serverIP, obj.serverPort];
    return [NSURL URLWithString:serverJSON];
}

- (NSDictionary*)getServerHTTPHeaders {
    NSData *authCredential = [[NSString stringWithFormat:@"%@:%@", obj.serverUser, obj.serverPass] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64AuthCredentials = [authCredential base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", base64AuthCredentials];
    NSDictionary *httpHeaders = [NSDictionary dictionaryWithObjectsAndKeys:authValue, @"Authorization", nil];
    return httpHeaders;
}

#pragma mark -

- (void)handleProximityChangeNotification:(id)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    UIApplication *xbmcRemote = [UIApplication sharedApplication];
    if ([[UIDevice currentDevice] proximityState]) {
        xbmcRemote.idleTimerDisabled = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIApplicationDidEnterBackgroundNotification" object: nil];
    }
    else {
        if ([[userDefaults objectForKey:@"lockscreen_preference"] boolValue]) {
            xbmcRemote.idleTimerDisabled = YES;
        }
        else {
            xbmcRemote.idleTimerDisabled = NO;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIApplicationWillEnterForegroundNotification" object: nil];
        [UIDevice currentDevice].proximityMonitoringEnabled = NO;
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    }
}

- (void)sendWOL:(NSString*)MAC withPort:(NSInteger)WOLport {
    CFSocketRef     WOLsocket;
    WOLsocket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_DGRAM, IPPROTO_UDP, 0, NULL, NULL);
    if (WOLsocket) {
        int desc = -1;
        desc = CFSocketGetNative(WOLsocket);
        int yes = -1;
        
        if (setsockopt (desc, SOL_SOCKET, SO_BROADCAST, (char*)&yes, sizeof (yes)) < 0) {
            NSLog(@"Set Socket options failed");
        }
        
        unsigned char ether_addr[6];
        
        int idx;
        
        for (idx = 0; idx + 2 <= [MAC length]; idx += 3) {
            NSRange range = NSMakeRange(idx, 2);
            NSString *hexStr = [MAC substringWithRange:range];
            
            NSScanner *scanner = [NSScanner scannerWithString:hexStr];
            unsigned int intValue;
            [scanner scanHexInt:&intValue];
            
            ether_addr[idx/3] = intValue;
        }
        
        /* Build the message to send - 6 x 0xff then 16 x MAC address */
        
        unsigned char message[102];
        unsigned char *message_ptr = message;
        
        memset(message_ptr, 0xFF, 6);
        message_ptr += 6;
        for (int i = 0; i < 16; ++i) {
            memcpy(message_ptr, ether_addr, 6);
            message_ptr += 6;
        }

        __auto_type getLocalBroadcastAddress = ^in_addr_t {
            in_addr_t broadcastAddress = 0xffffffff;
            struct ifaddrs *ifs = NULL;
            getifaddrs(&ifs);
            for (__auto_type ifIter = ifs; ifIter != NULL; ifIter = ifIter->ifa_next) {
                if (ifIter->ifa_flags & IFF_LOOPBACK || ifIter->ifa_flags & IFF_POINTOPOINT || !(ifIter->ifa_flags & IFF_RUNNING))
                    continue;
                if (!ifIter->ifa_addr || ifIter->ifa_addr->sa_family != AF_INET || !ifIter->ifa_broadaddr)
                    continue;
                broadcastAddress = ((struct sockaddr_in*)ifIter->ifa_broadaddr)->sin_addr.s_addr;
                break;
            }
            if (ifs) {
                freeifaddrs(ifs);
            }
            return broadcastAddress;
        };

        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_len = sizeof(addr);
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = getLocalBroadcastAddress();
        addr.sin_port = htons(WOLport);
        
        CFDataRef message_data = CFDataCreate(NULL, (unsigned char*)&message, sizeof(message));
        CFDataRef destinationAddressData = CFDataCreate(NULL, (const UInt8*)&addr, sizeof(addr));
        
        CFSocketError CFSocketSendData_error = CFSocketSendData(WOLsocket, destinationAddressData, message_data, 30);
        
        if (CFSocketSendData_error) {
            NSLog(@"CFSocketSendData error: %li", CFSocketSendData_error);
        }
    }
}


- (void)applicationWillResignActive:(UIApplication*)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication*)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    UIApplication *xbmcRemote = [UIApplication sharedApplication];
    if ([[userDefaults objectForKey:@"lockscreen_preference"] boolValue]) {
        xbmcRemote.idleTimerDisabled = YES;
    }
    else {
        xbmcRemote.idleTimerDisabled = NO;
    }
//    [[NSNotificationCenter defaultCenter] postNotificationName: @"UIApplicationWillEnterForegroundNotification" object: nil];
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
}

- (void)applicationWillTerminate:(UIApplication*)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication*)application {
    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)saveServerList {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if ([paths count] > 0) { 
        [NSKeyedArchiver archiveRootObject:arrayServerList toFile:self.dataFilePath];
    }
}

- (void)clearAppDiskCache {
    // OLD SDWEBImageCache
    NSString *fullNamespace = @"ImageCache"; 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *diskCachePath = [paths[0] stringByAppendingPathComponent:fullNamespace];
    [[NSFileManager defaultManager] removeItemAtPath:diskCachePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:paths[0] error:nil];
    
    // TO BE CHANGED!!!
    fullNamespace = @"com.hackemist.SDWebImageCache.default";
    diskCachePath = [paths[0] stringByAppendingPathComponent:fullNamespace];
    [[NSFileManager defaultManager] removeItemAtPath:diskCachePath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
    
    [[NSFileManager defaultManager] removeItemAtPath:self.libraryCachePath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.libraryCachePath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
    
    [[NSFileManager defaultManager] removeItemAtPath:self.epgCachePath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.epgCachePath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
    
    // Clean NetworkCache
    NSString *caches = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, TRUE)[0];
    NSString *appID = [[NSBundle mainBundle] infoDictionary][@"CFBundleIdentifier"];
    NSString *path = [NSString stringWithFormat:@"%@/%@/Cache.db-wal", caches, appID];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    path = [NSString stringWithFormat:@"%@/%@/Cache.db-shm", caches, appID];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    path = [NSString stringWithFormat:@"%@/%@/Cache.db", caches, appID];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    path = [NSString stringWithFormat:@"%@/%@/fsCachedData", caches, appID];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

@end
