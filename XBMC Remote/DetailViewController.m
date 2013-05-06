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
#define COLLECTION_HEADER_HEIGHT 24

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
    int numelement=[array count];
    for (int i=0;i<numelement-1;i+=2){
        [mutableDictionary setObject:[array objectAtIndex:i] forKey:[array objectAtIndex:i+1]];
    }
    return (NSDictionary *)mutableDictionary;
}

- (NSMutableDictionary *) indexKeyedMutableDictionaryFromArray:(NSArray *)array {
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    int numelement=[array count];
    for (int i=0;i<numelement-1;i+=2){
        [mutableDictionary setObject:[array objectAtIndex:i] forKey:[array objectAtIndex:i+1]];
    }
    return (NSMutableDictionary *)mutableDictionary;
}

#pragma mark - library disk cache management

-(NSString *)getCacheKey:(NSString *)fieldA parameters:(NSMutableDictionary *)fieldB{
    GlobalData *obj=[GlobalData getInstance];
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
    int section = [sender.view tag];
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
    CGContextRef shadowContext = CGBitmapContextCreate(NULL, source.size.width + shadowRadius * 2, source.size.height + shadowRadius * 2, CGImageGetBitsPerComponent(source.CGImage), 0, colourSpace, kCGImageAlphaPremultipliedLast);
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
    int count = [[self.detailItem mainParameters] count];
    NSMutableArray *mainMenu = [[NSMutableArray alloc] init];
    int numIcons = [[self.detailItem mainButtons] count];
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
        [detailView addSubview:moreItemsViewController.view];
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
        [UIView commitAnimations];
    }
    [activityIndicatorView stopAnimating];
}


- (void) handleTabHasChanged:(NSNotification*) notification{
    NSArray *buttons=[self.detailItem mainButtons];
    if (![buttons count]) return;
    NSIndexPath *choice=notification.object;
    choosedTab = 0;
    int selectedIdx = MAX_NORMAL_BUTTONS + choice.row;
    selectedMoreTab.tag=selectedIdx;
    [self changeTab:selectedMoreTab];
}

-(void)changeViewMode:(int)newWatchMode forceRefresh:(BOOL)refresh{
    [activityIndicatorView startAnimating];
    if (!refresh){
        [self AnimTable:(UITableView *)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:viewWidth];
    }
    NSArray *buttonsIB=[NSArray arrayWithObjects:button1, button2, button3, button4, button5, nil];
    [[buttonsIB objectAtIndex:choosedTab] setImage:[UIImage imageNamed:[[[[self.detailItem watchModes] objectAtIndex:choosedTab] objectForKey:@"icons"] objectAtIndex:newWatchMode]] forState:UIControlStateSelected];
    [self.richResults removeAllObjects];
    [self.sections removeAllObjects];
    [activeLayoutView reloadData];
    self.richResults = [storeRichResults mutableCopy];
    int total = [self.richResults count];
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
    return;
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
        searchBarColor = collectionViewSearchBarColor;
        [bar.viewLabel setText:currentCollectionViewName];
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
        searchBarColor = tableViewSearchBarColor;
        [bar.viewLabel setText:NSLocalizedString(@"View: List", nil)];
        [bar.leftButton setImage:[UIImage imageNamed:@"button_view_list"] forState:UIControlStateNormal];
    }
    [activeLayoutView addSubview:self.searchDisplayController.searchBar];
}

-(IBAction)changeTab:(id)sender{
    if (activityIndicatorView.hidden == NO) return;
    [activeLayoutView setUserInteractionEnabled:YES];
    [((UITableView *)activeLayoutView).pullToRefreshView stopAnimating];
    if ([sender tag]==choosedTab) {
        NSArray *watchedCycle = [self.detailItem watchModes];
        int num_modes = [[[watchedCycle objectAtIndex:choosedTab] objectForKey:@"modes"] count];
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
    numTabs=[[self.detailItem mainMethod] count];
    int newChoosedTab=[sender tag];
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
    choosedTab=newChoosedTab;
    if (choosedTab<[buttonsIB count]){
        [[buttonsIB objectAtIndex:choosedTab] setSelected:YES];
    }
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[self.detailItem mainMethod] objectAtIndex:choosedTab]];
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    
    BOOL newEnableCollectionView = [self collectionViewIsEnabled];
    UISearchBarLeftButton *bar = (UISearchBarLeftButton *)self.searchDisplayController.searchBar;
    bar.leftPadding = 0;
    if ([self collectionViewCanBeEnabled] == YES){
        bar.leftPadding = SEARCH_BAR_LEFT_PADDING;
    }
    [bar layoutSubviews];
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
        [UIView commitAnimations];
    }
    NSMutableDictionary *mutableParameters = [[parameters objectForKey:@"parameters"] mutableCopy];
    NSMutableArray *mutableProperties = [[[parameters objectForKey:@"parameters"] objectForKey:@"properties"] mutableCopy];
    if ([[parameters objectForKey:@"FrodoExtraArt"] boolValue] == YES && [AppDelegate instance].serverVersion > 11){
        [mutableProperties addObject:@"art"];
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
    if ([methods objectForKey:@"method"]!=nil){
        [self retrieveData:[methods objectForKey:@"method"] parameters:mutableParameters sectionMethod:[methods objectForKey:@"extra_section_method"] sectionParameters:[parameters objectForKey:@"extra_section_parameters"] resultStore:self.richResults extraSectionCall:NO refresh:NO];
    }
    else {
        [activityIndicatorView stopAnimating];
        [self AnimTable:(UITableView *)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
}

#pragma mark - Library item didSelect

-(void)didSelectItemAtIndexPath:(NSIndexPath *)indexPath item:(NSDictionary *)item displayPoint:(CGPoint) point{
    
    self.detailViewController=nil;
    mainMenu *MenuItem=self.detailItem;
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[MenuItem.subItem mainMethod] objectAtIndex:choosedTab]];
    NSMutableArray *sheetActions=[[self.detailItem sheetActions] objectAtIndex:choosedTab];
    int rectOriginX = point.x;
    int rectOriginY = point.y;
    
    if ([methods objectForKey:@"method"]!=nil){ // THERE IS A CHILD
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
        
        if ([[parameters objectForKey:@"parameters"] objectForKey:@"properties"]!=nil){ // CHILD IS LIBRARY MODE
            NSString *key=@"null";
            if ([item objectForKey:[mainFields objectForKey:@"row15"]]!=nil){
                key=[mainFields objectForKey:@"row15"];
            }
            id obj = [item objectForKey:[mainFields objectForKey:@"row6"]];
            id objKey = [mainFields objectForKey:@"row6"];
            //            NSLog(@"ECCOCI %d %d", [MenuItem.subItem disableFilterParameter], [[parameters objectForKey:@"disableFilterParameter"] boolValue]);
            if ([AppDelegate instance].serverVersion>11 && [[parameters objectForKey:@"disableFilterParameter"] boolValue] == FALSE){
                obj = [NSDictionary dictionaryWithObjectsAndKeys:[item objectForKey:[mainFields objectForKey:@"row6"]],[mainFields objectForKey:@"row6"], nil];
                objKey = @"filter";
            }
            if ([parameters objectForKey:@"disableFilterParameter"]==nil)
                [parameters setObject:@"false" forKey:@"disableFilterParameter"];
            NSMutableDictionary *newSectionParameters = nil;
            if ([parameters objectForKey:@"extra_section_parameters"] != nil){
                newSectionParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        obj, objKey,
                                        [[parameters objectForKey:@"extra_section_parameters"] objectForKey:@"properties"], @"properties",
                                        [[parameters objectForKey:@"extra_section_parameters"] objectForKey:@"sort"],@"sort",
                                        [item objectForKey:[mainFields objectForKey:@"row15"]], key,
                                        nil];
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
                                           [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"collectionViewRecentlyAdded"] boolValue]], @"collectionViewRecentlyAdded",
                                           [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"blackTableSeparator"] boolValue]], @"blackTableSeparator",
                                           [parameters objectForKey:@"extra_info_parameters"], @"extra_info_parameters",
                                           newSectionParameters, @"extra_section_parameters",
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
                DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem.subItem withFrame:CGRectMake(0, 0, 477, self.view.frame.size.height) bundle:nil];
                [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
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
                        DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem withFrame:CGRectMake(0, 0, 477, self.view.frame.size.height) bundle:nil];
                        [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
                    }
                }
                else if ([[item objectForKey:@"genre"] isEqualToString:@"file"] || [[item objectForKey:@"filetype"] isEqualToString:@"file"]){
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    [userDefaults synchronize];
                    if ([[userDefaults objectForKey:@"song_preference"] boolValue]==NO ){
                        selected=indexPath;
                        [self showActionSheet:indexPath sheetActions:sheetActions item:item rectOriginX:rectOriginX rectOriginY:rectOriginY];
                    }
                    else {
                        [self addPlayback:item indexPath:indexPath position:indexPath.row shuffle:NO];
                    }
                    return;
                }
                else
                    return;
            }
            else{ // WE ENTERING FILEMODE
                NSMutableArray *newParameters=[NSMutableArray arrayWithObjects:
                                               [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                [item objectForKey:[mainFields objectForKey:@"row6"]],@"directory",
                                                [[parameters objectForKey:@"parameters"] objectForKey:@"media"], @"media",
                                                [[parameters objectForKey:@"parameters"] objectForKey:@"sort"],@"sort",
                                                [[parameters objectForKey:@"parameters"] objectForKey:@"file_properties"], @"file_properties",
                                                nil], @"parameters", [parameters objectForKey:@"label"], @"label", @"nocover_filemode.png", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeThumbWidth, @"thumbWidth",
                                               [NSDictionary dictionaryWithDictionary:[parameters objectForKey:@"itemSizes"]], @"itemSizes",
                                               [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"enableCollectionView"] boolValue]], @"enableCollectionView",
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
                    DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem.subItem withFrame:CGRectMake(0, 0, 477, self.view.frame.size.height) bundle:nil];
                    [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
                }
            }
        }
    }
    else {
        if ([[MenuItem.showInfo objectAtIndex:choosedTab] boolValue]){
            [self showInfo:indexPath menuItem:self.detailItem item:item tabToShow:choosedTab];
        }
        else {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults synchronize];
            if ([[userDefaults objectForKey:@"song_preference"] boolValue] == NO){
                sheetActions = [self checkMusicPlaylists:sheetActions item:item params:[self indexKeyedMutableDictionaryFromArray:[[MenuItem mainParameters] objectAtIndex:choosedTab]]];
                selected=indexPath;
                [self showActionSheet:indexPath sheetActions:sheetActions item:item rectOriginX:rectOriginX rectOriginY:rectOriginY];
            }
            else {
                [self addPlayback:item indexPath:indexPath position:indexPath.row shuffle:NO];
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
    if (enableCollectionView && [self.richResults count] > SECTIONS_START_AT && section > 0){
        return CGSizeMake(dataList.frame.size.width, COLLECTION_HEADER_HEIGHT);
    }
    else{
        return CGSizeMake(0, 0);
    }
}

-(void)setFlowLayoutParams{
    [flowLayout setItemSize:CGSizeMake(cellGridWidth, cellGridHeight)];
    if (!cellMinimumLineSpacing) cellMinimumLineSpacing = 2;
    [flowLayout setMinimumLineSpacing:cellMinimumLineSpacing];
}

#pragma mark - UICollectionView methods

-(void)initCollectionView{
    if (collectionView == nil){
        flowLayout = [[FloatingHeaderFlowLayout alloc] init];
        [self setFlowLayoutParams];
        [flowLayout setMinimumInteritemSpacing:2.0f];
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
        collectionView = [[UICollectionView alloc] initWithFrame:dataList.frame collectionViewLayout:flowLayout];
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
        [detailView addSubview:collectionView];
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
    if (section == 0) {
        return UIEdgeInsetsMake(CGRectGetHeight(self.searchDisplayController.searchBar.frame), 0, 0, 0);
    }
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)cView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"posterHeaderView";
    PosterHeaderView *headerView = [cView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:identifier forIndexPath:indexPath];
    NSString *searchTerm = [self.sectionArray objectAtIndex:indexPath.section];
    [headerView setHeaderText:searchTerm];
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

    if (recentlyAddedView == FALSE){
        static NSString *identifier = @"posterCell";
        PosterCell *cell = [cView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        [cell.posterLabel setFont:[UIFont boldSystemFontOfSize:posterFontSize]];
        [cell.posterThumbnail setContentMode:UIViewContentModeScaleAspectFill];
        if ([[item objectForKey:@"filetype"] length]!=0 || [[item objectForKey:@"family"] isEqualToString:@"file"] || [[item objectForKey:@"family"] isEqualToString:@"genreid"]){
            if (![stringURL isEqualToString:@""]){
                displayThumb=stringURL;
            }
        }
        if (![stringURL isEqualToString:@""]){
            if ([[item objectForKey:@"family"] isEqualToString:@"channelid"]){
                [cell.posterThumbnail setContentMode:UIViewContentModeScaleAspectFit];
            }
            [cell.posterThumbnail setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:displayThumb] andResize:CGSizeMake(cellGridWidth, cellGridHeight)];
        }
        else {
            [cell.posterThumbnail setImageWithURL:[NSURL URLWithString:@""] placeholderImage:[UIImage imageNamed:displayThumb] ];
        }
        [cell.posterLabel setText:[item objectForKey:@"label"]];
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
        float posterWidth = cellGridHeight * 0.66f;
        float fanartWidth = cellGridWidth - posterWidth;

        if (![stringURL isEqualToString:@""]){
            [cell.posterThumbnail setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:displayThumb] andResize:CGSizeMake(posterWidth, cellGridHeight)];
        }
        else {
            [cell.posterThumbnail setImageWithURL:[NSURL URLWithString:@""] placeholderImage:[UIImage imageNamed:displayThumb] ];
        }

        if (![fanartURL isEqualToString:@""]){
            [cell.posterFanart setImageWithURL:[NSURL URLWithString:fanartURL] placeholderImage:[UIImage imageNamed:@""]andResize:CGSizeMake(fanartWidth, cellGridHeight)];
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
    sectionNameOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width / 4, self.view.frame.size.width / 4)];
    sectionNameOverlayView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin);
    [sectionNameOverlayView setBackgroundColor:[UIColor clearColor]];
    sectionNameOverlayView.center = self.view.center;
    float cornerRadius = 6.0f;
    sectionNameOverlayView.layer.cornerRadius = cornerRadius;
    sectionNameOverlayView.layer.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0f].CGColor;
    sectionNameOverlayView.layer.shadowOpacity = 1.0f;
    sectionNameOverlayView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    sectionNameOverlayView.layer.shadowRadius = 1.0f;
    sectionNameOverlayView.layer.masksToBounds = NO;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:sectionNameOverlayView.bounds
                                               byRoundingCorners:UIRectCornerAllCorners
                                                     cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
    sectionNameOverlayView.layer.shadowPath = path.CGPath;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = sectionNameOverlayView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:.6 green:.6 blue:.6 alpha:.95] CGColor], (id)[[UIColor colorWithRed:.9 green:.9 blue:.9 alpha:.95] CGColor], nil];
    gradient.cornerRadius = cornerRadius;
    [sectionNameOverlayView.layer insertSublayer:gradient atIndex:0];
    
    sectionNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, sectionNameOverlayView.frame.size.height/2 - 10, sectionNameOverlayView.frame.size.width, 20)];
    [sectionNameLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [sectionNameLabel setTextColor:[UIColor whiteColor]];
    [sectionNameLabel setBackgroundColor:[UIColor clearColor]];
    [sectionNameLabel setTextAlignment:NSTextAlignmentCenter];
    [sectionNameLabel setShadowColor:[UIColor darkGrayColor]];
    [sectionNameLabel setShadowOffset:CGSizeMake(0, 1)];
    [sectionNameOverlayView addSubview:sectionNameLabel];
    [self.view addSubview:sectionNameOverlayView];
}

- (BDKCollectionIndexView *)indexView {
    if (_indexView) return _indexView;
    CGFloat indexWidth = 32;
    CGRect frame = CGRectMake(CGRectGetWidth(dataList.frame) - indexWidth,
                              CGRectGetMinY(dataList.frame) + 4,
                              indexWidth,
                              CGRectGetHeight(dataList.frame) - 4);
    _indexView = [BDKCollectionIndexView indexViewWithFrame:frame indexTitles:@[]];
    _indexView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin);
    _indexView.hidden = YES;
    [_indexView addTarget:self action:@selector(indexViewValueChanged:) forControlEvents:UIControlEventValueChanged];
    [detailView addSubview:_indexView];
    return _indexView;
}

- (void)indexViewValueChanged:(BDKCollectionIndexView *)sender {
//    [SDWebImageManager.sharedManager.imageCache clearMemory];
    if (sender.currentIndex == 0){
        [collectionView setContentOffset:CGPointMake(0, 0) animated:NO];
        return;
    }
    else{
        NSIndexPath *path = [NSIndexPath indexPathForItem:0 inSection:sender.currentIndex];
        [collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        collectionView.contentOffset = CGPointMake(collectionView.contentOffset.x, collectionView.contentOffset.y - COLLECTION_HEADER_HEIGHT);
        if (sectionNameOverlayView == nil && COLLECTION_HEADER_HEIGHT <= 10){
            [self initSectionNameOverlayView];
        }
        sectionNameLabel.text = [self.sectionArray objectAtIndex:sender.currentIndex];
    }
}

-(void)handleCollectionIndexStateBegin{
    if (COLLECTION_HEADER_HEIGHT <= 10){
        [self alphaView:sectionNameOverlayView AnimDuration:0.1f Alpha:1];
    }
}

-(void)handleCollectionIndexStateEnded{
    if (COLLECTION_HEADER_HEIGHT <= 10){
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
    if ([[parameters objectForKey:@"defaultThumb"] length]!=0){
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
    }
    else if (episodesView){
        thumbWidth = 0;
        labelPosition = 18;
    }
    else{
        labelPosition=thumbWidth + 8;
    }
    int newWidthLabel = 0;
    if (Menuitem.originLabel && ![parameters objectForKey:@"thumbWidth"])
        labelPosition = Menuitem.originLabel;
    // CHECK IF THERE ARE SECTIONS
    if ([self.richResults count]<=SECTIONS_START_AT || ![self.detailItem enableSection]){
        newWidthLabel = viewWidth - 8 - labelPosition;
        Menuitem.originYearDuration = viewWidth - 72;
    }
    else{
        newWidthLabel = viewWidth - 38 - labelPosition;
        Menuitem.originYearDuration = viewWidth - 100;
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
        int numResult=[self.filteredListContent count];
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
        return [self.sectionArray objectAtIndex:section];
    }
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
        if ([self.detailItem enableSection]  && [self.richResults count]>SECTIONS_START_AT){
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
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"jsonDataCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        if (albumView){
            UILabel *trackNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(albumViewPadding, cellHeight/2 - (artistFontSize + labelPadding)/2, trackCountLabelWidth - 2, artistFontSize + labelPadding)];
            [trackNumberLabel setBackgroundColor:[UIColor clearColor]];
            [trackNumberLabel setFont:[UIFont systemFontOfSize:artistFontSize]];
            trackNumberLabel.adjustsFontSizeToFitWidth = YES;
            trackNumberLabel.minimumFontSize = artistFontSize - 4;
            trackNumberLabel.tag = 101;
            [trackNumberLabel setHighlightedTextColor:[UIColor whiteColor]];
            [cell addSubview:trackNumberLabel];
        }
    }
    mainMenu *Menuitem = self.detailItem;
//    NSDictionary *mainFields=[[Menuitem mainFields] objectAtIndex:choosedTab];
/* future - need to be tweaked: doesn't work on file mode. mainLabel need to be resized */
//    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[Menuitem.subItem mainMethod] objectAtIndex:choosedTab]];
//    if ([methods objectForKey:@"method"]!=nil){ // THERE IS A CHILD
//        cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator; 
//    }
/* end future */
    CGRect frame=cell.urlImageView.frame;
    frame.size.width=thumbWidth;
    cell.urlImageView.frame=frame;
    NSDictionary *item=nil;
    if (tableView == self.searchDisplayController.searchResultsTableView){
        item = [self.filteredListContent objectAtIndex:indexPath.row];
    }
	else{
        item = [[self.sections valueForKey:[self.sectionArray objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    }
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
//    if([[item objectForKey:@"family"] isEqualToString:@"episodeid"]){
//        [genre setText:[item objectForKey:@"runtime"]];
//    }
//    else{
        [genre setText:[item objectForKey:@"genre"]];
//    }
    
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
    [rating setText:[item objectForKey:@"rating"]];
    [cell.urlImageView setContentMode:UIViewContentModeScaleAspectFill];
    if (!albumView && !episodesView){
        NSString *stringURL = [item objectForKey:@"thumbnail"];
        NSString *displayThumb=defaultThumb;
        if ([[item objectForKey:@"filetype"] length]!=0 || [[item objectForKey:@"family"] isEqualToString:@"file"] || [[item objectForKey:@"family"] isEqualToString:@"genreid"]){
            if (![stringURL isEqualToString:@""]){
                displayThumb=stringURL;
            }
            genre.hidden = YES;
            runtimeyear.hidden = YES;
            [title setFrame:CGRectMake(title.frame.origin.x, (int)((cellHeight/2) - (title.frame.size.height/2)), title.frame.size.width, title.frame.size.height)];
        }
        else{
            genre.hidden = NO;
            runtimeyear.hidden = NO;
        }
        if (![stringURL isEqualToString:@""]){
            if ([[item objectForKey:@"family"] isEqualToString:@"channelid"]){
                [cell.urlImageView setContentMode:UIViewContentModeScaleAspectFit];
            }
            [cell.urlImageView setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:displayThumb]andResize:CGSizeMake(thumbWidth, cellHeight) completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                if (blackTableSeparator == YES && [AppDelegate instance].obj.preferTVPosters == NO && [indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:0]]){
                    UIColor *barColor = [utils darkerColorForColor:[utils averageColor:image inverse:NO]];
                    self.searchDisplayController.searchBar.tintColor = barColor;
                }
            }];
        }
        else {
            [cell.urlImageView setImageWithURL:[NSURL URLWithString:@""] placeholderImage:[UIImage imageNamed:displayThumb]];
        }
    }
    else if (albumView){
        UILabel *trackNumber = (UILabel *)[cell viewWithTag:101];
        trackNumber.text = [item objectForKey:@"track"];
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
        [thumbImageView setClipsToBounds:YES];
        [thumbImageView setContentMode:UIViewContentModeScaleAspectFill];
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
                                      BOOL isRetina = ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2);
                                      float thumbBorder = isRetina ? 0.5f : 1.0f;
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
                                          self.navigationController.navigationBar.tintColor = albumColor;
                                          self.searchDisplayController.searchBar.tintColor = albumColor;
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
                                          albumDetailsColor = [utils updateColor:albumColor lightColor:[UIColor whiteColor] darkColor:[UIColor darkGrayColor]];
                                          [artist setTextColor:albumFontColor];
                                          [artist setShadowColor:albumFontShadowColor];
                                          [albumLabel setTextColor:albumFontColor];
                                          [albumLabel setShadowColor:albumFontShadowColor];
                                          [trackCountLabel setTextColor:albumDetailsColor];
                                          [trackCountLabel setShadowColor:albumFontShadowColor];
                                          [releasedLabel setTextColor:albumDetailsColor];
                                          [releasedLabel setShadowColor:albumFontShadowColor];
                                          
                                      }
                                  }];
        }
        else {
            [thumbImageView setImageWithURL:[NSURL URLWithString:@""] placeholderImage:[UIImage imageNamed:displayThumb] ];
        }
        [thumbImageContainer addSubview:thumbImageView];
        [albumDetailView addSubview:thumbImageContainer];
        
        [artist setBackgroundColor:[UIColor clearColor]];
        [artist setTextColor:albumFontColor];
        [artist setShadowColor:albumFontShadowColor];
        [artist setShadowOffset:CGSizeMake(0, 1)];
        [artist setFont:[UIFont systemFontOfSize:artistFontSize]];
        artist.adjustsFontSizeToFitWidth = YES;
        artist.minimumFontSize = 9;
        artist.text = [item objectForKey:@"genre"];
        [albumDetailView addSubview:artist];
        
        [albumLabel setBackgroundColor:[UIColor clearColor]];
        [albumLabel setTextColor:albumFontColor];
        [albumLabel setShadowColor:albumFontShadowColor];
        [albumLabel setShadowOffset:CGSizeMake(0, 1)];
        [albumLabel setFont:[UIFont boldSystemFontOfSize:albumFontSize]];
        albumLabel.text = self.navigationItem.title;
        albumLabel.numberOfLines = 0;
        CGSize maximunLabelSize= CGSizeMake(viewWidth - albumViewHeight - albumViewPadding, albumViewHeight - albumViewPadding*4 -28);
        CGSize expectedLabelSize = [albumLabel.text
                                    sizeWithFont:albumLabel.font
                                    constrainedToSize:maximunLabelSize
                                    lineBreakMode:albumLabel.lineBreakMode];
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
        trackCountLabel.text = [NSString stringWithFormat:@"%d %@, %@ %@", [self.richResults count], [self.richResults count] > 1 ? NSLocalizedString(@"Songs", nil)  : NSLocalizedString(@"Song", nil), numberString, totalTime/60 > 1 ? NSLocalizedString(@"Mins.", nil) : NSLocalizedString(@"Min", nil)];
        [albumDetailView addSubview:trackCountLabel];
        int year = [[item objectForKey:@"year"] intValue];
        [releasedLabel setBackgroundColor:[UIColor clearColor]];
        [releasedLabel setTextColor:albumDetailsColor];
        [releasedLabel setShadowColor:albumFontShadowColor];
        [releasedLabel setShadowOffset:CGSizeMake(0, 1)];
        [releasedLabel setFont:[UIFont systemFontOfSize:trackCountFontSize]];
        releasedLabel.text = [NSString stringWithFormat:@"%@", (year > 0) ? [NSString stringWithFormat:NSLocalizedString(@"Released %d", nil), year] : @"" ];
        [albumDetailView addSubview:releasedLabel];
        
        BOOL fromShowInfo = NO;
        if ([[self.detailItem mainParameters] count]>0){
            NSMutableDictionary *parameters=[self indexKeyedMutableDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:0]];
            if (((NSNull *)[parameters objectForKey:@"fromShowInfo"] != [NSNull null])){
                fromShowInfo = [[parameters objectForKey:@"fromShowInfo"] boolValue];
            }
        }
        UIButton *albumInfoButton =  [UIButton buttonWithType:UIButtonTypeInfoDark ];
        albumInfoButton.alpha = .5f;
        [albumInfoButton setFrame:CGRectMake(viewWidth - albumInfoButton.frame.size.width - albumViewPadding, bottomMargin, albumInfoButton.frame.size.width, albumInfoButton.frame.size.height)];
        if (fromShowInfo){
            [albumInfoButton addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
        }
        else{
            albumInfoButton.tag = 0;
            [albumInfoButton addTarget:self action:@selector(prepareShowAlbumInfo:) forControlEvents:UIControlEventTouchUpInside];
        }
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
        int seasonIdx = [self indexOfObjectWithSeason:[NSString stringWithFormat:@"%d",[[item objectForKey:@"season"] intValue]] inArray:self.extraSectionRichResults];
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
            artist.minimumFontSize = 9;
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
            CGSize expectedLabelSize = [albumLabel.text
                                        sizeWithFont:albumLabel.font
                                        constrainedToSize:maximunLabelSize
                                        lineBreakMode:albumLabel.lineBreakMode];
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

            BOOL fromShowInfo = NO;
            if ([[self.detailItem mainParameters] count]>0){
                NSMutableDictionary *parameters=[self indexKeyedMutableDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:0]];
                if (((NSNull *)[parameters objectForKey:@"fromShowInfo"] != [NSNull null])){
                    fromShowInfo = [[parameters objectForKey:@"fromShowInfo"] boolValue];
                }
            }
            UIButton *albumInfoButton =  [UIButton buttonWithType:UIButtonTypeInfoDark ] ;
            albumInfoButton.alpha = .6f;
            [albumInfoButton setFrame:CGRectMake(viewWidth - albumInfoButton.frame.size.width - albumViewPadding, bottomMargin - 3, albumInfoButton.frame.size.width, albumInfoButton.frame.size.height)];
            if (fromShowInfo){
                [albumInfoButton addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
            }
            else{
                albumInfoButton.tag = 1;
                [albumInfoButton addTarget:self action:@selector(prepareShowAlbumInfo:) forControlEvents:UIControlEventTouchUpInside];
            }
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
    int sectionHeight = 22;
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
        CGRect toolbarShadowUpFrame = CGRectMake(0.0f, -5, viewWidth, 4);
        UIImageView *toolbarUpShadow = [[UIImageView alloc] initWithFrame:toolbarShadowUpFrame];
        [toolbarUpShadow setImage:[UIImage imageNamed:@"tableDown.png"]];
        toolbarUpShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbarUpShadow.contentMode = UIViewContentModeScaleToFill;
        toolbarUpShadow.opaque = YES;
        toolbarUpShadow.alpha = .3f;
        [sectionView addSubview:toolbarUpShadow];
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, viewWidth - 20, sectionHeight)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    [label setShadowColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.6]];
    [label setShadowOffset:CGSizeMake(0, 1)];
    label.font = [UIFont boldSystemFontOfSize:18];
    label.text = sectionTitle;    
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
        return 22;
    }
    if ([[self.sections allKeys] count] == 1){
        return 1;
    }
    return 0;
}


- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
        UIImage *myImage = [UIImage imageNamed:@"blank.png"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
        imageView.frame = CGRectMake(0,0,viewWidth,1);
        return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
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
    numFilteredResults=[self.filteredListContent count];
}


#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

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



#pragma mark - Long Press & Action sheet

NSIndexPath *selected;

-(void)showActionSheet:(NSIndexPath *)indexPath sheetActions:(NSArray *)sheetActions item:(NSDictionary *)item rectOriginX:(int) rectOriginX rectOriginY:(int) rectOriginY {
    int numActions=[sheetActions count];
    if (numActions){
        NSString *title=[NSString stringWithFormat:@"%@\n%@", [item objectForKey:@"label"], [item objectForKey:@"genre"]];
        UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:title
                                                            delegate:self
                                                   cancelButtonTitle:nil
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:nil
                                 ];
        action.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        for (int i = 0; i < numActions; i++) {
            [action addButtonWithTitle:[sheetActions objectAtIndex:i]];
        }
        action.cancelButtonIndex = [action addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
            [action showInView:self.view];
        }
        else{
            [action showFromRect:CGRectMake(rectOriginX, rectOriginY, 1, 1) inView:self.view animated:YES];
        }    
    }
    else if (indexPath!=nil){ // No actions found, revert back to standard play action
        [self addPlayback:item indexPath:indexPath position:indexPath.row shuffle:NO];
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
            }
            NSMutableArray *sheetActions=[[self.detailItem sheetActions] objectAtIndex:choosedTab];
            int numActions=[sheetActions count];
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
                numActions=[sheetActions count];
//                if ([[item objectForKey:@"filetype"] isEqualToString:@"directory"]) { // DOESN'T WORK AT THE MOMENT IN XBMC?????
//                    return;
//                }                
                NSString *title=[NSString stringWithFormat:@"%@\n%@", [item objectForKey:@"label"], [item objectForKey:@"genre"]];
                UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:title
                                                                    delegate:self
                                                           cancelButtonTitle:nil
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:nil
                                         ];
                action.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
                for (int i = 0; i < numActions; i++) {
                    [action addButtonWithTitle:[sheetActions objectAtIndex:i]];
                }
                if ([[item objectForKey:@"trailer"] isKindOfClass:[NSString class]]){
                    if ([[item objectForKey:@"trailer"] length]!=0 && [[[self.detailItem sheetActions] objectAtIndex:choosedTab] isKindOfClass:[NSMutableArray class]]){
                        [action addButtonWithTitle:NSLocalizedString(@"Play Trailer", nil)];
                        [[[self.detailItem sheetActions] objectAtIndex:choosedTab] addObject:NSLocalizedString(@"Play Trailer", nil)];
                    }
                }
                action.cancelButtonIndex = [action addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
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

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    NSArray *sheetActions=[[self.detailItem sheetActions] objectAtIndex:choosedTab];
    if (buttonIndex!=actionSheet.cancelButtonIndex){
        NSDictionary *item = nil;
        if ([self.searchDisplayController isActive]){
            item = [self.filteredListContent objectAtIndex:selected.row];
        }
        else{
            item = [[self.sections valueForKey:[self.sectionArray objectAtIndex:selected.section]] objectAtIndex:selected.row];
        }
        if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Play", nil)]){
            NSString *songid = [NSString stringWithFormat:@"%@", [item objectForKey:@"songid"]];
            if ([songid intValue]){
                [self addPlayback:item indexPath:selected position:selected.row shuffle:NO];
            }
            else {
                [self addPlayback:item indexPath:selected position:0 shuffle:NO];
            }
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Play in shuffle mode", nil)]){
            [self addPlayback:item indexPath:selected position:0 shuffle:YES];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Queue", nil)]){
            [self addQueue:item indexPath:selected];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Queue after current", nil)]){
            [self addQueue:item indexPath:selected afterCurrentItem:YES];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Show Content", nil)]){
            [self exploreItem:item];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Play in party mode", nil)]){
            [self partyModeItem:item indexPath:selected];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] rangeOfString:NSLocalizedString(@"Details", nil)].location!= NSNotFound){
            [self showInfo:selected menuItem:self.detailItem item:item tabToShow:choosedTab];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Play Trailer", nil)]){
            [self playerOpen:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:@"trailer"], @"file", nil], @"item", nil] index:selected];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Stream to iPhone", nil)]){
            [self addStream:item indexPath:selected];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Search Wikipedia", nil)]){            
            [self searchWeb:item indexPath:selected serviceURL:[NSString stringWithFormat:@"http://%@.m.wikipedia.org/wiki?search=%%@", NSLocalizedString(@"WIKI_LANG", nil)]];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Search last.fm charts", nil)]){
            [self searchWeb:item indexPath:selected serviceURL:@"http://m.last.fm/music/%@/+charts?subtype=tracks&rangetype=6month&go=Go"];
        }
    }
    else{
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

-(void)searchWeb:(NSDictionary *)item indexPath:(NSIndexPath *)indexPath serviceURL:(NSString *)serviceURL{
    self.webViewController = nil;
    self.webViewController = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
    NSString *query = [[item objectForKey:@"label"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *url = [NSString stringWithFormat:serviceURL, query]; 
	NSURL *_url = [NSURL URLWithString:url];    
    self.webViewController.urlRequest = [NSURLRequest requestWithURL:_url];
    self.webViewController.detailItem = item;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        [self.navigationController pushViewController:self.webViewController animated:YES];
    }
    else{
        CGRect frame=self.webViewController.view.frame;
        frame.size.width=477;
        self.webViewController.view.frame=frame;
        [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:self.webViewController invokeByController:self isStackStartView:FALSE];
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
        topNavigationLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;;
        topNavigationLabel.backgroundColor = [UIColor clearColor];
        topNavigationLabel.font = [UIFont boldSystemFontOfSize:11];
        topNavigationLabel.minimumFontSize=8.0;
        topNavigationLabel.numberOfLines=2;
        topNavigationLabel.adjustsFontSizeToFitWidth = YES;
        topNavigationLabel.textAlignment = UITextAlignmentLeft;
        topNavigationLabel.textColor = [UIColor whiteColor];
        topNavigationLabel.shadowColor = shadowColor;
        topNavigationLabel.shadowOffset    = CGSizeMake (0.0, -1.0);
        topNavigationLabel.highlightedTextColor = [UIColor blackColor];
        topNavigationLabel.opaque=YES;
        topNavigationLabel.text=[self.detailItem mainLabel];
        self.navigationItem.title = [self.detailItem mainLabel];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && [self.detailItem enableSection]){
            UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 244, 44)];
            titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            topNavigationLabel.textAlignment = UITextAlignmentRight;
            topNavigationLabel.font = [UIFont boldSystemFontOfSize:14];
            [titleView addSubview:topNavigationLabel];
            titleView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
            [titleView setFrame:CGRectMake(320, 373, -16, 40)];
            [self.view addSubview:titleView];
        }
        if (![self.detailItem disableNowPlaying]){
            UIImage* nowPlayingImg = [UIImage imageNamed:@"button_now_playing_empty.png"];
            CGRect frameimg = CGRectMake(0, 0, nowPlayingImg.size.width, nowPlayingImg.size.height);
            UIButton *nowPlayingButton = [[UIButton alloc] initWithFrame:frameimg];
            [nowPlayingButton setBackgroundImage:nowPlayingImg forState:UIControlStateNormal];
            [nowPlayingButton addTarget:self action:@selector(showNowPlaying) forControlEvents:UIControlEventTouchUpInside];
            UIBarButtonItem *nowPlayingButtonItem =[[UIBarButtonItem alloc] initWithCustomView:nowPlayingButton];
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
                                    nil], @"parameters", [parameters objectForKey:@"label"], @"label", @"nocover_filemode.png", @"defaultThumb", filemodeRowHeight, @"rowHeight", filemodeThumbWidth, @"thumbWidth",
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
        DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem.subItem withFrame:CGRectMake(0, 0, 477, self.view.frame.size.height) bundle:nil];
        [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
    }
}

-(void)addStream:(NSDictionary *)item indexPath:(NSIndexPath *)indexPath{
    id cell;
    if (enableCollectionView){
        cell = [collectionView cellForItemAtIndexPath:indexPath];
    }
    else{
        cell = [dataList cellForRowAtIndexPath:indexPath];
    }
    UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
    [queuing startAnimating];
//    NSDictionary *item = nil;
//    if ([self.searchDisplayController isActive]){
//        item = [self.filteredListContent objectAtIndex:indexPath.row];
//    }
//    else{
//        item = [[self.sections valueForKey:[self.sectionArray objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
//    }
    [jsonRPC callMethod:@"Files.PrepareDownload" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[item objectForKey:@"file"], @"path", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                GlobalData *obj=[GlobalData getInstance];
                //NSDictionary *itemid = [methodResult objectForKey:@"details"]; 
               // ;
                NSString *serverURL=[NSString stringWithFormat:@"%@:%@", obj.serverIP, obj.serverPort];
                NSString *stringURL = [NSString stringWithFormat:@"%@://%@/%@",(NSArray*)[methodResult objectForKey:@"protocol"], serverURL, [(NSDictionary*)[methodResult objectForKey:@"details"] objectForKey:@"path"]];                
               // NSLog(@"RESULT %@", stringURL);
                NSURLRequest *request = [[NSURLRequest alloc] initWithURL: [NSURL URLWithString: stringURL] cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 10];  
                CGRect frame=webPlayView.frame;
                CGRect targetFrame;
                if (enableCollectionView){
                    UICollectionViewCell *tmp_cell = (UICollectionViewCell *)cell;
                    targetFrame = tmp_cell.frame;
                }
                else{
                    UITableViewCell *tmp_cell = (UITableViewCell *)cell;
                    targetFrame = tmp_cell.frame;
                }
                frame.origin.y=targetFrame.origin.y;
                webPlayView.frame=frame;   
                //NSLog(@"%d", webPlayView.loading);
                [webPlayView loadRequest:request];  
                
//                playerViewController =[[MPMoviePlayerController alloc] initWithContentURL: [NSURL URLWithString: stringURL]];
//                [playerViewController prepareToPlay];
//                [playerViewController.view setFrame: self.view.bounds];  // player's frame must match parent's
//                [self.view addSubview: playerViewController.view];
//                [playerViewController play];
                
                //MPMoviePlayerController *playerViewController;
//                NSURL *movieURL = [NSURL URLWithString:stringURL];
//                playerViewController = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
////                playerViewController.controlStyle = MPMovieControlStyleFullscreen;
//                playerViewController.shouldAutoplay = YES;
                
//                [[playerViewController view] setFrame: self.view.bounds]; // 2X the native resolution
//                [self.view addSubview: [playerViewController view]];
//                [playerViewController play];
                
//                NSString *medialink = @"http://someWebAddress.mp3";
//                self.player = [[[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:medialink]] autorelease];
//                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerDidFinish:) name:@"MPMoviePlayerPlaybackDidFinishNotification" object:self.player];
//                [self.player play];
                
                [queuing stopAnimating];
            }
        }
        else {
//            NSLog(@"ci deve essere un primo problema %@", methodError);
            [queuing stopAnimating];
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
    NSString *key=[mainFields objectForKey:@"row9"];
    if ([[item objectForKey:@"filetype"] isEqualToString:@"directory"]){
        key=@"directory";
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
                                                [NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:[mainFields objectForKey:@"row9"]], key, nil],@"item",
                                                [NSNumber numberWithInt:newPos],@"position",
                                                nil];
                         [jsonRPC callMethod:action2 withParameters:params2 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                             if (error==nil && methodError==nil){
                                 [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil]; 
                             }
                         
                         }];
                     }
                     else{
                         [self addToPlaylist:mainFields currentItem:item currentKey:key currentActivityIndicator:queuing];
                     }
                 }
                 else{
                     [self addToPlaylist:mainFields currentItem:item currentKey:key currentActivityIndicator:queuing];
                 }
             }
             else {
                [self addToPlaylist:mainFields currentItem:item currentKey:key currentActivityIndicator:queuing];
             }
         }];
    }
    else {
        [self addToPlaylist:mainFields currentItem:item currentKey:key currentActivityIndicator:queuing];
    }
}

-(void)addToPlaylist:(NSDictionary *)mainFields currentItem:(NSDictionary *)item currentKey:(NSString *)key currentActivityIndicator:(UIActivityIndicatorView *)queuing{
    [jsonRPC callMethod:@"Playlist.Add" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[mainFields objectForKey:@"playlistid"], @"playlistid", [NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:[mainFields objectForKey:@"row9"]], key, nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
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
        [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
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
    else if ([[mainFields objectForKey:@"row8"] isEqualToString:@"channelid"]){
        [self playerOpen:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:[mainFields objectForKey:@"row8"]], [mainFields objectForKey:@"row8"], nil], @"item", nil] index:indexPath];
//        [jsonRPC callMethod:@"Player.Open" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:[mainFields objectForKey:@"row8"]], [mainFields objectForKey:@"row8"], nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
//            [queuing stopAnimating];
//            if (error==nil && methodError==nil){
//                [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
//                [self showNowPlaying];
//            }
////            else {
//                //                            NSLog(@"terzo errore %@",methodError);
////            }
//        }];
        
    }
    else if ([[mainFields objectForKey:@"row7"] isEqualToString:@"plugin"]){ // TEST
        [self playerOpen:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:@"file"], @"file", nil], @"item", nil] index:indexPath];
    }
    else{
        id optionsParam = nil;
        id optionsValue = nil;
        if ([AppDelegate instance].serverVersion > 11){
            optionsParam = @"options";
            optionsValue = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:shuffled], @"shuffled", nil];
        }
        [jsonRPC callMethod:@"Playlist.Clear" withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [mainFields objectForKey:@"playlistid"], @"playlistid", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            if (error==nil && methodError==nil){
                NSString *key=[mainFields objectForKey:@"row8"];
                if ([[item objectForKey:@"filetype"] isEqualToString:@"directory"]){ 
                    key=@"directory";
                }
                if (shuffled && [AppDelegate instance].serverVersion > 11){
                    [jsonRPC
                     callMethod:@"Player.SetPartymode"
                     withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0], @"playerid", [NSNumber numberWithBool:NO], @"partymode", nil]
                     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *internalError) {
                         [self playlistAndPlay:[NSDictionary dictionaryWithObjectsAndKeys:
                                                [mainFields objectForKey:@"playlistid"], @"playlistid",
                                                [NSDictionary dictionaryWithObjectsAndKeys:
                                                 [item objectForKey:[mainFields objectForKey:@"row8"]], key, nil], @"item",
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
                else{
                    [self playlistAndPlay:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [mainFields objectForKey:@"playlistid"], @"playlistid",
                                           [NSDictionary dictionaryWithObjectsAndKeys:
                                            [item objectForKey:[mainFields objectForKey:@"row8"]], key, nil], @"item",
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
                //            NSLog(@"ERRORE %@", methodError);
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

-(void)SimpleAction:(NSString *)action params:(NSDictionary *)parameters{
    [jsonRPC callMethod:action withParameters:parameters onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
    }];
}

-(void)displayInfoView:(NSDictionary *)item{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        self.showInfoViewController=nil;
        self.showInfoViewController = [[ShowInfoViewController alloc] initWithNibName:@"ShowInfoViewController" bundle:nil];
        self.showInfoViewController.detailItem = item;
        [self.navigationController pushViewController:self.showInfoViewController animated:YES];
    }
    else{
        ShowInfoViewController *iPadShowViewController = [[ShowInfoViewController alloc] initWithNibName:@"ShowInfoViewController" withItem:item withFrame:CGRectMake(0, 0, 477, self.view.frame.size.height) bundle:nil];                
        [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadShowViewController invokeByController:self isStackStartView:FALSE];
    }

}

-(void)preparePlaybackAlbum:(id)sender{
    mainMenu *MenuItem = nil;
    if ([sender tag] == 0){
        MenuItem = [[AppDelegate instance].playlistArtistAlbums copy];
    }
    else if ([sender tag] == 1){
        MenuItem = [[AppDelegate instance].playlistTvShows copy];
    }
    //    choosedTab = 0;
    MenuItem.subItem.mainLabel=self.navigationItem.title;
    [MenuItem.subItem setMainMethod:nil];
    if ([self.richResults count]>0){
        [self.searchDisplayController.searchBar resignFirstResponder];
        [self showInfo:nil menuItem:MenuItem item:[self.richResults objectAtIndex:0] tabToShow:0];
    }
}


-(void)prepareShowAlbumInfo:(id)sender{
    mainMenu *MenuItem = nil;
    if ([sender tag] == 0){
        MenuItem = [[AppDelegate instance].playlistArtistAlbums copy];
    }
    else if ([sender tag] == 1){
        MenuItem = [[AppDelegate instance].playlistTvShows copy];
    }
//    choosedTab = 0;
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
    NSMutableArray *newParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     [parameters objectForKey:@"properties"], @"properties",
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
                 NSString *type=@"";
                 
                 if ([videoLibraryMovieDetail objectForKey:@"filetype"]!=nil){
                     filetype=[videoLibraryMovieDetail objectForKey:@"filetype"];
                     type=[videoLibraryMovieDetail objectForKey:@"type"];;
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
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row6"]], [mainFields objectForKey:@"row6"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row8"]], [mainFields objectForKey:@"row8"],
                  year, @"year",
                  rating, @"rating",
                  [mainFields objectForKey:@"playlistid"], @"playlistid",
                  [mainFields objectForKey:@"row8"], @"family",
                  [NSNumber numberWithInt:[[NSString stringWithFormat:@"%@", [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row9"]]]intValue]], [mainFields objectForKey:@"row9"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row10"]], [mainFields objectForKey:@"row10"],
                  row11, [mainFields objectForKey:@"row11"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row12"]], [mainFields objectForKey:@"row12"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row13"]], [mainFields objectForKey:@"row13"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row14"]], [mainFields objectForKey:@"row14"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row15"]], [mainFields objectForKey:@"row15"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row16"]], [mainFields objectForKey:@"row16"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row17"]], [mainFields objectForKey:@"row17"],
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row18"]], [mainFields objectForKey:@"row18"],
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
    elapsedTime = 0;
    startTime = [NSDate timeIntervalSinceReferenceDate];
    countExecutionTime = [NSTimer scheduledTimerWithTimeInterval:WARNING_TIMEOUT target:self selector:@selector(checkExecutionTime) userInfo:nil repeats:YES];
    debugText.text = [NSString stringWithFormat:@"*METHOD: %@\n*PARAMS: %@", methodToCall, parameters];
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
                 if (((NSNull *)videoLibraryMovies != [NSNull null])){
                     total=[videoLibraryMovies count];
                 }
                 NSString *serverURL= @"";
                 serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                 int secondsToMinute = 1;
                 if ([AppDelegate instance].serverVersion > 11){
                     serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
                     if ([self.detailItem noConvertTime]) secondsToMinute = 60;
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
                     NSString *type=@"";
                     
                     if ([[videoLibraryMovies objectAtIndex:i] objectForKey:@"filetype"]!=nil){
                         filetype=[[videoLibraryMovies objectAtIndex:i] objectForKey:@"filetype"];
                         type=[[videoLibraryMovies objectAtIndex:i] objectForKey:@"type"];;
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
                     
                      NSString *episodeNumber = [NSString stringWithFormat:@"%@", [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row19"]]];
                     
                     [resultStoreArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                  label, @"label",
                                                  genre, @"genre",
                                                  stringURL, @"thumbnail",
                                                  fanartURL, @"fanart",
                                                  runtime, @"runtime",
                                                  seasonNumber, @"season",
                                                  episodeNumber, @"episode",
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
                                                  [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row13"]], [mainFields objectForKey:@"row13"],
                                                  [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row14"]], [mainFields objectForKey:@"row14"],
                                                  [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row15"]], [mainFields objectForKey:@"row15"],
                                                  [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row16"]], [mainFields objectForKey:@"row16"],
                                                  [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row17"]], [mainFields objectForKey:@"row17"],
                                                  [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row18"]], [mainFields objectForKey:@"row18"],
                                                  nil]];
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
//             debugText.text = [NSString stringWithFormat:@"*ERROR: %@\n*METHOD ERROR: %@\n%@\n", error, methodError, debugText.text];
//             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"DEBUG INFO"
//                                                                 message:debugText.text
//                                                                delegate:self
//                                                       cancelButtonTitle:nil
//                                                       otherButtonTitles:@"Copy to clipboard", nil];
//             [alertView show];
//             UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
//             pasteboard.string = debugText.text;
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

-(void)indexAndDisplayData{
    self.sectionArray = nil;
    if ([self.richResults count] == 0){
        albumView = FALSE;
        episodesView = FALSE;
    }
    UISearchBarLeftButton *bar = (UISearchBarLeftButton *)self.searchDisplayController.searchBar;
    bar.rightPadding = 0;
    if ([self.detailItem enableSection] && [self.richResults count]>SECTIONS_START_AT){
        bar.rightPadding = 26;
        [self.sections setValue:[[NSMutableArray alloc] init] forKey:UITableViewIndexSearch];
        BOOL found;
        NSCharacterSet * set = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ"] invertedSet];
        NSCharacterSet * numberset = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
        for (NSDictionary *item in self.richResults){
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
            for (NSString *str in [self.sections allKeys]){
                if ([[str uppercaseString] isEqualToString:c]){
                    found = YES;
                }
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
            for (NSString *str in [self.sections allKeys]){
                if ([[str uppercaseString] isEqualToString:c]){
                    found = YES;
                }
            }
            if (!found){
                [self.sections setValue:[[NSMutableArray alloc] init] forKey:c];
            }
            [[self.sections objectForKey:c] addObject:item];
        }
    }
    else {
        [self.sections setValue:[[NSMutableArray alloc] init] forKey:@""];
        for (NSDictionary *item in self.richResults){
            [[self.sections objectForKey:@""] addObject:item];
        }
    }
    [bar layoutSubviews];
    self.sectionArray = [[NSArray alloc] initWithArray:
                    [[self.sections allKeys] sortedArrayUsingComparator:^(id firstObject, id secondObject) {
        return [self alphaNumericCompare:firstObject secondObject:secondObject];
    }]];
    
    self.sectionArrayOpen = [[NSMutableArray alloc] init];
    BOOL defaultValue = FALSE;
    if ([self.sectionArray count] == 1){
        defaultValue = TRUE;
    }
    for (int i=0; i<[self.sectionArray count]; i++) {
        [self.sectionArrayOpen addObject:[NSNumber numberWithBool:defaultValue]];
    }
    //    NSLog(@"END INDEX");

//    [self saveData:mutableParameters];
    
    [self displayData];
}

-(void)displayData{
    [self configureLibraryView];
//    [activeLayoutView setContentOffset:[(UITableView *)activeLayoutView contentOffset] animated:NO];
    [self choseParams];
    numResults=[self.richResults count];
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    if ([self.detailItem enableSection]){
        // CONDIZIONE DEBOLE!!!
        self.navigationItem.title =[NSString stringWithFormat:@"%@ (%d)", [parameters objectForKey:@"label"], numResults];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
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
    [self setFlowLayoutParams];
    [activityIndicatorView stopAnimating];
    [activeLayoutView reloadData];
    [self AnimTable:(UITableView *)activeLayoutView AnimDuration:0.3 Alpha:1.0 XPos:0];
    [dataList setContentOffset:CGPointMake(0, 44) animated:NO];
    [collectionView layoutSubviews];
    [collectionView setContentOffset:CGPointMake(0, 44) animated:NO];
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
}

-(NSComparisonResult)alphaNumericCompare:(id)firstObject secondObject:(id)secondObject{
    if (episodesView){
        return [((NSString *)firstObject) compare:((NSString *)secondObject) options:NSNumericSearch];
    }
    return [((NSString *)firstObject) localizedCaseInsensitiveCompare:((NSString *)secondObject)];
}

# pragma mark - Life-Cycle

-(void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name:@"ECSLidingSwipeLeft" object:nil];
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:.14 green:.14 blue:.14 alpha:1]];
    self.searchDisplayController.searchBar.tintColor = searchBarColor;
}

-(void)viewWillAppear:(BOOL)animated{
    if (albumColor!=nil){
        [self.navigationController.navigationBar setTintColor:albumColor];
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    if ([[userDefaults objectForKey:@"reveal_preference"] boolValue] == NO ){
        [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    }
    else{
        [self.navigationController.navigationBar addGestureRecognizer:self.slidingViewController.panGesture];
    }
    self.slidingViewController.underRightViewController = nil;
    self.slidingViewController.anchorLeftPeekAmount     = 0;
    self.slidingViewController.anchorLeftRevealAmount   = 0;
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

// TRICK WHEN CHILDREN WAS FORCED TO PORTRAIT
//    UIViewController *c = [[UIViewController alloc]init];
//    [self presentViewController:c animated:NO completion:nil];
//    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void)viewDidAppear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleSwipeFromLeft:)
                                                 name: @"ECSLidingSwipeLeft"
                                               object: nil];
    [self disableScrollsToTopPropertyOnAllSubviewsOf:self.slidingViewController.view];
    [activeLayoutView setScrollsToTop:YES];
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
    int count=[buttons count];
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
            cellMinimumLineSpacing = 2;
        }
        else{
            cellMinimumLineSpacing = 2;
            cellGridWidth = [[itemSizes objectForKey:@"width"] floatValue];
        }
        cellGridHeight =  [[itemSizes objectForKey:@"height"] floatValue];
    }
}

-(void)setIphoneInterface:(NSDictionary *)itemSizes{
    viewWidth=320;
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
    viewWidth = 477;
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
    posterFontSize = 11;
    fanartFontSize = 13;
    [self checkParamSize:itemSizes viewWidth:viewWidth];
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
                arr_properties = [NSArray arrayWithArray:nil];
            }
            
            NSArray *arr_sort = [[parameters objectForKey:@"parameters"] objectForKey:@"sort"];
            if (arr_sort == nil){
                arr_sort = [NSArray arrayWithArray:nil];
            }
            [tempDict setObject:arr_properties forKey:@"properties"];
            [tempDict setObject:arr_sort forKey:@"sort"];
            [tempDict setObject:@"YES" forKey:@"filtered"];
        }
    }
    NSString *viewKey = [NSString stringWithFormat:@"%@_grid_preference", [self getCacheKey:[methods objectForKey:@"method"] parameters:tempDict]];
    return (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0") && ([[parameters objectForKey:@"enableCollectionView"] boolValue] == YES) && ([[userDefaults objectForKey:viewKey] boolValue] == YES));
}

- (void)viewDidLoad{
    [super viewDidLoad];
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
    numTabs=[[self.detailItem mainMethod] count];
    if ([self.detailItem chooseTab])
        choosedTab=[self.detailItem chooseTab];
    if (choosedTab>=numTabs){
        choosedTab=0;
    }
    watchMode = [self.detailItem currentWatchMode];
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[self.detailItem mainMethod] objectAtIndex:choosedTab]];
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    [self checkDiskCache];
    UISearchBarLeftButton *bar = (UISearchBarLeftButton *)self.searchDisplayController.searchBar;
    if ([self collectionViewCanBeEnabled] == YES){
        bar.leftPadding = SEARCH_BAR_LEFT_PADDING;
    }
    searchBarColor = [UIColor colorWithRed:.35 green:.35 blue:.35 alpha:1];
    collectionViewSearchBarColor = [UIColor blackColor];
    if ([[methods objectForKey:@"albumView"] boolValue] == YES){
        albumView = TRUE;
    }
    else if ([[methods objectForKey:@"episodesView"] boolValue] == YES){
        episodesView = TRUE;
        searchBarColor = [UIColor colorWithRed:.95 green:.95 blue:.95 alpha:1];
    }
    else if ([[methods objectForKey:@"tvshowsView"] boolValue] == YES){
        tvshowsView = [AppDelegate instance].serverVersion > 11 && [AppDelegate instance].obj.preferTVPosters == NO;
    }
    tableViewSearchBarColor = searchBarColor;
    if ([[parameters objectForKey:@"blackTableSeparator"] boolValue] == YES && [AppDelegate instance].obj.preferTVPosters == NO){
        blackTableSeparator = YES;
        dataList.separatorColor = [UIColor colorWithRed:.15 green:.15 blue:.15 alpha:1];
        self.searchDisplayController.searchResultsTableView.separatorColor = [UIColor colorWithRed:.15 green:.15 blue:.15 alpha:1];
    }
    self.searchDisplayController.searchBar.tintColor = searchBarColor;
    [detailView setClipsToBounds:YES];
    trackCountLabelWidth = 26;
    NSDictionary *itemSizes = [parameters objectForKey:@"itemSizes"];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        [self setIphoneInterface:[itemSizes objectForKey:@"iphone"]];
    }
    else {
        [self setIpadInterface:[itemSizes objectForKey:@"ipad"]];
    }
    CGRect frame=dataList.frame;
    frame.origin.x = viewWidth;
    dataList.frame=frame;
    activeLayoutView = dataList;
    currentCollectionViewName = NSLocalizedString(@"View: Wall", nil);
    if ([[parameters objectForKey:@"collectionViewRecentlyAdded"] boolValue] == YES){
        recentlyAddedView = TRUE;
        currentCollectionViewName = NSLocalizedString(@"View: Fanart", nil);
    }
    else{
        recentlyAddedView = FALSE;
    }
    enableCollectionView = [self collectionViewIsEnabled];
    if (enableCollectionView) {
        [self initCollectionView];
    }
//    [((UITableView *)activeLayoutView).pullToRefreshView
//     setSubtitle:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Last sync", nil),NSLocalizedString(@"never", nil)]
//     forState:SVPullToRefreshStateStopped];
    GlobalData *obj=[GlobalData getInstance];
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    
    self.sections = [[NSMutableDictionary alloc] init];
    self.richResults= [[NSMutableArray alloc] init ];
    self.filteredListContent = [[NSMutableArray alloc] init ];
    storeRichResults = [[NSMutableArray alloc] init ];
    self.extraSectionRichResults = [[NSMutableArray alloc] init ];
    
    [activityIndicatorView startAnimating];
        
    [self startRetrieveDataWithRefresh:NO];
    
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
                             [activeLayoutView setContentOffset:CGPointMake(0, 44) animated:NO];
                         }];
    }
}

- (void)viewDidUnload{
//    debugText = nil;
    [super viewDidUnload];
    jsonRPC=nil;
    self.richResults=nil;
    self.filteredListContent=nil;
    self.sections=nil;
    dataList=nil;
    collectionView = nil;
    jsonCell=nil;
    activityIndicatorView=nil;  
//    manager=nil;
    nowPlaying=nil;
    playFileViewController=nil;
    [[NSNotificationCenter defaultCenter] removeObserver: self];
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
    jsonRPC=nil;
    [self.richResults removeAllObjects];
    [self.filteredListContent removeAllObjects];
    self.richResults=nil;
    self.filteredListContent=nil;
    [self.sections removeAllObjects];
    self.sections=nil;
    self.sectionArray = nil;
    self.sectionArrayOpen = nil;
    self.extraSectionRichResults = nil;
    dataList=nil;
    collectionView = nil;
    jsonCell=nil;
    activityIndicatorView=nil;  
//    manager=nil;
    nowPlaying=nil;
    playFileViewController=nil;
    self.nowPlaying = nil;
    self.webViewController=nil;
    self.showInfoViewController=nil;
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

-(NSUInteger)supportedInterfaceOrientations{
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
