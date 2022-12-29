//
//  mainMenu.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    FamilyDetailView,
    FamilyNowPlaying,
    FamilyRemote,
    FamilyServer
} MenuItemFamilyType;

typedef enum {
    ViewModeDefault,
    ViewModeUnwatched,
    ViewModeWatched,
    ViewModeNotListened,
    ViewModeListened,
    ViewModeDefaultArtists,
    ViewModeAlbumArtists,
    ViewModeSongArtists
} ViewModes;

@interface mainMenu : NSObject

@property (nonatomic, copy) NSString *rootLabel;
@property (nonatomic, copy) NSString *mainLabel;
@property MenuItemFamilyType family;
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
@property BOOL disableNowPlaying;
@property (nonatomic, copy) NSArray *showRuntime;
@property BOOL noConvertTime;
@property (nonatomic, copy) NSArray *filterModes;
@property ViewModes currentFilterMode;

- (id)copyWithZone:(NSZone*)zone;

@end
