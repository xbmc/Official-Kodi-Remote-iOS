//
//  mainMenu.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

@import Foundation;

typedef NS_ENUM(NSInteger, MenuItemFamily) {
    FamilyDetailView,
    FamilyNowPlaying,
    FamilyRemote,
    FamilyServer,
    FamilyAppSettings,
};

typedef NS_ENUM(NSInteger, MenuItemType) {
    TypeNone = 0,
    TypeServer,
    TypeMusic,
    TypeMovies,
    TypeVideos,
    TypeTvShows,
    TypePictures,
    TypeLiveTv,
    TypeRadio,
    TypeFavourites,
    TypeNowPlaying,
    TypeRemote,
    TypeGlobalSearch,
    TypeFiles,
    TypeAddons,
    TypeKodiSettings,
    TypeCustomButtonEntry,
    TypeAppSettings,
};

typedef NS_ENUM(NSInteger, ViewModes) {
    ViewModeDefault,
    ViewModeUnwatched,
    ViewModeWatched,
    ViewModeNotListened,
    ViewModeListened,
    ViewModeDefaultArtists,
    ViewModeAlbumArtists,
    ViewModeSongArtists,
};

@interface mainMenu : NSObject

@property (nonatomic, copy) NSString *mainLabel;
@property (nonatomic) MenuItemFamily family;
@property (nonatomic) MenuItemType type;
@property (nonatomic) BOOL enableSection;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSArray *mainMethod;
@property (nonatomic, copy) NSArray *mainButtons;
@property (nonatomic, copy) NSArray *mainFields;
@property (nonatomic, strong) NSMutableArray *mainParameters;
@property (nonatomic, strong) mainMenu *subItem;
@property (nonatomic, copy) NSArray *sheetActions;
@property (nonatomic) int rowHeight;
@property (nonatomic) int thumbWidth;
@property (nonatomic, copy) NSArray *showInfo;
@property (nonatomic) int maxXrightLabel;
@property (nonatomic) int widthLabel;
@property (nonatomic) int chooseTab;
@property (nonatomic) BOOL disableNavbarButtons;
@property (nonatomic, copy) NSArray *showRuntime;
@property (nonatomic) BOOL noConvertTime;
@property (nonatomic, copy) NSArray *filterModes;

- (id)copyWithZone:(NSZone*)zone;
+ (NSMutableArray*)generateMenus;
+ (NSArray*)action_album;

@end

@interface LookupItem : NSObject

- (instancetype)initWithPath:(mainMenu*)path label:(NSString*)label icon:(NSString*)icon itemId:(NSString*)itemId;

@property (nonatomic, copy) mainMenu *menuPath;
@property (nonatomic, assign) NSInteger menuTab;
@property (nonatomic, copy) NSString *menuLabel;
@property (nonatomic, copy) NSString *menuIcon;
@property (nonatomic, copy) NSString *itemId;

@end


@interface MainMenuGlobalSearchLookup : NSObject {
    NSArray *lookupTable;
}

- (instancetype)initWithConfiguration:(NSArray*)configTable;
- (NSUInteger)getLookupIndexForItemId:(NSString*)itemid;
- (NSString*)getThumbForItem:(NSDictionary*)item;
- (LookupItem*)getLookupForItem:(id)item;
- (mainMenu*)getMenuForItem:(id)item;
- (NSInteger)getTabForItem:(id)item;
- (mainMenu*)getMenuForIndex:(int)index;
- (NSInteger)getTabForIndex:(int)index;
- (NSString*)getLongNameForIndex:(int)index;

@end
