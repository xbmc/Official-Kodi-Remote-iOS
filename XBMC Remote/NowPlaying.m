//
//  NowPlaying.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 24/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "NowPlaying.h"
#import "mainMenu.h"
#import "UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>
#import "GlobalData.h"
#import "SDImageCache.h"
#import "RemoteController.h"
#import "AppDelegate.h"
#import "DetailViewController.h"
#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"
#import "ShowInfoViewController.h"
#import "OBSlider.h"
#import "Utilities.h"

@interface NowPlaying ()

@end

@implementation NowPlaying

@synthesize detailItem = _detailItem;
@synthesize remoteController;
@synthesize jewelView;
@synthesize shuffleButton;
@synthesize repeatButton;
@synthesize itemLogoImage;
@synthesize songDetailsView;
@synthesize ProgressSlider;
@synthesize scrabbingView;
@synthesize itemDescription;
//@synthesize presentedFromNavigation;

#define MAX_CELLBAR_WIDTH 45
#define PROGRESSBAR_PADDING_LEFT 20
#define PROGRESSBAR_PADDING_BOTTOM 80
#define SEGMENTCONTROL_WIDTH 122
#define SEGMENTCONTROL_HEIGHT 29

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.detailItem) {
//        CGRect frame = CGRectMake(0, 0, 320, 44);
//        viewTitle = [[UILabel alloc] initWithFrame:frame];
//        viewTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//        viewTitle.backgroundColor = [UIColor clearColor];
//        viewTitle.font = [UIFont boldSystemFontOfSize:18];
//        viewTitle.shadowColor = [Utilities getGrayColor:0 alpha:0.5];
//        viewTitle.textAlignment = UITextAlignmentCenter;
//        viewTitle.textColor = [Utilities getGrayColor:230 alpha:1];
//        viewTitle.text = LOCALIZED_STR(@"Now Playing");
//        [viewTitle sizeToFit];
//        self.navigationItem.titleView = viewTitle;
        self.navigationItem.title = LOCALIZED_STR(@"Now Playing"); // DA SISTEMARE COME PARAMETRO
        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromRight:)];
        rightSwipe.numberOfTouchesRequired = 1;
        rightSwipe.cancelsTouchesInView = NO;
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:rightSwipe];
        
        UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromLeft:)];
        leftSwipe.numberOfTouchesRequired = 1;
        leftSwipe.cancelsTouchesInView = NO;
        leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.view addGestureRecognizer:leftSwipe];
    }
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}



# pragma mark - toolbar management

- (UIImage*)resizeToolbarThumb:(UIImage*)img {
    return [self resizeImage:img width:34 height:34 padding:0];
}

- (IBAction)changePlaylist:(id)sender {
    if ([sender tag] == 101 && seg_music.selected) {
        return;
    }
    if ([sender tag] == 102 && seg_video.selected) {
        return;
    }
    [self editTable:nil forceClose:YES];
    if ([playlistData count] && (playlistTableView.dragging || playlistTableView.decelerating)) {
        NSArray *visiblePaths = [playlistTableView indexPathsForVisibleRows];
        [playlistTableView scrollToRowAtIndexPath:visiblePaths[0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    if (seg_music.selected) {
        lastSelected = -1;
        seg_music.selected = NO;
        seg_video.selected = YES;
        selectedPlayerID = 1;
        musicPartyMode = 0;
        [self createPlaylist:NO animTableView:YES];
    }
    else {
        lastSelected = -1;
        seg_music.selected = YES;
        seg_video.selected = NO;
        selectedPlayerID = 0;
        musicPartyMode = 0;
        [self createPlaylist:NO animTableView:YES];
    }
}

#pragma mark - utility

- (NSString*)processSongCodecName:(NSString*)codec {
    if ([codec rangeOfString:@"musepack"].location != NSNotFound) {
        codec = [codec stringByReplacingOccurrencesOfString:@"musepack" withString:@"mpc"];
    }
    return codec;
}

- (UIImage*)loadImageFromName:(NSString*)imageName {
    UIImage *image = nil;
    if ([imageName length] != 0) {
        image = [UIImage imageNamed:[NSString stringWithFormat:@"%@", imageName]];
    }
    return image;
}

- (void)resizeCellBar:(CGFloat)width image:(UIImageView*)cellBarImage {
    NSTimeInterval time = (width == 0) ? 0.1 : 1.0;
    width = MIN(width, MAX_CELLBAR_WIDTH);
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:time];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    CGRect frame;
    frame = [cellBarImage frame];
    frame.size.width = width;
    cellBarImage.frame = frame;
    [UIView commitAnimations];
}

- (IBAction)togglePartyMode:(id)sender {
    if ([AppDelegate instance].serverVersion == 11) {
        storedItemID = -1;
        [PartyModeButton setSelected:YES];
        GlobalData *obj = [GlobalData getInstance];
        NSString *userPassword = [obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
        NSString *serverHTTP = [NSString stringWithFormat:@"http://%@%@@%@:%@/xbmcCmds/xbmcHttp?command=ExecBuiltIn&parameter=PlayerControl(Partymode('music'))", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
        NSURL *url = [NSURL URLWithString:serverHTTP];
        [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
        playerID = -1;
        selectedPlayerID = -1;
        [self createPlaylist:NO animTableView:YES];
    }
    else {
        if (musicPartyMode) {
            [PartyModeButton setSelected:NO];
            [[Utilities getJsonRPC]
             callMethod:@"Player.SetPartymode"
             withParameters:[NSDictionary dictionaryWithObjectsAndKeys: @(0), @"playerid", @"toggle", @"partymode", nil]
             onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                 [PartyModeButton setSelected:NO];
             }];
        }
        else {
            [PartyModeButton setSelected:YES];
            [[Utilities getJsonRPC]
             callMethod:@"Player.Open"
             withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                             [NSDictionary dictionaryWithObjectsAndKeys:@"music", @"partymode", nil], @"item", nil]
             onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                 [PartyModeButton setSelected:YES];
                 playerID = -1;
                 selectedPlayerID = -1;
                 storedItemID = -1;
//                 [self createPlaylist:NO animTableView:YES];
             }];
        }
    }
    return;
}

- (void)fadeView:(UIView*)view hidden:(BOOL)value {
    if (value == view.hidden) {
        return;
    }
    view.hidden = value;
}

- (void)AnimTable:(UITableView*)tV AnimDuration:(NSTimeInterval)seconds Alpha:(CGFloat)alphavalue XPos:(int)X {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	tV.alpha = alphavalue;
	CGRect frame;
	frame = [tV frame];
	frame.origin.x = X;
	tV.frame = frame;
    [UIView commitAnimations];
}

- (void)AnimButton:(UIButton*)button AnimDuration:(NSTimeInterval)seconds hidden:(BOOL)hiddenValue XPos:(int)X {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	CGRect frame;
	frame = [button frame];
	frame.origin.x = X;
	button.frame = frame;
    [UIView commitAnimations];
}

- (UIImage*)resizeImage:(UIImage*)image width:(int)destWidth height:(int)destHeight padding:(int)destPadding {
	int w = image.size.width;
    int h = image.size.height;
    if (!w || !h) {
        return image;
    }
    destPadding = 0;
    CGImageRef imageRef = [image CGImage];
	
	int width, height;
    
	if (w > h) {
		width = destWidth - destPadding;
		height = h * (destWidth - destPadding) / w;
	}
    else {
		height = destHeight - destPadding;
		width = w * (destHeight - destPadding) / h;
	}
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
	CGContextRef bitmap;
	bitmap = CGBitmapContextCreate(NULL, destWidth, destHeight, 8, 4 * destWidth, colorSpace, kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
	
	if (image.imageOrientation == UIImageOrientationLeft) {
		CGContextRotateCTM (bitmap, M_PI/2);
		CGContextTranslateCTM (bitmap, 0, -height);
		
	}
    else if (image.imageOrientation == UIImageOrientationRight) {
		CGContextRotateCTM (bitmap, -M_PI/2);
		CGContextTranslateCTM (bitmap, -width, 0);
		
	}
    else if (image.imageOrientation == UIImageOrientationUp) {
		
	}
    else if (image.imageOrientation == UIImageOrientationDown) {
		CGContextTranslateCTM (bitmap, width, height);
		CGContextRotateCTM (bitmap, -M_PI);
		
	}
	
	CGContextDrawImage(bitmap, CGRectMake((destWidth / 2) - (width / 2), (destHeight / 2) - (height / 2), width, height), imageRef);
	CGImageRef ref = CGBitmapContextCreateImage(bitmap);
	UIImage *result = [UIImage imageWithCGImage:ref];
	
	CGContextRelease(bitmap);
    CGColorSpaceRelease(colorSpace);
	CGImageRelease(ref);
	
	return result;
}

- (UIImage*)imageWithBorderFromImage:(UIImage*)source {
    return [Utilities imageWithShadow:source radius:10];
}

#pragma mark - JSON management

int lastSelected = -1;
int currentPlayerID = -1;
float storePercentage;
int storedItemID;
int currentItemID;

- (void)setCoverSize:(NSString*)type {
    NSString *jewelImg = @"";
    eJewelType jeweltype;
    if ([type isEqualToString:@"song"]) {
        jewelImg = @"jewel_cd.9";
        jeweltype = jewelTypeCD;
    }
    else if ([type isEqualToString:@"movie"]) {
        jewelImg = @"jewel_dvd.9";
        jeweltype = jewelTypeDVD;
    }
    else if ([type isEqualToString:@"episode"]) {
        jewelImg = @"jewel_tv.9";
        jeweltype = jewelTypeTV;
    }
    else {
        jewelImg = @"jewel_cd.9";
        jeweltype = jewelTypeCD;
    }
    if ([self enableJewelCases]) {
        jewelView.image = [UIImage imageNamed:jewelImg];
        thumbnailView.frame = [Utilities createCoverInsideJewel:jewelView jewelType:jeweltype];
        [nowPlayingView bringSubviewToFront:jewelView];
        thumbnailView.hidden = NO;
    }
    else {
        [nowPlayingView sendSubviewToBack:jewelView];
        thumbnailView.hidden = YES;
    }
    songDetailsView.frame = jewelView.frame;
    songDetailsView.center = [jewelView.superview convertPoint:jewelView.center toView:songDetailsView.superview];
    [nowPlayingView sendSubviewToBack:xbmcOverlayImage];
}

- (void)nothingIsPlaying {
    if (startFlipDemo) {
        UIImage *image = [UIImage imageNamed:@"xbmc_overlay_small"];
        [playlistButton setImage:image forState:UIControlStateNormal];
        [playlistButton setImage:image forState:UIControlStateHighlighted];
        [playlistButton setImage:image forState:UIControlStateSelected];
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(startFlipDemo) userInfo:nil repeats:NO];
        startFlipDemo = NO;
    }
    if (nothingIsPlaying) {
        return;
    }
    nothingIsPlaying = YES;
    ProgressSlider.userInteractionEnabled = NO;
    [ProgressSlider setThumbImage:[UIImage new] forState:UIControlStateNormal];
    [ProgressSlider setThumbImage:[UIImage new] forState:UIControlStateHighlighted];
    ProgressSlider.hidden = YES;
    currentTime.text = @"";
    thumbnailView.image = nil;
    lastThumbnail = @"";
    if (![self enableJewelCases]) {
        jewelView.image = nil;
    }
    duration.text = @"";
    albumName.text = LOCALIZED_STR(@"Nothing is playing");
    songName.text = @"";
    artistName.text = @"";
    lastSelected = -1;
    storeSelection = nil;
    songCodec.text = @"";
    songBitRate.text = @"";
    songSampleRate.text = @"";
    songNumChannels.text = @"";
    itemDescription.text = @"";
    songCodecImage.image = nil;
    songBitRateImage.image = nil;
    songSampleRateImage.image = nil;
    songNumChanImage.image = nil;
    itemLogoImage.image = nil;
    songCodec.hidden = NO;
    songBitRate.hidden = NO;
    songSampleRate.hidden = NO;
    songNumChannels.hidden = NO;
    ProgressSlider.value = 0;
    storedItemID = -1;
    [PartyModeButton setSelected:NO];
    repeatButton.hidden = YES;
    shuffleButton.hidden = YES;
    musicPartyMode = 0;
    [self setIOS7backgroundEffect:[UIColor clearColor] barTintColor:TINT_COLOR];
    NSIndexPath *selection = [playlistTableView indexPathForSelectedRow];
    if (selection) {
        [playlistTableView deselectRowAtIndexPath:selection animated:YES];
        UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
        UIImageView *coverView = (UIImageView*)[cell viewWithTag:4];
        coverView.alpha = 1.0;
        UIView *timePlaying = (UIView*)[cell viewWithTag:5];
        storeSelection = nil;
        if (!timePlaying.hidden) {
            [self fadeView:timePlaying hidden:YES];
        }
    }
    [self showPlaylistTable];
    [self toggleSongDetails];
}

- (void)setButtonImageAndStartDemo:(UIImage*)buttonImage {
    if (nowPlayingHidden || startFlipDemo) {
        [playlistButton setImage:buttonImage forState:UIControlStateNormal];
        [playlistButton setImage:buttonImage forState:UIControlStateHighlighted];
        [playlistButton setImage:buttonImage forState:UIControlStateSelected];
        if (startFlipDemo) {
            [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(startFlipDemo) userInfo:nil repeats:NO];
            startFlipDemo = NO;
        }
    }
}

- (void)IOS7colorProgressSlider:(UIColor*)color {
    [UIView transitionWithView:ProgressSlider
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        if ([color isEqual:[UIColor clearColor]]) {
                            [ProgressSlider setMinimumTrackTintColor:SLIDER_DEFAULT_COLOR];
                            if (ProgressSlider.userInteractionEnabled) {
                                UIImage *image = [UIImage imageNamed:@"pgbar_thumb_iOS7"];
                                [ProgressSlider setThumbImage:image forState:UIControlStateNormal];
                                [ProgressSlider setThumbImage:image forState:UIControlStateHighlighted];
                            }
                            [UIView transitionWithView:albumName
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [albumName setTextColor:[UIColor whiteColor]];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:songName
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [songName setTextColor:[Utilities getGrayColor:230 alpha:1]];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:artistName
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [artistName setTextColor:[UIColor lightGrayColor]];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:currentTime
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [currentTime setTextColor:[UIColor lightGrayColor]];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:duration
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [duration setTextColor:[UIColor lightGrayColor]];
                                            }
                                            completion:NULL];
                        }
                        else {
                            UIColor *lighterColor = [Utilities lighterColorForColor:color];
                            UIColor *slightLighterColor = [Utilities slightLighterColorForColor:color];
                            UIColor *progressColor = slightLighterColor;
                            UIColor *pgThumbColor = lighterColor;
                            [ProgressSlider setMinimumTrackTintColor:progressColor];
                            if (ProgressSlider.userInteractionEnabled) {
                                UIImage *thumbImage = [Utilities colorizeImage:[UIImage imageNamed:@"pgbar_thumb_iOS7"] withColor:pgThumbColor];
                                [ProgressSlider setThumbImage:thumbImage forState:UIControlStateNormal];
                                [ProgressSlider setThumbImage:thumbImage forState:UIControlStateHighlighted];
                            }
                            [UIView transitionWithView:albumName
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [albumName setTextColor:pgThumbColor];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:songName
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [songName setTextColor:pgThumbColor];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:artistName
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [artistName setTextColor:progressColor];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:currentTime
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [currentTime setTextColor:progressColor];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:duration
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [duration setTextColor:progressColor];
                                            }
                                            completion:NULL];
                        }
                    }
                    completion:NULL];
}

- (void)IOS7effect:(UIColor*)color barTintColor:(UIColor*)barColor effectDuration:(NSTimeInterval)time {
    [UIView animateWithDuration:time
                     animations:^{
                         [iOS7bgEffect setBackgroundColor:color];
                         [iOS7navBarEffect setBackgroundColor:color];
                         if ([color isEqual:[UIColor clearColor]]) {
                             self.navigationController.navigationBar.tintColor = TINT_COLOR;
                             [UIView transitionWithView:backgroundImageView
                                               duration:1.0
                                                options:UIViewAnimationOptionTransitionCrossDissolve
                                             animations:^{
                                                 backgroundImageView.image = [UIImage imageNamed:@"shiny_black_back"];
                                             }
                                             completion:NULL];
                             if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                                 NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                                         [Utilities getGrayColor:36 alpha:1], @"startColor",
                                                         [Utilities getGrayColor:22 alpha:1], @"endColor",
                                                         nil, @"image",
                                                         nil];
                                 [[NSNotificationCenter defaultCenter] postNotificationName:@"UIViewChangeBackgroundGradientColor" object:nil userInfo:params];
                                 [[NSNotificationCenter defaultCenter] postNotificationName:@"UIViewChangeBackgroundImage" object:nil userInfo:params];
                             }
                         }
                         else {
                             UIColor *lighterColor = [Utilities lighterColorForColor:color];
                             self.navigationController.navigationBar.tintColor = lighterColor;
                             [UIView transitionWithView:backgroundImageView
                                               duration:1.0
                                                options:UIViewAnimationOptionTransitionCrossDissolve
                                             animations:^{
                                                 backgroundImageView.image = [Utilities colorizeImage:[UIImage imageNamed:@"shiny_black_back"] withColor:lighterColor];
                                             }
                                             completion:NULL];
                             if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                                 CGFloat hue, saturation, brightness, alpha;
                                 BOOL ok = [color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
                                 if (ok) {
                                     UIColor *iPadStartColor = [UIColor colorWithHue:hue saturation:saturation brightness:0.2 alpha:alpha];
                                     
                                     UIColor *iPadEndColor = [UIColor colorWithHue:hue saturation:saturation brightness:0.1 alpha:alpha];
                                     NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                                             iPadStartColor, @"startColor",
                                                             iPadEndColor, @"endColor",
                                                             nil];
                                     [[NSNotificationCenter defaultCenter] postNotificationName:@"UIViewChangeBackgroundGradientColor" object:nil userInfo:params];
                                 }
                             }
                         }
                     }
                     completion:NULL];
}

- (void)setIOS7backgroundEffect:(UIColor*)color barTintColor:(UIColor*)barColor {
    foundEffectColor = color;
    if (!nowPlayingView.hidden) {
        [self IOS7colorProgressSlider:color];
        [self IOS7effect:color barTintColor:barColor effectDuration:1.0];
    }
}

- (void)changeImage:(UIImageView*)imageView image:(UIImage*)newImage {
    [UIView transitionWithView:jewelView
                      duration:0.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        imageView.image = newImage;
                    }
                    completion:NULL];
}

- (void)getActivePlayers {
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionary] withTimeout:2.0 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error == nil && methodError == nil) {
            if ([methodResult count] > 0) {
                nothingIsPlaying = NO;
                NSNumber *response;
                if (((NSNull*)methodResult[0][@"playerid"] != [NSNull null])) {
                    response = methodResult[0][@"playerid"];
                }
                currentPlayerID = [response intValue];
                if (playerID != [response intValue] || (selectedPlayerID > -1 && playerID != selectedPlayerID)) {  // DA SISTEMARE SE AGGIUNGONO ITEM DALL'ESTERNO: FUTURA SEGNALAZIONE CON SOCKET!
                    if (selectedPlayerID > -1 && playerID != selectedPlayerID) {
                        playerID = selectedPlayerID;
                    }
                    else if (selectedPlayerID == -1) {
                        playerID = [response intValue];
                        [self createPlaylist:NO animTableView:YES];
                    }
                }
                NSMutableArray *properties = [@[@"album", @"artist", @"title", @"thumbnail", @"track", @"studio", @"showtitle", @"episode", @"season", @"fanart", @"description", @"plot"] mutableCopy];
                if ([AppDelegate instance].serverVersion > 11) {
                    [properties addObject:@"art"];
                }
                [[Utilities getJsonRPC]
                 callMethod:@"Player.GetItem" 
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                                 response, @"playerid",
                                 properties, @"properties",
                                 nil] 
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error == nil && methodError == nil) {
//                         NSLog(@"Risposta %@", methodResult);
                         bool enableJewel = [self enableJewelCases];
                         if ([NSJSONSerialization isValidJSONObject:methodResult]) {
                             NSDictionary *nowPlayingInfo = nil;
                             if ((NSNull*)methodResult[@"item"] != [NSNull null]) {
                                 nowPlayingInfo = methodResult[@"item"];
                             }
                             if (nowPlayingInfo[@"id"] == nil) {
                                 currentItemID = -2;
                             }
                             else {
                                 currentItemID = [nowPlayingInfo[@"id"] intValue];
                             }
                             if (([nowPlayingInfo count] && currentItemID != storedItemID) || nowPlayingInfo[@"id"] == nil || ([nowPlayingInfo[@"type"] isEqualToString:@"channel"] && ![nowPlayingInfo[@"title"] isEqualToString:storeLiveTVTitle])) {
                                 storedItemID = currentItemID;
                                 [self performSelector:@selector(loadCodecView) withObject:nil afterDelay:.5];
                                 itemDescription.text = [nowPlayingInfo[@"description"] length] != 0 ? [NSString stringWithFormat:@"%@", nowPlayingInfo[@"description"]] : [nowPlayingInfo[@"plot"] length] != 0 ? [NSString stringWithFormat:@"%@", nowPlayingInfo[@"plot"]] : @"";
                                 [itemDescription scrollRangeToVisible:NSMakeRange(0, 0)];
                                 NSString *album = [Utilities getStringFromDictionary:nowPlayingInfo key:@"album" emptyString:@""];
                                 if ([nowPlayingInfo[@"type"] isEqualToString:@"channel"]) {
                                     album = nowPlayingInfo[@"label"];
                                 }
                                 NSString *title = [Utilities getStringFromDictionary:nowPlayingInfo key:@"title" emptyString:@""];
                                 storeLiveTVTitle = title;
                                 NSString *artist = [Utilities getStringFromDictionary:nowPlayingInfo key:@"artist" emptyString:@""];
                                 if ([album length] == 0 && ((NSNull*)nowPlayingInfo[@"showtitle"] != [NSNull null]) && nowPlayingInfo[@"season"] > 0) {
                                     album = [nowPlayingInfo[@"showtitle"] length] != 0 ? [NSString stringWithFormat:@"%@ - %@x%@", nowPlayingInfo[@"showtitle"], nowPlayingInfo[@"season"], nowPlayingInfo[@"episode"]] : @"";
                                 }
                                 if ([title length] == 0) {
                                     title = [Utilities getStringFromDictionary:nowPlayingInfo key:@"label" emptyString:@""];
                                 }

                                 if ([artist length] == 0 && ((NSNull*)nowPlayingInfo[@"studio"] != [NSNull null])) {
                                     artist = [Utilities getStringFromDictionary:nowPlayingInfo key:@"studio" emptyString:@""];
                                 }
                                 albumName.text = album;
                                 songName.text = title;
                                 artistName.text = artist;
                                 NSString *type = [Utilities getStringFromDictionary:nowPlayingInfo key:@"type" emptyString:@"unknown"];
                                 currentType = type;
                                 [self setCoverSize:currentType];
                                 GlobalData *obj = [GlobalData getInstance];
                                 NSString *serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                                 if ([AppDelegate instance].serverVersion > 11) {
                                     serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
                                 }
                                 NSString *thumbnailPath = [Utilities getThumbnailFromDictionary:nowPlayingInfo useBanner:NO useIcon:NO];
                                 NSString *stringURL = [Utilities formatStringURL:thumbnailPath serverURL:serverURL];
                                 if (![lastThumbnail isEqualToString:stringURL]) {
                                     if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                                         NSString *fanart = (NSNull*)nowPlayingInfo[@"fanart"] == [NSNull null] ? @"" : nowPlayingInfo[@"fanart"];
                                         if (![fanart isEqualToString:@""]) {
                                             NSString *fanartURL = [Utilities formatStringURL:fanart serverURL:serverURL];
                                             [tempFanartImageView setImageWithURL:[NSURL URLWithString:fanartURL]
                                                                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                                                            if (error == nil && image != nil) {
                                                                                NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: image, @"image", nil];
                                                                                [[NSNotificationCenter defaultCenter] postNotificationName:@"UIViewChangeBackgroundImage" object:nil userInfo:params];
                                                                            }
                                                                            else {
                                                                                NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: [UIImage new], @"image", nil];
                                                                                [[NSNotificationCenter defaultCenter] postNotificationName:@"UIViewChangeBackgroundImage" object:nil userInfo:params];
                                                                            }
                                                                            
                                                                        }];
                                         }
                                         else {
                                             NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: [UIImage new], @"image", nil];
                                             [[NSNotificationCenter defaultCenter] postNotificationName:@"UIViewChangeBackgroundImage" object:nil userInfo:params];
                                         }
                                     }
                                     if ([thumbnailPath isEqualToString:@""]) {
                                         UIImage *buttonImage = [self resizeToolbarThumb:[UIImage imageNamed:@"coverbox_back"]];
                                         [self setButtonImageAndStartDemo:buttonImage];
                                         [self setIOS7backgroundEffect:[UIColor clearColor] barTintColor:TINT_COLOR];
                                         if (enableJewel) {
                                             thumbnailView.image = [UIImage imageNamed:@"coverbox_back"];
                                         }
                                         else {
                                             [self changeImage:jewelView image:[UIImage imageNamed:@"coverbox_back"]];
                                         }
                                     }
                                     else {
                                         [[SDImageCache sharedImageCache] queryDiskCacheForKey:stringURL done:^(UIImage *image, SDImageCacheType cacheType) {
                                             if (image != nil) {
                                                 UIImage *buttonImage = nil;
                                                 if (enableJewel) {
                                                     thumbnailView.image = image;
                                                     buttonImage = [self resizeToolbarThumb:[self imageWithBorderFromImage:image]];
                                                 }
                                                 else {
                                                     [self changeImage:jewelView image:[self imageWithBorderFromImage:image]];
                                                     buttonImage = [self resizeToolbarThumb:jewelView.image];
                                                 }
                                                 [self setButtonImageAndStartDemo:buttonImage];
                                                 UIColor *effectColor = [Utilities averageColor:image inverse:NO];
                                                 [self setIOS7backgroundEffect:effectColor barTintColor:effectColor];
                                             }
                                             else {
                                                 __weak NowPlaying *sf = self;
                                                 __block UIColor *newColor = nil;
                                                 if (enableJewel) {
                                                     [thumbnailView setImageWithURL:[NSURL URLWithString:stringURL]
                                                                   placeholderImage:[UIImage imageNamed:@"coverbox_back"]
                                                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                                                              if (error == nil) {
                                                                                  
                                                                                  UIImage *buttonImage = [sf resizeToolbarThumb:[sf imageWithBorderFromImage:image]];
                                                                                  [sf setButtonImageAndStartDemo:buttonImage];
                                                                                  newColor = [Utilities averageColor:image inverse:NO];
                                                                                  [sf setIOS7backgroundEffect:newColor barTintColor:newColor];
                                                                              }
                                                                          }];
                                                 }
                                                 else {
                                                     __weak UIImageView *jV = jewelView;
                                                     [jewelView
                                                      setImageWithURL:[NSURL URLWithString:stringURL]
                                                      placeholderImage:[UIImage imageNamed:@"coverbox_back"]
                                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                                          if (error == nil) {
                                                              [sf changeImage:jV image:[sf imageWithBorderFromImage:image]];
                                                              UIImage *buttonImage = [sf resizeToolbarThumb:jV.image];
                                                              [sf setButtonImageAndStartDemo:buttonImage];
                                                              newColor = [Utilities averageColor:image inverse:NO];
                                                              [sf setIOS7backgroundEffect:newColor barTintColor:newColor];
                                                          }
                                                      }];
                                                 }
                                             }
                                         }];
                                     }
                                 }
                                 lastThumbnail = stringURL;
                                 itemLogoImage.image = nil;
                                 NSDictionary *art = nowPlayingInfo[@"art"];
                                 storeClearlogo = [Utilities getClearArtFromDictionary:art type:@"clearlogo"];
                                 storeClearart = [Utilities getClearArtFromDictionary:art type:@"clearart"];
                                 if ([storeClearlogo isEqualToString:@""]) {
                                     storeClearlogo = storeClearart;
                                 }
                                 if (![storeClearlogo isEqualToString:@""]) {
                                     NSString *stringURL = [Utilities formatStringURL:storeClearlogo serverURL:serverURL];
                                     [itemLogoImage setImageWithURL:[NSURL URLWithString:stringURL]];
                                     storeCurrentLogo = storeClearlogo;
                                 }
                             }
                         }
                         else {
                             storedItemID = -1;
                             lastThumbnail = @"";
                             if (enableJewel) {
                                 thumbnailView.image = [UIImage imageNamed:@"coverbox_back"];
                             }
                             else {
                                 jewelView.image = [UIImage imageNamed:@"coverbox_back"];
                             }
                         }
                     }
                     else {
                         storedItemID = -1;
                     }
                 }];
                [[Utilities getJsonRPC]
                 callMethod:@"Player.GetProperties" 
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                                 response, @"playerid",
                                 @[@"percentage", @"time", @"totaltime", @"partymode", @"position", @"canrepeat", @"canshuffle", @"repeat", @"shuffled", @"canseek"], @"properties",
                                 nil] 
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error == nil && methodError == nil) {
                         if ([NSJSONSerialization isValidJSONObject:methodResult]) {
                             //                             NSLog(@"risposta %@", methodResult);
                             if ([methodResult count]) {
                                 if (updateProgressBar) {
                                     ProgressSlider.value = [(NSNumber*)methodResult[@"percentage"] floatValue];
                                 }
                                 musicPartyMode = [methodResult[@"partymode"] intValue];
                                 if (musicPartyMode) {
                                     [PartyModeButton setSelected:YES];
                                 }
                                 else {
                                     [PartyModeButton setSelected:NO];
                                 }
                                 BOOL canrepeat = [methodResult[@"canrepeat"] boolValue] && !musicPartyMode;
                                 if (canrepeat) {
                                     repeatStatus = methodResult[@"repeat"];
                                     if (repeatButton.hidden) {
                                         repeatButton.hidden = NO;
                                     }
                                     if ([repeatStatus isEqualToString:@"all"]) {
                                         [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat_all"] forState:UIControlStateNormal];
                                     }
                                     else if ([repeatStatus isEqualToString:@"one"]) {
                                         [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat_one"] forState:UIControlStateNormal];
                                     }
                                     else {
                                         [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat"] forState:UIControlStateNormal];
                                     }
                                 }
                                 else if (!repeatButton.hidden) {
                                     repeatButton.hidden = YES;
                                 }
                                 BOOL canshuffle = [methodResult[@"canshuffle"] boolValue] && !musicPartyMode;
                                 if (canshuffle) {
                                     shuffled = [methodResult[@"shuffled"] boolValue];
                                     if (shuffleButton.hidden) {
                                         shuffleButton.hidden = NO;
                                     }
                                     if (shuffled) {
                                         [shuffleButton setBackgroundImage:[UIImage imageNamed:@"button_shuffle_on"] forState:UIControlStateNormal];
                                     }
                                     else {
                                         [shuffleButton setBackgroundImage:[UIImage imageNamed:@"button_shuffle"] forState:UIControlStateNormal];
                                     }
                                 }
                                 else if (!shuffleButton.hidden) {
                                     shuffleButton.hidden = YES;
                                 }
                                 
                                 BOOL canseek = [methodResult[@"canseek"] boolValue];
                                 if (canseek && !ProgressSlider.userInteractionEnabled) {
                                     ProgressSlider.userInteractionEnabled = YES;
                                     UIImage *image = [UIImage imageNamed:@"pgbar_thumb_iOS7"];
                                     [ProgressSlider setThumbImage:image forState:UIControlStateNormal];
                                     [ProgressSlider setThumbImage:image forState:UIControlStateHighlighted];
//                                     [ProgressSlider setThumbTintColor:[UIColor lightGrayColor]];

                                 }
                                 if (!canseek && ProgressSlider.userInteractionEnabled) {
                                     ProgressSlider.userInteractionEnabled = NO;
                                     [ProgressSlider setThumbImage:[UIImage new] forState:UIControlStateNormal];
                                     [ProgressSlider setThumbImage:[UIImage new] forState:UIControlStateHighlighted];
                                 }

                                 NSDictionary *timeGlobal = methodResult[@"totaltime"];
                                 int hoursGlobal = [timeGlobal[@"hours"] intValue];
                                 int minutesGlobal = [timeGlobal[@"minutes"] intValue];
                                 int secondsGlobal = [timeGlobal[@"seconds"] intValue];
                                 NSString *globalTime = [NSString stringWithFormat:@"%@%02i:%02i", (hoursGlobal == 0) ? @"" : [NSString stringWithFormat:@"%02i:", hoursGlobal], minutesGlobal, secondsGlobal];
                                 globalSeconds = hoursGlobal * 3600 + minutesGlobal * 60 + secondsGlobal;
                                 duration.text = globalTime;
                                 
                                 NSDictionary *time = methodResult[@"time"];
                                 int hours = [time[@"hours"] intValue];
                                 int minutes = [time[@"minutes"] intValue];
                                 int seconds = [time[@"seconds"] intValue];
                                 NSString *actualTime = [NSString stringWithFormat:@"%@%02i:%02i", (hoursGlobal == 0) ? @"" : [NSString stringWithFormat:@"%02i:", hours], minutes, seconds];
                                 if (updateProgressBar) {
                                     currentTime.text = actualTime;
                                     ProgressSlider.hidden = NO;
                                 }
                                 if (playerID == 2) {
                                     ProgressSlider.hidden = YES;
                                     currentTime.hidden = YES;
                                     duration.hidden = YES;
                                 }
                                 NSIndexPath* selection = [playlistTableView indexPathForSelectedRow];
                                 if (storeSelection) {
                                     selection = storeSelection;
                                 }
                                 if (selection) {
                                     UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
                                     UILabel *playlistActualTime = (UILabel*)[cell viewWithTag:6];
                                     playlistActualTime.text = actualTime;
                                     UIImageView *playlistActualBar = (UIImageView*)[cell viewWithTag:7];
                                     CGFloat newx = MAX(MAX_CELLBAR_WIDTH * [(NSNumber*)methodResult[@"percentage"] doubleValue] / 100, 1.0);
                                     [self resizeCellBar:newx image:playlistActualBar];
                                     UIView *timePlaying = (UIView*)[cell viewWithTag:5];
                                     if (timePlaying.hidden) {
                                         [self fadeView:timePlaying hidden:NO];
                                     }
                                 }
                                 int playlistPosition = [methodResult[@"position"] intValue];
                                 if (playlistPosition > -1) {
                                     playlistPosition += 1;
                                 }
                                 if (musicPartyMode && [(NSNumber*)methodResult[@"percentage"] floatValue] < storePercentage) { // BLEAH!!!
                                     [self checkPartyMode];
                                 }
                                 //                                 if (selection) {
                                 //                                     NSLog(@"%d %d %@", currentItemID, [playlistData[selection.row][@"idItem"] intValue], selection);
                                 //                                     
                                 ////                                     if (currentItemID != [playlistData[selection.row][@"idItem"] intValue] && [playlistData[selection.row][@"idItem"] intValue] > 0) {
                                 //////                                         lastSelected = -1;
                                 //////                                         // storeSelection = 0;
                                 //////                                         currentItemID = [playlistData[selection.row][@"idItem"] intValue];
                                 ////                                         [self createPlaylist:NO];
                                 ////                                     }
                                 //                                 }
                                 
                                 //                                 NSLog(@"CURRENT ITEMID %d PLAYLIST ID %@", currentItemID, playlistData[selection.row][@"idItem"]);
                                 storePercentage = [(NSNumber*)methodResult[@"percentage"] floatValue];
                                 if (playlistPosition != lastSelected && playlistPosition > 0) {
                                     if (([playlistData count] >= playlistPosition) && currentPlayerID == playerID) {
                                         if (playlistPosition > 0) {
                                             if (lastSelected != playlistPosition) {
                                                 NSIndexPath* selection = [playlistTableView indexPathForSelectedRow];
                                                 if (storeSelection) {
                                                     selection = storeSelection;
                                                 }
                                                 if (selection) {
                                                     UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
                                                     UIView *timePlaying = (UIView*)[cell viewWithTag:5];
                                                     if (!timePlaying.hidden) {
                                                         [self fadeView:timePlaying hidden:YES];
                                                     }
                                                     UIImageView *coverView = (UIImageView*)[cell viewWithTag:4];
                                                     coverView.alpha = 1.0;
                                                 }
                                                 NSIndexPath *newSelection = [NSIndexPath indexPathForRow:playlistPosition - 1 inSection:0];
                                                 UITableViewScrollPosition position = UITableViewScrollPositionMiddle;
                                                 if (musicPartyMode) {
                                                     position = UITableViewScrollPositionNone;
                                                 }
                                                 [playlistTableView selectRowAtIndexPath:newSelection animated:YES scrollPosition:position];
                                                 UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:newSelection];
                                                 UIView *timePlaying = (UIView*)[cell viewWithTag:5];
                                                 if (timePlaying.hidden) {
                                                     [self fadeView:timePlaying hidden:NO];
                                                 }
                                                 storeSelection = newSelection;
                                                 lastSelected = playlistPosition;
                                             }
                                         }
                                         else {
                                             NSIndexPath* selection = [playlistTableView indexPathForSelectedRow];
                                             if (selection) {
                                                 
                                                 [playlistTableView deselectRowAtIndexPath:selection animated:YES];
                                                 UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
                                                 UIView *timePlaying = (UIView*)[cell viewWithTag:5];
                                                 if (!timePlaying.hidden) {
                                                     [self fadeView:timePlaying hidden:YES];
                                                 }
                                                 UIImageView *coverView = (UIImageView*)[cell viewWithTag:4];
                                                 coverView.alpha = 1.0;
                                             }
                                         }
                                     }
                                 }
                             }
                             else {
                                 [PartyModeButton setSelected:NO];
                             }
                         }
                         else {
                             [PartyModeButton setSelected:NO];
                         }
                     }
                     else {
                         [PartyModeButton setSelected:NO];
                     }
                 }];
            }
            else {
                [self nothingIsPlaying];
                if (playerID == -1 && selectedPlayerID == -1) {
                    playerID = -2;
                    [self createPlaylist:YES animTableView:YES];
                }
            }
        }
        else {
            [self nothingIsPlaying];
        }
    }];
}

- (void)loadCodecView {
    [[Utilities getJsonRPC]
     callMethod:@"XBMC.GetInfoLabels" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                     @[@"MusicPlayer.Codec", @"MusicPlayer.SampleRate", @"MusicPlayer.BitRate", @"MusicPlayer.Channels", @"VideoPlayer.VideoResolution", @"VideoPlayer.VideoAspect", @"VideoPlayer.AudioCodec", @"VideoPlayer.VideoCodec"], @"labels",
                     nil]
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error == nil && methodError == nil && [methodResult isKindOfClass: [NSDictionary class]]) {
             NSString *codec = @"";
             NSString *bitrate = @"";
             NSString *samplerate = @"";
             NSString *numchan = @"";
             if (playerID == 0 && currentPlayerID == playerID) {
                 codec = [methodResult[@"MusicPlayer.Codec"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@", methodResult[@"MusicPlayer.Codec"]];
                 songCodec.text = codec;
                 songCodec.hidden = NO;
                 songCodecImage.image = nil;
                 songSampleRateImage.image = nil;
                 songNumChanImage.image = nil;
                 
                 codec = [self processSongCodecName:codec];
                 UIImage *songImage = [self loadImageFromName:codec];
                 [songCodecImage setImage:songImage];
                 if (songImage != nil) {
                     songCodec.hidden = YES;
                 }
                 
                 numchan = [methodResult[@"MusicPlayer.Channels"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@", methodResult[@"MusicPlayer.Channels"]];
                 songBitRate.text = numchan;
                 songBitRate.hidden = NO;
                 songBitRateImage.image = nil;
                 UIImage *numChanImage = [self loadImageFromName:numchan];
                 [songBitRateImage setImage:numChanImage];
                 if (numChanImage != nil) {
                     songBitRate.hidden = YES;
                 }
        
                 samplerate = [methodResult[@"MusicPlayer.SampleRate"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@\nkHz", methodResult[@"MusicPlayer.SampleRate"]];
                 songNumChannels.text = samplerate;
                 songNumChannels.hidden = NO;
                 
                 bitrate = [methodResult[@"MusicPlayer.BitRate"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@\nkbit/s", methodResult[@"MusicPlayer.BitRate"]];
                 songSampleRate.text = bitrate;
                 songSampleRate.hidden = NO;
             }
             else if (playerID == 1 && currentPlayerID == playerID) {
                 codec = [methodResult[@"VideoPlayer.VideoResolution"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@", methodResult[@"VideoPlayer.VideoResolution"]];
                 songCodec.text = codec;
                 songCodec.hidden = NO;
                 songCodecImage.image = nil;
                 UIImage *resolutionImage = [self loadImageFromName:codec];
                 [songCodecImage setImage:resolutionImage];
                 if (resolutionImage != nil) {
                     songCodec.hidden = YES;
                 }
                 
                 bitrate = [methodResult[@"VideoPlayer.VideoAspect"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@", methodResult[@"VideoPlayer.VideoAspect"]];
                 songBitRate.text = bitrate;
                 songBitRate.hidden = NO;
                 songBitRateImage.image = nil;
                 UIImage *aspectImage = [self loadImageFromName:bitrate];
                 [songBitRateImage setImage:aspectImage];
                 if (aspectImage != nil) {
                     songBitRate.hidden = YES;
                 }
                 
                samplerate = [methodResult[@"VideoPlayer.VideoCodec"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@", methodResult[@"VideoPlayer.VideoCodec"]];
                 songSampleRate.text = samplerate;
                 songSampleRate.hidden = NO;
                 songSampleRateImage.image = nil;
                 UIImage *videoCodecImage = [self loadImageFromName:samplerate];
                 [songSampleRateImage setImage:videoCodecImage];
                 if (videoCodecImage != nil) {
                     songSampleRate.hidden = YES;
                 }
                 
                 numchan = [methodResult[@"VideoPlayer.AudioCodec"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@", methodResult[@"VideoPlayer.AudioCodec"]];
                 numchan = [self processSongCodecName:numchan];
                 songNumChannels.text = numchan;
                 songNumChannels.hidden = NO;
                 songNumChanImage.image = nil;
                 UIImage *audioCodecImage = [self loadImageFromName:numchan];
                 [songNumChanImage setImage:audioCodecImage];
                 if (audioCodecImage != nil) {
                     songNumChannels.hidden = YES;
                 }
             }
             else {
                 songCodec.hidden = YES;
                 songBitRate.hidden = YES;
                 songSampleRate.hidden = YES;
                 songNumChannels.hidden = YES;
             }
         }
    }];
}

- (void)playbackInfo {
    if (![AppDelegate instance].serverOnLine) {
        playerID = -1;
        selectedPlayerID = -1;
        storedItemID = 0;
        [self AnimTable:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:slideFrom];
        [playlistData performSelectorOnMainThread:@selector(removeAllObjects) withObject:nil waitUntilDone:YES];
        [self nothingIsPlaying];
        return;
    }
    if ([AppDelegate instance].serverVersion == 11) {
        [[Utilities getJsonRPC]
         callMethod:@"XBMC.GetInfoBooleans" 
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                         @[@"Window.IsActive(virtualkeyboard)", @"Window.IsActive(selectdialog)"], @"booleans",
                         nil] 
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
             
             if (error == nil && methodError == nil && [methodResult isKindOfClass: [NSDictionary class]]) {
                 if (((NSNull*)methodResult[@"Window.IsActive(virtualkeyboard)"] != [NSNull null]) && ((NSNull*)methodResult[@"Window.IsActive(selectdialog)"] != [NSNull null])) {
                     NSNumber *virtualKeyboardActive = methodResult[@"Window.IsActive(virtualkeyboard)"];
                     NSNumber *selectDialogActive = methodResult[@"Window.IsActive(selectdialog)"];
                     if ([virtualKeyboardActive intValue] == 1 || [selectDialogActive intValue] == 1) {
                         return;
                     }
                     else {
                         [self getActivePlayers];
                     }
                 }
             }
         }];
    }
    else {
        [self getActivePlayers];
    }
}


- (void)clearPlaylist:(int)playlistID {
    [[Utilities getJsonRPC] callMethod:@"Playlist.Clear" withParameters:[NSDictionary dictionaryWithObjectsAndKeys: @(playlistID), @"playlistid", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error == nil && methodError == nil) {
            [self createPlaylist:NO animTableView:NO];
        }
//        else {
//            NSLog(@"ci deve essere un problema %@", methodError);
//        }
    }];
}

- (void)playbackAction:(NSString*)action params:(NSArray*)parameters checkPartyMode:(BOOL)checkPartyMode {
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionary] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error == nil && methodError == nil) {
            if ([methodResult count] > 0) {
                NSNumber *response = methodResult[0][@"playerid"];
                NSMutableArray *commonParams = [NSMutableArray arrayWithObjects:response, @"playerid", nil];
                if (parameters != nil) {
                    [commonParams addObjectsFromArray:parameters];
                }
                [[Utilities getJsonRPC] callMethod:action withParameters:[Utilities indexKeyedDictionaryFromArray:commonParams] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                    if (error == nil && methodError == nil) {
                        if (musicPartyMode && checkPartyMode) {
                            [self checkPartyMode];
                        }
                    }
//                    else {
//                        NSLog(@"ci deve essere un secondo problema %@", methodError);
//                    }
                }];
            }
        }
//        else {
//            NSLog(@"ci deve essere un primo problema %@", methodError);
//        }
    }];
}
- (void)alphaView:(UIView*)view AnimDuration:(NSTimeInterval)seconds Alpha:(CGFloat)alphavalue {
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	view.alpha = alphavalue;
    [UIView commitAnimations];
}

- (void)alphaButton:(UIButton*)button AnimDuration:(NSTimeInterval)seconds show:(BOOL)show {
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	button.hidden = show;
    [UIView commitAnimations];
}

- (void)createPlaylist:(BOOL)forcePlaylistID animTableView:(BOOL)animTable { 
    if (![AppDelegate instance].serverOnLine) {
        playerID = -1;
        selectedPlayerID = -1;
        storedItemID = 0;
        [self AnimTable:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:slideFrom];
        [playlistData performSelectorOnMainThread:@selector(removeAllObjects) withObject:nil waitUntilDone:YES];
        [self nothingIsPlaying];
        return;
    }
    if (!musicPartyMode && animTable) {
        [self AnimTable:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:slideFrom];
    }
    [activityIndicatorView startAnimating];
    GlobalData *obj = [AppDelegate instance].obj;
    int playlistID = playerID;
    if (forcePlaylistID) {
        playlistID = 0;
    }
    
    if (selectedPlayerID > -1) {
        playlistID = selectedPlayerID;
        playerID = selectedPlayerID;
    }
    
    if (playlistID == 0) {
        playerID = 0;
        [playlistSegmentedControl setSelectedSegmentIndex:0];
        seg_music.selected = YES;
        seg_video.selected = NO;
        [self AnimButton:PartyModeButton AnimDuration:0.3 hidden:NO XPos:8];
    }
    else if (playlistID == 1) {
        playerID = 1;
        [playlistSegmentedControl setSelectedSegmentIndex:1];
        seg_music.selected = NO;
        seg_video.selected = YES;
        [self AnimButton:PartyModeButton AnimDuration:0.3 hidden:YES XPos:-72];
    }
    [self alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
    [[Utilities getJsonRPC] callMethod:@"Playlist.GetItems"
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                         @[@"thumbnail", @"duration", @"artist", @"album", @"runtime", @"showtitle", @"season", @"episode", @"artistid", @"albumid", @"genre", @"tvshowid", @"file", @"title", @"art"], @"properties",
                         @(playlistID), @"playlistid",
                         nil] 
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               NSInteger total = 0;
               if (error == nil && methodError == nil) {
                   [playlistData performSelectorOnMainThread:@selector(removeAllObjects) withObject:nil waitUntilDone:YES];
                   [playlistTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
                   if ([NSJSONSerialization isValidJSONObject:methodResult]) {
                       NSArray *playlistItems = methodResult[@"items"];
                       total = [playlistItems count];
                       if (total == 0) {
                           [self alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
                       }
                       else {
                           [self alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
                       }
                       NSString *serverURL;
                       serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                       int runtimeInMinute = 1;
                       if ([AppDelegate instance].serverVersion > 11) {
                           serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
                           runtimeInMinute = 60;
                       }
                       for (int i = 0; i < total; i++) {
                           NSString *idItem = [NSString stringWithFormat:@"%@", playlistItems[i][@"id"]];
                           NSString *label = [NSString stringWithFormat:@"%@", playlistItems[i][@"label"]];
                           NSString *title = [NSString stringWithFormat:@"%@", playlistItems[i][@"title"]];
                           
                           NSString *artist = [Utilities getStringFromDictionary:playlistItems[i] key:@"artist" emptyString:@""];
                           NSString *album = [Utilities getStringFromDictionary:playlistItems[i] key:@"album" emptyString:@""];
                           
                           NSString *runtime = [Utilities getTimeFromDictionary:playlistItems[i] key:@"runtime" sec2min:runtimeInMinute];
                           
                           NSString *showtitle = playlistItems[i][@"showtitle"];
                         
                           NSString *season = playlistItems[i][@"season"];
                           NSString *episode = playlistItems[i][@"episode"];
                           NSString *type = playlistItems[i][@"type"];
                           
                           NSString *artistid = [NSString stringWithFormat:@"%@", playlistItems[i][@"artistid"]];
                           NSString *albumid = [NSString stringWithFormat:@"%@", playlistItems[i][@"albumid"]];
                           NSString *movieid = [NSString stringWithFormat:@"%@", playlistItems[i][@"id"]];
                           NSString *genre = [Utilities getStringFromDictionary:playlistItems[i] key:@"genre" emptyString:@""];
                           NSString *durationTime = @"";
                           if ([playlistItems[i][@"duration"] isKindOfClass:[NSNumber class]]) {
                               durationTime = [Utilities convertTimeFromSeconds:playlistItems[i][@"duration"]];
                           }

                           NSString *thumbnailPath = [Utilities getThumbnailFromDictionary:playlistItems[i] useBanner:NO useIcon:NO];
                           NSString *stringURL = [Utilities formatStringURL:thumbnailPath serverURL:serverURL];
                           NSNumber *tvshowid = @([[NSString stringWithFormat:@"%@", playlistItems[i][@"tvshowid"]] intValue]);
                           NSString *file = [NSString stringWithFormat:@"%@", playlistItems[i][@"file"]];
                           [playlistData addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    idItem, @"idItem",
                                                    file, @"file",
                                                    label, @"label",
                                                    title, @"title",
                                                    type, @"type",
                                                    artist, @"artist",
                                                    album, @"album",
                                                    durationTime, @"duration",
                                                    artistid, @"artistid",
                                                    albumid, @"albumid",
                                                    genre, @"genre",
                                                    movieid, @"movieid",
                                                    movieid, @"episodeid",
                                                    stringURL, @"thumbnail",
                                                    runtime, @"runtime",
                                                    showtitle, @"showtitle",
                                                    season, @"season",
                                                    episode, @"episode",
                                                    tvshowid, @"tvshowid",
                                                    nil]];
                       }
                       [self showPlaylistTable];
                       if (musicPartyMode && playlistID == 0) {
                           [playlistTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
                       }
                   }
               }
               else {
//                   NSLog(@"ci deve essere un primo problema %@", methodError);
                   [self showPlaylistTable];
               }
           }];
}

- (void)showPlaylistTable {
    numResults = (int)[playlistData count];
    if (numResults == 0) {
        [self alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
    }
    else {
        [self AnimTable:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
    [playlistTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
    [activityIndicatorView stopAnimating];
}

- (void)SimpleAction:(NSString*)action params:(NSDictionary*)parameters reloadPlaylist:(BOOL)reload startProgressBar:(BOOL)progressBar {
    [[Utilities getJsonRPC] callMethod:action withParameters:parameters onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error == nil && methodError == nil) {
            if (reload) {
                [self createPlaylist:NO animTableView:YES];
            }
            if (progressBar) {
                updateProgressBar = YES;
            }
        }
        else {
            if (progressBar) {
                updateProgressBar = YES;
            }
        }
    }];
}

- (void)showInfo:(NSDictionary*)item menuItem:(mainMenu*)menuItem indexPath:(NSIndexPath*)indexPath {
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[menuItem mainMethod][choosedTab]];
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:[menuItem mainParameters][choosedTab]];
    
    NSMutableDictionary *mutableParameters = [parameters[@"extra_info_parameters"] mutableCopy];
    NSMutableArray *mutableProperties = [parameters[@"extra_info_parameters"][@"properties"] mutableCopy];
    
    if ([parameters[@"FrodoExtraArt"] boolValue] && [AppDelegate instance].serverVersion > 11) {
        [mutableProperties addObject:@"art"];
        mutableParameters[@"properties"] = mutableProperties;
    }

    if (parameters[@"extra_info_parameters"] != nil && methods[@"extra_info_method"] != nil) {
        [self retrieveExtraInfoData:methods[@"extra_info_method"] parameters:mutableParameters index:indexPath item:item menuItem:menuItem];
    }
    else {
        [self displayInfoView:item];
    }
}

- (void)displayInfoView:(NSDictionary*)item {
    fromItself = YES;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        ShowInfoViewController *showInfoViewController = [[ShowInfoViewController alloc] initWithNibName:@"ShowInfoViewController" bundle:nil];
        showInfoViewController.detailItem = item;
        [self.navigationController pushViewController:showInfoViewController animated:YES];
    }
    else {
        ShowInfoViewController *iPadShowViewController = [[ShowInfoViewController alloc] initWithNibName:@"ShowInfoViewController" withItem:item withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
        [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadShowViewController invokeByController:self isStackStartView:YES];
        [[AppDelegate instance].windowController.stackScrollViewController enablePanGestureRecognizer];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object: nil];
    }
}

- (void)retrieveExtraInfoData:(NSString*)methodToCall parameters:(NSDictionary*)parameters index:(NSIndexPath*)indexPath item:(NSDictionary*)item menuItem:(mainMenu*)menuItem {
    NSString *itemid = @"";
    NSDictionary *mainFields = [menuItem mainFields][choosedTab];
    if (((NSNull*)mainFields[@"row6"] != [NSNull null])) {
        itemid = mainFields[@"row6"];
    }
    else {
        return; // something goes wrong
    }
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
    UIActivityIndicatorView *queuing = (UIActivityIndicatorView*)[cell viewWithTag:8];
    [queuing startAnimating];
    id object = @([item[itemid] intValue]);
    if ([AppDelegate instance].serverVersion > 11 && [methodToCall isEqualToString:@"AudioLibrary.GetArtistDetails"]) {// WORKAROUND due the lack of the artistid with Playlist.GetItems
        methodToCall = @"AudioLibrary.GetArtists";
        NSString *artistFrodoWorkaround = [NSString stringWithFormat:@"%@", item[@"idItem"]];
        object = [NSDictionary dictionaryWithObjectsAndKeys: @([artistFrodoWorkaround intValue]), @"songid", nil];
        itemid = @"filter";
    }
    NSMutableArray *newProperties = [parameters[@"properties"] mutableCopy];
    if (parameters[@"kodiExtrasPropertiesMinimumVersion"] != nil) {
        for (id key in parameters[@"kodiExtrasPropertiesMinimumVersion"]) {
            if ([AppDelegate instance].serverVersion >= [key integerValue]) {
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
    GlobalData *obj = [GlobalData getInstance];
//    NSLog(@"%@ - %@", methodToCall, newParameters);
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
                     [self somethingGoesWrong:LOCALIZED_STR(@"Details not found")];
                     return;
                 }
                 if ([AppDelegate instance].serverVersion > 11 && [methodToCall isEqualToString:@"AudioLibrary.GetArtists"]) {// WORKAROUND due the lack of the artistid with Playlist.GetItems
                     itemid_extra_info = @"artists";
                 }
                 NSDictionary *videoLibraryMovieDetail = methodResult[itemid_extra_info];
                 if (((NSNull*)videoLibraryMovieDetail == [NSNull null]) || videoLibraryMovieDetail == nil) {
                     [self somethingGoesWrong:LOCALIZED_STR(@"Details not found")];
                     return;
                 }
                 if ([AppDelegate instance].serverVersion > 11 && [methodToCall isEqualToString:@"AudioLibrary.GetArtists"]) {// WORKAROUND due the lack of the artistid with Playlist.GetItems
                     if ([methodResult[itemid_extra_info] count]) {
                         videoLibraryMovieDetail = methodResult[itemid_extra_info][0];
                     }
                     else {
                         [self somethingGoesWrong:LOCALIZED_STR(@"Details not found")];
                         return;
                     }
                 }
                 NSString *serverURL = @"";
                 serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                 if ([AppDelegate instance].serverVersion > 11) {
                     serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
                 }

                 NSString *label = [NSString stringWithFormat:@"%@", videoLibraryMovieDetail[mainFields[@"row1"]]];
                 NSString *genre = [Utilities getStringFromDictionary:videoLibraryMovieDetail key:mainFields[@"row2"] emptyString:@""];
                 
                 NSString *year = [Utilities getYearFromDictionary:videoLibraryMovieDetail key:mainFields[@"row3"]];

                 NSString *runtime = [Utilities getStringFromDictionary:videoLibraryMovieDetail key:mainFields[@"row4"] emptyString:@""];
                 
                 NSString *rating = [Utilities getRatingFromDictionary:videoLibraryMovieDetail key:mainFields[@"row5"]];
                 
                 NSString *thumbnailPath = videoLibraryMovieDetail[@"thumbnail"];
                 NSDictionary *art = videoLibraryMovieDetail[@"art"];
                 NSString *clearlogo = [Utilities getClearArtFromDictionary:art type:@"clearlogo"];
                 NSString *clearart = [Utilities getClearArtFromDictionary:art type:@"clearart"];
//                 if ([art count] && [art[@"banner"] length] != 0 && [AppDelegate instance].serverVersion > 11 && ![AppDelegate instance].obj.preferTVPosters) {
//                     thumbnailPath = art[@"banner"];
//                 }
                 NSString *stringURL = [Utilities formatStringURL:thumbnailPath serverURL:serverURL];
                 NSString *fanartURL = [Utilities formatStringURL:videoLibraryMovieDetail[@"fanart"] serverURL:serverURL];
                 if ([stringURL isEqualToString:@""]) {
                     stringURL = [Utilities getItemIconFromDictionary:videoLibraryMovieDetail mainFields:mainFields];
                 }
                 BOOL disableNowPlaying = YES;
                 NSObject *row11 = videoLibraryMovieDetail[mainFields[@"row11"]];
                 if (row11 == nil) {
                     row11 = @(0);
                 }
                 NSDictionary *newItem =
                 [NSMutableDictionary dictionaryWithObjectsAndKeys:
                  @(disableNowPlaying), @"disableNowPlaying",
                  clearlogo, @"clearlogo",
                  clearart, @"clearart",
                  label, @"label",
                  genre, @"genre",
                  stringURL, @"thumbnail",
                  fanartURL, @"fanart",
                  runtime, @"runtime",
                  videoLibraryMovieDetail[mainFields[@"row6"]], mainFields[@"row6"],
                  videoLibraryMovieDetail[mainFields[@"row8"]], mainFields[@"row8"],
                  year, @"year",
                  rating, @"rating",
                  mainFields[@"playlistid"], @"playlistid",
                  mainFields[@"row8"], @"family",
                  @([[NSString stringWithFormat:@"%@", videoLibraryMovieDetail[mainFields[@"row9"]]] intValue]), mainFields[@"row9"],
                  videoLibraryMovieDetail[mainFields[@"row10"]], mainFields[@"row10"],
                  row11, mainFields[@"row11"],
                  videoLibraryMovieDetail[mainFields[@"row12"]], mainFields[@"row12"],
                  videoLibraryMovieDetail[mainFields[@"row13"]], mainFields[@"row13"],
                  videoLibraryMovieDetail[mainFields[@"row14"]], mainFields[@"row14"],
                  videoLibraryMovieDetail[mainFields[@"row15"]], mainFields[@"row15"],
                  videoLibraryMovieDetail[mainFields[@"row16"]], mainFields[@"row16"],
                  videoLibraryMovieDetail[mainFields[@"row17"]], mainFields[@"row17"],
                  videoLibraryMovieDetail[mainFields[@"row18"]], mainFields[@"row18"],
                  videoLibraryMovieDetail[mainFields[@"row20"]], mainFields[@"row20"],
                  nil];
                 [self displayInfoView:newItem];
             }
             else {
                 [queuing stopAnimating];
             }
         }
         else {
//             NSLog(@"ERORR %@ ", methodError);
             [self somethingGoesWrong:LOCALIZED_STR(@"Details not found")];
             [queuing stopAnimating];
         }
     }];
}

- (void)somethingGoesWrong:(NSString*)message {
    UIAlertController *alertView = [Utilities createAlertOK:message message:nil];
    [self presentViewController:alertView animated:YES completion:nil];
}

# pragma mark - animations

- (void)flipAnimButton:(UIButton*)button demo:(BOOL)demo {
    if (demo) {
        anim = UIViewAnimationTransitionFlipFromLeft;
        anim2 = UIViewAnimationTransitionFlipFromLeft;
        startFlipDemo = NO;
    }
    [UIView animateWithDuration:0.2
                     animations:^{ 
                         button.hidden = YES;
                         if (nowPlayingHidden) {
                             UIImage *buttonImage;
                             if ([self enableJewelCases] && thumbnailView.image.size.width) {
                                 buttonImage = [self resizeToolbarThumb:[self imageWithBorderFromImage:thumbnailView.image]];
                             }
                             else if (jewelView.image.size.width) {
                                 buttonImage = [self resizeToolbarThumb:jewelView.image];
                             }
                             if (!buttonImage.size.width) {
                                 buttonImage = [self resizeToolbarThumb:[UIImage imageNamed:@"xbmc_overlay_small"]];
                             }
                             [button setImage:buttonImage forState:UIControlStateNormal];
                             [button setImage:buttonImage forState:UIControlStateHighlighted];
                             [button setImage:buttonImage forState:UIControlStateSelected];
                         }
                         else {
                             UIImage *image = [UIImage imageNamed:@"now_playing_playlist"];
                             [button setImage:image forState:UIControlStateNormal];
                             [button setImage:image forState:UIControlStateHighlighted];
                             [button setImage:image forState:UIControlStateSelected];
                         }
                         [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                         [UIView setAnimationTransition:anim forView:button cache:YES];
                     } 
                     completion:^(BOOL finished) {
                         [UIView beginAnimations:nil context:nil];
                         button.hidden = NO;
                         [UIView setAnimationDuration:0.5];
                         [UIView setAnimationDelegate:self];
                         [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
                         [UIView setAnimationTransition:anim2 forView:button cache:YES];
                         [UIView commitAnimations];
                     }];
}

- (void)animViews {
    UIColor *effectColor;
    UIColor *barColor;
    __block CGRect playlistToolBarOriginY = playlistActionView.frame;
    NSTimeInterval iOS7effectDuration = 1.0;
    if (!nowPlayingView.hidden) {
        iOS7effectDuration = 0.0;
        nowPlayingView.hidden = YES;
        transitionView = nowPlayingView;
        transitionedView = playlistView;
        playlistHidden = NO;
        nowPlayingHidden = YES;
        viewTitle.text = LOCALIZED_STR(@"Playlist");
        self.navigationItem.title = LOCALIZED_STR(@"Playlist");
        self.navigationItem.titleView.hidden = YES;
        anim = UIViewAnimationTransitionFlipFromRight;
        anim2 = UIViewAnimationTransitionFlipFromRight;
        effectColor = [UIColor clearColor];
        barColor = TINT_COLOR;
        playlistToolBarOriginY.origin.y = playlistTableView.frame.size.height - playlistTableView.scrollIndicatorInsets.bottom;
        [self IOS7effect:effectColor barTintColor:barColor effectDuration:0.2];
    }
    else {
        playlistView.hidden = YES;
        transitionView = playlistView;
        transitionedView = nowPlayingView;
        playlistHidden = YES;
        nowPlayingHidden = NO;
        viewTitle.text = LOCALIZED_STR(@"Now Playing");
        self.navigationItem.title = LOCALIZED_STR(@"Now Playing");
        self.navigationItem.titleView.hidden = YES;
        anim = UIViewAnimationTransitionFlipFromLeft;
        anim2 = UIViewAnimationTransitionFlipFromLeft;
        if (foundEffectColor == nil) {
            effectColor = [UIColor clearColor];
            barColor = TINT_COLOR;
        }
        else {
            effectColor = foundEffectColor;
            barColor = foundEffectColor;
        }
        playlistToolBarOriginY.origin.y = playlistTableView.frame.size.height;
    }
    [self IOS7colorProgressSlider:effectColor];

    [UIView animateWithDuration:0.2
                     animations:^{
                         [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                         [UIView setAnimationTransition:anim forView:transitionView cache:YES];
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.5
                                          animations:^{
                                              [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
                                              playlistView.hidden = playlistHidden;
                                              nowPlayingView.hidden = nowPlayingHidden;
                                              self.navigationItem.titleView.hidden = NO;
                                              playlistActionView.frame = playlistToolBarOriginY;
                                              playlistActionView.alpha = (int)nowPlayingHidden;
                                              [UIView setAnimationTransition:anim2 forView:transitionedView cache:YES];
                                          }
                                          completion:^(BOOL finished) {
                                              if (iOS7effectDuration) {
                                                  [self IOS7effect:effectColor barTintColor:barColor effectDuration:iOS7effectDuration];
                                              }
                                          }];
                     }];
    [self flipAnimButton:playlistButton demo:NO];
}

#pragma mark - bottom toolbar

- (IBAction)startVibrate:(id)sender {
    NSString *action;
    NSArray *params;
    switch ([sender tag]) {
        case 1:
            if ([AppDelegate instance].serverVersion > 11) {
                action = @"Player.GoTo";
                params = @[@"previous", @"to"];
                [self playbackAction:action params:params checkPartyMode:YES];
            }
            else {
                action = @"Player.GoPrevious";
                params = nil;
                [self playbackAction:action params:nil checkPartyMode:YES];
            }
            ProgressSlider.value = 0;
            break;
            
        case 2:
            action = @"Player.PlayPause";
            params = nil;
            [self playbackAction:action params:nil checkPartyMode:NO];
            break;
            
        case 3:
            action = @"Player.Stop";
            params = nil;
            [self playbackAction:action params:nil checkPartyMode:NO];
            storeSelection = nil;
            break;
            
        case 4:
            if ([AppDelegate instance].serverVersion > 11) {
                action = @"Player.GoTo";
                params = @[@"next", @"to"];
                [self playbackAction:action params:params checkPartyMode:YES];
            }
            else {
                action = @"Player.GoNext";
                params = nil;
                [self playbackAction:action params:nil checkPartyMode:YES];
            }
            break;
            
        case 5:
            [self animViews];
            break;
            
        case 6:
            action = @"Player.Seek";
            params = [Utilities buildPlayerSeekStepParams:@"smallbackward"];
            [self playbackAction:action params:params checkPartyMode:NO];
            break;
            
        case 7:
            action = @"Player.Seek";
            params = [Utilities buildPlayerSeekStepParams:@"smallforward"];
            [self playbackAction:action params:params checkPartyMode:NO];
            break;
                    
        default:
            break;
    }
}



- (void)updateInfo {
    [self playbackInfo];
}

- (void)toggleSongDetails {
    if ((nothingIsPlaying && songDetailsView.alpha == 0.0) || playerID == 2) {
        return;
    }
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.2];
    if (songDetailsView.alpha == 0) {
        songDetailsView.alpha = 1.0;
        [self loadCodecView];
        [itemDescription setScrollsToTop:YES];
    }
    else {
        songDetailsView.alpha = 0.0;
        [itemDescription setScrollsToTop:NO];
    }
    [UIView commitAnimations];
}

- (void)toggleHighlight:(UIButton*)button {
    button.highlighted = NO;
}

- (IBAction)changeShuffle:(id)sender {
    [shuffleButton setHighlighted:YES];
    [self performSelector:@selector(toggleHighlight:) withObject:shuffleButton afterDelay:.1];
    lastSelected = -1;
    storeSelection = nil;
    if ([AppDelegate instance].serverVersion > 11) {
        [self SimpleAction:@"Player.SetShuffle" params:[NSDictionary dictionaryWithObjectsAndKeys: @(currentPlayerID), @"playerid", @"toggle", @"shuffle", nil] reloadPlaylist:YES startProgressBar:NO];
        if (shuffled) {
            [shuffleButton setBackgroundImage:[UIImage imageNamed:@"button_shuffle"] forState:UIControlStateNormal];
        }
        else {
            [shuffleButton setBackgroundImage:[UIImage imageNamed:@"button_shuffle_on"] forState:UIControlStateNormal];
        }
    }
    else {
        if (shuffled) {
            [self SimpleAction:@"Player.UnShuffle" params:[NSDictionary dictionaryWithObjectsAndKeys: @(currentPlayerID), @"playerid", nil] reloadPlaylist:YES startProgressBar:NO];
            [shuffleButton setBackgroundImage:[UIImage imageNamed:@"button_shuffle"] forState:UIControlStateNormal];
        }
        else {
            [self SimpleAction:@"Player.Shuffle" params:[NSDictionary dictionaryWithObjectsAndKeys: @(currentPlayerID), @"playerid", nil] reloadPlaylist:YES startProgressBar:NO];
            [shuffleButton setBackgroundImage:[UIImage imageNamed:@"button_shuffle_on"] forState:UIControlStateNormal];
        }
    }
}

- (IBAction)changeRepeat:(id)sender {
    [repeatButton setHighlighted:YES];
    [self performSelector:@selector(toggleHighlight:) withObject:repeatButton afterDelay:.1];
    if ([AppDelegate instance].serverVersion > 11) {
        [self SimpleAction:@"Player.SetRepeat" params:[NSDictionary dictionaryWithObjectsAndKeys: @(currentPlayerID), @"playerid", @"cycle", @"repeat", nil] reloadPlaylist:NO startProgressBar:NO];
        if ([repeatStatus isEqualToString:@"off"]) {
            [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat_all"] forState:UIControlStateNormal];
        }
        else if ([repeatStatus isEqualToString:@"all"]) {
            [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat_one"] forState:UIControlStateNormal];

        }
        else if ([repeatStatus isEqualToString:@"one"]) {
            [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat"] forState:UIControlStateNormal];
        }
    }
    else {
        if ([repeatStatus isEqualToString:@"off"]) {
            [self SimpleAction:@"Player.Repeat" params:[NSDictionary dictionaryWithObjectsAndKeys: @(currentPlayerID), @"playerid", @"all", @"state", nil] reloadPlaylist:NO startProgressBar:NO];
            [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat_all"] forState:UIControlStateNormal];
        }
        else if ([repeatStatus isEqualToString:@"all"]) {
            [self SimpleAction:@"Player.Repeat" params:[NSDictionary dictionaryWithObjectsAndKeys: @(currentPlayerID), @"playerid", @"one", @"state", nil] reloadPlaylist:NO startProgressBar:NO];
            [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat_one"] forState:UIControlStateNormal];
            
        }
        else if ([repeatStatus isEqualToString:@"one"]) {
            [self SimpleAction:@"Player.Repeat" params:[NSDictionary dictionaryWithObjectsAndKeys: @(currentPlayerID), @"playerid", @"off", @"state", nil] reloadPlaylist:NO startProgressBar:NO];
            [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat"] forState:UIControlStateNormal];
        }
    }
}

#pragma mark - Touch Events & Gestures

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch *touch = [touches anyObject];
    CGPoint locationPoint = [[touches anyObject] locationInView:self.view];
    CGPoint viewPoint = [shuffleButton convertPoint:locationPoint fromView:self.view];
    CGPoint viewPoint2 = [repeatButton convertPoint:locationPoint fromView:self.view];
    CGPoint viewPoint3 = [itemLogoImage convertPoint:locationPoint fromView:self.view];
    if ([shuffleButton pointInside:viewPoint withEvent:event] && songDetailsView.alpha > 0 && !shuffleButton.hidden) {
        [self changeShuffle:nil];
    }
    else if ([repeatButton pointInside:viewPoint2 withEvent:event] && songDetailsView.alpha > 0 && !repeatButton.hidden) {
        [self changeRepeat:nil];
    }
    else if ([itemLogoImage pointInside:viewPoint3 withEvent:event] && songDetailsView.alpha > 0 && itemLogoImage.image != nil) {
        [self updateCurrentLogo];
    }
    else if ([touch.view isEqual:jewelView] || [touch.view isEqual:songDetailsView]) {
        [self toggleSongDetails];
    }
}

- (void)updateCurrentLogo {
    GlobalData *obj = [GlobalData getInstance];
    NSString *serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
    if ([AppDelegate instance].serverVersion > 11) {
        serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
    }
    if ([storeCurrentLogo isEqualToString:storeClearart]) {
        storeCurrentLogo = storeClearlogo;
    }
    else {
        storeCurrentLogo = storeClearart;
    }
    if (![storeCurrentLogo isEqualToString:@""]) {
        NSString *stringURL = [Utilities formatStringURL:storeCurrentLogo serverURL:serverURL];
        [itemLogoImage setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:itemLogoImage.image];
    }
}

- (IBAction)buttonToggleItemInfo:(id)sender {
    [self toggleSongDetails];
}

- (void)showClearPlaylistAlert {
    if (!playlistView.hidden && self.view.superview != nil) {
        NSString *playlistName = @"";
        if (playerID == 0) {
            playlistName = LOCALIZED_STR(@"Music ");
        }
        else if (playerID == 1) {
            playlistName = LOCALIZED_STR(@"Video ");
        }
        NSString *message = [NSString stringWithFormat:LOCALIZED_STR(@"Are you sure you want to clear the %@playlist?"), playlistName];
        UIAlertController *alertView = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* cancelButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];
        UIAlertAction* clearButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Clear Playlist") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                [self clearPlaylist:playerID];
            }];
        [alertView addAction:clearButton];
        [alertView addAction:cancelButton];
        [self presentViewController:alertView animated:YES completion:nil];
    }
}

- (IBAction)handleTableLongPress:(UILongPressGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint p = [gestureRecognizer locationInView:playlistTableView];
        NSIndexPath *indexPath = [playlistTableView indexPathForRowAtPoint:p];
        if (indexPath != nil) {
            [sheetActions removeAllObjects];
            NSDictionary *item = ([playlistData count] > indexPath.row) ? playlistData[indexPath.row] : nil;
            selected = indexPath;
            CGPoint selectedPoint = [gestureRecognizer locationInView:self.view];
            if ([item[@"albumid"] intValue] > 0) {
                [sheetActions addObjectsFromArray:@[LOCALIZED_STR(@"Album Details"), LOCALIZED_STR(@"Album Tracks")]];
            }
            if ([item[@"artistid"] intValue] > 0 || ([item[@"type"] isEqualToString:@"song"] && [AppDelegate instance].serverVersion > 11)) {
                [sheetActions addObjectsFromArray:@[LOCALIZED_STR(@"Artist Details"), LOCALIZED_STR(@"Artist Albums")]];
            }
            if ([item[@"movieid"] intValue] > 0) {
                if ([item[@"type"] isEqualToString:@"movie"]) {
                    [sheetActions addObjectsFromArray:@[LOCALIZED_STR(@"Movie Details")]];
                }
                else if ([item[@"type"] isEqualToString:@"episode"]) {
                    [sheetActions addObjectsFromArray:@[LOCALIZED_STR(@"TV Show Details"), LOCALIZED_STR(@"Episode Details")]];
                }
            }
            NSInteger numActions = [sheetActions count];
            if (numActions) {
                 NSString *title = item[@"label"];
                if ([item[@"type"] isEqualToString:@"song"]) {
                    title = [NSString stringWithFormat:@"%@\n%@\n%@", item[@"label"], item[@"album"], item[@"artist"]];
                }
                else if ([item[@"type"] isEqualToString:@"episode"]) {
                    title = [NSString stringWithFormat:@"%@\n%@x%@. %@", item[@"showtitle"], item[@"season"], item[@"episode"], item[@"label"]];
                }
                [self showActionNowPlaying:sheetActions title:title point:selectedPoint];
            }
        }
    }
}

- (IBAction)handleButtonLongPress:(UILongPressGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        switch (gestureRecognizer.view.tag) {
            case 6:// BACKWARD BUTTON - DECREASE PLAYBACK SPEED
                [self playbackAction:@"Player.SetSpeed" params:@[@"decrement", @"speed"] checkPartyMode:NO];
                break;
                
            case 7:// FORWARD BUTTON - INCREASE PLAYBACK SPEED
                [self playbackAction:@"Player.SetSpeed" params:@[@"increment", @"speed"] checkPartyMode:NO];
                break;
                
            case 88:// EDIT TABLE
                [self showClearPlaylistAlert];
                break;

            default:
                break;
        }
    }
}

- (void)changeAlphaView:(UIView*)view alpha:(CGFloat)value time:(NSTimeInterval)sec {
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:sec];
	view.alpha = value;
    [UIView commitAnimations];
}

- (IBAction)stopUpdateProgressBar:(id)sender {
    updateProgressBar = NO;
    [self changeAlphaView:scrabbingView alpha:1.0 time:0.3];
}

- (IBAction)startUpdateProgressBar:(id)sender {
    [self SimpleAction:@"Player.Seek" params:[Utilities buildPlayerSeekPercentageParams:playerID percentage:ProgressSlider.value] reloadPlaylist:NO startProgressBar:YES];
    [self changeAlphaView:scrabbingView alpha:0.0 time:0.3];
}

- (IBAction)updateCurrentTime:(id)sender {
    if (!updateProgressBar && !nothingIsPlaying) {
        int selectedTime = (ProgressSlider.value/100) * globalSeconds;
        NSUInteger h = selectedTime / 3600;
        NSUInteger m = (selectedTime / 60) % 60;
        NSUInteger s = selectedTime % 60;
        NSString *displaySelectedTime = [NSString stringWithFormat:@"%@%02lu:%02lu", (globalSeconds < 3600) ? @"" : [NSString stringWithFormat:@"%02lu:", (unsigned long)h], (unsigned long)m, (unsigned long)s];
        currentTime.text = displaySelectedTime;
        scrabbingRate.text = LOCALIZED_STR(([NSString stringWithFormat:@"Scrubbing %@", @(ProgressSlider.scrubbingSpeed)]));
    }
}

# pragma mark - Action Sheet

- (void)showActionNowPlaying:(NSMutableArray*)sheetActions title:(NSString*)title point:(CGPoint)origin {
    NSInteger numActions = [sheetActions count];
    if (numActions) {
        UIAlertController *actionView = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
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
            popPresenter.sourceRect = CGRectMake(origin.x, origin.y, 1, 1);
        }
        [self presentViewController:actionView animated:YES completion:nil];
    }
}

- (void)actionSheetHandler:(NSString*)actiontitle {
    NSDictionary *item = nil;
    NSInteger numPlaylistEntries = [playlistData count];
    if (selected.row < numPlaylistEntries) {
        item = playlistData[selected.row];
    }
    else {
        return;
    }
    choosedTab = -1;
    mainMenu *MenuItem = nil;
    notificationName = @"";
    if ([item[@"type"] isEqualToString:@"song"]) {
        notificationName = @"UIApplicationEnableMusicSection";
        MenuItem = [[AppDelegate instance].playlistArtistAlbums copy];
        if ([actiontitle isEqualToString:LOCALIZED_STR(@"Album Details")]) {
            choosedTab = 0;
            MenuItem.subItem.mainLabel = item [@"album"];
            [MenuItem.subItem setMainMethod:nil];
        }
        else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Album Tracks")]) {
            choosedTab = 0;
            MenuItem.subItem.mainLabel = item[@"album"];

        }
        else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Artist Details")]) {
            choosedTab = 1;
            MenuItem.subItem.mainLabel = item[@"artist"];
            [MenuItem.subItem setMainMethod:nil];
        }
        else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Artist Albums")]) {
            choosedTab = 1;
            MenuItem.subItem.mainLabel = item[@"artist"];
        }
        else {
            return;
        }
    }
    else if ([item[@"type"] isEqualToString:@"movie"]) {
        MenuItem = [AppDelegate instance].playlistMovies;
        choosedTab = 0;
        MenuItem.subItem.mainLabel = item[@"label"];
        notificationName = @"UIApplicationEnableMovieSection";
    }
    else if ([item[@"type"] isEqualToString:@"episode"]) {
        notificationName = @"UIApplicationEnableTvShowSection";
        if ([actiontitle isEqualToString:LOCALIZED_STR(@"Episode Details")]) {
            MenuItem = [AppDelegate instance].playlistTvShows.subItem;
            choosedTab = 0;
            MenuItem.subItem.mainLabel = item[@"label"];
        }
        else if ([actiontitle isEqualToString:LOCALIZED_STR(@"TV Show Details")]) {
            MenuItem = [[AppDelegate instance].playlistTvShows copy];
            [MenuItem.subItem setMainMethod:nil];
            choosedTab = 0;
            MenuItem.subItem.mainLabel = item[@"label"];
        }
    }
    else {
        return;
    }
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[MenuItem.subItem mainMethod][choosedTab]];
    if (methods[@"method"] != nil) { // THERE IS A CHILD
        NSDictionary *mainFields = [MenuItem mainFields][choosedTab];
        NSMutableDictionary *parameters = [Utilities indexKeyedMutableDictionaryFromArray:[MenuItem.subItem mainParameters][choosedTab]];
        NSString *key = @"null";
        if (item[mainFields[@"row15"]] != nil) {
            key = mainFields[@"row15"];
        }
        id obj = @([item[mainFields[@"row6"]] intValue]);
        id objKey = mainFields[@"row6"];
        if ([AppDelegate instance].serverVersion > 11 && ![parameters[@"disableFilterParameter"] boolValue]) {
            if ([mainFields[@"row6"] isEqualToString:@"artistid"]) { // WORKAROUND due the lack of the artistid with Playlist.GetItems
                NSString *artistFrodoWorkaround = [NSString stringWithFormat:@"%@", [item[@"artist"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                obj = [NSDictionary dictionaryWithObjectsAndKeys:artistFrodoWorkaround, @"artist", nil];
            }
            else {
                obj = [NSDictionary dictionaryWithObjectsAndKeys: @([item[mainFields[@"row6"]] intValue]), mainFields[@"row6"], nil];
            }
            objKey = @"filter";
        }
        NSMutableArray *newParameters = [NSMutableArray arrayWithObjects:
                                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        obj, objKey,
                                        parameters[@"parameters"][@"properties"], @"properties",
                                        parameters[@"parameters"][@"sort"], @"sort",
                                        item[mainFields[@"row15"]], key,
                                        nil], @"parameters", parameters[@"label"], @"label",
                                       parameters[@"extra_info_parameters"], @"extra_info_parameters",
                                       [NSDictionary dictionaryWithDictionary:parameters[@"itemSizes"]], @"itemSizes",
                                       [NSString stringWithFormat:@"%d", [parameters[@"enableCollectionView"] boolValue]], @"enableCollectionView",
                                       nil];
        [[MenuItem.subItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
        MenuItem.subItem.chooseTab = choosedTab;
        fromItself = YES;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
            detailViewController.detailItem = MenuItem.subItem;
            [self.navigationController pushViewController:detailViewController animated:YES];
        }
        else {
            DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem.subItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
            [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:YES];
            [[AppDelegate instance].windowController.stackScrollViewController enablePanGestureRecognizer];
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object: nil];
        }
    }
    else {
        [self showInfo:item menuItem:MenuItem indexPath:selected];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return [playlistData count];
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
//	cell.backgroundColor = [Utilities getGrayColor:217 alpha:1];
    cell.backgroundColor = [Utilities getSystemGray6];

}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"playlistCell"];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"playlistCellView" owner:self options:nil];
        cell = nib[0];
        [(UILabel*)[cell viewWithTag:1] setHighlightedTextColor:[Utilities get1stLabelColor]];
        [(UILabel*)[cell viewWithTag:2] setHighlightedTextColor:[Utilities get2ndLabelColor]];
        [(UILabel*)[cell viewWithTag:3] setHighlightedTextColor:[Utilities get2ndLabelColor]];
        
        [(UILabel*)[cell viewWithTag:1] setTextColor:[Utilities get1stLabelColor]];
        [(UILabel*)[cell viewWithTag:2] setTextColor:[Utilities get2ndLabelColor]];
        [(UILabel*)[cell viewWithTag:3] setTextColor:[Utilities get2ndLabelColor]];
    }
    NSDictionary *item = ([playlistData count] > indexPath.row) ? playlistData[indexPath.row] : nil;
    UIImageView *thumb = (UIImageView*)[cell viewWithTag:4];
    
    UILabel *mainLabel = (UILabel*)[cell viewWithTag:1];
    UILabel *subLabel = (UILabel*)[cell viewWithTag:2];
    UILabel *cornerLabel = (UILabel*)[cell viewWithTag:3];

    [mainLabel setText:![item[@"title"] isEqualToString:@""] ? item[@"title"] : item[@"label"]];
    [(UILabel*)[cell viewWithTag:2] setText:@""];
    if ([item[@"type"] isEqualToString:@"episode"]) {
        if ([item[@"season"] intValue] != 0 || [item[@"episode"] intValue] != 0) {
            [mainLabel setText:[NSString stringWithFormat:@"%@x%02i. %@", item[@"season"], [item[@"episode"] intValue], item[@"label"]]];
        }
        [subLabel setText:[NSString stringWithFormat:@"%@", item[@"showtitle"]]];
    }
    else if ([item[@"type"] isEqualToString:@"song"]) {
        NSString *artist = [item[@"artist"] length] == 0 ? @"" : [NSString stringWithFormat:@" - %@", item[@"artist"]];
        [subLabel setText:[NSString stringWithFormat:@"%@%@", item[@"album"], artist]];
    }
    else if ([item[@"type"] isEqualToString:@"movie"]) {
        [subLabel setText:[NSString stringWithFormat:@"%@", item[@"genre"]]];
    }
    if (playerID == 0)
        [cornerLabel setText:item[@"duration"]];
    if (playerID == 1)
        [cornerLabel setText:item[@"runtime"]];
    NSString *stringURL = item[@"thumbnail"];
    [thumb setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:@"nocover_music"]];
    // andResize:CGSizeMake(thumb.frame.size.width, thumb.frame.size.height)
    UIView *timePlaying = (UIView*)[cell viewWithTag:5];
    if (!timePlaying.hidden) {
        [self fadeView:timePlaying hidden:YES];
    }
    
    return cell;
}
- (void)tableView:(UITableView*)tableView didDeselectRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
    UIImageView *coverView = (UIImageView*)[cell viewWithTag:4];
    coverView.alpha = 1.0;
    UIView *timePlaying = (UIView*)[cell viewWithTag:5];
    storeSelection = nil;
    if (!timePlaying.hidden)
        [self fadeView:timePlaying hidden:YES];
}

- (void)checkPartyMode {
    if (musicPartyMode) {
        lastSelected = -1;
        storeSelection = 0;
        [self createPlaylist:NO animTableView:YES];
    }
 }

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
    UIActivityIndicatorView *queuing = (UIActivityIndicatorView*)[cell viewWithTag:8];
    storeSelection = nil;
    [queuing startAnimating];
    if (playerID == -2) {
        playerID = 0;
    }
    [[Utilities getJsonRPC]
     callMethod:@"Player.Open" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      @(indexPath.row), @"position", @(playerID), @"playlistid", nil], @"item", nil]
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error == nil && methodError == nil) {
             storedItemID = -1;
             UIActivityIndicatorView *queuing = (UIActivityIndicatorView*)[cell viewWithTag:8];
             [queuing stopAnimating];
             UIView *timePlaying = (UIView*)[cell viewWithTag:5];
             if (timePlaying.hidden) {
                 [self fadeView:timePlaying hidden:NO];
             }
//             [self SimpleAction:@"GUI.SetFullscreen" params:[NSDictionary dictionaryWithObjectsAndKeys:@(YES), @"fullscreen", nil] reloadPlaylist:NO startProgressBar:NO];
         }
         else {
             UIActivityIndicatorView *queuing = (UIActivityIndicatorView*)[cell viewWithTag:8];
             [queuing stopAnimating];
         }
     }
     ];
    
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
    if (storeSelection && storeSelection.row == indexPath.row)
        return NO;
    return YES;
}

- (BOOL)tableView:(UITableView*)tableview canMoveRowAtIndexPath:(NSIndexPath*)indexPath {
    return YES;
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
    
    NSDictionary *objSource = playlistData[sourceIndexPath.row];
    NSDictionary *itemToMove;
    
    int idItem = [objSource[@"idItem"] intValue];
    if (idItem) {
        itemToMove = [NSDictionary dictionaryWithObjectsAndKeys:
                      @(idItem), [NSString stringWithFormat:@"%@id", objSource[@"type"]],
                      nil];
    }
    else {
        itemToMove = [NSDictionary dictionaryWithObjectsAndKeys:
                      objSource[@"file"], @"file",
                      nil];
    }
    
    NSString *action1 = @"Playlist.Remove";
    NSDictionary *params1 = [NSDictionary dictionaryWithObjectsAndKeys:
                          @(playerID), @"playlistid",
                          @(sourceIndexPath.row), @"position",
                          nil];
    NSString *action2 = @"Playlist.Insert";
    NSDictionary *params2 = [NSDictionary dictionaryWithObjectsAndKeys:
                          @(playerID), @"playlistid",
                          itemToMove, @"item",
                          @(destinationIndexPath.row), @"position",
                          nil];
    [[Utilities getJsonRPC] callMethod:action1 withParameters:params1 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error == nil && methodError == nil) {
            [[Utilities getJsonRPC] callMethod:action2 withParameters:params2];
            NSInteger numObj = [playlistData count];
            if ([sourceIndexPath row] < numObj) {
                [playlistData removeObjectAtIndex:[sourceIndexPath row]];
            }
            if ([destinationIndexPath row] <= [playlistData count]) {
                [playlistData insertObject:objSource atIndex:[destinationIndexPath row]];
            }
            if (sourceIndexPath.row > storeSelection.row && destinationIndexPath.row <= storeSelection.row) {
                storeSelection = [NSIndexPath indexPathForRow:storeSelection.row+1 inSection:storeSelection.section];
            }
            else if (sourceIndexPath.row < storeSelection.row && destinationIndexPath.row >= storeSelection.row) {
                storeSelection = [NSIndexPath indexPathForRow:storeSelection.row-1 inSection:storeSelection.section];
            }
            [playlistTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
        }
        else {
            [playlistTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
            [playlistTableView selectRowAtIndexPath:storeSelection animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        }
    }];
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *action1 = @"Playlist.Remove";
        NSDictionary *params1 = [NSDictionary dictionaryWithObjectsAndKeys:
                               @(playerID), @"playlistid",
                               @(indexPath.row), @"position",
                               nil];
        [[Utilities getJsonRPC] callMethod:action1 withParameters:params1 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            if (error == nil && methodError == nil) {
                NSInteger numObj = [playlistData count];
                if ([indexPath row] < numObj) {
                    [playlistData removeObjectAtIndex:indexPath.row];
                }
                if ([indexPath row] < [playlistTableView numberOfRowsInSection:[indexPath section]]) {
                    [playlistTableView beginUpdates];
                    [playlistTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
                    [playlistTableView endUpdates];
                }
                if ((storeSelection) && (indexPath.row<storeSelection.row)) {
                    storeSelection = [NSIndexPath indexPathForRow:storeSelection.row-1 inSection:storeSelection.section];
                }
            }
            else {
                [playlistTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
                [playlistTableView selectRowAtIndexPath:storeSelection animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            }
        }];
    } 
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)aTableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer {
    if (playlistTableView.editing) {
        return NO;
        
    }
    else {
        return YES;
    }
}

- (IBAction)editTable:(id)sender forceClose:(BOOL)forceClose {
    if (sender != nil) {
        forceClose = NO;
    }
    if ([playlistData count] == 0 && !playlistTableView.editing) {
        return;
    }
    if (playlistTableView.editing || forceClose) {
        [playlistTableView setEditing:NO animated:YES];
        [editTableButton setSelected:NO];
        lastSelected = -1;
        storeSelection = nil;
    }
    else {
        storeSelection = [playlistTableView indexPathForSelectedRow];
        [playlistTableView setEditing:YES animated:YES];
        [editTableButton setSelected:YES];
    }
}

# pragma mark - Swipe Gestures

- (void)handleSwipeFromRight:(id)sender {
    if (updateProgressBar) {
        if ([self.navigationController.viewControllers indexOfObject:self] == 0) {
            [self revealMenu:nil];
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)handleSwipeFromLeft:(id)sender {
    if (updateProgressBar) {
        [self revealUnderRight:nil];
    }
}

#pragma mark - Interface customizations

- (void)setNowPlayingDimension:(int)width height:(int)height YPOS:(int)YPOS {
    CGRect frame;
    
    // Maximum allowed height shall be 90% of visible height in landscape mode
    CGFloat bottomPadding = 0;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        bottomPadding = window.safeAreaInsets.bottom;
    }
    CGFloat maxheight = floor((CGRectGetHeight(UIScreen.mainScreen.bounds) - bottomPadding - playlistToolbar.frame.size.height) * 0.9);
    
    frame = ProgressSlider.frame;
    frame.origin.y = maxheight - PROGRESSBAR_PADDING_BOTTOM;
    frame.origin.x = PAD_MENU_TABLE_WIDTH + PROGRESSBAR_PADDING_LEFT;
    ProgressSlider.frame = frame;
    
    frame = scrabbingView.frame;
    frame.origin.y = ProgressSlider.frame.origin.y - scrabbingView.frame.size.height - 2;
    frame.origin.x = ProgressSlider.frame.origin.x;
    frame.size.width = ProgressSlider.frame.size.width;
    scrabbingView.frame = frame;
    
    frame = playlistToolbar.frame;
    frame.size.width = width;
    frame.origin.x = 0;
    playlistToolbar.frame = frame;
    
    frame = nowPlayingView.frame;
    frame.origin.x = PAD_MENU_TABLE_WIDTH + 2;
    frame.origin.y = YPOS;
    frame.size.height = maxheight;
    frame.size.width = width - (PAD_MENU_TABLE_WIDTH + 2);
    nowPlayingView.frame = frame;
    
    frame = iOS7bgEffect.frame;
    frame.size.width = width;
    iOS7bgEffect.frame = frame;
    
    [self setCoverSize:currentType];
}

- (void)setIphoneInterface {
    slideFrom = [self currentScreenBoundsDependOnOrientation].size.width;
    xbmcOverlayImage.hidden = YES;
    [playlistToolbar setShadowImage:[UIImage imageNamed:@"blank"] forToolbarPosition:UIBarPositionAny];
    
    // Use bigger fonts and move text and bar towards to the cover
    if (IS_AT_LEAST_IPHONE_X_HEIGHT) {
        [albumName setFont:[UIFont systemFontOfSize:20]];
        [songName setFont:[UIFont systemFontOfSize:18]];
        [artistName setFont:[UIFont systemFontOfSize:16]];
        [currentTime setFont:[UIFont systemFontOfSize:14]];
        [duration setFont:[UIFont systemFontOfSize:14]];
        
        CGRect frame;
        frame = nowPlayingView.frame;
        frame.size.width = frame.size.width;
        frame.origin.y += 30;
        frame.size.height -= 2*30;
        nowPlayingView.frame = frame;
        
        frame = ProgressSlider.frame;
        frame.origin.y -= 5;
        ProgressSlider.frame = frame;
        
        frame = scrabbingView.frame;
        frame.origin.y -= 5;
        scrabbingView.frame = frame;
        
        frame = songName.frame;
        frame.origin.y += 10;
        songName.frame = frame;
        
        frame = artistName.frame;
        frame.origin.y += 15;
        artistName.frame = frame;
    }
}

- (void)setIpadInterface {
    slideFrom = -PAD_MENU_TABLE_WIDTH;
    CGRect frame;
    
    // fontsizes and offsets for smaller iPads
    CGFloat albumFontSize  = 24;
    CGFloat songFontSize   = 20;
    CGFloat artistFontSize = 18;
    CGFloat timeFontSize   = 16;
    CGFloat songOffset     = 10;
    CGFloat artistOffset   = 15;
    
    // fontsizes and offsets for larger iPads
    if (IS_AT_LEAST_IPAD_1K_WIDTH) {
        albumFontSize  = 28;
        songFontSize   = 24;
        artistFontSize = 22;
        timeFontSize   = 20;
        songOffset     = 15;
        artistOffset   = 25;
    }
    
    [albumName setFont:[UIFont systemFontOfSize:albumFontSize]];
    [songName setFont:[UIFont systemFontOfSize:songFontSize]];
    [artistName setFont:[UIFont systemFontOfSize:artistFontSize]];
    [currentTime setFont:[UIFont systemFontOfSize:timeFontSize]];
    [duration setFont:[UIFont systemFontOfSize:timeFontSize]];
    
    frame = songName.frame;
    frame.origin.y += songOffset;
    songName.frame = frame;
    
    frame = artistName.frame;
    frame.origin.y += artistOffset;
    artistName.frame = frame;
    
    frame = playlistTableView.frame;
    frame.origin.x = slideFrom;
    playlistTableView.frame = frame;
    
    /* TODO: Find an elegant solution for the following code.
       Toolbar items defined in xib are:
       0, 2, 4, 6, 8, 10, 12, 14 = flexible spaces
       1, 3, 5, 7, 9, 11         = playback control buttons (skip, search, play, pause)
       13                        = button to switch between NowPlaying and playlist
       For the iPad toolbar we need to remove the not supported switch-button at
       index 13 and all flexible spaces execpt the one right of the last playback control
       button, which is the flexible space at index 12. */
    NSMutableArray *items = [NSMutableArray arrayWithArray:playlistToolbar.items];
    [items removeObjectAtIndex:14];
    [items removeObjectAtIndex:13];
    [items removeObjectAtIndex:10];
    [items removeObjectAtIndex:8];
    [items removeObjectAtIndex:6];
    [items removeObjectAtIndex:4];
    [items removeObjectAtIndex:2];
    [items removeObjectAtIndex:0];
    [playlistToolbar setItems:items animated:NO];
    playlistToolbar.alpha = 1.0;
    
    nowPlayingView.hidden = NO;
    playlistView.hidden = NO;
    xbmcOverlayImage_iphone.hidden = YES;
    playlistLeftShadow.hidden = NO;
    
    frame = playlistActionView.frame;
    frame.origin.y = playlistToolbar.frame.origin.y - playlistToolbar.frame.size.height;
    playlistActionView.frame = frame;
    playlistActionView.alpha = 1.0;
    
    [itemDescription setFont:[UIFont systemFontOfSize:15]];
}

- (BOOL)enableJewelCases {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [[userDefaults objectForKey:@"jewel_preference"] boolValue];
}

#pragma mark - GestureRecognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch {
    if ([touch.view isKindOfClass:[UISlider class]]) {
        return NO;
    }
    return YES;
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent*)event {
    if (motion == UIEventSubtypeMotionShake) {
        [self handleShakeNotification];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark - UISegmentControl

- (CGRect)currentScreenBoundsDependOnOrientation {
    return UIScreen.mainScreen.bounds;
}

- (void)addSegmentControl {
    seg_music.hidden = YES;
    seg_video.hidden = YES;
    playlistSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[LOCALIZED_STR(@"Music"), [[LOCALIZED_STR(@"Video ") capitalizedString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
    CGFloat left_margin = (PAD_MENU_TABLE_WIDTH - SEGMENTCONTROL_WIDTH)/2;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        left_margin = floor(([self currentScreenBoundsDependOnOrientation].size.width - SEGMENTCONTROL_WIDTH)/2);
    }
    playlistSegmentedControl.frame = CGRectMake(left_margin, (playlistActionView.frame.size.height - SEGMENTCONTROL_HEIGHT)/2, SEGMENTCONTROL_WIDTH, SEGMENTCONTROL_HEIGHT);
    playlistSegmentedControl.tintColor = [UIColor whiteColor];
    [playlistSegmentedControl addTarget:self action:@selector(segmentValueChanged:) forControlEvents: UIControlEventValueChanged];
    [playlistActionView addSubview:playlistSegmentedControl];
}

- (void)segmentValueChanged:(UISegmentedControl *)segment {
    [self editTable:nil forceClose:YES];
    if ([playlistData count] && (playlistTableView.dragging || playlistTableView.decelerating)) {
        NSArray *visiblePaths = [playlistTableView indexPathsForVisibleRows];
        [playlistTableView scrollToRowAtIndexPath:visiblePaths[0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    if (segment.selectedSegmentIndex == 0) {
        lastSelected = -1;
        seg_music.selected = YES;
        seg_video.selected = NO;
        selectedPlayerID = 0;
        musicPartyMode = 0;
        [self createPlaylist:NO animTableView:YES];
        
    }
    else if (segment.selectedSegmentIndex == 1) {
        lastSelected = -1;
        seg_music.selected = NO;
        seg_video.selected = YES;
        selectedPlayerID = 1;
        musicPartyMode = 0;
        [self createPlaylist:NO animTableView:YES];
    }
}

#pragma mark - Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if (self.slidingViewController.panGesture != nil) {
            [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
        }
        if ([self.navigationController.viewControllers indexOfObject:self] == 0) {
            UIImage* menuImg = [UIImage imageNamed:@"button_menu"];
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:menuImg style:UIBarButtonItemStylePlain target:nil action:@selector(revealMenu:)];
        }
        UIImage* settingsImg = [UIImage imageNamed:@"icon_menu_remote"];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:settingsImg style:UIBarButtonItemStylePlain target:self action:@selector(revealUnderRight:)];
        self.slidingViewController.underRightViewController = nil;
        self.slidingViewController.panGesture.delegate = self;
    }
    if (!fromItself) {
        if (nowPlayingView.hidden) {
            nowPlayingView.hidden = NO;
            nowPlayingHidden = NO;
            playlistView.hidden = YES;
            playlistHidden = YES;
            viewTitle.text = LOCALIZED_STR(@"Now Playing");
            self.navigationItem.title = LOCALIZED_STR(@"Now Playing");
            CGRect playlistToolBarOriginY = playlistActionView.frame;
            playlistToolBarOriginY.origin.y = playlistToolbar.frame.origin.y + playlistToolbar.frame.size.height;
            playlistActionView.frame = playlistToolBarOriginY;
        }
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            startFlipDemo = YES;
            UIImage *buttonImage;
            if ([self enableJewelCases]) {
                buttonImage = [self resizeToolbarThumb:thumbnailView.image];
            }
            else {
                buttonImage = [self resizeToolbarThumb:jewelView.image];
            }
            if (buttonImage.size.width == 0) {
                buttonImage = [UIImage imageNamed:@"xbmc_overlay_small"];
            }
            [playlistButton setImage:buttonImage forState:UIControlStateNormal];
            [playlistButton setImage:buttonImage forState:UIControlStateHighlighted];
            [playlistButton setImage:buttonImage forState:UIControlStateSelected];
        }
    }
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnterForeground:)
                                                 name: @"UIApplicationWillEnterForegroundNotification"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleXBMCPlaylistHasChanged:)
                                                 name: @"XBMCPlaylistHasChanged"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleXBMCPlaylistHasChanged:)
                                                 name: @"Playlist.OnAdd"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleXBMCPlaylistHasChanged:)
                                                 name: @"Playlist.OnClear"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleXBMCPlaylistHasChanged:)
                                                 name: @"Playlist.OnRemove"
                                               object: nil];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(revealMenu:)
                                                 name: @"RevealMenu"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(disableInteractivePopGestureRecognizer:)
                                                 name: @"ECSlidingViewUnderRightWillAppear"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(disableInteractivePopGestureRecognizer:)
                                                 name: @"ECSlidingViewTopDidReset"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(connectionSuccess:)
                                                 name: @"XBMCServerConnectionSuccess"
                                               object: nil];

    // TRICK TO FORCE VIEW IN PORTRAIT EVEN IF ROOT NAVIGATION WAS LANDSCAPE
//    UIViewController *c = [[UIViewController alloc]init];
//    [self presentModalViewController:c animated:NO];
//    [self dismissModalViewControllerAnimated:NO];
}

- (void)handleDidEnterBackground:(NSNotification*)sender {
    [self viewWillDisappear:YES];
}

- (void)disableInteractivePopGestureRecognizer:(id)sender {
    if ([[sender name] isEqualToString:@"ECSlidingViewUnderRightWillAppear"]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    else {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}

- (void)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)revealUnderRight:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECLeft];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
    [self handleXBMCPlaylistHasChanged:nil];
    [self playbackInfo];
    updateProgressBar = YES;
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateInfo) userInfo:nil repeats:YES];
    fromItself = NO;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.slidingViewController.underRightViewController = nil;
        RightMenuViewController *rightMenuViewController = [[RightMenuViewController alloc] initWithNibName:@"RightMenuViewController" bundle:nil];
        rightMenuViewController.rightMenuItems = [AppDelegate instance].nowPlayingMenuItems;
        self.slidingViewController.underRightViewController = rightMenuViewController;
    }
    // upper half of bottom area is colored in album color
    if (iOS7bgEffect == nil) {
        CGFloat bottomBarHeight = playlistToolbar.frame.size.height + bottomPadding;
        CGFloat effectHeight = bottomBarHeight/2;
        iOS7bgEffect = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - bottomBarHeight, self.view.frame.size.width, effectHeight)];
        iOS7bgEffect.autoresizingMask = playlistToolbar.autoresizingMask;
        [self.view insertSubview:iOS7bgEffect atIndex:0];
    }
    // lower half of top area is colored in album color
    if (iOS7navBarEffect == nil && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        CGFloat effectHeight = CGRectGetMaxY(self.navigationController.navigationBar.frame)/2;
        iOS7navBarEffect = [[UIView alloc] initWithFrame:CGRectMake(0, -effectHeight, self.view.frame.size.width, effectHeight)];
        iOS7navBarEffect.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self.view insertSubview:iOS7navBarEffect atIndex:0];
    }
}

- (void)startFlipDemo {
    [self flipAnimButton:playlistButton demo:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [timer invalidate];
    currentItemID = -1;
    self.slidingViewController.panGesture.delegate = nil;
    self.navigationController.navigationBar.tintColor = TINT_COLOR;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self AnimTable:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:slideFrom];
    songDetailsView.alpha = 0;
    [playlistTableView setEditing:NO animated:YES];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)setIOS7toolbar {
    UIButton *buttonItem = nil;
    for (int i = 1; i < 8; i++) {
        buttonItem = (UIButton*)[self.view viewWithTag:i];
        [buttonItem setBackgroundImage:[UIImage new] forState:UIControlStateNormal];
        [buttonItem setBackgroundImage:[UIImage new] forState:UIControlStateHighlighted];
    }
    
    [editTableButton setBackgroundImage:[UIImage new] forState:UIControlStateNormal];
    [editTableButton setBackgroundImage:[UIImage new] forState:UIControlStateHighlighted];
    [editTableButton setBackgroundImage:[UIImage new] forState:UIControlStateSelected];
    [editTableButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [editTableButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [editTableButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [editTableButton.titleLabel setShadowOffset:CGSizeZero];
    
    [PartyModeButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [PartyModeButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [PartyModeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [PartyModeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [PartyModeButton.titleLabel setShadowOffset:CGSizeZero];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    SDWebImageDownloader *manager = [SDWebImageManager sharedManager].imageDownloader;
    NSDictionary *httpHeaders = [AppDelegate instance].getServerHTTPHeaders;
    if (httpHeaders[@"Authorization"] != nil) {
        [manager setValue:httpHeaders[@"Authorization"] forHTTPHeaderField:@"Authorization"];
    }
    [itemDescription setSelectable:NO];
    [itemLogoImage.layer setMinificationFilter:kCAFilterTrilinear];
    [songCodecImage.layer setMinificationFilter:kCAFilterTrilinear];
    [songBitRateImage.layer setMinificationFilter:kCAFilterTrilinear];
    [songSampleRateImage.layer setMinificationFilter:kCAFilterTrilinear];
    [songNumChanImage.layer setMinificationFilter:kCAFilterTrilinear];
    tempFanartImageView = [UIImageView new];
    tempFanartImageView.hidden = YES;
    [self.view addSubview:tempFanartImageView];
    [seg_music setTitle:LOCALIZED_STR(@"Music") forState:UIControlStateNormal];
    [seg_video setTitle:LOCALIZED_STR(@"Video") forState:UIControlStateNormal];
    [PartyModeButton setTitle:LOCALIZED_STR(@"Party") forState:UIControlStateNormal];
    [PartyModeButton setTitle:LOCALIZED_STR(@"Party") forState:UIControlStateHighlighted];
    [PartyModeButton setTitle:LOCALIZED_STR(@"Party") forState:UIControlStateSelected];
    [editTableButton setTitle:LOCALIZED_STR(@"Edit") forState:UIControlStateNormal];
    [editTableButton setTitle:LOCALIZED_STR(@"Done") forState:UIControlStateSelected];
    editTableButton.titleLabel.numberOfLines = 1;
    editTableButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [noItemsLabel setText:LOCALIZED_STR(@"No items found.")];
    [self addSegmentControl];
    cellBackgroundColor = [UIColor whiteColor];
    bottomPadding = 0;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        bottomPadding = window.safeAreaInsets.bottom;
    }
    [self setIOS7toolbar];

    if (bottomPadding > 0) {
        CGRect frame = playlistToolbar.frame;
        frame.origin.y -= bottomPadding;
        playlistToolbar.frame = frame;
        
        frame = nowPlayingView.frame;
        frame.size.height -= bottomPadding;
        nowPlayingView.frame = frame;
        
        frame = playlistTableView.frame;
        frame.size.height -= bottomPadding;
        playlistView.frame = frame;
        playlistTableView.frame = frame;
    }
    [playlistTableView setContentInset:UIEdgeInsetsMake(0, 0, 44, 0)];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [ProgressSlider setMinimumTrackTintColor:SLIDER_DEFAULT_COLOR];
    [ProgressSlider setMaximumTrackTintColor:APP_TINT_COLOR];
    playlistTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    ProgressSlider.userInteractionEnabled = NO;
    [ProgressSlider setThumbImage:[UIImage new] forState:UIControlStateNormal];
    [ProgressSlider setThumbImage:[UIImage new] forState:UIControlStateHighlighted];
    [scrabbingMessage setText:LOCALIZED_STR(@"Slide your finger up to adjust the scrubbing rate.")];
    [scrabbingRate setText:LOCALIZED_STR(@"Scrubbing 1")];
    sheetActions = [NSMutableArray new];
    playerID = -1;
    selectedPlayerID = -1;
    lastSelected = -1;
    storedItemID = -1;
    storeSelection = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self setIphoneInterface];
    }
    else {
        [self setIpadInterface];
    }
    playlistData = [NSMutableArray new];
}

- (void)connectionSuccess:(NSNotification*)note {
    SDWebImageDownloader *manager = [SDWebImageManager sharedManager].imageDownloader;
    NSDictionary *httpHeaders = [AppDelegate instance].getServerHTTPHeaders;
    if (httpHeaders[@"Authorization"] != nil) {
        [manager setValue:httpHeaders[@"Authorization"] forHTTPHeaderField:@"Authorization"];
    }
}

- (void)handleShakeNotification {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL shake_preference = [[userDefaults objectForKey:@"shake_preference"] boolValue];
    if (shake_preference) {
        [self showClearPlaylistAlert];
    }
}

- (void)handleEnterForeground:(NSNotification*)sender {
    [self handleXBMCPlaylistHasChanged:nil];
    [self playbackInfo];
    updateProgressBar = YES;
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateInfo) userInfo:nil repeats:YES];
}

- (void)handleXBMCPlaylistHasChanged:(NSNotification*)sender {
    playerID = -1;
    selectedPlayerID = -1;
    lastSelected = -1;
    storedItemID = -1;
    storeSelection = nil;
    lastThumbnail = @"";
    [playlistData performSelectorOnMainThread:@selector(removeAllObjects) withObject:nil waitUntilDone:YES];
    [playlistTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [timer invalidate];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
