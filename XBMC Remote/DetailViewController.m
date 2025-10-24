//
//  DetailViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "DetailViewController.h"
#import "mainMenu.h"
#import "DSJSONRPC.h"
#import "GlobalData.h"
#import "ShowInfoViewController.h"
#import "DetailViewController.h"
#import "NowPlaying.h"
#import "SDImageCache.h"
#import "AppDelegate.h"
#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"
#import "QuartzCore/CALayer.h"
#import <QuartzCore/QuartzCore.h>
#import "PosterCell.h"
#import "PosterLabel.h"
#import "PosterHeaderView.h"
#import "RecentlyAddedCell.h"
#import "NSString+MD5.h"
#import "UIScrollView+SVPullToRefresh.h"
#import "BroadcastProgressView.h"
#import "SettingsValuesViewController.h"
#import "customButton.h"
#import "VersionCheck.h"
#import "SharingActivityItemSource.h"

#import "GeneratedAssetSymbols.h"

@interface DetailViewController ()
- (void)configureView;
@end

@implementation DetailViewController

@synthesize detailItem = _detailItem;
@synthesize sections;
@synthesize filteredListContent;
@synthesize richResults;
@synthesize sectionArray;
@synthesize sectionArrayOpen;

#define SECTIONS_START_AT 100
#define MAX_NORMAL_BUTTONS 4
#define WARNING_TIMEOUT 30.0
#define GRID_SECTION_HEADER_HEIGHT 24
#define LIST_SECTION_HEADER_HEIGHT 24
#define FIXED_SPACE_WIDTH 120
#define INFO_PADDING 10
#define MONKEY_COUNT 38
#define MONKEY_OFFSET_X 3
#define GLOBALSEARCH_INDEX_MOVIES 0
#define GLOBALSEARCH_INDEX_MOVIESETS 1
#define GLOBALSEARCH_INDEX_TVSHOWS 2
#define GLOBALSEARCH_INDEX_MUSICVIDEOS 3
#define GLOBALSEARCH_INDEX_ARTISTS 4
#define GLOBALSEARCH_INDEX_ALBUMS 5
#define GLOBALSEARCH_INDEX_SONGS 6
#define IPHONE_SEASON_SECTION_HEIGHT 99
#define IPHONE_ALBUM_SECTION_HEIGHT 116
#define IPAD_SEASON_SECTION_HEIGHT 120
#define IPAD_ALBUM_SECTION_HEIGHT 166
#define INDEX_WIDTH 34
#define RUNTIMEYEAR_WIDTH 63
#define GENRE_HEIGHT 18
#define EPGCHANNELTIME_WIDTH 40
#define EPGCHANNELTIME_HEIGHT 12
#define EPGCHANNELBAR_HEIGHT 30
#define RECORDING_DOT_SIZE 12
#define TRACKCOUNT_WIDTH 26
#define LABEL_PADDING 8
#define VERTICAL_PADDING 8
#define SMALL_PADDING 4
#define TINY_PADDING 2
#define FLAG_SIZE 16
#define INDICATOR_SIZE 16
#define FLOWLAYOUT_FULLSCREEN_INSET 8
#define FLOWLAYOUT_FULLSCREEN_MIN_SPACE 4
#define FLOWLAYOUT_FULLSCREEN_LABEL (FULLSCREEN_LABEL_HEIGHT + 8)
#define TOGGLE_BUTTON_SIZE 11
#define INFO_BUTTON_SIZE 30
#define FULLSCREEN_BUTTON_SIZE 26
#define LABEL_HEIGHT(font) ceil(font.lineHeight)

#define XIB_JSON_DATA_CELL_TITLE 1
#define XIB_JSON_DATA_CELL_GENRE 2
#define XIB_JSON_DATA_CELL_RUNTIMEYEAR 3
#define XIB_JSON_DATA_CELL_RUNTIME 4
#define XIB_JSON_DATA_CELL_RATING 5
#define XIB_JSON_DATA_CELL_WATCHED_FLAG 9
#define XIB_JSON_DATA_CELL_ACTIVTYINDICATOR SHARED_CELL_ACTIVTYINDICATOR
#define ALBUM_VIEW_CELL_TRACKNUMBER 101
#define SEASON_VIEW_CELL_TOGGLE 99
#define DETAIL_VIEW_INFO_ALBUM 104
#define DETAIL_VIEW_INFO_TVSHOW 105
#define EPG_VIEW_CELL_STARTTIME 102
#define EPG_VIEW_CELL_PROGRESSVIEW 103
#define EPG_VIEW_CELL_RECORDING_ICON SHARED_CELL_RECORDING_ICON

- (id)initWithFrame:(CGRect)frame {
    if (self = [super init]) {
		self.view.frame = frame;
    }
    return self;
}

- (id)initWithNibName:(NSString*)nibNameOrNil withItem:(mainMenu*)item withFrame:(CGRect)frame bundle:(NSBundle*)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.detailItem = item;
        self.view.frame = frame;
    }
    return self;
}

#pragma mark - Live TV epg memory/disk cache management

- (NSMutableArray*)loadEPGFromMemory:(NSNumber*)channelid {
    __block NSMutableArray *epgarray = nil;
    dispatch_sync(epglockqueue, ^{
        epgarray = epgDict[channelid];
    });
    return epgarray;
}

- (NSMutableArray*)loadEPGFromDisk:(NSNumber*)channelid parameters:(NSDictionary*)params {
    NSString *epgKey = [self getCacheKey:@"EPG" parameters:nil];
    NSString *filename = [NSString stringWithFormat:@"%@-%@.epg.dat", epgKey, channelid];
    NSMutableArray *epgArray = [Utilities unarchivePath:epgCachePath file:filename];
    dispatch_sync(epglockqueue, ^{
        if (epgArray != nil && channelid != nil) {
            epgDict[channelid] = epgArray;
        }
    });
    return epgArray;
}

- (void)backgroundSaveEPGToDisk:(NSDictionary*)parameters {
    NSNumber *channelid = parameters[@"channelid"];
    NSMutableArray *epgData = parameters[@"epgArray"];
    [self saveEPGToDisk:channelid epgData:epgData];
}

- (void)saveEPGToDisk:(NSNumber*)channelid epgData:(NSMutableArray*)epgArray {
    if (epgArray != nil && channelid != nil && epgArray.count > 0) {
        NSString *epgKey = [self getCacheKey:@"EPG" parameters:nil];
        NSString *filename = [NSString stringWithFormat:@"%@-%@.epg.dat", epgKey, channelid];
        [Utilities archivePath:epgCachePath file:filename data:epgArray];
        dispatch_sync(epglockqueue, ^{
            epgDict[channelid] = epgArray;
            [epgDownloadQueue removeObject:channelid];
        });
    }
}

#pragma mark - Live TV epg management

- (void)getChannelEpgInfo:(NSDictionary*)parameters {
    NSNumber *channelid = [Utilities getNumberFromItem:parameters[@"channelid"]];
    NSIndexPath *indexPath = parameters[@"indexPath"];
    NSMutableDictionary *item = parameters[@"item"];
    if ([channelid longValue] > 0) {
        NSMutableArray *retrievedEPG = [self loadEPGFromMemory:channelid];
        NSMutableDictionary *channelEPG = [self parseEpgData:retrievedEPG];
        NSDictionary *epgparams = [NSDictionary dictionaryWithObjectsAndKeys:
                                   channelEPG, @"channelEPG",
                                   indexPath, @"indexPath",
                                   item, @"item",
                                   nil];
        [self performSelectorOnMainThread:@selector(updateEpgTableInfo:) withObject:epgparams waitUntilDone:NO];
        if ([channelEPG[@"refresh_data"] boolValue]) {
            retrievedEPG = [self loadEPGFromDisk:channelid parameters:parameters];
            channelEPG = [self parseEpgData:retrievedEPG];
            NSDictionary *epgparams = [NSDictionary dictionaryWithObjectsAndKeys:
                                       channelEPG, @"channelEPG",
                                       indexPath, @"indexPath",
                                       item, @"item",
                                       nil];
            [self performSelectorOnMainThread:@selector(updateEpgTableInfo:) withObject:epgparams waitUntilDone:NO];
            dispatch_sync(epglockqueue, ^{
                if ([channelEPG[@"refresh_data"] boolValue] && ![epgDownloadQueue containsObject:channelid]) {
                    [epgDownloadQueue addObject:channelid];
                    [self performSelectorOnMainThread:@selector(getJsonEPG:) withObject:parameters waitUntilDone:NO];
                }
            });
        }
    }
}

- (NSMutableDictionary*)parseEpgData:(NSMutableArray*)epgData {
    NSMutableDictionary *channelEPG = [NSMutableDictionary new];
    channelEPG[@"current"] = LOCALIZED_STR(@"Not Available");
    channelEPG[@"next"] = LOCALIZED_STR(@"Not Available");
    channelEPG[@"current_details"] = @"";
    channelEPG[@"refresh_data"] = @YES;
    channelEPG[@"starttime"] = @"";
    channelEPG[@"endtime"] = @"";
    if (epgData != nil) {
        NSDictionary *objectToSearch;
        NSDate *nowDate = [NSDate date];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"starttime <= %@ AND endtime >= %@", nowDate, nowDate];
        NSArray *filteredArray = [epgData filteredArrayUsingPredicate:predicate];
        if (filteredArray.count > 0) {
            objectToSearch = filteredArray[0];
            channelEPG[@"starttime"] = objectToSearch[@"starttime"];
            channelEPG[@"endtime"] = objectToSearch[@"endtime"];
            channelEPG[@"current"] = [NSString stringWithFormat:@"%@ %@",
                                      [localHourMinuteFormatter stringFromDate:objectToSearch[@"starttime"]],
                                      objectToSearch[@"title"]
                                      ];
            NSCalendar *gregorian = [[NSCalendar alloc]
                                     initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSUInteger unitFlags = NSCalendarUnitMinute;
            NSDateComponents *components = [gregorian components:unitFlags
                                                        fromDate:objectToSearch[@"starttime"]
                                                          toDate:objectToSearch[@"endtime"] options:0];
            NSInteger minutes = [components minute];
            NSString *plotoutline = objectToSearch[@"plotoutline"];
            if (!plotoutline || [plotoutline isKindOfClass:[NSNull class]] || [objectToSearch[@"plot"] isEqualToString:plotoutline]) {
                plotoutline = @"";
            }
            channelEPG[@"current_details"] = [NSString stringWithFormat:@"\n%@\n%@\n%@\n\n%@ - %@ (%ld %@)",
                                              objectToSearch[@"title"],
                                              plotoutline.length > 0 ? [NSString stringWithFormat:@"%@\n", plotoutline] : @"",
                                              objectToSearch[@"plot"],
                                              [localHourMinuteFormatter stringFromDate:objectToSearch[@"starttime"]],
                                              [localHourMinuteFormatter stringFromDate:objectToSearch[@"endtime"]],
                                              (long)minutes,
                                              (long)minutes > 1 ? LOCALIZED_STR(@"Mins.") : LOCALIZED_STR(@"Min")
                                              ];
            predicate = [NSPredicate predicateWithFormat:@"starttime >= %@", objectToSearch[@"endtime"]];
            NSArray *nextFilteredArray = [epgData filteredArrayUsingPredicate:predicate];
            if (nextFilteredArray.count > 0) {
                channelEPG[@"next"] = [NSString stringWithFormat:@"%@ %@",
                                       [localHourMinuteFormatter stringFromDate:nextFilteredArray[0][@"starttime"]],
                                       nextFilteredArray[0][@"title"]
                                       ];
                channelEPG[@"refresh_data"] = @NO;
            }
        }
    }
    return channelEPG;
}

- (void)updateEpgTableInfo:(NSDictionary*)parameters {
    NSMutableDictionary *channelEPG = parameters[@"channelEPG"];
    NSIndexPath *indexPath = parameters[@"indexPath"];
    NSMutableDictionary *item = parameters[@"item"];
    UITableViewCell *cell = [dataList cellForRowAtIndexPath:indexPath];
    UILabel *current = (UILabel*)[cell viewWithTag:XIB_JSON_DATA_CELL_GENRE];
    UILabel *next = (UILabel*)[cell viewWithTag:XIB_JSON_DATA_CELL_RUNTIME];
    current.text = channelEPG[@"current"];
    next.text = channelEPG[@"next"];
    if (channelEPG[@"current_details"] != nil) {
        item[@"genre"] = channelEPG[@"current_details"];
    }
    BroadcastProgressView *progressView = (BroadcastProgressView*)[cell viewWithTag:EPG_VIEW_CELL_PROGRESSVIEW];
    if (![current.text isEqualToString:LOCALIZED_STR(@"Not Available")] && [channelEPG[@"starttime"] isKindOfClass:[NSDate class]] && [channelEPG[@"endtime"] isKindOfClass:[NSDate class]]) {
        float percent_elapsed = [Utilities getPercentElapsed:channelEPG[@"starttime"] EndDate:channelEPG[@"endtime"]];
        [progressView setProgress:percent_elapsed / 100.0];
        progressView.hidden = NO;
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSUInteger unitFlags = NSCalendarUnitMinute;
        NSDateComponents *components = [gregorian components:unitFlags
                                                    fromDate:channelEPG[@"starttime"]
                                                      toDate:channelEPG[@"endtime"] options:0];
        NSInteger minutes = [components minute];
        progressView.barLabel.text = [NSString stringWithFormat:@"%ld'", (long)minutes];
    }
    else {
        progressView.hidden = YES;
    }
}

- (void)parseBroadcasts:(NSDictionary*)parameters {
    NSArray *broadcasts = parameters[@"broadcasts"];
    NSNumber *channelid = parameters[@"channelid"];
    NSIndexPath *indexPath = parameters[@"indexPath"];
    NSMutableDictionary *item = parameters[@"item"];
    NSMutableArray *retrievedEPG = [NSMutableArray new];
    for (id EPGobject in broadcasts) {
        if ([EPGobject isKindOfClass:[NSDictionary class]]) {
            NSDate *starttime = [xbmcDateFormatter dateFromString:EPGobject[@"starttime"]];
            NSDate *endtime = [xbmcDateFormatter dateFromString:EPGobject[@"endtime"]];
            [retrievedEPG addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                     starttime, @"starttime",
                                     endtime, @"endtime",
                                     EPGobject[@"title"], @"title",
                                     EPGobject[@"label"], @"label",
                                     EPGobject[@"plot"], @"plot",
                                     EPGobject[@"plotoutline"], @"plotoutline",
                                     nil]];
        }
    }
    [self saveEPGToDisk:channelid epgData:retrievedEPG];
    NSDictionary *epgparams = [NSDictionary dictionaryWithObjectsAndKeys:
                               [self parseEpgData:retrievedEPG], @"channelEPG",
                               indexPath, @"indexPath",
                               item, @"item",
                               nil];
    [self performSelectorOnMainThread:@selector(updateEpgTableInfo:) withObject:epgparams waitUntilDone:NO];
}

- (void)getJsonEPG:(NSDictionary*)parameters {
    NSNumber *channelid = parameters[@"channelid"];
    NSIndexPath *indexPath = parameters[@"indexPath"];
    NSMutableDictionary *item = parameters[@"item"];
    [[Utilities getJsonRPC] callMethod:@"PVR.GetBroadcasts"
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                         channelid, @"channelid",
                         @[@"title", @"starttime", @"endtime", @"plot", @"plotoutline"], @"properties",
                         nil]
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
               if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSDictionary class]]) {
                   NSArray *broadcasts = methodResult[@"broadcasts"];
                   if (broadcasts && [broadcasts isKindOfClass:[NSArray class]]) {
                       NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                               channelid, @"channelid",
                                               indexPath, @"indexPath",
                                               item, @"item",
                                               broadcasts, @"broadcasts",
                                               nil];
                       [NSThread detachNewThreadSelector:@selector(parseBroadcasts:) toTarget:self withObject:params];
                   }
               }
           }];
}

#pragma mark - Library disk cache management

- (NSString*)getCacheKey:(NSString*)fieldA parameters:(NSMutableDictionary*)fieldB {
    // Which server are we connected to?
    GlobalData *obj = [GlobalData getInstance];
    NSString *serverInfo = [NSString stringWithFormat:@"%@ %@ %@", obj.serverIP, obj.serverPort, obj.serverDescription];
    
    // Which version does the serer have?
    NSString *serverVersion = [NSString stringWithFormat:@"%d.%d", serverMajorVersion, serverMinorVersion];
    
    // Which App version are we running?
    NSString *appVersion = [Utilities getAppVersionString];
    
    // Which JSON request's results do we cache??
    NSString *jsonRequest = [NSString stringWithFormat:@"%@ %@", fieldA, fieldB];
    
    // Get SHA256 hash for the combination given above
    NSString *text = [NSString stringWithFormat:@"%@%@%@%@", serverInfo, serverVersion, appVersion, jsonRequest];
    return [text SHA256String];
}

- (void)saveData:(NSMutableDictionary*)mutableParameters {
    if (!enableDiskCache) {
        return;
    }
    if (mutableParameters != nil) {
        mainMenu *menuItem = self.detailItem;
        NSDictionary *methods = menuItem.mainMethod[chosenTab];
        NSString *viewKey = [self getCacheKey:methods[@"method"] parameters:mutableParameters];
        
        NSString *filename = [NSString stringWithFormat:@"%@.richResults.dat", viewKey];
        [Utilities archivePath:libraryCachePath file:filename data:self.richResults];
        
        NSString *path = [libraryCachePath stringByAppendingPathComponent:filename];
        [self updateSyncDate:path];
 
        filename = [NSString stringWithFormat:@"%@.extraSectionRichResults.dat", viewKey];
        [Utilities archivePath:libraryCachePath file:filename data:self.extraSectionRichResults];
    }
}

- (void)loadDataFromDisk:(NSDictionary*)params {
    self.richResults = nil;
    self.sectionArray = nil;
    self.sectionArrayOpen = nil;
    self.extraSectionRichResults = nil;
    self.sections = [NSMutableDictionary new];
    
    NSString *viewKey = [self getCacheKey:params[@"methodToCall"] parameters:params[@"mutableParameters"]];
    NSString *filename = [NSString stringWithFormat:@"%@.richResults.dat", viewKey];
    NSMutableArray *tempArray = [Utilities unarchivePath:libraryCachePath file:filename];
    self.richResults = tempArray;
    
    filename = [NSString stringWithFormat:@"%@.extraSectionRichResults.dat", viewKey];
    tempArray = [Utilities unarchivePath:libraryCachePath file:filename];
    self.extraSectionRichResults = tempArray;
    
    storeRichResults = [self.richResults mutableCopy];
    [self performSelectorOnMainThread:@selector(indexAndDisplayData) withObject:nil waitUntilDone:YES];
}

- (BOOL)loadedDataFromDisk:(NSString*)methodToCall parameters:(NSMutableDictionary*)mutableParameters refresh:(BOOL)forceRefresh {
    if (forceRefresh) {
        return NO;
    }
    if (!enableDiskCache) {
        return NO;
    }
    NSString *viewKey = [self getCacheKey:methodToCall parameters:mutableParameters];
    NSString *filename = [NSString stringWithFormat:@"%@.richResults.dat", viewKey];
    NSString *path = [libraryCachePath stringByAppendingPathComponent:filename];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSDictionary *extraParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                     mutableParameters, @"mutableParameters",
                                     methodToCall, @"methodToCall",
                                     nil];
        [self updateSyncDate:path];
        [NSThread detachNewThreadSelector:@selector(loadDataFromDisk:) toTarget:self withObject:extraParams];
        return YES;
    }
    return NO;
}

- (void)updateSyncDate:(NSString*)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *attributesRetrievalError = nil;
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:&attributesRetrievalError];
        if (attributes) {
            NSDateFormatter *dateFormatter = [NSDateFormatter new];
            dateFormatter.dateStyle = NSDateFormatterLongStyle;
            dateFormatter.timeStyle = NSDateFormatterShortStyle;
            dateFormatter.locale = [NSLocale currentLocale];
            NSString *dateString = [dateFormatter stringFromDate:[attributes fileModificationDate]];
            NSString *title = [NSString stringWithFormat:@"%@: %@", LOCALIZED_STR(@"Last sync"), dateString];
            [dataList.pullToRefreshView setSubtitle:title forState:SVPullToRefreshStateStopped];
            [dataList.pullToRefreshView setSubtitle:title forState:SVPullToRefreshStateTriggered];
            [collectionView.pullToRefreshView setSubtitle:title forState:SVPullToRefreshStateStopped];
            [collectionView.pullToRefreshView setSubtitle:title forState:SVPullToRefreshStateTriggered];
        }
    }
}

#pragma mark - Utility

- (BOOL)isTimerActiveForItem:(id)item {
    return [item[@"hastimer"] boolValue] || [item[@"isrecording"] boolValue];
}

- (void)enterSubmenuForItem:(id)item params:(NSDictionary*)parameters {
    mainMenu *menuItem = [self getMainMenu:item];
    int activeTab = [self getActiveTab:item];
    menuItem.subItem.mainLabel = item[@"label"];
    mainMenu *newMenuItem = [menuItem.subItem copy];
    newMenuItem.mainParameters[activeTab] = parameters;
    newMenuItem.chooseTab = activeTab;
    if (IS_IPHONE) {
        DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
        detailViewController.detailItem = newMenuItem;
        [self.navigationController pushViewController:detailViewController animated:YES];
    }
    else {
        if (stackscrollFullscreen) {
            [self toggleFullscreen];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:newMenuItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:NO];
            });
        }
        else {
            DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:newMenuItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
            [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:NO];
        }
    }
}

- (void)addFileProperties:(NSMutableDictionary*)dict {
    if (dict[@"file_properties"] != nil) {
        dict[@"properties"] = [dict[@"file_properties"] mutableCopy];
        [dict removeObjectForKey:@"file_properties"];
        
        // Kodi 11 does not support art for file properties
        if (AppDelegate.instance.serverVersion <= 11) {
            [dict[@"properties"] removeObject:@"art"];
        }
    }
}

- (void)addExtraProperties:(NSMutableArray*)mutableProperties newParams:(NSMutableDictionary*)mutableParameters params:(NSDictionary*)parameters {
    if ([parameters[@"FrodoExtraArt"] boolValue] && AppDelegate.instance.serverVersion > 11) {
        [mutableProperties addObject:@"art"];
    }
    if (parameters[@"kodiExtrasPropertiesMinimumVersion"] != nil) {
        for (id key in parameters[@"kodiExtrasPropertiesMinimumVersion"]) {
            if (AppDelegate.instance.serverVersion >= [key integerValue]) {
                id arrayProperties = parameters[@"kodiExtrasPropertiesMinimumVersion"][key];
                for (id value in arrayProperties) {
                    [mutableProperties addObject:value];
                }
            }
        }
    }
    if (mutableProperties != nil) {
        mutableParameters[@"properties"] = mutableProperties;
    }
}

- (void)setFilternameLabel:(NSString*)labelText {
    labelText = [Utilities stripBBandHTML:labelText];
    self.navigationItem.title = labelText;
    if (IS_IPHONE || stackscrollFullscreen) {
        return;
    }
    [UIView animateWithDuration:0.1
                     animations:^{
        // fade out
        topNavigationLabel.alpha = 0;
                     }
                     completion:^(BOOL finished) {
        // update label
        topNavigationLabel.text = labelText;
        // fade in
        [UIView animateWithDuration:0.1
                         animations:^{
            topNavigationLabel.alpha = 1;
                         }
                         completion:nil];
    }];
}

- (NSDictionary*)getNewDictionaryFromExtraInfoItem:(NSDictionary*)item mainFields:(NSDictionary*)mainFields serverURL:(NSString*)serverURL sec2min:(int)sec2min useBanner:(BOOL)useBanner useIcon:(BOOL)useIcon {
    NSString *label = [NSString stringWithFormat:@"%@", item[mainFields[@"row1"]]];
    NSString *genre = [Utilities getStringFromItem:item[mainFields[@"row2"]]];
    NSString *year = [Utilities getYearFromItem:item[mainFields[@"row3"]]];
    NSString *runtime = [Utilities getTimeFromItem:item[mainFields[@"row4"]] sec2min:sec2min];
    NSString *rating = [Utilities getRatingFromItem:item[mainFields[@"row5"]]];
    NSString *thumbnailPath = [Utilities getThumbnailFromDictionary:item useBanner:useBanner useIcon:useIcon];
    NSDictionary *art = item[@"art"];
    NSString *clearlogo = [Utilities getClearArtFromDictionary:art type:@"clearlogo"];
    NSString *clearart = [Utilities getClearArtFromDictionary:art type:@"clearart"];
    NSString *stringURL = [Utilities formatStringURL:thumbnailPath serverURL:serverURL];
    NSString *fanartURL = [Utilities formatStringURL:item[@"fanart"] serverURL:serverURL];
    if (!stringURL.length) {
        stringURL = [Utilities getItemIconFromDictionary:item];
    }
    
    id row11 = item[mainFields[@"row11"]] ?: @0;
    NSString *row11key = mainFields[@"row11"] ?: @"";
    
    id row7 = item[mainFields[@"row7"]] ?: @0;
    NSString *row7key = mainFields[@"row7"] ?: @"";

    NSDictionary *newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                             @(albumView), @"fromAlbumView",
                             @(episodesView), @"fromEpisodesView",
                             clearlogo, @"clearlogo",
                             clearart, @"clearart",
                             label, @"label",
                             genre, @"genre",
                             stringURL, @"thumbnail",
                             fanartURL, @"fanart",
                             runtime, @"runtime",
                             row7, row7key,
                             item[mainFields[@"row6"]], mainFields[@"row6"],
                             item[mainFields[@"row8"]], mainFields[@"row8"],
                             year, @"year",
                             rating, @"rating",
                             mainFields[@"playlistid"], @"playlistid",
                             mainFields[@"row8"], @"family",
                             [Utilities getNumberFromItem:item[mainFields[@"row9"]]], mainFields[@"row9"],
                             item[mainFields[@"row10"]], mainFields[@"row10"],
                             row11, row11key,
                             item[mainFields[@"row12"]], mainFields[@"row12"],
                             item[mainFields[@"row13"]], mainFields[@"row13"],
                             item[mainFields[@"row14"]], mainFields[@"row14"],
                             item[mainFields[@"row15"]], mainFields[@"row15"],
                             item[mainFields[@"row16"]], mainFields[@"row16"],
                             item[mainFields[@"row17"]], mainFields[@"row17"],
                             item[mainFields[@"row18"]], mainFields[@"row18"],
                             item[mainFields[@"row19"]], mainFields[@"row19"],
                             item[mainFields[@"row20"]], mainFields[@"row20"],
                             nil];
    return newItem;
}

- (NSMutableDictionary*)getNewDictionaryFromItem:(NSDictionary*)item mainFields:(NSDictionary*)mainFields serverURL:(NSString*)serverURL sec2min:(int)sec2min useBanner:(BOOL)useBanner useIcon:(BOOL)useIcon {
    NSString *label = [NSString stringWithFormat:@"%@", item[mainFields[@"row1"]]];
    NSString *genre = [Utilities getStringFromItem:item[mainFields[@"row2"]]];
    NSString *year = [Utilities getYearFromItem:item[mainFields[@"row3"]]];
    NSString *runtime = [Utilities getTimeFromItem:item[mainFields[@"row4"]] sec2min:sec2min];
    NSString *rating = [Utilities getRatingFromItem:item[mainFields[@"row5"]]];
    NSString *thumbnailPath = [Utilities getThumbnailFromDictionary:item useBanner:NO useIcon:recordingListView];
    NSString *bannerPath = [Utilities getThumbnailFromDictionary:item useBanner:YES useIcon:recordingListView];
    NSString *stringURL = [Utilities formatStringURL:thumbnailPath serverURL:serverURL];
    NSString *bannerURL = [Utilities formatStringURL:bannerPath serverURL:serverURL];
    NSString *fanartURL = [Utilities formatStringURL:item[@"fanart"] serverURL:serverURL];
    if (!stringURL.length) {
        stringURL = [Utilities getItemIconFromDictionary:item];
    }
    NSString *row7key = mainFields[@"row7"] ?: @"none";
    NSString *row7obj = mainFields[@"row7"] ? [NSString stringWithFormat:@"%@", item[mainFields[@"row7"]]] : @"";
    
    NSString *seasonNumber = [NSString stringWithFormat:@"%@", item[mainFields[@"row10"]]];
    NSString *family = [NSString stringWithFormat:@"%@", mainFields[@"row8"]];
    
    NSString *row19key = mainFields[@"row19"] ?: @"episode";
    id row19obj = @"";
    if ([item[mainFields[@"row19"]] isKindOfClass:[NSDictionary class]]) {
        row19obj = [item[mainFields[@"row19"]] mutableCopy];
    }
    else if ([row19key isEqualToString:@"tag"]) {
        row19obj = [Utilities getStringFromItem:item[@"label"]];
    }
    else {
        row19obj = [NSString stringWithFormat:@"%@", item[mainFields[@"row19"]]];
    }
    id row13key = mainFields[@"row13"];
    id row13obj = [row13key isEqualToString:@"options"] ? (item[row13key] ?: @"") : item[row13key];
    
    id row14key = mainFields[@"row14"];
    id row14obj = [row14key isEqualToString:@"allowempty"] ? (item[row14key] ?: @"") : item[row14key];
    
    id row15key = mainFields[@"row15"];
    id row15obj = [row15key isEqualToString:@"addontype"] ? (item[row15key] ?: @"") : item[row15key];
    
    NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 label, @"label",
                                 genre, @"genre",
                                 stringURL, @"thumbnail",
                                 fanartURL, @"fanart",
                                 bannerURL, @"banner",
                                 runtime, @"runtime",
                                 seasonNumber, @"season",
                                 row19obj, row19key,
                                 family, @"family",
                                 item[mainFields[@"row6"]], mainFields[@"row6"],
                                 item[mainFields[@"row8"]], mainFields[@"row8"],
                                 year, @"year",
                                 rating, @"rating",
                                 mainFields[@"playlistid"], @"playlistid",
                                 row7obj, row7key,
                                 item[mainFields[@"row9"]], mainFields[@"row9"],
                                 item[mainFields[@"row10"]], mainFields[@"row10"],
                                 item[mainFields[@"row11"]], mainFields[@"row11"],
                                 item[mainFields[@"row12"]], mainFields[@"row12"],
                                 row13obj, row13key,
                                 row14obj, row14key,
                                 row15obj, row15key,
                                 item[mainFields[@"row16"]], mainFields[@"row16"],
                                 item[mainFields[@"row17"]], mainFields[@"row17"],
                                 item[mainFields[@"row18"]], mainFields[@"row18"],
                                 item[mainFields[@"row20"]], mainFields[@"row20"],
                                 nil];
    return newDict;
}

- (CGPoint)getGlobalSearchThumbsize:(NSDictionary*)item {
    CGPoint thumbSize = CGPointMake(DEFAULT_THUMB_WIDTH, DEFAULT_ROW_HEIGHT);
    if ([item[@"family"] isEqualToString:@"movieid"] ||
        [item[@"family"] isEqualToString:@"setid"] ||
        [item[@"family"] isEqualToString:@"musicvideoid"] ||
        [item[@"family"] isEqualToString:@"tvshowid"]) {
        thumbSize.x = DEFAULT_THUMB_WIDTH;
        thumbSize.y = PORTRAIT_ROW_HEIGHT;
    }
    return thumbSize;
}

- (NSString*)getGlobalSearchThumb:(NSDictionary*)item {
    NSString *thumb = @"nocover_filemode";
    if ([item[@"family"] isEqualToString:@"movieid"]) {
        thumb = @"nocover_movies";
    }
    else if ([item[@"family"] isEqualToString:@"setid"]) {
        thumb = @"nocover_movie_sets";
    }
    else if ([item[@"family"] isEqualToString:@"tvshowid"]) {
        thumb = @"nocover_tvshows_episode";
    }
    else if ([item[@"family"] isEqualToString:@"musicvideoid"]) {
        thumb = @"nocover_music";
    }
    else if ([item[@"family"] isEqualToString:@"artistid"]) {
        thumb = @"nocover_artist";
    }
    else if ([item[@"family"] isEqualToString:@"albumid"]) {
        thumb = @"nocover_music";
    }
    else if ([item[@"family"] isEqualToString:@"songid"]) {
        thumb = @"nocover_music";
    }
    return thumb;
}

- (NSArray*)getGlobalSearchLookup:(id)item {
    NSArray *lookup;
    if ([item[@"family"] isEqualToString:@"albumid"]) {
        lookup = AppDelegate.instance.globalSearchMenuLookup[GLOBALSEARCH_INDEX_ALBUMS];
    }
    else if ([item[@"family"] isEqualToString:@"artistid"]) {
        lookup = AppDelegate.instance.globalSearchMenuLookup[GLOBALSEARCH_INDEX_ARTISTS];
    }
    else if ([item[@"family"] isEqualToString:@"songid"]) {
        lookup = AppDelegate.instance.globalSearchMenuLookup[GLOBALSEARCH_INDEX_SONGS];
    }
    else if ([item[@"family"] isEqualToString:@"movieid"]) {
        lookup = AppDelegate.instance.globalSearchMenuLookup[GLOBALSEARCH_INDEX_MOVIES];
    }
    else if ([item[@"family"] isEqualToString:@"setid"]) {
        lookup = AppDelegate.instance.globalSearchMenuLookup[GLOBALSEARCH_INDEX_MOVIESETS];
    }
    else if ([item[@"family"] isEqualToString:@"musicvideoid"]) {
        lookup = AppDelegate.instance.globalSearchMenuLookup[GLOBALSEARCH_INDEX_MUSICVIDEOS];
    }
    else if ([item[@"family"] isEqualToString:@"tvshowid"]) {
        lookup = AppDelegate.instance.globalSearchMenuLookup[GLOBALSEARCH_INDEX_TVSHOWS];
    }
    return lookup;
}

- (mainMenu*)getMainMenu:(id)item {
    mainMenu *menuItem = self.detailItem;
    if (globalSearchView) {
        NSArray *lookup = [self getGlobalSearchLookup:item];
        if (lookup.count > 0) {
            menuItem = lookup[0];
        }
    }
    return menuItem;
}

- (int)getActiveTab:(id)item {
    int activeTab = chosenTab;
    if (globalSearchView) {
        NSArray *lookup = [self getGlobalSearchLookup:item];
        if (lookup.count > 1) {
            activeTab = [lookup[1] intValue];
        }
    }
    return activeTab;
}

- (void)setIndexViewVisibility {
    // Only show the collection view index, if there are valid index titles to show
    self.indexView.hidden = self.indexView.indexTitles.count <= 1;
}

- (NSDictionary*)getItemFromIndexPath:(NSIndexPath*)indexPath {
    NSDictionary *item;
    if ([self doesShowSearchResults] && !useSectionInSearchResults) {
        if (indexPath.row < self.filteredListContent.count) {
            item = self.filteredListContent[indexPath.row];
        }
    }
    else {
        if (indexPath.section < self.sectionArray.count) {
            if (indexPath.row < [self.sections[self.sectionArray[indexPath.section]] count]) {
                item = self.sections[self.sectionArray[indexPath.section]][indexPath.row];
            }
        }
    }
    return item;
}

- (BOOL)wasSeasonPlayed:(NSInteger)section {
    BOOL seasonWasPlayed = YES;
    if (section < self.sectionArray.count) {
        for (NSDictionary *episode in self.sections[sectionArray[section]]) {
            if ([episode[@"playcount"] intValue] == 0) {
                seasonWasPlayed = NO;
                break;
            }
        }
    }
    return seasonWasPlayed;
}

- (void)updatePlaycount {
    if (tvshowsView) {
        // In tvshowsview we need to sync the TV Shows to retrieve playcount and to update the watched overlays.
        [self startRetrieveDataWithRefresh:YES];
    }
    else if (episodesView) {
        // In episodesView we do only want to reloadData to keep the section closed/opened in their current state.
        [dataList reloadData];
    }
}

- (NSString*)getAmountOfSearchResultsString {
    NSString *results = @"";
    NSUInteger numResult = self.filteredListContent.count;
    if (numResult > 0) {
        if (numResult > 1) {
            // Keep cast to (int) as "%d" is used for many translated languages
            results = LOCALIZED_STR_ARGS(@"%d results", (int)numResult);
        }
        else {
            results = LOCALIZED_STR(@"1 result");
        }
    }
    return results;
}

- (void)setSearchBar:(UISearchBar*)searchBar toColor:(UIColor*)albumColor {
    UITextField *searchTextField = [self getSearchTextField:searchBar];
    UIColor *lightAlbumColor = [Utilities updateColor:albumColor
                                           lightColor:[Utilities getGrayColor:255 alpha:0.7]
                                            darkColor:[Utilities getGrayColor:0 alpha:0.6]];
    if (searchTextField != nil) {
        UIImageView *iconView = (id)searchTextField.leftView;
        iconView.image = [iconView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        iconView.tintColor = lightAlbumColor;
        searchTextField.textColor = lightAlbumColor;
        searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchController.searchBar.placeholder attributes:@{NSForegroundColorAttributeName: lightAlbumColor}];
    }
    searchBar.backgroundColor = albumColor;
    searchBar.tintColor = lightAlbumColor;
    searchBar.barTintColor = lightAlbumColor;
}

- (void)setViewColor:(UIView*)view image:(UIImage*)image isTopMost:(BOOL)isTopMost label1:(UILabel*)label1 label2:(UILabel*)label2 label3:(UILabel*)label3 label4:(UILabel*)label4 infoButton:(UIButton*)infoButton {
    // Gather average cover color and limit saturation
    UIColor *mainColor = [Utilities averageColor:image inverse:NO autoColorCheck:YES];
    mainColor = [Utilities limitSaturation:mainColor satmax:0.33];
    
    // Create gradient based on average color
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = view.bounds;
    gradient.colors = @[(id)[mainColor CGColor], (id)[[Utilities lighterColorForColor:mainColor] CGColor]];
    [view.layer insertSublayer:gradient atIndex:0];
    
    // Set text/shadow colors
    UIColor *label12Color = [Utilities updateColor:mainColor
                                        lightColor:[Utilities getGrayColor:255 alpha:1.0]
                                         darkColor:[Utilities getGrayColor:0 alpha:1.0]];
    UIColor *label34Color = [Utilities updateColor:mainColor
                                        lightColor:[Utilities getGrayColor:255 alpha:0.8]
                                         darkColor:[Utilities getGrayColor:0 alpha:0.7]];
    UIColor *shadowColor = [Utilities updateColor:mainColor
                                       lightColor:[Utilities getGrayColor:0 alpha:0.3]
                                        darkColor:[Utilities getGrayColor:255 alpha:0.3]];
    
    // Set colors for the different labels
    label1.textColor = label2.textColor = label12Color;
    label3.textColor = label4.textColor = label34Color;
    label1.shadowColor = label2.shadowColor = label3.shadowColor = label4.shadowColor = shadowColor;
    
    // Set color of info button
    UIImage *buttonImage = [Utilities colorizeImage:[UIImage imageNamed:@"table_arrow_right"] withColor:label34Color];
    [infoButton setImage:buttonImage forState:UIControlStateNormal];
    
    // Only the top most item shall define albumcolor, searchbar tint and navigationbar tint
    if (isTopMost) {
        albumColor = mainColor;
        [self setSearchBar:self.searchController.searchBar toColor:albumColor];
        [self setSearchBar:(UISearchBar*)dataList.tableHeaderView toColor:albumColor];
        self.navigationController.navigationBar.tintColor = [Utilities lighterColorForColor:albumColor];
    }
}

- (BOOL)doesShowSearchResults {
    BOOL result = NO;
    if (@available(iOS 13.0, *)) {
        result = self.searchController.showsSearchResultsController;
    }
    else {
        // Fallback on earlier versions
        result = (self.filteredListContent.count > 0);
    }
    return result;
}

- (UITextField*)getSearchTextField {
    return [self getSearchTextField:self.searchController.searchBar];
}

- (UITextField*)getSearchTextField:(UISearchBar*)searchBar {
    UITextField *textfield = nil;
    if (@available(iOS 13.0, *)) {
        textfield = searchBar.searchTextField;
    }
    else {
        textfield = [searchBar valueForKey:@"searchField"];
    }
    return textfield;
}

- (void)setGridListButtonImage:(BOOL)isGridView {
    NSString *imgName = isGridView ? @"st_view_grid" : @"st_view_list";
    UIImage *image = [Utilities colorizeImage:[UIImage imageNamed:imgName] withColor:ICON_TINT_COLOR];
    [button6 setBackgroundImage:image forState:UIControlStateNormal];
}

- (void)setSortButtonImage:(NSString*)sortOrder {
    NSString *imgName = [sortOrder isEqualToString:@"descending"] ? @"st_sort_desc" : @"st_sort_asc";
    UIImage *image = [Utilities colorizeImage:[UIImage imageNamed:imgName] withColor:ICON_TINT_COLOR];
    [button7 setBackgroundImage:image forState:UIControlStateNormal];
}

- (void)setButtonViewContent:(int)activeTab {
    mainMenu *menuItem = self.detailItem;
    NSDictionary *methods = menuItem.mainMethod[chosenTab];
    NSDictionary *parameters = menuItem.mainParameters[chosenTab];
    
    // Build basic button list
    [self buildButtons:activeTab];
    
    // Show grid/list button when grid view is possible
    button6.hidden = [self collectionViewCanBeEnabled] ? NO : YES;
    
    // Set up sorting
    sortMethodIndex = -1;
    sortMethodName = nil;
    sortAscDesc = nil;
    [self setUpSort:methods parameters:parameters];
    
    // Show sort button when sorting is possible
    button7.hidden = parameters[@"available_sort_methods"] ? NO : YES;
    
    [self hideButtonListWhenEmpty];
}

- (void)setViewInset:(UIScrollView*)scrollView bottom:(CGFloat)bottomInset {
    UIEdgeInsets viewInsets = scrollView.contentInset;
    viewInsets.bottom = bottomInset;
    scrollView.contentInset = viewInsets;
    scrollView.scrollIndicatorInsets = viewInsets;
}

- (void)hideButtonList:(BOOL)hide {
    if (hide) {
        buttonsView.hidden = YES;
        [self setViewInset:dataList bottom:0];
        [self setViewInset:collectionView bottom:0];
    }
    else {
        buttonsView.hidden = NO;
        CGFloat bottomInset = buttonsViewBgToolbar.frame.size.height;
        [self setViewInset:dataList bottom:bottomInset];
        [self setViewInset:collectionView bottom:bottomInset];
    }
}

- (void)hideButtonListWhenEmpty {
    // Hide the toolbar when no button is shown at all
    BOOL hide = button1.hidden && button2.hidden && button3.hidden && button4.hidden &&
                button5.hidden && button6.hidden && button7.hidden;
    [self hideButtonList:hide];
}

- (void)toggleOpen:(UITapGestureRecognizer*)sender {
    [self.searchController.searchBar resignFirstResponder];
    [self.searchController setActive:NO];
    NSInteger section = [sender.view tag];
    
    // Toggle the section's state (open/close)
    BOOL expandSection = ![self.sectionArrayOpen[section] boolValue];
    self.sectionArrayOpen[section] = @(expandSection);
    
    // Build the section content
    NSInteger countEpisodes = [self.sections[self.sectionArray[section]] count];
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (NSInteger i = 0; i < countEpisodes; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
    }
    
    // Add/remove the section content
    UIButton *toggleButton = (UIButton*)[sender.view viewWithTag:SEASON_VIEW_CELL_TOGGLE];
    if (expandSection) {
        [dataList performBatchUpdates:^{
            [dataList insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        } completion:nil];
    }
    else {
        [dataList performBatchUpdates:^{
            [dataList deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        } completion:nil];
    }
    toggleButton.selected = expandSection;
    
    // Refresh layout (moves section header to top when expanding any season or when toggling the first season)
    int visibleRows = 0;
    for (int i = 0; i < section; i++) {
        visibleRows += [dataList numberOfRowsInSection:i];
    }
    int insetToMoveSectionToTop = iOSYDelta + section * albumViewHeight + visibleRows * cellHeight;
    if (expandSection || section == 0) {
        // Moves inset to show current section on top
        [dataList setContentOffset:CGPointMake(0, insetToMoveSectionToTop) animated:YES];
    }
}

- (void)goBack:(id)sender {
    if (IS_IPHONE) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationEnableStackPan" object:nil];
    }
}

- (void)layoutTVShowCell:(UIView*)cell useDefaultThumb:(BOOL)useFallback imgView:(UIImageView*)imgView {
    // Exception handling for TVShow banner view
    if (tvshowsView) {
        // First tab shows the banner
        if (chosenTab == 0) {
            // When not in grid and not in fullscreen view
            if (!enableCollectionView && !stackscrollFullscreen) {
                // If loaded, we use a dark background
                if (!useFallback) {
                    cell.backgroundColor = SYSTEMGRAY6_DARKMODE;
                }
                // If not loaded, use default background color and poster dimensions for default thumb
                else {
                    cell.backgroundColor = [Utilities getSystemGray6];
                }
            }
            // When in grid or fullscreen view
            else {
                cell.backgroundColor = SYSTEMGRAY6_DARKMODE;
            }
        }
        // Other tabs (e.g. list of episodes) use default layout
        else {
            if (enableCollectionView) {
                cell.backgroundColor = SYSTEMGRAY6_DARKMODE;
            }
            else {
                cell.backgroundColor = [Utilities getSystemGray6];
            }
        }
        if ([cell isKindOfClass:[UITableViewCell class]]) {
            [(UITableViewCell*)cell contentView].backgroundColor = cell.backgroundColor;
        }
    }
}

- (void)setCellImageView:(UIImageView*)imgView cell:(UIView*)cell dictItem:(NSDictionary*)item url:(NSString*)stringURL size:(CGSize)viewSize defaultImg:(NSString*)displayThumb {
    if (viewSize.width == 0 || viewSize.height == 0) {
        return;
    }
    if ([item[@"family"] isEqualToString:@"channelid"] ||
        [item[@"family"] isEqualToString:@"recordingid"] ||
        [item[@"family"] isEqualToString:@"type"]) {
        imgView.contentMode = UIViewContentModeScaleAspectFit;
    }
    BOOL isOnPVR = [item[@"path"] hasPrefix:@"pvr:"];
    [Utilities applyRoundedEdgesView:imgView];
    // In few cases stringURL does not hold an URL path but a loadable icon name. In this case
    // ensure sd_setImageWithURL falls back to this icon.
    if (stringURL.length) {
        if ([UIImage imageNamed:stringURL]) {
            displayThumb = stringURL;
            stringURL = @"";
        }
    }
    if (stringURL.length) {
        __auto_type __weak weakImageView = imgView;
        [imgView sd_setImageWithURL:[NSURL URLWithString:stringURL]
                   placeholderImage:[UIImage imageNamed:displayThumb]
                            options:SDWebImageScaleToNativeSize
                           progress:nil
                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *url) {
            // Only set the logo background, if the attempt to load it was successful (image != nil).
            // This avoids a possibly wrong background for a default thumb.
            if (image && (channelListView || channelGuideView || recordingListView || isOnPVR)) {
                [Utilities setLogoBackgroundColor:weakImageView mode:logoBackgroundMode];
            }
            // Special handling for TV Show cells
            [self layoutTVShowCell:cell useDefaultThumb:(!image || error) imgView:weakImageView];
        }];
    }
    else {
        imgView.image = [UIImage imageNamed:displayThumb];
        // Special handling for TV Show cells, this is already in default thumb state
        [self layoutTVShowCell:cell useDefaultThumb:YES imgView:imgView];
    }
}

- (NSString*)getTimerDefaultThumb:(id)item {
    if (item[@"isreminder"]) {
        return [item[@"isreminder"] boolValue] ? @"nocover_reminder" : @"nocover_recording";
    }
    return defaultThumb;
}

#pragma mark - Tabbar management

- (void)showMore {
    if ([self doesShowSearchResults] || self.searchController.isActive) {
        [self.searchController setActive:NO];
    }
    mainMenu *menuItem = self.detailItem;
    self.indexView.hidden = YES;
    button6.hidden = YES;
    button7.hidden = YES;
    [Utilities alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
    [activityIndicatorView startAnimating];
    NSArray *buttonsIB = @[button1, button2, button3, button4, button5];
    if (chosenTab < buttonsIB.count) {
        [buttonsIB[chosenTab] setSelected:NO];
    }
    chosenTab = MAX_NORMAL_BUTTONS;
    [buttonsIB[chosenTab] setSelected:YES];
    [Utilities AnimView:activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:viewWidth];
    int i;
    NSInteger count = menuItem.mainParameters.count;
    NSMutableArray *moreMenu = [NSMutableArray new];
    NSInteger numIcons = menuItem.mainButtons.count;
    for (i = MAX_NORMAL_BUTTONS; i < count; i++) {
        NSString *icon = @"";
        if (i < numIcons) {
            icon = menuItem.mainButtons[i];
        }
        [moreMenu addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [NSString stringWithFormat:@"%@", menuItem.mainParameters[i][@"morelabel"]], @"label",
          icon, @"icon",
          nil]];
    }
    if (moreItemsViewController == nil) {
        moreItemsViewController = [[MoreItemsViewController alloc] initWithFrame:CGRectMake(dataList.bounds.size.width, 0, dataList.bounds.size.width, dataList.bounds.size.height) mainMenu:moreMenu];
        moreItemsViewController.view.backgroundColor = UIColor.clearColor;
        UIEdgeInsets tableViewInsets = UIEdgeInsetsZero;
        tableViewInsets.bottom = buttonsViewBgToolbar.frame.size.height;
        moreItemsViewController.tableView.contentInset = tableViewInsets;
        moreItemsViewController.tableView.scrollIndicatorInsets = tableViewInsets;
        [moreItemsViewController.tableView setContentOffset:CGPointMake(0, - tableViewInsets.top) animated:NO];
        [maskView insertSubview:moreItemsViewController.view aboveSubview:dataList];
    }

    [Utilities AnimView:moreItemsViewController.view AnimDuration:0.3 Alpha:1.0 XPos:0];
    NSString *labelText = LOCALIZED_STR_ARGS(@"More (%d)", (int)(count - MAX_NORMAL_BUTTONS));
    [self checkFullscreenButton:YES];
    [self setFilternameLabel:labelText];
    [activityIndicatorView stopAnimating];
}

- (void)handleTabHasChanged:(NSNotification*)notification {
    mainMenu *menuItem = self.detailItem;
    NSArray *buttons = menuItem.mainButtons;
    if (!buttons.count) {
        return;
    }
    NSIndexPath *choice = notification.object;
    NSInteger selectedIdx = MAX_NORMAL_BUTTONS + choice.row;
    [self handleChangeTab:(int)selectedIdx fromMoreItems:YES];
}

- (void)changeViewMode:(ViewModes)newViewMode forceRefresh:(BOOL)refresh {
    [activityIndicatorView startAnimating];
    if (!refresh) {
            [UIView transitionWithView:activeLayoutView
                              duration:0.2
                               options:UIViewAnimationOptionBeginFromCurrentState
                            animations:^{
                                activeLayoutView.alpha = 1.0;
                                CGRect frame = activeLayoutView.frame;
                                frame.origin.x = viewWidth;
                                frame.origin.y = 0;
                                activeLayoutView.frame = frame;
                            }
                            completion:^(BOOL finished) {
                                [self changeViewMode:newViewMode];
                            }];
    }
    else {
        [self changeViewMode:newViewMode];
    }
}

- (void)changeViewMode:(ViewModes)newViewMode {
    [self.richResults removeAllObjects];
    [self.sections removeAllObjects];
    [activeLayoutView reloadData];
    NSPredicate *filter;
    if (!albumView) {
        switch (newViewMode) {
            case ViewModeNotListened:
            case ViewModeUnwatched:
                filter = [NSPredicate predicateWithFormat:@"playcount.intValue == 0"];
                self.richResults = [[storeRichResults filteredArrayUsingPredicate:filter] mutableCopy];
                break;

            case ViewModeListened:
            case ViewModeWatched:
                filter = [NSPredicate predicateWithFormat:@"playcount.intValue > 0"];
                self.richResults = [[storeRichResults filteredArrayUsingPredicate:filter] mutableCopy];
                break;
                
            case ViewModeDefaultArtists:
            case ViewModeAlbumArtists:
            case ViewModeSongArtists:
            case ViewModeDefault:
                self.richResults = [storeRichResults mutableCopy];
                break;
                
            default:
                NSAssert(NO, @"changeViewMode: unknown mode %ld", newViewMode);
                break;
        }
    }
    [self indexAndDisplayData];
    
}

- (void)configureLibraryView {
    if (enableCollectionView) {
        collectionView.contentInset = dataList.contentInset;
        dataList.delegate = nil;
        dataList.dataSource = nil;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        dataList.scrollsToTop = NO;
        dataList.tableHeaderView.hidden = YES;
        collectionView.scrollsToTop = YES;
        activeLayoutView = (UITableView*)collectionView;
        
        [self setSearchBar:self.searchController.searchBar toDark:YES];
    }
    else {
        dataList.delegate = self;
        dataList.dataSource = self;
        collectionView.delegate = nil;
        collectionView.dataSource = nil;
        dataList.scrollsToTop = YES;
        dataList.tableHeaderView.hidden = NO;
        collectionView.scrollsToTop = NO;
        activeLayoutView = dataList;
        
        [self setSearchBar:self.searchController.searchBar toDark:NO];
    }
    [self initIndexView];
    [self buildIndexView];
    [self setIndexViewVisibility];
    [self setGridListButtonImage:enableCollectionView];
}

- (void)setUpSort:(NSDictionary*)methods parameters:(NSDictionary*)parameters {
    NSDictionary *sortDictionary = parameters[@"available_sort_methods"];
    sortMethodName = [self getCurrentSortMethod:methods withParameters:parameters];
    NSUInteger foundIndex = sortDictionary ? [sortDictionary[@"method"] indexOfObject:sortMethodName] : NSNotFound;
    if (foundIndex != NSNotFound) {
        sortMethodIndex = foundIndex;
    }
    sortAscDesc = [self getCurrentSortAscDesc:methods withParameters:parameters];
}

- (IBAction)changeTab:(id)sender {
    NSInteger newChoosedTab = [sender tag];
    [self handleChangeTab:(int)newChoosedTab fromMoreItems:NO];
}

- (void)handleChangeTab:(int)newChoosedTab fromMoreItems:(BOOL)fromMoreItems {
    if ([self doesShowSearchResults] || self.searchController.isActive) {
        [self.searchController setActive:NO];
    }
    if (!activityIndicatorView.hidden) {
        return;
    }
    [activeLayoutView setUserInteractionEnabled:YES];
    [activeLayoutView.pullToRefreshView stopAnimating];
    
    mainMenu *menuItem = self.detailItem;
    NSDictionary *methods = nil;
    NSDictionary *parameters = nil;
    NSMutableDictionary *mutableParameters = nil;
    NSMutableArray *mutableProperties = nil;
    BOOL refresh = NO;
    
    // Read new tab index
    int numTabs = (int)menuItem.mainMethod.count;
    newChoosedTab = newChoosedTab % numTabs;
    
    // Bring up MoreItemsViewContoller
    if (newChoosedTab == MAX_NORMAL_BUTTONS && numTabs > MAX_NORMAL_BUTTONS + 1 && !fromMoreItems) {
        [self showMore];
        return;
    }
    
    // Handle modes (pressing same tab) or changed tabs
    if (newChoosedTab == chosenTab && !fromMoreItems) {
        // Read relevant data from configuration
        methods = menuItem.mainMethod[chosenTab];
        parameters = menuItem.mainParameters[chosenTab];
        mutableParameters = [parameters[@"parameters"] mutableCopy];
        mutableProperties = [parameters[@"parameters"][@"properties"] mutableCopy];
        
        NSInteger num_modes = [menuItem.filterModes[chosenTab][@"modes"] count];
        if (!num_modes) {
            return;
        }
        filterModeIndex = (filterModeIndex + 1) % num_modes;
        NSArray *buttonsIB = @[button1, button2, button3, button4, button5];
        [buttonsIB[chosenTab] setImage:[UIImage imageNamed:menuItem.filterModes[chosenTab][@"icons"][filterModeIndex]] forState:UIControlStateSelected];
        
        // Artist filter is inactive. We simply filter results via helper function changeViewMode and return.
        filterModeType = [menuItem.filterModes[chosenTab][@"modes"][filterModeIndex] intValue];
        if (!(filterModeType == ViewModeAlbumArtists ||
              filterModeType == ViewModeSongArtists ||
              filterModeType == ViewModeDefaultArtists)) {
            [self changeViewMode:filterModeType forceRefresh:NO];
            return;
        }
    }
    else {
        filterModeIndex = 0;
        filterModeType = ViewModeDefault;
        NSArray *buttonsIB = @[button1, button2, button3, button4, button5];
        if (chosenTab < buttonsIB.count) {
            [buttonsIB[chosenTab] setImage:[UIImage imageNamed:@"blank"] forState:UIControlStateSelected];
            [buttonsIB[chosenTab] setSelected:NO];
        }
        else {
            [buttonsIB.lastObject setSelected:NO];
        }
        chosenTab = newChoosedTab;
        if (chosenTab < buttonsIB.count) {
            [buttonsIB[chosenTab] setSelected:YES];
        }
        // Read relevant data from configuration (important: new value for chosenTab)
        methods = menuItem.mainMethod[chosenTab];
        parameters = menuItem.mainParameters[chosenTab];
        mutableParameters = [parameters[@"parameters"] mutableCopy];
        mutableProperties = [parameters[@"parameters"][@"properties"] mutableCopy];
    }
    self.indexView.indexTitles = nil;
    self.indexView.hidden = YES;
    startTime = 0;
    [countExecutionTime invalidate];
    if (longTimeout != nil) {
        [longTimeout removeFromSuperview];
        longTimeout = nil;
    }
    [Utilities AnimView:moreItemsViewController.view AnimDuration:0.3 Alpha:1.0 XPos:viewWidth];
    
    [activityIndicatorView startAnimating];

    if ([parameters[@"numberOfStars"] intValue] > 0) {
        numberOfStars = [parameters[@"numberOfStars"] intValue];
    }

    BOOL newEnableCollectionView = [self collectionViewIsEnabled];
    [self setButtonViewContent:chosenTab];
    [self checkDiskCache];
    
    [Utilities SetView:activeLayoutView Alpha:1.0 XPos:viewWidth];
    
    enableCollectionView = newEnableCollectionView;
    recentlyAddedView = [parameters[@"collectionViewRecentlyAdded"] boolValue];
    activeLayoutView.contentOffset = activeLayoutView.contentOffset;
    [self checkFullscreenButton:NO];
    [self addExtraProperties:mutableProperties newParams:mutableParameters params:parameters];
    if (!tvshowsView || [Utilities getPreferTvPosterMode]) {
        [self setSearchBar:self.searchController.searchBar toDark:NO];
    }
    if (methods[@"method"] != nil) {
        [self retrieveData:methods[@"method"] parameters:mutableParameters sectionMethod:methods[@"extra_section_method"] sectionParameters:parameters[@"extra_section_parameters"] resultStore:self.richResults extraSectionCall:NO refresh:refresh];
    }
    else {
        [activityIndicatorView stopAnimating];
        [Utilities AnimView:activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
}

#pragma mark - Library item didSelect

- (void)viewChild:(NSIndexPath*)indexPath item:(NSDictionary*)item displayPoint:(CGPoint)point {
    selectedIndexPath = indexPath;
    mainMenu *menuItem = [self getMainMenu:item];
    int activeTab = [self getActiveTab:item];
    NSArray *sheetActions = menuItem.sheetActions[activeTab];
    NSMutableDictionary *parameters = menuItem.subItem.mainParameters[activeTab];
    NSDictionary *mainFields = menuItem.mainFields[activeTab];
    
    NSNumber *libraryRowHeight = parameters[@"rowHeight"] ?: @(menuItem.subItem.rowHeight);
    NSNumber *libraryThumbWidth = parameters[@"thumbWidth"] ?: @(menuItem.subItem.thumbWidth);
    
    if (parameters[@"parameters"][@"properties"] != nil) { // CHILD IS LIBRARY MODE
        NSString *key = @"null";
        if (item[mainFields[@"row15"]] != nil) {
            key = mainFields[@"row15"];
        }
        id objKey = mainFields[@"row6"];
        id obj = item[objKey];
        if (AppDelegate.instance.serverVersion > 11 && ![parameters[@"disableFilterParameter"] boolValue]) {
            NSDictionary *currentParams = menuItem.mainParameters[activeTab];
            obj = [NSDictionary dictionaryWithObjectsAndKeys:
                   obj, objKey,
                   currentParams[@"parameters"][@"filter"][parameters[@"combinedFilter"]], parameters[@"combinedFilter"],
                   nil];
            objKey = @"filter";
        }
        NSMutableDictionary *newSectionParameters = [NSMutableDictionary dictionary];
        if (parameters[@"extra_section_parameters"] != nil) {
            newSectionParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    obj, objKey,
                                    parameters[@"extra_section_parameters"][@"properties"], @"properties",
                                    parameters[@"extra_section_parameters"][@"sort"], @"sort",
                                    item[mainFields[@"row15"]], key,
                                    nil];
        }
        NSMutableDictionary *pvrExtraInfo = [NSMutableDictionary dictionary];
        if ([item[@"family"] isEqualToString:@"channelid"]) {
            pvrExtraInfo[@"channel_name"] = item[@"label"];
            pvrExtraInfo[@"channel_icon"] = item[@"thumbnail"];
            pvrExtraInfo[@"channelid"] = item[@"channelid"];
        }
        
        NSMutableDictionary *kodiExtrasPropertiesMinimumVersion = [NSMutableDictionary dictionary];
        if (parameters[@"kodiExtrasPropertiesMinimumVersion"]) {
            kodiExtrasPropertiesMinimumVersion = parameters[@"kodiExtrasPropertiesMinimumVersion"];
        }
        NSMutableDictionary *newParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                              [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                               obj, objKey,
                                               parameters[@"parameters"][@"properties"], @"properties",
                                               parameters[@"parameters"][@"sort"], @"sort",
                                               item[mainFields[@"row15"]], key,
                                               nil], @"parameters",
                                              @([parameters[@"disableFilterParameter"] boolValue]), @"disableFilterParameter",
                                              libraryRowHeight, @"rowHeight",
                                              libraryThumbWidth, @"thumbWidth",
                                              parameters[@"label"], @"label",
                                              [NSDictionary dictionaryWithDictionary:parameters[@"itemSizes"]], @"itemSizes",
                                              @([parameters[@"FrodoExtraArt"] boolValue]), @"FrodoExtraArt",
                                              @([parameters[@"enableLibraryCache"] boolValue]), @"enableLibraryCache",
                                              @([parameters[@"enableCollectionView"] boolValue]), @"enableCollectionView",
                                              @([parameters[@"forcePlayback"] boolValue]), @"forcePlayback",
                                              @([parameters[@"forceActionSheet"] boolValue]), @"forceActionSheet",
                                              @([parameters[@"collectionViewRecentlyAdded"] boolValue]), @"collectionViewRecentlyAdded",
                                              pvrExtraInfo, @"pvrExtraInfo",
                                              kodiExtrasPropertiesMinimumVersion, @"kodiExtrasPropertiesMinimumVersion",
                                              parameters[@"extra_info_parameters"], @"extra_info_parameters",
                                              newSectionParameters, @"extra_section_parameters",
                                              [NSString stringWithFormat:@"%@", parameters[@"defaultThumb"]], @"defaultThumb",
                                              parameters[@"watchedListenedStrings"], @"watchedListenedStrings",
                                              nil];
        if (parameters[@"available_sort_methods"] != nil) {
            newParameters[@"available_sort_methods"] = parameters[@"available_sort_methods"];
        }
        if (parameters[@"combinedFilter"]) {
            newParameters[@"combinedFilter"] = parameters[@"combinedFilter"];
        }
        if (parameters[@"parameters"][@"albumartistsonly"]) {
            newParameters[@"parameters"][@"albumartistsonly"] = parameters[@"parameters"][@"albumartistsonly"];
        }
        [self enterSubmenuForItem:item params:newParameters];
    }
    else { // CHILD IS FILEMODE
        NSNumber *filemodeRowHeight = parameters[@"rowHeight"] ?: @FILEMODE_ROW_HEIGHT;
        NSNumber *filemodeThumbWidth = parameters[@"thumbWidth"] ?: @FILEMODE_THUMB_WIDTH;
        if ([item[@"filetype"] length] != 0 && ![item[@"isSources"] boolValue]) { // WE ARE ALREADY IN BROWSING FILES MODE
            if ([item[@"filetype"] isEqualToString:@"directory"]) {
                parameters = menuItem.mainParameters[activeTab];
                NSMutableDictionary *newParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                      [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                       item[mainFields[@"row6"]], @"directory",
                                                       parameters[@"parameters"][@"media"], @"media",
                                                       parameters[@"parameters"][@"sort"], @"sort",
                                                       parameters[@"parameters"][@"file_properties"], @"file_properties",
                                                       nil], @"parameters",
                                                      parameters[@"label"], @"label",
                                                      @"nocover_filemode", @"defaultThumb",
                                                      filemodeRowHeight, @"rowHeight",
                                                      filemodeThumbWidth, @"thumbWidth",
                                                      [NSDictionary dictionaryWithDictionary:parameters[@"itemSizes"]], @"itemSizes",
                                                      @([parameters[@"enableCollectionView"] boolValue]), @"enableCollectionView",
                                                      @([parameters[@"disableFilterParameter"] boolValue]), @"disableFilterParameter",
                                                      nil];
                menuItem.mainLabel = item[@"label"];
                mainMenu *newMenuItem = [menuItem copy];
                newMenuItem.mainParameters[activeTab] = newParameters;
                newMenuItem.chooseTab = activeTab;
                if (IS_IPHONE) {
                    DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
                    detailViewController.detailItem = newMenuItem;
                    [self.navigationController pushViewController:detailViewController animated:YES];
                }
                else {
                    if (stackscrollFullscreen) {
                        [self toggleFullscreen];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:newMenuItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                            [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:NO];
                        });
                    }
                    else {
                        DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:newMenuItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                        [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:NO];
                    }
                }
            }
            else if ([item[@"genre"] isEqualToString:@"file"] ||
                     [item[@"filetype"] isEqualToString:@"file"]) {
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                if (![userDefaults boolForKey:@"song_preference"]) {
                    [self showActionSheet:indexPath sheetActions:sheetActions item:item origin:point];
                }
                else {
                    [self startPlayback:item indexPath:indexPath shuffle:NO];
                }
                [self deselectAtIndexPath:indexPath];
                return;
            }
            else {
                return;
            }
        }
        else { // WE ENTERING FILEMODE
            NSString *fileModeKey = @"directory";
            id objValue = item[mainFields[@"row6"]];
            if ([item[@"family"] isEqualToString:@"sectionid"]) {
                fileModeKey = @"section";
            }
            else if ([item[@"family"] isEqualToString:@"categoryid"]) {
                fileModeKey = @"filter";
                objValue = [NSDictionary dictionaryWithObjectsAndKeys:
                            item[mainFields[@"row6"]], @"category",
                            menuItem.mainParameters[activeTab][@"parameters"][@"section"], @"section",
                            nil];
            }
            else if ([item[@"family"] isEqualToString:@"addonid"]) {
                objValue = [@"plugin://" stringByAppendingString: objValue];
            }
            NSMutableDictionary *newParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                  [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                   objValue, fileModeKey,
                                                   parameters[@"parameters"][@"media"], @"media",
                                                   parameters[@"parameters"][@"sort"], @"sort",
                                                   parameters[@"parameters"][@"file_properties"], @"file_properties",
                                                   nil], @"parameters",
                                                  parameters[@"label"], @"label",
                                                  @"nocover_filemode", @"defaultThumb",
                                                  filemodeRowHeight, @"rowHeight",
                                                  filemodeThumbWidth, @"thumbWidth",
                                                  [NSDictionary dictionaryWithDictionary:parameters[@"itemSizes"]], @"itemSizes",
                                                  @([parameters[@"enableCollectionView"] boolValue]), @"enableCollectionView",
                                                  @([parameters[@"disableFilterParameter"] boolValue]), @"disableFilterParameter",
                                                  nil];
            if ([item[@"family"] isEqualToString:@"sectionid"] || [item[@"family"] isEqualToString:@"categoryid"]) {
                newParameters[@"parameters"][@"level"] = @"expert";
            }
            [self enterSubmenuForItem:item params:newParameters];
        }
    }
}

- (void)didSelectItemAtIndexPath:(NSIndexPath*)indexPath item:(NSDictionary*)item displayPoint:(CGPoint)point {
    [self selectAtIndexPath:indexPath];
    mainMenu *menuItem = [self getMainMenu:item];
    int activeTab = [self getActiveTab:item];
    NSDictionary *methods = menuItem.subItem.mainMethod[activeTab];
    NSMutableArray *sheetActions = [menuItem.sheetActions[activeTab] mutableCopy];
    NSMutableDictionary *parameters = menuItem.mainParameters[activeTab];
    if ([item[@"family"] isEqualToString:@"id"]) {
        if (IS_IPHONE) {
            SettingsValuesViewController *settingsViewController = [[SettingsValuesViewController alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) withItem:item];
            [self.navigationController pushViewController:settingsViewController animated:YES];
        }
        else {
            if (stackscrollFullscreen) {
                [self toggleFullscreen];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    SettingsValuesViewController *iPadSettingsViewController = [[SettingsValuesViewController alloc] initWithFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.bounds.size.height) withItem:item];
                    [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:iPadSettingsViewController invokeByController:self isStackStartView:NO];
                });
            }
            else {
                SettingsValuesViewController *iPadSettingsViewController = [[SettingsValuesViewController alloc] initWithFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.bounds.size.height) withItem:item];
                [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:iPadSettingsViewController invokeByController:self isStackStartView:NO];
            }
        }
    }
    else if ([item[@"family"] isEqualToString:@"type"]) {
        // Selected favourite item is a window type -> activate it
        if ([item[@"type"] isEqualToString:@"window"]) {
            if (item[@"window"] && item[@"windowparameter"]) {
                [self SimpleAction:@"GUI.ActivateWindow"
                            params:@{@"window": item[@"window"], @"parameters": @[item[@"windowparameter"]]}
                           success:LOCALIZED_STR(@"Window activated successfully")
                           failure:LOCALIZED_STR(@"Unable to activate the window")
                 ];
            }
        }
        // Selected favourite item is a script type -> run it
        else if ([item[@"type"] isEqualToString:@"script"]) {
            if (item[@"path"]) {
                [self SimpleAction:@"Addons.ExecuteAddon"
                            params:@{@"addonid": item[@"path"]}
                           success:LOCALIZED_STR(@"Action executed successfully")
                           failure:LOCALIZED_STR(@"Unable to execute the action")
                 ];
            }
        }
        // Selected favourite item is a media type -> play it
        else if ([item[@"type"] isEqualToString:@"media"]) {
            if (item[@"path"]) {
                [self playerOpen:@{@"item": @{@"file": item[@"path"]}} index:indexPath];
            }
        }
        // Selected favourite item is an unknown type -> throw an error
        else {
            NSString *message = [NSString stringWithFormat:@"%@ (type = '%@')", LOCALIZED_STR(@"Cannot do that"), item[@"type"]];
            [Utilities showMessage:message color:ERROR_MESSAGE_COLOR];
        }
        [self deselectAtIndexPath:indexPath];
    }
    else if ([parameters[@"forcePlayback"] boolValue]) {
        [self startPlayback:item indexPath:indexPath shuffle:NO];
    }
    else if (methods[@"method"] != nil && ![parameters[@"forceActionSheet"] boolValue] && !stackscrollFullscreen) {
        // There is a child and we want to show it (only when not in fullscreen)
        [self viewChild:indexPath item:item displayPoint:point];
    }
    else {
        if ([menuItem.showInfo[activeTab] boolValue]) {
            [self showInfo:indexPath menuItem:menuItem item:item tabToShow:activeTab];
        }
        else {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            if (![userDefaults boolForKey:@"song_preference"] || [parameters[@"forceActionSheet"] boolValue]) {
                sheetActions = [self getPlaylistActions:sheetActions item:item params:menuItem.mainParameters[activeTab]];
                selectedIndexPath = indexPath;
                if ([item[@"family"] isEqualToString:@"timerid"] && AppDelegate.instance.serverVersion < 17) {
                    UIAlertController *alertCtrl = [Utilities createAlertOK:@"" message:LOCALIZED_STR(@"-- WARNING --\nKodi API prior Krypton (v17) don't allow timers editing. Use the Kodi GUI for adding, editing and removing timers. Thank you.")];
                    [self presentViewController:alertCtrl animated:YES completion:nil];
                }
                else {
                    [self showActionSheet:indexPath sheetActions:sheetActions item:item origin:point];
                }
            }
            else {
                [self startPlayback:item indexPath:indexPath shuffle:NO];
            }
            [self deselectAtIndexPath:indexPath];
        }
    }
}

- (NSMutableArray*)getPlaylistActions:(NSMutableArray*)sheetActions item:(NSDictionary*)item params:(NSMutableDictionary*)parameters {
    if ([parameters[@"isMusicPlaylist"] boolValue] ||
        [parameters[@"isVideoPlaylist"] boolValue]) { // NOTE: sheetActions objects must be moved outside from there
        if ([sheetActions isKindOfClass:[NSMutableArray class]]) {
            if (![[item[@"file"] pathExtension] isEqualToString:@"xsp"] || AppDelegate.instance.serverVersion <= 11) {
                [sheetActions removeObject:LOCALIZED_STR(@"Play in party mode")];
            }
        }
    }
    return sheetActions;
}

#pragma mark - UICollectionView FlowLayout delegate

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if ((enableCollectionView && self.sectionArray.count > 1 && section > 0) || [self doesShowSearchResults]) {
        return CGSizeMake(dataList.frame.size.width, GRID_SECTION_HEADER_HEIGHT);
    }
    else {
        return CGSizeZero;
    }
}

- (void)setFlowLayoutParams {
    if (![self collectionViewCanBeEnabled]) {
        return;
    }
    if (stackscrollFullscreen) {
        // Calculate the dimensions of the items to match the screen size.
        CGFloat screenwidth = IS_PORTRAIT ? GET_MAINSCREEN_WIDTH : GET_MAINSCREEN_HEIGHT;
        CGFloat numItemsPerRow = screenwidth / fullscreenCellGridWidth;
        int num = round(numItemsPerRow);
        CGFloat newWidth = (screenwidth - (num - 1) * FLOWLAYOUT_FULLSCREEN_MIN_SPACE - 2 * FLOWLAYOUT_FULLSCREEN_INSET) / num;
        
        CGFloat pixelExactWidth = GET_PIXEL_EXACT_SIZE(newWidth);
        CGFloat pixelExactHeight = GET_PIXEL_EXACT_SIZE(fullscreenCellGridHeight * newWidth / fullscreenCellGridWidth);
        flowLayout.itemSize = CGSizeMake(pixelExactWidth, pixelExactHeight);
        if (!recentlyAddedView && !hiddenLabel) {
            flowLayout.minimumLineSpacing = FLOWLAYOUT_FULLSCREEN_LABEL;
        }
        else {
            flowLayout.minimumLineSpacing = FLOWLAYOUT_FULLSCREEN_MIN_SPACE;
        }
        flowLayout.minimumInteritemSpacing = FLOWLAYOUT_FULLSCREEN_MIN_SPACE;
    }
    else {
        flowLayout.itemSize = CGSizeMake(cellGridWidth, cellGridHeight);
        flowLayout.minimumLineSpacing = cellMinimumLineSpacing;
        flowLayout.minimumInteritemSpacing = cellMinimumLineSpacing;
    }
    flowLayout.collectionView.backgroundColor = UIColor.clearColor;
}

#pragma mark - UICollectionView methods

- (void)initCollectionView {
    if (!collectionView) {
        flowLayout = [FloatingHeaderFlowLayout new];
        [flowLayout setSearchBarHeight:self.searchController.searchBar.frame.size.height];
        
        [self setFlowLayoutParams];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        collectionView = [[UICollectionView alloc] initWithFrame:dataList.frame collectionViewLayout:flowLayout];
        collectionView.contentInset = dataList.contentInset;
        collectionView.scrollIndicatorInsets = dataList.scrollIndicatorInsets;
        collectionView.backgroundColor = UIColor.clearColor;
        collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        [collectionView registerClass:[PosterCell class] forCellWithReuseIdentifier:@"posterCell"];
        [collectionView registerClass:[RecentlyAddedCell class] forCellWithReuseIdentifier:@"recentlyAddedCell"];
        [collectionView registerClass:[PosterHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"posterHeaderView"];
        collectionView.autoresizingMask = dataList.autoresizingMask;
        __weak DetailViewController *weakSelf = self;
        [collectionView addPullToRefreshWithActionHandler:^{
            [weakSelf.searchController setActive:NO];
            [weakSelf startRetrieveDataWithRefresh:YES];
            [weakSelf hideButtonListWhenEmpty];
        }];
        [collectionView setShowsPullToRefresh:enableDiskCache];
        collectionView.alwaysBounceVertical = YES;
        [collectionView addSubview:[self createFakeSearchbarInDark:YES]];
        [maskView insertSubview:collectionView belowSubview:buttonsView];
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    if ([self doesShowSearchResults] && !useSectionInSearchResults) {
        return (self.filteredListContent.count > 0) ? 1 : 0;
    }
    else {
        return [self.sections allKeys].count;
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    CGFloat margin = 0;
    if (stackscrollFullscreen) {
        margin = 8;
    }
    if (section == 0) {
        return UIEdgeInsetsMake(CGRectGetHeight(self.searchController.searchBar.frame), margin, 0, margin);
    }
    
    return UIEdgeInsetsMake(0, margin, 0, margin);
}

- (UICollectionReusableView*)collectionView:(UICollectionView*)cView viewForSupplementaryElementOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath {
    static NSString *identifier = @"posterHeaderView";
    PosterHeaderView *headerView = [cView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:identifier forIndexPath:indexPath];
    NSString *sectionHeaderLabel;
    if ([self doesShowSearchResults]) {
        sectionHeaderLabel = [self getAmountOfSearchResultsString];
    }
    else {
        sectionHeaderLabel = [self buildSortInfo:self.sectionArray[indexPath.section]];
    }
    [headerView setHeaderText:sectionHeaderLabel];
    return headerView;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([self doesShowSearchResults] && !useSectionInSearchResults) {
        return self.filteredListContent.count;
    }
    if (episodesView) {
        return ([self.sectionArrayOpen[section] boolValue] ? [self.sections[self.sectionArray[section]] count] : 0);
    }
    return [self.sections[self.sectionArray[section]] count];
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)cView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    NSDictionary *item = [self getItemFromIndexPath:indexPath];
    defaultThumb = [self getTimerDefaultThumb:item];
    NSString *stringURL = item[@"thumbnail"];
    NSString *fanartURL = item[@"fanart"];
    NSString *displayThumb = [NSString stringWithFormat:@"%@_wall", defaultThumb];
    NSString *playcount = [NSString stringWithFormat:@"%@", item[@"playcount"]];
    
    CGFloat cellthumbWidth = cellGridWidth;
    CGFloat cellthumbHeight = cellGridHeight;
    if (stackscrollFullscreen) {
        cellthumbWidth = fullscreenCellGridWidth;
        cellthumbHeight = fullscreenCellGridHeight;
    }
    if (!recentlyAddedView) {
        static NSString *identifier = @"posterCell";
        PosterCell *cell = [cView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        [Utilities applyRoundedEdgesView:cell.contentView];
        cell.posterLabel.text = @"";
        cell.posterLabelFullscreen.text = @"";
        cell.posterLabel.font = [UIFont boldSystemFontOfSize:posterFontSize];
        cell.posterLabelFullscreen.font = [UIFont boldSystemFontOfSize:posterFontSize];
        cell.posterThumbnail.contentMode = UIViewContentModeScaleAspectFill;
        if (stackscrollFullscreen) {
            cell.posterLabelFullscreen.text = [Utilities stripBBandHTML:item[@"label"]];
            cell.labelImageView.hidden = YES;
            cell.posterLabelFullscreen.hidden = NO;
        }
        else {
            cell.posterLabel.text = [Utilities stripBBandHTML:item[@"label"]];
            cell.posterLabelFullscreen.hidden = YES;
        }
        
        if (tvshowsView && chosenTab == 0) {
            defaultThumb = displayThumb = @"nocover_tvshows";
        }
        
        if (channelListView) {
            [cell setIsRecording:[item[@"isrecording"] boolValue]];
        }
        [cell setPosterCellLayoutManually:cell.bounds];
        [self setCellImageView:cell.posterThumbnail cell:cell dictItem:item url:stringURL size:CGSizeMake(cellthumbWidth, cellthumbHeight) defaultImg:displayThumb];
        if (!stringURL.length) {
            cell.posterThumbnail.backgroundColor = SYSTEMGRAY6_DARKMODE;
        }
        // Set label visibility based on setting and current view
        if (hiddenLabel || stackscrollFullscreen) {
            cell.posterLabel.hidden = YES;
            cell.labelImageView.hidden = YES;
            cell.posterLabelFullscreen.hidden = hiddenLabel;
        }
        else {
            cell.posterLabel.hidden = NO;
            cell.labelImageView.hidden = NO;
        }
        // Set "Watched"-icon overlay
        if ([playcount intValue]) {
            [cell setOverlayWatched:YES];
        }
        else {
            [cell setOverlayWatched:NO];
        }
        
        return cell;
    }
    else {
        static NSString *identifier = @"recentlyAddedCell";
        RecentlyAddedCell *cell = [cView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        [Utilities applyRoundedEdgesView:cell.contentView];
        [cell setRecentlyAddedCellLayoutManually:cell.bounds];

        if (stringURL.length) {
            [cell.posterThumbnail sd_setImageWithURL:[NSURL URLWithString:stringURL]
                                    placeholderImage:[UIImage imageNamed:displayThumb]
                                             options:SDWebImageScaleToNativeSize];
        }
        else {
            cell.posterThumbnail.image = [UIImage imageNamed:displayThumb];
        }

        if (fanartURL.length) {
            [cell.posterFanart sd_setImageWithURL:[NSURL URLWithString:fanartURL]
                                 placeholderImage:[UIImage imageNamed:@"blank"]
                                          options:SDWebImageScaleToNativeSize];
        }
        else {
            cell.posterFanart.image = [UIImage imageNamed:@"blank"];
        }
        
        cell.posterLabel.font = [UIFont boldSystemFontOfSize:fanartFontSize + 8];
        cell.posterLabel.text = item[@"label"];
        
        cell.posterGenre.font = [UIFont systemFontOfSize:fanartFontSize + 2];
        cell.posterGenre.text = item[@"genre"];
        
        cell.posterYear.font = [UIFont systemFontOfSize:fanartFontSize];
        cell.posterYear.text = item[@"year"];
        
        // Set label visibility based on setting
        cell.posterLabel.hidden = cell.posterGenre.hidden = cell.posterYear.hidden = hiddenLabel;
        if ([playcount intValue]) {
            [cell setOverlayWatched:YES];
        }
        else {
            [cell setOverlayWatched:NO];
        }
        return cell;
    }
}

- (void)collectionView:(UICollectionView*)cView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    NSDictionary *item = [self getItemFromIndexPath:indexPath];
    UICollectionViewCell *cell = [cView cellForItemAtIndexPath:indexPath];
    CGPoint offsetPoint = [cView contentOffset];
    int rectOriginX = cell.frame.origin.x + cell.frame.size.width / 2;
    int rectOriginY = cell.frame.origin.y + cell.frame.size.height / 2 - offsetPoint.y;
    [self didSelectItemAtIndexPath:indexPath item:item displayPoint:CGPointMake(rectOriginX, rectOriginY)];
}

#pragma mark - BDKCollectionIndexView init

- (void)initSectionNameOverlayView {
    // First create the label and calculate its height for 2 rows
    sectionNameLabel = [[UILabel alloc] init];
    sectionNameLabel.font = [UIFont boldSystemFontOfSize:32];
    sectionNameLabel.numberOfLines = 2;
    sectionNameLabel.textColor = UIColor.whiteColor;
    sectionNameLabel.backgroundColor = UIColor.clearColor;
    sectionNameLabel.textAlignment = NSTextAlignmentCenter;
    sectionNameLabel.frame = CGRectMake(LABEL_PADDING,
                                        VERTICAL_PADDING,
                                        self.view.frame.size.width * 0.75,
                                        2 * ceil(sectionNameLabel.font.lineHeight));
    
    // Then fit the overlayview around it with horizontal and vertical padding
    CGFloat overlayWidth = CGRectGetWidth(sectionNameLabel.frame) + 2 * LABEL_PADDING;
    CGFloat overlayHeight = CGRectGetHeight(sectionNameLabel.frame) + 2 * VERTICAL_PADDING;
    sectionNameOverlayView = [[UIView alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.view.frame) - overlayWidth) / 2,
                                                                      (CGRectGetHeight(self.view.frame) - overlayHeight) / 2,
                                                                      overlayWidth,
                                                                      overlayHeight)];
    sectionNameOverlayView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin);
    sectionNameOverlayView.backgroundColor = INFO_POPOVER_COLOR;
    sectionNameOverlayView.layer.cornerRadius = 12;
    [sectionNameOverlayView addSubview:sectionNameLabel];
    [self.view addSubview:sectionNameOverlayView];
}

- (void)initIndexView {
    if (self.indexView) {
        return;
    }
    UITableView *activeView = activeLayoutView;
    CGRect frame = CGRectMake(CGRectGetWidth(activeView.frame) - INDEX_WIDTH,
                              CGRectGetMinY(activeView.frame) + activeView.contentInset.top,
                              INDEX_WIDTH,
                              CGRectGetHeight(activeView.frame) - activeView.contentInset.top - activeView.contentInset.bottom - bottomPadding);
    self.indexView = [BDKCollectionIndexView indexViewWithFrame:frame indexTitles:@[]];
    self.indexView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin);
    self.indexView.alpha = 1.0;
    self.indexView.hidden = YES;
    [self.indexView addTarget:self action:@selector(indexViewValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)buildIndexView {
    // Get the index titles
    NSMutableArray *tmpArr = [[NSMutableArray alloc] initWithArray:self.sectionArray];
    if (tmpArr.count > 1) {
        tmpArr[0] = @"🔍";
    }
    if (self.sectionArray.count > 1 && !episodesView && !channelGuideView) {
        self.indexView.indexTitles = [NSArray arrayWithArray:tmpArr];
        [maskView addSubview:self.indexView];
    }
    else if (channelGuideView) {
        if (self.sectionArray.count > 0) {
            NSMutableArray *channelGuideTableIndexTitles = [NSMutableArray new];
            NSDateFormatter *format = [NSDateFormatter new];
            format.locale = [NSLocale currentLocale];
            for (NSString *label in tmpArr) {
                NSString *dateString = label;
                format.dateFormat = @"yyyy-MM-dd";
                NSDate *date = [format dateFromString:label];
                format.dateFormat = @"EEE";
                if ([format stringFromDate:date] != nil) {
                    dateString = [format stringFromDate:date];
                }
                [channelGuideTableIndexTitles addObject:dateString];
            }
            self.indexView.indexTitles = channelGuideTableIndexTitles;
            [maskView addSubview:self.indexView];
        }
    }
    else {
        self.indexView.indexTitles = @[];
        [self.indexView removeFromSuperview];
    }
}

- (void)indexViewValueChanged:(BDKCollectionIndexView*)sender {
    if (sender.currentIndex == -1) {
        return;
    }
    else if (sender.currentIndex == 0) {
        if (enableCollectionView) {
            [collectionView setContentOffset:CGPointZero animated:NO];
            if (sectionNameOverlayView == nil && stackscrollFullscreen) {
                [self initSectionNameOverlayView];
            }
        }
        else {
            [dataList setContentOffset:CGPointZero animated:NO];
        }
        sectionNameLabel.text = @"🔍";
        return;
    }
    else if (stackscrollFullscreen) {
        if (sectionNameOverlayView == nil && stackscrollFullscreen) {
            [self initSectionNameOverlayView];
        }
        // Ensure the sort tokens are respected as well when using the index in fullscreen mode
        NSString *sortbymethod = sortMethodName;
        if ([self isEligibleForSorttokenSort]) {
            sortbymethod = @"sortby";
        }
        
        sectionNameLabel.text = [self buildSortInfo:storeSectionArray[sender.currentIndex]];
        NSString *value = storeSectionArray[sender.currentIndex];
        NSPredicate *predExists = [NSPredicate predicateWithFormat:@"SELF.%@ BEGINSWITH[c] %@", sortbymethod, value];
        if ([value isEqual:@"#"]) {
            predExists = [NSPredicate predicateWithFormat:@"SELF.%@ MATCHES[c] %@", sortbymethod, @"^[0-9].*"];
        }
        else if ([sortbymethod isEqualToString:@"rating"] && [value isEqualToString:@"0"]) {
            predExists = [NSPredicate predicateWithFormat:@"SELF.%@.length == 0", sortbymethod];
        }
        else if ([sortbymethod isEqualToString:@"runtime"]) {
             [NSPredicate predicateWithFormat:@"attributeName BETWEEN %@", @[@1, @10]];
            predExists = [NSPredicate predicateWithFormat:@"SELF.%@.intValue BETWEEN %@", sortbymethod, @[@([value intValue] - 15), @([value intValue])]];
        }
        else if ([sortbymethod isEqualToString:@"playcount"]) {
            predExists = [NSPredicate predicateWithFormat:@"SELF.%@.intValue == %d", sortbymethod, [value intValue]];
        }
        else if ([sortbymethod isEqualToString:@"year"]) {
            predExists = [NSPredicate predicateWithFormat:@"SELF.%@.intValue >= %d", sortbymethod, [value intValue]];
        }
        NSUInteger index = [sections[@""] indexOfObjectPassingTest:
                            ^(id obj, NSUInteger idx, BOOL *stop) {
                                return [predExists evaluateWithObject:obj];
                            }];
        if (index != NSNotFound) {
            NSIndexPath *path = [NSIndexPath indexPathForItem:index inSection:0];
            [collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
            collectionView.contentOffset = CGPointMake(collectionView.contentOffset.x, collectionView.contentOffset.y - GRID_SECTION_HEADER_HEIGHT);
        }
        return;
    }
    else if (enableCollectionView && sender.currentIndex < collectionView.numberOfSections) {
        NSIndexPath *path = [NSIndexPath indexPathForItem:0 inSection:sender.currentIndex];
        [collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        CGFloat offset = collectionView.contentOffset.y - GRID_SECTION_HEADER_HEIGHT;
        
        // Use correct scroll to bottom (not hiding a portion underneath the toolbar)
        CGFloat height_content = collectionView.contentSize.height;
        CGFloat height_bounds = collectionView.bounds.size.height;
        CGFloat bottom = buttonsView.frame.size.height;
        CGFloat bottom_scroll = MAX(height_content - height_bounds + bottom, 0);
        if (offset > height_content - height_bounds) {
            offset = bottom_scroll;
        }
        
        collectionView.contentOffset = CGPointMake(collectionView.contentOffset.x, offset);
    }
    else if (sender.currentIndex < dataList.numberOfSections) {
        NSIndexPath *path = [NSIndexPath indexPathForItem:0 inSection:sender.currentIndex];
        [dataList scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)handleCollectionIndexStateBegin {
    if (stackscrollFullscreen) {
        [Utilities alphaView:sectionNameOverlayView AnimDuration:0.1 Alpha:1];
    }
}

- (void)handleCollectionIndexStateEnded {
    if (stackscrollFullscreen) {
        [Utilities alphaView:sectionNameOverlayView AnimDuration:0.3 Alpha:0];
    }
    self.indexView.alpha = 1.0;
}

#pragma mark - Cell Formatting

- (UIActivityIndicatorView*)getCellActivityIndicator:(NSIndexPath*)indexPath {
    // Get the indicator view and place it in the middle of the thumb (if no thumb keep it at least fully visible)
    id cell = [self getCell:indexPath];
    UIActivityIndicatorView *cellActivityIndicator = (UIActivityIndicatorView*)[cell viewWithTag:XIB_JSON_DATA_CELL_ACTIVTYINDICATOR];
    if (!enableCollectionView) {
        cellActivityIndicator.center = CGPointMake(MAX(thumbWidth / 2, cellActivityIndicator.frame.size.width / 2), cellHeight / 2);
    }
    else if (recentlyAddedView) {
        cellActivityIndicator.center = ((RecentlyAddedCell*)cell).posterThumbnail.center;
    }
    else {
        cellActivityIndicator.center = ((PosterCell*)cell).posterThumbnail.center;
    }
    return cellActivityIndicator;
}

- (void)setTVshowThumbSize {
    mainMenu *Menuitem = self.detailItem;
    // Adapt thumbsize if viewing TV Shows and "preferTVPoster" feature is enabled
    if (!tvshowsView) {
        if (IS_IPAD) {
            Menuitem.thumbWidth = PAD_TV_SHOWS_POSTER_WIDTH;
            Menuitem.rowHeight = PAD_TV_SHOWS_POSTER_HEIGHT;
        }
        else {
            Menuitem.thumbWidth = PHONE_TV_SHOWS_POSTER_WIDTH;
            Menuitem.rowHeight = PHONE_TV_SHOWS_POSTER_HEIGHT;
        }
    }
    else {
        CGFloat transform = [Utilities getTransformX];
        if (IS_IPAD) {
            Menuitem.thumbWidth = (int)(PAD_TV_SHOWS_BANNER_WIDTH * transform);
            Menuitem.rowHeight = (int)(PAD_TV_SHOWS_BANNER_HEIGHT * transform);
        }
        else {
            Menuitem.thumbWidth = (int)(PHONE_TV_SHOWS_BANNER_WIDTH * transform);
            Menuitem.rowHeight = (int)(PHONE_TV_SHOWS_BANNER_HEIGHT * transform);
        }
    }
}

- (void)setWatchedOverlayPosition {
    flagX = thumbWidth - FLAG_SIZE / 2 - TINY_PADDING;
    flagY = cellHeight - FLAG_SIZE - TINY_PADDING;
    // Top left position, if no thumb (e.g. album tracks) or full size banner (TV Show banner)
    if (thumbWidth == 0 || flagX + FLAG_SIZE + TINY_PADDING > self.view.bounds.size.width) {
        flagX = TINY_PADDING;
        flagY = TINY_PADDING;
    }
}

- (void)choseParams {
    mainMenu *menuItem = self.detailItem;
    NSDictionary *parameters = menuItem.mainParameters[chosenTab];
    if ([parameters[@"defaultThumb"] length] != 0 && ![parameters[@"defaultThumb"] isEqualToString:@"(null)"]) {
        defaultThumb = parameters[@"defaultThumb"];
    }
    else {
        defaultThumb = menuItem.defaultThumb;
    }
    if (parameters[@"rowHeight"]) {
        cellHeight = [parameters[@"rowHeight"] intValue];
    }
    else if (menuItem.rowHeight != 0) {
        cellHeight = menuItem.rowHeight;
    }
    else {
        cellHeight = PORTRAIT_ROW_HEIGHT;
    }

    if (parameters[@"thumbWidth"]) {
        thumbWidth = [parameters[@"thumbWidth"] intValue];
    }
    else if (menuItem.thumbWidth != 0) {
        thumbWidth = menuItem.thumbWidth;
    }
    else {
        thumbWidth = DEFAULT_THUMB_WIDTH;
    }
    if (albumView || episodesView) {
        thumbWidth = 0;
        labelPosition = SMALL_PADDING + TRACKCOUNT_WIDTH + SMALL_PADDING;
    }
    else if (channelGuideView) {
        thumbWidth = 0;
        labelPosition = SMALL_PADDING + EPGCHANNELTIME_WIDTH + SMALL_PADDING;
    }
    else {
        labelPosition = thumbWidth + LABEL_PADDING;
    }
    dataList.separatorInset = UIEdgeInsetsMake(0, thumbWidth + LABEL_PADDING, 0, 0);
    
    // label position for TVShow banner view needs to be tailored to match the default thumb size
    if (tvshowsView && chosenTab == 0) {
        CGFloat targetHeight = IS_IPAD ? PAD_TV_SHOWS_BANNER_HEIGHT : PHONE_TV_SHOWS_BANNER_HEIGHT;
        CGFloat factor = targetHeight / PHONE_TV_SHOWS_POSTER_HEIGHT * [Utilities getTransformX];
        labelPosition = PAD_TV_SHOWS_POSTER_WIDTH * factor + LABEL_PADDING;
    }
    
    int newWidthLabel = 0;
    if (episodesView || (self.sectionArray.count == 1 && !channelGuideView)) {
        newWidthLabel = viewWidth - LABEL_PADDING - labelPosition;
        menuItem.originYearDuration = viewWidth - RUNTIMEYEAR_WIDTH - LABEL_PADDING;
        UIEdgeInsets dataListSeparatorInset = [dataList separatorInset];
        dataListSeparatorInset.right = 0;
        dataList.separatorInset = dataListSeparatorInset;
    }
    else {
        int indexPadding = INDEX_WIDTH;
        UIEdgeInsets dataListSeparatorInset = [dataList separatorInset];
        dataListSeparatorInset.right = indexPadding;
        dataList.separatorInset = dataListSeparatorInset;
        newWidthLabel = viewWidth - labelPosition - indexPadding;
        menuItem.originYearDuration = viewWidth - indexPadding - RUNTIMEYEAR_WIDTH;
    }
    menuItem.widthLabel = newWidthLabel;
    [self setWatchedOverlayPosition];
}

#pragma mark - Table Management

- (void)setSearchBar:(UISearchBar*)searchBar toDark:(BOOL)isDark {
    if (isDark) {
        searchBar.backgroundColor = SYSTEMGRAY6_DARKMODE;
        searchBar.tintColor = ICON_TINT_COLOR;
    }
    else {
        searchBar.backgroundColor = [Utilities getSystemGray6];
        searchBar.tintColor = [Utilities get2ndLabelColor];
    }
}

- (UISearchBar*)createFakeSearchbarInDark:(BOOL)isDark {
    // Create non-used search controller. This is added as tableHeaderView and lets iOS gracefully handle insets
    UISearchController *searchCtrl = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchCtrl.searchBar.showsCancelButton = NO;
    searchCtrl.searchBar.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.searchController.searchBar.frame));
    searchCtrl.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchCtrl.searchBar.barStyle = UIBarStyleBlack;
    searchCtrl.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self setSearchBar:searchCtrl.searchBar toDark:isDark];
    
    // Create a transparent view on top of the unused searchbar. This receives a tap gesture to start a search.
    UIView *tapOverlay = [[UIView alloc] initWithFrame:searchCtrl.searchBar.frame];
    tapOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    tapOverlay.backgroundColor = UIColor.clearColor;
    [searchCtrl.searchBar addSubview:tapOverlay];
    
    // Add tap gesture to create a detached search bar
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openSearchBar)];
    [tapOverlay addGestureRecognizer:tapGesture];
    
    return searchCtrl.searchBar;
}

- (void)scrollViewDidScroll:(UIScrollView*)theScrollView {
    // Hide keyboard on drag
    showkeyboard = NO;
    [self.searchController.searchBar resignFirstResponder];
    // Stop an empty search on drag
    NSString *searchString = self.searchController.searchBar.text;
    if (searchString.length == 0 && self.searchController.isActive) {
        [self.searchController setActive:NO];
    }
    // Workaround iOS 17: Force scroll indicator visible.
    dataList.showsVerticalScrollIndicator = YES;
    dataList.showsHorizontalScrollIndicator = NO;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    NSDictionary *item = [self getItemFromIndexPath:indexPath];
    return globalSearchView ? [self getGlobalSearchThumbsize:item].y : cellHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    if ([self doesShowSearchResults] && !useSectionInSearchResults) {
        return (self.filteredListContent.count > 0) ? 1 : 0;
    }
	else {
        return [self.sections allKeys].count;
    }
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self doesShowSearchResults]) {
        if (!useSectionInSearchResults) {
            return [self getAmountOfSearchResultsString];
        }
        if (section == 0) {
            return [self getAmountOfSearchResultsString];
        }
        NSString *sectionName = self.sectionArray[section];
        return [self buildSortInfo:sectionName];
    }
    else {
        if (section == 0) {
            return nil;
        }
        NSString *sectionName = self.sectionArray[section];
        if (channelGuideView) {
            NSString *dateString = @"";
            NSDateFormatter *format = [NSDateFormatter new];
            format.locale = [NSLocale currentLocale];
            format.dateFormat = @"yyyy-MM-dd";
            NSDate *date = [format dateFromString:sectionName];
            format.dateStyle = NSDateFormatterLongStyle;
            dateString = [format stringFromDate:date];
            format.dateFormat = @"yyyy-MM-dd";
            date = [format dateFromString:sectionName];
            format.dateFormat = @"cccc";
            if (date != nil) {
                sectionName = [NSString stringWithFormat:@"%@ - %@", [format stringFromDate:date], dateString];
            }
            else {
                sectionName = @"";
            }
        }
        return [self buildSortInfo:sectionName];
    }
}

- (NSString*)buildSortInfo:(NSString*)sectionName {
    if ([sortMethodName isEqualToString:@"year"]) {
        if (sectionName.length > 3) {
            sectionName = LOCALIZED_STR_ARGS(@"The %@s decade", sectionName);
        }
        else {
            sectionName = LOCALIZED_STR(@"Year not available");
        }
    }
    else if ([sortMethodName isEqualToString:@"dateadded"]) {
        sectionName = LOCALIZED_STR_ARGS(@"Year %@", sectionName);
    }
    else if ([sortMethodName isEqualToString:@"playcount"]) {
        if ([sectionName intValue] == 0) {
            if (watchedListenedStrings[@"notWatched"] != nil) {
                sectionName = watchedListenedStrings[@"notWatched"];
            }
            else {
                sectionName = LOCALIZED_STR(@"Not watched");
            }
        }
        else if ([sectionName intValue] == 1) {
            if (watchedListenedStrings[@"watchedOneTime"] != nil) {
                sectionName = watchedListenedStrings[@"watchedOneTime"];
            }
            else {
                sectionName = LOCALIZED_STR(@"Watched one time");
            }
        }
        else {
            NSNumberFormatter *formatter = [NSNumberFormatter new];
            formatter.numberStyle = NSNumberFormatterDecimalStyle;
            NSString *formatString = LOCALIZED_STR(@"Watched %@ times");
            if (watchedListenedStrings[@"watchedTimes"] != nil) {
                formatString = watchedListenedStrings[@"watchedTimes"];
            }
            sectionName = [NSString stringWithFormat:formatString, [formatter stringFromNumber:@([sectionName intValue])]];
        }
    }
    else if ([sortMethodName isEqualToString:@"rating"]) {
        int start = 0;
        int num_stars = [sectionName intValue];
        int stop = numberOfStars;
        NSString *newName = LOCALIZED_STR_ARGS(@"Rated %@", sectionName);
        NSMutableString *stars = [NSMutableString string];
        for (start = 0; start < num_stars; start++) {
            [stars appendString:@"\u2605"];
        }
        for (int j = start; j < stop; j++) {
            [stars appendString:@"\u2606"];
        }
        sectionName = [NSString stringWithFormat:@"%@ - %@", stars, newName];
    }
    else if ([sortMethodName isEqualToString:@"runtime"]) {
        if ([sectionName isEqualToString:@"15"]) {
            sectionName = LOCALIZED_STR(@"Less than 15 minutes");
        }
        else if ([sectionName isEqualToString:@"30"]) {
            sectionName = LOCALIZED_STR(@"Less than half an hour");
        }
        else if ([sectionName isEqualToString:@"45"]) {
            sectionName = LOCALIZED_STR(@"About half an hour");
        }
        else if ([sectionName isEqualToString:@"60"]) {
            sectionName = LOCALIZED_STR(@"Less than one hour");
        }
        else if ([sectionName isEqualToString:@"75"]) {
            sectionName = LOCALIZED_STR(@"About one hour");
        }
        else if ([sectionName isEqualToString:@"90"]) {
            sectionName = LOCALIZED_STR(@"About an hour and a half");
        }
        else if ([sectionName isEqualToString:@"105"]) {
            sectionName = LOCALIZED_STR(@"Nearly two hours");
        }
        else if ([sectionName isEqualToString:@"120"]) {
            sectionName = LOCALIZED_STR(@"About two hours");
        }
        else if ([sectionName isEqualToString:@"135"]) {
            sectionName = LOCALIZED_STR(@"Two hours");
        }
        else if ([sectionName isEqualToString:@"150"]) {
            sectionName = LOCALIZED_STR(@"About two and a half hours");
        }
        else if ([sectionName isEqualToString:@"165"]) {
            sectionName = LOCALIZED_STR(@"More than two and a half hours");
        }
        else if ([sectionName isEqualToString:@"180"]) {
            sectionName = LOCALIZED_STR(@"Nearly three hours");
        }
        else if ([sectionName isEqualToString:@"195"]) {
            sectionName = LOCALIZED_STR(@"About three hours");
        }
        else if ([sectionName isEqualToString:@"210"]) {
            sectionName = LOCALIZED_STR(@"Nearly three and half hours");
        }
        else if ([sectionName isEqualToString:@"225"]) {
            sectionName = LOCALIZED_STR(@"About three and half hours");
        }
        else if ([sectionName isEqualToString:@"240"]) {
            sectionName = LOCALIZED_STR(@"Nearly four hours");
        }
        else if ([sectionName isEqualToString:@"255"]) {
            sectionName = LOCALIZED_STR(@"About four hours");
        }
        else {
            sectionName = LOCALIZED_STR(@"More than four hours");
        }
    }
    else if ([sortMethodName isEqualToString:@"track"]) {
        sectionName = LOCALIZED_STR_ARGS(@"Track n.%@", sectionName);
    }
    else if ([sortMethodName isEqualToString:@"itemgroup"]) {
        int index = [sectionName intValue];
        NSString *sectionLongName;
        switch (index) {
            case GLOBALSEARCH_INDEX_MOVIES:
                sectionLongName = LOCALIZED_STR(@"Movies");
                break;
            case GLOBALSEARCH_INDEX_TVSHOWS:
                sectionLongName = LOCALIZED_STR(@"TV Shows");
                break;
            case GLOBALSEARCH_INDEX_MUSICVIDEOS:
                sectionLongName = LOCALIZED_STR(@"Music Videos");
                break;
            case GLOBALSEARCH_INDEX_ARTISTS:
                sectionLongName = LOCALIZED_STR(@"Artists");
                break;
            case GLOBALSEARCH_INDEX_ALBUMS:
                sectionLongName = LOCALIZED_STR(@"Albums");
                break;
            case GLOBALSEARCH_INDEX_SONGS:
                sectionLongName = LOCALIZED_STR(@"Songs");
                break;
            case GLOBALSEARCH_INDEX_MOVIESETS:
                sectionLongName = LOCALIZED_STR(@"Movie Sets");
                break;
            default:
                break;
        }
        sectionName = [NSString stringWithFormat:@"%@ - %@", sectionName, sectionLongName];
    }
    return sectionName;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self doesShowSearchResults] && !useSectionInSearchResults) {
        return self.filteredListContent.count;
    }
	else {
        if (episodesView) {
            return ([self.sectionArrayOpen[section] boolValue] ? [[self.sections objectForKey:self.sectionArray[section]] count] : 0);
        }
        return [self.sections[self.sectionArray[section]] count];
    }
}

- (NSInteger)tableView:(UITableView*)tableView sectionForSectionIndexTitle:(NSString*)title atIndex:(NSInteger)index {
    if (index == 0) {
        [tableView scrollRectToVisible:tableView.tableHeaderView.frame animated:NO];
        return index -1;
    }
    return index;
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)tableView {
    return nil;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    // Will be set inside setCellImageView to be able to handle special case for TVshows
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    jsonDataCell *cell = [tableView dequeueReusableCellWithIdentifier:@"jsonDataCellIdentifier"];
    NSDictionary *item = [self getItemFromIndexPath:indexPath];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"jsonDataCell" owner:self options:nil];
        cell = nib[0];
        if (albumView || episodesView) {
            UILabel *trackNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(SMALL_PADDING, cellHeight / 2 - (artistFontSize + VERTICAL_PADDING) / 2, TRACKCOUNT_WIDTH, artistFontSize + VERTICAL_PADDING)];
            trackNumberLabel.backgroundColor = UIColor.clearColor;
            trackNumberLabel.font = [UIFont systemFontOfSize:artistFontSize];
            trackNumberLabel.adjustsFontSizeToFitWidth = YES;
            trackNumberLabel.minimumScaleFactor = FONT_SCALING_DEFAULT;
            trackNumberLabel.textAlignment = NSTextAlignmentCenter;
            trackNumberLabel.tag = ALBUM_VIEW_CELL_TRACKNUMBER;
            trackNumberLabel.highlightedTextColor = [Utilities get1stLabelColor];
            trackNumberLabel.textColor = [Utilities get1stLabelColor];
            [cell.contentView addSubview:trackNumberLabel];
        }
        else if (channelGuideView) {
            UILabel *title = (UILabel*)[cell viewWithTag:XIB_JSON_DATA_CELL_TITLE];
            UILabel *programTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(SMALL_PADDING, VERTICAL_PADDING, EPGCHANNELTIME_WIDTH, EPGCHANNELTIME_HEIGHT)];
            programTimeLabel.backgroundColor = UIColor.clearColor;
            programTimeLabel.center = CGPointMake(programTimeLabel.center.x, title.center.y);
            programTimeLabel.font = [UIFont systemFontOfSize:13];
            programTimeLabel.adjustsFontSizeToFitWidth = YES;
            programTimeLabel.minimumScaleFactor = FONT_SCALING_DEFAULT;
            programTimeLabel.textAlignment = NSTextAlignmentCenter;
            programTimeLabel.tag = EPG_VIEW_CELL_STARTTIME;
            programTimeLabel.highlightedTextColor = [Utilities get2ndLabelColor];
            programTimeLabel.textColor = [Utilities get2ndLabelColor];
            [cell.contentView addSubview:programTimeLabel];
            
            [self addProgressBar:cell recDotSize:RECORDING_DOT_SIZE];
        }
        else if (channelListView) {
            [self addProgressBar:cell recDotSize:RECORDING_DOT_SIZE];
        }
        UILabel *title = (UILabel*)[cell viewWithTag:XIB_JSON_DATA_CELL_TITLE];
        UILabel *genre = (UILabel*)[cell viewWithTag:XIB_JSON_DATA_CELL_GENRE];
        UILabel *runtimeyear = (UILabel*)[cell viewWithTag:XIB_JSON_DATA_CELL_RUNTIMEYEAR];
        UILabel *runtime = (UILabel*)[cell viewWithTag:XIB_JSON_DATA_CELL_RUNTIME];
        UILabel *rating = (UILabel*)[cell viewWithTag:XIB_JSON_DATA_CELL_RATING];
        
        title.highlightedTextColor = [Utilities get1stLabelColor];
        genre.highlightedTextColor = [Utilities get2ndLabelColor];
        runtimeyear.highlightedTextColor = [Utilities get2ndLabelColor];
        runtime.highlightedTextColor = [Utilities get2ndLabelColor];
        rating.highlightedTextColor = [Utilities get2ndLabelColor];
        
        title.textColor = [Utilities get1stLabelColor];
        genre.textColor = [Utilities get2ndLabelColor];
        runtimeyear.textColor = [Utilities get2ndLabelColor];
        runtime.textColor = [Utilities get2ndLabelColor];
        rating.textColor = [Utilities get2ndLabelColor];
        
        cell.backgroundColor = [Utilities getSystemGray6];
    }
    mainMenu *menuItem = self.detailItem;
    CGPoint thumbSize = globalSearchView ? [self getGlobalSearchThumbsize:item] : CGPointMake(thumbWidth, cellHeight);
    thumbWidth = thumbSize.x;
    cellHeight = thumbSize.y;
    [self setWatchedOverlayPosition];
    CGRect frame;
    frame.origin = CGPointZero;
    frame.size.width = thumbWidth;
    frame.size.height = cellHeight;
    cell.urlImageView.frame = frame;
    cell.urlImageView.autoresizingMask = UIViewAutoresizingNone;
    cell.urlImageView.backgroundColor = UIColor.clearColor;
    
    UILabel *title = (UILabel*)[cell viewWithTag:XIB_JSON_DATA_CELL_TITLE];
    UILabel *genre = (UILabel*)[cell viewWithTag:XIB_JSON_DATA_CELL_GENRE];
    UILabel *runtimeyear = (UILabel*)[cell viewWithTag:XIB_JSON_DATA_CELL_RUNTIMEYEAR];
    UILabel *runtime = (UILabel*)[cell viewWithTag:XIB_JSON_DATA_CELL_RUNTIME];
    UILabel *rating = (UILabel*)[cell viewWithTag:XIB_JSON_DATA_CELL_RATING];
    BroadcastProgressView *progressView = (BroadcastProgressView*)[cell viewWithTag:EPG_VIEW_CELL_PROGRESSVIEW];
    UIImageView *timerView = (UIImageView*)[cell viewWithTag:EPG_VIEW_CELL_RECORDING_ICON];

    frame = title.frame;
    frame.origin.x = labelPosition;
    frame.origin.y = 0;
    frame.size.width = menuItem.widthLabel;
    title.frame = frame;
    if (channelListView && item[@"channelnumber"]) {
        title.text = [NSString stringWithFormat:@"%@. %@", item[@"channelnumber"], item[@"label"]];
    }
    else if (item[@"episodeid"] && !episodesView) {
        title.text = [Utilities formatTVShowStringForSeasonLeading:item[@"season"] episode:item[@"episode"] title:item[@"label"]];
    }
    else {
        title.text = [Utilities stripBBandHTML:item[@"label"]];
    }
    
    // In case no thumbs are shown and there is a child view or we are showing a setting, display disclosure indicator and adapt width.
    NSDictionary *method = menuItem.subItem.mainMethod[chosenTab];
    BOOL hasChild = method.count > 0;
    BOOL isSettingID = [item[@"family"] isEqualToString:@"id"];
    if (!thumbWidth && self.indexView.hidden && (hasChild || isSettingID)) {
        frame = title.frame;
        frame.size.width = frame.size.width - INDICATOR_SIZE - LABEL_PADDING;
        title.frame = frame;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    frame = genre.frame;
    frame.size.width = menuItem.widthLabel;
    frame.origin.x = labelPosition;
    genre.frame = frame;
    if (item[@"episodeid"] && episodesView && [self doesShowSearchResults]) {
        genre.text = [Utilities formatTVShowStringForSeasonTrailing:item[@"season"] episode:item[@"episode"] title:item[@"genre"]];
    }
    else {
        genre.text = [item[@"genre"] stringByReplacingOccurrencesOfString:@"[CR]" withString:@"\n"];
    }

    frame = runtimeyear.frame;
    frame.origin.x = menuItem.originYearDuration;
    runtimeyear.frame = frame;

    if ([menuItem.showRuntime[chosenTab] boolValue]) {
        NSString *duration = @"";
        if (!menuItem.noConvertTime) {
            duration = [Utilities convertTimeFromSeconds:item[@"runtime"]];
        }
        else {
            duration = item[@"runtime"];
        }
        runtimeyear.text = duration;
    }
    else {
        runtimeyear.text = [Utilities getDateFromItem:item[@"year"] dateStyle:NSDateFormatterShortStyle];
        if (runtimeyear.text.length == 0) {
            runtimeyear.text = item[@"year"];
        }
    }
    frame = runtime.frame;
    frame.size.width = menuItem.widthLabel;
    frame.origin.x = labelPosition;
    runtime.frame = frame;
    runtime.text = item[@"runtime"];

    frame = rating.frame;
    frame.origin.x = menuItem.originYearDuration;
    rating.frame = frame;
    rating.text = [Utilities getRatingFromItem:item[@"rating"]];
    cell.urlImageView.contentMode = UIViewContentModeScaleAspectFill;
    genre.hidden = NO;
    runtimeyear.hidden = NO;
    if (!albumView && !episodesView && !channelGuideView) {
        // Since recordings must be synced it is required to set recordingListView here.
        recordingListView = [item[@"family"] isEqualToString:@"recordingid"];
        
        if (channelListView || recordingListView) {
            CGRect frame;
            frame.origin.x = SMALL_PADDING;
            frame.origin.y = VERTICAL_PADDING;
            frame.size.width = ceil(thumbWidth * 0.9);
            frame.size.height = ceil(thumbWidth * 0.7);
            cell.urlImageView.frame = frame;
            cell.urlImageView.autoresizingMask = UIViewAutoresizingNone;
            
            CGFloat originY = CGRectGetMaxY(frame) + VERTICAL_PADDING;
            CGFloat height = cellHeight - originY - TINY_PADDING;
            CGRect barFrame = CGRectMake(SMALL_PADDING, originY, CGRectGetWidth(frame), height);
            progressView.frame = barFrame;
            timerView.center = [progressView convertPoint:[progressView getReservedCenter] toView:cell.contentView];
        }
        if (channelListView) {
            runtime.hidden = NO;
            CGRect frame = genre.frame;
            frame.size.width = title.frame.size.width;
            frame.size.height = GENRE_HEIGHT;
            genre.frame = frame;
            genre.textColor = [Utilities get1stLabelColor];
            genre.font = [UIFont boldSystemFontOfSize:14];
            progressView.hidden = YES;
            timerView.hidden = ![item[@"isrecording"] boolValue];
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [Utilities getNumberFromItem:item[@"channelid"]], @"channelid",
                                    indexPath, @"indexPath",
                                    item, @"item",
                                    nil];
            [NSThread detachNewThreadSelector:@selector(getChannelEpgInfo:) toTarget:self withObject:params];
        }
        if (recordingListView) {
            genre.textColor = [Utilities get2ndLabelColor];
            genre.font = [UIFont systemFontOfSize:12];
        }
        NSString *stringURL = tvshowsView ? item[@"banner"] : item[@"thumbnail"];
        NSString *displayThumb = globalSearchView ? [self getGlobalSearchThumb:item] : defaultThumb;
        if (tvshowsView && chosenTab == 0) {
            displayThumb = defaultThumb = @"nocover_tvshows_banner";
        }
        if ([item[@"filetype"] length] != 0 ||
            [item[@"family"] isEqualToString:@"file"] ||
            [item[@"family"] isEqualToString:@"type"] ||
            [item[@"family"] isEqualToString:@"genreid"] ||
            [item[@"family"] isEqualToString:@"channelgroupid"] ||
            [item[@"family"] isEqualToString:@"roleid"]) {
            genre.hidden = YES;
            runtimeyear.hidden = YES;
            title.frame = CGRectMake(title.frame.origin.x, (int)(cellHeight / 2 - title.frame.size.height / 2), title.frame.size.width, title.frame.size.height);
        }
        else if ([item[@"family"] isEqualToString:@"channelid"]) {
            runtimeyear.hidden = YES;
            rating.hidden = YES;
        }
        else if ([item[@"family"] isEqualToString:@"recordingid"] ||
                 [item[@"family"] isEqualToString:@"timerid"]) {
            cell.urlImageView.contentMode = UIViewContentModeScaleAspectFit;
            runtimeyear.hidden = YES;
            runtime.hidden = YES;
            rating.hidden = YES;
            genre.hidden = NO;
            if ([item[@"family"] isEqualToString:@"timerid"]) {
                NSDate *timerStartTime = [xbmcDateFormatter dateFromString:item[@"starttime"]];
                NSDate *endTime = [xbmcDateFormatter dateFromString:item[@"endtime"]];
                
                defaultThumb = displayThumb = [self getTimerDefaultThumb:item];

                NSString *timerPlan;
                if ([item[@"istimerrule"] boolValue] && ![item[@"genre"] isEqualToString:@""]) {
                    timerPlan = item[@"genre"];
                }
                else {
                    NSDateFormatter *localFormatter = [NSDateFormatter new];
                    localFormatter.dateFormat = @"ccc dd MMM, HH:mm";
                    localFormatter.timeZone = [NSTimeZone systemTimeZone];
                    timerPlan = [localFormatter stringFromDate:timerStartTime];
                    localFormatter.dateFormat = @"HH:mm";
                    timerPlan = [NSString stringWithFormat:@"%@ - %@", timerPlan, [localFormatter stringFromDate:endTime]];
                }

                NSString *runtime;
                if (![item[@"runtime"] isEqualToString:@""]) {
                    runtime = item[@"runtime"];
                }
                else {
                    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSUInteger unitFlags = NSCalendarUnitMinute;
                    NSDateComponents *components = [gregorian components:unitFlags fromDate:timerStartTime toDate:endTime options:0];
                    NSInteger minutes = [components minute];
                    NSString *minutesUnit = minutes > 1 ? LOCALIZED_STR(@"Mins.") : LOCALIZED_STR(@"Min");
                    runtime = [NSString stringWithFormat:@"%ld %@", (long)minutes, minutesUnit];
                }

                genre.text = [NSString stringWithFormat:@"%@ (%@)", timerPlan, runtime];
            }
            else {
                genre.text = [NSString stringWithFormat:@"%@ - %@", item[@"channel"], item[@"plot"]];
                genre.numberOfLines = 3;
            }
            CGRect frame = genre.frame;
            frame.size.width = title.frame.size.width;
            frame.size.height = cellHeight - frame.origin.y - SMALL_PADDING;
            genre.frame = frame;
            frame = title.frame;
            frame.origin.y = 0;
            title.frame = frame;
            genre.font = [genre.font fontWithSize:12];
            genre.minimumScaleFactor = FONT_SCALING_DEFAULT;
            [genre sizeToFit];
        }
        else if ([item[@"family"] isEqualToString:@"sectionid"] ||
                 [item[@"family"] isEqualToString:@"categoryid"] ||
                 [item[@"family"] isEqualToString:@"id"] ||
                 [item[@"family"] isEqualToString:@"addonid"]) {
            CGRect frame;
            cell.urlImageView.contentMode = UIViewContentModeScaleAspectFit;
            runtimeyear.hidden = YES;
            runtime.hidden = YES;
            rating.hidden = YES;
            frame = genre.frame;
            frame.size.width = title.frame.size.width;
            frame.size.height = cellHeight - frame.origin.y - SMALL_PADDING;
            genre.frame = frame;
            genre.numberOfLines = 2;
            genre.font = [genre.font fontWithSize:11];
            genre.minimumScaleFactor = FONT_SCALING_DEFAULT;
        }
        else if ([item[@"family"] isEqualToString:@"musicvideoid"]) {
            rating.hidden = YES;
            genre.text = [Utilities getStringFromItem:item[@"genre"]];
            runtime.text = [Utilities getStringFromItem:item[@"artist"]];
        }
        else {
            genre.hidden = NO;
            runtimeyear.hidden = NO;
            rating.hidden = NO;
        }
        [self setCellImageView:cell.urlImageView cell:cell dictItem:item url:stringURL size:CGSizeMake(thumbWidth, cellHeight) defaultImg:displayThumb];
    }
    else if (albumView) {
        UILabel *trackNumber = (UILabel*)[cell viewWithTag:ALBUM_VIEW_CELL_TRACKNUMBER];
        trackNumber.text = item[@"track"];
    }
    else if (episodesView) {
        UILabel *trackNumber = (UILabel*)[cell viewWithTag:ALBUM_VIEW_CELL_TRACKNUMBER];
        trackNumber.text = item[@"episode"];
    }
    else if (channelGuideView) {
        runtimeyear.hidden = YES;
        runtime.hidden = YES;
        rating.hidden = YES;
        CGRect frame = genre.frame;
        frame.size.width = title.frame.size.width;
        frame.size.height = cellHeight - frame.origin.y - SMALL_PADDING;
        genre.frame = frame;
        genre.numberOfLines = 3;
        genre.font = [genre.font fontWithSize:12];
        genre.minimumScaleFactor = FONT_SCALING_DEFAULT;
        [genre sizeToFit];
        UILabel *programStartTime = (UILabel*)[cell viewWithTag:EPG_VIEW_CELL_STARTTIME];
        NSDate *starttime = [xbmcDateFormatter dateFromString:item[@"starttime"]];
        NSDate *endtime = [xbmcDateFormatter dateFromString:item[@"endtime"]];
        programStartTime.text = [localHourMinuteFormatter stringFromDate:starttime];
        float percent_elapsed = [Utilities getPercentElapsed:starttime EndDate:endtime];
        
        CGRect progressFrame = CGRectMake(SMALL_PADDING,
                                          CGRectGetMinY(genre.frame) + VERTICAL_PADDING,
                                          CGRectGetWidth(programStartTime.frame),
                                          EPGCHANNELBAR_HEIGHT);
        progressView.frame = progressFrame;
        timerView.center = [progressView convertPoint:[progressView getReservedCenter] toView:cell.contentView];
        
        title.textColor = [Utilities get1stLabelColor];
        genre.textColor = [Utilities get2ndLabelColor];
        title.highlightedTextColor = [Utilities get1stLabelColor];
        genre.highlightedTextColor = [Utilities get2ndLabelColor];

        if (percent_elapsed > 0 && percent_elapsed < 100) {
            programStartTime.textColor = [Utilities get1stLabelColor];
            programStartTime.highlightedTextColor = [Utilities get1stLabelColor];
            programStartTime.font = [UIFont systemFontOfSize:14];
            cell.backgroundColor = [Utilities getSystemGray4];
            
            [progressView setProgress:percent_elapsed / 100.0];
            NSCalendar *gregorian = [[NSCalendar alloc]
                                     initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSUInteger unitFlags = NSCalendarUnitMinute;
            NSDateComponents *components = [gregorian components:unitFlags
                                                        fromDate:starttime
                                                          toDate:endtime
                                                         options:0];
            NSInteger minutes = [components minute];
            progressView.barLabel.text = [NSString stringWithFormat:@"%ld'", (long)minutes];
            progressView.hidden = NO;
        }
        else {
            programStartTime.textColor = [Utilities get2ndLabelColor];
            programStartTime.highlightedTextColor = [Utilities get2ndLabelColor];
            programStartTime.font = [UIFont systemFontOfSize:13];
            cell.backgroundColor = [Utilities getSystemGray6];
            
            progressView.hidden = YES;
        }
        timerView.hidden = ![item[@"hastimer"] boolValue];
    }
    if (!runtimeyear.hidden) {
        frame = genre.frame;
        frame.size.width = menuItem.widthLabel - [Utilities getSizeOfLabel:runtimeyear].width - LABEL_PADDING;
        genre.frame = frame;
    }
    if (!rating.hidden) {
        frame = runtime.frame;
        frame.size.width = menuItem.widthLabel - [Utilities getSizeOfLabel:rating].width - LABEL_PADDING;
        runtime.frame = frame;
    }
    
    NSString *playcount = [NSString stringWithFormat:@"%@", item[@"playcount"]];
    UIImageView *flagView = (UIImageView*)[cell viewWithTag:XIB_JSON_DATA_CELL_WATCHED_FLAG];
    frame = flagView.frame;
    frame.origin.x = flagX;
    frame.origin.y = flagY;
    flagView.frame = frame;
    if ([playcount intValue]) {
        flagView.hidden = NO;
    }
    else {
        flagView.hidden = YES;
    }
    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [self.searchController.searchBar resignFirstResponder];
    NSDictionary *item = [self getItemFromIndexPath:indexPath];
    UITableViewCell *cell = [dataList cellForRowAtIndexPath:indexPath];
    CGPoint offsetPoint = [dataList contentOffset];
    int rectOriginX = cell.frame.origin.x + cell.frame.size.width / 2;
    int rectOriginY = cell.frame.origin.y + cell.frame.size.height / 2 - offsetPoint.y;
    [self didSelectItemAtIndexPath:indexPath item:item displayPoint:CGPointMake(rectOriginX, rectOriginY)];
}

- (NSUInteger)indexOfObjectWithSeason:(NSString*)seasonNumber inArray:(NSArray*)array {
    return [array indexOfObjectPassingTest:
            ^(id dictionary, NSUInteger idx, BOOL *stop) {
                return ([dictionary[@"season"] isEqualToString:seasonNumber]);
            }];
}

- (NSInteger)getFirstListedSeason:(NSArray*)array {
    NSInteger firstSeason = NSNotFound;
    for (NSDictionary *season in array) {
        NSInteger index = [season[@"season"] intValue];
        if (index < firstSeason) {
            firstSeason = index;
        }
    }
    return firstSeason;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    if (albumView && self.richResults.count > 0) {
        UIImageView *thumbImageView = [UIImageView new];
        UIView *albumDetailView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, albumViewHeight)];
        
        NSDictionary *item = self.richResults[0];
        
        // Get artist and album
        NSString *artistText = [Utilities getStringFromItem:item[@"albumartist"]];
        NSString *albumText = self.navigationItem.title;
        
        // Get total runtime in minutes
        int totalTimeSeconds = 0;
        for (NSDictionary *item in self.richResults) {
            totalTimeSeconds += [item[@"runtime"] intValue];
        }
        int totalTimeMinutes = (int)round(totalTimeSeconds / 60.0);
        NSString *trackCountText = [NSString stringWithFormat:@"%lu %@, %d %@",
                                self.richResults.count, self.richResults.count > 1 ? LOCALIZED_STR(@"Songs") : LOCALIZED_STR(@"Song"),
                                totalTimeMinutes, totalTimeMinutes > 1 ? LOCALIZED_STR(@"Mins.") : LOCALIZED_STR(@"Min")];
        
        // Get year of release
        int year = [item[@"year"] intValue];
        NSString *releasedText = (year > 0) ? LOCALIZED_STR_ARGS(@"Released %d", year) : @"";
        
        [self layoutSectionView:albumDetailView
                      thumbView:thumbImageView
                       thumbURL:item[@"thumbnail"]
                      fanartURL:item[@"fanart"]
                     artistText:artistText
                      albumText:albumText
                   releasedText:releasedText
                 trackCountText:trackCountText
                      isWatched:NO
                      isTopMost:YES];
        
        // Add tap gesture to show album details
        UITapGestureRecognizer *touchOnAlbumView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAlbumActions:)];
        [thumbImageView addGestureRecognizer:touchOnAlbumView];

        return albumDetailView;
    }
    else if (episodesView && self.sectionArray.count > section && ![self doesShowSearchResults]) {
        UIImageView *thumbImageView = [UIImageView new];
        UIView *albumDetailView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, albumViewHeight)];
        albumDetailView.tag = section;
        
        // Get the first listed episode of the season in this section
        NSDictionary *item;
        id seasonNumber = self.sectionArray[section];
        NSArray *episodesInSeason = self.sections[seasonNumber];
        if ([episodesInSeason isKindOfClass:[NSArray class]] && episodesInSeason.count > 0) {
            item = episodesInSeason[0];
        }
        else {
            return nil;
        }
        
        NSInteger seasonIdx = [self indexOfObjectWithSeason:[NSString stringWithFormat:@"%d", [item[@"season"] intValue]] inArray:self.extraSectionRichResults];
        NSInteger firstListedSeason = [self getFirstListedSeason:self.extraSectionRichResults];
        
        if (seasonIdx != NSNotFound && self.extraSectionRichResults.count > seasonIdx) {
            BOOL isFirstListedSeason = [item[@"season"] intValue] == firstListedSeason;
            if (isFirstListedSeason) {
                [self setSearchBar:self.searchController.searchBar toDark:NO];
            }
            
            // Get show name ("genre") and season ("label")
            NSString *artistText = item[@"genre"];
            NSString *albumText = self.extraSectionRichResults[seasonIdx][@"label"];
            
            // Get amount of episodes
            NSString *trackCountText = LOCALIZED_STR_ARGS(@"Episodes: %@", self.extraSectionRichResults[seasonIdx][@"episode"]);
            
            // Get info on when first aired
            NSString *aired = [Utilities getDateFromItem:item[@"year"] dateStyle:NSDateFormatterLongStyle];
            NSString *releasedText = aired ? LOCALIZED_STR_ARGS(@"First aired on %@", aired) : @"";
            
            [self layoutSectionView:albumDetailView
                          thumbView:thumbImageView
                           thumbURL:self.extraSectionRichResults[seasonIdx][@"thumbnail"]
                          fanartURL:item[@"thumbnail"]
                         artistText:artistText
                          albumText:albumText
                       releasedText:releasedText
                     trackCountText:trackCountText
                          isWatched:[self wasSeasonPlayed:section]
                          isTopMost:isFirstListedSeason];
            
            // Add long press gesture for action list
            UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressSeason:)];
            [albumDetailView addGestureRecognizer:longPressGesture];
            
            // Add tap gesture to toggle open/close the section
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOpen:)];
            [albumDetailView addGestureRecognizer:tapGesture];
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.tag = SEASON_VIEW_CELL_TOGGLE;
            button.alpha = 0.5;
            button.frame = CGRectMake(0, 0, TOGGLE_BUTTON_SIZE, TOGGLE_BUTTON_SIZE);
            button.center = CGPointMake(thumbImageView.frame.origin.x / 2, thumbImageView.center.y);
            [button setImage:[UIImage imageNamed:@"arrow_close"] forState:UIControlStateNormal];
            [button setImage:[UIImage imageNamed:@"arrow_open"] forState:UIControlStateSelected];
            button.selected = [self.sectionArrayOpen[section] boolValue];
            [albumDetailView addSubview:button];
        }
        return albumDetailView;
    }

    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    
    // Draw gray bar as section header background
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, sectionHeight)];
    sectionView.backgroundColor = [Utilities getSystemGray5];
    
    // Draw text into section header
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(LABEL_PADDING, 0, viewWidth - 2 * LABEL_PADDING, sectionHeight)];
    label.backgroundColor = UIColor.clearColor;
    label.textColor = [Utilities get2ndLabelColor];
    label.font = [UIFont boldSystemFontOfSize:sectionHeight - 10];
    label.text = sectionTitle;
    label.autoresizingMask = UIViewAutoresizingFlexibleHeight |
                             UIViewAutoresizingFlexibleWidth |
                             UIViewAutoresizingFlexibleLeftMargin |
                             UIViewAutoresizingFlexibleRightMargin |
                             UIViewAutoresizingFlexibleTopMargin |
                             UIViewAutoresizingFlexibleBottomMargin;
    [sectionView addSubview:label];
    
    return sectionView;
}

- (void)layoutSectionView:(UIView*)albumDetailView thumbView:(UIImageView*)thumbImageView thumbURL:(NSString*)stringURL fanartURL:(NSString*)fanartURL artistText:(NSString*)artistText albumText:(NSString*)albumText releasedText:(NSString*)releasedText trackCountText:(NSString*)trackCountText isWatched:(BOOL)isWatched isTopMost:(BOOL)isTopMost {
    UILabel *artist = [UILabel new];
    UILabel *album = [UILabel new];
    UILabel *trackCount = [UILabel new];
    UILabel *released = [UILabel new];
    UIButton *albumInfoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    // Set dimensions for thumb view
    int thumbHeight = albumViewHeight - albumViewPadding * 2;
    int thumbWidth = episodesView ? (int)(thumbHeight * 0.67) : thumbHeight;
    
    // Set main layout root parameters
    CGFloat toggleIconSpace = episodesView ? LABEL_PADDING : 0;
    CGFloat originX = thumbWidth + albumViewPadding * 2 + toggleIconSpace;
    CGFloat labelwidth = viewWidth - originX - LABEL_PADDING;
    
    // Layout for thumb
    thumbImageView.frame = CGRectMake(albumViewPadding + toggleIconSpace, albumViewPadding, thumbWidth, thumbHeight);
    thumbImageView.userInteractionEnabled = episodesView ? NO : YES;
    thumbImageView.clipsToBounds = YES;
    thumbImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    // Load fanart, if present
    if (fanartURL.length) {
        CGFloat topExpansion = isTopMost ? self.searchController.searchBar.frame.size.height : 0;
        UIImageView *fanartBackgroundImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, -topExpansion, viewWidth, albumViewHeight + topExpansion)];
        fanartBackgroundImage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        fanartBackgroundImage.contentMode = UIViewContentModeScaleAspectFill;
        fanartBackgroundImage.alpha = 0.1;
        fanartBackgroundImage.clipsToBounds = YES;
        [fanartBackgroundImage sd_setImageWithURL:[NSURL URLWithString:fanartURL]
                                 placeholderImage:[UIImage imageNamed:@"blank"]];
        [albumDetailView addSubview:fanartBackgroundImage];
    }
    
    // Load the thumb image and set the colors for the labels
    NSString *displayThumb = episodesView ? @"coverbox_back_section" : @"coverbox_back";
    [Utilities applyRoundedEdgesView:thumbImageView];
    if (stringURL.length) {
        // In few cases stringURL does not hold an URL path but a loadable icon name. In this case
        // ensure setImageWithURL falls back to this icon.
        if ([UIImage imageNamed:stringURL]) {
            displayThumb = stringURL;
        }
        [thumbImageView sd_setImageWithURL:[NSURL URLWithString:stringURL]
                          placeholderImage:[UIImage imageNamed:displayThumb]
                              completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *url) {
            [self setViewColor:albumDetailView
                         image:thumbImageView.image
                     isTopMost:isTopMost
                        label1:artist
                        label2:album
                        label3:trackCount
                        label4:released
                    infoButton:albumInfoButton];
        }];
    }
    else {
        thumbImageView.image = [UIImage imageNamed:displayThumb];
        [self setViewColor:albumDetailView
                     image:thumbImageView.image
                 isTopMost:isTopMost
                    label1:artist
                    label2:album
                    label3:trackCount
                    label4:released
                infoButton:albumInfoButton];
    }
    [albumDetailView addSubview:thumbImageView];
    
    // Add watched overlay icon to lower right corner of thumb
    UIImageView *watchedIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ACImageNameOverlayWatched]];
    watchedIcon.frame = CGRectMake(CGRectGetMaxX(thumbImageView.frame) - FLAG_SIZE / 2 - TINY_PADDING,
                                   CGRectGetMaxY(thumbImageView.frame) - FLAG_SIZE - TINY_PADDING,
                                   CGRectGetWidth(watchedIcon.frame),
                                   CGRectGetHeight(watchedIcon.frame));
    watchedIcon.hidden = !isWatched;
    [albumDetailView addSubview:watchedIcon];
    
    // Add Info button to bottom-right corner
    albumInfoButton.alpha = 0.8;
    albumInfoButton.showsTouchWhenHighlighted = YES;
    albumInfoButton.frame = CGRectMake(albumDetailView.bounds.size.width - INFO_BUTTON_SIZE,
                                       albumDetailView.bounds.size.height - INFO_BUTTON_SIZE - TINY_PADDING,
                                       INFO_BUTTON_SIZE,
                                       INFO_BUTTON_SIZE);
    albumInfoButton.tag = episodesView ? DETAIL_VIEW_INFO_TVSHOW : DETAIL_VIEW_INFO_ALBUM;
    albumInfoButton.hidden = [self isModal];
    [albumInfoButton addTarget:self action:@selector(prepareShowAlbumInfo:) forControlEvents:UIControlEventTouchUpInside];
    [albumDetailView addSubview:albumInfoButton];
    
    // Top down
    // Layout for artist
    artist.text = artistText;
    artist.font = [UIFont systemFontOfSize:artistFontSize];
    artist.frame = CGRectMake(originX, albumViewPadding, labelwidth, LABEL_HEIGHT(artist.font));
    artist.backgroundColor = UIColor.clearColor;
    artist.shadowOffset = CGSizeMake(0, 1);
    artist.numberOfLines = 1;
    artist.lineBreakMode = NSLineBreakByTruncatingTail;
    artist.adjustsFontSizeToFitWidth = YES;
    artist.minimumScaleFactor = FONT_SCALING_DEFAULT;
    [albumDetailView addSubview:artist];
    
    // Layout for album
    album.text = albumText;
    album.font = [UIFont boldSystemFontOfSize:albumFontSize];
    album.frame = CGRectMake(originX, CGRectGetMaxY(artist.frame) + TINY_PADDING, labelwidth, 2 * LABEL_HEIGHT(album.font));
    album.backgroundColor = UIColor.clearColor;
    album.shadowOffset = CGSizeMake(0, 1);
    album.numberOfLines = 2;
    album.lineBreakMode = NSLineBreakByTruncatingTail;
    album.adjustsFontSizeToFitWidth = YES;
    album.minimumScaleFactor = FONT_SCALING_DEFAULT;
    [album sizeToFit];
    [albumDetailView addSubview:album];
    
    // Bottom up
    CGFloat labelWidthBottom = CGRectGetMinX(albumInfoButton.frame) - originX;
    
    // Layout for track count
    trackCount.text = trackCountText;
    trackCount.font = [UIFont systemFontOfSize:trackCountFontSize];
    trackCount.frame = CGRectMake(originX, albumViewHeight - albumViewPadding - LABEL_HEIGHT(trackCount.font), labelWidthBottom, LABEL_HEIGHT(trackCount.font));
    trackCount.backgroundColor = UIColor.clearColor;
    trackCount.shadowOffset = CGSizeMake(0, 1);
    trackCount.numberOfLines = 1;
    trackCount.lineBreakMode = NSLineBreakByTruncatingTail;
    trackCount.minimumScaleFactor = FONT_SCALING_MIN;
    trackCount.adjustsFontSizeToFitWidth = YES;
    [albumDetailView addSubview:trackCount];
    
    // Layout for released date
    released.text = releasedText;
    released.font = [UIFont systemFontOfSize:trackCountFontSize];
    released.frame = CGRectMake(originX, CGRectGetMinY(trackCount.frame) - LABEL_HEIGHT(released.font) - TINY_PADDING, labelWidthBottom, LABEL_HEIGHT(released.font));
    released.backgroundColor = UIColor.clearColor;
    released.shadowOffset = CGSizeMake(0, 1);
    released.numberOfLines = 1;
    released.lineBreakMode = NSLineBreakByTruncatingTail;
    released.minimumScaleFactor = FONT_SCALING_MIN;
    released.adjustsFontSizeToFitWidth = YES;
    [albumDetailView addSubview:released];
}

- (void)addProgressBar:(UITableViewCell*)cell recDotSize:(CGFloat)dotSize {
    BroadcastProgressView *progressView = [BroadcastProgressView new];
    progressView.tag = EPG_VIEW_CELL_PROGRESSVIEW;
    progressView.hidden = YES;
    [cell.contentView addSubview:progressView];
    
    UIImageView *timerView = [[UIImageView alloc] initWithFrame:(CGRect){CGPointZero, CGSizeMake(dotSize, dotSize)}];
    timerView.image = [UIImage imageNamed:@"button_timer"];
    timerView.contentMode = UIViewContentModeScaleToFill;
    timerView.tag = EPG_VIEW_CELL_RECORDING_ICON;
    timerView.hidden = YES;
    timerView.backgroundColor = UIColor.clearColor;
    [cell.contentView addSubview:timerView];
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    if (albumView && self.richResults.count > 0) {
        return albumViewHeight;
    }
    else if (episodesView && self.richResults.count > 0 && ![self doesShowSearchResults]) {
        return albumViewHeight;
    }
    else if (section != 0 || [self doesShowSearchResults]) {
        return sectionHeight;
    }
    return 0;
}

#pragma mark - Content Filtering

- (UIImageView*)findHairlineImageViewUnder:(UIView*)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView*)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findHairlineImageViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}

- (id)getCell:(NSIndexPath*)indexPath {
    id cell = nil;
    if (enableCollectionView) {
        cell = [collectionView cellForItemAtIndexPath:indexPath];
    }
    else {
        cell = [dataList cellForRowAtIndexPath:indexPath];
    }
    return cell;
}

- (void)selectAtIndexPath:(NSIndexPath*)indexPath {
    if (enableCollectionView) {
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    else {
        [dataList selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)deselectAtIndexPath:(NSIndexPath*)indexPath {
    if (enableCollectionView) {
        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    else {
        [dataList deselectRowAtIndexPath:indexPath animated:NO];
    }
}

#pragma mark - Long Press & Action sheet

- (void)showActionSheet:(NSIndexPath*)indexPath sheetActions:(NSArray*)sheetActions item:(NSDictionary*)item origin:(CGPoint)sheetOrigin {
    if (sheetActions.count) {
        NSString *title = [self buildActionSheetTitle:item];
        [self showActionSheetWithTitle:title sheetActions:sheetActions item:item origin:sheetOrigin fromview:self.view];
    }
    else if (indexPath != nil) { // No actions found, revert back to standard play action
        [self startPlayback:item indexPath:indexPath shuffle:NO];
        forceMusicAlbumMode = NO;
    }
}

- (void)longPressSeason:(UILongPressGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        NSInteger section = [sender.view tag];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
        NSMutableDictionary *item = [[self getItemFromIndexPath:indexPath] mutableCopy];
        [item removeObjectForKey:@"file"]; // A season is not a file, avoids adding "Share" option.
        
        processAllItemsInSection = @(section);
        NSInteger seasonIdx = [self indexOfObjectWithSeason:[NSString stringWithFormat:@"%d", [item[@"season"] intValue]] inArray:self.extraSectionRichResults];
        
        if (seasonIdx != NSNotFound) {
            NSArray *sheetActions = @[
                LOCALIZED_STR(@"Queue after current"),
                LOCALIZED_STR(@"Queue"),
                LOCALIZED_STR(@"Play"),
            ];
            NSString *title = [Utilities getStringFromItem:item[@"genre"]];
            NSString *season = self.extraSectionRichResults[seasonIdx][@"label"];
            if (season.length) {
                title = [NSString stringWithFormat:@"%@\n%@", title, season];
            }
            
            UIView *showFromView = self.view;
            CGPoint sheetOrigin = [sender locationInView:showFromView];
            [self showActionSheetWithTitle:title sheetActions:sheetActions item:item origin:sheetOrigin fromview:showFromView];
        }
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)activeRecognizer {
    if (activeRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint selectedPointInView = [activeRecognizer locationInView:activeLayoutView];
        NSIndexPath *indexPath = nil;
        if (enableCollectionView) {
            indexPath = [collectionView indexPathForItemAtPoint:selectedPointInView];
        }
        else {
            indexPath = [dataList indexPathForRowAtPoint:selectedPointInView];
        }
        
        if (indexPath != nil) {
            selectedIndexPath = indexPath;
            
            NSDictionary *item = [self getItemFromIndexPath:indexPath];
            mainMenu *menuItem = [self getMainMenu:item];
            int activeTab = [self getActiveTab:item];
            NSMutableArray *sheetActions = [menuItem.sheetActions[activeTab] mutableCopy];
            if (sheetActions.count) {
                sheetActions = [self getPlaylistActions:sheetActions item:item params:menuItem.mainParameters[activeTab]];
                NSString *title = [self buildActionSheetTitle:item];
                UIView *showFromView = self.view;
                CGPoint sheetOrigin = [activeRecognizer locationInView:showFromView];
                [self showActionSheetWithTitle:title sheetActions:sheetActions item:item origin:sheetOrigin fromview:showFromView];
            }
        }
    }
}

- (void)showActionSheetWithTitle:(NSString*)title sheetActions:(NSArray*)sheetActions item:(NSDictionary*)item origin:(CGPoint)origin fromview:(UIView*)fromview {
    BOOL isRecording = [self isTimerActiveForItem:item];
    if (sheetActions.count) {
        UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *action_cancel = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            forceMusicAlbumMode = NO;
        }];
        
        // Trim action list
        NSMutableArray *mutableActions = [sheetActions mutableCopy];
        if ([item[@"trailer"] length] > 0) {
            [mutableActions addObject:LOCALIZED_STR(@"Play Trailer")];
        }
        if ([item[@"family"] isEqualToString:@"movieid"] ||
            [item[@"family"] isEqualToString:@"episodeid"] ||
            [item[@"family"] isEqualToString:@"musicvideoid"] ||
            [item[@"family"] isEqualToString:@"tvshowid"]) {
            NSString *actionString = [item[@"playcount"] intValue] == 0 ? LOCALIZED_STR(@"Mark as watched") : LOCALIZED_STR(@"Mark as unwatched");
            [mutableActions addObject:actionString];
        }
        if (![VersionCheck hasPlayUsingSupport]) {
            [mutableActions removeObject:LOCALIZED_STR(@"Play using...")];
        }
        if ([item[@"file"] length] > 0 && ![item[@"filetype"] isEqualToString:@"directory"]) {
            [mutableActions addObject:LOCALIZED_STR(@"Share")];
        }
        
        // Convert action list to actions
        for (NSString *actionName in mutableActions) {
            NSString *actiontitle = actionName;
            if ([actiontitle isEqualToString:LOCALIZED_STR(@"Record")] && isRecording) {
                actiontitle = LOCALIZED_STR(@"Stop Recording");
            }
            UIAlertAction *action = [UIAlertAction actionWithTitle:actiontitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self actionSheetHandler:actiontitle origin:origin fromview:fromview];
            }];
            [alertCtrl addAction:action];
        }
        [alertCtrl addAction:action_cancel];
        alertCtrl.modalPresentationStyle = UIModalPresentationPopover;
        
        UIViewController *fromctrl = [Utilities topMostController];
        UIPopoverPresentationController *popPresenter = [alertCtrl popoverPresentationController];
        if (popPresenter != nil) {
            popPresenter.sourceView = fromview;
            popPresenter.sourceRect = CGRectMake(origin.x, origin.y, 1, 1);
        }
        [fromctrl presentViewController:alertCtrl animated:YES completion:nil];
    }
}

- (NSString*)buildActionSheetTitle:(NSDictionary*)item {
    NSString *label = [Utilities getStringFromItem:item[@"label"]];
    NSString *genre = [item[@"filetype"] length] ? @"" : [Utilities getStringFromItem:item[@"genre"]];
    NSString *album = [item[@"family"] isEqualToString:@"songid"] ? [Utilities getStringFromItem:item[@"album"]] : @"";
    
    NSString *newLine1 = genre.length ? @"\n" : @"";
    NSString *newLine2 = album.length ? @"\n" : @"";
    NSString *title = [NSString stringWithFormat:@"%@%@%@%@%@", label, newLine1, genre, newLine2, album];
    return title;
}

- (void)markVideo:(NSMutableDictionary*)item indexPath:(NSIndexPath*)indexPath watched:(int)watched {
    UIActivityIndicatorView *cellActivityIndicator = [self getCellActivityIndicator:indexPath];
    [cellActivityIndicator startAnimating];

    NSString *methodToCall = @"";
    NSString *family = item[@"family"];
    if ([family isEqualToString:@"tvshowid"]) {
        methodToCall = @"VideoLibrary.SetEpisodeDetails";
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:item[@"tvshowid"], @"tvshowid", @[@"season", @"episode"], @"properties", nil];
        [[Utilities getJsonRPC]
         callMethod:@"VideoLibrary.GetEpisodes"
         withParameters:params
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
            if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSDictionary class]]) {
                // Set the playcount for each episode of the TV Show (fire-and-forget, no error check)
                for (id arrayItem in methodResult[@"episodes"]) {
                    if ([arrayItem isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                                arrayItem[@"episodeid"], @"episodeid",
                                                @(watched), @"playcount",
                                                nil];
                        [[Utilities getJsonRPC]
                         callMethod:methodToCall
                         withParameters:params
                         onCompletion:nil];
                    }
                }
                [self updateCellAndSaveRichData:indexPath watched:watched item:item];
            }
            [cellActivityIndicator stopAnimating];
         }];
        return;
    }
    else if ([family isEqualToString:@"episodeid"]) {
        methodToCall = @"VideoLibrary.SetEpisodeDetails";
    }
    else if ([family isEqualToString:@"movieid"]) {
        methodToCall = @"VideoLibrary.SetMovieDetails";
    }
    else if ([family isEqualToString:@"musicvideoid"]) {
        methodToCall = @"VideoLibrary.SetMusicVideoDetails";
    }
    else {
        [cellActivityIndicator stopAnimating];
        return;
    }
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            item[family], family,
                            @(watched), @"playcount",
                            nil];
    [[Utilities getJsonRPC]
     callMethod:methodToCall
     withParameters:params
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
         if (error == nil && methodError == nil) {
             // Important: First call updateCellAndSaveRichData to set the updated playcount. Then send the trigger to update the views.
             [self updateCellAndSaveRichData:indexPath watched:watched item:item];
             if (episodesView || tvshowsView) {
                  [[NSNotificationCenter defaultCenter] postNotificationName:@"PlaycountChanged" object:nil];
             }
         }
        [cellActivityIndicator stopAnimating];
     }];
}

- (void)updateCellAndSaveRichData:(NSIndexPath*)indexPath watched:(int)watched item:(id)item {
    id cell = [self getCell:indexPath];
    BOOL wasWatched = watched > 0;
    
    // Set or unset the ckeck mark icon
    if (enableCollectionView) {
        [cell setOverlayWatched:wasWatched];
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    else {
        UIImageView *flagView = (UIImageView*)[cell viewWithTag:XIB_JSON_DATA_CELL_WATCHED_FLAG];
        flagView.hidden = !wasWatched;
        [dataList deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    // Set the new playcount for the item inside the rich data
    item[@"playcount"] = @(watched);
    
    // Store the rich data
    mainMenu *menuItem = [self getMainMenu:item];
    int activeTab = [self getActiveTab:item];
    NSDictionary *parameters = menuItem.mainParameters[activeTab];
    NSMutableDictionary *mutableParameters = [parameters[@"parameters"] mutableCopy];
    NSMutableArray *mutableProperties = [parameters[@"parameters"][@"properties"] mutableCopy];
    if ([parameters[@"FrodoExtraArt"] boolValue] && AppDelegate.instance.serverVersion > 11) {
        [mutableProperties addObject:@"art"];
        mutableParameters[@"properties"] = mutableProperties;
    }
    [self addFileProperties:mutableParameters];
    [self saveData:mutableParameters];
}

- (void)saveSortMethod:(NSString*)sortMethod parameters:(NSDictionary*)parameters {
    mainMenu *menuItem = self.detailItem;
    NSDictionary *methods = menuItem.mainMethod[chosenTab];
    NSString *sortKey = [NSString stringWithFormat:@"%@_sort_method", [self getCacheKey:methods[@"method"] parameters:[parameters mutableCopy]]];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:sortMethod forKey:sortKey];
}

- (void)saveSortAscDesc:(NSString*)sortAscDescSave parameters:(NSDictionary*)parameters {
    mainMenu *menuItem = self.detailItem;
    NSDictionary *methods = menuItem.mainMethod[chosenTab];
    NSString *sortKey = [NSString stringWithFormat:@"%@_sort_ascdesc", [self getCacheKey:methods[@"method"] parameters:[parameters mutableCopy]]];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:sortAscDescSave forKey:sortKey];
}

- (void)actionSheetHandler:(NSString*)actiontitle origin:(CGPoint)origin fromview:(UIView*)fromview {
    NSDictionary *item = nil;
    if (processAllItemsInSection) {
        selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:[processAllItemsInSection longValue]];
    }
    if (selectedIndexPath != nil) {
        item = [self getItemFromIndexPath:selectedIndexPath];
        if (item == nil) {
            return;
        }
    }
    mainMenu *menuItem = [self getMainMenu:item];
    int activeTab = [self getActiveTab:item];
    if ([actiontitle isEqualToString:LOCALIZED_STR(@"Play")]) {
        NSDictionary *mainFields = menuItem.mainFields[activeTab];
        int playlistid = [mainFields[@"playlistid"] intValue];
        if (playlistid == PLAYERID_PICTURES) {
            [self startSlideshow:item indexPath:selectedIndexPath];
        }
        else {
            [self startPlayback:item indexPath:selectedIndexPath shuffle:NO];
        }
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Play using...")]) {
        [[Utilities getJsonRPC] callMethod:@"Player.GetPlayers" withParameters:@{} onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
            if (error == nil && methodError == nil) {
                NSArray *sheetActions = [self getSupportedPlayers:methodResult forItem:item];
                if (!sheetActions.count) {
                    [Utilities showMessage:LOCALIZED_STR(@"Cannot do that") color:ERROR_MESSAGE_COLOR];
                    return;
                }
                UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:LOCALIZED_STR(@"Play using...") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                
                UIAlertAction *action_cancel = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    forceMusicAlbumMode = NO;
                }];
                
                for (NSString *actiontitle in sheetActions) {
                    UIAlertAction *action = [UIAlertAction actionWithTitle:actiontitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        [self startPlayback:item indexPath:selectedIndexPath using:actiontitle shuffle:NO];
                    }];
                    [alertCtrl addAction:action];
                }
                [alertCtrl addAction:action_cancel];
                alertCtrl.modalPresentationStyle = UIModalPresentationPopover;
                
                UIViewController *fromctrl = [Utilities topMostController];
                UIPopoverPresentationController *popPresenter = [alertCtrl popoverPresentationController];
                if (popPresenter != nil) {
                    popPresenter.sourceView = fromview;
                    popPresenter.sourceRect = CGRectMake(origin.x, origin.y, 1, 1);
                }
                [fromctrl presentViewController:alertCtrl animated:YES completion:nil];
            }
        }];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Share")]) {
        [self shareItem:item indexPath:selectedIndexPath];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Record")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Stop Recording")]) {
        [self recordChannel:item indexPath:selectedIndexPath];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Delete timer")]) {
        [self deleteTimer:item indexPath:selectedIndexPath];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Play in shuffle mode")]) {
        [self startPlayback:item indexPath:selectedIndexPath shuffle:YES];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Queue")]) {
        [self addQueue:item indexPath:selectedIndexPath];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Queue after current")]) {
        [self addQueue:item indexPath:selectedIndexPath afterCurrentItem:YES];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Show Content")]) {
        [self exploreItem:item];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Channel Guide")]) {
        [self viewChild:selectedIndexPath item:item displayPoint:CGPointMake(0, 0)];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Mark as watched")]) {
        [self markVideo:(NSMutableDictionary*)item indexPath:selectedIndexPath watched:1];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Mark as unwatched")]) {
        [self markVideo:(NSMutableDictionary*)item indexPath:selectedIndexPath watched:0];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Play in party mode")]) {
        [self partyModeItem:item indexPath:selectedIndexPath];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Artist Details")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Album Details")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Movie Details")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Movie Set Details")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Episode Details")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"TV Show Details")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Music Video Details")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Broadcast Details")]) {
        if (forceMusicAlbumMode) {
            [self prepareShowAlbumInfo:nil];
        }
        else {
            [self showInfo:selectedIndexPath menuItem:menuItem item:item tabToShow:activeTab];
        }
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Play Trailer")]) {
        NSDictionary *itemParams = @{
            @"item": [NSDictionary dictionaryWithObjectsAndKeys:item[@"trailer"], @"file", nil],
        };
        [self playerOpen:itemParams index:selectedIndexPath];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Search Wikipedia")]) {
        [self searchWeb:item indexPath:selectedIndexPath serviceURL:[NSString stringWithFormat:@"http://%@.m.wikipedia.org/wiki?search=%%@", LOCALIZED_STR(@"WIKI_LANG")]];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Search last.fm charts")]) {
        [self searchWeb:item indexPath:selectedIndexPath serviceURL:@"http://m.last.fm/music/%@/+charts?subtype=tracks&rangetype=6month&go=Go"];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Execute program")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Execute add-on")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Execute video add-on")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Execute audio add-on")]) {
        [self SimpleAction:@"Addons.ExecuteAddon"
                    params:[NSDictionary dictionaryWithObjectsAndKeys:
                            item[@"addonid"], @"addonid",
                            nil]
                   success:LOCALIZED_STR(@"Add-on executed successfully")
                   failure:LOCALIZED_STR(@"Unable to execute the add-on")
         ];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Execute action")]) {
        [self SimpleAction:@"Input.ExecuteAction"
                    params:[NSDictionary dictionaryWithObjectsAndKeys:
                            item[@"label"], @"action",
                            nil]
                   success:LOCALIZED_STR(@"Action executed successfully")
                   failure:LOCALIZED_STR(@"Unable to execute the action")
         ];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Activate window")]) {
        [self SimpleAction:@"GUI.ActivateWindow"
                    params:[NSDictionary dictionaryWithObjectsAndKeys:
                            item[@"label"], @"window",
                            nil]
                   success:LOCALIZED_STR(@"Window activated successfully")
                   failure:LOCALIZED_STR(@"Unable to activate the window")
         ];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Add button")]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                item[@"addonid"], @"addonid",
                                nil];
        NSDictionary *newButton = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   item[@"label"], @"label",
                                   @"xbmc-exec-addon", @"type",
                                   item[@"thumbnail"], @"icon",
                                   @(0), @"xbmcSetting",
                                   item[@"genre"], @"helpText",
                                   [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"Addons.ExecuteAddon", @"command",
                                    params, @"params",
                                    nil], @"action",
                                   nil];
        [self saveCustomButton:newButton];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Add action button")]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                item[@"label"], @"action",
                                nil];
        NSDictionary *newButton = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   item[@"label"], @"label",
                                   @"string", @"type",
                                   @"", @"icon",
                                   @(0), @"xbmcSetting",
                                   item[@"genre"], @"helpText",
                                   [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"Input.ExecuteAction", @"command",
                                    params, @"params",
                                    nil], @"action",
                                   nil];
        [self saveCustomButton:newButton];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Add window activation button")]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                item[@"label"], @"window",
                                nil];
        NSDictionary *newButton = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   item[@"label"], @"label",
                                   @"string", @"type",
                                   @"", @"icon",
                                   @(0), @"xbmcSetting",
                                   item[@"genre"], @"helpText",
                                   [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"GUI.ActivateWindow", @"command",
                                    params, @"params",
                                    nil], @"action",
                                   nil];
        [self saveCustomButton:newButton];
    }
    else {
        NSDictionary *parameters = menuItem.mainParameters[activeTab];
        NSMutableDictionary *sortDictionary = parameters[@"available_sort_methods"];
        if (sortDictionary[@"label"] != nil) {
            // In case of random still find index despite leading @"\u2713". This avoids inversion of sort order.
            NSString *targetedAction = [actiontitle containsString:LOCALIZED_STR(@"Random")] ? LOCALIZED_STR(@"Random") : actiontitle;
            NSUInteger sort_method_index = [sortDictionary[@"label"] indexOfObject:targetedAction];
            if (sort_method_index != NSNotFound) {
                if (sort_method_index < [sortDictionary[@"method"] count]) {
                    [activityIndicatorView startAnimating];
                    [UIView transitionWithView:activeLayoutView
                                      duration:0.2
                                       options:UIViewAnimationOptionBeginFromCurrentState
                                    animations:^{
                                        activeLayoutView.alpha = 1.0;
                                        CGRect frame = activeLayoutView.frame;
                                        frame.origin.x = viewWidth;
                                        frame.origin.y = 0;
                                        activeLayoutView.frame = frame;
                                    }
                                    completion:^(BOOL finished) {
                                        NSString *sortMethod = sortDictionary[@"method"][sort_method_index];
                                        sortMethodIndex = sort_method_index;
                                        sortMethodName = sortMethod;
                                        [self saveSortMethod:sortMethod parameters:[parameters mutableCopy]];
                                        storeSectionArray = [sectionArray copy];
                                        storeSections = [sections mutableCopy];
                                        self.sectionArray = nil;
                                        self.sections = [NSMutableDictionary new];
                                        [self indexAndDisplayData];
                                    }];
                }
            }
            else if ([actiontitle hasPrefix:@"\u2713"]) {
                [activityIndicatorView startAnimating];
                [UIView transitionWithView:activeLayoutView
                                  duration:0.2
                                   options:UIViewAnimationOptionBeginFromCurrentState
                                animations:^{
                                    activeLayoutView.alpha = 1.0;
                                    CGRect frame = activeLayoutView.frame;
                                    frame.origin.x = viewWidth;
                                    frame.origin.y = 0;
                                    activeLayoutView.frame = frame;
                                }
                                completion:^(BOOL finished) {
                                    sortAscDesc = !([sortAscDesc isEqualToString:@"ascending"] || sortAscDesc == nil) ? @"ascending" : @"descending";
                                    [self saveSortAscDesc:sortAscDesc parameters:[parameters mutableCopy]];
                                    storeSectionArray = [sectionArray copy];
                                    storeSections = [sections mutableCopy];
                                    self.sectionArray = nil;
                                    self.sections = [NSMutableDictionary new];
                                    [self indexAndDisplayData];
                                }];
            }
        }
    }
}

- (void)saveCustomButton:(NSDictionary*)button {
    customButton *arrayButtons = [customButton new];
    [arrayButtons.buttons addObject:button];
    [arrayButtons saveData];
    [Utilities showMessage:LOCALIZED_STR(@"Button added") color:SUCCESS_MESSAGE_COLOR];
    if (IS_IPAD) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UIInterfaceCustomButtonAdded" object:nil];
    }
}

- (void)searchWeb:(NSDictionary*)item indexPath:(NSIndexPath*)indexPath serviceURL:(NSString*)serviceURL {
    mainMenu *menuItem = self.detailItem;
    if (menuItem.mainParameters.count > 0) {
        NSMutableDictionary *parameters = menuItem.mainParameters[0];
        if (parameters[@"fromWikipedia"] != [NSNull null]) {
            if ([parameters[@"fromWikipedia"] boolValue]) {
                [self goBack:nil];
                return;
            }
        }
    }
    NSString *phrase1 = item[@"label"];
    if (forceMusicAlbumMode) {
        phrase1 = self.navigationItem.title;
        forceMusicAlbumMode = NO;
    }
    NSString *phrase2 = item[@"genre"];
    NSString *searchString = [NSString stringWithFormat:@"%@%@%@",
                              phrase1,
                              (phrase1.length > 0 && phrase2.length > 0) ? @" " : @"",
                              phrase2];
    NSString *query = [searchString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *url = [NSString stringWithFormat:serviceURL, query];
    [Utilities SFloadURL:url fromctrl:self];
}

#pragma mark - UPNP

- (NSArray*)getSupportedPlayers:(NSArray*)listedPlayers forItem:(id)item {
    mainMenu *menuItem = [self getMainMenu:item];
    int activeTab = [self getActiveTab:item];
    NSDictionary *mainFields = menuItem.mainFields[activeTab];
    int playlistid = [mainFields[@"playlistid"] intValue];
    NSMutableArray *supportedPlayers = [NSMutableArray new];
    for (NSDictionary *player in listedPlayers) {
        BOOL supportsAudio = [player[@"playsaudio"] boolValue];
        BOOL supportsVideo = [player[@"playsvideo"] boolValue];
        switch (playlistid) {
            case PLAYERID_MUSIC:
                if (supportsAudio) {
                    [supportedPlayers addObject:player[@"name"]];
                }
                break;
            case PLAYERID_PICTURES:
                if (supportsVideo) {
                    [supportedPlayers addObject:player[@"name"]];
                }
                break;
            case PLAYERID_VIDEO:
            default:
                if (supportsAudio && supportsVideo) {
                    [supportedPlayers addObject:player[@"name"]];
                }
                break;
        }
    }
    return [supportedPlayers copy];
}

#pragma mark - Safari

- (void)safariViewControllerDidFinish:(SFSafariViewController*)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Keyboard

- (void)hideKeyboard:(id)sender {
    [self.searchController.searchBar resignFirstResponder];
}

- (void)showKeyboard:(id)sender {
    // Show the keyboard if it was active when the view was shown last time. Remark: Only works with dalay!
    if (showkeyboard) {
        [[self getSearchTextField] performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.1];
    }
}

#pragma mark - View Configuration

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    mainMenu *menuItem = self.detailItem;
    if (menuItem && !menuItem.disableNavbarButtons) {
        topNavigationLabel = [UILabel new];
        topNavigationLabel.backgroundColor = UIColor.clearColor;
        topNavigationLabel.font = [UIFont boldSystemFontOfSize:11];
        topNavigationLabel.minimumScaleFactor = FONT_SCALING_DEFAULT;
        topNavigationLabel.numberOfLines = 2;
        topNavigationLabel.adjustsFontSizeToFitWidth = YES;
        topNavigationLabel.textAlignment = NSTextAlignmentLeft;
        topNavigationLabel.textColor = UIColor.whiteColor;
        topNavigationLabel.shadowColor = FONT_SHADOW_WEAK;
        topNavigationLabel.shadowOffset = CGSizeMake (0, -1);
        topNavigationLabel.highlightedTextColor = UIColor.blackColor;
        topNavigationLabel.opaque = YES;
        
        // Set up navigation bar items on upper right
        UIImage *remoteButtonImage = [UIImage imageNamed:@"icon_menu_remote"];
        UIBarButtonItem *remoteButton = [[UIBarButtonItem alloc] initWithImage:remoteButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(showRemote)];
        UIImage *nowPlayingButtonImage = [UIImage imageNamed:@"icon_menu_playing"];
        UIBarButtonItem *nowPlayingButton = [[UIBarButtonItem alloc] initWithImage:nowPlayingButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(showNowPlaying)];
        self.navigationItem.rightBarButtonItems = @[remoteButton,
                                                    nowPlayingButton];
    }
}

- (void)leaveFullscreen {
    if (stackscrollFullscreen) {
        [self toggleFullscreen];
    }
}

- (void)toggleFullscreen {
    if ([self doesShowSearchResults] || self.searchController.isActive) {
        [self.searchController setActive:NO];
    }
    [activityIndicatorView startAnimating];
    NSTimeInterval animDuration = 0.5;
    if (stackscrollFullscreen) {
        stackscrollFullscreen = NO;
        [UIView animateWithDuration:0.1
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            collectionView.alpha = 0;
            dataList.alpha = 0;
        }
                         completion:^(BOOL finished) {
            viewWidth = STACKSCROLL_WIDTH;
            button1.alpha = button2.alpha = button3.alpha = button4.alpha = button5.alpha = button6.alpha = button7.alpha = buttonsViewBgToolbar.alpha = buttonsViewEffect.alpha = topNavigationLabel.alpha = 1.0;
            if ([self collectionViewCanBeEnabled]) {
                button6.hidden = NO;
            }
            sectionArray = [storeSectionArray copy];
            sections = [storeSections mutableCopy];
            [self choseParams];
            if (forceCollection) {
                forceCollection = NO;
                [Utilities SetView:activeLayoutView Alpha:0.0 XPos:viewWidth];
                enableCollectionView = NO;
                [self configureLibraryView];
                [Utilities SetView:activeLayoutView Alpha:0.0 XPos:0];
            }
            [self setFlowLayoutParams];
            [collectionView.collectionViewLayout invalidateLayout];
            [collectionView reloadData];
            [collectionView setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
            NSDictionary *params = @{@"duration": @(animDuration)};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"StackScrollFullScreenDisabled" object:self.view userInfo:params];
            [UIView animateWithDuration:0.2
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                collectionView.alpha = 1;
                dataList.alpha = 1;
                [fullscreenButton setImage:[UIImage imageNamed:@"button_fullscreen"] forState:UIControlStateNormal];
                fullscreenButton.backgroundColor = UIColor.clearColor;
            }
                             completion:^(BOOL finished) {
                [activityIndicatorView stopAnimating];
            }
            ];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, animDuration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                moreItemsViewController.view.hidden = NO;
            });
        }
        ];
    }
    else {
        stackscrollFullscreen = YES;
        [UIView animateWithDuration:0.1
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            collectionView.alpha = 0;
            dataList.alpha = 0;
            button1.alpha = button2.alpha = button3.alpha = button4.alpha = button5.alpha = button6.alpha = button7.alpha = buttonsViewBgToolbar.alpha = buttonsViewEffect.alpha = topNavigationLabel.alpha = 0.0;
        }
                         completion:^(BOOL finished) {
            button6.hidden = YES;
            moreItemsViewController.view.hidden = YES;
            if (!enableCollectionView) {
                forceCollection = YES;
                [Utilities SetView:activeLayoutView Alpha:0.0 XPos:viewWidth];
                enableCollectionView = YES;
                [self configureLibraryView];
                [Utilities SetView:activeLayoutView Alpha:0.0 XPos:0];
            }
            else {
                forceCollection = NO;
            }
            storeSectionArray = [sectionArray copy];
            storeSections = [sections mutableCopy];
            [self choseParams];
            NSMutableDictionary *sectionsTemp = [NSMutableDictionary new];
            [sectionsTemp setValue:[NSMutableArray new] forKey:@""];
            for (id key in self.sectionArray) {
                NSDictionary *tmp = self.sections[key];
                for (NSDictionary *item in tmp) {
                    [sectionsTemp[@""] addObject:item];
                }
            }
            self.sectionArray = @[@""];
            self.sections = [sectionsTemp mutableCopy];
            [self setFlowLayoutParams];
            [collectionView.collectionViewLayout invalidateLayout];
            [collectionView reloadData];
            [collectionView setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
            [dataList setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
            NSDictionary *params = @{
                @"hideToolbar": @NO,
                @"duration": @(animDuration),
            };
            [[NSNotificationCenter defaultCenter] postNotificationName:@"StackScrollFullScreenEnabled" object:self.view userInfo:params];
            [UIView animateWithDuration:0.2
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                collectionView.alpha = 1;
                [fullscreenButton setImage:[UIImage imageNamed:@"button_exit_fullscreen"] forState:UIControlStateNormal];
                fullscreenButton.backgroundColor = [Utilities getGrayColor:0 alpha:0.5];
            }
                             completion:^(BOOL finished) {
                [activityIndicatorView stopAnimating];
            }
            ];
        }
        ];
    }
}

- (void)dismissAddAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showNowPlaying {
    NowPlaying *nowPlaying = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
    nowPlaying.detailItem = self.detailItem;
    [self.navigationController pushViewController:nowPlaying animated:YES];
}

- (void)showRemote {
    RemoteController *remote = [[RemoteController alloc] initWithNibName:@"RemoteController" bundle:nil];
    [self.navigationController pushViewController:remote animated:YES];
}

# pragma mark - Playback Management

- (void)partyModeItem:(NSDictionary*)item indexPath:(NSIndexPath*)indexPath {
    NSString *smartplaylist = item[@"file"];
    if (smartplaylist == nil) {
        return;
    }
    [self playerOpen:@{@"item": @{@"partymode": smartplaylist}} index:indexPath];
}

- (void)exploreItem:(NSDictionary*)item {
    mainMenu *menuItem = [self getMainMenu:item];
    int activeTab = [self getActiveTab:item];
    NSDictionary *mainFields = menuItem.mainFields[activeTab];
    NSMutableDictionary *parameters = menuItem.subItem.mainParameters[activeTab];
    NSNumber *libraryRowHeight = parameters[@"rowHeight"] ?: @(menuItem.subItem.rowHeight);
    NSNumber *libraryThumbWidth = parameters[@"thumbWidth"] ?: @(menuItem.subItem.thumbWidth);
    NSNumber *filemodeRowHeight = parameters[@"rowHeight"] ?: @FILEMODE_ROW_HEIGHT;
    NSNumber *filemodeThumbWidth = parameters[@"thumbWidth"] ?: @FILEMODE_THUMB_WIDTH;
    NSMutableArray *mutableProperties = [parameters[@"parameters"][@"file_properties"] mutableCopy];
    if ([parameters[@"FrodoExtraArt"] boolValue] && AppDelegate.instance.serverVersion > 11) {
        [mutableProperties addObject:@"art"];
    }
    NSMutableDictionary *newParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           item[mainFields[@"row6"]], @"directory",
                                           parameters[@"parameters"][@"media"], @"media",
                                           parameters[@"parameters"][@"sort"], @"sort",
                                           mutableProperties, @"file_properties",
                                           nil], @"parameters",
                                          libraryRowHeight, @"rowHeight",
                                          libraryThumbWidth, @"thumbWidth",
                                          parameters[@"label"], @"label",
                                          @"nocover_filemode", @"defaultThumb",
                                          filemodeRowHeight, @"rowHeight",
                                          filemodeThumbWidth, @"thumbWidth",
                                          [NSDictionary dictionaryWithDictionary:parameters[@"itemSizes"]], @"itemSizes",
                                          @([parameters[@"enableCollectionView"] boolValue]), @"enableCollectionView",
                                          @"Files.GetDirectory", @"exploreCommand",
                                          @([parameters[@"disableFilterParameter"] boolValue]), @"disableFilterParameter",
                                          nil];
    [self enterSubmenuForItem:item params:newParameters];
}

- (void)deleteTimer:(NSDictionary*)item indexPath:(NSIndexPath*)indexPath {
    NSNumber *itemid = [Utilities getNumberFromItem:item[@"timerid"]];
    if ([itemid longValue] == 0) {
        return;
    }
    UIActivityIndicatorView *cellActivityIndicator = [self getCellActivityIndicator:indexPath];
    NSString *methodToCall = @"PVR.DeleteTimer";
    NSDictionary *parameters = @{@"timerid": itemid};

    [cellActivityIndicator startAnimating];
    [[Utilities getJsonRPC] callMethod:methodToCall
         withParameters:parameters
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
               [cellActivityIndicator stopAnimating];
               if (error == nil && methodError == nil) {
                   [self.searchController setActive:NO];
                   [Utilities AnimView:activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:viewWidth];
                   [self startRetrieveDataWithRefresh:YES];
               }
               else {
                   NSString *message = [Utilities formatClipboardMessage:methodToCall
                                                              parameters:parameters
                                                                   error:error
                                                             methodError:methodError];
                   UIAlertController *alertView = [Utilities createAlertCopyClipboard:LOCALIZED_STR(@"ERROR") message:message];
                   [self presentViewController:alertView animated:YES completion:nil];
               }
    }];
}

- (void)recordChannel:(NSDictionary*)item indexPath:(NSIndexPath*)indexPath {
    NSString *methodToCall = @"PVR.Record";
    NSString *parameterName = @"channel";
    NSNumber *itemid = [Utilities getNumberFromItem:item[@"channelid"]];
    NSNumber *storeChannelid = itemid;
    NSNumber *storeBroadcastid = [Utilities getNumberFromItem:item[@"broadcastid"]];
    if ([itemid longValue] == 0) {
        itemid = [Utilities getNumberFromItem:item[@"pvrExtraInfo"][@"channelid"]];
        if ([itemid longValue] == 0) {
            return;
        }
        storeChannelid = itemid;
        NSDate *starttime = [xbmcDateFormatter dateFromString:item[@"starttime"]];
        NSDate *endtime = [xbmcDateFormatter dateFromString:item[@"endtime"]];
        float percent_elapsed = [Utilities getPercentElapsed:starttime EndDate:endtime];
        if (percent_elapsed < 0) {
            itemid = [Utilities getNumberFromItem:item[@"broadcastid"]];
            storeBroadcastid = itemid;
            storeChannelid = @(0);
            methodToCall = @"PVR.ToggleTimer";
            parameterName = @"broadcastid";
        }
    }
    UIActivityIndicatorView *cellActivityIndicator = [self getCellActivityIndicator:indexPath];
    [cellActivityIndicator startAnimating];
    NSDictionary *parameters = @{parameterName: itemid};
    [[Utilities getJsonRPC] callMethod:methodToCall
         withParameters:parameters
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
               [cellActivityIndicator stopAnimating];
               if (error == nil && methodError == nil) {
                   id cell = [self getCell:indexPath];
                   UIImageView *timerView = (UIImageView*)[cell viewWithTag:EPG_VIEW_CELL_RECORDING_ICON];
                   NSNumber *status = @(![item[@"isrecording"] boolValue]);
                   if ([item[@"broadcastid"] longLongValue] > 0) {
                       status = @(![item[@"hastimer"] boolValue]);
                   }
                   NSDictionary *params = @{
                       @"channelid": storeChannelid,
                       @"broadcastid": storeBroadcastid,
                       @"status": status,
                   };
                   timerView.hidden = ![status boolValue];
                   [[NSNotificationCenter defaultCenter] postNotificationName:@"KodiServerRecordTimerStatusChange" object:nil userInfo:params];
               }
               else {
                   NSString *message = [Utilities formatClipboardMessage:methodToCall
                                                              parameters:parameters
                                                                   error:error
                                                             methodError:methodError];
                   UIAlertController *alertView = [Utilities createAlertCopyClipboard:LOCALIZED_STR(@"ERROR") message:message];
                   [self presentViewController:alertView animated:YES completion:nil];
               }
           }];
}

- (void)addQueue:(NSDictionary*)item indexPath:(NSIndexPath*)indexPath {
    [self addQueue:item indexPath:indexPath afterCurrentItem:NO];
}

- (void)addQueue:(NSDictionary*)item indexPath:(NSIndexPath*)indexPath afterCurrentItem:(BOOL)afterCurrent {
    UIActivityIndicatorView *cellActivityIndicator = [self getCellActivityIndicator:indexPath];
    [cellActivityIndicator startAnimating];
    mainMenu *menuItem = [self getMainMenu:item];
    int activeTab = [self getActiveTab:item];
    NSDictionary *mainFields = menuItem.mainFields[activeTab];
    if (forceMusicAlbumMode) {
        mainFields = AppDelegate.instance.playlistArtistAlbums.mainFields[0];
        forceMusicAlbumMode = NO;
    }
    int playlistid = [mainFields[@"playlistid"] intValue];
    id playlistItems = [self buildPlaylistItems:item key:mainFields[@"row9"]];
    if (!playlistItems) {
        [cellActivityIndicator stopAnimating];
        [Utilities showMessage:LOCALIZED_STR(@"Cannot do that") color:ERROR_MESSAGE_COLOR];
        return;
    }
    NSDictionary *playlistParams = @{
        @"playlistid": @(playlistid),
        @"item": playlistItems,
    };
    if (afterCurrent) {
        NSDictionary *params = @{
            @"playerid": @(playlistid),
            @"properties": @[@"percentage", @"time", @"totaltime", @"partymode", @"position"],
        };
        [[Utilities getJsonRPC]
         callMethod:@"Player.GetProperties"
         withParameters:params
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
             if (error == nil && methodError == nil) {
                 if ([methodResult isKindOfClass:[NSDictionary class]]) {
                     if ([methodResult count]) {
                         [cellActivityIndicator stopAnimating];
                         int newPos = [methodResult[@"position"] intValue] + 1;
                         NSString *action2 = @"Playlist.Insert";
                         NSDictionary *params2 = @{
                             @"playlistid": @(playlistid),
                             @"item": playlistItems,
                             @"position": @(newPos),
                         };
                         [[Utilities getJsonRPC] callMethod:action2 withParameters:params2 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                             if (error == nil && methodError == nil) {
                                 [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCPlaylistHasChanged" object:nil];
                             }
                         }];
                     }
                     else {
                         [self addToPlaylist:playlistParams indicator:cellActivityIndicator];
                     }
                 }
                 else {
                     [self addToPlaylist:playlistParams indicator:cellActivityIndicator];
                 }
             }
             else {
                [self addToPlaylist:playlistParams indicator:cellActivityIndicator];
             }
         }];
    }
    else {
        [self addToPlaylist:playlistParams indicator:cellActivityIndicator];
    }
}

- (void)addToPlaylist:(NSDictionary*)playlistParams indicator:(UIActivityIndicatorView*)cellActivityIndicator {
    [[Utilities getJsonRPC] callMethod:@"Playlist.Add" withParameters:playlistParams onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        [cellActivityIndicator stopAnimating];
        if (error == nil && methodError == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCPlaylistHasChanged" object:nil];
        }
    }];
    
}

- (void)playerOpen:(NSDictionary*)params index:(NSIndexPath*)indexPath {
    UIActivityIndicatorView *cellActivityIndicator = [self getCellActivityIndicator:indexPath];
    [self playerOpen:params indicator:cellActivityIndicator];
}

- (void)playerOpen:(NSDictionary*)params indicator:(UIActivityIndicatorView*)cellActivityIndicator {
    [cellActivityIndicator startAnimating];
    [[Utilities getJsonRPC] callMethod:@"Player.Open" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        [cellActivityIndicator stopAnimating];
        if (error == nil && methodError == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCPlaylistHasChanged" object:nil];
            [self showNowPlaying];
            [Utilities checkForReviewRequest];
        }
    }];
}

- (void)shareItem:(NSDictionary*)item indexPath:(NSIndexPath*)indexPath {
    [[Utilities getJsonRPC]
     callMethod:@"Files.PrepareDownload"
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys:item[@"file"], @"path", nil]
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (!error && !methodError) {
            GlobalData *obj = [GlobalData getInstance];
            NSString *serverURL = [NSString stringWithFormat:@"%@:%@/", obj.serverIP, obj.serverPort];
            NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, methodResult[@"details"][@"path"]];
            
            static dispatch_once_t once;
            static UIImageView *sharedImageView; // Must be static to exist when sd_setImageWithURL wants to return the image.
            dispatch_once(&once, ^{
                sharedImageView = [UIImageView new];
            });
            [sharedImageView sd_setImageWithURL:[NSURL URLWithString:item[@"thumbnail"]]
                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *url) {
                // Image is loaded, now create an show the share action sheet
                NSArray *activityItems = @[[[SharingActivityItemSource alloc] initWithUrlString:stringURL label:item[@"label"] image:image]];
                NSArray *excludeActivities = @[
                    UIActivityTypePostToFacebook,
                    UIActivityTypePostToTwitter,
                    UIActivityTypePostToVimeo,
                    UIActivityTypePostToWeibo,
                    UIActivityTypePostToTencentWeibo,
                    UIActivityTypePrint,
                    UIActivityTypeAddToReadingList,
                    UIActivityTypePostToFlickr,
                ];
                UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
                activityController.excludedActivityTypes = excludeActivities;
                
                // Origin of popover is the selected item
                UIView *itemCell = [self getCell:indexPath];
                
                // Position the source of the popover
                UIPopoverPresentationController *popPresenter = [activityController popoverPresentationController];
                if (popPresenter != nil) {
                    popPresenter.sourceView = itemCell;
                    popPresenter.sourceRect = itemCell.bounds;
                }
                [self presentViewController:activityController animated:YES completion:nil];
            }];
        }
    }];
}

- (void)startPlayback:(NSDictionary*)item indexPath:(NSIndexPath*)indexPath shuffle:(BOOL)shuffled {
    [self startPlayback:item indexPath:indexPath using:nil shuffle:shuffled];
}

- (void)startPlayback:(NSDictionary*)item indexPath:(NSIndexPath*)indexPath using:(NSString*)playername shuffle:(BOOL)shuffled {
    mainMenu *menuItem = [self getMainMenu:item];
    int activeTab = [self getActiveTab:item];
    NSDictionary *mainFields = menuItem.mainFields[activeTab];
    if (forceMusicAlbumMode) {
        mainFields = AppDelegate.instance.playlistArtistAlbums.mainFields[0];
        forceMusicAlbumMode = NO;
    }
    if (mainFields.count == 0) {
        return;
    }
    UIActivityIndicatorView *cellActivityIndicator = [self getCellActivityIndicator:indexPath];
    [cellActivityIndicator startAnimating];
    id optionsKey;
    id optionsValue;
    if (AppDelegate.instance.serverVersion > 11) {
        optionsKey = @"options";
        optionsValue = [NSDictionary dictionaryWithObjectsAndKeys:
                        @(shuffled), @"shuffled",
                        playername, @"playername",
                        nil];
    }
    id playlistItems = [self buildPlaylistItems:item key:mainFields[@"row9"]];
    if (!playlistItems) {
        [cellActivityIndicator stopAnimating];
        [Utilities showMessage:LOCALIZED_STR(@"Cannot do that") color:ERROR_MESSAGE_COLOR];
        return;
    }
    NSDictionary *playbackParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                    playlistItems, @"item",
                                    optionsValue, optionsKey,
                                    nil];
    if (shuffled && AppDelegate.instance.serverVersion > 11) {
        [[Utilities getJsonRPC]
         callMethod:@"Player.SetPartymode"
         withParameters:@{@"playerid": @(0), @"partymode": @NO}
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *internalError) {
            [self playerOpen:playbackParams indicator:cellActivityIndicator];
         }];
    }
    else {
        [self playerOpen:playbackParams indicator:cellActivityIndicator];
    }
}

- (void)startSlideshow:(NSDictionary*)item indexPath:(NSIndexPath*)indexPath {
    mainMenu *menuItem = [self getMainMenu:item];
    int activeTab = [self getActiveTab:item];
    NSDictionary *mainFields = menuItem.mainFields[activeTab];
    if (mainFields.count == 0) {
        return;
    }
    UIActivityIndicatorView *cellActivityIndicator = [self getCellActivityIndicator:indexPath];
    [cellActivityIndicator startAnimating];
    
    NSString *key = mainFields[@"row8"];
    id value = item[key];
    if ([item[@"filetype"] isEqualToString:@"directory"]) {
        key = @"directory";
    }
    if (!value || !key) {
        [cellActivityIndicator stopAnimating];
        [Utilities showMessage:LOCALIZED_STR(@"Cannot do that") color:ERROR_MESSAGE_COLOR];
        return;
    }
    NSDictionary *playbackParams = @{@"item": @{key: value}};
    
    // Usually we just send key:value as this fits the common use cases. But for picture folders we must
    // use "path", "random" and "recursive" to ensure the files are added to picture playlist, even if short
    // videos are included. Otherwise folders which have at least one video inside will completely be moved to
    // video playlist and pictures are skipped during playback. Random must be explictly set to off.
    if ([key isEqualToString:@"directory"]) {
        playbackParams = @{
            @"item": @{
                @"path": value,
                @"random": @NO,
                @"recursive": @YES,
            }
        };
    }
    [self playerOpen:playbackParams indicator:cellActivityIndicator];
}

- (id)buildPlaylistItems:(NSDictionary*)item key:(id)key {
    id value = item[key];
    if ([item[@"filetype"] isEqualToString:@"directory"]) {
        key = @"directory";
    }
    else if (processAllItemsInSection) {
        // Build the array of items to add to playlist
        int section = [processAllItemsInSection intValue];
        NSInteger countRows = [self.sections[self.sectionArray[section]] count];
        NSMutableArray *listedItems = [NSMutableArray arrayWithCapacity:countRows];
        for (int i = 0; i < countRows; ++i) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:section];
            NSDictionary *singleItem = [self getItemFromIndexPath:indexPath];
            if ([singleItem isKindOfClass:[NSDictionary class]] && singleItem[key]) {
                [listedItems addObject:singleItem[key]];
            }
        }
        value = listedItems;
        processAllItemsInSection = nil;
    }
    // If Playlist.Insert and Playlist.Add for recordingid is not supported, use file path.
    else if (![VersionCheck hasRecordingIdPlaylistSupport] && [key isEqualToString:@"recordingid"]) {
        key = @"file";
        value = item[@"file"];
    }
    else if ([key isEqualToString:@"channelid"] ||
             [key isEqualToString:@"broadcastid"]) {
        key = @"channelid";
        value = item[@"pvrExtraInfo"][@"channelid"] ?: item[@"channelid"];
    }
    if (!value || !key) {
        return nil;
    }
    // Build parameters to fill playlist
    id playlistItems;
    if ([value isKindOfClass:[NSMutableArray class]]) {
        playlistItems = [NSMutableArray arrayWithCapacity:[value count]];
        for (id arrayItem in value) {
            [playlistItems addObject:@{key: arrayItem}];
        }
    }
    else {
        playlistItems = @{key: value};
    }
    
    return playlistItems;
}

- (void)SimpleAction:(NSString*)action params:(NSDictionary*)parameters success:(NSString*)successMessage failure:(NSString*)failureMessage {
    [[Utilities getJsonRPC] callMethod:action withParameters:parameters onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil) {
            [Utilities showMessage:successMessage color:SUCCESS_MESSAGE_COLOR];
        }
        else {
            [Utilities showMessage:failureMessage color:ERROR_MESSAGE_COLOR];
        }
    }];
}

- (void)displayInfoView:(NSDictionary*)item {
    if (IS_IPHONE) {
        ShowInfoViewController *showInfoViewController = [[ShowInfoViewController alloc] initWithNibName:@"ShowInfoViewController" bundle:nil];
        showInfoViewController.detailItem = item;
        [self.navigationController pushViewController:showInfoViewController animated:YES];
    }
    else {
        ShowInfoViewController *iPadShowViewController = [[ShowInfoViewController alloc] initWithNibName:@"ShowInfoViewController" withItem:item withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
        if (stackscrollFullscreen || [self isModal]) {
            // Workaround: Deactivate search when accessing ShowInfoView and search is active.
            // If not done, selecting an item or requesting details will fail.
            if (stackscrollFullscreen && self.searchController.isActive) {
                [self.searchController setActive:NO];
            }
            
            iPadShowViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:iPadShowViewController animated:YES completion:nil];
        }
        else {
            [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:iPadShowViewController invokeByController:self isStackStartView:NO];
        }
    }
}

- (void)prepareShowAlbumInfo:(id)sender {
    mainMenu *menuItem = self.detailItem;
    if (menuItem.mainParameters.count > 0) {
        NSMutableDictionary *parameters = menuItem.mainParameters[0];
        if (parameters[@"fromShowInfo"] != [NSNull null]) {
            if ([parameters[@"fromShowInfo"] boolValue]) {
                [self goBack:nil];
                return;
            }
        }
    }
    menuItem = nil;
    if (!sender || [sender tag] == DETAIL_VIEW_INFO_ALBUM) {
        menuItem = [AppDelegate.instance.playlistArtistAlbums copy];
    }
    else if ([sender tag] == DETAIL_VIEW_INFO_TVSHOW) {
        menuItem = [AppDelegate.instance.playlistTvShows copy];
    }
    menuItem.subItem.mainLabel = self.navigationItem.title;
    menuItem.subItem.mainMethod = nil;
    if (self.richResults.count > 0) {
        [self.searchController.searchBar resignFirstResponder];
        [self showInfo:nil menuItem:menuItem item:self.richResults[0] tabToShow:0];
    }
}

- (void)showInfo:(NSIndexPath*)indexPath menuItem:(mainMenu*)menuItem item:(NSDictionary*)item tabToShow:(int)tabToShow {
    NSDictionary *methods = menuItem.mainMethod[tabToShow];
    NSDictionary *parameters = menuItem.mainParameters[tabToShow];
    
    NSMutableDictionary *mutableParameters = [parameters[@"extra_info_parameters"] mutableCopy];
    NSMutableArray *mutableProperties = [parameters[@"extra_info_parameters"][@"properties"] mutableCopy];
    
    if ([parameters[@"FrodoExtraArt"] boolValue] && AppDelegate.instance.serverVersion > 11) {
        [mutableProperties addObject:@"art"];
        mutableParameters[@"properties"] = mutableProperties;
    }
    if (parameters[@"extra_info_parameters"] != nil && methods[@"extra_info_method"] != nil) {
        [self retrieveExtraInfoData:methods[@"extra_info_method"] parameters:mutableParameters index:indexPath item:item menuItem:menuItem tabToShow:tabToShow];
    }
    else {
        [self displayInfoView:item];
    }
}

- (void)showAlbumActions:(UITapGestureRecognizer*)tap {
    if (self.sectionArray.count == 0) {
        return;
    };
    id sectionKey = self.sectionArray[0];
    id sectionItem = [self.sections[sectionKey] firstObject];
    if (!sectionItem) {
        return;
    };
    NSMutableArray *sheetActions = [[mainMenu action_album] mutableCopy];
    selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    NSMutableDictionary *item = [sectionItem mutableCopy];
    item[@"label"] = self.navigationItem.title;
    [item removeObjectForKey:@"file"]; // An album is not a file, avoids adding "Share" option.
    forceMusicAlbumMode = YES;
    CGFloat rectOrigin = floor((albumViewHeight - albumViewPadding * 2) / 2);
    CGPoint sheetOrigin = CGPointMake(rectOrigin + albumViewPadding, rectOrigin);
    [self showActionSheet:nil sheetActions:sheetActions item:item origin:sheetOrigin];
}

# pragma mark - JSON DATA Management

- (void)checkExecutionTime {
    if (startTime != 0) {
        elapsedTime += [NSDate timeIntervalSinceReferenceDate] - startTime;
    }
    startTime = [NSDate timeIntervalSinceReferenceDate];
    if (elapsedTime > WARNING_TIMEOUT && longTimeout == nil) {
        NSMutableArray *monkeys = [NSMutableArray arrayWithCapacity:MONKEY_COUNT];
        for (int i = 1; i <= MONKEY_COUNT; ++i) {
            [monkeys addObject:[UIImage imageNamed:[NSString stringWithFormat:@"monkeys_%d", i]]];
        }
        UIImage *image = monkeys[0];
        longTimeout = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
        longTimeout.animationImages = monkeys;
        longTimeout.animationDuration = 5.0;
        longTimeout.animationRepeatCount = 0;
        longTimeout.center = activityIndicatorView.center;
        CGRect frame = longTimeout.frame;
        frame.origin.y = CGRectGetMaxY(activityIndicatorView.frame);
        frame.origin.x -= MONKEY_OFFSET_X;
        longTimeout.frame = frame;
        [longTimeout startAnimating];
        [self.view addSubview:longTimeout];
    }
}

// retrieveData and retrieveExtraInfoData should be unified in an unique method!

- (void)retrieveExtraInfoData:(NSString*)methodToCall parameters:(NSDictionary*)parameters index:(NSIndexPath*)indexPath item:(NSDictionary*)item menuItem:(mainMenu*)menuItem tabToShow:(int)tabToShow {
    NSDictionary *mainFields = menuItem.mainFields[tabToShow];
    NSString *itemid = [Utilities getStringFromItem:mainFields[@"row6"]];
    id object = item[itemid];
    if (!object) {
        return; // something goes wrong
    }
    
    UIActivityIndicatorView *cellActivityIndicator = [self getCellActivityIndicator:indexPath];
    [cellActivityIndicator startAnimating];
    
    NSMutableArray *newProperties = [parameters[@"properties"] mutableCopy];
    if (parameters[@"kodiExtrasPropertiesMinimumVersion"] != nil) {
        for (id key in parameters[@"kodiExtrasPropertiesMinimumVersion"]) {
            if (AppDelegate.instance.serverVersion >= [key integerValue]) {
                id arrayProperties = parameters[@"kodiExtrasPropertiesMinimumVersion"][key];
                for (id value in arrayProperties) {
                    [newProperties addObject:value];
                }
            }
        }
    }
    NSMutableDictionary *newParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          newProperties, @"properties",
                                          object, itemid,
                                          nil];
    [[Utilities getJsonRPC]
     callMethod:methodToCall
     withParameters:newParameters
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
         [cellActivityIndicator stopAnimating];
         if (error == nil && methodError == nil) {
             if ([methodResult isKindOfClass:[NSDictionary class]]) {
                 NSString *itemid_extra_info = mainFields[@"itemid_extra_info"] ?: @"";
                 NSDictionary *itemExtraDict = methodResult[itemid_extra_info];
                 if (itemExtraDict && [itemExtraDict isKindOfClass:[NSDictionary class]]) {
                     NSString *serverURL = [Utilities getImageServerURL];
                     int secondsToMinute = [Utilities getSec2Min:YES];
                     NSDictionary *newItem = [self getNewDictionaryFromExtraInfoItem:itemExtraDict
                                                                          mainFields:mainFields
                                                                           serverURL:serverURL
                                                                             sec2min:secondsToMinute
                                                                           useBanner:NO
                                                                             useIcon:methodResult[@"recordingdetails"] != nil];
                     [self displayInfoView:newItem];
                 }
             }
         }
         else {
             UIAlertController *alertView = [Utilities createAlertOK:LOCALIZED_STR(@"Details not found") message:nil];
             [self presentViewController:alertView animated:YES completion:nil];
         }
     }];
}

- (void)startRetrieveDataWithRefresh:(BOOL)forceRefresh {
    if (forceRefresh) {
        [activeLayoutView setUserInteractionEnabled:NO];
    }
    mainMenu *menuItem = self.detailItem;
    if (chosenTab >= menuItem.mainParameters.count) {
        return;
    }
    NSDictionary *methods = menuItem.mainMethod[chosenTab];
    NSDictionary *parameters = menuItem.mainParameters[chosenTab];
    NSMutableDictionary *mutableParameters = [parameters[@"parameters"] mutableCopy];
    NSMutableArray *mutableProperties = [parameters[@"parameters"][@"properties"] mutableCopy];
    [self addExtraProperties:mutableProperties newParams:mutableParameters params:parameters];
    NSString *methodToCall = methods[@"method"];
    if (parameters[@"exploreCommand"] != nil) {
        methodToCall = parameters[@"exploreCommand"];
    }
    if (methodToCall != nil) {
        [self retrieveData:methodToCall parameters:mutableParameters sectionMethod:methods[@"extra_section_method"] sectionParameters:parameters[@"extra_section_parameters"] resultStore:self.richResults extraSectionCall:NO refresh:forceRefresh];
    }
    else if (globalSearchView) {
        [self retrieveGlobalData:forceRefresh];
    }
    else {
        [activityIndicatorView stopAnimating];
        [Utilities AnimView:activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
}

- (void)retrieveGlobalData:(BOOL)forceRefresh {
    NSArray *itemsAndTabs = AppDelegate.instance.globalSearchMenuLookup;
    
    mainMenu *menuItem = self.detailItem;
    NSMutableDictionary *parameters = [menuItem.mainParameters[chosenTab] mutableCopy];
    if ([self loadedDataFromDisk:nil parameters:parameters refresh:forceRefresh]) {
        return;
    }
    
    // Kick off recursive calls
    NSMutableArray *richData = [NSMutableArray new];
    [self loadDetailedData:itemsAndTabs index:0 results:richData];
}

- (void)addItemGroup:(NSMutableDictionary*)dict {
    NSString *family = dict[@"family"];
    int index = -1;
    if ([family isEqualToString:@"albumid"]) {
        index = GLOBALSEARCH_INDEX_ALBUMS;
    }
    else if ([family isEqualToString:@"artistid"]) {
        index = GLOBALSEARCH_INDEX_ARTISTS;
    }
    else if ([family isEqualToString:@"songid"]) {
        index = GLOBALSEARCH_INDEX_SONGS;
    }
    else if ([family isEqualToString:@"movieid"]) {
        index = GLOBALSEARCH_INDEX_MOVIES;
    }
    else if ([family isEqualToString:@"setid"]) {
        index = GLOBALSEARCH_INDEX_MOVIESETS;
    }
    else if ([family isEqualToString:@"tvshowid"]) {
        index = GLOBALSEARCH_INDEX_TVSHOWS;
    }
    else if ([family isEqualToString:@"musicvideoid"]) {
        index = GLOBALSEARCH_INDEX_MUSICVIDEOS;
    }
    // The index shall only show numbers to be able to jump to the sections
    dict[@"itemgroup"] = [NSString stringWithFormat:@"%i", index];
}

- (void)loadDetailedData:(NSArray*)itemsAndTabs index:(int)index results:(NSMutableArray*)richData {
    if (index > itemsAndTabs.count - 1) {
        [self.sections removeAllObjects];
        [self.richResults removeAllObjects];
        [self.filteredListContent removeAllObjects];
        self.richResults = richData;
        
        // Stop refresh animation
        [activeLayoutView.pullToRefreshView stopAnimating];
        [activeLayoutView setUserInteractionEnabled:YES];
        
        // Save and display
        mainMenu *menuItem = self.detailItem;
        NSMutableDictionary *parameters = [menuItem.mainParameters[chosenTab] mutableCopy];
        [self saveData:parameters];
        [self indexAndDisplayData];
        return;
    }
    mainMenu *menuItem = itemsAndTabs[index][0];
    int activeTab = [itemsAndTabs[index][1] intValue];
    NSDictionary *methods = menuItem.mainMethod[activeTab];
    NSDictionary *parameters = menuItem.mainParameters[activeTab];
    NSDictionary *mainFields = menuItem.mainFields[activeTab];
    NSString *methodToCall = methods[@"method"];
    NSMutableDictionary *mutableParameters = [parameters[@"parameters"] mutableCopy];
    NSMutableArray *mutableProperties = [parameters[@"parameters"][@"properties"] mutableCopy];
    [self addExtraProperties:mutableProperties newParams:mutableParameters params:parameters];
    [[Utilities getJsonRPC]
     callMethod:methodToCall
     withParameters:mutableParameters
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil) {
            [activeLayoutView reloadData];
            if ([methodResult isKindOfClass:[NSDictionary class]]) {
                NSString *itemid = mainFields[@"itemid"];
                NSArray *itemDict = methodResult[itemid];
                if ([itemDict isKindOfClass:[NSArray class]]) {
                    NSString *serverURL = [Utilities getImageServerURL];
                    int secondsToMinute = [Utilities getSec2Min:menuItem.noConvertTime];
                    for (NSDictionary *item in itemDict) {
                        if ([item isKindOfClass:[NSDictionary class]]) {
                            NSMutableDictionary *newDict = [self getNewDictionaryFromItem:item
                                                                               mainFields:mainFields
                                                                                serverURL:serverURL
                                                                                  sec2min:secondsToMinute
                                                                                useBanner:NO
                                                                                  useIcon:NO];
                            // Convert from array to string to allow searching globally
                            if (newDict[@"artist"]) {
                                newDict[@"artist"] = [Utilities getStringFromItem:newDict[@"artist"]];
                            }
                            if (newDict[@"director"]) {
                                newDict[@"director"] = [Utilities getStringFromItem:newDict[@"director"]];
                            }
                            [self addItemGroup:newDict];
                            [richData addObject:newDict];
                        }
                    }
                }
            }
        }
        [self loadDetailedData:itemsAndTabs index:index + 1 results:richData];
    }];
}

- (void)retrieveData:(NSString*)methodToCall parameters:(NSDictionary*)parameters sectionMethod:(NSString*)SectionMethodToCall sectionParameters:(NSDictionary*)sectionParameters resultStore:(NSMutableArray*)resultStoreArray extraSectionCall:(BOOL) extraSectionCallBool refresh:(BOOL)forceRefresh {
    mainMenu *menuItem = self.detailItem;
    NSMutableDictionary *mutableParameters = [parameters mutableCopy];
    [self addFileProperties:mutableParameters];
    
    // Artist filter is active. We change the API call parameters and continue.
    if (filterModeType == ViewModeAlbumArtists ||
        filterModeType == ViewModeSongArtists ||
        filterModeType == ViewModeDefaultArtists) {
        if ([VersionCheck hasAlbumArtistOnlySupport]) {
            switch (filterModeType) {
                case ViewModeAlbumArtists:
                    mutableParameters[@"albumartistsonly"] = @YES;
                    forceRefresh = YES;
                    break;
                    
                case ViewModeSongArtists:
                    mutableParameters[@"albumartistsonly"] = @NO;
                    forceRefresh = YES;
                    break;
                    
                case ViewModeDefaultArtists:
                    [mutableParameters removeObjectForKey:@"albumartistsonly"];
                    break;
                    
                default:
                    NSAssert(NO, @"retrieveData: unexpected mode %ld", filterModeType);
                    break;
            }
        }
    }
    
    if ([self loadedDataFromDisk:methodToCall parameters:(sectionParameters == nil) ? mutableParameters : [sectionParameters mutableCopy] refresh:forceRefresh]) {
        return;
    }
    
    BOOL useCommonPvrRecordingsTimers = NO;
    if ([methodToCall containsString:@"PVR."]) {
        // PVR methods do not support "sort" before JSON API 12.1
        if (![VersionCheck hasPvrSortSupport]) {
            // remove "sort" from setup
            [mutableParameters removeObjectForKey:@"sort"];
        }
        else if ([mutableParameters[@"channelgroupid"] intValue] == -1) {
            [self animateNoResultsFound];
            return;
        }
        // PVR functions not supported with xbmc 11
        if (AppDelegate.instance.serverVersion == 11) {
            [self animateNoResultsFound];
            return;
        }
        // PVR.GetRecordings and PVR.GetTimers are not supported with xbmc 12
        else if (AppDelegate.instance.serverVersion == 12 && ([methodToCall isEqualToString:@"PVR.GetRecordings"] || [methodToCall isEqualToString:@"PVR.GetTimers"])) {
            [self animateNoResultsFound];
            return;
        }
        // PVR.GetRecordings and PVR.GetTimers support dedicated results for TV + Radio since JSON RPC v8. But
        // in reality this works since Kodi 19. Kodi 18 does not handle timers correct, Kodi 13 to 17 does not handle
        // recordings correct. Therefore we remove the request for "radio" and "isradio" and set a flag to always show
        // common results (TV and Radio) for recordings and timers. For consistency same is done for timer rules.
        else if (AppDelegate.instance.serverVersion < 19) {
            [mutableParameters[@"properties"] removeObject:@"radio"];
            [mutableParameters[@"properties"] removeObject:@"isradio"];
            [mutableParameters[@"properties"] removeObject:@"istimerrule"];
            useCommonPvrRecordingsTimers = YES;
        }
    }
    
    // Settings access requires Kodi 13 or higher
    if ([methodToCall containsString:@"Settings."] && AppDelegate.instance.serverVersion < 13) {
        UIAlertController *alertView = [Utilities createAlertOK:@"" message:LOCALIZED_STR(@"XBMC \"Gotham\" version 13 or superior is required to access XBMC settings")];
        [self presentViewController:alertView animated:YES completion:nil];
        [self animateNoResultsFound];
        return;
    }

    [Utilities alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
    elapsedTime = 0;
    startTime = [NSDate timeIntervalSinceReferenceDate];
    countExecutionTime = [NSTimer scheduledTimerWithTimeInterval:WARNING_TIMEOUT target:self selector:@selector(checkExecutionTime) userInfo:nil repeats:YES];
    [[Utilities getJsonRPC]
     callMethod:methodToCall
     withParameters:mutableParameters
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
         startTime = 0;
         [countExecutionTime invalidate];
         if (longTimeout != nil) {
             [longTimeout removeFromSuperview];
             longTimeout = nil;
         }
         // Cannot check for PVR Add-on availability. We show "no results" in case of a
         // methodError "-32100" combined with "PVR." method calls. Other errors are still
         // shown via debug message.
         if (error == nil && methodError != nil && [methodToCall containsString:@"PVR."]) {
             if (methodError.code == JSONRPCMethodExecutionFailure) {
                 [self animateNoResultsFound];
                 return;
             }
         }
         // Ignore error when aborting a search or sending an empty search string within an addon. Just show "no results".
         NSString *directory = mutableParameters[@"directory"];
         if (error == nil && methodError != nil && [directory hasPrefix:@"plugin://"] && [directory containsString:@"search"]) {
             if (methodError.code == JSONRPCInvalidParams) {
                 [self animateNoResultsFound];
                 return;
             }
         }
         // If the feature to also show movies sets with only 1 movie is disabled and the current results
         // are movie sets, enable the postprocessing to ignore movies sets with only 1 movie.
         BOOL ignoreSingleMovieSets = !AppDelegate.instance.isGroupSingleItemSetsEnabled && [methodToCall isEqualToString:@"VideoLibrary.GetMovieSets"];
        
         // If the feature to list empty TV Shows is disabled and the current results are TV Shows, ignore TV Shows without any episode.
         BOOL ignoreEmptyTvShows = !AppDelegate.instance.isShowEmptyTvShowsEnabled && [methodToCall isEqualToString:@"VideoLibrary.GetTVShows"];
        
         // If we are reading PVR recordings or PVR timers, we need to filter them for the current mode in
         // postprocessing. Ignore Radio recordings/timers, if we are in TV mode. Or ignore TV recordings/timers,
         // if we are in Radio mode.
         BOOL isRecordingsOrTimersMethod = [methodToCall isEqualToString:@"PVR.GetRecordings"] || [methodToCall isEqualToString:@"PVR.GetTimers"];
         BOOL ignoreRadioItems = menuItem.type == TypeLiveTv && isRecordingsOrTimersMethod;
         BOOL ignoreTvItems = menuItem.type == TypeRadio && isRecordingsOrTimersMethod;
         // If we are reading PVR timer, we need to filter them for the current mode in postprocessing. Ignore
         // scheduled recordings, if we are in timer rules mode. Or ignore timer rules, if scheduled recordings
         // are listed.
         NSDictionary *menuParam = menuItem.mainParameters[chosenTab];
         BOOL isTimerMethod = [methodToCall isEqualToString:@"PVR.GetTimers"];
         BOOL ignoreTimerRulesItems = isTimerMethod && [menuParam[@"label"] isEqualToString:LOCALIZED_STR(@"Timers")];
         BOOL ignoreTimerItems = isTimerMethod && [menuParam[@"label"] isEqualToString:LOCALIZED_STR(@"Timer rules")];
         // Override in case we are dealing with an older Kodi version which does not correctly support the JSON requests
         if (useCommonPvrRecordingsTimers) {
             ignoreTimerRulesItems = ignoreTimerItems = ignoreRadioItems = ignoreTvItems = NO;
         }
        
         if (error == nil && methodError == nil) {
             [resultStoreArray removeAllObjects];
             [self.sections removeAllObjects];
             [activeLayoutView reloadData];
             if ([methodResult isKindOfClass:[NSDictionary class]]) {
                 NSMutableDictionary *mainFields = [[self.detailItem mainFields][chosenTab] mutableCopy];
                 NSString *itemid = extraSectionCallBool ? mainFields[@"itemid_extra_section"] : mainFields[@"itemid"];
                 id itemDict = methodResult[itemid];
                 if ([itemDict isKindOfClass:[NSArray class]]) {
                     // "VideoLibrary.GetSeasons" does not support "title" for API < 9.7.0. Instead, we look for "label" which is always provided.
                     if ([methodName isEqualToString:@"VideoLibrary.GetSeasons"]) {
                         mainFields[@"row1"] = @"label";
                     }
                     recordingListView = methodResult[@"recordings"] ? YES : NO;
                     NSString *serverURL = [Utilities getImageServerURL];
                     int secondsToMinute = [Utilities getSec2Min:menuItem.noConvertTime];
                     dispatch_group_t group = dispatch_group_create();
                     for (NSDictionary *item in itemDict) {
                         if ([item isKindOfClass:[NSDictionary class]]) {
                             NSMutableDictionary *newDict = [self getNewDictionaryFromItem:item
                                                                                mainFields:mainFields
                                                                                 serverURL:serverURL
                                                                                   sec2min:secondsToMinute
                                                                                 useBanner:tvshowsView
                                                                                   useIcon:recordingListView];
                             
                             // JSON API does not return the expected "filetype" when retrieving list of "sources".
                             // The correct "filetype" is "directory". But we also need to be aware this is a source
                             // and not a directory yet.
                             if ([itemid isEqualToString:@"sources"]) {
                                 newDict[@"filetype"] = @"directory";
                                 newDict[@"isSources"] = @YES;
                             }
                             
                             // Check if we need to ignore the current item
                             BOOL isRadioItem = [item[@"radio"] boolValue] ||
                                                [item[@"isradio"] boolValue];
                             BOOL isTimerRule = [item[@"istimerrule"] boolValue];
                             BOOL ignorePvrItem = (ignoreRadioItems && isRadioItem) ||
                                                  (ignoreTvItems && !isRadioItem) ||
                                                  (ignoreTimerRulesItems && isTimerRule) ||
                                                  (ignoreTimerItems && !isTimerRule);
                             
                             // Postprocessing of movie sets lists to ignore 1-movie-sets
                             if (ignoreSingleMovieSets) {
                                 NSString *newMethodToCall = @"VideoLibrary.GetMovieSetDetails";
                                 NSDictionary *newParameter = @{@"setid": [Utilities getNumberFromItem:item[@"setid"]]};
                                 dispatch_group_enter(group);
                                 [[Utilities getJsonRPC]
                                  callMethod:newMethodToCall
                                  withParameters:newParameter
                                  onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                                     if (error == nil && methodError == nil) {
                                         if ([methodResult isKindOfClass:[NSDictionary class]]) {
                                             if ([methodResult[@"setdetails"][@"movies"] count] > 1) {
                                                 [resultStoreArray addObject:newDict];
                                             }
                                         }
                                     }
                                     dispatch_group_leave(group);
                                 }];
                             }
                             else if (ignorePvrItem) {
                                 NSLog(@"Ignore PVR item as not matching current TV/Radio mode.");
                             }
                             else if (ignoreEmptyTvShows && [item[@"episode"] intValue] == 0) {
                                 // Do nothing
                             }
                             else {
                                 [resultStoreArray addObject:newDict];
                             }
                         }
                     }
                     // Finish the processing for 1-movie sets
                     if (ignoreSingleMovieSets) {
                         dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                             storeRichResults = [resultStoreArray mutableCopy];
                             // Show "no results found", if results are empty, and leave
                             if (!resultStoreArray.count) {
                                 [self showNoResultsFound:resultStoreArray refresh:forceRefresh];
                                 return;
                             }
                             // Store and show results
                             [self saveAndShowResultsRefresh:forceRefresh params:mutableParameters];
                         });
                     }
                 }
                 else if ([itemDict isKindOfClass:[NSDictionary class]]) {
                     id itemType = itemDict[mainFields[@"typename"]];
                     id itemField = mainFields[@"fieldname"];
                     if ([itemType isKindOfClass:[NSDictionary class]]) {
                         itemDict = itemType[itemField];
                         if ([itemDict isKindOfClass:[NSArray class]]) {
                             NSString *sublabel = menuItem.mainParameters[chosenTab][@"morelabel"] ?: @"";
                             for (id item in itemDict) {
                                 if ([item isKindOfClass:[NSString class]]) {
                                     NSDictionary *listEntry = @{
                                         @"label": item,
                                         @"genre": sublabel,
                                         @"family": @"file",
                                         @"thumbnail": @"",
                                         @"fanart": @"",
                                         @"runtime": @"",
                                     };
                                     [resultStoreArray addObject:listEntry];
                                 }
                             }
                         }
                     }
                 }
                 // Single Movie Sets are handled seperately
                 if (ignoreSingleMovieSets) {
                     if (!itemDict){
                         [self showNoResultsFound:resultStoreArray refresh:forceRefresh];
                     }
                     return;
                 }
                 if (!extraSectionCallBool) {
                     storeRichResults = [resultStoreArray mutableCopy];
                 }
                 if (SectionMethodToCall != nil) {
                     [self retrieveData:SectionMethodToCall parameters:sectionParameters sectionMethod:nil sectionParameters:nil resultStore:self.extraSectionRichResults extraSectionCall:YES refresh:forceRefresh];
                 }
                 else {
                     // Store and show results
                     [self saveAndShowResultsRefresh:forceRefresh params:mutableParameters];
                 }
             }
             else {
                 [self showNoResultsFound:resultStoreArray refresh:forceRefresh];
             }
         }
         else {
             NSString *message = [Utilities formatClipboardMessage:methodToCall
                                                        parameters:mutableParameters
                                                             error:error
                                                       methodError:methodError];
             UIAlertController *alertView = [Utilities createAlertCopyClipboard:LOCALIZED_STR(@"ERROR") message:message];
             [self presentViewController:alertView animated:YES completion:nil];
             
             [self showNoResultsFound:resultStoreArray refresh:forceRefresh];
         }
     }];
}

- (void)saveAndShowResultsRefresh:(BOOL)forceRefresh params:(NSMutableDictionary*)mutableParameters {
    if (filterModeType == ViewModeWatched ||
        filterModeType == ViewModeUnwatched ||
        filterModeType == ViewModeListened ||
        filterModeType == ViewModeNotListened) {
        if (forceRefresh) {
            [activeLayoutView.pullToRefreshView stopAnimating];
            [activeLayoutView setUserInteractionEnabled:YES];
            [self saveData:mutableParameters];
        }
        [self changeViewMode:filterModeType forceRefresh:forceRefresh];
    }
    else {
        if (forceRefresh) {
            [activeLayoutView.pullToRefreshView stopAnimating];
            [activeLayoutView setUserInteractionEnabled:YES];
        }
        [self saveData:mutableParameters];
        [self indexAndDisplayData];
    }
}

- (void)animateNoResultsFound {
    [Utilities alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
    [activityIndicatorView stopAnimating];
    [activeLayoutView.pullToRefreshView stopAnimating];
    [self setGridListButtonImage:enableCollectionView];
    [self setSortButtonImage:sortAscDesc];
}

- (void)showNoResultsFound:(NSMutableArray*)resultStoreArray refresh:(BOOL)forceRefresh {
    if (forceRefresh) {
        [activeLayoutView.pullToRefreshView stopAnimating];
        [activeLayoutView setUserInteractionEnabled:YES];
    }
    [resultStoreArray removeAllObjects];
    [self.sections removeAllObjects];
    self.sections[@""] = @[];
    [self animateNoResultsFound];
    [activeLayoutView reloadData];
    [self displayData];
}

- (BOOL)isEligibleForSections:(NSArray*)array {
    return [self.detailItem enableSection] && array.count > SECTIONS_START_AT;
}

- (NSString*)ignoreSorttoken:(NSString*)text {
    if (AppDelegate.instance.KodiSorttokens.count == 0) {
        return text;
    }
    NSMutableString *string = [text mutableCopy];
    for (NSString *token in AppDelegate.instance.KodiSorttokens) {
        NSRange range = [string rangeOfString:token];
        if (range.location == 0 && range.length > 0) {
            [string deleteCharactersInRange:range];
            break; // We want to leave the loop after we removed the sort token
        }
    }
    return [string copy];
}

- (NSArray*)applySortTokens:(NSArray*)incomingRichArray sortmethod:(NSString*)sortmethod {
    NSMutableArray *copymutable = [[NSMutableArray alloc] initWithCapacity:incomingRichArray.count];
    for (NSMutableDictionary *mutabledict in incomingRichArray) {
        NSString *string = [Utilities getStringFromItem:mutabledict[sortmethod]];
        NSDictionary *dict = @{@"sortby": [self ignoreSorttoken:string]};
        [mutabledict addEntriesFromDictionary:dict];
        [copymutable addObject:mutabledict];
    }
    return [copymutable copy];
}

- (BOOL)isEligibleForSorttokenSort {
    BOOL isEligible = NO;
    // Support sort token processing only for a set of sort methods (same as in Kodi server)
    // Taken from xbmc/xbmc/utils/SortUtils.cpp (method for which SortAttributeIgnoreArticle is defined)
    if ([sortMethodName isEqualToString:@"genre"] || // genre is misused for artists for app-internal reasons
        [sortMethodName isEqualToString:@"label"] ||
        [sortMethodName isEqualToString:@"title"] ||
        [sortMethodName isEqualToString:@"artist"] ||
        [sortMethodName isEqualToString:@"album"] ||
        [sortMethodName isEqualToString:@"sorttitle"] ||
        [sortMethodName isEqualToString:@"studio"]) {
        isEligible = (AppDelegate.instance.isIgnoreArticlesEnabled && AppDelegate.instance.KodiSorttokens.count > 0);
    }
    return isEligible;
}

- (BOOL)isSortDifferentToDefault {
    BOOL isDifferent = NO;
    mainMenu *menuItem = self.detailItem;
    NSDictionary *parameters = menuItem.mainParameters[chosenTab];
    NSString *defaultSortMethod = parameters[@"parameters"][@"sort"][@"method"];
    NSString *defaultSortOrder = parameters[@"parameters"][@"sort"][@"order"];
    if (sortMethodName != nil && ![sortMethodName isEqualToString:defaultSortMethod]) {
        isDifferent = YES;
    }
    else if (sortAscDesc != nil && ![sortAscDesc isEqualToString:defaultSortOrder]) {
        isDifferent = YES;
    }
    return isDifferent;
}

- (NSArray*)applySortByMethod:(NSArray*)incomingRichArray sortmethod:(NSString*)sortmethod ascending:(BOOL)isAscending selector:(SEL)selector {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortmethod ascending:isAscending selector:selector];
    return [incomingRichArray sortedArrayUsingDescriptors:@[sortDescriptor]];
}

- (void)indexAndDisplayData {
    mainMenu *menuItem = self.detailItem;
    NSDictionary *parameters = menuItem.mainParameters[chosenTab];
    NSDictionary *methods = menuItem.mainMethod[chosenTab];
    NSArray *copyRichResults = [self.richResults copy];
    BOOL addUITableViewIndexSearch = NO;
    BOOL isFileBrowsing = [methods[@"method"] isEqualToString:@"Files.GetDirectory"];
    self.sectionArray = nil;
    autoScrollTable = nil;
    if (copyRichResults.count == 0) {
        albumView = NO;
        episodesView = NO;
    }
    BOOL sortAscending = [sortAscDesc isEqualToString:@"descending"] ? NO : YES;
    
    // In case of sorting by playcount and not having any key, we skip sorting (happens for "Top 100")
    if ([sortMethodName isEqualToString:@"playcount"] && copyRichResults.count > 0 && copyRichResults[0][sortMethodName] == nil) {
        sortMethodName = nil;
    }
    
    // In case of sort-by-none set sortMethodName to nil
    if ([sortMethodName isEqualToString:@"none"]) {
        sortMethodName = nil;
    }
    
    // In case of random sort create a random number to sort by
    if ([sortMethodName isEqualToString:@"random"]) {
        NSMutableArray *tempArray = [copyRichResults mutableCopy];
        for (NSMutableDictionary *item in tempArray) {
            item[@"random"] = @(arc4random());
        }
        copyRichResults = [tempArray copy];
    }
    
    // If a sort method is defined which is not found as key, we select @"label" as sort method.
    // This happens for example when sorting by @"artist".
    if (sortMethodName != nil && copyRichResults.count > 0 && copyRichResults[0][sortMethodName] == nil) {
        sortMethodName = @"label";
    }
    
    // Sort tokens need to be processed outside of other conditions to ensure they are applied
    // also for default sorting coming from Kodi server.
    NSString *sortbymethod = sortMethodName;
    if (sortMethodName != nil && !isFileBrowsing) {
        if ([self isEligibleForSorttokenSort]) {
            copyRichResults = [self applySortTokens:copyRichResults sortmethod:sortbymethod];
            sortbymethod = @"sortby";
        }
        // Only sort if the sort method is different to what Kodi server provides or if sort token must be applied
        if ([self isSortDifferentToDefault] || [self isEligibleForSorttokenSort]) {
            SEL selector = [self buildSelectorForSortMethod:sortbymethod inArray:copyRichResults];
            copyRichResults = [self applySortByMethod:copyRichResults sortmethod:sortbymethod ascending:sortAscending selector:selector];
        }
    }
    
    if (episodesView) {
        for (NSDictionary *item in self.richResults) {
            NSString *c = [NSString stringWithFormat:@"%@", item[@"season"]];
            BOOL found = [[self.sections allKeys] containsObject:c];
            if (!found) {
                [self.sections setValue:[NSMutableArray new] forKey:c];
            }
            [self.sections[c] addObject:item];
        }
    }
    else if (channelGuideView) {
        addUITableViewIndexSearch = YES;
        NSDateFormatter *localDate = [NSDateFormatter new];
        localDate.dateFormat = @"yyyy-MM-dd";
        localDate.timeZone = [NSTimeZone systemTimeZone];
        NSDate *nowDate = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSInteger components = (NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute);
        NSDateComponents *nowDateComponents = [calendar components:components fromDate:nowDate];
        nowDate = [calendar dateFromComponents:nowDateComponents];
        NSUInteger countRow = 0;
        NSMutableArray *retrievedEPG = [NSMutableArray new];
        for (NSMutableDictionary *item in self.richResults) {
            NSDate *starttime = [xbmcDateFormatter dateFromString:item[@"starttime"]];
            NSDate *endtime = [xbmcDateFormatter dateFromString:item[@"endtime"]];
            NSDate *itemEndDate;
            NSDate *itemStartDate;
            if (starttime != nil && endtime != nil) {
                NSDateComponents *itemDateComponents = [calendar components:components fromDate:endtime];
                itemEndDate = [calendar dateFromComponents:itemDateComponents];
                itemDateComponents = [calendar components:components fromDate:starttime];
                itemStartDate = [calendar dateFromComponents:itemDateComponents];
            }
            NSComparisonResult datesCompare = [itemEndDate compare:nowDate];
            if (datesCompare == NSOrderedDescending || datesCompare == NSOrderedSame) {
                NSString *c = [localDate stringFromDate:itemStartDate];
                if (!c || [c isKindOfClass:[NSNull class]]) {
                    c = @"";
                }
                BOOL found = [[self.sections allKeys] containsObject:c];
                if (!found) {
                    [self.sections setValue:[NSMutableArray new] forKey:c];
                    countRow = 0;
                }
                item[@"pvrExtraInfo"] = parameters[@"pvrExtraInfo"];
                [self.sections[c] addObject:item];
                if ([item[@"isactive"] boolValue]) {
                    autoScrollTable = [NSIndexPath indexPathForRow:countRow inSection:self.sections.count - 1];
                }
                [retrievedEPG addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                         starttime, @"starttime",
                                         endtime, @"endtime",
                                         item[@"title"], @"title",
                                         item[@"label"], @"label",
                                         item[@"genre"], @"plot",
                                         item[@"plotoutline"], @"plotoutline",
                                         nil]];
                countRow ++;
            }
        }
        if (self.sections.count == 1) {
            [self.richResults removeAllObjects];
        }
        NSDictionary *epgparams = [NSDictionary dictionaryWithObjectsAndKeys:
                                   menuItem.mainParameters[chosenTab][@"parameters"][@"channelid"], @"channelid",
                                   retrievedEPG, @"epgArray",
                                   nil];
        [NSThread detachNewThreadSelector:@selector(backgroundSaveEPGToDisk:) toTarget:self withObject:epgparams];
    }
    else {
        if (!albumView && sortbymethod && ![sortbymethod isEqualToString:@"random"] && ([self isSortDifferentToDefault] || [self isEligibleForSections:copyRichResults] || [sortbymethod isEqualToString:@"itemgroup"])) {
            addUITableViewIndexSearch = YES;
            [self buildSectionsForList:copyRichResults sortMethod:sortbymethod];
        }
        else {
            [self.sections setValue:[NSMutableArray new] forKey:@""];
            for (NSDictionary *item in copyRichResults) {
                [self.sections[@""] addObject:item];
            }
        }
    }
    [self buildSectionsArraySortedAscending:sortAscending withIndexSearch:addUITableViewIndexSearch];
    [self setSortButtonImage:sortAscDesc];
    [self displayData];
}

- (SEL)buildSelectorForSortMethod:(NSString*)sortByMethod inArray:(NSArray*)itemList {
    // Use localizedStandardCompare for all NSString items to be sorted (provides correct order for multi-digit
    // numbers). But do not use for any other types as this crashes.
    SEL selector = nil;
    if (itemList.count > 0 && [itemList[0][sortByMethod] isKindOfClass:[NSString class]]) {
        selector = @selector(localizedStandardCompare:);
    }
    return selector;
}

- (void)buildSectionsForList:(NSArray*)itemList sortMethod:(NSString*)sortByMethod {
    for (NSDictionary *item in itemList) {
        NSString *searchKey = @"";
        if ([item[sortByMethod] isKindOfClass:[NSMutableArray class]] || [item[sortByMethod] isKindOfClass:[NSArray class]]) {
            searchKey = [item[sortByMethod] componentsJoinedByString:@""];
        }
        else {
            searchKey = item[sortByMethod];
        }
        NSString *key = [self getIndexTableKey:searchKey sortMethod:sortMethodName];
        BOOL found = [[self.sections allKeys] containsObject:key];
        if (!found) {
            [self.sections setValue:[NSMutableArray new] forKey:key];
        }
        [self.sections[key] addObject:item];
    }
}

- (void)buildSectionsArraySortedAscending:(BOOL)sortAscending withIndexSearch:(BOOL)addUITableViewIndexSearch {
    // first sort the index table ...
    NSMutableArray<NSString*> *sectionKeys = [[self applySortByMethod:[self.sections.allKeys copy] sortmethod:nil ascending:sortAscending selector:@selector(localizedStandardCompare:)] mutableCopy];
    // ... then add the search item on top of the sorted list when needed
    if (addUITableViewIndexSearch) {
        [sectionKeys insertObject:UITableViewIndexSearch atIndex:0];
        self.sections[UITableViewIndexSearch] = @[];
    }
    self.sectionArray = sectionKeys;
    self.sectionArrayOpen = [NSMutableArray new];
    BOOL defaultValue = self.sectionArray.count == 1;
    for (int i = 0; i < self.sectionArray.count; i++) {
        [self.sectionArrayOpen addObject:@(defaultValue)];
    }
}

- (NSString*)getIndexTableKey:(NSString*)value sortMethod:(NSString*)sortMethod {
    NSString *currentValue = [NSString stringWithFormat:@"%@", value];
    if ([sortMethod isEqualToString:@"year"]) {
        int year = [currentValue intValue];
        if (year >= 1900 && year <= 2099) {
            currentValue = [NSString stringWithFormat:@"%@0", [currentValue substringToIndex:3]];
        }
        else {
            currentValue = @"";
        }
    }
    else if ([sortMethod isEqualToString:@"runtime"]) {
        currentValue = [currentValue stringByTrimmingCharactersInSet:[NSCharacterSet letterCharacterSet]];
        currentValue = [NSString stringWithFormat:@"%ld", ((long)currentValue.integerValue / 15) * 15 + 15];
    }
    else if ([sortMethod isEqualToString:@"rating"]) {
        currentValue = [@(round([currentValue doubleValue])) stringValue];
    }
    else if (([sortMethod isEqualToString:@"dateadded"] || [sortMethod isEqualToString:@"starttime"]) && ![currentValue isEqualToString:@"(null)"]) {
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[xbmcDateFormatter dateFromString:currentValue]];
        currentValue = [NSString stringWithFormat:@"%ld", (long)[components year]];
    }
    else if ([sortMethod isEqualToString:@"playcount"] ||
             [sortMethod isEqualToString:@"itemgroup"] ||
             [sortMethod isEqualToString:@"track"]) {
        currentValue = [NSString stringWithFormat:@"%@", value];
    }
    else if (currentValue.length) {
        NSCharacterSet *set = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ"] invertedSet];
        NSCharacterSet *numberset = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
        NSString *c = @"/";
        if (currentValue.length > 0) {
            c = [[currentValue substringToIndex:1] uppercaseString];
        }
        if ([c rangeOfCharacterFromSet:numberset].location == NSNotFound) {
            c = @"#";
        }
        else if ([c rangeOfCharacterFromSet:set].location != NSNotFound) {
            c = @"/";
        }
        currentValue = c;
    }
    if ([currentValue isEqualToString:@""] || [currentValue isEqualToString:@"(null)"]) {
        currentValue = @"/";
    }
    return currentValue;
}

- (void)displayData {
    [self configureLibraryView];
    [self choseParams];
    NSUInteger numResults = self.richResults.count;
    mainMenu *menuItem = self.detailItem;
    NSDictionary *parameters = menuItem.mainParameters[chosenTab];
    
    BOOL mainLabelChanged = menuItem.mainLabel.length && menuItem.type == TypeNone;
    BOOL useMainLabel = mainLabelChanged && !(menuItem.type == TypeSettings || menuItem.type == TypeCustomButtonEntry);
    NSString *labelText = useMainLabel ? menuItem.mainLabel : parameters[@"label"];
    self.navigationItem.backButtonTitle = labelText;
    if (!albumView) {
        labelText = [labelText stringByAppendingFormat:@" (%lu)", numResults];
    }
    [self setFilternameLabel:labelText];
    
    if (!self.richResults.count) {
        [Utilities alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
    }
    else {
        [Utilities alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
    }
    NSDictionary *itemSizes = parameters[@"itemSizes"];
    if (IS_IPHONE) {
        [self setIphoneInterface:itemSizes[@"iphone"]];
    }
    else {
        [self setIpadInterface:itemSizes[@"ipad"]];
    }
    if (stackscrollFullscreen) {
        storeSectionArray = [sectionArray copy];
        storeSections = [sections mutableCopy];
        NSMutableDictionary *sectionsTemp = [NSMutableDictionary new];
        [sectionsTemp setValue:[NSMutableArray new] forKey:@""];
        for (id key in self.sectionArray) {
            NSDictionary *tmp = self.sections[key];
            for (NSDictionary *item in tmp) {
                [sectionsTemp[@""] addObject:item];
            }
        }
        self.sectionArray = @[@""];
        self.sections = [sectionsTemp mutableCopy];
    }
    [self setFlowLayoutParams];
    [activityIndicatorView stopAnimating];
    [activeLayoutView reloadData];
    [dataList setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
    [collectionView layoutSubviews];
    [collectionView setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
    [Utilities AnimView:activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0 YPos:0];
    if (channelGuideView && autoScrollTable != nil && autoScrollTable.row < [dataList numberOfRowsInSection:autoScrollTable.section]) {
        [dataList scrollToRowAtIndexPath:autoScrollTable atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)startChannelListUpdateTimer {
    [self updateChannelListTableCell];
    [channelListUpdateTimer invalidate];
    channelListUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(updateChannelListTableCell) userInfo:nil repeats:YES];
}

- (void)updateChannelListTableCell {
    [dataList reloadData];
    [collectionView reloadData];
}

# pragma mark - Life-Cycle

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputCanceled" object:nil userInfo:nil];
    self.navigationController.navigationBar.tintColor = ICON_TINT_COLOR;
    [channelListUpdateTimer invalidate];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [channelListUpdateTimer invalidate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.slidingViewController != nil) {
        [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
        self.slidingViewController.underRightViewController = nil;
        self.slidingViewController.anchorLeftPeekAmount   = 0;
        self.slidingViewController.anchorLeftRevealAmount = 0;
    }
    NSIndexPath *selection = [dataList indexPathForSelectedRow];
    if (selection) {
        [dataList deselectRowAtIndexPath:selection animated:NO];
    }
    for (selection in [collectionView indexPathsForSelectedItems]) {
        [collectionView deselectItemAtIndexPath:selection animated:YES];
    }

    [self choseParams];

    if ([self isModal]) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissAddAction:)];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
    [self hideButtonListWhenEmpty];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.slidingViewController.view != nil) {
        [self disableScrollsToTopPropertyOnAllSubviewsOf:self.slidingViewController.view];
    }
    else {
        [self disableScrollsToTopPropertyOnAllSubviewsOf:self.view];
    }
    [activeLayoutView setScrollsToTop:YES];
    if (albumColor != nil) {
        self.navigationController.navigationBar.tintColor = [Utilities lighterColorForColor:albumColor];
    }
    else {
        self.navigationController.navigationBar.tintColor = ICON_TINT_COLOR;
    }
    
    // We load data only in viewDidAppear as loading/presenting is tightly coupled and we want
    // the layout to be ready. We do not want to repeat loading/presenting, if we re-enter the
    // same controller instance from another view, e.g. when coming back from detail view.
    if (loadAndPresentDataOnViewDidAppear) {
        [self initIpadCornerInfo];
        [self startRetrieveDataWithRefresh:NO];
        loadAndPresentDataOnViewDidAppear = NO;
    }
    
    if (channelListView || channelGuideView) {
        [channelListUpdateTimer invalidate];
        // Set up a timer that will always trigger at the start of each local minute. This supports
        // to move highlighting to the current running broadcast in channel lists.
        NSDate *now = [NSDate date];
        NSDateFormatter *outputFormatter = [NSDateFormatter new];
        outputFormatter.dateFormat = @"ss";
        [self updateChannelListTableCell];
        channelListUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:(60.0 - [[outputFormatter stringFromDate:now] floatValue]) target:self selector:@selector(startChannelListUpdateTimer) userInfo:nil repeats:NO];
    }
    // Show the keyboard if it was active when the view was shown last time. Remark: Only works with dalay!
    if (showkeyboard) {
        [[self getSearchTextField] performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.1];
    }
    [self setButtonViewContent:chosenTab];
}

- (void)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)buildButtons:(int)activeTab {
    mainMenu *menuItem = self.detailItem;
    NSArray *buttons = menuItem.mainButtons;
    NSArray *buttonsIB = @[button1, button2, button3, button4, button5];
    UIImage *imageOff = nil;
    UIImage *imageOn = nil;
    UIImage *img = nil;
    CGRect frame;
    NSInteger count = buttons.count;
    // If >6 buttons are required, only use 4 normal buttons and keep 5th for "more items"
    if (count > MAX_NORMAL_BUTTONS + 1) {
        count = MAX_NORMAL_BUTTONS;
    }
    for (int i = 0; i < count; i++) {
        img = [UIImage imageNamed:buttons[i]];
        imageOff = [Utilities colorizeImage:img withColor:ICON_TINT_COLOR];
        imageOn = [Utilities colorizeImage:img withColor:ICON_TINT_COLOR_ACTIVE];
        [buttonsIB[i] setBackgroundImage:imageOff forState:UIControlStateNormal];
        [buttonsIB[i] setBackgroundImage:imageOn forState:UIControlStateSelected];
        [buttonsIB[i] setBackgroundImage:imageOn forState:UIControlStateHighlighted];
        [buttonsIB[i] setEnabled:YES];
    }
    activeTab = MIN(activeTab, MAX_NORMAL_BUTTONS);
    [buttonsIB[activeTab] setSelected:YES];
    button1.hidden = button2.hidden = button3.hidden = button4.hidden = button5.hidden = NO;
    switch (buttons.count) {
        case 0:
            // no button, no toolbar
            button1.hidden = button2.hidden = button3.hidden = button4.hidden = button5.hidden = YES;
            frame = dataList.frame;
            frame.size.height = self.view.bounds.size.height;
            dataList.frame = frame;
            break;
        case 1:
            button2.hidden = button3.hidden = button4.hidden = button5.hidden = YES;
            break;
        case 2:
            button3.hidden = button4.hidden = button5.hidden = YES;
            break;
        case 3:
            button4.hidden = button5.hidden = YES;
            break;
        case 4:
            button5.hidden = YES;
            break;
        case 5:
            break;
        default:
            // 6 or more buttons/actions require a "more" button
            img = [UIImage imageNamed:@"st_more"];
            imageOff = [Utilities colorizeImage:img withColor:ICON_TINT_COLOR];
            imageOn = [Utilities colorizeImage:img withColor:ICON_TINT_COLOR_ACTIVE];
            [buttonsIB.lastObject setBackgroundImage:imageOff forState:UIControlStateNormal];
            [buttonsIB.lastObject setBackgroundImage:imageOn forState:UIControlStateSelected];
            [buttonsIB.lastObject setBackgroundImage:imageOn forState:UIControlStateHighlighted];
            [buttonsIB.lastObject setEnabled:YES];
            break;
    }
}

- (void)checkParamSize:(NSDictionary*)itemSizes viewWidth:(int)fullWidth {
    cellGridWidth = 0;
    cellGridHeight = 0;
    fullscreenCellGridWidth = 0;
    fullscreenCellGridHeight = 0;
    if (itemSizes[@"width"] && itemSizes[@"height"]) {
        CGFloat transform = [Utilities getTransformX];
        if ([itemSizes[@"width"] isKindOfClass:[NSString class]]) {
            if ([itemSizes[@"width"] isEqualToString:@"fullWidth"]) {
                cellGridWidth = fullWidth;
            }
            cellMinimumLineSpacing = 1;
        }
        else {
            cellMinimumLineSpacing = 0;
            cellGridWidth = [itemSizes[@"width"] floatValue];
            cellGridWidth = (int)(cellGridWidth * transform);
        }
        cellGridHeight = [itemSizes[@"height"] floatValue];
        cellGridHeight = (int)(cellGridHeight * transform);
    }
    if (itemSizes[@"fullscreenWidth"] && itemSizes[@"fullscreenHeight"]) {
        fullscreenCellGridWidth = [itemSizes[@"fullscreenWidth"] floatValue];
        fullscreenCellGridHeight = [itemSizes[@"fullscreenHeight"] floatValue];
    }
}

- (BOOL)isModal {
    return [self presentingViewController] != nil;
}

- (void)setIphoneInterface:(NSDictionary*)itemSizes {
    viewWidth = UIScreen.mainScreen.bounds.size.width;
    albumViewPadding = 8;
    albumViewHeight = episodesView ? IPHONE_SEASON_SECTION_HEIGHT : IPHONE_ALBUM_SECTION_HEIGHT;
    artistFontSize = 12;
    albumFontSize = 15;
    trackCountFontSize = 11;
    posterFontSize = 10;
    fanartFontSize = 10;
    [self checkParamSize:itemSizes viewWidth:viewWidth];
}

- (void)setIpadInterface:(NSDictionary*)itemSizes {
    viewWidth = STACKSCROLL_WIDTH;
    // ensure modal views are forced to width = STACKSCROLL_WIDTH, this eases the layout
    CGSize size = CGSizeMake(STACKSCROLL_WIDTH, self.view.frame.size.height);
    self.preferredContentSize = size;
    albumViewPadding = 12;
    albumViewHeight = episodesView ? IPAD_SEASON_SECTION_HEIGHT : IPAD_ALBUM_SECTION_HEIGHT;
    artistFontSize = 14;
    albumFontSize = 18;
    trackCountFontSize = 13;
    posterFontSize = 11;
    fanartFontSize = 13;
    [self checkParamSize:itemSizes viewWidth:viewWidth];
    if (stackscrollFullscreen) {
        viewWidth = UIScreen.mainScreen.bounds.size.width;
    }
}

- (void)disableScrollsToTopPropertyOnAllSubviewsOf:(UIView*)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UIScrollView class]]) {
            ((UIScrollView*)subview).scrollsToTop = NO;
        }
        [self disableScrollsToTopPropertyOnAllSubviewsOf:subview];
    }
}

- (BOOL)collectionViewCanBeEnabled {
    mainMenu *menuItem = self.detailItem;
    NSDictionary *parameters = menuItem.mainParameters[chosenTab];
    return ([parameters[@"enableCollectionView"] boolValue]);
}

- (BOOL)collectionViewIsEnabled {
    if (![self collectionViewCanBeEnabled]) {
        return NO;
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    mainMenu *menuItem = self.detailItem;
    NSDictionary *parameters = menuItem.mainParameters[chosenTab];
    NSDictionary *methods = menuItem.mainMethod[chosenTab];
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:parameters[@"parameters"]];
    if (AppDelegate.instance.serverVersion > 11) {
        if (tempDict[@"filter"] != nil) {
            [tempDict removeObjectForKey:@"filter"];
            tempDict[@"filtered"] = @"YES";
        }
    }
    else {
        if (tempDict.count > 2) {
            [tempDict removeAllObjects];
            NSArray *arr_properties = parameters[@"parameters"][@"properties"];
            if (arr_properties == nil) {
                arr_properties = parameters[@"parameters"][@"file_properties"];
            }
            
            if (arr_properties == nil) {
                arr_properties = @[];
            }
            
            NSArray *arr_sort = parameters[@"parameters"][@"sort"];
            if (arr_sort == nil) {
                arr_sort = @[];
            }
            tempDict[@"properties"] = arr_properties;
            tempDict[@"sort"] = arr_sort;
            tempDict[@"filtered"] = @"YES";
        }
    }
    NSString *viewKey = [NSString stringWithFormat:@"%@_grid_preference", [self getCacheKey:methods[@"method"] parameters:tempDict]];
    return ([parameters[@"enableCollectionView"] boolValue] && [userDefaults boolForKey:viewKey]);
}

- (NSString*)getCurrentSortMethod:(NSDictionary*)methods withParameters:(NSDictionary*)parameters {
    NSString *sortMethod = parameters[@"parameters"][@"sort"][@"method"];
    NSString *sortKey = [NSString stringWithFormat:@"%@_sort_method", [self getCacheKey:methods[@"method"] parameters:[parameters mutableCopy]]];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:sortKey] != nil) {
        sortMethod = [userDefaults objectForKey:sortKey];
    }
    return sortMethod;
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar*)searchbar {
    showkeyboard = NO;
    // Restore the toolbar when search became inactive
    [self hideButtonListWhenEmpty];
}

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchbar {
    showkeyboard = NO;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar*)searchbar {
    showkeyboard = YES;
}

#pragma mark - UISearchController Delegate Methods

- (void)initSearchController {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    self.searchController.delegate = self;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.searchBar.placeholder = LOCALIZED_STR(@"Search");
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.barStyle = UIBarStyleBlack;
    self.searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.searchController.searchBar.showsCancelButton = YES;
    [self.searchController.searchBar sizeToFit];
    [self.searchController setActive:NO];
}

- (void)showSearchBar {
    UISearchBar *searchbar = self.searchController.searchBar;
    searchbar.frame = CGRectMake(0, 0, self.view.frame.size.width, searchbar.frame.size.height);
    if (showSearchbar) {
        [self.view addSubview:searchbar];
    }
    else {
        [searchbar removeFromSuperview];
    }
}

- (void)openSearchBar {
    showSearchbar = YES;
    [self showSearchBar];
    [self.searchController.searchBar becomeFirstResponder];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self showSearchBar];
    viewWidth = self.view.bounds.size.width;
}

- (void)willPresentSearchController:(UISearchController*)controller {
    showSearchbar = YES;
    [self showSearchBar];
}

- (void)willDismissSearchController:(UISearchController*)controller {
    showSearchbar = NO;
    [self showSearchBar];
    [self setIndexViewVisibility];
    
    // Scroll back to top with inactive searchbar visible on top.
    activeLayoutView.contentOffset = CGPointMake(0, -activeLayoutView.contentInset.top);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Dismiss any visible action sheet as the origin is not corrected in fullscreen
    if (IS_IPAD && stackscrollFullscreen) {
        UIViewController *topMostCtrl = [Utilities topMostController];
        if ([topMostCtrl isKindOfClass:[UIAlertController class]]) {
            [topMostCtrl dismissViewControllerAnimated:YES completion:nil];
        }
    }
    
    // Force reloading of index overlay after rotation
    sectionNameOverlayView = nil;
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (stackscrollFullscreen) {
            [self setFlowLayoutParams];
            [collectionView.collectionViewLayout invalidateLayout];
            [collectionView reloadData];
        }
        activeLayoutView.contentOffset = CGPointMake(0, iOSYDelta);
    }
                                 completion:nil];
}

- (void)updateSearchResultsForSearchController:(UISearchController*)searchController {
    NSString *searchString = searchController.searchBar.text;
    [self searchForText:searchString];
    [activeLayoutView reloadData];
    
    // Hide the toolbar and index while search is active with a non-empty string
    if (self.searchController.isActive) {
        BOOL hasNonEmptySearchString = searchString.length > 0;
        
        // Hide toolbar when search string is non-empty or no toolbar buttons exist
        BOOL hasEmptyToolbar = button1.hidden && button2.hidden && button3.hidden && button4.hidden && button5.hidden && button6.hidden && button7.hidden;
        BOOL hideToolbar = (hasNonEmptySearchString || hasEmptyToolbar) && !stackscrollFullscreen;
        [self hideButtonList:hideToolbar];
        
        // Hide index when search string is non-empty
        self.indexView.hidden = hasNonEmptySearchString;
    }
}

- (void)searchForText:(NSString*)searchText {
    // filter here
    [self.filteredListContent removeAllObjects];
    
    // Set main parameters for the search and the result visualization
    NSPredicate *pred;
    if (globalSearchView) {
        pred = [NSPredicate predicateWithFormat:@"label CONTAINS[cd] %@ || year CONTAINS %@ || artist CONTAINS[cd] %@ || director CONTAINS[cd] %@", searchText, searchText, searchText, searchText];
        useSectionInSearchResults = [sortMethodName isEqualToString:@"itemgroup"];
    }
    else {
        pred = [NSPredicate predicateWithFormat:@"label CONTAINS[cd] %@ || year CONTAINS %@", searchText, searchText];
        useSectionInSearchResults = NO;
    }
    
    if (useSectionInSearchResults) {
        // When showing filtered results with sections the filtered list must be identical to richResults in case of empty search string
        if (searchText.length) {
            self.filteredListContent = [self sortfilteredList:[self.richResults filteredArrayUsingPredicate:pred]];
        }
        else {
            self.filteredListContent = [self.richResults mutableCopy];
        }
        
        // Build sections and sectionsArray for the filtered list
        BOOL sortAscending = [sortAscDesc isEqualToString:@"descending"] ? NO : YES;
        self.sections = [NSMutableDictionary new];
        [self buildSectionsForList:self.filteredListContent sortMethod:sortMethodName];
        [self buildSectionsArraySortedAscending:sortAscending withIndexSearch:self.filteredListContent.count > 0];
    }
    else {
        self.filteredListContent = [self sortfilteredList:[self.richResults filteredArrayUsingPredicate:pred]];
    }
}

- (NSMutableArray*)sortfilteredList:(NSArray*)resultsList {
    // Always sort search list by ascending label
    NSString *sortByMethod = @"label";
    SEL selector = [self buildSelectorForSortMethod:sortByMethod inArray:resultsList];
    resultsList = [self applySortByMethod:resultsList sortmethod:sortByMethod ascending:YES selector:selector];
    return [resultsList mutableCopy];
}

- (NSString*)getCurrentSortAscDesc:(NSDictionary*)methods withParameters:(NSDictionary*)parameters {
    NSString *sortAscDescSaved = parameters[@"parameters"][@"sort"][@"order"];
    NSString *sortKey = [NSString stringWithFormat:@"%@_sort_ascdesc", [self getCacheKey:methods[@"method"] parameters:[parameters mutableCopy]]];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:sortKey] != nil) {
        sortAscDescSaved = [userDefaults objectForKey:sortKey];
    }
    return sortAscDescSaved;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    serverMajorVersion = AppDelegate.instance.serverVersion;
    serverMinorVersion = AppDelegate.instance.serverMinorVersion;
    libraryCachePath = AppDelegate.instance.libraryCachePath;
    epgCachePath = AppDelegate.instance.epgCachePath;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    hiddenLabel = [userDefaults boolForKey:@"hidden_label_preference"];
    noItemsLabel.text = LOCALIZED_STR(@"No items found.");
    loadAndPresentDataOnViewDidAppear = YES;
    sectionHeight = LIST_SECTION_HEADER_HEIGHT;
    epglockqueue = dispatch_queue_create("com.epg.arrayupdate", DISPATCH_QUEUE_SERIAL);
    epgDict = [NSMutableDictionary new];
    epgDownloadQueue = [NSMutableArray new];
    xbmcDateFormatter = [NSDateFormatter new];
    xbmcDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    xbmcDateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"]; // all times in Kodi PVR are UTC
    xbmcDateFormatter.locale = [NSLocale systemLocale]; // Needed to work with 12h system setting in combination with "UTC"
    localHourMinuteFormatter = [NSDateFormatter new];
    localHourMinuteFormatter.dateFormat = @"HH:mm";
    localHourMinuteFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    [self initSearchController];
    self.navigationController.view.backgroundColor = UIColor.blackColor;
    self.definesPresentationContext = NO;
    iOSYDelta = self.searchController.searchBar.frame.size.height;
    dataList.tableHeaderView = [self createFakeSearchbarInDark:NO];

    if (@available(iOS 15.0, *)) {
        dataList.sectionHeaderTopPadding = 0;
    }
    
    [button6 addTarget:self action:@selector(handleChangeLibraryView) forControlEvents:UIControlEventTouchUpInside];

    [button7 addTarget:self action:@selector(handleChangeSortLibrary) forControlEvents:UIControlEventTouchUpInside];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    dataList.indicatorStyle = UIScrollViewIndicatorStyleDefault;
    
    CGRect frame = dataList.frame;
    frame.size.height = self.view.bounds.size.height;
    dataList.frame = frame;
    buttonsViewBgToolbar.hidden = NO;
    
    __weak DetailViewController *weakSelf = self;
    [dataList addPullToRefreshWithActionHandler:^{
        [weakSelf.searchController setActive:NO];
        [weakSelf startRetrieveDataWithRefresh:YES];
        [weakSelf hideButtonListWhenEmpty];
    }];
    [self disableScrollsToTopPropertyOnAllSubviewsOf:self.slidingViewController.view];
    for (UIView *subView in self.searchController.searchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            [(UITextField*)subView setKeyboardAppearance:UIKeyboardAppearanceAlert];
        }
    }
    self.view.userInteractionEnabled = YES;
    mainMenu *menuItem = self.detailItem;
    int numTabs = (int)menuItem.mainMethod.count;
    chosenTab = menuItem.chooseTab;
    if (chosenTab >= numTabs) {
        chosenTab = 0;
    }
    filterModeType = ViewModeDefault;
    NSDictionary *methods = menuItem.mainMethod[chosenTab];
    NSDictionary *parameters = menuItem.mainParameters[chosenTab];
    watchedListenedStrings = parameters[@"watchedListenedStrings"];
    [self checkDiskCache];
    numberOfStars = 10;
    if ([parameters[@"numberOfStars"] intValue] > 0) {
        numberOfStars = [parameters[@"numberOfStars"] intValue];
    }
    
    // Transparent toolbar
    [Utilities createTransparentToolbar:buttonsViewBgToolbar];
    
    // Gray background for toolbar
    if (IS_IPHONE) {
        buttonsView.backgroundColor = UIColor.clearColor;
    }
    else {
        buttonsViewBgToolbar.backgroundColor = UIColor.clearColor;
    }
    
    if ([methods[@"albumView"] boolValue]) {
        albumView = YES;
    }
    else if ([methods[@"episodesView"] boolValue]) {
        episodesView = YES;
    }
    else if ([methods[@"tvshowsView"] boolValue]) {
        tvshowsView = AppDelegate.instance.serverVersion > 11 && ![Utilities getPreferTvPosterMode];
        [self setTVshowThumbSize];
    }
    else if ([methods[@"channelGuideView"] boolValue]) {
        channelGuideView = YES;
    }
    else if ([methods[@"channelListView"] boolValue]) {
        channelListView = YES;
    }
    else if (menuItem.type == TypeGlobalSearch) {
        globalSearchView = YES;
    }
    
    if (tvshowsView && ![Utilities getPreferTvPosterMode]) {
        dataList.separatorInset = UIEdgeInsetsZero;
    }
    bottomPadding = [Utilities getBottomPadding];
    if (IS_IPHONE) {
        if (bottomPadding > 0) {
            frame = buttonsView.frame;
            frame.size.height += bottomPadding;
            frame.origin.y -= bottomPadding;
            buttonsView.frame = frame;
        }
    }
    
    maskView.clipsToBounds = YES;
    NSDictionary *itemSizes = parameters[@"itemSizes"];
    if (IS_IPHONE) {
        [self setIphoneInterface:itemSizes[@"iphone"]];
    }
    else {
        [self setIpadInterface:itemSizes[@"ipad"]];
    }
    
    // As default both list and grid views animate from right to left.
    frame = dataList.frame;
    frame.origin.x = viewWidth;
    dataList.frame = frame;
    
    recentlyAddedView = [parameters[@"collectionViewRecentlyAdded"] boolValue];
    enableCollectionView = [self collectionViewIsEnabled];
    activeLayoutView = dataList;
    self.sections = [NSMutableDictionary new];
    self.richResults = [NSMutableArray new];
    self.filteredListContent = [NSMutableArray new];
    storeRichResults = [NSMutableArray new];
    self.extraSectionRichResults = [NSMutableArray new];
    
    logoBackgroundMode = [Utilities getLogoBackgroundMode];
    
    [self initCollectionView];
    
    longPressGestureCollection = [UILongPressGestureRecognizer new];
    [longPressGestureCollection addTarget:self action:@selector(handleLongPress:)];
    [collectionView addGestureRecognizer:longPressGestureCollection];
    
    longPressGestureList = [UILongPressGestureRecognizer new];
    [longPressGestureList addTarget:self action:@selector(handleLongPress:)];
    [dataList addGestureRecognizer:longPressGestureList];
    
    [activityIndicatorView startAnimating];
    
    // As an exception custom button menu on iPhone animates bottom-up. This requires to
    // change the initial frame for the first table shown (list view). It is important
    // to apply this only change after the library view has been initialized as this
    // uses the list view frame to set its own frame.
    if (menuItem.type == TypeCustomButtonEntry && IS_IPHONE) {
        frame = dataList.frame;
        frame.origin.x = 0;
        frame.origin.y = UIScreen.mainScreen.bounds.size.height;
        dataList.frame = frame;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTabHasChanged:)
                                                 name:@"tabHasChanged"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(revealMenu:)
                                                 name:@"RevealMenu"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideKeyboard:)
                                                 name:@"ECSlidingViewUnderLeftWillAppear"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showKeyboard:)
                                                 name:@"ECSlidingViewTopDidReset"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleCollectionIndexStateBegin)
                                                 name:@"BDKCollectionIndexViewGestureRecognizerStateBegin"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleCollectionIndexStateEnded)
                                                 name:@"BDKCollectionIndexViewGestureRecognizerStateEnded"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(leaveFullscreen)
                                                 name:@"LeaveFullscreen"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePlaycount)
                                                 name:@"PlaycountChanged"
                                               object:nil];
    
    if (channelListView || channelGuideView) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRecordTimerStatusChange:)
                                                     name:@"KodiServerRecordTimerStatusChange"
                                                   object:nil];
    }
}

- (void)handleRecordTimerStatusChange:(NSNotification*)note {
    NSDictionary *theData = note.userInfo;
    NSArray *keys = [self.sections allKeys];
    for (NSString *keysV in keys) {
        [self checkUpdateRecordingState:self.sections[keysV] dataInfo:theData];
    }
    if ([self doesShowSearchResults]) {
        [self checkUpdateRecordingState:self.filteredListContent dataInfo:theData];
    }
}

- (void)checkUpdateRecordingState:(NSMutableArray*)source dataInfo:(NSDictionary*)data {
    NSNumber *channelid = data[@"channelid"];
    NSNumber *broadcastid = data[@"broadcastid"];
    NSNumber *status = data[@"status"];
    if (channelid.integerValue > 0) {
        NSPredicate *filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"channelid = %@", channelid]];
        NSArray *filteredItems = [source filteredArrayUsingPredicate:filter];
        if (filteredItems.count > 0) {
            NSMutableDictionary *item = filteredItems[0];
            item[@"isrecording"] = status;
            [self updateChannelListTableCell];
        }
    }
    if (broadcastid.integerValue > 0) {
        NSPredicate *filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"broadcastid = %@", broadcastid]];
        NSArray *filteredItems = [source filteredArrayUsingPredicate:filter];
        if (filteredItems.count > 0) {
            NSMutableDictionary *item = filteredItems[0];
            item[@"hastimer"] = status;
            [self updateChannelListTableCell];
        }
    }
}

- (void)initIpadCornerInfo {
    mainMenu *menuItem = self.detailItem;
    if (IS_IPAD && menuItem.enableSection) {
        // Add a reserved fixed space which is used for iPad corner info
        for (UILabel *view in buttonsView.subviews) {
            if ([view isKindOfClass:[UIToolbar class]]) {
                UIToolbar *toolbar = (UIToolbar*)view;
                UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
                fixedSpace.width = FIXED_SPACE_WIDTH;
                toolbar.items = [toolbar.items arrayByAddingObject:fixedSpace];
                break;
            }
        }
        
        // Add the corner info view
        titleView = [[UIView alloc] initWithFrame:CGRectMake(buttonsView.frame.size.width - FIXED_SPACE_WIDTH, 0, FIXED_SPACE_WIDTH - SMALL_PADDING, buttonsView.frame.size.height)];
        titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
        topNavigationLabel.textAlignment = NSTextAlignmentRight;
        topNavigationLabel.font = [UIFont boldSystemFontOfSize:14];
        topNavigationLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [titleView addSubview:topNavigationLabel];
        [buttonsView addSubview:titleView];
        [self checkFullscreenButton:NO];
    }
}

- (void)checkFullscreenButton:(BOOL)forceHide {
    mainMenu *menuItem = self.detailItem;
    if (IS_IPAD && menuItem.enableSection) {
        NSDictionary *parameters = menuItem.mainParameters[chosenTab];
        if ([self collectionViewCanBeEnabled] && ([parameters[@"enableLibraryFullScreen"] boolValue] && !forceHide)) {
            if (fullscreenButton == nil) {
                fullscreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
                fullscreenButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
                fullscreenButton.showsTouchWhenHighlighted = YES;
                fullscreenButton.frame = CGRectMake(0, 0, FULLSCREEN_BUTTON_SIZE, FULLSCREEN_BUTTON_SIZE);
                fullscreenButton.contentMode = UIViewContentModeCenter;
                [fullscreenButton setImage:[UIImage imageNamed:@"button_fullscreen"] forState:UIControlStateNormal];
                fullscreenButton.layer.cornerRadius = 2;
                fullscreenButton.tintColor = UIColor.whiteColor;
                [fullscreenButton addTarget:self action:@selector(toggleFullscreen) forControlEvents:UIControlEventTouchUpInside];
                fullscreenButton.frame = CGRectMake(titleView.frame.size.width - fullscreenButton.frame.size.width, titleView.frame.size.height / 2 - fullscreenButton.frame.size.height / 2, fullscreenButton.frame.size.width, fullscreenButton.frame.size.height);
                [titleView addSubview:fullscreenButton];
            }
            if (twoFingerPinch == nil) {
                twoFingerPinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerPinch:)];
                [self.view addGestureRecognizer:twoFingerPinch];
            }
            topNavigationLabel.frame = CGRectMake(0, 0, titleView.frame.size.width - fullscreenButton.frame.size.width - TINY_PADDING, titleView.frame.size.height);
            topNavigationLabel.alpha = 0;
            fullscreenButton.hidden = NO;
            twoFingerPinch.enabled = YES;
        }
        else {
            topNavigationLabel.frame = CGRectMake(0, 0, titleView.frame.size.width, titleView.frame.size.height);
            topNavigationLabel.alpha = 0;
            fullscreenButton.hidden = YES;
            twoFingerPinch.enabled = NO;
        }
    }
}

- (void)twoFingerPinch:(UIPinchGestureRecognizer*)recognizer {
    if ([recognizer state] == UIGestureRecognizerStateEnded) {
        if ((recognizer.scale > 1 && !stackscrollFullscreen) || (recognizer.scale <= 1 && stackscrollFullscreen)) {
            [self toggleFullscreen];
        }
    }
}

- (void)checkDiskCache {
    mainMenu *menuItem = self.detailItem;
    NSDictionary *parameters = menuItem.mainParameters[chosenTab];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL diskcache_preference = [userDefaults boolForKey:@"diskcache_preference"];
    enableDiskCache = diskcache_preference && [parameters[@"enableLibraryCache"] boolValue];
    [dataList setShowsPullToRefresh:enableDiskCache];
    [collectionView setShowsPullToRefresh:enableDiskCache];
}

- (void)handleChangeLibraryView {
    if ([self doesShowSearchResults] || self.searchController.isActive) {
        [self.searchController setActive:NO];
    }
    mainMenu *menuItem = self.detailItem;
    NSDictionary *methods = menuItem.mainMethod[chosenTab];
    NSDictionary *parameters = menuItem.mainParameters[chosenTab];
    if ([self collectionViewCanBeEnabled] && self.view.superview != nil && ![methods[@"method"] isEqualToString:@""]) {
        NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:parameters[@"parameters"]];
        if (AppDelegate.instance.serverVersion > 11) {
            if (tempDict[@"filter"] != nil) {
                [tempDict removeObjectForKey:@"filter"];
                tempDict[@"filtered"] = @"YES";
            }
        }
        else {
            if (tempDict.count > 2) {
                [tempDict removeAllObjects];
                tempDict[@"properties"] = parameters[@"parameters"][@"properties"];
                tempDict[@"sort"] = parameters[@"parameters"][@"sort"];
                tempDict[@"filtered"] = @"YES";
            }
        }
        NSString *viewKey = [NSString stringWithFormat:@"%@_grid_preference", [self getCacheKey:methods[@"method"] parameters:tempDict]];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setBool:![userDefaults boolForKey:viewKey] forKey:viewKey];
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             CGRect frame = activeLayoutView.frame;
                             frame.origin.x = viewWidth;
                             activeLayoutView.frame = frame;
                         }
                         completion:^(BOOL finished) {
                             activeLayoutView.contentOffset = CGPointMake(0, iOSYDelta);
                             recentlyAddedView = [parameters[@"collectionViewRecentlyAdded"] boolValue];
                             enableCollectionView = [self collectionViewIsEnabled];
                             [self configureLibraryView];
                             [Utilities AnimView:activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
                             activeLayoutView.contentOffset = CGPointMake(0, iOSYDelta);
                         }];
    }
}

- (void)handleChangeSortLibrary {
    if ([self doesShowSearchResults] || self.searchController.isActive) {
        [self.searchController setActive:NO];
    }
    selectedIndexPath = nil;
    mainMenu *menuItem = self.detailItem;
    if (chosenTab >= menuItem.mainParameters.count) {
        return;
    }
    NSDictionary *parameters = menuItem.mainParameters[chosenTab];
    NSDictionary *sortDictionary = parameters[@"available_sort_methods"];
    NSMutableArray *sortOptions = [sortDictionary[@"label"] mutableCopy];
    if (sortMethodIndex != -1) {
        sortOptions[sortMethodIndex] = [NSString stringWithFormat:@"\u2713 %@", sortOptions[sortMethodIndex]];
    }
    
    CGPoint sheetOrigin = [button7 convertPoint:button7.center toView:buttonsView];
    sheetOrigin.y -= CGRectGetHeight(button7.frame) / 2;
    NSString *title = [NSString stringWithFormat:@"%@\n\n(%@)",
                       LOCALIZED_STR(@"Sort by"),
                       LOCALIZED_STR(@"tap the selection\nto reverse the sort order")];
    [self showActionSheetWithTitle:title sheetActions:sortOptions item:nil origin:sheetOrigin fromview:buttonsView];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}
							
@end
