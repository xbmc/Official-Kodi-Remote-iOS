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
#import "VersionCheck.h"

#define PLAY_BUTTON_SIZE 20
#define TV_LOGO_SIZE_REC_DETAILS 72
#define TITLE_HEIGHT 44
#define LEFT_RIGHT_PADDING 10
#define VERTICAL_PADDING 10
#define REC_DOT_SIZE 10
#define REC_DOT_PADDING 4
#define ARROW_ALPHA 0.5
#define IPAD_NAVBAR_PADDING 20
#define FANART_FULLSCREEN_DISABLE 1
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
        if (resumePointDict && [resumePointDict isKindOfClass:[NSDictionary class]]) {
            float position = [Utilities getFloatValueFromItem:resumePointDict[@"position"]];
            float total = [Utilities getFloatValueFromItem:resumePointDict[@"total"]];
            if (position > 0 && total > 0) {
                resumePointPercentage = (position * 100) / total;
                [sheetActions addObject:[NSString stringWithFormat:LOCALIZED_STR(@"Resume from %@"), [Utilities convertTimeFromSeconds: @(position)]]];
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
            toolbar = [UIToolbar new];
            toolbar.barStyle = UIBarStyleBlack;
            toolbar.translucent = YES;
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
            if (actionSheetButtonItem && extraButton) {
                self.navigationItem.rightBarButtonItems = @[actionSheetButtonItem, extraButton];
            }
            else if (actionSheetButtonItem) {
                self.navigationItem.rightBarButtonItems = @[actionSheetButtonItem];
            }
            else if (extraButton) {
                self.navigationItem.rightBarButtonItems = @[extraButton];
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
    BOOL blackTableSeparator = NO;
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
            blackTableSeparator = YES;
        }
    }
    else {
        return;
    }
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[choosedMenuItem mainMethod][choosedTab]];
    if (methods[@"method"] != nil) { // THERE IS A CHILD
        NSDictionary *mainFields = menuItem.mainFields[choosedTab];
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
                                       @(blackTableSeparator), @"blackTableSeparator",
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
    if (sheetActions.count) {
        NSDictionary *item = self.detailItem;
        NSString *sheetTitle = item[@"label"];
        if ([item[@"family"] isEqualToString:@"broadcastid"]) {
            sheetTitle = item[@"pvrExtraInfo"][@"channel_name"];
        }
        
        UIAlertController *actionView = [UIAlertController alertControllerWithTitle:sheetTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *action_cancel = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
        
        for (NSString *actionName in sheetActions) {
            NSString *actiontitle = actionName;
            UIAlertAction *action = [UIAlertAction actionWithTitle:actiontitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self actionSheetHandler:actiontitle];
            }];
            [actionView addAction:action];
        }
        [actionView addAction:action_cancel];
        actionView.modalPresentationStyle = UIModalPresentationPopover;
        
        UIPopoverPresentationController *popPresenter = [actionView popoverPresentationController];
        if (popPresenter != nil) {
            popPresenter.sourceView = self.view;
            popPresenter.barButtonItem = actionSheetButtonItem;
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
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Record")] ||
             [actiontitle isEqualToString:LOCALIZED_STR(@"Stop Recording")]) {
        [self recordChannel];
    }
    else if ([actiontitle rangeOfString:LOCALIZED_STR(@"Resume from")].location != NSNotFound) {
        [self addPlayback:resumePointPercentage];
        return;
    }
    else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Play Trailer")]) {
        NSDictionary *itemParams = @{
            @"item": [NSDictionary dictionaryWithObjectsAndKeys: self.detailItem[@"trailer"], @"file", nil],
        };
        [self openFile:itemParams];
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
    NSDictionary *item = self.detailItem;
    NSNumber *channelid = @([item[@"pvrExtraInfo"][@"channelid"] longValue]);
    if ([channelid longValue] == 0) {
        return;
    }
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
                   if ([item[@"broadcastid"] longValue] > 0) {
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
        frame.origin.y = coverView.frame.origin.y + 4;
        coverView.frame = frame;
        
        // Ensure we draw the rounded edges around TV station logo view
        coverView.image = imageToShow;
        coverView = [Utilities applyRoundedEdgesView:coverView drawBorder:YES];
        
        // Choose correct background color for station logos
        if (image != nil) {
            [Utilities setLogoBackgroundColor:coverView mode:logoBackgroundMode];
        }
    }
    else {
        // Ensure we draw the rounded edges around thumbnail images
        coverView.image = [Utilities applyRoundedEdgesImage:imageToShow drawBorder:YES];
    }
    [Utilities alphaView:coverView AnimDuration:0.1 Alpha:1.0];
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

        jewelImg = @"jewel_dvd.9";
        jeweltype = jewelTypeDVD;
        int coverHeight = IS_IPAD ? DVD_HEIGHT_IPAD : DVD_HEIGHT_IPHONE;
        CGRect frame = jewelView.frame;
        frame.size.height = coverHeight;
        jewelView.frame = frame;
        
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
        directorLabel.text = [Utilities formatTVShowStringForSeasonTrailing:item[@"season"] episode:item[@"episode"] title:item[@"showtitle"]];
        genreLabel.text = [Utilities getDateFromItem:item[@"firstaired"] dateStyle:NSDateFormatterLongStyle];
        runtimeLabel.text = [Utilities getStringFromItem:item[@"director"]];
        studioLabel.text = [Utilities getStringFromItem:item[@"writer"]];
        summaryLabel.text = [Utilities getStringFromItem:item[@"plot"]];
        
        parentalRatingLabelUp.hidden = YES;
        parentalRatingLabel.hidden = YES;
        jewelView.hidden = NO;
        
        jewelImg = @"jewel_tv.9";
        jeweltype = jewelTypeTV;
        int coverHeight = IS_IPAD ? TV_HEIGHT_IPAD : TV_HEIGHT_IPHONE;
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
        
        jewelImg = @"jewel_cd.9";
        jeweltype = jewelTypeCD;
        int coverHeight = IS_IPAD ? CD_HEIGHT_IPAD : CD_HEIGHT_IPHONE;
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
        
        jewelImg = @"jewel_cd.9";
        jeweltype = jewelTypeCD;
        int coverHeight = IS_IPAD ? CD_HEIGHT_IPAD : CD_HEIGHT_IPHONE;
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
    }
    else if ([item[@"family"] isEqualToString:@"recordingid"]) {
        placeHolderImage = @"nocover_channels";
        
        // Be aware: "rating" is later used to display the label
        item[@"rating"] = item[@"label"];
        if (item[@"pvrExtraInfo"][@"channel_icon"] != nil) {
            item[@"thumbnail"] = item[@"pvrExtraInfo"][@"channel_icon"];
        }
        item[@"genre"] = [item[@"plotoutline"] length] > 0 ? item[@"plotoutline"] : item[@"genre"];
        
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
        genreLabel.text = [Utilities getStringFromItem:item[@"plotoutline"]];
        numVotesLabel.text = item[@"pvrExtraInfo"][@"channel_name"];
        summaryLabel.text = [Utilities getStringFromItem:item[@"genre"]];
        
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
        
        jewelImg = @"jewel_dvd.9";
        jeweltype = jewelTypeDVD;
        int coverHeight = IS_IPAD ? DVD_HEIGHT_IPAD : DVD_HEIGHT_IPHONE;
        CGRect frame = jewelView.frame;
        frame.size.height = coverHeight;
        jewelView.frame = frame;
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

    parentalRatingLabel.text = [Utilities getStringFromItem:item[@"mpaa"]];
    
    summaryLabel.text = [Utilities stripBBandHTML:summaryLabel.text];
    
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
            NSURL *url = [NSURL URLWithString:trailerString];
            if (url) {
                NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
                NSArray *queryItems = urlComponents.queryItems;
                for (NSURLQueryItem *item in queryItems) {
                    if ([item.name isEqualToString:@"videoid"]) {
                        embedVideoURL = [NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@", item.value];
                        break; // We can leave the loop as we found what we were looking for.
                    }
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

- (void)loadThumbnail:(NSString*)thumbnailPath placeHolder:(NSString*)placeHolderImage jewelType:(eJewelType)jewelType jewelEnabled:(BOOL)enableJewel {
    [activityIndicatorView startAnimating];
    if (thumbnailPath.length) {
        coverView.alpha = 0.0;
    }
    [[SDImageCache sharedImageCache] queryDiskCacheForKey:thumbnailPath done:^(UIImage *image, SDImageCacheType cacheType) {
        if (image != nil) {
            foundTintColor = [Utilities lighterColorForColor:[Utilities averageColor:image inverse:NO autoColorCheck:YES]];
            [self setIOS7barTintColor:foundTintColor];
            [self elaborateImage:image fallbackImage:[UIImage imageNamed:placeHolderImage]];
        }
        else {
            __weak ShowInfoViewController *sf = self;
            __block UIColor *newColor = nil;
            [coverView sd_setImageWithURL:[NSURL URLWithString:thumbnailPath]
                         placeholderImage:[UIImage imageNamed:placeHolderImage]
                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *url) {
                                if (image != nil) {
                                    newColor = [Utilities lighterColorForColor:[Utilities averageColor:image inverse:NO autoColorCheck:YES]];
                                    [sf setIOS7barTintColor:newColor];
                                    foundTintColor = newColor;
                                }
                                [sf elaborateImage:image fallbackImage:[UIImage imageNamed:placeHolderImage]];
            }];
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
                [Utilities alphaView:sf.kenView AnimDuration:1.5 Alpha:0.2];
            }
        }
        else {
            [fanartView sd_setImageWithURL:[NSURL URLWithString:fanartPath]
                          placeholderImage:[UIImage imageNamed:@"blank"]
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *url) {
                                  __auto_type strongSelf = sf;
                                  if (strongSelf != nil && strongSelf->enableKenBurns) {
                                      [sf elabKenBurns:image];
                                      [Utilities alphaView:sf.kenView AnimDuration:1.5 Alpha:0.2];
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
                                    [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollFullScreenDisabled" object:self.view userInfo:nil];
                                }
                            }
                         }
                         completion:^(BOOL finished) {
                            [UIView animateWithDuration:0.2
                                                  delay:0
                                                options:UIViewAnimationOptionCurveEaseInOut
                                             animations:^{
                                                scrollView.alpha = 1.0;
                                                toolbar.alpha = 1.0;
                                                arrow_back_up.alpha = ARROW_ALPHA;
                                             }
                                             completion:^(BOOL finished) {}
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
                                             completion:^(BOOL finished) {}
                             ];
                             if (IS_IPAD) {
                                 if (![self isModal]) {
                                     NSDictionary *params = @{
                                         @"hideToolbar": @YES,
                                         @"clipsToBounds": @YES,
                                     };
                                     [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollFullScreenEnabled" object:self.view userInfo:params];
                                 }
                             }
                        }
         ];
        
        if (closeButton == nil) {
            int cbWidth = clearLogoWidth / 2;
            int cbHeight = clearLogoHeight / 2;
            closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width / 2 - cbWidth / 2, self.view.bounds.size.height - cbHeight - 20, cbWidth, cbHeight)];
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
            closeButton.tag = FANART_FULLSCREEN_DISABLE;
            closeButton.alpha = 0;
            [self.view addSubview:closeButton];
        }
        [Utilities alphaView:closeButton AnimDuration:1.5 Alpha:1];
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
        [Utilities alphaView:arrow_continue_down AnimDuration:0.3 Alpha:0];
    }
    else if (!arrow_continue_down.alpha && !at_bottom) {
        [Utilities alphaView:arrow_continue_down AnimDuration:0.3 Alpha:ARROW_ALPHA];
    }
    bool at_top = theScrollView.contentOffset.y <= -scrollView.contentInset.top;
    if (arrow_back_up.alpha && at_top) {
        [Utilities alphaView:arrow_back_up AnimDuration:0.3 Alpha:0];
    }
    else if (!arrow_back_up.alpha && !at_top) {
        [Utilities alphaView:arrow_back_up AnimDuration:0.3 Alpha:ARROW_ALPHA];
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
    return cast.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *CellIdentifier = @"CellActor";
    ActorCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ActorCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier castWidth:castWidth castHeight:castHeight size:lineSpacing castFontSize:castFontSize];
    }
    NSString *serverURL = [Utilities getImageServerURL];
    NSString *stringURL = [Utilities formatStringURL:cast[indexPath.row][@"thumbnail"] serverURL:serverURL];
    [cell.actorThumbnail sd_setImageWithURL:[NSURL URLWithString:stringURL]
                           placeholderImage:[UIImage imageNamed:@"person"]
                                    options:SDWebImageScaleToNativeSize];
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
        UIImage *image = [Utilities colorizeImage:[UIImage imageNamed:@"table_arrow_right"] withColor:UIColor.grayColor];
        cell.accessoryView = [[UIImageView alloc] initWithImage:image];
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
    int playlistid = [item[@"playlistid"] intValue];
    NSString *param = item[@"family"];
    id value = item[item[@"family"]];
    // If Playlist.Insert and Playlist.Add for recordingid is not supported, use file path.
    if (![VersionCheck hasRecordingIdPlaylistSupport] && [item[@"family"] isEqualToString:@"recordingid"]) {
        param = @"file";
        value = item[@"file"];
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
                             @"item": [NSDictionary dictionaryWithObjectsAndKeys: value, param, nil],
                             @"position": @(newPos),
                         };
                         [[Utilities getJsonRPC] callMethod:action2 withParameters:params2 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
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
        NSDictionary *params = @{
            @"playlistid": @(playlistid),
            @"item": [NSDictionary dictionaryWithObjectsAndKeys: value, param, nil],
        };
        [[Utilities getJsonRPC] callMethod:@"Playlist.Add" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
            [activityIndicatorView stopAnimating];
            if (error == nil && methodError == nil) {
                [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
            }
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }];
    }
}

- (void)addPlayback:(float)resumePointLocal {
    NSDictionary *item = self.detailItem;
    if ([item[@"family"] isEqualToString:@"broadcastid"]) {
        NSDictionary *itemParams = @{
            @"item": [NSDictionary dictionaryWithObjectsAndKeys: item[@"pvrExtraInfo"][@"channelid"], @"channelid", nil],
        };
        [self openFile:itemParams];
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [activityIndicatorView startAnimating];
        int playlistid = [item[@"playlistid"] intValue];
        [[Utilities getJsonRPC] callMethod:@"Playlist.Clear" withParameters:@{@"playlistid": @(playlistid)} onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
            if (error == nil && methodError == nil) {
                NSString *param = item[@"family"];
                id value = item[item[@"family"]];
                // If Playlist.Insert and Playlist.Add for recordingid is not supported, use file path.
                if (![VersionCheck hasRecordingIdPlaylistSupport] && [item[@"family"] isEqualToString:@"recordingid"]) {
                    param = @"file";
                    value = item[@"file"];
                }
                NSDictionary *params = @{
                    @"playlistid": @(playlistid),
                    @"item": [NSDictionary dictionaryWithObjectsAndKeys: value, param, nil],
                };
                [[Utilities getJsonRPC] callMethod:@"Playlist.Add" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                    if (error == nil && methodError == nil) {
                        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
                        NSDictionary *params = @{
                            @"item": @{
                                @"playlistid": @(playlistid),
                                @"position": @(0),
                            },
                        };
                        [[Utilities getJsonRPC] callMethod:@"Player.Open" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                            if (error == nil && methodError == nil) {
                                [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
                                [activityIndicatorView stopAnimating];
                                [self showNowPlaying];
                                [Utilities checkForReviewRequest];
                                if (resumePointLocal) {
                                    [NSThread sleepForTimeInterval:1.0];
                                    [self SimpleAction:@"Player.Seek" params:[Utilities buildPlayerSeekPercentageParams:playlistid percentage:resumePointLocal]];
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
    [[Utilities getJsonRPC] callMethod:@"Player.Open" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
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
        [Utilities alphaView:fanartView AnimDuration:1.5 Alpha:alphaValue];// cool
    }
    else {
        [Utilities alphaView:self.kenView AnimDuration:1.5 Alpha:alphaValue];// cool
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
    [self setIOS7barTintColor:ICON_TINT_COLOR];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [Utilities alphaView:fanartView AnimDuration:0.3 Alpha:0.0];
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
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(leaveFullscreen)
                                                 name: @"LeaveFullscreen"
                                               object: nil];
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {}
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
                                 [Utilities alphaView:self.kenView AnimDuration:0.2 Alpha:alphaValue];
                             }
             ];
        }
    }];
}

@end
