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
#import "AppDelegate.h"
#import "DetailViewController.h"
#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"
#import "ActorCell.h"
#import "Utilities.h"
#import "VersionCheck.h"

@import QuartzCore;

#define PLAY_BUTTON_SIZE 40
#define TV_LOGO_SIZE_REC_DETAILS 72
#define TITLE_HEIGHT 44
#define LEFT_RIGHT_PADDING 10
#define VERTICAL_PADDING 10
#define LABEL_PADDING 10
#define LABEL_HEIGHT 20
#define REC_DOT_SIZE 10
#define REC_DOT_PADDING 4
#define SMALL_PADDING 4
#define ARROW_ALPHA 0.5
#define IPAD_NAVBAR_PADDING 20
#define FANART_FULLSCREEN_DISABLE 1
#define CLEARLOGO_FULLSCREEN_PADDING 20
#define DVD_HEIGHT_IPAD 560
#define DVD_HEIGHT_IPHONE 376
#define TV_HEIGHT_IPAD 280
#define TV_HEIGHT_IPHONE 200
#define CD_HEIGHT_IPAD 380
#define CD_HEIGHT_IPHONE 290

@interface ShowInfoViewController ()

@end

@implementation ShowInfoViewController

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

- (void)configureView {
    if (self.detailItem) {
        NSMutableDictionary *item = self.detailItem;
        sheetActions = [@[LOCALIZED_STR(@"Queue after current"),
                          LOCALIZED_STR(@"Queue"),
                          LOCALIZED_STR(@"Play"),
                        ] mutableCopy];
        NSDictionary *resumePointDict = item[@"resume"];
        if (resumePointDict && [resumePointDict isKindOfClass:[NSDictionary class]]) {
            float position = [Utilities getFloatValueFromItem:resumePointDict[@"position"]];
            float total = [Utilities getFloatValueFromItem:resumePointDict[@"total"]];
            if (position > 0 && total > 0 && [VersionCheck hasPlayerOpenOptions]) {
                [sheetActions addObject:LOCALIZED_STR_ARGS(@"Resume from %@", [Utilities convertTimeFromSeconds:@(position)])];
            }
        }
        BOOL fromAlbumView = NO;
        if (item[@"fromAlbumView"] != [NSNull null]) {
            fromAlbumView = [item[@"fromAlbumView"] boolValue];
        }
        BOOL fromEpisodesView = NO;
        if (item[@"fromEpisodesView"] != [NSNull null]) {
            fromEpisodesView = [item[@"fromEpisodesView"] boolValue];
        }
        
        actionSheetButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(showActionSheet)];
        extraButton = nil;
        if ([item[@"family"] isEqualToString:@"albumid"]) {
            UIImage *extraButtonImg = [UIImage imageNamed:@"st_songs"];
            if (fromAlbumView) {
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
            }
            else {
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(showContent:)];
            }
        }
        else if ([item[@"family"] isEqualToString:@"artistid"]) {
            UIImage *extraButtonImg = [UIImage imageNamed:@"st_album"];
            extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(showContent:)];
        }
        else if ([item[@"family"] isEqualToString:@"tvshowid"]) {
            actionSheetButtonItem = nil;
            UIImage *extraButtonImg = [UIImage imageNamed:@"st_tv"];
            if (fromEpisodesView) {
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
            }
            else {
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(showContent:)];
            }
        }
        else if ([item[@"family"] isEqualToString:@"setid"]) {
            actionSheetButtonItem = nil;
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
            viewTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, TITLE_HEIGHT)];
            viewTitle.backgroundColor = UIColor.clearColor;
            viewTitle.textAlignment = NSTextAlignmentLeft;
            viewTitle.textColor = UIColor.whiteColor;
            viewTitle.text = item[@"label"];
            viewTitle.numberOfLines = 1;
            viewTitle.font = [UIFont boldSystemFontOfSize:22];
            viewTitle.minimumScaleFactor = FONT_SCALING_DEFAULT;
            viewTitle.adjustsFontSizeToFitWidth = YES;
            viewTitle.shadowOffset = CGSizeMake(1, 1);
            viewTitle.shadowColor = FONT_SHADOW_WEAK;
            viewTitle.autoresizingMask = UIViewAutoresizingNone;
            viewTitle.contentMode = UIViewContentModeScaleAspectFill;
            [viewTitle sizeThatFits:viewTitle.frame.size];
            UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithCustomView:viewTitle];
            
            // Spacing items for alignment and desired left/right padding
            UIBarButtonItem *spaceFlex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            UIView *paddingViewLeft = [[UIView alloc] initWithFrame:CGRectMake(0, 0, IPAD_NAVBAR_PADDING, TITLE_HEIGHT)];
            UIBarButtonItem *spaceFixedLeft = [[UIBarButtonItem alloc] initWithCustomView:paddingViewLeft];
            UIView *paddingViewRight = [[UIView alloc] initWithFrame:CGRectMake(0, 0, IPAD_NAVBAR_PADDING, TITLE_HEIGHT)];
            UIBarButtonItem *spaceFixedRight = [[UIBarButtonItem alloc] initWithCustomView:paddingViewRight];
            
            // An "undo" fixed space with negative width is needed to remove automatic padding by some iOS versioms
            UIBarButtonItem *spaceUndo = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            spaceUndo.width = -1;
            
            // Build the toolbar (fixed space, title, flex space, button1, button2, fixed space)
            NSMutableArray *items = [@[spaceUndo, spaceFixedLeft, title] mutableCopy];
            if (extraButton || actionSheetButtonItem) {
                [items addObject:spaceFlex];
                if (extraButton) {
                    [items addObject:extraButton];
                }
                if (actionSheetButtonItem) {
                    [items addObject:actionSheetButtonItem];
                }
            }
            [items addObject:spaceFixedRight];
            [items addObject:spaceUndo];
            
            toolbar = [UIToolbar new];
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
            // Transparent toolbar
            [Utilities createTransparentToolbar:toolbar];
            [self.view addSubview:toolbar];
            
            effectView = [[UIVisualEffectView alloc] initWithFrame:toolbar.frame];
            effectView.autoresizingMask = toolbar.autoresizingMask;
            effectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            [self.view insertSubview:effectView belowSubview:toolbar];
            
            scrollView.contentInset = UIEdgeInsetsMake(toolbarHeight, 0, 0, 0);
        }
        else {
            self.navigationItem.title = item[@"label"];
            if (actionSheetButtonItem && extraButton) {
                self.navigationItem.rightBarButtonItems = @[actionSheetButtonItem, extraButton];
            }
            else if (actionSheetButtonItem) {
                self.navigationItem.rightBarButtonItems = @[actionSheetButtonItem];
            }
            else if (extraButton) {
                self.navigationItem.rightBarButtonItems = @[extraButton];
            }
        }
        // Place the up and down arrows. Keep them invisible for now.
        CGFloat bottomPadding = [Utilities getBottomPadding];
        [arrow_continue_down offsetY:-bottomPadding];
        arrow_continue_down.alpha = 0;
        [arrow_back_up offsetY:scrollView.contentInset.top];
        arrow_back_up.alpha = 0;
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
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationEnableStackPan" object:nil];
    }
}

#pragma mark - ToolBar button

- (void)showContent:(id)sender {
    NSDictionary *item = self.detailItem;
    mainMenu *menuItem = nil;
    mainMenu *chosenMenuItem = nil;
    int activeTab = 0;
    id movieObj = nil;
    id movieObjKey = nil;
    if ([item[@"family"] isEqualToString:@"albumid"]) {
        notificationName = @"MainMenuDeselectSection";
        menuItem = [AppDelegate.instance.playlistArtistAlbums copy];
        chosenMenuItem = menuItem.subItem;
        chosenMenuItem.mainLabel = [NSString stringWithFormat:@"%@", item[@"label"]];
    }
    else if ([item[@"family"] isEqualToString:@"tvshowid"] && ![sender isKindOfClass:[NSString class]]) {
        notificationName = @"MainMenuDeselectSection";
        menuItem = [AppDelegate.instance.playlistTvShows copy];
        chosenMenuItem = menuItem.subItem;
        chosenMenuItem.mainLabel = [NSString stringWithFormat:@"%@", item[@"label"]];
    }
    else if ([item[@"family"] isEqualToString:@"artistid"]) {
        notificationName = @"MainMenuDeselectSection";
        activeTab = 1;
        menuItem = [AppDelegate.instance.playlistArtistAlbums copy];
        chosenMenuItem = menuItem.subItem;
        chosenMenuItem.mainLabel = [NSString stringWithFormat:@"%@", item[@"label"]];
    }
    else if ([item[@"family"] isEqualToString:@"movieid"] && AppDelegate.instance.serverVersion > 11) {
        if ([sender isKindOfClass:[NSString class]]) {
            NSString *actorName = (NSString*)sender;
            activeTab = 2;
            menuItem = [AppDelegate.instance.playlistMovies copy];
            movieObj = [NSDictionary dictionaryWithObjectsAndKeys:actorName, @"actor", nil];
            movieObjKey = @"filter";
            chosenMenuItem = menuItem.subItem;
            chosenMenuItem.mainLabel = actorName;
        }
    }
    else if (([item[@"family"] isEqualToString:@"episodeid"] || [item[@"family"] isEqualToString:@"tvshowid"]) && AppDelegate.instance.serverVersion > 11) {
        if ([sender isKindOfClass:[NSString class]]) {
            NSString *actorName = (NSString*)sender;
            activeTab = 0;
            menuItem = [AppDelegate.instance.playlistTvShows copy];
            movieObj = [NSDictionary dictionaryWithObjectsAndKeys:actorName, @"actor", nil];
            movieObjKey = @"filter";
            chosenMenuItem = menuItem;
            chosenMenuItem.mainLabel = actorName;
            menuItem.enableSection = NO;
            menuItem.mainButtons = nil;
            if ([Utilities getPreferTvPosterMode]) {
                thumbWidth = PHONE_TV_SHOWS_POSTER_WIDTH;
                tvshowHeight = PHONE_TV_SHOWS_POSTER_HEIGHT;
            }
            menuItem.thumbWidth = thumbWidth;
            menuItem.rowHeight = tvshowHeight;
        }
    }
    else {
        return;
    }
    NSDictionary *methods = chosenMenuItem.mainMethod[activeTab];
    if (methods[@"method"] != nil) { // THERE IS A CHILD
        NSDictionary *mainFields = menuItem.mainFields[activeTab];
        NSMutableDictionary *parameters = chosenMenuItem.mainParameters[activeTab];
        id objKey = mainFields[@"row6"];
        id obj = [Utilities getNumberFromItem:item[objKey]];
        if (movieObj != nil && movieObjKey != nil) {
            obj = movieObj;
            objKey = movieObjKey;
        }
        else if (AppDelegate.instance.serverVersion > 11 && ![parameters[@"disableFilterParameter"] boolValue]) {
            obj = [NSDictionary dictionaryWithObjectsAndKeys:obj, objKey, nil];
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
        NSMutableDictionary *newParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                              [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                               obj, objKey,
                                               parameters[@"parameters"][@"properties"], @"properties",
                                               parameters[@"parameters"][@"sort"], @"sort",
                                               nil], @"parameters",
                                              parameters[@"label"], @"label",
                                              @YES, @"fromShowInfo",
                                              @([parameters[@"enableCollectionView"] boolValue]), @"enableCollectionView",
                                              [NSDictionary dictionaryWithDictionary:parameters[@"itemSizes"]], @"itemSizes",
                                              parameters[@"extra_info_parameters"], @"extra_info_parameters",
                                              @([parameters[@"FrodoExtraArt"] boolValue]), @"FrodoExtraArt",
                                              @([parameters[@"enableLibraryCache"] boolValue]), @"enableLibraryCache",
                                              @([parameters[@"collectionViewRecentlyAdded"] boolValue]), @"collectionViewRecentlyAdded",
                                              newSectionParameters, @"extra_section_parameters",
                                              nil];
        chosenMenuItem.mainParameters[activeTab] = newParameters;
        chosenMenuItem.chooseTab = activeTab;
        if (IS_IPHONE) {
            DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
            detailViewController.detailItem = chosenMenuItem;
            [self.navigationController pushViewController:detailViewController animated:YES];
        }
        else {
            if (![self isModal]) {
                DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:chosenMenuItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:NO];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
            }
            else {
                DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:chosenMenuItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                iPadDetailViewController.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:iPadDetailViewController animated:YES completion:nil];
            }
        }
    }
}

#pragma mark - ActionSheet

- (void)showActionSheet {
    if (sheetActions.count) {
        NSDictionary *item = self.detailItem;
        NSString *sheetTitle = item[@"label"];
        if ([item[@"family"] isEqualToString:@"broadcastid"]) {
            sheetTitle = item[@"pvrExtraInfo"][@"channel_name"];
        }
        
        UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:sheetTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *action_cancel = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
        
        for (NSString *actionName in sheetActions) {
            NSString *actiontitle = actionName;
            UIAlertAction *action = [UIAlertAction actionWithTitle:actiontitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self actionSheetHandler:actiontitle];
            }];
            [alertCtrl addAction:action];
        }
        [alertCtrl addAction:action_cancel];
        alertCtrl.modalPresentationStyle = UIModalPresentationPopover;
        
        UIPopoverPresentationController *popPresenter = [alertCtrl popoverPresentationController];
        if (popPresenter != nil) {
            popPresenter.sourceView = self.view;
            popPresenter.barButtonItem = actionSheetButtonItem;
        }
        [self presentViewController:alertCtrl animated:YES completion:nil];
    }
}

- (void)actionSheetHandler:(NSString*)actiontitle {
    NSString *resumeKey = [LOCALIZED_STR(@"Resume from %@") stringByReplacingOccurrencesOfString:@"%@" withString:@""];
    if ([actiontitle isEqualToString:LOCALIZED_STR(@"Queue after current")]) {
        [self addQueueAfterCurrent:YES];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Queue")]) {
        [self addQueueAfterCurrent:NO];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Play")]) {
        [self startPlayback:NO];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Record")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Stop Recording")]) {
        [self recordChannel];
    }
    else if ([actiontitle rangeOfString:resumeKey].location != NSNotFound) {
        [self startPlayback:YES];
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Play Trailer")]) {
        NSDictionary *itemParams = @{
            @"item": [NSDictionary dictionaryWithObjectsAndKeys:self.detailItem[@"trailer"], @"file", nil],
        };
        [self openFile:itemParams];
    }
}

- (void)animateRecordAction {
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
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
                     completion:nil];
}

- (void)recordChannel {
    NSDictionary *item = self.detailItem;
    NSNumber *channelid = [Utilities getNumberFromItem:item[@"pvrExtraInfo"][@"channelid"]];
    if ([channelid longValue] == 0) {
        return;
    }
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
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [activityIndicatorView startAnimating];
    NSDictionary *parameters = @{parameterName: itemid};
    [[Utilities getJsonRPC] callMethod:methodToCall
         withParameters:parameters
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
               [activityIndicatorView stopAnimating];
               self.navigationItem.rightBarButtonItem.enabled = YES;
               if (error == nil && methodError == nil) {
                   [self animateRecordAction];
                   NSNumber *status = @(![item[@"isrecording"] boolValue]);
                   if ([item[@"broadcastid"] longLongValue] > 0) {
                       status = @(![item[@"hastimer"] boolValue]);
                   }
                   NSDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           storeChannelid, @"channelid",
                                           storeBroadcastid, @"broadcastid",
                                           status, @"status",
                                           nil];
                   [[NSNotificationCenter defaultCenter] postNotificationName:@"KodiServerRecordTimerStatusChange" object:nil userInfo:params];
               }
               else {
                   NSString *message = [Utilities formatClipboardMessage:methodToCall
                                                              parameters:parameters
                                                                   error:error
                                                             methodError:methodError];
                   UIAlertController *alertCtrl = [Utilities createAlertCopyClipboard:LOCALIZED_STR(@"ERROR") message:message];
                   [self presentViewController:alertCtrl animated:YES completion:nil];
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
    int bottom_scroll = MAX(height_content - height_bounds, -scrollView.contentInset.top);
    CGPoint bottomOffset = CGPointMake(0, bottom_scroll);
    [scrollView setContentOffset:bottomOffset animated:YES];
}

- (void)showNowPlaying {
    NowPlaying *nowPlaying = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
    nowPlaying.detailItem = self.detailItem;
    [self.navigationController pushViewController:nowPlaying animated:YES];
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (BOOL)enableJewelCases {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:@"jewel_preference"];
}

- (void)elaborateImage:(UIImage*)image fallbackImage:(UIImage*)fallback {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showImage:image fallbackImage:fallback];
    });
}

- (void)showImage:(UIImage*)image fallbackImage:(UIImage*)fallback {
    [activityIndicatorView stopAnimating];
    UIImage *imageToShow = image != nil ? image : fallback;
    if (isPvrDetail) {
        CGRect frame;
        frame.size.width = ceil(TV_LOGO_SIZE_REC_DETAILS * 0.9);
        frame.size.height = ceil(TV_LOGO_SIZE_REC_DETAILS * 0.7);
        frame.origin.x = coverView.frame.origin.x + (coverView.frame.size.width - frame.size.width) / 2;
        frame.origin.y = coverView.frame.origin.y + SMALL_PADDING;
        coverView.frame = frame;
        
        // Ensure we draw the rounded edges around TV station logo view
        coverView.image = imageToShow;
        [Utilities applyRoundedEdgesView:coverView];
        
        // Choose correct background color for station logos
        if (image != nil) {
            [Utilities setLogoBackgroundColor:coverView mode:logoBackgroundMode];
        }
    }
    else {
        // Ensure we draw the rounded edges around thumbnail images
        coverView.image = [Utilities applyRoundedEdgesImage:imageToShow];
    }
    [coverView animateAlpha:1.0 duration:0.1];
}

- (void)setIOS7barTintColor:(UIColor*)tintColor {
    self.navigationController.navigationBar.tintColor = tintColor;
    toolbar.tintColor = tintColor;
}

- (void)createInfo {
    // Use mainLabel0 to check, if the info view already has been created
    if (mainLabel0) {
        return;
    }
    // NEED TO BE OPTIMIZED. IT WORKS BUT THERE ARE TOO MANY IFS!
    NSMutableDictionary *item = self.detailItem;
    NSString *placeHolderImage = @"coverbox_back";
    isPvrDetail = item[@"recordingid"] != nil || item[@"broadcastid"] != nil;
    JewelType jeweltype = JewelTypeUnknown;
    NSString *jewelImg = @"";
    lineSpacing = IS_IPAD ? 2 : 0;
    castFontSize = IS_IPAD ? 16 : 14;
    
    // Cast use dimension of 2:3 as per Kodi specification
    castWidth = IS_IPAD ? 70 : 46;
    castHeight = IS_IPAD ? 105 : 69;
    
    // ClearLogo uses dimension of 80:31 as per Kodi specification
    clearLogoWidth = self.view.frame.size.width - LEFT_RIGHT_PADDING * 2;
    clearLogoHeight = ceil(clearLogoWidth * 31.0 / 80.0);
    
    bool enableJewel = [self enableJewelCases];
    
    CGFloat transform = [Utilities getTransformX];
    NSString *contributorString = @"cast";
    if (IS_IPAD) {
        thumbWidth = (int)(PAD_TV_SHOWS_BANNER_WIDTH * transform);
        tvshowHeight = (int)(PAD_TV_SHOWS_BANNER_HEIGHT * transform);
        
        CGRect frame = starsView.frame;
        frame.origin.y -= lineSpacing;
        frame.size.height += lineSpacing * 2;
        starsView.frame = frame;
        
        [voteLabel offsetY:-lineSpacing];
    }
    else {
        thumbWidth = (int)(PHONE_TV_SHOWS_BANNER_WIDTH * transform);
        tvshowHeight = (int)(PHONE_TV_SHOWS_BANNER_HEIGHT * transform);
    }
    
    mainLabel0 = [self createMainLabel];
    mainLabel1 = [self createMainLabel];
    mainLabel2 = [self createMainLabel];
    mainLabel3 = [self createMainLabel];
    mainLabel4 = [self createMainLabel];
    mainLabel5 = [self createMainLabel];
    parentalRatingMainLabel = [self createMainLabel];
    castMainLabel = [self createMainLabel];
    
    subLabel0 = [self createSubLabel];
    subLabel1 = [self createSubLabel];
    subLabel2 = [self createSubLabel];
    subLabel3 = [self createSubLabel];
    subLabel4 = [self createSubLabel];
    subLabel5 = [self createSubLabel];
    parentalRatingSubLabel = [self createSubLabel];
    
    if ([item[@"family"] isEqualToString:@"tvshowid"]) {
        placeHolderImage = @"nocover_tvshows_wall";
        
        mainLabel1.text = LOCALIZED_STR(@"EPISODES");
        mainLabel2.text = LOCALIZED_STR(@"FIRST AIRED");
        mainLabel3.text = LOCALIZED_STR(@"GENRE");
        mainLabel4.text = LOCALIZED_STR(@"STUDIO");
        mainLabel5.text = LOCALIZED_STR(@"SUMMARY");
        castMainLabel.text = LOCALIZED_STR(@"CAST");
        parentalRatingMainLabel.text = LOCALIZED_STR(@"PARENTAL RATING");
        subLabel1.text = [Utilities getStringFromItem:item[@"episode"]];
        subLabel2.text = [Utilities getDateFromItem:item[@"premiered"] dateStyle:NSDateFormatterLongStyle];
        subLabel3.text = [Utilities getStringFromItem:item[@"genre"]];
        subLabel4.text = [Utilities getStringFromItem:item[@"studio"]];
        subLabel5.text = [Utilities getStringFromItem:item[@"plot"]];

        jewelImg = @"jewel_dvd.9";
        jeweltype = JewelTypeDVD;
        int coverHeight = IS_IPAD ? DVD_HEIGHT_IPAD : DVD_HEIGHT_IPHONE;
        [jewelView setHeight:coverHeight];
        
        coverView.autoresizingMask = UIViewAutoresizingNone;
        coverView.contentMode = UIViewContentModeScaleAspectFill;
    }
    else if ([item[@"family"] isEqualToString:@"episodeid"]) {
        placeHolderImage = @"nocover_tvshows_episode_wall";
        
        mainLabel0.text = LOCALIZED_STR(@"TV SHOW");
        mainLabel1.text = LOCALIZED_STR(@"FIRST AIRED");
        mainLabel2.text = LOCALIZED_STR(@"DIRECTOR");
        mainLabel3.text = LOCALIZED_STR(@"RUNTIME");
        mainLabel4.text = LOCALIZED_STR(@"WRITER");
        mainLabel5.text = LOCALIZED_STR(@"SUMMARY");
        castMainLabel.text = LOCALIZED_STR(@"CAST");
        parentalRatingMainLabel.text = LOCALIZED_STR(@"PARENTAL RATING");
        subLabel0.text = [Utilities formatTVShowStringForSeasonTrailing:item[@"season"] episode:item[@"episode"] title:item[@"showtitle"]];
        subLabel1.text = [Utilities getDateFromItem:item[@"firstaired"] dateStyle:NSDateFormatterLongStyle];
        subLabel2.text = [Utilities getStringFromItem:item[@"director"]];
        subLabel3.text = [Utilities getStringFromItem:item[@"runtime"]];
        subLabel4.text = [Utilities getStringFromItem:item[@"writer"]];
        subLabel5.text = [Utilities getStringFromItem:item[@"plot"]];
        
        parentalRatingMainLabel.hidden = YES;
        parentalRatingSubLabel.hidden = YES;
        jewelView.hidden = NO;
        
        jewelImg = @"jewel_tv.9";
        jeweltype = JewelTypeTV;
        int coverHeight = IS_IPAD ? TV_HEIGHT_IPAD : TV_HEIGHT_IPHONE;
        [jewelView setHeight:coverHeight];
        
        coverView.autoresizingMask = UIViewAutoresizingNone;
        coverView.contentMode = UIViewContentModeScaleAspectFill;
    }
    else if ([item[@"family"] isEqualToString:@"albumid"]) {
        placeHolderImage = @"coverbox_back";
        
        mainLabel1.text = LOCALIZED_STR(@"ARTIST");
        mainLabel2.text = LOCALIZED_STR(@"YEAR");
        mainLabel3.text = LOCALIZED_STR(@"GENRE");
        mainLabel4.text = LOCALIZED_STR(@"ALBUM LABEL");
        mainLabel5.text = LOCALIZED_STR(@"DESCRIPTION");
        castMainLabel.text = @"";
        parentalRatingMainLabel.text = LOCALIZED_STR(@"PARENTAL RATING");
        subLabel1.text = [Utilities getStringFromItem:item[@"artist"]];
        subLabel2.text = [Utilities getStringFromItem:item[@"year"]];
        subLabel3.text = [Utilities getStringFromItem:item[@"genre"]];
        subLabel4.text = [Utilities getStringFromItem:item[@"label"]];
        subLabel5.text = [Utilities getStringFromItem:item[@"description"]];
        
        starsView.hidden = YES;
        voteLabel.hidden = YES;
        numVotesLabel.hidden = YES;
        parentalRatingMainLabel.hidden = YES;
        parentalRatingSubLabel.hidden = YES;
        jewelView.hidden = NO;
        
        jewelImg = @"jewel_cd.9";
        jeweltype = JewelTypeCD;
        int coverHeight = IS_IPAD ? CD_HEIGHT_IPAD : CD_HEIGHT_IPHONE;
        [jewelView setHeight:coverHeight];
    }
    else if ([item[@"family"] isEqualToString:@"musicvideoid"]) {
        placeHolderImage = @"nocover_musicvideos_wall";
        
        NSString *director = [Utilities getStringFromItem:item[@"director"]];
        NSString *year = [Utilities getYearFromItem:item[@"year"]];
        
        mainLabel0.text = LOCALIZED_STR(@"ARTIST");
        mainLabel1.text = LOCALIZED_STR(@"GENRE");
        mainLabel2.text = [self formatDirectorYearHeading:director year:year];
        mainLabel3.text = LOCALIZED_STR(@"RUNTIME");
        mainLabel4.text = LOCALIZED_STR(@"STUDIO");
        mainLabel5.text = LOCALIZED_STR(@"SUMMARY");
        castMainLabel.text = @"";
        parentalRatingMainLabel.text = LOCALIZED_STR(@"PARENTAL RATING");
        subLabel0.text = [Utilities getStringFromItem:item[@"artist"]];
        subLabel1.text = [Utilities getStringFromItem:item[@"genre"]];
        subLabel2.text = [self formatDirectorYear:director year:year];
        subLabel3.text = [Utilities getStringFromItem:item[@"runtime"]];
        subLabel4.text = [Utilities getStringFromItem:item[@"studio"]];
        subLabel5.text = [Utilities getStringFromItem:item[@"plot"]];
        
        jewelImg = @"jewel_cd.9";
        jeweltype = JewelTypeCD;
        int coverHeight = IS_IPAD ? CD_HEIGHT_IPAD : CD_HEIGHT_IPHONE;
        [jewelView setHeight:coverHeight];
    }
    else if ([item[@"family"] isEqualToString:@"artistid"]) {
        placeHolderImage = @"nocover_artist_wall";
        contributorString = @"roles";
        
        mainLabel1.text = LOCALIZED_STR(@"GENRE");
        mainLabel2.text = LOCALIZED_STR(@"STYLE");
        mainLabel3.text = @"";
        mainLabel4.text = LOCALIZED_STR(@"BORN / FORMED");
        mainLabel5.text = LOCALIZED_STR(@"DESCRIPTION");
        castMainLabel.text = LOCALIZED_STR(@"MUSIC ROLES");
        parentalRatingMainLabel.text = LOCALIZED_STR(@"PARENTAL RATING");
        subLabel1.text = [Utilities getStringFromItem:item[@"genre"]];
        subLabel2.text = [Utilities getStringFromItem:item[@"style"]];
        subLabel5.text = [Utilities getStringFromItem:item[@"description"]];
        NSString *born = [Utilities getStringFromItem:item[@"born"]];
        NSString *formed = [Utilities getStringFromItem:item[@"formed"]];
        subLabel4.text = formed.length ? formed : born;
        
        parentalRatingMainLabel.hidden = YES;
        parentalRatingSubLabel.hidden = YES;
        subLabel3.hidden = YES;
        mainLabel3.hidden = YES;
        starsView.hidden = YES;
        voteLabel.hidden = YES;
        numVotesLabel.hidden = YES;
        
        enableJewel = NO;
    }
    else if ([item[@"family"] isEqualToString:@"recordingid"]) {
        placeHolderImage = @"nocover_channels_wall";
        
        // Be aware: "rating" is later used to display the label
        item[@"rating"] = item[@"label"];
        if (item[@"pvrExtraInfo"][@"channel_icon"] != nil) {
            item[@"thumbnail"] = item[@"pvrExtraInfo"][@"channel_icon"];
        }
        item[@"genre"] = [item[@"plotoutline"] length] > 0 ? item[@"plotoutline"] : item[@"genre"];
        
        mainLabel1.text = LOCALIZED_STR(@"TIME");
        mainLabel2.text = LOCALIZED_STR(@"DESCRIPTION");
        mainLabel3.text = @"";
        mainLabel4.text = @"";
        mainLabel5.text = LOCALIZED_STR(@"SUMMARY");
        castMainLabel.text = @"";
        parentalRatingMainLabel.text = LOCALIZED_STR(@"PARENTAL RATING");
        subLabel1.text = [self formatBroadcastTime:item];
        subLabel2.text = [Utilities getStringFromItem:item[@"genre"]];
        numVotesLabel.text = item[@"channel"];
        subLabel5.text = [Utilities getStringFromItem:item[@"plot"]];
        
        starsView.hidden = YES;
        mainLabel3.hidden = YES;
        mainLabel4.hidden = YES;
        castMainLabel.hidden = YES;
        subLabel3.hidden = YES;
        subLabel4.hidden = YES;
        arrow_continue_down.alpha = 0;
        arrow_back_up.alpha = 0;
        enableJewel = NO;
        
        [self layoutPvrDetails];
    }
    else if ([item[@"family"] isEqualToString:@"broadcastid"]) {
        placeHolderImage = @"nocover_channels_wall";
        
        // Be aware: "rating" is later used to display the label
        item[@"rating"] = item[@"label"];
        if (item[@"pvrExtraInfo"][@"channel_icon"] != nil) {
            item[@"thumbnail"] = item[@"pvrExtraInfo"][@"channel_icon"];
        }
        
        mainLabel1.text = LOCALIZED_STR(@"TIME");
        mainLabel2.text = LOCALIZED_STR(@"DESCRIPTION");
        mainLabel3.text = @"";
        mainLabel4.text = @"";
        mainLabel5.text = LOCALIZED_STR(@"SUMMARY");
        castMainLabel.text = @"";
        parentalRatingMainLabel.text = LOCALIZED_STR(@"PARENTAL RATING");
        subLabel1.text = [self formatBroadcastTime:item];
        subLabel2.text = [Utilities getStringFromItem:item[@"plotoutline"]];
        numVotesLabel.text = item[@"pvrExtraInfo"][@"channel_name"];
        subLabel5.text = [Utilities getStringFromItem:item[@"genre"]];
        
        starsView.hidden = YES;
        mainLabel3.hidden = YES;
        mainLabel4.hidden = YES;
        castMainLabel.hidden = YES;
        subLabel3.hidden = YES;
        subLabel4.hidden = YES;
        arrow_continue_down.alpha = 0;
        arrow_back_up.alpha = 0;
        enableJewel = NO;
    
        [self layoutPvrDetails];
        [self processRecordingTimerFromItem:item];
    }
    else {
        placeHolderImage = @"nocover_movies_wall";
        
        NSString *director = [Utilities getStringFromItem:item[@"director"]];
        NSString *year = [Utilities getYearFromItem:item[@"year"]];
        
        mainLabel0.text = LOCALIZED_STR(@"TAGLINE");
        mainLabel1.text = [self formatDirectorYearHeading:director year:year];
        mainLabel2.text = LOCALIZED_STR(@"GENRE");
        mainLabel3.text = LOCALIZED_STR(@"RUNTIME");
        mainLabel4.text = LOCALIZED_STR(@"STUDIO");
        mainLabel5.text = LOCALIZED_STR(@"SUMMARY");
        castMainLabel.text = LOCALIZED_STR(@"CAST");
        parentalRatingMainLabel.text = LOCALIZED_STR(@"PARENTAL RATING");
        subLabel0.text = [Utilities getStringFromItem:item[@"tagline"]];
        subLabel1.text = [self formatDirectorYear:director year:year];
        subLabel2.text = [Utilities getStringFromItem:item[@"genre"]];
        subLabel3.text = [Utilities getStringFromItem:item[@"runtime"]];
        subLabel4.text = [Utilities getStringFromItem:item[@"studio"]];
        subLabel5.text = [Utilities getStringFromItem:item[@"plot"]];
        
        jewelImg = @"jewel_dvd.9";
        jeweltype = JewelTypeDVD;
        int coverHeight = IS_IPAD ? DVD_HEIGHT_IPAD : DVD_HEIGHT_IPHONE;
        [jewelView setHeight:coverHeight];
        coverView.autoresizingMask = UIViewAutoresizingNone;
        coverView.contentMode = UIViewContentModeScaleToFill;
    }

    if (enableJewel) {
        jewelView.image = [UIImage imageNamed:jewelImg];
        coverView.frame = [Utilities createCoverInsideJewel:jewelView jewelType:jeweltype];
        coverView.contentMode = UIViewContentModeScaleAspectFill;
    }
    else {
        jewelView.image = nil;
        coverView.frame = jewelView.frame;
        coverView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    [self loadThumbnail:item[@"thumbnail"] placeHolder:placeHolderImage jewelType:jeweltype jewelEnabled:enableJewel];
    
    voteLabel.text = [Utilities getStringFromItem:item[@"rating"]];
    starsView.image = [UIImage imageNamed:[NSString stringWithFormat:@"stars_%.0f", roundf([item[@"rating"] floatValue])]];
    NSString *numVotes = [Utilities getStringFromItem:item[@"votes"]];
    if (numVotes.length != 0) {
        NSString *numVotesPlus = LOCALIZED_STR(([numVotes isEqualToString:@"1"]) ? @"vote" : @"votes");
        numVotesLabel.text = [NSString stringWithFormat:@"(%@ %@)", numVotes, numVotesPlus];
    }

    parentalRatingSubLabel.text = [Utilities getStringFromItem:item[@"mpaa"]];
    
    subLabel5.text = [Utilities stripBBandHTML:subLabel5.text];
    
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
    if (subLabel0.text.length == 0) {
        subLabel0.hidden = YES;
        mainLabel0.hidden = YES;
    }
    if (subLabel1.text.length == 0) {
        subLabel1.hidden = YES;
        mainLabel1.hidden = YES;
    }
    if (subLabel2.text.length == 0) {
        subLabel2.hidden = YES;
        mainLabel2.hidden = YES;
    }
    if (subLabel3.text.length == 0) {
        subLabel3.hidden = YES;
        mainLabel3.hidden = YES;
    }
    if (subLabel4.text.length == 0) {
        subLabel4.hidden = YES;
        mainLabel4.hidden = YES;
    }
    if (subLabel5.text.length == 0) {
        subLabel5.hidden = YES;
        mainLabel5.hidden = YES;
    }
    if (parentalRatingSubLabel.text.length == 0) {
        parentalRatingSubLabel.hidden = YES;
        parentalRatingMainLabel.hidden = YES;
    }
    if (trailerLabel == nil) {
        trailerWebView.hidden = YES;
        trailerLabel.hidden = YES;
    }
    if (castList.count == 0) {
        castMainLabel.hidden = YES;
    }
    
    // Adapt font sizes
    if (IS_IPAD) {
        // Votes
        voteLabel.font = [UIFont boldSystemFontOfSize:22];
        numVotesLabel.font = [UIFont systemFontOfSize:16];
        
        // Headers
        mainLabel0.font = [UIFont systemFontOfSize:13];
        mainLabel1.font = [UIFont systemFontOfSize:13];
        mainLabel2.font = [UIFont systemFontOfSize:13];
        mainLabel3.font = [UIFont systemFontOfSize:13];
        mainLabel4.font = [UIFont systemFontOfSize:13];
        mainLabel5.font = [UIFont systemFontOfSize:13];
        castMainLabel.font = [UIFont systemFontOfSize:14];
        trailerLabel.font = [UIFont systemFontOfSize:13];
        parentalRatingMainLabel.font = [UIFont systemFontOfSize:13];
        
        // Text fields
        subLabel0.font = [UIFont systemFontOfSize:16];
        subLabel1.font = [UIFont systemFontOfSize:16];
        subLabel2.font = [UIFont systemFontOfSize:16];
        subLabel3.font = [UIFont systemFontOfSize:16];
        subLabel4.font = [UIFont systemFontOfSize:16];
        subLabel5.font = [UIFont systemFontOfSize:16];
        parentalRatingSubLabel.font = [UIFont systemFontOfSize:16];
    }
    
    // Layout
    CGFloat offset = CGRectGetMaxY(jewelView.frame);
    offset = [self layoutStars:offset];
    offset = [self layoutLabel:mainLabel0 sub:subLabel0 offset:offset];
    offset = [self layoutLabel:mainLabel1 sub:subLabel1 offset:offset];
    offset = [self layoutLabel:mainLabel2 sub:subLabel2 offset:offset];
    offset = [self layoutLabel:mainLabel3 sub:subLabel3 offset:offset];
    offset = [self layoutLabel:mainLabel4 sub:subLabel4 offset:offset];
    offset = [self layoutLabel:mainLabel5 sub:subLabel5 offset:offset];
    offset = [self layoutLabel:parentalRatingMainLabel sub:parentalRatingSubLabel offset:offset];
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
    jewelView.frame = CGRectMake(mainLabel1.frame.origin.x,
                                 jewelView.frame.origin.y,
                                 jewelView.frame.size.width / 4,
                                 jewelView.frame.size.height / 8);
    
    voteLabel.frame = CGRectMake(CGRectGetMaxX(jewelView.frame) + LEFT_RIGHT_PADDING,
                                 jewelView.frame.origin.y,
                                 self.view.bounds.size.width - CGRectGetMaxX(jewelView.frame) - LEFT_RIGHT_PADDING * 2,
                                 jewelView.frame.size.height / 2);
    voteLabel.numberOfLines = 2;
    voteLabel.textColor = subLabel1.textColor;
    
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
        [starsView setY:offset];
        [voteLabel setY:offset];
        [numVotesLabel setY:offset];
        
        offset = CGRectGetMaxY(starsView.frame);
    }
    else {
        offset += VERTICAL_PADDING * 2;
    }
    return offset;
}

- (UILabel*)createMainLabel {
    CGRect defaultFrame = CGRectMake(LABEL_PADDING, 0, scrollView.frame.size.width - 2 * LABEL_PADDING, LABEL_HEIGHT);
    UILabel *label = [[UILabel alloc] initWithFrame:defaultFrame];
    label.hidden = NO;
    label.textColor = UIColor.lightGrayColor;
    label.shadowColor = FONT_SHADOW_STRONG;
    label.font = [UIFont systemFontOfSize:12];
    label.textAlignment = NSTextAlignmentLeft;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.numberOfLines = 1;
    [scrollView addSubview:label];
    return label;
}

- (UILabel*)createSubLabel {
    CGRect defaultFrame = CGRectMake(LABEL_PADDING, 0, scrollView.frame.size.width - 2 * LABEL_PADDING, LABEL_HEIGHT);
    UILabel *label = [[UILabel alloc] initWithFrame:defaultFrame];
    label.hidden = NO;
    label.textColor = UIColor.whiteColor;
    label.shadowColor = FONT_SHADOW_WEAK;
    label.font = [UIFont systemFontOfSize:15];
    label.textAlignment = NSTextAlignmentJustified;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    [scrollView addSubview:label];
    return label;
}

- (CGFloat)layoutLabel:(UILabel*)mainLabel sub:(UILabel*)subLabel offset:(CGFloat)offset {
    if (!mainLabel.hidden) {
        CGRect frame = mainLabel.frame;
        frame.origin.y = offset;
        frame.size.height = [mainLabel getSize].height + lineSpacing;
        mainLabel.frame = frame;
        offset += frame.size.height;
        
        frame = subLabel.frame;
        frame.origin.y = offset;
        frame.size.height = [subLabel getSize].height + lineSpacing;
        subLabel.frame = frame;
        offset += frame.size.height + VERTICAL_PADDING;
    }
    return offset;
}

- (CGFloat)layoutTrailer:(CGFloat)offset {
    if (trailerLabel != nil) {
        CGRect frame = trailerLabel.frame;
        frame.origin.y = offset;
        frame.size.height = [trailerLabel getSize].height + lineSpacing;
        trailerLabel.frame = frame;
        offset += frame.size.height;
        
        frame = trailerWebView.frame;
        frame.origin.y = offset;
        trailerWebView.frame = frame;
        offset += frame.size.height + lineSpacing + VERTICAL_PADDING;
    }
    return offset;
}

- (CGFloat)layoutCastRoles:(CGFloat)offset {
    if (castList.count) {
        CGRect frame = castMainLabel.frame;
        frame.origin.y = offset;
        frame.size.height = [castMainLabel getSize].height + lineSpacing;
        castMainLabel.frame = frame;
        offset += frame.size.height;
        
        [actorsTable setY:offset];
        offset += frame.size.height + VERTICAL_PADDING;
    }
    return offset;
}

- (CGFloat)layoutClearLogo:(CGFloat)offset {
    [clearlogoButton setY:offset];
    offset += clearlogoButton.frame.size.height;
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
        frame = voteLabel.frame;
        frame.origin.x += REC_DOT_SIZE + REC_DOT_PADDING;
        frame.size.width -= REC_DOT_SIZE + REC_DOT_PADDING;
        voteLabel.frame = frame;
    }
}

- (void)processCastFromArray:(NSArray*)array {
    castList = array;
    if (actorsTable == nil) {
        CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, castList.count * (castHeight + VERTICAL_PADDING));
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

- (BOOL)isEmbeddedYoutubeLink:(NSURLComponents*)urlComponents {
    if (urlComponents) {
        NSString *path = urlComponents.path;
        NSString *host = urlComponents.host;
        NSString *scheme = urlComponents.scheme;
        if ([scheme isEqualToString:@"http"] ||
            [scheme isEqualToString:@"https"]) {
            if ([host isEqualToString:@"www.youtube.com"] ||
                [host isEqualToString:@"youtube.com"]) {
                if ([path hasPrefix:@"/embed/"]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (BOOL)isYoutubePluginLink:(NSURLComponents*)urlComponents {
    BOOL isPluginLink = NO;
    if (urlComponents) {
        NSString *host = urlComponents.host;
        NSString *scheme = urlComponents.scheme;
        isPluginLink = [scheme isEqualToString:@"plugin"] && [host isEqualToString:@"plugin.video.youtube"];
    }
    return isPluginLink;
}

- (BOOL)isYoutubeLink:(NSURLComponents*)urlComponents {
    if (urlComponents) {
        NSArray *queryItems = urlComponents.queryItems;
        NSString *path = urlComponents.path;
        NSString *host = urlComponents.host;
        NSString *scheme = urlComponents.scheme;
        if ([scheme isEqualToString:@"http"] ||
            [scheme isEqualToString:@"https"]) {
            if ([host isEqualToString:@"www.youtube.com"] ||
                [host isEqualToString:@"youtube.com"] ||
                [host isEqualToString:@"youtu.be"]) {
                if ([path isEqualToString:@"/watch"]) {
                    for (NSURLQueryItem *item in queryItems) {
                        if ([item.name isEqualToString:@"v"]) {
                            if (item.value.length > 0) {
                                return YES;
                            }
                        }
                    }
                }
            }
        }
    }
    return NO;
}

- (NSURL*)getEmbeddedYoutubeLink:(NSURLComponents*)urlComponents queryItemName:(NSString*)queryItemName {
    // Extracts the video id from the URL and creates a new embedded youtube video link
    NSString *videoURLpath;
    if (urlComponents) {
        NSArray *queryItems = urlComponents.queryItems;
        for (NSURLQueryItem *item in queryItems) {
            if ([item.name isEqualToString:queryItemName]) {
                videoURLpath = [NSString stringWithFormat:@"https://www.youtube.com/embed/%@?&vq=hd1080", item.value];
                break;
            }
        }
    }
    return [NSURL URLWithString:videoURLpath];
}

- (void)processTrailerFromString:(NSString*)trailerString {
    embedVideoURL = nil;
    if (trailerString.length > 0) {
        NSURL *trailerURL = [NSURL URLWithString:trailerString];
        if (!trailerURL) {
            return;
        }
        NSURLComponents *trailerComponents = [NSURLComponents componentsWithURL:trailerURL resolvingAgainstBaseURL:YES];
        if ([self isYoutubePluginLink:trailerComponents]) {
            embedVideoURL = [self getEmbeddedYoutubeLink:trailerComponents queryItemName:@"videoid"];
        }
        else if ([self isYoutubeLink:trailerComponents]) {
            embedVideoURL = [self getEmbeddedYoutubeLink:trailerComponents queryItemName:@"v"];
        }
        else if ([self isEmbeddedYoutubeLink:trailerComponents]) {
            embedVideoURL = trailerURL;
        }
        if (embedVideoURL != nil) {
            CGRect frame = CGRectMake(LEFT_RIGHT_PADDING, 0, clearLogoWidth, mainLabel1.frame.size.height);
            trailerLabel = [[UILabel alloc] initWithFrame:frame];
            trailerLabel.text = LOCALIZED_STR(@"TRAILER");
            trailerLabel.textColor = mainLabel1.textColor;
            trailerLabel.font = mainLabel1.font;
            trailerLabel.shadowColor = mainLabel1.shadowColor;
            trailerLabel.shadowOffset = mainLabel1.shadowOffset;
            trailerLabel.backgroundColor = UIColor.clearColor;
            [scrollView addSubview:trailerLabel];
            
            WKWebViewConfiguration *webViewConfiguration = [[WKWebViewConfiguration alloc] init];
            webViewConfiguration.allowsInlineMediaPlayback = NO;
            frame = CGRectMake(LEFT_RIGHT_PADDING, 0, clearLogoWidth, floor(clearLogoWidth * 9.0 / 16.0));
            trailerWebView = [[WKWebView alloc] initWithFrame:frame configuration:webViewConfiguration];
            trailerWebView.contentMode = UIViewContentModeScaleAspectFit;
            trailerWebView.opaque = NO;
            trailerWebView.backgroundColor = UIColor.blackColor;
            trailerWebView.UIDelegate = self;
            [Utilities applyRoundedEdgesView:trailerWebView];
            [scrollView addSubview:trailerWebView];
            
            trailerComponents = [NSURLComponents componentsWithURL:embedVideoURL resolvingAgainstBaseURL:YES];
            if ([self isEmbeddedYoutubeLink:trailerComponents]) {
                [self loadTrailerInWebKit:nil];
            }
            else {
                UIImage *playTrailerImg = [UIImage imageNamed:@"button_play"];
                trailerPlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
                trailerPlayButton.frame = CGRectMake(0, 0, PLAY_BUTTON_SIZE, PLAY_BUTTON_SIZE);
                trailerPlayButton.center = trailerWebView.center;
                trailerPlayButton.hidden = NO;
                [trailerPlayButton setImage:playTrailerImg forState:UIControlStateNormal];
                [trailerPlayButton addTarget:self action:@selector(loadTrailerInWebKit:) forControlEvents:UIControlEventTouchUpInside];
                [trailerWebView addSubview:trailerPlayButton];
            }
        }
    }
}

- (void)processClearlogoFromDictionary:(NSDictionary*)item {
    clearlogoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    clearlogoButton.frame = CGRectMake(LEFT_RIGHT_PADDING, 0, clearLogoWidth, clearLogoHeight);
    clearlogoButton.titleLabel.shadowColor = FONT_SHADOW_STRONG;
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
        NSString *serverURL = [Utilities getImageServerURL];
        NSString *stringURL = [Utilities formatStringURL:item[@"clearlogo"] serverURL:serverURL];
        [clearLogoImageView sd_setImageWithURL:[NSURL URLWithString:stringURL]
                              placeholderImage:[UIImage imageNamed:@"blank"]];
        [clearlogoButton addSubview:clearLogoImageView];
    }
    else {
        [clearlogoButton setTitle:[item[@"showtitle"] length] == 0 ? item[@"label"] : item[@"showtitle"] forState:UIControlStateNormal];
        clearlogoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    }
    [scrollView addSubview:clearlogoButton];
}

- (void)loadThumbnail:(NSString*)thumbnailPath placeHolder:(NSString*)placeHolderImage jewelType:(JewelType)jewelType jewelEnabled:(BOOL)enableJewel {
    [activityIndicatorView startAnimating];
    if (thumbnailPath.length) {
        coverView.alpha = 0.0;
    }
    __typeof__(self) __weak weakSelf = self;
    [coverView sd_setImageWithURL:[NSURL URLWithString:thumbnailPath]
                 placeholderImage:[UIImage imageNamed:placeHolderImage]
                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *url) {
                        __auto_type strongSelf = weakSelf;
                        if (!strongSelf) {
                            return;
                        }
                        if (image != nil) {
                            UIColor *newColor = [Utilities textTintColor:[Utilities getUIColorFromImage:image]];
                            [strongSelf setIOS7barTintColor:newColor];
                            foundTintColor = newColor;
                        }
                        [strongSelf elaborateImage:image fallbackImage:[UIImage imageNamed:placeHolderImage]];
    }];
}

- (void)loadFanart:(NSString*)fanartPath {
    __typeof__(self) __weak weakSelf = self;
    [fanartView sd_setImageWithURL:[NSURL URLWithString:fanartPath]
                  placeholderImage:[UIImage imageNamed:@"blank"]
                         completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *url) {
                          __auto_type strongSelf = weakSelf;
                          if (strongSelf != nil && strongSelf->enableKenBurns) {
                              [strongSelf elabKenBurns:image];
                              [strongSelf.kenView animateAlpha:0.2 duration:1.5];
                          }
                      }
     ];
    fanartView.clipsToBounds = YES;
}

- (void)showBackgroundForTag:(NSInteger)tag {
    // Close then fullscreen fanart view
    if (tag == FANART_FULLSCREEN_DISABLE) {
        // 1. Fade in the navbar.
        // 2. Fade out the fanart and send StackScrollFullScreenDisabled to iPad screen handler.
        // 3. Fade in scrollview and up arrow (we are always on the bottom of the scrollview when fading in).
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [UIView animateWithDuration:1.5
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                            isFullscreenFanArt = NO;
                            closeButton.alpha = 0.0;
                            if (!enableKenBurns) {
                                fanartView.alpha = 0.2;
                            }
                            else {
                                self.kenView.alpha = 0.2;
                            }
                            if (IS_IPAD) {
                                if (![self isModal]) {
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"StackScrollFullScreenDisabled" object:self.view userInfo:nil];
                                }
                            }
                         }
                         completion:^(BOOL finished) {
                            [UIView animateWithDuration:0.2
                                                  delay:0
                                                options:UIViewAnimationOptionCurveEaseInOut
                                             animations:^{
                                                scrollView.alpha = 1.0;
                                                effectView.alpha = 1.0;
                                                toolbar.alpha = 1.0;
                                                arrow_back_up.alpha = ARROW_ALPHA;
                                             }
                                             completion:nil
                             ];
                        }
         ];
    }
    // Open then fullscreen fanart view
    else {
        // 1. Fade out the scrollview and arrows. Only when finished hide the navbar.
        // 2. Fade in the fullscreen fanart and send StackScrollFullScreenEnabled to iPad screen handler.
        // Special handling: For iPad we first fade out, then re-load the fanart and fade in again.
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                            scrollView.alpha = 0.0;
                            effectView.alpha = 0.0;
                            toolbar.alpha = 0.0;
                            arrow_back_up.alpha = 0.0;
                            arrow_continue_down.alpha = 0.0;
                            if (IS_IPAD && self.kenView != nil) {
                                self.kenView.alpha = 0;
                            }
                         }
                         completion:^(BOOL finished) {
                            isFullscreenFanArt = YES;
                            [self.navigationController setNavigationBarHidden:YES animated:YES];
                            if (IS_IPAD && self.kenView != nil) {
                                [self elabKenBurns:fanartView.image];
                            }
                            [UIView animateWithDuration:1.5
                                                  delay:0
                                                options:UIViewAnimationOptionCurveEaseInOut
                                             animations:^{
                                                if (!enableKenBurns) {
                                                    fanartView.alpha = 1.0;
                                                }
                                                else {
                                                    self.kenView.alpha = 1.0;
                                                }
                                             }
                                             completion:nil
                             ];
                             if (IS_IPAD) {
                                 if (![self isModal]) {
                                     NSDictionary *params = @{
                                         @"hideToolbar": @YES,
                                         @"clipsToBounds": @YES,
                                     };
                                     [[NSNotificationCenter defaultCenter] postNotificationName:@"StackScrollFullScreenEnabled" object:self.view userInfo:params];
                                 }
                             }
                        }
         ];
        
        if (closeButton == nil) {
            int cbWidth = clearLogoWidth / 2;
            int cbHeight = clearLogoHeight / 2;
            closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width / 2 - cbWidth / 2, self.view.bounds.size.height - cbHeight - CLEARLOGO_FULLSCREEN_PADDING, cbWidth, cbHeight)];
            closeButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                           UIViewAutoresizingFlexibleRightMargin |
                                           UIViewAutoresizingFlexibleLeftMargin |
                                           UIViewAutoresizingFlexibleWidth;
            if (clearLogoImageView.frame.size.width == 0) {
                [closeButton setTitle:clearlogoButton.titleLabel.text forState:UIControlStateNormal];
                [closeButton setTitleShadowColor:FONT_SHADOW_STRONG forState:UIControlStateNormal];
                closeButton.titleLabel.shadowOffset = CGSizeMake(1, 1);
                closeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
            }
            else {
                closeButton.imageView.layer.minificationFilter = kCAFilterTrilinear;
                [closeButton setImage:clearLogoImageView.image forState:UIControlStateNormal];
                [closeButton setImage:clearLogoImageView.image forState:UIControlStateHighlighted];
                closeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
            }
            [closeButton addTarget:self action:@selector(showBackground:) forControlEvents:UIControlEventTouchUpInside];
            closeButton.tag = FANART_FULLSCREEN_DISABLE;
            closeButton.alpha = 0;
            [self.view addSubview:closeButton];
        }
        [closeButton animateAlpha:1.0 duration:1.5];
    }
    [self scrollDown:nil];
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
    [self showBackgroundForTag:foundTag];
}

- (void)scrollViewDidScroll:(UIScrollView*)theScrollView {
    int height_content = theScrollView.contentSize.height;
    int height_bounds = theScrollView.bounds.size.height;
    int scrolled = theScrollView.contentOffset.y;
    bool at_bottom = scrolled >= height_content - height_bounds;
    
    // Ignore while not in scrollview mode
    if (scrollView.alpha == 0) {
        return;
    }
    
    if (arrow_continue_down.alpha && at_bottom) {
        [arrow_continue_down animateAlpha:0.0 duration:0.3];
    }
    else if (!arrow_continue_down.alpha && !at_bottom) {
        [arrow_continue_down animateAlpha:ARROW_ALPHA duration:0.3];
    }
    bool at_top = theScrollView.contentOffset.y <= -scrollView.contentInset.top;
    if (arrow_back_up.alpha && at_top) {
        [arrow_back_up animateAlpha:0.0 duration:0.3];
    }
    else if (!arrow_back_up.alpha && !at_top) {
        [arrow_back_up animateAlpha:ARROW_ALPHA duration:0.3];
    }
}

#pragma mark - Actors UITableView data source & delegate

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return castHeight + VERTICAL_PADDING;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return castList.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *CellIdentifier = @"CellActor";
    ActorCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ActorCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier castWidth:castWidth castHeight:castHeight lineSpacing:lineSpacing castFontSize:castFontSize];
    }
    if (castList.count > indexPath.row) {
        NSDictionary *castMember = castList[indexPath.row];
        NSString *serverURL = [Utilities getImageServerURL];
        NSString *stringURL = [Utilities formatStringURL:castMember[@"thumbnail"] serverURL:serverURL];
        [cell.actorThumbnail sd_setImageWithURL:[NSURL URLWithString:stringURL]
                               placeholderImage:[UIImage imageNamed:@"nocover_actor"]
                                        options:SDWebImageScaleToNativeSize];
        [Utilities applyRoundedEdgesView:cell.actorThumbnail];
        cell.actorName.text = castMember[@"name"] ?: self.detailItem[@"label"];
        cell.actorRole.text = castMember[@"role"];
        [cell.actorRole sizeToFit];
    }
    return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    if (AppDelegate.instance.serverVersion > 11 && ![self isModal]) {
        UIImage *image = [Utilities colorizeImage:[UIImage imageNamed:@"table_arrow_right"] withColor:UIColor.grayColor];
        cell.accessoryView = [[UIImageView alloc] initWithImage:image];
        cell.accessoryView.alpha = ARROW_ALPHA;
    }
    else {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    if (AppDelegate.instance.serverVersion > 11 && ![self isModal] && castList.count > indexPath.row) {
        [self showContent:castList[indexPath.row][@"name"]];
    }
}

#pragma mark - WebKit

- (WKWebView*)webView:(WKWebView*)webView createWebViewWithConfiguration:(WKWebViewConfiguration*)configuration forNavigationAction:(WKNavigationAction*)navigationAction windowFeatures:(WKWindowFeatures*)windowFeatures {
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

- (void)loadTrailerInWebKit:(id)sender {
    trailerPlayButton.hidden = YES;
    NSMutableURLRequest *urlrequest = [NSMutableURLRequest requestWithURL:embedVideoURL];
    
    /*
     Add Referer and origin to fix youtube "Error 153"
     References:
     https://developers.google.com/youtube/terms/required-minimum-functionality?hl=en#embedded-player-api-client-identity
     https://stackoverflow.com/questions/79802987/youtube-error-153-video-player-configuration-error-when-embedding-youtube-video
     */
    NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;
    NSString *referrer = [NSString stringWithFormat:@"https://%@", bundleID.lowercaseString];
    [urlrequest addValue:referrer forHTTPHeaderField:@"Referer"];
    [urlrequest addValue:referrer forHTTPHeaderField:@"origin"];
    
    [trailerWebView loadRequest:urlrequest];
}

# pragma mark - JSON Data

- (void)addQueueAfterCurrent:(BOOL)afterCurrent {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    NSDictionary *item = self.detailItem;
    int playlistid = [item[@"playlistid"] intValue];
    NSString *param = item[@"family"];
    id value = item[item[@"family"]];
    // If Playlist.Insert and Playlist.Add for recordingid is not supported, use file path.
    if (![VersionCheck hasRecordingIdPlaylistSupport] && [item[@"family"] isEqualToString:@"recordingid"]) {
        param = @"file";
        value = item[@"file"];
    }
    if (!value || !param) {
        [activityIndicatorView stopAnimating];
        [Utilities showMessage:LOCALIZED_STR(@"Cannot do that") color:ERROR_MESSAGE_COLOR];
        return;
    }
    if (afterCurrent) {
        NSDictionary *params = @{
            @"playerid": @(playlistid),
            @"properties": @[@"percentage", @"time", @"totaltime", @"partymode", @"position"],
        };
        [activityIndicatorView startAnimating];
        [[Utilities getJsonRPC]
         callMethod:@"Player.GetProperties"
         withParameters:params
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
             if (error == nil && methodError == nil) {
                 if ([methodResult isKindOfClass:[NSDictionary class]]) {
                     if ([methodResult count]) {
                         [activityIndicatorView stopAnimating];
                         int newPos = [methodResult[@"position"] intValue] + 1;
                         NSString *action2 = @"Playlist.Insert";
                         NSDictionary *params2 = @{
                             @"playlistid": @(playlistid),
                             @"item": @{param: value},
                             @"position": @(newPos),
                         };
                         [[Utilities getJsonRPC] callMethod:action2 withParameters:params2 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                             if (error == nil && methodError == nil) {
                                 [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCPlaylistHasChanged" object:nil];
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
        NSDictionary *params = @{
            @"playlistid": @(playlistid),
            @"item": @{param: value},
        };
        [[Utilities getJsonRPC] callMethod:@"Playlist.Add" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
            [activityIndicatorView stopAnimating];
            if (error == nil && methodError == nil) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCPlaylistHasChanged" object:nil];
            }
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }];
    }
}

- (void)startPlayback:(BOOL)resume {
    NSDictionary *item = self.detailItem;
    if ([item[@"family"] isEqualToString:@"broadcastid"]) {
        NSDictionary *itemParams = @{
            @"item": [NSDictionary dictionaryWithObjectsAndKeys:item[@"pvrExtraInfo"][@"channelid"], @"channelid", nil],
        };
        [self openFile:itemParams];
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [activityIndicatorView startAnimating];
        NSString *key = item[@"family"];
        id value = item[key];
        if (!value || !key) {
            [activityIndicatorView stopAnimating];
            [Utilities showMessage:LOCALIZED_STR(@"Cannot do that") color:ERROR_MESSAGE_COLOR];
            return;
        }
        NSDictionary *params = @{
            @"item": @{
                key: value,
            },
            @"options": @{
                @"resume": @(resume),
            },
        };
        [[Utilities getJsonRPC] callMethod:@"Player.Open" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
            if (error == nil && methodError == nil) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCPlaylistHasChanged" object:nil];
                [activityIndicatorView stopAnimating];
                [self showNowPlaying];
                [Utilities checkForReviewRequest];
            }
            else {
                [activityIndicatorView stopAnimating];
            }
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }];
    }
}

- (void)openFile:(NSDictionary*)params {
    [activityIndicatorView startAnimating];
    [[Utilities getJsonRPC] callMethod:@"Player.Open" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        [activityIndicatorView stopAnimating];
        if (error == nil && methodError == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCPlaylistHasChanged" object:nil];
            [self showNowPlaying];
        }
    }];
}

- (void)SimpleAction:(NSString*)action params:(NSDictionary*)parameters {
    [[Utilities getJsonRPC] callMethod:action withParameters:parameters];
}

# pragma mark - Utility

- (void)elabKenBurns:(UIImage*)image {
    CGRect targetedFrame = (IS_IPHONE) ? UIScreen.mainScreen.bounds : fanartView.bounds;
    [self.kenView stopAnimation];
    [self.kenView removeFromSuperview];
    self.kenView = [[KenBurnsView alloc] initWithFrame:targetedFrame];
    self.kenView.layer.minificationFilter = kCAFilterTrilinear;
    self.kenView.layer.magnificationFilter = kCAFilterTrilinear;
    self.kenView.autoresizingMask = fanartView.autoresizingMask;
    self.kenView.contentMode = fanartView.contentMode;
    self.kenView.delegate = self;
    self.kenView.alpha = 0;
    self.kenView.tag = FANART_FULLSCREEN_DISABLE;
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

- (void)leaveFullscreen {
    if (isFullscreenFanArt) {
        [self showBackgroundForTag:FANART_FULLSCREEN_DISABLE];
    }
}

# pragma mark - Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.slidingViewController.underRightViewController = nil;
    self.slidingViewController.anchorLeftPeekAmount   = 0;
    self.slidingViewController.anchorLeftRevealAmount = 0;
    [actorsTable deselectRowAtIndexPath:[actorsTable indexPathForSelectedRow] animated:YES];
    if ([self isModal]) {
        if (doneButton == nil) {
            NSMutableArray *items = [toolbar.items mutableCopy];
            doneButton = [[UIBarButtonItem alloc] initWithTitle:LOCALIZED_STR(@"Done") style:UIBarButtonItemStyleDone target:self action:@selector(dismissModal:)];
            [items insertObject:doneButton atIndex:0];
            toolbar.items = items;
        }
        
        // Special treatment for older iOS version where it is not possible to close some of the modal views.
        NSOperatingSystemVersion versionOS = [[NSProcessInfo processInfo] operatingSystemVersion];
        if (versionOS.majorVersion < 14) {
            if (extraButton) {
                NSMutableArray *items = [toolbar.items mutableCopy];
                [items removeObject:extraButton];
                toolbar.items = items;
            }
        }
        
        [self setIOS7barTintColor:ICON_TINT_COLOR];
        viewTitle.textAlignment = NSTextAlignmentCenter;
        bottomShadow.hidden = YES;
    }
    [self createInfo];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (foundTintColor != nil) {
        [self setIOS7barTintColor:foundTintColor];
    }
    else {
        [self setIOS7barTintColor:ICON_TINT_COLOR];
    }
    CGFloat alphaValue = 0.2;
    if (closeButton.alpha == 1) {
        alphaValue = 1;
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
    
    NSString *fanart = self.detailItem[@"fanart"];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (fanart.length == 0 && [userDefaults boolForKey:@"fanart_fallback_preference"]) {
        fanart = self.detailItem[@"thumbnail"];
    }
    [self loadFanart:fanart];
    if (!enableKenBurns) {
        [fanartView animateAlpha:alphaValue duration:1.5];
    }
    else {
        [self.kenView animateAlpha:alphaValue duration:1.5];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setIOS7barTintColor:ICON_TINT_COLOR];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [fanartView animateAlpha:0.0 duration:0.3];
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
    fanartView.tag = FANART_FULLSCREEN_DISABLE;
    fanartView.userInteractionEnabled = YES;
    UITapGestureRecognizer *touchOnKenView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showBackground:)];
    touchOnKenView.numberOfTapsRequired = 1;
    touchOnKenView.numberOfTouchesRequired = 1;
    [fanartView addGestureRecognizer:touchOnKenView];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self disableScrollsToTopPropertyOnAllSubviewsOf:self.slidingViewController.view];
    scrollView.scrollsToTop = YES;
    scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    enableKenBurns = [userDefaults boolForKey:@"ken_preference"];
    self.kenView = nil;
    logoBackgroundMode = [Utilities getLogoBackgroundMode];
    foundTintColor = ICON_TINT_COLOR;
    [self configureView];
    
    coverView.layer.minificationFilter = kCAFilterTrilinear;
    coverView.layer.magnificationFilter = kCAFilterTrilinear;
    fanartView.layer.minificationFilter = kCAFilterTrilinear;
    fanartView.layer.magnificationFilter = kCAFilterTrilinear;
    
    xbmcDateFormatter = [NSDateFormatter new];
    xbmcDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    xbmcDateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"]; // all times in Kodi PVR are UTC
    xbmcDateFormatter.locale = [NSLocale systemLocale]; // Needed to work with 12h system setting in combination with "UTC"
    
    localStartDateFormatter = [NSDateFormatter new];
    localStartDateFormatter.timeZone = [NSTimeZone systemTimeZone];
    localStartDateFormatter.dateFormat = @"ccc, dd MMM YYYY, HH:mm";
    
    localEndDateFormatter = [NSDateFormatter new];
    localEndDateFormatter.timeZone = [NSTimeZone systemTimeZone];
    localEndDateFormatter.dateFormat = @"HH:mm";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(leaveFullscreen)
                                                 name:@"LeaveFullscreen"
                                               object:nil];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:nil
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (self.kenView != nil && ![self isModal]) {
            CGFloat alphaValue = 0.2;
            if (closeButton.alpha == 1) {
                alphaValue = 1;
            }
            [UIView animateWithDuration:0.1
                             animations:^{
                                 self.kenView.alpha = 0;
                             }
                             completion:^(BOOL finished) {
                                 [self elabKenBurns:fanartView.image];
                                 [self.kenView animateAlpha:alphaValue duration:0.2];
                             }
             ];
        }
    }];
}

@end
