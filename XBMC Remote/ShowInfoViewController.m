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
        [self.view setFrame:frame];
    }
    return self;
}

double round(double d) {
    return floor(d + 0.5);
}

int count = 0;

- (void)configureView {
    if (self.detailItem) {
        NSMutableDictionary *item = self.detailItem;
        CGRect frame = CGRectMake(0, 0, 140, 40);
        viewTitle = [[UILabel alloc] initWithFrame:frame];
        viewTitle.numberOfLines = 0;
        viewTitle.font = [UIFont boldSystemFontOfSize:11];
        viewTitle.minimumScaleFactor = 6.0/11.0;
        viewTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        viewTitle.backgroundColor = [UIColor clearColor];
        viewTitle.shadowColor = [Utilities getGrayColor:0 alpha:0];
        viewTitle.textAlignment = NSTextAlignmentCenter;
        viewTitle.textColor = [UIColor whiteColor];
        viewTitle.text = item[@"label"];
        [viewTitle sizeThatFits:CGSizeMake(140, 40)];
        sheetActions = [[NSMutableArray alloc] initWithObjects:LOCALIZED_STR(@"Queue after current"), LOCALIZED_STR(@"Queue"), LOCALIZED_STR(@"Play"), nil];
        NSDictionary *resumePointDict = item[@"resume"];
        if (resumePointDict != nil) {
            if (((NSNull*)resumePointDict[@"position"] != [NSNull null])) {
                if ([resumePointDict[@"position"] floatValue] > 0) {
                    resumePointPercentage = ([resumePointDict[@"position"] floatValue] * 100) / [resumePointDict[@"total"] floatValue];
                    [sheetActions addObject:[NSString stringWithFormat:LOCALIZED_STR(@"Resume from %@"), [Utilities convertTimeFromSeconds: @([resumePointDict[@"position"] floatValue])]]];
                }
            }
        }
//        if ([item[@"family"] isEqualToString:@"movieid"] || [item[@"family"] isEqualToString:@"episodeid"]|| [item[@"family"] isEqualToString:@"musicvideoid"]) {
//            NSString *actionString = @"";
//            if ([item[@"playcount"] intValue] == 0) {
//                actionString = LOCALIZED_STR(@"Mark as watched");
//            }
//            else {
//                actionString = LOCALIZED_STR(@"Mark as unwatched");
//            }
//            [sheetActions addObject:actionString];
//        }
        BOOL fromAlbumView = NO;
        if (((NSNull*)item[@"fromAlbumView"] != [NSNull null])) {
            fromAlbumView = [item[@"fromAlbumView"] boolValue];
        }
        BOOL fromEpisodesView = NO;
        if (((NSNull*)item[@"fromEpisodesView"] != [NSNull null])) {
            fromEpisodesView = [item[@"fromEpisodesView"] boolValue];
        }
        UIBarButtonItem *extraButton = nil;
        int titleWidth = 350;
        if ([item[@"family"] isEqualToString:@"albumid"]) {
            UIImage* extraButtonImg = [UIImage imageNamed:@"st_songs"];
            if (fromAlbumView) {
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
            }
            else {
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(showContent:)];
            }
            titleWidth = 350;
        }
        else if ([item[@"family"] isEqualToString:@"artistid"]) {
            UIImage* extraButtonImg = [UIImage imageNamed:@"st_album"];
            extraButton =[[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(showContent:)];
            titleWidth = 350;
        }
        else if ([item[@"family"] isEqualToString:@"tvshowid"]) {
            UIImage* extraButtonImg = [UIImage imageNamed:@"st_tv"];
            if (fromEpisodesView) {
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
            }
            else {
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(showContent:)];
            }
            titleWidth = 350;
        }
        else if ([item[@"family"] isEqualToString:@"broadcastid"]) {
            NSString *pvrAction = [item[@"hastimer"] boolValue] ? LOCALIZED_STR(@"Stop Recording") : LOCALIZED_STR(@"Record");
            sheetActions = [[NSMutableArray alloc] initWithObjects:
                            LOCALIZED_STR(@"Play"),
                            pvrAction,
                            nil];
            titleWidth = 350;
        }
//        else if ([item[@"family"] isEqualToString:@"episodeid"] || [item[@"family"] isEqualToString:@"movieid"] || [item[@"family"] isEqualToString:@"musicvideoid"]) {
//            [sheetActions addObject:LOCALIZED_STR(@"Open with VLC")];
//            titleWidth = 400;
//        }
        else {
            titleWidth = 400;
        }
        if ([item[@"trailer"] isKindOfClass:[NSString class]]) {
            if ([item[@"trailer"] length] > 0) {
                [sheetActions addObject:LOCALIZED_STR(@"Play Trailer")];
            }
        }
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            toolbar = [UIToolbar new];
            toolbar.barStyle = UIBarStyleBlack;
            toolbar.translucent = YES;
            UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            actionSheetButtonItemIpad = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(showActionSheet)];
            actionSheetButtonItemIpad.style = UIBarButtonItemStylePlain;
            viewTitle.numberOfLines = 1;
            viewTitle.font = [UIFont boldSystemFontOfSize:22];
            viewTitle.minimumScaleFactor = 6.0/22.0;
            viewTitle.adjustsFontSizeToFitWidth = YES;
            viewTitle.shadowOffset = CGSizeMake(1, 1);
            viewTitle.shadowColor = [Utilities getGrayColor:0 alpha:0.7];
            viewTitle.autoresizingMask = UIViewAutoresizingNone;
            viewTitle.contentMode = UIViewContentModeScaleAspectFill;
            [viewTitle setFrame:CGRectMake(0, 0, titleWidth, 44)];
            [viewTitle sizeThatFits:CGSizeMake(titleWidth, 44)];
            viewTitle.textAlignment = NSTextAlignmentLeft;
            UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithCustomView:viewTitle];
            if (extraButton == nil) {
                extraButton = spacer;
            }
            NSArray *items = [NSArray arrayWithObjects: 
                              title,
                              spacer,
                              extraButton,
                              spacer,
                              actionSheetButtonItemIpad,
                              nil];
            toolbar.items = items;
            toolbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
            toolbar.contentMode = UIViewContentModeScaleAspectFill;
            [toolbar sizeToFit];
            CGFloat toolbarHeight = [toolbar frame].size.height;
            CGRect mainViewBounds = self.view.bounds;
            [toolbar setFrame:CGRectMake(CGRectGetMinX(mainViewBounds),
                                         CGRectGetMinY(mainViewBounds),
                                         CGRectGetWidth(mainViewBounds),
                                         toolbarHeight)];
            [self.view addSubview:toolbar];
            scrollView.contentInset = UIEdgeInsetsMake(toolbarHeight, 0, 0, 0);
        }
        else {
//            self.navigationItem.titleView = viewTitle;
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

//- (BOOL)isModal {
//    BOOL isModal = ((self.parentViewController && self.parentViewController.modalViewController == self) ||
//                    (self.navigationController && self.navigationController.parentViewController && self.navigationController.parentViewController.modalViewController == self.navigationController) ||
//                    [[[self tabBarController] parentViewController] isKindOfClass:[UITabBarController class]]);
//    if (!isModal && [self respondsToSelector:@selector(presentingViewController)]) {
//        
//        isModal = ((self.presentingViewController && self.presentingViewController.modalViewController == self) ||
//                   (self.navigationController && self.navigationController.presentingViewController && self.navigationController.presentingViewController.modalViewController == self.navigationController) ||
//                   [[[self tabBarController] presentingViewController] isKindOfClass:[UITabBarController class]]);
//    }
//    return isModal;
//}

- (BOOL)isModal {
    return self.presentingViewController.presentedViewController == self
    || (self.navigationController != nil && self.navigationController.presentingViewController.presentedViewController == self.navigationController)
    || [self.tabBarController.presentingViewController isKindOfClass:[UITabBarController class]];
}

- (void)goBack:(id)sender {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationEnableStackPan" object: nil];
    }
}

#pragma mark - ToolBar button

- (void)showContent:(id)sender {
    NSDictionary *item = self.detailItem;
    mainMenu *MenuItem = nil;
    mainMenu *choosedMenuItem = nil;
    choosedTab = 0;
    id movieObj = nil;
    id movieObjKey = nil;
    NSString *blackTableSeparator = @"NO";
    if ([item[@"family"] isEqualToString:@"albumid"]) {
        notificationName = @"UIApplicationEnableMusicSection";
        MenuItem = [[AppDelegate instance].playlistArtistAlbums copy];
        choosedMenuItem = MenuItem.subItem;
        choosedMenuItem.mainLabel = [NSString stringWithFormat:@"%@", item[@"label"]];

    }
    else if ([item[@"family"] isEqualToString:@"tvshowid"] && ![sender isKindOfClass:[NSString class]]) {
        notificationName = @"UIApplicationEnableTvShowSection";
        MenuItem = [[AppDelegate instance].playlistTvShows copy];
        choosedMenuItem = MenuItem.subItem;
        choosedMenuItem.mainLabel = [NSString stringWithFormat:@"%@", item[@"label"]];

    }
    else if ([item[@"family"] isEqualToString:@"artistid"]) {
        notificationName = @"UIApplicationEnableMusicSection";
        choosedTab = 1;
        MenuItem = [[AppDelegate instance].playlistArtistAlbums copy];
        choosedMenuItem = MenuItem.subItem;
        choosedMenuItem.mainLabel = [NSString stringWithFormat:@"%@", item[@"label"]];
    }
    else if ([item[@"family"] isEqualToString:@"movieid"] && [AppDelegate instance].serverVersion > 11) {
        if ([sender isKindOfClass:[NSString class]]) {
            NSString *actorName = (NSString*)sender;
            choosedTab = 2;
            MenuItem = [[AppDelegate instance].playlistMovies copy];
            movieObj = [NSDictionary dictionaryWithObjectsAndKeys:actorName, @"actor", nil];
            movieObjKey = @"filter";
            choosedMenuItem = MenuItem.subItem;
            choosedMenuItem.mainLabel = actorName;
        }
    }
    else if (([item[@"family"] isEqualToString:@"episodeid"] || [item[@"family"] isEqualToString:@"tvshowid"]) && [AppDelegate instance].serverVersion > 11) {
        if ([sender isKindOfClass:[NSString class]]) {
            NSString *actorName = (NSString*)sender;
            choosedTab = 0;
            MenuItem = [[AppDelegate instance].playlistTvShows copy];
            movieObj = [NSDictionary dictionaryWithObjectsAndKeys:actorName, @"actor", nil];
            movieObjKey = @"filter";
            choosedMenuItem = MenuItem;
            choosedMenuItem.mainLabel = actorName;
            [MenuItem setEnableSection:NO];
            [MenuItem setMainButtons:nil];
            if ([AppDelegate instance].obj.preferTVPosters) {
                thumbWidth = PHONE_TV_SHOWS_POSTER_WIDTH;
                tvshowHeight = PHONE_TV_SHOWS_POSTER_HEIGHT;
            }
            MenuItem.thumbWidth = thumbWidth;
            MenuItem.rowHeight = tvshowHeight;
            blackTableSeparator = @"YES";
        }
    }
    else {
        return;
    }
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[choosedMenuItem mainMethod][choosedTab]];
    if (methods[@"method"] != nil) { // THERE IS A CHILD
        NSDictionary *mainFields = [MenuItem mainFields][choosedTab];
        NSMutableDictionary *parameters = [Utilities indexKeyedMutableDictionaryFromArray:[choosedMenuItem mainParameters][choosedTab]];
        id obj = @([item[mainFields[@"row6"]] intValue]);
        id objKey = mainFields[@"row6"];
        if (movieObj != nil && movieObjKey != nil) {
            obj = movieObj;
            objKey = movieObjKey;
        }
        else if ([AppDelegate instance].serverVersion > 11 && ![parameters[@"disableFilterParameter"] boolValue]) {
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
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
            detailViewController.detailItem = choosedMenuItem;
            [self.navigationController pushViewController:detailViewController animated:YES];
        }
        else {
            if (![self isModal]) {
                DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:choosedMenuItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:NO];
                [[AppDelegate instance].windowController.stackScrollViewController enablePanGestureRecognizer];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object: nil];
            }
            else {
                DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:choosedMenuItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                [iPadDetailViewController setModalPresentationStyle:UIModalPresentationFormSheet];
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
    NSInteger numActions = [sheetActions count];
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
        [actionView setModalPresentationStyle:UIModalPresentationPopover];
        
        UIPopoverPresentationController *popPresenter = [actionView popoverPresentationController];
        if (popPresenter != nil) {
            popPresenter.sourceView = self.view;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
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
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Open with VLC")]) {
        [self openWithVLC:self.detailItem];
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
                             frame.origin.x += dotSize + dotSizePadding;
                             frame.size.width -= dotSize + dotSizePadding;
                             [voteLabel setFrame:frame];
                         }
                         else {
                             isRecording.alpha = 0.0;
                             frame.origin.x -= dotSize + dotSizePadding;
                             frame.size.width += dotSize + dotSizePadding;
                             [voteLabel setFrame:frame];
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
        NSDateFormatter *xbmcDateFormatter = [NSDateFormatter new];
        [xbmcDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
        NSDate *starttime = [xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", self.detailItem[@"starttime"]]];
        NSDate *endtime = [xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", self.detailItem[@"endtime"]]];
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

- (void)moveLabel:(NSArray*)objects posY:(int)y {
    NSInteger count = [objects count];
    CGRect frame;
    for (int i = 0; i < count; i++) {
        if ([objects[i] isKindOfClass:[UIImageView class]]) {
            UIImageView *label = objects[i];
            frame = label.frame;
            frame.origin.y = frame.origin.y - y;
            label.frame = frame;
        }
        if ([objects[i] isKindOfClass:[UILabel class]]) {
            UILabel *label = objects[i];
            frame = label.frame;
            frame.origin.y = frame.origin.y - y;
            label.frame = frame;
        }
        
    }
}

- (void)setAndMoveLabels:(NSArray*)arrayLabels size:(int)moveSize {
    UIFont *fontFace = [UIFont systemFontOfSize:16];

    int offset = moveSize;
    for (UILabel *label in arrayLabels) {
        [label setFont:fontFace];
        [label setFrame:
         CGRectMake(
                    label.frame.origin.x, 
                    label.frame.origin.y + offset, 
                    label.frame.size.width, 
                    label.frame.size.height + moveSize
                    )
         ];
        offset += moveSize;
    }
}

- (void)setTvShowsToolbar {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSInteger count = [toolbar.items count];
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

- (UIImage*)imageWithBorderFromImage:(UIImage*)source {
    return [Utilities imageWithShadow:source radius:10];
}

- (BOOL)enableJewelCases {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [[userDefaults objectForKey:@"jewel_preference"] boolValue];
}

- (void)startActivityIndicator {
    [activityIndicatorView startAnimating];
}

- (void)elaborateImage:(UIImage*)image {
    [self performSelectorOnMainThread:@selector(startActivityIndicator) withObject:nil waitUntilDone:YES];
    UIImage *elabImage = isRecordingDetail ? image : [self imageWithBorderFromImage:image];
    [self performSelectorOnMainThread:@selector(showImage:) withObject:elabImage waitUntilDone:YES];
}

- (void)showImage:(UIImage*)image {
    [activityIndicatorView stopAnimating];
    jewelView.alpha = 0;
    jewelView.image = image;
    if (isRecordingDetail) {
        [Utilities setLogoBackgroundColor:jewelView mode:logoBackgroundMode];
        CGRect frame;
        frame.size.width = ceil(TV_LOGO_SIZE_REC_DETAILS * 0.9);
        frame.size.height = ceil(TV_LOGO_SIZE_REC_DETAILS * 0.7);
        frame.origin.x = jewelView.frame.origin.x + (jewelView.frame.size.width - frame.size.width)/2;
        frame.origin.y = jewelView.frame.origin.y + 4;
        jewelView.frame = frame;
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
    isRecordingDetail = item[@"recordingid"] != nil;
//    NSLog(@"ITEM %@", item);
    eJewelType jeweltype = jewelTypeUnknown;
    castFontSize = 14;
    size = 0;
    castWidth = 50;
    castHeight = 70;
    int pageSize = [self currentScreenBoundsDependOnOrientation].size.width - 23;
    int labelSpace = 20;
    bool enableJewel = [self enableJewelCases];
    if (!enableJewel) {
        jewelView.image = nil;
    }
    clearLogoWidth = self.view.frame.size.width - 20;
    clearLogoHeight = 116;
    CGFloat transform = [Utilities getTransformX];
    int shiftParentalRating = -20;
    NSString *contributorString = @"cast";
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        clearLogoWidth = 457;
        clearLogoHeight = 177;
        thumbWidth = (int)(PAD_TV_SHOWS_BANNER_WIDTH * transform);
        tvshowHeight = (int)(PAD_TV_SHOWS_BANNER_HEIGHT * transform);
        shiftParentalRating = -40;
        labelSpace = 33;
        castFontSize = 16;
        size = 6;
        castWidth = 75;
        castHeight = 105;
        pageSize = self.view.bounds.size.width - 40;
        [starsView setFrame:
         CGRectMake(
                    starsView.frame.origin.x, 
                    starsView.frame.origin.y - size, 
                    starsView.frame.size.width, 
                    starsView.frame.size.height + size*2
                    )];
        [voteLabel setFont:[UIFont systemFontOfSize:26]];
        [voteLabel setFrame:
         CGRectMake(
                    voteLabel.frame.origin.x,
                    voteLabel.frame.origin.y - size,
                    voteLabel.frame.size.width,
                    voteLabel.frame.size.height
                    )];
        [numVotesLabel setFont:[UIFont systemFontOfSize:18]];

        NSArray *arrayLabels = @[label1, directorLabel, label2, genreLabel, label3, runtimeLabel, label4, studioLabel, label5, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, label6];
        [self setAndMoveLabels:arrayLabels size:size];
    }
    else {
        thumbWidth = (int)(PHONE_TV_SHOWS_BANNER_WIDTH * transform);
        tvshowHeight = (int)(PHONE_TV_SHOWS_BANNER_HEIGHT * transform);
    }
    if (!enableJewel) {
        CGRect frame = jewelView.frame;
        frame.origin.x = 0;
        jewelView.frame = frame;
    }
    if ([item[@"family"] isEqualToString:@"episodeid"] || [item[@"family"] isEqualToString:@"tvshowid"]) {
        int deltaY = 0;
        int coverHeight = 0;
        CGRect frame;
        placeHolderImage = @"coverbox_back_tvshows";
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:LOCALIZED_STR(@"LocaleIdentifier")];
        NSDateFormatter *format = [NSDateFormatter new];
        [format setLocale:locale];
        if ([item[@"family"] isEqualToString:@"tvshowid"]) {
            GlobalData *obj = [GlobalData getInstance];
            if (!obj.preferTVPosters && [AppDelegate instance].serverVersion < 12) {
                placeHolderImage = @"blank";
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                    coverHeight = 70;
                }
                else {
                    coverHeight = 90;
                }
                deltaY = coverView.frame.size.height - coverHeight;
                jewelView.hidden = YES;
            }
            else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                int originalHeight = jewelView.frame.size.height;
                int coverHeight = 560;
                deltaY = -(coverHeight - originalHeight);
                frame = jewelView.frame;
                frame.size.height = coverHeight;
                jewelView.frame = frame;
            }
            if (enableJewel) {
                jewelView.image = [UIImage imageNamed:@"jewel_dvd.9"];
                jeweltype = jewelTypeDVD;
            }
            coverView.autoresizingMask = UIViewAutoresizingNone;
            coverView.contentMode = UIViewContentModeScaleAspectFill;
            label1.text = LOCALIZED_STR(@"EPISODES");
            label3.text = LOCALIZED_STR(@"GENRE");
            label4.text = LOCALIZED_STR(@"STUDIO");
            directorLabel.text = [Utilities getStringFromDictionary:item key:@"episode" emptyString:@"-"];
            [format setDateFormat:@"yyyy-MM-dd"];
            NSDate *date = [format dateFromString:item[@"premiered"]];
            [format setDateFormat:LOCALIZED_STR(@"LongDateTimeFormat")];
            genreLabel.text = date == nil ? @"-" : [format stringFromDate:date];
            runtimeLabel.text = [Utilities getStringFromDictionary:item key:@"genre" emptyString:@"-"];
            studioLabel.text = [Utilities getStringFromDictionary:item key:@"studio" emptyString:@"-"];
            numVotesLabel.hidden = YES;
            [self setTvShowsToolbar];
        }
        else if ([item[@"family"] isEqualToString:@"episodeid"]) {
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                coverHeight = 280;
            }
            else {
                coverHeight = 200;
            }
            jewelView.hidden = NO;
            deltaY = jewelView.frame.size.height - coverHeight;
            coverView.autoresizingMask = UIViewAutoresizingNone;
            coverView.contentMode = UIViewContentModeScaleAspectFill;
            label1.text = LOCALIZED_STR(@"TV SHOW");
            label3.text = LOCALIZED_STR(@"DIRECTOR");
            label4.text = LOCALIZED_STR(@"WRITER");
            parentalRatingLabelUp.hidden = YES;
            parentalRatingLabel.hidden = YES;
            
            frame = label6.frame;
            frame.origin.y = frame.origin.y + shiftParentalRating;
            label6.frame = frame;
            if (enableJewel) {
                jewelView.image = [UIImage imageNamed:@"jewel_tv.9"];
                jeweltype = jewelTypeTV;
            }
            frame = jewelView.frame;
            frame.size.height = coverHeight;
            jewelView.frame = frame;
            directorLabel.text = [Utilities getStringFromDictionary:item key:@"showtitle" emptyString:@"-"];

            NSString *aired = @"-";
            if ([item[@"firstaired"] length] > 0) {
                [format setDateFormat:@"yyyy-MM-dd"];
                NSDate *date = [format dateFromString:item[@"firstaired"]];
                [format setDateFormat:LOCALIZED_STR(@"LongDateTimeFormat")];
                aired = [format stringFromDate:date];
            }
            genreLabel.text = aired;
            runtimeLabel.text = [Utilities getStringFromDictionary:item key:@"director" emptyString:@"-"];
            studioLabel.text = [Utilities getStringFromDictionary:item key:@"writer" emptyString:@"-"];
            shiftParentalRating = 0;
        }
        [self moveLabel:@[starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel] posY:deltaY];
        
        label2.text = LOCALIZED_STR(@"FIRST AIRED");
        label5.text = LOCALIZED_STR(@"SUMMARY");
        
        frame = starsView.frame;
        frame.origin.x = frame.origin.x+29;
        starsView.frame = frame;
        
        frame = voteLabel.frame;
        frame.origin.x = frame.origin.x+29;
        voteLabel.frame = frame;
    }
    else if ([item[@"family"] isEqualToString:@"albumid"]) {
        // album details
        int coverHeight = 380;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            coverHeight = 290;
        }
        [self moveLabel:@[starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel] posY:40];
        jewelView.hidden = NO;
        int deltaY = jewelView.frame.size.height - coverHeight;
        label1.text = LOCALIZED_STR(@"ARTIST");
        label2.text = LOCALIZED_STR(@"YEAR");
        label3.text = LOCALIZED_STR(@"GENRE");
        label4.text = LOCALIZED_STR(@"ALBUM LABEL");
        label5.text = LOCALIZED_STR(@"DESCRIPTION");
        label6.text = @"";
        
        starsView.hidden = YES;
        voteLabel.hidden = YES;
        numVotesLabel.hidden = YES;

        parentalRatingLabelUp.hidden = YES;
        parentalRatingLabel.hidden = YES;
        
        CGRect frame = label6.frame;
        frame.origin.y = frame.origin.y-40;
        label6.frame = frame;
        if (enableJewel) {
            jewelView.image = [UIImage imageNamed:@"jewel_cd.9"];
            jeweltype = jewelTypeCD;
        }
        frame = jewelView.frame;
        frame.size.height = coverHeight;
        jewelView.frame = frame;
        
        directorLabel.text = [Utilities getStringFromDictionary:item key:@"artist" emptyString:@"-"];
        genreLabel.text = [Utilities getStringFromDictionary:item key:@"year" emptyString:@"-"];
        runtimeLabel.text = [Utilities getStringFromDictionary:item key:@"genre" emptyString:@"-"];
        studioLabel.text = [Utilities getStringFromDictionary:item key:@"label" emptyString:@"-"];
        [self moveLabel:@[starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel] posY:deltaY];
    }
    else if ([item[@"family"] isEqualToString:@"artistid"]) {
        // artist details
        contributorString = @"roles";
        castHeight -= 26;
        placeHolderImage = @"coverbox_back_artists";
        enableJewel = NO;
        jewelView.image = nil;
        int shiftY = 40;
        [self moveLabel:@[starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel] posY:shiftY];
        [self moveLabel:@[label4, label5, label6, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel] posY:40];
        label1.text = LOCALIZED_STR(@"GENRE");
        label2.text = LOCALIZED_STR(@"STYLE");
        label3.text = @"";
        label4.text = LOCALIZED_STR(@"BORN / FORMED");
        label5.text = LOCALIZED_STR(@"DESCRIPTION");
        label6.text = LOCALIZED_STR(@"MUSIC ROLES");
        parentalRatingLabelUp.hidden = YES;
        parentalRatingLabel.hidden = YES;
        runtimeLabel.hidden = YES;
        label3.hidden = YES;
//        CGRect frame = label6.frame;
//        frame.origin.y = frame.origin.y-40;
//        label6.frame = frame;
        starsView.hidden = YES;
        voteLabel.hidden = YES;
        numVotesLabel.hidden = YES;
        directorLabel.text = [Utilities getStringFromDictionary:item key:@"genre" emptyString:@"-"];
        genreLabel.text = [Utilities getStringFromDictionary:item key:@"style" emptyString:@"-"];
        genreLabel.numberOfLines = 0;
        CGSize maximunLabelSize = CGSizeMake(pageSize, 9999);
        CGRect expectedLabelRect = [genreLabel.text boundingRectWithSize:maximunLabelSize
                                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                                              attributes:@{NSFontAttributeName:genreLabel.font}
                                                                 context:nil];
        CGSize expectedLabelSize = expectedLabelRect.size;
        
        //adjust the label the the new height.
        CGRect newFrame = genreLabel.frame;
        newFrame.size.height = expectedLabelSize.height + size;
        genreLabel.frame = newFrame;
        [self moveLabel:@[label3, label4, label5, label6, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel] posY:-(expectedLabelSize.height - labelSpace)];
        
        studioLabel.text = [Utilities getStringFromDictionary:item key:@"born" emptyString:@"-"];
        NSString *formed = [Utilities getStringFromDictionary:item key:@"formed" emptyString:@"-"];
        studioLabel.text = [formed isEqualToString:@"-"] ? studioLabel.text : formed;
        
        if ([directorLabel.text isEqualToString:@"-"]) {
            directorLabel.hidden = YES;
            label1.hidden = YES;
            [self moveLabel:@[label2, label4, label5, label6, genreLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel] posY:labelSpace + 20];
        }
        if ([genreLabel.text isEqualToString:@"-"]) {
            genreLabel.hidden = YES;
            label2.hidden = YES;
            [self moveLabel:@[label4, label5, label6, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel] posY:labelSpace + 20];
        }
        if ([studioLabel.text isEqualToString:@"-"]) {
            studioLabel.hidden = YES;
            label4.hidden = YES;
            [self moveLabel:@[label5, label6, summaryLabel, parentalRatingLabelUp, parentalRatingLabel] posY:labelSpace + 20];
        }
    }
    else if ([item[@"family"] isEqualToString:@"broadcastid"] || [item[@"family"] isEqualToString:@"recordingid"]) {
        label1.text = LOCALIZED_STR(@"TIME");
        label5.text = LOCALIZED_STR(@"DESCRIPTION");
        [jewelView setAutoresizingMask:UIViewAutoresizingNone];
        [voteLabel setAutoresizingMask:UIViewAutoresizingNone];
        [numVotesLabel setAutoresizingMask:UIViewAutoresizingNone];
        coverView.hidden = YES;
        starsView.hidden = YES;
        label2.hidden = YES;
        label3.hidden = YES;
        label4.hidden = YES;
        genreLabel.hidden = YES;
        runtimeLabel.hidden = YES;
        studioLabel.hidden = YES;
        arrow_continue_down.hidden = YES;
        clearLogoHeight = 0;
        label6.frame = label5.frame;
//        label5.frame = label3.frame;
//        summaryLabel.frame = runtimeLabel.frame;
        label5.frame = label2.frame;
        CGRect frame = genreLabel.frame;
        if ([self.detailItem[@"plotoutline"] length] > 0) {
            label2.text = LOCALIZED_STR(@"PLOT OUTLINE");
            label2.hidden = NO;
            genreLabel.hidden = NO;
            [genreLabel setText:self.detailItem[@"plotoutline"]];
            label5.frame = label3.frame;
            frame = runtimeLabel.frame;
        }
        frame.origin.y ++;
        summaryLabel.frame = frame;
         [self moveLabel:@[label1, label2, label5, label6, directorLabel, genreLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel] posY:(int)(jewelView.frame.size.height - (jewelView.frame.size.height/8))];
        frame = jewelView.frame;
        frame.origin.x = label1.frame.origin.x;
        frame.size.width = frame.size.width / 4;
        frame.size.height = frame.size.height /8;
        jewelView.frame = frame;
        frame = voteLabel.frame;
        frame.origin.y = jewelView.frame.origin.y;
        frame.origin.x = jewelView.frame.origin.x + jewelView.frame.size.width + 8;
        frame.size.width = pageSize - frame.origin.x;
        frame.size.height = jewelView.frame.size.height / 2;
        voteLabel.frame = frame;
        voteLabel.numberOfLines = 2;
        [voteLabel setTextColor:directorLabel.textColor];
        frame = numVotesLabel.frame;
        frame.size.width = voteLabel.frame.size.width;
        frame.origin.y = (int)(voteLabel.frame.origin.y + voteLabel.frame.size.height + 10);
        frame.origin.x = voteLabel.frame.origin.x;
        numVotesLabel.frame = frame;
        if ([item[@"family"] isEqualToString:@"recordingid"]) {
            numVotesLabel.text = item[@"channel"];
        }
        else if ([item[@"family"] isEqualToString:@"broadcastid"]) {
            item[@"plot"] = item[@"genre"];
            numVotesLabel.text = item[@"pvrExtraInfo"][@"channel_name"];
            frame = voteLabel.frame;
            dotSize = 10;
            dotSizePadding = 4;
            isRecording = [[UIImageView alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y + (frame.size.height/2 - dotSize/2), dotSize, dotSize)];
            [isRecording setImage:[UIImage imageNamed:@"button_timer"]];
            [isRecording setContentMode:UIViewContentModeScaleAspectFill];
            isRecording.alpha = 0.0;
            [isRecording setBackgroundColor:[UIColor clearColor]];
            [scrollView addSubview:isRecording];
            if ([item[@"hastimer"] boolValue]) {
                isRecording.alpha = 1.0;
                frame.origin.x += dotSize + dotSizePadding;
                frame.size.width -= dotSize + dotSizePadding;
                [voteLabel setFrame:frame];
            }
        }
        // Be aware: "rating" is later used to display the label
        item[@"rating"] = item[@"label"];
        if (item[@"pvrExtraInfo"][@"channel_icon"] != nil) {
            item[@"thumbnail"] = item[@"pvrExtraInfo"][@"channel_icon"];
        }
        placeHolderImage = @"nocover_channels";
        NSDateFormatter *xbmcDateFormatter = [NSDateFormatter new];
        [xbmcDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
        NSDateFormatter *localFormatter = [NSDateFormatter new];
        [localFormatter setDateFormat:@"ccc dd MMM, HH:mm"];
        localFormatter.timeZone = [NSTimeZone systemTimeZone];
        NSDate *startTime = [xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", item[@"starttime"]]];
        NSDate *endTime = [xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", item[@"endtime"]]];
        if (startTime != nil && endTime != nil) {
            directorLabel.text = [localFormatter stringFromDate:startTime];
            [localFormatter setDateFormat:@"HH:mm"];
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSUInteger unitFlags = NSCalendarUnitMinute;
            NSDateComponents *components = [gregorian components:unitFlags fromDate:startTime toDate:endTime options:0];
            NSInteger minutes = [components minute];
            directorLabel.text = [NSString stringWithFormat:@"%@ - %@ (%ld %@)", directorLabel.text, [localFormatter stringFromDate:endTime], (long)minutes, (long)minutes > 1 ? LOCALIZED_STR(@"Mins.") : LOCALIZED_STR(@"Min")];
        }
        else {
            directorLabel.text = @"-";
        }
//        UIImage *buttonImage = [UIImage imageNamed:@"button_record"];
//        UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        recordButton.frame = CGRectMake(0, 0, 200, 29);
//        [recordButton setImage:buttonImage forState:UIControlStateNormal];
//        frame = recordButton.frame;
//        frame.origin.x = label2.frame.origin.x;
//        frame.origin.y = label2.frame.origin.y + 4;
//        recordButton.frame = frame;
//        [recordButton setTitle:LOCALIZED_STR(@"Record") forState:UIControlStateNormal];
//        [recordButton.titleLabel setFont:[UIFont fontWithName:directorLabel.font.fontName size:directorLabel.font.pointSize]];
//        [recordButton setTitleColor:label1.textColor forState:UIControlStateHighlighted];
//        recordButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
//        [recordButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
//        [recordButton setContentMode:UIViewContentModeScaleAspectFill];
//        recordButton.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
//        [scrollView addSubview:recordButton];
    }
    else {
        placeHolderImage = @"coverbox_back_movies";
        jeweltype = jewelTypeDVD;
        coverView.autoresizingMask = UIViewAutoresizingNone;
        coverView.contentMode = UIViewContentModeScaleToFill;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            int originalHeight = jewelView.frame.size.height;
            int coverHeight = 560;
            int coverWidth = STACKSCROLL_WIDTH;
            CGRect frame;
            frame = jewelView.frame;
            frame.origin.x = (self.view.frame.size.width - STACKSCROLL_WIDTH) / 2;
            frame.size.height = coverHeight;
            frame.size.width = coverWidth;
            jewelView.frame = frame;
            [self moveLabel:@[starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel] posY:-(coverHeight - originalHeight)];
        }
        directorLabel.text = [Utilities getStringFromDictionary:item key:@"director" emptyString:@"-"];
        directorLabel.text = [item[@"year"] length] == 0 ? directorLabel.text : [NSString stringWithFormat:@"%@ (%@)", directorLabel.text, item[@"year"]];
        genreLabel.text = [Utilities getStringFromDictionary:item key:@"genre" emptyString:@"-"];
        runtimeLabel.text = [Utilities getStringFromDictionary:item key:@"runtime" emptyString:@"-"];
        studioLabel.text = [Utilities getStringFromDictionary:item key:@"studio" emptyString:@"-"];
    }
    BOOL inEnableKenBurns = enableKenBurns;
    __weak ShowInfoViewController *sf = self;
    NSString *thumbnailPath = item[@"thumbnail"];
    if (![item[@"thumbnail"] isEqualToString:@""] && item[@"thumbnail"] != nil) {
        jewelView.alpha = 0;
        [activityIndicatorView startAnimating];
    }
    [[SDImageCache sharedImageCache] queryDiskCacheForKey:thumbnailPath done:^(UIImage *image, SDImageCacheType cacheType) {
        if (image != nil) {
            Utilities *utils = [Utilities new];
            UIColor *averageColor = [utils averageColor:image inverse:NO];
            foundTintColor = TINT_COLOR;
            CGFloat red, green, blue, alpha;
            [averageColor getRed:&red green:&green blue:&blue alpha:&alpha];
            if (alpha > 0) {
                foundTintColor = [utils lighterColorForColor:[utils averageColor:image inverse:NO]];
            }
            [self setIOS7barTintColor:foundTintColor];
            if (enableJewel) {
                coverView.image = image;
                coverView.frame = [Utilities createCoverInsideJewel:jewelView jewelType:jeweltype];
                [activityIndicatorView stopAnimating];
                jewelView.alpha = 1;
            }
            else {
                [NSThread detachNewThreadSelector:@selector(elaborateImage:) toTarget:self withObject:image];
            }
        }
        else {
            __weak ShowInfoViewController *sf = self;
            __block UIColor *newColor = nil;
            if (enableJewel) {
                [coverView setImageWithURL:[NSURL URLWithString:thumbnailPath]
                          placeholderImage:[UIImage imageNamed:placeHolderImage]
                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                     if (error == nil) {
                         if (image != nil) {
                             Utilities *utils = [Utilities new];
                             newColor = [utils lighterColorForColor:[utils averageColor:image inverse:NO]];
                             [sf setIOS7barTintColor:newColor];
                             foundTintColor = newColor;
                         }
                     }
                 }];
                coverView.frame = [Utilities createCoverInsideJewel:jewelView jewelType:jeweltype];
                [activityIndicatorView stopAnimating];
                jewelView.alpha = 1;
            }
            else {
                [jewelView setImageWithURL:[NSURL URLWithString:thumbnailPath]
                          placeholderImage:[UIImage imageNamed:placeHolderImage]
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                     if (image != nil) {
                                         if (error == nil) {
                                             Utilities *utils = [Utilities new];
                                             newColor = [utils lighterColorForColor:[utils averageColor:image inverse:NO]];
                                             [sf setIOS7barTintColor:newColor];
                                             foundTintColor = newColor;
                                         }
                                         [NSThread detachNewThreadSelector:@selector(elaborateImage:) toTarget:sf withObject:image];
                                     }
                                 }
                 ];
            }
        }
    }];
    
    NSString *fanartPath = item[@"fanart"];
    [[SDImageCache sharedImageCache] queryDiskCacheForKey:fanartPath done:^(UIImage *image, SDImageCacheType cacheType) {
        if (image != nil) {
            fanartView.image = image;
            if (inEnableKenBurns) {
                fanartView.alpha = 0;
                [sf elabKenBurns:image];
                [sf alphaView:sf.kenView AnimDuration:1.5 Alpha:0.2];
            }
        }
        else {
            [fanartView setImageWithURL:[NSURL URLWithString:fanartPath]
                       placeholderImage:[UIImage imageNamed:@"blank"]
                              completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                  if (inEnableKenBurns) {
                                      [sf elabKenBurns:image];
                                      [sf alphaView:sf.kenView AnimDuration:1.5 Alpha:0.2];
                                  }
                              }
             ];
        }
        
    }];

    [fanartView setClipsToBounds:YES];
    
    voteLabel.text = [Utilities getStringFromDictionary:item key:@"rating" emptyString:@"N.A."];
    starsView.image = [UIImage imageNamed:[NSString stringWithFormat:@"stars_%.0f", round([item[@"rating"] doubleValue])]];
    
    NSString *numVotes = [Utilities getStringFromDictionary:item key:@"votes" emptyString:@""];
    if ([numVotes length] != 0) {
        NSString *numVotesPlus = LOCALIZED_STR(([numVotes isEqualToString:@"1"]) ? @"vote" : @"votes");
        numVotesLabel.text = [NSString stringWithFormat:@"(%@ %@)", numVotes, numVotesPlus];
    }
    CGRect frame = summaryLabel.frame;
    summaryLabel.frame = frame;
    summaryLabel.text = [Utilities getStringFromDictionary:item key:@"plot" emptyString:@"-"];
    if ([item[@"family"] isEqualToString:@"albumid"] || [item[@"family"] isEqualToString:@"artistid"]) {
        summaryLabel.text = [Utilities getStringFromDictionary:item key:@"description" emptyString:@"-"];
    }
    CGSize maximunLabelSize = CGSizeMake(pageSize, 9999);
    CGRect expectedLabelRect = [summaryLabel.text  boundingRectWithSize:maximunLabelSize
                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                          attributes:@{NSFontAttributeName:summaryLabel.font}
                                                             context:nil];
    CGSize expectedLabelSize = expectedLabelRect.size;
    
    CGRect newFrame = summaryLabel.frame;
    newFrame.size.height = expectedLabelSize.height + size;
    summaryLabel.frame = newFrame;

    if ([item[@"mpaa"] length] == 0) {
        parentalRatingLabel.hidden = YES;
        parentalRatingLabelUp.hidden = YES;
    }
    else {
        frame = parentalRatingLabel.frame;
        frame.origin.y = frame.origin.y + summaryLabel.frame.size.height-20;
        parentalRatingLabel.frame = frame;
        
        frame = parentalRatingLabelUp.frame;
        frame.origin.y = frame.origin.y + summaryLabel.frame.size.height-20;
        parentalRatingLabelUp.frame = frame;
        
        frame = parentalRatingLabel.frame;
        frame.size.height = 2000;
        parentalRatingLabel.frame = frame;
        parentalRatingLabel.text = [Utilities getStringFromDictionary:item key:@"mpaa" emptyString:@"-"];
        
        CGRect expectedLabelRect = [parentalRatingLabel.text  boundingRectWithSize:maximunLabelSize
                                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                                 attributes:@{NSFontAttributeName:parentalRatingLabel.font}
                                                                    context:nil];
        CGSize expectedLabelSize = expectedLabelRect.size;
        
        newFrame = parentalRatingLabel.frame;
        newFrame.size.height = expectedLabelSize.height + size;
        parentalRatingLabel.frame = newFrame;
        shiftParentalRating = parentalRatingLabel.frame.size.height;
    }
    
    GlobalData *obj = [GlobalData getInstance];
    NSString *serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
    if ([AppDelegate instance].serverVersion > 11) {
        serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
    }
    frame = label6.frame;
    frame.origin.y = frame.origin.y + summaryLabel.frame.size.height + shiftParentalRating - 40;
    label6.frame = frame;
    int startY = label6.frame.origin.y - label6.frame.size.height + size;
    if ([item[@"trailer"] isKindOfClass:[NSString class]]) {
        if ([item[@"trailer"] length] > 0) {
            NSString *param = nil;
            embedVideoURL = nil;
            
            if (([item[@"trailer"] rangeOfString:@"plugin://plugin.video.youtube"].location != NSNotFound)) {
                NSString *url = [item[@"trailer"] lastPathComponent];
                NSRange start = [url rangeOfString:@"videoid="];
                if (start.location != NSNotFound) {
                    param = [url substringFromIndex:start.location + start.length];
                    NSRange end = [param rangeOfString:@"&"];
                    if (end.location != NSNotFound) {
                        param = [param substringToIndex:end.location];
                    }
                }
                if ([param length] > 0) {
                    NSString *param = nil;
                    NSString *url = [item[@"trailer"] lastPathComponent];
                    NSRange start = [url rangeOfString:@"videoid="];
                    if (start.location != NSNotFound) {
                        param = [url substringFromIndex:start.location + start.length];
                        NSRange end = [param rangeOfString:@"&"];
                        if (end.location != NSNotFound) {
                            param = [param substringToIndex:end.location];
                        }
                    }
                    embedVideoURL = [NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@", param];
                }
            }
            else {
                embedVideoURL = item[@"trailer"];
            }
            if (embedVideoURL != nil) {
                startY = startY + 20;
                UILabel *trailerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, startY, clearLogoWidth, label1.frame.size.height)];
                [trailerLabel setText:LOCALIZED_STR(@"TRAILER")];
                [trailerLabel setTextColor:label1.textColor];
                [trailerLabel setFont:label1.font];
                [trailerLabel setShadowColor:label1.shadowColor];
                [trailerLabel setShadowOffset:label1.shadowOffset];
                [trailerLabel setBackgroundColor:[UIColor clearColor]];
                [scrollView addSubview:trailerLabel];
                startY = startY + label1.frame.size.height;

                UIButton *playTrailerButton = [UIButton buttonWithType:UIButtonTypeCustom];
                UIImage *playTrailerImg = [UIImage imageNamed:@"button_play"];
                [playTrailerButton setImage:playTrailerImg forState:UIControlStateNormal];
                [playTrailerButton setFrame:CGRectMake(10, startY, PLAY_BUTTON_SIZE, PLAY_BUTTON_SIZE)];
                [playTrailerButton addTarget:self action:@selector(callbrowser:) forControlEvents:UIControlEventTouchUpInside];
                [playTrailerButton setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin];
                [scrollView addSubview:playTrailerButton];

                startY = startY + PLAY_BUTTON_SIZE - 10;
            }
        }
    }
    frame = label6.frame;
    frame.origin.y = startY + 20;
    label6.frame = frame;
    startY = startY + 16 + size + label6.frame.size.height;
    if (![item[@"family"] isEqualToString:@"albumid"]) {// TRANSFORM IN SHOW_CAST BOOLEAN
        cast = item[contributorString];
        if (actorsTable == nil) {
            int actorsTableWidth = self.view.frame.size.width;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                actorsTableWidth = pageSize + 40;
            }
            actorsTable = [[UITableView alloc] initWithFrame:CGRectMake(0, startY, actorsTableWidth, [cast count]*(castHeight + 10)) style:UITableViewStylePlain];
        }
        [actorsTable setScrollsToTop:NO];
        [actorsTable setBackgroundColor:[UIColor clearColor]];
        [actorsTable setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [actorsTable setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin];
        [actorsTable setDelegate:self];
        [actorsTable setDataSource:self];
        [scrollView addSubview:actorsTable];
        startY = startY + (int)[cast count]*(castHeight + 10);
        if ([cast count] == 0) {
            label6.hidden = YES;
            startY -= 20;
        }
    }
    if (!([item[@"family"] isEqualToString:@"broadcastid"] || [item[@"family"] isEqualToString:@"recordingid"])) {
        clearlogoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [clearlogoButton setFrame:CGRectMake(10, startY, clearLogoWidth, clearLogoHeight)];
        [clearlogoButton.titleLabel setShadowColor:[Utilities getGrayColor:0 alpha:0.8]];
        [clearlogoButton.titleLabel setShadowOffset:CGSizeMake(0, 1)];
        [clearlogoButton addTarget:self action:@selector(showBackground:) forControlEvents:UIControlEventTouchUpInside];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            [clearlogoButton setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        }
        if ([item[@"clearlogo"] length] != 0) {
            clearLogoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, clearLogoWidth, clearLogoHeight)];
            [[clearLogoImageView layer] setMinificationFilter:kCAFilterTrilinear];
            [clearLogoImageView setContentMode:UIViewContentModeScaleAspectFit];
            NSString *stringURL = [Utilities formatStringURL:item[@"clearlogo"] serverURL:serverURL];
            [clearLogoImageView setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:@"blank"]];
            [clearlogoButton addSubview:clearLogoImageView];
        }
        else {
            [clearlogoButton setTitle:[item[@"showtitle"] length] == 0 ? item[@"label"] : item[@"showtitle"] forState:UIControlStateNormal];
            [clearlogoButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        }
        [scrollView addSubview:clearlogoButton];
    }
    startY = startY + clearLogoHeight + 20;
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width, startY);
    
    // Check if the arrow needs to be displayed (only if content is > visible area)
    int height_content = scrollView.contentSize.height;
    int height_bounds = scrollView.bounds.size.height;
    int height_navbar = self.navigationController.navigationBar.frame.size.height + labelSpace;
    arrow_continue_down.hidden = (height_content <= height_bounds-height_navbar);
}

- (void)buildTrailerView {
    
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
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            if (![self isModal]) {
                [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollFullScreenDisabled" object:self.view userInfo:nil];
            }
            [UIView animateWithDuration:1.5
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 [toolbar setAlpha:1.0];
                             }
                             completion:^(BOOL finished) {}
             ];
        }
    }
    else {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
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
                                 self.kenView.alpha = 0;
                                 [toolbar setAlpha:0.0];
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
            [closeButton.titleLabel setShadowColor:[Utilities getGrayColor:0 alpha:0.8]];
            [closeButton.titleLabel setShadowOffset:CGSizeMake(0, 1)];
            [closeButton setAutoresizingMask:
             UIViewAutoresizingFlexibleTopMargin    |
             UIViewAutoresizingFlexibleRightMargin  |
             UIViewAutoresizingFlexibleLeftMargin   |
             UIViewAutoresizingFlexibleWidth
             ];
            if (clearLogoImageView.frame.size.width == 0) {
                [closeButton setTitle:clearlogoButton.titleLabel.text forState:UIControlStateNormal];
                [closeButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
            }
            else {
                [[closeButton.imageView layer] setMinificationFilter:kCAFilterTrilinear];
                [closeButton setImage:clearLogoImageView.image forState:UIControlStateNormal];
                [closeButton setImage:clearLogoImageView.image forState:UIControlStateHighlighted];
                [closeButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
            }
            [closeButton addTarget:self action:@selector(showBackground:) forControlEvents:UIControlEventTouchUpInside];
            closeButton.tag = 1;
            closeButton.alpha = 0;
            [self.view addSubview:closeButton];
        }
        [self alphaView:closeButton AnimDuration:1.5 Alpha:1];
    }
}

- (void)scrollViewDidScroll:(UIScrollView*)theScrollView {
    int height_content = theScrollView.contentSize.height;
    int height_bounds = theScrollView.bounds.size.height;
    int scrolled = theScrollView.contentOffset.y;
    bool at_bottom = scrolled >= height_content-height_bounds;
    if (!arrow_continue_down.hidden && at_bottom) {
        arrow_continue_down.hidden = YES;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:1];
        [UIView commitAnimations];
    }
    else if (arrow_continue_down.hidden && !at_bottom) {
        arrow_continue_down.hidden = NO;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:1];
        [UIView commitAnimations];
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
    return castHeight + 10;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return [cast count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *CellIdentifier = @"CellActor";
    ActorCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ActorCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier castWidth:castWidth castHeight:castHeight size:size castFontSize:castFontSize];
    }
    GlobalData *obj = [GlobalData getInstance];
    NSString *serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
    if ([AppDelegate instance].serverVersion > 11) {
        serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
    }
    NSString *stringURL = [Utilities formatStringURL:cast[indexPath.row][@"thumbnail"] serverURL:serverURL];
    [cell.actorThumbnail setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:@"person"] andResize:CGSizeMake(castWidth, castHeight)];
    cell.actorName.text = cast[indexPath.row][@"name"] == nil ? self.detailItem[@"label"] : cast[indexPath.row][@"name"];
    if ([cast[indexPath.row][@"role"] length] != 0) {
        cell.actorRole.text = [NSString stringWithFormat:@"%@", cast[indexPath.row][@"role"]];
        [cell.actorRole sizeToFit];
    }
    return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    if ([AppDelegate instance].serverVersion > 11 && ![self isModal]) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_arrow_right_selected"]];
        cell.accessoryView.alpha = 0.5;
    }
    else {
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    if ([AppDelegate instance].serverVersion > 11 && ![self isModal]) {
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

- (void)openWithVLC:(NSDictionary*)item {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [activityIndicatorView startAnimating];
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"vlc://"]]) {
        [activityIndicatorView stopAnimating];
        self.navigationItem.rightBarButtonItem.enabled = YES;
        UIAlertController *alertView = [Utilities createAlertOK:LOCALIZED_STR(@"VLC non installed") message:nil];
        [self presentViewController:alertView animated:YES completion:nil];
    }
    else {
        [[Utilities getJsonRPC] callMethod:@"Files.PrepareDownload" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:item[@"file"], @"path", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            if (error == nil && methodError == nil) {
                if ([methodResult count] > 0) {
                    GlobalData *obj = [GlobalData getInstance];
                    NSString *userPassword = [[AppDelegate instance].obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", [AppDelegate instance].obj.serverPass];
                    NSString *serverURL = [NSString stringWithFormat:@"%@%@@%@:%@", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
                    NSString *stringURL = [NSString stringWithFormat:@"vlc://%@://%@/%@", (NSArray*)methodResult[@"protocol"], serverURL, (NSDictionary*)methodResult[@"details"][@"path"]];
                    [Utilities SFloadURL:stringURL fromctrl:self];
                    [activityIndicatorView stopAnimating];
                    self.navigationItem.rightBarButtonItem.enabled = YES;
                }
            }
            else {
                [activityIndicatorView stopAnimating];
                self.navigationItem.rightBarButtonItem.enabled = YES;
            }
        }];
    }
}

- (void)addQueueAfterCurrent:(BOOL)afterCurrent {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    NSDictionary *item = self.detailItem;
    NSString *param = item[@"family"];
    id value = item[item[@"family"]];
    if ([self.detailItem[@"family"] isEqualToString:@"recordingid"]) {
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
                if ([self.detailItem[@"family"] isEqualToString:@"recordingid"]) {
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
    [touchOnKenView setNumberOfTapsRequired:1];
    [touchOnKenView setNumberOfTouchesRequired:1];
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
            NSMutableArray *items = [[toolbar items] mutableCopy];
            doneButton = [[UIBarButtonItem alloc] initWithTitle:LOCALIZED_STR(@"Done") style:UIBarButtonItemStyleDone target:self action:@selector(dismissModal:)];
            [items insertObject:doneButton atIndex:0];
            [toolbar setItems:items];
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
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleSwipeFromLeft:)
                                                 name: @"ECSLidingSwipeLeft"
                                               object: nil];
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
        [clearlogoButton setFrame:CGRectMake((int)(self.view.frame.size.width/2) - (int)(clearlogoButton.frame.size.width/2), clearlogoButton.frame.origin.y, clearlogoButton.frame.size.width, clearlogoButton.frame.size.height)];
        self.view.superview.backgroundColor = [UIColor clearColor];
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
    NSDictionary *httpHeaders = [AppDelegate instance].getServerHTTPHeaders;
    if (httpHeaders[@"Authorization"] != nil) {
        [manager setValue:httpHeaders[@"Authorization"] forHTTPHeaderField:@"Authorization"];
    }
    isViewDidLoad = YES;
    [label1 setText:LOCALIZED_STR(@"DIRECTED BY")];
    [label2 setText:LOCALIZED_STR(@"GENRE")];
    [label3 setText:LOCALIZED_STR(@"RUNTIME")];
    [label4 setText:LOCALIZED_STR(@"STUDIO")];
    [label5 setText:LOCALIZED_STR(@"SUMMARY")];
    [label6 setText:LOCALIZED_STR(@"CAST")];
    [parentalRatingLabelUp setText:LOCALIZED_STR(@"PARENTAL RATING")];
    fanartView.tag = 1;
    fanartView.userInteractionEnabled = YES;
    UITapGestureRecognizer *touchOnKenView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showBackground:)];
    [touchOnKenView setNumberOfTapsRequired:1];
    [touchOnKenView setNumberOfTouchesRequired:1];
    [fanartView addGestureRecognizer:touchOnKenView];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    CGFloat bottomPadding = 0;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        bottomPadding = window.safeAreaInsets.bottom;
    }
    CGRect frame = arrow_continue_down.frame;
    frame.origin.y -= bottomPadding;
    [arrow_continue_down setFrame:frame];
    arrow_continue_down.alpha = 0.5;
    [self disableScrollsToTopPropertyOnAllSubviewsOf:self.slidingViewController.view];
    scrollView.scrollsToTop = YES;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL kenBurns = NO;
    NSString *kenBurnsString = [userDefaults objectForKey:@"ken_preference"];
    if (kenBurnsString == nil || [kenBurnsString boolValue]) kenBurns = YES;
    enableKenBurns = kenBurns;
    self.kenView = nil;
    logoBackgroundMode = [Utilities getLogoBackgroundMode];
    [self configureView];
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
