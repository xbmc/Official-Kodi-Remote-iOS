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
#import "ProgressPieView.h"
#import "SettingsValuesViewController.h"
#import "customButton.h"
#import "VersionCheck.h"

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
//@synthesize detailDescriptionLabel = _detailDescriptionLabel;
#define SECTIONS_START_AT 100
#define MAX_NORMAL_BUTTONS 4
#define WARNING_TIMEOUT 30.0
#define GRID_SECTION_HEADER_HEIGHT 24
#define LIST_SECTION_HEADER_HEIGHT 24
#define FIXED_SPACE_WIDTH 120
#define INFO_PADDING 10
#define MONKEY_COUNT 38
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
#define INDEX_WIDTH 40
#define INDEX_PADDING 2
#define RUNTIMEYEAR_WIDTH 63
#define EPGCHANNELTIME_WIDTH 40
#define TRACKCOUNT_WIDTH 26
#define LABEL_PADDING 8
#define VERTICAL_PADDING 8
#define SMALL_PADDING 4
#define TINY_PADDING 2
#define FLAG_SIZE 16
#define INDICATOR_SIZE 16
#define FLOWLAYOUT_FULLSCREEN_INSET 8
#define FLOWLAYOUT_FULLSCREEN_MIN_SPACE 4
#define FLOWLAYOUT_FULLSCREEN_LABEL (FULLSCREEN_LABEL_HEIGHT * [Utilities getTransformX] + 8)
#define TOGGLE_BUTTON_SIZE 11
#define LABEL_HEIGHT(fontsize) (fontsize + 6)

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

#pragma mark - live tv epg memory/disk cache management

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

#pragma mark - live tv epg management

- (void)getChannelEpgInfo:(NSDictionary*)parameters {
    NSNumber *channelid = parameters[@"channelid"];
    NSIndexPath *indexPath = parameters[@"indexPath"];
    UITableView *tableView = parameters[@"tableView"];
    NSMutableDictionary *item = parameters[@"item"];
    if ([channelid intValue] > 0) {
        NSMutableArray *retrievedEPG = [self loadEPGFromMemory:channelid];
        NSMutableDictionary *channelEPG = [self parseEpgData:retrievedEPG];
        NSDictionary *epgparams = [NSDictionary dictionaryWithObjectsAndKeys:
                                   channelEPG, @"channelEPG",
                                   indexPath, @"indexPath",
                                   tableView, @"tableView",
                                   item, @"item",
                                   nil];
        [self performSelectorOnMainThread:@selector(updateEpgTableInfo:) withObject:epgparams waitUntilDone:NO];
        if ([channelEPG[@"refresh_data"] boolValue]) {
            retrievedEPG = [self loadEPGFromDisk:channelid parameters:parameters];
            channelEPG = [self parseEpgData:retrievedEPG];
            NSDictionary *epgparams = [NSDictionary dictionaryWithObjectsAndKeys:
                                       channelEPG, @"channelEPG",
                                       indexPath, @"indexPath",
                                       tableView, @"tableView",
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
    return;
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
//                NSSortDescriptor *sortDescriptor;
//                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"starttime"
//                                                             ascending:YES];
//                NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
//                NSArray *sortedArray;
//                sortedArray = [nextFilteredArray sortedArrayUsingDescriptors:sortDescriptors];
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
    UILabel *current = (UILabel*)[cell viewWithTag:2];
    UILabel *next = (UILabel*)[cell viewWithTag:4];
    current.text = channelEPG[@"current"];
    next.text = channelEPG[@"next"];
    if (channelEPG[@"current_details"] != nil) {
        item[@"genre"] = channelEPG[@"current_details"];
    }
    ProgressPieView *progressView = (ProgressPieView*)[cell viewWithTag:103];
    if (![current.text isEqualToString:LOCALIZED_STR(@"Not Available")] && [channelEPG[@"starttime"] isKindOfClass:[NSDate class]] && [channelEPG[@"endtime"] isKindOfClass:[NSDate class]]) {
        float percent_elapsed = [Utilities getPercentElapsed:channelEPG[@"starttime"] EndDate:channelEPG[@"endtime"]];
        [progressView updateProgressPercentage:percent_elapsed];
        progressView.hidden = NO;
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSUInteger unitFlags = NSCalendarUnitMinute;
        NSDateComponents *components = [gregorian components:unitFlags
                                                    fromDate:channelEPG[@"starttime"]
                                                      toDate:channelEPG[@"endtime"] options:0];
        NSInteger minutes = [components minute];
        progressView.pieLabel.text = [NSString stringWithFormat:@" %ld'", (long)minutes];
    }
    else {
        progressView.hidden = YES;
    }
}

- (void)parseBroadcasts:(NSDictionary*)parameters {
    NSArray *broadcasts = parameters[@"broadcasts"];
    NSNumber *channelid = parameters[@"channelid"];
    NSIndexPath *indexPath = parameters[@"indexPath"];
    UITableView *tableView = parameters[@"tableView"];
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
                               tableView, @"tableView",
                               item, @"item",
                               nil];
    [self performSelectorOnMainThread:@selector(updateEpgTableInfo:) withObject:epgparams waitUntilDone:NO];
}

- (void)getJsonEPG:(NSDictionary*)parameters {
    NSNumber *channelid = parameters[@"channelid"];
    NSIndexPath *indexPath = parameters[@"indexPath"];
    UITableView *tableView = parameters[@"tableView"];
    NSMutableDictionary *item = parameters[@"item"];
    [[Utilities getJsonRPC] callMethod:@"PVR.GetBroadcasts"
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                         channelid, @"channelid",
                         @[@"title", @"starttime", @"endtime", @"plot", @"plotoutline"], @"properties",
                         nil]
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
               if (error == nil && methodError == nil && [methodResult isKindOfClass: [NSDictionary class]]) {
                   NSArray *broadcasts = methodResult[@"broadcasts"];
                   if (broadcasts && [broadcasts isKindOfClass:[NSArray class]]) {
                       NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                               channelid, @"channelid",
                                               indexPath, @"indexPath",
                                               tableView, @"tableView",
                                               item, @"item",
                                               broadcasts, @"broadcasts",
                                               nil];
                       [NSThread detachNewThreadSelector:@selector(parseBroadcasts:) toTarget:self withObject:params];
                   }
               }
//               else {
//                   NSLog(@"method error %@ %@", methodError, error);
//               }
           }];
}

#pragma mark - library disk cache management

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
        NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:menuItem.mainMethod[choosedTab]];
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
            dateFormatter.timeStyle = NSDateFormatterMediumStyle;
            dateFormatter.locale = [NSLocale currentLocale];
            NSString *dateString = [dateFormatter stringFromDate:[attributes fileModificationDate]];
            NSString *title = [NSString stringWithFormat:@"%@: %@", LOCALIZED_STR(@"Last sync"), dateString];
            [dataList.pullToRefreshView setSubtitle:title forState: SVPullToRefreshStateStopped];
            [dataList.pullToRefreshView setSubtitle:title forState: SVPullToRefreshStateTriggered];
            [collectionView.pullToRefreshView setSubtitle:title forState: SVPullToRefreshStateStopped];
            [collectionView.pullToRefreshView setSubtitle:title forState: SVPullToRefreshStateTriggered];
        }
    }
}

#pragma mark - Utility

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

- (UIViewController*)topMostController {
    UIViewController *topController = UIApplication.sharedApplication.keyWindow.rootViewController;

    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }

    return topController;
}

- (void)setFilternameLabel:(NSString*)labelText runFullscreenButtonCheck:(BOOL)check forceHide:(BOOL)forceHide {
    self.navigationItem.title = [Utilities stripBBandHTML:labelText];
    if (IS_IPHONE) {
        return;
    }
    // fade out
    [UIView animateWithDuration:0.3 animations:^{
        topNavigationLabel.alpha = 0;
    }];
    // update label
    topNavigationLabel.text = labelText;
    // fade in
    [UIView animateWithDuration:0.1 animations:^{
        topNavigationLabel.alpha = 1;
        if (check) {
            [self checkFullscreenButton:forceHide];
        }
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
        stringURL = [Utilities getItemIconFromDictionary:item mainFields:mainFields];
    }
    mainMenu *menuItem = self.detailItem;
    BOOL disableNowPlaying = NO;
    if (menuItem.disableNowPlaying) {
        disableNowPlaying = YES;
    }
    
    id row11 = item[mainFields[@"row11"]] ?: @0;
    NSString *row11key = mainFields[@"row11"] ?: @"";
    
    id row7 = item[mainFields[@"row7"]] ?: @0;
    NSString *row7key = mainFields[@"row7"] ?: @"";

    NSDictionary *newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                             @(disableNowPlaying), @"disableNowPlaying",
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
                             @([[NSString stringWithFormat:@"%@", item[mainFields[@"row9"]]] intValue]), mainFields[@"row9"],
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
        stringURL = [Utilities getItemIconFromDictionary:item mainFields:mainFields];
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
    else {
        row19obj = [NSString stringWithFormat:@"%@", item[mainFields[@"row19"]]];
    }
    id row13key = mainFields[@"row13"];
    id row13obj = [row13key isEqualToString:@"options"] ? (item[row13key] == nil ? @"" : item[row13key]) : item[row13key];
    
    id row14key = mainFields[@"row14"];
    id row14obj = [row14key isEqualToString:@"allowempty"] ? (item[row14key] == nil ? @"" : item[row14key]) : item[row14key];
    
    id row15key = mainFields[@"row15"];
    id row15obj = [row15key isEqualToString:@"addontype"] ? (item[row15key] == nil ? @"" : item[row15key]) : item[row15key];
    
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
                                 [NSString stringWithFormat:@"%@", rating], @"rating",
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

- (mainMenu*)getMainMenu:(id)item {
    mainMenu *menuItem = self.detailItem;
    if (globalSearchView) {
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
        if (lookup) {
            menuItem = lookup[0];
            choosedTab = [lookup[1] intValue];
        }
    }
    return menuItem;
}

- (void)setIndexViewVisibility {
    // Only show the collection view index, if there are valid index titles to show
    self.indexView.hidden = self.indexView.indexTitles.count <= 1;
}

- (NSDictionary*)getItemFromIndexPath:(NSIndexPath*)indexPath {
    NSDictionary *item;
    if ([self doesShowSearchResults]) {
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

- (NSString*)getAmountOfSearchResultsString {
    NSString *results = @"";
    int numResult = (int)self.filteredListContent.count;
    if (numResult) {
        if (numResult != 1) {
            results = [NSString stringWithFormat:LOCALIZED_STR(@"%d results"), numResult];
        }
        else {
            results = LOCALIZED_STR(@"1 result");
        }
    }
    return results;
}

- (void)setSearchBarColor:(UIColor*)albumColor {
    UITextField *searchTextField = [self getSearchTextField];
    UIColor *lightAlbumColor = [Utilities updateColor:albumColor
                                           lightColor:[Utilities getGrayColor:255 alpha:0.7]
                                            darkColor:[Utilities getGrayColor:0 alpha:0.6]];
    if (searchTextField != nil) {
        UIImageView *iconView = (id)searchTextField.leftView;
        iconView.image = [iconView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        iconView.tintColor = lightAlbumColor;
        searchTextField.textColor = lightAlbumColor;
        searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchController.searchBar.placeholder attributes: @{NSForegroundColorAttributeName: lightAlbumColor}];
    }
    self.searchController.searchBar.backgroundColor = albumColor;
    self.searchController.searchBar.tintColor = lightAlbumColor;
    self.searchController.searchBar.barTintColor = lightAlbumColor;
}

- (void)setViewColor:(UIView*)view image:(UIImage*)image isTopMost:(BOOL)isTopMost label1:(UILabel*)label1 label2:(UILabel*)label2 label3:(UILabel*)label3 label4:(UILabel*)label4 {
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
    
    // Only the top most item shall define albumcolor, searchbar tint and navigationbar tint
    if (isTopMost) {
        albumColor = mainColor;
        [self setSearchBarColor:albumColor];
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
    UITextField *textfield = nil;
    if (@available(iOS 13.0, *)) {
        textfield = self.searchController.searchBar.searchTextField;
    }
    else {
        textfield = [self.searchController.searchBar valueForKey:@"searchField"];
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
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:menuItem.mainMethod[choosedTab]];
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
    
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

- (void)setViewInset:(UIView*)view bottom:(CGFloat)bottomInset {
    UIEdgeInsets viewInsets = dataList.contentInset;
    viewInsets.bottom = bottomInset;
    dataList.contentInset = viewInsets;
    dataList.scrollIndicatorInsets = viewInsets;
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
    UIButton *toggleButton = (UIButton*)[sender.view viewWithTag:99];
    if (expandSection) {
        [dataList beginUpdates];
        [dataList insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationMiddle];
        [dataList endUpdates];
    }
    else {
        [dataList beginUpdates];
        [dataList deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationMiddle];
        [dataList endUpdates];
    }
    toggleButton.selected = expandSection;
    dataList.tableHeaderView = self.searchController.searchBar;
    
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
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationEnableStackPan" object: nil];
    }
}

- (void)layoutTVShowCell:(UIView*)cell useDefaultThumb:(BOOL)useFallback imgView:(UIImageView*)imgView {
    // Exception handling for TVShow banner view
    if (tvshowsView) {
        // First tab shows the banner
        if (choosedTab == 0) {
            // When not in grid and not in fullscreen view
            if (!enableCollectionView && !stackscrollFullscreen) {
                // If loaded, we use a dark background
                if (!useFallback) {
                    // Gray:28 is similar to systemGray6 in Dark Mode
                    cell.backgroundColor = [Utilities getGrayColor:28 alpha:1.0];
                }
                // If not loaded, use default background color and poster dimensions for default thumb
                else {
                    cell.backgroundColor = [Utilities getSystemGray6];
                }
            }
            // When in grid or fullscreen view
            else {
                // Gray:28 is similar to systemGray6 in Dark Mode
                cell.backgroundColor = [Utilities getGrayColor:28 alpha:1.0];
            }
        }
        // Other tabs (e.g. list of episodes) use default layout
        else {
            if (enableCollectionView) {
                // Gray:28 is similar to systemGray6 in Dark Mode
                cell.backgroundColor = [Utilities getGrayColor:28 alpha:1.0];
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
    BOOL showBorder = !([item[@"family"] isEqualToString:@"channelid"] ||
                        [item[@"family"] isEqualToString:@"recordingid"] ||
                        [item[@"family"] isEqualToString:@"channelgroupid"] ||
                        [item[@"family"] isEqualToString:@"timerid"] ||
                        [item[@"family"] isEqualToString:@"genreid"] ||
                        [item[@"family"] isEqualToString:@"sectionid"] ||
                        [item[@"family"] isEqualToString:@"categoryid"] ||
                        [item[@"family"] isEqualToString:@"type"] ||
                        [item[@"family"] isEqualToString:@"file"]);
    BOOL isOnPVR = [item[@"path"] hasPrefix:@"pvr:"];
    [Utilities applyRoundedEdgesView:imgView drawBorder:showBorder];
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
            // Special handling for TV SHow cells
            [self layoutTVShowCell:cell useDefaultThumb:(!image || error) imgView:weakImageView];
        }];
    }
    else {
        imgView.image = [UIImage imageNamed:displayThumb];
        // Special handling for TV SHow cells, this is already in default thumb state
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

- (IBAction)showMore:(id)sender {
    if ([self doesShowSearchResults] || self.searchController.isActive) {
        return;
    }
    mainMenu *menuItem = self.detailItem;
    self.indexView.hidden = YES;
    button6.hidden = YES;
    button7.hidden = YES;
    [Utilities alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
    [activityIndicatorView startAnimating];
    NSArray *buttonsIB = @[button1, button2, button3, button4, button5];
    if (choosedTab < buttonsIB.count) {
        [buttonsIB[choosedTab] setSelected:NO];
    }
    choosedTab = MAX_NORMAL_BUTTONS;
    [buttonsIB[choosedTab] setSelected:YES];
    [Utilities AnimView:(UITableView*)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:viewWidth];
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
          [NSString stringWithFormat:@"%@", [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[i]][@"morelabel"]], @"label",
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
        [detailView insertSubview:moreItemsViewController.view aboveSubview:dataList];
    }

    [Utilities AnimView:moreItemsViewController.view AnimDuration:0.3 Alpha:1.0 XPos:0];
    NSString *labelText = [NSString stringWithFormat:LOCALIZED_STR(@"More (%d)"), (int)(count - MAX_NORMAL_BUTTONS)];
    [self setFilternameLabel:labelText runFullscreenButtonCheck:YES forceHide:YES];
    [activityIndicatorView stopAnimating];
}


- (void)handleTabHasChanged:(NSNotification*)notification {
    mainMenu *menuItem = self.detailItem;
    NSArray *buttons = menuItem.mainButtons;
    if (!buttons.count) {
        return;
    }
    NSIndexPath *choice = notification.object;
    choosedTab = 0;
    NSInteger selectedIdx = MAX_NORMAL_BUTTONS + choice.row;
    [self handleChangeTab:(int)selectedIdx];
}

- (void)changeViewMode:(ViewModes)newViewMode forceRefresh:(BOOL)refresh {
    [activityIndicatorView startAnimating];
    if (!refresh) {
            [UIView transitionWithView: activeLayoutView
                              duration: 0.2
                               options: UIViewAnimationOptionBeginFromCurrentState
                            animations: ^{
                                ((UITableView*)activeLayoutView).alpha = 1.0;
                                CGRect frame;
                                frame = [activeLayoutView frame];
                                frame.origin.x = viewWidth;
                                frame.origin.y = 0;
                                ((UITableView*)activeLayoutView).frame = frame;
                            }
                            completion:^(BOOL finished) {
                                [self changeViewMode:newViewMode];
                            }];
    }
    else {
        [self changeViewMode:newViewMode];
    }
    return;
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
                NSAssert(NO, @"changeViewMode: unknown mode %d", newViewMode);
                break;
        }
    }
    [self indexAndDisplayData];
    
}

- (void)configureLibraryView {
    if (enableCollectionView) {
        [self initCollectionView];
        if (longPressGesture == nil) {
            longPressGesture = [UILongPressGestureRecognizer new];
            [longPressGesture addTarget:self action:@selector(handleLongPress)];
        }
        [collectionView addGestureRecognizer:longPressGesture];
        collectionView.contentInset = dataList.contentInset;
        dataList.delegate = nil;
        dataList.dataSource = nil;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        dataList.scrollsToTop = NO;
        collectionView.scrollsToTop = YES;
        activeLayoutView = collectionView;
        
        [self initSearchController];
        self.searchController.searchBar.backgroundColor = [Utilities getGrayColor:22 alpha:1];
        self.searchController.searchBar.tintColor = ICON_TINT_COLOR;
    }
    else {
        dataList.delegate = self;
        dataList.dataSource = self;
        collectionView.delegate = nil;
        collectionView.dataSource = nil;
        dataList.scrollsToTop = YES;
        collectionView.scrollsToTop = NO;
        activeLayoutView = dataList;
        
        // Ensure the searchController is properly attached to the dataList header view.
        dataList.tableHeaderView = self.searchController.searchBar;
        
        [self initSearchController];
        self.searchController.searchBar.backgroundColor = [Utilities getSystemGray6];
        self.searchController.searchBar.tintColor = [Utilities get2ndLabelColor];
    }
    [self initIndexView];
    [self buildIndexView];
    [self setIndexViewVisibility];
    [self setGridListButtonImage:enableCollectionView];
    
    if (!isViewDidLoad) {
        [activeLayoutView addSubview:self.searchController.searchBar];
    }
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
    [self handleChangeTab:(int)newChoosedTab];
}

- (void)handleChangeTab:(int)newChoosedTab {
    if ([self doesShowSearchResults] || self.searchController.isActive) {
        return;
    }
    if (!activityIndicatorView.hidden) {
        return;
    }
    [activeLayoutView setUserInteractionEnabled:YES];
    [((UITableView*)activeLayoutView).pullToRefreshView stopAnimating];
    
    mainMenu *menuItem = self.detailItem;
    NSDictionary *methods = nil;
    NSDictionary *parameters = nil;
    NSMutableDictionary *mutableParameters = nil;
    NSMutableArray *mutableProperties = nil;
    BOOL refresh = NO;
    
    // Read new tab index
    numTabs = (int)menuItem.mainMethod.count;
    newChoosedTab = newChoosedTab % numTabs;
    
    // Handle modes (pressing same tab) or changed tabs
    if (newChoosedTab == choosedTab) {
        // Read relevant data from configuration
        methods = [Utilities indexKeyedDictionaryFromArray:menuItem.mainMethod[choosedTab]];
        parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
        mutableParameters = [parameters[@"parameters"] mutableCopy];
        mutableProperties = [parameters[@"parameters"][@"properties"] mutableCopy];
        
        NSInteger num_modes = [menuItem.filterModes[choosedTab][@"modes"] count];
        if (!num_modes) {
            return;
        }
        filterModeIndex = (filterModeIndex + 1) % num_modes;
        NSArray *buttonsIB = @[button1, button2, button3, button4, button5];
        [buttonsIB[choosedTab] setImage:[UIImage imageNamed:menuItem.filterModes[choosedTab][@"icons"][filterModeIndex]] forState:UIControlStateSelected];
        
        // Artist filter is inactive. We simply filter results via helper function changeViewMode and return.
        filterModeType = [menuItem.filterModes[choosedTab][@"modes"][filterModeIndex] intValue];
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
        if (choosedTab < buttonsIB.count) {
            [buttonsIB[choosedTab] setImage:[UIImage imageNamed:@"blank"] forState:UIControlStateSelected];
            [buttonsIB[choosedTab] setSelected:NO];
        }
        else {
            [buttonsIB.lastObject setSelected:NO];
        }
        choosedTab = newChoosedTab;
        if (choosedTab < buttonsIB.count) {
            [buttonsIB[choosedTab] setSelected:YES];
        }
        // Read relevant data from configuration (important: new value for chooseTab)
        methods = [Utilities indexKeyedDictionaryFromArray:menuItem.mainMethod[choosedTab]];
        parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
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
    [self setButtonViewContent:choosedTab];
    [self checkDiskCache];
    NSTimeInterval animDuration = 0.3;
    if (newEnableCollectionView != enableCollectionView) {
        animDuration = 0.0;
    }
    [Utilities AnimView:(UITableView*)activeLayoutView AnimDuration:animDuration Alpha:1.0 XPos:viewWidth];
    enableCollectionView = newEnableCollectionView;
    recentlyAddedView = [parameters[@"collectionViewRecentlyAdded"] boolValue];
    [activeLayoutView setContentOffset:[(UITableView*)activeLayoutView contentOffset] animated:NO];
    NSString *labelText = parameters[@"label"];
    [self setFilternameLabel:labelText runFullscreenButtonCheck:YES forceHide:NO];
    [self addExtraProperties:mutableProperties newParams:mutableParameters params:parameters];
    if ([parameters[@"blackTableSeparator"] boolValue] && ![Utilities getPreferTvPosterMode]) {
        dataList.separatorColor = [Utilities getGrayColor:38 alpha:1];
    }
    else {
        self.searchController.searchBar.tintColor = [Utilities get2ndLabelColor];
        dataList.separatorColor = [Utilities getGrayColor:191 alpha:1];
    }
    if (methods[@"method"] != nil) {
        [self retrieveData:methods[@"method"] parameters:mutableParameters sectionMethod:methods[@"extra_section_method"] sectionParameters:parameters[@"extra_section_parameters"] resultStore:self.richResults extraSectionCall:NO refresh:refresh];
    }
    else {
        [activityIndicatorView stopAnimating];
        [Utilities AnimView:(UITableView*)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
}

#pragma mark - Library item didSelect

- (void)viewChild:(NSIndexPath*)indexPath item:(NSDictionary*)item displayPoint:(CGPoint)point {
    selected = indexPath;
    mainMenu *menuItem = [self getMainMenu:item];
    NSMutableArray *sheetActions = menuItem.sheetActions[choosedTab];
    NSMutableDictionary *parameters = [Utilities indexKeyedMutableDictionaryFromArray:[menuItem.subItem mainParameters][choosedTab]];
    int rectOriginX = point.x;
    int rectOriginY = point.y;
    NSDictionary *mainFields = menuItem.mainFields[choosedTab];
    
    NSNumber *libraryRowHeight = parameters[@"rowHeight"] ?: @(menuItem.subItem.rowHeight);
    NSNumber *libraryThumbWidth = parameters[@"thumbWidth"] ?: @(menuItem.subItem.thumbWidth);
    
    if (parameters[@"parameters"][@"properties"] != nil) { // CHILD IS LIBRARY MODE
        NSString *key = @"null";
        if (item[mainFields[@"row15"]] != nil) {
            key = mainFields[@"row15"];
        }
        id obj = item[mainFields[@"row6"]];
        id objKey = mainFields[@"row6"];
        if (AppDelegate.instance.serverVersion > 11 && ![parameters[@"disableFilterParameter"] boolValue]) {
            NSDictionary *currentParams = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
            obj = [NSDictionary dictionaryWithObjectsAndKeys:
                   item[mainFields[@"row6"]], mainFields[@"row6"],
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
        NSMutableArray *newParameters = [NSMutableArray arrayWithObjects:
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
                                       @([parameters[@"forceActionSheet"] boolValue]), @"forceActionSheet",
                                       @([parameters[@"collectionViewRecentlyAdded"] boolValue]), @"collectionViewRecentlyAdded",
                                       @([parameters[@"blackTableSeparator"] boolValue]), @"blackTableSeparator",
                                       pvrExtraInfo, @"pvrExtraInfo",
                                       kodiExtrasPropertiesMinimumVersion, @"kodiExtrasPropertiesMinimumVersion",
                                       parameters[@"extra_info_parameters"], @"extra_info_parameters",
                                       newSectionParameters, @"extra_section_parameters",
                                       [NSString stringWithFormat:@"%@", parameters[@"defaultThumb"]], @"defaultThumb",
                                       parameters[@"watchedListenedStrings"], @"watchedListenedStrings",
                                       nil];
        if (parameters[@"available_sort_methods"] != nil) {
            [newParameters addObjectsFromArray:@[parameters[@"available_sort_methods"], @"available_sort_methods"]];
        }
        if (parameters[@"combinedFilter"]) {
            [newParameters addObjectsFromArray:@[parameters[@"combinedFilter"], @"combinedFilter"]];
        }
        if (parameters[@"parameters"][@"albumartistsonly"]) {
            newParameters[0][@"albumartistsonly"] = parameters[@"parameters"][@"albumartistsonly"];
        }
        menuItem.subItem.mainLabel = item[@"label"];
        mainMenu *newMenuItem = [menuItem.subItem copy];
        [[newMenuItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
        newMenuItem.chooseTab = choosedTab;
        newMenuItem.currentFilterMode = filterModeType;
        if (IS_IPHONE) {
            DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
            detailViewController.detailItem = newMenuItem;
            [self.navigationController pushViewController:detailViewController animated:YES];
        }
        else {
            if (stackscrollFullscreen) {
                [self toggleFullscreen:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:newMenuItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                    [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:NO];
                });
            }
            else if ([self isModal]) {
                DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:newMenuItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                iPadDetailViewController.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:iPadDetailViewController animated:YES completion:nil];
            }
            else {
                DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:newMenuItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:NO];
            }
        }
    }
    else { // CHILD IS FILEMODE
        NSNumber *filemodeRowHeight = parameters[@"rowHeight"] ?: @44;
        NSNumber *filemodeThumbWidth = parameters[@"thumbWidth"] ?: @44;
        if ([item[@"filetype"] length] != 0) { // WE ARE ALREADY IN BROWSING FILES MODE
            if ([item[@"filetype"] isEqualToString:@"directory"]) {
                [parameters removeAllObjects];
                parameters = [Utilities indexKeyedMutableDictionaryFromArray:menuItem.mainParameters[choosedTab]];
                NSMutableArray *newParameters = [NSMutableArray arrayWithObjects:
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
                                               @"icon_song", @"fileThumb",
                                               [NSDictionary dictionaryWithDictionary:parameters[@"itemSizes"]], @"itemSizes",
                                               @([parameters[@"enableCollectionView"] boolValue]), @"enableCollectionView",
                                               @([parameters[@"disableFilterParameter"] boolValue]), @"disableFilterParameter",
                                               nil];
                menuItem.mainLabel = item[@"label"];
                mainMenu *newMenuItem = [menuItem copy];
                [[newMenuItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
                newMenuItem.chooseTab = choosedTab;
                if (IS_IPHONE) {
                    DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
                    detailViewController.detailItem = newMenuItem;
                    [self.navigationController pushViewController:detailViewController animated:YES];
                }
                else {
                    if (stackscrollFullscreen) {
                        [self toggleFullscreen:nil];
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
                    [self showActionSheet:indexPath sheetActions:sheetActions item:item rectOriginX:rectOriginX rectOriginY:rectOriginY];
                }
                else {
                    [self addPlayback:item indexPath:indexPath position:(int)indexPath.row shuffle:NO];
                }
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
                            menuItem.mainParameters[choosedTab][0][@"section"], @"section",
                            nil];
            }
            NSMutableArray *newParameters = [NSMutableArray arrayWithObjects:
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
                newParameters[0][@"level"] = @"expert";
            }
            menuItem.subItem.mainLabel = item[@"label"];
            mainMenu *newMenuItem = [menuItem.subItem copy];
            [[newMenuItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
            newMenuItem.chooseTab = choosedTab;
            if (IS_IPHONE) {
                DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
                detailViewController.detailItem = newMenuItem;
                [self.navigationController pushViewController:detailViewController animated:YES];
            }
            else {
                if (stackscrollFullscreen) {
                    [self toggleFullscreen:nil];
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
    }
}

- (void)didSelectItemAtIndexPath:(NSIndexPath*)indexPath item:(NSDictionary*)item displayPoint:(CGPoint)point {
    mainMenu *menuItem = [self getMainMenu:item];
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[menuItem.subItem mainMethod][choosedTab]];
    NSMutableArray *sheetActions = [menuItem.sheetActions[choosedTab] mutableCopy];
    NSMutableDictionary *parameters = [Utilities indexKeyedMutableDictionaryFromArray:[menuItem.subItem mainParameters][choosedTab]];
    int rectOriginX = point.x;
    int rectOriginY = point.y;
    if ([item[@"family"] isEqualToString:@"id"]) {
        if (IS_IPHONE) {
            SettingsValuesViewController *settingsViewController = [[SettingsValuesViewController alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) withItem:item];
            [self.navigationController pushViewController:settingsViewController animated:YES];
        }
        else {
            if (stackscrollFullscreen) {
                [self toggleFullscreen:nil];
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
                [self playerOpen:@{@"item": @{@"file": item[@"path"]}} index:nil];
            }
        }
        // Selected favourite item is an unknown type -> throw an error
        else {
            NSString *message = [NSString stringWithFormat:@"%@ (type = '%@')", LOCALIZED_STR(@"Cannot do that"), item[@"type"]];
            [messagesView showMessage:message timeout:2.0 color:[Utilities getSystemRed:0.95]];
        }
    }
    else if (methods[@"method"] != nil && ![parameters[@"forceActionSheet"] boolValue] && !stackscrollFullscreen) {
        // There is a child and we want to show it (only when not in fullscreen)
        [self viewChild:indexPath item:item displayPoint:point];
    }
    else {
        if ([menuItem.showInfo[choosedTab] boolValue]) {
            [self showInfo:indexPath menuItem:menuItem item:item tabToShow:choosedTab];
        }
        else {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            if (![userDefaults boolForKey:@"song_preference"] || [parameters[@"forceActionSheet"] boolValue]) {
                sheetActions = [self getPlaylistActions:sheetActions item:item params:[Utilities indexKeyedMutableDictionaryFromArray:menuItem.mainParameters[choosedTab]]];
                selected = indexPath;
                [self showActionSheet:indexPath sheetActions:sheetActions item:item rectOriginX:rectOriginX rectOriginY:rectOriginY];
            }
            else {
                [self addPlayback:item indexPath:indexPath position:(int)indexPath.row shuffle:NO];
            }
        }
    }
    // In case of Global Search restore choosedTab after processing
    if (globalSearchView) {
        choosedTab = 0;
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

#pragma mark - UICollectionView FlowLayout deleagate

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if ((enableCollectionView && self.sectionArray.count > 1 && section > 0) || [self doesShowSearchResults]) {
        return CGSizeMake(dataList.frame.size.width, GRID_SECTION_HEADER_HEIGHT);
    }
    else {
        return CGSizeZero;
    }
}

- (void)setFlowLayoutParams {
    if (stackscrollFullscreen) {
        // Calculate the dimensions of the items to match the screen size.
        CGFloat screenwidth = IS_PORTRAIT ? GET_MAINSCREEN_WIDTH : GET_MAINSCREEN_HEIGHT;
        CGFloat numItemsPerRow = screenwidth / fullscreenCellGridWidth;
        int num = round(numItemsPerRow);
        CGFloat newWidth = (screenwidth - num * FLOWLAYOUT_FULLSCREEN_MIN_SPACE - 2 * FLOWLAYOUT_FULLSCREEN_INSET) / num;
        
        flowLayout.itemSize = CGSizeMake(newWidth, fullscreenCellGridHeight * newWidth / fullscreenCellGridWidth);
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
}

#pragma mark - UICollectionView methods

- (void)initCollectionView {
    if (collectionView == nil) {
        flowLayout = [FloatingHeaderFlowLayout new];
        [flowLayout setSearchBarHeight:self.searchController.searchBar.frame.size.height];
        
        [self setFlowLayoutParams];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        collectionView = [[UICollectionView alloc] initWithFrame:dataList.frame collectionViewLayout:flowLayout];
        collectionView.contentInset = dataList.contentInset;
        collectionView.scrollIndicatorInsets = dataList.scrollIndicatorInsets;
        collectionView.backgroundColor = [Utilities getGrayColor:0 alpha:0.5];
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
        [detailView insertSubview:collectionView belowSubview:buttonsView];
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    if ([self doesShowSearchResults]) {
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
    if ([self doesShowSearchResults]) {
        return self.filteredListContent.count;
    }
    if (episodesView) {
        return ([self.sectionArrayOpen[section] boolValue] ? [self.sections[self.sectionArray[section]] count] : 0);
    }
    return [self.sections[self.sectionArray[section]] count];
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)cView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    NSDictionary *item = [self getItemFromIndexPath:indexPath];
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
        
        defaultThumb = displayThumb = [self getTimerDefaultThumb:item];
        if (tvshowsView && choosedTab == 0) {
            defaultThumb = displayThumb = @"nocover_tvshows";
        }
        
        if (channelListView) {
            [cell setIsRecording:[item[@"isrecording"] boolValue]];
        }
        cell.posterThumbnail.frame = cell.bounds;
        [self setCellImageView:cell.posterThumbnail cell:cell dictItem:item url:stringURL size:CGSizeMake(cellthumbWidth, cellthumbHeight) defaultImg:displayThumb];
        if (!stringURL.length) {
            cell.posterThumbnail.backgroundColor = [Utilities getGrayColor:28 alpha:1.0];
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

        if (stringURL.length) {
            [cell.posterThumbnail sd_setImageWithURL:[NSURL URLWithString:stringURL]
                                    placeholderImage:[UIImage imageNamed:displayThumb]
                                             options:SDWebImageScaleToNativeSize
                                           completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *url) {
                UIColor *averageColor = [Utilities averageColor:image inverse:NO autoColorCheck:YES];
                CGFloat hue, saturation, brightness, alpha;
                BOOL ok = [averageColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
                if (ok) {
                    UIColor *bgColor = [UIColor colorWithHue:hue saturation:saturation brightness:0.2 alpha:alpha];
                    cell.backgroundColor = bgColor;
                }
            }];
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
//        cell.posterYear.text = [NSString stringWithFormat:@"%@%@", item[@"year"], item[@"runtime"] == nil ? @"" : [NSString stringWithFormat:@" - %@", item[@"runtime"]]];
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
    sectionNameOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width * 0.75, self.view.frame.size.width / 6)];
    sectionNameOverlayView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin);
    sectionNameOverlayView.backgroundColor = [Utilities getGrayColor:0 alpha:1.0];
    sectionNameOverlayView.center = UIApplication.sharedApplication.delegate.window.rootViewController.view.center;
    CGFloat cornerRadius = 12;
    sectionNameOverlayView.layer.cornerRadius = cornerRadius;
    
    int fontSize = 32;
    sectionNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, sectionNameOverlayView.frame.size.height / 2 - (fontSize + VERTICAL_PADDING) / 2, sectionNameOverlayView.frame.size.width, fontSize + VERTICAL_PADDING)];
    sectionNameLabel.font = [UIFont boldSystemFontOfSize:fontSize];
    sectionNameLabel.textColor = UIColor.whiteColor;
    sectionNameLabel.backgroundColor = UIColor.clearColor;
    sectionNameLabel.textAlignment = NSTextAlignmentCenter;
    [sectionNameOverlayView addSubview:sectionNameLabel];
    [self.view addSubview:sectionNameOverlayView];
}

- (void)initIndexView {
    if (self.indexView) {
        return;
    }
    UITableView *activeView = activeLayoutView;
    CGRect frame = CGRectMake(CGRectGetWidth(activeView.frame) - INDEX_WIDTH - INDEX_PADDING,
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
        [tmpArr replaceObjectAtIndex:0 withObject:@"🔍"];
    }
    if (self.sectionArray.count > 1 && !episodesView && !channelGuideView) {
        self.indexView.indexTitles = [NSArray arrayWithArray:tmpArr];
        [detailView addSubview:self.indexView];
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
            [detailView addSubview:self.indexView];
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
        NSPredicate *predExists = [NSPredicate predicateWithFormat: @"SELF.%@ BEGINSWITH[c] %@", sortbymethod, value];
        if ([value isEqual:@"#"]) {
            predExists = [NSPredicate predicateWithFormat: @"SELF.%@ MATCHES[c] %@", sortbymethod, @"^[0-9].*"];
        }
        else if ([sortbymethod isEqualToString:@"rating"] && [value isEqualToString:@"0"]) {
            predExists = [NSPredicate predicateWithFormat: @"SELF.%@.length == 0", sortbymethod];
        }
        else if ([sortbymethod isEqualToString:@"runtime"]) {
             [NSPredicate predicateWithFormat: @"attributeName BETWEEN %@", @[@1, @10]];
            predExists = [NSPredicate predicateWithFormat: @"SELF.%@.intValue BETWEEN %@", sortbymethod, @[@([value intValue] - 15), @([value intValue])]];
        }
        else if ([sortbymethod isEqualToString:@"playcount"]) {
            predExists = [NSPredicate predicateWithFormat: @"SELF.%@.intValue == %d", sortbymethod, [value intValue]];
        }
        else if ([sortbymethod isEqualToString:@"year"]) {
            predExists = [NSPredicate predicateWithFormat: @"SELF.%@.intValue >= %d", sortbymethod, [value intValue]];
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
    UIActivityIndicatorView *cellActivityIndicator = (UIActivityIndicatorView*)[cell viewWithTag:8];
    cellActivityIndicator.center = CGPointMake(MAX(thumbWidth / 2, cellActivityIndicator.frame.size.width / 2), cellHeight / 2);
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

- (void)choseParams { // DA OTTIMIZZARE TROPPI IF!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    mainMenu *menuItem = self.detailItem;
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
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
    if (tvshowsView && choosedTab == 0) {
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
        int indexPadding = INDEX_WIDTH + INDEX_PADDING;
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

- (void)scrollViewDidScroll:(UIScrollView*)theScrollView {
    // Hide keyboard on drag
    showkeyboard = NO;
    [self.searchController.searchBar resignFirstResponder];
    // Stop an empty search on drag
    NSString *searchString = self.searchController.searchBar.text;
    if (searchString.length == 0 && self.searchController.isActive) {
        [self.searchController setActive:NO];
    }
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return cellHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    if ([self doesShowSearchResults]) {
        return (self.filteredListContent.count > 0) ? 1 : 0;
    }
	else {
        return [self.sections allKeys].count;
    }
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self doesShowSearchResults]) {
        return [self getAmountOfSearchResultsString];
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
            sectionName = [NSString stringWithFormat:LOCALIZED_STR(@"The %@s decade"), sectionName];
        }
        else {
            sectionName = LOCALIZED_STR(@"Year not available");
        }
    }
    else if ([sortMethodName isEqualToString:@"dateadded"]) {
        sectionName = [NSString stringWithFormat:LOCALIZED_STR(@"Year %@"), sectionName];
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
        NSString *newName = [NSString stringWithFormat:LOCALIZED_STR(@"Rated %@"), sectionName];
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
        sectionName = [NSString stringWithFormat:LOCALIZED_STR(@"Track n.%@"), sectionName];
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
    if ([self doesShowSearchResults]) {
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
            trackNumberLabel.minimumScaleFactor = (artistFontSize - 4) / artistFontSize;
            trackNumberLabel.textAlignment = NSTextAlignmentCenter;
            trackNumberLabel.tag = 101;
            trackNumberLabel.highlightedTextColor = [Utilities get1stLabelColor];
            trackNumberLabel.textColor = [Utilities get1stLabelColor];
            [cell.contentView addSubview:trackNumberLabel];
        }
        else if (channelGuideView) {
            UILabel *title = (UILabel*)[cell viewWithTag:1];
            UILabel *programTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(SMALL_PADDING, VERTICAL_PADDING, EPGCHANNELTIME_WIDTH, 12 + VERTICAL_PADDING)];
            programTimeLabel.backgroundColor = UIColor.clearColor;
            programTimeLabel.center = CGPointMake(programTimeLabel.center.x, title.center.y);
            programTimeLabel.font = [UIFont systemFontOfSize:12];
            programTimeLabel.adjustsFontSizeToFitWidth = YES;
            programTimeLabel.minimumScaleFactor = 8.0 / 12.0;
            programTimeLabel.textAlignment = NSTextAlignmentCenter;
            programTimeLabel.tag = 102;
            programTimeLabel.highlightedTextColor = [Utilities get2ndLabelColor];
            programTimeLabel.textColor = [Utilities get2ndLabelColor];
            [cell.contentView addSubview:programTimeLabel];
            
            CGFloat pieSize = EPGCHANNELTIME_WIDTH;
            ProgressPieView *progressView = [[ProgressPieView alloc] initWithFrame:CGRectMake(SMALL_PADDING, programTimeLabel.frame.origin.y + programTimeLabel.frame.size.height + 7, pieSize, pieSize)];
            progressView.tag = 103;
            progressView.hidden = YES;
            [cell.contentView addSubview:progressView];
            
            CGFloat dotSize = 12;
            __auto_type hasTimerOrigin = progressView.frame.origin;
            hasTimerOrigin.x += pieSize / 2 - dotSize / 2;
            hasTimerOrigin.y += [progressView getPieRadius] + [progressView getLineWidth] - dotSize / 2;
            UIImageView *hasTimer = [[UIImageView alloc] initWithFrame:(CGRect){hasTimerOrigin, CGSizeMake(dotSize, dotSize)}];
            hasTimer.image = [UIImage imageNamed:@"button_timer"];
            hasTimer.contentMode = UIViewContentModeScaleToFill;
            hasTimer.tag = 104;
            hasTimer.hidden = YES;
            hasTimer.backgroundColor = UIColor.clearColor;
            [cell.contentView addSubview:hasTimer];
        }
        else if (channelListView) {
            CGFloat pieSize = 28;
            ProgressPieView *progressView = [[ProgressPieView alloc] initWithFrame:CGRectMake(viewWidth - pieSize - SMALL_PADDING, LABEL_PADDING, pieSize, pieSize) color:[Utilities get1stLabelColor]];
            progressView.tag = 103;
            progressView.hidden = YES;
            [cell.contentView addSubview:progressView];
            
            CGFloat dotSize = 6;
            __auto_type isRecordingImageOrigin = progressView.frame.origin;
            isRecordingImageOrigin.x += pieSize / 2 - dotSize / 2;
            isRecordingImageOrigin.y += [progressView getPieRadius] + [progressView getLineWidth] - dotSize / 2;
            UIImageView *isRecordingImageView = [[UIImageView alloc] initWithFrame:(CGRect){isRecordingImageOrigin, CGSizeMake(dotSize, dotSize)}];
            isRecordingImageView.image = [UIImage imageNamed:@"button_timer"];
            isRecordingImageView.contentMode = UIViewContentModeScaleToFill;
            isRecordingImageView.tag = 104;
            isRecordingImageView.hidden = YES;
            isRecordingImageView.backgroundColor = UIColor.clearColor;
            [cell.contentView addSubview:isRecordingImageView];
        }
        UILabel *title = (UILabel*)[cell viewWithTag:1];
        UILabel *genre = (UILabel*)[cell viewWithTag:2];
        UILabel *runtimeyear = (UILabel*)[cell viewWithTag:3];
        UILabel *runtime = (UILabel*)[cell viewWithTag:4];
        UILabel *rating = (UILabel*)[cell viewWithTag:5];
        
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
//    NSDictionary *mainFields = menuItem.mainFields[choosedTab];
/* future - need to be tweaked: doesn't work on file mode. mainLabel need to be resized */
//    NSDictionary *methods = [self indexKeyedDictionaryFromArray:[Menuitem.subItem mainMethod][choosedTab]];
//    if (methods[@"method"] != nil) { // THERE IS A CHILD
//        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//    }
/* end future */
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
    
    UILabel *title = (UILabel*)[cell viewWithTag:1];
    UILabel *genre = (UILabel*)[cell viewWithTag:2];
    UILabel *runtimeyear = (UILabel*)[cell viewWithTag:3];
    UILabel *runtime = (UILabel*)[cell viewWithTag:4];
    UILabel *rating = (UILabel*)[cell viewWithTag:5];

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

    if ([menuItem.showRuntime[choosedTab] boolValue]) {
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
    rating.text = [NSString stringWithFormat:@"%@", item[@"rating"]];
    cell.urlImageView.contentMode = UIViewContentModeScaleAspectFill;
    genre.hidden = NO;
    runtimeyear.hidden = NO;
    if (!albumView && !episodesView && !channelGuideView) {
        if (channelListView || recordingListView) {
            CGRect frame;
            frame.origin.x = SMALL_PADDING;
            frame.origin.y = VERTICAL_PADDING;
            frame.size.width = ceil(thumbWidth * 0.9);
            frame.size.height = ceil(thumbWidth * 0.7);
            cell.urlImageView.frame = frame;
            cell.urlImageView.autoresizingMask = UIViewAutoresizingNone;
        }
        if (channelListView) {
            CGRect frame = genre.frame;
            frame.size.width = title.frame.size.width;
            genre.frame = frame;
            genre.textColor = [Utilities get1stLabelColor];
            genre.font = [UIFont boldSystemFontOfSize:genre.font.pointSize];
            ProgressPieView *progressView = (ProgressPieView*)[cell viewWithTag:103];
            progressView.hidden = YES;
            UIImageView *isRecordingImageView = (UIImageView*)[cell viewWithTag:104];
            isRecordingImageView.hidden = ![item[@"isrecording"] boolValue];
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @([item[@"channelid"] integerValue]), @"channelid",
                                    tableView, @"tableView",
                                    indexPath, @"indexPath",
                                    item, @"item",
                                    nil];
            [NSThread detachNewThreadSelector:@selector(getChannelEpgInfo:) toTarget:self withObject:params];
        }
        NSString *stringURL = tvshowsView ? item[@"banner"] : item[@"thumbnail"];
        NSString *displayThumb = globalSearchView ? [self getGlobalSearchThumb:item] : defaultThumb;
        if (tvshowsView && choosedTab == 0) {
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
            genre.font = [genre.font fontWithSize:11];
            genre.minimumScaleFactor = 10.0 / 11.0;
            [genre sizeToFit];
        }
        else if ([item[@"family"] isEqualToString:@"sectionid"] ||
                 [item[@"family"] isEqualToString:@"categoryid"] ||
                 [item[@"family"] isEqualToString:@"id"] ||
                 [item[@"family"] isEqualToString:@"addonid"]) {
            CGRect frame;
            if ([item[@"family"] isEqualToString:@"id"]) {
                frame = title.frame;
                frame.size.width = frame.size.width - INDICATOR_SIZE - LABEL_PADDING;
                title.frame = frame;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            cell.urlImageView.contentMode = UIViewContentModeScaleAspectFit;
            runtimeyear.hidden = YES;
            runtime.hidden = YES;
            rating.hidden = YES;
            frame = genre.frame;
            frame.size.width = title.frame.size.width;
            frame.size.height = frame.size.height + (cellHeight - (frame.origin.y + frame.size.height)) - 4;
            genre.frame = frame;
            genre.numberOfLines = 2;
            genre.font = [genre.font fontWithSize:11];
            genre.minimumScaleFactor = 10.0 / 11.0;
            [genre sizeToFit];
        }
        else if ([item[@"family"] isEqualToString:@"musicvideoid"]) {
            rating.hidden = YES;
            genre.text = [Utilities getStringFromItem:item[@"genre"]];
            runtime.text = [Utilities getStringFromItem:item[@"artist"]];
        }
        else {
            genre.hidden = NO;
            runtimeyear.hidden = NO;
        }
        [self setCellImageView:cell.urlImageView cell:cell dictItem:item url:stringURL size:CGSizeMake(thumbWidth, cellHeight) defaultImg:displayThumb];
    }
    else if (albumView) {
        UILabel *trackNumber = (UILabel*)[cell viewWithTag:101];
        trackNumber.text = item[@"track"];
    }
    else if (episodesView) {
        UILabel *trackNumber = (UILabel*)[cell viewWithTag:101];
        trackNumber.text = item[@"episode"];
    }
    else if (channelGuideView) {
        runtimeyear.hidden = YES;
        runtime.hidden = YES;
        rating.hidden = YES;
        CGRect frame = genre.frame;
        frame.size.width = title.frame.size.width;
        frame.size.height = frame.size.height + (cellHeight - (frame.origin.y + frame.size.height)) - 4;
        genre.frame = frame;
        genre.numberOfLines = 3;
        genre.font = [genre.font fontWithSize:11];
        genre.minimumScaleFactor = 10.0 / 11.0;
        UILabel *programStartTime = (UILabel*)[cell viewWithTag:102];
        ProgressPieView *progressView = (ProgressPieView*)[cell viewWithTag:103];
        NSDate *starttime = [xbmcDateFormatter dateFromString:item[@"starttime"]];
        NSDate *endtime = [xbmcDateFormatter dateFromString:item[@"endtime"]];
        programStartTime.text = [localHourMinuteFormatter stringFromDate:starttime];
        float percent_elapsed = [Utilities getPercentElapsed:starttime EndDate:endtime];

        if (percent_elapsed > 0 && percent_elapsed < 100) {
            title.textColor = [Utilities getSystemBlue];
            genre.textColor = [Utilities getSystemBlue];
            programStartTime.textColor = [Utilities getSystemBlue];

            title.highlightedTextColor = [Utilities getSystemBlue];
            genre.highlightedTextColor = [Utilities getSystemBlue];
            programStartTime.highlightedTextColor = [Utilities getSystemBlue];

            [progressView updateProgressPercentage:percent_elapsed];
            progressView.pieLabel.hidden = NO;
            NSCalendar *gregorian = [[NSCalendar alloc]
                                     initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSUInteger unitFlags = NSCalendarUnitMinute;
            NSDateComponents *components = [gregorian components:unitFlags
                                                        fromDate:starttime
                                                          toDate:endtime
                                                         options:0];
            NSInteger minutes = [components minute];
            progressView.pieLabel.text = [NSString stringWithFormat:@" %ld'", (long)minutes];
            progressView.hidden = NO;
        }
        else {
            progressView.hidden = YES;
            progressView.pieLabel.hidden = YES;
            title.textColor = [Utilities get1stLabelColor];
            genre.textColor = [Utilities get2ndLabelColor];
            programStartTime.textColor = [Utilities get2ndLabelColor];
            title.highlightedTextColor = [Utilities get1stLabelColor];
            genre.highlightedTextColor = [Utilities get2ndLabelColor];
            programStartTime.highlightedTextColor = [Utilities get2ndLabelColor];
        }
        UIImageView *hasTimer = (UIImageView*)[cell viewWithTag:104];
        if ([item[@"hastimer"] boolValue]) {
            hasTimer.hidden = NO;
        }
        else {
            hasTimer.hidden = YES;
        }
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
    UIImageView *flagView = (UIImageView*)[cell viewWithTag:9];
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
    if ([self doesShowSearchResults]) {
        offsetPoint.y = offsetPoint.y - 44;
    }
    int rectOriginX = cell.frame.origin.x + cell.frame.size.width / 2;
    int rectOriginY = cell.frame.origin.y + cell.frame.size.height / 2 - offsetPoint.y;
    [self didSelectItemAtIndexPath:indexPath item:item displayPoint:CGPointMake(rectOriginX, rectOriginY)];
    return;
}

- (NSUInteger)indexOfObjectWithSeason:(NSString*)seasonNumber inArray:(NSArray*)array {
    return [array indexOfObjectPassingTest:
            ^(id dictionary, NSUInteger idx, BOOL *stop) {
                return ([dictionary[@"season"] isEqualToString: seasonNumber]);
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
        UIImageView *thumbImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
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
        NSString *trackCounText = [NSString stringWithFormat:@"%lu %@, %d %@",
                                (unsigned long)self.richResults.count, self.richResults.count > 1 ? LOCALIZED_STR(@"Songs") : LOCALIZED_STR(@"Song"),
                                totalTimeMinutes, totalTimeMinutes > 1 ? LOCALIZED_STR(@"Mins.") : LOCALIZED_STR(@"Min")];
        
        // Get year of release
        int year = [item[@"year"] intValue];
        NSString *releasedText = (year > 0) ? [NSString stringWithFormat:LOCALIZED_STR(@"Released %d"), year] : @"";
        
        [self layoutSectionView:albumDetailView
                      thumbView:thumbImageView
                       thumbURL:item[@"thumbnail"]
                      fanartURL:item[@"fanart"]
                     artistText:artistText
                      albumText:albumText
                   releasedText:releasedText
                 trackCountText:trackCounText
                      isTopMost:YES];
        
        // Add tap gesture to show album details
        UITapGestureRecognizer *touchOnAlbumView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAlbumActions:)];
        [thumbImageView addGestureRecognizer:touchOnAlbumView];

        return albumDetailView;
    }
    else if (episodesView && self.sectionArray.count > section && ![self doesShowSearchResults]) {
        UIImageView *thumbImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
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
                self.searchController.searchBar.backgroundColor = [Utilities getSystemGray6];
                self.searchController.searchBar.tintColor = [Utilities get2ndLabelColor];
            }
            
            // Get show name ("genre") and season ("label")
            NSString *artistText = item[@"genre"];
            NSString *albumText = self.extraSectionRichResults[seasonIdx][@"label"];
            
            // Get amount of episodes
            NSString *trackCountText = [NSString stringWithFormat:LOCALIZED_STR(@"Episodes: %@"), self.extraSectionRichResults[seasonIdx][@"episode"]];
            
            // Get info on when first aired
            NSString *aired = [Utilities getDateFromItem:item[@"year"] dateStyle:NSDateFormatterLongStyle];
            NSString *releasedText = aired ? [NSString stringWithFormat:LOCALIZED_STR(@"First aired on %@"), aired] : @"";
            
            [self layoutSectionView:albumDetailView
                          thumbView:thumbImageView
                           thumbURL:self.extraSectionRichResults[seasonIdx][@"thumbnail"]
                          fanartURL:item[@"thumbnail"]
                         artistText:artistText
                          albumText:albumText
                       releasedText:releasedText
                     trackCountText:trackCountText
                          isTopMost:isFirstListedSeason];
            
            // Add tap gesture to toggle open/close the section
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOpen:)];
            [albumDetailView addGestureRecognizer:tapGesture];
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.tag = 99;
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
    if (sectionTitle == nil) {
        UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, 1)];
        sectionView.backgroundColor = [Utilities getSystemGray5];
        return sectionView;
    }
    
    // Draw gray bar as section header background
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, sectionHeight)];
    sectionView.backgroundColor = [Utilities getSystemGray5];
    
    // Draw text into section header
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, viewWidth - 20, sectionHeight)];
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

- (void)layoutSectionView:(UIView*)albumDetailView thumbView:(UIImageView*)thumbImageView thumbURL:(NSString*)stringURL fanartURL:(NSString*)fanartURL artistText:(NSString*)artistText albumText:(NSString*)albumText releasedText:(NSString*)releasedText trackCountText:(NSString*)trackCountText isTopMost:(BOOL)isTopMost {
    UILabel *artist = [UILabel new];
    UILabel *album = [UILabel new];
    UILabel *trackCount = [UILabel new];
    UILabel *released = [UILabel new];
    
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
    [Utilities applyRoundedEdgesView:thumbImageView drawBorder:YES];
    if (stringURL.length) {
        // In few cases stringURL does not hold an URL path but a loadable icon name. In this case
        // ensure setImageWithURL falls back to this icon.
        if ([UIImage imageNamed:stringURL]) {
            displayThumb = stringURL;
        }
        [thumbImageView sd_setImageWithURL:[NSURL URLWithString:stringURL]
                          placeholderImage:[UIImage imageNamed:displayThumb]
                              completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *url) {
            if (image) {
                [self setViewColor:albumDetailView
                             image:image
                         isTopMost:isTopMost
                            label1:artist
                            label2:album
                            label3:trackCount
                            label4:released];
            }
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
                    label4:released];
    }
    [albumDetailView addSubview:thumbImageView];
    
    // Add Info button to bottom-right corner
    UIButton *albumInfoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    albumInfoButton.alpha = 0.8;
    albumInfoButton.showsTouchWhenHighlighted = YES;
    albumInfoButton.frame = CGRectMake(albumDetailView.bounds.size.width - albumInfoButton.frame.size.width - albumViewPadding,
                                       albumDetailView.bounds.size.height - albumInfoButton.frame.size.height - albumViewPadding,
                                       albumInfoButton.frame.size.width,
                                       albumInfoButton.frame.size.height);
    albumInfoButton.tag = episodesView ? 1 : 0;
    albumInfoButton.hidden = [self isModal];
    [albumInfoButton addTarget:self action:@selector(prepareShowAlbumInfo:) forControlEvents:UIControlEventTouchUpInside];
    [albumDetailView addSubview:albumInfoButton];
    
    // Top down
    // Layout for artist
    artist.text = artistText;
    artist.frame = CGRectMake(originX, albumViewPadding, labelwidth, LABEL_HEIGHT(artistFontSize));
    artist.backgroundColor = UIColor.clearColor;
    artist.shadowOffset = CGSizeMake(0, 1);
    artist.font = [UIFont systemFontOfSize:artistFontSize];
    artist.numberOfLines = 1;
    artist.lineBreakMode = NSLineBreakByTruncatingTail;
    artist.adjustsFontSizeToFitWidth = YES;
    artist.minimumScaleFactor = 9.0 / artistFontSize;
    [albumDetailView addSubview:artist];
    
    // Layout for album
    album.text = albumText;
    album.frame = CGRectMake(originX, CGRectGetMaxY(artist.frame), labelwidth, LABEL_HEIGHT(albumFontSize * 2));
    album.backgroundColor = UIColor.clearColor;
    album.shadowOffset = CGSizeMake(0, 1);
    album.font = [UIFont boldSystemFontOfSize:albumFontSize];
    album.numberOfLines = 2;
    album.lineBreakMode = NSLineBreakByTruncatingTail;
    [album sizeToFit];
    [albumDetailView addSubview:album];
    
    // Bottom up
    CGFloat labelwidthBottom = CGRectGetMinX(albumInfoButton.frame) - originX - LABEL_PADDING;
    
    // Layout for track count
    trackCount.text = trackCountText;
    trackCount.frame = CGRectMake(originX, albumViewHeight - albumViewPadding - LABEL_HEIGHT(trackCountFontSize), labelwidthBottom, LABEL_HEIGHT(trackCountFontSize));
    trackCount.backgroundColor = UIColor.clearColor;
    trackCount.shadowOffset = CGSizeMake(0, 1);
    trackCount.font = [UIFont systemFontOfSize:trackCountFontSize];
    trackCount.numberOfLines = 1;
    trackCount.lineBreakMode = NSLineBreakByTruncatingTail;
    trackCount.minimumScaleFactor = (trackCountFontSize - 2) / trackCountFontSize;
    trackCount.adjustsFontSizeToFitWidth = YES;
    [albumDetailView addSubview:trackCount];
    
    // Layout for released date
    released.text = releasedText;
    released.frame = CGRectMake(originX, CGRectGetMinY(trackCount.frame) - LABEL_HEIGHT(trackCountFontSize), labelwidthBottom, LABEL_HEIGHT(trackCountFontSize));
    released.backgroundColor = UIColor.clearColor;
    released.shadowOffset = CGSizeMake(0, 1);
    released.font = [UIFont systemFontOfSize:trackCountFontSize];
    released.numberOfLines = 1;
    released.lineBreakMode = NSLineBreakByTruncatingTail;
    released.minimumScaleFactor = (trackCountFontSize - 2) / trackCountFontSize;
    released.adjustsFontSizeToFitWidth = YES;
    [albumDetailView addSubview:released];
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

- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
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

- (void)deselectAtIndexPath:(NSIndexPath*)indexPath {
    if (enableCollectionView) {
        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    else {
        [dataList deselectRowAtIndexPath:indexPath animated:NO];
    }
}

#pragma mark - Long Press & Action sheet

NSIndexPath *selected;

- (void)showActionSheet:(NSIndexPath*)indexPath sheetActions:(NSArray*)sheetActions item:(NSDictionary*)item rectOriginX:(int) rectOriginX rectOriginY:(int) rectOriginY {
    NSInteger numActions = sheetActions.count;
    if (numActions) {
        NSString *title = [NSString stringWithFormat:@"%@%@%@", item[@"label"], [item[@"genre"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"\n%@", item[@"genre"]], [item[@"family"] isEqualToString:@"songid"] ? [NSString stringWithFormat:@"\n%@", item[@"album"]] : @""];
        if ([item[@"family"] isEqualToString:@"timerid"] && AppDelegate.instance.serverVersion < 17) {
            title = [NSString stringWithFormat:@"%@\n\n%@", title, LOCALIZED_STR(@"-- WARNING --\nKodi API prior Krypton (v17) don't allow timers editing. Use the Kodi GUI for adding, editing and removing timers. Thank you.")];
            sheetActions = @[LOCALIZED_STR(@"Ok")];
        }
        id cell = [self getCell:indexPath];
        UIImageView *isRecordingImageView = (UIImageView*)[cell viewWithTag:104];
        BOOL isRecording = isRecordingImageView == nil ? NO : !isRecordingImageView.hidden;
        CGPoint sheetOrigin = CGPointMake(rectOriginX, rectOriginY);
        UIViewController *showFromCtrl = [self topMostController];
        [self showActionSheetOptions:title options:sheetActions recording:isRecording point:sheetOrigin fromcontroller:showFromCtrl fromview:self.view];
    }
    else if (indexPath != nil) { // No actions found, revert back to standard play action
        [self addPlayback:item indexPath:indexPath position:(int)indexPath.row shuffle:NO];
        forceMusicAlbumMode = NO;
    }
}

- (IBAction)handleLongPress {
    if (lpgr.state == UIGestureRecognizerStateBegan || longPressGesture.state == UIGestureRecognizerStateBegan) {
        CGPoint p;
        CGPoint selectedPoint;
        NSIndexPath *indexPath = nil;
        if (enableCollectionView) {
            p = [longPressGesture locationInView:collectionView];
            selectedPoint = [longPressGesture locationInView:self.view];
            indexPath = [collectionView indexPathForItemAtPoint:p];
        }
        else {
            p = [lpgr locationInView:dataList];
            selectedPoint = [lpgr locationInView:self.view];
            indexPath = [dataList indexPathForRowAtPoint:p];
        }
        
        if (indexPath != nil) {
            selected = indexPath;
            
            NSDictionary *item = [self getItemFromIndexPath:indexPath];
            
            if ([self doesShowSearchResults]) {
                [dataList selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
            else {
                if (enableCollectionView) {
                    [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                }
                else {
                    [dataList selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            }
            mainMenu *menuItem = [self getMainMenu:item];
            NSMutableArray *sheetActions = [menuItem.sheetActions[choosedTab] mutableCopy];
            if ([sheetActions isKindOfClass:[NSMutableArray class]]) {
                [sheetActions removeObject:LOCALIZED_STR(@"Play Trailer")];
                [sheetActions removeObject:LOCALIZED_STR(@"Mark as watched")];
                [sheetActions removeObject:LOCALIZED_STR(@"Mark as unwatched")];
            }
            NSInteger numActions = sheetActions.count;
            if (numActions) {
                sheetActions = [self getPlaylistActions:sheetActions item:item params:[Utilities indexKeyedMutableDictionaryFromArray:menuItem.mainParameters[choosedTab]]];
                NSString *title = [NSString stringWithFormat:@"%@", item[@"label"]];
                if (item[@"genre"] != nil && ![item[@"genre"] isEqualToString:@""]) {
                    title = [NSString stringWithFormat:@"%@\n%@", title, item[@"genre"]];
                }
                id cell = [self getCell:selected];
                
                if ([item[@"trailer"] isKindOfClass:[NSString class]]) {
                    if ([item[@"trailer"] length] != 0 && [sheetActions isKindOfClass:[NSMutableArray class]]) {
                        [sheetActions addObject:LOCALIZED_STR(@"Play Trailer")];
                    }
                }
                if ([item[@"family"] isEqualToString:@"movieid"] || [item[@"family"] isEqualToString:@"episodeid"]|| [item[@"family"] isEqualToString:@"musicvideoid"] || [item[@"family"] isEqualToString:@"tvshowid"]) {
                    if ([sheetActions isKindOfClass:[NSMutableArray class]]) {
                        NSString *actionString = @"";
                        if ([item[@"playcount"] intValue] == 0) {
                            actionString = LOCALIZED_STR(@"Mark as watched");
                        }
                        else {
                            actionString = LOCALIZED_STR(@"Mark as unwatched");
                        }
                        [sheetActions addObject:actionString];
                    }
                }
                UIImageView *isRecordingImageView = (UIImageView*)[cell viewWithTag:104];
                BOOL isRecording = isRecordingImageView == nil ? NO : !isRecordingImageView.hidden;
                UIViewController *showFromCtrl = [self topMostController];
                UIView *showfromview = nil;
                if (IS_IPHONE) {
                    showfromview = self.view;
                }
                else {
                    showfromview = enableCollectionView ? collectionView : [showFromCtrl.view superview];
                    selectedPoint = enableCollectionView ? p : [lpgr locationInView:showfromview];
                }
                [self showActionSheetOptions:title options:sheetActions recording:isRecording point:selectedPoint fromcontroller:showFromCtrl fromview:showfromview];
            }
            // In case of Global Search restore choosedTab after processing
            if (globalSearchView) {
                choosedTab = 0;
            }
        }
    }
}

- (void)showActionSheetOptions:(NSString*)title options:(NSArray*)sheetActions recording:(BOOL)isRecording point:(CGPoint)origin fromcontroller:(UIViewController*)fromctrl fromview:(UIView*)fromview {
    NSInteger numActions = sheetActions.count;
    if (numActions) {
        UIAlertController *actionTemp = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        actionView = actionTemp;
        
        UIAlertAction *action_cancel = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            forceMusicAlbumMode = NO;
            [self deselectAtIndexPath:selected];
        }];
        
        for (NSString *actionName in sheetActions) {
            NSString *actiontitle = actionName;
            if ([actiontitle isEqualToString:LOCALIZED_STR(@"Record")] && isRecording) {
                actiontitle = LOCALIZED_STR(@"Stop Recording");
            }
            UIAlertAction *action = [UIAlertAction actionWithTitle:actiontitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self actionSheetHandler:actiontitle];
            }];
            [actionView addAction:action];
        }
        [actionView addAction:action_cancel];
        actionView.modalPresentationStyle = UIModalPresentationPopover;
        
        UIPopoverPresentationController *popPresenter = [actionView popoverPresentationController];
        if (popPresenter != nil) {
            popPresenter.sourceView = fromview;
            popPresenter.sourceRect = CGRectMake(origin.x, origin.y, 1, 1);
        }
        [fromctrl presentViewController:actionView animated:YES completion:nil];
    }
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
             [self updateCellAndSaveRichData:indexPath watched:watched item:item];
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
        UIImageView *flagView = (UIImageView*)[cell viewWithTag:9];
        flagView.hidden = !wasWatched;
        [dataList deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    // Set the new playcount for the item inside the rich data
    item[@"playcount"] = @(watched);
    
    // Store the rich data
    mainMenu *menuItem = [self getMainMenu:item];
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
    NSMutableDictionary *mutableParameters = [parameters[@"parameters"] mutableCopy];
    NSMutableArray *mutableProperties = [parameters[@"parameters"][@"properties"] mutableCopy];
    if ([parameters[@"FrodoExtraArt"] boolValue] && AppDelegate.instance.serverVersion > 11) {
        [mutableProperties addObject:@"art"];
        mutableParameters[@"properties"] = mutableProperties;
    }
    if (mutableParameters[@"file_properties"] != nil) {
        mutableParameters[@"properties"] = mutableParameters[@"file_properties"];
        [mutableParameters removeObjectForKey: @"file_properties"];
    }
    [self saveData:mutableParameters];
}

- (void)saveSortMethod:(NSString*)sortMethod parameters:(NSDictionary*)parameters {
    mainMenu *menuItem = self.detailItem;
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:menuItem.mainMethod[choosedTab]];
    NSString *sortKey = [NSString stringWithFormat:@"%@_sort_method", [self getCacheKey:methods[@"method"] parameters:[parameters mutableCopy]]];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:sortMethod forKey:sortKey];
}

- (void)saveSortAscDesc:(NSString*)sortAscDescSave parameters:(NSDictionary*)parameters {
    mainMenu *menuItem = self.detailItem;
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:menuItem.mainMethod[choosedTab]];
    NSString *sortKey = [NSString stringWithFormat:@"%@_sort_ascdesc", [self getCacheKey:methods[@"method"] parameters:[parameters mutableCopy]]];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:sortAscDescSave forKey:sortKey];
}

- (void)actionSheetHandler:(NSString*)actiontitle {
    NSDictionary *item = nil;
    if (selected != nil) {
        item = [self getItemFromIndexPath:selected];
        if (item == nil) {
            return;
        }
    }
    mainMenu *menuItem = [self getMainMenu:item];
    if ([actiontitle isEqualToString:LOCALIZED_STR(@"Play")]) {
        NSString *songid = [NSString stringWithFormat:@"%@", item[@"songid"]];
        if ([songid intValue]) {
            [self addPlayback:item indexPath:selected position:(int)selected.row shuffle:NO];
        }
        else {
            [self addPlayback:item indexPath:selected position:0 shuffle:NO];
        }
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Record")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Stop Recording")]) {
        [self recordChannel:item indexPath:selected];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Delete timer")]) {
        [self deleteTimer:item indexPath:selected];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Play in shuffle mode")]) {
        [self addPlayback:item indexPath:selected position:0 shuffle:YES];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Queue")]) {
        [self addQueue:item indexPath:selected];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Queue after current")]) {
        [self addQueue:item indexPath:selected afterCurrentItem:YES];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Show Content")]) {
        [self exploreItem:item];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Channel Guide")]) {
        [self viewChild:selected item:item displayPoint:CGPointMake(0, 0)];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Mark as watched")]) {
        [self markVideo:(NSMutableDictionary*)item indexPath:selected watched:1];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Mark as unwatched")]) {
        [self markVideo:(NSMutableDictionary*)item indexPath:selected watched:0];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Play in party mode")]) {
        [self partyModeItem:item indexPath:selected];
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
            [self showInfo:selected menuItem:menuItem item:item tabToShow:choosedTab];
        }
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Play Trailer")]) {
        NSDictionary *itemParams = @{
            @"item": [NSDictionary dictionaryWithObjectsAndKeys: item[@"trailer"], @"file", nil],
        };
        [self playerOpen:itemParams index:selected];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Search Wikipedia")]) {
        [self searchWeb:item indexPath:selected serviceURL:[NSString stringWithFormat:@"http://%@.m.wikipedia.org/wiki?search=%%@", LOCALIZED_STR(@"WIKI_LANG")]];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Search last.fm charts")]) {
        [self searchWeb:item indexPath:selected serviceURL:@"http://m.last.fm/music/%@/+charts?subtype=tracks&rangetype=6month&go=Go"];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Execute program")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Execute video add-on")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Execute audio add-on")]) {
        [self SimpleAction:@"Addons.ExecuteAddon"
                    params:[NSDictionary dictionaryWithObjectsAndKeys:
                            item[@"addonid"], @"addonid",
                            nil]
                   success: LOCALIZED_STR(@"Add-on executed successfully")
                   failure:LOCALIZED_STR(@"Unable to execute the add-on")
         ];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Execute action")]) {
        [self SimpleAction:@"Input.ExecuteAction"
                    params:[NSDictionary dictionaryWithObjectsAndKeys:
                            item[@"label"], @"action",
                            nil]
                   success: LOCALIZED_STR(@"Action executed successfully")
                   failure:LOCALIZED_STR(@"Unable to execute the action")
         ];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Activate window")]) {
        [self SimpleAction:@"GUI.ActivateWindow"
                    params:[NSDictionary dictionaryWithObjectsAndKeys:
                            item[@"label"], @"window",
                            nil]
                   success: LOCALIZED_STR(@"Window activated successfully")
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
                                   item[@"thumbnail"], @"icon",
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
                                   item[@"thumbnail"], @"icon",
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
        NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
        NSMutableDictionary *sortDictionary = parameters[@"available_sort_methods"];
        if (sortDictionary[@"label"] != nil) {
            // In case of random still find index despite leading @"\u2713". This avoids inversion of sort order.
            NSString *targetedAction = [actiontitle containsString:LOCALIZED_STR(@"Random")] ? LOCALIZED_STR(@"Random") : actiontitle;
            NSUInteger sort_method_index = [sortDictionary[@"label"] indexOfObject:targetedAction];
            if (sort_method_index != NSNotFound) {
                if (sort_method_index < [sortDictionary[@"method"] count]) {
                    [activityIndicatorView startAnimating];
                    [UIView transitionWithView: activeLayoutView
                                      duration: 0.2
                                       options: UIViewAnimationOptionBeginFromCurrentState
                                    animations: ^{
                                        ((UITableView*)activeLayoutView).alpha = 1.0;
                                        CGRect frame;
                                        frame = [activeLayoutView frame];
                                        frame.origin.x = viewWidth;
                                        frame.origin.y = 0;
                                        ((UITableView*)activeLayoutView).frame = frame;
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
                [UIView transitionWithView: activeLayoutView
                                  duration: 0.2
                                   options: UIViewAnimationOptionBeginFromCurrentState
                                animations: ^{
                                    ((UITableView*)activeLayoutView).alpha = 1.0;
                                    CGRect frame;
                                    frame = [activeLayoutView frame];
                                    frame.origin.x = viewWidth;
                                    frame.origin.y = 0;
                                    ((UITableView*)activeLayoutView).frame = frame;
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
    [messagesView showMessage:LOCALIZED_STR(@"Button added") timeout:2.0 color:[Utilities getSystemGreen:0.95]];
    if (IS_IPAD) {
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIInterfaceCustomButtonAdded" object: nil];
    }
}

- (void)searchWeb:(NSDictionary*)item indexPath:(NSIndexPath*)indexPath serviceURL:(NSString*)serviceURL {
    mainMenu *menuItem = self.detailItem;
    if (menuItem.mainParameters.count > 0) {
        NSMutableDictionary *parameters = [Utilities indexKeyedMutableDictionaryFromArray:menuItem.mainParameters[0]];
        if (parameters[@"fromWikipedia"] != [NSNull null]) {
            if ([parameters[@"fromWikipedia"] boolValue]) {
                [self goBack:nil];
                return;
            }
        }
    }
    NSString *searchString = item[@"label"];
    if (forceMusicAlbumMode) {
        searchString = self.navigationItem.title;
        forceMusicAlbumMode = NO;
    }
    NSString *query = [searchString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *url = [NSString stringWithFormat:serviceURL, query];
    [Utilities SFloadURL:url fromctrl:self];
}

#pragma mark - Safari

- (void)safariViewControllerDidFinish:(SFSafariViewController*)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Gestures

- (void)handleSwipeFromLeft:(id)sender {
    mainMenu *menuItem = self.detailItem;
    if (!menuItem.disableNowPlaying) {
        [self showNowPlaying];
    }
}

- (void)handleSwipeFromRight:(id)sender {
    if ([self.navigationController.viewControllers indexOfObject:self] == 0) {
        [self revealMenu:nil];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

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
    if (menuItem) {
        topNavigationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -1, 240, 44)];
        topNavigationLabel.backgroundColor = UIColor.clearColor;
        topNavigationLabel.font = [UIFont boldSystemFontOfSize:11];
        topNavigationLabel.minimumScaleFactor = 8.0/11.0;
        topNavigationLabel.numberOfLines = 2;
        topNavigationLabel.adjustsFontSizeToFitWidth = YES;
        topNavigationLabel.textAlignment = NSTextAlignmentLeft;
        topNavigationLabel.textColor = UIColor.whiteColor;
        topNavigationLabel.shadowColor = [Utilities getGrayColor:0 alpha:0.5];
        topNavigationLabel.shadowOffset = CGSizeMake (0, -1);
        topNavigationLabel.highlightedTextColor = UIColor.blackColor;
        topNavigationLabel.opaque = YES;
        
        // Set up gestures
        if (!menuItem.disableNowPlaying) {
            UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromLeft:)];
            leftSwipe.numberOfTouchesRequired = 1;
            leftSwipe.cancelsTouchesInView = NO;
            leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
            [self.view addGestureRecognizer:leftSwipe];
        }
        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromRight:)];
        rightSwipe.numberOfTouchesRequired = 1;
        rightSwipe.cancelsTouchesInView = NO;
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:rightSwipe];
        
        // Set up navigation bar items on upper right
        UIImage *remoteButtonImage = [UIImage imageNamed:@"icon_menu_remote"];
        UIBarButtonItem *remoteButton = [[UIBarButtonItem alloc] initWithImage:remoteButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(showRemote)];
        UIImage *nowPlayingButtonImage = [UIImage imageNamed:@"icon_menu_playing"];
        UIBarButtonItem *nowPlayingButton = [[UIBarButtonItem alloc] initWithImage:nowPlayingButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(showNowPlaying)];
         if (!menuItem.disableNowPlaying) {
             self.navigationItem.rightBarButtonItems = @[remoteButton,
                                                         nowPlayingButton];
         }
         else {
             self.navigationItem.rightBarButtonItems = @[remoteButton];
         }
   }
}

- (CGRect)currentScreenBoundsDependOnOrientation {
    return UIScreen.mainScreen.bounds;
}

- (void)leaveFullscreen {
    if (stackscrollFullscreen) {
        [self toggleFullscreen:nil];
    }
}

- (void)toggleFullscreen:(id)sender {
    if ([self doesShowSearchResults] || self.searchController.isActive) {
        return;
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
                             button1.alpha = button2.alpha = button3.alpha = button4.alpha = button5.alpha = button6.alpha = button7.alpha = buttonsViewBgToolbar.alpha = topNavigationLabel.alpha = 1.0;
                             if ([self collectionViewCanBeEnabled]) {
                                 button6.hidden = NO;
                             }
                             sectionArray = [storeSectionArray copy];
                             sections = [storeSections mutableCopy];
                             [self choseParams];
                             if (forceCollection) {
                                 forceCollection = NO;
                                 [Utilities AnimView:(UITableView*)activeLayoutView AnimDuration:0.0 Alpha:0.0 XPos:viewWidth];
                                 enableCollectionView = NO;
                                 [self configureLibraryView];
                                 [Utilities AnimView:(UITableView*)activeLayoutView AnimDuration:0.0 Alpha:0.0 XPos:0];
                             }
                             [self setFlowLayoutParams];
                             [collectionView.collectionViewLayout invalidateLayout];
                             [collectionView reloadData];
                             [collectionView setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
                             NSDictionary *params = @{@"duration": @(animDuration)};
                             [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollFullScreenDisabled" object:self.view userInfo:params];
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
                             button1.alpha = button2.alpha = button3.alpha = button4.alpha = button5.alpha = button6.alpha = button7.alpha = buttonsViewBgToolbar.alpha = topNavigationLabel.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             button6.hidden = YES;
                             moreItemsViewController.view.hidden = YES;
                             if (!enableCollectionView) {
                                 forceCollection = YES;
                                 [Utilities AnimView:(UITableView*)activeLayoutView AnimDuration:0.0 Alpha:0.0 XPos:viewWidth];
                                 enableCollectionView = YES;
                                 [self configureLibraryView];
                                 [Utilities AnimView:(UITableView*)activeLayoutView AnimDuration:0.0 Alpha:0.0 XPos:0];
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
                             NSDictionary *params = @{
                                 @"hideToolbar": @NO,
                                 @"duration": @(animDuration),
                             };
                             [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollFullScreenEnabled" object:self.view userInfo:params];
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
    [self dismissViewControllerAnimated:YES completion:^{
    }];
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
    NSDictionary *mainFields = menuItem.mainFields[choosedTab];
    NSMutableDictionary *parameters = [Utilities indexKeyedMutableDictionaryFromArray:[menuItem.subItem mainParameters][choosedTab]];
    NSNumber *libraryRowHeight = parameters[@"rowHeight"] ?: @(menuItem.subItem.rowHeight);
    NSNumber *libraryThumbWidth = parameters[@"thumbWidth"] ?: @(menuItem.subItem.thumbWidth);
    NSNumber *filemodeRowHeight = parameters[@"rowHeight"] ?: @44;
    NSNumber *filemodeThumbWidth = parameters[@"thumbWidth"] ?: @44;
    NSMutableArray *mutableProperties = [parameters[@"parameters"][@"file_properties"] mutableCopy];
    if ([parameters[@"FrodoExtraArt"] boolValue] && AppDelegate.instance.serverVersion > 11) {
        [mutableProperties addObject:@"art"];
    }
    NSMutableArray *newParameters = [NSMutableArray arrayWithObjects:
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
    menuItem.subItem.mainLabel = item[@"label"];
    mainMenu *newMenuItem = [menuItem.subItem copy];
    [[newMenuItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
    newMenuItem.chooseTab = choosedTab;
    if (IS_IPHONE) {
        DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
        detailViewController.detailItem = newMenuItem;
        [self.navigationController pushViewController:detailViewController animated:YES];
    }
    else {
        if (stackscrollFullscreen) {
            [self toggleFullscreen:nil];
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

- (void)deleteTimer:(NSDictionary*)item indexPath:(NSIndexPath*)indexPath {
    NSNumber *itemid = @([item[@"timerid"] longValue]);
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
               [self deselectAtIndexPath:indexPath];
               if (error == nil && methodError == nil) {
                   [self.searchController setActive:NO];
                   [Utilities AnimView:(UITableView*)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:viewWidth];
                   [self startRetrieveDataWithRefresh:YES];
               }
               else {
                   NSString *message = @"";
                   message = [NSString stringWithFormat:LOCALIZED_STR(@"METHOD\n%@\n\nPARAMETERS\n%@\n"), methodToCall, [[[NSString stringWithFormat:@"%@", parameters] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
                   if (methodError != nil) {
                       message = [NSString stringWithFormat:@"%@\n\n%@\n", methodError, message];
                   }
                   if (error != nil) {
                       message = [NSString stringWithFormat:@"%@\n\n%@\n", error.localizedDescription, message];
                       
                   }
                   UIAlertController *alertView = [Utilities createAlertCopyClipboard:LOCALIZED_STR(@"ERROR") message:message];
                   [self presentViewController:alertView animated:YES completion:nil];
               }
    }];
}

- (void)recordChannel:(NSDictionary*)item indexPath:(NSIndexPath*)indexPath {
    NSString *methodToCall = @"PVR.Record";
    NSString *parameterName = @"channel";
    NSNumber *itemid = @([item[@"channelid"] longValue]);
    NSNumber *storeChannelid = itemid;
    NSNumber *storeBroadcastid = @([item[@"broadcastid"] longValue]);
    if ([itemid longValue] == 0) {
        itemid = @([item[@"pvrExtraInfo"][@"channelid"] longValue]);
        if ([itemid longValue] == 0) {
            return;
        }
        storeChannelid = itemid;
        NSDate *starttime = [xbmcDateFormatter dateFromString:item[@"starttime"]];
        NSDate *endtime = [xbmcDateFormatter dateFromString:item[@"endtime"]];
        float percent_elapsed = [Utilities getPercentElapsed:starttime EndDate:endtime];
        if (percent_elapsed < 0) {
            itemid = @([item[@"broadcastid"] longValue]);
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
               [self deselectAtIndexPath:indexPath];
               if (error == nil && methodError == nil) {
                   id cell = [self getCell:indexPath];
                   UIImageView *isRecordingImageView = (UIImageView*)[cell viewWithTag:104];
                   isRecordingImageView.hidden = !isRecordingImageView.hidden;
                   NSNumber *status = @(![item[@"isrecording"] boolValue]);
                   if ([item[@"broadcastid"] longValue] > 0) {
                       status = @(![item[@"hastimer"] boolValue]);
                   }
                   NSDictionary *params = @{
                       @"channelid": storeChannelid,
                       @"broadcastid": storeBroadcastid,
                       @"status": status,
                   };
                   [[NSNotificationCenter defaultCenter] postNotificationName: @"KodiServerRecordTimerStatusChange" object:nil userInfo:params];
               }
               else {
                   NSString *message = @"";
                    message = [NSString stringWithFormat:LOCALIZED_STR(@"METHOD\n%@\n\nPARAMETERS\n%@\n"), methodToCall, [[[NSString stringWithFormat:@"%@", parameters] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
                   if (methodError != nil) {
                       message = [NSString stringWithFormat:@"%@\n\n%@\n", methodError, message];
                   }
                   if (error != nil) {
                       message = [NSString stringWithFormat:@"%@\n\n%@\n", error.localizedDescription, message];
                       
                   }
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
    NSDictionary *mainFields = menuItem.mainFields[choosedTab];
    if (forceMusicAlbumMode) {
        mainFields = [AppDelegate.instance.playlistArtistAlbums mainFields][0];
        forceMusicAlbumMode = NO;
    }
    int playlistid = [mainFields[@"playlistid"] intValue];
    NSString *key = mainFields[@"row9"];
    id value = item[key];
    if ([item[@"filetype"] isEqualToString:@"directory"]) {
        key = @"directory";
    }
    // If Playlist.Insert and Playlist.Add for recordingid is not supported, use file path.
    else if (![VersionCheck hasRecordingIdPlaylistSupport] && [mainFields[@"row9"] isEqualToString:@"recordingid"]) {
        key = @"file";
        value = item[@"file"];
    }
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
                             @"item": [NSDictionary dictionaryWithObjectsAndKeys: value, key, nil],
                             @"position": @(newPos),
                         };
                         [[Utilities getJsonRPC] callMethod:action2 withParameters:params2 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                             if (error == nil && methodError == nil) {
                                 [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
                             }
                         }];
                     }
                     else {
                         [self addToPlaylist:playlistid currentItem:value currentKey:key indicator:cellActivityIndicator];
                     }
                 }
                 else {
                     [self addToPlaylist:playlistid currentItem:value currentKey:key indicator:cellActivityIndicator];
                 }
             }
             else {
                [self addToPlaylist:playlistid currentItem:value currentKey:key indicator:cellActivityIndicator];
             }
         }];
    }
    else {
        [self addToPlaylist:playlistid currentItem:value currentKey:key indicator:cellActivityIndicator];
    }
}

- (void)addToPlaylist:(NSInteger)playlistid currentItem:(id)value currentKey:(NSString*)key indicator:(UIActivityIndicatorView*)cellActivityIndicator {
    NSDictionary *params = @{
        @"playlistid": @(playlistid),
        @"item": [NSDictionary dictionaryWithObjectsAndKeys: value, key, nil],
    };
    [[Utilities getJsonRPC] callMethod:@"Playlist.Add" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        [cellActivityIndicator stopAnimating];
        if (error == nil && methodError == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
        }
    }];
    
}

- (void)playerOpen:(NSDictionary*)params index:(NSIndexPath*)indexPath {
    UIActivityIndicatorView *cellActivityIndicator = [self getCellActivityIndicator:indexPath];
    [self playerOpen:params index:indexPath indicator:cellActivityIndicator];
}

- (void)playerOpen:(NSDictionary*)params index:(NSIndexPath*)indexPath indicator:(UIActivityIndicatorView*)cellActivityIndicator {
    [cellActivityIndicator startAnimating];
    [[Utilities getJsonRPC] callMethod:@"Player.Open" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        [cellActivityIndicator stopAnimating];
        if (error == nil && methodError == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
            [self showNowPlaying];
            [Utilities checkForReviewRequest];
        }
//        else {
//            NSLog(@"terzo errore %@", methodError);
//        }
    }];
}

- (void)addPlayback:(NSDictionary*)item indexPath:(NSIndexPath*)indexPath position:(int)pos shuffle:(BOOL)shuffled {
    mainMenu *menuItem = [self getMainMenu:item];
    NSDictionary *mainFields = menuItem.mainFields[choosedTab];
    if (forceMusicAlbumMode) {
        mainFields = [AppDelegate.instance.playlistArtistAlbums mainFields][0];
        forceMusicAlbumMode = NO;
    }
    if (mainFields.count == 0) {
        return;
    }
    UIActivityIndicatorView *cellActivityIndicator = [self getCellActivityIndicator:indexPath];
    [cellActivityIndicator startAnimating];
    int playlistid = [mainFields[@"playlistid"] intValue];
    if ([mainFields[@"row8"] isEqualToString:@"channelid"] ||
        [mainFields[@"row8"] isEqualToString:@"broadcastid"]) {
        NSNumber *channelid = item[mainFields[@"row8"]];
        if ([mainFields[@"row8"] isEqualToString:@"broadcastid"]) {
            channelid = item[@"pvrExtraInfo"][@"channelid"];
        }
        NSDictionary *itemParams = @{
            @"item": [NSDictionary dictionaryWithObjectsAndKeys: channelid, @"channelid", nil],
        };
        [self playerOpen:itemParams index:indexPath indicator:cellActivityIndicator];
    }
    else if ([mainFields[@"row7"] isEqualToString:@"plugin"]) {
        NSDictionary *itemParams = @{
            @"item": [NSDictionary dictionaryWithObjectsAndKeys: item[@"file"], @"file", nil],
        };
        [self playerOpen:itemParams index:indexPath indicator:cellActivityIndicator];
    }
    else {
        id optionsParam = nil;
        id optionsValue = nil;
        if (AppDelegate.instance.serverVersion > 11) {
            optionsParam = @"options";
            optionsValue = @{@"shuffled": @(shuffled)};
        }
        [[Utilities getJsonRPC] callMethod:@"Playlist.Clear" withParameters:@{@"playlistid": @(playlistid)} onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
            if (error == nil && methodError == nil) {
                NSString *key = mainFields[@"row8"];
                id value = item[key];
                if ([item[@"filetype"] isEqualToString:@"directory"]) {
                    key = @"directory";
                }
                // If Playlist.Insert and Playlist.Add for recordingid is not supported, use file path.
                else if (![VersionCheck hasRecordingIdPlaylistSupport] && [mainFields[@"row8"] isEqualToString:@"recordingid"]) {
                    key = @"file";
                    value = item[@"file"];
                }
                NSDictionary *playlistParams = @{
                    @"playlistid": @(playlistid),
                    @"item": [NSDictionary dictionaryWithObjectsAndKeys: value, key, nil],
                };
                NSDictionary *playbackParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                                @{@"playlistid": @(playlistid), @"position": @(pos)}, @"item",
                                                optionsValue, optionsParam,
                                                nil];
                if (shuffled && AppDelegate.instance.serverVersion > 11) {
                    [[Utilities getJsonRPC]
                     callMethod:@"Player.SetPartymode"
                     withParameters:@{@"playerid": @(0), @"partymode": @NO}
                     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *internalError) {
                         [self playlistAndPlay:playlistParams
                                playbackParams:playbackParams
                                     indexPath:indexPath
                                     indicator:cellActivityIndicator];
                     }];
                }
                else {
                    [self playlistAndPlay:playlistParams
                           playbackParams:playbackParams
                                indexPath:indexPath
                                indicator:cellActivityIndicator];
                }
            }
            else {
                [cellActivityIndicator stopAnimating];
            }
        }];
    }
}

- (void)playlistAndPlay:(NSDictionary*)playlistParams playbackParams:(NSDictionary*)playbackParams indexPath:(NSIndexPath*)indexPath indicator:(UIActivityIndicatorView*)cellActivityIndicator {
    [[Utilities getJsonRPC] callMethod:@"Playlist.Add" withParameters:playlistParams onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
            [self playerOpen:playbackParams index:indexPath indicator:cellActivityIndicator];
        }
        else {
            [cellActivityIndicator stopAnimating];
        }
    }];
}

- (void)SimpleAction:(NSString*)action params:(NSDictionary*)parameters success:(NSString*)successMessage failure:(NSString*)failureMessage {
    [[Utilities getJsonRPC] callMethod:action withParameters:parameters onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil) {
            [messagesView showMessage:successMessage timeout:2.0 color:[Utilities getSystemGreen:0.95]];
        }
        else {
            [messagesView showMessage:failureMessage timeout:2.0 color:[Utilities getSystemRed:0.95]];
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
        NSMutableDictionary *parameters = [Utilities indexKeyedMutableDictionaryFromArray:menuItem.mainParameters[0]];
        if (parameters[@"fromShowInfo"] != [NSNull null]) {
            if ([parameters[@"fromShowInfo"] boolValue]) {
                [self goBack:nil];
                return;
            }
        }
    }
    menuItem = nil;
    if ([sender tag] == 0) {
        menuItem = [AppDelegate.instance.playlistArtistAlbums copy];
    }
    else if ([sender tag] == 1) {
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
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:menuItem.mainMethod[tabToShow]];
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[tabToShow]];
    
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
    NSArray *sheetActions = @[
        LOCALIZED_STR(@"Queue after current"),
        LOCALIZED_STR(@"Queue"),
        LOCALIZED_STR(@"Play"),
        LOCALIZED_STR(@"Play in shuffle mode"),
        LOCALIZED_STR(@"Album Details"),
        LOCALIZED_STR(@"Search Wikipedia"),
    ];
    selected = [NSIndexPath indexPathForRow:0 inSection:0];
    NSMutableDictionary *item = [sectionItem mutableCopy];
    item[@"label"] = self.navigationItem.title;
    forceMusicAlbumMode = YES;
    int rectOrigin = (int)((albumViewHeight - albumViewPadding * 2) / 2);
    [self showActionSheet:nil sheetActions:sheetActions item:item rectOriginX:rectOrigin + albumViewPadding rectOriginY:rectOrigin];
}

# pragma mark - JSON DATA Management

- (void)checkExecutionTime {
    if (startTime != 0) {
        elapsedTime += [NSDate timeIntervalSinceReferenceDate] - startTime;
    }
    startTime = [NSDate timeIntervalSinceReferenceDate];
    if (elapsedTime > WARNING_TIMEOUT && longTimeout == nil) {
        longTimeout = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 111, 56)];
        NSMutableArray *monkeys = [NSMutableArray arrayWithCapacity:MONKEY_COUNT];
        for (int i = 1; i <= MONKEY_COUNT; ++i) {
            [monkeys addObject:[UIImage imageNamed:[NSString stringWithFormat:@"monkeys_%d", i]]];
        }
        longTimeout.animationImages = monkeys;
        longTimeout.animationDuration = 5.0;
        longTimeout.animationRepeatCount = 0;
        longTimeout.center = activityIndicatorView.center;
        CGRect frame = longTimeout.frame;
        frame.origin.y = frame.origin.y + 30;
        frame.origin.x = frame.origin.x - 3;
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
    if (choosedTab >= menuItem.mainParameters.count) {
        return;
    }
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:menuItem.mainMethod[choosedTab]];
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
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
        [Utilities AnimView:(UITableView*)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
}

- (void)retrieveGlobalData:(BOOL)forceRefresh {
    NSArray *itemsAndTabs = AppDelegate.instance.globalSearchMenuLookup;
    
    mainMenu *menuItem = self.detailItem;
    NSMutableDictionary *parameters = [[Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]] mutableCopy];
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
        [((UITableView*)activeLayoutView).pullToRefreshView stopAnimating];
        [activeLayoutView setUserInteractionEnabled:YES];
        
        // Save and display
        choosedTab = 0;
        mainMenu *menuItem = self.detailItem;
        NSMutableDictionary *parameters = [[Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]] mutableCopy];
        [self saveData:parameters];
        [self indexAndDisplayData];
        return;
    }
    mainMenu *menuItem = itemsAndTabs[index][0];
    int activeTab = [itemsAndTabs[index][1] intValue];
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:menuItem.mainMethod[activeTab]];
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[activeTab]];
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
            [self loadDetailedData:itemsAndTabs index:index + 1 results:richData];
        }
    }];
}

- (void)retrieveData:(NSString*)methodToCall parameters:(NSDictionary*)parameters sectionMethod:(NSString*)SectionMethodToCall sectionParameters:(NSDictionary*)sectionParameters resultStore:(NSMutableArray*)resultStoreArray extraSectionCall:(BOOL) extraSectionCallBool refresh:(BOOL)forceRefresh {
    mainMenu *menuItem = self.detailItem;
    NSMutableDictionary *mutableParameters = [parameters mutableCopy];
    if (mutableParameters[@"file_properties"] != nil) {
        mutableParameters[@"properties"] = mutableParameters[@"file_properties"];
        [mutableParameters removeObjectForKey: @"file_properties"];
    }
    
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
                    NSAssert(NO, @"retrieveData: unexpected mode %d", filterModeType);
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

    [Utilities alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
//    NSLog(@"START");
    debugText.text = [NSString stringWithFormat:LOCALIZED_STR(@"METHOD\n%@\n\nPARAMETERS\n%@\n"), methodToCall, [[[NSString stringWithFormat:@"%@", mutableParameters] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
    elapsedTime = 0;
    startTime = [NSDate timeIntervalSinceReferenceDate];
    countExecutionTime = [NSTimer scheduledTimerWithTimeInterval:WARNING_TIMEOUT target:self selector:@selector(checkExecutionTime) userInfo:nil repeats:YES];
//    NSLog(@" METHOD %@ PARAMETERS %@", methodToCall, mutableParameters);
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
             if (methodError.code == -32100) {
                 [self animateNoResultsFound];
                 return;
             }
         }
         // If the feature to also show movies sets with only 1 movie is disabled and the current results
         // are movie sets, enable the postprocessing to ignore movies sets with only 1 movie.
         BOOL ignoreSingleMovieSets = !AppDelegate.instance.isGroupSingleItemSetsEnabled && [methodToCall isEqualToString:@"VideoLibrary.GetMovieSets"];
        
         // If we are reading PVR recordings or PVR timers, we need to filter them for the current mode in
         // postprocessing. Ignore Radio recordings/timers, if we are in TV mode. Or ignore TV recordings/timers,
         // if we are in Radio mode.
         BOOL isRecordingsOrTimersMethod = [methodToCall isEqualToString:@"PVR.GetRecordings"] || [methodToCall isEqualToString:@"PVR.GetTimers"];
         BOOL ignoreRadioItems = [menuItem.rootLabel isEqualToString:LOCALIZED_STR(@"Live TV")] && isRecordingsOrTimersMethod;
         BOOL ignoreTvItems = [menuItem.rootLabel isEqualToString:LOCALIZED_STR(@"Radio")] && isRecordingsOrTimersMethod;
         // If we are reading PVR timer, we need to filter them for the current mode in postprocessing. Ignore
         // scheduled recordings, if we are in timer rules mode. Or ignore timer rules, if scheduled recordings
         // are listed.
         NSDictionary *menuParam = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
         BOOL isTimerMethod = [methodToCall isEqualToString:@"PVR.GetTimers"];
         BOOL ignoreTimerRulesItems = isTimerMethod && [menuParam[@"label"] isEqualToString:LOCALIZED_STR(@"Timers")];
         BOOL ignoreTimerItems = isTimerMethod && [menuParam[@"label"] isEqualToString:LOCALIZED_STR(@"Timer rules")];
         // Override in case we are dealing with an older Kodi version which does not correctly support the JSON requests
         if (useCommonPvrRecordingsTimers) {
             ignoreTimerRulesItems = ignoreTimerItems = ignoreRadioItems = ignoreTvItems = NO;
         }
        
         if (error == nil && methodError == nil) {
//             debugText.text = [NSString stringWithFormat:@"%@\n*DATA: %@", debugText.text, methodResult];
//             NSLog(@"END JSON");
//             NSLog(@"DATO RICEVUTO %@", methodResult);
             [resultStoreArray removeAllObjects];
             [self.sections removeAllObjects];
             [activeLayoutView reloadData];
             if ([methodResult isKindOfClass:[NSDictionary class]]) {
                 NSMutableDictionary *mainFields = [[self.detailItem mainFields][choosedTab] mutableCopy];
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
                                 NSDictionary *newParameter = @{@"setid": @([item[@"setid"] longValue])};
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
                             NSString *sublabel = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]][@"morelabel"] ?: @"";
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
//                 NSLog(@"END STORE");
//                 NSLog(@"RICH RESULTS %@", resultStoreArray);
                 // Single Movie Sets are handled seperately
                 if (ignoreSingleMovieSets) {
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
//             NSLog(@"ERROR:%@ METHOD:%@", error, methodError);
             if (methodError != nil) {
                 debugText.text = [NSString stringWithFormat:@"%@\n\n%@\n", methodError, debugText.text];
             }
             if (error != nil) {
                 debugText.text = [NSString stringWithFormat:@"%@\n\n%@\n", error.localizedDescription, debugText.text];
                 
             }
             UIAlertController *alertView = [Utilities createAlertCopyClipboard:LOCALIZED_STR(@"ERROR") message:debugText.text];
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
            [((UITableView*)activeLayoutView).pullToRefreshView stopAnimating];
            [activeLayoutView setUserInteractionEnabled:YES];
            [self saveData:mutableParameters];
        }
        [self changeViewMode:filterModeType forceRefresh:forceRefresh];
    }
    else {
        if (forceRefresh) {
            [((UITableView*)activeLayoutView).pullToRefreshView stopAnimating];
            [activeLayoutView setUserInteractionEnabled:YES];
        }
        [self saveData:mutableParameters];
        [self indexAndDisplayData];
    }
}

- (void)animateNoResultsFound {
    [Utilities alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
    [activityIndicatorView stopAnimating];
    [((UITableView*)activeLayoutView).pullToRefreshView stopAnimating];
    [self setGridListButtonImage:enableCollectionView];
    [self setSortButtonImage:sortAscDesc];
}

- (void)showNoResultsFound:(NSMutableArray*)resultStoreArray refresh:(BOOL)forceRefresh {
    if (forceRefresh) {
        [((UITableView*)activeLayoutView).pullToRefreshView stopAnimating];
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
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
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
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:menuItem.mainMethod[choosedTab]];
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
            // Use localizedStandardCompare for all NSString items to be sorted (provides correct order for multi-digit
            // numbers). But do not use for any other types as this crashes.
            SEL selector = nil;
            if (copyRichResults.count > 0 && [copyRichResults[0][sortbymethod] isKindOfClass:[NSString class]]) {
                selector = @selector(localizedStandardCompare:);
            }
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
        NSDateComponents *nowDateComponents = [calendar components:components fromDate: nowDate];
        nowDate = [calendar dateFromComponents:nowDateComponents];
        NSUInteger countRow = 0;
        NSMutableArray *retrievedEPG = [NSMutableArray new];
        for (NSMutableDictionary *item in self.richResults) {
            NSDate *starttime = [xbmcDateFormatter dateFromString:item[@"starttime"]];
            NSDate *endtime = [xbmcDateFormatter dateFromString:item[@"endtime"]];
            NSDate *itemEndDate;
            NSDate *itemStartDate;
            if (starttime != nil && endtime != nil) {
                NSDateComponents *itemDateComponents = [calendar components:components fromDate: endtime];
                itemEndDate = [calendar dateFromComponents:itemDateComponents];
                itemDateComponents = [calendar components:components fromDate: starttime];
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
                                   menuItem.mainParameters[choosedTab][0][@"channelid"], @"channelid",
                                   retrievedEPG, @"epgArray",
                                   nil];
        [NSThread detachNewThreadSelector:@selector(backgroundSaveEPGToDisk:) toTarget:self withObject:epgparams];
    }
    else {
        if (!albumView && sortbymethod && ![sortbymethod isEqualToString:@"random"] && ([self isSortDifferentToDefault] || [self isEligibleForSections:copyRichResults] || [sortbymethod isEqualToString:@"itemgroup"])) {
            addUITableViewIndexSearch = YES;
            for (NSDictionary *item in copyRichResults) {
                NSString *searchKey = @"";
                if ([item[sortbymethod] isKindOfClass:[NSMutableArray class]] || [item[sortbymethod] isKindOfClass:[NSArray class]]) {
                    searchKey = [item[sortbymethod] componentsJoinedByString:@""];
                }
                else {
                    searchKey = item[sortbymethod];
                }
                NSString *key = [self getIndexTableKey:searchKey sortMethod:sortMethodName];
                BOOL found = [[self.sections allKeys] containsObject:key];
                if (!found) {
                    [self.sections setValue:[NSMutableArray new] forKey:key];
                }
                [self.sections[key] addObject:item];
            }
        }
        else {
            [self.sections setValue:[NSMutableArray new] forKey:@""];
            for (NSDictionary *item in copyRichResults) {
                [self.sections[@""] addObject:item];
            }
        }
    }
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
    [self setSortButtonImage:sortAscDesc];
    [self displayData];
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
        NSDateComponents *components = [[NSCalendar currentCalendar] components: NSCalendarUnitYear fromDate:[xbmcDateFormatter dateFromString:currentValue]];
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
    numResults = (int)self.richResults.count;
    mainMenu *menuItem = self.detailItem;
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
    
    BOOL useMainLabel = ![menuItem.mainLabel isEqualToString:menuItem.rootLabel];
    NSString *labelText = useMainLabel ? menuItem.mainLabel : parameters[@"label"];
    self.navigationItem.backButtonTitle = labelText;
    if (!albumView) {
        labelText = [labelText stringByAppendingFormat:@" (%d)", numResults];
    }
    [self setFilternameLabel:labelText runFullscreenButtonCheck:NO forceHide:NO];
    
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
    [Utilities AnimView:(UITableView*)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0 YPos:0];
    [dataList setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
    [collectionView layoutSubviews];
    [collectionView setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
    if (channelGuideView && autoScrollTable != nil && autoScrollTable.row < [dataList numberOfRowsInSection:autoScrollTable.section]) {
            [dataList scrollToRowAtIndexPath:autoScrollTable atScrollPosition:UITableViewScrollPositionTop animated: NO];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
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
    selection = [dataList indexPathForSelectedRow];
    if (selection) {
		[dataList deselectRowAtIndexPath:selection animated:YES];
    }
    
    for (selection in [collectionView indexPathsForSelectedItems]) {
        [collectionView deselectItemAtIndexPath:selection animated:YES];
    }

    // When going back to a Global Search view ensure we are in first index
    if (globalSearchView) {
        choosedTab = 0;
    }
    [self choseParams];

    if ([self isModal]) {
        UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissAddAction:)];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
    [self hideButtonListWhenEmpty];
// TRICK WHEN CHILDREN WAS FORCED TO PORTRAIT
//    UIViewController *c = [[UIViewController alloc]init];
//    [self presentViewController:c animated:NO completion:nil];
//    [self dismissViewControllerAnimated:NO completion:nil];
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
    if (isViewDidLoad) {
        [activeLayoutView addSubview:self.searchController.searchBar];
        [self initIpadCornerInfo];
        if (globalSearchView) {
            [self retrieveGlobalData:NO];
        }
        else {
            [self startRetrieveDataWithRefresh:NO];
        }
        isViewDidLoad = NO;
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
    [self setButtonViewContent:choosedTab];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
    count = MIN(count, MAX_NORMAL_BUTTONS);
    activeTab = MIN(activeTab, MAX_NORMAL_BUTTONS);
    for (int i = 0; i < count; i++) {
        img = [UIImage imageNamed:buttons[i]];
        imageOff = [Utilities colorizeImage:img withColor:ICON_TINT_COLOR];
        imageOn = [Utilities colorizeImage:img withColor:ICON_TINT_COLOR_ACTIVE];
        [buttonsIB[i] setBackgroundImage:imageOff forState:UIControlStateNormal];
        [buttonsIB[i] setBackgroundImage:imageOn forState:UIControlStateSelected];
        [buttonsIB[i] setBackgroundImage:imageOn forState:UIControlStateHighlighted];
        [buttonsIB[i] setEnabled:YES];
    }
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
        default:
            // 5 or more buttons/actions require a "more" button
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
    viewWidth = [self currentScreenBoundsDependOnOrientation].size.width;
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
        viewWidth = [self currentScreenBoundsDependOnOrientation].size.width;
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
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
    return ([parameters[@"enableCollectionView"] boolValue]);
}

- (BOOL)collectionViewIsEnabled {
    if (![self collectionViewCanBeEnabled]) {
        return NO;
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    mainMenu *menuItem = self.detailItem;
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:menuItem.mainMethod[choosedTab]];
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
                arr_properties = [NSArray array];
            }
            
            NSArray *arr_sort = parameters[@"parameters"][@"sort"];
            if (arr_sort == nil) {
                arr_sort = [NSArray array];
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
    if (methods != nil) {
        NSString *sortKey = [NSString stringWithFormat:@"%@_sort_method", [self getCacheKey:methods[@"method"] parameters:[parameters mutableCopy]]];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if ([userDefaults objectForKey:sortKey] != nil) {
            sortMethod = [userDefaults objectForKey:sortKey];
        }
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

#pragma mark UISearchController Delegate Methods

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
    [self.searchController.searchBar setShowsCancelButton:YES animated:NO];
    [self.searchController.searchBar sizeToFit];
    [self.searchController setActive:NO];
}

- (void)showSearchBar {
    UISearchBar *searchbar = self.searchController.searchBar;
    searchbar.frame = CGRectMake(0, 0, self.view.frame.size.width, searchbar.frame.size.height);
    if (showbar) {
        [self.view addSubview:searchbar];
    }
    else {
        [searchbar removeFromSuperview];
        [activeLayoutView addSubview:searchbar];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self showSearchBar];
    viewWidth = self.view.bounds.size.width;
}

- (void)willPresentSearchController:(UISearchController*)controller {
    showbar = YES;
    [self showSearchBar];
}

- (void)willDismissSearchController:(UISearchController*)controller {
    showbar = NO;
    [self showSearchBar];
    [self setIndexViewVisibility];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Dismiss any visible action sheet as the origin is not corrected in fullscreen
    if (IS_IPAD && stackscrollFullscreen && [actionView isViewLoaded]) {
        [actionView dismissViewControllerAnimated:YES completion:nil];
    }
    
    // Force reloading of index overlay after rotation
    sectionNameOverlayView = nil;
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (stackscrollFullscreen) {
            [self setFlowLayoutParams];
            [collectionView.collectionViewLayout invalidateLayout];
            [collectionView reloadData];
        }
        [activeLayoutView setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
    }
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {}];
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
        BOOL hideToolbar = hasNonEmptySearchString || hasEmptyToolbar;
        [self hideButtonList:hideToolbar];
        
        // Hide index when search string is non-empty
        self.indexView.hidden = hasNonEmptySearchString;
    }
}

- (void)searchForText:(NSString*)searchText {
    // filter here
    [self.filteredListContent removeAllObjects];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"label CONTAINS[cd] %@", searchText];
    if (globalSearchView) {
        pred = [NSPredicate predicateWithFormat:@"label CONTAINS[cd] %@ || artist CONTAINS[cd] %@ || director CONTAINS[cd] %@", searchText, searchText, searchText];
    }
    self.filteredListContent = [NSMutableArray arrayWithArray:[self.richResults filteredArrayUsingPredicate:pred]];
    numFilteredResults = (int)self.filteredListContent.count;
}

- (NSString*)getCurrentSortAscDesc:(NSDictionary*)methods withParameters:(NSDictionary*)parameters {
    NSString *sortAscDescSaved = parameters[@"parameters"][@"sort"][@"order"];
    if (methods != nil) {
        NSString *sortKey = [NSString stringWithFormat:@"%@_sort_ascdesc", [self getCacheKey:methods[@"method"] parameters:[parameters mutableCopy]]];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if ([userDefaults objectForKey:sortKey] != nil) {
            sortAscDescSaved = [userDefaults objectForKey:sortKey];
        }
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
    isViewDidLoad = YES;
    sectionHeight = LIST_SECTION_HEADER_HEIGHT;
    dataList.tableFooterView = [UIView new];
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
    dataList.tableFooterView = [UIView new];
    
    [self initSearchController];
    self.navigationController.view.backgroundColor = UIColor.blackColor;
    self.definesPresentationContext = NO;
    iOSYDelta = self.searchController.searchBar.frame.size.height;

    if (@available(iOS 15.0, *)) {
        dataList.sectionHeaderTopPadding = 0;
    }
    
    [button6 addTarget:self action:@selector(handleChangeLibraryView) forControlEvents:UIControlEventTouchUpInside];

    [button7 addTarget:self action:@selector(handleChangeSortLibrary) forControlEvents:UIControlEventTouchUpInside];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    dataList.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
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
        if ([subView isKindOfClass: [UITextField class]]) {
            [(UITextField*)subView setKeyboardAppearance: UIKeyboardAppearanceAlert];
        }
    }
    self.view.userInteractionEnabled = YES;
    choosedTab = 0;
    mainMenu *menuItem = self.detailItem;
    numTabs = (int)menuItem.mainMethod.count;
    if (menuItem.chooseTab) {
        choosedTab = menuItem.chooseTab;
    }
    if (choosedTab >= numTabs) {
        choosedTab = 0;
    }
    filterModeType = menuItem.currentFilterMode;
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:menuItem.mainMethod[choosedTab]];
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
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
        buttonsView.backgroundColor = TOOLBAR_TINT_COLOR;
    }
    else {
        buttonsViewBgToolbar.backgroundColor = TOOLBAR_TINT_COLOR;
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
    else if ([menuItem.rootLabel isEqualToString:LOCALIZED_STR(@"Global Search")]) {
        globalSearchView = YES;
    }
    
    if ([parameters[@"blackTableSeparator"] boolValue] && ![Utilities getPreferTvPosterMode]) {
        dataList.separatorInset = UIEdgeInsetsZero;
        dataList.separatorColor = [Utilities getGrayColor:38 alpha:1];
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
    
    detailView.clipsToBounds = YES;
    NSDictionary *itemSizes = parameters[@"itemSizes"];
    if (IS_IPHONE) {
        [self setIphoneInterface:itemSizes[@"iphone"]];
    }
    else {
        [self setIpadInterface:itemSizes[@"ipad"]];
    }
    
    messagesView = [[MessagesView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, DEFAULT_MSG_HEIGHT) deltaY:0 deltaX:0];
    [self.view addSubview:messagesView];
    
    frame = dataList.frame;
    if (parameters[@"animationStartX"] != nil) {
        frame.origin.x = [parameters[@"animationStartX"] intValue];
    }
    else {
        frame.origin.x = viewWidth;
    }
    if ([parameters[@"animationStartBottomScreen"] boolValue]) {
        frame.origin.y = UIScreen.mainScreen.bounds.size.height;
    }
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
    
    [activityIndicatorView startAnimating];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleTabHasChanged:)
                                                 name: @"tabHasChanged"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(revealMenu:)
                                                 name: @"RevealMenu"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(hideKeyboard:)
                                                 name: @"ECSlidingViewUnderLeftWillAppear"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(showKeyboard:)
                                                 name: @"ECSlidingViewTopDidReset"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleCollectionIndexStateBegin)
                                                 name: @"BDKCollectionIndexViewGestureRecognizerStateBegin"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleCollectionIndexStateEnded)
                                                 name: @"BDKCollectionIndexViewGestureRecognizerStateEnded"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnterForeground:)
                                                 name: @"UIApplicationWillEnterForegroundNotification"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(leaveFullscreen)
                                                 name: @"LeaveFullscreen"
                                               object: nil];
    if (channelListView || channelGuideView) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleRecordTimerStatusChange:)
                                                     name: @"KodiServerRecordTimerStatusChange"
                                                   object: nil];
    }
}

- (void)handleRecordTimerStatusChange:(NSNotification*)note {
    NSDictionary *theData = note.userInfo;
    NSArray *keys = [self.sections allKeys];
    for (NSString *keysV in keys) {
        [self checkUpdateRecordingState: self.sections[keysV] dataInfo:theData];
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
        titleView = [[UIView alloc] initWithFrame:CGRectMake(STACKSCROLL_WIDTH - FIXED_SPACE_WIDTH, 0, FIXED_SPACE_WIDTH - 5, buttonsView.frame.size.height)];
        titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        topNavigationLabel.textAlignment = NSTextAlignmentRight;
        topNavigationLabel.font = [UIFont boldSystemFontOfSize:14];
        topNavigationLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [titleView addSubview:topNavigationLabel];
        [buttonsView addSubview:titleView];
        [self checkFullscreenButton:NO];
    }
    else {
        // Remove the reserved fixed space which is only used for iPad corner info
        for (UILabel *view in buttonsView.subviews) {
            if ([view isKindOfClass:[UIToolbar class]]) {
                UIToolbar *bar = (UIToolbar*)view;
                NSMutableArray *items = [NSMutableArray arrayWithArray:bar.items];
                [items removeObjectAtIndex:15];
                [bar setItems:items animated:NO];
            }
        }
    }
}

- (void)checkFullscreenButton:(BOOL)forceHide {
    mainMenu *menuItem = self.detailItem;
    if (IS_IPAD && menuItem.enableSection) {
        NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
        if ([self collectionViewCanBeEnabled] && ([parameters[@"enableLibraryFullScreen"] boolValue] && !forceHide)) {
            int buttonPadding = 1;
            if (fullscreenButton == nil) {
                fullscreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
                fullscreenButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
                fullscreenButton.showsTouchWhenHighlighted = YES;
                fullscreenButton.frame = CGRectMake(0, 0, 26, 26);
                fullscreenButton.contentMode = UIViewContentModeCenter;
                [fullscreenButton setImage:[UIImage imageNamed:@"button_fullscreen"] forState:UIControlStateNormal];
                fullscreenButton.layer.cornerRadius = 2;
                fullscreenButton.tintColor = UIColor.whiteColor;
                [fullscreenButton addTarget:self action:@selector(toggleFullscreen:) forControlEvents:UIControlEventTouchUpInside];
                fullscreenButton.frame = CGRectMake(titleView.frame.size.width - fullscreenButton.frame.size.width - buttonPadding, titleView.frame.size.height / 2 - fullscreenButton.frame.size.height / 2, fullscreenButton.frame.size.width, fullscreenButton.frame.size.height);
                [titleView addSubview:fullscreenButton];
            }
            if (twoFingerPinch == nil) {
                twoFingerPinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerPinch:)];
                [self.view addGestureRecognizer:twoFingerPinch];
            }
            topNavigationLabel.frame = CGRectMake(0, 0, titleView.frame.size.width - fullscreenButton.frame.size.width - buttonPadding * 2, 44);
            fullscreenButton.hidden = NO;
            twoFingerPinch.enabled = YES;
        }
        else {
            topNavigationLabel.frame = CGRectMake(0, 0, titleView.frame.size.width - 4, 44);
            fullscreenButton.hidden = YES;
            twoFingerPinch.enabled = NO;
        }
    }
}

- (void)twoFingerPinch:(UIPinchGestureRecognizer*)recognizer {
    if ([recognizer state] == UIGestureRecognizerStateEnded) {
        if ((recognizer.scale > 1 && !stackscrollFullscreen) || (recognizer.scale <= 1 && stackscrollFullscreen)) {
            [self toggleFullscreen:nil];
        }
    }
    return;
}

- (void)checkDiskCache {
    mainMenu *menuItem = self.detailItem;
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL diskcache_preference = [userDefaults boolForKey:@"diskcache_preference"];
    enableDiskCache = diskcache_preference && [parameters[@"enableLibraryCache"] boolValue];
    [dataList setShowsPullToRefresh:enableDiskCache];
    [collectionView setShowsPullToRefresh:enableDiskCache];
}

- (void)handleEnterForeground:(NSNotification*)sender {
}

- (void)handleChangeLibraryView {
    if ([self doesShowSearchResults] || self.searchController.isActive) {
        return;
    }
    mainMenu *menuItem = self.detailItem;
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:menuItem.mainMethod[choosedTab]];
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
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
                             CGRect frame;
                             frame = [activeLayoutView frame];
                             frame.origin.x = viewWidth;
                             ((UITableView*)activeLayoutView).frame = frame;
                         }
                         completion:^(BOOL finished) {
                             recentlyAddedView = [parameters[@"collectionViewRecentlyAdded"] boolValue];
                             enableCollectionView = [self collectionViewIsEnabled];
                             [self configureLibraryView];
                             [Utilities AnimView:(UITableView*)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
                             [activeLayoutView setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
                         }];
    }
}

- (void)handleChangeSortLibrary {
    if ([self doesShowSearchResults] || self.searchController.isActive) {
        return;
    }
    selected = nil;
    mainMenu *menuItem = self.detailItem;
    if (choosedTab >= menuItem.mainParameters.count) {
        return;
    }
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
    NSDictionary *sortDictionary = parameters[@"available_sort_methods"];
    NSDictionary *item = @{
        @"label": LOCALIZED_STR(@"Sort by"),
        @"genre": [NSString stringWithFormat:@"\n(%@)", LOCALIZED_STR(@"tap the selection\nto reverse the sort order")],
    };
    NSMutableArray *sortOptions = [sortDictionary[@"label"] mutableCopy];
    if (sortMethodIndex != -1) {
        [sortOptions replaceObjectAtIndex:sortMethodIndex withObject:[NSString stringWithFormat:@"\u2713 %@", sortOptions[sortMethodIndex]]];
    }
    [self showActionSheet:nil sheetActions:sortOptions item:item rectOriginX:[button7 convertPoint:button7.center toView:buttonsView.superview].x rectOriginY:buttonsView.center.y - button7.frame.size.height / 2];
}

- (void)handleLongPressSortButton:(UILongPressGestureRecognizer*)gestureRecognizer {
    mainMenu *menuItem = self.detailItem;
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
            [activityIndicatorView startAnimating];
            [UIView transitionWithView: activeLayoutView
                              duration: 0.2
                               options: UIViewAnimationOptionBeginFromCurrentState
                            animations: ^{
                                ((UITableView*)activeLayoutView).alpha = 1.0;
                                CGRect frame;
                                frame = [activeLayoutView frame];
                                frame.origin.x = viewWidth;
                                frame.origin.y = 0;
                                ((UITableView*)activeLayoutView).frame = frame;
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
            break;
        default:
            break;
    }
}

- (void)dealloc {
    [self.richResults removeAllObjects];
    [self.filteredListContent removeAllObjects];
    [self.sections removeAllObjects];
    [channelListUpdateTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    self.searchController.searchResultsUpdater = nil;
    self.searchController.searchBar.delegate = nil;
    self.searchController.delegate = nil;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}
							
@end
