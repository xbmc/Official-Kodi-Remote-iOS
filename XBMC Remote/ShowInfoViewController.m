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

@interface ShowInfoViewController ()
@end

@implementation ShowInfoViewController

@synthesize detailItem = _detailItem;
@synthesize nowPlaying;
@synthesize detailViewController;
@synthesize kenView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil withItem:(NSDictionary *)item withFrame:(CGRect)frame bundle:(NSBundle *)nibBundleOrNil{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.detailItem = item;
        [self.view setFrame:frame];
    }
    return self;
}

double round(double d){
    return floor(d + 0.5);
}

int count=0;

- (void)configureView{
    if (self.detailItem) {
        NSMutableDictionary *item=self.detailItem;
        CGRect frame = CGRectMake(0, 0, 140, 40);
        viewTitle = [[UILabel alloc] initWithFrame:frame];
        viewTitle.numberOfLines=0;
        viewTitle.font = [UIFont boldSystemFontOfSize:11];
        viewTitle.minimumScaleFactor = 6.0f/11.0f;
        viewTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        viewTitle.backgroundColor = [UIColor clearColor];
        viewTitle.shadowColor = [UIColor colorWithWhite:0.0 alpha:0];
        viewTitle.textAlignment = NSTextAlignmentCenter;
        viewTitle.textColor = [UIColor whiteColor];
        viewTitle.text = [item objectForKey:@"label"];
        [viewTitle sizeThatFits:CGSizeMake(140, 40)];
        sheetActions = [[NSMutableArray alloc] initWithObjects:NSLocalizedString(@"Queue after current", nil), NSLocalizedString(@"Queue", nil), NSLocalizedString(@"Play", nil), nil];
        NSDictionary *resumePointDict = [item objectForKey:@"resume"];
        if (resumePointDict != nil){
            if (((NSNull *)[resumePointDict objectForKey:@"position"] != [NSNull null])){
                if ([[resumePointDict objectForKey:@"position"] floatValue]>0){
                    resumePointPercentage = ([[resumePointDict objectForKey:@"position"] floatValue] * 100) / [[resumePointDict objectForKey:@"total"] floatValue];
                    [sheetActions addObject:[NSString stringWithFormat:NSLocalizedString(@"Resume from %@", nil), [self convertTimeFromSeconds:[NSNumber numberWithFloat:[[resumePointDict objectForKey:@"position"] floatValue]]]]];
                }
            }
        }
//        if ([[item objectForKey:@"family"] isEqualToString:@"movieid"] || [[item objectForKey:@"family"] isEqualToString:@"episodeid"]|| [[item objectForKey:@"family"] isEqualToString:@"musicvideoid"]){
//            NSString *actionString = @"";
//            if ([[item objectForKey:@"playcount"] intValue] == 0){
//                actionString = NSLocalizedString(@"Mark as watched", nil);
//            }
//            else{
//                actionString = NSLocalizedString(@"Mark as unwatched", nil);
//            }
//            [sheetActions addObject:actionString];
//        }
        BOOL fromAlbumView = NO;
        if (((NSNull *)[item objectForKey:@"fromAlbumView"] != [NSNull null])){
            fromAlbumView = [[item objectForKey:@"fromAlbumView"] boolValue];
        }
        BOOL fromEpisodesView = NO;
        if (((NSNull *)[item objectForKey:@"fromEpisodesView"] != [NSNull null])){
            fromEpisodesView = [[item objectForKey:@"fromEpisodesView"] boolValue];
        }
        UIBarButtonItem *extraButton = nil;
        int titleWidth = 350;
        if ([[item objectForKey:@"family"] isEqualToString:@"albumid"]){
            UIImage* extraButtonImg = [UIImage imageNamed:@"st_song_icon"];
            if (fromAlbumView){
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
            }
            else{
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(showContent:)];
            }
            titleWidth = 350;
        }
        else if ([[item objectForKey:@"family"] isEqualToString:@"artistid"]){
            UIImage* extraButtonImg = [UIImage imageNamed:@"st_album_icon"];
            extraButton =[[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(showContent:)];
            titleWidth = 350;
        }
        else if ([[item objectForKey:@"family"] isEqualToString:@"tvshowid"]){
            UIImage* extraButtonImg = [UIImage imageNamed:@"st_tv_icon"];
            if (fromEpisodesView){
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
            }
            else{
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(showContent:)];
            }
            titleWidth = 350;
        }
        else if ([[item objectForKey:@"family"] isEqualToString:@"broadcastid"]){
            NSString *pvrAction = [[item objectForKey:@"hastimer"] boolValue] == YES ? NSLocalizedString(@"Stop Recording", nil) :  NSLocalizedString(@"Record", nil);
            sheetActions = [[NSMutableArray alloc] initWithObjects:
                            NSLocalizedString(@"Play", nil),
                            pvrAction,
                            nil];
            titleWidth = 350;
        }
//        else if ([[item objectForKey:@"family"] isEqualToString:@"episodeid"] || [[item objectForKey:@"family"] isEqualToString:@"movieid"] || [[item objectForKey:@"family"] isEqualToString:@"musicvideoid"]){
//            [sheetActions addObject:NSLocalizedString(@"Open with VLC", nil)];
//            titleWidth = 400;
//        }
        else{
            titleWidth = 400;
        }
        if ([[item objectForKey:@"trailer"] isKindOfClass:[NSString class]]){
            if ([[item objectForKey:@"trailer"] length] > 0){
                [sheetActions addObject:NSLocalizedString(@"Play Trailer", nil)];
            }
        }
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            toolbar = [UIToolbar new];
            toolbar.barStyle = UIBarStyleBlack;
            toolbar.translucent = YES;
            UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            actionSheetButtonItemIpad = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(showActionSheet)];
            actionSheetButtonItemIpad.style = UIBarButtonItemStylePlain;
            viewTitle.numberOfLines=1;
            viewTitle.font = [UIFont boldSystemFontOfSize:22];
            viewTitle.minimumScaleFactor = 6.0f/22.0f;
            viewTitle.adjustsFontSizeToFitWidth = YES;
            viewTitle.shadowOffset = CGSizeMake(1.0, 1.0);
            viewTitle.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.7];
            viewTitle.autoresizingMask = UIViewAutoresizingNone;
            viewTitle.contentMode = UIViewContentModeScaleAspectFill;
            [viewTitle setFrame:CGRectMake(0, 0, titleWidth, 44)];
            [viewTitle sizeThatFits:CGSizeMake(titleWidth, 44)];
            viewTitle.textAlignment = NSTextAlignmentLeft;
            UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithCustomView:viewTitle];
            if (extraButton == nil){
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
        else{
//            self.navigationItem.titleView = viewTitle;
            self.navigationItem.title = [item objectForKey:@"label"];
            UIBarButtonItem *actionSheetButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(showActionSheet)];
            if (extraButton == nil){
                self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:
                                                           actionSheetButtonItem,
                                                           nil];
            }
            else{
                self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:
                                                           actionSheetButtonItem,
                                                           extraButton,
                                                           nil];
            }
            UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromRight:)];
            rightSwipe.numberOfTouchesRequired = 1;
            rightSwipe.cancelsTouchesInView=NO;
            rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
            [self.view addGestureRecognizer:rightSwipe];
        }
    }
    if (![[self.detailItem objectForKey:@"disableNowPlaying"] boolValue]){
        UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromLeft:)];
        leftSwipe.numberOfTouchesRequired = 1;
        leftSwipe.cancelsTouchesInView=NO;
        leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.view addGestureRecognizer:leftSwipe];
    }
}

#pragma mark - Utility 

-(void)dismissModal:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//-(BOOL)isModal {
//    BOOL isModal = ((self.parentViewController && self.parentViewController.modalViewController == self) ||
//                    ( self.navigationController && self.navigationController.parentViewController && self.navigationController.parentViewController.modalViewController == self.navigationController) ||
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

-(void)goBack:(id)sender{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        [self.navigationController popViewControllerAnimated:YES];
    }
    else{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationEnableStackPan" object: nil];
    }
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

#pragma mark - ToolBar button

- (NSDictionary *) indexKeyedDictionaryFromArray:(NSArray *)array {
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    NSInteger numelement = [array count];
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

-(void)showContent:(id)sender{
    NSDictionary *item=self.detailItem;
    mainMenu *MenuItem = nil;
    mainMenu *choosedMenuItem = nil;
    choosedTab = 0;
    id movieObj = nil;
    id movieObjKey = nil;
    NSString *blackTableSeparator=@"NO";
    if ([[item objectForKey:@"family"] isEqualToString:@"albumid"]){
        notificationName = @"UIApplicationEnableMusicSection";
        MenuItem = [[AppDelegate instance].playlistArtistAlbums copy];
        choosedMenuItem = MenuItem.subItem;
        choosedMenuItem.mainLabel=[NSString stringWithFormat:@"%@", [item objectForKey:@"label"]];

    }
    else if ([[item objectForKey:@"family"] isEqualToString:@"tvshowid"] && ![sender isKindOfClass:[NSString class]]){
        notificationName = @"UIApplicationEnableTvShowSection";
        MenuItem = [[AppDelegate instance].playlistTvShows copy];
        choosedMenuItem = MenuItem.subItem;
        choosedMenuItem.mainLabel=[NSString stringWithFormat:@"%@", [item objectForKey:@"label"]];

    }
    else if ([[item objectForKey:@"family"] isEqualToString:@"artistid"]){
        notificationName = @"UIApplicationEnableMusicSection";
        choosedTab = 1;
        MenuItem = [[AppDelegate instance].playlistArtistAlbums copy];
        choosedMenuItem = MenuItem.subItem;
        choosedMenuItem.mainLabel=[NSString stringWithFormat:@"%@", [item objectForKey:@"label"]];

    }
    else if ([[item objectForKey:@"family"] isEqualToString:@"movieid"] && [AppDelegate instance].serverVersion>11){
        if ([sender isKindOfClass:[NSString class]]){
            NSString *actorName = (NSString *)sender;
            choosedTab = 2;
            MenuItem = [[AppDelegate instance].playlistMovies copy];
            movieObj = [NSDictionary dictionaryWithObjectsAndKeys:actorName,@"actor", nil];
            movieObjKey = @"filter";
            choosedMenuItem = MenuItem.subItem;
            choosedMenuItem.mainLabel=actorName;
        }
    }
    else if (([[item objectForKey:@"family"] isEqualToString:@"episodeid"] || [[item objectForKey:@"family"] isEqualToString:@"tvshowid"]) && [AppDelegate instance].serverVersion>11){
        if ([sender isKindOfClass:[NSString class]]){
            NSString *actorName = (NSString *)sender;
            choosedTab = 0;
            MenuItem = [[AppDelegate instance].playlistTvShows copy];
            movieObj = [NSDictionary dictionaryWithObjectsAndKeys:actorName,@"actor", nil];
            movieObjKey = @"filter";
            choosedMenuItem = MenuItem;
            choosedMenuItem.mainLabel=actorName;
            [MenuItem setEnableSection:NO];
            [MenuItem setMainButtons:nil];
            if ([AppDelegate instance].obj.preferTVPosters==YES){
                thumbWidth = PHONE_TV_SHOWS_POSTER_WIDTH;
                tvshowHeight = PHONE_TV_SHOWS_POSTER_HEIGHT;
            }
            MenuItem.thumbWidth=thumbWidth;
            MenuItem.rowHeight=tvshowHeight;
            blackTableSeparator=@"YES";
        }
    }
    else{
        return;
    }
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[choosedMenuItem mainMethod] objectAtIndex:choosedTab]];
    if ([methods objectForKey:@"method"]!=nil){ // THERE IS A CHILD
        NSDictionary *mainFields=[[MenuItem mainFields] objectAtIndex:choosedTab];
        NSMutableDictionary *parameters=[self indexKeyedMutableDictionaryFromArray:[[choosedMenuItem mainParameters] objectAtIndex:choosedTab]];
        id obj = [NSNumber numberWithInt:[[item objectForKey:[mainFields objectForKey:@"row6"]] intValue]];
        id objKey = [mainFields objectForKey:@"row6"];
        if (movieObj!= nil && movieObjKey!=nil){
            obj = movieObj;
            objKey = movieObjKey;
        }
        else if ([AppDelegate instance].serverVersion>11 && [[parameters objectForKey:@"disableFilterParameter"] boolValue] == FALSE){
            obj = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[[item objectForKey:[mainFields objectForKey:@"row6"]] intValue]],[mainFields objectForKey:@"row6"], nil];
            objKey = @"filter";
        }
        NSMutableDictionary *newSectionParameters = nil;
        if ([parameters objectForKey:@"extra_section_parameters"] != nil){
            newSectionParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    obj, objKey,
                                    [[parameters objectForKey:@"extra_section_parameters"] objectForKey:@"properties"], @"properties",
                                    [[parameters objectForKey:@"extra_section_parameters"] objectForKey:@"sort"],@"sort",
                                    [item objectForKey:[mainFields objectForKey:@"row6"]], [mainFields objectForKey:@"row6"],
                                    nil];
        }
        NSMutableArray *newParameters=[NSMutableArray arrayWithObjects:
                                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        obj,objKey,
                                        [[parameters objectForKey:@"parameters"] objectForKey:@"properties"], @"properties",
                                        [[parameters objectForKey:@"parameters"] objectForKey:@"sort"],@"sort",
                                        nil], @"parameters",
                                       blackTableSeparator, @"blackTableSeparator",
                                       [parameters objectForKey:@"label"], @"label",
                                       [NSNumber numberWithBool:YES], @"fromShowInfo",
                                       [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"enableCollectionView"] boolValue]], @"enableCollectionView",
                                       [NSDictionary dictionaryWithDictionary:[parameters objectForKey:@"itemSizes"]], @"itemSizes",
                                       [parameters objectForKey:@"extra_info_parameters"], @"extra_info_parameters",
                                       [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"FrodoExtraArt"] boolValue]], @"FrodoExtraArt",
                                       [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"enableLibraryCache"] boolValue]], @"enableLibraryCache",
                                       [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"collectionViewRecentlyAdded"] boolValue]], @"collectionViewRecentlyAdded",
                                       newSectionParameters, @"extra_section_parameters",
                                       nil];
        [[choosedMenuItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
        choosedMenuItem.chooseTab=choosedTab;
        if (![[item objectForKey:@"disableNowPlaying"] boolValue]){
            choosedMenuItem.disableNowPlaying = NO;
        }
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
            self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
            self.detailViewController.detailItem = choosedMenuItem;
            [self.navigationController pushViewController:self.detailViewController animated:YES];
        }
        else{
            if (![self isModal]){
                DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:choosedMenuItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
                [[AppDelegate instance].windowController.stackScrollViewController enablePanGestureRecognizer];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object: nil];
            }
        }
    }
}

#pragma mark - UIWebView delegates

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSString *requestString = [[request URL] absoluteString];
    return (([requestString isEqualToString:@"about:blank"] || [requestString isEqualToString:embedVideoURL]) || ([embedVideoURL rangeOfString:@"http://www.youtube.com/embed/"].location == NSNotFound));
}

-(void)webViewDidStartLoad:(UIWebView *)webView{
    [embedVideoActivityIndicator startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    [embedVideoActivityIndicator stopAnimating];
}

-(void)loadUrl:(id)sender{
    [trailerView stopLoading];
    [embedVideoActivityIndicator startAnimating];
    [(UIButton *)sender setHidden:YES];
    [trailerView loadHTMLString:embedVideo baseURL:nil];
}

#pragma mark - ActionSheet

-(void)showActionSheet {
    if (actionSheetView.window){
        [actionSheetView dismissWithClickedButtonIndex:actionSheetView.cancelButtonIndex animated:YES];
        return;
    }
    NSInteger numActions = [sheetActions count];
    if (numActions){
        NSDictionary *item=self.detailItem;
        NSString *sheetTitle = [item objectForKey:@"label"];
        if ([[item objectForKey:@"family"] isEqualToString:@"broadcastid"]){
            sheetTitle = [[item objectForKey:@"pvrExtraInfo"] objectForKey:@"channel_name"];
        }
        actionSheetView = [[UIActionSheet alloc] initWithTitle:sheetTitle
                                                            delegate:self
                                                   cancelButtonTitle:nil
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:nil];
        actionSheetView.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        NSString *title;
        for (int i = 0; i < numActions; i++) {
             title = [sheetActions objectAtIndex:i];
            if ([title isEqualToString:NSLocalizedString(@"Record", nil)] && isRecording.alpha == 1.0f) {
                title = NSLocalizedString(@"Stop Recording", nil);
            }
            [actionSheetView addButtonWithTitle:title];
        }
        actionSheetView.cancelButtonIndex = [actionSheetView addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
            [actionSheetView showInView:self.view];
        }
        else{
            [actionSheetView showFromBarButtonItem:actionSheetButtonItemIpad animated:YES];
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex!=actionSheet.cancelButtonIndex){
        if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Queue after current", nil)]){
            [self addQueueAfterCurrent:YES];

        }
        else if([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Queue", nil)]){
            [self addQueueAfterCurrent:NO];
        }
        else if([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Play", nil)]){
            [self addPlayback:0.0];
        }
        else if (([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Record", nil)] || [[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Stop Recording", nil)])) {
            [self recordChannel];
        }
        else if([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Open with VLC", nil)]){
            [self openWithVLC:self.detailItem];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] rangeOfString:NSLocalizedString(@"Resume from", nil)].location!= NSNotFound){
            [self addPlayback:resumePointPercentage];
            return;
        }
        else if([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Play Trailer", nil)]){
            [self openFile:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: [self.detailItem objectForKey:@"trailer"], @"file", nil], @"item", nil]];
        }
    }
}

-(void)animateRecordAction {
    [UIView animateWithDuration: 0.2f
                          delay: 0.0f
                        options: UIViewAnimationOptionCurveEaseOut
                     animations: ^{
                         CGRect frame;
                         frame = voteLabel.frame;
                         if (isRecording.alpha == 0.0f) {
                             isRecording.alpha = 1.0f;
                             frame.origin.x += dotSize + dotSizePadding;
                             frame.size.width -= dotSize + dotSizePadding;
                             [voteLabel setFrame:frame];
                         }
                         else {
                             isRecording.alpha = 0.0f;
                             frame.origin.x -= dotSize + dotSizePadding;
                             frame.size.width += dotSize + dotSizePadding;
                             [voteLabel setFrame:frame];
                         }
                     }
                     completion: ^(BOOL finished) {
                     }];
}

-(void)recordChannel {
    NSNumber *channelid = [NSNumber numberWithInt:[[[self.detailItem objectForKey:@"pvrExtraInfo"] objectForKey:@"channelid"] intValue]];
    if ([channelid isEqualToValue:[NSNumber numberWithInt:0]]) {
        return;
    }
    NSString *methodToCall = @"PVR.Record";
    NSString *parameterName = @"channel";
    NSNumber *itemid = [NSNumber numberWithInt:[[self.detailItem objectForKey:@"channelid"] intValue]];
    NSNumber *storeChannelid = itemid;
    NSNumber *storeBroadcastid = [NSNumber numberWithInt:[[self.detailItem objectForKey:@"broadcastid"] intValue]];
    if ([itemid isEqualToValue:[NSNumber numberWithInt:0]]) {
        itemid = [NSNumber numberWithInt:[[[self.detailItem objectForKey:@"pvrExtraInfo"] objectForKey:@"channelid"] intValue]];
        if ([itemid isEqualToValue:[NSNumber numberWithInt:0]]) {
            return;
        }
        storeChannelid = itemid;
        NSDateFormatter *xbmcDateFormatter = [[NSDateFormatter alloc] init];
        [xbmcDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
        NSDate *starttime = [xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", [self.detailItem objectForKey:@"starttime"]]];
        NSDate *endtime = [xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", [self.detailItem objectForKey:@"endtime"]]];
        float total_seconds = [endtime timeIntervalSince1970] - [starttime timeIntervalSince1970];
        float elapsed_seconds = [[NSDate date] timeIntervalSince1970] - [starttime timeIntervalSince1970];
        float percent_elapsed = (elapsed_seconds/total_seconds) * 100.0f;
        if (percent_elapsed < 0) {
            itemid = [NSNumber numberWithInt:[[self.detailItem objectForKey:@"broadcastid"] intValue]];
            storeBroadcastid = itemid;
            storeChannelid = [NSNumber numberWithInteger:0];
            methodToCall = @"PVR.ToggleTimer";
            parameterName = @"broadcastid";
        }
    }
    self.navigationItem.rightBarButtonItem.enabled=NO;
    [activityIndicatorView startAnimating];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                itemid, parameterName,
                                nil];
    [jsonRPC callMethod:methodToCall
         withParameters:parameters
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               [activityIndicatorView stopAnimating];
               self.navigationItem.rightBarButtonItem.enabled=YES;
               if (error == nil && methodError == nil) {
                   [self animateRecordAction];
                   NSNumber *status = [NSNumber numberWithBool:![[self.detailItem objectForKey:@"isrecording"] boolValue]];
                   if ([[self.detailItem objectForKey:@"broadcastid"] intValue] > 0) {
                       status = [NSNumber numberWithBool:![[self.detailItem objectForKey:@"hastimer"] boolValue]];
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
                   if (methodError != nil) {
                       message = [NSString stringWithFormat:@"%@\n\n%@\n", methodError, message];
                   }
                   if (error != nil) {
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

-(IBAction)scrollDown:(id)sender{
    CGPoint bottomOffset = CGPointMake(0, scrollView.contentSize.height - scrollView.bounds.size.height);
    [scrollView setContentOffset:bottomOffset animated:YES];
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
        self.navigationItem.rightBarButtonItem.enabled=YES;
        alreadyPush=YES;
    }
}

-(void)moveLabel:(NSArray *)objects posY:(int)y{
    NSInteger count = [objects count];
    CGRect frame;
    for (int i = 0; i < count; i++){
        if ([[objects objectAtIndex:i] isKindOfClass:[UIImageView class]]){
            UIImageView *label=[objects objectAtIndex:i];
            frame=label.frame;
            frame.origin.y=frame.origin.y - y;
            label.frame=frame;
        }
        if ([[objects objectAtIndex:i] isKindOfClass:[UILabel class]]){
            UILabel *label=[objects objectAtIndex:i];
            frame=label.frame;
            frame.origin.y=frame.origin.y - y;
            label.frame=frame;
        }
        
    }
}

-(void)setAndMoveLabels:(NSArray *)arrayLabels size:(int)moveSize{
    UIFont *fontFace=[UIFont systemFontOfSize:16];

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

int h=0;

-(void)setTvShowsToolbar{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        NSInteger count = [toolbar.items count];
        NSMutableArray *newToolbarItems = [toolbar.items mutableCopy];
        [newToolbarItems removeObjectAtIndex:(count - 1)];
        [newToolbarItems removeObjectAtIndex:(count - 2)];
        toolbar.items = newToolbarItems;
    }
    else{
        NSMutableArray *navigationItems = [self.navigationItem.rightBarButtonItems mutableCopy];
        [navigationItems removeObjectAtIndex:0];
        self.navigationItem.rightBarButtonItems=navigationItems;
    }
}

- (UIImage*)imageWithShadow:(UIImage *)source {
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef shadowContext = CGBitmapContextCreate(NULL, source.size.width + 20, source.size.height + 20, CGImageGetBitsPerComponent(source.CGImage), 0, colourSpace, kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colourSpace);
    
    CGContextSetShadowWithColor(shadowContext, CGSizeMake(0, 0), 10, [UIColor blackColor].CGColor);
    CGContextDrawImage(shadowContext, CGRectMake(10, 10, source.size.width, source.size.height), source.CGImage);
    
    CGImageRef shadowedCGImage = CGBitmapContextCreateImage(shadowContext);
    CGContextRelease(shadowContext);
    
    UIImage * shadowedImage = [UIImage imageWithCGImage:shadowedCGImage];
    CGImageRelease(shadowedCGImage);
    
    return shadowedImage;
}

- (UIImage*)imageWithBorderFromImage:(UIImage*)source{
    CGSize imgSize = [source size];
    UIGraphicsBeginImageContext(imgSize);
    CGRect rect = CGRectMake(0, 0, imgSize.width, imgSize.height);
    [source drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0); 
    CGFloat borderWidth = 2.0;
	CGContextSetLineWidth(context, borderWidth);
    CGContextStrokeRect(context, rect);
    
    UIImage *Img =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [self imageWithShadow:Img];
}

-(bool)enableJewelCases{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    return [[userDefaults objectForKey:@"jewel_preference"] boolValue];
}

-(void)elaborateImage:(UIImage *)image{
    [activityIndicatorView startAnimating];
    UIImage *elabImage = [self imageWithBorderFromImage:image];
    [self performSelectorOnMainThread:@selector(showImage:) withObject:elabImage waitUntilDone:YES];    
}

-(void)showImage:(UIImage *)image{
    [activityIndicatorView stopAnimating];
    jewelView.alpha = 0;
    jewelView.image = image;
    [self alphaImage:jewelView AnimDuration:0.1 Alpha:1.0f];
}

-(void)setIOS7barTintColor:(UIColor *)tintColor{
    self.navigationController.navigationBar.tintColor = tintColor;
    toolbar.tintColor = tintColor;
}

-(void)createInfo{
    // NEED TO BE OPTIMIZED. IT WORKS BUT THERE ARE TOO MANY IFS!
    NSDictionary *item=self.detailItem;
    NSString *placeHolderImage = @"coverbox_back.png";
//    NSLog(@"ITEM %@", item);
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
    clearLogoWidth = 300;
    clearLogoHeight = 116;
    thumbWidth = PHONE_TV_SHOWS_BANNER_WIDTH;
    tvshowHeight = PHONE_TV_SHOWS_BANNER_HEIGHT;
    int shiftParentalRating = -20;
    NSString *contributorString = @"cast";
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        clearLogoWidth = 457;
        clearLogoHeight = 177;
        thumbWidth = PAD_TV_SHOWS_BANNER_WIDTH;
        tvshowHeight = PAD_TV_SHOWS_BANNER_HEIGHT;
        shiftParentalRating = -40;
        labelSpace = 33;
        placeHolderImage = @"coverbox_back@2x.png";
        castFontSize = 16;
        size = 6;
        castWidth = 75;
        castHeight = 105;
        pageSize = STACKSCROLL_WIDTH - 40;
        if ([self isModal]){
            pageSize = 540 - 40;
        }
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

        NSArray *arrayLabels=[NSArray arrayWithObjects:
                              label1,
                              directorLabel, 
                              label2,
                              genreLabel,
                              label3,
                              runtimeLabel,
                              label4,
                              studioLabel,
                              label5,
                              summaryLabel,
                              parentalRatingLabelUp,
                              parentalRatingLabel,
                              label6,
                              nil];
        [self setAndMoveLabels:arrayLabels size:size];
    }
    else {
        float transform = 1.0f;
        if (IS_IPHONE_6) {
            transform = 1.18f;
        }
        else if (IS_IPHONE_6_PLUS){
            transform = 1.294f;
        }
        thumbWidth = (int)(PHONE_TV_SHOWS_BANNER_WIDTH * transform);
        tvshowHeight = (int)(PHONE_TV_SHOWS_BANNER_HEIGHT * transform);
        if (!enableJewel) {
            CGRect frame = jewelView.frame;
            frame.origin.x = frame.origin.x + 4;
            jewelView.frame = frame;
        }
    }
    if ([[item objectForKey:@"family"] isEqualToString:@"episodeid"] || [[item objectForKey:@"family"] isEqualToString:@"tvshowid"]){
        int deltaY=0;
        int coverHeight=0;
        CGRect frame;
        placeHolderImage = @"coverbox_back_tvshows";
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            placeHolderImage = @"coverbox_back_tvshows@2x.png";
        }
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:NSLocalizedString(@"LocaleIdentifier",nil)];
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setLocale:locale];
        if ([[item objectForKey:@"family"] isEqualToString:@"tvshowid"]){
            GlobalData *obj=[GlobalData getInstance];
            if (obj.preferTVPosters==NO && [AppDelegate instance].serverVersion < 12){
                placeHolderImage = @"";
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
                    coverHeight=70;
                    deltaY=coverView.frame.size.height - coverHeight;
                    jewelView.hidden=YES;
                    frame=coverView.frame;
                    frame.origin.x=0;
                    frame.origin.y=12;
                    frame.size.width=320;
                    frame.size.height=59;
                    coverView.frame=frame;
                    jewelView.frame = frame;
                }
                else {
                    coverHeight=90;
                    deltaY=coverView.frame.size.height - coverHeight;
                    jewelView.hidden=YES;
                    frame=coverView.frame;
                    frame.origin.x=-78;
                    frame.origin.y=12;
                    frame.size.width=STACKSCROLL_WIDTH;
                    frame.size.height=90;
                    coverView.frame=frame;
                    jewelView.frame = frame;
                }
            }
            else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
                int originalHeight = jewelView.frame.size.height;
                int coverHeight = 560;
                int coverWidth = STACKSCROLL_WIDTH;
                CGRect frame;
                frame = jewelView.frame;
                frame.origin.x = 0;
                frame.size.height = coverHeight;
                frame.size.width = coverWidth;
                jewelView.frame = frame;
                frame=coverView.frame;
                frame.origin.x = 87;
                frame.origin.y = 24;
                frame.size.width = 353;
                frame.size.height = 518;
                coverView.autoresizingMask = UIViewAutoresizingNone;
                coverView.contentMode = UIViewContentModeScaleAspectFill;
                coverView.frame = frame;
                deltaY = -(coverHeight - originalHeight);
            }
            label1.text = NSLocalizedString(@"EPISODES", nil);
            label3.text = NSLocalizedString(@"GENRE", nil);
            label4.text = NSLocalizedString(@"STUDIO", nil);
            directorLabel.text = [[item objectForKey:@"showtitle"] length] == 0 ? @"-" : [item objectForKey:@"showtitle"];
            [format setDateFormat:@"yyyy-MM-dd"];
            NSDate *date = [format dateFromString:[item objectForKey:@"premiered"]];
            [format setDateFormat:NSLocalizedString(@"LongDateTimeFormat", nil)];
            genreLabel.text = date == nil ? @"-" : [format stringFromDate:date];
            if ([[item objectForKey:@"genre"] isKindOfClass:NSClassFromString(@"JKArray")] ||
                [[item objectForKey:@"genre"] isKindOfClass:[NSArray class]]){
                runtimeLabel.text=[[item objectForKey:@"genre"] componentsJoinedByString:@" / "];
                runtimeLabel.text=[runtimeLabel.text length]==0 ? @"-" : runtimeLabel.text;
            }
            else{
                runtimeLabel.text=[[item objectForKey:@"genre"] length]==0 ? @"-" : [item objectForKey:@"genre"];
            }
            if ([[item objectForKey:@"studio"] isKindOfClass:NSClassFromString(@"JKArray")] ||
                [[item objectForKey:@"studio"] isKindOfClass:[NSArray class]]){
                studioLabel.text=[[item objectForKey:@"studio"] componentsJoinedByString:@" / "];
                studioLabel.text=[studioLabel.text length]==0 ? @"-" : studioLabel.text;
            }
            else{
                studioLabel.text=[[item objectForKey:@"studio"] length]==0 ? @"-" : [item objectForKey:@"studio"];
            }
            numVotesLabel.hidden = YES;
            [self setTvShowsToolbar];
        }
        else if ([[item objectForKey:@"family"] isEqualToString:@"episodeid"]){
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
                coverHeight = 280;
                jewelView.hidden = NO;
                deltaY = jewelView.frame.size.height - coverHeight;
                coverView.autoresizingMask = UIViewAutoresizingNone;
                coverView.contentMode = UIViewContentModeScaleAspectFill;
                frame = coverView.frame;
                frame.origin.x = 32;
                frame.origin.y = 20;
                frame.size.width = 414;
                frame.size.height = 232;
                coverView.frame = frame;
            }
            else{
                coverHeight = 200;
                jewelView.hidden = NO;
                deltaY = jewelView.frame.size.height - coverHeight;
                frame = coverView.frame;
                frame.origin.x = 11;
                frame.origin.y = 17;
                frame.size.width = 297;
                frame.size.height = 167;
                coverView.frame = frame;
            }
            label1.text = NSLocalizedString(@"TV SHOW", nil);
            label3.text = NSLocalizedString(@"DIRECTOR", nil);
            label4.text = NSLocalizedString(@"WRITER", nil);
            parentalRatingLabelUp.hidden = YES;
            parentalRatingLabel.hidden = YES;
            
            frame = label6.frame;
            frame.origin.y = frame.origin.y + shiftParentalRating;
            label6.frame = frame;
            if (enableJewel){
                jewelView.image = [UIImage imageNamed:@"jewel_tv.9.png"];
            }
            frame = jewelView.frame;
            frame.size.height = coverHeight;
            jewelView.frame = frame;
            directorLabel.text = [[item objectForKey:@"showtitle"] length]==0 ? @"-" : [item objectForKey:@"showtitle"];
            

            NSString *aired = @"-";
            if ([[item objectForKey:@"firstaired"] length] > 0) {
                [format setDateFormat:@"yyyy-MM-dd"];
                NSDate *date = [format dateFromString:[item objectForKey:@"firstaired"]];
                [format setDateFormat:NSLocalizedString(@"LongDateTimeFormat", nil)];
                aired = [format stringFromDate:date];
            }
            genreLabel.text = aired;
            if ([[item objectForKey:@"director"] isKindOfClass:NSClassFromString(@"JKArray")] ||
                [[item objectForKey:@"director"] isKindOfClass:[NSArray class]]){
                runtimeLabel.text = [[item objectForKey:@"director"] componentsJoinedByString:@" / "];
                runtimeLabel.text = [runtimeLabel.text length]==0 ? @"-" : runtimeLabel.text;
            }
            else{
                runtimeLabel.text = [[item objectForKey:@"director"] length]==0 ? @"-" : [item objectForKey:@"director"];
            }
            if ([[item objectForKey:@"writer"] isKindOfClass:NSClassFromString(@"JKArray")] ||
                [[item objectForKey:@"writer"] isKindOfClass:[NSArray class]]){
                studioLabel.text = [[item objectForKey:@"writer"] componentsJoinedByString:@" / "];
                studioLabel.text = [studioLabel.text length]==0 ? @"-" : studioLabel.text;
            }
            else{
                studioLabel.text=[[item objectForKey:@"writer"] length]==0 ? @"-" : [item objectForKey:@"writer"];
            }
            shiftParentalRating = 0;
        }
        [self moveLabel:[NSArray arrayWithObjects:starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:deltaY];
        
        label2.text=NSLocalizedString(@"FIRST AIRED", nil);
        label5.text=NSLocalizedString(@"SUMMARY", nil);
        
        frame=starsView.frame;
        frame.origin.x=frame.origin.x+29;
        starsView.frame=frame;
        
        frame=voteLabel.frame;
        frame.origin.x=frame.origin.x+29;
        voteLabel.frame=frame;
    }
    else if ([[item objectForKey:@"family"] isEqualToString:@"albumid"]){
        
        int coverHeight = 380;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
            coverHeight = 290;
        }
        [self moveLabel:[NSArray arrayWithObjects:starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:40];
        jewelView.hidden = NO;
        int deltaY = jewelView.frame.size.height - coverHeight;
        label1.text = NSLocalizedString(@"ARTIST", nil);
        label2.text = NSLocalizedString(@"YEAR", nil);
        label3.text = NSLocalizedString(@"GENRE", nil);
        label4.text = NSLocalizedString(@"ALBUM LABEL", nil);
        label5.text = NSLocalizedString(@"DESCRIPTION", nil);
        label6.text = @"";
        
        starsView.hidden = YES;
        voteLabel.hidden = YES;
        numVotesLabel.hidden = YES;

        parentalRatingLabelUp.hidden = YES;
        parentalRatingLabel.hidden = YES;
        
        CGRect frame = label6.frame;
        frame.origin.y = frame.origin.y-40;
        label6.frame = frame;
        if (enableJewel){
            jewelView.image = [UIImage imageNamed:@"jewel_cd.9.png"];
        }
        frame = jewelView.frame;
        frame.size.height = coverHeight;
        jewelView.frame = frame;
        
        frame = coverView.frame;
        frame.origin.x = 5;
        frame.origin.y = 24;
        frame.size.width = 336;
        frame.size.height = 336;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
            frame.origin.x = 42;
            frame.origin.y = 22;
            frame.size.width = 256;
            frame.size.height = 256;
        }
        else {
            frame.origin.x = 80;
        }
        coverView.frame = frame;
        if ([[item objectForKey:@"artist"] isKindOfClass:NSClassFromString(@"JKArray")] ||
            [[item objectForKey:@"artist"] isKindOfClass:[NSArray class]]){
            directorLabel.text = [[item objectForKey:@"artist"] componentsJoinedByString:@" / "];
            directorLabel.text = [directorLabel.text length]==0 ? @"-" : directorLabel.text;
        }
        else{
            directorLabel.text = [[item objectForKey:@"artist"] length] == 0 ? @"-" : [item objectForKey:@"artist"];
        }
        genreLabel.text = [[item objectForKey:@"year"] length] == 0 ? @"-" : [item objectForKey:@"year"];
        if ([[item objectForKey:@"genre"] isKindOfClass:NSClassFromString(@"JKArray")] ||
            [[item objectForKey:@"genre"] isKindOfClass:[NSArray class]]){
            runtimeLabel.text = [[item objectForKey:@"genre"] componentsJoinedByString:@" / "];
            runtimeLabel.text = [runtimeLabel.text length]==0 ? @"-" : runtimeLabel.text;
        }
        else{
            runtimeLabel.text = [[item objectForKey:@"genre"] length] == 0 ? @"-" : [item objectForKey:@"genre"];
        }
        studioLabel.text = [[item objectForKey:@"albumlabel"] length] == 0 ? @"-" : [item objectForKey:@"albumlabel"];
        [self moveLabel:[NSArray arrayWithObjects:starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:deltaY];
    }
    else if ([[item objectForKey:@"family"] isEqualToString:@"artistid"]){
        contributorString = @"roles";
        castHeight -= 26;
        placeHolderImage = @"coverbox_back_artists.png";
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            placeHolderImage = @"coverbox_back_artists@2x.png";
        }
        enableJewel = NO;
        jewelView.image = nil;
        int shiftY = 40;
        [self moveLabel:[NSArray arrayWithObjects:starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:shiftY];
        [self moveLabel:[NSArray arrayWithObjects:label4, label5, label6, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:40];
        label1.text = NSLocalizedString(@"GENRE", nil);
        label2.text = NSLocalizedString(@"STYLE", nil);
        label3.text = @"";
        label4.text = NSLocalizedString(@"BORN / FORMED", nil);
        label5.text = NSLocalizedString(@"DESCRIPTION", nil);
        label6.text = NSLocalizedString(@"MUSIC ROLES", nil);
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
        if ([[item objectForKey:@"genre"] isKindOfClass:NSClassFromString(@"JKArray")] ||
            [[item objectForKey:@"genre"] isKindOfClass:[NSArray class]]){
            directorLabel.text = [[item objectForKey:@"genre"] componentsJoinedByString:@" / "];
            directorLabel.text = [directorLabel.text length]==0 ? @"-" : directorLabel.text;
        }
        else{
            directorLabel.text = [[item objectForKey:@"genre"] length] == 0 ? @"-" : [item objectForKey:@"genre"];
        }
        
        if ([[item objectForKey:@"style"] isKindOfClass:NSClassFromString(@"JKArray")] ||
            [[item objectForKey:@"style"] isKindOfClass:[NSArray class]]){
            genreLabel.text = [[item objectForKey:@"style"] componentsJoinedByString:@" / "];
            genreLabel.text = [genreLabel.text length]==0 ? @"-" : genreLabel.text;
        }
        else{
            genreLabel.text = [[item objectForKey:@"style"] length] == 0 ? @"-" : [item objectForKey:@"style"];
        }
        genreLabel.numberOfLines = 0;
        CGSize maximunLabelSize= CGSizeMake(pageSize, 9999);
        CGRect expectedLabelRect = [genreLabel.text boundingRectWithSize:maximunLabelSize
                                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                                              attributes:@{NSFontAttributeName:genreLabel.font}
                                                                 context:nil];
        CGSize expectedLabelSize = expectedLabelRect.size;
        
        //adjust the label the the new height.
        CGRect newFrame = genreLabel.frame;
        newFrame.size.height = expectedLabelSize.height + size;
        genreLabel.frame = newFrame;
        [self moveLabel:[NSArray arrayWithObjects:label3, label4, label5, label6, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:-(expectedLabelSize.height - labelSpace)];
        
        if ([[item objectForKey:@"born"] isKindOfClass:NSClassFromString(@"JKArray")] ||
            [[item objectForKey:@"born"] isKindOfClass:[NSArray class]]){
            studioLabel.text = [[item objectForKey:@"born"] componentsJoinedByString:@" / "];
            studioLabel.text = [studioLabel.text length]==0 ? @"-" : studioLabel.text;
        }
        else{
            studioLabel.text = [[item objectForKey:@"born"] length] == 0 ? @"-" : [item objectForKey:@"born"];
        }
        
        if ([[item objectForKey:@"formed"] isKindOfClass:NSClassFromString(@"JKArray")] ||
            [[item objectForKey:@"formed"] isKindOfClass:[NSArray class]]){
            studioLabel.text = [[item objectForKey:@"formed"] componentsJoinedByString:@" / "];
            studioLabel.text = [studioLabel.text length]==0 ? @"-" : studioLabel.text;
        }
        else{
            studioLabel.text = [[item objectForKey:@"formed"] length] == 0 ? studioLabel.text : [item objectForKey:@"formed"];
        }
        
//        if ([directorLabel.text isEqualToString:@"-"]){
//            directorLabel.hidden = YES;
//            label1.hidden = YES;
//            [self moveLabel:[NSArray arrayWithObjects: label2, label4, label5, label6, genreLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:53];
//        }
//        
//        if ([genreLabel.text isEqualToString:@"-"]){
//            genreLabel.hidden = YES;
//            label2.hidden = YES;
//            [self moveLabel:[NSArray arrayWithObjects: label4, label5, label6, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:53];
//        }
        if ([studioLabel.text isEqualToString:@"-"]){
            studioLabel.hidden = YES;
            label4.hidden = YES;
            [self moveLabel:[NSArray arrayWithObjects: label5, label6, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:labelSpace + 20];
        }
    }
    else if ([[item objectForKey:@"family"] isEqualToString:@"broadcastid"] || [[item objectForKey:@"family"] isEqualToString:@"recordingid"]){
        label1.text = NSLocalizedString(@"TIME", nil);
        label5.text = NSLocalizedString(@"DESCRIPTION", nil);
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
//        summaryLabel.frame= runtimeLabel.frame;
        label5.frame = label2.frame;
        CGRect frame = genreLabel.frame;
        if ([[self.detailItem objectForKey:@"plotoutline"] length] > 0){
            label2.text = NSLocalizedString(@"PLOT OUTLINE", nil);
            label2.hidden = NO;
            genreLabel.hidden = NO;
            [genreLabel setText:[self.detailItem objectForKey:@"plotoutline"]];
            label5.frame = label3.frame;
            frame = runtimeLabel.frame;
        }
        frame.origin.y ++;
        summaryLabel.frame= frame;
         [self moveLabel:[NSArray arrayWithObjects: label1, label2, label5, label6, directorLabel, genreLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:(int)(jewelView.frame.size.height - (jewelView.frame.size.height/8))];
        frame = jewelView.frame;
        frame.origin.x = label1.frame.origin.x;
        frame.size.width = frame.size.width / 4;
        frame.size.height = frame.size.height /8;
        jewelView.frame = frame;
        frame = voteLabel.frame;
        frame.origin.y = jewelView.frame.origin.y;
        frame.origin.x = jewelView.frame.origin.x + jewelView.frame.size.width + 8;
        frame.size.width = pageSize - frame.origin.x;
        frame.size.height = jewelView.frame.size.height / 2.0f;
        voteLabel.frame = frame;
        voteLabel.numberOfLines = 2;
        [voteLabel setFont:[UIFont fontWithName:label1.font.fontName size:castFontSize]];
        [voteLabel setTextColor:directorLabel.textColor];
        frame = numVotesLabel.frame;
        frame.size.width = voteLabel.frame.size.width;
        frame.origin.y = (int)(voteLabel.frame.origin.y + voteLabel.frame.size.height + 10);
        frame.origin.x = voteLabel.frame.origin.x;
        numVotesLabel.frame = frame;
        [numVotesLabel setFont:[UIFont fontWithName:label1.font.fontName size:label1.font.pointSize]];
        if ([[item objectForKey:@"family"] isEqualToString:@"recordingid"]){
            numVotesLabel.text = [item objectForKey:@"channel"];
        }
        else if ([[item objectForKey:@"family"] isEqualToString:@"broadcastid"]) {
            [item setValue:[item objectForKey:@"genre"] forKey:@"plot"];
            numVotesLabel.text = [[item objectForKey:@"pvrExtraInfo"] objectForKey:@"channel_name"];
            frame = voteLabel.frame;
            dotSize = 10.0f;
            dotSizePadding = 4.0f;
            isRecording = [[UIImageView alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y + (frame.size.height/2.0f - dotSize/2.0f), dotSize, dotSize)];
            [isRecording setImage:[UIImage imageNamed:@"button_timer"]];
            [isRecording setContentMode:UIViewContentModeScaleAspectFill];
            isRecording.alpha = 0.0f;
            [isRecording setBackgroundColor:[UIColor clearColor]];
            [scrollView addSubview:isRecording];
            if ([[item objectForKey:@"hastimer"] boolValue] == YES) {
                isRecording.alpha = 1.0f;
                frame.origin.x += dotSize + dotSizePadding;
                frame.size.width -= dotSize + dotSizePadding;
                [voteLabel setFrame:frame];
            }
        }
        [item setValue:[item objectForKey:@"label"] forKey:@"rating"];
        [item setValue:[[item objectForKey:@"pvrExtraInfo"] objectForKey:@"channel_icon"] forKey:@"thumbnail"];
        placeHolderImage = @"nocover_channels";
        NSDateFormatter *xbmcDateFormatter = [[NSDateFormatter alloc] init];
        [xbmcDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
        NSDateFormatter *localFormatter = [[NSDateFormatter alloc] init];
        [localFormatter setDateFormat:@"ccc dd MMM, HH:mm"];
        localFormatter.timeZone = [NSTimeZone systemTimeZone];
        NSDate *startTime = [xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", [item objectForKey:@"starttime"]]];
        NSDate *endTime = [xbmcDateFormatter dateFromString:[NSString stringWithFormat:@"%@ UTC", [item objectForKey:@"endtime"]]];
        if (startTime != nil && endTime != nil) {
            directorLabel.text = [localFormatter stringFromDate:startTime];
            [localFormatter setDateFormat:@"HH:mm"];
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSUInteger unitFlags = NSCalendarUnitMinute;
            NSDateComponents *components = [gregorian components:unitFlags fromDate:startTime toDate:endTime options:0];
            NSInteger minutes = [components minute];
            directorLabel.text = [NSString stringWithFormat:@"%@ - %@ (%ld %@)", directorLabel.text, [localFormatter stringFromDate:endTime], (long)minutes, (long)minutes > 1 ? NSLocalizedString(@"Mins.", nil) : NSLocalizedString(@"Min", nil)];
        }
        else {
            directorLabel.text = @"-";
        }
//        UIImage *buttonImage = [UIImage imageNamed:@"button_record"];
//        UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeCustom];;
//        recordButton.frame = CGRectMake(0, 0, 200.0f, 29.0f);
//        [recordButton setImage:buttonImage forState:UIControlStateNormal];
//        frame = recordButton.frame;
//        frame.origin.x = label2.frame.origin.x;
//        frame.origin.y = label2.frame.origin.y + 4;
//        recordButton.frame = frame;
//        [recordButton setTitle:NSLocalizedString(@"Record", nil) forState:UIControlStateNormal];
//        [recordButton.titleLabel setFont:[UIFont fontWithName:directorLabel.font.fontName size:directorLabel.font.pointSize]];
//        [recordButton setTitleColor:label1.textColor forState:UIControlStateHighlighted];
//        recordButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
//        [recordButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
//        [recordButton setContentMode:UIViewContentModeScaleAspectFill];
//        recordButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 4.0f, 0.0, 0.0);
//        [scrollView addSubview:recordButton];
    }
    else {
        placeHolderImage = @"coverbox_back_movies.png";
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            placeHolderImage = @"coverbox_back_movies@2x.png";
            int originalHeight = jewelView.frame.size.height;
            int coverHeight = 560;
            int coverWidth = STACKSCROLL_WIDTH;
            CGRect frame;
            frame = jewelView.frame;
            frame.origin.x = 0;
            frame.size.height = coverHeight;
            frame.size.width = coverWidth;
            jewelView.frame = frame;
            frame=coverView.frame;
            frame.origin.x = 87;
            frame.origin.y = 24;
            frame.size.width = 353;
            frame.size.height = 518;
            coverView.autoresizingMask = UIViewAutoresizingNone;
            coverView.contentMode = UIViewContentModeScaleAspectFill;
            coverView.frame = frame;
            int deltaY = -(coverHeight - originalHeight);
            [self moveLabel:[NSArray arrayWithObjects:starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:deltaY];
        }
        if ([[item objectForKey:@"director"] isKindOfClass:NSClassFromString(@"JKArray")] ||
            [[item objectForKey:@"director"] isKindOfClass:[NSArray class]]){
            directorLabel.text = [[item objectForKey:@"director"] componentsJoinedByString:@" / "];
            directorLabel.text = [directorLabel.text length]==0 ? @"-" : directorLabel.text;
        }
        else{
            directorLabel.text = [[item objectForKey:@"director"] length]==0 ? @"-" : [item objectForKey:@"director"];
        }
        directorLabel.text = [[item objectForKey:@"year"] length] == 0 ? directorLabel.text : [NSString stringWithFormat:@"%@ (%@)", directorLabel.text, [item objectForKey:@"year"]];
        if ([[item objectForKey:@"genre"] isKindOfClass:NSClassFromString(@"JKArray")] ||
            [[item objectForKey:@"genre"] isKindOfClass:[NSArray class]]){
            genreLabel.text = [[item objectForKey:@"genre"] componentsJoinedByString:@" / "];
            genreLabel.text = [genreLabel.text length]==0 ? @"-" : genreLabel.text;
        }
        else{
            genreLabel.text = [[item objectForKey:@"genre"] length]==0 ? @"-" : [item objectForKey:@"genre"];
        }
        runtimeLabel.text = [[item objectForKey:@"runtime"] length]==0 ? @"-" : [item objectForKey:@"runtime"];
        if ([[item objectForKey:@"studio"] isKindOfClass:NSClassFromString(@"JKArray")] ||
            [[item objectForKey:@"studio"] isKindOfClass:[NSArray class]]){
            studioLabel.text = [[item objectForKey:@"studio"] componentsJoinedByString:@" / "];
            studioLabel.text = [studioLabel.text length]==0 ? @"-" : studioLabel.text;
        }
        else{
            studioLabel.text = [[item objectForKey:@"studio"] length]==0 ? @"-" : [item objectForKey:@"studio"];
        }
    }
    BOOL inEnableKenBurns = enableKenBurns;
    __weak ShowInfoViewController *sf = self;
    NSString *thumbnailPath = [item objectForKey:@"thumbnail"];
    if (![[item objectForKey:@"thumbnail"] isEqualToString:@""] && [item objectForKey:@"thumbnail"] != nil){
        jewelView.alpha = 0;
        [activityIndicatorView startAnimating];
    }
    [[SDImageCache sharedImageCache] queryDiskCacheForKey:thumbnailPath done:^(UIImage *image, SDImageCacheType cacheType) {
        if (image!=nil){
            Utilities *utils = [[Utilities alloc] init];
            UIColor *averageColor = [utils averageColor:image inverse:NO];
            foundTintColor = TINT_COLOR;
            CGFloat red, green, blue, alpha;
            [averageColor getRed:&red green:&green blue:&blue alpha:&alpha];
            if (alpha > 0){
                foundTintColor = [utils slightLighterColorForColor:[utils averageColor:image inverse:NO]];
            }
            self.navigationController.navigationBar.tintColor = foundTintColor;
            toolbar.tintColor = foundTintColor;
            if (enableJewel){
                coverView.image = image;
                [activityIndicatorView stopAnimating];
                jewelView.alpha = 1;
            }
            else{
                [NSThread detachNewThreadSelector:@selector(elaborateImage:) toTarget:self withObject:image];
            }
        }
        else{
            __weak ShowInfoViewController *sf = self;
            __block UIColor *newColor = nil;
            if (enableJewel){
                [coverView setImageWithURL:[NSURL URLWithString:thumbnailPath]
                          placeholderImage:[UIImage imageNamed:placeHolderImage]
                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                     if (error == nil){
                         if (image !=nil){
                             Utilities *utils = [[Utilities alloc] init];
                             newColor = [utils slightLighterColorForColor:[utils averageColor:image inverse:NO]];
                             [sf setIOS7barTintColor:newColor];
                         }
                     }
                 }];
                foundTintColor = newColor;
                [activityIndicatorView stopAnimating];
                jewelView.alpha = 1;
            }
            else{
                [jewelView setImageWithURL:[NSURL URLWithString:thumbnailPath]
                          placeholderImage:[UIImage imageNamed:placeHolderImage]
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                     if (image !=nil){
                                         if (error == nil){
                                             Utilities *utils = [[Utilities alloc] init];
                                             newColor = [utils slightLighterColorForColor:[utils averageColor:image inverse:NO]];
                                             [sf setIOS7barTintColor:newColor];
                                         }
                                         [NSThread detachNewThreadSelector:@selector(elaborateImage:) toTarget:sf withObject:image];
                                     }
                                 }
                 ];
                foundTintColor = newColor;
            }
        }
    }];
    
    NSString *fanartPath=[item objectForKey:@"fanart"];
    [[SDImageCache sharedImageCache] queryDiskCacheForKey:fanartPath done:^(UIImage *image, SDImageCacheType cacheType) {
        if (image!=nil){
            fanartView.image=image;
            if (inEnableKenBurns){
                fanartView.alpha = 0;
                [sf elabKenBurns:image];
                [sf alphaView:sf.kenView AnimDuration:1.5 Alpha:0.2];
            }
        }
        else{
            [fanartView setImageWithURL:[NSURL URLWithString:fanartPath]
                       placeholderImage:[UIImage imageNamed:@""]
                              completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                  if (inEnableKenBurns){
                                      [sf elabKenBurns:image];
                                      [sf alphaView:sf.kenView AnimDuration:1.5 Alpha:0.2];
                                  }
                              }
             ];
        }
        
    }];

    [fanartView setClipsToBounds:YES];
    
    voteLabel.text=[[item objectForKey:@"rating"] length]==0 ? @"N.A." : [item objectForKey:@"rating"];
    starsView.image=[UIImage imageNamed:[NSString stringWithFormat:@"stars_%.0f.png", round([[item objectForKey:@"rating"] doubleValue])]];
    
    NSString *numVotes=[[item objectForKey:@"votes"] length]==0 ? @"" : [item objectForKey:@"votes"];
    if ([numVotes length]!=0){
        NSString *numVotesPlus = NSLocalizedString(([numVotes isEqualToString:@"1"]) ? @"vote" : @"votes",nil);
        numVotesLabel.text=[NSString stringWithFormat:@"(%@ %@)",numVotes, numVotesPlus];
    }
    CGRect frame=summaryLabel.frame;
    summaryLabel.frame=frame;
    summaryLabel.text=[[item objectForKey:@"plot"] length]==0 ? @"-" : [item objectForKey:@"plot"];
    if ([[item objectForKey:@"family"] isEqualToString:@"albumid"] || [[item objectForKey:@"family"] isEqualToString:@"artistid"]){
        summaryLabel.text=[[item objectForKey:@"description"] length]==0 ? @"-" : [item objectForKey:@"description"];
    }
    CGSize maximunLabelSize= CGSizeMake(pageSize, 9999);
    CGRect expectedLabelRect = [summaryLabel.text  boundingRectWithSize:maximunLabelSize
                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                          attributes:@{NSFontAttributeName:summaryLabel.font}
                                                             context:nil];
    CGSize expectedLabelSize = expectedLabelRect.size;
    
    CGRect newFrame = summaryLabel.frame;
    newFrame.size.height = expectedLabelSize.height + size;
    summaryLabel.frame = newFrame;

    if ([[item objectForKey:@"mpaa"] length]==0){
        parentalRatingLabel.hidden = YES;
        parentalRatingLabelUp.hidden = YES;
    }
    else{
        frame = parentalRatingLabel.frame;
        frame.origin.y = frame.origin.y + summaryLabel.frame.size.height-20;
        parentalRatingLabel.frame = frame;
        
        frame = parentalRatingLabelUp.frame;
        frame.origin.y = frame.origin.y + summaryLabel.frame.size.height-20;
        parentalRatingLabelUp.frame = frame;
        
        frame = parentalRatingLabel.frame;
        frame.size.height = 2000;
        parentalRatingLabel.frame = frame;
        parentalRatingLabel.text = [[item objectForKey:@"mpaa"] length]==0 ? @"-" : [item objectForKey:@"mpaa"];
        
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
    if ([AppDelegate instance].serverVersion > 11){
        serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
    }
    frame = label6.frame;
    frame.origin.y = frame.origin.y + summaryLabel.frame.size.height + shiftParentalRating - 40;
    label6.frame = frame;
    int startY = label6.frame.origin.y - label6.frame.size.height + size;
    if ([[item objectForKey:@"trailer"] isKindOfClass:[NSString class]]){
        BOOL isYoutubeVideoLink = NO;
        if ([[item objectForKey:@"trailer"] length]> 0){
            NSString *param = nil;
            embedVideoURL = nil;
            
            if (([[item objectForKey:@"trailer"] rangeOfString:@"plugin://plugin.video.youtube"].location!= NSNotFound)){
                NSString *url = [[item objectForKey:@"trailer"] lastPathComponent];
                NSRange start = [url rangeOfString:@"videoid="];
                if (start.location != NSNotFound){
                    param = [url substringFromIndex:start.location + start.length];
                    NSRange end = [param rangeOfString:@"&"];
                    if (end.location != NSNotFound){
                        param = [param substringToIndex:end.location];
                    }
                }
                if ([param length] > 0){
                    NSString *param = nil;
                    NSString *url = [[item objectForKey:@"trailer"] lastPathComponent];
                    NSRange start = [url rangeOfString:@"videoid="];
                    if (start.location != NSNotFound){
                        param = [url substringFromIndex:start.location + start.length];
                        NSRange end = [param rangeOfString:@"&"];
                        if (end.location != NSNotFound){
                            param = [param substringToIndex:end.location];
                        }
                    }
                    embedVideoURL = [NSString stringWithFormat:@"//www.youtube.com/embed/%@?&hd=1&showinfo=0&autohide=1&rel=0", param];
                    isYoutubeVideoLink = YES;
                }
            }
            else{
                embedVideoURL = [item objectForKey:@"trailer"];
            }
            if (embedVideoURL != nil){
                startY = startY + 20;
                UILabel *trailerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, startY, clearLogoWidth, label1.frame.size.height)];
                [trailerLabel setText:NSLocalizedString(@"TRAILER", nil)];
                [trailerLabel setTextColor:label1.textColor];
                [trailerLabel setFont:label1.font];
                [trailerLabel setShadowColor:label1.shadowColor];
                [trailerLabel setShadowOffset:label1.shadowOffset];
                [trailerLabel setBackgroundColor:[UIColor clearColor]];
                [scrollView addSubview:trailerLabel];
                startY = startY + label1.frame.size.height;
                int videoHeight = (int)((clearLogoWidth * 9) / 16);
                if (trailerView == nil){
                    trailerView = [[UIWebView alloc] initWithFrame:CGRectMake(10, startY, clearLogoWidth, videoHeight)];
                    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
                        [trailerView setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin];
                    }
                    trailerView.delegate = self;
                }
                if (((NSNull *)[[trailerView subviews] objectAtIndex:0] != [NSNull null])){
                    ((UIScrollView *)[[trailerView subviews] objectAtIndex:0]).scrollsToTop = NO;
                }
                [trailerView setBackgroundColor:[UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:0.5f]];
                [trailerView setClipsToBounds: NO];
                trailerView.layer.shadowColor = [UIColor blackColor].CGColor;
                trailerView.layer.shadowOpacity = 0.7f;
                trailerView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
                trailerView.layer.shadowRadius = 3.0f;
                trailerView.layer.masksToBounds = NO;
                
                UIBezierPath *path = [UIBezierPath bezierPathWithRect:trailerView.bounds];
                trailerView.layer.shadowPath = path.CGPath;
                
                [trailerView.layer setBorderWidth:1];
                [trailerView.layer setBorderColor:[[UIColor blackColor] CGColor]];
                embedVideo = [NSString stringWithFormat:@"\
                                          <html>\
                                          <head>\
                                          <style type=\"text/css\">\
                                          iframe {position:absolute; top:50%%; margin-top:-%dpx;}\
                                          body {background-color:#000; margin:0;}\
                                          </style>\
                                          </head>\
                                          <body>\
                                          <iframe width=\"100%%\" height=\"%dpx\" src=\"%@\" frameborder=\"0\" allowfullscreen></iframe>\
                                          </body>\
                                          </html>", videoHeight/2, videoHeight, embedVideoURL];
                if (isYoutubeVideoLink){
                    [trailerView loadHTMLString:embedVideo baseURL:[NSURL URLWithString:@"http:"]];
                }
                else{
                    NSString *blackPage = @"\
                    <html>\
                    <head>\
                    <style type=\"text/css\">\
                    body {background-color:#000; margin:0;}\
                    </style>\
                    </head>\
                    <body>\
                    </body>\
                    </html>";
                    [trailerView loadHTMLString:blackPage baseURL:nil];
                    UIButton *playTrailerButton = [UIButton buttonWithType:UIButtonTypeCustom];
                    UIImage *playTrailerImg = [UIImage imageNamed:@"button_play"];
                    [playTrailerButton setImage:playTrailerImg forState:UIControlStateNormal];
                    [playTrailerButton setFrame:CGRectMake(0, 0, trailerView.frame.size.width, trailerView.frame.size.height)];
                    [playTrailerButton addTarget:self action:@selector(loadUrl:) forControlEvents:UIControlEventTouchUpInside];
                    [trailerView addSubview:playTrailerButton];
                }
                embedVideoActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                embedVideoActivityIndicator.hidesWhenStopped = YES;
                embedVideoActivityIndicator.center = CGPointMake(trailerView.frame.size.width / 2, videoHeight / 2);
                [embedVideoActivityIndicator setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin];
                [trailerView addSubview:embedVideoActivityIndicator];
                [scrollView addSubview:trailerView];
                startY = startY + videoHeight - 10;
            }
        }
    }
    frame = label6.frame;
    frame.origin.y = startY + 20;
    label6.frame = frame;
    startY = startY + 16 + size + label6.frame.size.height;
    if (![[item objectForKey:@"family"] isEqualToString:@"albumid"]) {// TRANSFORM IN SHOW_CAST BOOLEAN
        cast = [item objectForKey:contributorString];
        if (actorsTable == nil){
            int actorsTableWidth = 320;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                actorsTableWidth = pageSize + 40;
            }
            actorsTable = [[UITableView alloc] initWithFrame:CGRectMake(0, startY, actorsTableWidth, [cast count]*(castHeight + 10)) style:UITableViewStylePlain];
        }
        [actorsTable setScrollsToTop:NO];
        [actorsTable setBackgroundColor:[UIColor clearColor]];
        [actorsTable setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [actorsTable setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin ];
        [actorsTable setDelegate:self];
        [actorsTable setDataSource:self];
        [scrollView addSubview:actorsTable];
        startY = startY + (int)[cast count]*(castHeight + 10);
        if ([cast count]==0){
            label6.hidden = YES;
            startY-=20;
        }
    }
    if (!([[item objectForKey:@"family"] isEqualToString:@"broadcastid"] || [[item objectForKey:@"family"] isEqualToString:@"recordingid"])){
        clearlogoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [clearlogoButton setFrame:CGRectMake(10, startY, clearLogoWidth, clearLogoHeight)];
        [clearlogoButton.titleLabel setShadowColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.8]];
        [clearlogoButton.titleLabel setShadowOffset:CGSizeMake(0, 1)];
        [clearlogoButton addTarget:self action:@selector(showBackground:) forControlEvents:UIControlEventTouchUpInside];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
            [clearlogoButton setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        }
        if ([[item objectForKey:@"clearlogo"] length] != 0){
            clearLogoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, clearLogoWidth, clearLogoHeight)];
            [[clearLogoImageView layer] setMinificationFilter:kCAFilterTrilinear];
            [clearLogoImageView setContentMode:UIViewContentModeScaleAspectFit];
            NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [[item objectForKey:@"clearlogo"] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
            [clearLogoImageView setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:@""]];
            [clearlogoButton addSubview:clearLogoImageView];
        }
        else{
            [clearlogoButton setTitle:[[item objectForKey:@"showtitle"] length] == 0 ? [item objectForKey:@"label"] :[item objectForKey:@"showtitle"] forState:UIControlStateNormal];
            [clearlogoButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        }
        [scrollView addSubview:clearlogoButton];
    }
    startY = startY + clearLogoHeight + 20;
    scrollView.contentSize=CGSizeMake(320, startY);
}

-(void)buildTrailerView{
    
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

- (void)showBackground:(id)sender {
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    NSInteger foundTag = 0;
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        foundTag = [sender view].tag;
    }
    else {
        foundTag = [sender tag];
    }
    if (foundTag== 1) {
        [self alphaView:closeButton AnimDuration:1.5 Alpha:0];
        [self alphaView:scrollView AnimDuration:1.5 Alpha:1];
        if (!enableKenBurns) {
            [self alphaImage:fanartView AnimDuration:1.5 Alpha:0.2f];// cool
        }
        else {
            [self alphaView:self.kenView AnimDuration:1.5 Alpha:0.2];// cool
        }
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            if (![self isModal]){
                [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollFullScreenDisabled" object:self.view userInfo:nil];
            }
            [UIView animateWithDuration:1.5f
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^ {
                                 [toolbar setAlpha:1.0];
                                 if ([self isModal]){
                                     if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
//                                         self.view.superview.bounds = originalSelfFrame;
                                     }
                                     else {
                                         self.view.superview.bounds = originalSelfFrame;
                                     }
                                 }
                             }
                             completion:^(BOOL finished) {}
             ];
        }
    }
    else {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            if (![self isModal]){
                NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:YES], @"hideToolbar",
                                        [NSNumber numberWithBool:YES], @"clipsToBounds",
                                        nil];
                [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollFullScreenEnabled" object:self.view userInfo:params];
            }
            [UIView animateWithDuration:1.5f
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^ {
                                 self.kenView.alpha = 0;
                                 [toolbar setAlpha:0.0];
                                 if ([self isModal]){
                                     originalSelfFrame = self.view.frame;
                                     CGRect fullscreenRect = [self currentScreenBoundsDependOnOrientation];
                                     fullscreenRect.origin.y += 10;
                                     if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
//                                         self.view.superview.bounds = fullscreenRect;
                                     }
                                     else {
                                         self.view.superview.bounds = fullscreenRect;
                                     }
                                 }
                             }
                             completion:^(BOOL finished) {}
             ];
            if (self.kenView != nil) {
                float alphaValue = 1;
                [UIView animateWithDuration:0.2
                                 animations:^ {
                                     self.kenView.alpha = 0;
                                 }
                                 completion:^(BOOL finished){
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
            [closeButton.titleLabel setShadowColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.8]];
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

- (void) scrollViewDidScroll: (UIScrollView *) theScrollView{
    if (arrow_continue_down.alpha && theScrollView.contentOffset.y>40){
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:1];
        arrow_continue_down.alpha=0;
        [UIView commitAnimations];
    }
    else if (arrow_continue_down.alpha==0 && theScrollView.contentOffset.y<40){
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:1];
        arrow_continue_down.alpha=0.5;
        [UIView commitAnimations];
    }
}

-(void)alphaImage:(UIImageView *)image AnimDuration:(float)seconds Alpha:(float)alphavalue{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	image.alpha = alphavalue;
    if (alphavalue) {
        image.hidden = NO;
    }
    [UIView commitAnimations];
}

-(void)alphaView:(UIView *)view AnimDuration:(float)seconds Alpha:(float)alphavalue{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	view.alpha = alphavalue;
    [UIView commitAnimations];
}

#pragma mark - Actors UITableView data source & delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return castHeight + 10;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [cast count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"CellActor";
    ActorCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[ActorCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier castWidth:castWidth castHeight:castHeight size:size castFontSize:castFontSize];
    }
    GlobalData *obj = [GlobalData getInstance];
    NSString *serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
    if ([AppDelegate instance].serverVersion > 11){
        serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
    }
    NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [[[cast objectAtIndex:indexPath.row] objectForKey:@"thumbnail"] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    [cell.actorThumbnail setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:@"person.png"] andResize:CGSizeMake(castWidth, castHeight)];
    cell.actorName.text = [[cast objectAtIndex:indexPath.row] objectForKey:@"name"] == nil ? [self.detailItem objectForKey:@"label"] : [[cast objectAtIndex:indexPath.row] objectForKey:@"name"];
    if ([[[cast objectAtIndex:indexPath.row] objectForKey:@"role"] length] != 0){
        cell.actorRole.text = [NSString stringWithFormat:@"%@", [[cast objectAtIndex:indexPath.row] objectForKey:@"role"]];
        [cell.actorRole sizeToFit];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([AppDelegate instance].serverVersion > 11  && ![self isModal]) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_arrow_right_selected"]];
        cell.accessoryView.alpha = 0.5f;
    }
    else {
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([AppDelegate instance].serverVersion > 11 && ![self isModal]) {
        [self showContent:[[cast objectAtIndex:indexPath.row] objectForKey:@"name"]];
    }
}

#pragma mark - Gestures

- (void)handleSwipeFromLeft:(id)sender {
    if (![[self.detailItem objectForKey:@"disableNowPlaying"] boolValue]){
        [self showNowPlaying];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}

# pragma  mark - JSON Data

-(void)openWithVLC:(NSDictionary *)item {
    self.navigationItem.rightBarButtonItem.enabled=NO;
    [activityIndicatorView startAnimating];
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"vlc://"]]){
        [activityIndicatorView stopAnimating];
        self.navigationItem.rightBarButtonItem.enabled=YES;
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"VLC non installed", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
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
                    [activityIndicatorView stopAnimating];
                    self.navigationItem.rightBarButtonItem.enabled=YES;
                }
            }
            else {
                [activityIndicatorView stopAnimating];
                self.navigationItem.rightBarButtonItem.enabled=YES;
            }
        }];
    }
}

-(void)addQueueAfterCurrent:(BOOL)afterCurrent{
    self.navigationItem.rightBarButtonItem.enabled=NO;
    NSDictionary *item = self.detailItem;
    NSString *param = [item objectForKey:@"family"];
    id value = [item objectForKey:[item objectForKey:@"family"]];
    if ([[self.detailItem objectForKey:@"family"] isEqualToString:@"recordingid"]){
        param = @"file";
        value = [item objectForKey:@"file"];
    }
    if (afterCurrent){
        [activityIndicatorView startAnimating];
        [jsonRPC
         callMethod:@"Player.GetProperties"
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                         [item objectForKey:@"playlistid"], @"playerid",
                         [[NSArray alloc] initWithObjects:@"percentage", @"time", @"totaltime", @"partymode", @"position", nil], @"properties",
                         nil]
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
             if (error==nil && methodError==nil){
                 if( [NSJSONSerialization isValidJSONObject:methodResult]){
                     if ([methodResult count]){
                         [activityIndicatorView stopAnimating];
                         int newPos = [[methodResult objectForKey:@"position"] intValue] + 1;
                         NSString *action2=@"Playlist.Insert";
                         NSDictionary *params2=[NSDictionary dictionaryWithObjectsAndKeys:
                                                [item objectForKey:@"playlistid"], @"playlistid",
                                                [NSDictionary dictionaryWithObjectsAndKeys: value, param, nil], @"item",
                                                [NSNumber numberWithInt:newPos],@"position",
                                                nil];
                         [jsonRPC callMethod:action2 withParameters:params2 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                             if (error==nil && methodError==nil){
                                 [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
                             }
                             
                         }];
                         self.navigationItem.rightBarButtonItem.enabled=YES;
                     }
                     else{
                         [self addQueueAfterCurrent:NO];
                     }
                 }
                 else{
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
        [jsonRPC callMethod:@"Playlist.Add" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[item objectForKey:@"playlistid"], @"playlistid", [NSDictionary dictionaryWithObjectsAndKeys: value, param, nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            [activityIndicatorView stopAnimating];
            if (error==nil && methodError==nil){
                [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
            }
            self.navigationItem.rightBarButtonItem.enabled=YES;
        }];
    }
}

-(void)addPlayback:(float)resumePointLocal{
    if ([[self.detailItem objectForKey:@"family"] isEqualToString:@"broadcastid"]){
        [self openFile:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: [[self.detailItem objectForKey:@"pvrExtraInfo"] objectForKey:@"channelid"], @"channelid", nil], @"item", nil]];
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled=NO;
        [activityIndicatorView startAnimating];
        NSDictionary *item = self.detailItem;
        [jsonRPC callMethod:@"Playlist.Clear" withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:@"playlistid"], @"playlistid", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            if (error==nil && methodError==nil){
                NSString *param = [item objectForKey:@"family"];
                id value = [item objectForKey:[item objectForKey:@"family"]];
                if ([[self.detailItem objectForKey:@"family"] isEqualToString:@"recordingid"]){
                    param = @"file";
                    value = [item objectForKey:@"file"];
                }
                [jsonRPC callMethod:@"Playlist.Add" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[item objectForKey:@"playlistid"], @"playlistid", [NSDictionary dictionaryWithObjectsAndKeys: value, param, nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                    if (error==nil && methodError==nil){
                        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
                        [jsonRPC callMethod:@"Player.Open" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:@"playlistid"], @"playlistid", [NSNumber numberWithInt: 0], @"position", nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                            if (error==nil && methodError==nil){
                                [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
                                [activityIndicatorView stopAnimating];
                                [self showNowPlaying];
                                if (resumePointLocal){
                                    [self SimpleAction:@"Player.Seek" params:[NSDictionary dictionaryWithObjectsAndKeys:[item objectForKey:@"playlistid"], @"playerid", [NSNumber numberWithFloat:resumePointLocal], @"value", nil]];
                                }
                            }
                            else {
                                [activityIndicatorView stopAnimating];
                                self.navigationItem.rightBarButtonItem.enabled=YES;
                            }
                        }];
                    }
                    else {
                        [activityIndicatorView stopAnimating];
                        self.navigationItem.rightBarButtonItem.enabled=YES;
                    }
                }];
            }
            else {
                [activityIndicatorView stopAnimating];
                self.navigationItem.rightBarButtonItem.enabled=YES;
            }
        }];
    }
}

-(void)openFile:(NSDictionary *)params{
    [activityIndicatorView startAnimating];
    [jsonRPC callMethod:@"Player.Open" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        [activityIndicatorView stopAnimating];
        if (error==nil && methodError==nil){
            [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
            [self showNowPlaying];
        }
    }];
}

-(void)SimpleAction:(NSString *)action params:(NSDictionary *)parameters{
    jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    [jsonRPC callMethod:action withParameters:parameters];
}

# pragma  mark - Gestures

- (void)handleSwipeFromRight:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

# pragma mark - Utility

-(void) elabKenBurns:(UIImage *)image{
    [self.kenView stopAnimation];
    [self.kenView removeFromSuperview];
    self.kenView = nil;
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

# pragma  mark - Life Cycle

- (void)setDetailItem:(id)newDetailItem{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        // Update the view.
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    alreadyPush=NO;
    self.slidingViewController.underRightViewController = nil;
    self.slidingViewController.anchorLeftPeekAmount     = 0;
    self.slidingViewController.anchorLeftRevealAmount   = 0;
    // TRICK WHEN CHILDREN WAS FORCED TO PORTRAIT
//    if (![[self.detailItem objectForKey:@"disableNowPlaying"] boolValue]){
//        UIViewController *c = [[UIViewController alloc]init];
//        [self presentViewController:c animated:NO completion:nil];
//        [self dismissViewControllerAnimated:NO completion:nil];
//    }
    [actorsTable deselectRowAtIndexPath:[actorsTable indexPathForSelectedRow] animated:YES];
    if ([self isModal]){
        NSMutableArray *items = [[toolbar items] mutableCopy];
        UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissModal:)];
        [items insertObject:close atIndex:0];
        [toolbar setItems:items];
        toolbar.tintColor = TINT_COLOR;
        viewTitle.textAlignment = NSTextAlignmentCenter;
        bottomShadow.hidden = YES;
    }
    if (isViewDidLoad){
        [self createInfo];
        isViewDidLoad = false;
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleSwipeFromLeft:)
                                                 name: @"ECSLidingSwipeLeft"
                                               object: nil];
    if (foundTintColor != nil){
        self.navigationController.navigationBar.tintColor = foundTintColor;
        toolbar.tintColor = foundTintColor;
    }
    else {
        self.navigationController.navigationBar.tintColor = TINT_COLOR;
        toolbar.tintColor = TINT_COLOR;
    }
    float alphaValue = 0.2;
    if (closeButton.alpha==1){
        alphaValue = 1;
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
    if (!enableKenBurns){
        [self alphaImage:fanartView AnimDuration:1.5 Alpha:alphaValue];// cool
    }
    else{
        if (fanartView.image!=nil && self.kenView==nil){
            fanartView.alpha = 0;
            [self elabKenBurns:fanartView.image];
        }
        [self alphaView:self.kenView AnimDuration:1.5 Alpha:alphaValue];// cool
    }
    if ([self isModal]){
        [clearlogoButton setFrame:CGRectMake((int)(self.view.frame.size.width/2) - (int)(clearlogoButton.frame.size.width/2), clearlogoButton.frame.origin.y, clearlogoButton.frame.size.width, clearlogoButton.frame.size.height)];
        [trailerView setFrame:CGRectMake((int)(self.view.frame.size.width/2) - (int)(trailerView.frame.size.width/2), trailerView.frame.origin.y, trailerView.frame.size.width, trailerView.frame.size.height)];
        self.view.superview.backgroundColor = [UIColor clearColor];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [self.navigationController.navigationBar setTintColor:TINT_COLOR];
    toolbar.tintColor = TINT_COLOR;
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self alphaImage:fanartView AnimDuration:0.3 Alpha:0.0f];
    if (self.kenView != nil){
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.kenView.alpha = 0;
                         }
                         completion:^(BOOL finished){
                             [self.kenView stopAnimation];
                             [self.kenView removeFromSuperview];
                             self.kenView = nil;
                         }
         ];
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

- (void)viewDidLoad{
    [super viewDidLoad];
    SDWebImageDownloader *manager = [SDWebImageManager sharedManager].imageDownloader;
    NSDictionary *httpHeaders = [AppDelegate instance].getServerHTTPHeaders;
    if ([httpHeaders objectForKey:@"Authorization"] != nil){
        [manager setValue:[httpHeaders objectForKey:@"Authorization"] forHTTPHeaderField:@"Authorization"];
    }
    isViewDidLoad = TRUE;
    [label1 setText:NSLocalizedString(@"DIRECTED BY", nil)];
    [label2 setText:NSLocalizedString(@"GENRE", nil)];
    [label3 setText:NSLocalizedString(@"RUNTIME", nil)];
    [label4 setText:NSLocalizedString(@"STUDIO", nil)];
    [label5 setText:NSLocalizedString(@"SUMMARY", nil)];
    [label6 setText:NSLocalizedString(@"CAST", nil)];
    [parentalRatingLabelUp setText:NSLocalizedString(@"PARENTAL RATING", nil)];
    fanartView.tag = 1;
    fanartView.userInteractionEnabled = YES;
    UITapGestureRecognizer *touchOnKenView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showBackground:)];
    [touchOnKenView setNumberOfTapsRequired:1];
    [touchOnKenView setNumberOfTouchesRequired:1];
    [fanartView addGestureRecognizer:touchOnKenView];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        float iOSYDelta = - [[UIApplication sharedApplication] statusBarFrame].size.height;
        UIEdgeInsets tableViewInsets = UIEdgeInsetsZero;
        tableViewInsets.top = 44 + fabs(iOSYDelta);
        scrollView.contentInset = tableViewInsets;
        scrollView.scrollIndicatorInsets = tableViewInsets;
    }
    [self disableScrollsToTopPropertyOnAllSubviewsOf:self.slidingViewController.view];
    scrollView.scrollsToTop = YES;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL kenBurns = NO;
    NSString *kenBurnsString = [userDefaults objectForKey:@"ken_preference"];
    if (kenBurnsString == nil || [kenBurnsString boolValue]) kenBurns = YES;
    enableKenBurns = kenBurns;
    self.kenView = nil;
    [self configureView];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)dealloc{
    trailerView.delegate = nil;
    [trailerView stopLoading];
    [trailerView removeFromSuperview];
    trailerView = nil;
    actorsTable = nil;
    [kenView removeFromSuperview];
    [self.kenView removeFromSuperview];
    kenView = nil;
    clearLogoImageView = nil;
    nowPlaying=nil;
    jsonRPC=nil;
    fanartView=nil;
    coverView=nil;
    scrollView=nil;
    self.nowPlaying = nil;
    self.kenView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
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
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    if (self.kenView != nil){
        float alphaValue = 0.2;
        if (closeButton.alpha==1){
            alphaValue = 1;
        }
        [UIView animateWithDuration:0.2
                         animations:^{
                             self.kenView.alpha = 0;
                         }
                         completion:^(BOOL finished){
                             [self elabKenBurns:fanartView.image];
                             [self alphaView:self.kenView AnimDuration:.2 Alpha:alphaValue];
                         }
         ];
    }
}

@end
