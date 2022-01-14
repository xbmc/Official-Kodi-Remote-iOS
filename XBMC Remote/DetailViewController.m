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

@interface DetailViewController ()
- (void)configureView;
@end

@implementation DetailViewController

@synthesize detailItem = _detailItem;
@synthesize activityIndicatorView;
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
    NSString *path = [epgCachePath stringByAppendingPathComponent:filename];
    NSMutableArray *epgArray = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
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
        NSString *dicPath = [epgCachePath stringByAppendingPathComponent:filename];
        [NSKeyedArchiver archiveRootObject:epgArray toFile:dicPath];
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
    channelEPG[@"refresh_data"] = @(YES);
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
                channelEPG[@"refresh_data"] = @(NO);
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
        float total_seconds = [channelEPG[@"endtime"] timeIntervalSince1970] - [channelEPG[@"starttime"] timeIntervalSince1970];
        float elapsed_seconds = [[NSDate date] timeIntervalSince1970] - [channelEPG[@"starttime"] timeIntervalSince1970];
        float percent_elapsed = (elapsed_seconds/total_seconds) * 100.0f;
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
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"]; // all times in Kodi PVR are UTC

    for (id EPGobject in broadcasts) {
        NSDate *starttime = [dateFormatter dateFromString:EPGobject[@"starttime"]];
        NSDate *endtime = [dateFormatter dateFromString:EPGobject[@"endtime"]];
        [retrievedEPG addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                 starttime, @"starttime",
                                 endtime, @"endtime",
                                 EPGobject[@"title"], @"title",
                                 EPGobject[@"label"], @"label",
                                 EPGobject[@"plot"], @"plot",
                                 EPGobject[@"plotoutline"], @"plotoutline",
                                 nil]];
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
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               if (error == nil && methodError == nil && [methodResult isKindOfClass: [NSDictionary class]]) {
                   if (((NSNull*)methodResult[@"broadcasts"] != [NSNull null])) {
                       
                       NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                               channelid, @"channelid",
                                               indexPath, @"indexPath",
                                               tableView, @"tableView",
                                               item, @"item",
                                               methodResult[@"broadcasts"], @"broadcasts",
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
    GlobalData *obj = [GlobalData getInstance];
    return [[NSString stringWithFormat:@"%@%@%@%d%d%@%@", obj.serverIP, obj.serverPort, obj.serverDescription, serverVersion, serverMinorVersion, fieldA, fieldB] MD5String];
}

- (void)saveData:(NSMutableDictionary*)mutableParameters {
    if (!enableDiskCache) {
        return;
    }
    if (mutableParameters != nil) {
        NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainMethod][choosedTab]];
        NSString *viewKey = [self getCacheKey:methods[@"method"] parameters:mutableParameters];
        NSString *diskCachePath = AppDelegate.instance.libraryCachePath;
//        if (paths.count > 0) {
        

            NSString *filename = [NSString stringWithFormat:@"%@.richResults.dat", viewKey];
            NSString *dicPath = [diskCachePath stringByAppendingPathComponent:filename];
            [NSKeyedArchiver archiveRootObject:self.richResults toFile:dicPath];
            [self updateSyncDate:dicPath];

//            filename = [NSString stringWithFormat:@"%@.sections.dat", viewKey];
//            dicPath = [[paths[0] stringByAppendingPathComponent:fullNamespace] stringByAppendingPathComponent:filename];
//            [NSKeyedArchiver archiveRootObject:self.sections toFile:dicPath];
//            
//            filename = [NSString stringWithFormat:@"%@.sectionArray.dat", viewKey];
//            dicPath = [[paths[0] stringByAppendingPathComponent:fullNamespace] stringByAppendingPathComponent:filename];
//            
//            [NSKeyedArchiver archiveRootObject:self.sectionArray toFile:dicPath];
//            
//            filename = [NSString stringWithFormat:@"%@.sectionArrayOpen.dat", viewKey];
//            dicPath = [[paths[0] stringByAppendingPathComponent:fullNamespace] stringByAppendingPathComponent:filename];
//            [NSKeyedArchiver archiveRootObject:self.sectionArrayOpen toFile:dicPath];
//            
            filename = [NSString stringWithFormat:@"%@.extraSectionRichResults.dat", viewKey];
            dicPath = [diskCachePath stringByAppendingPathComponent:filename];
            [NSKeyedArchiver archiveRootObject:self.extraSectionRichResults toFile:dicPath];
//        }
    }
}

- (void)loadDataFromDisk:(NSDictionary*)params {
    NSString *viewKey = [self getCacheKey:params[@"methodToCall"] parameters:params[@"mutableParameters"]];
    NSString *path = [libraryCachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.richResults.dat", viewKey]];
    NSMutableArray *tempArray;
//    NSMutableDictionary *tempDict;
    self.richResults = nil;
//    self.sections = nil;
    self.sectionArray = nil;
    self.sectionArrayOpen = nil;
    self.extraSectionRichResults = nil;
    
    self.sections = [NSMutableDictionary new];
    
    tempArray = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    self.richResults = tempArray;
    
//    path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sections.dat", viewKey]];
//    tempDict = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
//    self.sections = tempDict;
//    
//    path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sectionArray.dat", viewKey]];
//    tempArray = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
//    self.sectionArray = tempArray;
//    
//    path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sectionArrayOpen.dat", viewKey]];
//    tempArray = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
//    self.sectionArrayOpen = tempArray;
//    
    path = [libraryCachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.extraSectionRichResults.dat", viewKey]];
    tempArray = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
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
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [libraryCachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.richResults.dat", viewKey]];
    if ([fileManager fileExistsAtPath:path]) {
        NSDictionary *extraParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                     methodToCall, @"methodToCall",
                                     mutableParameters, @"mutableParameters",
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

- (void)setFilternameLabel:(NSString*)labelText runFullscreenButtonCheck:(BOOL)check forceHide:(BOOL)forceHide {
    self.navigationItem.title = labelText;
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

- (void)setCollectionViewIndexVisibility {
    if (enableCollectionView) {
        // Get the index titles
        NSMutableArray *tmpArr = [[NSMutableArray alloc] initWithArray:self.sectionArray];
        if (tmpArr.count > 1) {
            [tmpArr replaceObjectAtIndex:0 withObject:@"🔍"];
        }
        self.indexView.indexTitles = [NSArray arrayWithArray:tmpArr];
        
        // Only show the collection view index, if there are valid index titles to show
        if (self.indexView.indexTitles.count > 1) {
            self.indexView.hidden = NO;
        }
        else {
            self.indexView.hidden = YES;
        }
    }
    else {
        self.indexView.hidden = YES;
    }
}

- (NSDictionary*)getItemFromIndexPath:(NSIndexPath*)indexPath {
    if ([self doesShowSearchResults]) {
        return self.filteredListContent[indexPath.row];
    }
    else {
        return [self.sections objectForKey:self.sectionArray[indexPath.section]][indexPath.row];
    }
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

- (void)setViewColor:(UIView*)view image:(UIImage*)image isTopMost:(BOOL)isTopMost lab12color:(UIColor*)lab12color label34Color:(UIColor*)lab34color fontshadow:(UIColor*)shadow label1:(UILabel*)label1 label2:(UILabel*)label2 label3:(UILabel*)label3 label4:(UILabel*)label4 {

    // Gather average cover color and limit saturation
    UIColor* mainColor = [Utilities averageColor:image inverse:NO];
    mainColor = [Utilities limitSaturation:mainColor satmax:0.33];
    
    // Create gradient based on average color
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = view.bounds;
    gradient.colors = @[(id)[mainColor CGColor], (id)[[Utilities lighterColorForColor:mainColor] CGColor]];
    [view.layer insertSublayer:gradient atIndex:1];
    
    // Set text/shadow colors
    lab12color = [Utilities updateColor:mainColor
                             lightColor:[Utilities getGrayColor:255 alpha:1.0]
                              darkColor:[Utilities getGrayColor:0 alpha:1.0]];
    shadow = [Utilities updateColor:mainColor
                         lightColor:[Utilities getGrayColor:0 alpha:0.3]
                          darkColor:[Utilities getGrayColor:255 alpha:0.3]];
    lab34color = [Utilities updateColor:mainColor
                             lightColor:[Utilities getGrayColor:255 alpha:0.7]
                              darkColor:[Utilities getGrayColor:0 alpha:0.6]];
    
    [self setLabelColor:lab12color
           label34Color:lab34color
             fontshadow:shadow
                 label1:label1
                 label2:label2
                 label3:label3
                 label4:label4];
    
    // Only the top most item shall define albumcolor, searchbar tint and navigationbar tint
    if (isTopMost) {
        albumColor = mainColor;
        [self setSearchBarColor:albumColor];
        self.navigationController.navigationBar.tintColor = [Utilities lighterColorForColor:albumColor];
    }
}

- (void)setLabelColor:(UIColor*)lab12color label34Color:(UIColor*)lab34color fontshadow:(UIColor*)shadow label1:(UILabel*)label1 label2:(UILabel*)label2 label3:(UILabel*)label3 label4:(UILabel*)label4 {
    label1.shadowColor = shadow;
    label1.textColor = lab12color;
    label2.shadowColor = shadow;
    label2.textColor = lab12color;
    label3.shadowColor = shadow;
    label3.textColor = lab34color;
    label4.shadowColor = shadow;
    label4.textColor = lab34color;
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

- (void)setSortButtonImage:(NSString*)sortOrder {
    NSString *imgName = [sortOrder isEqualToString:@"descending"] ? @"st_sort_desc" : @"st_sort_asc";
    UIImage *image = [Utilities colorizeImage:[UIImage imageNamed:imgName] withColor:UIColor.lightGrayColor];
    [button7 setBackgroundImage:image forState:UIControlStateNormal];
}

- (void)setButtonViewContent {
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainMethod][choosedTab]];
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
    
    // Show grid/list button when grid view is possible
    button6.hidden = YES;
    if ([self collectionViewCanBeEnabled]) {
        button6.hidden = NO;
    }
    
    // Set up sorting
    sortMethodIndex = -1;
    sortMethodName = nil;
    sortAscDesc = nil;
    [self setUpSort:methods parameters:parameters];
    
    // Show sort button when sorting is possible
    button7.hidden = YES;
    if (parameters[@"available_sort_methods"] != nil) {
        button7.hidden = NO;
    }
    
    [self hideButtonListWhenEmpty];
}

- (void)hideButtonList:(BOOL)hide {
    if (hide) {
        buttonsView.hidden = YES;
        
        UIEdgeInsets tableViewInsets = dataList.contentInset;
        tableViewInsets.bottom = 0;
        dataList.contentInset = tableViewInsets;
        dataList.scrollIndicatorInsets = tableViewInsets;
        collectionView.contentInset = tableViewInsets;
        collectionView.scrollIndicatorInsets = tableViewInsets;
    }
    else {
        buttonsView.hidden = NO;
        
        UIEdgeInsets tableViewInsets = dataList.contentInset;
        tableViewInsets.bottom = 44;
        dataList.contentInset = tableViewInsets;
        dataList.scrollIndicatorInsets = tableViewInsets;
        collectionView.contentInset = tableViewInsets;
        collectionView.scrollIndicatorInsets = tableViewInsets;
    }
}

- (void)hideButtonListWhenEmpty {
    // Hide the toolbar when no button is shown at all
    BOOL hide = button1.hidden && button2.hidden && button3.hidden && button4.hidden &&
                button5.hidden && button6.hidden && button7.hidden;
    [self hideButtonList:hide];
}

- (void)toggleOpen:(UITapGestureRecognizer*)sender {
    NSInteger section = [sender.view tag];
    [self.sectionArrayOpen replaceObjectAtIndex:section withObject:@(![self.sectionArrayOpen[section] boolValue])];
    NSInteger countEpisodes = [[self.sections objectForKey:self.sectionArray[section]] count];
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (NSInteger i = 0; i < countEpisodes; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
    }
    UIButton *toggleButton = (UIButton*)[sender.view viewWithTag:99];
    if ([self.sectionArrayOpen[section] boolValue]) {
        [dataList beginUpdates];
        [dataList insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [dataList endUpdates];
        toggleButton.selected = YES;
    }
    else {
        toggleButton.selected = NO;
        [dataList beginUpdates];
        [dataList deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [dataList endUpdates];
        if (section > 0) {
            CGRect sectionRect = [dataList rectForSection:section - 1];
            [dataList scrollRectToVisible:sectionRect animated:YES];
        }
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

- (void)setCellImageView:(UIImageView*)imgView dictItem:(NSDictionary*)item url:(NSString*)stringURL size:(CGSize)viewSize defaultImg:(NSString*)displayThumb {
    if ([item[@"family"] isEqualToString:@"channelid"] || [item[@"family"] isEqualToString:@"type"]) {
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
    if (![stringURL isEqualToString:@""]) {
        __auto_type __weak weakImageView = imgView;
        [imgView setImageWithURL:[NSURL URLWithString:stringURL]
                placeholderImage:[UIImage imageNamed:displayThumb]
                         options:0
                       andResize:viewSize
                      withBorder:showBorder
                        progress:nil
                       completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            // Only set the logo background, if the attempt to load it was successful (image != nil).
            // This avoids a possibly wrong background for a default thumb.
            if (image && (channelListView || channelGuideView || recordingListView || isOnPVR)) {
                [Utilities setLogoBackgroundColor:weakImageView mode:logoBackgroundMode];
            }
        }];
    }
    else {
        [imgView setImageWithURL:[NSURL URLWithString:@""]
                placeholderImage:[UIImage imageNamed:displayThumb]
                         options:0
                       andResize:CGSizeZero
                      withBorder:showBorder
                        progress:nil
                       completed:nil];
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
//    if ([sender tag] == choosedTab) {
//        return;
//    }
    button6.hidden = YES;
    button7.hidden = YES;
    [self alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
    [activityIndicatorView startAnimating];
    NSArray *buttonsIB = @[button1, button2, button3, button4, button5];
    if (choosedTab < buttonsIB.count) {
        [buttonsIB[choosedTab] setSelected:NO];
    }
    choosedTab = MAX_NORMAL_BUTTONS;
    [buttonsIB[choosedTab] setSelected:YES];
    [self AnimTable:(UITableView*)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:viewWidth];
    int i;
    NSInteger count = [self.detailItem mainParameters].count;
    NSMutableArray *mainMenu = [NSMutableArray new];
    NSInteger numIcons = [self.detailItem mainButtons].count;
    for (i = MAX_NORMAL_BUTTONS; i < count; i++) {
        NSString *icon = @"";
        if (i < numIcons) {
            icon = [self.detailItem mainButtons][i];
        }
        [mainMenu addObject: 
         [NSDictionary dictionaryWithObjectsAndKeys:
          [NSString stringWithFormat:@"%@", [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][i]][@"morelabel"]], @"label",
          icon, @"icon",
          nil]];
    }
    if (moreItemsViewController == nil) {
        moreItemsViewController = [[MoreItemsViewController alloc] initWithFrame:CGRectMake(dataList.bounds.size.width, 0, dataList.bounds.size.width, dataList.bounds.size.height) mainMenu:mainMenu];
        moreItemsViewController.view.backgroundColor = UIColor.clearColor;
        [moreItemsViewController viewWillAppear:NO];
        [moreItemsViewController viewDidAppear:NO];
        UIEdgeInsets tableViewInsets = UIEdgeInsetsZero;
        tableViewInsets.bottom = 44;
        moreItemsViewController.tableView.contentInset = tableViewInsets;
        moreItemsViewController.tableView.scrollIndicatorInsets = tableViewInsets;
        [moreItemsViewController.tableView setContentOffset:CGPointMake(0, - tableViewInsets.top) animated:NO];
        [detailView insertSubview:moreItemsViewController.view aboveSubview:dataList];
    }

    [self AnimView:moreItemsViewController.view AnimDuration:0.3 Alpha:1.0 XPos:0];
    NSString *labelText = [NSString stringWithFormat:LOCALIZED_STR(@"More (%d)"), (int)(count - MAX_NORMAL_BUTTONS)];
    [self setFilternameLabel:labelText runFullscreenButtonCheck:YES forceHide:YES];
    [activityIndicatorView stopAnimating];
}


- (void)handleTabHasChanged:(NSNotification*)notification {
    NSArray *buttons = [self.detailItem mainButtons];
    if (!buttons.count) {
        return;
    }
    NSIndexPath *choice = notification.object;
    choosedTab = 0;
    NSInteger selectedIdx = MAX_NORMAL_BUTTONS + choice.row;
    selectedMoreTab.tag = selectedIdx;
    [self changeTab:selectedMoreTab];
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
    self.richResults = [storeRichResults mutableCopy];
    NSInteger total = self.richResults.count;
    NSMutableIndexSet *mutableIndexSet = [NSMutableIndexSet new];
    if (!albumView) {
        switch (newViewMode) {
            case ViewModeNotListened:
            case ViewModeUnwatched:
                for (int i = 0; i < total; i++) {
                    if ([self.richResults[i][@"playcount"] intValue] > 0) {
                        [mutableIndexSet addIndex:i];
                    }
                }
                [self.richResults removeObjectsAtIndexes:mutableIndexSet];
                break;

            case ViewModeListened:
            case ViewModeWatched:
                for (int i = 0; i < total; i++) {
                    if ([self.richResults[i][@"playcount"] intValue] == 0) {
                        [mutableIndexSet addIndex:i];
                    }
                }
                [self.richResults removeObjectsAtIndexes:mutableIndexSet];
                break;
                
            case ViewModeDefaultArtists:
            case ViewModeAlbumArtists:
            case ViewModeSongArtists:
            case ViewModeDefault:
                break;
                
            default:
                NSAssert(NO, @"changeViewMode: unknown mode %d", newViewMode);
                break;
        }
    }
    [self indexAndDisplayData];
    
}

- (void)configureLibraryView {
    NSString *imgName = nil;
    if (enableCollectionView) {
        [self initCollectionView];
        if (longPressGesture == nil) {
            longPressGesture = [UILongPressGestureRecognizer new];
            [longPressGesture addTarget:self action:@selector(handleLongPress)];
        }
        [collectionView addGestureRecognizer:longPressGesture];
        dataList.delegate = nil;
        dataList.dataSource = nil;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        dataList.scrollsToTop = NO;
        collectionView.scrollsToTop = YES;
        activeLayoutView = collectionView;
        [self initCollectionIndexView];
        // Need to remove the searchController from the dataList header view. Otherwise the search
        // will not correctly show on top of the grid view.
        dataList.tableHeaderView = nil;
        
        self.searchController.searchBar.backgroundColor = [Utilities getGrayColor:22 alpha:1];
        self.searchController.searchBar.tintColor = UIColor.lightGrayColor;
        imgName = @"st_view_grid";
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
        
        self.searchController.searchBar.backgroundColor = [Utilities getSystemGray6];
        self.searchController.searchBar.tintColor = [Utilities get2ndLabelColor];
        imgName = @"st_view_list";
    }
    [self setCollectionViewIndexVisibility];
    
    UIImage *image = [Utilities colorizeImage:[UIImage imageNamed:imgName] withColor:UIColor.lightGrayColor];
    [button6 setBackgroundImage:image forState:UIControlStateNormal];
    
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
    if (!activityIndicatorView.hidden) {
        return;
    }
    [activeLayoutView setUserInteractionEnabled:YES];
    [((UITableView*)activeLayoutView).pullToRefreshView stopAnimating];
    
    NSDictionary *methods = nil;
    NSDictionary *parameters = nil;
    NSMutableDictionary *mutableParameters = nil;
    NSMutableArray *mutableProperties = nil;
    BOOL refresh = NO;
    
    // Read new tab index
    numTabs = (int)[[self.detailItem mainMethod] count];
    int newChoosedTab = (int)[sender tag];
    newChoosedTab = newChoosedTab % numTabs;
    
    // Handle modes (pressing same tab) or changed tabs
    if (newChoosedTab == choosedTab) {
        // Read relevant data from configuration
        methods = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainMethod][choosedTab]];
        parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
        mutableParameters = [parameters[@"parameters"] mutableCopy];
        mutableProperties = [parameters[@"parameters"][@"properties"] mutableCopy];
        
        NSInteger num_modes = [[self.detailItem filterModes][choosedTab][@"modes"] count];
        if (!num_modes) {
            return;
        }
        filterModeIndex = (filterModeIndex + 1) % num_modes;
        NSArray *buttonsIB = @[button1, button2, button3, button4, button5];
        [buttonsIB[choosedTab] setImage:[UIImage imageNamed:[self.detailItem filterModes][choosedTab][@"icons"][filterModeIndex]] forState:UIControlStateSelected];
        
        // Artist filter is active. We change the API call parameters and continue.
        filterModeType = [[self.detailItem filterModes][choosedTab][@"modes"][filterModeIndex] intValue];
        if (filterModeType == ViewModeAlbumArtists ||
            filterModeType == ViewModeSongArtists ||
            filterModeType == ViewModeDefaultArtists) {
            if (AppDelegate.instance.APImajorVersion >= 4) {
                switch (filterModeType) {
                    case ViewModeAlbumArtists:
                        mutableParameters[@"albumartistsonly"] = @YES;
                        refresh = YES;
                        break;
                        
                    case ViewModeSongArtists:
                        mutableParameters[@"albumartistsonly"] = @NO;
                        refresh = YES;
                        break;
                        
                    case ViewModeDefaultArtists:
                        [mutableParameters removeObjectForKey:@"albumartistsonly"];
                        break;
                        
                    default:
                        NSAssert(NO, @"changeTab: unexpected mode %d", filterModeType);
                        break;
                }
            }
        }
        // Some other filter is active. We simply filter results via helper function changeViewMode and return.
        else {
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
        methods = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainMethod][choosedTab]];
        parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
        mutableParameters = [parameters[@"parameters"] mutableCopy];
        mutableProperties = [parameters[@"parameters"][@"properties"] mutableCopy];
    }
    self.indexView.indexTitles = nil;
    self.indexView.hidden = YES;
    startTime = 0;
    [countExecutionTime invalidate];
    countExecutionTime = nil;
    if (longTimeout != nil) {
        [longTimeout removeFromSuperview];
        longTimeout = nil;
    }
    [self AnimView:moreItemsViewController.view AnimDuration:0.3 Alpha:1.0 XPos:viewWidth];
    
    [activityIndicatorView startAnimating];

    if ([parameters[@"numberOfStars"] intValue] > 0) {
        numberOfStars = [parameters[@"numberOfStars"] intValue];
    }

    BOOL newEnableCollectionView = [self collectionViewIsEnabled];
    [self setButtonViewContent];
    [self checkDiskCache];
    NSTimeInterval animDuration = 0.3;
    if (newEnableCollectionView != enableCollectionView) {
        animDuration = 0.0;
    }
    [self AnimTable:(UITableView*)activeLayoutView AnimDuration:animDuration Alpha:1.0 XPos:viewWidth];
    enableCollectionView = newEnableCollectionView;
    recentlyAddedView = [parameters[@"collectionViewRecentlyAdded"] boolValue];
    [activeLayoutView setContentOffset:[(UITableView*)activeLayoutView contentOffset] animated:NO];
    NSString *labelText = parameters[@"label"];
    [self setFilternameLabel:labelText runFullscreenButtonCheck:YES forceHide:NO];
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
    if ([parameters[@"blackTableSeparator"] boolValue] && !AppDelegate.instance.obj.preferTVPosters) {
        blackTableSeparator = YES;
        dataList.separatorColor = [Utilities getGrayColor:38 alpha:1];
    }
    else {
        blackTableSeparator = NO;
        self.searchController.searchBar.tintColor = [Utilities get2ndLabelColor];
        dataList.separatorColor = [Utilities getGrayColor:191 alpha:1];
    }
    if ([parameters[@"itemSizes"][@"separatorInset"] length]) {
        dataList.separatorInset = UIEdgeInsetsMake(0, [parameters[@"itemSizes"][@"separatorInset"] intValue], 0, 0);
    }
    if (methods[@"method"] != nil) {
        [self retrieveData:methods[@"method"] parameters:mutableParameters sectionMethod:methods[@"extra_section_method"] sectionParameters:parameters[@"extra_section_parameters"] resultStore:self.richResults extraSectionCall:NO refresh:refresh];
    }
    else {
        [activityIndicatorView stopAnimating];
        [self AnimTable:(UITableView*)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
}

#pragma mark - Library item didSelect

- (void)viewChild:(NSIndexPath*)indexPath item:(NSDictionary*)item displayPoint:(CGPoint) point {
    selected = indexPath;
    mainMenu *MenuItem = self.detailItem;
    NSMutableArray *sheetActions = [self.detailItem sheetActions][choosedTab];
    NSMutableDictionary *parameters = [Utilities indexKeyedMutableDictionaryFromArray:[MenuItem.subItem mainParameters][choosedTab]];
    int rectOriginX = point.x;
    int rectOriginY = point.y;
    NSDictionary *mainFields = [MenuItem mainFields][choosedTab];
    
    NSString *libraryRowHeight = [NSString stringWithFormat:@"%d", MenuItem.subItem.rowHeight];
    NSString *libraryThumbWidth = [NSString stringWithFormat:@"%d", MenuItem.subItem.thumbWidth];
    if (parameters[@"rowHeight"] != nil) {
        libraryRowHeight = parameters[@"rowHeight"];
    }
    if (parameters[@"thumbWidth"] != nil) {
        libraryThumbWidth = parameters[@"thumbWidth"];
    }
    
    if (parameters[@"parameters"][@"properties"] != nil) { // CHILD IS LIBRARY MODE
        NSString *key = @"null";
        if (item[mainFields[@"row15"]] != nil) {
            key = mainFields[@"row15"];
        }
        id obj = item[mainFields[@"row6"]];
        id objKey = mainFields[@"row6"];
        if (AppDelegate.instance.serverVersion > 11 && ![parameters[@"disableFilterParameter"] boolValue]) {
            NSDictionary *currentParams = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
            obj = [NSDictionary dictionaryWithObjectsAndKeys:
                   item[mainFields[@"row6"]], mainFields[@"row6"],
                   currentParams[@"parameters"][@"filter"][parameters[@"combinedFilter"]], parameters[@"combinedFilter"],
                   nil];
            objKey = @"filter";
        }
        if (parameters[@"disableFilterParameter"] == nil) {
            parameters[@"disableFilterParameter"] = @"NO";
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
                                       parameters[@"disableFilterParameter"], @"disableFilterParameter",
                                       libraryRowHeight, @"rowHeight", libraryThumbWidth, @"thumbWidth",
                                       parameters[@"label"], @"label",
                                       [NSDictionary dictionaryWithDictionary:parameters[@"itemSizes"]], @"itemSizes",
                                       [NSString stringWithFormat:@"%d", [parameters[@"FrodoExtraArt"] boolValue]], @"FrodoExtraArt",
                                       [NSString stringWithFormat:@"%d", [parameters[@"enableLibraryCache"] boolValue]], @"enableLibraryCache",
                                       [NSString stringWithFormat:@"%d", [parameters[@"enableCollectionView"] boolValue]], @"enableCollectionView",
                                        [NSString stringWithFormat:@"%d", [parameters[@"forceActionSheet"] boolValue]], @"forceActionSheet",
                                       [NSString stringWithFormat:@"%d", [parameters[@"collectionViewRecentlyAdded"] boolValue]], @"collectionViewRecentlyAdded",
                                       [NSString stringWithFormat:@"%d", [parameters[@"blackTableSeparator"] boolValue]], @"blackTableSeparator",
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
        MenuItem.subItem.mainLabel = item[@"label"];
        mainMenu *newMenuItem = [MenuItem.subItem copy];
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
        NSString *filemodeRowHeight = @"44";
        NSString *filemodeThumbWidth = @"44";
        if (parameters[@"rowHeight"] != nil) {
            filemodeRowHeight = parameters[@"rowHeight"];
        }
        if (parameters[@"thumbWidth"] != nil) {
            filemodeThumbWidth = parameters[@"thumbWidth"];
        }
        if ([item[@"filetype"] length] != 0) { // WE ARE ALREADY IN BROWSING FILES MODE
            if ([item[@"filetype"] isEqualToString:@"directory"]) {
                [parameters removeAllObjects];
                parameters = [Utilities indexKeyedMutableDictionaryFromArray:[MenuItem mainParameters][choosedTab]];
                NSMutableArray *newParameters = [NSMutableArray arrayWithObjects:
                                               [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                item[mainFields[@"row6"]], @"directory",
                                                parameters[@"parameters"][@"media"], @"media",
                                                parameters[@"parameters"][@"sort"], @"sort",
                                                parameters[@"parameters"][@"file_properties"], @"file_properties",
                                                nil], @"parameters", parameters[@"label"], @"label", @"nocover_filemode", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeThumbWidth, @"thumbWidth", @"icon_song", @"fileThumb",
                                               [NSDictionary dictionaryWithDictionary:parameters[@"itemSizes"]], @"itemSizes",
                                               [NSString stringWithFormat:@"%d", [parameters[@"enableCollectionView"] boolValue]], @"enableCollectionView",
                                               parameters[@"disableFilterParameter"], @"disableFilterParameter",
                                               nil];
                MenuItem.mainLabel = item[@"label"];
                mainMenu *newMenuItem = [MenuItem copy];
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
            else if ([item[@"genre"] isEqualToString:@"file"] || [item[@"filetype"] isEqualToString:@"file"]) {
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                if (![[userDefaults objectForKey:@"song_preference"] boolValue]) {
                    [self showActionSheet:indexPath sheetActions:sheetActions item:item rectOriginX:rectOriginX rectOriginY:rectOriginY];
                }
                else {
                    [self addPlayback:item indexPath:indexPath position:(int)indexPath.row shuffle:NO];
                }
                return;
            }
            else
                return;
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
                            [MenuItem mainParameters][choosedTab][0][@"section"], @"section",
                            nil];
            }
            NSMutableArray *newParameters = [NSMutableArray arrayWithObjects:
                                           [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            objValue, fileModeKey,
                                            parameters[@"parameters"][@"media"], @"media",
                                            parameters[@"parameters"][@"sort"], @"sort",
                                            parameters[@"parameters"][@"file_properties"], @"file_properties",
                                            nil], @"parameters", parameters[@"label"], @"label", @"nocover_filemode", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeThumbWidth, @"thumbWidth",
                                           [NSDictionary dictionaryWithDictionary:parameters[@"itemSizes"]], @"itemSizes",
                                           [NSString stringWithFormat:@"%d", [parameters[@"enableCollectionView"] boolValue]], @"enableCollectionView",
                                           parameters[@"disableFilterParameter"], @"disableFilterParameter",
                                           nil];
            if ([item[@"family"] isEqualToString:@"sectionid"] || [item[@"family"] isEqualToString:@"categoryid"]) {
                newParameters[0][@"level"] = @"expert";
            }
            MenuItem.subItem.mainLabel = item[@"label"];
            mainMenu *newMenuItem = [MenuItem.subItem copy];
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

- (void)didSelectItemAtIndexPath:(NSIndexPath*)indexPath item:(NSDictionary*)item displayPoint:(CGPoint) point {
    mainMenu *MenuItem = self.detailItem;
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[MenuItem.subItem mainMethod][choosedTab]];
    NSMutableArray *sheetActions = [[self.detailItem sheetActions][choosedTab] mutableCopy];
    NSMutableDictionary *parameters = [Utilities indexKeyedMutableDictionaryFromArray:[MenuItem.subItem mainParameters][choosedTab]];
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
            [self SimpleAction: @"GUI.ActivateWindow"
                        params: @{@"window": item[@"window"], @"parameters": @[item[@"windowparameter"]]}
                       success: LOCALIZED_STR(@"Window activated successfully")
                       failure: LOCALIZED_STR(@"Unable to activate the window")
             ];
        }
        // Selected favourite item is a media type -> play it
        else if ([item[@"type"] isEqualToString:@"media"]) {
            [self playerOpen: @{@"item": @{@"file": item[@"path"] }} index:nil];
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
        if ([MenuItem.showInfo[choosedTab] boolValue]) {
            [self showInfo:indexPath menuItem:self.detailItem item:item tabToShow:choosedTab];
        }
        else {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            if (![[userDefaults objectForKey:@"song_preference"] boolValue] || [parameters[@"forceActionSheet"] boolValue]) {
                sheetActions = [self getPlaylistActions:sheetActions item:item params:[Utilities indexKeyedMutableDictionaryFromArray:[MenuItem mainParameters][choosedTab]]];
                selected = indexPath;
                [self showActionSheet:indexPath sheetActions:sheetActions item:item rectOriginX:rectOriginX rectOriginY:rectOriginY];
            }
            else {
                [self addPlayback:item indexPath:indexPath position:(int)indexPath.row shuffle:NO];
            }
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
        flowLayout.itemSize = CGSizeMake(fullscreenCellGridWidth, fullscreenCellGridHeight);
        if (!recentlyAddedView) {
            flowLayout.minimumLineSpacing = 38;
        }
        else {
            flowLayout.minimumLineSpacing = 4;
        }
        flowLayout.minimumInteritemSpacing = cellMinimumLineSpacing;
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
        collectionView.delegate = self;
        collectionView.dataSource = self;
        [collectionView registerClass:[PosterCell class] forCellWithReuseIdentifier:@"posterCell"];
        [collectionView registerClass:[RecentlyAddedCell class] forCellWithReuseIdentifier:@"recentlyAddedCell"];
        [collectionView registerClass:[PosterHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"posterHeaderView"];
        collectionView.autoresizingMask = dataList.autoresizingMask;
        __weak DetailViewController *weakSelf = self;
        [collectionView addPullToRefreshWithActionHandler:^{
            [weakSelf startRetrieveDataWithRefresh:YES];
        }];
        [collectionView setShowsPullToRefresh:enableDiskCache];
        collectionView.alwaysBounceVertical = YES;
        [detailView insertSubview:collectionView belowSubview:buttonsView];
    }
    activeLayoutView = collectionView;
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
        return ([self.sectionArrayOpen[section] boolValue] ? [[self.sections objectForKey:self.sectionArray[section]] count] : 0);
    }
    return [[self.sections objectForKey:self.sectionArray[section]] count];
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
        cell.posterThumbnail.contentMode = UIViewContentModeScaleAspectFit;
        if (stackscrollFullscreen) {
            cell.posterLabelFullscreen.text = item[@"label"];
            cell.labelImageView.hidden = YES;
            cell.posterLabelFullscreen.hidden = NO;
        }
        else {
            cell.posterLabel.text = item[@"label"];
            cell.posterLabelFullscreen.hidden = YES;
        }
        
        defaultThumb = displayThumb = [self getTimerDefaultThumb:item];
        
        if ([item[@"filetype"] length] != 0 || [item[@"family"] isEqualToString:@"file"] || [item[@"family"] isEqualToString:@"genreid"]) {
            if (![stringURL isEqualToString:@""]) {
                displayThumb = stringURL;
            }
        }
        else if (channelListView) {
            [cell setIsRecording:[item[@"isrecording"] boolValue]];
        }
        cell.posterThumbnail.frame = cell.bounds;
        [self setCellImageView:cell.posterThumbnail dictItem:item url:stringURL size:CGSizeMake(cellthumbWidth, cellthumbHeight) defaultImg:displayThumb];
        if ([stringURL isEqualToString:@""]) {
            cell.posterThumbnail.backgroundColor = [Utilities getGrayColor:28 alpha:1.0];
        }
        // Set label visibility based on setting and current view
        if (hiddenLabel || stackscrollFullscreen) {
            cell.posterLabel.hidden = YES;
            cell.labelImageView.hidden = YES;
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
        CGFloat posterWidth = cellthumbHeight * 0.66;
        CGFloat fanartWidth = cellthumbWidth - posterWidth;

        if (![stringURL isEqualToString:@""]) {
            [cell.posterThumbnail setImageWithURL:[NSURL URLWithString:stringURL]
                                 placeholderImage:[UIImage imageNamed:displayThumb]
                                        andResize:CGSizeMake(posterWidth, cellthumbHeight)
                                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                UIColor *averageColor = [Utilities averageColor:image inverse:NO];
                CGFloat hue, saturation, brightness, alpha;
                BOOL ok = [averageColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
                if (ok) {
                    UIColor *bgColor = [UIColor colorWithHue:hue saturation:saturation brightness:0.2 alpha:alpha];
                    cell.backgroundColor = bgColor;
                }
            }];
        }
        else {
            [cell.posterThumbnail setImageWithURL:[NSURL URLWithString:@""]
                                 placeholderImage:[UIImage imageNamed:displayThumb]];
        }

        if (![fanartURL isEqualToString:@""]) {
            [cell.posterFanart setImageWithURL:[NSURL URLWithString:fanartURL]
                              placeholderImage:[UIImage imageNamed:@"blank"]
                                     andResize:CGSizeMake(fanartWidth, cellthumbHeight)];
        }
        else {
            [cell.posterFanart setImageWithURL:[NSURL URLWithString:@""]
                              placeholderImage:[UIImage imageNamed:@"blank"]];
        }
        
        cell.posterLabel.font = [UIFont boldSystemFontOfSize:fanartFontSize + 8];
        cell.posterLabel.text = item[@"label"];
        
        cell.posterGenre.font = [UIFont systemFontOfSize:fanartFontSize + 2];
        cell.posterGenre.text = item[@"genre"];
        
        cell.posterYear.font = [UIFont systemFontOfSize:fanartFontSize];
//        cell.posterYear.text = [NSString stringWithFormat:@"%@%@", item[@"year"], item[@"runtime"] == nil ? @"" : [NSString stringWithFormat:@" - %@", item[@"runtime"]]];
        cell.posterYear.text = item[@"year"];
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
    int rectOriginX = cell.frame.origin.x + (cell.frame.size.width/2);
    int rectOriginY = cell.frame.origin.y + cell.frame.size.height/2 - offsetPoint.y;
    [self didSelectItemAtIndexPath:indexPath item:item displayPoint:CGPointMake(rectOriginX, rectOriginY)];
}

#pragma mark - BDKCollectionIndexView init

- (void)initSectionNameOverlayView {
    sectionNameOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width / 2, self.view.frame.size.width / 6)];
    sectionNameOverlayView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin);
    sectionNameOverlayView.backgroundColor = [Utilities getGrayColor:0 alpha:1.0];
    sectionNameOverlayView.center = UIApplication.sharedApplication.delegate.window.rootViewController.view.center;
    CGFloat cornerRadius = 12;
    sectionNameOverlayView.layer.cornerRadius = cornerRadius;
    
    int fontSize = 32;
    sectionNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, sectionNameOverlayView.frame.size.height/2 - (fontSize + 8)/2, sectionNameOverlayView.frame.size.width, (fontSize + 8))];
    sectionNameLabel.font = [UIFont boldSystemFontOfSize:fontSize];
    sectionNameLabel.textColor = UIColor.whiteColor;
    sectionNameLabel.backgroundColor = UIColor.clearColor;
    sectionNameLabel.textAlignment = NSTextAlignmentCenter;
    [sectionNameOverlayView addSubview:sectionNameLabel];
    [self.view addSubview:sectionNameOverlayView];
}

- (void)initCollectionIndexView {
    if (self.indexView) {
        return;
    }
    CGFloat indexWidth = 40;
    CGRect frame = CGRectMake(CGRectGetWidth(collectionView.frame) - indexWidth,
                              CGRectGetMinY(collectionView.frame) + collectionView.contentInset.top,
                              indexWidth,
                              CGRectGetHeight(collectionView.frame) - collectionView.contentInset.top - collectionView.contentInset.bottom - bottomPadding);
    self.indexView = [BDKCollectionIndexView indexViewWithFrame:frame indexTitles:@[]];
    self.indexView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin);
    self.indexView.alpha = 1.0;
    self.indexView.hidden = YES;
    [self.indexView addTarget:self action:@selector(indexViewValueChanged:) forControlEvents:UIControlEventValueChanged];
    [detailView addSubview:self.indexView];
}

- (void)indexViewValueChanged:(BDKCollectionIndexView*)sender {
    if (sender.currentIndex == 0) {
        [collectionView setContentOffset:CGPointZero animated:NO];
        if (sectionNameOverlayView == nil && stackscrollFullscreen) {
            [self initSectionNameOverlayView];
        }
        sectionNameLabel.text = [NSString stringWithFormat:@"%C%C", 0xD83D, 0xDD0D];
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
    else {
        NSIndexPath *path = [NSIndexPath indexPathForItem:0 inSection:sender.currentIndex];
        [collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        collectionView.contentOffset = CGPointMake(collectionView.contentOffset.x, collectionView.contentOffset.y - GRID_SECTION_HEADER_HEIGHT + 4);
    }
}

- (void)handleCollectionIndexStateBegin {
    if (stackscrollFullscreen) {
        [self alphaView:sectionNameOverlayView AnimDuration:0.1 Alpha:1];
    }
}

- (void)handleCollectionIndexStateEnded {
    if (stackscrollFullscreen) {
        [self alphaView:sectionNameOverlayView AnimDuration:0.3 Alpha:0];
    }
    _indexView.alpha = 1.0;
}

#pragma mark - Table Animation

- (void)alphaImage:(UIImageView*)image AnimDuration:(NSTimeInterval)seconds Alpha:(CGFloat)alphavalue {
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	image.alpha = alphavalue;
    [UIView commitAnimations];
}

- (void)alphaView:(UIView*)view AnimDuration:(NSTimeInterval)seconds Alpha:(CGFloat)alphavalue {
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	view.alpha = alphavalue;
    [UIView commitAnimations];
}

- (void)AnimTable:(UITableView*)tV AnimDuration:(NSTimeInterval)seconds Alpha:(CGFloat)alphavalue XPos:(int)X {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:seconds];
    tV.alpha = alphavalue;
    CGRect frame;
    frame = tV.frame;
    frame.origin.x = X;
    frame.origin.y = 0;
    tV.frame = frame;
    [UIView commitAnimations];
}

- (void)AnimView:(UIView*)view AnimDuration:(NSTimeInterval)seconds Alpha:(CGFloat)alphavalue XPos:(int)X {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	view.alpha = alphavalue;
	CGRect frame;
	frame = view.frame;
	frame.origin.x = X;
	view.frame = frame;
    [UIView commitAnimations];
}

#pragma mark - Cell Formatting 

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

int originYear = 0;
- (void)choseParams { // DA OTTIMIZZARE TROPPI IF!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    flagX = 43;
    flagY = 54;
    mainMenu *Menuitem = self.detailItem;
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
    if ([parameters[@"defaultThumb"] length] != 0 && ![parameters[@"defaultThumb"] isEqualToString:@"(null)"]) {
        defaultThumb = parameters[@"defaultThumb"];
    }
    else {
        defaultThumb = [self.detailItem defaultThumb];
    }
    if (parameters[@"rowHeight"] != 0)
        cellHeight = [parameters[@"rowHeight"] intValue];
    else if (Menuitem.rowHeight != 0) {
        cellHeight = Menuitem.rowHeight;
    }
    else {
        cellHeight = 76;
    }

    if (parameters[@"thumbWidth"] != 0)
        thumbWidth = [parameters[@"thumbWidth"] intValue];
    else if (Menuitem.thumbWidth != 0) {
        thumbWidth = Menuitem.thumbWidth;
    }
    else {
        thumbWidth = 53;
    }
    if (albumView) {
        thumbWidth = 0;
        labelPosition = thumbWidth + albumViewPadding + trackCountLabelWidth;
        dataList.separatorInset = UIEdgeInsetsMake(0, 8, 0, 0);
    }
    else if (episodesView) {
        thumbWidth = 0;
        labelPosition = 18;
    }
    else if (channelGuideView) {
        thumbWidth = 0;
        labelPosition = epgChannelTimeLabelWidth;
    }
    else {
        labelPosition = thumbWidth + 8;
    }
    int newWidthLabel = 0;
    if (Menuitem.originLabel && !parameters[@"thumbWidth"]) {
        labelPosition = Menuitem.originLabel;
    }
    // CHECK IF THERE ARE SECTIONS
    
    int iOS7offset = 0;
    int iOS7insetSeparator = 0;
    if (IS_IPHONE) {
        iOS7offset = 12;
        iOS7insetSeparator = 20;
    }
    else {
        iOS7offset = 4;
        iOS7insetSeparator = 30;
    }
    if (episodesView || (self.sectionArray.count == 1 && !channelGuideView)) {
        //(self.richResults.count <= SECTIONS_START_AT || ![self.detailItem enableSection])
        newWidthLabel = viewWidth - 8 - labelPosition;
        Menuitem.originYearDuration = viewWidth - 72;
        UIEdgeInsets dataListSeparatorInset = [dataList separatorInset];
        dataListSeparatorInset.right = 0;
        dataList.separatorInset = dataListSeparatorInset;
    }
    else {
        int extraPadding = 0;
        if ([sortMethodName isEqualToString:@"year"] || [sortMethodName isEqualToString:@"dateadded"]) {
            extraPadding = 18;
        }
        else if ([sortMethodName isEqualToString:@"runtime"]) {
            extraPadding = 12;
        }
        if (iOS7offset > 0) {
            UIEdgeInsets dataListSeparatorInset = [dataList separatorInset];
            dataListSeparatorInset.right = iOS7insetSeparator + extraPadding;
            dataList.separatorInset = dataListSeparatorInset;
        }
        if (channelGuideView) {
            iOS7offset += 6;
        }
        
        newWidthLabel = viewWidth - 38 - labelPosition + iOS7offset - extraPadding;
        Menuitem.originYearDuration = viewWidth - 100 + iOS7offset - extraPadding;
    }
    Menuitem.widthLabel = newWidthLabel;
    flagX = thumbWidth - 10;
    flagY = cellHeight - 19;
    if (flagX + 22 > self.view.bounds.size.width) {
        flagX = 2;
        flagY = 2;
    }
    if (thumbWidth == 0) {
        flagX = 6;
        flagY = 4;
    }
}

#pragma mark - Table Management

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
        return [[self.sections objectForKey:self.sectionArray[section]] count];
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
    if ([self doesShowSearchResults]) {
        return nil;
    }
    else {
        if (self.sectionArray.count > 1 && !episodesView && !channelGuideView) {
            return self.sectionArray;
        }
        else if (channelGuideView) {
            if (self.sectionArray.count > 0) {
                NSMutableArray *channelGuideTableIndexTitles = [NSMutableArray new];
                for (NSString *label in self.sectionArray) {
                        NSString *dateString = label;
                        NSDateFormatter *format = [NSDateFormatter new];
                        format.locale = [NSLocale currentLocale];
                        format.dateFormat = @"yyyy-MM-dd";
                        NSDate *date = [format dateFromString:label];
                        format.dateFormat = @"EEE";
                    if ([format stringFromDate:date] != nil) {
                        dateString = [format stringFromDate:date];
                    }
                    [channelGuideTableIndexTitles addObject:dateString];
                }
                return channelGuideTableIndexTitles;
            }
            return self.sectionArray;
        }
        else {
            return nil;
        }
    }
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    if (tvshowsView && choosedTab == 0) {
        // Gray:28 is similar to systemGray6 in Dark Mode
        cell.backgroundColor = [Utilities getGrayColor:28 alpha:1.0];
    }
    else {
        cell.backgroundColor = [Utilities getSystemGray6];
    }
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    jsonDataCell *cell = [tableView dequeueReusableCellWithIdentifier:@"jsonDataCellIdentifier"];
    NSDictionary *item = [self getItemFromIndexPath:indexPath];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"jsonDataCell" owner:self options:nil];
        cell = nib[0];
        if (albumView) {
            UILabel *trackNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(albumViewPadding, cellHeight / 2 - (artistFontSize + labelPadding) / 2, trackCountLabelWidth - 2, artistFontSize + labelPadding)];
            trackNumberLabel.backgroundColor = UIColor.clearColor;
            trackNumberLabel.font = [UIFont systemFontOfSize:artistFontSize];
            trackNumberLabel.adjustsFontSizeToFitWidth = YES;
            trackNumberLabel.minimumScaleFactor = (artistFontSize - 4) / artistFontSize;
            trackNumberLabel.tag = 101;
            trackNumberLabel.highlightedTextColor = UIColor.whiteColor;
            [cell.contentView addSubview:trackNumberLabel];
        }
        else if (channelGuideView) {
            UILabel *programTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 8, epgChannelTimeLabelWidth - 8, 12 + labelPadding)];
            programTimeLabel.backgroundColor = UIColor.clearColor;
            programTimeLabel.font = [UIFont systemFontOfSize:12];
            programTimeLabel.adjustsFontSizeToFitWidth = YES;
            programTimeLabel.minimumScaleFactor = 8.0 / 12.0;
            programTimeLabel.textAlignment = NSTextAlignmentCenter;
            programTimeLabel.tag = 102;
            programTimeLabel.highlightedTextColor = UIColor.whiteColor;
            [cell.contentView addSubview:programTimeLabel];
            ProgressPieView *progressView = [[ProgressPieView alloc] initWithFrame:CGRectMake(4, programTimeLabel.frame.origin.y + programTimeLabel.frame.size.height + 7, epgChannelTimeLabelWidth - 8, epgChannelTimeLabelWidth - 8)];
            progressView.tag = 103;
            progressView.hidden = YES;
            [cell.contentView addSubview:progressView];
            
            UIImageView *hasTimer = [[UIImageView alloc] initWithFrame:CGRectMake((int)((2 + (epgChannelTimeLabelWidth - 8) - 6) / 2), programTimeLabel.frame.origin.y + programTimeLabel.frame.size.height + 14, 12, 12)];
            hasTimer.image = [UIImage imageNamed:@"button_timer"];
            hasTimer.tag = 104;
            hasTimer.hidden = YES;
            hasTimer.backgroundColor = UIColor.clearColor;
            [cell.contentView addSubview:hasTimer];
        }
        else if (channelListView) {
            CGFloat pieSize = 28;
            ProgressPieView *progressView = [[ProgressPieView alloc] initWithFrame:CGRectMake(viewWidth - pieSize - 2, 10, pieSize, pieSize) color:[Utilities get1stLabelColor]];
            progressView.tag = 103;
            progressView.hidden = YES;
            [cell.contentView addSubview:progressView];
            
            CGFloat dotSize = 6;
            UIImageView *isRecordingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(progressView.frame.origin.x + pieSize/2 - dotSize/2, progressView.frame.origin.y + [progressView getPieRadius]/2 + [progressView getLineWidth] + 0.5, dotSize, dotSize)];
            isRecordingImageView.image = [UIImage imageNamed:@"button_timer"];
            isRecordingImageView.contentMode = UIViewContentModeScaleToFill;
            isRecordingImageView.tag = 104;
            isRecordingImageView.hidden = YES;
            isRecordingImageView.backgroundColor = UIColor.clearColor;
            [cell.contentView addSubview:isRecordingImageView];
        }
        ((UILabel*)[cell viewWithTag:1]).highlightedTextColor = [Utilities get1stLabelColor];
        ((UILabel*)[cell viewWithTag:2]).highlightedTextColor = [Utilities get2ndLabelColor];
        ((UILabel*)[cell viewWithTag:3]).highlightedTextColor = [Utilities get2ndLabelColor];
        ((UILabel*)[cell viewWithTag:4]).highlightedTextColor = [Utilities get2ndLabelColor];
        ((UILabel*)[cell viewWithTag:5]).highlightedTextColor = [Utilities get2ndLabelColor];
        ((UILabel*)[cell viewWithTag:101]).highlightedTextColor = [Utilities get1stLabelColor];
        ((UILabel*)[cell viewWithTag:102]).highlightedTextColor = [Utilities get2ndLabelColor];
        ((UILabel*)[cell viewWithTag:1]).textColor = [Utilities get1stLabelColor];
        ((UILabel*)[cell viewWithTag:2]).textColor = [Utilities get2ndLabelColor];
        ((UILabel*)[cell viewWithTag:3]).textColor = [Utilities get2ndLabelColor];
        ((UILabel*)[cell viewWithTag:4]).textColor = [Utilities get2ndLabelColor];
        ((UILabel*)[cell viewWithTag:5]).textColor = [Utilities get2ndLabelColor];
        ((UILabel*)[cell viewWithTag:101]).textColor = [Utilities get1stLabelColor];
        ((UILabel*)[cell viewWithTag:102]).textColor = [Utilities get2ndLabelColor];
    }
    mainMenu *Menuitem = self.detailItem;
//    NSDictionary *mainFields = [Menuitem mainFields][choosedTab];
/* future - need to be tweaked: doesn't work on file mode. mainLabel need to be resized */
//    NSDictionary *methods = [self indexKeyedDictionaryFromArray:[Menuitem.subItem mainMethod][choosedTab]];
//    if (methods[@"method"] != nil) { // THERE IS A CHILD
//        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//    }
/* end future */
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
    frame.size.width = Menuitem.widthLabel;
    title.frame = frame;
    if (channelListView && item[@"channelnumber"]) {
        title.text = [NSString stringWithFormat:@"%@. %@", item[@"channelnumber"], item[@"label"]];
    }
    else {
        title.text = item[@"label"];
    }

    frame = genre.frame;
    frame.size.width = frame.size.width - (labelPosition - frame.origin.x);
    frame.origin.x = labelPosition;
    genre.frame = frame;
    genre.text = [item[@"genre"] stringByReplacingOccurrencesOfString:@"[CR]" withString:@"\n"];

    frame = runtimeyear.frame;
    frame.origin.x = Menuitem.originYearDuration;
    runtimeyear.frame = frame;

    if ([Menuitem.showRuntime[choosedTab] boolValue]) {
        NSString *duration = @"";
        if (!Menuitem.noConvertTime) {
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
    frame.size.width = frame.size.width - (labelPosition - frame.origin.x);
    frame.origin.x = labelPosition;
    runtime.frame = frame;
    runtime.text = item[@"runtime"];

    frame = rating.frame;
    frame.origin.x = Menuitem.originYearDuration;
    rating.frame = frame;
    rating.text = [NSString stringWithFormat:@"%@", item[@"rating"]];
    cell.urlImageView.contentMode = UIViewContentModeScaleAspectFill;
    genre.hidden = NO;
    runtimeyear.hidden = NO;
    if (!albumView && !episodesView && !channelGuideView) {
        if (channelListView || recordingListView) {
            CGRect frame;
            frame.origin.x = 4;
            frame.origin.y = 10;
            frame.size.width = ceil(thumbWidth * 0.9);
            frame.size.height = ceil(thumbWidth * 0.7);
            cell.urlImageView.frame = frame;
            cell.urlImageView.autoresizingMask = UIViewAutoresizingNone;
        }
        if (channelListView) {
            CGRect frame = genre.frame;
            genre.autoresizingMask = title.autoresizingMask;
            frame.size.width = title.frame.size.width;
            genre.frame = frame;
            genre.textColor = [Utilities get1stLabelColor];
            genre.font = [UIFont boldSystemFontOfSize:genre.font.pointSize];
            frame = runtime.frame;
            frame.size.width = Menuitem.widthLabel;
            runtime.frame = frame;
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
        NSString *stringURL = item[@"thumbnail"];
        NSString *displayThumb = defaultThumb;
        if ([item[@"filetype"] length] != 0 ||
            [item[@"family"] isEqualToString:@"file"] ||
            [item[@"family"] isEqualToString:@"genreid"] ||
            [item[@"family"] isEqualToString:@"channelgroupid"] ||
            [item[@"family"] isEqualToString:@"roleid"]) {
            if (![stringURL isEqualToString:@""]) {
                displayThumb = stringURL;
            }
            genre.hidden = YES;
            runtimeyear.hidden = YES;
            title.frame = CGRectMake(title.frame.origin.x, (int)((cellHeight/2) - (title.frame.size.height/2)), title.frame.size.width, title.frame.size.height);
        }
        else if ([item[@"family"] isEqualToString:@"recordingid"] || [item[@"family"] isEqualToString:@"timerid"]) {
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
            genre.autoresizingMask = title.autoresizingMask;
            CGRect frame = genre.frame;
            frame.size.width = title.frame.size.width;
            frame.size.height = frame.size.height + (cellHeight - (frame.origin.y + frame.size.height)) - 4;
            genre.frame = frame;
            frame = title.frame;
            frame.origin.y = 0;
            title.frame = frame;
            genre.font = [genre.font fontWithSize:11];
            genre.minimumScaleFactor = 10.0 / 11.0;
            [genre sizeToFit];
        }
        else if ([item[@"family"] isEqualToString:@"sectionid"] || [item[@"family"] isEqualToString:@"categoryid"] || [item[@"family"] isEqualToString:@"id"] || [item[@"family"] isEqualToString:@"addonid"]) {
            CGRect frame;
            if ([item[@"family"] isEqualToString:@"id"]) {
                frame = title.frame;
                frame.size.width = frame.size.width - 22;
                title.frame = frame;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            cell.urlImageView.contentMode = UIViewContentModeScaleAspectFit;
            runtimeyear.hidden = YES;
            runtime.hidden = YES;
            rating.hidden = YES;
            genre.autoresizingMask = title.autoresizingMask;
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
            genre.text = [Utilities getStringFromItem:item[@"genre"]];
            runtime.text = [Utilities getStringFromItem:item[@"artist"]];
        }
        else {
            genre.hidden = NO;
            runtimeyear.hidden = NO;
        }
        [self setCellImageView:cell.urlImageView dictItem:item url:stringURL size:CGSizeMake(thumbWidth, cellHeight) defaultImg:displayThumb];
    }
    else if (albumView) {
        UILabel *trackNumber = (UILabel*)[cell viewWithTag:101];
        trackNumber.text = item[@"track"];
    }
    else if (channelGuideView) {
        runtimeyear.hidden = YES;
        runtime.hidden = YES;
        rating.hidden = YES;
        genre.autoresizingMask = title.autoresizingMask;
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
        float total_seconds = [endtime timeIntervalSince1970] - [starttime timeIntervalSince1970];
        float elapsed_seconds = [[NSDate date] timeIntervalSince1970] - [starttime timeIntervalSince1970];
        float percent_elapsed = (elapsed_seconds/total_seconds) * 100.0f;

        if (percent_elapsed >= 0 && percent_elapsed < 100) {
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
    int rectOriginX = cell.frame.origin.x + (cell.frame.size.width/2);
    int rectOriginY = cell.frame.origin.y + cell.frame.size.height/2 - offsetPoint.y;
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
        __block UIColor *albumFontColor = [Utilities getGrayColor:0 alpha:1];
        __block UIColor *albumFontShadowColor = [Utilities getGrayColor:255 alpha:0.3];
        __block UIColor *albumDetailsColor = [Utilities getGrayColor:0 alpha:0.6];

        CGFloat labelwidth = viewWidth - albumViewHeight - albumViewPadding;
        CGFloat bottomMargin = albumViewHeight - albumViewPadding - (trackCountFontSize + (labelPadding / 2) - 1);
        UIView *albumDetailView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, albumViewHeight + 2)];
        UILabel *artist = [[UILabel alloc] initWithFrame:CGRectMake(albumViewHeight, (albumViewPadding / 2) - 1, labelwidth, artistFontSize + labelPadding)];
        UILabel *albumLabel = [[UILabel alloc] initWithFrame:CGRectMake(albumViewHeight, artist.frame.origin.y + artistFontSize + 2, labelwidth, albumFontSize + labelPadding)];
        UILabel *trackCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(albumViewHeight, bottomMargin, labelwidth, trackCountFontSize + labelPadding)];
        UILabel *releasedLabel = [[UILabel alloc] initWithFrame:CGRectMake(albumViewHeight, bottomMargin - trackCountFontSize -labelPadding/2, labelwidth, trackCountFontSize + labelPadding)];
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = albumDetailView.bounds;
        gradient.colors = @[(id)[[Utilities getSystemGray1] CGColor], (id)[[Utilities getSystemGray5] CGColor]];
        [albumDetailView.layer insertSublayer:gradient atIndex:0];
        CGRect toolbarShadowFrame = CGRectMake(0, albumViewHeight + 1, viewWidth, 8);
        UIImageView *toolbarShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
        toolbarShadow.image = [UIImage imageNamed:@"tableUp"];
        toolbarShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbarShadow.opaque = YES;
        toolbarShadow.alpha = 0.3;
        [albumDetailView addSubview:toolbarShadow];
        NSDictionary *item;
        item = self.richResults[0];
        int albumThumbHeight = albumViewHeight - (albumViewPadding * 2);
        UIView *thumbImageContainer = [[UIView alloc] initWithFrame:CGRectMake(albumViewPadding, albumViewPadding, albumThumbHeight, albumThumbHeight)];
        thumbImageContainer.clipsToBounds = NO;
        UIImageView *thumbImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, albumThumbHeight, albumThumbHeight)];
        thumbImageView.userInteractionEnabled = YES;
        thumbImageView.clipsToBounds = YES;
        thumbImageView.contentMode = UIViewContentModeScaleAspectFill;
        
        UITapGestureRecognizer *touchOnAlbumView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAlbumActions:)];
        touchOnAlbumView.numberOfTapsRequired = 1;
        touchOnAlbumView.numberOfTouchesRequired = 1;
        [thumbImageView addGestureRecognizer:touchOnAlbumView];
    
        NSString *stringURL = item[@"thumbnail"];
        NSString *displayThumb = @"coverbox_back";
        if ([item[@"filetype"] length] != 0) {
            displayThumb = stringURL;
        }
        if (![stringURL isEqualToString:@""]) {
            __weak UIImageView *weakThumbView = thumbImageView;
            [thumbImageView setImageWithURL:[NSURL URLWithString:stringURL]
                           placeholderImage:[UIImage imageNamed:displayThumb]
                                  andResize:CGSizeMake(albumThumbHeight, albumThumbHeight)
                                  completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                      if (image != nil) {
                                          weakThumbView.image = [Utilities applyRoundedEdgesImage:image drawBorder:YES];
                                          [self setViewColor:albumDetailView
                                                       image:image
                                                   isTopMost:YES
                                                  lab12color:albumFontColor
                                                label34Color:albumDetailsColor
                                                  fontshadow:albumFontShadowColor
                                                      label1:artist
                                                      label2:albumLabel
                                                      label3:trackCountLabel
                                                      label4:releasedLabel];
                                          
                                          if ([[self.searchController.searchBar subviews][0] isKindOfClass:[UIImageView class]]) {
                                              [[self.searchController.searchBar subviews][0] removeFromSuperview];
                                          }
                                      }
                                  }];
        }
        else {
            [thumbImageView setImageWithURL:[NSURL URLWithString:@""]
                           placeholderImage:[UIImage imageNamed:displayThumb]];
            [self setLabelColor:albumFontColor
                   label34Color:albumDetailsColor
                     fontshadow:albumFontShadowColor
                         label1:artist
                         label2:albumLabel
                         label3:trackCountLabel
                         label4:releasedLabel];
        }
        stringURL = item[@"fanart"];
        if (![stringURL isEqualToString:@""]) {
            UIImageView *fanartBackgroundImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, - self.searchController.searchBar.frame.size.height, viewWidth, albumViewHeight + 2 + self.searchController.searchBar.frame.size.height)];
            fanartBackgroundImage.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
            fanartBackgroundImage.contentMode = UIViewContentModeScaleAspectFill;
            fanartBackgroundImage.alpha = 0.1;
                fanartBackgroundImage.clipsToBounds = YES;
            [fanartBackgroundImage setImageWithURL:[NSURL URLWithString:stringURL]
                                  placeholderImage:[UIImage imageNamed:@"blank"]];
            [albumDetailView addSubview:fanartBackgroundImage];
        }
        [thumbImageContainer addSubview:thumbImageView];
        [albumDetailView addSubview:thumbImageContainer];
        
        artist .backgroundColor = UIColor.clearColor;
        artist.shadowOffset = CGSizeMake(0, 1);
        artist.font = [UIFont systemFontOfSize:artistFontSize];
        artist.adjustsFontSizeToFitWidth = YES;
        artist.minimumScaleFactor = 9.0 / artistFontSize;
        artist.text = item[@"genre"];
        [albumDetailView addSubview:artist];
        
        albumLabel.backgroundColor = UIColor.clearColor;
        albumLabel.shadowOffset = CGSizeMake(0, 1);
        albumLabel.font = [UIFont boldSystemFontOfSize:albumFontSize];
        albumLabel.text = self.navigationItem.title;
        albumLabel.numberOfLines = 0;
        CGSize maximunLabelSize = CGSizeMake(labelwidth, albumViewHeight - (albumViewPadding * 4) - 28);
        
        CGRect expectedLabelRect = [albumLabel.text boundingRectWithSize:maximunLabelSize
                                           options:NSStringDrawingUsesLineFragmentOrigin
                                        attributes:@{NSFontAttributeName:albumLabel.font}
                                           context:nil];
        CGSize expectedLabelSize = expectedLabelRect.size;
        
        CGRect newFrame = albumLabel.frame;
        newFrame.size.height = expectedLabelSize.height + 8;
        albumLabel.frame = newFrame;
        [albumDetailView addSubview:albumLabel];
        
        float totalTime = 0;
        for (int i = 0; i < self.richResults.count; i++) {
            totalTime += [self.richResults[i][@"runtime"] intValue];
        }
        
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        formatter.maximumFractionDigits = 0;
        formatter.roundingMode = NSNumberFormatterRoundHalfEven;
        NSString *numberString = [formatter stringFromNumber:@(totalTime/60)];
        
        trackCountLabel.backgroundColor = UIColor.clearColor;
        trackCountLabel.shadowOffset = CGSizeMake(0, 1);
        trackCountLabel.font = [UIFont systemFontOfSize:trackCountFontSize];
        trackCountLabel.text = [NSString stringWithFormat:@"%lu %@, %@ %@", (unsigned long)self.richResults.count, self.richResults.count > 1 ? LOCALIZED_STR(@"Songs") : LOCALIZED_STR(@"Song"), numberString, totalTime/60 > 1 ? LOCALIZED_STR(@"Mins.") : LOCALIZED_STR(@"Min")];
        [albumDetailView addSubview:trackCountLabel];
        int year = [item[@"year"] intValue];
        releasedLabel.backgroundColor = UIColor.clearColor;
        releasedLabel.shadowOffset = CGSizeMake(0, 1);
        releasedLabel.font = [UIFont systemFontOfSize:trackCountFontSize];
        releasedLabel.text = [NSString stringWithFormat:@"%@", (year > 0) ? [NSString stringWithFormat:LOCALIZED_STR(@"Released %d"), year] : @""];
        [albumDetailView addSubview:releasedLabel];
        
        UIButton *albumInfoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
        albumInfoButton.alpha = 0.8;
        albumInfoButton.showsTouchWhenHighlighted = YES;
        albumInfoButton.frame = CGRectMake(viewWidth - albumInfoButton.frame.size.width - albumViewPadding, bottomMargin - 3, albumInfoButton.frame.size.width, albumInfoButton.frame.size.height);
        albumInfoButton.tag = 0;
        [albumInfoButton addTarget:self action:@selector(prepareShowAlbumInfo:) forControlEvents:UIControlEventTouchUpInside];
        [albumDetailView addSubview:albumInfoButton];
        albumInfoButton.hidden = [self isModal];
        
//        UIButton *albumPlaybackButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        albumPlaybackButton.tag = 0;
//        albumPlaybackButton.showsTouchWhenHighlighted = YES;
//        UIImage *btnImage = [UIImage imageNamed:@"button_play"];
//        albumPlaybackButton.image = btnImage forState:UIControlStateNormal;
//        albumPlaybackButton.alpha = 0.8;
//        int playbackOriginX = [[formatter stringFromNumber:@(albumThumbHeight/2 - btnImage.size.width/2 + albumViewPadding)] intValue];
//        int playbackOriginY = [[formatter stringFromNumber:@(albumThumbHeight/2 - btnImage.size.height/2 + albumViewPadding)] intValue];
//        albumPlaybackButton.frame = CGRectMake(playbackOriginX, playbackOriginY, btnImage.size.width, btnImage.size.height);
//        [albumPlaybackButton addTarget:self action:@selector(preparePlaybackAlbum:) forControlEvents:UIControlEventTouchUpInside];
//        [albumDetailView addSubview:albumPlaybackButton];

        return albumDetailView;
    }
    else if (episodesView && self.richResults.count > 0 && ![self doesShowSearchResults]) {
        __block UIColor *seasonFontColor = [Utilities getGrayColor:0 alpha:1];
        __block UIColor *seasonFontShadowColor = [Utilities getGrayColor:255 alpha:0.3];
        __block UIColor *seasonDetailsColor = [Utilities getGrayColor:0 alpha:0.6];
        UIView *albumDetailView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, albumViewHeight + 2)];
        albumDetailView.tag = section;
        int toggleIconSpace = 0;
        if (self.sectionArray.count > 1) {
            toggleIconSpace = 8;
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOpen:)];
            [albumDetailView addGestureRecognizer:tapGesture];
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.tag = 99;
            button.alpha = 0.5;
            button.frame = CGRectMake(3, (int)(albumViewHeight / 2) - 6, 11, 11);
            [button setImage:[UIImage imageNamed:@"arrow_close"] forState:UIControlStateNormal];
            [button setImage:[UIImage imageNamed:@"arrow_open"] forState:UIControlStateSelected];
            if ([self.sectionArrayOpen[section] boolValue]) {
                button.selected = YES;
            }
            [albumDetailView addSubview:button];
        }
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = albumDetailView.bounds;
        gradient.colors = @[(id)[[Utilities getSystemGray5] CGColor], (id)[[Utilities getSystemGray1] CGColor]];
        [albumDetailView.layer insertSublayer:gradient atIndex:0];
        if (section > 0) {
            UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, -1, viewWidth, 1)];
            lineView.backgroundColor = [Utilities getGrayColor:242 alpha:1];
            [albumDetailView addSubview:lineView];
        }
        CGRect toolbarShadowFrame = CGRectMake(0, albumViewHeight + 1, viewWidth, 8);
        UIImageView *toolbarShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
        toolbarShadow.image = [UIImage imageNamed:@"tableUp"];
        toolbarShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbarShadow.opaque = YES;
        toolbarShadow.alpha = 0.3;
        [albumDetailView addSubview:toolbarShadow];
        
        NSDictionary *item;
        if ([self doesShowSearchResults]) {
            item = self.richResults[0];
        }
        else {
            item = [self.sections objectForKey:self.sectionArray[section]][0];
        }
        NSInteger seasonIdx = [self indexOfObjectWithSeason:[NSString stringWithFormat:@"%d", [item[@"season"] intValue]] inArray:self.extraSectionRichResults];
        NSInteger firstListedSeason = [self getFirstListedSeason:self.extraSectionRichResults];
        CGFloat seasonThumbWidth = (albumViewHeight - (albumViewPadding * 2)) * 0.71;
        if (seasonIdx != NSNotFound) {
            CGFloat origin_x = seasonThumbWidth + toggleIconSpace + (albumViewPadding * 2);
            CGFloat labelwidth = viewWidth - albumViewHeight - albumViewPadding;
            CGFloat bottomMargin = albumViewHeight - albumViewPadding - (trackCountFontSize + (labelPadding / 2) - 1);
            UILabel *artist = [[UILabel alloc] initWithFrame:CGRectMake(origin_x, (albumViewPadding / 2), labelwidth, artistFontSize + labelPadding)];
            UILabel *albumLabel = [[UILabel alloc] initWithFrame:CGRectMake(origin_x, artist.frame.origin.y + artistFontSize + 2, labelwidth, albumFontSize + labelPadding)];
            UILabel *trackCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(origin_x, bottomMargin, labelwidth - toggleIconSpace, trackCountFontSize + labelPadding)];
            UILabel *releasedLabel = [[UILabel alloc] initWithFrame:CGRectMake(origin_x, bottomMargin - trackCountFontSize -labelPadding/2, labelwidth - toggleIconSpace, trackCountFontSize + labelPadding)];
            UIImageView *thumbImageView = [[UIImageView alloc] initWithFrame:CGRectMake(albumViewPadding + toggleIconSpace, albumViewPadding, seasonThumbWidth, albumViewHeight - (albumViewPadding * 2))];
            NSString *stringURL = self.extraSectionRichResults[seasonIdx][@"thumbnail"];
            NSString *displayThumb = @"coverbox_back_section";
            BOOL isFirstListedSeason = [item[@"season"] intValue] == firstListedSeason;
            if (isFirstListedSeason) {
                self.searchController.searchBar.backgroundColor = [Utilities getSystemGray6];
                self.searchController.searchBar.tintColor = [Utilities get2ndLabelColor];
            }
            if ([item[@"filetype"] length] != 0) {
                displayThumb = stringURL;
            }
            if (![stringURL isEqualToString:@""]) {
                __weak UIImageView *weakThumbView = thumbImageView;
                [thumbImageView setImageWithURL:[NSURL URLWithString:stringURL]
                               placeholderImage:[UIImage imageNamed:displayThumb]
                                      andResize:CGSizeMake(seasonThumbWidth, albumViewHeight - (albumViewPadding * 2))
                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                    if (image != nil) {
                        weakThumbView.image = [Utilities applyRoundedEdgesImage:image drawBorder:YES];
                        [self setViewColor:albumDetailView
                                     image:image
                                 isTopMost:isFirstListedSeason
                                lab12color:seasonFontColor
                              label34Color:seasonDetailsColor
                                fontshadow:seasonFontShadowColor
                                    label1:artist
                                    label2:albumLabel
                                    label3:trackCountLabel
                                    label4:releasedLabel];
                    }
                }];
            }
            else {
                [thumbImageView setImageWithURL:[NSURL URLWithString:@""]
                               placeholderImage:[UIImage imageNamed:displayThumb]];
                [self setLabelColor:seasonFontColor
                       label34Color:seasonDetailsColor
                         fontshadow:seasonFontShadowColor
                             label1:artist
                             label2:albumLabel
                             label3:trackCountLabel
                             label4:releasedLabel];
            }
            [albumDetailView addSubview:thumbImageView];
            
            artist.backgroundColor = UIColor.clearColor;
            artist.shadowOffset = CGSizeMake(0, 1);
            artist.font = [UIFont systemFontOfSize:artistFontSize];
            artist.adjustsFontSizeToFitWidth = YES;
            artist.minimumScaleFactor = 9.0 / artistFontSize;
            artist.text = item[@"genre"];
            [albumDetailView addSubview:artist];
            
            albumLabel.backgroundColor = UIColor.clearColor;
            albumLabel.shadowOffset = CGSizeMake(0, 1);
            albumLabel.font = [UIFont boldSystemFontOfSize:albumFontSize];
            albumLabel.text = self.extraSectionRichResults[seasonIdx][@"label"];
            albumLabel.numberOfLines = 0;
            CGSize maximumLabelSize = CGSizeMake(labelwidth - toggleIconSpace, albumViewHeight - albumViewPadding*4 -28);
            CGRect expectedLabelRect = [albumLabel.text boundingRectWithSize:maximumLabelSize
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                        attributes:@{NSFontAttributeName:albumLabel.font}
                                                        context:nil];
            CGSize expectedLabelSize = expectedLabelRect.size;
            CGRect newFrame = albumLabel.frame;
            newFrame.size.height = expectedLabelSize.height + 8;
            albumLabel.frame = newFrame;
            [albumDetailView addSubview:albumLabel];
            
            trackCountLabel.backgroundColor = UIColor.clearColor;
            trackCountLabel.shadowOffset = CGSizeMake(0, 1);
            trackCountLabel.font = [UIFont systemFontOfSize:trackCountFontSize];
            trackCountLabel.text = [NSString stringWithFormat:LOCALIZED_STR(@"Episodes: %@"), self.extraSectionRichResults[seasonIdx][@"episode"]];
            [albumDetailView addSubview:trackCountLabel];

            releasedLabel.backgroundColor = UIColor.clearColor;
            releasedLabel.shadowOffset = CGSizeMake(0, 1);
            releasedLabel.font = [UIFont systemFontOfSize:trackCountFontSize];
            releasedLabel.minimumScaleFactor = (trackCountFontSize - 2) / trackCountFontSize;
            releasedLabel.numberOfLines = 1;
            releasedLabel.adjustsFontSizeToFitWidth = YES;
            
            NSString *aired = [Utilities getDateFromItem:item[@"year"] dateStyle:NSDateFormatterLongStyle];
            
            releasedLabel.text = @"";
            if (aired != nil) {
                releasedLabel.text = [NSString stringWithFormat:LOCALIZED_STR(@"First aired on %@"), aired];
            }
            [albumDetailView addSubview:releasedLabel];

            UIButton *albumInfoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
            albumInfoButton.alpha = 0.8;
            albumInfoButton.showsTouchWhenHighlighted = YES;
            albumInfoButton.frame = CGRectMake(viewWidth - albumInfoButton.frame.size.width - albumViewPadding, bottomMargin - 6, albumInfoButton.frame.size.width, albumInfoButton.frame.size.height);
            albumInfoButton.tag = 1;
            [albumInfoButton addTarget:self action:@selector(prepareShowAlbumInfo:) forControlEvents:UIControlEventTouchUpInside];
            [albumDetailView addSubview:albumInfoButton];
            albumInfoButton.hidden = [self isModal];
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

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    if (albumView && self.richResults.count > 0) {
        return albumViewHeight + 2;
    }
    else if (episodesView && self.richResults.count > 0 && ![self doesShowSearchResults]) {
        return albumViewHeight + 2;
    }
    else if (section != 0 || [self doesShowSearchResults]) {
        return sectionHeight;
    }
    if ([self.sections allKeys].count == 1) {
        return 1;
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
        UIViewController *showFromCtrl = nil;
        if (IS_IPHONE) {
            showFromCtrl = self;
        }
        else {
            showFromCtrl = self.view.window.rootViewController;
        }
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
            
            NSMutableArray *sheetActions = [[self.detailItem sheetActions][choosedTab] mutableCopy];
            if ([sheetActions isKindOfClass:[NSMutableArray class]]) {
                [sheetActions removeObject:LOCALIZED_STR(@"Play Trailer")];
                [sheetActions removeObject:LOCALIZED_STR(@"Mark as watched")];
                [sheetActions removeObject:LOCALIZED_STR(@"Mark as unwatched")];
            }
            NSInteger numActions = sheetActions.count;
            if (numActions) {
                NSDictionary *item = nil;
                if ([self doesShowSearchResults]) {
                    item = self.filteredListContent[indexPath.row];
                    [dataList selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
                else {
                    if (enableCollectionView) {
                        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                    }
                    else {
                        [dataList selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                    }
                    item = [self.sections objectForKey:self.sectionArray[indexPath.section]][indexPath.row];
                }
                sheetActions = [self getPlaylistActions:sheetActions item:item params:[Utilities indexKeyedMutableDictionaryFromArray:[self.detailItem mainParameters][choosedTab]]];
//                if ([item[@"filetype"] isEqualToString:@"directory"]) { // DOESN'T WORK AT THE MOMENT IN XBMC?????
//                    return;
//                }
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
                UIViewController *showFromCtrl = nil;
                UIView *showfromview = nil;
                if (IS_IPHONE) {
                    showFromCtrl = self;
                    showfromview = self.view;
                }
                else {
                    if ([self doesShowSearchResults] || [self getSearchTextField].editing) {
                        // We are searching an must present from searchController
                        showFromCtrl = self.searchController;
                    }
                    else if ([self isModal]) {
                        // We are in modal view (e.g. fullscreen) and must present from ourself
                        showFromCtrl = self;
                    }
                    else {
                        // We are in stackview and must present from rootVC
                        showFromCtrl = self.view.window.rootViewController;
                    }
                    showfromview = enableCollectionView ? collectionView : [showFromCtrl.view superview];
                    selectedPoint = enableCollectionView ? p : [lpgr locationInView:showfromview];
                }
                [self showActionSheetOptions:title options:sheetActions recording:isRecording point:selectedPoint fromcontroller:showFromCtrl fromview:showfromview];
            }
        }
    }
}

- (void)showActionSheetOptions:(NSString*)title options:(NSArray*)sheetActions recording:(BOOL)isRecording point:(CGPoint)origin fromcontroller:(UIViewController*)fromctrl fromview:(UIView*)fromview {
    NSInteger numActions = sheetActions.count;
    if (numActions) {
        UIAlertController *actionView = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction* action_cancel = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
            forceMusicAlbumMode = NO;
            [self deselectAtIndexPath:selected];
        }];
        
        NSInteger numActions = sheetActions.count;
        for (int i = 0; i < numActions; i++) {
            NSString *actiontitle = sheetActions[i];
            if ([actiontitle isEqualToString:LOCALIZED_STR(@"Record")] && isRecording) {
                actiontitle = LOCALIZED_STR(@"Stop Recording");
            }
            UIAlertAction* action = [UIAlertAction actionWithTitle:actiontitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
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
    id cell = [self getCell:indexPath];
    UITableView *tableView = dataList;
    BOOL isTableView = YES;
    if (enableCollectionView) {
        isTableView = NO;
    }
    UIActivityIndicatorView *queuing = (UIActivityIndicatorView*)[cell viewWithTag:8];
    [queuing startAnimating];

    NSString *methodToCall = @"";
    if ([item[@"family"] isEqualToString:@"episodeid"]) {
        methodToCall = @"VideoLibrary.SetEpisodeDetails";
    }
    else if ([item[@"family"] isEqualToString:@"tvshowid"]) {
        methodToCall = @"VideoLibrary.SetTVShowDetails";
    }
    else if ([item[@"family"] isEqualToString:@"movieid"]) {
        methodToCall = @"VideoLibrary.SetMovieDetails";
    }
    else if ([item[@"family"] isEqualToString:@"musicvideoid"]) {
        methodToCall = @"VideoLibrary.SetMusicVideoDetails";
    }
    else {
        [queuing stopAnimating];
        return;
    }
    [[Utilities getJsonRPC]
     callMethod:methodToCall
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                     item[item[@"family"]], item[@"family"],
                     @(watched), @"playcount",
                     nil]
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error == nil && methodError == nil) {
             if (isTableView) {
                 UIImageView *flagView = (UIImageView*)[cell viewWithTag:9];
                 if (watched > 0) {
                     flagView.hidden = NO;
                 }
                 else {
                     flagView.hidden = YES;
                 }
                 [tableView deselectRowAtIndexPath:indexPath animated:YES];
             }
             else {
                 if (watched > 0) {
                     [cell setOverlayWatched:YES];
                 }
                 else {
                     [cell setOverlayWatched:NO];
                 }
                 [collectionView deselectItemAtIndexPath:indexPath animated:YES];
             }
             item[@"playcount"] = @(watched);
             
             NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
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
             [queuing stopAnimating];
         }
         else {
             [queuing stopAnimating];
         }
     }];
}

- (void)saveSortMethod:(NSString*)sortMethod parameters:(NSDictionary*)parameters {
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainMethod][choosedTab]];
    NSString *sortKey = [NSString stringWithFormat:@"%@_sort_method", [self getCacheKey:methods[@"method"] parameters:[parameters mutableCopy]]];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:sortMethod forKey:sortKey];
}

- (void)saveSortAscDesc:(NSString*)sortAscDescSave parameters:(NSDictionary*)parameters {
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainMethod][choosedTab]];
    NSString *sortKey = [NSString stringWithFormat:@"%@_sort_ascdesc", [self getCacheKey:methods[@"method"] parameters:[parameters mutableCopy]]];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:sortAscDescSave forKey:sortKey];
}

- (void)actionSheetHandler:(NSString*)actiontitle {
    NSMutableDictionary *item = nil;
    if (selected != nil) {
        if ([self doesShowSearchResults]) {
            if (selected.row < self.filteredListContent.count) {
                item = self.filteredListContent[selected.row];
            }
        }
        else {
            if (selected.section < self.sectionArray.count) {
                if (selected.row < [self.sections[self.sectionArray[selected.section]] count]) {
                    item = self.sections[self.sectionArray[selected.section]][selected.row];
                }
            }
        }
        if (item == nil) {
            return;
        }
    }
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
             [actiontitle isEqualToString:LOCALIZED_STR(@"Episode Details")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"TV Show Details")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Music Video Details")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Broadcast Details")]) {
        if (forceMusicAlbumMode) {
            [self prepareShowAlbumInfo:nil];
        }
        else {
            [self showInfo:selected menuItem:self.detailItem item:item tabToShow:choosedTab];
        }
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Play Trailer")]) {
        [self playerOpen:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: item[@"trailer"], @"file", nil], @"item", nil] index:selected];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Search Wikipedia")]) {
        [self searchWeb:(NSMutableDictionary*)item indexPath:selected serviceURL:[NSString stringWithFormat:@"http://%@.m.wikipedia.org/wiki?search=%%@", LOCALIZED_STR(@"WIKI_LANG")]];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Search last.fm charts")]) {
        [self searchWeb:(NSMutableDictionary*)item indexPath:selected serviceURL:@"http://m.last.fm/music/%@/+charts?subtype=tracks&rangetype=6month&go=Go"];
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
        NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
        NSMutableDictionary *sortDictionary = parameters[@"available_sort_methods"];
        if (sortDictionary[@"label"] != nil) {
            NSUInteger sort_method_index = [sortDictionary[@"label"] indexOfObject:actiontitle];
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

- (void)searchWeb:(NSMutableDictionary*)item indexPath:(NSIndexPath*)indexPath serviceURL:(NSString*)serviceURL {
    if ([self.detailItem mainParameters].count > 0) {
        NSMutableDictionary *parameters = [Utilities indexKeyedMutableDictionaryFromArray:[self.detailItem mainParameters][0]];
        if (((NSNull*)parameters[@"fromWikipedia"] != [NSNull null])) {
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
    if (![self.detailItem disableNowPlaying]) {
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

#pragma mark - View Configuration

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    if (self.detailItem) {
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
        if (![self.detailItem disableNowPlaying]) {
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
         if (![self.detailItem disableNowPlaying]) {
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

- (void)toggleFullscreen:(id)sender {
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
                             button1.alpha = button2.alpha = button3.alpha = button4.alpha = button5.alpha = button6.alpha = button7.alpha = buttonsViewBgToolbar.alpha = topNavigationLabel.alpha = 1.0;
                            
                         }
                         completion:^(BOOL finished) {
                             viewWidth = STACKSCROLL_WIDTH;
                             if ([self collectionViewCanBeEnabled]) {
                                 button6.hidden = NO;
                             }
                             sectionArray = [storeSectionArray copy];
                             sections = [storeSections mutableCopy];
                             [self choseParams];
                             if (forceCollection) {
                                 forceCollection = NO;
                                 [self AnimTable:(UITableView*)activeLayoutView AnimDuration:0.0 Alpha:0.0 XPos:viewWidth];
                                 enableCollectionView = NO;
                                 [self configureLibraryView];
                                 [self AnimTable:(UITableView*)activeLayoutView AnimDuration:0.0 Alpha:0.0 XPos:0];
                             }
                             [self setFlowLayoutParams];
                             [collectionView.collectionViewLayout invalidateLayout];
                             [collectionView reloadData];
                             [collectionView setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
                             NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     @(animDuration), @"duration",
                                                     nil];
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
                                 [self AnimTable:(UITableView*)activeLayoutView AnimDuration:0.0 Alpha:0.0 XPos:viewWidth];
                                 enableCollectionView = YES;
                                 [self configureLibraryView];
                                 [self AnimTable:(UITableView*)activeLayoutView AnimDuration:0.0 Alpha:0.0 XPos:0];
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
                             NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     @(NO), @"hideToolbar",
                                                     @(animDuration), @"duration",
                                                     nil];
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
    [self playerOpen:[NSDictionary dictionaryWithObjectsAndKeys:
                      [NSDictionary dictionaryWithObjectsAndKeys:smartplaylist, @"partymode", nil], @"item", nil] index:indexPath];
}

- (void)exploreItem:(NSDictionary*)item {
    mainMenu *MenuItem = self.detailItem;
    NSDictionary *mainFields = [MenuItem mainFields][choosedTab];
    NSMutableDictionary *parameters = [Utilities indexKeyedMutableDictionaryFromArray:[MenuItem.subItem mainParameters][choosedTab]];
    NSString *libraryRowHeight = [NSString stringWithFormat:@"%d", MenuItem.subItem.rowHeight];
    NSString *libraryThumbWidth = [NSString stringWithFormat:@"%d", MenuItem.subItem.thumbWidth];
    if (parameters[@"rowHeight"] != nil) {
        libraryRowHeight = parameters[@"rowHeight"];
    }
    if (parameters[@"thumbWidth"] != nil) {
        libraryThumbWidth = parameters[@"thumbWidth"];
    }
    NSString *filemodeRowHeight = @"44";
    NSString *filemodeThumbWidth = @"44";
    if (parameters[@"rowHeight"] != nil) {
        filemodeRowHeight = parameters[@"rowHeight"];
    }
    if (parameters[@"thumbWidth"] != nil) {
        filemodeThumbWidth = parameters[@"thumbWidth"];
    }
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
                                   libraryRowHeight, @"rowHeight", libraryThumbWidth, @"thumbWidth",
                                   parameters[@"label"], @"label", @"nocover_filemode", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeThumbWidth, @"thumbWidth",
                                   [NSDictionary dictionaryWithDictionary:parameters[@"itemSizes"]], @"itemSizes",
                                   [NSString stringWithFormat:@"%d", [parameters[@"enableCollectionView"] boolValue]], @"enableCollectionView",
                                   @"Files.GetDirectory", @"exploreCommand",
                                   parameters[@"disableFilterParameter"], @"disableFilterParameter",
                                   nil];
    MenuItem.subItem.mainLabel = item[@"label"];
    mainMenu *newMenuItem = [MenuItem.subItem copy];
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
    NSNumber *itemid = @([item[@"timerid"] intValue]);
    if ([itemid isEqualToValue:@(0)]) {
        return;
    }
    id cell = [self getCell:indexPath];
    UIActivityIndicatorView *queuing = (UIActivityIndicatorView*)[cell viewWithTag:8];
    NSString *methodToCall = @"PVR.DeleteTimer";
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                itemid, @"timerid",
                                nil];

    [queuing startAnimating];
    [[Utilities getJsonRPC] callMethod:methodToCall
         withParameters:parameters
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               [queuing stopAnimating];
               [self deselectAtIndexPath:indexPath];
               if (error == nil && methodError == nil) {
                   [self.searchController setActive:NO];
                   [self AnimTable:(UITableView*)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:viewWidth];
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

- (void)recordChannel:(NSMutableDictionary*)item indexPath:(NSIndexPath*)indexPath {
    NSString *methodToCall = @"PVR.Record";
    NSString *parameterName = @"channel";
    NSNumber *itemid = @([item[@"channelid"] intValue]);
    NSNumber *storeChannelid = itemid;
    NSNumber *storeBroadcastid = @([item[@"broadcastid"] intValue]);
    if ([itemid isEqualToValue:@(0)]) {
        itemid = @([item[@"pvrExtraInfo"][@"channelid"] intValue]);
        if ([itemid isEqualToValue:@(0)]) {
            return;
        }
        storeChannelid = itemid;
        NSDate *starttime = [xbmcDateFormatter dateFromString:item[@"starttime"]];
        NSDate *endtime = [xbmcDateFormatter dateFromString:item[@"endtime"]];
        float total_seconds = [endtime timeIntervalSince1970] - [starttime timeIntervalSince1970];
        float elapsed_seconds = [[NSDate date] timeIntervalSince1970] - [starttime timeIntervalSince1970];
        float percent_elapsed = (elapsed_seconds/total_seconds) * 100.0f;
        if (percent_elapsed < 0) {
            itemid = @([item[@"broadcastid"] intValue]);
            storeBroadcastid = itemid;
            storeChannelid = @(0);
            methodToCall = @"PVR.ToggleTimer";
            parameterName = @"broadcastid";
        }
    }
    id cell = [self getCell:indexPath];
    UIActivityIndicatorView *queuing = (UIActivityIndicatorView*)[cell viewWithTag:8];
    [queuing startAnimating];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                itemid, parameterName,
                                nil];
    [[Utilities getJsonRPC] callMethod:methodToCall
         withParameters:parameters
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               [queuing stopAnimating];
               [self deselectAtIndexPath:indexPath];
               if (error == nil && methodError == nil) {
                   UIImageView *isRecordingImageView = (UIImageView*)[cell viewWithTag:104];
                   isRecordingImageView.hidden = !isRecordingImageView.hidden;
                   NSNumber *status = @(![item[@"isrecording"] boolValue]);
                   if ([item[@"broadcastid"] intValue] > 0) {
                       status = @(![item[@"hastimer"] boolValue]);
                   }
                   NSDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           storeChannelid, @"channelid",
                                           storeBroadcastid, @"broadcastid",
                                           status, @"status",
                                           nil];
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
    id cell = [self getCell:indexPath];
    UIActivityIndicatorView *queuing = (UIActivityIndicatorView*)[cell viewWithTag:8];
    [queuing startAnimating];
    NSDictionary *mainFields = [self.detailItem mainFields][choosedTab];
    if (forceMusicAlbumMode) {
        mainFields = [AppDelegate.instance.playlistArtistAlbums mainFields][0];
        forceMusicAlbumMode = NO;
    }
    NSString *key = mainFields[@"row9"];
    id value = item[key];
    if ([item[@"filetype"] isEqualToString:@"directory"]) {
        key = @"directory";
    }
    // Since API 12.7.0 Kodi server can handle Playlist.Insert and Playlist.Add for recordingid.
    // Before, the JSON parameters must use the file path.
    else if (!(AppDelegate.instance.APImajorVersion >= 12 && AppDelegate.instance.APIminorVersion >= 7) && [mainFields[@"row9"] isEqualToString:@"recordingid"]) {
        key = @"file";
        value = item[@"file"];
    }
    if (afterCurrent) {
        [[Utilities getJsonRPC]
         callMethod:@"Player.GetProperties"
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                         mainFields[@"playlistid"], @"playerid",
                         @[@"percentage", @"time", @"totaltime", @"partymode", @"position"], @"properties",
                         nil] 
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
             if (error == nil && methodError == nil) {
                 if ([NSJSONSerialization isValidJSONObject:methodResult]) {
                     if ([methodResult count]) {
                         [queuing stopAnimating];
                         int newPos = [methodResult[@"position"] intValue] + 1;
                         NSString *action2 = @"Playlist.Insert";
                         NSDictionary *params2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                                mainFields[@"playlistid"], @"playlistid",
                                                [NSDictionary dictionaryWithObjectsAndKeys: value, key, nil], @"item",
                                                @(newPos), @"position",
                                                nil];
                         [[Utilities getJsonRPC] callMethod:action2 withParameters:params2 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                             if (error == nil && methodError == nil) {
                                 [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil]; 
                             }
                         }];
                     }
                     else {
                         [self addToPlaylist:mainFields currentItem:value currentKey:key currentActivityIndicator:queuing];
                     }
                 }
                 else {
                     [self addToPlaylist:mainFields currentItem:value currentKey:key currentActivityIndicator:queuing];
                 }
             }
             else {
                [self addToPlaylist:mainFields currentItem:value currentKey:key currentActivityIndicator:queuing];
             }
         }];
    }
    else {
        [self addToPlaylist:mainFields currentItem:value currentKey:key currentActivityIndicator:queuing];
    }
}

- (void)addToPlaylist:(NSDictionary*)mainFields currentItem:(id)value currentKey:(NSString*)key currentActivityIndicator:(UIActivityIndicatorView*)queuing {
    [[Utilities getJsonRPC] callMethod:@"Playlist.Add" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:mainFields[@"playlistid"], @"playlistid", [NSDictionary dictionaryWithObjectsAndKeys: value, key, nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        [queuing stopAnimating];
        if (error == nil && methodError == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil]; 
        }
    }];
    
}

- (void)playerOpen:(NSDictionary*)params index:(NSIndexPath*)indexPath {
    id cell = [self getCell:indexPath];
    UIActivityIndicatorView *queuing = (UIActivityIndicatorView*)[cell viewWithTag:8];
    [queuing startAnimating];
    [[Utilities getJsonRPC] callMethod:@"Player.Open" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        [queuing stopAnimating];
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
    NSDictionary *mainFields = [self.detailItem mainFields][choosedTab];
    if (forceMusicAlbumMode) {
        mainFields = [AppDelegate.instance.playlistArtistAlbums mainFields][0];
        forceMusicAlbumMode = NO;
    }
    if (mainFields.count == 0) {
        return;
    }
    id cell = [self getCell:indexPath];
    UIActivityIndicatorView *queuing = (UIActivityIndicatorView*)[cell viewWithTag:8];
    [queuing startAnimating];
    if ([mainFields[@"row8"] isEqualToString:@"channelid"] ||
        [mainFields[@"row8"] isEqualToString:@"broadcastid"]) {
        NSNumber *channelid = item[mainFields[@"row8"]];
        NSString *param = @"channelid";
        if ([mainFields[@"row8"] isEqualToString:@"broadcastid"]) {
            channelid = item[@"pvrExtraInfo"][@"channelid"];
        }
        [self playerOpen:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: channelid, param, nil], @"item", nil] index:indexPath];
    }
    else if ([mainFields[@"row7"] isEqualToString:@"plugin"]) {
        [self playerOpen:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: item[@"file"], @"file", nil], @"item", nil] index:indexPath];
    }
    else {
        id optionsParam = nil;
        id optionsValue = nil;
        if (AppDelegate.instance.serverVersion > 11) {
            optionsParam = @"options";
            optionsValue = [NSDictionary dictionaryWithObjectsAndKeys: @(shuffled), @"shuffled", nil];
        }
        [[Utilities getJsonRPC] callMethod:@"Playlist.Clear" withParameters:[NSDictionary dictionaryWithObjectsAndKeys: mainFields[@"playlistid"], @"playlistid", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            if (error == nil && methodError == nil) {
                NSString *key = mainFields[@"row8"];
                id value = item[key];
                if ([item[@"filetype"] isEqualToString:@"directory"]) {
                    key = @"directory";
                }
                // Since API 12.7.0 Kodi server can handle Playlist.Insert and Playlist.Add for recordingid.
                // Before, the JSON parameters must use the file path.
                else if (!(AppDelegate.instance.APImajorVersion >= 12 && AppDelegate.instance.APIminorVersion >= 7) && [mainFields[@"row8"] isEqualToString:@"recordingid"]) {
                    key = @"file";
                    value = item[@"file"];
                }
                if (shuffled && AppDelegate.instance.serverVersion > 11) {
                    [[Utilities getJsonRPC]
                     callMethod:@"Player.SetPartymode"
                     withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@(0), @"playerid", @(NO), @"partymode", nil]
                     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *internalError) {
                         [self playlistAndPlay:[NSDictionary dictionaryWithObjectsAndKeys:
                                                mainFields[@"playlistid"], @"playlistid",
                                                [NSDictionary dictionaryWithObjectsAndKeys:
                                                 value, key, nil], @"item",
                                                nil]
                                playbackParams:[NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSDictionary dictionaryWithObjectsAndKeys:
                                                 mainFields[@"playlistid"], @"playlistid",
                                                 @(pos), @"position",
                                                 nil], @"item",
                                                optionsValue, optionsParam,
                                                nil]
                                     indexPath:indexPath
                                          cell:cell];
                     }];
                }
                else {
                    [self playlistAndPlay:[NSDictionary dictionaryWithObjectsAndKeys:
                                           mainFields[@"playlistid"], @"playlistid",
                                           [NSDictionary dictionaryWithObjectsAndKeys:
                                            value, key, nil], @"item",
                                           nil]
                           playbackParams:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSDictionary dictionaryWithObjectsAndKeys:
                                            mainFields[@"playlistid"], @"playlistid",
                                            @(pos), @"position",
                                            nil], @"item",
                                           optionsValue, optionsParam,
                                           nil]
                                indexPath:indexPath
                                     cell:cell];
                }
            }
            else {
                UIActivityIndicatorView *queuing = (UIActivityIndicatorView*)[cell viewWithTag:8];
                [queuing stopAnimating];
            }
        }];
    }
}

- (void)playlistAndPlay:(NSDictionary*)playlistParams playbackParams:(NSDictionary*)playbackParams indexPath:(NSIndexPath*)indexPath cell:(id)cell {
    [[Utilities getJsonRPC] callMethod:@"Playlist.Add" withParameters:playlistParams onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error == nil && methodError == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
            [self playerOpen:playbackParams index:indexPath];
        }
        else {
            UIActivityIndicatorView *queuing = (UIActivityIndicatorView*)[cell viewWithTag:8];
            [queuing stopAnimating];
            //                                            NSLog(@"secondo errore %@", methodError);
        }
    }];
}

- (void)SimpleAction:(NSString*)action params:(NSDictionary*)parameters success:(NSString*)successMessage failure:(NSString*)failureMessage {
    [[Utilities getJsonRPC] callMethod:action withParameters:parameters onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
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
    if ([self.detailItem mainParameters].count > 0) {
        NSMutableDictionary *parameters = [Utilities indexKeyedMutableDictionaryFromArray:[self.detailItem mainParameters][0]];
        if (((NSNull*)parameters[@"fromShowInfo"] != [NSNull null])) {
            if ([parameters[@"fromShowInfo"] boolValue]) {
                [self goBack:nil];
                return;
            }
        }
    }
    mainMenu *MenuItem = nil;
    if ([sender tag] == 0) {
        MenuItem = [AppDelegate.instance.playlistArtistAlbums copy];
    }
    else if ([sender tag] == 1) {
        MenuItem = [AppDelegate.instance.playlistTvShows copy];
    }
    MenuItem.subItem.mainLabel = self.navigationItem.title;
    MenuItem.subItem.mainMethod = nil;
    if (self.richResults.count > 0) {
        [self.searchController.searchBar resignFirstResponder];
        [self showInfo:nil menuItem:MenuItem item:self.richResults[0] tabToShow:0];
    }
}

- (void)showInfo:(NSIndexPath*)indexPath menuItem:(mainMenu*)menuItem item:(NSDictionary*)item tabToShow:(int)tabToShow {
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[menuItem mainMethod][tabToShow]];
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[menuItem mainParameters][tabToShow]];
    
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
    NSArray *sheetActions = @[LOCALIZED_STR(@"Queue after current"), LOCALIZED_STR(@"Queue"), LOCALIZED_STR(@"Play"), LOCALIZED_STR(@"Play in shuffle mode"), LOCALIZED_STR(@"Album Details"), LOCALIZED_STR(@"Search Wikipedia")];
    selected = [NSIndexPath indexPathForRow:0 inSection:0];
    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[self.sections objectForKey:self.sectionArray[0]][0]];
    item[@"label"] = self.navigationItem.title;
    forceMusicAlbumMode = YES;
    int rectOrigin = (int)((albumViewHeight - (albumViewPadding * 2))/2);
    [self showActionSheet:nil sheetActions:sheetActions item:item rectOriginX:rectOrigin + albumViewPadding rectOriginY:rectOrigin];
}

//- (void)playbackAction:(NSString*)action params:(NSArray*)parameters {
//    [[Utilities getJsonRPC] callMethod:@"Playlist.GetPlaylists" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
//        if (error == nil && methodError == nil) {
////            NSLog(@"RISPOSRA %@", methodResult);
//            if (methodResult.count > 0) {
//                NSNumber *response = methodResult[0][@"playerid"];
////                NSMutableArray *commonParams = [NSMutableArray arrayWithObjects:response, @"playerid", nil];
////                if (parameters != nil) {
////                    [commonParams addObjectsFromArray:parameters];
////                }
////                [[Utilities getJsonRPC] callMethod:action withParameters:nil onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
////                    if (error == nil && methodError == nil) {
////                        //                        NSLog(@"comando %@ eseguito ", action);
////                    }
////                    else {
////                        NSLog(@"ci deve essere un secondo problema %@", methodError);
////                    }
////                }];
//            }
//        }
//        else {
//            NSLog(@"ci deve essere un primo problema %@", methodError);
//        }
//    }];
//}

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
    NSString *itemid = @"";
    NSDictionary *mainFields = [menuItem mainFields][tabToShow];
    if (((NSNull*)mainFields[@"row6"] != [NSNull null])) {
        itemid = mainFields[@"row6"];
    }
    else {
        return; // something goes wrong
    }

    UIActivityIndicatorView *queuing = nil;
    
    if (indexPath != nil) {
        id cell = [self getCell:indexPath];
        queuing = (UIActivityIndicatorView*)[cell viewWithTag:8];
        [queuing startAnimating];
    }
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
                                     item[itemid], itemid,
                                     nil];
    GlobalData *obj = [GlobalData getInstance];
    [[Utilities getJsonRPC]
     callMethod:methodToCall
     withParameters:newParameters
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error == nil && methodError == nil) {
             [queuing stopAnimating];
             if ([NSJSONSerialization isValidJSONObject:methodResult]) {
                 NSString *itemid_extra_info = @"";
                 if (((NSNull*)mainFields[@"itemid_extra_info"] != [NSNull null])) {
                     itemid_extra_info = mainFields[@"itemid_extra_info"];
                 }
                 else {
                     return; // something goes wrong
                 }
                 NSDictionary *itemExtraDict = methodResult[itemid_extra_info];
                 if (((NSNull*)itemExtraDict == [NSNull null]) || itemExtraDict == nil) {
                     return; // something goes wrong
                 }
                 NSString *serverURL = @"";
                 int secondsToMinute = 1;
                 serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                 if (AppDelegate.instance.serverVersion > 11) {
                     serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
                     secondsToMinute = 60;
                 }
                 NSString *label = [NSString stringWithFormat:@"%@", itemExtraDict[mainFields[@"row1"]]];
                 NSString *genre = [Utilities getStringFromItem:itemExtraDict[mainFields[@"row2"]]];
                 
                 NSString *year = [Utilities getYearFromItem:itemExtraDict[mainFields[@"row3"]]];
                 
                 NSString *runtime = [Utilities getTimeFromItem:itemExtraDict[mainFields[@"row4"]] sec2min:secondsToMinute];
                 
                 NSString *rating = [Utilities getRatingFromItem:itemExtraDict[mainFields[@"row5"]]];
                 
                 NSString *thumbnailPath = [Utilities getThumbnailFromDictionary:itemExtraDict useBanner:NO useIcon:methodResult[@"recordingdetails"] != nil];

                 NSDictionary *art = itemExtraDict[@"art"];
                 NSString *clearlogo = [Utilities getClearArtFromDictionary:art type:@"clearlogo"];
                 NSString *clearart = [Utilities getClearArtFromDictionary:art type:@"clearart"];
//                 if (art.count && [art[@"banner"] length] != 0 && AppDelegate.instance.serverVersion > 11 && !AppDelegate.instance.obj.preferTVPosters) {
//                     thumbnailPath = art[@"banner"];
//                 }
                 NSString *stringURL = [Utilities formatStringURL:thumbnailPath serverURL:serverURL];
                 NSString *fanartURL = [Utilities formatStringURL:itemExtraDict[@"fanart"] serverURL:serverURL];
                 if ([stringURL isEqualToString:@""]) {
                     stringURL = [Utilities getItemIconFromDictionary:itemExtraDict mainFields:mainFields];
                 }
                 BOOL disableNowPlaying = NO;
                 if ([self.detailItem disableNowPlaying]) {
                     disableNowPlaying = YES;
                 }
                 
                 NSObject *row11 = itemExtraDict[mainFields[@"row11"]];
                 if (row11 == nil) {
                     row11 = @(0);
                 }
                 NSString *row11key = mainFields[@"row11"];
                 if (row11key == nil) {
                     row11key = @"";
                 }
                 
                 NSObject *row7 = itemExtraDict[mainFields[@"row7"]];
                 if (row7 == nil) {
                     row7 = @(0);
                 }
                 NSString *row7key = mainFields[@"row7"];
                 if (row7key == nil) {
                     row7key = @"";
                 }

                 
                 NSDictionary *newItem =
                 [NSMutableDictionary dictionaryWithObjectsAndKeys:
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
                  itemExtraDict[mainFields[@"row6"]], mainFields[@"row6"],
                  itemExtraDict[mainFields[@"row8"]], mainFields[@"row8"],
                  year, @"year",
                  rating, @"rating",
                  mainFields[@"playlistid"], @"playlistid",
                  mainFields[@"row8"], @"family",
                  @([[NSString stringWithFormat:@"%@", itemExtraDict[mainFields[@"row9"]]] intValue]), mainFields[@"row9"],
                  itemExtraDict[mainFields[@"row10"]], mainFields[@"row10"],
                  row11, row11key,
                  itemExtraDict[mainFields[@"row12"]], mainFields[@"row12"],
                  itemExtraDict[mainFields[@"row13"]], mainFields[@"row13"],
                  itemExtraDict[mainFields[@"row14"]], mainFields[@"row14"],
                  itemExtraDict[mainFields[@"row15"]], mainFields[@"row15"],
                  itemExtraDict[mainFields[@"row16"]], mainFields[@"row16"],
                  itemExtraDict[mainFields[@"row17"]], mainFields[@"row17"],
                  itemExtraDict[mainFields[@"row18"]], mainFields[@"row18"],
                  itemExtraDict[mainFields[@"row20"]], mainFields[@"row20"],
                  nil];
                 [self displayInfoView:newItem];
             }
             else {
                 [queuing stopAnimating];
             }
         }
         else {
             UIAlertController *alertView = [Utilities createAlertOK:LOCALIZED_STR(@"Details not found") message:nil];
             [self presentViewController:alertView animated:YES completion:nil];
             [queuing stopAnimating];
         }
     }];
}

- (void)startRetrieveDataWithRefresh:(BOOL)forceRefresh {
    if (forceRefresh) {
        [activeLayoutView setUserInteractionEnabled:NO];
    }
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainMethod][choosedTab]];
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
    NSMutableDictionary *mutableParameters = [parameters[@"parameters"] mutableCopy];
    NSMutableArray *mutableProperties = [parameters[@"parameters"][@"properties"] mutableCopy];
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
    NSString *methodToCall = methods[@"method"];
    if (parameters[@"exploreCommand"] != nil) {
        methodToCall = parameters[@"exploreCommand"];
    }
    if (methodToCall != nil) {
        [self retrieveData:methodToCall parameters:mutableParameters sectionMethod:methods[@"extra_section_method"] sectionParameters:parameters[@"extra_section_parameters"] resultStore:self.richResults extraSectionCall:NO refresh:forceRefresh];
    }
    else {
        [activityIndicatorView stopAnimating];
        [self AnimTable:(UITableView*)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
}

- (void)retrieveData:(NSString*)methodToCall parameters:(NSDictionary*)parameters sectionMethod:(NSString*)SectionMethodToCall sectionParameters:(NSDictionary*)sectionParameters resultStore:(NSMutableArray*)resultStoreArray extraSectionCall:(BOOL) extraSectionCallBool refresh:(BOOL)forceRefresh {
    NSMutableDictionary *mutableParameters = [parameters mutableCopy];
    if (mutableParameters[@"file_properties"] != nil) {
        mutableParameters[@"properties"] = mutableParameters[@"file_properties"];
        [mutableParameters removeObjectForKey: @"file_properties"];
    }
    
    if ([self loadedDataFromDisk:methodToCall parameters:(sectionParameters == nil) ? mutableParameters : [NSMutableDictionary dictionaryWithDictionary:sectionParameters] refresh:forceRefresh]) {
        return;
    }
    
    BOOL useCommonPvrRecordingsTimers = NO;
    if ([methodToCall containsString:@"PVR."]) {
        // PVR methods do not support "sort" before JSON API 12.1
        if ((AppDelegate.instance.APImajorVersion < 12) ||
            ((AppDelegate.instance.APImajorVersion == 12) && (AppDelegate.instance.APIminorVersion < 1))) {
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

    GlobalData *obj = [GlobalData getInstance];
    [self alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
//    NSLog(@"START");
    debugText.text = [NSString stringWithFormat:LOCALIZED_STR(@"METHOD\n%@\n\nPARAMETERS\n%@\n"), methodToCall, [[[NSString stringWithFormat:@"%@", parameters] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
    elapsedTime = 0;
    startTime = [NSDate timeIntervalSinceReferenceDate];
    countExecutionTime = [NSTimer scheduledTimerWithTimeInterval:WARNING_TIMEOUT target:self selector:@selector(checkExecutionTime) userInfo:nil repeats:YES];
//    NSLog(@" METHOD %@ PARAMETERS %@", methodToCall, mutableParameters);
    [[Utilities getJsonRPC]
     callMethod:methodToCall
     withParameters:mutableParameters
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         int total = 0;
         startTime = 0;
         [countExecutionTime invalidate];
         countExecutionTime = nil;
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
         BOOL ignoreRadioItems = [[self.detailItem mainLabel] isEqualToString:LOCALIZED_STR(@"Live TV")] && isRecordingsOrTimersMethod;
         BOOL ignoreTvItems = [[self.detailItem mainLabel] isEqualToString:LOCALIZED_STR(@"Radio")] && isRecordingsOrTimersMethod;
         // If we are reading PVR timer, we need to filter them for the current mode in postprocessing. Ignore
         // scheduled recordings, if we are in timer rules mode. Or ignore timer rules, if scheduled recordings
         // are listed.
         NSDictionary *menuParam = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
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
             if (resultStoreArray.count) {
                 [resultStoreArray removeAllObjects];
             }
             if (self.sections.count) {
                 [self.sections removeAllObjects];
             }
             [activeLayoutView reloadData];
             if ([NSJSONSerialization isValidJSONObject:methodResult]) {
                 NSString *itemid = @"";
                 NSDictionary *mainFields = [self.detailItem mainFields][choosedTab];
                 if (((NSNull*)mainFields[@"itemid"] != [NSNull null])) {
                     itemid = mainFields[@"itemid"];
                 }
                 if (extraSectionCallBool) {
                     if (((NSNull*)mainFields[@"itemid_extra_section"] != [NSNull null])) {
                         itemid = mainFields[@"itemid_extra_section"];
                     }
                     else {
                         return;
                     }
                 }
                 if (methodResult[@"recordings"] != nil) {
                     recordingListView = YES;
                 }
                 else {
                     recordingListView = NO;
                 }
                 NSArray *itemDict = methodResult[itemid];
                 NSString *serverURL = @"";
                 serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                 int secondsToMinute = 1;
                 if (AppDelegate.instance.serverVersion > 11) {
                     serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
                     if ([self.detailItem noConvertTime]) {
                         secondsToMinute = 60;
                     }
                 }
                 if ([itemDict isKindOfClass:[NSArray class]]) {
                     if (((NSNull*)itemDict != [NSNull null])) {
                         total = (int)itemDict.count;
                     }
                     for (int i = 0; i < total; i++) {
                         NSString *label = [NSString stringWithFormat:@"%@", itemDict[i][mainFields[@"row1"]]];
                         
                         NSString *genre = [Utilities getStringFromItem:itemDict[i][mainFields[@"row2"]]];
                         
                         NSString *year = [Utilities getYearFromItem:itemDict[i][mainFields[@"row3"]]];

                         NSString *runtime = [Utilities getTimeFromItem:itemDict[i][mainFields[@"row4"]] sec2min:secondsToMinute];
                         
                         NSString *rating = [Utilities getRatingFromItem:itemDict[i][mainFields[@"row5"]]];
                         
                         NSString *thumbnailPath = [Utilities getThumbnailFromDictionary:itemDict[i] useBanner:tvshowsView useIcon:recordingListView];

                         NSString *stringURL = [Utilities formatStringURL:thumbnailPath serverURL:serverURL];
                         NSString *fanartURL = [Utilities formatStringURL:itemDict[i][@"fanart"] serverURL:serverURL];
                         if ([stringURL isEqualToString:@""]) {
                             stringURL = [Utilities getItemIconFromDictionary:itemDict[i] mainFields:mainFields];
                         }
                         NSString *key = @"none";
                         NSString *value = @"";
                         if ((mainFields[@"row7"] != nil)) {
                             key = mainFields[@"row7"];
                             value = [NSString stringWithFormat:@"%@", itemDict[i][mainFields[@"row7"]]];
                         }
                         NSString *seasonNumber = [NSString stringWithFormat:@"%@", itemDict[i][mainFields[@"row10"]]];
                         
                         NSString *family = [NSString stringWithFormat:@"%@", mainFields[@"row8"]];
                         
                         NSString *row19key = mainFields[@"row19"];
                         if (row19key == nil) {
                             row19key = @"episode";
                         }
                         id episodeNumber = @"";
                         if ([itemDict[i][mainFields[@"row19"]] isKindOfClass:[NSDictionary class]]) {
                             episodeNumber = [itemDict[i][mainFields[@"row19"]] mutableCopy];
                         }
                         else {
                             episodeNumber = [NSString stringWithFormat:@"%@", itemDict[i][mainFields[@"row19"]]];
                         }
                         id row13obj = [mainFields[@"row13"] isEqualToString:@"options"] ? itemDict[i][mainFields[@"row13"]] == nil ? @"" : itemDict[i][mainFields[@"row13"]] : itemDict[i][mainFields[@"row13"]];
                         
                         id row14obj = [mainFields[@"row14"] isEqualToString:@"allowempty"] ? itemDict[i][mainFields[@"row14"]] == nil ? @"" : itemDict[i][mainFields[@"row14"]] : itemDict[i][mainFields[@"row14"]];
                         
                         id row15obj = [mainFields[@"row15"] isEqualToString:@"addontype"] ? itemDict[i][mainFields[@"row15"]] == nil ? @"" : itemDict[i][mainFields[@"row15"]] : itemDict[i][mainFields[@"row15"]];
                         
                         NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                      label, @"label",
                                                      genre, @"genre",
                                                      stringURL, @"thumbnail",
                                                      fanartURL, @"fanart",
                                                      runtime, @"runtime",
                                                      seasonNumber, @"season",
                                                      episodeNumber, row19key,
                                                      family, @"family",
                                                      itemDict[i][mainFields[@"row6"]], mainFields[@"row6"],
                                                      itemDict[i][mainFields[@"row8"]], mainFields[@"row8"],
                                                      year, @"year",
                                                      [NSString stringWithFormat:@"%@", rating], @"rating",
                                                      mainFields[@"playlistid"], @"playlistid",
                                                      value, key,
                                                      itemDict[i][mainFields[@"row9"]], mainFields[@"row9"],
                                                      itemDict[i][mainFields[@"row10"]], mainFields[@"row10"],
                                                      itemDict[i][mainFields[@"row11"]], mainFields[@"row11"],
                                                      itemDict[i][mainFields[@"row12"]], mainFields[@"row12"],
                                                      row13obj, mainFields[@"row13"],
                                                      row14obj, mainFields[@"row14"],
                                                      row15obj, mainFields[@"row15"],
                                                      itemDict[i][mainFields[@"row16"]], mainFields[@"row16"],
                                                      itemDict[i][mainFields[@"row17"]], mainFields[@"row17"],
                                                      itemDict[i][mainFields[@"row18"]], mainFields[@"row18"],
                                                      nil];
                         
                         // Check if we need to ignore the current item
                         BOOL isRadioItem = [itemDict[i][@"radio"] boolValue] ||
                                            [itemDict[i][@"isradio"] boolValue];
                         BOOL isTimerRule = [itemDict[i][@"istimerrule"] boolValue];
                         BOOL ignorePvrItem = (ignoreRadioItems && isRadioItem) ||
                                              (ignoreTvItems && !isRadioItem) ||
                                              (ignoreTimerRulesItems && isTimerRule) ||
                                              (ignoreTimerItems && !isTimerRule);
                         
                         // Postprocessing of movie sets lists to ignore 1-movie-sets
                         if (ignoreSingleMovieSets) {
                             BOOL isLastItem = i == total-1;
                             if (i==0) {
                                 [storeRichResults removeAllObjects];
                             }
                             NSString *newMethodToCall = @"VideoLibrary.GetMovieSetDetails";
                             NSDictionary *newParameter = @{@"setid": @([itemDict[i][@"setid"] intValue])};
                             [[Utilities getJsonRPC]
                              callMethod:newMethodToCall
                              withParameters:newParameter
                              onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                                 if (error==nil && methodError==nil) {
                                     if ([methodResult[@"setdetails"][@"movies"] count]>1) {
                                         [storeRichResults addObject:newDict];
                                     }
                                 }
                                 if (isLastItem) {
                                     self.richResults = [storeRichResults mutableCopy];
                                     if (forceRefresh == YES){
                                         [((UITableView*)activeLayoutView).pullToRefreshView stopAnimating];
                                         [activeLayoutView setUserInteractionEnabled:YES];
                                     }
                                     [self saveData:mutableParameters];
                                     [self indexAndDisplayData];
                                 }
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
                 else if ([itemDict isKindOfClass:[NSDictionary class]]) {
                     NSDictionary *dictVideoLibraryMovies = methodResult[itemid];
                     if ([dictVideoLibraryMovies[mainFields[@"typename"]] isKindOfClass:[NSDictionary class]]) {
                         if ([dictVideoLibraryMovies[mainFields[@"typename"]][mainFields[@"fieldname"]] isKindOfClass:[NSArray class]]) {
                             itemDict = dictVideoLibraryMovies[mainFields[@"typename"]][mainFields[@"fieldname"]];
                             if (((NSNull*)itemDict != [NSNull null])) {
                                 total = (int)itemDict.count;
                             }
                             NSString *sublabel = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]][@"morelabel"];
                             if (!sublabel || [sublabel isKindOfClass:[NSNull class]]) {
                                 sublabel = @"";
                             }
                             for (int i = 0; i < total; i++) {
                                 [resultStoreArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                              itemDict[i], @"label",
                                                              sublabel, @"genre",
                                                              @"file", @"family",
                                                              mainFields[@"thumbnail"], @"thumbnail",
                                                              @"", @"fanart",
                                                              @"", @"runtime",
                                                              nil]];
                             }
                         }
                     }
                 }
//                 NSLog(@"END STORE");
//                 NSLog(@"RICH RESULTS %@", resultStoreArray);
                 // Leave as all necessary steps are handled in callbacks of the postprocessing for 1-movie-sets
                 if (ignoreSingleMovieSets) {
                     return;
                 }
                 if (!extraSectionCallBool) {
                     storeRichResults = [resultStoreArray mutableCopy];
                 }
                 if (SectionMethodToCall != nil) {
                     [self retrieveData:SectionMethodToCall parameters:sectionParameters sectionMethod:nil sectionParameters:nil resultStore:self.extraSectionRichResults extraSectionCall:YES refresh:forceRefresh];
                 }
                 else if (filterModeType == ViewModeWatched ||
                          filterModeType == ViewModeUnwatched) {
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

- (void)animateNoResultsFound {
    [self alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
    [activityIndicatorView stopAnimating];
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
    [self AnimTable:(UITableView*)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
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
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
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
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
    NSArray *copyRichResults = [self.richResults copy];
    BOOL addUITableViewIndexSearch = NO;
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
    
    // If a sort method is defined which is not found as key, we select @"label" as sort method.
    // This happens for example when sorting by @"artist".
    if (sortMethodName != nil && copyRichResults.count > 0 && copyRichResults[0][sortMethodName] == nil) {
        sortMethodName = @"label";
    }
    
    // Sort tokens need to be processed outside of other conditions to ensure they are applied
    // also for default sorting coming from Kodi server.
    NSString *sortbymethod = sortMethodName;
    if (sortMethodName != nil) {
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
            BOOL found;
            NSString *c = [NSString stringWithFormat:@"%@", item[@"season"]];
            found = NO;
            if ([[self.sections allKeys] containsObject:c]) {
                found = YES;
            }
            if (!found) {
                [self.sections setValue:[NSMutableArray new] forKey:c];
            }
            [self.sections[c] addObject:item];
        }
    }
    else if (channelGuideView) {
        addUITableViewIndexSearch = YES;
        BOOL found;
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
                found = NO;
                if ([[self.sections allKeys] containsObject:c]) {
                    found = YES;
                }
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
                                   [self.detailItem mainParameters][choosedTab][0][@"channelid"], @"channelid",
                                   retrievedEPG, @"epgArray",
                                   nil];
        [NSThread detachNewThreadSelector:@selector(backgroundSaveEPGToDisk:) toTarget:self withObject:epgparams];
    }
    else {
        if (sortbymethod && ([self isSortDifferentToDefault] || [self isEligibleForSections:copyRichResults])) {
            BOOL found;
            addUITableViewIndexSearch = YES;
            for (NSDictionary *item in copyRichResults) {
                found = NO;
                NSString *searchKey = @"";
                if ([item[sortbymethod] isKindOfClass:[NSMutableArray class]] || [item[sortbymethod] isKindOfClass:[NSArray class]]) {
                    searchKey = [item[sortbymethod] componentsJoinedByString:@""];
                }
                else {
                    searchKey = item[sortbymethod];
                }
                NSString *key = [self getIndexTableKey:searchKey sortMethod:sortMethodName];
                if ([[self.sections allKeys] containsObject:key]) {
                    found = YES;
                }
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
    BOOL defaultValue = NO;
    if (self.sectionArray.count == 1) {
        defaultValue = YES;
    }
    [self setSortButtonImage:sortAscDesc];
    for (int i = 0; i < self.sectionArray.count; i++) {
        [self.sectionArrayOpen addObject:@(defaultValue)];
    }
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
    enableCollectionView = [self collectionViewIsEnabled];
    numResults = (int)self.richResults.count;
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
    
    NSString *labelText = [self.detailItem mainLabel];
    if (@available(iOS 11.0, *)) {
        self.navigationItem.backButtonTitle = labelText;
        if (!albumView) {
            labelText = [labelText stringByAppendingFormat:@" (%d)", numResults];
        }
    }
    [self setFilternameLabel:labelText runFullscreenButtonCheck:NO forceHide:NO];
    
    if (!self.richResults.count) {
        [self alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
    }
    else {
        [self alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
    }
    NSDictionary *itemSizes = parameters [@"itemSizes"];
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
    [self AnimTable:(UITableView*)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
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
    NSArray* indexPaths = [dataList indexPathsForVisibleRows];
    if ([dataList numberOfSections] > 0 && indexPaths.count > 0) {
        [dataList beginUpdates];
        [dataList reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        [dataList endUpdates];
    }

    indexPaths = [collectionView indexPathsForVisibleItems];
    if ([collectionView numberOfSections] > 0 && indexPaths.count > 0) {
        [collectionView reloadItemsAtIndexPaths:indexPaths];
    }
}

# pragma mark - Life-Cycle

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
    self.navigationController.navigationBar.tintColor = UIColor.lightGrayColor;
    [channelListUpdateTimer invalidate];
    channelListUpdateTimer = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [channelListUpdateTimer invalidate];
    channelListUpdateTimer = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.slidingViewController != nil) {
        [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
        self.slidingViewController.underRightViewController = nil;
        self.slidingViewController.anchorLeftPeekAmount   = 0;
        self.slidingViewController.anchorLeftRevealAmount = 0;
    }
    NSIndexPath* selection = [dataList indexPathForSelectedRow];
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
//    [self brightCells];

    [self choseParams];

    if ([self isModal]) {
        UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissAddAction:)];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
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
        self.navigationController.navigationBar.tintColor = UIColor.lightGrayColor;
    }
    if (isViewDidLoad) {
        [activeLayoutView addSubview:self.searchController.searchBar];
        [self initIpadCornerInfo];
        [self startRetrieveDataWithRefresh:NO];
        isViewDidLoad = NO;
    }
    if (channelListView || channelGuideView) {
        [channelListUpdateTimer invalidate];
        channelListUpdateTimer = nil;
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
    [self setButtonViewContent];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
//    [SDWebImageManager.sharedManager cancelAll];
//    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)buildButtons {
    NSArray *buttons = [self.detailItem mainButtons];
    NSArray *buttonsIB = @[button1, button2, button3, button4, button5];
    UIImage *imageOff = nil;
    UIImage *imageOn = nil;
    UIImage *img = nil;
    CGRect frame;
    NSInteger count = buttons.count;
    count = MIN(count, MAX_NORMAL_BUTTONS);
    choosedTab = MIN(choosedTab, MAX_NORMAL_BUTTONS);
    for (int i = 0; i < count; i++) {
        img = [UIImage imageNamed:buttons[i]];
        imageOff = [Utilities colorizeImage:img withColor:UIColor.lightGrayColor];
        imageOn = [Utilities colorizeImage:img withColor:UIColor.systemBlueColor];
        [buttonsIB[i] setBackgroundImage:imageOff forState:UIControlStateNormal];
        [buttonsIB[i] setBackgroundImage:imageOn forState:UIControlStateSelected];
        [buttonsIB[i] setBackgroundImage:imageOn forState:UIControlStateHighlighted];
        [buttonsIB[i] setEnabled:YES];
    }
    [buttonsIB[choosedTab] setSelected:YES];
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
            imageOff = [Utilities colorizeImage:img withColor:UIColor.lightGrayColor];
            imageOn = [Utilities colorizeImage:img withColor:UIColor.systemBlueColor];
            [buttonsIB.lastObject setBackgroundImage:imageOff forState:UIControlStateNormal];
            [buttonsIB.lastObject setBackgroundImage:imageOn forState:UIControlStateSelected];
            [buttonsIB.lastObject setBackgroundImage:imageOn forState:UIControlStateHighlighted];
            [buttonsIB.lastObject setEnabled:YES];
            selectedMoreTab = [UIButton new];
            break;
    }
}

- (void)checkParamSize:(NSDictionary*)itemSizes viewWidth:(int)fullWidth {
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
    albumViewHeight = 116;
    albumViewPadding = 8;
    if (episodesView) {
        albumViewHeight = 99;
    }
    artistFontSize = 12;
    albumFontSize = 15;
    trackCountFontSize = 11;
    labelPadding = 8;
    cellGridWidth = 105;
    cellGridHeight = 151;
    posterFontSize = 10;
    fanartFontSize = 10;
    [self checkParamSize:itemSizes viewWidth:viewWidth];
}

- (void)setIpadInterface:(NSDictionary*)itemSizes {
    viewWidth = STACKSCROLL_WIDTH;
    // ensure modal views are forced to width = STACKSCROLL_WIDTH, this eases the layout
    CGSize size = CGSizeMake(STACKSCROLL_WIDTH, self.view.frame.size.height);
    self.preferredContentSize = size;
    albumViewHeight = 166;
    if (episodesView) {
        albumViewHeight = 120;
    }
    albumViewPadding = 12;
    artistFontSize = 14;
    albumFontSize = 18;
    trackCountFontSize = 13;
    labelPadding = 8;
    cellGridWidth = 117;
    cellGridHeight = 168;
    fullscreenCellGridWidth = 164;
    fullscreenCellGridHeight = 246;
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
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
    return ([parameters[@"enableCollectionView"] boolValue]);
}

- (BOOL)collectionViewIsEnabled {
    if (![self collectionViewCanBeEnabled]) {
        return NO;
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainMethod][choosedTab]];
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
    return ([parameters[@"enableCollectionView"] boolValue] && [[userDefaults objectForKey:viewKey] boolValue]);
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
    // Hide the toolbar while search is active
    [self hideButtonList:YES];
}

#pragma mark UISearchController Delegate Methods

- (void)initSearchController {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
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
    if (showbar) {
        searchbar.frame = CGRectMake(0, 0, self.view.frame.size.width, searchbar.frame.size.height);
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
    self.indexView.hidden = YES;
}

- (void)willDismissSearchController:(UISearchController*)controller {
    showbar = NO;
    [self showSearchBar];
    [self setCollectionViewIndexVisibility];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [activeLayoutView setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
    }
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {}];
}

- (void)updateSearchResultsForSearchController:(UISearchController*)searchController {
  NSString *searchString = searchController.searchBar.text;
  [self searchForText:searchString];
  [activeLayoutView reloadData];
}

- (void)searchForText:(NSString*)searchText {
    // filter here
    [self.filteredListContent removeAllObjects];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"label CONTAINS[cd] %@", searchText];
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
    serverVersion = AppDelegate.instance.serverVersion;
    serverMinorVersion = AppDelegate.instance.serverMinorVersion;
    libraryCachePath = AppDelegate.instance.libraryCachePath;
    epgCachePath = AppDelegate.instance.epgCachePath;
    SDWebImageDownloader *manager = [SDWebImageManager sharedManager].imageDownloader;
    NSDictionary *httpHeaders = AppDelegate.instance.getServerHTTPHeaders;
    if (httpHeaders[@"Authorization"] != nil) {
        [manager setValue:httpHeaders[@"Authorization"] forHTTPHeaderField:@"Authorization"];
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *hidden_label_preferenceString = [userDefaults objectForKey:@"hidden_label_preference"];
    hiddenLabel = [hidden_label_preferenceString boolValue];
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
    localHourMinuteFormatter = [NSDateFormatter new];
    localHourMinuteFormatter.dateFormat = @"HH:mm";
    localHourMinuteFormatter.timeZone = [NSTimeZone systemTimeZone];
    dataList.tableFooterView = [UIView new];
    
    [self initSearchController];
    self.navigationController.view.backgroundColor = UIColor.blackColor;
    self.definesPresentationContext = NO;
    iOSYDelta = self.searchController.searchBar.frame.size.height;

    [button6 addTarget:self action:@selector(handleChangeLibraryView) forControlEvents:UIControlEventTouchUpInside];

    [button7 addTarget:self action:@selector(handleChangeSortLibrary) forControlEvents:UIControlEventTouchUpInside];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    dataList.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    dataList.sectionIndexBackgroundColor = UIColor.clearColor;
    dataList.sectionIndexColor = UIColor.systemBlueColor;
    dataList.sectionIndexTrackingBackgroundColor = [Utilities getGrayColor:0 alpha:0.3];
    dataList.separatorInset = UIEdgeInsetsMake(0, 53, 0, 0);
    
    CGRect frame = dataList.frame;
    frame.size.height = self.view.bounds.size.height;
    dataList.frame = frame;
    buttonsViewBgToolbar.hidden = NO;
    
    __weak DetailViewController *weakSelf = self;
    [dataList addPullToRefreshWithActionHandler:^{
        [weakSelf startRetrieveDataWithRefresh:YES];
    }];
    [self disableScrollsToTopPropertyOnAllSubviewsOf:self.slidingViewController.view];
    for (UIView *subView in self.searchController.searchBar.subviews) {
        if ([subView isKindOfClass: [UITextField class]]) {
            [(UITextField*)subView setKeyboardAppearance: UIKeyboardAppearanceAlert];
        }
    }
    self.view.userInteractionEnabled = YES;
    choosedTab = 0;
    [self buildButtons]; // TEMP ?
    numTabs = (int)[self.detailItem mainMethod].count;
    if ([self.detailItem chooseTab]) {
        choosedTab = [self.detailItem chooseTab];
    }
    if (choosedTab >= numTabs) {
        choosedTab = 0;
    }
    filterModeType = [self.detailItem currentFilterMode];
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainMethod][choosedTab]];
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
    watchedListenedStrings = parameters[@"watchedListenedStrings"];
    [self checkDiskCache];
    numberOfStars = 10;
    if ([parameters[@"numberOfStars"] intValue] > 0) {
        numberOfStars = [parameters[@"numberOfStars"] intValue];
    }
    
    button6.hidden = YES;
    button7.hidden = YES;
    [self hideButtonListWhenEmpty];

    if ([methods[@"albumView"] boolValue]) {
        albumView = YES;
    }
    else if ([methods[@"episodesView"] boolValue]) {
        episodesView = YES;
        dataList.separatorInset = UIEdgeInsetsMake(0, 18, 0, 0);
    }
    else if ([methods[@"tvshowsView"] boolValue]) {
        tvshowsView = AppDelegate.instance.serverVersion > 11 && !AppDelegate.instance.obj.preferTVPosters;
        [self setTVshowThumbSize];
    }
    else if ([methods[@"channelGuideView"] boolValue]) {
        channelGuideView = YES;
    }
    else if ([methods[@"channelListView"] boolValue]) {
        channelListView = YES;
    }
    
    if ([parameters[@"blackTableSeparator"] boolValue] && !AppDelegate.instance.obj.preferTVPosters) {
        blackTableSeparator = YES;
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
    trackCountLabelWidth = 26;
    epgChannelTimeLabelWidth = 48;
    NSDictionary *itemSizes = parameters[@"itemSizes"];
    if (IS_IPHONE) {
        [self setIphoneInterface:itemSizes[@"iphone"]];
    }
    else {
        [self setIpadInterface:itemSizes[@"ipad"]];
    }
    
    if ([parameters[@"itemSizes"][@"separatorInset"] length]) {
        dataList.separatorInset = UIEdgeInsetsMake(0, [parameters[@"itemSizes"][@"separatorInset"] intValue], 0, 0);
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
        frame.origin.y = UIScreen.mainScreen.bounds.size.height - 44;
    }
    dataList.frame = frame;
    recentlyAddedView = [parameters[@"collectionViewRecentlyAdded"] boolValue];
    enableCollectionView = [self collectionViewIsEnabled];
    if ([self collectionViewCanBeEnabled]) { // TEMP FIX
        [self initCollectionView];
    }
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
    if (IS_IPAD && [self.detailItem enableSection]) {
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
    if (IS_IPAD && [self.detailItem enableSection]) {
        NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
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
            topNavigationLabel.frame = CGRectMake(0, 0, titleView.frame.size.width - fullscreenButton.frame.size.width - (buttonPadding * 2), 44);
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
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL diskcache_preference = NO;
    NSString *diskcache_preferenceString = [userDefaults objectForKey:@"diskcache_preference"];
    if (diskcache_preferenceString == nil || [diskcache_preferenceString boolValue]) {
        diskcache_preference = YES;
    }
    enableDiskCache = diskcache_preference && [parameters[@"enableLibraryCache"] boolValue];
    [dataList setShowsPullToRefresh:enableDiskCache];
    [collectionView setShowsPullToRefresh:enableDiskCache];
}

- (void)handleEnterForeground:(NSNotification*)sender {
    [self checkDiskCache];
}

- (void)handleChangeLibraryView {
    if ([self doesShowSearchResults]) {
        return;
    }
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainMethod][choosedTab]];
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
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
        [userDefaults setObject:@(![[userDefaults objectForKey:viewKey] boolValue])
                         forKey:viewKey];
        enableCollectionView = [self collectionViewIsEnabled];
        recentlyAddedView = [parameters[@"collectionViewRecentlyAdded"] boolValue];
        [UIView animateWithDuration:0.2
                         animations:^{
                             CGRect frame;
                             frame = [activeLayoutView frame];
                             frame.origin.x = viewWidth;
                             ((UITableView*)activeLayoutView).frame = frame;
                             [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                         }
                         completion:^(BOOL finished) {
                             [self configureLibraryView];
                             [self AnimTable:(UITableView*)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
                             [activeLayoutView setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
                         }];
    }
}

- (void)handleChangeSortLibrary {
    selected = nil;
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
    NSDictionary *sortDictionary = parameters[@"available_sort_methods"];
    NSDictionary *item = [NSDictionary dictionaryWithObjectsAndKeys:
                          LOCALIZED_STR(@"Sort by"), @"label",
                          [NSString stringWithFormat:@"\n(%@)", LOCALIZED_STR(@"tap the selection\nto reverse the sort order")], @"genre",
                          nil];
    NSMutableArray *sortOptions = [sortDictionary[@"label"] mutableCopy];
    if (sortMethodIndex != -1) {
        [sortOptions replaceObjectAtIndex:sortMethodIndex withObject:[NSString stringWithFormat:@"\u2713 %@", sortOptions[sortMethodIndex]]];
    }
    [self showActionSheet:nil sheetActions:sortOptions item:item rectOriginX:[button7 convertPoint:button7.center toView:buttonsView.superview].x rectOriginY:buttonsView.center.y - (button7.frame.size.height/2)];
}

- (void)handleLongPressSortButton:(UILongPressGestureRecognizer*)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[self.detailItem mainParameters][choosedTab]];
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
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}
							
@end
