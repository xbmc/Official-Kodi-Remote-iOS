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
//#import "UIImageView+WebCache.h"
#import "GlobalData.h"
#import "ShowInfoViewController.h"
#import "DetailViewController.h"
#import "NowPlaying.h"
#import "PlayFileViewController.h"
//#import <MediaPlayer/MediaPlayer.h>
#import "SDImageCache.h"
#import "WebViewController.h"
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
#import "UISearchBar+LeftButton.h"
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
@synthesize detailViewController;
@synthesize nowPlaying;
@synthesize showInfoViewController;
@synthesize playFileViewController;
@synthesize filteredListContent;
@synthesize richResults;
@synthesize webViewController;
@synthesize sectionArray;
@synthesize sectionArrayOpen;
//@synthesize detailDescriptionLabel = _detailDescriptionLabel;
#define SECTIONS_START_AT 100
#define SHOW_ONLY_VISIBLE_THUMBNAIL_START_AT 50
#define MAX_NORMAL_BUTTONS 4
#define WARNING_TIMEOUT 30.0f
#define COLLECTION_HEADER_HEIGHT 16

- (id)initWithFrame:(CGRect)frame {
    if (self = [super init]) {
		[self.view setFrame:frame]; 
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil withItem:(mainMenu *)item withFrame:(CGRect)frame bundle:(NSBundle *)nibBundleOrNil{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.detailItem = item;
        [self.view setFrame:frame];
    }
    return self;
}

- (NSString *)convertTimeFromSeconds:(NSNumber *)seconds {
    NSString *result = @"";    
    int secs = [seconds intValue];
    int tempHour    = 0;
    int tempMinute  = 0;
    int tempSecond  = 0;
    NSString *hour      = @"";
    NSString *minute    = @"";
    NSString *second    = @"";    
    tempHour    = secs / 3600;
    tempMinute  = secs / 60 - tempHour * 60;
    tempSecond  = secs - (tempHour * 3600 + tempMinute * 60);
    hour    = [[NSNumber numberWithInt:tempHour] stringValue];
    minute  = [[NSNumber numberWithInt:tempMinute] stringValue];
    second  = [[NSNumber numberWithInt:tempSecond] stringValue];
    if (tempHour < 10) {
        hour = [@"0" stringByAppendingString:hour];
    } 
    if (tempMinute < 10) {
        minute = [@"0" stringByAppendingString:minute];
    }
    if (tempSecond < 10) {
        second = [@"0" stringByAppendingString:second];
    }
    if (tempHour == 0) {
        result = [NSString stringWithFormat:@"%@:%@", minute, second];
        
    } else {
        result = [NSString stringWithFormat:@"%@:%@:%@",hour, minute, second];
    }
    return result;    
}

- (NSDictionary *) indexKeyedDictionaryFromArray:(NSArray *)array {
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    NSInteger numelement=[array count];
    for (int i=0;i<numelement-1;i+=2){
        [mutableDictionary setObject:[array objectAtIndex:i] forKey:[array objectAtIndex:i+1]];
    }
    return (NSDictionary *)mutableDictionary;
}

- (NSMutableDictionary *) indexKeyedMutableDictionaryFromArray:(NSArray *)array {
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    NSInteger numelement=[array count];
    for (int i=0;i<numelement-1;i+=2){
        [mutableDictionary setObject:[array objectAtIndex:i] forKey:[array objectAtIndex:i+1]];
    }
    return (NSMutableDictionary *)mutableDictionary;
}

#pragma mark - live tv epg memory/disk cache management

-(NSMutableArray *)loadEPGFromMemory:(NSNumber *)channelid {
    return [epgDict objectForKey:channelid];
}

-(NSMutableArray *)loadEPGFromDisk:(NSNumber *)channelid parameters:(NSDictionary *)params{
    NSString *documentsDirectory = [AppDelegate instance].epgCachePath;
    NSString *epgKey = [self getCacheKey:@"EPG" parameters:nil];
    NSString *filename = [NSString stringWithFormat:@"%@-%@.epg.dat", epgKey, channelid];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];
    NSMutableArray *epgArray;
    epgArray = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    if (epgArray != nil) {
        [epgDict setObject:epgArray forKey:channelid];
//        // UPDATE DISK CACHE
//        if (![epgDownloadQueue containsObject:channelid]){
//            @synchronized(epgDownloadQueue){
//                [epgDownloadQueue addObject:channelid];
//            }
//            [self performSelectorOnMainThread:@selector(getJsonEPG:) withObject:params waitUntilDone:NO];
//        }
    }
    return epgArray;
}

-(void)backgroundSaveEPGToDisk:(NSDictionary *)parameters{
    NSNumber *channelid = [parameters objectForKey:@"channelid"];
    NSMutableArray *epgData = [parameters objectForKey:@"epgArray"];
    [self saveEPGToDisk:channelid epgData:epgData];
}

-(void)saveEPGToDisk:(NSNumber *)channelid epgData:(NSMutableArray *)epgArray{
    if (epgArray != nil && channelid != nil && [epgArray count] > 0){
        NSString *diskCachePath = [AppDelegate instance].epgCachePath;
        NSString *epgKey = [self getCacheKey:@"EPG" parameters:nil];
        NSString *filename = [NSString stringWithFormat:@"%@-%@.epg.dat", epgKey, channelid];
        NSString  *dicPath = [diskCachePath stringByAppendingPathComponent:filename];
        @synchronized(epgArray){
            [NSKeyedArchiver archiveRootObject:epgArray toFile:dicPath];
            [epgDict setObject:epgArray forKey:channelid];
        }
        @synchronized(epgDownloadQueue){
            [epgDownloadQueue removeObject:channelid];
        }
    }
    return;
}

#pragma mark - live tv epg management

-(void)getChannelEpgInfo:(NSDictionary *)parameters {
    NSNumber *channelid = [parameters objectForKey:@"channelid"];
    NSIndexPath *indexPath = [parameters objectForKey:@"indexPath"];
    UITableView *tableView = [parameters objectForKey:@"tableView"];
    NSMutableDictionary *item = [parameters objectForKey:@"item"];
    NSMutableDictionary *channelEPG = nil;
    if ([channelid intValue] > 0){
        NSMutableArray *retrievedEPG = nil;
        retrievedEPG = [self loadEPGFromMemory:channelid];
        channelEPG = [self parseEpgData:retrievedEPG];
        NSDictionary *epgparams = [NSDictionary dictionaryWithObjectsAndKeys:
                                   channelEPG, @"channelEPG",
                                   indexPath, @"indexPath",
                                   tableView, @"tableView",
                                   item, @"item",
                                   nil];
        [self performSelectorOnMainThread:@selector(updateEpgTableInfo:) withObject:epgparams waitUntilDone:NO];
        if ([[channelEPG objectForKey:@"refresh_data"] boolValue] == YES){
            retrievedEPG = [self loadEPGFromDisk:channelid parameters:parameters];
            channelEPG = [self parseEpgData:retrievedEPG];
            NSDictionary *epgparams = [NSDictionary dictionaryWithObjectsAndKeys:
                                       channelEPG, @"channelEPG",
                                       indexPath, @"indexPath",
                                       tableView, @"tableView",
                                       item, @"item",
                                       nil];
            [self performSelectorOnMainThread:@selector(updateEpgTableInfo:) withObject:epgparams waitUntilDone:NO];
            BOOL alreadyInDownloadQueue = FALSE;
            @synchronized(epgDownloadQueue){
                alreadyInDownloadQueue = [epgDownloadQueue containsObject:channelid];
            }
            if ([[channelEPG objectForKey:@"refresh_data"] boolValue] == YES && !alreadyInDownloadQueue){
                @synchronized(epgDownloadQueue){
                    [epgDownloadQueue addObject:channelid];
                }
                [self performSelectorOnMainThread:@selector(getJsonEPG:) withObject:parameters waitUntilDone:NO];
            }
        }
    }
    return;
}

-(NSMutableDictionary *)parseEpgData:(NSMutableArray *)epgData {
    NSMutableDictionary *channelEPG = [[NSMutableDictionary alloc] init];
    [channelEPG setObject: NSLocalizedString(@"Not Available",nil) forKey:@"current"];
    [channelEPG setObject: NSLocalizedString(@"Not Available",nil) forKey:@"next"];
    [channelEPG setObject: @"" forKey:@"current_details"];
    [channelEPG setObject: [NSNumber numberWithBool:YES] forKey:@"refresh_data"];
    [channelEPG setObject: @"" forKey:@"starttime"];
    [channelEPG setObject: @"" forKey:@"endtime"];
    if (epgData != nil) {
        NSDictionary *objectToSearch;
        NSDate *nowDate = [NSDate date];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"starttime <= %@ AND endtime >= %@", nowDate, nowDate];
        NSArray *filteredArray = [epgData filteredArrayUsingPredicate:predicate];
        if ([filteredArray count] > 0) {
            objectToSearch = [filteredArray objectAtIndex:0];
            [channelEPG setObject: [objectToSearch objectForKey:@"starttime"] forKey:@"starttime"];
            [channelEPG setObject: [objectToSearch objectForKey:@"endtime"] forKey:@"endtime"];
            [channelEPG setObject: [NSString stringWithFormat:@"%@ %@",
                                    [localHourMinuteFormatter stringFromDate:[objectToSearch objectForKey:@"starttime"]],
                                    [objectToSearch objectForKey:@"title"]
                                    ] forKey:@"current"];
            NSCalendar *gregorian = [[NSCalendar alloc]
                                     initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSUInteger unitFlags = NSCalendarUnitMinute;
            NSDateComponents *components = [gregorian components:unitFlags
                                                        fromDate:[objectToSearch objectForKey:@"starttime"]
                                                          toDate:[objectToSearch objectForKey:@"endtime"] options:0];
            NSInteger minutes = [components minute];
            NSString *plotoutline = [objectToSearch objectForKey:@"plotoutline"];
            if (!plotoutline || [plotoutline isKindOfClass:[NSNull class]] || [[objectToSearch objectForKey:@"plot"] isEqualToString:plotoutline]) {
                plotoutline = @"";
            }
            [channelEPG setObject: [NSString stringWithFormat:@"\n%@\n%@\n%@\n\n%@ - %@ (%ld %@)",
                                    [objectToSearch objectForKey:@"title"],
                                    [plotoutline length] > 0 ? [NSString stringWithFormat:@"%@\n",plotoutline] : @"",
                                    [objectToSearch objectForKey:@"plot"],
                                    [localHourMinuteFormatter stringFromDate:[objectToSearch objectForKey:@"starttime"]],
                                    [localHourMinuteFormatter stringFromDate:[objectToSearch objectForKey:@"endtime"]],
                                    (long)minutes,
                                    (long)minutes > 1 ? NSLocalizedString(@"Mins.", nil) : NSLocalizedString(@"Min", nil)
                                    ] forKey:@"current_details"];
            predicate = [NSPredicate predicateWithFormat:@"starttime >= %@", [objectToSearch objectForKey:@"endtime"]];
            NSArray *nextFilteredArray = [epgData filteredArrayUsingPredicate:predicate];
            if ([nextFilteredArray count] > 0) {
//                NSSortDescriptor *sortDescriptor;
//                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"starttime"
//                                                             ascending:YES];
//                NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
//                NSArray *sortedArray;
//                sortedArray = [nextFilteredArray sortedArrayUsingDescriptors:sortDescriptors];
                [channelEPG setObject: [NSString stringWithFormat:@"%@ %@",
                                        [localHourMinuteFormatter stringFromDate:[[nextFilteredArray objectAtIndex:0] objectForKey:@"starttime"]],
                                        [[nextFilteredArray objectAtIndex:0] objectForKey:@"title"]
                                        ] forKey:@"next"];
                [channelEPG setObject: [NSNumber numberWithBool:NO] forKey:@"refresh_data"];
            }
        }
    }
    return channelEPG;
}

-(void)updateEpgTableInfo:(NSDictionary *)parameters{
    NSMutableDictionary *channelEPG = [parameters objectForKey:@"channelEPG"];
    NSIndexPath *indexPath = [parameters objectForKey:@"indexPath"];
    UITableView *tableView = [parameters objectForKey:@"tableView"];
    NSMutableDictionary *item = [parameters objectForKey:@"item"];
    UITableViewCell *cell = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView){
        cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
    }
    else{
        cell = [dataList cellForRowAtIndexPath:indexPath];
    }
    UILabel *current = (UILabel*) [cell viewWithTag:2];
    UILabel *next = (UILabel*) [cell viewWithTag:4];
    current.text = [channelEPG objectForKey:@"current"];
    next.text = [channelEPG objectForKey:@"next"];
    [item setObject:[channelEPG objectForKey:@"current_details"] forKey:@"genre"];
    ProgressPieView *progressView = (ProgressPieView*) [cell viewWithTag:103];
    if (![current.text isEqualToString:NSLocalizedString(@"Not Available",nil)] && [[channelEPG objectForKey:@"starttime"] isKindOfClass:[NSDate class]] && [[channelEPG objectForKey:@"endtime"] isKindOfClass:[NSDate class]]) {
        float total_seconds = [[channelEPG objectForKey:@"endtime"] timeIntervalSince1970] - [[channelEPG objectForKey:@"starttime"] timeIntervalSince1970];
        float elapsed_seconds = [[NSDate date] timeIntervalSince1970] - [[channelEPG objectForKey:@"starttime"] timeIntervalSince1970];
        float percent_elapsed = (elapsed_seconds/total_seconds) * 100.0f;
        [progressView updateProgressPercentage:percent_elapsed];
        progressView.hidden = NO;
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSUInteger unitFlags = NSCalendarUnitMinute;
        NSDateComponents *components = [gregorian components:unitFlags
                                                    fromDate:[channelEPG objectForKey:@"starttime"]
                                                      toDate:[channelEPG objectForKey:@"endtime"] options:0];
        NSInteger minutes = [components minute];
        progressView.pieLabel.text = [NSString stringWithFormat:@" %ld'", (long)minutes];
    }
    else {
        progressView.hidden = YES;
    }
}

-(void)parseBroadcasts:(NSDictionary *)parameters{
    NSArray *broadcasts = [parameters objectForKey:@"broadcasts"];
    NSNumber *channelid = [parameters objectForKey:@"channelid"];
    NSIndexPath *indexPath = [parameters objectForKey:@"indexPath"];
    UITableView *tableView = [parameters objectForKey:@"tableView"];
    NSMutableDictionary *item = [parameters objectForKey:@"item"];
    NSMutableArray *retrievedEPG = [[NSMutableArray alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];

    for (id EPGobject in broadcasts) {
        NSDate *starttime = [dateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", [EPGobject objectForKey:@"starttime"]]];// all times in XBMC PVR are UTC
        NSDate *endtime = [dateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", [EPGobject objectForKey:@"endtime"]]];// all times in XBMC PVR are UTC
        [retrievedEPG addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                 starttime, @"starttime",
                                 endtime, @"endtime",
                                 [EPGobject objectForKey:@"title"], @"title",
                                 [EPGobject objectForKey:@"label"], @"label",
                                 [EPGobject objectForKey:@"plot"], @"plot",
                                 [EPGobject objectForKey:@"plotoutline"], @"plotoutline",
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

-(void)getJsonEPG:(NSDictionary *)parameters{
    NSNumber *channelid = [parameters objectForKey:@"channelid"];
    NSIndexPath *indexPath = [parameters objectForKey:@"indexPath"];
    UITableView *tableView = [parameters objectForKey:@"tableView"];
    NSMutableDictionary *item = [parameters objectForKey:@"item"];
    if (jsonRPC == nil){
        jsonRPC = nil;
        jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    }
    [jsonRPC callMethod:@"PVR.GetBroadcasts"
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                         channelid, @"channelid",
                         [[NSArray alloc] initWithObjects:@"title", @"starttime", @"endtime", @"plot", @"plotoutline", nil], @"properties",
                         nil]
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               if (error==nil && methodError==nil && [methodResult isKindOfClass: [NSDictionary class]]){
                   if (((NSNull *)[methodResult objectForKey:@"broadcasts"] != [NSNull null])){
                       
                       NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                               channelid, @"channelid",
                                               indexPath, @"indexPath",
                                               tableView, @"tableView",
                                               item, @"item",
                                               [methodResult objectForKey:@"broadcasts"], @"broadcasts",
                                               nil];
                       [NSThread detachNewThreadSelector:@selector(parseBroadcasts:) toTarget:self withObject:params];
                   }
               }
//               else{
//                   NSLog(@"method error %@ %@", methodError, error);
//               }
           }];
}

#pragma mark - library disk cache management

-(NSString *)getCacheKey:(NSString *)fieldA parameters:(NSMutableDictionary *)fieldB{
    GlobalData *obj=[GlobalData getInstance];
//    if ([[fieldB objectForKey:@"sort"] respondsToSelector:@selector(removeObjectForKey:)]){
//        [[fieldB objectForKey:@"sort"] removeObjectForKey:@"available_methods"];
//    }
    return [[NSString stringWithFormat:@"%@%@%@%d%d%@%@", obj.serverIP, obj.serverPort, obj.serverDescription, [AppDelegate instance].serverVersion, [AppDelegate instance].serverMinorVersion, fieldA, fieldB] MD5String];
}

-(void)saveData:(NSMutableDictionary *)mutableParameters{
    if (!enableDiskCache) return;
    if (mutableParameters != nil){
        NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[self.detailItem mainMethod] objectAtIndex:choosedTab]];
        NSString *viewKey = [self getCacheKey:[methods objectForKey:@"method"] parameters:mutableParameters];
        NSString *diskCachePath = [AppDelegate instance].libraryCachePath;
//        if ([paths count] > 0) {
        

            NSString *filename = [NSString stringWithFormat:@"%@.richResults.dat", viewKey];
            NSString  *dicPath = [diskCachePath stringByAppendingPathComponent:filename];
            [NSKeyedArchiver archiveRootObject:self.richResults toFile:dicPath];
            [self updateSyncDate:dicPath];

//            filename = [NSString stringWithFormat:@"%@.sections.dat", viewKey];
//            dicPath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:fullNamespace] stringByAppendingPathComponent:filename];
//            [NSKeyedArchiver archiveRootObject:self.sections toFile:dicPath];
//            
//            filename = [NSString stringWithFormat:@"%@.sectionArray.dat", viewKey];
//            dicPath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:fullNamespace] stringByAppendingPathComponent:filename];
//            
//            [NSKeyedArchiver archiveRootObject:self.sectionArray toFile:dicPath];
//            
//            filename = [NSString stringWithFormat:@"%@.sectionArrayOpen.dat", viewKey];
//            dicPath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:fullNamespace] stringByAppendingPathComponent:filename];
//            [NSKeyedArchiver archiveRootObject:self.sectionArrayOpen toFile:dicPath];
//            
            filename = [NSString stringWithFormat:@"%@.extraSectionRichResults.dat", viewKey];
            dicPath = [diskCachePath stringByAppendingPathComponent:filename];
            [NSKeyedArchiver archiveRootObject:self.extraSectionRichResults toFile:dicPath];
//        }
    }
}

-(void)loadDataFromDisk:(NSDictionary*)params{
    NSString *viewKey = [self getCacheKey:[params objectForKey:@"methodToCall"] parameters:[params objectForKey:@"mutableParameters"]];    
    NSString *documentsDirectory = [AppDelegate instance].libraryCachePath;
    NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.richResults.dat", viewKey]];
    NSMutableArray *tempArray;
//    NSMutableDictionary *tempDict;
    self.richResults = nil;
//    self.sections = nil;
    self.sectionArray = nil;
    self.sectionArrayOpen = nil;
    self.extraSectionRichResults = nil;
    
    self.sections = [[NSMutableDictionary alloc] init];
    
    tempArray = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    [self setRichResults:tempArray];
    
//    path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sections.dat", viewKey]];
//    tempDict = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
//    [self setSections:tempDict];
//    
//    path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sectionArray.dat", viewKey]];
//    tempArray = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
//    [self setSectionArray:tempArray];
//    
//    path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sectionArrayOpen.dat", viewKey]];
//    tempArray = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
//    [self setSectionArrayOpen:tempArray];
//    
    path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.extraSectionRichResults.dat", viewKey]];
    tempArray = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    [self setExtraSectionRichResults:tempArray];
    
    storeRichResults = [self.richResults mutableCopy];
    [self performSelectorOnMainThread:@selector(indexAndDisplayData) withObject:nil waitUntilDone:YES];
}

-(BOOL)loadedDataFromDisk:(NSString *)methodToCall parameters:(NSMutableDictionary*)mutableParameters refresh:(BOOL)forceRefresh{
    if (forceRefresh) return NO;
    if (!enableDiskCache) return NO;
    NSString *viewKey = [self getCacheKey:methodToCall parameters:mutableParameters];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = [AppDelegate instance].libraryCachePath;
    NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.richResults.dat", viewKey]];
    if([fileManager fileExistsAtPath:path]){
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

-(void)updateSyncDate:(NSString *)filePath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:filePath]){
        NSError *attributesRetrievalError = nil;
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:&attributesRetrievalError];
        if (attributes){
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterLongStyle];
            [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
            NSLocale *userLocale = [[NSLocale alloc] initWithLocaleIdentifier:NSLocalizedString(@"LocaleIdentifier",nil)];
            [dateFormatter setLocale:userLocale];
            NSString *dateString = [dateFormatter stringFromDate:[attributes fileModificationDate]];
            NSString *title = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Last sync", nil),dateString];
            [dataList.pullToRefreshView setSubtitle:title forState: SVPullToRefreshStateStopped];
            [dataList.pullToRefreshView setSubtitle:title forState: SVPullToRefreshStateTriggered];
            [collectionView.pullToRefreshView setSubtitle:title forState: SVPullToRefreshStateStopped];
            [collectionView.pullToRefreshView setSubtitle:title forState: SVPullToRefreshStateTriggered];
        }
    }
}

#pragma mark - Utility

-(void)toggleOpen:(UITapGestureRecognizer *)sender {
    NSInteger section = [sender.view tag];
    [self.sectionArrayOpen replaceObjectAtIndex:section withObject:[NSNumber numberWithBool:![[self.sectionArrayOpen objectAtIndex:section] boolValue]]];
    NSInteger countEpisodes = [[self.sections valueForKey:[self.sectionArray objectAtIndex:section]] count];
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < countEpisodes; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
    }
    UIButton *toggleButton = (UIButton *)[sender.view viewWithTag:99];
    if ([[self.sectionArrayOpen objectAtIndex:section] boolValue]){
        [dataList beginUpdates];
        [dataList insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [dataList endUpdates];
        [toggleButton setSelected:YES];
        NSIndexPath *indexPathToScroll = [NSIndexPath indexPathForRow:0 inSection:section];
        [dataList scrollToRowAtIndexPath:indexPathToScroll atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else{
        [toggleButton setSelected:NO];
        NSIndexPath *indexPathToScroll = [NSIndexPath indexPathForRow:0 inSection:section];
        [dataList scrollToRowAtIndexPath:indexPathToScroll atScrollPosition:UITableViewScrollPositionTop animated:NO];
        [dataList beginUpdates];
        [dataList deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [dataList endUpdates];
        if (section>0){
            //            NSIndexPath *indexPathToScroll = [NSIndexPath indexPathForRow:NSNotFound inSection:section];
            //            [dataList scrollToRowAtIndexPath:indexPathToScroll atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            CGRect sectionRect = [dataList rectForSection:section - 1];
            [dataList scrollRectToVisible:sectionRect animated:YES];
        }
    }
}

-(void)goBack:(id)sender{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        [self.navigationController popViewControllerAnimated:YES];
    }
    else{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationEnableStackPan" object: nil];
    }
}

- (UIImage*)imageWithShadow:(UIImage *)source shadowRadius:(int)shadowRadius {
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef shadowContext = CGBitmapContextCreate(NULL, source.size.width + shadowRadius * 2, source.size.height + shadowRadius * 2, CGImageGetBitsPerComponent(source.CGImage), 0, colourSpace, kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colourSpace);
    
    CGContextSetShadowWithColor(shadowContext, CGSizeMake(0, 0), shadowRadius, [UIColor blackColor].CGColor);
    CGContextDrawImage(shadowContext, CGRectMake(shadowRadius, shadowRadius, source.size.width, source.size.height), source.CGImage);
    
    CGImageRef shadowedCGImage = CGBitmapContextCreateImage(shadowContext);
    CGContextRelease(shadowContext);
    
    UIImage * shadowedImage = [UIImage imageWithCGImage:shadowedCGImage];
    CGImageRelease(shadowedCGImage);
    
    return shadowedImage;
}

- (UIImage*)imageWithBorderFromImage:(UIImage*)source shadowRadius:(int)shadowRadius{
    CGSize size = [source size];
    UIGraphicsBeginImageContext(size);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    [source drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
    CGFloat borderWidth = 2.0f;
	CGContextSetLineWidth(context, borderWidth);
    CGContextStrokeRect(context, rect);
    
    UIImage *Img =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [self imageWithShadow:Img shadowRadius:shadowRadius];
}

-(void)elaborateImage:(UIImage *)image shadowRadius:(int)shadowRadius destination:(UIImageView *)imageViewDestination{
    UIImage *elabImage = [self imageWithBorderFromImage:image shadowRadius:shadowRadius];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:elabImage, @"image", imageViewDestination, @"destinationView", nil];
    [self performSelectorOnMainThread:@selector(showImage:) withObject:params waitUntilDone:YES];
}

-(void)showImage:(NSDictionary *)params{
    UIImage *image = [params objectForKey:@"image"];
    UIImageView *destinationView = [params objectForKey:@"destinationView"];
    destinationView.image = image;
    [self alphaView:destinationView AnimDuration:0.1 Alpha:1.0f];
}

#pragma mark - Tabbar management

-(IBAction)showMore:(id)sender{
//    if ([sender tag]==choosedTab) return;
    self.indexView.hidden = YES;
    [self alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
    [activityIndicatorView startAnimating];
    NSArray *buttonsIB=[NSArray arrayWithObjects:button1, button2, button3, button4, button5, nil];
    if (choosedTab<[buttonsIB count]){
        [[buttonsIB objectAtIndex:choosedTab] setSelected:NO];
    }
    choosedTab=MAX_NORMAL_BUTTONS;
    [[buttonsIB objectAtIndex:choosedTab] setSelected:YES];
    [self AnimTable:(UITableView *)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:viewWidth];
    int i;
    NSInteger count = [[self.detailItem mainParameters] count];
    NSMutableArray *mainMenu = [[NSMutableArray alloc] init];
    NSInteger numIcons = [[self.detailItem mainButtons] count];
    for (i = MAX_NORMAL_BUTTONS; i < count; i++){
        NSString *icon = @"";
        if (i < numIcons){
            icon = [[self.detailItem mainButtons] objectAtIndex:i];
        }
        [mainMenu addObject: 
         [NSDictionary dictionaryWithObjectsAndKeys:
          [NSString stringWithFormat:@"%@",[[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:i]] objectForKey:@"morelabel"]], @"label", 
          icon, @"icon",
          nil]];
    }
    if (moreItemsViewController == nil){
        moreItemsViewController = [[MoreItemsViewController alloc] initWithFrame:CGRectMake(dataList.bounds.size.width, 0, dataList.bounds.size.width, dataList.bounds.size.height) mainMenu:mainMenu];
        [moreItemsViewController.view setBackgroundColor:[UIColor clearColor]];
        [moreItemsViewController viewWillAppear:FALSE];
        [moreItemsViewController viewDidAppear:FALSE];
        UIEdgeInsets tableViewInsets = UIEdgeInsetsZero;
        tableViewInsets.bottom = 44;
        tableViewInsets.top = CGRectGetMaxY(self.navigationController.navigationBar.frame);
        moreItemsViewController.tableView.contentInset = tableViewInsets;
        moreItemsViewController.tableView.scrollIndicatorInsets = tableViewInsets;
        [moreItemsViewController.tableView setContentOffset:CGPointMake(0, - tableViewInsets.top) animated:NO];
        [detailView insertSubview:moreItemsViewController.view aboveSubview:dataList];
    }

    [self AnimView:moreItemsViewController.view AnimDuration:0.3 Alpha:1.0 XPos:0];
    self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"More (%d)", nil), (count - MAX_NORMAL_BUTTONS)];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        topNavigationLabel.alpha = 0;
        [UIView commitAnimations];
        topNavigationLabel.text = [NSString stringWithFormat:NSLocalizedString(@"More (%d)", nil), (count - MAX_NORMAL_BUTTONS)];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        topNavigationLabel.alpha = 1;
        [self checkFullscreenButton:YES];
        [UIView commitAnimations];
    }
    [activityIndicatorView stopAnimating];
}


- (void) handleTabHasChanged:(NSNotification*) notification{
    NSArray *buttons=[self.detailItem mainButtons];
    if (![buttons count]) return;
    NSIndexPath *choice=notification.object;
    choosedTab = 0;
    NSInteger selectedIdx = MAX_NORMAL_BUTTONS + choice.row;
    selectedMoreTab.tag=selectedIdx;
    [self changeTab:selectedMoreTab];
}

-(void)changeViewMode:(int)newWatchMode forceRefresh:(BOOL)refresh{
    [activityIndicatorView startAnimating];
    if (!refresh){
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
            [UIView transitionWithView: activeLayoutView
                              duration: 0.2
                               options: UIViewAnimationOptionBeginFromCurrentState
                            animations: ^ {
                                [(UITableView *)activeLayoutView setAlpha:1.0];
                                CGRect frame;
                                frame = [activeLayoutView frame];
                                frame.origin.x = viewWidth;
                                frame.origin.y = 0;
                                [(UITableView *)activeLayoutView setFrame:frame];
                            }
                            completion:^(BOOL finished){
                                [self changeViewMode:newWatchMode];
                            }];
        }
        else{
            [self AnimTable:(UITableView *)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:viewWidth];
            [self changeViewMode:newWatchMode];
        }
    }
    else{
        [self changeViewMode:newWatchMode];
    }
    return;
}

-(void)changeViewMode:(int)newWatchMode {
    NSArray *buttonsIB=[NSArray arrayWithObjects:button1, button2, button3, button4, button5, nil];
    [[buttonsIB objectAtIndex:choosedTab] setImage:[UIImage imageNamed:[[[[self.detailItem watchModes] objectAtIndex:choosedTab] objectForKey:@"icons"] objectAtIndex:newWatchMode]] forState:UIControlStateSelected];
    [self.richResults removeAllObjects];
    [self.sections removeAllObjects];
    [activeLayoutView reloadData];
    self.richResults = [storeRichResults mutableCopy];
    NSInteger total = [self.richResults count];
    NSMutableIndexSet *mutableIndexSet = [[NSMutableIndexSet alloc] init];
    switch (newWatchMode) {
        case 0:
            break;
            
        case 1:
            for (int i = 0; i < total; i++){
                if ([[[self.richResults objectAtIndex:i] objectForKey:@"playcount"] intValue] > 0){
                    [mutableIndexSet addIndex:i];
                }
            }
            [self.richResults removeObjectsAtIndexes:mutableIndexSet];
            break;

        case 2:
            for (int i = 0; i < total; i++){
                if ([[[self.richResults objectAtIndex:i] objectForKey:@"playcount"] intValue] == 0){
                    [mutableIndexSet addIndex:i];
                }
            }
            [self.richResults removeObjectsAtIndexes:mutableIndexSet];
            break;
            
        default:
            break;
    }
    [self indexAndDisplayData];
    
}

-(void)configureLibraryView{
    UISearchBarLeftButton *bar = (UISearchBarLeftButton *)self.searchDisplayController.searchBar;
    if (enableCollectionView){
        [self initCollectionView];
        if (longPressGesture == nil){
            longPressGesture = [UILongPressGestureRecognizer new];
            [longPressGesture addTarget:self action:@selector(handleLongPress)];
        }
        [collectionView addGestureRecognizer:longPressGesture];
        [dataList setDelegate:nil];
        [dataList setDataSource:nil];
        [collectionView setDelegate:self];
        [collectionView setDataSource:self];
        [dataList setScrollsToTop:NO];
        [collectionView setScrollsToTop:YES];
        activeLayoutView = collectionView;
        self.indexView.hidden = YES;
        if ([self.indexView.indexTitles count]>1){
            self.indexView.hidden = NO;
        }
        self.searchDisplayController.searchBar.tintColor = collectionViewSearchBarColor;
        [self.searchDisplayController.searchBar setBackgroundColor:collectionViewSearchBarColor];
        self.searchDisplayController.searchBar.tintColor = [utils lighterColorForColor:collectionViewSearchBarColor];
        searchBarColor = collectionViewSearchBarColor;
        [bar.leftButton setImage:[UIImage imageNamed:@"button_view"] forState:UIControlStateNormal];
    }
    else{
        [dataList setDelegate:self];
        [dataList setDataSource:self];
        [collectionView setDelegate:nil];
        [collectionView setDataSource:nil];
        [dataList setScrollsToTop:YES];
        [collectionView setScrollsToTop:NO];
        activeLayoutView = dataList;
        self.indexView.hidden = YES;
        self.searchDisplayController.searchBar.tintColor = tableViewSearchBarColor;
        [self.searchDisplayController.searchBar setBackgroundColor:tableViewSearchBarColor];
        self.searchDisplayController.searchBar.tintColor = [utils lighterColorForColor:tableViewSearchBarColor];
        searchBarColor = tableViewSearchBarColor;
        [bar.leftButton setImage:[UIImage imageNamed:@"button_view_list"] forState:UIControlStateNormal];
    }
    if (!isViewDidLoad){
        [activeLayoutView addSubview:self.searchDisplayController.searchBar];
    }
}

-(void)setUpSort:(UISearchBarLeftButton *)bar methods:(NSDictionary *)methods parameters:(NSDictionary *)parameters{
    [bar showSortButton:YES];
    NSDictionary *sortDictionary = [[[parameters objectForKey:@"parameters"] objectForKey:@"sort"] objectForKey:@"available_methods"];
    sortMethodName = [self getCurrentSortMethod:methods withParameters:parameters];
    NSUInteger foundIndex = [[sortDictionary objectForKey:@"method"] indexOfObject:sortMethodName];
    if (foundIndex != NSNotFound){
        sortMethodIndex = foundIndex;
    }
    sortAscDesc = [self getCurrentSortAscDesc:methods withParameters:parameters];
}

-(IBAction)changeTab:(id)sender{
    if (activityIndicatorView.hidden == NO) return;
    [activeLayoutView setUserInteractionEnabled:YES];
    [((UITableView *)activeLayoutView).pullToRefreshView stopAnimating];
    if ([sender tag]==choosedTab) {
        NSArray *watchedCycle = [self.detailItem watchModes];
        NSInteger num_modes = [[[watchedCycle objectAtIndex:choosedTab] objectForKey:@"modes"] count];
        if (num_modes){
            if (watchMode < num_modes - 1){
                watchMode ++;
            }
            else {
                watchMode = 0;
            }
            [self changeViewMode:watchMode forceRefresh:FALSE];
            return;
        }
        else {
            return;
        }
    }
    self.indexView.indexTitles = nil;
    self.indexView.hidden = YES;
    NSArray *buttonsIB=[NSArray arrayWithObjects:button1, button2, button3, button4, button5, nil];
    if (choosedTab < [buttonsIB count]){
        [[buttonsIB objectAtIndex:choosedTab] setImage:[UIImage imageNamed:@""] forState:UIControlStateSelected];
    }
    watchMode = 0;
    startTime = 0;
    [countExecutionTime invalidate];
    countExecutionTime = nil;
    if (longTimeout!=nil){
        [longTimeout removeFromSuperview];
        longTimeout = nil;
    }
    [self AnimView:moreItemsViewController.view AnimDuration:0.3 Alpha:1.0 XPos:viewWidth];
    numTabs = (int)[[self.detailItem mainMethod] count];
    int newChoosedTab = (int)[sender tag];
    if (newChoosedTab>=numTabs){
        newChoosedTab=0;
    }
    if (newChoosedTab==choosedTab) return;
    [activityIndicatorView startAnimating];
    if (choosedTab<[buttonsIB count]){
        [[buttonsIB objectAtIndex:choosedTab] setSelected:NO];
    }
    else {
        [[buttonsIB objectAtIndex:MAX_NORMAL_BUTTONS] setSelected:NO];
    }
    choosedTab = newChoosedTab;
    if (choosedTab<[buttonsIB count]){
        [[buttonsIB objectAtIndex:choosedTab] setSelected:YES];
    }
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[self.detailItem mainMethod] objectAtIndex:choosedTab]];
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    if ([[parameters objectForKey:@"numberOfStars"] intValue] > 0){
        numberOfStars = [[parameters objectForKey:@"numberOfStars"] intValue];
    }

    BOOL newEnableCollectionView = [self collectionViewIsEnabled];
    UISearchBarLeftButton *bar = (UISearchBarLeftButton *)self.searchDisplayController.searchBar;
    [bar showLeftButton:NO];
    [bar showSortButton:NO];
    if ([self collectionViewCanBeEnabled] == YES){
        [bar showLeftButton:YES];
    }
    sortMethodIndex = -1;
    sortMethodName = nil;
    sortAscDesc = nil;
    if ([[[parameters objectForKey:@"parameters"] objectForKey:@"sort"] objectForKey:@"available_methods"] != nil) {
        [self setUpSort:bar methods:methods parameters:parameters];
    }
    [self checkDiskCache];
    float animDuration = 0.3f;
    if (newEnableCollectionView != enableCollectionView){
        animDuration = 0.0;
    }
    [self AnimTable:(UITableView *)activeLayoutView AnimDuration:animDuration Alpha:1.0 XPos:viewWidth];
    enableCollectionView = newEnableCollectionView;
    if ([[parameters objectForKey:@"collectionViewRecentlyAdded"] boolValue] == YES){
        recentlyAddedView = TRUE;
        currentCollectionViewName = NSLocalizedString(@"View: Fanart", nil);
    }
    else{
        recentlyAddedView = FALSE;
        currentCollectionViewName = NSLocalizedString(@"View: Wall", nil);
    }
    [activeLayoutView setContentOffset:[(UITableView *)activeLayoutView contentOffset] animated:NO];
    self.navigationItem.title = [[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]] objectForKey:@"label"];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        topNavigationLabel.alpha = 0;
        [UIView commitAnimations];
        topNavigationLabel.text = [[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]] objectForKey:@"label"];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        topNavigationLabel.alpha = 1;
        [self checkFullscreenButton:NO];
        [UIView commitAnimations];
    }
    NSMutableDictionary *mutableParameters = [[parameters objectForKey:@"parameters"] mutableCopy];
    NSMutableArray *mutableProperties = [[[parameters objectForKey:@"parameters"] objectForKey:@"properties"] mutableCopy];
    if ([[parameters objectForKey:@"FrodoExtraArt"] boolValue] == YES && [AppDelegate instance].serverVersion > 11){
        [mutableProperties addObject:@"art"];
    }
    if ([parameters objectForKey:@"kodiExtrasPropertiesMinimumVersion"] != nil) {
        for(id key in [parameters objectForKey:@"kodiExtrasPropertiesMinimumVersion"]) {
            if ([AppDelegate instance].serverVersion >= [key integerValue]){
                id arrayProperties = [[parameters objectForKey:@"kodiExtrasPropertiesMinimumVersion"] objectForKey:key];
                for (id value in arrayProperties) {
                    [mutableProperties addObject:value];
                }
            }
        }
    }
    if (mutableProperties != nil) {
        [mutableParameters setObject:mutableProperties forKey:@"properties"];
    }
    if ([[parameters objectForKey:@"blackTableSeparator"] boolValue] == YES && [AppDelegate instance].obj.preferTVPosters == NO){
        blackTableSeparator = YES;
        dataList.separatorColor = [UIColor colorWithRed:.15 green:.15 blue:.15 alpha:1];
        self.searchDisplayController.searchResultsTableView.separatorColor = [UIColor colorWithRed:.15 green:.15 blue:.15 alpha:1];
    }
    else{
        blackTableSeparator = NO;
        self.searchDisplayController.searchBar.tintColor = searchBarColor;
        dataList.separatorColor = [UIColor colorWithRed:.75 green:.75 blue:.75 alpha:1];
        self.searchDisplayController.searchResultsTableView.separatorColor = [UIColor colorWithRed:.75 green:.75 blue:.75 alpha:1];
    }
    if ([[[parameters objectForKey:@"itemSizes"] objectForKey:@"separatorInset"] length]){
        [dataList setSeparatorInset:UIEdgeInsetsMake(0, [[[parameters objectForKey:@"itemSizes"] objectForKey:@"separatorInset"] intValue], 0, 0)];
    }
    if ([methods objectForKey:@"method"]!=nil){
        [self retrieveData:[methods objectForKey:@"method"] parameters:mutableParameters sectionMethod:[methods objectForKey:@"extra_section_method"] sectionParameters:[parameters objectForKey:@"extra_section_parameters"] resultStore:self.richResults extraSectionCall:NO refresh:NO];
    }
    else {
        [activityIndicatorView stopAnimating];
        [self AnimTable:(UITableView *)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
}

#pragma mark - Library item didSelect

-(void)viewChild:(NSIndexPath *)indexPath item:(NSDictionary *)item displayPoint:(CGPoint) point{
    self.detailViewController=nil;
    selected = indexPath;
    mainMenu *MenuItem=self.detailItem;
    NSMutableArray *sheetActions=[[self.detailItem sheetActions] objectAtIndex:choosedTab];
    NSMutableDictionary *parameters=[self indexKeyedMutableDictionaryFromArray:[[MenuItem.subItem mainParameters] objectAtIndex:choosedTab]];
    int rectOriginX = point.x;
    int rectOriginY = point.y;
    NSDictionary *mainFields=[[MenuItem mainFields] objectAtIndex:choosedTab];
    MenuItem.subItem.mainLabel=[item objectForKey:@"label"];
    
    NSString *libraryRowHeight= [NSString stringWithFormat:@"%d", MenuItem.subItem.rowHeight];
    NSString *libraryThumbWidth= [NSString stringWithFormat:@"%d", MenuItem.subItem.thumbWidth];
    if ([parameters objectForKey:@"rowHeight"] != nil){
        libraryRowHeight = [parameters objectForKey:@"rowHeight"];
    }
    if ([parameters objectForKey:@"thumbWidth"] != nil){
        libraryThumbWidth = [parameters objectForKey:@"thumbWidth"];
    }
    
    if ([[parameters objectForKey:@"parameters"] objectForKey:@"properties"]!=nil){ // CHILD IS LIBRARY MODE
        NSString *key=@"null";
        if ([item objectForKey:[mainFields objectForKey:@"row15"]]!=nil){
            key=[mainFields objectForKey:@"row15"];
        }
        id obj = [item objectForKey:[mainFields objectForKey:@"row6"]];
        id objKey = [mainFields objectForKey:@"row6"];
        if ([AppDelegate instance].serverVersion>11 && [[parameters objectForKey:@"disableFilterParameter"] boolValue] == FALSE){
            NSDictionary *currentParams = [self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
            obj = [NSDictionary dictionaryWithObjectsAndKeys:
                   [item objectForKey:[mainFields objectForKey:@"row6"]],[mainFields objectForKey:@"row6"],
                   [[[currentParams objectForKey:@"parameters"] objectForKey:@"filter"] objectForKey:[parameters objectForKey:@"combinedFilter"]], [parameters objectForKey:@"combinedFilter"],
                   nil];
            objKey = @"filter";
        }
        if ([parameters objectForKey:@"disableFilterParameter"]==nil)
            [parameters setObject:@"false" forKey:@"disableFilterParameter"];
        NSMutableDictionary *newSectionParameters = [NSMutableDictionary dictionary];
        if ([parameters objectForKey:@"extra_section_parameters"] != nil){
            newSectionParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    obj, objKey,
                                    [[parameters objectForKey:@"extra_section_parameters"] objectForKey:@"properties"], @"properties",
                                    [[parameters objectForKey:@"extra_section_parameters"] objectForKey:@"sort"],@"sort",
                                    [item objectForKey:[mainFields objectForKey:@"row15"]], key,
                                    nil];
        }
        NSMutableDictionary *pvrExtraInfo = [NSMutableDictionary dictionary];
        if ([[item objectForKey:@"family"] isEqualToString:@"channelid"]){
            [pvrExtraInfo setObject:[item objectForKey:@"label"] forKey:@"channel_name"];
            [pvrExtraInfo setObject:[item objectForKey:@"thumbnail"] forKey:@"channel_icon"];
            [pvrExtraInfo setObject:[item objectForKey:@"channelid"] forKey:@"channelid"];
        }
        
        NSMutableDictionary *kodiExtrasPropertiesMinimumVersion = [NSMutableDictionary dictionary];
        if ([parameters objectForKey:@"kodiExtrasPropertiesMinimumVersion"]){
            kodiExtrasPropertiesMinimumVersion = [parameters objectForKey:@"kodiExtrasPropertiesMinimumVersion"];
        }
        NSMutableArray *newParameters=[NSMutableArray arrayWithObjects:
                                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        obj, objKey,
                                        [[parameters objectForKey:@"parameters"] objectForKey:@"properties"], @"properties",
                                        [[parameters objectForKey:@"parameters"] objectForKey:@"sort"],@"sort",
                                        [item objectForKey:[mainFields objectForKey:@"row15"]], key,
                                        nil], @"parameters",
                                       [parameters objectForKey:@"disableFilterParameter"], @"disableFilterParameter",
                                       libraryRowHeight, @"rowHeight", libraryThumbWidth, @"thumbWidth",
                                       [parameters objectForKey:@"label"], @"label",
                                       [NSDictionary dictionaryWithDictionary:[parameters objectForKey:@"itemSizes"]], @"itemSizes",
                                       [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"FrodoExtraArt"] boolValue]], @"FrodoExtraArt",
                                       [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"enableLibraryCache"] boolValue]], @"enableLibraryCache",
                                       [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"enableCollectionView"] boolValue]], @"enableCollectionView",
                                        [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"forceActionSheet"] boolValue]], @"forceActionSheet",
                                       [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"collectionViewRecentlyAdded"] boolValue]], @"collectionViewRecentlyAdded",
                                       [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"blackTableSeparator"] boolValue]], @"blackTableSeparator",
                                       pvrExtraInfo, @"pvrExtraInfo",
                                       kodiExtrasPropertiesMinimumVersion, @"kodiExtrasPropertiesMinimumVersion",
                                       [parameters objectForKey:@"extra_info_parameters"], @"extra_info_parameters",
                                       newSectionParameters, @"extra_section_parameters",
                                       [NSString stringWithFormat:@"%@", [parameters objectForKey:@"defaultThumb"]], @"defaultThumb",
                                       [parameters objectForKey:@"combinedFilter"], @"combinedFilter",
                                       nil];
        [[MenuItem.subItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
        MenuItem.subItem.chooseTab=choosedTab;
        MenuItem.subItem.currentWatchMode = watchMode;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
            self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
            self.detailViewController.detailItem = MenuItem.subItem;
            [self.navigationController pushViewController:self.detailViewController animated:YES];
        }
        else{
            if (stackscrollFullscreen == YES){
                [self toggleFullscreen:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem.subItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                    [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];

                });
            }
            else {
                DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem.subItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
            }
        }
    }
    else { // CHILD IS FILEMODE
        NSString *filemodeRowHeight= @"44";
        NSString *filemodeThumbWidth= @"44";
        if ([parameters objectForKey:@"rowHeight"] != nil){
            filemodeRowHeight = [parameters objectForKey:@"rowHeight"];
        }
        if ([parameters objectForKey:@"thumbWidth"] != nil){
            filemodeThumbWidth = [parameters objectForKey:@"thumbWidth"];
        }
        if ([[item objectForKey:@"filetype"] length]!=0){ // WE ARE ALREADY IN BROWSING FILES MODE
            if ([[item objectForKey:@"filetype"] isEqualToString:@"directory"]){
                [parameters removeAllObjects];
                parameters=[self indexKeyedMutableDictionaryFromArray:[[MenuItem mainParameters] objectAtIndex:choosedTab]];
                NSMutableArray *newParameters=[NSMutableArray arrayWithObjects:
                                               [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                [item objectForKey:[mainFields objectForKey:@"row6"]],@"directory",
                                                [[parameters objectForKey:@"parameters"] objectForKey:@"media"], @"media",
                                                [[parameters objectForKey:@"parameters"] objectForKey:@"sort"],@"sort",
                                                [[parameters objectForKey:@"parameters"] objectForKey:@"file_properties"], @"file_properties",
                                                nil], @"parameters", [parameters objectForKey:@"label"], @"label", @"nocover_filemode.png", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeThumbWidth, @"thumbWidth", @"icon_song",@"fileThumb",
                                               [NSDictionary dictionaryWithDictionary:[parameters objectForKey:@"itemSizes"]], @"itemSizes",
                                               [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"enableCollectionView"] boolValue]], @"enableCollectionView",
                                               [parameters objectForKey:@"disableFilterParameter"], @"disableFilterParameter",
                                               nil];
                MenuItem.mainLabel=[NSString stringWithFormat:@"%@",[item objectForKey:@"label"]];
                [[MenuItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
                MenuItem.chooseTab=choosedTab;
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
                    self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
                    self.detailViewController.detailItem = MenuItem;
                    [self.navigationController pushViewController:self.detailViewController animated:YES];
                }
                else{
                    if (stackscrollFullscreen == YES){
                        [self toggleFullscreen:nil];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                            [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
                            
                        });
                    }
                    else {
                        DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                        [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
                    }
                }
            }
            else if ([[item objectForKey:@"genre"] isEqualToString:@"file"] || [[item objectForKey:@"filetype"] isEqualToString:@"file"]){
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults synchronize];
                if ([[userDefaults objectForKey:@"song_preference"] boolValue]==NO ){
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
        else{ // WE ENTERING FILEMODE
            NSString *fileModeKey = @"directory";
            id objValue = [item objectForKey:[mainFields objectForKey:@"row6"]];
            if ([[item objectForKey:@"family"] isEqualToString:@"sectionid"]){
                fileModeKey = @"section";
            }
            else if ([[item objectForKey:@"family"] isEqualToString:@"categoryid"]){
                fileModeKey = @"filter";
                objValue = [NSDictionary dictionaryWithObjectsAndKeys:
                            [item objectForKey:[mainFields objectForKey:@"row6"]],@"category",
                            [[[[MenuItem mainParameters] objectAtIndex:choosedTab] objectAtIndex:0] objectForKey:@"section"], @"section",
                            nil];
            }
            NSMutableArray *newParameters=[NSMutableArray arrayWithObjects:
                                           [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            objValue, fileModeKey,
                                            [[parameters objectForKey:@"parameters"] objectForKey:@"media"], @"media",
                                            [[parameters objectForKey:@"parameters"] objectForKey:@"sort"],@"sort",
                                            [[parameters objectForKey:@"parameters"] objectForKey:@"file_properties"], @"file_properties",
                                            nil], @"parameters", [parameters objectForKey:@"label"], @"label", @"nocover_filemode.png", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeThumbWidth, @"thumbWidth",
                                           [NSDictionary dictionaryWithDictionary:[parameters objectForKey:@"itemSizes"]], @"itemSizes",
                                           [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"enableCollectionView"] boolValue]], @"enableCollectionView",
                                           [parameters objectForKey:@"disableFilterParameter"], @"disableFilterParameter",
                                           nil];
            if ([[item objectForKey:@"family"] isEqualToString:@"sectionid"] || [[item objectForKey:@"family"] isEqualToString:@"categoryid"]){
                [[newParameters objectAtIndex:0] setObject:@"expert" forKey:@"level"];
            }
            [[MenuItem.subItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
            MenuItem.subItem.chooseTab=choosedTab;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
                
                self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
                self.detailViewController.detailItem = MenuItem.subItem;
                [self.navigationController pushViewController:self.detailViewController animated:YES];
            }
            else{
                if (stackscrollFullscreen == YES){
                    [self toggleFullscreen:nil];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem.subItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                        [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
                    });
                }
                else {
                    DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem.subItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                    [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
                }
            }
        }
    }
}

-(void)didSelectItemAtIndexPath:(NSIndexPath *)indexPath item:(NSDictionary *)item displayPoint:(CGPoint) point{
    self.detailViewController=nil;
    mainMenu *MenuItem=self.detailItem;
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[MenuItem.subItem mainMethod] objectAtIndex:choosedTab]];
    NSMutableArray *sheetActions=[[self.detailItem sheetActions] objectAtIndex:choosedTab];
    NSMutableDictionary *parameters=[self indexKeyedMutableDictionaryFromArray:[[MenuItem.subItem mainParameters] objectAtIndex:choosedTab]];
    int rectOriginX = point.x;
    int rectOriginY = point.y;
    if ([[item objectForKey:@"family"] isEqualToString:@"id"]){
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
            SettingsValuesViewController *settingsViewController = [[SettingsValuesViewController alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) withItem:item];
            [self.navigationController pushViewController:settingsViewController animated:YES];
        }
        else{
            if (stackscrollFullscreen == YES){
                [self toggleFullscreen:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    SettingsValuesViewController *iPadSettingsViewController = [[SettingsValuesViewController alloc] initWithFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.bounds.size.height) withItem:item];
                    [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadSettingsViewController invokeByController:self isStackStartView:FALSE];
                });
            }
            else {
                SettingsValuesViewController *iPadSettingsViewController = [[SettingsValuesViewController alloc] initWithFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.bounds.size.height) withItem:item];
                [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadSettingsViewController invokeByController:self isStackStartView:FALSE];
            }
        }
    }
    else if ([methods objectForKey:@"method"]!=nil && ![[parameters objectForKey:@"forceActionSheet"] boolValue]){ // THERE IS A CHILD
        [self viewChild:indexPath item:item displayPoint:point];
    }
    else {
        if ([[MenuItem.showInfo objectAtIndex:choosedTab] boolValue]){
            [self showInfo:indexPath menuItem:self.detailItem item:item tabToShow:choosedTab];
        }
        else {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults synchronize];
            if ([[userDefaults objectForKey:@"song_preference"] boolValue] == NO || [[parameters objectForKey:@"forceActionSheet"] boolValue] == YES) {
                sheetActions = [self checkMusicPlaylists:sheetActions item:item params:[self indexKeyedMutableDictionaryFromArray:[[MenuItem mainParameters] objectAtIndex:choosedTab]]];
                selected=indexPath;
                [self showActionSheet:indexPath sheetActions:sheetActions item:item rectOriginX:rectOriginX rectOriginY:rectOriginY];
            }
            else {
                [self addPlayback:item indexPath:indexPath position:(int)indexPath.row shuffle:NO];
            }
        }
    }
}

-(NSMutableArray *)checkMusicPlaylists:(NSMutableArray *)sheetActions item:(NSDictionary *)item params:(NSMutableDictionary *)parameters{
    if ([[parameters objectForKey:@"isMusicPlaylist"] boolValue] == YES){ // NOTE: sheetActions objects must be moved outside from there
        if ([sheetActions isKindOfClass:[NSMutableArray class]]){
            [sheetActions removeAllObjects];
            [sheetActions addObject:NSLocalizedString(@"Queue after current", nil)];
            [sheetActions addObject:NSLocalizedString(@"Queue", nil)];
            [sheetActions addObject:NSLocalizedString(@"Play", nil)];
            [sheetActions addObject:NSLocalizedString(@"Play in shuffle mode", nil)];
            if ([[[item objectForKey:@"file"] pathExtension] isEqualToString:@"xsp"] && [AppDelegate instance].serverVersion > 11){
                [sheetActions addObject:NSLocalizedString(@"Play in party mode", nil)];
            }
            [sheetActions addObject:NSLocalizedString(@"Show Content", nil)];
        }
    }
    return sheetActions;
}

#pragma mark - UICollectionView FlowLayout deleagate

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    if (enableCollectionView && [self.sectionArray count] > 1 && section > 0){
        return CGSizeMake(dataList.frame.size.width, COLLECTION_HEADER_HEIGHT);
    }
    else{
        return CGSizeMake(0, 0);
    }
}

-(void)setFlowLayoutParams{
    if (stackscrollFullscreen == YES){
        [flowLayout setItemSize:CGSizeMake(fullscreenCellGridWidth, fullscreenCellGridHeight)];
        if (!cellMinimumLineSpacing) cellMinimumLineSpacing = 0.0f;
        if  (!recentlyAddedView) {
            [flowLayout setMinimumLineSpacing:38.0f];
        }
        else {
            [flowLayout setMinimumLineSpacing:4.0f];
        }
        [flowLayout setMinimumInteritemSpacing:cellMinimumLineSpacing];
    }
    else{
        if (!cellMinimumLineSpacing) cellMinimumLineSpacing = 0.0f;
        [flowLayout setItemSize:CGSizeMake(cellGridWidth, cellGridHeight)];
        [flowLayout setMinimumLineSpacing:cellMinimumLineSpacing];
        [flowLayout setMinimumInteritemSpacing:cellMinimumLineSpacing];
    }
}

#pragma mark - UICollectionView methods

-(void)initCollectionView{
    if (collectionView == nil){
        flowLayout = [[FloatingHeaderFlowLayout alloc] init];
        [self setFlowLayoutParams];
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
        collectionView = [[UICollectionView alloc] initWithFrame:dataList.frame collectionViewLayout:flowLayout];
        collectionView.contentInset = dataList.contentInset;
        collectionView.scrollIndicatorInsets = dataList.scrollIndicatorInsets;
        [collectionView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
        [collectionView setDelegate:self];
        [collectionView setDataSource:self];
        [collectionView registerClass:[PosterCell class] forCellWithReuseIdentifier:@"posterCell"];
        [collectionView registerClass:[RecentlyAddedCell class] forCellWithReuseIdentifier:@"recentlyAddedCell"];
        [collectionView registerClass:[PosterHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"posterHeaderView"];
        [collectionView setAutoresizingMask:dataList.autoresizingMask];
        __weak DetailViewController *weakSelf = self;
        [collectionView addPullToRefreshWithActionHandler:^{
            [weakSelf startRetrieveDataWithRefresh:YES];
        }];
        [collectionView setShowsPullToRefresh:enableDiskCache];
        collectionView.alwaysBounceVertical = YES;
        [detailView insertSubview:collectionView belowSubview:buttonsView];
        NSMutableArray *tmpArr = [[NSMutableArray alloc] initWithArray:self.sectionArray];
        if ([tmpArr count] > 1){
            [tmpArr replaceObjectAtIndex:0 withObject:[NSString stringWithUTF8String:"\xF0\x9F\x94\x8D"]];
            self.indexView.indexTitles = [NSArray arrayWithArray:tmpArr];
            [detailView addSubview:self.indexView];
        }
    }
    activeLayoutView = collectionView;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return [[self.sections allKeys] count];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    float margin = 0.0f;
    if (stackscrollFullscreen == YES) {
        margin = 8.0f;
    }
    if (section == 0) {
        return UIEdgeInsetsMake(CGRectGetHeight(self.searchDisplayController.searchBar.frame), margin, 0, margin);
    }
    
    return UIEdgeInsetsMake(0, margin, 0, margin);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)cView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"posterHeaderView";
    PosterHeaderView *headerView = [cView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:identifier forIndexPath:indexPath];
    [headerView setHeaderText:[self buildSortInfo:[self.sectionArray objectAtIndex:indexPath.section]]];
    return headerView;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (episodesView){
        return ([[self.sectionArrayOpen objectAtIndex:section] boolValue] ? [[self.sections valueForKey:[self.sectionArray objectAtIndex:section]] count] : 0);
    }
    return [[self.sections valueForKey:[self.sectionArray objectAtIndex:section]] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    NSDictionary *item = [[self.sections valueForKey:[self.sectionArray objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    NSString *stringURL = [item objectForKey:@"thumbnail"];
    NSString *fanartURL = [item objectForKey:@"fanart"];
    NSString *displayThumb=[NSString stringWithFormat:@"%@_wall", defaultThumb];
    NSString *playcount = [NSString stringWithFormat:@"%@", [item objectForKey:@"playcount"]];
    
    float cellthumbWidth = cellGridWidth;
    float cellthumbHeight = cellGridHeight;
    if (stackscrollFullscreen == YES) {
        cellthumbWidth = fullscreenCellGridWidth;
        cellthumbHeight = fullscreenCellGridHeight;
    }
    if (recentlyAddedView == FALSE){
        static NSString *identifier = @"posterCell";
        PosterCell *cell = [cView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        [cell.posterLabel setText:@""];
        [cell.posterLabelFullscreen setText:@""];
        [cell.posterLabel setFont:[UIFont boldSystemFontOfSize:posterFontSize]];
        [cell.posterLabelFullscreen setFont:[UIFont boldSystemFontOfSize:posterFontSize]];
        [cell.posterThumbnail setContentMode:UIViewContentModeScaleAspectFill];
        if (stackscrollFullscreen == YES) {
            [cell.posterLabelFullscreen setText:[item objectForKey:@"label"]];
            cell.labelImageView.hidden = YES;
            cell.posterLabelFullscreen.hidden = NO;
        }
        else {
            [cell.posterLabel setText:[item objectForKey:@"label"]];
            cell.posterLabelFullscreen.hidden = YES;
        }
        
        if ([[item objectForKey:@"filetype"] length]!=0 || [[item objectForKey:@"family"] isEqualToString:@"file"] || [[item objectForKey:@"family"] isEqualToString:@"genreid"]){
            if (![stringURL isEqualToString:@""]){
                displayThumb=stringURL;
            }
        }
        else if (channelListView) {
            [cell setIsRecording:[[item objectForKey:@"isrecording"] boolValue]];
        }
        
        if (![stringURL isEqualToString:@""]){
            if ([[item objectForKey:@"family"] isEqualToString:@"channelid"]){
                [cell.posterThumbnail setContentMode:UIViewContentModeScaleAspectFit];
            }
            [cell.posterThumbnail setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:displayThumb] andResize:CGSizeMake(cellthumbWidth, cellthumbHeight)];
            if (hiddenLabel) {
                [cell.posterLabel setHidden:YES];
                [cell.labelImageView setHidden:YES];
            }
            else {
                [cell.posterLabel setHidden:NO];
                [cell.labelImageView setHidden:NO];
            }
        }
        else {
            [cell.posterThumbnail setImageWithURL:[NSURL URLWithString:@""] placeholderImage:[UIImage imageNamed:displayThumb] ];
            [cell.posterLabel setHidden:NO];
            [cell.labelImageView setHidden:NO];
        }
        
        if ([playcount intValue]){
            [cell setOverlayWatched:YES];
        }
        else{
            [cell setOverlayWatched:NO];
        }
        
        return cell;
    }
    else{
        static NSString *identifier = @"recentlyAddedCell";
        RecentlyAddedCell *cell = [cView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        float posterWidth = cellthumbHeight * 0.66f;
        float fanartWidth = cellthumbWidth - posterWidth;

        if (![stringURL isEqualToString:@""]){
            [cell.posterThumbnail setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:displayThumb] andResize:CGSizeMake(posterWidth, cellthumbHeight) completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                UIColor *averageColor = [utils averageColor:image inverse:NO];
                CGFloat hue, saturation, brightness, alpha;
                BOOL ok = [averageColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
                if (ok) {
                    UIColor *bgColor = [UIColor colorWithHue:hue saturation:saturation brightness:0.2f alpha:alpha];
                    [cell setBackgroundColor:bgColor];
                }
            }];
        }
        else {
            [cell.posterThumbnail setImageWithURL:[NSURL URLWithString:@""] placeholderImage:[UIImage imageNamed:displayThumb] ];
        }

        if (![fanartURL isEqualToString:@""]){
            [cell.posterFanart setImageWithURL:[NSURL URLWithString:fanartURL] placeholderImage:[UIImage imageNamed:@""]andResize:CGSizeMake(fanartWidth, cellthumbHeight)];
        }
        else {
            [cell.posterFanart setImageWithURL:[NSURL URLWithString:@""] placeholderImage:[UIImage imageNamed:@""]];
        }
        
        [cell.posterLabel setFont:[UIFont boldSystemFontOfSize:fanartFontSize + 8]];
        [cell.posterLabel setText:[item objectForKey:@"label"]];
        
        [cell.posterGenre setFont:[UIFont systemFontOfSize:fanartFontSize + 2]];
        [cell.posterGenre setText:[item objectForKey:@"genre"]];
        
        [cell.posterYear setFont:[UIFont systemFontOfSize:fanartFontSize]];
//        [cell.posterYear setText:[NSString stringWithFormat:@"%@%@", [item objectForKey:@"year"], [item objectForKey:@"runtime"] == nil ? @"" : [NSString stringWithFormat:@" - %@", [item objectForKey:@"runtime"]]]];
        [cell.posterYear setText:[item objectForKey:@"year"]];
        if ([playcount intValue]){
            [cell setOverlayWatched:YES];
        }
        else{
            [cell setOverlayWatched:NO];
        }
        return cell;
    }
}

-(void)collectionView:(UICollectionView *)cView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *item = [[self.sections valueForKey:[self.sectionArray objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    UICollectionViewCell *cell = [cView cellForItemAtIndexPath:indexPath];
    CGPoint offsetPoint = [cView contentOffset];
    int rectOriginX = cell.frame.origin.x + (cell.frame.size.width/2);
    int rectOriginY = cell.frame.origin.y + cell.frame.size.height/2 - offsetPoint.y;
//    // EXPERIMENTAL CODE
//    [cell setAlpha:1];
////    [cView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredVertically];
////    int k = [cView numberOfSections];
////    for (int j = 0; j < k; j++){
////        int n = [cView numberOfItemsInSection:j];
////        for (int i = 0; i < n; i++){
////            UICollectionViewCell *cell = [cView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
////            if (cell != nil && ![[NSIndexPath indexPathForRow:i inSection:0] isEqual:indexPath]){
////                [UIView beginAnimations:nil context:nil];
////                [UIView setAnimationDuration:0.5];
////                [cell setAlpha:0.3];
////                [UIView commitAnimations];
////                [darkCells addObject:cell];
////            }
////        }
////    }
//    [cView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredVertically];
//    autoScroll = YES;
//    [self darkCells];
//    // END EXPERIMENTAL CODE
    [self didSelectItemAtIndexPath:indexPath item:item displayPoint:CGPointMake(rectOriginX, rectOriginY)];
}
//// EXPERIMENTAL CODE
//
//-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
//    if ([scrollView isKindOfClass:[UICollectionView class]] && autoScroll == YES){
//        [self darkCells];
//        autoScroll = NO;
//    }
//}
//
//
//-(void)darkCells{
//        
//    [darkCells removeAllObjects];
//    [darkCells addObjectsFromArray:[collectionView indexPathsForVisibleItems]];
//    [darkCells removeObjectsInArray:[collectionView indexPathsForSelectedItems]];
//    for (NSIndexPath *idx in darkCells) {
//        UICollectionViewCell *darkcell = [collectionView cellForItemAtIndexPath:idx];
//        [UIView beginAnimations:nil context:nil];
//        [UIView setAnimationDuration:0.5];
//        [darkcell setAlpha:0.3];
//        [UIView commitAnimations];
//    }
//}
//
//-(void)brightCells{
//    for (NSIndexPath *idx in darkCells) {
//        UICollectionViewCell *darkcell = [collectionView cellForItemAtIndexPath:idx];
//        [UIView beginAnimations:nil context:nil];
//        [UIView setAnimationDuration:0.2];
//        [darkcell setAlpha:1];
//        [UIView commitAnimations];
//    }
//    [darkCells removeAllObjects];
//}
//
//-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
//    [self brightCells];
////    if ([darkCells count]){
////        for (UICollectionViewCell *cell in darkCells) {
////            [UIView beginAnimations:nil context:nil];
////            [UIView setAnimationDuration:0.1];
////            [cell setAlpha:1];
////            [UIView commitAnimations];
////        }
////        [darkCells removeAllObjects];
////    }
//}
//// END EXPERIMENTAL CODE

#pragma mark - BDKCollectionIndexView init

-(void)initSectionNameOverlayView{
    sectionNameOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width / 2, self.view.frame.size.width / 6)];
    sectionNameOverlayView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin);
    [sectionNameOverlayView setBackgroundColor:[UIColor clearColor]];
    sectionNameOverlayView.center = [[[[UIApplication sharedApplication] delegate] window] rootViewController].view.center;
    float cornerRadius = 12.0f;
    sectionNameOverlayView.layer.cornerRadius = cornerRadius;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = sectionNameOverlayView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:.1 green:.1 blue:.1 alpha:.8] CGColor], (id)[[UIColor colorWithRed:.0 green:.0 blue:.0 alpha:.8] CGColor], nil];
    gradient.cornerRadius = cornerRadius;
    [sectionNameOverlayView.layer insertSublayer:gradient atIndex:0];
    
    int fontSize = 32;
    sectionNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, sectionNameOverlayView.frame.size.height/2 - (fontSize + 8)/2, sectionNameOverlayView.frame.size.width, (fontSize + 8))];
    [sectionNameLabel setFont:[UIFont boldSystemFontOfSize:fontSize]];
    [sectionNameLabel setTextColor:[UIColor whiteColor]];
    [sectionNameLabel setBackgroundColor:[UIColor clearColor]];
    [sectionNameLabel setTextAlignment:NSTextAlignmentCenter];
    [sectionNameLabel setShadowColor:[UIColor blackColor]];
    [sectionNameLabel setShadowOffset:CGSizeMake(0, 1)];
    [sectionNameOverlayView addSubview:sectionNameLabel];
    [self.view addSubview:sectionNameOverlayView];
}

- (BDKCollectionIndexView *)indexView {
    if (_indexView) return _indexView;
    CGFloat indexWidth = 26;
    if ( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        indexWidth = 32;
    }
    CGRect frame = CGRectMake(CGRectGetWidth(dataList.frame) - indexWidth + 2,
                              CGRectGetMinY(dataList.frame) + dataList.contentInset.top + COLLECTION_HEADER_HEIGHT + 2,
                              indexWidth,
                              CGRectGetHeight(dataList.frame) - dataList.contentInset.top - dataList.contentInset.bottom - 4 -COLLECTION_HEADER_HEIGHT);
    _indexView = [BDKCollectionIndexView indexViewWithFrame:frame indexTitles:@[]];
    _indexView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin);
    _indexView.hidden = YES;
    [_indexView addTarget:self action:@selector(indexViewValueChanged:) forControlEvents:UIControlEventValueChanged];
    [detailView addSubview:_indexView];
    return _indexView;
}

- (void)indexViewValueChanged:(BDKCollectionIndexView *)sender {
    if (sender.currentIndex == 0){
        float deltaY = 0;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
            deltaY = - 44 + iOSYDelta;
        }
        [collectionView setContentOffset:CGPointMake(0, deltaY) animated:NO];
        if (sectionNameOverlayView == nil && stackscrollFullscreen == YES){
            [self initSectionNameOverlayView];
        }
        sectionNameLabel.text = [NSString stringWithFormat:@"%C%C", 0xD83D, 0xDD0D];
        return;
    }
    else if (stackscrollFullscreen == YES){
        if (sectionNameOverlayView == nil && stackscrollFullscreen == YES){
            [self initSectionNameOverlayView];
        }
        sectionNameLabel.text = [self buildSortInfo:[storeSectionArray objectAtIndex:sender.currentIndex]];
        NSString *value = [storeSectionArray objectAtIndex:sender.currentIndex];
        NSPredicate *predExists = [NSPredicate predicateWithFormat: @"SELF.%@ BEGINSWITH[c] %@", sortMethodName, value];
        if ([value isEqual:@"#"]) {
            predExists = [NSPredicate predicateWithFormat: @"SELF.%@ MATCHES[c] %@", sortMethodName, @"^[0-9].*"];
        }
        else if ([sortMethodName isEqualToString:@"rating"] && [value isEqualToString:@"0"]){
            predExists = [NSPredicate predicateWithFormat: @"SELF.%@.length == 0", sortMethodName];
        }
        else if ([sortMethodName isEqualToString:@"runtime"]){
             [NSPredicate predicateWithFormat: @"attributeName BETWEEN %@", @[@1, @10]];
            predExists = [NSPredicate predicateWithFormat: @"SELF.%@.intValue BETWEEN %@", sortMethodName, [NSArray arrayWithObjects:[NSNumber numberWithInt:[value intValue] - 15],[NSNumber numberWithInt:[value intValue]], nil]];
        }
        else if ([sortMethodName isEqualToString:@"playcount"]){
            predExists = [NSPredicate predicateWithFormat: @"SELF.%@.intValue == %d", sortMethodName, [value intValue]];
        }
        NSUInteger index = [[sections objectForKey:@""] indexOfObjectPassingTest:
                            ^(id obj, NSUInteger idx, BOOL *stop) {
                                return [predExists evaluateWithObject:obj];
                            }];
        if (index != NSNotFound){
            NSIndexPath *path = [NSIndexPath indexPathForItem:index inSection:0];
            [collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
            collectionView.contentOffset = CGPointMake(collectionView.contentOffset.x, collectionView.contentOffset.y - COLLECTION_HEADER_HEIGHT);
        }
        return;
    }
    else{
        NSIndexPath *path = [NSIndexPath indexPathForItem:0 inSection:sender.currentIndex];
        if (path.section == 1 && ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)){
            [collectionView setContentOffset:CGPointMake(0, -4) animated:NO];
        }
        else {
            [collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        }
        collectionView.contentOffset = CGPointMake(collectionView.contentOffset.x, collectionView.contentOffset.y - COLLECTION_HEADER_HEIGHT + 4);
    }
}

-(void)handleCollectionIndexStateBegin{
    if (stackscrollFullscreen == YES){
        [self alphaView:sectionNameOverlayView AnimDuration:0.1f Alpha:1];
    }
}

-(void)handleCollectionIndexStateEnded{
    if (stackscrollFullscreen == YES){
        [self alphaView:sectionNameOverlayView AnimDuration:0.3f Alpha:0];
    }
}

#pragma mark - Table Animation

-(void)alphaImage:(UIImageView *)image AnimDuration:(float)seconds Alpha:(float)alphavalue{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	image.alpha = alphavalue;
    [UIView commitAnimations];
}

-(void)alphaView:(UIView *)view AnimDuration:(float)seconds Alpha:(float)alphavalue{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	view.alpha = alphavalue;
    [UIView commitAnimations];
}

- (void)AnimTable:(UITableView *)tV AnimDuration:(float)seconds Alpha:(float)alphavalue XPos:(int)X{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:seconds];
    tV.alpha = alphavalue;
    CGRect frame;
    frame = [tV frame];
    frame.origin.x = X;
    frame.origin.y = 0;
    tV.frame = frame;
    [UIView commitAnimations];
}

- (void)AnimView:(UIView *)view AnimDuration:(float)seconds Alpha:(float)alphavalue XPos:(int)X{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	view.alpha = alphavalue;
	CGRect frame;
	frame = [view frame];
	frame.origin.x = X;
	view.frame = frame;
    [UIView commitAnimations];
}

#pragma mark - Cell Formatting 

int originYear = 0;
-(void)choseParams{ // DA OTTIMIZZARE TROPPI IF!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    flagX = 43;
    flagY = 54;
    mainMenu *Menuitem = self.detailItem;
    NSDictionary *parameters = [self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    if ([[parameters objectForKey:@"defaultThumb"] length] != 0 && ![[parameters objectForKey:@"defaultThumb"] isEqualToString:@"(null)"]){
        defaultThumb = [parameters objectForKey:@"defaultThumb"];
    }
    else {
        defaultThumb = [self.detailItem defaultThumb];
    }
    if ([parameters objectForKey:@"rowHeight"]!=0)
        cellHeight = [[parameters objectForKey:@"rowHeight"] intValue];
    else if (Menuitem.rowHeight!=0){
        cellHeight = Menuitem.rowHeight;
    }
    else {
        cellHeight = 76;
    }

    if ([parameters objectForKey:@"thumbWidth"]!=0)
        thumbWidth = [[parameters objectForKey:@"thumbWidth"] intValue];
    else if (Menuitem.thumbWidth!=0){
        thumbWidth = Menuitem.thumbWidth;
    }
    else {
        thumbWidth = 53;
    }
    if (albumView){
        thumbWidth = 0;
        labelPosition = thumbWidth + albumViewPadding + trackCountLabelWidth;
        [dataList setSeparatorInset:UIEdgeInsetsMake(0, 8, 0, 0)];
    }
    else if (episodesView){
        thumbWidth = 0;
        labelPosition = 18;
    }
    else if (channelGuideView){
        thumbWidth = 0;
        labelPosition = epgChannelTimeLabelWidth;
    }
    else{
        labelPosition=thumbWidth + 8;
    }
    int newWidthLabel = 0;
    if (Menuitem.originLabel && ![parameters objectForKey:@"thumbWidth"]){
        labelPosition = Menuitem.originLabel;
    }
    // CHECK IF THERE ARE SECTIONS
    
    int iOS7offset = 0;
    int iOS7insetSeparator = 0;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        iOS7offset = 12;
        iOS7insetSeparator = 20;
    }
    else{
        iOS7offset = 4;
        iOS7insetSeparator = 30;
    }
    if (episodesView || (([self.sectionArray count] == 1) && !channelGuideView)) {
        //([self.richResults count]<=SECTIONS_START_AT || ![self.detailItem enableSection])
        newWidthLabel = viewWidth - 8 - labelPosition;
        Menuitem.originYearDuration = viewWidth - 72;
        UIEdgeInsets dataListSeparatorInset = [dataList separatorInset];
        dataListSeparatorInset.right = 0;
        [dataList setSeparatorInset:dataListSeparatorInset];
    }
    else {
        int extraPadding = 0;
        if ([sortMethodName isEqualToString:@"year"] || [sortMethodName isEqualToString:@"dateadded"]){
            extraPadding = 18;
        }
        else if ([sortMethodName isEqualToString:@"runtime"]) {
            extraPadding = 12;
        }
        if (iOS7offset > 0) {
            UIEdgeInsets dataListSeparatorInset = [dataList separatorInset];
            dataListSeparatorInset.right = iOS7insetSeparator + extraPadding;
            [dataList setSeparatorInset:dataListSeparatorInset];
        }
        if (channelGuideView){
            iOS7offset += 6;
        }
        
        newWidthLabel = viewWidth - 38 - labelPosition + iOS7offset - extraPadding;
        Menuitem.originYearDuration = viewWidth - 100 + iOS7offset - extraPadding;
    }
    Menuitem.widthLabel=newWidthLabel;
    flagX = thumbWidth - 10;
    flagY = cellHeight - 19;
    if (flagX + 22 > self.view.bounds.size.width){
        flagX = 2;
        flagY = 2;
    }
    if (thumbWidth == 0){
        flagX = 6;
        flagY = 4;
    }
}

#pragma mark - Table Management

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return cellHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView){
        return 1;
    }
	else{
        return [[self.sections allKeys] count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (tableView == self.searchDisplayController.searchResultsTableView){
        int numResult = (int)[self.filteredListContent count];
        if (numResult){
            if (numResult!=1)
                return [NSString stringWithFormat:NSLocalizedString(@"%d results", nil), [self.filteredListContent count]];
            else {
                return NSLocalizedString(@"1 result", nil);
            }
        }
        else {
            return @"";
        }
    }
    else {
        if(section == 0){return nil;}
        NSString *sectionName = [self.sectionArray objectAtIndex:section];
        if (channelGuideView){
            NSString *dateString = @"";
            NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:NSLocalizedString(@"LocaleIdentifier",nil)];
            NSDateFormatter *format = [[NSDateFormatter alloc] init];
            [format setLocale:locale];
            [format setDateFormat:@"yyyy-MM-dd"];
            NSDate *date = [format dateFromString:sectionName];
            [format setDateStyle:NSDateFormatterLongStyle];
            dateString = [format stringFromDate:date];
            [format setDateFormat:@"yyyy-MM-dd"];
            date = [format dateFromString:sectionName];
            [format setDateFormat:@"cccc"];
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

-(NSString *)buildSortInfo:(NSString *)sectionName {
    if ([sortMethodName isEqualToString:@"year"]) {
        if ([sectionName length] > 3) {
        sectionName = [NSString stringWithFormat:NSLocalizedString(@"The %@s decade", nil), sectionName];
        }
        else {
            sectionName = NSLocalizedString(@"Year not available", nil);
        }
    }
    else if ([sortMethodName isEqualToString:@"dateadded"]) {
        sectionName = [NSString stringWithFormat:NSLocalizedString(@"Year %@", nil), sectionName];
    }
    else if ([sortMethodName isEqualToString:@"playcount"]) {
        if ([sectionName intValue] == 0) {
            if ([watchedListenedStrings objectForKey:@"notWatched"] != nil){
                sectionName = [watchedListenedStrings objectForKey:@"notWatched"];
            }
            else {
                sectionName = NSLocalizedString(@"Not watched", nil);
            }
        }
        else if ([sectionName intValue] == 1) {
            if ([watchedListenedStrings objectForKey:@"watchedOneTime"] != nil){
                sectionName = [watchedListenedStrings objectForKey:@"watchedOneTime"];
            }
            else {
                sectionName = NSLocalizedString(@"Watched one time", nil);
            }
        }
        else {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle: NSNumberFormatterSpellOutStyle];
            NSString *formatString = NSLocalizedString(@"Watched %@ times", nil);
            if ([watchedListenedStrings objectForKey:@"watchedTimes"] != nil){
                formatString = [watchedListenedStrings objectForKey:@"watchedTimes"];
            }
            sectionName = [NSString stringWithFormat:formatString, [formatter stringFromNumber:[NSNumber numberWithInt: [sectionName intValue]]]];
        }
    }
    else if ([sortMethodName isEqualToString:@"rating"]) {
        int start = 0;
        int num_stars = [sectionName intValue];
        int stop = numberOfStars;
        NSString *newName = [NSString stringWithFormat:NSLocalizedString(@"Rated %@", nil), sectionName];
        NSMutableString *stars = [NSMutableString string];
        for (start = 0; start < num_stars; start++ ) {
            [stars appendString:@"\u2605"];
        }
        for (int j = start; j < stop; j++){
            [stars appendString:@"\u2606"];
        }
        sectionName = [NSString stringWithFormat:@"%@ - %@", stars, newName];
    }
    else if ([sortMethodName isEqualToString:@"runtime"]) {
        if ([sectionName isEqualToString:@"15"]){
            sectionName = NSLocalizedString(@"Less than 15 minutes", nil);
        }
        else if ([sectionName isEqualToString:@"30"]){
            sectionName = NSLocalizedString(@"Less than half an hour", nil);
        }
        else if ([sectionName isEqualToString:@"45"]){
            sectionName = NSLocalizedString(@"About half an hour", nil);
        }
        else if ([sectionName isEqualToString:@"60"]){
            sectionName = NSLocalizedString(@"Less than one hour", nil);
        }
        else if ([sectionName isEqualToString:@"75"]){
            sectionName = NSLocalizedString(@"About one hour", nil);
        }
        else if ([sectionName isEqualToString:@"90"]){
            sectionName = NSLocalizedString(@"About an hour and a half", nil);
        }
        else if ([sectionName isEqualToString:@"105"]){
            sectionName = NSLocalizedString(@"Nearly two hours", nil);
        }
        else if ([sectionName isEqualToString:@"120"]){
            sectionName = NSLocalizedString(@"About two hours", nil);
        }
        else if ([sectionName isEqualToString:@"135"]){
            sectionName = NSLocalizedString(@"Two hours", nil);
        }
        else if ([sectionName isEqualToString:@"150"]){
            sectionName = NSLocalizedString(@"About two and a half hours", nil);
        }
        else if ([sectionName isEqualToString:@"165"]){
            sectionName = NSLocalizedString(@"More than two and a half hours", nil);
        }
        else if ([sectionName isEqualToString:@"180"]){
            sectionName = NSLocalizedString(@"Nearly three hours", nil);
        }
        else if ([sectionName isEqualToString:@"195"]){
            sectionName = NSLocalizedString(@"About three hours", nil);
        }
        else if ([sectionName isEqualToString:@"210"]){
            sectionName = NSLocalizedString(@"Nearly three and half hours", nil);
        }
        else if ([sectionName isEqualToString:@"225"]){
            sectionName = NSLocalizedString(@"About three and half hours", nil);
        }
        else if ([sectionName isEqualToString:@"240"]){
            sectionName = NSLocalizedString(@"Nearly four hours", nil);
        }
        else if ([sectionName isEqualToString:@"255"]){
            sectionName = NSLocalizedString(@"About four hours", nil);
        }
        else {
            sectionName = NSLocalizedString(@"More than four hours", nil);
        }
    }
    else if ([sortMethodName isEqualToString:@"track"]){
        sectionName = [NSString stringWithFormat:NSLocalizedString(@"Track n.%@", nil), sectionName];
    }
    return sectionName;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.filteredListContent count];
    }
	else {
        if (episodesView){
            return ([[self.sectionArrayOpen objectAtIndex:section] boolValue] ? [[self.sections valueForKey:[self.sectionArray objectAtIndex:section]] count] : 0);
        }
        return [[self.sections valueForKey:[self.sectionArray objectAtIndex:section]] count];
    }
}

-(NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index{
    if (index==0){
        [tableView scrollRectToVisible:tableView.tableHeaderView.frame animated:NO];
        return  index -1 ;
    }
    return index;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView){
        return nil;
    }
    else {
        if ([self.sectionArray count] > 1 && !episodesView && !channelGuideView){
            return self.sectionArray;
        }
        else if (channelGuideView){
            if ([self.sectionArray count] > 0){
                NSMutableArray *channelGuideTableIndexTitles = [[NSMutableArray alloc] init];
                for (NSString *label in self.sectionArray){
                        NSString *dateString = label;
                        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:NSLocalizedString(@"LocaleIdentifier",nil)];
                        NSDateFormatter *format = [[NSDateFormatter alloc] init];
                        [format setLocale:locale];
                        [format setDateFormat:@"yyyy-MM-dd"];
                        NSDate *date = [format dateFromString:label];
                        [format setDateFormat:@"ccccc"];
                    if ([format stringFromDate:date] != nil){
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {    
	cell.backgroundColor = [UIColor whiteColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"jsonDataCellIdentifier";
    jsonDataCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    NSMutableDictionary *item = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView){
        item = [self.filteredListContent objectAtIndex:indexPath.row];
    }
	else{
        item = [[self.sections valueForKey:[self.sectionArray objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    }
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"jsonDataCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        if (albumView){
            UILabel *trackNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(albumViewPadding, cellHeight/2 - (artistFontSize + labelPadding)/2, trackCountLabelWidth - 2, artistFontSize + labelPadding)];
            [trackNumberLabel setBackgroundColor:[UIColor clearColor]];
            [trackNumberLabel setFont:[UIFont systemFontOfSize:artistFontSize]];
            trackNumberLabel.adjustsFontSizeToFitWidth = YES;
            trackNumberLabel.minimumScaleFactor = (artistFontSize - 4) / artistFontSize;
            trackNumberLabel.tag = 101;
            [trackNumberLabel setHighlightedTextColor:[UIColor whiteColor]];
            [cell.contentView addSubview:trackNumberLabel];
        }
        else if (channelGuideView){
            UILabel *programTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 8, epgChannelTimeLabelWidth - 8, 12 + labelPadding)];
            [programTimeLabel setBackgroundColor:[UIColor clearColor]];
            [programTimeLabel setFont:[UIFont systemFontOfSize:12]];
            programTimeLabel.adjustsFontSizeToFitWidth = YES;
            programTimeLabel.minimumScaleFactor = 8.0f / 12.0f;
            programTimeLabel.textAlignment = NSTextAlignmentCenter;
            programTimeLabel.tag = 102;
            [programTimeLabel setHighlightedTextColor:[UIColor whiteColor]];
            [cell.contentView addSubview:programTimeLabel];
            ProgressPieView *progressView = [[ProgressPieView alloc] initWithFrame:CGRectMake(4, programTimeLabel.frame.origin.y + programTimeLabel.frame.size.height + 7, epgChannelTimeLabelWidth - 8, epgChannelTimeLabelWidth - 8)];
            progressView.tag = 103;
            progressView.hidden = YES;
            [cell.contentView addSubview:progressView];
            
            UIImageView *hasTimer = [[UIImageView alloc] initWithFrame:CGRectMake((int)((2 + (epgChannelTimeLabelWidth - 8) - 6) / 2), programTimeLabel.frame.origin.y + programTimeLabel.frame.size.height + 14, 12, 12)];
            [hasTimer setImage:[UIImage imageNamed:@"button_timer"]];
            hasTimer.tag = 104;
            hasTimer.hidden = YES;
            [hasTimer setBackgroundColor:[UIColor clearColor]];
            [cell.contentView addSubview:hasTimer];
        }
        else if (channelListView) {
            float pieSize = 28.0f;
            ProgressPieView *progressView = [[ProgressPieView alloc] initWithFrame:CGRectMake(viewWidth - pieSize - 2.0f, 10.0f, pieSize, pieSize) color:[UIColor blackColor]];
            progressView.tag = 103;
            progressView.hidden = YES;
            [cell.contentView addSubview:progressView];
            
            float dotSize = 6.0f;
            UIImageView *isRecordingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(progressView.frame.origin.x + pieSize/2.0f - dotSize/2.0f, progressView.frame.origin.y + [progressView getPieRadius]/2.0f + [progressView getLineWidth] + 0.5f, dotSize, dotSize)];
            [isRecordingImageView setImage:[UIImage imageNamed:@"button_timer"]];
            [isRecordingImageView setContentMode:UIViewContentModeScaleToFill];
            isRecordingImageView.tag = 104;
            isRecordingImageView.hidden = YES;
            [isRecordingImageView setBackgroundColor:[UIColor clearColor]];
            [cell.contentView addSubview:isRecordingImageView];
        }
        [(UILabel*) [cell viewWithTag:1] setHighlightedTextColor:[UIColor blackColor]];
        [(UILabel*) [cell viewWithTag:2] setHighlightedTextColor:[UIColor blackColor]];
        [(UILabel*) [cell viewWithTag:3] setHighlightedTextColor:[UIColor blackColor]];
        [(UILabel*) [cell viewWithTag:4] setHighlightedTextColor:[UIColor blackColor]];
        [(UILabel*) [cell viewWithTag:5] setHighlightedTextColor:[UIColor darkGrayColor]];
        [(UILabel*) [cell viewWithTag:101] setHighlightedTextColor:[UIColor blackColor]];
        [(UILabel*) [cell viewWithTag:102] setHighlightedTextColor:[UIColor blackColor]];
    }
    mainMenu *Menuitem = self.detailItem;
//    NSDictionary *mainFields=[[Menuitem mainFields] objectAtIndex:choosedTab];
/* future - need to be tweaked: doesn't work on file mode. mainLabel need to be resized */
//    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[Menuitem.subItem mainMethod] objectAtIndex:choosedTab]];
//    if ([methods objectForKey:@"method"]!=nil){ // THERE IS A CHILD
//        cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator; 
//    }
/* end future */
    CGRect frame = cell.urlImageView.frame;
    frame.size.width = thumbWidth;
    cell.urlImageView.frame = frame;
    
    UILabel *title=(UILabel*) [cell viewWithTag:1];
    UILabel *genre=(UILabel*) [cell viewWithTag:2];
    UILabel *runtimeyear=(UILabel*) [cell viewWithTag:3];
    UILabel *runtime = (UILabel*) [cell viewWithTag:4];
    UILabel *rating=(UILabel*) [cell viewWithTag:5];

    frame=title.frame;
    frame.origin.x=labelPosition;
    frame.size.width=Menuitem.widthLabel;
    title.frame=frame;
    [title setText:[item objectForKey:@"label"]];

    frame=genre.frame;
    frame.size.width=frame.size.width - (labelPosition - frame.origin.x);
    frame.origin.x=labelPosition; 
    genre.frame=frame;
    [genre setText:[[item objectForKey:@"genre"] stringByReplacingOccurrencesOfString:@"[CR]" withString:@"\n"]];

    frame=runtimeyear.frame;
    frame.origin.x=Menuitem.originYearDuration;
    runtimeyear.frame=frame;

    if ([[Menuitem.showRuntime objectAtIndex:choosedTab] boolValue]){
        NSString *duration=@"";
        if (!Menuitem.noConvertTime){
            duration=[self convertTimeFromSeconds:[item objectForKey:@"runtime"]];
        }
        else {
            duration=[item objectForKey:@"runtime"];
        }
        [runtimeyear setText:duration];        
    }
    else {
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:NSLocalizedString(@"LocaleIdentifier",nil)];
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setLocale:locale];
        [format setDateFormat:@"yyyy-MM-dd"];
        NSDate *date = [format dateFromString:[item objectForKey:@"year"]];
        if (date == nil){
            [runtimeyear setText:[item objectForKey:@"year"]];
        }
        else{
            [format setDateFormat:NSLocalizedString(@"ShortDateTimeFormat", nil)];
            [runtimeyear setText:[format stringFromDate:date]];
        }
    }
    frame=runtime.frame;
    frame.size.width=frame.size.width - (labelPosition - frame.origin.x);
    frame.origin.x=labelPosition;
    runtime.frame=frame;
    [runtime setText:[item objectForKey:@"runtime"]];

    frame=rating.frame;
    frame.origin.x=Menuitem.originYearDuration;
    rating.frame=frame;
    [rating setText:[NSString stringWithFormat:@"%@", [item objectForKey:@"rating"]]];
    [cell.urlImageView setContentMode:UIViewContentModeScaleAspectFill];
    genre.hidden = NO;
    runtimeyear.hidden = NO;
    if (!albumView && !episodesView && !channelGuideView){
        if (channelListView){
            CGRect frame = genre.frame;
            genre.autoresizingMask = title.autoresizingMask;
            frame.size.width = title.frame.size.width;;
            genre.frame = frame;
            [genre setTextColor:[UIColor blackColor]];
            [genre setFont:[UIFont boldSystemFontOfSize:genre.font.pointSize]];
            frame = runtime.frame;
            frame.size.width=Menuitem.widthLabel;
            runtime.frame = frame;
            frame = cell.urlImageView.frame;
            frame.size.width = thumbWidth * 0.9f;
            frame.origin.x = 6;
            frame.origin.y = 10;
            frame.size.height = thumbWidth * 0.7f;
            cell.urlImageView.frame = frame;
            ProgressPieView *progressView = (ProgressPieView*) [cell viewWithTag:103];
            progressView.hidden = YES;
            UIImageView *isRecordingImageView = (UIImageView*) [cell viewWithTag:104];
            isRecordingImageView.hidden = ![[item objectForKey:@"isrecording"] boolValue];
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInteger:[[item objectForKey:@"channelid"] integerValue]], @"channelid",
                                    tableView, @"tableView",
                                    indexPath, @"indexPath",
                                    item, @"item",
                                    nil];
            [NSThread detachNewThreadSelector:@selector(getChannelEpgInfo:) toTarget:self withObject:params];
        }
        NSString *stringURL = [item objectForKey:@"thumbnail"];
        NSString *displayThumb=defaultThumb;
        if ([[item objectForKey:@"filetype"] length]!=0 ||
            [[item objectForKey:@"family"] isEqualToString:@"file"] ||
            [[item objectForKey:@"family"] isEqualToString:@"genreid"] ||
            [[item objectForKey:@"family"] isEqualToString:@"channelgroupid"] ||
            [[item objectForKey:@"family"] isEqualToString:@"roleid"]
            ){
            if (![stringURL isEqualToString:@""]){
                displayThumb=stringURL;
            }
            genre.hidden = YES;
            runtimeyear.hidden = YES;
            [title setFrame:CGRectMake(title.frame.origin.x, (int)((cellHeight/2) - (title.frame.size.height/2)), title.frame.size.width, title.frame.size.height)];
        }
        else if ([[item objectForKey:@"family"] isEqualToString:@"recordingid"] || [[item objectForKey:@"family"] isEqualToString:@"timerid"]){
            [cell.urlImageView setContentMode:UIViewContentModeScaleAspectFit];
            runtimeyear.hidden = YES;
            runtime.hidden = YES;
            rating.hidden = YES;
            genre.hidden = NO;
            if ([[item objectForKey:@"family"] isEqualToString:@"timerid"]){
                NSDateFormatter *localFormatter = [[NSDateFormatter alloc] init];
                [localFormatter setDateFormat:@"ccc dd MMM, HH:mm"];
                localFormatter.timeZone = [NSTimeZone systemTimeZone];
                NSDate *timerStartTime = [xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", [item objectForKey:@"starttime"]]];
                NSDate *endTime = [xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", [item objectForKey:@"endtime"]]];
                genre.text = [localFormatter stringFromDate:timerStartTime];
                [localFormatter setDateFormat:@"HH:mm"];
                NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                NSUInteger unitFlags = NSCalendarUnitMinute;
                NSDateComponents *components = [gregorian components:unitFlags fromDate:timerStartTime toDate:endTime options:0];
                NSInteger minutes = [components minute];
                genre.text = [NSString stringWithFormat:@"%@ - %@ (%ld %@)", genre.text, [localFormatter stringFromDate:endTime], (long)minutes, (long)minutes > 1 ? NSLocalizedString(@"Mins.", nil) : NSLocalizedString(@"Min", nil)];
            }
            else{
                [genre setText:[NSString stringWithFormat:@"%@ - %@", [item objectForKey:@"channel"], [item objectForKey:@"year"]]];
                [genre setNumberOfLines:3];
            }
            genre.autoresizingMask = title.autoresizingMask;
            CGRect frame = genre.frame;
            frame.size.width = title.frame.size.width;
            frame.size.height = frame.size.height + (cellHeight - (frame.origin.y  + frame.size.height))  - 4;
            genre.frame = frame;
            frame = title.frame;
            frame.origin.y = 0;
            [title setFrame:frame];
            genre.font =  [genre.font fontWithSize:11];
            [genre setMinimumScaleFactor:10.0f/11.0f];
            [genre sizeToFit];
        }
        else if ([[item objectForKey:@"family"] isEqualToString:@"sectionid"] || [[item objectForKey:@"family"] isEqualToString:@"categoryid"]|| [[item objectForKey:@"family"] isEqualToString:@"id"] || [[item objectForKey:@"family"] isEqualToString:@"addonid"]){
            CGRect frame;
            if ([[item objectForKey:@"family"] isEqualToString:@"id"]){
                frame = title.frame;
                frame.size.width = frame.size.width - 22;
                title.frame = frame;
                cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;
            }
            [cell.urlImageView setContentMode:UIViewContentModeScaleAspectFit];
            runtimeyear.hidden = YES;
            runtime.hidden = YES;
            rating.hidden = YES;
            genre.autoresizingMask = title.autoresizingMask;
            frame = genre.frame;
            frame.size.width = title.frame.size.width;
            frame.size.height = frame.size.height + (cellHeight - (frame.origin.y  + frame.size.height))  - 4;
            genre.frame = frame;
            [genre setNumberOfLines:2];
            genre.font =  [genre.font fontWithSize:11];
            [genre setMinimumScaleFactor:10.f/11.0f];
            [genre sizeToFit];
        }
        else{
            genre.hidden = NO;
            runtimeyear.hidden = NO;
        }
        if (![stringURL isEqualToString:@""]){
            if ([[item objectForKey:@"family"] isEqualToString:@"channelid"]){
                [cell.urlImageView setContentMode:UIViewContentModeScaleAspectFit];
            }
            [cell.urlImageView setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:displayThumb]andResize:CGSizeMake(thumbWidth, cellHeight)];
        }
        else {
            [cell.urlImageView setImageWithURL:[NSURL URLWithString:@""] placeholderImage:[UIImage imageNamed:displayThumb]];
        }
    }
    else if (albumView){
        UILabel *trackNumber = (UILabel *)[cell viewWithTag:101];
        trackNumber.text = [item objectForKey:@"track"];
    }
    else if (channelGuideView){
        runtimeyear.hidden = YES;
        runtime.hidden = YES;
        rating.hidden = YES;
        genre.autoresizingMask = title.autoresizingMask;
        CGRect frame = genre.frame;
        frame.size.width = title.frame.size.width;
        frame.size.height = frame.size.height + (cellHeight - (frame.origin.y  + frame.size.height))  - 4;
        genre.frame = frame;
        [genre setNumberOfLines:3];
        genre.font =  [genre.font fontWithSize:11];
        [genre setMinimumScaleFactor:10.0f/11.0f];
        UILabel *programStartTime = (UILabel *)[cell viewWithTag:102];
        NSDateFormatter *test= [[NSDateFormatter alloc] init];
        [test setDateFormat:@"yyyy-MM-dd HH:mm"];
        test.timeZone = [NSTimeZone systemTimeZone];
        programStartTime.text = [localHourMinuteFormatter stringFromDate:[xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", [item objectForKey:@"starttime"]]]];
        ProgressPieView *progressView = (ProgressPieView*) [cell viewWithTag:103];
        NSDate *starttime = [xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", [item objectForKey:@"starttime"]]];
        NSDate *endtime = [xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", [item objectForKey:@"endtime"]]];
        float total_seconds = [endtime timeIntervalSince1970] - [starttime timeIntervalSince1970];
        float elapsed_seconds = [[NSDate date] timeIntervalSince1970] - [starttime timeIntervalSince1970];
        float percent_elapsed = (elapsed_seconds/total_seconds) * 100.0f;

        if (percent_elapsed >= 0 && percent_elapsed < 100) {
            [title setTextColor:[UIColor blueColor]];
            [genre setTextColor:[UIColor blueColor]];
            [programStartTime setTextColor:[UIColor blueColor]];

            [title setHighlightedTextColor:[UIColor blueColor]];
            [genre setHighlightedTextColor:[UIColor blueColor]];
            [programStartTime setHighlightedTextColor:[UIColor blueColor]];

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
        else{
            progressView.hidden = YES;
            progressView.pieLabel.hidden = YES;
            [title setTextColor:[UIColor blackColor]];
            [genre setTextColor:[UIColor blackColor]];
            [programStartTime setTextColor:[UIColor blackColor]];
            [title setHighlightedTextColor:[UIColor blackColor]];
            [genre setHighlightedTextColor:[UIColor blackColor]];
            [programStartTime setHighlightedTextColor:[UIColor blackColor]];
        }
        UIImageView *hasTimer = (UIImageView*) [cell viewWithTag:104];
        if ([[item objectForKey:@"hastimer"] boolValue]){
            hasTimer.hidden = FALSE;
        }
        else{
            hasTimer.hidden = TRUE;
        }
    }
    NSString *playcount = [NSString stringWithFormat:@"%@", [item objectForKey:@"playcount"]];
    UIImageView *flagView = (UIImageView*) [cell viewWithTag:9];
    frame=flagView.frame;
    frame.origin.x=flagX;
    frame.origin.y=flagY;
    flagView.frame=frame;
    if ([playcount intValue]){
        [flagView setHidden:NO];
    }
    else{
        [flagView setHidden:YES];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.searchDisplayController.searchBar resignFirstResponder];
    NSDictionary *item = nil;
    UITableViewCell *cell = nil;
    CGPoint offsetPoint;
    if (tableView == self.searchDisplayController.searchResultsTableView){
        item = [self.filteredListContent objectAtIndex:indexPath.row];
        cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
        offsetPoint = [self.searchDisplayController.searchResultsTableView contentOffset];
        offsetPoint.y = offsetPoint.y - 44;
    }
    else{
        item = [[self.sections valueForKey:[self.sectionArray objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        cell = [dataList cellForRowAtIndexPath:indexPath];
        offsetPoint = [dataList contentOffset];
    }
    int rectOriginX = cell.frame.origin.x + (cell.frame.size.width/2);
    int rectOriginY = cell.frame.origin.y + cell.frame.size.height/2 - offsetPoint.y;
    [self didSelectItemAtIndexPath:indexPath item:item displayPoint:CGPointMake(rectOriginX, rectOriginY)];
    return;
}

- (NSUInteger)indexOfObjectWithSeason: (NSString*)seasonNumber inArray: (NSArray*)array{
    return [array indexOfObjectPassingTest:
            ^(id dictionary, NSUInteger idx, BOOL *stop) {
                return ([[dictionary objectForKey: @"season"] isEqualToString: seasonNumber]);
            }];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (albumView && [self.richResults count]>0){
        __block UIColor *albumFontColor = [UIColor blackColor];
        __block UIColor *albumFontShadowColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.3];
        __block UIColor *albumDetailsColor = [UIColor darkGrayColor];

        UIView *albumDetailView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, albumViewHeight + 2)];
        UILabel *artist = [[UILabel alloc] initWithFrame:CGRectMake(albumViewHeight, (albumViewPadding / 2) - 1, viewWidth - albumViewHeight - albumViewPadding, artistFontSize + labelPadding)];
        UILabel *albumLabel = [[UILabel alloc] initWithFrame:CGRectMake(albumViewHeight, artist.frame.origin.y +  artistFontSize + 2, viewWidth - albumViewHeight - albumViewPadding, albumFontSize + labelPadding)];
        int bottomMargin = albumViewHeight - albumViewPadding - (trackCountFontSize + (labelPadding / 2) - 1);
        UILabel *trackCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(albumViewHeight, bottomMargin, viewWidth - albumViewHeight - albumViewPadding, trackCountFontSize + labelPadding)];
        UILabel *releasedLabel = [[UILabel alloc] initWithFrame:CGRectMake(albumViewHeight, bottomMargin - trackCountFontSize -labelPadding/2, viewWidth - albumViewHeight - albumViewPadding, trackCountFontSize + labelPadding)];
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = albumDetailView.bounds;
        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:.6 green:.6 blue:.6 alpha:.95] CGColor], (id)[[UIColor colorWithRed:.9 green:.9 blue:.9 alpha:.95] CGColor], nil];
        [albumDetailView.layer insertSublayer:gradient atIndex:0];
        CGRect toolbarShadowFrame = CGRectMake(0.0f, albumViewHeight + 1, viewWidth, 8);
        UIImageView *toolbarShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
        [toolbarShadow setImage:[UIImage imageNamed:@"tableUp.png"]];
        toolbarShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbarShadow.opaque = YES;
        toolbarShadow.alpha = 0.3;
        [albumDetailView addSubview:toolbarShadow];
        NSDictionary *item;
        item = [self.richResults objectAtIndex:0];
        int albumThumbHeight = albumViewHeight - (albumViewPadding * 2);
        UIView *thumbImageContainer = [[UIView alloc] initWithFrame:CGRectMake(albumViewPadding, albumViewPadding, albumThumbHeight, albumThumbHeight)];
        [thumbImageContainer setClipsToBounds: NO];
        UIImageView *thumbImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, albumThumbHeight, albumThumbHeight)];
        thumbImageView.userInteractionEnabled = YES;
        [thumbImageView setClipsToBounds:YES];
        [thumbImageView setContentMode:UIViewContentModeScaleAspectFill];
        
        UITapGestureRecognizer *touchOnAlbumView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAlbumActions:)];
        [touchOnAlbumView setNumberOfTapsRequired:1];
        [touchOnAlbumView setNumberOfTouchesRequired:1];
        [thumbImageView addGestureRecognizer:touchOnAlbumView];
    
        NSString *stringURL = [item objectForKey:@"thumbnail"];
        NSString *displayThumb=@"coverbox_back.png";
        if ([[item objectForKey:@"filetype"] length]!=0){
            displayThumb=stringURL;
        }
        if (![stringURL isEqualToString:@""]){
            [thumbImageView setImageWithURL:[NSURL URLWithString:stringURL]
                           placeholderImage:[UIImage imageNamed:displayThumb]
                                  andResize:CGSizeMake(albumThumbHeight, albumThumbHeight)
                                  completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                      BOOL isRetina = ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] >= 2);
                                      float thumbBorder = isRetina ? 1.0f/[[UIScreen mainScreen] scale] : 1.0f;
                                      [thumbImageContainer setBackgroundColor:[UIColor clearColor]];
                                      thumbImageContainer.layer.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1].CGColor;
                                      thumbImageContainer.layer.shadowOpacity = 1.0f;
                                      thumbImageContainer.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
                                      thumbImageContainer.layer.shadowRadius = 2.0f;
                                      thumbImageContainer.layer.masksToBounds = NO;
                                      thumbImageContainer.layer.borderWidth = thumbBorder;
                                      thumbImageContainer.layer.borderColor = [UIColor blackColor].CGColor;
                                      UIBezierPath *path = [UIBezierPath bezierPathWithRect:thumbImageContainer.bounds];
                                      thumbImageContainer.layer.shadowPath = path.CGPath;
                                      if (enableBarColor == YES){
                                          albumColor = [utils averageColor:image inverse:NO];
                                          UIColor *slightLightAlbumColor = [utils slightLighterColorForColor:albumColor];
                                          self.navigationController.navigationBar.tintColor = slightLightAlbumColor;
                                          self.searchDisplayController.searchBar.tintColor = slightLightAlbumColor;
                                          if ([[[self.searchDisplayController.searchBar subviews] objectAtIndex:0] isKindOfClass:[UIImageView class]]){
                                              [[[self.searchDisplayController.searchBar subviews] objectAtIndex:0] removeFromSuperview];
                                          }
                                          [self.searchDisplayController.searchBar setBackgroundColor:albumColor];
                                          CAGradientLayer *gradient = [CAGradientLayer layer];
                                          gradient.frame = albumDetailView.bounds;
                                          gradient.colors = [NSArray arrayWithObjects:(id)[albumColor CGColor], (id)[[utils lighterColorForColor:albumColor] CGColor], nil];
                                          [albumDetailView.layer insertSublayer:gradient atIndex:1];
                                          albumFontColor = [utils updateColor:albumColor lightColor:[UIColor whiteColor] darkColor:[UIColor blackColor]];
                                          albumFontShadowColor = [utils updateColor:albumColor lightColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.3] darkColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.3]];
                                          albumDetailsColor = [utils updateColor:albumColor lightColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.7] darkColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6]];
                                          [artist setTextColor:albumFontColor];
                                          [artist setShadowColor:albumFontShadowColor];
                                          [albumLabel setTextColor:albumFontColor];
                                          [albumLabel setShadowColor:albumFontShadowColor];
                                          [trackCountLabel setTextColor:albumDetailsColor];
                                          [trackCountLabel setShadowColor:albumFontShadowColor];
                                          [releasedLabel setTextColor:albumDetailsColor];
                                          [releasedLabel setShadowColor:albumFontShadowColor];
                                          if (((NSNull *)[self.searchDisplayController.searchBar valueForKey:@"_searchField"] != [NSNull null])){
                                              UITextField *searchTextField = [self.searchDisplayController.searchBar valueForKey:@"_searchField"];
                                              if ([searchTextField respondsToSelector:@selector(setAttributedPlaceholder:)]) {
                                                  UIImageView *iconView = (id)searchTextField.leftView;
                                                  iconView.image = [iconView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                                                  iconView.tintColor = slightLightAlbumColor;
                                                  searchTextField.textColor = slightLightAlbumColor;
                                                  searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchDisplayController.searchBar.placeholder attributes: @{NSForegroundColorAttributeName: slightLightAlbumColor}];
                                              }
                                          }
                                      }
                                  }];
        }
        else {
            [thumbImageView setImageWithURL:[NSURL URLWithString:@""] placeholderImage:[UIImage imageNamed:displayThumb] ];
        }
        stringURL = [item objectForKey:@"fanart"];
        if (![stringURL isEqualToString:@""]){
            UIImageView *fanartBackgroundImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, - self.searchDisplayController.searchBar.frame.size.height, viewWidth, albumViewHeight + 2 + self.searchDisplayController.searchBar.frame.size.height)];
            fanartBackgroundImage.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
            fanartBackgroundImage.contentMode = UIViewContentModeScaleAspectFill;
            fanartBackgroundImage.alpha = 0.1f;
            [fanartBackgroundImage setClipsToBounds:YES];
            [fanartBackgroundImage setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:@""]];
            [albumDetailView addSubview:fanartBackgroundImage];
        }
        [thumbImageContainer addSubview:thumbImageView];
        [albumDetailView addSubview:thumbImageContainer];
        
        [artist setBackgroundColor:[UIColor clearColor]];
        [artist setTextColor:albumFontColor];
        [artist setShadowColor:albumFontShadowColor];
        [artist setShadowOffset:CGSizeMake(0, 1)];
        [artist setFont:[UIFont systemFontOfSize:artistFontSize]];
        artist.adjustsFontSizeToFitWidth = YES;
        artist.minimumScaleFactor = 9.0f / artistFontSize;
        artist.text = [item objectForKey:@"genre"];
        [albumDetailView addSubview:artist];
        
        [albumLabel setBackgroundColor:[UIColor clearColor]];
        [albumLabel setTextColor:albumFontColor];
        [albumLabel setShadowColor:albumFontShadowColor];
        [albumLabel setShadowOffset:CGSizeMake(0, 1)];
        [albumLabel setFont:[UIFont boldSystemFontOfSize:albumFontSize]];
        albumLabel.text = self.navigationItem.title;
        albumLabel.numberOfLines = 0;
        CGSize maximunLabelSize= CGSizeMake(viewWidth - albumViewHeight - albumViewPadding, albumViewHeight - (albumViewPadding * 4) - 28);
        
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
        for(int i=0;i<[self.richResults count];i++)
            totalTime += [[[self.richResults objectAtIndex:i] objectForKey:@"runtime"] intValue];
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setMaximumFractionDigits:0];
        [formatter setRoundingMode: NSNumberFormatterRoundHalfEven];
        NSString *numberString = [formatter stringFromNumber:[NSNumber numberWithFloat:totalTime/60]];
        
        [trackCountLabel setBackgroundColor:[UIColor clearColor]];
        [trackCountLabel setTextColor:albumDetailsColor];
        [trackCountLabel setShadowColor:albumFontShadowColor];
        [trackCountLabel setShadowOffset:CGSizeMake(0, 1)];
        [trackCountLabel setFont:[UIFont systemFontOfSize:trackCountFontSize]];
        trackCountLabel.text = [NSString stringWithFormat:@"%lu %@, %@ %@", (unsigned long)[self.richResults count], [self.richResults count] > 1 ? NSLocalizedString(@"Songs", nil)  : NSLocalizedString(@"Song", nil), numberString, totalTime/60 > 1 ? NSLocalizedString(@"Mins.", nil) : NSLocalizedString(@"Min", nil)];
        [albumDetailView addSubview:trackCountLabel];
        int year = [[item objectForKey:@"year"] intValue];
        [releasedLabel setBackgroundColor:[UIColor clearColor]];
        [releasedLabel setTextColor:albumDetailsColor];
        [releasedLabel setShadowColor:albumFontShadowColor];
        [releasedLabel setShadowOffset:CGSizeMake(0, 1)];
        [releasedLabel setFont:[UIFont systemFontOfSize:trackCountFontSize]];
        releasedLabel.text = [NSString stringWithFormat:@"%@", (year > 0) ? [NSString stringWithFormat:NSLocalizedString(@"Released %d", nil), year] : @"" ];
        [albumDetailView addSubview:releasedLabel];
        
        UIButton *albumInfoButton =  [UIButton buttonWithType:UIButtonTypeInfoDark ];
        albumInfoButton.alpha = .5f;
        [albumInfoButton setShowsTouchWhenHighlighted:YES];
        [albumInfoButton setFrame:CGRectMake(viewWidth - albumInfoButton.frame.size.width - albumViewPadding, bottomMargin - 3, albumInfoButton.frame.size.width, albumInfoButton.frame.size.height)];
        albumInfoButton.tag = 0;
        [albumInfoButton addTarget:self action:@selector(prepareShowAlbumInfo:) forControlEvents:UIControlEventTouchUpInside];
        [albumDetailView addSubview:albumInfoButton];
        
//        UIButton *albumPlaybackButton =  [UIButton buttonWithType:UIButtonTypeCustom];
//        albumPlaybackButton.tag = 0;
//        albumPlaybackButton.showsTouchWhenHighlighted = YES;
//        UIImage *btnImage = [UIImage imageNamed:@"button_play"];
//        [albumPlaybackButton setImage:btnImage forState:UIControlStateNormal];
//        albumPlaybackButton.alpha = .8f;
//        int playbackOriginX = [[formatter stringFromNumber:[NSNumber numberWithFloat:(albumThumbHeight/2 - btnImage.size.width/2 + albumViewPadding)]] intValue];
//        int playbackOriginY = [[formatter stringFromNumber:[NSNumber numberWithFloat:(albumThumbHeight/2 - btnImage.size.height/2 + albumViewPadding)]] intValue];
//        [albumPlaybackButton setFrame:CGRectMake(playbackOriginX, playbackOriginY, btnImage.size.width, btnImage.size.height)];
//        [albumPlaybackButton addTarget:self action:@selector(preparePlaybackAlbum:) forControlEvents:UIControlEventTouchUpInside];
//        [albumDetailView addSubview:albumPlaybackButton];

        return albumDetailView;
    }
    else if (episodesView && [self.richResults count]>0 && !(tableView == self.searchDisplayController.searchResultsTableView)){
        UIColor *seasonFontShadowColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.3];
        UIView *albumDetailView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, albumViewHeight + 2)];
        albumDetailView.tag = section;
        int toggleIconSpace = 0;
        if ([self.sectionArray count] > 1){
            toggleIconSpace = 8;
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOpen:)];
            [albumDetailView addGestureRecognizer:tapGesture];
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.tag = 99;
            button.alpha = .5;
            button.frame = CGRectMake(3.0, (int)(albumViewHeight / 2) - 6, 11.0, 11.0);
            [button setImage:[UIImage imageNamed:@"arrow_close"] forState:UIControlStateNormal];
            [button setImage:[UIImage imageNamed:@"arrow_open"] forState:UIControlStateSelected];
//            [button addTarget:self action:@selector(toggleOpen:) forControlEvents:UIControlEventTouchUpInside];
            if ([[self.sectionArrayOpen objectAtIndex:section] boolValue] == TRUE){
                [button setSelected:YES];
            }
            [albumDetailView addSubview:button];
        }
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = albumDetailView.bounds;
        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1] CGColor], (id)[[UIColor colorWithRed:.6 green:.6 blue:.6 alpha:.95] CGColor], nil];
        [albumDetailView.layer insertSublayer:gradient atIndex:0];
        if (section>0){
            UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, -1, viewWidth, 1)];
            [lineView setBackgroundColor:[UIColor colorWithRed:.95 green:.95 blue:.95 alpha:1]];
            [albumDetailView addSubview:lineView];
        }
        CGRect toolbarShadowFrame = CGRectMake(0.0f, albumViewHeight + 1, viewWidth, 8);
        UIImageView *toolbarShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
        [toolbarShadow setImage:[UIImage imageNamed:@"tableUp.png"]];
        toolbarShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbarShadow.opaque = YES;
        toolbarShadow.alpha = 0.3;
        [albumDetailView addSubview:toolbarShadow];
        
        NSDictionary *item;
        if (tableView == self.searchDisplayController.searchResultsTableView){
            item = [self.richResults objectAtIndex:0];
        }
        else{
            item = [[self.sections valueForKey:[self.sectionArray objectAtIndex:section]] objectAtIndex:0];
        }
        NSInteger seasonIdx = [self indexOfObjectWithSeason:[NSString stringWithFormat:@"%d",[[item objectForKey:@"season"] intValue]] inArray:self.extraSectionRichResults];
        float seasonThumbWidth = (albumViewHeight - (albumViewPadding * 2)) * 0.71;
        if (seasonIdx != NSNotFound){
            
            UIImageView *thumbImageView = [[UIImageView alloc] initWithFrame:CGRectMake(albumViewPadding + toggleIconSpace, albumViewPadding, seasonThumbWidth, albumViewHeight - (albumViewPadding * 2))];
            NSString *stringURL = [[self.extraSectionRichResults objectAtIndex:seasonIdx] objectForKey:@"thumbnail"];
            NSString *displayThumb=@"coverbox_back_section.png";
            if ([[item objectForKey:@"filetype"] length]!=0){
                displayThumb=stringURL;
            }
            if (![stringURL isEqualToString:@""]){
                [thumbImageView setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:displayThumb] andResize:CGSizeMake(seasonThumbWidth, albumViewHeight - (albumViewPadding * 2))];
                
            }
            else {
                [thumbImageView setImageWithURL:[NSURL URLWithString:@""] placeholderImage:[UIImage imageNamed:displayThumb] ];
            }            
            [albumDetailView addSubview:thumbImageView];
            
            UIImageView *thumbImageShadowView = [[UIImageView alloc] initWithFrame:CGRectMake(albumViewPadding + toggleIconSpace - 3, albumViewPadding - 3, seasonThumbWidth + 6, albumViewHeight - (albumViewPadding * 2) + 6)];
            [thumbImageShadowView setContentMode:UIViewContentModeScaleToFill];
            thumbImageShadowView.image = [UIImage imageNamed:@"coverbox_back_section_shadow"];
            [albumDetailView addSubview:thumbImageShadowView];
            
            UILabel *artist = [[UILabel alloc] initWithFrame:CGRectMake(seasonThumbWidth + toggleIconSpace + (albumViewPadding * 2), (albumViewPadding / 2), viewWidth - albumViewHeight - albumViewPadding, artistFontSize + labelPadding)];
            [artist setBackgroundColor:[UIColor clearColor]];
            [artist setShadowColor:seasonFontShadowColor];
            [artist setShadowOffset:CGSizeMake(0, 1)];
            [artist setFont:[UIFont systemFontOfSize:artistFontSize]];
            artist.adjustsFontSizeToFitWidth = YES;
            artist.minimumScaleFactor = 9.0f/artistFontSize;
            artist.text = [item objectForKey:@"genre"];
            [albumDetailView addSubview:artist];
            
            UILabel *albumLabel = [[UILabel alloc] initWithFrame:CGRectMake(seasonThumbWidth + toggleIconSpace + (albumViewPadding * 2), artist.frame.origin.y +  artistFontSize + 2, viewWidth - albumViewHeight - albumViewPadding, albumFontSize + labelPadding)];
            [albumLabel setBackgroundColor:[UIColor clearColor]];
            [albumLabel setShadowColor:seasonFontShadowColor];
            [albumLabel setShadowOffset:CGSizeMake(0, 1)];
            [albumLabel setFont:[UIFont boldSystemFontOfSize:albumFontSize]];
            albumLabel.text = [[self.extraSectionRichResults objectAtIndex:seasonIdx] objectForKey:@"label"];
            albumLabel.numberOfLines = 0;
            CGSize maximunLabelSize= CGSizeMake(viewWidth - albumViewHeight - albumViewPadding - toggleIconSpace, albumViewHeight - albumViewPadding*4 -28);
            
            CGRect expectedLabelRect = [albumLabel.text boundingRectWithSize:maximunLabelSize
                                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                                  attributes:@{NSFontAttributeName:albumLabel.font}
                                                                     context:nil];
            CGSize expectedLabelSize = expectedLabelRect.size;
            CGRect newFrame = albumLabel.frame;
            newFrame.size.height = expectedLabelSize.height + 8;
            albumLabel.frame = newFrame;
            [albumDetailView addSubview:albumLabel];
            
            int bottomMargin = albumViewHeight - albumViewPadding - (trackCountFontSize + (labelPadding / 2) - 1);
            UILabel *trackCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(seasonThumbWidth + toggleIconSpace + (albumViewPadding * 2), bottomMargin, viewWidth - albumViewHeight - albumViewPadding - toggleIconSpace, trackCountFontSize + labelPadding)];
            [trackCountLabel setBackgroundColor:[UIColor clearColor]];
            [trackCountLabel setShadowColor:seasonFontShadowColor];
            [trackCountLabel setShadowOffset:CGSizeMake(0, 1)];
            [trackCountLabel setTextColor:[UIColor darkGrayColor]];
            [trackCountLabel setFont:[UIFont systemFontOfSize:trackCountFontSize]];
            trackCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Episodes: %@", nil), [[self.extraSectionRichResults objectAtIndex:seasonIdx] objectForKey:@"episode"]];
            [albumDetailView addSubview:trackCountLabel];

            UILabel *releasedLabel = [[UILabel alloc] initWithFrame:CGRectMake(seasonThumbWidth +toggleIconSpace + (albumViewPadding * 2), bottomMargin - trackCountFontSize -labelPadding/2, viewWidth - albumViewHeight - albumViewPadding - toggleIconSpace, trackCountFontSize + labelPadding)];
            [releasedLabel setBackgroundColor:[UIColor clearColor]];
            [releasedLabel setShadowColor:seasonFontShadowColor];
            [releasedLabel setShadowOffset:CGSizeMake(0, 1)];
            [releasedLabel setTextColor:[UIColor darkGrayColor]];
            [releasedLabel setFont:[UIFont systemFontOfSize:trackCountFontSize]];
            [releasedLabel setMinimumScaleFactor:(trackCountFontSize - 2)/trackCountFontSize];
            [releasedLabel setNumberOfLines:1];
            [releasedLabel setAdjustsFontSizeToFitWidth:YES];
            
            NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:NSLocalizedString(@"LocaleIdentifier",nil)];
            NSString *aired = @"";
            NSDateFormatter *format = [[NSDateFormatter alloc] init];
            [format setLocale:usLocale];
            [format setDateFormat:@"yyyy-MM-dd"];
            NSDate *date = [format dateFromString:[item objectForKey:@"year"]];
            [format setDateFormat:NSLocalizedString(@"LongDateTimeFormat", nil)];
            aired = [format stringFromDate:date];
            releasedLabel.text = @"";
            if (aired!=nil){
                releasedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"First aired on %@", nil), aired];
            }
            [albumDetailView addSubview:releasedLabel];

            UIButton *albumInfoButton =  [UIButton buttonWithType:UIButtonTypeInfoDark ] ;
            albumInfoButton.alpha = .6f;
            [albumInfoButton setShowsTouchWhenHighlighted:YES];
            [albumInfoButton setFrame:CGRectMake(viewWidth - albumInfoButton.frame.size.width - albumViewPadding, bottomMargin - 6, albumInfoButton.frame.size.width, albumInfoButton.frame.size.height)];
            albumInfoButton.tag = 1;
            [albumInfoButton addTarget:self action:@selector(prepareShowAlbumInfo:) forControlEvents:UIControlEventTouchUpInside];
            [albumDetailView addSubview:albumInfoButton];
        }
        return albumDetailView;
    }

    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle == nil) {
        UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, 1)];
        [sectionView setBackgroundColor:[UIColor colorWithRed:.4 green:.4 blue:.4 alpha:1]];
        CGRect toolbarShadowFrame = CGRectMake(0.0f, 1, viewWidth, 4);
        UIImageView *toolbarShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
        [toolbarShadow setImage:[UIImage imageNamed:@"tableUp.png"]];
        toolbarShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbarShadow.contentMode = UIViewContentModeScaleToFill;
        toolbarShadow.opaque = YES;
        toolbarShadow.alpha = .3f;
        [sectionView addSubview:toolbarShadow];
        return sectionView;
    }
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, sectionHeight)];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = sectionView.bounds;
    
    // TEST
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:.6 green:.6 blue:.6 alpha:.95] CGColor], (id)[[UIColor colorWithRed:.9 green:.9 blue:.9 alpha:.95] CGColor], nil];
//    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:.1 green:.1 blue:.1 alpha:.8] CGColor], (id)[[UIColor colorWithRed:.3 green:.3 blue:.3 alpha:.8f] CGColor], nil];
    //END TEST

    [sectionView.layer insertSublayer:gradient atIndex:0];
    
    //TEST
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, -1, viewWidth, 1)];
    [lineView setBackgroundColor:[UIColor colorWithRed:.5725 green:.5725 blue:.5725 alpha:1]];
    [sectionView addSubview:lineView];
//    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, -2, viewWidth, 1)];
//    [lineView setBackgroundColor:[UIColor colorWithRed:.1 green:.1 blue:.1 alpha:1]];
//    [sectionView addSubview:lineView];
    //END TEST

    CGRect toolbarShadowFrame = CGRectMake(0.0f, sectionHeight - 1, viewWidth, 4);
    UIImageView *toolbarShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
    [toolbarShadow setImage:[UIImage imageNamed:@"tableUp.png"]];
    toolbarShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    toolbarShadow.contentMode = UIViewContentModeScaleToFill;
    toolbarShadow.opaque = YES;
    toolbarShadow.alpha = .3f;
    [sectionView addSubview:toolbarShadow];
    
    if (section>1){
        CGRect toolbarShadowUpFrame = CGRectMake(0.0f, -3, viewWidth, 2);
        UIImageView *toolbarUpShadow = [[UIImageView alloc] initWithFrame:toolbarShadowUpFrame];
        [toolbarUpShadow setImage:[UIImage imageNamed:@"tableDown.png"]];
        toolbarUpShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbarUpShadow.contentMode = UIViewContentModeScaleToFill;
        toolbarUpShadow.opaque = YES;
        toolbarUpShadow.alpha = .3f;
        [sectionView addSubview:toolbarUpShadow];
    }
    
    int labelFontSize = sectionHeight > 16 ? sectionHeight - 10 : sectionHeight - 5;
    int labelOriginY = sectionHeight > 16 ? 2 : 1;
    BOOL isRetina = ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] >= 2);
    float shadowOffset = isRetina ? 1.0f/[[UIScreen mainScreen] scale] : 1.0f;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, labelOriginY, viewWidth - 20, sectionHeight)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    [label setShadowColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.4]];
    [label setShadowOffset:CGSizeMake(0, shadowOffset)];
    label.font = [UIFont boldSystemFontOfSize: labelFontSize];
    label.text = sectionTitle;
    [label sizeToFit];
    [sectionView addSubview:label];
    
    return sectionView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (albumView && [self.richResults count]>0){
        return albumViewHeight + 2;
    }
    else if (episodesView  && [self.richResults count]>0 && !(tableView == self.searchDisplayController.searchResultsTableView)){
        return albumViewHeight + 2;
    }
    else if (section!=0 || tableView == self.searchDisplayController.searchResultsTableView){
        return sectionHeight;
    }
    if ([[self.sections allKeys] count] == 1){
        return 1;
    }
    return 0;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

#pragma mark - ScrollView Delegate

-(void)scrollViewDidScrollToTop:(UIScrollView *)scrollView{
    UISearchBarLeftButton *bar = (UISearchBarLeftButton *)self.searchDisplayController.searchBar;
    bar.isVisible = YES;
    if (enableCollectionView == YES){ // temp hack to avoid the iOS7 search bar disappearing!!!
        [self.searchDisplayController.searchBar removeFromSuperview];
        [activeLayoutView addSubview:self.searchDisplayController.searchBar];
    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    hideSearchBarActive = YES;
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate){
        hideSearchBarActive = NO;
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    hideSearchBarActive = NO;
}

// iOS7 scrolling performance boost for a UITableView/UICollectionView with a custom UISearchBar header
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (!hideSearchBarActive || [scrollView isEqual:self.searchDisplayController.searchResultsTableView]) return;
    NSArray *paths;
    NSIndexPath *searchBarPath;
    NSInteger sectionNumber = [self.sections count] > 1 ? 1 : 0;
    UISearchBarLeftButton *bar = (UISearchBarLeftButton *)self.searchDisplayController.searchBar;
    if ([self.richResults count]){
        if ([scrollView isEqual:dataList]){
            paths = [dataList indexPathsForVisibleRows];
            searchBarPath = [NSIndexPath indexPathForRow:0 inSection:sectionNumber];
        }
        else if ([scrollView isEqual:collectionView]){
            paths = [collectionView indexPathsForVisibleItems];
            searchBarPath = [NSIndexPath indexPathForItem:0 inSection:sectionNumber];
        }
        if ([paths containsObject:searchBarPath]){
            bar.isVisible = YES;
            if (enableCollectionView == YES){ // temp hack to avoid the iOS7 search bar disappearing!!!
                [self.searchDisplayController.searchBar removeFromSuperview];
                [activeLayoutView addSubview:self.searchDisplayController.searchBar];
            }
        }
        else{
            bar.isVisible = NO;
        }
    }
}

#pragma mark - Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope{
	/*
	 Update the filtered array based on the search text and scope.
	 */
	[self.filteredListContent removeAllObjects]; // First clear the filtered array.
	
	/*
	 Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
	 */
	for (NSDictionary *item in self.richResults){
//		if ([scope isEqualToString:@"All"] || [[NSString stringWithFormat:@"%@",[item objectForKey:@"label"]] isEqualToString:scope])
//		{
//			NSComparisonResult result = [[NSString stringWithFormat:@"%@",[item objectForKey:@"label"]] compare:searchText options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [searchText length])];
//            if (result == NSOrderedSame)
//			{
//				[self.filteredListContent addObject:item];
//            }
        
        NSRange range = [[NSString stringWithFormat:@"%@",[item objectForKey:@"label"]] rangeOfString:searchText options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound) {
            [self.filteredListContent addObject:item];
        }
//		}
	}
    numFilteredResults = (int)[self.filteredListContent count];
}


#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    ((UITableView *)activeLayoutView).pullToRefreshView.alpha = 0;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        enableIpadWA = YES;
        [[activeLayoutView superview] addSubview:self.searchDisplayController.searchBar];
        [self.searchDisplayController.searchResultsTableView setContentOffset:CGPointMake(0, 0)];
    }
    UISearchBarLeftButton *bar = (UISearchBarLeftButton *)self.searchDisplayController.searchBar;
    bar.isVisible = YES;
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
    controller.searchResultsTableView.backgroundColor = [UIColor blackColor];
    if (longPressGesture == nil){
        longPressGesture = [UILongPressGestureRecognizer new];
        [longPressGesture addTarget:self action:@selector(handleLongPress)];
    }
    [collectionView removeGestureRecognizer:longPressGesture];
    [self.searchDisplayController.searchResultsTableView addGestureRecognizer:longPressGesture];
    if (enableCollectionView){
        self.indexView.hidden = YES;
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        [activeLayoutView setFrame:CGRectMake(((UITableView *)activeLayoutView).frame.origin.x, ((UITableView *)activeLayoutView).frame.origin.y - 44, ((UITableView *)activeLayoutView).frame.size.width, ((UITableView *)activeLayoutView).frame.size.height)];
    }
}

-(void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    if (longPressGesture) {
        [self.searchDisplayController.searchResultsTableView removeGestureRecognizer:longPressGesture];
    }
    if (enableCollectionView){
        if ([[self.indexView indexTitles] count] > 1){
            self.indexView.hidden = NO;
        }
        [collectionView addGestureRecognizer:longPressGesture];
    }
    if (enableIpadWA == YES){
        [activeLayoutView addSubview:self.searchDisplayController.searchBar];
        [self.searchDisplayController.searchResultsTableView setContentOffset:CGPointMake(0, 0)];
    }
    [self.searchDisplayController.searchBar layoutSubviews];
    UINavigationBar *newBar = self.navigationController.navigationBar;
    UIImageView *navBarHairlineImageView = [self findHairlineImageViewUnder:newBar];
    navBarHairlineImageView.hidden = YES;
}

- (UIImageView *)findHairlineImageViewUnder:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findHairlineImageViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}

- (void) searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.3];
        [activeLayoutView setFrame:CGRectMake(((UITableView *)activeLayoutView).frame.origin.x, ((UITableView *)activeLayoutView).frame.origin.y + 44, ((UITableView *)activeLayoutView).frame.size.width, ((UITableView *)activeLayoutView).frame.size.height)];
        [UIView commitAnimations];
    }
    ((UITableView *)activeLayoutView).pullToRefreshView.alpha = 1;
    
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (id)getCell:(NSIndexPath *)indexPath {
    id cell;
    if ([self.searchDisplayController isActive]){
        cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
    }
    else if (enableCollectionView){
        cell = [collectionView cellForItemAtIndexPath:indexPath];
    }
    else{
        cell = [dataList cellForRowAtIndexPath:indexPath];
    }
    return cell;
}

#pragma mark - Long Press & Action sheet

NSIndexPath *selected;

-(void)showActionSheet:(NSIndexPath *)indexPath sheetActions:(NSArray *)sheetActions item:(NSDictionary *)item rectOriginX:(int) rectOriginX rectOriginY:(int) rectOriginY {
    NSInteger numActions=[sheetActions count];
    if (numActions){
        NSString *title=[NSString stringWithFormat:@"%@%@%@", [item objectForKey:@"label"], [[item objectForKey:@"genre"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"\n%@", [item objectForKey:@"genre"]], [[item objectForKey:@"family"] isEqualToString:@"songid"] ? [NSString stringWithFormat:@"\n%@", [item objectForKey:@"album"]] : @""];
        if ( [[item objectForKey:@"family"] isEqualToString:@"timerid"] && [AppDelegate instance].serverVersion < 17) {
            title = [NSString stringWithFormat:@"%@\n\n%@", title, NSLocalizedString(@"-- WARNING --\nKodi API prior Krypton (v17) don't allow timers editing. Use the Kodi GUI for adding, editing and removing timers. Thank you.", nil)];
            sheetActions = [NSArray arrayWithObjects: NSLocalizedString(@"Ok", nil), nil];
        }
        id cell = [self getCell:indexPath];
        UIImageView *isRecordingImageView = (UIImageView*) [cell viewWithTag:104];
        BOOL isRecording = isRecordingImageView == nil ? false : !isRecordingImageView.hidden;
        UIActionSheet *action = [self buildActionSheetOptions:title options:sheetActions item:item recording:isRecording];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
            [action showInView:self.view];
        }
        else{
            [action showFromRect:CGRectMake(rectOriginX, rectOriginY, 1, 1) inView:self.view animated:YES];
        }    
    }
    else if (indexPath!=nil){ // No actions found, revert back to standard play action
        [self addPlayback:item indexPath:indexPath position:(int)indexPath.row shuffle:NO];
        forceMusicAlbumMode = NO;
    }
}

-(IBAction)handleLongPress{
    if (lpgr.state == UIGestureRecognizerStateBegan || longPressGesture.state == UIGestureRecognizerStateBegan){
        CGPoint p;
        CGPoint selectedPoint;
        NSIndexPath *indexPath = nil;
        NSIndexPath *indexPath2 = nil;
        if (enableCollectionView && ![self.searchDisplayController isActive]){
            p = [longPressGesture locationInView:collectionView];
            selectedPoint=[longPressGesture locationInView:self.view];
            indexPath = [collectionView indexPathForItemAtPoint:p];
           
        }
        else{
            p = [lpgr locationInView:dataList];
            selectedPoint=[lpgr locationInView:self.view];
            indexPath = [dataList indexPathForRowAtPoint:p];
            CGPoint p2 = [longPressGesture locationInView:self.searchDisplayController.searchResultsTableView];
            indexPath2 = [self.searchDisplayController.searchResultsTableView indexPathForRowAtPoint:p2];
        }
        
        if (indexPath != nil || indexPath2 != nil ){
            selected=indexPath;
            
            if ([[[self.detailItem sheetActions] objectAtIndex:choosedTab] isKindOfClass:[NSMutableArray class]]){
                [[[self.detailItem sheetActions] objectAtIndex:choosedTab] removeObject:NSLocalizedString(@"Play Trailer", nil)];
                [[[self.detailItem sheetActions] objectAtIndex:choosedTab] removeObject:NSLocalizedString(@"Mark as watched", nil)];
                [[[self.detailItem sheetActions] objectAtIndex:choosedTab] removeObject:NSLocalizedString(@"Mark as unwatched", nil)];
            }
            NSMutableArray *sheetActions=[[self.detailItem sheetActions] objectAtIndex:choosedTab];
            NSInteger numActions = [sheetActions count];
            if (numActions){
                NSDictionary *item = nil;
                if ([self.searchDisplayController isActive]){
                    selected=indexPath2;
                    selectedPoint=[longPressGesture locationInView:self.view];
                    item = [self.filteredListContent objectAtIndex:indexPath2.row];
                    [self.searchDisplayController.searchResultsTableView selectRowAtIndexPath:indexPath2 animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
                else{                    
                    if (enableCollectionView){
                        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                    }
                    else{
                        [dataList selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                    }
                    item = [[self.sections valueForKey:[self.sectionArray objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
                }
                 sheetActions = [self checkMusicPlaylists:sheetActions item:item params:[self indexKeyedMutableDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]]];
//                if ([[item objectForKey:@"filetype"] isEqualToString:@"directory"]) { // DOESN'T WORK AT THE MOMENT IN XBMC?????
//                    return;
//                }
                NSString *title=[NSString stringWithFormat:@"%@\n%@", [item objectForKey:@"label"], [item objectForKey:@"genre"]];
                id cell = [self getCell:selected];
                
                UIImageView *isRecordingImageView = (UIImageView*) [cell viewWithTag:104];
                BOOL isRecording = isRecordingImageView == nil ? false : !isRecordingImageView.hidden;
                UIActionSheet *action = [self buildActionSheetOptions:title options:sheetActions item:item recording:isRecording];
                
                if ([[item objectForKey:@"trailer"] isKindOfClass:[NSString class]]){
                    if ([[item objectForKey:@"trailer"] length]!=0 && [[[self.detailItem sheetActions] objectAtIndex:choosedTab] isKindOfClass:[NSMutableArray class]]){
                        [action addButtonWithTitle:NSLocalizedString(@"Play Trailer", nil)];
                        [[[self.detailItem sheetActions] objectAtIndex:choosedTab] addObject:NSLocalizedString(@"Play Trailer", nil)];
                    }
                }
                if ([[item objectForKey:@"family"] isEqualToString:@"movieid"] || [[item objectForKey:@"family"] isEqualToString:@"episodeid"]|| [[item objectForKey:@"family"] isEqualToString:@"musicvideoid"] || [[item objectForKey:@"family"] isEqualToString:@"tvshowid"]){
                    if ([[[self.detailItem sheetActions] objectAtIndex:choosedTab] isKindOfClass:[NSMutableArray class]]){
                        NSString *actionString = @"";
                        if ([[item objectForKey:@"playcount"] intValue] == 0){
                            actionString = NSLocalizedString(@"Mark as watched", nil);
                        }
                        else{
                           actionString = NSLocalizedString(@"Mark as unwatched", nil);
                        }
                        [action addButtonWithTitle:actionString];
                        [[[self.detailItem sheetActions] objectAtIndex:choosedTab] addObject:actionString];
                    }
                }
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
                    [action showInView:self.view];
                }
                else{
                   [action showFromRect:CGRectMake(selectedPoint.x, selectedPoint.y, 1, 1) inView:self.view animated:YES];
                }
            }
        }
    }
}

-(UIActionSheet *)buildActionSheetOptions:(NSString *)title options:(NSArray *)sheetActions item:(NSDictionary *)item recording:(BOOL)isRecording {
    
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:title
                                                        delegate:self
                                               cancelButtonTitle:nil
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:nil
                            ];
    action.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    NSInteger numActions = [sheetActions count];
    for (int i = 0; i < numActions; i++) {
        title = [sheetActions objectAtIndex:i];
        if ([title isEqualToString:NSLocalizedString(@"Record", nil)] && isRecording) {
            title = NSLocalizedString(@"Stop Recording", nil);
        }
        [action addButtonWithTitle:title];
    }
    action.cancelButtonIndex = [action addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    return action;
}

-(void)markVideo:(NSMutableDictionary *)item indexPath:(NSIndexPath *)indexPath watched:(int)watched{
    id cell;
    UITableView *tableView;
    BOOL isTableView = FALSE;
    if ([self.searchDisplayController isActive]){
        cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
        isTableView = TRUE;
        tableView = self.searchDisplayController.searchResultsTableView;
    }
    else if (enableCollectionView){
        cell = [collectionView cellForItemAtIndexPath:indexPath];
        isTableView = FALSE;
    }
    else{
        cell = [dataList cellForRowAtIndexPath:indexPath];
        isTableView = TRUE;
        tableView = dataList;
    }
    UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
    [queuing startAnimating];

    NSString *methodToCall = @"";
    if ([[item objectForKey:@"family"] isEqualToString:@"episodeid"]){
        methodToCall = @"VideoLibrary.SetEpisodeDetails";
    }
    else if ([[item objectForKey:@"family"] isEqualToString:@"tvshowid"]){
        methodToCall = @"VideoLibrary.SetTVShowDetails";
    }
    else if ([[item objectForKey:@"family"] isEqualToString:@"movieid"]){
        methodToCall = @"VideoLibrary.SetMovieDetails";
    }
    else if ([[item objectForKey:@"family"] isEqualToString:@"musicvideoid"]){
        methodToCall = @"VideoLibrary.SetMusicVideoDetails";
    }
    else{
        [queuing stopAnimating];
        return;
    }
    [jsonRPC
     callMethod:methodToCall
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                     [item objectForKey:[item objectForKey:@"family"]], [item objectForKey:@"family"],
                     [NSNumber numberWithInt:watched], @"playcount",
                     nil]
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if ( error == nil && methodError == nil ) {
             if ( isTableView == TRUE ) {
                 UIImageView *flagView = (UIImageView*) [cell viewWithTag:9];
                 if ( watched > 0 ){
                     [flagView setHidden:NO];
                 }
                 else{
                     [flagView setHidden:YES];
                 }
                 [tableView deselectRowAtIndexPath:indexPath animated:YES];
             }
             else{
                 if ( watched > 0 ) {
                     [cell setOverlayWatched:YES];
                 }
                 else{
                     [cell setOverlayWatched:NO];
                 }
                 [collectionView deselectItemAtIndexPath:indexPath animated:YES];
             }
             [item setObject:[NSNumber numberWithInt:watched] forKey:@"playcount"];
             
             NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
             NSMutableDictionary *mutableParameters = [[parameters objectForKey:@"parameters"] mutableCopy];
             NSMutableArray *mutableProperties = [[[parameters objectForKey:@"parameters"] objectForKey:@"properties"] mutableCopy];
             if ([[parameters objectForKey:@"FrodoExtraArt"] boolValue] == YES && [AppDelegate instance].serverVersion > 11){
                 [mutableProperties addObject:@"art"];
                 [mutableParameters setObject:mutableProperties forKey:@"properties"];
             }
             if ([mutableParameters objectForKey: @"file_properties"]!=nil){
                 [mutableParameters setObject: [mutableParameters objectForKey: @"file_properties"] forKey: @"properties"];
                 [mutableParameters removeObjectForKey: @"file_properties"];
             }
             [self saveData:mutableParameters];
             [queuing stopAnimating];
         }
         else{
             [queuing stopAnimating];
         }
     }];
}

-(void)saveSortMethod:(NSString *)sortMethod parameters:(NSDictionary *)parameters {
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[self.detailItem mainMethod] objectAtIndex:choosedTab]];
    NSString *sortKey = [NSString stringWithFormat:@"%@_sort_method", [self getCacheKey:[methods objectForKey:@"method"] parameters:[parameters mutableCopy]]];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    [userDefaults setObject:sortMethod forKey:sortKey];
}

-(void)saveSortAscDesc:(NSString *)sortAscDescSave parameters:(NSDictionary *)parameters {
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[self.detailItem mainMethod] objectAtIndex:choosedTab]];
    NSString *sortKey = [NSString stringWithFormat:@"%@_sort_ascdesc", [self getCacheKey:[methods objectForKey:@"method"] parameters:[parameters mutableCopy]]];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    [userDefaults setObject:sortAscDescSave forKey:sortKey];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    NSString *option = [actionSheet buttonTitleAtIndex:buttonIndex];
    if (buttonIndex!=actionSheet.cancelButtonIndex){
        NSMutableDictionary *item = nil;
        if (selected != nil){
            if ([self.searchDisplayController isActive]){
                item = [self.filteredListContent objectAtIndex:selected.row];
            }
            else{
                item = [[self.sections valueForKey:[self.sectionArray objectAtIndex:selected.section]] objectAtIndex:selected.row];
            }
        }
        if ([option isEqualToString:NSLocalizedString(@"Play", nil)]){
            NSString *songid = [NSString stringWithFormat:@"%@", [item objectForKey:@"songid"]];
            if ([songid intValue]){
                [self addPlayback:item indexPath:selected position:(int)selected.row shuffle:NO];
            }
            else {
                [self addPlayback:item indexPath:selected position:0 shuffle:NO];
            }
        }
        else if ([option isEqualToString:NSLocalizedString(@"Record", nil)] || [option isEqualToString:NSLocalizedString(@"Stop Recording", nil)]){
            [self recordChannel:item indexPath:selected];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Delete timer", nil)]){
            [self deleteTimer:item indexPath:selected];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Play in shuffle mode", nil)]){
            [self addPlayback:item indexPath:selected position:0 shuffle:YES];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Queue", nil)]){
            [self addQueue:item indexPath:selected];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Queue after current", nil)]){
            [self addQueue:item indexPath:selected afterCurrentItem:YES];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Show Content", nil)]){
            [self exploreItem:item];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Channel Guide", nil)]){
            [self viewChild:selected item:item displayPoint:CGPointMake(0, 0)];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Mark as watched", nil)]){
            [self markVideo:(NSMutableDictionary *)item indexPath:selected watched:1];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Mark as unwatched", nil)]){
            [self markVideo:(NSMutableDictionary *)item indexPath:selected watched:0];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Play in party mode", nil)]){
            [self partyModeItem:item indexPath:selected];
        }
        else if ([option rangeOfString:NSLocalizedString(@"Details", nil)].location!= NSNotFound){
            if (forceMusicAlbumMode){
                [self prepareShowAlbumInfo:nil];
            }
            else {
                [self showInfo:selected menuItem:self.detailItem item:item tabToShow:choosedTab];
            }
        }
        else if ([option isEqualToString:NSLocalizedString(@"Play Trailer", nil)]){
            [self playerOpen:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:@"trailer"], @"file", nil], @"item", nil] index:selected];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Open with VLC", nil)]){
            [self openWithVLC:item indexPath:selected];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Search Wikipedia", nil)]){
            [self searchWeb:(NSMutableDictionary *)item indexPath:selected serviceURL:[NSString stringWithFormat:@"http://%@.m.wikipedia.org/wiki?search=%%@", NSLocalizedString(@"WIKI_LANG", nil)]];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Search last.fm charts", nil)]){
            [self searchWeb:(NSMutableDictionary *)item indexPath:selected serviceURL:@"http://m.last.fm/music/%@/+charts?subtype=tracks&rangetype=6month&go=Go"];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Execute program", nil)] ||
                 [option isEqualToString:NSLocalizedString(@"Execute video add-on", nil)] ||
                 [option isEqualToString:NSLocalizedString(@"Execute audio add-on", nil)]){
            [self SimpleAction:@"Addons.ExecuteAddon"
                        params:[NSDictionary dictionaryWithObjectsAndKeys:
                                [item objectForKey:@"addonid"], @"addonid",
                                nil]
                       success: NSLocalizedString(@"Add-on executed successfully", nil)
                       failure:NSLocalizedString(@"Unable to execute the add-on", nil)
             ];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Execute action", nil)]){
            [self SimpleAction:@"Input.ExecuteAction"
                        params:[NSDictionary dictionaryWithObjectsAndKeys:
                                [item objectForKey:@"label"], @"action",
                                nil]
                       success: NSLocalizedString(@"Action executed successfully", nil)
                       failure:NSLocalizedString(@"Unable to  execute the action", nil)
             ];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Activate window", nil)]){
            [self SimpleAction:@"GUI.ActivateWindow"
                        params:[NSDictionary dictionaryWithObjectsAndKeys:
                                [item objectForKey:@"label"], @"window",
                                nil]
                       success: NSLocalizedString(@"Window activated successfully", nil)
                       failure:NSLocalizedString(@"Unable to  activate the window", nil)
             ];
        }
        
        else if ([option isEqualToString:NSLocalizedString(@"Add button", nil)]){
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [item objectForKey:@"addonid"], @"addonid",
                                    nil];
            NSDictionary *newButton = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       [item objectForKey:@"label"], @"label",
                                       @"xbmc-exec-addon", @"type",
                                       [item objectForKey:@"thumbnail"], @"icon",
                                       [NSNumber numberWithInt:0], @"xbmcSetting",
                                       [item objectForKey:@"genre"], @"helpText",
                                       [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"Addons.ExecuteAddon", @"command",
                                        params, @"params",
                                        nil], @"action",
                                       nil];
            [self saveCustomButton:newButton];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Add action button", nil)]){
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [item objectForKey:@"label"], @"action",
                                    nil];
            NSDictionary *newButton = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       [item objectForKey:@"label"], @"label",
                                       @"string", @"type",
                                       [item objectForKey:@"thumbnail"], @"icon",
                                       [NSNumber numberWithInt:0], @"xbmcSetting",
                                       [item objectForKey:@"genre"], @"helpText",
                                       [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"Input.ExecuteAction", @"command",
                                        params, @"params",
                                        nil], @"action",
                                       nil];
            [self saveCustomButton:newButton];
        }
        else if ([option isEqualToString:NSLocalizedString(@"Add window activation button", nil)]){
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [item objectForKey:@"label"], @"window",
                                    nil];
            NSDictionary *newButton = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       [item objectForKey:@"label"], @"label",
                                       @"string", @"type",
                                       [item objectForKey:@"thumbnail"], @"icon",
                                       [NSNumber numberWithInt:0], @"xbmcSetting",
                                       [item objectForKey:@"genre"], @"helpText",
                                       [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"GUI.ActivateWindow", @"command",
                                        params, @"params",
                                        nil], @"action",
                                       nil];
            [self saveCustomButton:newButton];
        }
        else {
            NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
            NSMutableDictionary *sortDictionary = [[[parameters objectForKey:@"parameters"] objectForKey:@"sort"] objectForKey:@"available_methods"];
            if ([sortDictionary objectForKey:@"label"] != nil){
                NSUInteger sort_method_index = [[sortDictionary objectForKey:@"label"] indexOfObject:option];
                if(sort_method_index != NSNotFound) {
                    if (sort_method_index < [[sortDictionary objectForKey:@"method"] count]) {
                        [activityIndicatorView startAnimating];
                        [UIView transitionWithView: activeLayoutView
                                          duration: 0.2
                                           options: UIViewAnimationOptionBeginFromCurrentState
                                        animations: ^ {
                                            [(UITableView *)activeLayoutView setAlpha:1.0];
                                            CGRect frame;
                                            frame = [activeLayoutView frame];
                                            frame.origin.x = viewWidth;
                                            frame.origin.y = 0;
                                            [(UITableView *)activeLayoutView setFrame:frame];
                                        }
                                        completion:^(BOOL finished){
                                            NSString *sortMethod = [[sortDictionary objectForKey:@"method"] objectAtIndex:sort_method_index];
                                            sortMethodIndex = sort_method_index;
                                            sortMethodName = sortMethod;
                                            [self saveSortMethod:sortMethod parameters:[parameters mutableCopy]];
                                            storeSectionArray = [sectionArray copy];
                                            storeSections = [sections mutableCopy];
                                            self.sectionArray = nil;
                                            self.sections = [[NSMutableDictionary alloc] init];
                                            [self indexAndDisplayData];
                                        }];
                    }
                }
                else if ([option hasPrefix:@"\u2713"]) {
                    [activityIndicatorView startAnimating];
                    [UIView transitionWithView: activeLayoutView
                                      duration: 0.2
                                       options: UIViewAnimationOptionBeginFromCurrentState
                                    animations: ^ {
                                        [(UITableView *)activeLayoutView setAlpha:1.0];
                                        CGRect frame;
                                        frame = [activeLayoutView frame];
                                        frame.origin.x = viewWidth;
                                        frame.origin.y = 0;
                                        [(UITableView *)activeLayoutView setFrame:frame];
                                    }
                                    completion:^(BOOL finished){
                                        sortAscDesc = !([sortAscDesc isEqualToString:@"ascending"] || sortAscDesc == nil)  ? @"ascending" : @"descending";
                                        [self saveSortAscDesc:sortAscDesc parameters:[parameters mutableCopy]];
                                        storeSectionArray = [sectionArray copy];
                                        storeSections = [sections mutableCopy];
                                        self.sectionArray = nil;
                                        self.sections = [[NSMutableDictionary alloc] init];
                                        [self indexAndDisplayData];
                                    }];
                }
            }
        }
    }
    else{
        forceMusicAlbumMode = NO;
        if ([self.searchDisplayController isActive]){
            [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:selected animated:NO];
        }
        else{
            if (enableCollectionView){
                [collectionView deselectItemAtIndexPath:selected animated:NO];
            }
            else{
                [dataList deselectRowAtIndexPath:selected animated:NO];
            }
        }
    }
}

-(void)saveCustomButton:(NSDictionary *)button {
    customButton *arrayButtons = [[customButton alloc] init];
    [arrayButtons.buttons addObject:button];
    [arrayButtons saveData];
    [messagesView showMessage:NSLocalizedString(@"Button added", nil) timeout:2.0f color:[UIColor colorWithRed:39.0f/255.0f green:158.0f/255.0f blue:34.0f/255.0f alpha:0.95f]];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIInterfaceCustomButtonAdded" object: nil];
    }
}

-(void)searchWeb:(NSMutableDictionary *)item indexPath:(NSIndexPath *)indexPath serviceURL:(NSString *)serviceURL{
    if ([[self.detailItem mainParameters] count] > 0) {
        NSMutableDictionary *parameters=[self indexKeyedMutableDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:0]];
        if (((NSNull *)[parameters objectForKey:@"fromWikipedia"] != [NSNull null])) {
            if ([[parameters objectForKey:@"fromWikipedia"] boolValue] == YES) {
                [self goBack:nil];
                return;
            }
        }
    }
    self.webViewController = nil;
    self.webViewController = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
    NSString *searchString = [item objectForKey:@"label"];
    if (forceMusicAlbumMode){
        searchString = self.navigationItem.title;
        forceMusicAlbumMode = NO;
    }
    NSString *query = [searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *url = [NSString stringWithFormat:serviceURL, query]; 
	NSURL *_url = [NSURL URLWithString:url];    
    self.webViewController.urlRequest = [NSURLRequest requestWithURL:_url];
    [item setObject:[NSNumber numberWithBool:albumView] forKey:@"fromAlbumView"];
    self.webViewController.detailItem = item;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        [self.navigationController pushViewController:self.webViewController animated:YES];
    }
    else{
        CGRect frame=self.webViewController.view.frame;
        frame.size.width=STACKSCROLL_WIDTH;
        self.webViewController.view.frame=frame;
        if (stackscrollFullscreen == YES){
            [self toggleFullscreen:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:self.webViewController invokeByController:self isStackStartView:FALSE];
            });
        }
        else {
            [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:self.webViewController invokeByController:self isStackStartView:FALSE];
        }
    }
}

#pragma mark - Gestures

- (void)handleSwipeFromLeft:(id)sender {
    if (![self.detailItem disableNowPlaying]){
        [self showNowPlaying];
    }
}

- (void)handleSwipeFromRight:(id)sender {
    if ([self.navigationController.viewControllers indexOfObject:self] == 0){
        [self revealMenu:nil];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - View Configuration

- (void)setDetailItem:(id)newDetailItem{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        // Update the view.
        [self configureView];
    }
}

- (void)configureView{
    if (self.detailItem) {
        NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
        self.navigationItem.title = [parameters objectForKey:@"label"];
        UIColor *shadowColor = [[UIColor alloc] initWithRed:0.0 green:0.0 blue:0.0 alpha:0.5] ;
        topNavigationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -1, 240, 44)];
        topNavigationLabel.backgroundColor = [UIColor clearColor];
        topNavigationLabel.font = [UIFont boldSystemFontOfSize:11];
        topNavigationLabel.minimumScaleFactor=8.0f/11.0f;
        topNavigationLabel.numberOfLines=2;
        topNavigationLabel.adjustsFontSizeToFitWidth = YES;
        topNavigationLabel.textAlignment = NSTextAlignmentLeft;
        topNavigationLabel.textColor = [UIColor whiteColor];
        topNavigationLabel.shadowColor = shadowColor;
        topNavigationLabel.shadowOffset    = CGSizeMake (0.0, -1.0);
        topNavigationLabel.highlightedTextColor = [UIColor blackColor];
        topNavigationLabel.opaque=YES;
        topNavigationLabel.text=[self.detailItem mainLabel];
        self.navigationItem.title = [self.detailItem mainLabel];
        if (![self.detailItem disableNowPlaying]){
            UIBarButtonItem *nowPlayingButtonItem = nil;
            nowPlayingButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Now Playing", nil) style:UIBarButtonItemStylePlain target:self action:@selector(showNowPlaying)];
            [nowPlayingButtonItem setTitleTextAttributes:
             [NSDictionary dictionaryWithObjectsAndKeys:
              [UIFont systemFontOfSize:12], NSFontAttributeName,
              nil] forState:UIControlStateNormal];
            self.navigationItem.rightBarButtonItem=nowPlayingButtonItem;
            
            UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromLeft:)];
            leftSwipe.numberOfTouchesRequired = 1;
            leftSwipe.cancelsTouchesInView = NO;
            leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
            [self.view addGestureRecognizer:leftSwipe];
        }
        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromRight:)];
        rightSwipe.numberOfTouchesRequired = 1;
        rightSwipe.cancelsTouchesInView=NO;
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:rightSwipe];
   }
}

-(CGRect)currentScreenBoundsDependOnOrientation {
    NSString *reqSysVer = @"8.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending) {
        return [UIScreen mainScreen].bounds;
    }
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if(UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        screenBounds.size = CGSizeMake(width, height);
    }
    else if(UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        screenBounds.size = CGSizeMake(height, width);
    }
    return screenBounds ;
}

- (void)toggleFullscreen:(id)sender {
    [activityIndicatorView startAnimating];
    float animDuration = 0.5f;
    if (stackscrollFullscreen == YES) {
        stackscrollFullscreen = NO;
        [UIView animateWithDuration:0.1f
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             collectionView.alpha = 0;
                             dataList.alpha = 0;
                             button1.alpha = button2.alpha = button3.alpha = button4.alpha = button5.alpha = buttonsViewBgToolbar.alpha = topNavigationLabel.alpha = buttonsViewBgImage.alpha = 1.0f;
                            
                         }
                         completion:^(BOOL finished) {
                             viewWidth = STACKSCROLL_WIDTH;
                             UISearchBarLeftButton *bar = (UISearchBarLeftButton *)self.searchDisplayController.searchBar;
                             bar.storeWidth = viewWidth;
                             if ([self collectionViewCanBeEnabled] == YES){
                                 [bar showLeftButton:YES];
                             }
                             [bar layoutSubviews];
                             sectionArray = [storeSectionArray copy];
                             sections = [storeSections mutableCopy];
                             [self choseParams];
                             if (forceCollection){
                                 forceCollection = NO;
                                 [self AnimTable:(UITableView *)activeLayoutView AnimDuration:0.0 Alpha:0.0 XPos:viewWidth];
                                 enableCollectionView = NO;
                                 [self configureLibraryView];
                                 [self AnimTable:(UITableView *)activeLayoutView AnimDuration:0.0 Alpha:0.0 XPos:0];
                             }
                             [self setFlowLayoutParams];
                             [collectionView.collectionViewLayout invalidateLayout];
                             [collectionView reloadData];
                             [collectionView setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
                             NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     [NSNumber numberWithFloat:animDuration], @"duration",
                                                     nil];
                             [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollFullScreenDisabled" object:self.view userInfo:params];
                             [UIView animateWithDuration:0.2f
                                                   delay:0.0f
                                                 options:UIViewAnimationOptionCurveEaseInOut
                                              animations:^{
                                                  collectionView.alpha = 1;
                                                  dataList.alpha = 1;
                                                  [fullscreenButton setImage:[UIImage imageNamed:@"button_fullscreen"] forState:UIControlStateNormal];
                                                  fullscreenButton.backgroundColor = [UIColor clearColor];
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
        [UIView animateWithDuration:0.1f
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             collectionView.alpha = 0;
                             dataList.alpha = 0;
                             button1.alpha = button2.alpha = button3.alpha = button4.alpha = button5.alpha = buttonsViewBgToolbar.alpha = topNavigationLabel.alpha = buttonsViewBgImage.alpha = 0.0f;
                         }
                         completion:^(BOOL finished) {
                             UISearchBarLeftButton *bar = (UISearchBarLeftButton *)self.searchDisplayController.searchBar;
                             viewWidth = [self currentScreenBoundsDependOnOrientation].size.width;
                             bar.storeWidth = viewWidth;
                             [bar showLeftButton:NO];
                             [bar layoutSubviews];
                             moreItemsViewController.view.hidden = YES;
                             storeSectionArray = [sectionArray copy];
                             storeSections = [sections mutableCopy];
                             [self choseParams];
                             NSMutableDictionary *sectionsTemp = [[NSMutableDictionary alloc] init];
                             [sectionsTemp setValue:[[NSMutableArray alloc] init] forKey:@""];
                             for (id key in self.sectionArray){
                                 NSDictionary *tmp = [self.sections objectForKey:key];
                                 for (NSDictionary *item in tmp) {
                                     [[sectionsTemp objectForKey:@""] addObject:item];
                                 }
                             }
                             self.sectionArray = [[NSArray alloc] initWithObjects:@"", nil];
                             self.sections = [sectionsTemp mutableCopy];
                             if (!enableCollectionView){
                                 forceCollection = YES;
                                 [self AnimTable:(UITableView *)activeLayoutView AnimDuration:0.0 Alpha:0.0 XPos:viewWidth];
                                 enableCollectionView = YES;
                                 [self configureLibraryView];
                                 [self AnimTable:(UITableView *)activeLayoutView AnimDuration:0.0 Alpha:0.0 XPos:0];
                             }
                             else {
                                 forceCollection = NO;
                             }
                             [self setFlowLayoutParams];
                             [collectionView.collectionViewLayout invalidateLayout];
                             [collectionView reloadData];
                             [collectionView setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
                             NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     [NSNumber numberWithBool:NO], @"hideToolbar",
                                                     [NSNumber numberWithFloat:animDuration], @"duration",
                                                     nil];
                             [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollFullScreenEnabled" object:self.view userInfo:params];
                             [UIView animateWithDuration:0.2f
                                                   delay:0.0f
                                                 options:UIViewAnimationOptionCurveEaseInOut
                                              animations:^{
                                                  collectionView.alpha = 1;
                                                  [fullscreenButton setImage:[UIImage imageNamed:@"button_exit_fullscreen"] forState:UIControlStateNormal];
                                                  fullscreenButton.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
                                              }
                                              completion:^(BOOL finished) {
                                                  [activityIndicatorView stopAnimating];
                                              }
                              ];
                         }
         ];
    }
}

- (void)dismissAddAction:(id)sender{
    [self dismissViewControllerAnimated:YES completion:^ {
    }];
}

#pragma mark - WebView for playback

- (void)webViewDidStartLoad: (UIWebView *)webView{
//    NSLog(@"START");
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
//    NSLog(@"Loading: %@", [request URL]);
    return YES;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
//    NSLog(@"didFinish: %@; stillLoading:%@", [[webView request]URL],
//          (webView.loading?@"NO":@"YES"));
//    if (webView.loading)
//        return;
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
//    NSLog(@"didFail: %@; stillLoading:%@", [[webView request]URL],
//          (webView.loading?@"NO":@"YES"));
}

-(void)showNowPlaying{
    if (!alreadyPush){
        //self.nowPlaying=nil;
        if (self.nowPlaying == nil){
            self.nowPlaying = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
        }
        self.nowPlaying.detailItem = self.detailItem;
//        self.nowPlaying.presentedFromNavigation = YES;
        
        [self.navigationController pushViewController:self.nowPlaying animated:YES];
        alreadyPush=YES;
    }
}

# pragma mark - Playback Management

-(void)partyModeItem:(NSDictionary *)item indexPath:(NSIndexPath *)indexPath{
    NSString *smartplaylist = [item objectForKey:@"file"];
    if (smartplaylist == nil) {
        return;
    }
    [self playerOpen:[NSDictionary dictionaryWithObjectsAndKeys:
                      [NSDictionary dictionaryWithObjectsAndKeys:smartplaylist, @"partymode", nil], @"item", nil] index:indexPath];
//    id cell;
//    if ([self.searchDisplayController isActive]){
//        cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
//    }
//    else if (enableCollectionView){
//        cell = [collectionView cellForItemAtIndexPath:indexPath];
//    }
//    else{
//        cell = [dataList cellForRowAtIndexPath:indexPath];
//    }
//    UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
//    [queuing startAnimating];
//    [jsonRPC
//     callMethod:@"Player.Open"
//     withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
//                     [NSDictionary dictionaryWithObjectsAndKeys:smartplaylist, @"partymode", nil], @"item", nil]
//     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
//         [queuing stopAnimating];
//
//         if (error==nil && methodError==nil){
//             [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
//             [self showNowPlaying];
//         }
////         else {
////             NSLog(@"errore %@",methodError);
////         }
//     }];
}

-(void)exploreItem:(NSDictionary *)item{
    self.detailViewController=nil;
    mainMenu *MenuItem=self.detailItem;
    NSDictionary *mainFields=[[MenuItem mainFields] objectAtIndex:choosedTab];
    MenuItem.subItem.mainLabel=[item objectForKey:@"label"];
    NSMutableDictionary *parameters=[self indexKeyedMutableDictionaryFromArray:[[MenuItem.subItem mainParameters] objectAtIndex:choosedTab]];
    NSString *libraryRowHeight= [NSString stringWithFormat:@"%d", MenuItem.subItem.rowHeight];
    NSString *libraryThumbWidth= [NSString stringWithFormat:@"%d", MenuItem.subItem.thumbWidth];
    if ([parameters objectForKey:@"rowHeight"] != nil){
        libraryRowHeight = [parameters objectForKey:@"rowHeight"];
    }
    if ([parameters objectForKey:@"thumbWidth"] != nil){
        libraryThumbWidth = [parameters objectForKey:@"thumbWidth"];
    }
    NSString *filemodeRowHeight= @"44";
    NSString *filemodeThumbWidth= @"44";
    if ([parameters objectForKey:@"rowHeight"] != nil){
        filemodeRowHeight = [parameters objectForKey:@"rowHeight"];
    }
    if ([parameters objectForKey:@"thumbWidth"] != nil){
        filemodeThumbWidth = [parameters objectForKey:@"thumbWidth"];
    }
    NSMutableArray *newParameters=[NSMutableArray arrayWithObjects:
                                   [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [item objectForKey:[mainFields objectForKey:@"row6"]],@"directory",
                                    [[parameters objectForKey:@"parameters"] objectForKey:@"media"], @"media",
                                    [[parameters objectForKey:@"parameters"] objectForKey:@"sort"],@"sort",
                                    [[parameters objectForKey:@"parameters"] objectForKey:@"file_properties"], @"file_properties",
                                    nil], @"parameters",
                                   libraryRowHeight, @"rowHeight", libraryThumbWidth, @"thumbWidth",
                                   [parameters objectForKey:@"label"], @"label", @"nocover_filemode.png", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeThumbWidth, @"thumbWidth",
                                   [NSDictionary dictionaryWithDictionary:[parameters objectForKey:@"itemSizes"]], @"itemSizes",
                                   [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"enableCollectionView"] boolValue]], @"enableCollectionView",
                                   @"Files.GetDirectory", @"exploreCommand",
                                   [parameters objectForKey:@"disableFilterParameter"], @"disableFilterParameter",
                                   nil];
    [[MenuItem.subItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
    MenuItem.subItem.chooseTab=choosedTab;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        
        self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
        self.detailViewController.detailItem = MenuItem.subItem;
        [self.navigationController pushViewController:self.detailViewController animated:YES];
    }
    else{
        if (stackscrollFullscreen == YES){
            [self toggleFullscreen:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem.subItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
            });
        }
        else {
            DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem.subItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
            [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
        }
    }
}

-(void)openWithVLC:(NSDictionary *)item indexPath:(NSIndexPath *)indexPath{
    id cell;
    if ([self.searchDisplayController isActive]){
        cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
    }
    else if (enableCollectionView){
        cell = [collectionView cellForItemAtIndexPath:indexPath];
    }
    else{
        cell = [dataList cellForRowAtIndexPath:indexPath];
    }
    UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
    [queuing startAnimating];
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"vlc://"]]){
        [queuing stopAnimating];
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot do that", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        [alertView show];
    }
    else {
        [jsonRPC callMethod:@"Files.PrepareDownload" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[item objectForKey:@"file"], @"path", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            if (error==nil && methodError==nil){
                if( [methodResult count] > 0){
                    GlobalData *obj=[GlobalData getInstance];
                    NSString *userPassword = [[AppDelegate instance].obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", [AppDelegate instance].obj.serverPass];
                    NSString *serverURL = [NSString stringWithFormat:@"%@%@@%@:%@", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
                    NSString *stringURL = [NSString stringWithFormat:@"vlc://%@://%@/%@",(NSArray*)[methodResult objectForKey:@"protocol"], serverURL, [(NSDictionary*)[methodResult objectForKey:@"details"] objectForKey:@"path"]];
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:stringURL]];
                    [queuing stopAnimating];
                }
            }
            else {
                [queuing stopAnimating];
            }
        }];
    }
}

-(void)deleteTimer:(NSDictionary *)item indexPath:(NSIndexPath *)indexPath {
    NSNumber *itemid = [NSNumber numberWithInt:[[item objectForKey:@"timerid"] intValue]];
    if ([itemid isEqualToValue:[NSNumber numberWithInt:0]]) {
        return;
    }
    id cell;
    if ([self.searchDisplayController isActive]){
        cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
    }
    else if (enableCollectionView){
        cell = [collectionView cellForItemAtIndexPath:indexPath];
    }
    else{
        cell = [dataList cellForRowAtIndexPath:indexPath];
    }
    UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
    NSString *methodToCall = @"PVR.DeleteTimer";
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                itemid, @"timerid",
                                nil];

    [queuing startAnimating];
    [jsonRPC callMethod:methodToCall
         withParameters:parameters
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               [queuing stopAnimating];
               if ([self.searchDisplayController isActive]){
                   [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:indexPath animated:NO];
               }
               else{
                   if (enableCollectionView){
                       [collectionView deselectItemAtIndexPath:indexPath animated:NO];
                   }
                   else{
                       [dataList deselectRowAtIndexPath:indexPath animated:NO];
                   }
               }
               if (error == nil && methodError == nil) {
                   [self.searchDisplayController setActive:NO animated:NO];
                   [self AnimTable:(UITableView *)activeLayoutView AnimDuration:0.3f Alpha:1.0 XPos:viewWidth];
                   [self startRetrieveDataWithRefresh:YES];
               }
               else {
                   NSString *message = @"";
                   message = [NSString stringWithFormat:@"METHOD\n%@\n\nPARAMETERS\n%@\n", methodToCall, [[[NSString stringWithFormat:@"%@", parameters] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
                   if (methodError != nil){
                       message = [NSString stringWithFormat:@"%@\n\n%@\n", methodError, message];
                   }
                   if (error != nil){
                       message = [NSString stringWithFormat:@"%@\n\n%@\n", error.localizedDescription, message];
                       
                   }
                   UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR", nil)
                                                                       message:message
                                                                      delegate:self
                                                             cancelButtonTitle:nil
                                                             otherButtonTitles:@"Copy to clipboard", nil];
                   [alertView show];
               }
    }];
}

-(void)recordChannel:(NSMutableDictionary *)item indexPath:(NSIndexPath *)indexPath {
    NSString *methodToCall = @"PVR.Record";
    NSString *parameterName = @"channel";
    NSNumber *itemid = [NSNumber numberWithInt:[[item objectForKey:@"channelid"] intValue]];
    NSNumber *storeChannelid = itemid;
    NSNumber *storeBroadcastid = [NSNumber numberWithInt:[[item objectForKey:@"broadcastid"] intValue]];
    if ([itemid isEqualToValue:[NSNumber numberWithInt:0]]) {
        itemid = [NSNumber numberWithInt:[[[item objectForKey:@"pvrExtraInfo"] objectForKey:@"channelid"] intValue]];
        if ([itemid isEqualToValue:[NSNumber numberWithInt:0]]) {
            return;
        }
        storeChannelid = itemid;
        NSDate *starttime = [xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", [item objectForKey:@"starttime"]]];
        NSDate *endtime = [xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", [item objectForKey:@"endtime"]]];
        float total_seconds = [endtime timeIntervalSince1970] - [starttime timeIntervalSince1970];
        float elapsed_seconds = [[NSDate date] timeIntervalSince1970] - [starttime timeIntervalSince1970];
        float percent_elapsed = (elapsed_seconds/total_seconds) * 100.0f;
        if (percent_elapsed < 0) {
            itemid = [NSNumber numberWithInt:[[item objectForKey:@"broadcastid"] intValue]];
            storeBroadcastid = itemid;
            storeChannelid = [NSNumber numberWithInteger:0];
            methodToCall = @"PVR.ToggleTimer";
            parameterName = @"broadcastid";
        }
    }
    id cell;
    if ([self.searchDisplayController isActive]){
        cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
    }
    else if (enableCollectionView){
        cell = [collectionView cellForItemAtIndexPath:indexPath];
    }
    else{
        cell = [dataList cellForRowAtIndexPath:indexPath];
    }
    UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
    [queuing startAnimating];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                itemid, parameterName,
                                nil];
    [jsonRPC callMethod:methodToCall
         withParameters:parameters
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               [queuing stopAnimating];
               if ([self.searchDisplayController isActive]){
                   [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:indexPath animated:NO];
               }
               else{
                   if (enableCollectionView){
                       [collectionView deselectItemAtIndexPath:indexPath animated:NO];
                   }
                   else{
                       [dataList deselectRowAtIndexPath:indexPath animated:NO];
                   }
               }
               if (error==nil && methodError==nil) {
                   UIImageView *isRecordingImageView = (UIImageView*) [cell viewWithTag:104];
                   isRecordingImageView.hidden = !isRecordingImageView.hidden;
                   NSNumber *status = [NSNumber numberWithBool:![[item objectForKey:@"isrecording"] boolValue]];
                   if ([[item objectForKey:@"broadcastid"] intValue] > 0) {
                       status = [NSNumber numberWithBool:![[item objectForKey:@"hastimer"] boolValue]];
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
                    message = [NSString stringWithFormat:@"METHOD\n%@\n\nPARAMETERS\n%@\n", methodToCall, [[[NSString stringWithFormat:@"%@", parameters] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
                   if (methodError != nil){
                       message = [NSString stringWithFormat:@"%@\n\n%@\n", methodError, message];
                   }
                   if (error != nil){
                       message = [NSString stringWithFormat:@"%@\n\n%@\n", error.localizedDescription, message];
                       
                   }
                   UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR", nil)
                                                                       message:message
                                                                      delegate:self
                                                             cancelButtonTitle:nil
                                                             otherButtonTitles:@"Copy to clipboard", nil];
                   [alertView show];
               }
           }];
}

-(void)addQueue:(NSDictionary *)item indexPath:(NSIndexPath *)indexPath{
    [self addQueue:item indexPath:indexPath afterCurrentItem:NO];
}

-(void)addQueue:(NSDictionary *)item indexPath:(NSIndexPath *)indexPath afterCurrentItem:(BOOL)afterCurrent{
//    UITableViewCell *cell = [dataList cellForRowAtIndexPath:indexPath];
    id cell;
    if ([self.searchDisplayController isActive]){
        cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
    }
    else if (enableCollectionView){
        cell = [collectionView cellForItemAtIndexPath:indexPath];
    }
    else{
        cell = [dataList cellForRowAtIndexPath:indexPath];
    }
    UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
    [queuing startAnimating];
    NSDictionary *mainFields=[[self.detailItem mainFields] objectAtIndex:choosedTab];
    if (forceMusicAlbumMode){
        mainFields=[[[AppDelegate instance].playlistArtistAlbums mainFields] objectAtIndex:0];
        forceMusicAlbumMode = NO;
    }
    NSString *key = [mainFields objectForKey:@"row9"];
    id value = [item objectForKey:key];
    if ([[item objectForKey:@"filetype"] isEqualToString:@"directory"]) {
        key = @"directory";
    }
    else if ([[mainFields objectForKey:@"row9"] isEqualToString:@"recordingid"]) {
        key = @"file";
        value = [item objectForKey:@"file"];
    }
    if (afterCurrent){
        [jsonRPC
         callMethod:@"Player.GetProperties"
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                         [mainFields objectForKey:@"playlistid"], @"playerid",
                         [[NSArray alloc] initWithObjects:@"percentage", @"time", @"totaltime", @"partymode", @"position", nil], @"properties",
                         nil] 
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
             if (error==nil && methodError==nil){
                 if( [NSJSONSerialization isValidJSONObject:methodResult]){
                     if ([methodResult count]){
                         [queuing stopAnimating];            
                         int newPos = [[methodResult objectForKey:@"position"] intValue] + 1;
                         NSString *action2=@"Playlist.Insert";
                         NSDictionary *params2=[NSDictionary dictionaryWithObjectsAndKeys:
                                                [mainFields objectForKey:@"playlistid"], @"playlistid",
                                                [NSDictionary dictionaryWithObjectsAndKeys: value, key, nil],@"item",
                                                [NSNumber numberWithInt:newPos],@"position",
                                                nil];
                         [jsonRPC callMethod:action2 withParameters:params2 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                             if (error==nil && methodError==nil){
                                 [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil]; 
                             }
                         
                         }];
                     }
                     else{
                         [self addToPlaylist:mainFields currentItem:value currentKey:key currentActivityIndicator:queuing];
                     }
                 }
                 else{
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

-(void)addToPlaylist:(NSDictionary *)mainFields currentItem:(id)value currentKey:(NSString *)key currentActivityIndicator:(UIActivityIndicatorView *)queuing{
    [jsonRPC callMethod:@"Playlist.Add" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[mainFields objectForKey:@"playlistid"], @"playlistid", [NSDictionary dictionaryWithObjectsAndKeys: value, key, nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        [queuing stopAnimating];
        if (error==nil && methodError==nil){
            [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil]; 
        }
    }];
    
}

-(void)playerOpen:(NSDictionary *)params index:(NSIndexPath *) indexPath{
    id cell;
    if ([self.searchDisplayController isActive]){
        cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
    }
    else if (enableCollectionView){
        cell = [collectionView cellForItemAtIndexPath:indexPath];
    }
    else{
        cell = [dataList cellForRowAtIndexPath:indexPath];
    }
    UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
    [queuing startAnimating];
    [jsonRPC callMethod:@"Player.Open" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        [queuing stopAnimating];
        if (error==nil && methodError==nil){
            [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
            [self showNowPlaying];
        }
//        else {
//            NSLog(@"terzo errore %@",methodError);
//        }
    }];
}

-(void)addPlayback:(NSDictionary *)item indexPath:(NSIndexPath *)indexPath position:(int)pos shuffle:(BOOL)shuffled{
    NSDictionary *mainFields=[[self.detailItem mainFields] objectAtIndex:choosedTab];
    if (forceMusicAlbumMode){
        mainFields=[[[AppDelegate instance].playlistArtistAlbums mainFields] objectAtIndex:0];
        forceMusicAlbumMode = NO;
    }
    if ([mainFields count]==0){
        return;
    }
    id cell;
    if ([self.searchDisplayController isActive]){
        cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
    }
    else if (enableCollectionView){
        cell = [collectionView cellForItemAtIndexPath:indexPath];
    }
    else{
        cell = [dataList cellForRowAtIndexPath:indexPath];
    }
    UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
    [queuing startAnimating];
    if ([[mainFields objectForKey:@"playlistid"] intValue]==2){
        [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionary] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            int currentPlayerID=0;
            if ([methodResult count]){
                currentPlayerID=[[[methodResult objectAtIndex:0] objectForKey:@"playerid"] intValue];
            }
            if (currentPlayerID==1) { // xbmc bug
                [jsonRPC callMethod:@"Player.Stop" withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:1], @"playerid", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                    if (error==nil && methodError==nil) {
                        [self playerOpen:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:@"file"], @"file", nil], @"item", nil] index:indexPath];
                    }
                    else {
                        UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
                        [queuing stopAnimating];
                    }
                }];
            }
            else {
                [self playerOpen:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:@"file"], @"file", nil], @"item", nil] index:indexPath];
            }
        }];
    }
    else if ([[mainFields objectForKey:@"row8"] isEqualToString:@"channelid"] || [[mainFields objectForKey:@"row8"] isEqualToString:@"broadcastid"]) {
        NSNumber *channelid = [item objectForKey:[mainFields objectForKey:@"row8"]];
        NSString *param = @"channelid";
        if ([[mainFields objectForKey:@"row8"] isEqualToString:@"broadcastid"]) {
            channelid = [[item objectForKey:@"pvrExtraInfo"] objectForKey:@"channelid"];
        }
        [self playerOpen:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: channelid, param, nil], @"item", nil] index:indexPath];
    }
    else if ([[mainFields objectForKey:@"row7"] isEqualToString:@"plugin"]){
        [self playerOpen:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:@"file"], @"file", nil], @"item", nil] index:indexPath];
    }
    else {
        id optionsParam = nil;
        id optionsValue = nil;
        if ([AppDelegate instance].serverVersion > 11) {
            optionsParam = @"options";
            optionsValue = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:shuffled], @"shuffled", nil];
        }
        [jsonRPC callMethod:@"Playlist.Clear" withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [mainFields objectForKey:@"playlistid"], @"playlistid", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            if ( error == nil && methodError == nil ) {
                NSString *key = [mainFields objectForKey:@"row8"];
                id value = [item objectForKey:key];
                if ([[item objectForKey:@"filetype"] isEqualToString:@"directory"]) {
                    key = @"directory";
                }
                else if ([[mainFields objectForKey:@"row8"] isEqualToString:@"recordingid"]) {
                    key = @"file";
                    value = [item objectForKey:@"file"];
                }
                if (shuffled && [AppDelegate instance].serverVersion > 11) {
                    [jsonRPC
                     callMethod:@"Player.SetPartymode"
                     withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0], @"playerid", [NSNumber numberWithBool:NO], @"partymode", nil]
                     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *internalError) {
                         [self playlistAndPlay:[NSDictionary dictionaryWithObjectsAndKeys:
                                                [mainFields objectForKey:@"playlistid"], @"playlistid",
                                                [NSDictionary dictionaryWithObjectsAndKeys:
                                                 value, key, nil], @"item",
                                                nil]
                                playbackParams:[NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSDictionary dictionaryWithObjectsAndKeys:
                                                 [mainFields objectForKey:@"playlistid"], @"playlistid",
                                                 [NSNumber numberWithInt: pos], @"position",
                                                 nil], @"item",
                                                optionsValue, optionsParam,
                                                nil]
                                     indexPath:indexPath
                                          cell:cell];
                     }];
                }
                else {
                    [self playlistAndPlay:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [mainFields objectForKey:@"playlistid"], @"playlistid",
                                           [NSDictionary dictionaryWithObjectsAndKeys:
                                            value, key, nil], @"item",
                                           nil]
                           playbackParams:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSDictionary dictionaryWithObjectsAndKeys:
                                            [mainFields objectForKey:@"playlistid"], @"playlistid",
                                            [NSNumber numberWithInt: pos], @"position",
                                            nil], @"item",
                                           optionsValue, optionsParam,
                                           nil]
                                indexPath:indexPath
                                     cell:cell];
                }
            }
            else {
                UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
                [queuing stopAnimating];
            }
        }];
    }
}

-(void)playlistAndPlay:(NSDictionary *)playlistParams playbackParams:(NSDictionary *)playbackParams indexPath:(NSIndexPath *)indexPath cell:(id)cell{
    [jsonRPC callMethod:@"Playlist.Add" withParameters:playlistParams onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
            [self playerOpen:playbackParams index:indexPath];
        }
        else {
            UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
            [queuing stopAnimating];
            //                                            NSLog(@"secondo errore %@",methodError);
        }
    }];
}

-(void)SimpleAction:(NSString *)action params:(NSDictionary *)parameters success:(NSString *)successMessage failure:(NSString *)failureMessage{
    [jsonRPC callMethod:action withParameters:parameters onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if ( error == nil && methodError == nil ){
            [messagesView showMessage:successMessage timeout:2.0f color:[UIColor colorWithRed:39.0f/255.0f green:158.0f/255.0f blue:34.0f/255.0f alpha:0.95f]];
        }
        else {
            [messagesView showMessage:failureMessage timeout:2.0f color:[UIColor colorWithRed:189.0f/255.0f green:36.0f/255.0f blue:36.0f/255.0f alpha:0.95f]];
        }
    }];
}

-(void)displayInfoView:(NSDictionary *)item {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.showInfoViewController=nil;
        self.showInfoViewController = [[ShowInfoViewController alloc] initWithNibName:@"ShowInfoViewController" bundle:nil];
        self.showInfoViewController.detailItem = item;
        [self.navigationController pushViewController:self.showInfoViewController animated:YES];
    }
    else {
        ShowInfoViewController *iPadShowViewController = [[ShowInfoViewController alloc] initWithNibName:@"ShowInfoViewController" withItem:item withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
        if (stackscrollFullscreen == YES) {
            [iPadShowViewController setModalPresentationStyle:UIModalPresentationFormSheet];
            UIViewController *vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
            [vc presentViewController:iPadShowViewController animated:YES completion:nil];
        }
        else {
            [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadShowViewController invokeByController:self isStackStartView:FALSE];
        }
    }
}

-(void)prepareShowAlbumInfo:(id)sender{
    if ([[self.detailItem mainParameters] count] > 0) {
        NSMutableDictionary *parameters=[self indexKeyedMutableDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:0]];
        if (((NSNull *)[parameters objectForKey:@"fromShowInfo"] != [NSNull null])) {
            if ([[parameters objectForKey:@"fromShowInfo"] boolValue] == YES) {
                [self goBack:nil];
                return;
            }
        }
    }
    mainMenu *MenuItem = nil;
    if ([sender tag] == 0){
        MenuItem = [[AppDelegate instance].playlistArtistAlbums copy];
    }
    else if ([sender tag] == 1){
        MenuItem = [[AppDelegate instance].playlistTvShows copy];
    }
    MenuItem.subItem.mainLabel=self.navigationItem.title;
    [MenuItem.subItem setMainMethod:nil];
    if ([self.richResults count]>0){
        [self.searchDisplayController.searchBar resignFirstResponder];
        [self showInfo:nil menuItem:MenuItem item:[self.richResults objectAtIndex:0] tabToShow:0];
    }
}

-(void)showInfo:(NSIndexPath *)indexPath menuItem:(mainMenu *)menuItem item:(NSDictionary *)item tabToShow:(int)tabToShow{
    NSDictionary *methods = nil;
    NSDictionary *parameters = nil;
    methods = [self indexKeyedDictionaryFromArray:[[menuItem mainMethod] objectAtIndex:tabToShow]];
    parameters = [self indexKeyedDictionaryFromArray:[[menuItem mainParameters] objectAtIndex:tabToShow]];
    
    NSMutableDictionary *mutableParameters = [[parameters objectForKey:@"extra_info_parameters"] mutableCopy];
    NSMutableArray *mutableProperties = [[[parameters objectForKey:@"extra_info_parameters"] objectForKey:@"properties"] mutableCopy];
    
    if ([[parameters objectForKey:@"FrodoExtraArt"] boolValue] == YES && [AppDelegate instance].serverVersion > 11){
        [mutableProperties addObject:@"art"];
        [mutableParameters setObject:mutableProperties forKey:@"properties"];
    }
    if ([parameters objectForKey:@"extra_info_parameters"]!=nil && [methods objectForKey:@"extra_info_method"]!=nil){
        [self retrieveExtraInfoData:[methods objectForKey:@"extra_info_method"] parameters:mutableParameters index:indexPath item:item menuItem:menuItem tabToShow:tabToShow];
    }
    else{
        [self displayInfoView:item];
    }
}


-(void)showAlbumActions:(UITapGestureRecognizer *)tap {
    NSArray *sheetActions = [NSArray arrayWithObjects:NSLocalizedString(@"Queue after current", nil), NSLocalizedString(@"Queue", nil), NSLocalizedString(@"Play", nil), NSLocalizedString(@"Play in shuffle mode", nil), NSLocalizedString(@"Album Details", nil), NSLocalizedString(@"Search Wikipedia", nil), nil];
    selected = [NSIndexPath indexPathForRow:0 inSection:0];
    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[[self.sections valueForKey:[self.sectionArray objectAtIndex:0]] objectAtIndex:0]];
    [item setObject:self.navigationItem.title forKey:@"label"];
    forceMusicAlbumMode = YES;
    int rectOrigin = (int)((albumViewHeight - (albumViewPadding * 2))/2);
    [self showActionSheet:nil sheetActions:sheetActions item:item rectOriginX:rectOrigin + albumViewPadding rectOriginY:rectOrigin];
}

//-(void)playbackAction:(NSString *)action params:(NSArray *)parameters{
//    [jsonRPC callMethod:@"Playlist.GetPlaylists" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
//        if (error==nil && methodError==nil){
////            NSLog(@"RISPOSRA %@", methodResult);
//            if( [methodResult count] > 0){
//                NSNumber *response = [[methodResult objectAtIndex:0] objectForKey:@"playerid"];
////                NSMutableArray *commonParams=[NSMutableArray arrayWithObjects:response, @"playerid", nil];
////                if (parameters!=nil)
////                    [commonParams addObjectsFromArray:parameters];
////                [jsonRPC callMethod:action withParameters:nil onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
////                    if (error==nil && methodError==nil){
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

-(void)checkExecutionTime{
    if (startTime !=0)
        elapsedTime += [NSDate timeIntervalSinceReferenceDate] - startTime;
    startTime = [NSDate timeIntervalSinceReferenceDate];
    if (elapsedTime > WARNING_TIMEOUT && longTimeout == nil){
        longTimeout = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 111, 56)];
        longTimeout.animationImages = [NSArray arrayWithObjects:    
                                       [UIImage imageNamed:@"monkeys_1"],
                                       [UIImage imageNamed:@"monkeys_2"],
                                       [UIImage imageNamed:@"monkeys_3"],
                                       [UIImage imageNamed:@"monkeys_4"],
                                       [UIImage imageNamed:@"monkeys_5"],
                                       [UIImage imageNamed:@"monkeys_6"],
                                       [UIImage imageNamed:@"monkeys_7"],
                                       [UIImage imageNamed:@"monkeys_8"],
                                       [UIImage imageNamed:@"monkeys_9"],
                                       [UIImage imageNamed:@"monkeys_10"],
                                       [UIImage imageNamed:@"monkeys_11"],
                                       [UIImage imageNamed:@"monkeys_12"],
                                       [UIImage imageNamed:@"monkeys_13"],
                                       [UIImage imageNamed:@"monkeys_14"],
                                       [UIImage imageNamed:@"monkeys_15"],
                                       [UIImage imageNamed:@"monkeys_16"],
                                       [UIImage imageNamed:@"monkeys_17"],
                                       [UIImage imageNamed:@"monkeys_18"],
                                       [UIImage imageNamed:@"monkeys_19"],
                                       [UIImage imageNamed:@"monkeys_20"],
                                       [UIImage imageNamed:@"monkeys_21"],
                                       [UIImage imageNamed:@"monkeys_22"],
                                       [UIImage imageNamed:@"monkeys_23"],
                                       [UIImage imageNamed:@"monkeys_24"],
                                       [UIImage imageNamed:@"monkeys_25"],
                                       [UIImage imageNamed:@"monkeys_26"],
                                       [UIImage imageNamed:@"monkeys_27"],
                                       [UIImage imageNamed:@"monkeys_28"],
                                       [UIImage imageNamed:@"monkeys_29"],
                                       [UIImage imageNamed:@"monkeys_30"],
                                       [UIImage imageNamed:@"monkeys_31"],
                                       [UIImage imageNamed:@"monkeys_32"],
                                       [UIImage imageNamed:@"monkeys_33"],
                                       [UIImage imageNamed:@"monkeys_34"],
                                       [UIImage imageNamed:@"monkeys_35"],
                                       [UIImage imageNamed:@"monkeys_36"],
                                       [UIImage imageNamed:@"monkeys_37"],
                                       [UIImage imageNamed:@"monkeys_38"],
                                        nil];        
        longTimeout.animationDuration = 5.0f;
        longTimeout.animationRepeatCount = 0;
        longTimeout.center = activityIndicatorView.center;
        CGRect frame = longTimeout.frame;
        frame.origin.y = frame.origin.y + 30.0f;
        frame.origin.x = frame.origin.x - 3.0f;
        longTimeout.frame = frame;
        [longTimeout startAnimating];
        [self.view addSubview:longTimeout];
    }
} 

// retrieveData and retrieveExtraInfoData should be unified in an unique method!

-(void) retrieveExtraInfoData:(NSString *)methodToCall parameters:(NSDictionary*)parameters index:(NSIndexPath *)indexPath item:(NSDictionary *)item menuItem:(mainMenu *)menuItem tabToShow:(int)tabToShow{
    NSString *itemid = @"";
    NSDictionary *mainFields = nil;
    mainFields = [[menuItem mainFields] objectAtIndex:tabToShow];
    if (((NSNull *)[mainFields objectForKey:@"row6"] != [NSNull null])){
        itemid = [mainFields objectForKey:@"row6"];
    }
    else{
        return; // something goes wrong
    }

    UIActivityIndicatorView *queuing= nil;
    
    if (indexPath != nil){
        id cell = nil;
        if ([self.searchDisplayController isActive]){
            cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
        }
        else if (enableCollectionView){
            cell = [collectionView cellForItemAtIndexPath:indexPath];
        }
        else{
            cell = [dataList cellForRowAtIndexPath:indexPath];
        }
        queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
        [queuing startAnimating];
    }
    NSMutableArray *newProperties =[[parameters objectForKey:@"properties"] mutableCopy];
    if ([parameters objectForKey:@"kodiExtrasPropertiesMinimumVersion"] != nil) {
        for(id key in [parameters objectForKey:@"kodiExtrasPropertiesMinimumVersion"]) {
            if ([AppDelegate instance].serverVersion >= [key integerValue]){
                id arrayProperties = [[parameters objectForKey:@"kodiExtrasPropertiesMinimumVersion"] objectForKey:key];
                for (id value in arrayProperties) {
                    [newProperties addObject:value];
                }
            }
        }
    }
    NSMutableDictionary *newParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     newProperties, @"properties",
                                     [item objectForKey:itemid], itemid,
                                     nil];
    GlobalData *obj=[GlobalData getInstance];
    [jsonRPC 
     callMethod:methodToCall
     withParameters:newParameters
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error==nil && methodError==nil){
             [queuing stopAnimating];
             if( [NSJSONSerialization isValidJSONObject:methodResult]){
                 NSString *itemid_extra_info = @"";
                 if (((NSNull *)[mainFields objectForKey:@"itemid_extra_info"] != [NSNull null])){
                     itemid_extra_info = [mainFields objectForKey:@"itemid_extra_info"]; 
                 }
                 else{
                     return; // something goes wrong
                 }    
                 NSDictionary *videoLibraryMovieDetail = [methodResult objectForKey:itemid_extra_info];
                 if (((NSNull *)videoLibraryMovieDetail == [NSNull null]) || videoLibraryMovieDetail == nil){
                     return; // something goes wrong
                 }
                 NSString *serverURL= @"";
                 int secondsToMinute = 1;
                 serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                 if ([AppDelegate instance].serverVersion > 11){
                     serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
                     secondsToMinute = 60;
                 }
                 NSString *label=[NSString stringWithFormat:@"%@",[videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row1"]]];
                 NSString *genre=@"";
                 if ([[videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row2"]] isKindOfClass:NSClassFromString(@"JKArray")]){
                     genre=[NSString stringWithFormat:@"%@",[[videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row2"]] componentsJoinedByString:@" / "]];
                 }
                 else{
                     genre=[NSString stringWithFormat:@"%@",[videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row2"]]];
                 }
                 if ([genre isEqualToString:@"(null)"]) genre=@"";
                 
                 NSString *year=@"";
                 if([[videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row3"]] isKindOfClass:[NSNumber class]]){
                     year=[(NSNumber *)[videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row3"]] stringValue];
                 }
                 else{
                     if ([[mainFields objectForKey:@"row3"] isEqualToString:@"blank"])
                         year=@"";
                     else
                         year=[videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row3"]];
                 }                     
                 NSString *runtime=@"";
                 if ([[videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row4"]] isKindOfClass:NSClassFromString(@"JKArray")]){
                     runtime=[NSString stringWithFormat:@"%@",[[videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row4"]] componentsJoinedByString:@" / "]];
                 }
                 else if ([[videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row4"]] intValue]){
                     runtime=[NSString stringWithFormat:@"%d min",[[videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row4"]] intValue]/secondsToMinute];
                 }
                 else{
                     runtime=[NSString stringWithFormat:@"%@",[videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row4"]]];
                 }
                 if ([runtime isEqualToString:@"(null)"]) runtime=@"";
                 
                 
                 NSString *rating=[NSString stringWithFormat:@"%.1f",[(NSNumber *)[videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row5"]] floatValue]];
                 
                 if ([rating isEqualToString:@"0.0"])
                     rating=@"";
                 
                 NSString *thumbnailPath = [videoLibraryMovieDetail objectForKey:@"thumbnail"];
                 NSDictionary *art = [videoLibraryMovieDetail objectForKey:@"art"];

                 NSString *clearlogo = @"";
                 NSString *clearart = @"";
                 for (NSString *key in art) {
                     if ([key rangeOfString:@"clearlogo"].location != NSNotFound){
                         clearlogo = [art objectForKey:key];
                     }
                     if ([key rangeOfString:@"clearart"].location != NSNotFound){
                         clearart = [art objectForKey:key];
                     }
                 }
//                 if ([art count] && [[art objectForKey:@"banner"] length]!=0 && [AppDelegate instance].serverVersion > 11 && [AppDelegate instance].obj.preferTVPosters == NO){
//                     thumbnailPath = [art objectForKey:@"banner"];
//                 }
                 NSString *fanartPath = [videoLibraryMovieDetail objectForKey:@"fanart"];
                 NSString *fanartURL=@"";
                 NSString *stringURL = @"";
                 if (![thumbnailPath isEqualToString:@""] && ![thumbnailPath isEqualToString:@"(null)"]){
                     stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [thumbnailPath stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
                 }
                 if (![fanartPath isEqualToString:@""]){
                     fanartURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [fanartPath stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
                 }
                 NSString *filetype=@"";
                 if ([videoLibraryMovieDetail objectForKey:@"filetype"]!=nil){
                     filetype=[videoLibraryMovieDetail objectForKey:@"filetype"];
                     if ([filetype isEqualToString:@"directory"]){
                         stringURL=@"nocover_filemode.png";
                     }
                     else if ([filetype isEqualToString:@"file"]){
                         if ([[mainFields objectForKey:@"playlistid"] intValue]==0){
                             stringURL=@"icon_song.png";
                             
                         }
                         else if ([[mainFields objectForKey:@"playlistid"] intValue]==1){
                             stringURL=@"icon_video.png";
                         }
                         else if ([[mainFields objectForKey:@"playlistid"] intValue]==2){
                             stringURL=@"icon_picture.png";
                         }
                     }
                 }
                 BOOL disableNowPlaying = NO;
                 if ([self.detailItem disableNowPlaying]){
                     disableNowPlaying = YES;
                 }
                 
                 NSObject *row11 = [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row11"]];
                 if (row11 == nil){
                     row11 = [NSNumber numberWithInt:0];
                 }
                 NSString *row11key = [mainFields objectForKey:@"row11"];
                 if (row11key == nil){
                     row11key = @"";
                 }
                 
                 NSObject *row7 = [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row7"]];
                 if (row7 == nil){
                     row7 = [NSNumber numberWithInt:0];
                 }
                 NSString *row7key = [mainFields objectForKey:@"row7"];
                 if (row7key == nil){
                     row7key = @"";
                 }

                 
                 NSDictionary *newItem =
                 [NSMutableDictionary dictionaryWithObjectsAndKeys:
                  [NSNumber numberWithBool:disableNowPlaying], @"disableNowPlaying",
                  [NSNumber numberWithBool:albumView], @"fromAlbumView",
                  [NSNumber numberWithBool:episodesView], @"fromEpisodesView",
                  clearlogo, @"clearlogo",
                  clearart, @"clearart",
                  label, @"label",
                  genre, @"genre",
                  stringURL, @"thumbnail",
                  fanartURL, @"fanart",
                  runtime, @"runtime",
                  row7, row7key,
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row6"]], [mainFields objectForKey:@"row6"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row8"]], [mainFields objectForKey:@"row8"],
                  year, @"year",
                  rating, @"rating",
                  [mainFields objectForKey:@"playlistid"], @"playlistid",
                  [mainFields objectForKey:@"row8"], @"family",
                  [NSNumber numberWithInt:[[NSString stringWithFormat:@"%@", [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row9"]]]intValue]], [mainFields objectForKey:@"row9"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row10"]], [mainFields objectForKey:@"row10"],
                  row11, row11key,
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row12"]], [mainFields objectForKey:@"row12"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row13"]], [mainFields objectForKey:@"row13"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row14"]], [mainFields objectForKey:@"row14"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row15"]], [mainFields objectForKey:@"row15"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row16"]], [mainFields objectForKey:@"row16"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row17"]], [mainFields objectForKey:@"row17"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row18"]], [mainFields objectForKey:@"row18"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row20"]], [mainFields objectForKey:@"row20"],
                  nil];
                 [self displayInfoView:newItem];
             }
             else {
                 [queuing stopAnimating];
             }
         }
         else {
             UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Details not found", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
             [alertView show];
             [queuing stopAnimating];
         }
     }];
}

-(void)startRetrieveDataWithRefresh:(BOOL)forceRefresh{
    if (forceRefresh == YES){
        [activeLayoutView setUserInteractionEnabled:NO];
        self.indexView.hidden = YES;
    }
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[self.detailItem mainMethod] objectAtIndex:choosedTab]];
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    NSMutableDictionary *mutableParameters = [[parameters objectForKey:@"parameters"] mutableCopy];
    NSMutableArray *mutableProperties = [[[parameters objectForKey:@"parameters"] objectForKey:@"properties"] mutableCopy];
    if ([[parameters objectForKey:@"FrodoExtraArt"] boolValue] == YES && [AppDelegate instance].serverVersion > 11){
        [mutableProperties addObject:@"art"];
    }
    if ([parameters objectForKey:@"kodiExtrasPropertiesMinimumVersion"] != nil) {
        for(id key in [parameters objectForKey:@"kodiExtrasPropertiesMinimumVersion"]) {
            if ([AppDelegate instance].serverVersion >= [key integerValue]){
                id arrayProperties = [[parameters objectForKey:@"kodiExtrasPropertiesMinimumVersion"] objectForKey:key];
                for (id value in arrayProperties) {
                    [mutableProperties addObject:value];
                }
            }
        }
    }
    if (mutableProperties != nil) {
        [mutableParameters setObject:mutableProperties forKey:@"properties"];
    }
    NSString *methodToCall = [methods objectForKey:@"method"];
    if ([parameters objectForKey:@"exploreCommand"] != nil){
        methodToCall = [parameters objectForKey:@"exploreCommand"];
    }
    if (methodToCall!=nil){
        [self retrieveData:methodToCall parameters:mutableParameters sectionMethod:[methods objectForKey:@"extra_section_method"] sectionParameters:[parameters objectForKey:@"extra_section_parameters"] resultStore:self.richResults extraSectionCall:NO refresh:forceRefresh];
    }
    else {
        [activityIndicatorView stopAnimating];
        [self AnimTable:(UITableView *)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
}

-(void) retrieveData:(NSString *)methodToCall parameters:(NSDictionary*)parameters sectionMethod:(NSString *)SectionMethodToCall sectionParameters:(NSDictionary*)sectionParameters resultStore:(NSMutableArray *)resultStoreArray extraSectionCall:(BOOL) extraSectionCallBool refresh:(BOOL)forceRefresh{
    NSMutableDictionary *mutableParameters = [parameters mutableCopy];
    if ([mutableParameters objectForKey: @"file_properties"]!=nil){
        [mutableParameters setObject: [mutableParameters objectForKey: @"file_properties"] forKey: @"properties"];
        [mutableParameters removeObjectForKey: @"file_properties"];
    }
    
    if ([self loadedDataFromDisk:methodToCall parameters:(sectionParameters == nil) ? mutableParameters : [NSMutableDictionary dictionaryWithDictionary:sectionParameters] refresh:forceRefresh] == YES){
        return;
    }

    GlobalData *obj=[GlobalData getInstance];
    [self alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];    
//    NSLog(@"START");
    debugText.text = [NSString stringWithFormat:@"METHOD\n%@\n\nPARAMETERS\n%@\n", methodToCall, [[[NSString stringWithFormat:@"%@", parameters] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
    elapsedTime = 0;
    startTime = [NSDate timeIntervalSinceReferenceDate];
    countExecutionTime = [NSTimer scheduledTimerWithTimeInterval:WARNING_TIMEOUT target:self selector:@selector(checkExecutionTime) userInfo:nil repeats:YES];
//    if ([[mutableParameters objectForKey:@"sort"] respondsToSelector:@selector(removeObjectForKey:)]){
//        [[mutableParameters objectForKey:@"sort"] removeObjectForKey:@"available_methods"];
//    }
//    NSLog(@" METHOD %@ PARAMETERS %@", methodToCall, mutableParameters);
    [jsonRPC
     callMethod:methodToCall
     withParameters:mutableParameters
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         int total=0;
         startTime = 0;
         [countExecutionTime invalidate];
         countExecutionTime = nil;
         if (longTimeout!=nil){
             [longTimeout removeFromSuperview];
             longTimeout = nil;
         }
         if (error==nil && methodError==nil){
             callBack = FALSE;
//             debugText.text = [NSString stringWithFormat:@"%@\n*DATA: %@", debugText.text, methodResult];
//             NSLog(@"END JSON");
//             NSLog(@"DATO RICEVUTO %@", methodResult);
             if ([resultStoreArray count]){
                 [resultStoreArray removeAllObjects];
             }
             if ([self.sections count]){
                 [self.sections removeAllObjects];
             }
             [activeLayoutView reloadData];
             if( [NSJSONSerialization isValidJSONObject:methodResult]){
                 NSString *itemid = @"";
                 NSDictionary *mainFields=[[self.detailItem mainFields] objectAtIndex:choosedTab];
                 if (((NSNull *)[mainFields objectForKey:@"itemid"] != [NSNull null])){
                     itemid = [mainFields objectForKey:@"itemid"]; 
                 }
                 if (extraSectionCallBool){
                     if (((NSNull *)[mainFields objectForKey:@"itemid_extra_section"] != [NSNull null])){
                         itemid = [mainFields objectForKey:@"itemid_extra_section"];
                     }
                     else{
                         return;
                     }
                 }
                 NSArray *videoLibraryMovies = [methodResult objectForKey:itemid];
                 NSString *serverURL= @"";
                 serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                 int secondsToMinute = 1;
                 if ([AppDelegate instance].serverVersion > 11){
                     serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
                     if ([self.detailItem noConvertTime]) secondsToMinute = 60;
                 }
                 if ([videoLibraryMovies isKindOfClass:NSClassFromString(@"JKArray")]) {
                     if (((NSNull *)videoLibraryMovies != [NSNull null])) {
                         total = (int)[videoLibraryMovies count];
                     }
                     for (int i=0; i<total; i++) {
                         NSString *label=[NSString stringWithFormat:@"%@",[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row1"]]];
                         
                         NSString *genre=@"";
                         if ([[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row2"]] isKindOfClass:NSClassFromString(@"JKArray")]){
                             genre=[NSString stringWithFormat:@"%@",[[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row2"]] componentsJoinedByString:@" / "]];
                         }
                         else{
                             genre=[NSString stringWithFormat:@"%@",[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row2"]]];
                         }
                         if ([genre isEqualToString:@"(null)"]) genre=@"";
                         
                         NSString *year=@"";
                         if([[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row3"]] isKindOfClass:[NSNumber class]]){
                             year=[(NSNumber *)[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row3"]] stringValue];
                         }
                         else{
                             if ([[mainFields objectForKey:@"row3"] isEqualToString:@"blank"])
                                 year=@"";
                             else
                                 year=[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row3"]];
                         }
                         year = [NSString stringWithFormat:@"%@", year];
                         if ([year isEqualToString:@"(null)"]) year=@"";
                         
                         NSString *runtime=@"";
                         if ([[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row4"]] isKindOfClass:NSClassFromString(@"JKArray")]){
                             runtime=[NSString stringWithFormat:@"%@",[[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row4"]] componentsJoinedByString:@" / "]];
                         }
                         else if ([[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row4"]] intValue]){
                             runtime=[NSString stringWithFormat:@"%d min",[[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row4"]] intValue]/secondsToMinute];
                         }
                         else{
                             runtime=[NSString stringWithFormat:@"%@",[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row4"]]];
                         }
                         if ([runtime isEqualToString:@"(null)"]) runtime=@"";
                         
                         NSString *rating=[NSString stringWithFormat:@"%.1f",[(NSNumber *)[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row5"]] floatValue]];
                         if ([rating isEqualToString:@"0.0"])
                             rating=@"";
                         
                         NSString *thumbnailPath = [[videoLibraryMovies objectAtIndex:i] objectForKey:@"thumbnail"];
                         NSDictionary *art = [[videoLibraryMovies objectAtIndex:i] objectForKey:@"art"];
                         if ([art count] && [[art objectForKey:@"banner"] length]!=0 && tvshowsView){
                             thumbnailPath = [art objectForKey:@"banner"];
                         }
                         NSString *fanartPath = [[videoLibraryMovies objectAtIndex:i] objectForKey:@"fanart"];
                         NSString *fanartURL=@"";
                         NSString *stringURL = @"";
                         
                         if (![thumbnailPath isEqualToString:@""] && thumbnailPath != nil){
                             stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [thumbnailPath stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
                         }
                         if (![fanartPath isEqualToString:@""]){
                             fanartURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [fanartPath stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
                         }
                         NSString *filetype=@"";
                         if ([[videoLibraryMovies objectAtIndex:i] objectForKey:@"filetype"]!=nil){
                             filetype=[[videoLibraryMovies objectAtIndex:i] objectForKey:@"filetype"];
                             if ([thumbnailPath length] == 0){
                                 if ([filetype isEqualToString:@"directory"]){
                                     stringURL=@"nocover_filemode.png";
                                 }
                                 else if ([filetype isEqualToString:@"file"]){
                                     if ([[mainFields objectForKey:@"playlistid"] intValue]==0){
                                         stringURL=@"icon_song.png";
                                         
                                     }
                                     else if ([[mainFields objectForKey:@"playlistid"] intValue]==1){
                                         stringURL=@"icon_video.png";
                                     }
                                     else if ([[mainFields objectForKey:@"playlistid"] intValue]==2){
                                         stringURL=@"icon_picture.png";
                                     }
                                 }
                             }
                         }
                         NSString *key = @"none";
                         NSString *value = @"";
                         if (([mainFields objectForKey:@"row7"] != nil)){
                             key = [mainFields objectForKey:@"row7"];
                             value = [NSString stringWithFormat:@"%@", [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row7"]]];
                         }
                         NSString *seasonNumber = [NSString stringWithFormat:@"%@", [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row10"]]];
                         
                         NSString *family = [NSString stringWithFormat:@"%@", [mainFields objectForKey:@"row8"]];
                         
                         NSString *row19key = [mainFields objectForKey:@"row19"];
                         if (row19key == nil){
                             row19key = @"episode";
                         }
                         id episodeNumber = @"";
                         if ([[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row19"]] isKindOfClass:NSClassFromString(@"JKDictionary")]){
                             episodeNumber = [[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row19"]] mutableCopy];
                         }
                         else{
                             episodeNumber = [NSString stringWithFormat:@"%@", [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row19"]]];
                         }
                         id row13obj = [[mainFields objectForKey:@"row13"] isEqualToString:@"options"] ? [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row13"]] == nil ? @"" : [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row13"]] : [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row13"]];
                         
                         id row14obj = [[mainFields objectForKey:@"row14"] isEqualToString:@"allowempty"] ? [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row14"]] == nil ? @"" : [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row14"]] : [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row14"]];
                         
                         id row15obj = [[mainFields objectForKey:@"row15"] isEqualToString:@"addontype"] ? [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row15"]] == nil ? @"" : [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row15"]] : [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row15"]];
                         
                         [resultStoreArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                      label, @"label",
                                                      genre, @"genre",
                                                      stringURL, @"thumbnail",
                                                      fanartURL, @"fanart",
                                                      runtime, @"runtime",
                                                      seasonNumber, @"season",
                                                      episodeNumber, row19key,
                                                      family, @"family",
                                                      [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row6"]], [mainFields objectForKey:@"row6"],
                                                      [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row8"]], [mainFields objectForKey:@"row8"],
                                                      year, @"year",
                                                      [NSString stringWithFormat:@"%@", rating], @"rating",
                                                      [mainFields objectForKey:@"playlistid"], @"playlistid",
                                                      value, key,
                                                      [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row9"]], [mainFields objectForKey:@"row9"],
                                                      [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row10"]], [mainFields objectForKey:@"row10"],
                                                      [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row11"]], [mainFields objectForKey:@"row11"],
                                                      [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row12"]], [mainFields objectForKey:@"row12"],
                                                      row13obj, [mainFields objectForKey:@"row13"],
                                                      row14obj, [mainFields objectForKey:@"row14"],
                                                      row15obj, [mainFields objectForKey:@"row15"],
                                                      [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row16"]], [mainFields objectForKey:@"row16"],
                                                      [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row17"]], [mainFields objectForKey:@"row17"],
                                                      [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row18"]], [mainFields objectForKey:@"row18"],
                                                      nil]];
                     }
                 }
                 else if ([videoLibraryMovies isKindOfClass:NSClassFromString(@"JKDictionary")]) {
                     NSDictionary *dictVideoLibraryMovies = [methodResult objectForKey:itemid];
                     if ([[dictVideoLibraryMovies objectForKey:[mainFields objectForKey:@"typename"]] isKindOfClass:NSClassFromString(@"JKDictionary")]){
                         if ([[[dictVideoLibraryMovies objectForKey:[mainFields objectForKey:@"typename"]] objectForKey:[mainFields objectForKey:@"fieldname"]] isKindOfClass:NSClassFromString(@"JKArray")]) {
                             videoLibraryMovies = [[dictVideoLibraryMovies objectForKey:[mainFields objectForKey:@"typename"]] objectForKey:[mainFields objectForKey:@"fieldname"]];
                             if (((NSNull *)videoLibraryMovies != [NSNull null])) {
                                 total = (int)[videoLibraryMovies count];
                             }
                             NSString *sublabel = [[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]] objectForKey:@"morelabel"];
                             if (!sublabel || [sublabel isKindOfClass:[NSNull class]]) {
                                 sublabel = @"";
                             }
                             for (int i=0; i < total; i++) {
                                 [resultStoreArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                              [videoLibraryMovies objectAtIndex:i], @"label",
                                                              sublabel, @"genre",
                                                              @"file", @"family",
                                                              [mainFields objectForKey:@"thumbnail"], @"thumbnail",
                                                              @"", @"fanart",
                                                              @"", @"runtime",
                                                              nil]];
                             }
                         }
                     }
                 }
//                 NSLog(@"END STORE");
//                 NSLog(@"RICH RESULTS %@", resultStoreArray);
                 if (!extraSectionCallBool){
                     storeRichResults = [resultStoreArray mutableCopy];
                 }
                 if (SectionMethodToCall != nil){
                     [self retrieveData:SectionMethodToCall parameters:sectionParameters sectionMethod:nil sectionParameters:nil resultStore:self.extraSectionRichResults extraSectionCall:YES refresh:forceRefresh];
                 }
                 else if (watchMode != 0){
                     if (forceRefresh == YES){
                         [((UITableView *)activeLayoutView).pullToRefreshView stopAnimating];
                         [activeLayoutView setUserInteractionEnabled:YES];
                         [self saveData:mutableParameters];
                     }
                     [self changeViewMode:watchMode forceRefresh:forceRefresh];
                 }
                 else{
                     if (forceRefresh == YES){
                         [((UITableView *)activeLayoutView).pullToRefreshView stopAnimating];
                         [activeLayoutView setUserInteractionEnabled:YES];
                     }
                     [self saveData:mutableParameters];
                     [self indexAndDisplayData];
                 }
             }
             else {
                 if (forceRefresh == YES){
                     [((UITableView *)activeLayoutView).pullToRefreshView stopAnimating];
                     [activeLayoutView setUserInteractionEnabled:YES];
                 }
                 [resultStoreArray removeAllObjects];
                 [self.sections removeAllObjects];
                 [self.sections setValue:[[NSMutableArray alloc] init] forKey:@""];
                 [self alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
                 //                NSLog(@"NON E' JSON %@", methodError);
                 [activityIndicatorView stopAnimating];
                 [activeLayoutView reloadData];
                 [self AnimTable:(UITableView*)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
             }
         }
         else {
//             NSLog(@"ERROR:%@ METHOD:%@", error, methodError);
//             if (!callBack){
//                 callBack = TRUE;
//                 NSMutableDictionary *mutableParameters = [parameters mutableCopy];
//                 [mutableParameters removeObjectForKey:@"sort"];
//                 [self retrieveData:methodToCall parameters:mutableParameters sectionMethod:SectionMethodToCall sectionParameters:sectionParameters resultStore:resultStoreArray extraSectionCall:NO];
////                 [self retrieveData:methodToCall parameters:mutableParameters];
//             }
//             else{
             
             // DISPLAY DEBUG
             if (methodError != nil){
                 debugText.text = [NSString stringWithFormat:@"%@\n\n%@\n", methodError, debugText.text];
             }
             if (error != nil){
                 debugText.text = [NSString stringWithFormat:@"%@\n\n%@\n", error.localizedDescription, debugText.text];
                 
             }
             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR", nil)
                                                                 message:debugText.text
                                                                delegate:self
                                                       cancelButtonTitle:nil
                                                       otherButtonTitles:@"Copy to clipboard", nil];
             [alertView show];
             UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
             pasteboard.string = debugText.text;
             // END DISPLAY DEBUG
             
             if (forceRefresh == YES){
                 [((UITableView *)activeLayoutView).pullToRefreshView stopAnimating];
                 [activeLayoutView setUserInteractionEnabled:YES];
             }
             [resultStoreArray removeAllObjects];
             [self.sections removeAllObjects];
             [self.sections setValue:[[NSMutableArray alloc] init] forKey:@""];
             [self alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
             [activityIndicatorView stopAnimating];
             [activeLayoutView reloadData];
             [self AnimTable:(UITableView *)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
//             }
         }
     }];
}

-(void)indexAndDisplayData {
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    NSArray *copyRichResults = [self.richResults copy];
    self.sectionArray = nil;
    autoScrollTable = nil;
    if ([copyRichResults count] == 0){
        albumView = FALSE;
        episodesView = FALSE;
    }
    BOOL sortAscending = [sortAscDesc isEqualToString:@"descending"] ? NO : YES;
    if ([self.detailItem enableSection] && [copyRichResults count]>SECTIONS_START_AT && (sortMethodIndex == -1 || [sortMethodName isEqualToString:@"label"])){
        if ([sortAscDesc isEqualToString:@"descending"]) {
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"label" ascending:sortAscending];
            NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            copyRichResults = [copyRichResults sortedArrayUsingDescriptors:sortDescriptors];
        }
        [self.sections setValue:[[NSMutableArray alloc] init] forKey:UITableViewIndexSearch];
        BOOL found;
        NSCharacterSet * set = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ"] invertedSet];
        NSCharacterSet * numberset = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
        for (NSDictionary *item in copyRichResults){
            NSString *c = @"/";
            if ([[item objectForKey:@"label"] length]>0){
                c = [[[item objectForKey:@"label"] substringToIndex:1] uppercaseString];
            }
            if ([c rangeOfCharacterFromSet:numberset].location == NSNotFound){
                c = @"#";
            }
            else if ([c rangeOfCharacterFromSet:set].location != NSNotFound) {
                c = @"/";
            }
            found = NO;
            if ([[self.sections allKeys] containsObject:c]){
                found = YES;
            }
            if (!found){
                [self.sections setValue:[[NSMutableArray alloc] init] forKey:c];
            }
            [[self.sections objectForKey:c] addObject:item];
        }
    }
    else if (episodesView) {
        for (NSDictionary *item in self.richResults){
            BOOL found;
            NSString *c =  [NSString stringWithFormat:@"%@", [item objectForKey:@"season"]];
            found = NO;
            if ([[self.sections allKeys] containsObject:c]){
                found = YES;
            }
            if (!found){
                [self.sections setValue:[[NSMutableArray alloc] init] forKey:c];
            }
            [[self.sections objectForKey:c] addObject:item];
        }
    }
    else if (channelGuideView){
        [self.sections setValue:[[NSMutableArray alloc] init] forKey:UITableViewIndexSearch];
        BOOL found;
        NSDateFormatter *localDate = [[NSDateFormatter alloc] init];
        [localDate setDateFormat:@"yyyy-MM-dd"];
        localDate.timeZone = [NSTimeZone systemTimeZone];
        NSDate *nowDate = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSInteger components = (NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute);
        NSDateComponents *nowDateComponents = [calendar components:components fromDate: nowDate];
        nowDate = [calendar dateFromComponents:nowDateComponents];
        NSUInteger countRow = 0;
        NSMutableArray *retrievedEPG = [[NSMutableArray alloc] init];
        for (NSMutableDictionary *item in self.richResults){
            NSDate *starttime = [xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", [item objectForKey:@"starttime"]]];
            NSDate *endtime = [xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", [item objectForKey:@"endtime"]]];
            NSDate *itemEndDate;
            NSDate *itemStartDate;
            if (starttime!=nil && endtime!=nil) {
                NSDateComponents *itemDateComponents = [calendar components:components fromDate: endtime];
                itemEndDate = [calendar dateFromComponents:itemDateComponents];
                itemDateComponents = [calendar components:components fromDate: starttime];
                itemStartDate = [calendar dateFromComponents:itemDateComponents];
            }
            NSComparisonResult datesCompare = [itemEndDate compare:nowDate];
            if (datesCompare == NSOrderedDescending || datesCompare == NSOrderedSame){
                NSString *c = [localDate stringFromDate:itemStartDate];
                if (!c || [c isKindOfClass:[NSNull class]]) {
                    c = @"";
                }
                found = NO;
                if ([[self.sections allKeys] containsObject:c]){
                    found = YES;
                }
                if (!found){
                    [self.sections setValue:[[NSMutableArray alloc] init] forKey:c];
                    countRow = 0;
                }
                [item setObject:[parameters objectForKey:@"pvrExtraInfo"] forKey:@"pvrExtraInfo"];
                [[self.sections objectForKey:c] addObject:item];
                if ([[item objectForKey:@"isactive"] boolValue] == TRUE){
                    autoScrollTable = [NSIndexPath indexPathForRow:countRow inSection:[self.sections count] - 1];
                }
                [retrievedEPG addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                         starttime, @"starttime",
                                         endtime, @"endtime",
                                         [item objectForKey:@"title"], @"title",
                                         [item objectForKey:@"label"], @"label",
                                         [item objectForKey:@"genre"], @"plot",
                                         [item objectForKey:@"plotoutline"], @"plotoutline",
                                         nil]];
                countRow ++;
            }
        }
        if ([self.sections count] == 1){
            [self.richResults removeAllObjects];
        }
        NSDictionary *epgparams = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [[[[self.detailItem mainParameters] objectAtIndex:0] objectAtIndex:0] objectForKey:@"channelid"], @"channelid",
                                   retrievedEPG, @"epgArray",
                                   nil];
        [NSThread detachNewThreadSelector:@selector(backgroundSaveEPGToDisk:) toTarget:self withObject:epgparams];
    }
    else {
        NSString *defaultSortMethod = [[[parameters objectForKey:@"parameters"] objectForKey:@"sort"] objectForKey:@"method"];
        if (sortMethodName != nil && ![sortMethodName isEqualToString:defaultSortMethod]) {
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortMethodName ascending:sortAscending];
            NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            copyRichResults = [copyRichResults sortedArrayUsingDescriptors:sortDescriptors];
            BOOL found;
            [self.sections setValue:[[NSMutableArray alloc] init] forKey:UITableViewIndexSearch];
            for (NSDictionary *item in copyRichResults){
                found = NO;
                NSString *searchKey = @"";
                if ([[item objectForKey:sortMethodName] isKindOfClass:[NSMutableArray class]] || [[item objectForKey:sortMethodName] isKindOfClass:NSClassFromString(@"JKArray")]){
                    searchKey = [[item objectForKey:sortMethodName] componentsJoinedByString:@""];
                }
                else {
                    searchKey = [item objectForKey:sortMethodName];
                }
                NSString *key = [self getIndexTableKey:searchKey sortMethod:sortMethodName];
                if ([[self.sections allKeys] containsObject:key] == YES){
                    found = YES;
                }
                if (!found){
                    [self.sections setValue:[[NSMutableArray alloc] init] forKey:key];
                }
                [[self.sections objectForKey:key] addObject:item];
            }
        }
        else {
            if ([sortAscDesc isEqualToString:@"descending"]) {
                NSString *methodSort = (sortMethodName == nil) ?  @"label" : sortMethodName;
                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:methodSort ascending:sortAscending];
                NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                copyRichResults = [copyRichResults sortedArrayUsingDescriptors:sortDescriptors];
            }
            [self.sections setValue:[[NSMutableArray alloc] init] forKey:@""];
            for (NSDictionary *item in copyRichResults){
                [[self.sections objectForKey:@""] addObject:item];
            }
        }
    }
    self.sectionArray = [[NSArray alloc] initWithArray:
                         [[self.sections allKeys] sortedArrayUsingComparator:^(id firstObject, id secondObject) {
        return [self alphaNumericCompare:firstObject secondObject:secondObject];
    }]];
    UISearchBarLeftButton *bar = (UISearchBarLeftButton *)self.searchDisplayController.searchBar;
    bar.rightPadding = 0;
    self.sectionArrayOpen = [[NSMutableArray alloc] init];
    BOOL defaultValue = FALSE;
    if ([self.sectionArray count] == 1){
        defaultValue = TRUE;
    }
    else {
        bar.rightPadding = 26;
    }
    [bar setSortButtonImage:sortAscDesc];
    [bar layoutSubviews];
    for (int i=0; i<[self.sectionArray count]; i++) {
        [self.sectionArrayOpen addObject:[NSNumber numberWithBool:defaultValue]];
    }
    [self displayData];
}

-(NSString *)getIndexTableKey:(NSString *)value sortMethod:(NSString *)sortMethod {
    NSString *currentValue = [NSString stringWithFormat:@"%@", value];
    if ([sortMethod isEqualToString:@"year"]) {
        int year = [currentValue intValue];
        if (year >= 1900 && year <= 2099){
            currentValue = [NSString stringWithFormat:@"%@0", [currentValue substringToIndex:3]];
        }
        else {
            currentValue = @"";
        }
    }
    else if ([sortMethod isEqualToString:@"runtime"]) {
        currentValue = [currentValue stringByTrimmingCharactersInSet:[NSCharacterSet letterCharacterSet]];
        
        currentValue = [NSString stringWithFormat:@"%ld", ((long)[[NSString stringWithFormat:@"%@", [NSNumber numberWithFloat:[currentValue integerValue] / 15.0f]] integerValue] * 15) + 15 ];
    }
    else if ([sortMethod isEqualToString:@"rating"]) {
        currentValue = [@(round([currentValue doubleValue])) stringValue];
    }
    else if ([sortMethod isEqualToString:@"dateadded"] && ![currentValue isEqualToString:@"(null)"]) {
        NSDateComponents *components = [[NSCalendar currentCalendar] components: NSCalendarUnitYear fromDate:[xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", currentValue]]];
        currentValue = [NSString stringWithFormat:@"%ld", (long)[components year]];
    }
    else if (([sortMethod isEqualToString:@"label"]  || [sortMethod isEqualToString:@"genre"] || [sortMethod isEqualToString:@"album"]) && [currentValue length]) {
        NSCharacterSet * set = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ"] invertedSet];
        NSCharacterSet * numberset = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
        NSString *c = @"/";
        if ([currentValue length] > 0){
            c = [[currentValue substringToIndex:1] uppercaseString];
        }
        if ([c rangeOfCharacterFromSet:numberset].location == NSNotFound){
            c = @"#";
        }
        else if ([c rangeOfCharacterFromSet:set].location != NSNotFound) {
            c = @"/";
        }
        currentValue = c;
    }
    if ([currentValue isEqualToString:@""] || [currentValue isEqualToString:@"(null)"]){
        currentValue = @"/";
    }
    return currentValue;
}

-(void)displayData{
    [self configureLibraryView];
    [self choseParams];
    numResults = (int)[self.richResults count];
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    if ([self.detailItem enableSection]){
        // CONDIZIONE DEBOLE!!!
        self.navigationItem.title =[NSString stringWithFormat:@"%@ (%d)", [parameters objectForKey:@"label"], numResults];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            if (!stackscrollFullscreen){
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.3];
                topNavigationLabel.alpha = 0;
                [UIView commitAnimations];
                topNavigationLabel.text = [NSString stringWithFormat:@"%@ (%d)", [parameters objectForKey:@"label"], numResults];
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.1];
                topNavigationLabel.alpha = 1;
                [UIView commitAnimations];
            }
            else{
                topNavigationLabel.text = [NSString stringWithFormat:@"%@ (%d)", [parameters objectForKey:@"label"], numResults];
            }
        }
        // FINE CONDIZIONE
    }
    if (![self.richResults count]){
        [self alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
    }
    else {
        [self alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
    }
    NSDictionary *itemSizes = [parameters objectForKey:@"itemSizes"];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        [self setIphoneInterface:[itemSizes objectForKey:@"iphone"]];
    }
    else {
        [self setIpadInterface:[itemSizes objectForKey:@"ipad"]];
    }
    if (collectionView != nil){
        if (enableCollectionView){
            self.indexView.hidden = NO;
        }
        NSMutableArray *tmpArr = [[NSMutableArray alloc] initWithArray:self.sectionArray];
        if ([tmpArr count] > 1){
            [tmpArr replaceObjectAtIndex:0 withObject:[NSString stringWithUTF8String:"\xF0\x9F\x94\x8D"]];
        }
        else{
            self.indexView.hidden = YES;
        }
        self.indexView.indexTitles = [NSArray arrayWithArray:tmpArr];
    }
    if (stackscrollFullscreen == YES){
        storeSectionArray = [sectionArray copy];
        storeSections = [sections mutableCopy];
        NSMutableDictionary *sectionsTemp = [[NSMutableDictionary alloc] init];
        [sectionsTemp setValue:[[NSMutableArray alloc] init] forKey:@""];
        for (id key in self.sectionArray){
            NSDictionary *tmp = [self.sections objectForKey:key];
            for (NSDictionary *item in tmp) {
                [[sectionsTemp objectForKey:@""] addObject:item];
            }
        }
        self.sectionArray = [[NSArray alloc] initWithObjects:@"", nil];
        self.sections = [sectionsTemp mutableCopy];
    }
    [self setFlowLayoutParams];
    [activityIndicatorView stopAnimating];
    [activeLayoutView reloadData];
    [self AnimTable:(UITableView *)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
    [dataList setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
    [collectionView layoutSubviews];
    [collectionView setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
    if (channelGuideView && autoScrollTable != nil){
        [dataList scrollToRowAtIndexPath:autoScrollTable atScrollPosition: UITableViewScrollPositionTop animated: NO];
    }
}

-(void)startChannelListUpdateTimer {
    [self updateChannelListTableCell];
    if (channelListUpdateTimer != nil){
        [channelListUpdateTimer invalidate];
        channelListUpdateTimer = nil;
    }
    channelListUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:60.0f target:self selector:@selector(updateChannelListTableCell) userInfo:nil repeats:YES];
}

-(void)updateChannelListTableCell {
    if ([self.searchDisplayController isActive]) {
        [self.searchDisplayController.searchResultsTableView beginUpdates];
        [self.searchDisplayController.searchResultsTableView reloadRowsAtIndexPaths:[self.searchDisplayController.searchResultsTableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
        [self.searchDisplayController.searchResultsTableView endUpdates];
    }
    [dataList beginUpdates];
    [dataList reloadRowsAtIndexPaths:[dataList indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
    [dataList endUpdates];
    
    [collectionView performBatchUpdates:^{
        [collectionView reloadItemsAtIndexPaths:[collectionView indexPathsForVisibleItems]];
    } completion:^(BOOL finished) {}];
}

-(NSComparisonResult)alphaNumericCompare:(id)firstObject secondObject:(id)secondObject{
    if ([((NSString *)firstObject) isEqualToString:UITableViewIndexSearch]){
        return NSOrderedAscending;
    }
    else if ([((NSString *)secondObject) isEqualToString:UITableViewIndexSearch]){
        return NSOrderedDescending;
    }
    int comparisionSign = [sortAscDesc isEqualToString:@"descending"] ? -1 : 1;
    if (episodesView || [sortMethodName isEqualToString:@"runtime"] || [sortMethodName isEqualToString:@"track"] || [sortMethodName isEqualToString:@"duration"] || [sortMethodName isEqualToString:@"rating"]){
        return comparisionSign * [((NSString *)firstObject) compare:((NSString *)secondObject) options:NSNumericSearch];
    }
    return comparisionSign * [((NSString *)firstObject) localizedCaseInsensitiveCompare:((NSString *)secondObject)];
}

# pragma mark - Life-Cycle

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name:@"ECSLidingSwipeLeft" object:nil];
    [self.navigationController.navigationBar setTintColor:IOS6_BAR_TINT_COLOR];
    [self.navigationController.navigationBar setTintColor:TINT_COLOR];
    self.searchDisplayController.searchBar.tintColor = [utils lighterColorForColor:searchBarColor];
    [channelListUpdateTimer invalidate];
    channelListUpdateTimer = nil;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.slidingViewController != nil){
        [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
        self.slidingViewController.underRightViewController = nil;
        self.slidingViewController.anchorLeftPeekAmount     = 0;
        self.slidingViewController.anchorLeftRevealAmount   = 0;
    }
    alreadyPush = NO;
    self.webViewController = nil;
    NSIndexPath* selection = [dataList indexPathForSelectedRow];
	if (selection){
		[dataList deselectRowAtIndexPath:selection animated:NO];
    }
    selection = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
    if (selection){
		[self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:selection animated:YES];
    }
    
    for (selection in [collectionView indexPathsForSelectedItems]) {
        [collectionView deselectItemAtIndexPath:selection animated:YES];
    }
//    [self brightCells];

    [self choseParams];

    if ([self presentingViewController] != nil) {
        UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissAddAction:)];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
// TRICK WHEN CHILDREN WAS FORCED TO PORTRAIT
//    UIViewController *c = [[UIViewController alloc]init];
//    [self presentViewController:c animated:NO completion:nil];
//    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleSwipeFromLeft:)
                                                 name: @"ECSLidingSwipeLeft"
                                               object: nil];
    if (self.slidingViewController.view != nil){
        [self disableScrollsToTopPropertyOnAllSubviewsOf:self.slidingViewController.view];
    }
    else {
        [self disableScrollsToTopPropertyOnAllSubviewsOf:self.view];
    }
    [activeLayoutView setScrollsToTop:YES];
    if (albumColor!=nil){
        [self.navigationController.navigationBar setTintColor:albumColor];
        [self.navigationController.navigationBar setTintColor:[utils slightLighterColorForColor:albumColor]];
    }
    if (isViewDidLoad){
        [activeLayoutView addSubview:self.searchDisplayController.searchBar];
        [self initIpadCornerInfo];
        [self startRetrieveDataWithRefresh:NO];
        isViewDidLoad = FALSE;
    }
    if (channelListView == YES || channelGuideView == YES) {
        [channelListUpdateTimer invalidate];
        channelListUpdateTimer = nil;
        NSDate * now = [NSDate date];
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
        [outputFormatter setDateFormat:@"ss"];
        [self updateChannelListTableCell];
        [self performSelector:@selector(startChannelListUpdateTimer) withObject:nil afterDelay:60.0f - [[outputFormatter stringFromDate:now] floatValue]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
//    [SDWebImageManager.sharedManager cancelAll];
//    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)revealMenu:(id)sender{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

-(void)buildButtons{
    NSArray *buttons=[self.detailItem mainButtons];
    NSArray *buttonsIB=[NSArray arrayWithObjects:button1, button2, button3, button4, button5, nil];
    int i=0;
    NSInteger count = [buttons count];
    if (count > MAX_NORMAL_BUTTONS)
        count = MAX_NORMAL_BUTTONS;
    if (choosedTab > MAX_NORMAL_BUTTONS)
        choosedTab = MAX_NORMAL_BUTTONS;
    for (i=0;i<count;i++){
        NSString *imageNameOff=[NSString stringWithFormat:@"%@_off", [buttons objectAtIndex:i]];
        NSString *imageNameOn=[NSString stringWithFormat:@"%@_on", [buttons objectAtIndex:i]];
        [[buttonsIB objectAtIndex:i] setBackgroundImage:[UIImage imageNamed:imageNameOff] forState:UIControlStateNormal];
        [[buttonsIB objectAtIndex:i] setBackgroundImage:[UIImage imageNamed:imageNameOn] forState:UIControlStateSelected];
        [[buttonsIB objectAtIndex:i] setBackgroundImage:[UIImage imageNamed:imageNameOn] forState:UIControlStateHighlighted];
        [[buttonsIB objectAtIndex:i] setEnabled:YES];
    }
    [[buttonsIB objectAtIndex:choosedTab] setSelected:YES];
    if (count==0){
        buttonsView.hidden=YES;
        CGRect frame=dataList.frame;
        frame.size.height=self.view.bounds.size.height;
        dataList.frame=frame;
        
        UIEdgeInsets tableViewInsets = dataList.contentInset;
        tableViewInsets.bottom = 0;
        dataList.contentInset = tableViewInsets;
        dataList.scrollIndicatorInsets = tableViewInsets;
        collectionView.contentInset = tableViewInsets;
        collectionView.scrollIndicatorInsets = tableViewInsets;
    }
    if ([[self.detailItem mainMethod] count]>MAX_NORMAL_BUTTONS){
        NSString *imageNameOff=@"st_more_off";
        NSString *imageNameOn=@"st_more_on";
        [[buttonsIB objectAtIndex:MAX_NORMAL_BUTTONS] setBackgroundImage:[UIImage imageNamed:imageNameOff] forState:UIControlStateNormal];
        [[buttonsIB objectAtIndex:MAX_NORMAL_BUTTONS] setBackgroundImage:[UIImage imageNamed:imageNameOn] forState:UIControlStateSelected];
        [[buttonsIB objectAtIndex:MAX_NORMAL_BUTTONS] setBackgroundImage:[UIImage imageNamed:imageNameOn] forState:UIControlStateHighlighted];
        [[buttonsIB objectAtIndex:MAX_NORMAL_BUTTONS] setEnabled:YES];
        selectedMoreTab = [[UIButton alloc] init];
    }
}

-(void)checkParamSize:(NSDictionary *)itemSizes viewWidth:(int)fullWidth{
    if ([itemSizes objectForKey:@"width"] && [itemSizes objectForKey:@"height"]){
        if ([[itemSizes objectForKey:@"width"] isKindOfClass:[NSString class]]){
            if ([[itemSizes objectForKey:@"width"] isEqualToString:@"fullWidth"]){
                cellGridWidth = fullWidth;
            }
            cellMinimumLineSpacing = 1;
        }
        else{
            cellMinimumLineSpacing = 0;
            cellGridWidth = [[itemSizes objectForKey:@"width"] floatValue];
            if (IS_IPHONE_6) {
                cellGridWidth = (int)(cellGridWidth * 1.18f);
            }
            else if (IS_IPHONE_6_PLUS){
                cellGridWidth = (int)(cellGridWidth * 1.31f);
            }
        }
        cellGridHeight =  [[itemSizes objectForKey:@"height"] floatValue];
        if (IS_IPHONE_6) {
            cellGridHeight = (int)(cellGridHeight * 1.18f);
        }
        else if (IS_IPHONE_6_PLUS){
            cellGridHeight = (int)(cellGridHeight * 1.31f);
        }
    }
    if ([itemSizes objectForKey:@"fullscreenWidth"] && [itemSizes objectForKey:@"fullscreenHeight"]){
        fullscreenCellGridWidth = [[itemSizes objectForKey:@"fullscreenWidth"] floatValue];
        fullscreenCellGridHeight =  [[itemSizes objectForKey:@"fullscreenHeight"] floatValue];
    }
}

-(void)setIphoneInterface:(NSDictionary *)itemSizes {
    viewWidth = [self currentScreenBoundsDependOnOrientation].size.width;
    albumViewHeight = 116;
    albumViewPadding = 8;
    if (episodesView){
        albumViewHeight = 99;
    }
    artistFontSize = 12;
    albumFontSize = 15;
    trackCountFontSize = 11;
    labelPadding = 8;
    cellGridWidth =105.0f;
    cellGridHeight =  151.0f;
    posterFontSize = 10;
    fanartFontSize = 10;
    [self checkParamSize:itemSizes viewWidth:viewWidth];
}

-(void)setIpadInterface:(NSDictionary *)itemSizes{
    viewWidth = STACKSCROLL_WIDTH;
    albumViewHeight = 166;
    if (episodesView){
        albumViewHeight = 120;
    }
    albumViewPadding = 12;
    artistFontSize = 14;
    albumFontSize = 18;
    trackCountFontSize = 13;
    labelPadding = 8;
    cellGridWidth =117.0f;
    cellGridHeight =  168.0f;
    fullscreenCellGridWidth = 164.0f;
    fullscreenCellGridHeight = 246.0f;
    posterFontSize = 11;
    fanartFontSize = 13;
    [self checkParamSize:itemSizes viewWidth:viewWidth];
    if (stackscrollFullscreen == YES) {
        viewWidth = [self currentScreenBoundsDependOnOrientation].size.width;
    }
}

- (void) disableScrollsToTopPropertyOnAllSubviewsOf:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UIScrollView class]]) {
            ((UIScrollView *)subview).scrollsToTop = NO;
        }
        [self disableScrollsToTopPropertyOnAllSubviewsOf:subview];
    }
}

-(BOOL)collectionViewCanBeEnabled{
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    return (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0") && ([[parameters objectForKey:@"enableCollectionView"] boolValue] == YES));
}

-(BOOL)collectionViewIsEnabled{
    if (![self collectionViewCanBeEnabled]) return NO;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[self.detailItem mainMethod] objectAtIndex:choosedTab]];
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:[parameters objectForKey:@"parameters"]];
    if ([AppDelegate instance].serverVersion > 11) {
        if ([tempDict objectForKey:@"filter"] != nil) {
            [tempDict removeObjectForKey:@"filter"];
            [tempDict setObject:@"YES" forKey:@"filtered"];
        }
    }
    else {
        if ([tempDict count] > 2) {
            [tempDict removeAllObjects];
            NSArray *arr_properties = [[parameters objectForKey:@"parameters"] objectForKey:@"properties"];
            if (arr_properties == nil){
                arr_properties = [[parameters objectForKey:@"parameters"] objectForKey:@"file_properties"];
            }
            
            if (arr_properties == nil){
                arr_properties = [NSArray array];
            }
            
            NSArray *arr_sort = [[parameters objectForKey:@"parameters"] objectForKey:@"sort"];
            if (arr_sort == nil){
                arr_sort = [NSArray array];
            }
            [tempDict setObject:arr_properties forKey:@"properties"];
            [tempDict setObject:arr_sort forKey:@"sort"];
            [tempDict setObject:@"YES" forKey:@"filtered"];
        }
    }
    NSString *viewKey = [NSString stringWithFormat:@"%@_grid_preference", [self getCacheKey:[methods objectForKey:@"method"] parameters:tempDict]];
    return (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0") && ([[parameters objectForKey:@"enableCollectionView"] boolValue] == YES) && ([[userDefaults objectForKey:viewKey] boolValue] == YES));
}

-(NSString *)getCurrentSortMethod:(NSDictionary *)methods withParameters:(NSDictionary *)parameters {
    NSString *sortMethod = [[[parameters objectForKey:@"parameters"] objectForKey:@"sort"] objectForKey:@"method"];
    if (methods != nil){
        NSString *sortKey = [NSString stringWithFormat:@"%@_sort_method", [self getCacheKey:[methods objectForKey:@"method"] parameters:[parameters mutableCopy]]];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults synchronize];
        if ([userDefaults objectForKey:sortKey] != nil){
            sortMethod = [userDefaults objectForKey:sortKey];
        }
    }
    return sortMethod;
}

-(NSString *)getCurrentSortAscDesc:(NSDictionary *)methods withParameters:(NSDictionary *)parameters {
    NSString *sortAscDescSaved = nil;
    if (methods != nil){
        NSString *sortKey = [NSString stringWithFormat:@"%@_sort_ascdesc", [self getCacheKey:[methods objectForKey:@"method"] parameters:[parameters mutableCopy]]];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults synchronize];
        if ([userDefaults objectForKey:sortKey] != nil){
            sortAscDescSaved = [userDefaults objectForKey:sortKey];
        }
    }
    return sortAscDescSaved;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    SDWebImageDownloader *manager = [SDWebImageManager sharedManager].imageDownloader;
    NSDictionary *httpHeaders = [AppDelegate instance].getServerHTTPHeaders;
    if ([httpHeaders objectForKey:@"Authorization"] != nil){
        [manager setValue:[httpHeaders objectForKey:@"Authorization"] forHTTPHeaderField:@"Authorization"];
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    NSString *hidden_label_preferenceString = [userDefaults objectForKey:@"hidden_label_preference"];
    hiddenLabel = [hidden_label_preferenceString boolValue];
    [noItemsLabel setText:NSLocalizedString(@"No items found.", nil)];
    isViewDidLoad = YES;
    iOSYDelta = 44;
    sectionHeight = 16;
    dataList.tableFooterView = [UIView new];
    epgDict = [[NSMutableDictionary alloc] init];
    epgDownloadQueue = [[NSMutableArray alloc] init];
    xbmcDateFormatter = [[NSDateFormatter alloc] init];
    [xbmcDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
    localHourMinuteFormatter = [[NSDateFormatter alloc] init];
    [localHourMinuteFormatter setDateFormat:@"HH:mm"];
    localHourMinuteFormatter.timeZone = [NSTimeZone systemTimeZone];
    self.searchDisplayController.searchResultsTableView.tableFooterView = [UIView new];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        iOSYDelta = - [[UIApplication sharedApplication] statusBarFrame].size.height;
        UIEdgeInsets tableViewInsets = UIEdgeInsetsZero;
        tableViewInsets.top = 44 + fabs(iOSYDelta);
        dataList.contentInset = tableViewInsets;
        dataList.scrollIndicatorInsets = tableViewInsets;
    }
    dataList.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.searchDisplayController.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    [dataList setSectionIndexBackgroundColor:[UIColor clearColor]];
    [dataList setSectionIndexTrackingBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]];
    [dataList setSeparatorInset:UIEdgeInsetsMake(0, 53, 0, 0)];
    
    UIEdgeInsets tableViewInsets = dataList.contentInset;
    tableViewInsets.bottom = 44;
    dataList.contentInset = tableViewInsets;
    dataList.scrollIndicatorInsets = tableViewInsets;
    CGRect frame = dataList.frame;
    frame.size.height=self.view.bounds.size.height;
    dataList.frame = frame;
    buttonsViewBgImage.hidden = YES;
    buttonsViewBgToolbar.hidden = NO;
    
    __weak DetailViewController *weakSelf = self;
    [dataList addPullToRefreshWithActionHandler:^{
        [weakSelf startRetrieveDataWithRefresh:YES];
    }];
    darkCells = [[NSMutableArray alloc] init];
    [self disableScrollsToTopPropertyOnAllSubviewsOf:self.slidingViewController.view];
    enableBarColor = YES;
    utils = [[Utilities alloc] init];
    for(UIView *subView in self.searchDisplayController.searchBar.subviews){
        if([subView isKindOfClass: [UITextField class]]){
            [(UITextField *)subView setKeyboardAppearance: UIKeyboardAppearanceAlert];
        }
    }
    callBack = FALSE;
    self.view.userInteractionEnabled = YES;
    choosedTab = 0;
    [self buildButtons]; // TEMP ?
    numTabs = (int)[[self.detailItem mainMethod] count];
    if ([self.detailItem chooseTab])
        choosedTab=[self.detailItem chooseTab];
    if (choosedTab>=numTabs){
        choosedTab=0;
    }
    watchMode = [self.detailItem currentWatchMode];
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[self.detailItem mainMethod] objectAtIndex:choosedTab]];
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    watchedListenedStrings = [parameters objectForKey:@"watchedListenedStrings"];
    [self checkDiskCache];
    numberOfStars = 10;
    if ([[parameters objectForKey:@"numberOfStars"] intValue] > 0){
        numberOfStars = [[parameters objectForKey:@"numberOfStars"] intValue];
    }
    
    UISearchBarLeftButton *bar = (UISearchBarLeftButton *)self.searchDisplayController.searchBar;
    if ([self collectionViewCanBeEnabled] == YES){
        [bar showLeftButton:YES];
    }
    sortMethodIndex = -1;
    sortMethodName = nil;
    sortAscDesc = nil;
    if ([[[parameters objectForKey:@"parameters"] objectForKey:@"sort"] objectForKey:@"available_methods"] != nil) {
        [self setUpSort:bar methods:methods parameters:parameters];
    }
    [bar setPlaceholder:NSLocalizedString(@"Search", nil)];
    searchBarColor = [UIColor colorWithRed:.35 green:.35 blue:.35 alpha:1];
    collectionViewSearchBarColor = [UIColor blackColor];
    
    CGFloat deltaY = 0;
    searchBarColor = [UIColor colorWithRed:.572f green:.572f blue:.572f alpha:1];
    collectionViewSearchBarColor = [UIColor colorWithRed:22.0f/255.0f green:22.0f/255.0f blue:22.0f/255.0f alpha:1];
    deltaY = 64.0f;

    if ([[methods objectForKey:@"albumView"] boolValue] == YES){
        albumView = TRUE;
    }
    else if ([[methods objectForKey:@"episodesView"] boolValue] == YES){
        episodesView = TRUE;
        searchBarColor = [UIColor colorWithRed:.95 green:.95 blue:.95 alpha:1];
        searchBarColor = [UIColor colorWithRed:229.0f/255.0f green:229.0f/255.0f blue:229.0f/255.0f alpha:1];
        [dataList setSeparatorInset:UIEdgeInsetsMake(0, 18, 0, 0)];
    }
    else if ([[methods objectForKey:@"tvshowsView"] boolValue] == YES){
        tvshowsView = [AppDelegate instance].serverVersion > 11 && [AppDelegate instance].obj.preferTVPosters == NO;
    }
    else if ([[methods objectForKey:@"channelGuideView"] boolValue] == YES){
        channelGuideView = YES;
        sectionHeight = 24;
    }
    else if ([[methods objectForKey:@"channelListView"] boolValue] == YES){
        channelListView = YES;
    }
    
    tableViewSearchBarColor = searchBarColor;
    if ([[parameters objectForKey:@"blackTableSeparator"] boolValue] == YES && [AppDelegate instance].obj.preferTVPosters == NO){
        blackTableSeparator = YES;
        [dataList setSeparatorInset:UIEdgeInsetsZero];
        dataList.separatorColor = [UIColor colorWithRed:.15 green:.15 blue:.15 alpha:1];
        self.searchDisplayController.searchResultsTableView.separatorColor = [UIColor colorWithRed:.15 green:.15 blue:.15 alpha:1];
    }
    self.searchDisplayController.searchBar.tintColor = searchBarColor;
    [self.searchDisplayController.searchBar setBackgroundColor:searchBarColor];

    [detailView setClipsToBounds:YES];
    trackCountLabelWidth = 26;
    epgChannelTimeLabelWidth = 48;
    NSDictionary *itemSizes = [parameters objectForKey:@"itemSizes"];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        [self setIphoneInterface:[itemSizes objectForKey:@"iphone"]];
    }
    else {
        [self setIpadInterface:[itemSizes objectForKey:@"ipad"]];
        deltaY = 0;
    }
    
    if ([[[parameters objectForKey:@"itemSizes"] objectForKey:@"separatorInset"] length]){
        [dataList setSeparatorInset:UIEdgeInsetsMake(0, [[[parameters objectForKey:@"itemSizes"] objectForKey:@"separatorInset"] intValue], 0, 0)];
    }
    
    messagesView = [[MessagesView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, deltaY + 42.0f) deltaY:deltaY deltaX:0];
    [self.view addSubview:messagesView];
    
    frame = dataList.frame;
    if ([parameters objectForKey:@"animationStartX"] != nil){
        frame.origin.x = [[parameters objectForKey:@"animationStartX"] intValue];
    }
    else{
        frame.origin.x = viewWidth;
    }
    if ([[parameters objectForKey:@"animationStartBottomScreen"] boolValue] == YES){
        frame.origin.y = [[UIScreen mainScreen ] bounds].size.height - 44;
    }
    bar.storeWidth = viewWidth;
    dataList.frame=frame;
    currentCollectionViewName = NSLocalizedString(@"View: Wall", nil);
    if ([[parameters objectForKey:@"collectionViewRecentlyAdded"] boolValue] == YES){
        recentlyAddedView = TRUE;
        currentCollectionViewName = NSLocalizedString(@"View: Fanart", nil);
    }
    else{
        recentlyAddedView = FALSE;
    }
    enableCollectionView = [self collectionViewIsEnabled];
    if ([self collectionViewCanBeEnabled]) { // TEMP FIX
        [self initCollectionView];
    }
    activeLayoutView = dataList;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    
    self.sections = [[NSMutableDictionary alloc] init];
    self.richResults= [[NSMutableArray alloc] init ];
    self.filteredListContent = [[NSMutableArray alloc] init ];
    storeRichResults = [[NSMutableArray alloc] init ];
    self.extraSectionRichResults = [[NSMutableArray alloc] init ];
    
    [activityIndicatorView startAnimating];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleTabHasChanged:)
                                                 name: @"tabHasChanged"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(revealMenu:)
                                                 name: @"RevealMenu"
                                               object: nil];

//    //EXPERIMENTAL CODE
//    [[NSNotificationCenter defaultCenter] addObserver: self
//                                             selector: @selector(brightCells)
//                                                 name: @"StackScrollCardDropNotification"
//                                               object: nil];
//    //END EXPERIMENTAL CODE
    
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
    if (channelListView == YES || channelGuideView == YES) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleRecordTimerStatusChange:)
                                                     name: @"KodiServerRecordTimerStatusChange"
                                                   object: nil];
    }
}

-(void)handleRecordTimerStatusChange:(NSNotification*)note {
    NSDictionary *theData = [note userInfo];
    NSArray *keys= [self.sections allKeys];
    for (NSString *keysV in keys) {
        [self checkUpdateRecordingState: [self.sections objectForKey: keysV] dataInfo:theData];
    }
    if ([self.searchDisplayController isActive]) {
        [self checkUpdateRecordingState:self.filteredListContent dataInfo:theData];
    }
}

-(void)checkUpdateRecordingState:(NSMutableArray *)source dataInfo:(NSDictionary *)data {
    NSNumber *channelid = [data objectForKey:@"channelid"];
    NSNumber *broadcastid = [data objectForKey:@"broadcastid"];
    NSNumber *status = [data objectForKey:@"status"];
    if (channelid.integerValue > 0) {
        NSPredicate *filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"channelid = %@", channelid]];
        NSArray *filteredItems = [source filteredArrayUsingPredicate:filter];
        if ([filteredItems count] > 0) {
            NSMutableDictionary *item = [filteredItems objectAtIndex:0];
            [item setObject:status forKey:@"isrecording"];
            [self updateChannelListTableCell];
        }
    }
    if (broadcastid.integerValue > 0) {
        NSPredicate *filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"broadcastid = %@", broadcastid]];
        NSArray *filteredItems = [source filteredArrayUsingPredicate:filter];
        if ([filteredItems count] > 0) {
            NSMutableDictionary *item = [filteredItems objectAtIndex:0];
            [item setObject:status forKey:@"hastimer"];
            [self updateChannelListTableCell];
        }
    }
}

-(void)initIpadCornerInfo {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && [self.detailItem enableSection]){
        titleView = [[UIView alloc] initWithFrame:CGRectMake(320, 0, STACKSCROLL_WIDTH - 320, 44)];
        [titleView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin];
        topNavigationLabel.textAlignment = NSTextAlignmentRight;
        topNavigationLabel.font = [UIFont boldSystemFontOfSize:14];
        [topNavigationLabel setAutoresizingMask: UIViewAutoresizingFlexibleLeftMargin];
        [titleView addSubview:topNavigationLabel];
        [buttonsView addSubview:titleView];
        [self checkFullscreenButton:NO];
    }
}

-(void)checkFullscreenButton:(BOOL)forceHide {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && [self.detailItem enableSection]){
        NSDictionary *parameters = [self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
        if ([self collectionViewCanBeEnabled] && (([[parameters objectForKey:@"enableLibraryFullScreen"] boolValue] == YES) && forceHide == NO)) {
            int buttonPadding = 1;
            if (fullscreenButton == nil){
                fullscreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [fullscreenButton setAutoresizingMask: UIViewAutoresizingFlexibleLeftMargin];
                [fullscreenButton setShowsTouchWhenHighlighted:YES];
                [fullscreenButton setFrame:CGRectMake(0, 0, 26, 26)];
                [fullscreenButton setContentMode:UIViewContentModeCenter];
                [fullscreenButton setImage:[UIImage imageNamed:@"button_fullscreen"] forState:UIControlStateNormal];
                fullscreenButton.layer.cornerRadius = 2.0f;
                [fullscreenButton setTintColor:[UIColor whiteColor]];
                [fullscreenButton addTarget:self action:@selector(toggleFullscreen:) forControlEvents:UIControlEventTouchUpInside];
                [fullscreenButton setFrame:CGRectMake(titleView.frame.size.width - fullscreenButton.frame.size.width - buttonPadding,
                                                      titleView.frame.size.height/2 - fullscreenButton.frame.size.height/2,
                                                      fullscreenButton.frame.size.width,
                                                      fullscreenButton.frame.size.height)];
                [titleView addSubview:fullscreenButton];
            }
            if (twoFingerPinch == nil){
                twoFingerPinch =[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerPinch:)];
                [[self view] addGestureRecognizer:twoFingerPinch];
            }
            [topNavigationLabel setFrame:CGRectMake(0, 0, titleView.frame.size.width - fullscreenButton.frame.size.width - (buttonPadding * 2), 44)];
            fullscreenButton.hidden = NO;
            twoFingerPinch.enabled = YES;
        }
        else {
            [topNavigationLabel setFrame:CGRectMake(0, 0, titleView.frame.size.width - 4, 44)];
            fullscreenButton.hidden = YES;
            twoFingerPinch.enabled = NO;
        }
    }
}

- (void)twoFingerPinch:(UIPinchGestureRecognizer *)recognizer {
    if ([recognizer state] == UIGestureRecognizerStateEnded) {
        if ((recognizer.scale > 1 && stackscrollFullscreen == NO) || (recognizer.scale <= 1 && stackscrollFullscreen == YES)){
            [self toggleFullscreen:nil];
        }
    }
    return;
}

-(void)checkDiskCache{
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    BOOL diskcache_preference = NO;
    NSString *diskcache_preferenceString = [userDefaults objectForKey:@"diskcache_preference"];
    if (diskcache_preferenceString == nil || [diskcache_preferenceString boolValue] == YES) diskcache_preference = YES;
    enableDiskCache = diskcache_preference && [[parameters objectForKey:@"enableLibraryCache"] boolValue];
    [dataList setShowsPullToRefresh:enableDiskCache];
    [collectionView setShowsPullToRefresh:enableDiskCache];
}

- (void) handleEnterForeground: (NSNotification*) sender{
    [self checkDiskCache];
}

-(void)handleChangeLibraryView{
    if ([self.searchDisplayController isActive]) return;
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[self.detailItem mainMethod] objectAtIndex:choosedTab]];
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    if ([self collectionViewCanBeEnabled] == YES && self.view.superview != nil && ![[methods objectForKey:@"method"] isEqualToString:@""]){
        NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:[parameters objectForKey:@"parameters"]];
        if ([AppDelegate instance].serverVersion > 11) {
            if ([tempDict objectForKey:@"filter"] != nil) {
                [tempDict removeObjectForKey:@"filter"];
                [tempDict setObject:@"YES" forKey:@"filtered"];
            }
        }
        else {
            if ([tempDict count] > 2) {
                [tempDict removeAllObjects];
                [tempDict setObject:[[parameters objectForKey:@"parameters"] objectForKey:@"properties"] forKey:@"properties"];
                [tempDict setObject:[[parameters objectForKey:@"parameters"] objectForKey:@"sort"] forKey:@"sort"];
                [tempDict setObject:@"YES" forKey:@"filtered"];
            }
        }
        NSString *viewKey = [NSString stringWithFormat:@"%@_grid_preference", [self getCacheKey:[methods objectForKey:@"method"] parameters:tempDict]];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults synchronize];
        [userDefaults setObject:[NSNumber numberWithBool:![[userDefaults objectForKey:viewKey] boolValue]]
                         forKey:viewKey];
        enableCollectionView = [self collectionViewIsEnabled];
        if ([[parameters objectForKey:@"collectionViewRecentlyAdded"] boolValue] == YES){
            recentlyAddedView = TRUE;
            currentCollectionViewName = NSLocalizedString(@"View: Fanart", nil);
        }
        else{
            recentlyAddedView = FALSE;
            currentCollectionViewName = NSLocalizedString(@"View: Wall", nil);
        }
        [UIView animateWithDuration:0.2
                         animations:^{
                             CGRect frame;
                             frame = [activeLayoutView frame];
                             frame.origin.x = viewWidth;
                             [(UITableView *)activeLayoutView setFrame:frame];
                             [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                         }
                         completion:^(BOOL finished){
                             [self configureLibraryView];
                             [self AnimTable:(UITableView *)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
                             [activeLayoutView setContentOffset:CGPointMake(0, iOSYDelta) animated:NO];
                         }];
    }
}

- (void)handleChangeSortLibrary {
    selected = nil;
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    NSDictionary *sortDictionary = [[[parameters objectForKey:@"parameters"] objectForKey:@"sort"] objectForKey:@"available_methods"];
    NSDictionary *item = [NSDictionary dictionaryWithObjectsAndKeys:
                          NSLocalizedString(@"Sort by", nil), @"label",
                          [NSString stringWithFormat:@"\n(%@)", NSLocalizedString(@"tap the selection\nto reverse the sort order", nil)], @"genre",
                          nil];
    NSMutableArray *sortOptions = [[sortDictionary objectForKey:@"label"] mutableCopy];
    if (sortMethodIndex != -1){
        [sortOptions replaceObjectAtIndex:sortMethodIndex withObject:[NSString stringWithFormat:@"\u2713 %@", [sortOptions objectAtIndex:sortMethodIndex]]];
    }
    UISearchBarLeftButton *bar = (UISearchBarLeftButton *)self.searchDisplayController.searchBar;
    [self showActionSheet:nil sheetActions:sortOptions item:item rectOriginX:bar.sortButton.center.x rectOriginY:bar.sortButton.center.y];
}

-(void)handleLongPressSortButton:(UILongPressGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
            [activityIndicatorView startAnimating];
            [UIView transitionWithView: activeLayoutView
                              duration: 0.2
                               options: UIViewAnimationOptionBeginFromCurrentState
                            animations: ^ {
                                [(UITableView *)activeLayoutView setAlpha:1.0];
                                CGRect frame;
                                frame = [activeLayoutView frame];
                                frame.origin.x = viewWidth;
                                frame.origin.y = 0;
                                [(UITableView *)activeLayoutView setFrame:frame];
                            }
                            completion:^(BOOL finished){
                                sortAscDesc = !([sortAscDesc isEqualToString:@"ascending"] || sortAscDesc == nil)  ? @"ascending" : @"descending";
                                [self saveSortAscDesc:sortAscDesc parameters:[parameters mutableCopy]];
                                storeSectionArray = [sectionArray copy];
                                storeSections = [sections mutableCopy];
                                self.sectionArray = nil;
                                self.sections = [[NSMutableDictionary alloc] init];
                                [self indexAndDisplayData];
                            }];
        }            break;
        default:
            break;
    }
}

- (void)viewDidUnload{
    debugText = nil;
    [super viewDidUnload];
    jsonRPC = nil;
    self.richResults = nil;
    self.filteredListContent = nil;
    self.sections = nil;
    dataList = nil;
    collectionView = nil;
    jsonCell = nil;
    activityIndicatorView = nil;
    nowPlaying = nil;
    playFileViewController = nil;
    epgDownloadQueue = nil;
    epgDict = nil;
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [channelListUpdateTimer invalidate];
    channelListUpdateTimer = nil;
}

//- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation duration:(NSTimeInterval)duration {
//	if (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
//        dataList.alpha = 1;
//	}
//	else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight){
//        dataList.alpha = 0;
//	}
//}

-(void)dealloc{
    jsonRPC = nil;
    [self.richResults removeAllObjects];
    [self.filteredListContent removeAllObjects];
    self.richResults = nil;
    self.filteredListContent = nil;
    self.detailItem = nil;
    [self.sections removeAllObjects];
    self.sections = nil;
    self.sectionArray = nil;
    self.sectionArrayOpen = nil;
    self.extraSectionRichResults = nil;
    self.indexView = nil;
    dataList = nil;
    collectionView = nil;
    jsonCell = nil;
    activityIndicatorView = nil;
    nowPlaying = nil;
    self.playFileViewController = nil;
    self.nowPlaying = nil;
    self.webViewController = nil;
    self.showInfoViewController = nil;
    self.detailViewController = nil;
    epgDownloadQueue = nil;
    epgDict = nil;
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
////    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
//    return interfaceOrientation;
//
//}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)shouldAutorotate{
    return YES;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    return UIInterfaceOrientationMaskPortrait;
}
////EXPERIMENTAL CODE
//-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
//    if ([[collectionView indexPathsForSelectedItems] count] > 0){
//        [self darkCells];
//        [collectionView selectItemAtIndexPath:[[collectionView indexPathsForSelectedItems] objectAtIndex:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredVertically];
//        autoScroll = YES;
//    }
//}
////END EXPERIMENTAL CODE

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}
							
@end
