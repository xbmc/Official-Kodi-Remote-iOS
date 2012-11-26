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
        NSDictionary *item=self.detailItem;
        CGRect frame = CGRectMake(0, 0, 140, 40);
        UILabel *viewTitle = [[UILabel alloc] initWithFrame:frame] ;
        viewTitle.numberOfLines=0;
        viewTitle.font = [UIFont boldSystemFontOfSize:11];
        viewTitle.minimumFontSize=6;
        viewTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        viewTitle.backgroundColor = [UIColor clearColor];
        viewTitle.shadowColor = [UIColor colorWithWhite:0.0 alpha:0];
        viewTitle.textAlignment = UITextAlignmentCenter;
        viewTitle.textColor = [UIColor whiteColor];
        viewTitle.text = [item objectForKey:@"label"];
        [viewTitle sizeThatFits:CGSizeMake(140, 40)];
        sheetActions = [[NSMutableArray alloc] initWithObjects:@"Queue after current", @"Queue", @"Play", nil];
        NSDictionary *resumePointDict = [item objectForKey:@"resume"];
        if (resumePointDict != nil){
            if (((NSNull *)[resumePointDict objectForKey:@"position"] != [NSNull null])){
                if ([[resumePointDict objectForKey:@"position"] floatValue]>0){
                    resumePointPercentage = ([[resumePointDict objectForKey:@"position"] floatValue] * 100) / [[resumePointDict objectForKey:@"total"] floatValue];
                    [sheetActions addObject:[NSString stringWithFormat:@"Resume from %@", [self convertTimeFromSeconds:[NSNumber numberWithFloat:[[resumePointDict objectForKey:@"position"] floatValue]]]]];
                }
            }
        }
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
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStyleBordered target:self action:@selector(goBack:)];
            }
            else{
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStyleBordered target:self action:@selector(showContent:)];
            }
        }
        else if ([[item objectForKey:@"family"] isEqualToString:@"artistid"]){
            UIImage* extraButtonImg = [UIImage imageNamed:@"st_album_icon"];
            extraButton =[[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStyleBordered target:self action:@selector(showContent:)];
        }
        else if ([[item objectForKey:@"family"] isEqualToString:@"tvshowid"]){
            UIImage* extraButtonImg = [UIImage imageNamed:@"st_tv_icon"];
            if (fromEpisodesView){
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStyleBordered target:self action:@selector(goBack:)];
            }
            else{
                extraButton = [[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStyleBordered target:self action:@selector(showContent:)];
            }
        }
        else{
            titleWidth = 400;
        }

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            toolbar = [UIToolbar new];
            toolbar.alpha = .8f;
            toolbar.barStyle = UIBarStyleBlackTranslucent;
//            toolbar.tintColor = [UIColor colorWithRed:.15 green:.15 blue:.15 alpha:.1];
            UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            actionSheetButtonItemIpad = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(showActionSheet)];
            actionSheetButtonItemIpad.style = UIBarButtonItemStyleBordered;
            viewTitle.numberOfLines=1;
            viewTitle.font = [UIFont boldSystemFontOfSize:22];
            viewTitle.minimumFontSize=6;
            viewTitle.adjustsFontSizeToFitWidth = YES;
            viewTitle.shadowOffset = CGSizeMake(1.0, 1.0);
            viewTitle.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.7];
            viewTitle.autoresizingMask = UIViewAutoresizingNone;
            viewTitle.contentMode = UIViewContentModeScaleAspectFill;
            [viewTitle setFrame:CGRectMake(0, 0, titleWidth, 44)];
            [viewTitle sizeThatFits:CGSizeMake(titleWidth, 44)];
            viewTitle.textAlignment = UITextAlignmentLeft;
            UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithCustomView:viewTitle];
            if (extraButton == nil){
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
            CGFloat toolbarHeight = [toolbar frame].size.height;
            CGRect mainViewBounds = self.view.bounds;
            [toolbar setFrame:CGRectMake(CGRectGetMinX(mainViewBounds),
                                         CGRectGetMinY(mainViewBounds),
                                         CGRectGetWidth(mainViewBounds),
                                         toolbarHeight)];
            CGRect toolbarShadowFrame = CGRectMake(0.0f, 43, 320, 8);
            UIImageView *toolbarShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
            [toolbarShadow setImage:[UIImage imageNamed:@"tableUp.png"]];
            toolbarShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            toolbarShadow.opaque = YES;
            toolbarShadow.alpha = 0.5;
            [toolbar addSubview:toolbarShadow];
            [self.view addSubview:toolbar];
            scrollView.autoresizingMask = UIViewAutoresizingNone;
            [scrollView setFrame:CGRectMake(scrollView.frame.origin.x, scrollView.frame.origin.y + 44, scrollView.frame.size.width, scrollView.frame.size.height-44)];
            scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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

-(void)showContent:(id)sender{
    NSDictionary *item=self.detailItem;
    mainMenu *MenuItem = nil;
    choosedTab = 0;
    if ([[item objectForKey:@"family"] isEqualToString:@"albumid"]){
        notificationName = @"UIApplicationEnableMusicSection";
        MenuItem = [[AppDelegate instance].playlistArtistAlbums copy];
    }
    else if ([[item objectForKey:@"family"] isEqualToString:@"tvshowid"]){
        notificationName = @"UIApplicationEnableTvShowSection";
        MenuItem = [[AppDelegate instance].playlistTvShows copy];
    }
    else if ([[item objectForKey:@"family"] isEqualToString:@"artistid"]){
        notificationName = @"UIApplicationEnableMusicSection";
        choosedTab = 1;
        MenuItem = [[AppDelegate instance].playlistArtistAlbums copy];
    }
//    MenuItem.subItem.mainLabel=@"";
    MenuItem.subItem.mainLabel=[NSString stringWithFormat:@"%@", [item objectForKey:@"label"]];
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[MenuItem.subItem mainMethod] objectAtIndex:choosedTab]];
    if ([methods objectForKey:@"method"]!=nil){ // THERE IS A CHILD
        NSDictionary *mainFields=[[MenuItem mainFields] objectAtIndex:choosedTab];
        NSMutableDictionary *parameters=[self indexKeyedMutableDictionaryFromArray:[[MenuItem.subItem mainParameters] objectAtIndex:choosedTab]];
        NSString *key=@"null";
        if ([item objectForKey:[mainFields objectForKey:@"row15"]]!=nil){
            key=[mainFields objectForKey:@"row15"];
        }
        id obj = [NSNumber numberWithInt:[[item objectForKey:[mainFields objectForKey:@"row6"]] intValue]];
        id objKey = [mainFields objectForKey:@"row6"];
        if ([AppDelegate instance].serverVersion>11 && [[parameters objectForKey:@"disableFilterParameter"] boolValue] == FALSE){
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
                                       [parameters objectForKey:@"label"], @"label",
                                       [NSNumber numberWithBool:YES], @"fromShowInfo",
                                       [parameters objectForKey:@"extra_info_parameters"], @"extra_info_parameters",
                                       newSectionParameters, @"extra_section_parameters",
                                       nil];
        [[MenuItem.subItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
        MenuItem.subItem.chooseTab=choosedTab;
        if (![[item objectForKey:@"disableNowPlaying"] boolValue]){
            MenuItem.subItem.disableNowPlaying = NO;
        }
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
            self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
            self.detailViewController.detailItem = MenuItem.subItem;
            [self.navigationController pushViewController:self.detailViewController animated:YES];
        }
        else{
            DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem.subItem withFrame:CGRectMake(0, 0, 477, self.view.frame.size.height) bundle:nil];
            [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
            [[AppDelegate instance].windowController.stackScrollViewController enablePanGestureRecognizer];
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object: nil];
        }
    }
}

#pragma mark - ActionSheet

-(void)showActionSheet {
    if (actionSheetView.window){
        [actionSheetView dismissWithClickedButtonIndex:actionSheetView.cancelButtonIndex animated:YES];
        return;
    }
    int numActions=[sheetActions count];
    if (numActions){
        NSDictionary *item=self.detailItem;
        actionSheetView = [[UIActionSheet alloc] initWithTitle:[item objectForKey:@"label"]
                                                            delegate:self
                                                   cancelButtonTitle:nil
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:nil];
        actionSheetView.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        for (int i = 0; i < numActions; i++) {
            [actionSheetView addButtonWithTitle:[sheetActions objectAtIndex:i]];
        }
        actionSheetView.cancelButtonIndex = [actionSheetView addButtonWithTitle:@"Cancel"];
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
        if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:@"Queue after current"]){
            [self addQueueAfterCurrent:YES];

        }
        else if([[sheetActions objectAtIndex:buttonIndex] isEqualToString:@"Queue"]){
            [self addQueueAfterCurrent:NO];
        }
        else if([[sheetActions objectAtIndex:buttonIndex] isEqualToString:@"Play"]){
            [self addPlayback:0.0];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] rangeOfString:@"Resume from"].location!= NSNotFound){
            [self addPlayback:resumePointPercentage];
            return;
        }
    }
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
    int count=[objects count];
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

-(void)setAndMoveLabels:(NSArray *)arrayLabels size:(int)size{
    UIFont *fontFace=[UIFont systemFontOfSize:16];

    int offset = size;
    for (UILabel *label in arrayLabels) {
        [label setFont:fontFace];
        [label setFrame:
         CGRectMake(
                    label.frame.origin.x, 
                    label.frame.origin.y + offset, 
                    label.frame.size.width, 
                    label.frame.size.height + size
                    )
         ];
        offset += size;
    }
}

int h=0;

-(void)setTvShowsToolbar{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        int count = [toolbar.items count];
        NSMutableArray *newToolbarItems = [toolbar.items mutableCopy];
        [newToolbarItems removeObjectAtIndex:(count - 1)];
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
    CGContextRef shadowContext = CGBitmapContextCreate(NULL, source.size.width + 20, source.size.height + 20, CGImageGetBitsPerComponent(source.CGImage), 0, colourSpace, kCGImageAlphaPremultipliedLast);
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
    CGSize size = [source size];
    UIGraphicsBeginImageContext(size);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
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

-(void)createInfo{
    // NEED TO BE OPTIMIZED. IT WORKS BUT THERE ARE TOO MANY IFS!
    NSDictionary *item=self.detailItem;
    NSString *placeHolderImage = @"coverbox_back.png";
//    NSLog(@"ITEM %@", item);
    int scrollViewDefaultHeight = 1660;
    int castFontSize = 14;
    int size = 0;
    int castWidth = 50;
    int castHeight = 50;
    int pageSize = 297;
    int labelSpace = 20;
    bool enableJewel = [self enableJewelCases];
    if (!enableJewel) {
        jewelView.image = nil;
    }
    clearLogoWidth = 300;
    clearLogoHeight = 116;
    int shiftParentalRating = -20;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        clearLogoWidth = 457;
        clearLogoHeight = 177;
        shiftParentalRating = -40;
        labelSpace = 33;
        placeHolderImage = @"coverbox_back@2x.png";
        castFontSize = 16;
        size = 6;
        castWidth = 75;
        castHeight = 75;
        pageSize = 447;
        [starsView setFrame: 
         CGRectMake(
                    starsView.frame.origin.x, 
                    starsView.frame.origin.y - size, 
                    starsView.frame.size.width, 
                    starsView.frame.size.height + size*2
                    )];
        [voteLabel setFont:[UIFont systemFontOfSize:26]];
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
    else if (!enableJewel) {
        CGRect frame = jewelView.frame;
        frame.origin.x = frame.origin.x + 4;
        jewelView.frame = frame;
    }
    if ([[item objectForKey:@"family"] isEqualToString:@"episodeid"] || [[item objectForKey:@"family"] isEqualToString:@"tvshowid"]){
        int deltaY=0;
        int coverHeight=0;
        int shiftY=40;
        CGRect frame;
        if ([[item objectForKey:@"family"] isEqualToString:@"tvshowid"]){
            GlobalData *obj=[GlobalData getInstance];     
            if (obj.preferTVPosters==NO){
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
                    coverHeight=70;
                    deltaY=coverView.frame.size.height - coverHeight;
                    shiftY=0;
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
                    shiftY=0;
                    jewelView.hidden=YES;
                    frame=coverView.frame;
                    frame.origin.x=-78;
                    frame.origin.y=12;
                    frame.size.width=477;
                    frame.size.height=90;
                    coverView.frame=frame;
                    jewelView.frame = frame;
                }
            }
            else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
                int originalHeight = jewelView.frame.size.height;
                int coverHeight = 560;
                int coverWidth = 477;
                CGRect frame;
                frame = jewelView.frame;
                frame.origin.x = -79;
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
            label1.text = @"EPISODES";
            label3.text = @"GENRE";
            label4.text = @"STUDIO";
            directorLabel.text = [[item objectForKey:@"showtitle"] length] == 0 ? @"-" : [item objectForKey:@"showtitle"];
            genreLabel.text = [[item objectForKey:@"premiered"] length] == 0 ? @"-" : [item objectForKey:@"premiered"];
            if ([[item objectForKey:@"genre"] isKindOfClass:NSClassFromString(@"JKArray")]){
                runtimeLabel.text=[[item objectForKey:@"genre"] componentsJoinedByString:@" / "];
                runtimeLabel.text=[runtimeLabel.text length]==0 ? @"-" : runtimeLabel.text;
            }
            else{
                runtimeLabel.text=[[item objectForKey:@"genre"] length]==0 ? @"-" : [item objectForKey:@"genre"];
            }
            if ([[item objectForKey:@"studio"] isKindOfClass:NSClassFromString(@"JKArray")]){
                studioLabel.text=[[item objectForKey:@"studio"] componentsJoinedByString:@" / "];
                studioLabel.text=[studioLabel.text length]==0 ? @"-" : studioLabel.text;
            }
            else{
                studioLabel.text=[[item objectForKey:@"studio"] length]==0 ? @"-" : [item objectForKey:@"studio"];
            }
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
            label1.text = @"TV SHOW";
            label3.text = @"DIRECTOR";
            label4.text = @"WRITER";
            parentalRatingLabelUp.hidden = YES;
            parentalRatingLabel.hidden = YES;
            
            frame = label6.frame;
            frame.origin.y = frame.origin.y + shiftParentalRating;
            label6.frame = frame;
            
            jewelView.image = [UIImage imageNamed:@"jewel_tv.9.png"];
            frame = jewelView.frame;
            frame.size.height = coverHeight;
            jewelView.frame = frame;
            
            directorLabel.text = [[item objectForKey:@"showtitle"] length]==0 ? @"-" : [item objectForKey:@"showtitle"];
            genreLabel.text = [[item objectForKey:@"firstaired"] length]==0 ? @"-" : [item objectForKey:@"firstaired"];
            if ([[item objectForKey:@"director"] isKindOfClass:NSClassFromString(@"JKArray")]){
                runtimeLabel.text = [[item objectForKey:@"director"] componentsJoinedByString:@" / "];
                runtimeLabel.text = [runtimeLabel.text length]==0 ? @"-" : runtimeLabel.text;
            }
            else{
                runtimeLabel.text = [[item objectForKey:@"director"] length]==0 ? @"-" : [item objectForKey:@"director"];
            }
            if ([[item objectForKey:@"writer"] isKindOfClass:NSClassFromString(@"JKArray")]){
                studioLabel.text = [[item objectForKey:@"writer"] componentsJoinedByString:@" / "];
                studioLabel.text = [studioLabel.text length]==0 ? @"-" : studioLabel.text;
            }
            else{
                studioLabel.text=[[item objectForKey:@"writer"] length]==0 ? @"-" : [item objectForKey:@"writer"];
            }
            shiftParentalRating = 0;
        }
        scrollViewDefaultHeight=scrollViewDefaultHeight - deltaY - shiftY;
        [self moveLabel:[NSArray arrayWithObjects:starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:deltaY];
        
        label2.text=@"FIRST AIRED";
        label5.text=@"SUMMARY";
        
        frame=starsView.frame;
        frame.origin.x=frame.origin.x+29;
        starsView.frame=frame;
        
        frame=voteLabel.frame;
        frame.origin.x=frame.origin.x+29;
        voteLabel.frame=frame;
    }
    else if ([[item objectForKey:@"family"] isEqualToString:@"albumid"]){
        
        int shiftY = 40;
        int coverHeight = 380;
        scrollViewDefaultHeight = 700;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
            coverHeight = 290;
        }
        [self moveLabel:[NSArray arrayWithObjects:starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:40];
        jewelView.hidden = NO;
        int deltaY = jewelView.frame.size.height - coverHeight;
        label1.text = @"ARTIST";
        label2.text = @"YEAR";
        label3.text = @"GENRE";
        label4.text = @"ALBUM LABEL";
        label5.text = @"DESCRIPTION";
        label6.text = @"";
        
        starsView.hidden = YES;
        voteLabel.hidden = YES;
        numVotesLabel.hidden = YES;

        parentalRatingLabelUp.hidden = YES;
        parentalRatingLabel.hidden = YES;
        
        CGRect frame = label6.frame;
        frame.origin.y = frame.origin.y-40;
        label6.frame = frame;
        if (enableJewel)
            jewelView.image = [UIImage imageNamed:@"jewel_cd.9.png"];
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
        coverView.frame = frame;
        if ([[item objectForKey:@"artist"] isKindOfClass:NSClassFromString(@"JKArray")]){
            directorLabel.text = [[item objectForKey:@"artist"] componentsJoinedByString:@" / "];
            directorLabel.text = [directorLabel.text length]==0 ? @"-" : directorLabel.text;
        }
        else{
            directorLabel.text = [[item objectForKey:@"artist"] length] == 0 ? @"-" : [item objectForKey:@"artist"];
        }
        genreLabel.text = [[item objectForKey:@"year"] length] == 0 ? @"-" : [item objectForKey:@"year"];
        if ([[item objectForKey:@"genre"] isKindOfClass:NSClassFromString(@"JKArray")]){
            runtimeLabel.text = [[item objectForKey:@"genre"] componentsJoinedByString:@" / "];
            runtimeLabel.text = [runtimeLabel.text length]==0 ? @"-" : runtimeLabel.text;
        }
        else{
            runtimeLabel.text = [[item objectForKey:@"genre"] length] == 0 ? @"-" : [item objectForKey:@"genre"];
        }
        studioLabel.text = [[item objectForKey:@"albumlabel"] length] == 0 ? @"-" : [item objectForKey:@"albumlabel"];
        scrollViewDefaultHeight=scrollViewDefaultHeight - deltaY - shiftY;
        [self moveLabel:[NSArray arrayWithObjects:starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:deltaY];
    }
    else if ([[item objectForKey:@"family"] isEqualToString:@"artistid"]){
        placeHolderImage = @"coverbox_back_artists.png";
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            placeHolderImage = @"coverbox_back_artists@2x.png";
        }
        enableJewel = NO;
        jewelView.image = nil;
        int shiftY = 40;
        [self moveLabel:[NSArray arrayWithObjects:starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:shiftY];
        [self moveLabel:[NSArray arrayWithObjects:label4, label5, label6, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:40];
        label1.text = @"GENRE";
        label2.text = @"STYLE";
        label3.text = @"";
        label4.text = @"BORN / FORMED";
        label5.text = @"DESCRIPTION";
        label6.text = @"";
        parentalRatingLabelUp.hidden = YES;
        parentalRatingLabel.hidden = YES;
        runtimeLabel.hidden = YES;
        label3.hidden = YES;
        CGRect frame = label6.frame;
        frame.origin.y = frame.origin.y-40;
        label6.frame = frame;
        starsView.hidden = YES;
        voteLabel.hidden = YES;
        numVotesLabel.hidden = YES;
        if ([[item objectForKey:@"genre"] isKindOfClass:NSClassFromString(@"JKArray")]){
            directorLabel.text = [[item objectForKey:@"genre"] componentsJoinedByString:@" / "];
            directorLabel.text = [directorLabel.text length]==0 ? @"-" : directorLabel.text;
        }
        else{
            directorLabel.text = [[item objectForKey:@"genre"] length] == 0 ? @"-" : [item objectForKey:@"genre"];
        }
        
        if ([[item objectForKey:@"style"] isKindOfClass:NSClassFromString(@"JKArray")]){
            genreLabel.text = [[item objectForKey:@"style"] componentsJoinedByString:@" / "];
            genreLabel.text = [genreLabel.text length]==0 ? @"-" : genreLabel.text;
        }
        else{
            genreLabel.text = [[item objectForKey:@"style"] length] == 0 ? @"-" : [item objectForKey:@"style"];
        }
        genreLabel.numberOfLines = 0;
        CGSize maximunLabelSize= CGSizeMake(pageSize, 9999);
        CGSize expectedLabelSize = [genreLabel.text
                                    sizeWithFont:genreLabel.font
                                    constrainedToSize:maximunLabelSize
                                    lineBreakMode:genreLabel.lineBreakMode];
        
        //adjust the label the the new height.
        CGRect newFrame = genreLabel.frame;
        newFrame.size.height = expectedLabelSize.height + size;
        genreLabel.frame = newFrame;
        [self moveLabel:[NSArray arrayWithObjects:label3, label4, label5, label6, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:-(expectedLabelSize.height - labelSpace)];
        
        if ([[item objectForKey:@"born"] isKindOfClass:NSClassFromString(@"JKArray")]){
            studioLabel.text = [[item objectForKey:@"born"] componentsJoinedByString:@" / "];
            studioLabel.text = [studioLabel.text length]==0 ? @"-" : studioLabel.text;
        }
        else{
            studioLabel.text = [[item objectForKey:@"born"] length] == 0 ? @"-" : [item objectForKey:@"born"];
        }
        
        if ([[item objectForKey:@"formed"] isKindOfClass:NSClassFromString(@"JKArray")]){
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
    else {
        placeHolderImage = @"coverbox_back_movies.png";
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            placeHolderImage = @"coverbox_back_movies@2x.png";
            int originalHeight = jewelView.frame.size.height;
            int coverHeight = 560;
            int coverWidth = 477;
            CGRect frame;
            frame = jewelView.frame;
            frame.origin.x = -79;
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
        if ([[item objectForKey:@"director"] isKindOfClass:NSClassFromString(@"JKArray")]){
            directorLabel.text = [[item objectForKey:@"director"] componentsJoinedByString:@" / "];
            directorLabel.text = [directorLabel.text length]==0 ? @"-" : directorLabel.text;
        }
        else{
            directorLabel.text = [[item objectForKey:@"director"] length]==0 ? @"-" : [item objectForKey:@"director"];
        }
        if ([[item objectForKey:@"genre"] isKindOfClass:NSClassFromString(@"JKArray")]){
            genreLabel.text = [[item objectForKey:@"genre"] componentsJoinedByString:@" / "];
            genreLabel.text = [genreLabel.text length]==0 ? @"-" : genreLabel.text;
        }
        else{
            genreLabel.text = [[item objectForKey:@"genre"] length]==0 ? @"-" : [item objectForKey:@"genre"];
        }
        runtimeLabel.text = [[item objectForKey:@"runtime"] length]==0 ? @"-" : [item objectForKey:@"runtime"];
        if ([[item objectForKey:@"studio"] isKindOfClass:NSClassFromString(@"JKArray")]){
            studioLabel.text = [[item objectForKey:@"studio"] componentsJoinedByString:@" / "];
            studioLabel.text = [studioLabel.text length]==0 ? @"-" : studioLabel.text;
        }
        else{
            studioLabel.text = [[item objectForKey:@"studio"] length]==0 ? @"-" : [item objectForKey:@"studio"];
        }
    }
    NSString *thumbnailPath = [item objectForKey:@"thumbnail"];
    NSURL *imageUrl = [NSURL URLWithString: thumbnailPath];
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    UIImage *cachedImage = [manager imageWithURL:imageUrl];
    if (cachedImage){
        if (enableJewel){
            coverView.image = cachedImage;
        }
        else{
            [NSThread detachNewThreadSelector:@selector(elaborateImage:) toTarget:self withObject:cachedImage];
            jewelView.hidden = NO;
        }
    }
    else{
        if (enableJewel){
            [coverView setImageWithURL:[NSURL URLWithString:thumbnailPath] placeholderImage:[UIImage imageNamed:placeHolderImage]];
        }
        else{
            [jewelView setImageWithURL:[NSURL URLWithString:thumbnailPath] placeholderImage:[UIImage imageNamed:placeHolderImage]];
            jewelView.hidden = NO;
        }
    }
    NSString *fanartPath=[item objectForKey:@"fanart"];
    NSURL *fanartUrl = [NSURL URLWithString: fanartPath];
    UIImage *cachedFanart = [manager imageWithURL:fanartUrl];
    if (cachedFanart){
        fanartView.image=cachedFanart;
    }
    else{
        enableKenBurns = NO;
        [fanartView setImageWithURL:[NSURL URLWithString:fanartPath] placeholderImage:[UIImage imageNamed:@""]];
    }
    [fanartView setClipsToBounds:YES];
    
    voteLabel.text=[[item objectForKey:@"rating"] length]==0 ? @"N.A." : [item objectForKey:@"rating"];
    starsView.image=[UIImage imageNamed:[NSString stringWithFormat:@"stars_%.0f.png", round([[item objectForKey:@"rating"] doubleValue])]];
    
    NSString *numVotes=[[item objectForKey:@"votes"] length]==0 ? @"" : [item objectForKey:@"votes"];
    if ([numVotes length]!=0){
        NSString *numVotesPlus=([numVotes isEqualToString:@"1"]) ? @"vote" : @"votes";
        numVotesLabel.text=[NSString stringWithFormat:@"(%@ %@)",numVotes, numVotesPlus];
    }
    CGRect frame=summaryLabel.frame;
    summaryLabel.frame=frame;
    summaryLabel.text=[[item objectForKey:@"plot"] length]==0 ? @"-" : [item objectForKey:@"plot"];
    if ([[item objectForKey:@"family"] isEqualToString:@"albumid"] || [[item objectForKey:@"family"] isEqualToString:@"artistid"]){
        summaryLabel.text=[[item objectForKey:@"description"] length]==0 ? @"-" : [item objectForKey:@"description"];
    }
    CGSize maximunLabelSize= CGSizeMake(pageSize, 9999);
    CGSize expectedLabelSize = [summaryLabel.text 
                                sizeWithFont:summaryLabel.font
                                constrainedToSize:maximunLabelSize 
                                lineBreakMode:summaryLabel.lineBreakMode]; 
    
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
        expectedLabelSize = [parentalRatingLabel.text
                             sizeWithFont:parentalRatingLabel.font
                             constrainedToSize:maximunLabelSize
                             lineBreakMode:parentalRatingLabel.lineBreakMode];
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
    int startY = label6.frame.origin.y + 20 + size;
    if (![[item objectForKey:@"family"] isEqualToString:@"albumid"] && ![[item objectForKey:@"family"] isEqualToString:@"artistid"]){// TRANSFORM IN SHOW_CAST BOOLEAN
        NSArray *cast = [item objectForKey:@"cast"];
// CLEARART AS CAST TITLE
//        if ([[item objectForKey:@"clearart"] length] != 0){
//            UIImageView *clearLogoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, startY, clearLogoWidth, clearLogoHeight)];
//            [clearLogoImageView setContentMode:UIViewContentModeScaleAspectFit];
//            [[clearLogoImageView layer] setMinificationFilter:kCAFilterTrilinear];
//            NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [[item objectForKey:@"clearart"] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
//            [clearLogoImageView setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:@""]];
//            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
//                [clearLogoImageView setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
//            }
//            [scrollView addSubview:clearLogoImageView];
//            startY = startY + 20 + clearLogoHeight;
//            frame = label6.frame;
//            frame.origin.y = frame.origin.y+clearLogoHeight + 20;
//            label6.frame = frame;
//        }
// END CLEARART
        int offsetX = 10;
        for (NSDictionary *actor in cast){
            NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [[actor objectForKey:@"thumbnail"] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
            UIImageView *actorImage = [[UIImageView alloc] initWithFrame:CGRectMake(offsetX, startY, castWidth, castHeight)];
            [actorImage setClipsToBounds:YES];
            [actorImage setContentMode:UIViewContentModeScaleAspectFill];
            
            NSURL *imageUrl = [NSURL URLWithString: stringURL];    
            UIImage *cachedImage = [manager imageWithURL:imageUrl];
            if (cachedImage){
                actorImage.image=cachedImage;
            }
            else { 
                [actorImage setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:@"person.png"]];
            }
            [actorImage.layer setBorderColor: [[UIColor whiteColor] CGColor]];
            [actorImage.layer setBorderWidth: 1.0];
            [actorImage setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];
            [scrollView addSubview:actorImage];
            
            UILabel *actorName=[[UILabel alloc] initWithFrame:CGRectMake(castWidth + offsetX + 10, startY, 320 - (castWidth + offsetX + 20) , 16 + size)];
            actorName.text = [actor objectForKey:@"name"];
            [actorName setFont:[UIFont systemFontOfSize:castFontSize]];

            [actorName setBackgroundColor:[UIColor clearColor]];
            [actorName setTextColor:[UIColor whiteColor]];
            [actorName setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth];
            [actorName setShadowColor:[UIColor blackColor]];
            [actorName setShadowOffset:CGSizeMake(1, 1)];
            [scrollView addSubview:actorName];
            
            UILabel *actorRole = [[UILabel alloc] initWithFrame:CGRectMake(castWidth + offsetX + 10, startY+20, 320 - (castWidth + offsetX + 20) , 16 + size)];
            actorRole.text = @"";
            actorRole.numberOfLines = 2;
            if ([[actor objectForKey:@"role"] length] != 0){
                actorRole.text = [NSString stringWithFormat:@"as %@", [actor objectForKey:@"role"]];
            }
            [actorRole setFont:[UIFont systemFontOfSize:castFontSize - 1]];
            [actorRole setBackgroundColor:[UIColor clearColor]];
            [actorRole setTextColor:[UIColor grayColor]];
            [actorRole setShadowColor:[UIColor blackColor]];
            [actorRole setShadowOffset:CGSizeMake(1, 1)];
            [actorRole setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth];
            [scrollView addSubview:actorRole];
            
            startY=startY + castHeight + 10;
        }
        if ([cast count]==0){
            label6.hidden = YES;
            startY-=20;
        }
    }
    clearlogoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [clearlogoButton setFrame:CGRectMake(10, startY, clearLogoWidth, clearLogoHeight)];
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
    startY = startY + clearLogoHeight + 20;
    scrollView.contentSize=CGSizeMake(320, startY);
}

- (void)showBackground:(id)sender{
    if ([sender tag]==1){
        [self alphaView:closeButton AnimDuration:1.5 Alpha:0];
        [self alphaView:scrollView AnimDuration:1.5 Alpha:1];
        if (!enableKenBurns){
            [self alphaImage:fanartView AnimDuration:1.5 Alpha:0.2f];// cool
        }
        else{
            [self alphaView:self.kenView AnimDuration:1.5 Alpha:0.2];// cool
        }
    }
    else{
        [self alphaView:scrollView AnimDuration:1.5 Alpha:0];
        if (!enableKenBurns){
            [self alphaImage:fanartView AnimDuration:1.5 Alpha:1];// cool
        }
        else{
            [self alphaView:self.kenView AnimDuration:1.5 Alpha:1];// cool
        }
        if (closeButton == nil){
            int cbWidth = clearLogoWidth / 2;
            int cbHeight = clearLogoHeight / 2;
            closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - cbWidth/2, self.view.bounds.size.height - cbHeight - 20, cbWidth, cbHeight)];
            [closeButton setAutoresizingMask:
             UIViewAutoresizingFlexibleTopMargin    |
             UIViewAutoresizingFlexibleRightMargin  |
             UIViewAutoresizingFlexibleLeftMargin   |
             UIViewAutoresizingFlexibleWidth
             ];
            if (clearLogoImageView.frame.size.width == 0){
                [closeButton setTitle:clearlogoButton.titleLabel.text forState:UIControlStateNormal];
                [closeButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
            }
            else{
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
	image.alpha = alphavalue;
    [UIView commitAnimations];
}

-(void)alphaView:(UIView *)view AnimDuration:(float)seconds Alpha:(float)alphavalue{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	view.alpha = alphavalue;
    [UIView commitAnimations];
}

#pragma mark - Gestures
- (void)handleSwipeFromLeft:(id)sender {
    if (![[self.detailItem objectForKey:@"disableNowPlaying"] boolValue]){
        [self showNowPlaying];
    }
}

# pragma  mark - JSON Data

-(void)addQueueAfterCurrent:(BOOL)afterCurrent{
    self.navigationItem.rightBarButtonItem.enabled=NO;
    NSDictionary *item = self.detailItem;
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
                                                [NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:[item objectForKey:@"family"]], [item objectForKey:@"family"], nil],@"item",
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
        [jsonRPC callMethod:@"Playlist.Add" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[item objectForKey:@"playlistid"], @"playlistid", [NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:[item objectForKey:@"family"]], [item objectForKey:@"family"], nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            [activityIndicatorView stopAnimating];
            if (error==nil && methodError==nil){
                [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
            }
            self.navigationItem.rightBarButtonItem.enabled=YES;
        }];
    }
}

-(void)addPlayback:(float)resumePointLocal{
    self.navigationItem.rightBarButtonItem.enabled=NO;
    [activityIndicatorView startAnimating];
    NSDictionary *item = self.detailItem;
    [jsonRPC callMethod:@"Playlist.Clear" withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:@"playlistid"], @"playlistid", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            [jsonRPC callMethod:@"Playlist.Add" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[item objectForKey:@"playlistid"], @"playlistid", [NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:[item objectForKey:@"family"]], [item objectForKey:@"family"], nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
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

-(void)SimpleAction:(NSString *)action params:(NSDictionary *)parameters{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance];
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC callMethod:action withParameters:parameters];
}

# pragma  mark - Gestures

- (void)handleSwipeFromRight:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

# pragma  mark - Life Cycle

- (void)setDetailItem:(id)newDetailItem{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        // Update the view.
    }
}

-(void)viewWillAppear:(BOOL)animated{
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
    float alphaValue = 0.2;
    if (closeButton.alpha==1){
        alphaValue = 1;
    }
    if (!enableKenBurns){
        [self alphaImage:fanartView AnimDuration:1.5 Alpha:alphaValue];// cool
    }
    else{
        if (fanartView.image!=nil){
            fanartView.alpha = 0;
            [self.kenView stopAnimation];
            [self.kenView removeFromSuperview];
            self.kenView = nil;
            self.kenView = [[KenBurnsView alloc] initWithFrame:fanartView.frame];
            self.kenView.autoresizingMask = fanartView.autoresizingMask;
            self.kenView.contentMode = fanartView.contentMode;
            self.kenView.delegate = self;
            self.kenView.alpha = 0;
            NSArray *backgroundImages = [NSArray arrayWithObjects:
                                         fanartView.image,
                                         nil];
            [self.kenView animateWithImages:backgroundImages
                         transitionDuration:45
                                       loop:YES
                                isLandscape:YES];
            [self.view insertSubview:self.kenView atIndex:1];
        }
        [self alphaView:self.kenView AnimDuration:1.5 Alpha:alphaValue];// cool
    }

}

-(void)viewDidAppear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleSwipeFromLeft:)
                                                 name: @"ECSLidingSwipeLeft"
                                               object: nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

-(void)viewDidDisappear:(BOOL)animated{
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
    [self disableScrollsToTopPropertyOnAllSubviewsOf:self.slidingViewController.view];
    scrollView.scrollsToTop = YES;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL kenBurns = NO;
    NSString *kenBurnsString = [userDefaults objectForKey:@"ken_preference"];
    if (kenBurnsString == nil || [kenBurnsString boolValue]) kenBurns = YES;
    enableKenBurns = kenBurns                                                ;
    self.kenView = nil;
    [self configureView];
    GlobalData *obj=[GlobalData getInstance];
    [[SDImageCache sharedImageCache] clearMemory];
    //    [manager cancelForDelegate:self];
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [self createInfo];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

-(void)dealloc{
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

-(NSUInteger)supportedInterfaceOrientations{
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
                             [self.kenView stopAnimation];
                             [self.kenView removeFromSuperview];
                             self.kenView = nil;
                             self.kenView = [[KenBurnsView alloc] initWithFrame:fanartView.frame];
                             self.kenView.autoresizingMask = fanartView.autoresizingMask;
                             self.kenView.contentMode = fanartView.contentMode;
                             self.kenView.delegate = self;
                             self.kenView.alpha = 0;
                             NSArray *backgroundImages = [NSArray arrayWithObjects:
                                                          fanartView.image,
                                                          nil];
                             [self.kenView animateWithImages:backgroundImages
                                          transitionDuration:45
                                                        loop:YES
                                                 isLandscape:YES];
                             [self.view insertSubview:self.kenView atIndex:1];
                             [self alphaView:self.kenView AnimDuration:.2 Alpha:alphaValue];
                         }
         ];
    }

}

@end
