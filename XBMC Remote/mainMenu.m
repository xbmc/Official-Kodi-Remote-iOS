//
//  mainMenu.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "mainMenu.h"
#import "AppDelegate.h"
#import "Utilities.h"

#pragma mark - Globals

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

#define LOOKUP_ITEM(mPath, mLabel, mIcon, mItemId) [[LookupItem alloc] initWithPath:mPath label:mLabel icon:mIcon itemId:mItemId]

@implementation mainMenu

@synthesize mainLabel, icon, family, type, mainButtons, mainMethod, mainFields, mainParameters, rowHeight, thumbWidth, subItem, enableSection, sheetActions, showInfo, maxXrightLabel, widthLabel, showRuntime, noConvertTime, chooseTab, disableNavbarButtons, filterModes;

- (id)copyWithZone:(NSZone*)zone {
    mainMenu *menuCopy = [[mainMenu allocWithZone:zone] init];
    menuCopy.mainLabel = [self.mainLabel copy];
    menuCopy.family = self.family;
    menuCopy.type = self.type;
    menuCopy.enableSection = self.enableSection;
    menuCopy.icon = [self.icon copy];
    menuCopy.mainMethod = [self.mainMethod copy];
    menuCopy.mainButtons = [self.mainButtons copy];
    menuCopy.mainFields = [self.mainFields copy];
    menuCopy.mainParameters = [self.mainParameters mutableCopy];
    menuCopy.subItem = [self.subItem copy];
    menuCopy.sheetActions = [self.sheetActions copy];
    menuCopy.rowHeight = self.rowHeight;
    menuCopy.thumbWidth = self.thumbWidth;
    menuCopy.showInfo = self.showInfo;
    menuCopy.maxXrightLabel = self.maxXrightLabel;
    menuCopy.widthLabel = self.widthLabel;
    menuCopy.chooseTab = self.chooseTab;
    menuCopy.disableNavbarButtons = self.disableNavbarButtons;
    menuCopy.showRuntime = [self.showRuntime copy];
    menuCopy.noConvertTime = self.noConvertTime;
    menuCopy.filterModes = [self.filterModes copy];
    return menuCopy;
}

#pragma mark - Helper

+ (NSDictionary*)itemSizes_Musicfullscreen {
    return @{
        @"iphone": @{
            @"width": @ITEM_MUSIC_PHONE_WIDTH,
            @"height": @ITEM_MUSIC_PHONE_HEIGHT,
        },
        @"ipad": @{
            @"width": @ITEM_MUSIC_PAD_WIDTH,
            @"height": @ITEM_MUSIC_PAD_HEIGHT,
            @"fullscreenWidth": @ITEM_MUSIC_PAD_WIDTH_FULLSCREEN,
            @"fullscreenHeight": @ITEM_MUSIC_PAD_HEIGHT_FULLSCREEN,
        },
    };
}

+ (NSDictionary*)itemSizes_Music {
    return @{
        @"iphone": @{
            @"width": @ITEM_MUSIC_PHONE_WIDTH,
            @"height": @ITEM_MUSIC_PHONE_HEIGHT,
        },
        @"ipad": @{
            @"width": @ITEM_MUSIC_PAD_WIDTH,
            @"height": @ITEM_MUSIC_PAD_HEIGHT,
        },
    };
}

+ (NSDictionary*)itemSizes_TVShowsfullscreen {
    return @{
        @"iphone": @{
            @"width": @ITEM_TVSHOW_PHONE_WIDTH,
            @"height": @ITEM_TVSHOW_PHONE_HEIGHT,
        },
        @"ipad": @{
            @"width": @ITEM_TVSHOW_PAD_WIDTH,
            @"height": @ITEM_TVSHOW_PAD_HEIGHT,
            @"fullscreenWidth": @ITEM_TVSHOW_PAD_WIDTH_FULLSCREEN,
            @"fullscreenHeight": @ITEM_TVSHOW_PAD_HEIGHT_FULLSCREEN,
        },
    };
}

+ (NSDictionary*)itemSizes_MovieRecentlyfullscreen {
    return @{
        @"iphone": @{
            @"width": @"fullWidth",
            @"height": @ITEM_MOVIE_PHONE_HEIGHT_RECENTLY,
        },
        @"ipad": @{
            @"width": @"fullWidth",
            @"height": @ITEM_MOVIE_PAD_HEIGHT_RECENTLY,
            @"fullscreenWidth": @ITEM_MOVIE_PAD_WIDTH_RECENTLY_FULLSCREEN,
            @"fullscreenHeight": @ITEM_MOVIE_PAD_HEIGHT_RECENTLY_FULLSCREEN,
        },
    };
}

+ (NSDictionary*)itemSizes_Moviefullscreen {
    return @{
        @"iphone": @{
            @"width": @ITEM_MOVIE_PHONE_WIDTH,
            @"height": @ITEM_MOVIE_PHONE_HEIGHT,
        },
        @"ipad": @{
            @"width": @ITEM_MOVIE_PAD_WIDTH,
            @"height": @ITEM_MOVIE_PAD_HEIGHT,
            @"fullscreenWidth": @ITEM_MOVIE_PAD_WIDTH_FULLSCREEN,
            @"fullscreenHeight": @ITEM_MOVIE_PAD_HEIGHT_FULLSCREEN,
        },
    };
}

+ (NSDictionary*)itemSizes_Movie {
    return @{
        @"iphone": @{
            @"width": @ITEM_MOVIE_PHONE_WIDTH,
            @"height": @ITEM_MOVIE_PHONE_HEIGHT,
        },
        @"ipad": @{
            @"width": @ITEM_MOVIE_PAD_WIDTH,
            @"height": @ITEM_MOVIE_PAD_HEIGHT,
        },
    };
}

+ (NSDictionary*)watchedListenedString {
    return @{
        @"notWatched": LOCALIZED_STR(@"Not listened"),
        @"watchedOneTime": LOCALIZED_STR(@"Listened one time"),
        @"watchedTimes": LOCALIZED_STR(@"Listened %@ times"),
    };
}

+ (NSArray*)action_album {
    return @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Play using..."),
        LOCALIZED_STR(@"Play in shuffle mode"),
        LOCALIZED_STR(@"Album Details"),
        LOCALIZED_STR(@"Search Wikipedia"),
    ];
}

+ (NSArray*)action_artist {
    return @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Play using..."),
        LOCALIZED_STR(@"Play in shuffle mode"),
        LOCALIZED_STR(@"Artist Details"),
        LOCALIZED_STR(@"Search Wikipedia"),
        LOCALIZED_STR(@"Search last.fm charts"),
    ];
}

+ (NSArray*)action_filemode_music {
    return @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Play using..."),
        LOCALIZED_STR(@"Play in shuffle mode"),
    ];
}

+ (NSArray*)action_queue_to_play {
    return @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Play using..."),
    ];
}

+ (NSArray*)action_pictures {
    return @[
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
    ];
}

+ (NSArray*)action_movie {
    return @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Play using..."),
        LOCALIZED_STR(@"Movie Details"),
    ];
}

+ (NSArray*)action_playlist {
    return @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Play in shuffle mode"),
        LOCALIZED_STR(@"Play in party mode"),
        LOCALIZED_STR(@"Show Content"),
    ];
}

+ (NSArray*)action_musicvideo {
    return @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Play using..."),
        LOCALIZED_STR(@"Music Video Details"),
    ];
}

+ (NSArray*)action_episode {
    return @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Play using..."),
        LOCALIZED_STR(@"Episode Details"),
    ];
}

+ (NSArray*)action_broadcast {
    return @[
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Record"),
        LOCALIZED_STR(@"Broadcast Details"),
    ];
}

+ (NSArray*)action_channel {
    return @[
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Record"),
        LOCALIZED_STR(@"Channel Guide"),
    ];
}

+ (NSDictionary*)modes_icons_empty {
    return @{
        @"modes": @[],
        @"icons": @[],
    };
}

+ (NSDictionary*)modes_icons_watched {
    return @{
        @"modes": @[
            @(ViewModeDefault),
            @(ViewModeUnwatched),
            @(ViewModeWatched),
        ],
        @"icons": @[
            @"blank",
            @"st_unchecked",
            @"st_checked",
        ],
    };
}

+ (NSDictionary*)modes_icons_listened {
    return @{
        @"modes": @[
            @(ViewModeDefault),
            @(ViewModeNotListened),
            @(ViewModeListened),
        ],
        @"icons": @[
            @"blank",
            @"st_unchecked",
            @"st_checked",
        ],
    };
}

+ (NSDictionary*)modes_icons_artiststype {
    return @{
        @"modes": @[
            @(ViewModeDefaultArtists),
            @(ViewModeAlbumArtists),
            @(ViewModeSongArtists),
        ],
        @"icons": @[
            @"blank",
            @"st_album_small",
            @"st_songs_small",
        ],
    };
}

+ (NSDictionary*)setColorRed:(double)r Green:(double)g Blue:(double)b {
    return @{
        @"red": @(r),
        @"green": @(g),
        @"blue": @(b),
    };
}

+ (NSDictionary*)sortmethod:(NSString*)method order:(NSString*)order ignorearticle:(BOOL)ignore {
    return @{
        @"order": order,
        @"ignorearticle": @(ignore),
        @"method": method,
    };
}

+ (BOOL)isMenuEntryEnabled:(NSString*)menuItem {
    id menuEnabled = [[NSUserDefaults standardUserDefaults] objectForKey:menuItem];
    return (menuEnabled == nil || [menuEnabled boolValue]);
}

# pragma mark - Build Menu Tree

+ (NSMutableArray*)generateMenus {
    NSString *filemodeVideoType = @"video";
    NSString *filemodeMusicType = @"music";
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:@"fileType_preference"]) {
        filemodeVideoType = @"files";
        filemodeMusicType = @"files";
    }
    
    int thumbWidth;
    int tvshowHeight;
    CGFloat transform = [Utilities getTransformX];
    if (IS_IPHONE) {
        thumbWidth = (int)(PHONE_TV_SHOWS_BANNER_WIDTH * transform);
        tvshowHeight = (int)(PHONE_TV_SHOWS_BANNER_HEIGHT * transform);
        NSDictionary *navbarTitleTextAttributes = @{NSForegroundColorAttributeName: UIColor.whiteColor,
                                                    NSFontAttributeName: [UIFont boldSystemFontOfSize:16]};
        UINavigationBar.appearance.titleTextAttributes = navbarTitleTextAttributes;
    }
    else {
        thumbWidth = (int)(PAD_TV_SHOWS_BANNER_WIDTH * transform);
        tvshowHeight = (int)(PAD_TV_SHOWS_BANNER_HEIGHT * transform);
    }
    
#pragma mark - Music
    __auto_type menu_Music = [mainMenu new];
    menu_Music.mainLabel = LOCALIZED_STR(@"Music");
    menu_Music.icon = @"icon_menu_music";
    menu_Music.type = TypeMusic;
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
        @"st_music_roles",
    ];
    
    menu_Music.mainMethod = @[
        @{
            @"method": @"AudioLibrary.GetAlbums",
            @"extra_info_method": @"AudioLibrary.GetAlbumDetails",
        },
        @{
            @"method": @"AudioLibrary.GetArtists",
            @"extra_info_method": @"AudioLibrary.GetArtistDetails",
        },
        @{
            @"method": @"AudioLibrary.GetGenres",
        },
        @{
            @"method": @"Files.GetSources",
        },
        @{
            @"method": @"AudioLibrary.GetRecentlyAddedAlbums",
            @"extra_info_method": @"AudioLibrary.GetAlbumDetails",
        },
        @{
            @"method": @"AudioLibrary.GetRecentlyAddedSongs",
        },
        @{
            @"method": @"AudioLibrary.GetAlbums",
            @"extra_info_method": @"AudioLibrary.GetAlbumDetails",
        },
        @{
            @"method": @"AudioLibrary.GetSongs",
        },
        @{
            @"method": @"AudioLibrary.GetRecentlyPlayedAlbums",
        },
        @{
            @"method": @"AudioLibrary.GetRecentlyPlayedSongs",
        },
        @{
            @"method": @"AudioLibrary.GetSongs",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"AudioLibrary.GetRoles",
        },
    ];
    
    menu_Music.mainParameters = [@[
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"year",
                    @"thumbnail",
                    @"artist",
                    @"playcount",
                ],
            },
            @"extra_info_parameters": @{
                @"properties": @[
                    @"year",
                    @"thumbnail",
                    @"artist",
                    @"genre",
                    @"description",
                    @"albumlabel",
                    @"fanart",
                ],
                @"kodiExtrasPropertiesMinimumVersion": @{
                    @"18": @[
                        @"art",
                    ],
                },
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Album"),
                    LOCALIZED_STR(@"Artist"),
                    LOCALIZED_STR(@"Year"),
                    LOCALIZED_STR(@"Play count"),
                    LOCALIZED_STR(@"Random"),
                ],
                @"method": @[
                    @"label",
                    @"genre",
                    @"year",
                    @"playcount",
                    @"random",
                ],
            },
            @"label": LOCALIZED_STR(@"Albums"),
            @"defaultThumb": @"nocover_music",
            @"enableCollectionView": @YES,
            @"enableLibraryCache": @YES,
            @"enableLibraryFullScreen": @YES,
            @"watchedListenedStrings": [self watchedListenedString],
            @"itemSizes": [self itemSizes_Musicfullscreen],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"artist" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"thumbnail",
                    @"genre",
                ],
            },
            @"extra_info_parameters": @{
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
                    @"fanart",
                ],
                @"kodiExtrasPropertiesMinimumVersion": @{
                    @"18": @[
                        @"roles",
                        @"art",
                    ],
                },
            },
            @"label": LOCALIZED_STR(@"Artists"),
            @"defaultThumb": @"nocover_artist",
            @"enableCollectionView": @YES,
            @"enableLibraryCache": @YES,
            @"enableLibraryFullScreen": @YES,
            @"itemSizes": [self itemSizes_Musicfullscreen],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Genres"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @0,
            @"enableLibraryCache": @YES,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"music",
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"year",
                    @"thumbnail",
                    @"artist",
                    @"playcount",
                ],
            },
            @"extra_info_parameters": @{
                @"properties": @[
                    @"year",
                    @"thumbnail",
                    @"artist",
                    @"genre",
                    @"description",
                    @"albumlabel",
                    @"fanart",
                ],
                @"kodiExtrasPropertiesMinimumVersion": @{
                    @"18": @[
                        @"art",
                    ],
                },
            },
            @"label": LOCALIZED_STR(@"Added Albums"),
            @"morelabel": LOCALIZED_STR(@"Recently added albums"),
            @"defaultThumb": @"nocover_music",
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
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
                    @"file",
                ],
            },
            @"label": LOCALIZED_STR(@"Added Songs"),
            @"morelabel": LOCALIZED_STR(@"Recently added songs"),
            @"defaultThumb": @"nocover_music",
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"playcount" order:@"descending" ignorearticle:NO],
                @"limits": @{
                    @"start": @0,
                    @"end": @100,
                },
                @"properties": @[
                    @"year",
                    @"thumbnail",
                    @"artist",
                    @"playcount",
                ],
            },
            @"extra_info_parameters": @{
                @"properties": @[
                    @"year",
                    @"thumbnail",
                    @"artist",
                    @"genre",
                    @"description",
                    @"albumlabel",
                    @"fanart",
                ],
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Top 100 Albums"),
                    LOCALIZED_STR(@"Album"),
                    LOCALIZED_STR(@"Artist"),
                    LOCALIZED_STR(@"Year"),
                ],
                @"method": @[
                    @"playcount",
                    @"label",
                    @"genre",
                    @"year",
                ],
                @"kodiExtrasPropertiesMinimumVersion": @{
                    @"18": @[
                        @"art",
                    ],
                },
            },
            @"label": LOCALIZED_STR(@"Top 100 Albums"),
            @"morelabel": LOCALIZED_STR(@"Top 100 Albums"),
            @"defaultThumb": @"nocover_music",
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"playcount" order:@"descending" ignorearticle:NO],
                @"limits": @{
                    @"start": @0,
                    @"end": @100,
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
                    @"album",
                ],
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Top 100 Songs"),
                    LOCALIZED_STR(@"Track"),
                    LOCALIZED_STR(@"Title"),
                    LOCALIZED_STR(@"Album"),
                    LOCALIZED_STR(@"Artist"),
                    LOCALIZED_STR(@"Rating"),
                    LOCALIZED_STR(@"Year"),
                ],
                @"method": @[
                    @"playcount",
                    @"track",
                    @"label",
                    @"album",
                    @"genre",
                    @"rating",
                    @"year",
                ],
            },
            @"label": LOCALIZED_STR(@"Top 100 Songs"),
            @"morelabel": LOCALIZED_STR(@"Top 100 Songs"),
            @"defaultThumb": @"nocover_music",
            @"numberOfStars": @5,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"year",
                    @"thumbnail",
                    @"artist",
                    @"playcount",
                ],
            },
            @"label": LOCALIZED_STR(@"Played albums"),
            @"morelabel": LOCALIZED_STR(@"Recently played albums"),
            @"defaultThumb": @"nocover_music",
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
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
                    @"file",
                ],
            },
            @"label": LOCALIZED_STR(@"Played songs"),
            @"morelabel": LOCALIZED_STR(@"Recently played songs"),
            @"defaultThumb": @"nocover_music",
        },
        
        @{
            @"parameters": @{
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
                    @"file",
                ],
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Name"),
                    LOCALIZED_STR(@"Rating"),
                    LOCALIZED_STR(@"Year"),
                    LOCALIZED_STR(@"Play count"),
                    LOCALIZED_STR(@"Track"),
                    LOCALIZED_STR(@"Album"),
                    LOCALIZED_STR(@"Artist"),
                    LOCALIZED_STR(@"Random"),
                ],
                @"method": @[
                    @"label",
                    @"rating",
                    @"year",
                    @"playcount",
                    @"track",
                    @"album",
                    @"genre",
                    @"random",
                ],
            },
            @"label": LOCALIZED_STR(@"All songs"),
            @"morelabel": LOCALIZED_STR(@"All songs"),
            @"defaultThumb": @"nocover_music",
            @"enableLibraryCache": @YES,
            @"numberOfStars": @5,
            @"watchedListenedStrings": [self watchedListenedString],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"music",
                @"directory": @"addons://sources/audio",
                @"properties": @[
                    @"thumbnail",
                    @"file",
                ],
            },
            @"label": LOCALIZED_STR(@"Music Add-ons"),
            @"morelabel": LOCALIZED_STR(@"Music Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"music",
                @"directory": @"special://musicplaylists",
                @"properties": @[
                    @"thumbnail",
                    @"file",
                    @"artist",
                    @"album",
                    @"duration",
                ],
                @"file_properties": @[
                    @"thumbnail",
                    @"file",
                    @"artist",
                    @"album",
                    @"duration",
                ],
            },
            @"label": LOCALIZED_STR(@"Music Playlists"),
            @"morelabel": LOCALIZED_STR(@"Music Playlists"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"isMusicPlaylist": @YES,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"title",
                ],
            },
            @"label": LOCALIZED_STR(@"Music Roles"),
            @"morelabel": LOCALIZED_STR(@"Music Roles"),
            @"defaultThumb": @"nocover_artist",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"itemSizes": [self itemSizes_Music],
        },
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
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"albumid",
            @"row9": @"albumid",
            @"row10": @"artist",
            @"row11": @"genre",
            @"row12": @"description",
            @"row13": @"albumlabel",
            @"itemid_extra_info": @"albumdetails",
        },
        
        @{
            @"itemid": @"artists",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"yearsactive",
            @"row4": @"genre",
            @"row5": @"disbanded",
            @"row6": @"artistid",
            @"playlistid": @PLAYERID_MUSIC,
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
            @"row19": @"artist",
            @"row20": @"roles",
            @"itemid_extra_info": @"artistdetails",
        },
        
        @{
            @"itemid": @"genres",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"genreid",
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"genreid",
            @"row9": @"genreid",
        },
        
        @{
            @"itemid": @"sources",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"file",
            @"row9": @"file",
        },
        
        @{
            @"itemid": @"albums",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"fanart",
            @"row5": @"rating",
            @"row6": @"albumid",
            @"row7": @"playcount",
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"albumid",
            @"row9": @"albumid",
            @"row10": @"artist",
            @"row11": @"genre",
            @"row12": @"description",
            @"row13": @"albumlabel",
            @"itemid_extra_info": @"albumdetails",
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
            @"playlistid": @PLAYERID_MUSIC,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"artist",
            @"row12": @"album",
            @"row13": @"playcount",
        },
        
        @{
            @"itemid": @"albums",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"fanart",
            @"row5": @"rating",
            @"row6": @"albumid",
            @"row7": @"playcount",
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"albumid",
            @"row9": @"albumid",
            @"row10": @"artist",
            @"row11": @"genre",
            @"row12": @"description",
            @"row13": @"albumlabel",
            @"itemid_extra_info": @"albumdetails",
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
            @"playlistid": @PLAYERID_MUSIC,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"artist",
            @"row12": @"album",
            @"row13": @"duration",
            @"row14": @"rating",
            @"row15": @"playcount",
        },
        
        @{
            @"itemid": @"albums",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"fanart",
            @"row5": @"rating",
            @"row6": @"albumid",
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"albumid",
            @"row9": @"albumid",
            @"row10": @"artist",
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
            @"playlistid": @PLAYERID_MUSIC,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"artist",
            @"row12": @"album",
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
            @"playlistid": @PLAYERID_MUSIC,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"artist",
            @"row12": @"album",
            @"row13": @"playcount",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"file",
            @"row9": @"file",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"filetype",
            @"row6": @"file",
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
        },
        
        @{
            @"itemid": @"roles",
            @"row1": @"title",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"filetype",
            @"row6": @"roleid",
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"roleid",
            @"row9": @"roleid",
        },
    ];
    
    menu_Music.rowHeight = DEFAULT_ROW_HEIGHT;
    menu_Music.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_Music.filterModes = @[
        [self modes_icons_listened],
        [self modes_icons_artiststype],
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
    ];
    
    menu_Music.sheetActions = @[
        [self action_album],
        [self action_artist],
        [self action_filemode_music],
        [self action_queue_to_play],
        [self action_album],
        [self action_queue_to_play],
        [self action_album],
        [self action_queue_to_play],
        [self action_album],
        [self action_queue_to_play],
        [self action_queue_to_play],
        @[],
        [self action_playlist],
        @[],
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
        @NO,
    ];
    
    menu_Music.subItem = [mainMenu new];
    menu_Music.subItem.mainMethod = @[
        @{
            @"method": @"AudioLibrary.GetSongs",
            @"albumView": @YES,
        },
        @{
            @"method": @"AudioLibrary.GetAlbums",
            @"extra_info_method": @"AudioLibrary.GetAlbumDetails",
        },
        @{
            @"method": @"AudioLibrary.GetAlbums",
            @"extra_info_method": @"AudioLibrary.GetAlbumDetails",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"AudioLibrary.GetSongs",
            @"albumView": @YES,
        },
        @{},
        @{
            @"method": @"AudioLibrary.GetSongs",
            @"albumView": @YES,
        },
        @{},
        @{
            @"method": @"AudioLibrary.GetSongs",
            @"albumView": @YES,
        },
        @{},
        @{},
        @{
            @"method": @"Files.GetDirectory",
        },
        @{},
        @{
            @"method": @"AudioLibrary.GetArtists",
            @"extra_info_method": @"AudioLibrary.GetArtistDetails",
        },
    ];
    
    menu_Music.subItem.mainParameters = [@[
        @{
            @"parameters": @{
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
                    @"albumartist",
                    @"albumid",
                    @"file",
                    @"fanart",
                ],
            },
            @"label": LOCALIZED_STR(@"Songs"),
            @"defaultThumb": @"nocover_music",
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"year" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"year",
                    @"thumbnail",
                    @"artist",
                    @"playcount",
                ],
            },
            @"extra_info_parameters": @{
                @"properties": @[
                    @"year",
                    @"thumbnail",
                    @"artist",
                    @"genre",
                    @"description",
                    @"albumlabel",
                    @"fanart",
                ],
                @"kodiExtrasPropertiesMinimumVersion": @{
                    @"18": @[
                        @"art",
                    ],
                },
            },
            @"label": LOCALIZED_STR(@"Albums"),
            @"defaultThumb": @"nocover_music",
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"year",
                    @"thumbnail",
                    @"artist",
                    @"playcount",
                ],
            },
            @"extra_info_parameters": @{
                @"properties": @[
                    @"year",
                    @"thumbnail",
                    @"artist",
                    @"genre",
                    @"description",
                    @"albumlabel",
                    @"fanart",
                ],
                @"kodiExtrasPropertiesMinimumVersion": @{
                    @"18": @[
                        @"art",
                    ],
                },
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Album"),
                    LOCALIZED_STR(@"Artist"),
                    LOCALIZED_STR(@"Year"),
                    LOCALIZED_STR(@"Play count"),
                ],
                @"method": @[
                    @"label",
                    @"genre",
                    @"year",
                    @"playcount",
                ],
            },
            @"label": LOCALIZED_STR(@"Albums"),
            @"defaultThumb": @"nocover_music",
            @"enableCollectionView": @YES,
            @"enableLibraryCache": @YES,
            @"watchedListenedStrings": [self watchedListenedString],
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": filemodeMusicType,
                @"file_properties": @[
                    @"thumbnail",
                    @"art",
                    @"playcount",
                ],
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        
        @{
            @"parameters": @{
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
                    @"albumartist",
                    @"albumid",
                    @"file",
                    @"fanart",
                ],
            },
            @"label": LOCALIZED_STR(@"Songs"),
            @"defaultThumb": @"nocover_music",
        },
        
        @{},
        
        @{
            @"parameters": @{
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
                    @"albumartist",
                    @"albumid",
                    @"file",
                    @"fanart",
                ],
            },
            @"label": LOCALIZED_STR(@"Songs"),
            @"defaultThumb": @"nocover_music",
        },
        
        @{},
        
        @{
            @"parameters": @{
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
                    @"albumartist",
                    @"albumid",
                    @"file",
                    @"fanart",
                ],
            },
            @"label": LOCALIZED_STR(@"Songs"),
            @"defaultThumb": @"nocover_music",
        },
        
        @{},
        @{},
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"file_properties": @[
                    @"thumbnail",
                ],
                @"media": @"music",
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @DEFAULT_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Movie],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"file_properties": @[
                    @"thumbnail",
                    @"artist",
                    @"duration",
                ],
                @"media": @"music",
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        
        @{
            @"parameters": @{
                @"albumartistsonly": @NO,
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"thumbnail",
                    @"genre",
                ],
            },
            @"extra_info_parameters": @{
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
                    @"fanart",
                ],
                @"kodiExtrasPropertiesMinimumVersion": @{
                    @"18": @[
                        @"roles",
                        @"art",
                    ],
                },
            },
            @"label": LOCALIZED_STR(@"Artists"),
            @"defaultThumb": @"nocover_artist",
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Musicfullscreen],
        },
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
            @"playlistid": @PLAYERID_MUSIC,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"albumartist",
        },
        
        @{
            @"itemid": @"albums",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"fanart",
            @"row5": @"rating",
            @"row6": @"albumid",
            @"row7": @"playcount",
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"albumid",
            @"row9": @"albumid",
            @"row10": @"artist",
            @"row11": @"genre",
            @"row12": @"description",
            @"row13": @"albumlabel",
            @"itemid_extra_info": @"albumdetails",
        },
        
        @{
            @"itemid": @"albums",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"fanart",
            @"row5": @"rating",
            @"row6": @"albumid",
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"albumid",
            @"row9": @"albumid",
            @"row10": @"playcount",
            @"row11": @"genre",
            @"row12": @"description",
            @"row13": @"albumlabel",
            @"itemid_extra_info": @"albumdetails",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"filetype",
            @"row3": @"filetype",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"file",
            @"row7": @"playcount",
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
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
            @"playlistid": @PLAYERID_MUSIC,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"albumartist",
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
            @"playlistid": @PLAYERID_MUSIC,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"albumartist",
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
            @"playlistid": @PLAYERID_MUSIC,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"albumartist",
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
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"filetype",
            @"row6": @"file",
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
        },
        
        @{
            @"itemid": @"artists",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"yearsactive",
            @"row4": @"genre",
            @"row5": @"disbanded",
            @"row6": @"artistid",
            @"playlistid": @PLAYERID_MUSIC,
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
            @"itemid_extra_info": @"artistdetails",
        },
    ];
    
    menu_Music.subItem.enableSection = YES;
    menu_Music.subItem.rowHeight = DEFAULT_ROW_HEIGHT;
    menu_Music.subItem.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_Music.subItem.sheetActions = @[
        [self action_queue_to_play],
        [self action_album],
        [self action_album],
        [self action_filemode_music],
        [self action_queue_to_play],
        @[],
        [self action_queue_to_play],
        @[],
        [self action_queue_to_play],
        @[],
        @[],
        [self action_queue_to_play],
        [self action_queue_to_play],
        [self action_artist],
    ];
    
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
        @NO,
    ];
    
    menu_Music.subItem.subItem = [mainMenu new];
    menu_Music.subItem.subItem.mainMethod = @[
        @{},
        @{
            @"method": @"AudioLibrary.GetSongs",
            @"albumView": @YES,
        },
        @{
            @"method": @"AudioLibrary.GetSongs",
            @"albumView": @YES,
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"AudioLibrary.GetAlbums",
            @"extra_info_method": @"AudioLibrary.GetAlbumDetails",
        },
    ];
    
    menu_Music.subItem.subItem.mainParameters = [@[
        @{},
        
        @{
            @"parameters": @{
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
                    @"albumartist",
                    @"albumid",
                    @"file",
                    @"fanart",
                ],
            },
            @"label": LOCALIZED_STR(@"Songs"),
            @"defaultThumb": @"nocover_music",
        },
        
        @{
            @"parameters": @{
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
                    @"albumartist",
                    @"albumid",
                    @"file",
                    @"fanart",
                ],
            },
            @"label": LOCALIZED_STR(@"Songs"),
            @"defaultThumb": @"nocover_music",
        },
        
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @DEFAULT_THUMB_WIDTH,
        },
        @{
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @DEFAULT_THUMB_WIDTH,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"year" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"year",
                    @"thumbnail",
                    @"artist",
                    @"playcount",
                ],
            },
            @"extra_info_parameters": @{
                @"properties": @[
                    @"year",
                    @"thumbnail",
                    @"artist",
                    @"genre",
                    @"description",
                    @"albumlabel",
                    @"fanart",
                ],
                @"kodiExtrasPropertiesMinimumVersion": @{
                    @"18": @[
                        @"art",
                    ],
                },
            },
            @"label": LOCALIZED_STR(@"Albums"),
            @"defaultThumb": @"nocover_music",
            @"enableCollectionView": @YES,
            @"combinedFilter": @"roleid",
            @"itemSizes": [self itemSizes_Music],
        },
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
            @"playlistid": @PLAYERID_MUSIC,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"albumartist",
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
            @"playlistid": @PLAYERID_MUSIC,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"albumartist",
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
            @"row7": @"playcount",
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"albumid",
            @"row9": @"albumid",
            @"row10": @"artist",
            @"row11": @"genre",
            @"row12": @"description",
            @"row13": @"albumlabel",
            @"itemid_extra_info": @"albumdetails",
        },
    ];
    
    menu_Music.subItem.subItem.rowHeight = DEFAULT_ROW_HEIGHT;
    menu_Music.subItem.subItem.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_Music.subItem.subItem.sheetActions = @[
        @[],
        [self action_queue_to_play],
        [self action_queue_to_play],
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
        [self action_album],
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
        @NO,
    ];
    
    menu_Music.subItem.subItem.subItem = [mainMenu new];
    menu_Music.subItem.subItem.subItem.mainMethod = @[
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
            @"method": @"AudioLibrary.GetSongs",
            @"albumView": @YES,
        },
    ];
    
    menu_Music.subItem.subItem.subItem.mainParameters = [@[
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
            @"parameters": @{
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
                    @"albumartist",
                    @"albumid",
                    @"file",
                    @"fanart",
                ],
            },
            @"label": LOCALIZED_STR(@"Songs"),
            @"defaultThumb": @"nocover_music",
        },
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
            @"playlistid": @PLAYERID_MUSIC,
            @"row9": @"songid",
            @"row10": @"file",
            @"row11": @"albumartist",
        },
    ];
    
    menu_Music.subItem.subItem.subItem.rowHeight = DEFAULT_ROW_HEIGHT;
    menu_Music.subItem.subItem.subItem.thumbWidth = DEFAULT_THUMB_WIDTH;
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
        [self action_queue_to_play],
    ];
    
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
        @NO,
    ];
    
#pragma mark - Movies
    __auto_type menu_Movies = [mainMenu new];
    menu_Movies.mainLabel = LOCALIZED_STR(@"Movies");
    menu_Movies.icon = @"icon_menu_movies";
    menu_Movies.type = TypeMovies;
    menu_Movies.family = FamilyDetailView;
    menu_Movies.enableSection = YES;
    menu_Movies.noConvertTime = YES;
    menu_Movies.mainButtons = @[
        @"st_movie",
        @"st_movie_genre",
        @"st_movie_set",
        @"st_movie_recently",
        @"st_movie_tags",
        @"st_filemode",
        @"st_addons",
        @"st_playlists",
    ];
    
    menu_Movies.mainMethod = @[
        @{
            @"method": @"VideoLibrary.GetMovies",
            @"extra_info_method": @"VideoLibrary.GetMovieDetails",
        },
        @{
            @"method": @"VideoLibrary.GetGenres",
        },
        @{
            @"method": @"VideoLibrary.GetMovieSets",
            @"extra_info_method": @"VideoLibrary.GetMovieSetDetails",
        },
        @{
            @"method": @"VideoLibrary.GetRecentlyAddedMovies",
            @"extra_info_method": @"VideoLibrary.GetMovieDetails",
        },
        @{
            @"method": @"VideoLibrary.GetTags",
        },
        @{
            @"method": @"Files.GetSources",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
    ];
    
    menu_Movies.mainParameters = [@[
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"year",
                    @"playcount",
                    @"rating",
                    @"thumbnail",
                    @"genre",
                    @"runtime",
                    @"trailer",
                    @"director",
                    @"file",
                    @"dateadded",
                ],
            },
            @"extra_info_parameters": @{
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
                    @"trailer",
                    @"dateadded",
                    @"tagline",
                ],
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Title"),
                    LOCALIZED_STR(@"Year"),
                    LOCALIZED_STR(@"Rating"),
                    LOCALIZED_STR(@"Duration"),
                    LOCALIZED_STR(@"Date added"),
                    LOCALIZED_STR(@"Play count"),
                    LOCALIZED_STR(@"Random"),
                ],
                @"method": @[
                    @"label",
                    @"year",
                    @"rating",
                    @"runtime",
                    @"dateadded",
                    @"playcount",
                    @"random",
                ],
            },
            @"label": LOCALIZED_STR(@"Movies"),
            @"defaultThumb": @"nocover_movies",
            @"FrodoExtraArt": @YES,
            @"enableCollectionView": @YES,
            @"enableLibraryCache": @YES,
            @"enableLibraryFullScreen": @YES,
            @"itemSizes": [self itemSizes_Moviefullscreen],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"type": @"movie",
                @"properties": @[
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Movie Genres"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @0,
            @"enableLibraryCache": @YES,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"thumbnail",
                    @"plot",
                    @"fanart",
                    @"playcount",
                ],
            },
            @"extra_info_parameters": @{
                @"properties": @[
                    @"thumbnail",
                    @"plot",
                    @"fanart",
                    @"playcount",
                ],
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Name"),
                    LOCALIZED_STR(@"Play count"),
                ],
                @"method": @[
                    @"label",
                    @"playcount",
                ],
            },
            @"FrodoExtraArt": @YES,
            @"enableCollectionView": @YES,
            @"enableLibraryCache": @YES,
            @"defaultThumb": @"nocover_movie_sets",
            @"itemSizes": [self itemSizes_Movie],
            @"label": LOCALIZED_STR(@"Movie Sets"),
        },
        
        @{
            @"parameters": @{
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
                    @"file",
                ],
            },
            @"label": LOCALIZED_STR(@"Added Movies"),
            @"defaultThumb": @"nocover_movies",
            @"extra_info_parameters": @{
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
                    @"trailer",
                    @"dateadded",
                    @"tagline",
                ],
            },
            @"FrodoExtraArt": @YES,
            @"enableCollectionView": @YES,
            @"collectionViewRecentlyAdded": @YES,
            @"enableLibraryFullScreen": @YES,
            @"itemSizes": [self itemSizes_MovieRecentlyfullscreen],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"type": @"movie",
                @"properties": @[],
            },
            @"label": LOCALIZED_STR(@"Movie Tags"),
            @"morelabel": LOCALIZED_STR(@"Movie Tags"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @0,
            @"enableLibraryCache": @YES,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"morelabel": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
                @"directory": @"addons://sources/video",
                @"properties": @[
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Video Add-ons"),
            @"morelabel": LOCALIZED_STR(@"Video Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
                @"directory": @"special://videoplaylists",
                @"properties": @[
                    @"thumbnail",
                    @"file",
                ],
                @"file_properties": @[
                    @"thumbnail",
                    @"file",
                ],
            },
            @"label": LOCALIZED_STR(@"Video Playlists"),
            @"morelabel": LOCALIZED_STR(@"Video Playlists"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"isVideoPlaylist": @YES,
        },
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
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"movieid",
            @"row9": @"movieid",
            @"row10": @"playcount",
            @"row11": @"trailer",
            @"row12": @"director",
            @"row13": @"mpaa",
            @"row14": @"votes",
            @"row15": @"studio",
            @"row16": @"cast",
            @"row7": @"file",
            @"row17": @"plot",
            @"row18": @"resume",
            @"row19": @"dateadded",
            @"row20": @"tagline",
            @"itemid_extra_info": @"moviedetails",
        },
        
        @{
            @"itemid": @"genres",
            @"row1": @"label",
            @"row2": @"label",
            @"row3": @"disable",
            @"row4": @"disable",
            @"row5": @"disable",
            @"row6": @"genre",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"genreid",
        },
        
        @{
            @"itemid": @"sets",
            @"row1": @"label",
            @"row2": @"disable",
            @"row3": @"disable",
            @"row4": @"disable",
            @"row5": @"disable",
            @"row6": @"setid",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"setid",
            @"row9": @"setid",
            @"row10": @"playcount",
            @"row11": @"plot",
            @"itemid_extra_info": @"setdetails",
        },
        
        @{
            @"itemid": @"movies",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"movieid",
            @"playlistid": @PLAYERID_VIDEO,
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
            @"row20": @"tagline",
            @"itemid_extra_info": @"moviedetails",
        },
        
        @{
            @"itemid": @"tags",
            @"row1": @"label",
            @"row2": @"label",
            @"row3": @"disable",
            @"row4": @"disable",
            @"row5": @"disable",
            @"row6": @"tag",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"tagid",
            @"row19": @"tag",
        },
        
        @{
            @"itemid": @"sources",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"filetype",
            @"row6": @"file",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
        },
    ];
    
    menu_Movies.rowHeight = PORTRAIT_ROW_HEIGHT;
    menu_Movies.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_Movies.sheetActions = @[
        [self action_movie],
        @[],
        @[LOCALIZED_STR(@"Movie Set Details")],
        [self action_movie],
        @[],
        [self action_queue_to_play],
        @[],
        [self action_playlist],
    ];
    
    menu_Movies.showInfo = @[
        @YES,
        @NO,
        @NO,
        @YES,
        @NO,
        @NO,
        @NO,
        @NO,
    ];
    
    menu_Movies.filterModes = @[
        [self modes_icons_watched],
        [self modes_icons_empty],
        [self modes_icons_watched],
        [self modes_icons_watched],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
    ];
    
    menu_Movies.subItem = [mainMenu new];
    menu_Movies.subItem.mainMethod = [@[
        @{},
        @{
            @"method": @"VideoLibrary.GetMovies",
            @"extra_info_method": @"VideoLibrary.GetMovieDetails",
        },
        @{
            @"method": @"VideoLibrary.GetMovies",
            @"extra_info_method": @"VideoLibrary.GetMovieDetails",
        },
        @{},
        @{
            @"method": @"VideoLibrary.GetMovies",
            @"extra_info_method": @"VideoLibrary.GetMovieDetails",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{},
    ] mutableCopy];
    
    menu_Movies.subItem.noConvertTime = YES;
    
    menu_Movies.subItem.mainParameters = [@[
        @{},
        
        @{
            @"parameters": @{
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
                    @"dateadded",
                ],
            },
            @"extra_info_parameters": @{
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
                    @"trailer",
                    @"dateadded",
                    @"tagline",
                ],
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Title"),
                    LOCALIZED_STR(@"Year"),
                    LOCALIZED_STR(@"Rating"),
                    LOCALIZED_STR(@"Duration"),
                    LOCALIZED_STR(@"Date added"),
                    LOCALIZED_STR(@"Play count"),
                ],
                @"method": @[
                    @"label",
                    @"year",
                    @"rating",
                    @"runtime",
                    @"dateadded",
                    @"playcount",
                ],
            },
            @"label": LOCALIZED_STR(@"Movies"),
            @"defaultThumb": @"nocover_movies",
            @"FrodoExtraArt": @YES,
            @"enableCollectionView": @YES,
            @"enableLibraryCache": @YES,
            @"itemSizes": [self itemSizes_Movie],
        },
        
        @{
            @"parameters": @{
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
                    @"dateadded",
                ],
            },
            @"extra_info_parameters": @{
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
                    @"trailer",
                    @"dateadded",
                    @"tagline",
                ],
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Title"),
                    LOCALIZED_STR(@"Year"),
                    LOCALIZED_STR(@"Rating"),
                    LOCALIZED_STR(@"Duration"),
                    LOCALIZED_STR(@"Date added"),
                    LOCALIZED_STR(@"Play count"),
                ],
                @"method": @[
                    @"label",
                    @"year",
                    @"rating",
                    @"runtime",
                    @"dateadded",
                    @"playcount",
                ],
            },
            @"label": LOCALIZED_STR(@"Movies"),
            @"defaultThumb": @"nocover_movies",
            @"FrodoExtraArt": @YES,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Movie],
        },
        
        @{},
        
        @{
            @"parameters": @{
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
                    @"dateadded",
                ],
            },
            @"extra_info_parameters": @{
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
                    @"trailer",
                    @"dateadded",
                    @"tagline",
                ],
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Title"),
                    LOCALIZED_STR(@"Year"),
                    LOCALIZED_STR(@"Rating"),
                    LOCALIZED_STR(@"Duration"),
                    LOCALIZED_STR(@"Date added"),
                    LOCALIZED_STR(@"Play count"),
                ],
                @"method": @[
                    @"label",
                    @"year",
                    @"rating",
                    @"runtime",
                    @"dateadded",
                    @"playcount",
                ],
            },
            @"label": LOCALIZED_STR(@"Movies"),
            @"defaultThumb": @"nocover_movies",
            @"FrodoExtraArt": @YES,
            @"enableCollectionView": @YES,
            @"enableLibraryCache": @YES,
            @"itemSizes": [self itemSizes_Movie],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": filemodeVideoType,
                @"file_properties": @[
                    @"thumbnail",
                    @"art",
                    @"playcount",
                ],
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
                @"file_properties": @[
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Video Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
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
                    @"resume",
                    @"tagline",
                ],
                @"media": @"video",
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @PORTRAIT_ROW_HEIGHT,
            @"thumbWidth": @DEFAULT_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"FrodoExtraArt": @YES,
            @"itemSizes": [self itemSizes_Movie],
        },
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
            @"playlistid": @PLAYERID_VIDEO,
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
            @"row20": @"tagline",
            @"itemid_extra_info": @"moviedetails",
        },
        
        @{
            @"itemid": @"movies",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"movieid",
            @"playlistid": @PLAYERID_VIDEO,
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
            @"row20": @"tagline",
            @"itemid_extra_info": @"moviedetails",
        },
        
        @{},
        
        @{
            @"itemid": @"movies",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"movieid",
            @"playlistid": @PLAYERID_VIDEO,
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
            @"row20": @"tagline",
            @"itemid_extra_info": @"moviedetails",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"filetype",
            @"row3": @"filetype",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"file",
            @"row7": @"playcount",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
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
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @PLAYERID_VIDEO,
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
            @"row19": @"dateadded",
            @"row20": @"tagline",
        },
    ];
    
    menu_Movies.subItem.enableSection = YES;
    menu_Movies.subItem.rowHeight = PORTRAIT_ROW_HEIGHT;
    menu_Movies.subItem.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_Movies.subItem.sheetActions = @[
        @[],
        [self action_movie],
        [self action_movie],
        @[],
        [self action_movie],
        [self action_queue_to_play],
        [self action_queue_to_play],
        [self action_queue_to_play],
    ];
    
    menu_Movies.subItem.showInfo = @[
        @NO,
        @YES,
        @YES,
        @NO,
        @YES,
        @NO,
        @NO,
        @NO,
    ];
    
    menu_Movies.subItem.filterModes = @[
        [self modes_icons_empty],
        [self modes_icons_watched],
        [self modes_icons_watched],
        [self modes_icons_empty],
        [self modes_icons_watched],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
    ];
    
    menu_Movies.subItem.subItem = [mainMenu new];
    menu_Movies.subItem.subItem.noConvertTime = YES;
    menu_Movies.subItem.subItem.mainMethod = [@[
        @{},
        @{},
        @{},
        @{},
        @{},
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{},
    ] mutableCopy];
    
    menu_Movies.subItem.subItem.mainParameters = [@[
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        @{},
    ] mutableCopy];
    
    menu_Movies.subItem.subItem.mainFields = @[
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
        @{},
    ];
    
    menu_Movies.subItem.subItem.enableSection = NO;
    menu_Movies.subItem.subItem.rowHeight = PORTRAIT_ROW_HEIGHT;
    menu_Movies.subItem.subItem.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_Movies.subItem.subItem.sheetActions = @[
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
        @[],
    ];
    
#pragma mark - Videos
    __auto_type menu_Videos = [mainMenu new];
    menu_Videos.mainLabel = LOCALIZED_STR(@"Videos");
    menu_Videos.icon = @"icon_menu_videos";
    menu_Videos.type = TypeVideos;
    menu_Videos.family = FamilyDetailView;
    menu_Videos.enableSection = YES;
    menu_Videos.noConvertTime = YES;
    menu_Videos.mainButtons = @[
        @"st_music_videos",
        @"st_movie_recently",
        @"st_filemode",
        @"st_addons",
        @"st_playlists",
    ];
    
    menu_Videos.mainMethod = @[
        @{
            @"method": @"VideoLibrary.GetMusicVideos",
            @"extra_info_method": @"VideoLibrary.GetMusicVideoDetails",
        },
        @{
            @"method": @"VideoLibrary.GetRecentlyAddedMusicVideos",
            @"extra_info_method": @"VideoLibrary.GetMusicVideoDetails",
        },
        @{
            @"method": @"Files.GetSources",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
    ];
    
    menu_Videos.mainParameters = [@[
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"artist",
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
                    @"resume",
                ],
            },
            @"extra_info_parameters": @{
                @"properties": @[
                    @"artist",
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
                    @"resume",
                ],
                @"kodiExtrasPropertiesMinimumVersion": @{
                    @"18": @[
                        @"art",
                    ],
                },
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Title"),
                    LOCALIZED_STR(@"Artist"),
                    LOCALIZED_STR(@"Genre"),
                    LOCALIZED_STR(@"Year"),
                    LOCALIZED_STR(@"Play count"),
                    LOCALIZED_STR(@"Random"),
                ],
                @"method": @[
                    @"label",
                    @"artist",
                    @"genre",
                    @"year",
                    @"playcount",
                    @"random",
                ],
            },
            @"kodiExtrasPropertiesMinimumVersion": @{
                @"18": @[
                    @"art",
                ],
            },
            @"label": LOCALIZED_STR(@"Music Videos"),
            @"morelabel": LOCALIZED_STR(@"Music Videos"),
            @"defaultThumb": @"nocover_musicvideos",
            @"enableCollectionView": @YES,
            @"enableLibraryCache": @YES,
            @"enableLibraryFullScreen": @YES,
            @"itemSizes": [self itemSizes_Moviefullscreen],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"artist",
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
                    @"resume",
                ],
            },
            @"extra_info_parameters": @{
                @"properties": @[
                    @"artist",
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
                    @"resume",
                ],
                @"kodiExtrasPropertiesMinimumVersion": @{
                    @"18": @[
                        @"art",
                    ],
                },
            },
            @"kodiExtrasPropertiesMinimumVersion": @{
                @"18": @[
                    @"art",
                ],
            },
            @"label": LOCALIZED_STR(@"Added Music Videos"),
            @"defaultThumb": @"nocover_musicvideos",
            @"enableCollectionView": @YES,
            @"collectionViewRecentlyAdded": @YES,
            @"enableLibraryFullScreen": @YES,
            @"itemSizes": [self itemSizes_MovieRecentlyfullscreen],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"morelabel": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
                @"directory": @"addons://sources/video",
                @"properties": @[
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Video Add-ons"),
            @"morelabel": LOCALIZED_STR(@"Video Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
                @"directory": @"special://videoplaylists",
                @"properties": @[
                    @"thumbnail",
                    @"file",
                ],
                @"file_properties": @[
                    @"thumbnail",
                    @"file",
                ],
            },
            @"label": LOCALIZED_STR(@"Video Playlists"),
            @"morelabel": LOCALIZED_STR(@"Video Playlists"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"isVideoPlaylist": @YES,
        },
    ] mutableCopy];
    
    menu_Videos.mainFields = @[
        @{
            @"itemid": @"musicvideos",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"musicvideoid",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"musicvideoid",
            @"row9": @"musicvideoid",
            @"row10": @"director",
            @"row11": @"artist",
            @"row12": @"plot",
            @"row13": @"playcount",
            @"row14": @"resume",
            @"row15": @"votes",
            @"row16": @"artist",
            @"row7": @"file",
            @"itemid_extra_info": @"musicvideodetails",
        },
        
        @{
            @"itemid": @"musicvideos",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"musicvideoid",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"musicvideoid",
            @"row9": @"musicvideoid",
            @"row10": @"director",
            @"row11": @"artist",
            @"row12": @"plot",
            @"row13": @"playcount",
            @"row14": @"resume",
            @"row15": @"votes",
            @"row16": @"artist",
            @"row7": @"file",
            @"itemid_extra_info": @"musicvideodetails",
        },
        
        @{
            @"itemid": @"sources",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"filetype",
            @"row6": @"file",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
        },
    ];
    
    menu_Videos.rowHeight = PORTRAIT_ROW_HEIGHT;
    menu_Videos.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_Videos.sheetActions = @[
        [self action_musicvideo],
        [self action_musicvideo],
        [self action_queue_to_play],
        @[],
        [self action_playlist],
    ];
    
    menu_Videos.showInfo = @[
        @YES,
        @YES,
        @NO,
        @NO,
        @NO,
    ];
    
    menu_Videos.filterModes = @[
        [self modes_icons_watched],
        [self modes_icons_watched],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
    ];
    
    menu_Videos.subItem = [mainMenu new];
    menu_Videos.subItem.mainMethod = [@[
        @{},
        @{},
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{},
    ] mutableCopy];
    
    menu_Videos.subItem.noConvertTime = YES;
    
    menu_Videos.subItem.mainParameters = [@[
        @{},
        @{},
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": filemodeVideoType,
                @"file_properties": @[
                    @"thumbnail",
                    @"art",
                    @"playcount",
                ],
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
                @"file_properties": @[
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Video Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
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
                    @"resume",
                ],
                @"media": @"video",
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @PORTRAIT_ROW_HEIGHT,
            @"thumbWidth": @DEFAULT_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"FrodoExtraArt": @YES,
            @"itemSizes": [self itemSizes_Movie],
        },
    ] mutableCopy];
    
    menu_Videos.subItem.mainFields = @[
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
            @"row7": @"playcount",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
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
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @PLAYERID_VIDEO,
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
            @"row19": @"dateadded",
        },
    ];
    
    menu_Videos.subItem.enableSection = YES;
    menu_Videos.subItem.rowHeight = PORTRAIT_ROW_HEIGHT;
    menu_Videos.subItem.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_Videos.subItem.sheetActions = @[
        @[],
        @[],
        [self action_queue_to_play],
        [self action_queue_to_play],
        [self action_queue_to_play],
    ];
    
    menu_Videos.subItem.filterModes = @[
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
    ];
    
    menu_Videos.subItem.subItem = [mainMenu new];
    menu_Videos.subItem.subItem.noConvertTime = YES;
    menu_Videos.subItem.subItem.mainMethod = [@[
        @{},
        @{},
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{},
    ] mutableCopy];
    
    menu_Videos.subItem.subItem.mainParameters = [@[
        @{},
        @{},
        @{},
        @{
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        @{},
    ] mutableCopy];
    
    menu_Videos.subItem.subItem.mainFields = @[
        @{},
        @{},
        @{},
        @{},
        @{},
    ];
    
    menu_Videos.subItem.subItem.enableSection = NO;
    menu_Videos.subItem.subItem.rowHeight = PORTRAIT_ROW_HEIGHT;
    menu_Videos.subItem.subItem.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_Videos.subItem.subItem.sheetActions = @[
        @[],
        @[],
        @[],
        @[],
        @[],
    ];
    
#pragma mark - TV Shows
    __auto_type menu_TVShows = [mainMenu new];
    menu_TVShows.mainLabel = LOCALIZED_STR(@"TV Shows");
    menu_TVShows.icon = @"icon_menu_tvshows";
    menu_TVShows.type = TypeTvShows;
    menu_TVShows.family = FamilyDetailView;
    menu_TVShows.enableSection = YES;
    menu_TVShows.mainButtons = @[
        @"st_tv",
        @"st_tv_recently",
        @"st_filemode",
        @"st_addons",
        @"st_playlists",
    ];
    
    menu_TVShows.mainMethod = [@[
        @{
            @"method": @"VideoLibrary.GetTVShows",
            @"extra_info_method": @"VideoLibrary.GetTVShowDetails",
            @"tvshowsView": @YES,
        },
        @{
            @"method": @"VideoLibrary.GetRecentlyAddedEpisodes",
            @"extra_info_method": @"VideoLibrary.GetEpisodeDetails",
        },
        @{
            @"method": @"Files.GetSources",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
    ] mutableCopy];
    
    menu_TVShows.mainParameters = [@[
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"year",
                    @"playcount",
                    @"rating",
                    @"thumbnail",
                    @"genre",
                    @"studio",
                    @"episode",
                ],
            },
            @"extra_info_parameters": @{
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
                    @"fanart",
                ],
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Title"),
                    LOCALIZED_STR(@"Year"),
                    LOCALIZED_STR(@"Rating"),
                    LOCALIZED_STR(@"Random"),
                ],
                @"method": @[
                    @"label",
                    @"year",
                    @"rating",
                    @"random",
                ],
            },
            @"label": LOCALIZED_STR(@"TV Shows"),
            @"defaultThumb": @"nocover_tvshows",
            @"FrodoExtraArt": @YES,
            @"enableLibraryCache": @YES,
            @"enableCollectionView": @YES,
            @"enableLibraryFullScreen": @YES,
            @"itemSizes": [self itemSizes_Moviefullscreen],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"episode",
                    @"thumbnail",
                    @"firstaired",
                    @"playcount",
                    @"showtitle",
                    @"file",
                    @"title",
                    @"season",
                ],
            },
            @"extra_info_parameters": @{
                @"properties": @[
                    @"episode",
                    @"thumbnail",
                    @"firstaired",
                    @"runtime",
                    @"plot",
                    @"director",
                    @"writer",
                    @"rating",
                    @"title",
                    @"showtitle",
                    @"season",
                    @"cast",
                    @"file",
                    @"fanart",
                    @"playcount",
                    @"resume",
                ],
            },
            @"label": LOCALIZED_STR(@"Added Episodes"),
            @"rowHeight": @DEFAULT_ROW_HEIGHT,
            @"thumbWidth": @EPISODE_THUMB_WIDTH,
            @"defaultThumb": @"nocover_tvshows_episode",
            @"FrodoExtraArt": @YES,
            @"itemSizes": [self itemSizes_TVShowsfullscreen],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
                @"directory": @"addons://sources/video",
                @"properties": @[
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Video Add-ons"),
            @"morelabel": LOCALIZED_STR(@"Video Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
                @"directory": @"special://videoplaylists",
                @"properties": @[
                    @"thumbnail",
                    @"file",
                ],
                @"file_properties": @[
                    @"thumbnail",
                    @"file",
                ],
            },
            @"label": LOCALIZED_STR(@"Video Playlists"),
            @"morelabel": LOCALIZED_STR(@"Video Playlists"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"isVideoPlaylist": @YES,
        },
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
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"tvshowid",
            @"row9": @"playcount",
            @"row10": @"mpaa",
            @"row11": @"votes",
            @"row12": @"cast",
            @"row13": @"premiered",
            @"row14": @"episode",
            @"row15": @"plot",
            @"row16": @"studio",
            @"itemid_extra_info": @"tvshowdetails",
        },
        
        @{
            @"itemid": @"episodes",
            @"row1": @"title",
            @"row2": @"showtitle",
            @"row3": @"firstaired",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"episodeid",
            @"row7": @"playcount",
            @"row8": @"episodeid",
            @"playlistid": @PLAYERID_VIDEO,
            @"row9": @"episodeid",
            @"row10": @"season",
            @"row11": @"episode",
            @"row12": @"writer",
            @"row13": @"resume",
            @"row14": @"showtitle",
            @"row15": @"plot",
            @"row16": @"cast",
            @"row17": @"firstaired",
            @"row18": @"season",
            @"itemid_extra_info": @"episodedetails",
        },
        
        @{
            @"itemid": @"sources",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"artist",
            @"row3": @"year",
            @"row4": @"duration",
            @"row5": @"filetype",
            @"row6": @"file",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
        },
    ];
    
    menu_TVShows.rowHeight = tvshowHeight;
    menu_TVShows.thumbWidth = thumbWidth;
    menu_TVShows.sheetActions = @[
        @[LOCALIZED_STR(@"TV Show Details")],
        [self action_episode],
        [self action_queue_to_play],
        @[],
        [self action_playlist],
    ];
    
    menu_TVShows.showInfo = @[
        @YES,
        @YES,
        @NO,
        @NO,
        @NO,
    ];
    
    menu_TVShows.filterModes = @[
        [self modes_icons_watched],
        [self modes_icons_watched],
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
    ];
    
    menu_TVShows.subItem = [mainMenu new];
    menu_TVShows.subItem.mainMethod = [@[
        @{
            @"method": @"VideoLibrary.GetEpisodes",
            @"extra_info_method": @"VideoLibrary.GetEpisodeDetails",
            @"episodesView": @YES,
            @"extra_section_method": @"VideoLibrary.GetSeasons",
        },
        @{},
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{},
    ] mutableCopy];
    
    menu_TVShows.subItem.mainParameters = [@[
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"episode" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"episode",
                    @"thumbnail",
                    @"firstaired",
                    @"showtitle",
                    @"playcount",
                    @"season",
                    @"tvshowid",
                    @"runtime",
                    @"file",
                    @"title",
                ],
            },
            @"extra_info_parameters": @{
                @"properties": @[
                    @"episode",
                    @"thumbnail",
                    @"firstaired",
                    @"runtime",
                    @"plot",
                    @"director",
                    @"writer",
                    @"rating",
                    @"title",
                    @"showtitle",
                    @"season",
                    @"cast",
                    @"fanart",
                    @"resume",
                    @"playcount",
                    @"file",
                ],
            },
            @"extra_section_parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"season",
                    @"thumbnail",
                    @"tvshowid",
                    @"playcount",
                    @"episode",
                    @"art",
                ],
            },
            @"label": LOCALIZED_STR(@"Episodes"),
            @"defaultThumb": @"nocover_tvshows_episode",
            @"disableFilterParameter": @YES,
            @"FrodoExtraArt": @YES,
        },
        
        @{},
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": filemodeVideoType,
                @"file_properties": @[
                    @"thumbnail",
                    @"art",
                    @"playcount",
                ],
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
                @"file_properties": @[
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Video Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
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
                    @"resume",
                ],
                @"media": @"video",
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @PORTRAIT_ROW_HEIGHT,
            @"thumbWidth": @DEFAULT_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"FrodoExtraArt": @YES,
            @"itemSizes": [self itemSizes_Movie],
        },
    ] mutableCopy];
    
    menu_TVShows.subItem.mainFields = @[
        @{
            @"itemid": @"episodes",
            @"row1": @"title",
            @"row2": @"showtitle",
            @"row3": @"firstaired",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"episodeid",
            @"row7": @"playcount",
            @"row8": @"episodeid",
            @"playlistid": @PLAYERID_VIDEO,
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
            @"itemid_extra_section": @"seasons",
        },
        
        @{},
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"filetype",
            @"row3": @"filetype",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"file",
            @"row7": @"playcount",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
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
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"genre",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @PLAYERID_VIDEO,
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
            @"row19": @"dateadded",
        },
    ];
    
    menu_TVShows.subItem.enableSection = YES;
    menu_TVShows.subItem.rowHeight = DEFAULT_ROW_HEIGHT;
    menu_TVShows.subItem.thumbWidth = EPISODE_THUMB_WIDTH;
    menu_TVShows.subItem.sheetActions = @[
        [self action_episode],
        @[],
        [self action_queue_to_play],
        [self action_queue_to_play],
        [self action_queue_to_play],
    ];
    
    menu_TVShows.subItem.showRuntime = @[
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
    ];
    
    menu_TVShows.subItem.noConvertTime = YES;
    menu_TVShows.subItem.showInfo = @[
        @YES,
        @NO,
        @NO,
        @NO,
        @NO,
    ];
    
    menu_TVShows.subItem.subItem = [mainMenu new];
    menu_TVShows.subItem.subItem.mainMethod = [@[
        @{},
        @{},
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{},
    ] mutableCopy];
    
    menu_TVShows.subItem.subItem.mainParameters = [@[
        @{},
        @{},
        @{},
        @{
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        @{},
    ] mutableCopy];
    
    menu_TVShows.subItem.subItem.mainFields = @[
        @{},
        @{},
        @{},
        @{},
        @{},
    ];
    
    menu_TVShows.subItem.subItem.enableSection = NO;
    menu_TVShows.subItem.subItem.rowHeight = DEFAULT_ROW_HEIGHT;
    menu_TVShows.subItem.subItem.thumbWidth = EPISODE_THUMB_WIDTH;
    menu_TVShows.subItem.subItem.sheetActions = @[
        @[],
        @[],
        @[],
        @[],
        @[],
    ];
    
    menu_TVShows.subItem.subItem.showRuntime = @[
        @NO,
        @NO,
        @NO,
        @NO,
        @NO,
    ];
    
    menu_TVShows.subItem.subItem.noConvertTime = YES;
    
#pragma mark - Live TV
    __auto_type menu_LiveTV = [mainMenu new];
    menu_LiveTV.mainLabel = LOCALIZED_STR(@"Live TV");
    menu_LiveTV.icon = @"icon_menu_livetv";
    menu_LiveTV.type = TypeLiveTv;
    menu_LiveTV.family = FamilyDetailView;
    menu_LiveTV.enableSection = YES;
    menu_LiveTV.noConvertTime = YES;
    menu_LiveTV.mainButtons = @[
        @"st_channels",
        @"st_livetv",
        @"st_recordings",
        @"st_timers",
        @"st_timerrules",
    ];
    
    menu_LiveTV.mainMethod = [@[
        @{
            @"method": @"PVR.GetChannels",
            @"channelListView": @YES,
        },
        @{
            @"method": @"PVR.GetChannelGroups",
        },
        @{
            @"method": @"PVR.GetRecordings",
            @"extra_info_method": @"PVR.GetRecordingDetails",
        },
        @{
            @"method": @"PVR.GetTimers",
        },
        @{
            @"method": @"PVR.GetTimers",
        },
    ] mutableCopy];
    
    menu_LiveTV.mainParameters = [@[
        @{
            @"parameters": @{
                @"channelgroupid": @"alltv",
                @"properties": @[
                    @"thumbnail",
                    @"channelnumber",
                    @"channel",
                ],
            },
            @"kodiExtrasPropertiesMinimumVersion": @{
                @"17": @[
                    @"isrecording",
                ],
            },
            @"label": LOCALIZED_STR(@"All channels"),
            @"defaultThumb": @"nocover_channels",
            @"disableFilterParameter": @YES,
            @"rowHeight": @LIVETV_ROW_HEIGHT,
            @"thumbWidth": @LIVETV_THUMB_WIDTH_SMALL,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
            @"forcePlayback": @YES,
        },
        
        @{
            @"parameters": @{
                @"channeltype": @"tv",
            },
            @"label": LOCALIZED_STR(@"Channel Groups"),
            @"morelabel": LOCALIZED_STR(@"Channel Groups"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
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
                    @"radio",
                    @"directory",
                ],
            },
            @"extra_info_parameters": @{
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
                    @"directory",
                ],
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Title"),
                    LOCALIZED_STR(@"Channel"),
                    LOCALIZED_STR(@"Date"),
                    LOCALIZED_STR(@"Play count"),
                    LOCALIZED_STR(@"Runtime"),
                    LOCALIZED_STR(@"Random"),
                ],
                @"method": @[
                    @"label",
                    @"channel",
                    @"starttime",
                    @"playcount",
                    @"runtime",
                    @"random",
                ],
            },
            @"label": LOCALIZED_STR(@"Recordings"),
            @"morelabel": LOCALIZED_STR(@"Recordings"),
            @"defaultThumb": @"nocover_recording",
            @"rowHeight": @CHANNEL_EPG_ROW_HEIGHT,
            @"thumbWidth": @LIVETV_THUMB_WIDTH_SMALL,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"title",
                    @"summary",
                    @"channelid",
                    @"isradio",
                    @"istimerrule",
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
                    @"isreminder",
                    @"directory",
                ],
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Title"),
                    LOCALIZED_STR(@"Date"),
                    LOCALIZED_STR(@"Runtime"),
                ],
                @"method": @[
                    @"label",
                    @"starttime",
                    @"runtime",
                ],
            },
            @"label": LOCALIZED_STR(@"Timers"),
            @"morelabel": LOCALIZED_STR(@"Timers"),
            @"defaultThumb": @"nocover_timers",
            @"rowHeight": @DEFAULT_ROW_HEIGHT,
            @"thumbWidth": @DEFAULT_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"title",
                    @"summary",
                    @"channelid",
                    @"isradio",
                    @"istimerrule",
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
                    @"isreminder",
                    @"directory",
                ],
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Title"),
                    LOCALIZED_STR(@"Date"),
                    LOCALIZED_STR(@"Runtime"),
                ],
                @"method": @[
                    @"label",
                    @"starttime",
                    @"runtime",
                ],
            },
            @"label": LOCALIZED_STR(@"Timer rules"),
            @"morelabel": LOCALIZED_STR(@"Timer rules"),
            @"defaultThumb": @"nocover_timerrules",
            @"rowHeight": @DEFAULT_ROW_HEIGHT,
            @"thumbWidth": @DEFAULT_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
    ] mutableCopy];
    
    menu_LiveTV.mainFields = @[
        @{
            @"itemid": @"channels",
            @"row1": @"channel",
            @"row2": @"starttime",
            @"row3": @"endtime",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"channelid",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"channelid",
            @"row9": @"channelid",
            @"row10": @"isrecording",
            @"row11": @"channelnumber",
            @"row12": @"type",
        },
        
        @{
            @"itemid": @"channelgroups",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"channelgroupid",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"channelgroupid",
            @"row9": @"channelgroupid",
        },
        
        @{
            @"itemid": @"recordings",
            @"row1": @"label",
            @"row2": @"plotoutline",
            @"row3": @"plot",
            @"row4": @"runtime",
            @"row5": @"starttime",
            @"row6": @"recordingid",
            @"row7": @"radio",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"recordingid",
            @"row9": @"recordingid",
            @"row10": @"file",
            @"row11": @"channel",
            @"row12": @"starttime",
            @"row13": @"endtime",
            @"row14": @"playcount",
            @"row15": @"plot",
            @"row16": @"resume",
            @"itemid_extra_info": @"recordingdetails",
        },
        
        @{
            @"itemid": @"timers",
            @"row1": @"label",
            @"row2": @"summary",
            @"row3": @"plot",
            @"row4": @"runtime",
            @"row5": @"starttime",
            @"row6": @"timerid",
            @"row7": @"isreminder",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"timerid",
            @"row9": @"istimerrule",
            @"row10": @"starttime",
            @"row11": @"endtime",
            @"row15": @"isradio",
        },
        
        @{
            @"itemid": @"timers",
            @"row1": @"label",
            @"row2": @"summary",
            @"row3": @"plot",
            @"row4": @"runtime",
            @"row5": @"starttime",
            @"row6": @"timerid",
            @"row7": @"isreminder",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"timerid",
            @"row9": @"istimerrule",
            @"row10": @"starttime",
            @"row11": @"endtime",
            @"row15": @"isradio",
        },
    ];
    
    menu_LiveTV.rowHeight = PORTRAIT_ROW_HEIGHT;
    menu_LiveTV.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_LiveTV.sheetActions = @[
        [self action_channel],
        @[],
        [self action_queue_to_play],
        @[LOCALIZED_STR(@"Delete timer")],
        @[LOCALIZED_STR(@"Delete timer")],
    ];
    
    menu_LiveTV.showInfo = @[
        @NO,
        @NO,
        @YES,
        @NO,
        @NO,
    ];
    
    menu_LiveTV.filterModes = @[
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_watched],
        [self modes_icons_empty],
        [self modes_icons_empty],
    ];
    
    menu_LiveTV.subItem = [mainMenu new];
    menu_LiveTV.subItem.mainMethod = [@[
        @{
            @"method": @"PVR.GetBroadcasts",
            @"channelGuideView": @YES,
        },
        @{
            @"method": @"PVR.GetChannels",
            @"channelListView": @YES,
        },
        @{},
        @{},
        @{},
    ] mutableCopy];
    
    menu_LiveTV.subItem.noConvertTime = YES;
    
    menu_LiveTV.subItem.mainParameters = [@[
        @{
            @"parameters": @{
                @"properties": @[
                    @"title",
                    @"starttime",
                    @"endtime",
                    @"plot",
                    @"plotoutline",
                    @"progresspercentage",
                    @"isactive",
                    @"hastimer",
                ],
            },
            @"label": LOCALIZED_STR(@"Live TV"),
            @"defaultThumb": @"nocover_channels",
            @"disableFilterParameter": @YES,
            @"rowHeight": @CHANNEL_EPG_ROW_HEIGHT,
            @"thumbWidth": @LIVETV_THUMB_WIDTH,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
                @"properties": @[
                    @"thumbnail",
                    @"channelnumber",
                    @"channel",
                ],
            },
            @"kodiExtrasPropertiesMinimumVersion": @{
                @"17": @[
                    @"isrecording",
                ],
            },
            @"label": LOCALIZED_STR(@"Live TV"),
            @"defaultThumb": @"nocover_channels",
            @"disableFilterParameter": @YES,
            @"rowHeight": @LIVETV_ROW_HEIGHT,
            @"thumbWidth": @LIVETV_THUMB_WIDTH_SMALL,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
            @"forcePlayback": @YES,
        },
        
        @{},
        @{},
        @{},
    ] mutableCopy];
    
    menu_LiveTV.subItem.mainFields = @[
        @{
            @"itemid": @"broadcasts",
            @"row1": @"title",
            @"row2": @"plot",
            @"row3": @"broadcastid",
            @"row4": @"broadcastid",
            @"row5": @"starttime",
            @"row6": @"broadcastid",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"broadcastid",
            @"row9": @"broadcastid",
            @"row10": @"starttime",
            @"row11": @"endtime",
            @"row12": @"progresspercentage",
            @"row13": @"isactive",
            @"row14": @"title",
            @"row15": @"hastimer",
            @"row16": @"plotoutline",
        },
        
        @{
            @"itemid": @"channels",
            @"row1": @"channel",
            @"row2": @"starttime",
            @"row3": @"endtime",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"channelid",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"channelid",
            @"row9": @"channelid",
            @"row10": @"channelnumber",
            @"row11": @"type",
        },
        
        @{},
        @{},
        @{},
    ];
    
    menu_LiveTV.subItem.enableSection = NO;
    menu_LiveTV.subItem.rowHeight = PORTRAIT_ROW_HEIGHT;
    menu_LiveTV.subItem.thumbWidth = LIVETV_THUMB_WIDTH;
    menu_LiveTV.subItem.sheetActions = @[
        [self action_broadcast],
        [self action_channel],
        @[],
        @[],
        @[],
    ];
    
    menu_LiveTV.subItem.filterModes = @[
        [self modes_icons_empty],
        [self modes_icons_empty],
        @{},
        @{},
        @{},
    ];
    
    menu_LiveTV.subItem.subItem = [mainMenu new];
    menu_LiveTV.subItem.subItem.noConvertTime = YES;
    menu_LiveTV.subItem.subItem.mainMethod = [@[
        @{},
        @{
            @"method": @"PVR.GetBroadcasts",
            @"channelGuideView": @YES,
        },
        @{},
        @{},
        @{},
    ] mutableCopy];
    
    menu_LiveTV.subItem.subItem.mainParameters = [@[
        @{},
        
        @{
            @"parameters": @{
                @"properties": @[
                    @"title",
                    @"starttime",
                    @"endtime",
                    @"plot",
                    @"plotoutline",
                    @"progresspercentage",
                    @"isactive",
                    @"hastimer",
                ],
            },
            @"label": LOCALIZED_STR(@"Live TV"),
            @"defaultThumb": @"nocover_channels",
            @"disableFilterParameter": @YES,
            @"rowHeight": @CHANNEL_EPG_ROW_HEIGHT,
            @"thumbWidth": @LIVETV_THUMB_WIDTH,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{},
        @{},
        @{},
    ] mutableCopy];
    
    menu_LiveTV.subItem.subItem.mainFields = @[
        @{},
        
        @{
            @"itemid": @"broadcasts",
            @"row1": @"title",
            @"row2": @"plot",
            @"row3": @"broadcastid",
            @"row4": @"broadcastid",
            @"row5": @"starttime",
            @"row6": @"broadcastid",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"broadcastid",
            @"row9": @"broadcastid",
            @"row10": @"starttime",
            @"row11": @"endtime",
            @"row12": @"progresspercentage",
            @"row13": @"isactive",
            @"row14": @"title",
            @"row15": @"hastimer",
            @"row16": @"plotoutline",
        },
        
        @{},
        @{},
        @{},
    ];
    
    menu_LiveTV.subItem.subItem.enableSection = NO;
    menu_LiveTV.subItem.subItem.rowHeight = PORTRAIT_ROW_HEIGHT;
    menu_LiveTV.subItem.subItem.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_LiveTV.subItem.subItem.sheetActions = @[
        @[],
        [self action_broadcast],
        @[],
        @[],
        @[],
    ];
    
#pragma mark - Radio
    __auto_type menu_Radio = [mainMenu new];
    menu_Radio.mainLabel = LOCALIZED_STR(@"Radio");
    menu_Radio.icon = @"icon_menu_radio";
    menu_Radio.type = TypeRadio;
    menu_Radio.family = FamilyDetailView;
    menu_Radio.enableSection = YES;
    menu_Radio.noConvertTime = YES;
    menu_Radio.mainButtons = @[
        @"st_channels",
        @"st_radio",
        @"st_recordings",
        @"st_timers",
        @"st_timerrules",
    ];
    
    menu_Radio.mainMethod = [@[
        @{
            @"method": @"PVR.GetChannels",
            @"channelListView": @YES,
        },
        @{
            @"method": @"PVR.GetChannelGroups",
        },
        @{
            @"method": @"PVR.GetRecordings",
            @"extra_info_method": @"PVR.GetRecordingDetails",
        },
        @{
            @"method": @"PVR.GetTimers",
        },
        @{
            @"method": @"PVR.GetTimers",
        },
    ] mutableCopy];
    
    menu_Radio.mainParameters = [@[
        @{
            @"parameters": @{
                @"channelgroupid": @"allradio",
                @"properties": @[
                    @"thumbnail",
                    @"channelnumber",
                    @"channel",
                ],
            },
            @"kodiExtrasPropertiesMinimumVersion": @{
                @"17": @[
                    @"isrecording",
                ],
            },
            @"label": LOCALIZED_STR(@"All channels"),
            @"defaultThumb": @"nocover_channels",
            @"disableFilterParameter": @YES,
            @"rowHeight": @LIVETV_ROW_HEIGHT,
            @"thumbWidth": @LIVETV_THUMB_WIDTH_SMALL,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
            @"forcePlayback": @YES,
        },
        
        @{
            @"parameters": @{
                @"channeltype": @"radio",
            },
            @"label": LOCALIZED_STR(@"Channel Groups"),
            @"morelabel": LOCALIZED_STR(@"Channel Groups"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
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
                    //@"lifetime", // Unused. Commented for Radio to support different persistence for TV/Radio.
                    @"icon",
                    @"art",
                    @"streamurl",
                    @"file",
                    @"radio",
                    @"directory",
                ],
            },
            @"extra_info_parameters": @{
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
                    //@"lifetime", // Unused. Commented for Radio to support different persistence for TV/Radio.
                    @"icon",
                    @"art",
                    @"streamurl",
                    @"file",
                    @"directory",
                ],
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Title"),
                    LOCALIZED_STR(@"Channel"),
                    LOCALIZED_STR(@"Date"),
                    LOCALIZED_STR(@"Runtime"),
                    LOCALIZED_STR(@"Random"),
                ],
                @"method": @[
                    @"label",
                    @"channel",
                    @"starttime",
                    @"runtime",
                    @"random",
                ],
            },
            @"label": LOCALIZED_STR(@"Recordings"),
            @"morelabel": LOCALIZED_STR(@"Recordings"),
            @"defaultThumb": @"nocover_recording",
            @"rowHeight": @CHANNEL_EPG_ROW_HEIGHT,
            @"thumbWidth": @LIVETV_THUMB_WIDTH_SMALL,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"title",
                    @"summary",
                    @"channelid",
                    @"isradio",
                    @"istimerrule",
                    @"starttime",
                    @"endtime",
                    @"runtime",
                    //@"lifetime", // Unused. Commented for Radio to support different persistence for TV/Radio.
                    @"firstday",
                    @"weekdays",
                    @"priority",
                    @"startmargin",
                    @"endmargin",
                    @"state",
                    @"file",
                    @"isreminder",
                    @"directory",
                ],
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Title"),
                    LOCALIZED_STR(@"Date"),
                    LOCALIZED_STR(@"Runtime"),
                ],
                @"method": @[
                    @"label",
                    @"starttime",
                    @"runtime",
                ],
            },
            @"label": LOCALIZED_STR(@"Timers"),
            @"morelabel": LOCALIZED_STR(@"Timers"),
            @"defaultThumb": @"nocover_timers",
            @"rowHeight": @DEFAULT_ROW_HEIGHT,
            @"thumbWidth": @DEFAULT_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"properties": @[
                    @"title",
                    @"summary",
                    @"channelid",
                    @"isradio",
                    @"istimerrule",
                    @"starttime",
                    @"endtime",
                    @"runtime",
                    //@"lifetime", // Unused. Commented for Radio to support different persistence for TV/Radio.
                    @"firstday",
                    @"weekdays",
                    @"priority",
                    @"startmargin",
                    @"endmargin",
                    @"state",
                    @"file",
                    @"isreminder",
                    @"directory",
                ],
            },
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Title"),
                    LOCALIZED_STR(@"Date"),
                    LOCALIZED_STR(@"Runtime"),
                ],
                @"method": @[
                    @"label",
                    @"starttime",
                    @"runtime",
                ],
            },
            @"label": LOCALIZED_STR(@"Timer rules"),
            @"morelabel": LOCALIZED_STR(@"Timer rules"),
            @"defaultThumb": @"nocover_timerrules",
            @"rowHeight": @DEFAULT_ROW_HEIGHT,
            @"thumbWidth": @DEFAULT_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
    ] mutableCopy];
    
    menu_Radio.mainFields = @[
        @{
            @"itemid": @"channels",
            @"row1": @"channel",
            @"row2": @"starttime",
            @"row3": @"endtime",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"channelid",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"channelid",
            @"row9": @"channelid",
            @"row10": @"isrecording",
            @"row11": @"channelnumber",
            @"row12": @"type",
        },
        
        @{
            @"itemid": @"channelgroups",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"channelgroupid",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"channelgroupid",
            @"row9": @"channelgroupid",
        },
        
        @{
            @"itemid": @"recordings",
            @"row1": @"label",
            @"row2": @"plotoutline",
            @"row3": @"plot",
            @"row4": @"runtime",
            @"row5": @"starttime",
            @"row6": @"recordingid",
            @"row7": @"radio",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"recordingid",
            @"row9": @"recordingid",
            @"row10": @"file",
            @"row11": @"channel",
            @"row12": @"starttime",
            @"row13": @"endtime",
            @"row14": @"playcount",
            @"row15": @"plot",
            @"row16": @"resume",
            @"itemid_extra_info": @"recordingdetails",
        },
        
        @{
            @"itemid": @"timers",
            @"row1": @"label",
            @"row2": @"summary",
            @"row3": @"plot",
            @"row4": @"runtime",
            @"row5": @"starttime",
            @"row6": @"timerid",
            @"row7": @"isreminder",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"timerid",
            @"row9": @"istimerrule",
            @"row10": @"starttime",
            @"row11": @"endtime",
            @"row15": @"isradio",
        },
        
        @{
            @"itemid": @"timers",
            @"row1": @"label",
            @"row2": @"summary",
            @"row3": @"plot",
            @"row4": @"runtime",
            @"row5": @"starttime",
            @"row6": @"timerid",
            @"row7": @"isreminder",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"timerid",
            @"row9": @"istimerrule",
            @"row10": @"starttime",
            @"row11": @"endtime",
            @"row15": @"isradio",
        },
    ];
    
    menu_Radio.rowHeight = PORTRAIT_ROW_HEIGHT;
    menu_Radio.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_Radio.sheetActions = @[
        [self action_channel],
        @[],
        [self action_queue_to_play],
        @[LOCALIZED_STR(@"Delete timer")],
        @[LOCALIZED_STR(@"Delete timer")],
    ];
    
    menu_Radio.showInfo = @[
        @NO,
        @NO,
        @YES,
        @NO,
        @NO,
    ];
    
    menu_Radio.filterModes = @[
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_watched],
        [self modes_icons_empty],
        [self modes_icons_empty],
    ];
    
    menu_Radio.subItem = [mainMenu new];
    menu_Radio.subItem.mainMethod = [@[
        @{
            @"method": @"PVR.GetBroadcasts",
            @"channelGuideView": @YES,
        },
        @{
            @"method": @"PVR.GetChannels",
            @"channelListView": @YES,
        },
        @{},
        @{},
        @{},
    ] mutableCopy];
    
    menu_Radio.subItem.noConvertTime = YES;
    
    menu_Radio.subItem.mainParameters = [@[
        @{
            @"parameters": @{
                @"properties": @[
                    @"title",
                    @"starttime",
                    @"endtime",
                    @"plot",
                    @"plotoutline",
                    @"progresspercentage",
                    @"isactive",
                    @"hastimer",
                ],
            },
            @"label": LOCALIZED_STR(@"Radio"),
            @"defaultThumb": @"icon_video",
            @"disableFilterParameter": @YES,
            @"rowHeight": @CHANNEL_EPG_ROW_HEIGHT,
            @"thumbWidth": @LIVETV_THUMB_WIDTH,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
                @"properties": @[
                    @"thumbnail",
                    @"channelnumber",
                    @"channel",
                ],
            },
            @"kodiExtrasPropertiesMinimumVersion": @{
                @"17": @[
                    @"isrecording",
                ],
            },
            @"label": LOCALIZED_STR(@"Radio"),
            @"defaultThumb": @"nocover_channels",
            @"disableFilterParameter": @YES,
            @"rowHeight": @LIVETV_ROW_HEIGHT,
            @"thumbWidth": @LIVETV_THUMB_WIDTH_SMALL,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
            @"forcePlayback": @YES,
        },
        
        @{},
        @{},
        @{},
    ] mutableCopy];
    
    menu_Radio.subItem.mainFields = @[
        @{
            @"itemid": @"broadcasts",
            @"row1": @"title",
            @"row2": @"plot",
            @"row3": @"broadcastid",
            @"row4": @"broadcastid",
            @"row5": @"starttime",
            @"row6": @"broadcastid",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"broadcastid",
            @"row9": @"broadcastid",
            @"row10": @"starttime",
            @"row11": @"endtime",
            @"row12": @"progresspercentage",
            @"row13": @"isactive",
            @"row14": @"title",
            @"row15": @"hastimer",
            @"row16": @"plotoutline",
        },
        
        @{
            @"itemid": @"channels",
            @"row1": @"channel",
            @"row2": @"starttime",
            @"row3": @"endtime",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"channelid",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"channelid",
            @"row9": @"channelid",
            @"row10": @"channelnumber",
            @"row11": @"type",
        },
        
        @{},
        @{},
        @{},
    ];
    
    menu_Radio.subItem.enableSection = NO;
    menu_Radio.subItem.rowHeight = PORTRAIT_ROW_HEIGHT;
    menu_Radio.subItem.thumbWidth = LIVETV_THUMB_WIDTH;
    menu_Radio.subItem.sheetActions = @[
        [self action_broadcast],
        [self action_channel],
        @[],
        @[],
        @[],
    ];
    
    menu_Radio.subItem.filterModes = @[
        [self modes_icons_empty],
        [self modes_icons_empty],
        @{},
        @{},
        @{},
    ];
    
    menu_Radio.subItem.subItem = [mainMenu new];
    menu_Radio.subItem.subItem.noConvertTime = YES;
    menu_Radio.subItem.subItem.mainMethod = [@[
        @{},
        @{
            @"method": @"PVR.GetBroadcasts",
            @"channelGuideView": @YES,
        },
        @{},
        @{},
        @{},
    ] mutableCopy];
    
    menu_Radio.subItem.subItem.mainParameters = [@[
        @{},
        
        @{
            @"parameters": @{
                @"properties": @[
                    @"title",
                    @"starttime",
                    @"endtime",
                    @"plot",
                    @"plotoutline",
                    @"progresspercentage",
                    @"isactive",
                    @"hastimer",
                ],
            },
            @"label": LOCALIZED_STR(@"Radio"),
            @"defaultThumb": @"nocover_channels",
            @"disableFilterParameter": @YES,
            @"rowHeight": @CHANNEL_EPG_ROW_HEIGHT,
            @"thumbWidth": @LIVETV_THUMB_WIDTH,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{},
        @{},
        @{},
    ] mutableCopy];
    
    menu_Radio.subItem.subItem.mainFields = @[
        @{},
        
        @{
            @"itemid": @"broadcasts",
            @"row1": @"title",
            @"row2": @"plot",
            @"row3": @"broadcastid",
            @"row4": @"broadcastid",
            @"row5": @"starttime",
            @"row6": @"broadcastid",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"broadcastid",
            @"row9": @"broadcastid",
            @"row10": @"starttime",
            @"row11": @"endtime",
            @"row12": @"progresspercentage",
            @"row13": @"isactive",
            @"row14": @"title",
            @"row15": @"hastimer",
            @"row16": @"plotoutline",
        },
        
        @{},
        @{},
        @{},
    ];
    
    menu_Radio.subItem.subItem.enableSection = NO;
    menu_Radio.subItem.subItem.rowHeight = PORTRAIT_ROW_HEIGHT;
    menu_Radio.subItem.subItem.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_Radio.subItem.subItem.sheetActions = @[
        @[],
        [self action_broadcast],
        @[],
        @[],
        @[],
    ];
    
#pragma mark - Pictures
    __auto_type menu_Pictures = [mainMenu new];
    menu_Pictures.mainLabel = LOCALIZED_STR(@"Pictures");
    menu_Pictures.icon = @"icon_menu_pictures";
    menu_Pictures.type = TypePictures;
    menu_Pictures.family = FamilyDetailView;
    menu_Pictures.enableSection = YES;
    menu_Pictures.mainButtons = @[
        @"st_filemode",
        @"st_addons",
    ];
    
    menu_Pictures.mainMethod = [@[
        @{
            @"method": @"Files.GetSources",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
    ] mutableCopy];
    
    menu_Pictures.mainParameters = [@[
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"pictures",
            },
            @"label": LOCALIZED_STR(@"Pictures"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"pictures",
                @"directory": @"addons://sources/image",
                @"properties": @[
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Pictures Add-ons"),
            @"morelabel": LOCALIZED_STR(@"Pictures Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
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
            @"playlistid": @PLAYERID_PICTURES,
            @"row8": @"file",
            @"row9": @"file",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @PLAYERID_PICTURES,
            @"row8": @"file",
            @"row9": @"file",
        },
    ];
    
    menu_Pictures.thumbWidth = DEFAULT_THUMB_WIDTH;
    
    menu_Pictures.subItem = [mainMenu new];
    menu_Pictures.subItem.mainMethod = [@[
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
    ] mutableCopy];
    
    menu_Pictures.sheetActions = @[
        [self action_pictures],
        @[],
    ];
    
    menu_Pictures.subItem.mainParameters = [@[
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"pictures",
                @"file_properties": @[
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"media": @"pictures",
                @"file_properties": @[
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Pictures Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
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
            @"playlistid": @PLAYERID_PICTURES,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"filetype",
            @"row3": @"filetype",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"file",
            @"playlistid": @PLAYERID_PICTURES,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
        },
    ];
    
    menu_Pictures.subItem.enableSection = NO;
    menu_Pictures.subItem.rowHeight = PORTRAIT_ROW_HEIGHT;
    menu_Pictures.subItem.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_Pictures.subItem.sheetActions = @[
        [self action_pictures],
        @[],
    ];
    
    menu_Pictures.subItem.subItem = [mainMenu new];
    menu_Pictures.subItem.subItem.mainMethod = [@[
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
    ] mutableCopy];
    
    menu_Pictures.subItem.subItem.mainParameters = [@[
        @{},
        @{},
    ] mutableCopy];
    
    menu_Pictures.subItem.subItem.mainFields = @[
        @{},
        @{},
    ];
    
#pragma mark - Favourites
    __auto_type menu_Favourites = [mainMenu new];
    menu_Favourites.mainLabel = LOCALIZED_STR(@"Favourites");
    menu_Favourites.icon = @"icon_menu_favourites";
    menu_Favourites.type = TypeFavourites;
    menu_Favourites.family = FamilyDetailView;
    menu_Favourites.enableSection = YES;
    menu_Favourites.mainButtons = @[
        @"st_filemode",
    ];
    
    menu_Favourites.mainMethod = [@[
        @{
            @"method": @"Favourites.GetFavourites",
        },
    ] mutableCopy];
    
    menu_Favourites.mainParameters = [@[
        @{
            @"parameters": @{
                @"properties": @[
                    @"thumbnail",
                    @"path",
                    @"window",
                    @"windowparameter",
                ],
            },
            @"label": LOCALIZED_STR(@"Favourites"),
            @"defaultThumb": @"nocover_favourites",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
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
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"type",
            @"row9": @"window",
            @"row10": @"windowparameter",
        },
    ];
    
    menu_Favourites.rowHeight = DEFAULT_ROW_HEIGHT;
    menu_Favourites.thumbWidth = DEFAULT_THUMB_WIDTH;
    
#pragma mark - Now Playing
    __auto_type menu_NowPlaying = [mainMenu new];
    menu_NowPlaying.mainLabel = LOCALIZED_STR(@"Now Playing");
    menu_NowPlaying.icon = @"icon_menu_playing";
    menu_NowPlaying.type = TypeNowPlaying;
    menu_NowPlaying.family = FamilyNowPlaying;
    
#pragma mark - Remote Control
    __auto_type menu_Remote = [mainMenu new];
    menu_Remote.mainLabel = LOCALIZED_STR(@"Remote Control");
    menu_Remote.icon = @"icon_menu_remote";
    menu_Remote.type = TypeRemote;
    menu_Remote.family = FamilyRemote;
    
#pragma mark - Global Search
    __auto_type menu_Search = [mainMenu new];
    menu_Search.mainLabel = LOCALIZED_STR(@"Global Search");
    menu_Search.icon = @"icon_menu_search";
    menu_Search.type = TypeGlobalSearch;
    menu_Search.family = FamilyDetailView;
    menu_Search.enableSection = YES;
    menu_Search.rowHeight = DEFAULT_ROW_HEIGHT;
    menu_Search.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_Search.mainParameters = [@[
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"itemgroup" order:@"ascending" ignorearticle:NO],
            },
            @"label": LOCALIZED_STR(@"Global Search"),
            @"defaultThumb": @"nocover_filemode",
            @"available_sort_methods": @{
                @"label": @[
                    LOCALIZED_STR(@"Type"),
                    LOCALIZED_STR(@"Name"),
                ],
                @"method": @[
                    @"itemgroup",
                    @"label",
                ],
            },
            @"enableLibraryCache": @YES,
        },
    ] mutableCopy];
    
#pragma mark - Files
    __auto_type menu_Files = [mainMenu new];
    menu_Files.mainLabel = LOCALIZED_STR(@"Files");
    menu_Files.icon = @"st_filemode";
    menu_Files.type = TypeFiles;
    menu_Files.family = FamilyDetailView;
    menu_Files.enableSection = YES;
    menu_Files.noConvertTime = YES;
    menu_Files.mainButtons = @[
        @"st_songs",
        @"st_videos",
        @"st_pictures",
    ];
    
    menu_Files.mainMethod = @[
        @{
            @"method": @"Files.GetSources",
        },
        @{
            @"method": @"Files.GetSources",
        },
        @{
            @"method": @"Files.GetSources",
        },
    ];
    
    menu_Files.mainParameters = [@[
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"music",
            },
            @"label": LOCALIZED_STR(@"Music"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
            },
            @"label": LOCALIZED_STR(@"Videos"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"pictures",
            },
            @"label": LOCALIZED_STR(@"Pictures"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
    ] mutableCopy];
    
    menu_Files.mainFields = @[
        @{
            @"itemid": @"sources",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"file",
            @"row9": @"file",
        },
        
        @{
            @"itemid": @"sources",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
        },
        
        @{
            @"itemid": @"sources",
            @"row1": @"label",
            @"row2": @"year",
            @"row3": @"year",
            @"row4": @"runtime",
            @"row5": @"rating",
            @"row6": @"file",
            @"playlistid": @PLAYERID_PICTURES,
            @"row8": @"file",
            @"row9": @"file",
        },
    ];
    
    menu_Files.rowHeight = PORTRAIT_ROW_HEIGHT;
    menu_Files.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_Files.sheetActions = @[
        [self action_filemode_music],
        [self action_queue_to_play],
        [self action_pictures],
    ];
    
    menu_Files.showInfo = @[
        @NO,
        @NO,
        @NO,
    ];
    
    menu_Files.filterModes = @[
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
    ];
    
    menu_Files.subItem = [mainMenu new];
    menu_Files.subItem.mainMethod = [@[
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
    ] mutableCopy];
    
    menu_Files.subItem.noConvertTime = YES;
    
    menu_Files.subItem.mainParameters = [@[
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": filemodeMusicType,
                @"file_properties": @[
                    @"thumbnail",
                    @"art",
                    @"playcount",
                ],
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": filemodeVideoType,
                @"file_properties": @[
                    @"thumbnail",
                    @"art",
                    @"playcount",
                ],
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"label" order:@"ascending" ignorearticle:NO],
                @"media": @"pictures",
                @"file_properties": @[
                    @"thumbnail",
                    @"art",
                ],
            },
            @"label": LOCALIZED_STR(@"Files"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
    ] mutableCopy];
    
    menu_Files.subItem.mainFields = @[
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"filetype",
            @"row3": @"filetype",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"file",
            @"row7": @"playcount",
            @"playlistid": @PLAYERID_MUSIC,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"filetype",
            @"row3": @"filetype",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"file",
            @"row7": @"playcount",
            @"playlistid": @PLAYERID_VIDEO,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
        },
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"filetype",
            @"row3": @"filetype",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"file",
            @"playlistid": @PLAYERID_PICTURES,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
        },
    ];
    
    menu_Files.subItem.enableSection = YES;
    menu_Files.subItem.rowHeight = PORTRAIT_ROW_HEIGHT;
    menu_Files.subItem.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_Files.subItem.sheetActions = @[
        [self action_filemode_music],
        [self action_queue_to_play],
        [self action_pictures],
    ];
    
    menu_Files.subItem.showInfo = @[
        @NO,
        @NO,
        @NO,
    ];
    
    menu_Files.subItem.filterModes = @[
        [self modes_icons_empty],
        [self modes_icons_empty],
        [self modes_icons_empty],
    ];
    
    menu_Files.subItem.subItem = [mainMenu new];
    menu_Files.subItem.subItem.noConvertTime = YES;
    menu_Files.subItem.subItem.mainMethod = [@[
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
    ] mutableCopy];
    
    menu_Files.subItem.subItem.mainParameters = [@[
        @{},
        @{},
        @{},
    ] mutableCopy];
    
    menu_Files.subItem.subItem.mainFields = @[
        @{},
        @{},
        @{},
    ];
    
    menu_Files.subItem.subItem.enableSection = NO;
    menu_Files.subItem.subItem.rowHeight = PORTRAIT_ROW_HEIGHT;
    menu_Files.subItem.subItem.thumbWidth = DEFAULT_THUMB_WIDTH;
    menu_Files.subItem.subItem.sheetActions = @[
        @[],
        @[],
        @[],
    ];
    
#pragma mark - Kodi Server Management
    __auto_type menu_Server = [mainMenu new];
    menu_Server.mainLabel = LOCALIZED_STR(@"XBMC Server");
    menu_Server.type = TypeServer;
    menu_Server.icon = @"";
    menu_Server.family = FamilyServer;
    
#pragma mark - Playlist Artist Albums
    AppDelegate.instance.playlistArtistAlbums = [menu_Music copy];
    
#pragma mark - Playlist Movies
    AppDelegate.instance.playlistMovies = [menu_Movies copy];
    
#pragma mark - Playlist Movies
    AppDelegate.instance.playlistMusicVideos = [menu_Videos copy];
    
#pragma mark - Playlist TV Shows
    AppDelegate.instance.playlistTvShows = [menu_TVShows copy];
    
#pragma mark - Playlist PVR
    AppDelegate.instance.playlistPVR = [menu_LiveTV copy];
    
#pragma mark - Addons
    __auto_type menu_Addons = [mainMenu new];
    menu_Addons.mainLabel = LOCALIZED_STR(@"Add-ons");
    menu_Addons.icon = @"st_addons";
    menu_Addons.type = TypeAddons;
    menu_Addons.family = FamilyDetailView;
    menu_Addons.enableSection = YES;
    menu_Addons.rowHeight = SETTINGS_ROW_HEIGHT;
    menu_Addons.thumbWidth = SETTINGS_THUMB_WIDTH;
    menu_Addons.mainButtons = @[
        @"st_addons",
        @"icon_song",
        @"icon_video",
        @"icon_picture",
    ];
    
    menu_Addons.mainMethod = [@[
        @{
            @"method": @"Addons.GetAddons",
        },
        @{
            @"method": @"Addons.GetAddons",
        },
        @{
            @"method": @"Addons.GetAddons",
        },
        @{
            @"method": @"Addons.GetAddons",
        },
    ] mutableCopy];
    
    menu_Addons.mainParameters = [@[
        @{
            @"parameters": @{
                @"type": @"xbmc.addon.executable",
                @"enabled": @YES,
                @"properties": @[
                    @"name",
                    @"version",
                    @"summary",
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Programs"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @SETTINGS_ROW_HEIGHT,
            @"thumbWidth": @SETTINGS_THUMB_WIDTH_BIG,
            @"itemSizes": [self itemSizes_Music],
            @"enableCollectionView": @YES,
        },
        
        @{
            @"parameters": @{
                @"type": @"xbmc.addon.audio",
                @"enabled": @YES,
                @"properties": @[
                    @"name",
                    @"version",
                    @"summary",
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Music Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @SETTINGS_ROW_HEIGHT,
            @"thumbWidth": @SETTINGS_THUMB_WIDTH_BIG,
            @"itemSizes": [self itemSizes_Music],
            @"enableCollectionView": @YES,
        },
        
        @{
            @"parameters": @{
                @"type": @"xbmc.addon.video",
                @"enabled": @YES,
                @"properties": @[
                    @"name",
                    @"version",
                    @"summary",
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Video Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @SETTINGS_ROW_HEIGHT,
            @"thumbWidth": @SETTINGS_THUMB_WIDTH_BIG,
            @"itemSizes": [self itemSizes_Music],
            @"enableCollectionView": @YES,
        },
        
        @{
            @"parameters": @{
                @"type": @"xbmc.addon.image",
                @"enabled": @YES,
                @"properties": @[
                    @"name",
                    @"version",
                    @"summary",
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Pictures Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @SETTINGS_ROW_HEIGHT,
            @"thumbWidth": @SETTINGS_THUMB_WIDTH_BIG,
            @"itemSizes": [self itemSizes_Music],
            @"enableCollectionView": @YES,
        },
    ] mutableCopy];
    
    menu_Addons.mainFields = @[
        @{
            @"itemid": @"addons",
            @"row1": @"name",
            @"row2": @"summary",
            @"row3": @"blank",
            @"row4": @"blank",
            @"row5": @"addonid",
            @"row6": @"addonid",
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"addonid",
            @"row9": @"addonid",
        },
        
        @{
            @"itemid": @"addons",
            @"row1": @"name",
            @"row2": @"summary",
            @"row3": @"blank",
            @"row4": @"blank",
            @"row5": @"addonid",
            @"row6": @"addonid",
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"addonid",
            @"row9": @"addonid",
        },
        
        @{
            @"itemid": @"addons",
            @"row1": @"name",
            @"row2": @"summary",
            @"row3": @"blank",
            @"row4": @"blank",
            @"row5": @"addonid",
            @"row6": @"addonid",
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"addonid",
            @"row9": @"addonid",
        },
        
        @{
            @"itemid": @"addons",
            @"row1": @"name",
            @"row2": @"summary",
            @"row3": @"blank",
            @"row4": @"blank",
            @"row5": @"addonid",
            @"row6": @"addonid",
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"addonid",
            @"row9": @"addonid",
        },
    ];
    
    menu_Addons.sheetActions = @[
        @[
            LOCALIZED_STR(@"Execute program"),
            LOCALIZED_STR(@"Add button"),
        ],
        @[
            LOCALIZED_STR(@"Execute audio add-on"),
            LOCALIZED_STR(@"Add button"),
        ],
        @[
            LOCALIZED_STR(@"Execute video add-on"),
            LOCALIZED_STR(@"Add button"),
        ],
        @[
            LOCALIZED_STR(@"Execute add-on"),
            LOCALIZED_STR(@"Add button"),
        ],
    ];
    
    menu_Addons.subItem = [mainMenu new];
    menu_Addons.subItem.mainMethod = [@[
        @{},
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
    ] mutableCopy];
    
    menu_Addons.subItem.mainParameters = [@[
        @{
            @"forceActionSheet": @YES,
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"media": @"music",
                @"file_properties": @[
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Music Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"media": @"video",
                @"file_properties": @[
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Video Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
        
        @{
            @"parameters": @{
                @"sort": [self sortmethod:@"none" order:@"ascending" ignorearticle:NO],
                @"media": @"pictures",
                @"file_properties": @[
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Pictures Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"enableCollectionView": @YES,
            @"itemSizes": [self itemSizes_Music],
        },
    ] mutableCopy];
    
    menu_Addons.subItem.mainFields = @[
        @{},
        
        @{
            @"itemid": @"files",
            @"row1": @"label",
            @"row2": @"filetype",
            @"row3": @"filetype",
            @"row4": @"filetype",
            @"row5": @"filetype",
            @"row6": @"file",
            @"row7": @"plugin",
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
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
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
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
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"file",
            @"row9": @"file",
            @"row10": @"filetype",
            @"row11": @"type",
        },
    ];
    
    menu_Addons.subItem.rowHeight = SETTINGS_ROW_HEIGHT;
    menu_Addons.subItem.thumbWidth = SETTINGS_THUMB_WIDTH;
    
    menu_Addons.subItem.subItem = [mainMenu new];
    menu_Addons.subItem.subItem.mainMethod = [@[
        @{},
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
        @{
            @"method": @"Files.GetDirectory",
        },
    ] mutableCopy];
    
    menu_Addons.subItem.subItem.mainParameters = [@[
        @{},
        @{
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        @{
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
        @{
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
        },
    ] mutableCopy];
    
    menu_Addons.subItem.subItem.mainFields = @[
        @{},
        @{},
        @{},
        @{},
    ];
    
    menu_Addons.subItem.subItem.enableSection = NO;
    menu_Addons.subItem.subItem.rowHeight = SETTINGS_ROW_HEIGHT;
    menu_Addons.subItem.subItem.thumbWidth = SETTINGS_ROW_HEIGHT;
    menu_Addons.subItem.subItem.sheetActions = @[
        @[],
        @[],
        @[],
        @[],
    ];
    
#pragma mark - App Settings
    __auto_type menu_AppSettings = [mainMenu new];
    menu_AppSettings.mainLabel = LOCALIZED_STR(@"App Settings");
    menu_AppSettings.icon = @"icon_menu_settings";
    menu_AppSettings.type = TypeAppSettings;
    menu_AppSettings.family = FamilyAppSettings;
    
#pragma mark - Kodi Settings
    __auto_type menu_Settings = [mainMenu new];
    menu_Settings.mainLabel = LOCALIZED_STR(@"XBMC Settings");
    menu_Settings.icon = @"icon_menu_kodi";
    menu_Settings.type = TypeKodiSettings;
    menu_Settings.family = FamilyDetailView;
    menu_Settings.enableSection = YES;
    menu_Settings.rowHeight = SETTINGS_ROW_HEIGHT;
    menu_Settings.thumbWidth = SETTINGS_THUMB_WIDTH;
    menu_Settings.mainButtons = @[
        @"st_filemode",
        @"st_kodi_action",
        @"st_kodi_window",
        @"st_profile",
    ];
    
    menu_Settings.mainMethod = [@[
        @{
            @"method": @"Settings.GetSections",
        },
        @{
            @"method": @"JSONRPC.Introspect",
        },
        @{
            @"method": @"JSONRPC.Introspect",
        },
        @{
            @"method": @"Profiles.GetProfiles",
        },
    ] mutableCopy];
    
    menu_Settings.mainParameters = [@[
        @{
            @"parameters": @{
                @"level": @"expert",
            },
            @"label": LOCALIZED_STR(@"XBMC Settings"),
            @"defaultThumb": @"nocover_filemode",
            @"thumbWidth": @0,
        },
        
        @{
            @"parameters": @{
                @"filter": @{
                    @"id": @"Input.ExecuteAction",
                    @"type": @"method",
                },
            },
            @"label": LOCALIZED_STR(@"Kodi actions"),
            @"defaultThumb": @"default-right-action-icon",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @0,
            @"morelabel": LOCALIZED_STR(@"Execute a specific action"),
            @"forceActionSheet": @YES,
        },
        
        @{
            @"parameters": @{
                @"filter": @{
                    @"id": @"GUI.ActivateWindow",
                    @"type": @"method",
                },
            },
            @"label": LOCALIZED_STR(@"Kodi windows"),
            @"defaultThumb": @"default-right-window-icon",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @0,
            @"morelabel": LOCALIZED_STR(@"Activate a specific window"),
            @"forceActionSheet": @YES,
        },
        
        @{
            @"parameters": @{
                @"properties": @[
                    @"lockmode",
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Profiles"),
            @"defaultThumb": @"nocover_profile",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @FILEMODE_THUMB_WIDTH,
            @"morelabel": LOCALIZED_STR(@"Profiles"),
        },
    ] mutableCopy];
    
    menu_Settings.mainFields = @[
        @{
            @"itemid": @"sections",
            @"row1": @"label",
            @"row2": @"help",
            @"row3": @"id",
            @"row4": @"id",
            @"row5": @"id",
            @"row6": @"id",
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"sectionid",
            @"row9": @"id",
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
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"addonid",
            @"row9": @"addonid",
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
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"addonid",
            @"row9": @"addonid",
        },
        
        @{
            @"itemid": @"profiles",
            @"row1": @"label",
            @"row8": @"profile",
        },
    ];
    
    menu_Settings.sheetActions = @[
        @[],
        @[
            LOCALIZED_STR(@"Execute action"),
            LOCALIZED_STR(@"Add action button"),
        ],
        @[
            LOCALIZED_STR(@"Activate window"),
            LOCALIZED_STR(@"Add window activation button"),
        ],
        @[],
    ];
    
    menu_Settings.subItem = [mainMenu new];
    menu_Settings.subItem.mainMethod = [@[
        @{
            @"method": @"Settings.GetCategories",
        },
        @{},
        @{},
        @{},
    ] mutableCopy];
    
    menu_Settings.subItem.mainParameters = [@[
        @{
            @"label": LOCALIZED_STR(@"Settings"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @SETTINGS_ROW_HEIGHT,
            @"thumbWidth": @0,
        },
        @{},
        @{},
        @{},
    ] mutableCopy];
    
    menu_Settings.subItem.mainFields = @[
        @{
            @"itemid": @"categories",
            @"row1": @"label",
            @"row2": @"help",
            @"row3": @"id",
            @"row4": @"id",
            @"row5": @"id",
            @"row6": @"id",
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"categoryid",
            @"row9": @"id",
        },
        @{},
        @{},
        @{},
    ];
    
    menu_Settings.subItem.rowHeight = SETTINGS_ROW_HEIGHT;
    menu_Settings.subItem.thumbWidth = SETTINGS_THUMB_WIDTH;
    
    menu_Settings.subItem.subItem = [mainMenu new];
    menu_Settings.subItem.subItem.mainMethod = [@[
        @{
            @"method": @"Settings.GetSettings",
        },
    ] mutableCopy];
    
    menu_Settings.subItem.subItem.mainParameters = [@[
        @{
            @"label": LOCALIZED_STR(@"Settings"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @SETTINGS_ROW_HEIGHT,
            @"thumbWidth": @0,
        },
    ] mutableCopy];
    
    menu_Settings.subItem.subItem.mainFields = @[
        @{
            @"itemid": @"settings",
            @"row1": @"label",
            @"row2": @"help",
            @"row3": @"id",
            @"row4": @"default",
            @"row5": @"enabled",
            @"row6": @"id",
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row7": @"delimiter",
            @"row8": @"id",
            @"row9": @"type",
            @"row10": @"parent",
            @"row11": @"control",
            @"row12": @"value",
            @"row13": @"options",
            @"row14": @"allowempty",
            @"row15": @"addontype",
            @"row16": @"maximum",
            @"row17": @"minimum",
            @"row18": @"step",
            @"row19": @"definition",
        },
    ];
    
    menu_Settings.subItem.subItem.sheetActions = @[
        @[],
    ];
    
    menu_Settings.subItem.subItem.rowHeight = SETTINGS_ROW_HEIGHT;
    menu_Settings.subItem.subItem.thumbWidth = SETTINGS_THUMB_WIDTH;
    
#pragma mark - Custom Button Entry (Settings & Addons)
    __auto_type customButtonEntry = [mainMenu new];
    customButtonEntry.mainLabel = @"Custom Button Menu";
    customButtonEntry.icon = @"icon_menu_settings";
    customButtonEntry.type = TypeCustomButtonEntry;
    customButtonEntry.family = FamilyDetailView;
    customButtonEntry.enableSection = YES;
    customButtonEntry.disableNavbarButtons = YES;
    customButtonEntry.rowHeight = SETTINGS_ROW_HEIGHT;
    customButtonEntry.thumbWidth = SETTINGS_THUMB_WIDTH;
    customButtonEntry.mainButtons = @[
        @"st_filemode",
        @"st_addons",
        @"st_video_addon",
        @"st_music_addon",
        @"st_kodi_action",
        @"st_kodi_window",
    ];
    
    customButtonEntry.mainMethod = [@[
        @{
            @"method": @"Settings.GetSections",
        },
        @{
            @"method": @"Addons.GetAddons",
        },
        @{
            @"method": @"Addons.GetAddons",
        },
        @{
            @"method": @"Addons.GetAddons",
        },
        @{
            @"method": @"JSONRPC.Introspect",
        },
        @{
            @"method": @"JSONRPC.Introspect",
        },
    ] mutableCopy];
    
    customButtonEntry.mainParameters = [@[
        @{
            @"parameters": @{
                @"level": @"expert",
            },
            @"label": LOCALIZED_STR(@"XBMC Settings"),
            @"defaultThumb": @"nocover_filemode",
            @"thumbWidth": @0,
        },
        
        @{
            @"parameters": @{
                @"type": @"xbmc.addon.executable",
                @"enabled": @YES,
                @"properties": @[
                    @"name",
                    @"version",
                    @"summary",
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Programs"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @SETTINGS_ROW_HEIGHT,
            @"thumbWidth": @SETTINGS_THUMB_WIDTH_BIG,
            @"itemSizes": [self itemSizes_Music],
            @"enableCollectionView": @YES,
            @"forceActionSheet": @YES,
        },
        
        @{
            @"parameters": @{
                @"type": @"xbmc.addon.video",
                @"enabled": @YES,
                @"properties": @[
                    @"name",
                    @"version",
                    @"summary",
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Video Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @SETTINGS_ROW_HEIGHT,
            @"thumbWidth": @SETTINGS_THUMB_WIDTH_BIG,
            @"itemSizes": [self itemSizes_Music],
            @"enableCollectionView": @YES,
            @"forceActionSheet": @YES,
        },
        
        @{
            @"parameters": @{
                @"type": @"xbmc.addon.audio",
                @"enabled": @YES,
                @"properties": @[
                    @"name",
                    @"version",
                    @"summary",
                    @"thumbnail",
                ],
            },
            @"label": LOCALIZED_STR(@"Music Add-ons"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @SETTINGS_ROW_HEIGHT,
            @"thumbWidth": @SETTINGS_THUMB_WIDTH_BIG,
            @"itemSizes": [self itemSizes_Music],
            @"enableCollectionView": @YES,
            @"forceActionSheet": @YES,
        },
        
        @{
            @"parameters": @{
                @"filter": @{
                    @"id": @"Input.ExecuteAction",
                    @"type": @"method",
                },
            },
            @"label": LOCALIZED_STR(@"Kodi actions"),
            @"defaultThumb": @"default-right-action-icon",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @0,
            @"morelabel": LOCALIZED_STR(@"Execute a specific action"),
            @"forceActionSheet": @YES,
        },
        
        @{
            @"parameters": @{
                @"filter": @{
                    @"id": @"GUI.ActivateWindow",
                    @"type": @"method",
                },
            },
            @"label": LOCALIZED_STR(@"Kodi windows"),
            @"defaultThumb": @"default-right-window-icon",
            @"rowHeight": @FILEMODE_ROW_HEIGHT,
            @"thumbWidth": @0,
            @"morelabel": LOCALIZED_STR(@"Activate a specific window"),
            @"forceActionSheet": @YES,
        },
    ] mutableCopy];
    
    customButtonEntry.mainFields = @[
        @{
            @"itemid": @"sections",
            @"row1": @"label",
            @"row2": @"help",
            @"row3": @"id",
            @"row4": @"id",
            @"row5": @"id",
            @"row6": @"id",
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"sectionid",
            @"row9": @"id",
        },
        
        @{
            @"itemid": @"addons",
            @"row1": @"name",
            @"row2": @"summary",
            @"row3": @"blank",
            @"row4": @"blank",
            @"row5": @"addonid",
            @"row6": @"addonid",
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"addonid",
            @"row9": @"addonid",
        },
        
        @{
            @"itemid": @"addons",
            @"row1": @"name",
            @"row2": @"summary",
            @"row3": @"blank",
            @"row4": @"blank",
            @"row5": @"addonid",
            @"row6": @"addonid",
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"addonid",
            @"row9": @"addonid",
        },
        
        @{
            @"itemid": @"addons",
            @"row1": @"name",
            @"row2": @"summary",
            @"row3": @"blank",
            @"row4": @"blank",
            @"row5": @"addonid",
            @"row6": @"addonid",
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"addonid",
            @"row9": @"addonid",
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
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"addonid",
            @"row9": @"addonid",
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
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"addonid",
            @"row9": @"addonid",
        },
    ];
    
    customButtonEntry.sheetActions = @[
        @[],
        @[
            LOCALIZED_STR(@"Execute program"),
            LOCALIZED_STR(@"Add button"),
        ],
        @[
            LOCALIZED_STR(@"Execute video add-on"),
            LOCALIZED_STR(@"Add button"),
        ],
        @[
            LOCALIZED_STR(@"Execute audio add-on"),
            LOCALIZED_STR(@"Add button"),
        ],
        @[
            LOCALIZED_STR(@"Execute action"),
            LOCALIZED_STR(@"Add action button"),
        ],
        @[
            LOCALIZED_STR(@"Activate window"),
            LOCALIZED_STR(@"Add window activation button"),
        ],
    ];
    
    customButtonEntry.subItem = [mainMenu new];
    customButtonEntry.subItem.mainMethod = [@[
        @{
            @"method": @"Settings.GetCategories",
        },
        @{},
        @{},
        @{},
        @{},
        @{},
    ] mutableCopy];
    
    customButtonEntry.subItem.mainParameters = [@[
        @{
            @"label": LOCALIZED_STR(@"Settings"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @SETTINGS_ROW_HEIGHT,
            @"thumbWidth": @0,
        },
        @{},
        @{},
        @{},
        @{},
        @{},
    ] mutableCopy];
    
    customButtonEntry.subItem.mainFields = @[
        @{
            @"itemid": @"categories",
            @"row1": @"label",
            @"row2": @"help",
            @"row3": @"id",
            @"row4": @"id",
            @"row5": @"id",
            @"row6": @"id",
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row8": @"categoryid",
            @"row9": @"id",
        },
        @{},
        @{},
        @{},
        @{},
        @{},
    ];
    
    customButtonEntry.subItem.disableNavbarButtons = YES;
    customButtonEntry.subItem.rowHeight = SETTINGS_ROW_HEIGHT;
    customButtonEntry.subItem.thumbWidth = SETTINGS_THUMB_WIDTH;
    
    customButtonEntry.subItem.subItem = [mainMenu new];
    customButtonEntry.subItem.subItem.mainMethod = [@[
        @{
            @"method": @"Settings.GetSettings",
        },
    ] mutableCopy];
    
    customButtonEntry.subItem.subItem.mainParameters = [@[
        @{
            @"label": LOCALIZED_STR(@"Settings"),
            @"defaultThumb": @"nocover_filemode",
            @"rowHeight": @SETTINGS_ROW_HEIGHT,
            @"thumbWidth": @0,
        },
    ] mutableCopy];
    
    customButtonEntry.subItem.subItem.mainFields = @[
        @{
            @"itemid": @"settings",
            @"row1": @"label",
            @"row2": @"help",
            @"row3": @"id",
            @"row4": @"default",
            @"row5": @"enabled",
            @"row6": @"id",
            @"playlistid": @PLAYERID_UNKNOWN,
            @"row7": @"delimiter",
            @"row8": @"id",
            @"row9": @"type",
            @"row10": @"parent",
            @"row11": @"control",
            @"row12": @"value",
            @"row13": @"options",
            @"row14": @"allowempty",
            @"row15": @"addontype",
            @"row16": @"maximum",
            @"row17": @"minimum",
            @"row18": @"step",
            @"row19": @"definition",
        },
    ];
    
    customButtonEntry.subItem.subItem.sheetActions = @[
        @[],
    ];
    
    customButtonEntry.subItem.subItem.disableNavbarButtons = YES;
    customButtonEntry.subItem.subItem.rowHeight = SETTINGS_ROW_HEIGHT;
    customButtonEntry.subItem.subItem.thumbWidth = SETTINGS_THUMB_WIDTH;
    
    AppDelegate.instance.customButtonEntry = customButtonEntry;
    
#pragma mark - Build and Initialize Menu Structure
    
    // Build menu tree
    NSMutableArray *mainMenuItems = [NSMutableArray new];
    if (IS_IPHONE) {
        [mainMenuItems addObject:menu_Server];
    }
    if ([self isMenuEntryEnabled:@"menu_music"]) {
        [mainMenuItems addObject:menu_Music];
    }
    if ([self isMenuEntryEnabled:@"menu_movies"]) {
        [mainMenuItems addObject:menu_Movies];
    }
    if ([self isMenuEntryEnabled:@"menu_videos"]) {
        [mainMenuItems addObject:menu_Videos];
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
    if ([self isMenuEntryEnabled:@"menu_radio"]) {
        [mainMenuItems addObject:menu_Radio];
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
    if ([self isMenuEntryEnabled:@"menu_search"]) {
        [mainMenuItems addObject:menu_Search];
    }
    if ([self isMenuEntryEnabled:@"menu_files"]) {
        [mainMenuItems addObject:menu_Files];
    }
    if ([self isMenuEntryEnabled:@"menu_addons"]) {
        [mainMenuItems addObject:menu_Addons];
    }
    if ([self isMenuEntryEnabled:@"menu_settings"]) {
        [mainMenuItems addObject:menu_Settings];
    }
    if (IS_IPHONE) {
        [mainMenuItems addObject:menu_AppSettings];
    }
    
#pragma mark - Build and Initialize Global Search Lookup
    
    NSArray *globalSearchKeyConfig = @[
                    //menu path,          label of tab                    nocover icon                itemid
        LOOKUP_ITEM(menu_Movies,          LOCALIZED_STR(@"Movies"),       @"nocover_movies",          @"movieid"),
        LOOKUP_ITEM(menu_Movies,          LOCALIZED_STR(@"Movie Sets"),   @"nocover_movie_sets",      @"setid"),
        LOOKUP_ITEM(menu_TVShows,         LOCALIZED_STR(@"TV Shows"),     @"nocover_tvshows_episode", @"tvshowid"),
        LOOKUP_ITEM(menu_TVShows.subItem, LOCALIZED_STR(@"Episodes"),     @"nocover_tvshows_episode", @"episodeid"),
        LOOKUP_ITEM(menu_Videos,          LOCALIZED_STR(@"Music Videos"), @"nocover_music",           @"musicvideoid"),
        LOOKUP_ITEM(menu_Music,           LOCALIZED_STR(@"Artists"),      @"nocover_artist",          @"artistid"),
        LOOKUP_ITEM(menu_Music,           LOCALIZED_STR(@"Albums"),       @"nocover_music",           @"albumid"),
        LOOKUP_ITEM(menu_Music,           LOCALIZED_STR(@"All songs"),    @"nocover_music",           @"songid"),
    ];
    
    // Build the GlobalSearch lookup table
    MainMenuGlobalSearchLookup *lookup = [[MainMenuGlobalSearchLookup alloc] initWithConfiguration:globalSearchKeyConfig];
    AppDelegate.instance.globalSearchLookup = lookup;
    
    return mainMenuItems;
}

@end

#pragma mark - Lookup Item Implementation

@implementation LookupItem

- (instancetype)initWithPath:(mainMenu*)path label:(NSString*)label icon:(NSString*)icon itemId:(NSString*)itemId {
    self = [super init];
    self.menuPath = path;
    self.menuLabel = label;
    self.menuIcon = icon;
    self.itemId = itemId;
    return self;
}

@end

#pragma mark - Global Search Lookup Implementation

@implementation MainMenuGlobalSearchLookup

- (instancetype)initWithConfiguration:(NSArray*)configTable {
    self = [super init];
    
    // Build the GlobalSearch lookup table (filtering out entries which cannot resolve tabIndex)
    lookupTable = [configTable filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(LookupItem *lookupItem, NSDictionary *bindings) {
        NSInteger tabIndex = [self getGlobalSearchTab:lookupItem.menuPath label:lookupItem.menuLabel];
        if (tabIndex == NSNotFound) {
            return NO;
        }
        lookupItem.menuTab = tabIndex;
        return YES;
    }]];
    
    return self;
}

- (NSInteger)getGlobalSearchTab:(mainMenu*)menuItem label:(NSString*)subLabel {
    // Search for the method index with the desired sub label (e.g. "All Songs")
    NSInteger tab = NSNotFound;
    for (int k = 0; k < menuItem.mainMethod.count; ++k) {
        id parameters = menuItem.mainParameters[k];
        if ([parameters[@"label"] isEqualToString:subLabel]) {
            return k;
        }
    }
    return tab;
}

- (NSUInteger)getLookupIndexForItemId:(NSString*)itemid {
    // Search for the GlobalSearch index for the desired itemid
    NSUInteger index = [lookupTable indexOfObjectPassingTest:^BOOL(LookupItem *item, NSUInteger idx, BOOL *stop) {
      return [itemid isEqualToString:item.itemId];
    }];
    return index;
}

- (NSString*)getThumbForItem:(NSDictionary*)item {
    NSUInteger index = [self getLookupIndexForItemId:item[@"family"]];
    if (index != NSNotFound) {
        LookupItem *lookupItem = lookupTable[index];
        return lookupItem.menuIcon;
    }
    return @"nocover_filemode";
}

- (LookupItem*)getLookupForItem:(id)item {
    NSUInteger index = [self getLookupIndexForItemId:item[@"family"]];
    return index != NSNotFound ? lookupTable[index] : nil;
}

- (mainMenu*)getMenuForItem:(id)item {
    LookupItem *lookupItem = [self getLookupForItem:item];
    return lookupItem.menuPath;
}

- (NSInteger)getTabForItem:(id)item {
    LookupItem *lookupItem = [self getLookupForItem:item];
    return lookupItem ? lookupItem.menuTab : NSNotFound;
}

- (mainMenu*)getMenuForIndex:(int)index {
    if (index < 0 || index >= lookupTable.count) {
        return nil;
    }
    LookupItem *lookupItem = lookupTable[index];
    return lookupItem.menuPath;
}

- (NSInteger)getTabForIndex:(int)index {
    if (index < 0 || index >= lookupTable.count) {
        return NSNotFound;
    }
    LookupItem *lookupItem = lookupTable[index];
    return lookupItem ? lookupItem.menuTab : NSNotFound;
}

- (NSString*)getLongNameForIndex:(int)index {
    if (index < 0 || index >= lookupTable.count) {
        return nil;
    }
    LookupItem *lookupItem = lookupTable[index];
    return lookupItem.menuLabel;
}

@end
