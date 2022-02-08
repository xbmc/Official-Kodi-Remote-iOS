//
//  ShowInfoViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "ShowInfoViewController.h"
#import "mainMenu.h"
#import "NowPlaying.h"
#import "GlobalData.h"
#import "SDImageCache.h"
#import "UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "DetailViewController.h"
#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"
#import "ActorCell.h"
#import "Utilities.h"

#define PLAY_BUTTON_SIZE 20
#define TV_LOGO_SIZE_REC_DETAILS 72
#define TITLE_HEIGHT 44
#define LEFT_RIGHT_PADDING 10
#define VERTICAL_PADDING 10
#define REC_DOT_SIZE 10
#define REC_DOT_PADDING 4
#define ARROW_ALPHA 0.5

@interface ShowInfoViewController ()
@end

@implementation ShowInfoViewController

@synthesize detailItem = _detailItem;
@synthesize kenView;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (id)initWithNibName:(NSString*)nibNameOrNil withItem:(NSDictionary*)item withFrame:(CGRect)frame bundle:(NSBundle*)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.detailItem = item;
        self.view.frame = frame;
    }
    return self;
}

double round(double d) {
    return floor(d + 0.5);
}

- (void)configureView {
    if (self.detailItem) {
        NSMutableDictionary *item = self.detailItem;
        sheetActions = [@[LOCALIZED_STR(@"Queue after current"),
                          LOCALIZED_STR(@"Queue"),
                          LOCALIZED_STR(@"Play")
                        ] mutableCopy];
        NSDictionary *resumePointDict = item[@"resume"];
        if (resumePointDict != nil) {
            if (((NSNull*)resumePointDict[@"position"] != [NSNull null])) {
                if ([resumePointDict[@"position"] floatValue] > 0) {
                    resumePointPercentage = ([resumePointDict[@"position"] floatValue] * 100) / [resumePointDict[@"total"] floatValue];
                    [sheetActions addObject:[NSString stringWithFormat:LOCALIZED_STR(@"Resume from %@"), [Utilities convertTimeFromSeconds: @([resumePointDict[@"position"] floatValue])]]];
                }
            }
        }
        BOOL fromAlbumView = NO;
        if (((NSNull*)item[@"fromAlbumView"] != [NSNull null])) {
            fromAlbumView = [item[@"fromAlbumView"] boolValue];
        }
        BOOL fromEpisodesView = NO;
        if (((NSNull*)item[@"fromEpisodesView"] != [NSNull null])) {
            fromEpisodesView = [item[@"fromEpisodesView"] boolValue];
        }
        UIBarButtonItem *extraButton = nil;
        if ([item[@"family"] isEqualToString:@"albumid"]) {
            UIImage* extraButtonImg = [UIImage imageNamed:@"st_songs"];
            if (fromAlbumView) {
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
            }
            else {
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(showContent:)];
            }
        }
        else if ([item[@"family"] isEqualToString:@"artistid"]) {
            UIImage* extraButtonImg = [UIImage imageNamed:@"st_album"];
            extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(showContent:)];
        }
        else if ([item[@"family"] isEqualToString:@"tvshowid"]) {
            UIImage* extraButtonImg = [UIImage imageNamed:@"st_tv"];
            if (fromEpisodesView) {
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
            }
            else {
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(showContent:)];
            }
        }
        else if ([item[@"family"] isEqualToString:@"broadcastid"]) {
            NSString *pvrAction = [item[@"hastimer"] boolValue] ? LOCALIZED_STR(@"Stop Recording") : LOCALIZED_STR(@"Record");
            sheetActions = [@[LOCALIZED_STR(@"Play"), pvrAction] mutableCopy];
        }
        if ([item[@"trailer"] isKindOfClass:[NSString class]]) {
            if ([item[@"trailer"] length] > 0) {
                [sheetActions addObject:LOCALIZED_STR(@"Play Trailer")];
            }
        }
        if (IS_IPAD) {
            toolbar = [UIToolbar new];
            toolbar.barStyle = UIBarStyleBlack;
            toolbar.translucent = YES;
            UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            actionSheetButtonItemIpad = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(showActionSheet)];
            actionSheetButtonItemIpad.style = UIBarButtonItemStylePlain;
            viewTitle = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, STACKSCROLL_WIDTH, TITLE_HEIGHT)];
            viewTitle.backgroundColor = UIColor.clearColor;
            viewTitle.textAlignment = NSTextAlignmentLeft;
            viewTitle.textColor = UIColor.whiteColor;
            viewTitle.text = item[@"label"];
            viewTitle.numberOfLines = 1;
            viewTitle.font = [UIFont boldSystemFontOfSize:22];
            viewTitle.minimumScaleFactor = 12.0 / 22.0;
            viewTitle.adjustsFontSizeToFitWidth = YES;
            viewTitle.shadowOffset = CGSizeMake(1, 1);
            viewTitle.shadowColor = [Utilities getGrayColor:0 alpha:0.7];
            viewTitle.autoresizingMask = UIViewAutoresizingNone;
            viewTitle.contentMode = UIViewContentModeScaleAspectFill;
            [viewTitle sizeThatFits: CGSizeMake(STACKSCROLL_WIDTH, TITLE_HEIGHT)];
            UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithCustomView:viewTitle];
            if (extraButton == nil) {
                extraButton = spacer;
            }
            NSArray *items = [NSArray arrayWithObjects: 
                              title,
                              spacer,
                              extraButton,
                              actionSheetButtonItemIpad,
                              nil];
            toolbar.items = items;
            toolbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
            toolbar.contentMode = UIViewContentModeScaleAspectFill;
            [toolbar sizeToFit];
            CGFloat toolbarHeight = toolbar.frame.size.height;
            CGRect mainViewBounds = self.view.bounds;
            toolbar.frame = CGRectMake(CGRectGetMinX(mainViewBounds),
                                       CGRectGetMinY(mainViewBounds),
                                       CGRectGetWidth(mainViewBounds),
                                       toolbarHeight);
            [self.view addSubview:toolbar];
            scrollView.contentInset = UIEdgeInsetsMake(toolbarHeight, 0, 0, 0);
        }
        else {
            self.navigationItem.title = item[@"label"];
            UIBarButtonItem *actionSheetButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(showActionSheet)];
            if (extraButton == nil) {
                self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:
                                                           actionSheetButtonItem,
                                                           nil];
            }
            else {
                self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:
                                                           actionSheetButtonItem,
                                                           extraButton,
                                                           nil];
            }
            UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromRight:)];
            rightSwipe.numberOfTouchesRequired = 1;
            rightSwipe.cancelsTouchesInView = NO;
            rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
            [self.view addGestureRecognizer:rightSwipe];
        }
        // Place the up and down arrows
        CGFloat bottomPadding = [Utilities getBottomPadding];
        CGRect frame = arrow_continue_down.frame;
        frame.origin.y -= bottomPadding;
        arrow_continue_down.frame = frame;
        arrow_continue_down.alpha = ARROW_ALPHA;
        frame = arrow_back_up.frame;
        frame.origin.y += scrollView.contentInset.top;
        arrow_back_up.frame = frame;
        arrow_back_up.alpha = ARROW_ALPHA;
    }
    if (![self.detailItem[@"disableNowPlaying"] boolValue]) {
        UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromLeft:)];
        leftSwipe.numberOfTouchesRequired = 1;
        leftSwipe.cancelsTouchesInView = NO;
        leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.view addGestureRecognizer:leftSwipe];
    }
}

#pragma mark - Utility

- (void)dismissModal:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)isModal {
    return self.presentingViewController.presentedViewController == self
    || (self.navigationController != nil && self.navigationController.presentingViewController.presentedViewController == self.navigationController)
    || [self.tabBarController.presentingViewController isKindOfClass:[UITabBarController class]];
}

- (void)goBack:(id)sender {
    if (IS_IPHONE) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationEnableStackPan" object: nil];
    }
}

#pragma mark - ToolBar button

- (void)showContent:(id)sender {
    NSDictionary *item = self.detailItem;
    mainMenu *menuItem = nil;
    mainMenu *choosedMenuItem = nil;
    choosedTab = 0;
    id movieObj = nil;
    id movieObjKey = nil;
    NSString *blackTableSeparator = @"NO";
    if ([item[@"family"] isEqualToString:@"albumid"]) {
        notificationName = @"MainMenuDeselectSection";
        menuItem = [AppDelegate.instance.playlistArtistAlbums copy];
        choosedMenuItem = menuItem.subItem;
        choosedMenuItem.mainLabel = [NSString stringWithFormat:@"%@", item[@"label"]];
    }
    else if ([item[@"family"] isEqualToString:@"tvshowid"] && ![sender isKindOfClass:[NSString class]]) {
        notificationName = @"MainMenuDeselectSection";
        menuItem = [AppDelegate.instance.playlistTvShows copy];
        choosedMenuItem = menuItem.subItem;
        choosedMenuItem.mainLabel = [NSString stringWithFormat:@"%@", item[@"label"]];
    }
    else if ([item[@"family"] isEqualToString:@"artistid"]) {
        notificationName = @"MainMenuDeselectSection";
        choosedTab = 1;
        menuItem = [AppDelegate.instance.playlistArtistAlbums copy];
        choosedMenuItem = menuItem.subItem;
        choosedMenuItem.mainLabel = [NSString stringWithFormat:@"%@", item[@"label"]];
    }
    else if ([item[@"family"] isEqualToString:@"movieid"] && AppDelegate.instance.serverVersion > 11) {
        if ([sender isKindOfClass:[NSString class]]) {
            NSString *actorName = (NSString*)sender;
            choosedTab = 2;
            menuItem = [AppDelegate.instance.playlistMovies copy];
            movieObj = [NSDictionary dictionaryWithObjectsAndKeys:actorName, @"actor", nil];
            movieObjKey = @"filter";
            choosedMenuItem = menuItem.subItem;
            choosedMenuItem.mainLabel = actorName;
        }
    }
    else if (([item[@"family"] isEqualToString:@"episodeid"] || [item[@"family"] isEqualToString:@"tvshowid"]) && AppDelegate.instance.serverVersion > 11) {
        if ([sender isKindOfClass:[NSString class]]) {
            NSString *actorName = (NSString*)sender;
            choosedTab = 0;
            menuItem = [AppDelegate.instance.playlistTvShows copy];
            movieObj = [NSDictionary dictionaryWithObjectsAndKeys:actorName, @"actor", nil];
            movieObjKey = @"filter";
            choosedMenuItem = menuItem;
            choosedMenuItem.mainLabel = actorName;
            menuItem.enableSection = NO;
            menuItem.mainButtons = nil;
            if ([Utilities getPreferTvPosterMode]) {
                thumbWidth = PHONE_TV_SHOWS_POSTER_WIDTH;
                tvshowHeight = PHONE_TV_SHOWS_POSTER_HEIGHT;
            }
            menuItem.thumbWidth = thumbWidth;
            menuItem.rowHeight = tvshowHeight;
            blackTableSeparator = @"YES";
        }
    }
    else {
        return;
    }
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[choosedMenuItem mainMethod][choosedTab]];
    if (methods[@"method"] != nil) { // THERE IS A CHILD
        NSDictionary *mainFields = [menuItem mainFields][choosedTab];
        NSMutableDictionary *parameters = [Utilities indexKeyedMutableDictionaryFromArray:[choosedMenuItem mainParameters][choosedTab]];
        id obj = @([item[mainFields[@"row6"]] intValue]);
        id objKey = mainFields[@"row6"];
        if (movieObj != nil && movieObjKey != nil) {
            obj = movieObj;
            objKey = movieObjKey;
        }
        else if (AppDelegate.instance.serverVersion > 11 && ![parameters[@"disableFilterParameter"] boolValue]) {
            obj = [NSDictionary dictionaryWithObjectsAndKeys: @([item[mainFields[@"row6"]] intValue]), mainFields[@"row6"], nil];
            objKey = @"filter";
        }
        NSMutableDictionary *newSectionParameters = nil;
        if (parameters[@"extra_section_parameters"] != nil) {
            newSectionParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    obj, objKey,
                                    parameters[@"extra_section_parameters"][@"properties"], @"properties",
                                    parameters[@"extra_section_parameters"][@"sort"], @"sort",
                                    item[mainFields[@"row6"]], mainFields[@"row6"],
                                    nil];
        }
        NSMutableArray *newParameters = [NSMutableArray arrayWithObjects:
                                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        obj, objKey,
                                        parameters[@"parameters"][@"properties"], @"properties",
                                        parameters[@"parameters"][@"sort"], @"sort",
                                        nil], @"parameters",
                                       blackTableSeparator, @"blackTableSeparator",
                                       parameters[@"label"], @"label",
                                       @(YES), @"fromShowInfo",
                                       [NSString stringWithFormat:@"%d", [parameters[@"enableCollectionView"] boolValue]], @"enableCollectionView",
                                       [NSDictionary dictionaryWithDictionary:parameters[@"itemSizes"]], @"itemSizes",
                                       parameters[@"extra_info_parameters"], @"extra_info_parameters",
                                       [NSString stringWithFormat:@"%d", [parameters[@"FrodoExtraArt"] boolValue]], @"FrodoExtraArt",
                                       [NSString stringWithFormat:@"%d", [parameters[@"enableLibraryCache"] boolValue]], @"enableLibraryCache",
                                       [NSString stringWithFormat:@"%d", [parameters[@"collectionViewRecentlyAdded"] boolValue]], @"collectionViewRecentlyAdded",
                                       newSectionParameters, @"extra_section_parameters",
                                       nil];
        [[choosedMenuItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
        choosedMenuItem.chooseTab = choosedTab;
        if (![item[@"disableNowPlaying"] boolValue]) {
            choosedMenuItem.disableNowPlaying = NO;
        }
        if (IS_IPHONE) {
            DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
            detailViewController.detailItem = choosedMenuItem;
            [self.navigationController pushViewController:detailViewController animated:YES];
        }
        else {
            if (![self isModal]) {
                DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:choosedMenuItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:NO];
                [AppDelegate.instance.windowController.stackScrollViewController enablePanGestureRecognizer];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object: nil];
            }
            else {
                DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:choosedMenuItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                iPadDetailViewController.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:iPadDetailViewController animated:YES completion:nil];
            }
        }
    }
}

- (void)callbrowser:(id)sender {
    [Utilities SFloadURL:embedVideoURL fromctrl:self];
}

#pragma mark - ActionSheet

- (void)showActionSheet {
    NSInteger numActions = sheetActions.count;
    if (numActions) {
        NSDictionary *item = self.detailItem;
        NSString *sheetTitle = item[@"label"];
        if ([item[@"family"] isEqualToString:@"broadcastid"]) {
            sheetTitle = item[@"pvrExtraInfo"][@"channel_name"];
        }
        
        UIAlertController *actionView = [UIAlertController alertControllerWithTitle:sheetTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction* action_cancel = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];
        
        for (int i = 0; i < numActions; i++) {
            NSString *actiontitle = sheetActions[i];
            UIAlertAction* action = [UIAlertAction actionWithTitle:actiontitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                [self actionSheetHandler:actiontitle];
            }];
            [actionView addAction:action];
        }
        [actionView addAction:action_cancel];
        actionView.modalPresentationStyle = UIModalPresentationPopover;
        
        UIPopoverPresentationController *popPresenter = [actionView popoverPresentationController];
        if (popPresenter != nil) {
            popPresenter.sourceView = self.view;
            if (IS_IPAD) {
                popPresenter.barButtonItem = actionSheetButtonItemIpad;
            }
        }
        [self presentViewController:actionView animated:YES completion:nil];
    }
}

- (void)actionSheetHandler:(NSString*)actiontitle {
    if ([actiontitle isEqualToString:LOCALIZED_STR(@"Queue after current")]) {
        [self addQueueAfterCurrent:YES];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Queue")]) {
        [self addQueueAfterCurrent:NO];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Play")]) {
        [self addPlayback:0.0];
    }
    else if (([actiontitle isEqualToString:LOCALIZED_STR(@"Record")] ||
              [actiontitle isEqualToString:LOCALIZED_STR(@"Stop Recording")])) {
        [self recordChannel];
    }
    else if ([actiontitle rangeOfString:LOCALIZED_STR(@"Resume from")].location != NSNotFound) {
        [self addPlayback:resumePointPercentage];
        return;
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Play Trailer")]) {
        [self openFile:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: self.detailItem[@"trailer"], @"file", nil], @"item", nil]];
    }
}

- (void)animateRecordAction {
    [UIView animateWithDuration: 0.2
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations: ^{
                         CGRect frame;
                         frame = voteLabel.frame;
                         if (isRecording.alpha == 0.0) {
                             isRecording.alpha = 1.0;
                             frame.origin.x += REC_DOT_SIZE + REC_DOT_PADDING;
                             frame.size.width -= REC_DOT_SIZE + REC_DOT_PADDING;
                             voteLabel.frame = frame;
                         }
                         else {
                             isRecording.alpha = 0.0;
                             frame.origin.x -= REC_DOT_SIZE + REC_DOT_PADDING;
                             frame.size.width += REC_DOT_SIZE + REC_DOT_PADDING;
                             voteLabel.frame = frame;
                         }
                     }
                     completion: ^(BOOL finished) {
                     }];
}

- (void)recordChannel {
    NSNumber *channelid = @([self.detailItem[@"pvrExtraInfo"][@"channelid"] intValue]);
    if ([channelid isEqualToValue:@(0)]) {
        return;
    }
    NSString *methodToCall = @"PVR.Record";
    NSString *parameterName = @"channel";
    NSNumber *itemid = @([self.detailItem[@"channelid"] intValue]);
    NSNumber *storeChannelid = itemid;
    NSNumber *storeBroadcastid = @([self.detailItem[@"broadcastid"] intValue]);
    if ([itemid isEqualToValue:@(0)]) {
        itemid = @([self.detailItem[@"pvrExtraInfo"][@"channelid"] intValue]);
        if ([itemid isEqualToValue:@(0)]) {
            return;
        }
        storeChannelid = itemid;
        NSDate *starttime = [xbmcDateFormatter dateFromString:self.detailItem[@"starttime"]];
        NSDate *endtime = [xbmcDateFormatter dateFromString:self.detailItem[@"endtime"]];
        float total_seconds = [endtime timeIntervalSince1970] - [starttime timeIntervalSince1970];
        float elapsed_seconds = [[NSDate date] timeIntervalSince1970] - [starttime timeIntervalSince1970];
        float percent_elapsed = (elapsed_seconds/total_seconds) * 100.0f;
        if (percent_elapsed < 0) {
            itemid = @([self.detailItem[@"broadcastid"] intValue]);
            storeBroadcastid = itemid;
            storeChannelid = @(0);
            methodToCall = @"PVR.ToggleTimer";
            parameterName = @"broadcastid";
        }
    }
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [activityIndicatorView startAnimating];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                itemid, parameterName,
                                nil];
    [[Utilities getJsonRPC] callMethod:methodToCall
         withParameters:parameters
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               [activityIndicatorView stopAnimating];
               self.navigationItem.rightBarButtonItem.enabled = YES;
               if (error == nil && methodError == nil) {
                   [self animateRecordAction];
                   NSNumber *status = @(![self.detailItem[@"isrecording"] boolValue]);
                   if ([self.detailItem[@"broadcastid"] intValue] > 0) {
                       status = @(![self.detailItem[@"hastimer"] boolValue]);
                   }
                   NSDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           storeChannelid, @"channelid",
                                           storeBroadcastid, @"broadcastid",
                                           status, @"status",
                                           nil];
                   [[NSNotificationCenter defaultCenter] postNotificationName: @"KodiServerRecordTimerStatusChange" object:nil userInfo:params];
               }
               else {
                   NSString *message = [NSString stringWithFormat:LOCALIZED_STR(@"METHOD\n%@\n\nPARAMETERS\n%@\n"), methodToCall, [[[NSString stringWithFormat:@"%@", parameters] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
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

- (IBAction)scrollUp:(id)sender {
    CGPoint bottomOffset = CGPointMake(0, -scrollView.contentInset.top);
    [scrollView setContentOffset:bottomOffset animated:YES];
}

- (IBAction)scrollDown:(id)sender {
    int height_content = scrollView.contentSize.height;
    int height_bounds = scrollView.bounds.size.height;
    int bottom_scroll = MAX(height_content - height_bounds, 0);
    CGPoint bottomOffset = CGPointMake(0, bottom_scroll);
    [scrollView setContentOffset:bottomOffset animated:YES];
}

- (void)showNowPlaying {
    NowPlaying *nowPlaying = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
    nowPlaying.detailItem = self.detailItem;
    [self.navigationController pushViewController:nowPlaying animated:YES];
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)setTvShowsToolbar {
    if (IS_IPAD) {
        NSInteger count = toolbar.items.count;
        NSMutableArray *newToolbarItems = [toolbar.items mutableCopy];
        [newToolbarItems removeObjectAtIndex:(count - 1)];
        [newToolbarItems removeObjectAtIndex:(count - 2)];
        toolbar.items = newToolbarItems;
    }
    else {
        NSMutableArray *navigationItems = [self.navigationItem.rightBarButtonItems mutableCopy];
        [navigationItems removeObjectAtIndex:0];
        self.navigationItem.rightBarButtonItems = navigationItems;
    }
}

- (BOOL)enableJewelCases {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [[userDefaults objectForKey:@"jewel_preference"] boolValue];
}

- (void)elaborateImage:(UIImage*)image fallbackImage:(UIImage*)fallback {
    dispatch_async(dispatch_get_main_queue(), ^{
        [activityIndicatorView startAnimating];
        [self showImage:image fallbackImage:fallback];
    });
}

- (void)showImage:(UIImage*)image fallbackImage:(UIImage*)fallback {
    [activityIndicatorView stopAnimating];
    jewelView.alpha = 0;
    UIImage *imageToShow = image != nil ? image : fallback;
    if (isPvrDetail) {
        CGRect frame;
        frame.size.width = ceil(TV_LOGO_SIZE_REC_DETAILS * 0.9);
        frame.size.height = ceil(TV_LOGO_SIZE_REC_DETAILS * 0.7);
        frame.origin.x = jewelView.frame.origin.x + (jewelView.frame.size.width - frame.size.width)/2;
        frame.origin.y = jewelView.frame.origin.y + 4;
        jewelView.frame = frame;
        
        // Ensure we draw the rounded edges around TV station logo view
        jewelView.image = imageToShow;
        jewelView = [Utilities applyRoundedEdgesView:jewelView drawBorder:YES];
        
        // Choose correct background color for station logos
        if (image != nil) {
            [Utilities setLogoBackgroundColor:jewelView mode:logoBackgroundMode];
        }
    }
    else {
        // Ensure we draw the rounded edges around thumbnail images
        jewelView.image = [Utilities applyRoundedEdgesImage:imageToShow drawBorder:YES];
    }
    [self alphaImage:jewelView AnimDuration:0.1 Alpha:1.0];
}

- (void)setIOS7barTintColor:(UIColor*)tintColor {
    self.navigationController.navigationBar.tintColor = tintColor;
    toolbar.tintColor = tintColor;
}

- (void)createInfo {
    // NEED TO BE OPTIMIZED. IT WORKS BUT THERE ARE TOO MANY IFS!
    NSMutableDictionary *item = self.detailItem;
    NSString *placeHolderImage = @"coverbox_back";
    isPvrDetail = item[@"recordingid"] != nil || item[@"broadcastid"] != nil;
//    NSLog(@"ITEM %@", item);
    eJewelType jeweltype = jewelTypeUnknown;
    lineSpacing = IS_IPAD ? 2 : 0;
    castFontSize = IS_IPAD ? 16 : 14;
    
    // Cast use dimension of 2:3 as per Kodi specification
    castWidth = IS_IPAD ? 70 : 46;
    castHeight = IS_IPAD ? 105 : 69;
    
    // ClearLogo uses dimension of 80:31 as per Kodi specification
    clearLogoWidth = self.view.frame.size.width - LEFT_RIGHT_PADDING * 2;
    clearLogoHeight = ceil(clearLogoWidth * 31.0 / 80.0);
    
    bool enableJewel = [self enableJewelCases];
    if (!enableJewel) {
        jewelView.image = nil;
        CGRect frame = jewelView.frame;
        frame.origin.x = 0;
        jewelView.frame = frame;
    }
    
    CGFloat transform = [Utilities getTransformX];
    NSString *contributorString = @"cast";
    if (IS_IPAD) {
        thumbWidth = (int)(PAD_TV_SHOWS_BANNER_WIDTH * transform);
        tvshowHeight = (int)(PAD_TV_SHOWS_BANNER_HEIGHT * transform);
        
        CGRect frame = starsView.frame;
        frame.origin.y -= lineSpacing;
        frame.size.height += lineSpacing * 2;
        starsView.frame = frame;
        
        frame = voteLabel.frame;
        frame.origin.y -= lineSpacing;
        voteLabel.frame = frame;
    }
    else {
        thumbWidth = (int)(PHONE_TV_SHOWS_BANNER_WIDTH * transform);
        tvshowHeight = (int)(PHONE_TV_SHOWS_BANNER_HEIGHT * transform);
    }
    
    if ([item[@"family"] isEqualToString:@"tvshowid"]) {
        placeHolderImage = @"coverbox_back_tvshows";
        
        label1.text = LOCALIZED_STR(@"EPISODES");
        label2.text = LOCALIZED_STR(@"FIRST AIRED");
        label3.text = LOCALIZED_STR(@"GENRE");
        label4.text = LOCALIZED_STR(@"STUDIO");
        label5.text = LOCALIZED_STR(@"SUMMARY");
        label6.text = LOCALIZED_STR(@"CAST");
        parentalRatingLabelUp.text = LOCALIZED_STR(@"PARENTAL RATING");
        directorLabel.text = [Utilities getStringFromItem:item[@"episode"]];
        genreLabel.text = [Utilities getDateFromItem:item[@"premiered"] dateStyle:NSDateFormatterLongStyle];
        runtimeLabel.text = [Utilities getStringFromItem:item[@"genre"]];
        studioLabel.text = [Utilities getStringFromItem:item[@"studio"]];
        summaryLabel.text = [Utilities getStringFromItem:item[@"plot"]];
        
        [self setTvShowsToolbar];
        
        if (![Utilities getPreferTvPosterMode] && AppDelegate.instance.serverVersion < 12) {
            placeHolderImage = @"blank";
            jewelView.hidden = YES;
        }
        else if (IS_IPAD) {
            int coverHeight = 560;
            CGRect frame = jewelView.frame;
            frame.size.height = coverHeight;
            jewelView.frame = frame;
        }
        if (enableJewel) {
            jewelView.image = [UIImage imageNamed:@"jewel_dvd.9"];
            jeweltype = jewelTypeDVD;
        }
        coverView.autoresizingMask = UIViewAutoresizingNone;
        coverView.contentMode = UIViewContentModeScaleAspectFill;
    }
    else if ([item[@"family"] isEqualToString:@"episodeid"]) {
        placeHolderImage = @"coverbox_back_tvshows";
        
        label1.text = LOCALIZED_STR(@"TV SHOW");
        label2.text = LOCALIZED_STR(@"FIRST AIRED");
        label3.text = LOCALIZED_STR(@"DIRECTOR");
        label4.text = LOCALIZED_STR(@"WRITER");
        label5.text = LOCALIZED_STR(@"SUMMARY");
        label6.text = LOCALIZED_STR(@"CAST");
        parentalRatingLabelUp.text = LOCALIZED_STR(@"PARENTAL RATING");
        directorLabel.text = [Utilities getStringFromItem:item[@"showtitle"]];
        genreLabel.text = [Utilities getDateFromItem:item[@"firstaired"] dateStyle:NSDateFormatterLongStyle];
        runtimeLabel.text = [Utilities getStringFromItem:item[@"director"]];
        studioLabel.text = [Utilities getStringFromItem:item[@"writer"]];
        summaryLabel.text = [Utilities getStringFromItem:item[@"plot"]];
        
        parentalRatingLabelUp.hidden = YES;
        parentalRatingLabel.hidden = YES;
        jewelView.hidden = NO;
        
        if (enableJewel) {
            jewelView.image = [UIImage imageNamed:@"jewel_tv.9"];
            jeweltype = jewelTypeTV;
        }
        int coverHeight = IS_IPAD ? 280 : 200;
        CGRect frame = jewelView.frame;
        frame.size.height = coverHeight;
        jewelView.frame = frame;
        
        coverView.autoresizingMask = UIViewAutoresizingNone;
        coverView.contentMode = UIViewContentModeScaleAspectFill;
    }
    else if ([item[@"family"] isEqualToString:@"albumid"]) {
        placeHolderImage = @"coverbox_back";
        
        label1.text = LOCALIZED_STR(@"ARTIST");
        label2.text = LOCALIZED_STR(@"YEAR");
        label3.text = LOCALIZED_STR(@"GENRE");
        label4.text = LOCALIZED_STR(@"ALBUM LABEL");
        label5.text = LOCALIZED_STR(@"DESCRIPTION");
        label6.text = @"";
        parentalRatingLabelUp.text = LOCALIZED_STR(@"PARENTAL RATING");
        directorLabel.text = [Utilities getStringFromItem:item[@"artist"]];
        genreLabel.text = [Utilities getStringFromItem:item[@"year"]];
        runtimeLabel.text = [Utilities getStringFromItem:item[@"genre"]];
        studioLabel.text = [Utilities getStringFromItem:item[@"label"]];
        summaryLabel.text = [Utilities getStringFromItem:item[@"description"]];
        
        starsView.hidden = YES;
        voteLabel.hidden = YES;
        numVotesLabel.hidden = YES;
        parentalRatingLabelUp.hidden = YES;
        parentalRatingLabel.hidden = YES;
        jewelView.hidden = NO;
        
        if (enableJewel) {
            jewelView.image = [UIImage imageNamed:@"jewel_cd.9"];
            jeweltype = jewelTypeCD;
        }
        int coverHeight = IS_IPAD ? 380 : 290;
        CGRect frame = jewelView.frame;
        frame.size.height = coverHeight;
        jewelView.frame = frame;
    }
    else if ([item[@"family"] isEqualToString:@"musicvideoid"]) {
        placeHolderImage = @"coverbox_back";
        
        NSString *director = [Utilities getStringFromItem:item[@"director"]];
        NSString *year = [Utilities getYearFromItem:item[@"year"]];
        
        label1.text = LOCALIZED_STR(@"ARTIST");
        label2.text = LOCALIZED_STR(@"GENRE");
        label3.text = [self formatDirectorYearHeading:director year:year];
        label4.text = LOCALIZED_STR(@"STUDIO");
        label5.text = LOCALIZED_STR(@"SUMMARY");
        label6.text = @"";
        parentalRatingLabelUp.text = LOCALIZED_STR(@"PARENTAL RATING");
        directorLabel.text = [Utilities getStringFromItem:item[@"artist"]];
        genreLabel.text = [Utilities getStringFromItem:item[@"genre"]];
        runtimeLabel.text = [self formatDirectorYear:director year:year];
        studioLabel.text = [Utilities getStringFromItem:item[@"studio"]];
        summaryLabel.text = [Utilities getStringFromItem:item[@"plot"]];
        
        if (enableJewel) {
            jewelView.image = [UIImage imageNamed:@"jewel_cd.9"];
            jeweltype = jewelTypeCD;
        }
        int coverHeight = IS_IPAD ? 380 : 290;
        CGRect frame = jewelView.frame;
        frame.size.height = coverHeight;
        jewelView.frame = frame;
    }
    else if ([item[@"family"] isEqualToString:@"artistid"]) {
        placeHolderImage = @"coverbox_back_artists";
        contributorString = @"roles";
        
        label1.text = LOCALIZED_STR(@"GENRE");
        label2.text = LOCALIZED_STR(@"STYLE");
        label3.text = @"";
        label4.text = LOCALIZED_STR(@"BORN / FORMED");
        label5.text = LOCALIZED_STR(@"DESCRIPTION");
        label6.text = LOCALIZED_STR(@"MUSIC ROLES");
        parentalRatingLabelUp.text = LOCALIZED_STR(@"PARENTAL RATING");
        directorLabel.text = [Utilities getStringFromItem:item[@"genre"]];
        genreLabel.text = [Utilities getStringFromItem:item[@"style"]];
        summaryLabel.text = [Utilities getStringFromItem:item[@"description"]];
        NSString *born = [Utilities getStringFromItem:item[@"born"]];
        NSString *formed = [Utilities getStringFromItem:item[@"formed"]];
        studioLabel.text = formed.length ? formed : born;
        
        parentalRatingLabelUp.hidden = YES;
        parentalRatingLabel.hidden = YES;
        runtimeLabel.hidden = YES;
        label3.hidden = YES;
        starsView.hidden = YES;
        voteLabel.hidden = YES;
        numVotesLabel.hidden = YES;
        
        enableJewel = NO;
        jewelView.image = nil;
    }
    else if ([item[@"family"] isEqualToString:@"recordingid"]) {
        placeHolderImage = @"nocover_channels";
        
        // Be aware: "rating" is later used to display the label
        item[@"rating"] = item[@"label"];
        if (item[@"pvrExtraInfo"][@"channel_icon"] != nil) {
            item[@"thumbnail"] = item[@"pvrExtraInfo"][@"channel_icon"];
        }
        item[@"genre"] = [self.detailItem[@"plotoutline"] length] > 0 ? self.detailItem[@"plotoutline"] : item[@"genre"];
        
        label1.text = LOCALIZED_STR(@"TIME");
        label2.text = LOCALIZED_STR(@"DESCRIPTION");
        label3.text = @"";
        label4.text = @"";
        label5.text = LOCALIZED_STR(@"SUMMARY");
        label6.text = @"";
        parentalRatingLabelUp.text = LOCALIZED_STR(@"PARENTAL RATING");
        directorLabel.text = [self formatBroadcastTime:item];
        genreLabel.text = [Utilities getStringFromItem:item[@"genre"]];
        numVotesLabel.text = item[@"channel"];
        summaryLabel.text = [Utilities getStringFromItem:item[@"plot"]];
        
        coverView.hidden = YES;
        starsView.hidden = YES;
        label3.hidden = YES;
        label4.hidden = YES;
        label6.hidden = YES;
        runtimeLabel.hidden = YES;
        studioLabel.hidden = YES;
        arrow_continue_down.alpha = 0;
        arrow_back_up.alpha = 0;
        enableJewel = NO;
        
        [self layoutPvrDetails];
    }
    else if ([item[@"family"] isEqualToString:@"broadcastid"]) {
        placeHolderImage = @"nocover_channels";
        
        // Be aware: "rating" is later used to display the label
        item[@"rating"] = item[@"label"];
        if (item[@"pvrExtraInfo"][@"channel_icon"] != nil) {
            item[@"thumbnail"] = item[@"pvrExtraInfo"][@"channel_icon"];
        }
        
        label1.text = LOCALIZED_STR(@"TIME");
        label2.text = LOCALIZED_STR(@"DESCRIPTION");
        label3.text = @"";
        label4.text = @"";
        label5.text = LOCALIZED_STR(@"SUMMARY");
        label6.text = @"";
        parentalRatingLabelUp.text = LOCALIZED_STR(@"PARENTAL RATING");
        directorLabel.text = [self formatBroadcastTime:item];
        genreLabel.text = [Utilities getStringFromItem:self.detailItem[@"plotoutline"]];
        numVotesLabel.text = item[@"pvrExtraInfo"][@"channel_name"];
        summaryLabel.text = [Utilities getStringFromItem:item[@"genre"]];
        
        coverView.hidden = YES;
        starsView.hidden = YES;
        label3.hidden = YES;
        label4.hidden = YES;
        label6.hidden = YES;
        runtimeLabel.hidden = YES;
        studioLabel.hidden = YES;
        arrow_continue_down.alpha = 0;
        arrow_back_up.alpha = 0;
        enableJewel = NO;
    
        [self layoutPvrDetails];
        [self processRecordingTimerFromItem:item];
    }
    else {
        placeHolderImage = @"coverbox_back_movies";
        
        NSString *director = [Utilities getStringFromItem:item[@"director"]];
        NSString *year = [Utilities getYearFromItem:item[@"year"]];
        
        label1.text = [self formatDirectorYearHeading:director year:year];
        label2.text = LOCALIZED_STR(@"GENRE");
        label3.text = LOCALIZED_STR(@"RUNTIME");
        label4.text = LOCALIZED_STR(@"STUDIO");
        label5.text = LOCALIZED_STR(@"SUMMARY");
        label6.text = LOCALIZED_STR(@"CAST");
        parentalRatingLabelUp.text = LOCALIZED_STR(@"PARENTAL RATING");
        directorLabel.text = [self formatDirectorYear:director year:year];
        genreLabel.text = [Utilities getStringFromItem:item[@"genre"]];
        runtimeLabel.text = [Utilities getStringFromItem:item[@"runtime"]];
        studioLabel.text = [Utilities getStringFromItem:item[@"studio"]];
        summaryLabel.text = [Utilities getStringFromItem:item[@"plot"]];
        
        if (enableJewel) {
            jewelView.image = [UIImage imageNamed:@"jewel_dvd.9"];
            jeweltype = jewelTypeDVD;
        }
        if (IS_IPAD) {
            int coverHeight = 560;
            CGRect frame = jewelView.frame;
            frame.size.height = coverHeight;
            jewelView.frame = frame;
        }
        coverView.autoresizingMask = UIViewAutoresizingNone;
        coverView.contentMode = UIViewContentModeScaleToFill;
    }
    
    [self loadThumbnail:item[@"thumbnail"] placeHolder:placeHolderImage jewelType:jeweltype jewelEnabled:enableJewel];
    
    [self loadFanart:item[@"fanart"]];
    
    voteLabel.text = [Utilities getStringFromItem:item[@"rating"]];
    starsView.image = [UIImage imageNamed:[NSString stringWithFormat:@"stars_%.0f", roundf([item[@"rating"] floatValue])]];
    NSString *numVotes = [Utilities getStringFromItem:item[@"votes"]];
    if (numVotes.length != 0) {
        NSString *numVotesPlus = LOCALIZED_STR(([numVotes isEqualToString:@"1"]) ? @"vote" : @"votes");
        numVotesLabel.text = [NSString stringWithFormat:@"(%@ %@)", numVotes, numVotesPlus];
    }

    parentalRatingLabel.text = [Utilities getStringFromItem:item[@"mpaa"]];
    
    if ([item[@"trailer"] isKindOfClass:[NSString class]]) {
        [self processTrailerFromString:item[@"trailer"]];
    }
    
    if (![item[@"family"] isEqualToString:@"albumid"]) {
        [self processCastFromArray:item[contributorString]];
    }
    
    if (!([item[@"family"] isEqualToString:@"broadcastid"] || [item[@"family"] isEqualToString:@"recordingid"])) {
        [self processClearlogoFromDictionary:item];
    }
    
    // Hide empty labels
    if (voteLabel.text.length == 0) {
        starsView.hidden = YES;
        voteLabel.hidden = YES;
        numVotesLabel.hidden = YES;
    }
    if (directorLabel.text.length == 0) {
        directorLabel.hidden = YES;
        label1.hidden = YES;
    }
    if (genreLabel.text.length == 0) {
        genreLabel.hidden = YES;
        label2.hidden = YES;
    }
    if (runtimeLabel.text.length == 0) {
        runtimeLabel.hidden = YES;
        label3.hidden = YES;
    }
    if (studioLabel.text.length == 0) {
        studioLabel.hidden = YES;
        label4.hidden = YES;
    }
    if (summaryLabel.text.length == 0) {
        summaryLabel.hidden = YES;
        label5.hidden = YES;
    }
    if (parentalRatingLabel.text.length == 0) {
        parentalRatingLabel.hidden = YES;
        parentalRatingLabelUp.hidden = YES;
    }
    if (trailerLabel == nil) {
        playTrailerButton.hidden = YES;
        trailerLabel.hidden = YES;
    }
    if (cast.count == 0) {
        label6.hidden = YES;
    }
    
    // Adapt font sizes
    if (IS_IPAD) {
        // Votes
        voteLabel.font = [UIFont boldSystemFontOfSize:22];
        numVotesLabel.font = [UIFont systemFontOfSize:16];
        
        // Headers
        label1.font = [UIFont systemFontOfSize:13];
        label2.font = [UIFont systemFontOfSize:13];
        label3.font = [UIFont systemFontOfSize:13];
        label4.font = [UIFont systemFontOfSize:13];
        label5.font = [UIFont systemFontOfSize:13];
        label6.font = [UIFont systemFontOfSize:14];
        trailerLabel.font = [UIFont systemFontOfSize:13];
        parentalRatingLabelUp.font = [UIFont systemFontOfSize:13];
        
        // Text fields
        directorLabel.font = [UIFont systemFontOfSize:16];
        genreLabel.font = [UIFont systemFontOfSize:16];
        runtimeLabel.font = [UIFont systemFontOfSize:16];
        studioLabel.font = [UIFont systemFontOfSize:16];
        summaryLabel.font = [UIFont systemFontOfSize:16];
        parentalRatingLabel.font = [UIFont systemFontOfSize:16];
    }
    
    // Layout
    CGFloat offset = CGRectGetMaxY(jewelView.frame);
    offset = [self layoutStars:offset];
    offset = [self layoutLabel:label1 sub:directorLabel offset:offset];
    offset = [self layoutLabel:label2 sub:genreLabel offset:offset];
    offset = [self layoutLabel:label3 sub:runtimeLabel offset:offset];
    offset = [self layoutLabel:label4 sub:studioLabel offset:offset];
    offset = [self layoutLabel:label5 sub:summaryLabel offset:offset];
    offset = [self layoutLabel:parentalRatingLabelUp sub:parentalRatingLabel offset:offset];
    offset = [self layoutTrailer:offset];
    offset = [self layoutCastRoles:offset];
    offset = [self layoutClearLogo:offset];
    if (IS_IPHONE) {
        offset += [Utilities getBottomPadding];
    }
    
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width, offset);
    
    // Check if the arrow needs to be displayed (only if content is > visible area)
    int height_content = scrollView.contentSize.height;
    int height_bounds = scrollView.bounds.size.height;
    int height_navbar = self.navigationController.navigationBar.frame.size.height;
    arrow_continue_down.alpha = (height_content <= height_bounds - height_navbar) ? 0 : ARROW_ALPHA;
    
    // Initially "up" arrow is not shown
    arrow_back_up.alpha = 0;
}

- (void)layoutPvrDetails {
    jewelView.frame = CGRectMake(label1.frame.origin.x,
                                 jewelView.frame.origin.y,
                                 jewelView.frame.size.width / 4,
                                 jewelView.frame.size.height / 8);
    
    voteLabel.frame = CGRectMake(CGRectGetMaxX(jewelView.frame) + LEFT_RIGHT_PADDING,
                                 jewelView.frame.origin.y,
                                 self.view.bounds.size.width - CGRectGetMaxX(jewelView.frame) - LEFT_RIGHT_PADDING * 2,
                                 jewelView.frame.size.height / 2);
    voteLabel.numberOfLines = 2;
    voteLabel.textColor = directorLabel.textColor;
    
    numVotesLabel.frame  = CGRectMake(voteLabel.frame.origin.x,
                                      CGRectGetMaxY(voteLabel.frame) + VERTICAL_PADDING,
                                      voteLabel.frame.size.width,
                                      numVotesLabel.frame.size.height);
    
    jewelView.autoresizingMask = UIViewAutoresizingNone;
    voteLabel.autoresizingMask = UIViewAutoresizingNone;
    numVotesLabel.autoresizingMask = UIViewAutoresizingNone;
}

- (CGFloat)layoutStars:(CGFloat)offset {
    if (!starsView.hidden) {
        CGRect frame = starsView.frame;
        frame.origin.y = offset;
        starsView.frame = frame;
        
        frame = voteLabel.frame;
        frame.origin.y = offset;
        voteLabel.frame = frame;
        
        frame = numVotesLabel.frame;
        frame.origin.y = offset;
        numVotesLabel.frame = frame;
        
        offset = CGRectGetMaxY(starsView.frame);
    }
    else {
        offset += VERTICAL_PADDING * 2;
    }
    return offset;
}

- (CGFloat)layoutLabel:(UILabel*)mainLabel sub:(UILabel*)subLabel offset:(CGFloat)offset {
    if (!mainLabel.hidden) {
        CGRect frame = mainLabel.frame;
        frame.origin.y = offset;
        frame.size.height = [Utilities getHeightOfLabel:mainLabel] + lineSpacing;
        mainLabel.frame = frame;
        offset += frame.size.height;
        
        frame = subLabel.frame;
        frame.origin.y = offset;
        frame.size.height = [Utilities getHeightOfLabel:subLabel] + lineSpacing;
        subLabel.frame = frame;
        offset += frame.size.height + VERTICAL_PADDING;
    }
    return offset;
}

- (CGFloat)layoutTrailer:(CGFloat)offset {
    if (trailerLabel != nil) {
        CGRect frame = trailerLabel.frame;
        frame.origin.y = offset;
        frame.size.height = [Utilities getHeightOfLabel:trailerLabel] + lineSpacing;
        trailerLabel.frame = frame;
        offset += frame.size.height;
        
        frame = playTrailerButton.frame;
        frame.origin.y = offset;
        playTrailerButton.frame = frame;
        offset += frame.size.height + lineSpacing + VERTICAL_PADDING;
    }
    return offset;
}

- (CGFloat)layoutCastRoles:(CGFloat)offset {
    if (cast.count) {
        CGRect frame = label6.frame;
        frame.origin.y = offset;
        frame.size.height = [Utilities getHeightOfLabel:label6] + lineSpacing;
        label6.frame = frame;
        offset += frame.size.height;
        
        frame = actorsTable.frame;
        frame.origin.y = offset;
        actorsTable.frame = frame;
        offset += frame.size.height + VERTICAL_PADDING;
    }
    return offset;
}

- (CGFloat)layoutClearLogo:(CGFloat)offset {
    CGRect frame = clearlogoButton.frame;
    frame.origin.y = offset;
    clearlogoButton.frame = frame;
    offset += frame.size.height;
    return offset;
}

- (NSString*)formatDirectorYearHeading:(NSString*)director year:(NSString*)year {
    NSString *text = @"";
    if (director.length && year.length) {
        text = [NSString stringWithFormat:@"%@ (%@)", LOCALIZED_STR(@"DIRECTED BY"), LOCALIZED_STR(@"YEAR")];
    }
    else if (year.length) {
        text = LOCALIZED_STR(@"YEAR");
    }
    else if (director.length) {
        text = LOCALIZED_STR(@"DIRECTED BY");
    }
    return text;
}

- (NSString*)formatDirectorYear:(NSString*)director year:(NSString*)year {
    NSString *text = @"";
    if (director.length && year.length) {
        text = [NSString stringWithFormat:@"%@ (%@)", director, year];
    }
    else if (year.length) {
        text = year;
    }
    else if (director.length) {
        text = director;
    }
    return text;
}

- (NSString*)formatBroadcastTime:(NSDictionary*)item {
    NSString *broadcastTime = @"";
    NSDate *startTime = [xbmcDateFormatter dateFromString:item[@"starttime"]];
    NSDate *endTime = [xbmcDateFormatter dateFromString:item[@"endtime"]];
    if (startTime != nil && endTime != nil) {
        NSString *startDate = [localStartDateFormatter stringFromDate:startTime];
        NSString *endDate = [localEndDateFormatter stringFromDate:endTime];
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSUInteger unitFlags = NSCalendarUnitMinute;
        NSDateComponents *components = [gregorian components:unitFlags fromDate:startTime toDate:endTime options:0];
        NSInteger minutes = [components minute];
        broadcastTime = [NSString stringWithFormat:@"%@ - %@ (%ld %@)", startDate, endDate, (long)minutes, (long)minutes > 1 ? LOCALIZED_STR(@"Mins.") : LOCALIZED_STR(@"Min")];
    }
    return broadcastTime;
}

- (void)processRecordingTimerFromItem:(NSDictionary*)item {
    CGRect frame = voteLabel.frame;
    frame.origin.y = frame.origin.y + (frame.size.height / 2 - REC_DOT_SIZE / 2);
    frame.size.width = REC_DOT_SIZE;
    frame.size.height = REC_DOT_SIZE;
    isRecording = [[UIImageView alloc] initWithFrame:frame];
    isRecording.image = [UIImage imageNamed:@"button_timer"];
    isRecording.contentMode = UIViewContentModeScaleAspectFill;
    isRecording.alpha = 0.0;
    isRecording.backgroundColor = UIColor.clearColor;
    [scrollView addSubview:isRecording];
    if ([item[@"hastimer"] boolValue]) {
        isRecording.alpha = 1.0;
        frame.origin.x += REC_DOT_SIZE + REC_DOT_PADDING;
        frame.size.width -= REC_DOT_SIZE + REC_DOT_PADDING;
        voteLabel.frame = frame;
    }
}

- (void)processCastFromArray:(NSArray*)array {
    cast = array;
    if (actorsTable == nil) {
        CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, cast.count * (castHeight + VERTICAL_PADDING));
        actorsTable = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    }
    actorsTable.scrollsToTop = NO;
    actorsTable.backgroundColor = UIColor.clearColor;
    actorsTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    actorsTable.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin |
                                   UIViewAutoresizingFlexibleWidth |
                                   UIViewAutoresizingFlexibleRightMargin |
                                   UIViewAutoresizingFlexibleLeftMargin;
    actorsTable.delegate = self;
    actorsTable.dataSource = self;
    [scrollView addSubview:actorsTable];
}

- (void)processTrailerFromString:(NSString*)trailerString {
    embedVideoURL = nil;
    if (trailerString.length > 0) {
        if ([trailerString hasPrefix:@"plugin://plugin.video.youtube"]) {
            NSURL* url = [NSURL URLWithString:trailerString];
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
            NSArray *queryItems = urlComponents.queryItems;
            for (NSURLQueryItem *item in queryItems) {
                if ([item.name isEqualToString:@"videoid"]) {
                    embedVideoURL = [NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@", item.value];
                    break; // We can leave the loop as we found what we were looking for.
                }
            }
        }
        else {
            embedVideoURL = trailerString;
        }
        if (embedVideoURL != nil) {
            CGRect frame = CGRectMake(LEFT_RIGHT_PADDING, 0, clearLogoWidth, label1.frame.size.height);
            trailerLabel = [[UILabel alloc] initWithFrame:frame];
            trailerLabel.text = LOCALIZED_STR(@"TRAILER");
            trailerLabel.textColor = label1.textColor;
            trailerLabel.font = label1.font;
            trailerLabel.shadowColor = label1.shadowColor;
            trailerLabel.shadowOffset = label1.shadowOffset;
            trailerLabel.backgroundColor = UIColor.clearColor;
            [scrollView addSubview:trailerLabel];

            UIImage *playTrailerImg = [UIImage imageNamed:@"button_play"];
            playTrailerButton = [UIButton buttonWithType:UIButtonTypeCustom];
            playTrailerButton.frame = CGRectMake(LEFT_RIGHT_PADDING, 0, PLAY_BUTTON_SIZE, PLAY_BUTTON_SIZE);
            playTrailerButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin |
                                                 UIViewAutoresizingFlexibleRightMargin |
                                                 UIViewAutoresizingFlexibleLeftMargin;
            [playTrailerButton setImage:playTrailerImg forState:UIControlStateNormal];
            [playTrailerButton addTarget:self action:@selector(callbrowser:) forControlEvents:UIControlEventTouchUpInside];
            [scrollView addSubview:playTrailerButton];
        }
    }
}

- (void)processClearlogoFromDictionary:(NSDictionary*)item {
    clearlogoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    clearlogoButton.frame = CGRectMake(LEFT_RIGHT_PADDING, 0, clearLogoWidth, clearLogoHeight);
    clearlogoButton.titleLabel.shadowColor = [Utilities getGrayColor:0 alpha:0.8];
    clearlogoButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
    clearlogoButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [clearlogoButton addTarget:self action:@selector(showBackground:) forControlEvents:UIControlEventTouchUpInside];
    if (IS_IPHONE) {
        clearlogoButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin |
                                           UIViewAutoresizingFlexibleLeftMargin |
                                           UIViewAutoresizingFlexibleRightMargin;
    }
    if ([item[@"clearlogo"] length] != 0) {
        clearLogoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, clearLogoWidth, clearLogoHeight)];
        clearLogoImageView.layer.minificationFilter = kCAFilterTrilinear;
        clearLogoImageView.contentMode = UIViewContentModeScaleAspectFit;
        GlobalData *obj = [GlobalData getInstance];
        NSString *serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
        if (AppDelegate.instance.serverVersion > 11) {
            serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
        }
        NSString *stringURL = [Utilities formatStringURL:item[@"clearlogo"] serverURL:serverURL];
        [clearLogoImageView setImageWithURL:[NSURL URLWithString:stringURL]
                           placeholderImage:[UIImage imageNamed:@"blank"]];
        [clearlogoButton addSubview:clearLogoImageView];
    }
    else {
        [clearlogoButton setTitle:[item[@"showtitle"] length] == 0 ? item[@"label"] : item[@"showtitle"] forState:UIControlStateNormal];
        clearlogoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    }
    [scrollView addSubview:clearlogoButton];
}

- (void)loadThumbnail:(NSString*)thumbnailPath placeHolder:(NSString*)placeHolderImage jewelType:(eJewelType)jewelType jewelEnabled:(BOOL)enableJewel {
    if (thumbnailPath.length > 0) {
        jewelView.alpha = 0;
        [activityIndicatorView startAnimating];
    }
    [[SDImageCache sharedImageCache] queryDiskCacheForKey:thumbnailPath done:^(UIImage *image, SDImageCacheType cacheType) {
        if (image != nil) {
            foundTintColor = [Utilities lighterColorForColor:[Utilities averageColor:image inverse:NO]];
            [self setIOS7barTintColor:foundTintColor];
            if (enableJewel) {
                coverView.image = image;
                coverView.frame = [Utilities createCoverInsideJewel:jewelView jewelType:jewelType];
                [activityIndicatorView stopAnimating];
                jewelView.alpha = 1;
            }
            else {
                [self elaborateImage:image fallbackImage:[UIImage imageNamed:placeHolderImage]];
            }
        }
        else {
            __weak ShowInfoViewController *sf = self;
            __block UIColor *newColor = nil;
            if (enableJewel) {
                [coverView setImageWithURL:[NSURL URLWithString:thumbnailPath]
                          placeholderImage:[UIImage imageNamed:placeHolderImage]
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                    if (image != nil) {
                                        newColor = [Utilities lighterColorForColor:[Utilities averageColor:image inverse:NO]];
                                        [sf setIOS7barTintColor:newColor];
                                        foundTintColor = newColor;
                                    }
                }];
                coverView.frame = [Utilities createCoverInsideJewel:jewelView jewelType:jewelType];
                [activityIndicatorView stopAnimating];
                jewelView.alpha = 1;
            }
            else {
                [jewelView setImageWithURL:[NSURL URLWithString:thumbnailPath]
                          placeholderImage:[UIImage imageNamed:placeHolderImage]
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                    if (image != nil) {
                                        newColor = [Utilities lighterColorForColor:[Utilities averageColor:image inverse:NO]];
                                        [sf setIOS7barTintColor:newColor];
                                        foundTintColor = newColor;
                                    }
                                    [sf elaborateImage:image fallbackImage:[UIImage imageNamed:placeHolderImage]];
                }];
            }
        }
    }];
}

- (void)loadFanart:(NSString*)fanartPath {
    __weak ShowInfoViewController *sf = self;
    [[SDImageCache sharedImageCache] queryDiskCacheForKey:fanartPath done:^(UIImage *image, SDImageCacheType cacheType) {
        __auto_type strongSelf = sf;
        if (image != nil) {
            fanartView.image = image;
            if (strongSelf != nil && strongSelf->enableKenBurns) {
                fanartView.alpha = 0;
                [sf elabKenBurns:image];
                [sf alphaView:sf.kenView AnimDuration:1.5 Alpha:0.2];
            }
        }
        else {
            [fanartView setImageWithURL:[NSURL URLWithString:fanartPath]
                       placeholderImage:[UIImage imageNamed:@"blank"]
                              completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                  __auto_type strongSelf = sf;
                                  if (strongSelf != nil && strongSelf->enableKenBurns) {
                                      [sf elabKenBurns:image];
                                      [sf alphaView:sf.kenView AnimDuration:1.5 Alpha:0.2];
                                  }
                              }
             ];
        }
    }];
    fanartView.clipsToBounds = YES;
}

- (CGRect)currentScreenBoundsDependOnOrientation {
    return UIScreen.mainScreen.bounds;
}

- (void)showBackground:(id)sender {
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    NSInteger foundTag = 0;
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        foundTag = [sender view].tag;
    }
    else {
        foundTag = [sender tag];
    }
    if (foundTag == 1) {
        [self alphaView:closeButton AnimDuration:1.5 Alpha:0];
        [self alphaView:scrollView AnimDuration:1.5 Alpha:1];
        if (!enableKenBurns) {
            [self alphaImage:fanartView AnimDuration:1.5 Alpha:0.2];// cool
        }
        else {
            [self alphaView:self.kenView AnimDuration:1.5 Alpha:0.2];// cool
        }
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        if (IS_IPAD) {
            if (![self isModal]) {
                [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollFullScreenDisabled" object:self.view userInfo:nil];
            }
            [UIView animateWithDuration:1.5
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 toolbar.alpha = 1.0;
                             }
                             completion:^(BOOL finished) {}
             ];
        }
    }
    else {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        if (IS_IPAD) {
            if (![self isModal]) {
                NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                        @(YES), @"hideToolbar",
                                        @(YES), @"clipsToBounds",
                                        nil];
                [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollFullScreenEnabled" object:self.view userInfo:params];
            }
            [UIView animateWithDuration:1.5
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 self.kenView.alpha = 0.0;
                                 toolbar.alpha = 0.0;
                                 if ([self isModal]) {
                                     originalSelfFrame = self.view.frame;
                                     CGRect fullscreenRect = [self currentScreenBoundsDependOnOrientation];
                                     fullscreenRect.origin.y += 10;
                                 }
                             }
                             completion:^(BOOL finished) {}
             ];
            if (self.kenView != nil) {
                CGFloat alphaValue = 1;
                [UIView animateWithDuration:0.2
                                 animations:^{
                                     self.kenView.alpha = 0;
                                 }
                                 completion:^(BOOL finished) {
                                     [self elabKenBurns:fanartView.image];
                                     [self alphaView:self.kenView AnimDuration:1.5 Alpha:alphaValue];
                                 }
                 ];
            }
        }
        [self alphaView:scrollView AnimDuration:1.5 Alpha:0];
        if (!enableKenBurns) {
            [self alphaImage:fanartView AnimDuration:1.5 Alpha:1];// cool
        }
        else {
            [self alphaView:self.kenView AnimDuration:1.5 Alpha:1];// cool
        }
        if (closeButton == nil) {
            int cbWidth = clearLogoWidth / 2;
            int cbHeight = clearLogoHeight / 2;
            closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - cbWidth/2, self.view.bounds.size.height - cbHeight - 20, cbWidth, cbHeight)];
            closeButton.titleLabel.shadowColor = [Utilities getGrayColor:0 alpha:0.8];
            closeButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
            closeButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                           UIViewAutoresizingFlexibleRightMargin |
                                           UIViewAutoresizingFlexibleLeftMargin |
                                           UIViewAutoresizingFlexibleWidth;
            if (clearLogoImageView.frame.size.width == 0) {
                [closeButton setTitle:clearlogoButton.titleLabel.text forState:UIControlStateNormal];
                closeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
            }
            else {
                closeButton.imageView.layer.minificationFilter = kCAFilterTrilinear;
                [closeButton setImage:clearLogoImageView.image forState:UIControlStateNormal];
                [closeButton setImage:clearLogoImageView.image forState:UIControlStateHighlighted];
                closeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
            }
            [closeButton addTarget:self action:@selector(showBackground:) forControlEvents:UIControlEventTouchUpInside];
            closeButton.tag = 1;
            closeButton.alpha = 0;
            [self.view addSubview:closeButton];
        }
        [self alphaView:closeButton AnimDuration:1.5 Alpha:1];
    }
    [self scrollDown:nil];
}

- (void)scrollViewDidScroll:(UIScrollView*)theScrollView {
    int height_content = theScrollView.contentSize.height;
    int height_bounds = theScrollView.bounds.size.height;
    int scrolled = theScrollView.contentOffset.y;
    bool at_bottom = scrolled >= height_content - height_bounds;
    if (arrow_continue_down.alpha && at_bottom) {
        [self alphaView:arrow_continue_down AnimDuration:0.3 Alpha:0];
    }
    else if (!arrow_continue_down.alpha && !at_bottom) {
        [self alphaView:arrow_continue_down AnimDuration:0.3 Alpha:ARROW_ALPHA];
    }
    bool at_top = theScrollView.contentOffset.y <= -scrollView.contentInset.top;
    if (arrow_back_up.alpha && at_top) {
        [self alphaView:arrow_back_up AnimDuration:0.3 Alpha:0];
    }
    else if (!arrow_back_up.alpha && !at_top) {
        [self alphaView:arrow_back_up AnimDuration:0.3 Alpha:ARROW_ALPHA];
    }
}

- (void)alphaImage:(UIImageView*)image AnimDuration:(NSTimeInterval)seconds Alpha:(CGFloat)alphavalue {
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	image.alpha = alphavalue;
    if (alphavalue) {
        image.hidden = NO;
    }
    [UIView commitAnimations];
}

- (void)alphaView:(UIView*)view AnimDuration:(NSTimeInterval)seconds Alpha:(CGFloat)alphavalue {
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	view.alpha = alphavalue;
    [UIView commitAnimations];
}

#pragma mark - Actors UITableView data source & delegate

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return castHeight + VERTICAL_PADDING;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return cast.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *CellIdentifier = @"CellActor";
    ActorCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ActorCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier castWidth:castWidth castHeight:castHeight size:lineSpacing castFontSize:castFontSize];
    }
    GlobalData *obj = [GlobalData getInstance];
    NSString *serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
    if (AppDelegate.instance.serverVersion > 11) {
        serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
    }
    NSString *stringURL = [Utilities formatStringURL:cast[indexPath.row][@"thumbnail"] serverURL:serverURL];
    [cell.actorThumbnail setImageWithURL:[NSURL URLWithString:stringURL]
                        placeholderImage:[UIImage imageNamed:@"person"]
                               andResize:CGSizeMake(castWidth, castHeight)];
    [Utilities applyRoundedEdgesView:cell.actorThumbnail drawBorder:YES];
    cell.actorName.text = cast[indexPath.row][@"name"] == nil ? self.detailItem[@"label"] : cast[indexPath.row][@"name"];
    if ([cast[indexPath.row][@"role"] length] != 0) {
        cell.actorRole.text = [NSString stringWithFormat:@"%@", cast[indexPath.row][@"role"]];
        [cell.actorRole sizeToFit];
    }
    return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    if (AppDelegate.instance.serverVersion > 11 && ![self isModal]) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_arrow_right_selected"]];
        cell.accessoryView.alpha = ARROW_ALPHA;
    }
    else {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    if (AppDelegate.instance.serverVersion > 11 && ![self isModal]) {
        [self showContent:cast[indexPath.row][@"name"]];
    }
}

#pragma mark - Safari

- (void)safariViewControllerDidFinish:(SFSafariViewController*)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Gestures

- (void)handleSwipeFromLeft:(id)sender {
    if (![self.detailItem[@"disableNowPlaying"] boolValue]) {
        [self showNowPlaying];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}

# pragma mark - JSON Data

- (void)addQueueAfterCurrent:(BOOL)afterCurrent {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    NSDictionary *item = self.detailItem;
    NSString *param = item[@"family"];
    id value = item[item[@"family"]];
    // Since API 12.7.0 Kodi server can handle Playlist.Insert and Playlist.Add for recordingid.
    // Before, the JSON parameters must use the file path.
    if (!(AppDelegate.instance.APImajorVersion >= 12 && AppDelegate.instance.APIminorVersion >= 7) && [self.detailItem[@"family"] isEqualToString:@"recordingid"]) {
        param = @"file";
        value = item[@"file"];
    }
    if (afterCurrent) {
        [activityIndicatorView startAnimating];
        [[Utilities getJsonRPC]
         callMethod:@"Player.GetProperties"
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                         item[@"playlistid"], @"playerid",
                         @[@"percentage", @"time", @"totaltime", @"partymode", @"position"], @"properties",
                         nil]
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
             if (error == nil && methodError == nil) {
                 if ([NSJSONSerialization isValidJSONObject:methodResult]) {
                     if ([methodResult count]) {
                         [activityIndicatorView stopAnimating];
                         int newPos = [methodResult[@"position"] intValue] + 1;
                         NSString *action2 = @"Playlist.Insert";
                         NSDictionary *params2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                                item[@"playlistid"], @"playlistid",
                                                [NSDictionary dictionaryWithObjectsAndKeys: value, param, nil], @"item",
                                                @(newPos), @"position",
                                                nil];
                         [[Utilities getJsonRPC] callMethod:action2 withParameters:params2 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                             if (error == nil && methodError == nil) {
                                 [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
                             }
                             
                         }];
                         self.navigationItem.rightBarButtonItem.enabled = YES;
                     }
                     else {
                         [self addQueueAfterCurrent:NO];
                     }
                 }
                 else {
                     [self addQueueAfterCurrent:NO];
                 }
             }
             else {
                 [self addQueueAfterCurrent:NO];
             }
         }];
    }
    else {
        [activityIndicatorView startAnimating];
        [[Utilities getJsonRPC] callMethod:@"Playlist.Add" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:item[@"playlistid"], @"playlistid", [NSDictionary dictionaryWithObjectsAndKeys: value, param, nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            [activityIndicatorView stopAnimating];
            if (error == nil && methodError == nil) {
                [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
            }
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }];
    }
}

- (void)addPlayback:(float)resumePointLocal {
    if ([self.detailItem[@"family"] isEqualToString:@"broadcastid"]) {
        [self openFile:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: self.detailItem[@"pvrExtraInfo"][@"channelid"], @"channelid", nil], @"item", nil]];
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [activityIndicatorView startAnimating];
        NSDictionary *item = self.detailItem;
        [[Utilities getJsonRPC] callMethod:@"Playlist.Clear" withParameters:[NSDictionary dictionaryWithObjectsAndKeys: item[@"playlistid"], @"playlistid", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            if (error == nil && methodError == nil) {
                NSString *param = item[@"family"];
                id value = item[item[@"family"]];
                // Since API 12.7.0 Kodi server can handle Playlist.Insert and Playlist.Add for recordingid.
                // Before, the JSON parameters must use the file path.
                if (!(AppDelegate.instance.APImajorVersion >= 12 && AppDelegate.instance.APIminorVersion >= 7) && [self.detailItem[@"family"] isEqualToString:@"recordingid"]) {
                    param = @"file";
                    value = item[@"file"];
                }
                [[Utilities getJsonRPC] callMethod:@"Playlist.Add" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:item[@"playlistid"], @"playlistid", [NSDictionary dictionaryWithObjectsAndKeys: value, param, nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                    if (error == nil && methodError == nil) {
                        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
                        [[Utilities getJsonRPC] callMethod:@"Player.Open" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: item[@"playlistid"], @"playlistid", @(0), @"position", nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                            if (error == nil && methodError == nil) {
                                [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
                                [activityIndicatorView stopAnimating];
                                [self showNowPlaying];
                                [Utilities checkForReviewRequest];
                                if (resumePointLocal) {
                                    [NSThread sleepForTimeInterval:1.0];
                                    [self SimpleAction:@"Player.Seek" params:[Utilities buildPlayerSeekPercentageParams:[item[@"playlistid"] intValue] percentage:resumePointLocal]];
                                }
                            }
                            else {
                                [activityIndicatorView stopAnimating];
                                self.navigationItem.rightBarButtonItem.enabled = YES;
                            }
                        }];
                    }
                    else {
                        [activityIndicatorView stopAnimating];
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }];
            }
            else {
                [activityIndicatorView stopAnimating];
                self.navigationItem.rightBarButtonItem.enabled = YES;
            }
        }];
    }
}

- (void)openFile:(NSDictionary*)params {
    [activityIndicatorView startAnimating];
    [[Utilities getJsonRPC] callMethod:@"Player.Open" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        [activityIndicatorView stopAnimating];
        if (error == nil && methodError == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
            [self showNowPlaying];
        }
    }];
}

- (void)SimpleAction:(NSString*)action params:(NSDictionary*)parameters {
    [[Utilities getJsonRPC] callMethod:action withParameters:parameters];
}

# pragma mark - Gestures

- (void)handleSwipeFromRight:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

# pragma mark - Utility

- (void)elabKenBurns:(UIImage*)image {
    [self.kenView stopAnimation];
    [self.kenView removeFromSuperview];
    self.kenView = [[KenBurnsView alloc] initWithFrame:fanartView.frame];
    self.kenView.autoresizingMask = fanartView.autoresizingMask;
    self.kenView.contentMode = fanartView.contentMode;
    self.kenView.delegate = self;
    self.kenView.alpha = 0;
    self.kenView.tag = 1;
    NSArray *backgroundImages = [NSArray arrayWithObjects:
                                 image,
                                 nil];
    [self.kenView animateWithImages:backgroundImages
                 transitionDuration:45
                               loop:YES
                        isLandscape:YES];
    UITapGestureRecognizer *touchOnKenView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showBackground:)];
    touchOnKenView.numberOfTapsRequired = 1;
    touchOnKenView.numberOfTouchesRequired = 1;
    [self.kenView addGestureRecognizer:touchOnKenView];
    [self.view insertSubview:self.kenView atIndex:1];
}

# pragma mark - Life Cycle

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        // Update the view.
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.slidingViewController.underRightViewController = nil;
    self.slidingViewController.anchorLeftPeekAmount   = 0;
    self.slidingViewController.anchorLeftRevealAmount = 0;
    // TRICK WHEN CHILDREN WAS FORCED TO PORTRAIT
//    if (![self.detailItem[@"disableNowPlaying"] boolValue]) {
//        UIViewController *c = [[UIViewController alloc]init];
//        [self presentViewController:c animated:NO completion:nil];
//        [self dismissViewControllerAnimated:NO completion:nil];
//    }
    [actorsTable deselectRowAtIndexPath:[actorsTable indexPathForSelectedRow] animated:YES];
    if ([self isModal]) {
        if (doneButton == nil) {
            NSMutableArray *items = [toolbar.items mutableCopy];
            doneButton = [[UIBarButtonItem alloc] initWithTitle:LOCALIZED_STR(@"Done") style:UIBarButtonItemStyleDone target:self action:@selector(dismissModal:)];
            [items insertObject:doneButton atIndex:0];
            toolbar.items = items;
        }
        [self setIOS7barTintColor:TINT_COLOR];
        viewTitle.textAlignment = NSTextAlignmentCenter;
        bottomShadow.hidden = YES;
    }
    if (isViewDidLoad) {
        [self createInfo];
        isViewDidLoad = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (foundTintColor != nil) {
        [self setIOS7barTintColor:foundTintColor];
    }
    else {
        [self setIOS7barTintColor:TINT_COLOR];
    }
    CGFloat alphaValue = 0.2;
    if (closeButton.alpha == 1) {
        alphaValue = 1;
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
    if (!enableKenBurns) {
        [self alphaImage:fanartView AnimDuration:1.5 Alpha:alphaValue];// cool
    }
    else {
        if (fanartView.image != nil && self.kenView == nil) {
            fanartView.alpha = 0;
            [self elabKenBurns:fanartView.image];
        }
        [self alphaView:self.kenView AnimDuration:1.5 Alpha:alphaValue];// cool
    }
    if ([self isModal]) {
        clearlogoButton.frame = CGRectMake((int)(self.view.frame.size.width / 2) - (int)(clearlogoButton.frame.size.width / 2),
                                           clearlogoButton.frame.origin.y,
                                           clearlogoButton.frame.size.width,
                                           clearlogoButton.frame.size.height);
        self.view.superview.backgroundColor = UIColor.clearColor;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [self setIOS7barTintColor:TINT_COLOR];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self alphaImage:fanartView AnimDuration:0.3 Alpha:0.0];
    if (self.kenView != nil) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.kenView.alpha = 0;
                         }
                         completion:^(BOOL finished) {
                             [self.kenView stopAnimation];
                             [self.kenView removeFromSuperview];
                             self.kenView = nil;
                         }
         ];
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

- (void)viewDidLoad {
    [super viewDidLoad];
    SDWebImageDownloader *manager = [SDWebImageManager sharedManager].imageDownloader;
    NSDictionary *httpHeaders = AppDelegate.instance.getServerHTTPHeaders;
    if (httpHeaders[@"Authorization"] != nil) {
        [manager setValue:httpHeaders[@"Authorization"] forHTTPHeaderField:@"Authorization"];
    }
    isViewDidLoad = YES;
    fanartView.tag = 1;
    fanartView.userInteractionEnabled = YES;
    UITapGestureRecognizer *touchOnKenView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showBackground:)];
    touchOnKenView.numberOfTapsRequired = 1;
    touchOnKenView.numberOfTouchesRequired = 1;
    [fanartView addGestureRecognizer:touchOnKenView];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self disableScrollsToTopPropertyOnAllSubviewsOf:self.slidingViewController.view];
    scrollView.scrollsToTop = YES;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *kenBurnsString = [userDefaults objectForKey:@"ken_preference"];
    if (kenBurnsString == nil || [kenBurnsString boolValue]) {
        enableKenBurns = YES;
    }
    else {
        enableKenBurns = NO;
    }
    self.kenView = nil;
    logoBackgroundMode = [Utilities getLogoBackgroundMode];
    foundTintColor = TINT_COLOR;
    [self configureView];
    
    xbmcDateFormatter = [NSDateFormatter new];
    xbmcDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    xbmcDateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"]; // all times in Kodi PVR are UTC
    
    localStartDateFormatter = [NSDateFormatter new];
    localStartDateFormatter.timeZone = [NSTimeZone systemTimeZone];
    localStartDateFormatter.dateFormat = @"ccc dd MMM, HH:mm";
    
    localEndDateFormatter = [NSDateFormatter new];
    localEndDateFormatter.timeZone = [NSTimeZone systemTimeZone];
    localEndDateFormatter.dateFormat = @"HH:mm";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [kenView removeFromSuperview];
    [self.kenView removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (self.kenView != nil) {
        CGFloat alphaValue = 0.2;
        if (closeButton.alpha == 1) {
            alphaValue = 1;
        }
        [UIView animateWithDuration:0.2
                         animations:^{
                             self.kenView.alpha = 0;
                         }
                         completion:^(BOOL finished) {
                             [self elabKenBurns:fanartView.image];
                             [self alphaView:self.kenView AnimDuration:0.2 Alpha:alphaValue];
                         }
         ];
    }
}

@end
