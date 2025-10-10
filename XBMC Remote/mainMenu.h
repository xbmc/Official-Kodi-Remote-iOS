//
//  mainMenu.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MenuItemFamily) {
    FamilyDetailView,
    FamilyNowPlaying,
    FamilyRemote,
    FamilyServer,
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
    TypeSettings,
    TypeCustomButtonEntry,
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
@property MenuItemFamily family;
@property MenuItemType type;
@property BOOL enableSection;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSArray *mainMethod;
@property (nonatomic, copy) NSString *defaultThumb;
@property (nonatomic, copy) NSArray *mainButtons;
@property (nonatomic, copy) NSArray *mainFields;
@property (nonatomic, strong) NSMutableArray *mainParameters;
@property (nonatomic, strong) mainMenu *subItem;
@property (nonatomic, copy) NSArray *sheetActions;
@property int rowHeight;
@property int thumbWidth;
@property (nonatomic, copy) NSArray *showInfo;
@property int originYearDuration;
@property int widthLabel;
@property int chooseTab;
@property BOOL disableNavbarButtons;
@property (nonatomic, copy) NSArray *showRuntime;
@property BOOL noConvertTime;
@property (nonatomic, copy) NSArray *filterModes;

- (id)copyWithZone:(NSZone*)zone;
+ (NSMutableArray*)generateMenus;
+ (NSArray*)action_album;

@end
