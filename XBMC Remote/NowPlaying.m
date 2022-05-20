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
@synthesize BottomView;
@synthesize scrabbingView;
@synthesize itemDescription;

#define MAX_CELLBAR_WIDTH 45
#define PARTYBUTTON_PADDING_LEFT 8
#define PROGRESSBAR_PADDING_LEFT 20
#define PROGRESSBAR_PADDING_BOTTOM 80
#define SEGMENTCONTROL_WIDTH 122
#define SEGMENTCONTROL_HEIGHT 32
#define TOOLBAR_HEIGHT 44
#define TAG_ID_PREVIOUS 1
#define TAG_ID_PLAYPAUSE 2
#define TAG_ID_STOP 3
#define TAG_ID_NEXT 4
#define TAG_ID_TOGGLE 5
#define TAG_SEEK_BACKWARD 6
#define TAG_SEEK_FORWARD 7
#define TAG_ID_EDIT 88
#define SELECTED_NONE -1

typedef enum {
    PLAYERID_UNKNOWN = -1,
    PLAYERID_MUSIC = 0,
    PLAYERID_VIDEO = 1,
    PLAYERID_PICTURES = 2
} PlayerIDs;

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

#pragma mark - utility

- (NSString*)getNowPlayingThumbnailPath:(NSDictionary*)item {
    // If a recording is played, we can use the iocn (typically the station logo)
    BOOL useIcon = [item[@"type"] isEqualToString:@"recording"] || [item[@"recordingid"] longValue] > 0;
    return [Utilities getThumbnailFromDictionary:item useBanner:NO useIcon:useIcon];
}

- (void)setSongDetails:(UILabel*)label image:(UIImageView*)imageView item:(id)item {
    label.text = [Utilities getStringFromItem:item];
    imageView.image = [self loadImageFromName:label.text];
    label.hidden = imageView.image != nil;
}

- (NSString*)processSongCodecName:(NSString*)codec {
    if ([codec rangeOfString:@"musepack"].location != NSNotFound) {
        codec = [codec stringByReplacingOccurrencesOfString:@"musepack" withString:@"mpc"];
    }
    else if ([codec hasPrefix:@"pcm"]) {
        // Map pcm_s16le, pcm_s24le, pcm_f32le and other linear pcm to "pcm".
        // Do not map other formats like adpcm to pcm.
        codec = @"pcm";
    }
    return codec;
}

- (BOOL)isLosslessFormat:(NSString*)codec {
    NSString *upperCaseCodec = [codec uppercaseString];
    return ([upperCaseCodec isEqualToString:@"WMALOSSLESS"] ||
            [upperCaseCodec isEqualToString:@"TTA"] ||
            [upperCaseCodec isEqualToString:@"TAK"] ||
            [upperCaseCodec isEqualToString:@"SHN"] ||
            [upperCaseCodec isEqualToString:@"RALF"] ||
            [upperCaseCodec isEqualToString:@"PCM"] ||
            [upperCaseCodec isEqualToString:@"MP4ALS"] ||
            [upperCaseCodec isEqualToString:@"MLP"] ||
            [upperCaseCodec isEqualToString:@"FLAC"] ||
            [upperCaseCodec isEqualToString:@"APE"] ||
            [upperCaseCodec isEqualToString:@"ALAC"]);
}

- (UIImage*)loadImageFromName:(NSString*)imageName {
    UIImage *image = nil;
    if (imageName.length != 0) {
        image = [UIImage imageNamed:[NSString stringWithFormat:@"%@", imageName]];
    }
    return image;
}

- (void)resizeCellBar:(CGFloat)width image:(UIImageView*)cellBarImage {
    NSTimeInterval time = (width == 0) ? 0.1 : 1.0;
    width = MIN(width, MAX_CELLBAR_WIDTH);
    [UIView animateWithDuration:time
                     animations:^{
        CGRect frame;
        frame = cellBarImage.frame;
        frame.size.width = width;
        cellBarImage.frame = frame;
                     }];
}

- (IBAction)togglePartyMode:(id)sender {
    if (AppDelegate.instance.serverVersion == 11) {
        storedItemID = SELECTED_NONE;
        PartyModeButton.selected = YES;
        [Utilities sendXbmcHttp:@"ExecBuiltIn&parameter=PlayerControl(Partymode('music'))"];
        playerID = PLAYERID_UNKNOWN;
        selectedPlayerID = PLAYERID_UNKNOWN;
        [self createPlaylist:NO animTableView:YES];
    }
    else {
        if (musicPartyMode) {
            PartyModeButton.selected = NO;
            [[Utilities getJsonRPC]
             callMethod:@"Player.SetPartymode"
             withParameters:@{@"playerid": @(0), @"partymode": @"toggle"}
             onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                 PartyModeButton.selected = NO;
             }];
        }
        else {
            PartyModeButton.selected = YES;
            [[Utilities getJsonRPC]
             callMethod:@"Player.Open"
             withParameters:@{@"item": @{@"partymode": @"music"}}
             onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                 PartyModeButton.selected = YES;
                 playerID = PLAYERID_UNKNOWN;
                 selectedPlayerID = PLAYERID_UNKNOWN;
                 storedItemID = SELECTED_NONE;
             }];
        }
    }
    return;
}

- (void)fadeView:(UIView*)view hidden:(BOOL)value {
    // Do not unhide the playlist progress bar while in pictures playlist
    if (!value && currentPlayerID == PLAYERID_PICTURES) {
        return;
    }
    if (value == view.hidden) {
        return;
    }
    view.hidden = value;
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
    return [Utilities applyRoundedEdgesImage:source drawBorder:YES];
}

#pragma mark - JSON management

int lastPlayerID = PLAYERID_UNKNOWN;
long lastSelected = SELECTED_NONE;
int currentPlayerID = PLAYERID_UNKNOWN;
float storePercentage;
long storedItemID;
long currentItemID;

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
    [nowPlayingView bringSubviewToFront:songDetailsView];
    [nowPlayingView bringSubviewToFront:BottomView];
    [nowPlayingView sendSubviewToBack:xbmcOverlayImage];
}

- (void)nothingIsPlaying {
    if (startFlipDemo) {
        UIImage *image = [UIImage imageNamed:@"st_kodi_window"];
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
    albumName.text = @"";
    songName.text = @"";
    artistName.text = @"";
    lastSelected = SELECTED_NONE;
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
    storedItemID = SELECTED_NONE;
    PartyModeButton.selected = NO;
    repeatButton.hidden = YES;
    shuffleButton.hidden = YES;
    hiresImage.hidden = YES;
    musicPartyMode = 0;
    [self setIOS7backgroundEffect:UIColor.clearColor barTintColor:TINT_COLOR];
    [self hidePlaylistProgressbarWithDeselect:YES];
    [self showPlaylistTable];
    [self toggleSongDetails];
}

- (void)setButtonImageAndStartDemo:(UIImage*)buttonImage {
    if (nowPlayingHidden || startFlipDemo) {
        [playlistButton setImage:buttonImage forState:UIControlStateNormal];
        [playlistButton setImage:buttonImage forState:UIControlStateHighlighted];
        [playlistButton setImage:buttonImage forState:UIControlStateSelected];
        if (startFlipDemo) {
            [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(startFlipDemo) userInfo:nil repeats:NO];
            startFlipDemo = NO;
        }
    }
}

- (void)IOS7colorProgressSlider:(UIColor*)color {
    [UIView transitionWithView:ProgressSlider
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        if ([color isEqual:UIColor.clearColor]) {
                            ProgressSlider.minimumTrackTintColor = SLIDER_DEFAULT_COLOR;
                            if (ProgressSlider.userInteractionEnabled) {
                                UIImage *image = [UIImage imageNamed:@"pgbar_thumb_iOS7"];
                                [ProgressSlider setThumbImage:image forState:UIControlStateNormal];
                                [ProgressSlider setThumbImage:image forState:UIControlStateHighlighted];
                            }
                            [UIView transitionWithView:albumName
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                albumName.textColor = UIColor.whiteColor;
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:songName
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                songName.textColor = [Utilities getGrayColor:230 alpha:1];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:artistName
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                artistName.textColor = UIColor.lightGrayColor;
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:currentTime
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                currentTime.textColor = UIColor.lightGrayColor;
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:duration
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                duration.textColor = UIColor.lightGrayColor;
                                            }
                                            completion:NULL];
                        }
                        else {
                            UIColor *lighterColor = [Utilities lighterColorForColor:color];
                            UIColor *slightLighterColor = [Utilities slightLighterColorForColor:color];
                            UIColor *progressColor = slightLighterColor;
                            UIColor *pgThumbColor = lighterColor;
                            ProgressSlider.minimumTrackTintColor = progressColor;
                            if (ProgressSlider.userInteractionEnabled) {
                                UIImage *thumbImage = [Utilities colorizeImage:[UIImage imageNamed:@"pgbar_thumb_iOS7"] withColor:pgThumbColor];
                                [ProgressSlider setThumbImage:thumbImage forState:UIControlStateNormal];
                                [ProgressSlider setThumbImage:thumbImage forState:UIControlStateHighlighted];
                            }
                            [UIView transitionWithView:albumName
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                albumName.textColor = pgThumbColor;
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:songName
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                songName.textColor = pgThumbColor;
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:artistName
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                artistName.textColor = progressColor;
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:currentTime
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                currentTime.textColor = progressColor;
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:duration
                                              duration:1.0
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                duration.textColor = progressColor;
                                            }
                                            completion:NULL];
                        }
                    }
                    completion:NULL];
}

- (void)IOS7effect:(UIColor*)color barTintColor:(UIColor*)barColor effectDuration:(NSTimeInterval)time {
    [UIView animateWithDuration:time
                     animations:^{
                         iOS7bgEffect.backgroundColor = color;
                         iOS7navBarEffect.backgroundColor = color;
                         if ([color isEqual:UIColor.clearColor]) {
                             self.navigationController.navigationBar.tintColor = TINT_COLOR;
                             [UIView transitionWithView:backgroundImageView
                                               duration:1.0
                                                options:UIViewAnimationOptionTransitionCrossDissolve
                                             animations:^{
                                                 backgroundImageView.image = [UIImage imageNamed:@"shiny_black_back"];
                                             }
                                             completion:NULL];
                             if (IS_IPAD) {
                                 NSDictionary *params = @{@"startColor": [Utilities getGrayColor:36 alpha:1],
                                                          @"endColor": [Utilities getGrayColor:22 alpha:1]};
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
                             if (IS_IPAD) {
                                 CGFloat hue, saturation, brightness, alpha;
                                 BOOL ok = [color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
                                 if (ok) {
                                     UIColor *iPadStartColor = [UIColor colorWithHue:hue saturation:saturation brightness:0.2 alpha:alpha];
                                     UIColor *iPadEndColor = [UIColor colorWithHue:hue saturation:saturation brightness:0.1 alpha:alpha];
                                     NSDictionary *params = @{@"startColor": iPadStartColor,
                                                              @"endColor": iPadEndColor};
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
            if ([methodResult isKindOfClass:[NSArray class]] && [methodResult count] > 0) {
                nothingIsPlaying = NO;
                NSNumber *response;
                if (methodResult[0][@"playerid"] != [NSNull null]) {
                    response = methodResult[0][@"playerid"];
                }
                currentPlayerID = [response intValue];
                if (playerID != currentPlayerID ||
                    lastPlayerID != currentPlayerID ||
                    (selectedPlayerID != PLAYERID_UNKNOWN && playerID != selectedPlayerID)) {
                    if (selectedPlayerID != PLAYERID_UNKNOWN && playerID != selectedPlayerID) {
                        lastPlayerID = playerID = selectedPlayerID;
                    }
                    else if (selectedPlayerID == PLAYERID_UNKNOWN) {
                        lastPlayerID = playerID = currentPlayerID;
                        [self createPlaylist:NO animTableView:YES];
                    }
                    else if (lastPlayerID != currentPlayerID) {
                        lastPlayerID = selectedPlayerID = currentPlayerID;
                        if (playerID != currentPlayerID) {
                            [self createPlaylist:NO animTableView:YES];
                        }
                    }
                }
                NSMutableArray *properties = [@[@"album",
                                                @"artist",
                                                @"title",
                                                @"thumbnail",
                                                @"track",
                                                @"studio",
                                                @"showtitle",
                                                @"episode",
                                                @"season",
                                                @"fanart",
                                                @"description",
                                                @"plot"] mutableCopy];
                if (AppDelegate.instance.serverVersion > 11) {
                    [properties addObject:@"art"];
                }
                [[Utilities getJsonRPC]
                 callMethod:@"Player.GetItem" 
                 withParameters:@{@"playerid": @(currentPlayerID),
                                  @"properties": properties}
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error == nil && methodError == nil) {
                         bool enableJewel = [self enableJewelCases];
                         if ([NSJSONSerialization isValidJSONObject:methodResult]) {
                             NSDictionary *nowPlayingInfo = nil;
                             if (methodResult[@"item"] != [NSNull null]) {
                                 nowPlayingInfo = methodResult[@"item"];
                             }
                             if (nowPlayingInfo[@"id"] == nil) {
                                 currentItemID = -2;
                             }
                             else {
                                 currentItemID = [nowPlayingInfo[@"id"] longValue];
                             }
                             if ((nowPlayingInfo.count && currentItemID != storedItemID) || nowPlayingInfo[@"id"] == nil || ([nowPlayingInfo[@"type"] isEqualToString:@"channel"] && ![nowPlayingInfo[@"title"] isEqualToString:storeLiveTVTitle])) {
                                 storedItemID = currentItemID;
                                 [self performSelector:@selector(loadCodecView) withObject:nil afterDelay:.5];
                                 itemDescription.text = [nowPlayingInfo[@"description"] length] != 0 ? [NSString stringWithFormat:@"%@", nowPlayingInfo[@"description"]] : [nowPlayingInfo[@"plot"] length] != 0 ? [NSString stringWithFormat:@"%@", nowPlayingInfo[@"plot"]] : @"";
                                 [itemDescription scrollRangeToVisible:NSMakeRange(0, 0)];
                                 NSString *album = [Utilities getStringFromItem:nowPlayingInfo[@"album"]];
                                 if ([nowPlayingInfo[@"type"] isEqualToString:@"channel"]) {
                                     album = nowPlayingInfo[@"label"];
                                 }
                                 NSString *title = [Utilities getStringFromItem:nowPlayingInfo[@"title"]];
                                 storeLiveTVTitle = title;
                                 NSString *artist = [Utilities getStringFromItem:nowPlayingInfo[@"artist"]];
                                 if (album.length == 0 && ((NSNull*)nowPlayingInfo[@"showtitle"] != [NSNull null]) && nowPlayingInfo[@"season"] > 0) {
                                     album = [nowPlayingInfo[@"showtitle"] length] != 0 ? [NSString stringWithFormat:@"%@ - %@x%@", nowPlayingInfo[@"showtitle"], nowPlayingInfo[@"season"], nowPlayingInfo[@"episode"]] : @"";
                                 }
                                 if (title.length == 0) {
                                     title = [Utilities getStringFromItem:nowPlayingInfo[@"label"]];
                                 }

                                 if (artist.length == 0 && ((NSNull*)nowPlayingInfo[@"studio"] != [NSNull null])) {
                                     artist = [Utilities getStringFromItem:nowPlayingInfo[@"studio"]];
                                 }
                                 albumName.text = album;
                                 songName.text = title;
                                 artistName.text = artist;
                                 NSString *type = [Utilities getStringFromItem:nowPlayingInfo[@"type"]];
                                 currentType = type;
                                 [self setCoverSize:currentType];
                                 GlobalData *obj = [GlobalData getInstance];
                                 NSString *serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                                 if (AppDelegate.instance.serverVersion > 11) {
                                     serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
                                 }
                                 NSString *thumbnailPath = [self getNowPlayingThumbnailPath:nowPlayingInfo];
                                 NSString *stringURL = [Utilities formatStringURL:thumbnailPath serverURL:serverURL];
                                 if (![lastThumbnail isEqualToString:stringURL] || [lastThumbnail isEqualToString:@""]) {
                                     if (IS_IPAD) {
                                         NSString *fanart = (NSNull*)nowPlayingInfo[@"fanart"] == [NSNull null] ? @"" : nowPlayingInfo[@"fanart"];
                                         if (![fanart isEqualToString:@""]) {
                                             NSString *fanartURL = [Utilities formatStringURL:fanart serverURL:serverURL];
                                             [tempFanartImageView setImageWithURL:[NSURL URLWithString:fanartURL]
                                                                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                                                            if (error == nil && image != nil) {
                                                                                NSDictionary *params = @{@"image": image};
                                                                                [[NSNotificationCenter defaultCenter] postNotificationName:@"UIViewChangeBackgroundImage" object:nil userInfo:params];
                                                                            }
                                                                            else {
                                                                                NSDictionary *params = @{@"image": [UIImage new]};
                                                                                [[NSNotificationCenter defaultCenter] postNotificationName:@"UIViewChangeBackgroundImage" object:nil userInfo:params];
                                                                            }
                                                                            
                                                                        }];
                                         }
                                         else {
                                             NSDictionary *params = @{@"image": [UIImage new]};
                                             [[NSNotificationCenter defaultCenter] postNotificationName:@"UIViewChangeBackgroundImage" object:nil userInfo:params];
                                         }
                                     }
                                     if ([thumbnailPath isEqualToString:@""]) {
                                         UIImage *buttonImage = [self resizeToolbarThumb:[UIImage imageNamed:@"coverbox_back"]];
                                         [self setButtonImageAndStartDemo:buttonImage];
                                         [self setIOS7backgroundEffect:UIColor.clearColor barTintColor:TINT_COLOR];
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
                                                     [jewelView setImageWithURL:[NSURL URLWithString:stringURL]
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
                             storedItemID = SELECTED_NONE;
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
                         storedItemID = SELECTED_NONE;
                     }
                 }];
                [[Utilities getJsonRPC]
                 callMethod:@"Player.GetProperties" 
                 withParameters:@{@"playerid": @(currentPlayerID),
                                  @"properties": @[@"percentage",
                                                   @"time",
                                                   @"totaltime",
                                                   @"partymode",
                                                   @"position",
                                                   @"canrepeat",
                                                   @"canshuffle",
                                                   @"repeat",
                                                   @"shuffled",
                                                   @"canseek"]}
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error == nil && methodError == nil) {
                         if ([NSJSONSerialization isValidJSONObject:methodResult]) {
                             if ([methodResult count]) {
                                 if (updateProgressBar) {
                                     ProgressSlider.value = [(NSNumber*)methodResult[@"percentage"] floatValue];
                                 }
                                 musicPartyMode = [methodResult[@"partymode"] intValue];
                                 if (musicPartyMode) {
                                     PartyModeButton.selected = YES;
                                 }
                                 else {
                                     PartyModeButton.selected = NO;
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
                                 float percentage = [(NSNumber*)methodResult[@"percentage"] floatValue];
                                 NSString *actualTime = [NSString stringWithFormat:@"%@%02i:%02i", (hoursGlobal == 0) ? @"" : [NSString stringWithFormat:@"%02i:", hours], minutes, seconds];
                                 if (updateProgressBar) {
                                     currentTime.text = actualTime;
                                     ProgressSlider.hidden = NO;
                                     currentTime.hidden = NO;
                                     duration.hidden = NO;
                                 }
                                 if (currentPlayerID == PLAYERID_PICTURES) {
                                     ProgressSlider.hidden = YES;
                                     currentTime.hidden = YES;
                                     duration.hidden = YES;
                                 }
                                 [self updatePlaylistProgressbar:percentage actual:actualTime];
                                 long playlistPosition = [methodResult[@"position"] longValue];
                                 if (playlistPosition > -1) {
                                     playlistPosition += 1;
                                 }
                                 if (musicPartyMode && percentage < storePercentage) { // BLEAH!!!
                                     [self checkPartyMode];
                                 }
                                 storePercentage = percentage;
                                 if (playlistPosition != lastSelected && playlistPosition > 0) {
                                     if (playlistData.count >= playlistPosition && currentPlayerID == playerID) {
                                         [self hidePlaylistProgressbarWithDeselect:NO];
                                         NSIndexPath *newSelection = [NSIndexPath indexPathForRow:playlistPosition - 1 inSection:0];
                                         UITableViewScrollPosition position = UITableViewScrollPositionMiddle;
                                         if (musicPartyMode) {
                                             position = UITableViewScrollPositionNone;
                                         }
                                         [playlistTableView selectRowAtIndexPath:newSelection animated:YES scrollPosition:position];
                                         UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:newSelection];
                                         UIView *timePlaying = (UIView*)[cell viewWithTag:5];
                                         [self fadeView:timePlaying hidden:NO];
                                         storeSelection = newSelection;
                                         lastSelected = playlistPosition;
                                     }
                                 }
                             }
                             else {
                                 PartyModeButton.selected = NO;
                             }
                         }
                         else {
                             PartyModeButton.selected = NO;
                         }
                     }
                     else {
                         PartyModeButton.selected = NO;
                     }
                 }];
            }
            else {
                [self nothingIsPlaying];
                if (playerID == PLAYERID_UNKNOWN && selectedPlayerID == PLAYERID_UNKNOWN) {
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
     withParameters:@{@"labels": @[@"MusicPlayer.Codec",
                                   @"MusicPlayer.SampleRate",
                                   @"MusicPlayer.BitRate",
                                   @"MusicPlayer.BitsPerSample",
                                   @"MusicPlayer.Channels",
                                   @"VideoPlayer.VideoResolution",
                                   @"VideoPlayer.VideoAspect",
                                   @"VideoPlayer.AudioCodec",
                                   @"VideoPlayer.VideoCodec"]}
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error == nil && methodError == nil && [methodResult isKindOfClass: [NSDictionary class]]) {
             hiresImage.hidden = YES;
             if (playerID == PLAYERID_MUSIC && currentPlayerID == playerID) {
                 NSString *codec = [Utilities getStringFromItem:methodResult[@"MusicPlayer.Codec"]];
                 [self setSongDetails:songCodec image:songCodecImage item:[self processSongCodecName:codec]];
                 [self setSongDetails:songBitRate image:songBitRateImage item:methodResult[@"MusicPlayer.Channels"]];
                 
                 BOOL isLossless = [self isLosslessFormat:codec];
                 
                 NSString *bps = [Utilities getStringFromItem:methodResult[@"MusicPlayer.BitsPerSample"]];
                 bps = bps.length ? [NSString stringWithFormat:@"%@ Bit", bps] : @"";
                 
                 NSString *kHz = [Utilities getStringFromItem:methodResult[@"MusicPlayer.SampleRate"]];
                 kHz = kHz.length ? [NSString stringWithFormat:@"%@ kHz", kHz] : @"";
                 
                 // Check for High Resolution Audio
                 // Must be using a lossless codec and have either at least 24 Bit or at least 88.2 kHz.
                 // But never have less than 16 Bit or less than 44.1 kHz.
                 if (isLossless && ([bps integerValue] >= 24 || [kHz integerValue] >= 88) && !([bps integerValue] < 16 || [kHz integerValue] < 44)) {
                     hiresImage.hidden = NO;
                 }
                
                 NSString *newLine = ![bps isEqualToString:@""] && ![kHz isEqualToString:@""] ? @"\n" : @"";
                 NSString *samplerate = [NSString stringWithFormat:@"%@%@%@", bps, newLine, kHz];
                 songNumChannels.text = samplerate;
                 songNumChannels.hidden = NO;
                 songNumChanImage.image = nil;
                 
                 NSString *bitrate = [Utilities getStringFromItem:methodResult[@"MusicPlayer.BitRate"]];
                 bitrate = bitrate.length ? [NSString stringWithFormat:@"%@\nkbit/s", bitrate] : @"";
                 songSampleRate.text = bitrate;
                 songSampleRate.hidden = NO;
                 songSampleRateImage.image = nil;
             }
             else if (playerID == PLAYERID_VIDEO && currentPlayerID == playerID) {
                 [self setSongDetails:songCodec image:songCodecImage item:methodResult[@"VideoPlayer.VideoResolution"]];
                 [self setSongDetails:songBitRate image:songBitRateImage item:methodResult[@"VideoPlayer.VideoAspect"]];
                 [self setSongDetails:songSampleRate image:songSampleRateImage item:methodResult[@"VideoPlayer.VideoCodec"]];
                 [self setSongDetails:songNumChannels image:songNumChanImage item:methodResult[@"VideoPlayer.AudioCodec"]];
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
    if (!AppDelegate.instance.serverOnLine) {
        playerID = PLAYERID_UNKNOWN;
        selectedPlayerID = PLAYERID_UNKNOWN;
        storedItemID = 0;
        [Utilities AnimView:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:slideFrom];
        [playlistData performSelectorOnMainThread:@selector(removeAllObjects) withObject:nil waitUntilDone:YES];
        [self nothingIsPlaying];
        return;
    }
    if (AppDelegate.instance.serverVersion == 11) {
        [[Utilities getJsonRPC]
         callMethod:@"XBMC.GetInfoBooleans" 
         withParameters:@{@"booleans": @[@"Window.IsActive(virtualkeyboard)", @"Window.IsActive(selectdialog)"]}
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
             
             if (error == nil && methodError == nil && [methodResult isKindOfClass: [NSDictionary class]]) {
                 if ((methodResult[@"Window.IsActive(virtualkeyboard)"] != [NSNull null]) && (methodResult[@"Window.IsActive(selectdialog)"] != [NSNull null])) {
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
    [[Utilities getJsonRPC] callMethod:@"Playlist.Clear" withParameters:@{@"playlistid": @(playlistID)} onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error == nil && methodError == nil) {
            [self createPlaylist:NO animTableView:NO];
        }
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
                }];
            }
        }
    }];
}

- (void)createPlaylist:(BOOL)forcePlaylistID animTableView:(BOOL)animTable { 
    if (!AppDelegate.instance.serverOnLine) {
        playerID = PLAYERID_UNKNOWN;
        selectedPlayerID = PLAYERID_UNKNOWN;
        storedItemID = 0;
        [Utilities AnimView:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:slideFrom];
        [playlistData performSelectorOnMainThread:@selector(removeAllObjects) withObject:nil waitUntilDone:YES];
        [self nothingIsPlaying];
        return;
    }
    if (!musicPartyMode && animTable) {
        [Utilities AnimView:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:slideFrom];
    }
    [activityIndicatorView startAnimating];
    GlobalData *obj = AppDelegate.instance.obj;
    int playlistID = playerID;
    if (forcePlaylistID) {
        playlistID = PLAYERID_MUSIC;
    }
    
    if (selectedPlayerID != PLAYERID_UNKNOWN) {
        playlistID = selectedPlayerID;
        playerID = selectedPlayerID;
    }
    
    if (playlistID == PLAYERID_MUSIC) {
        playerID = PLAYERID_MUSIC;
        playlistSegmentedControl.selectedSegmentIndex = PLAYERID_MUSIC;
        [Utilities AnimView:PartyModeButton AnimDuration:0.3 Alpha:1.0 XPos:PARTYBUTTON_PADDING_LEFT];
    }
    else if (playlistID == PLAYERID_VIDEO) {
        playerID = PLAYERID_VIDEO;
        playlistSegmentedControl.selectedSegmentIndex = PLAYERID_VIDEO;
        [Utilities AnimView:PartyModeButton AnimDuration:0.3 Alpha:0.0 XPos:-PartyModeButton.frame.size.width];
    }
    else if (playlistID == PLAYERID_PICTURES) {
        playerID = PLAYERID_PICTURES;
        playlistSegmentedControl.selectedSegmentIndex = PLAYERID_PICTURES;
        [Utilities AnimView:PartyModeButton AnimDuration:0.3 Alpha:0.0 XPos:-PartyModeButton.frame.size.width];
    }
    [Utilities alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
    [[Utilities getJsonRPC] callMethod:@"Playlist.GetItems"
                        withParameters:@{@"properties": @[@"thumbnail",
                                                          @"duration",
                                                          @"artist",
                                                          @"album",
                                                          @"runtime",
                                                          @"showtitle",
                                                          @"season",
                                                          @"episode",
                                                          @"artistid",
                                                          @"albumid",
                                                          @"genre",
                                                          @"tvshowid",
                                                          @"channel",
                                                          @"file",
                                                          @"title",
                                                          @"art"],
                                         @"playlistid": @(playlistID)}
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               if (error == nil && methodError == nil) {
                   [playlistData performSelectorOnMainThread:@selector(removeAllObjects) withObject:nil waitUntilDone:YES];
                   [playlistTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
                   if ([NSJSONSerialization isValidJSONObject:methodResult]) {
                       NSArray *playlistItems = methodResult[@"items"];
                       if (playlistItems.count == 0) {
                           [Utilities alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
                       }
                       else {
                           [Utilities alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
                       }
                       NSString *serverURL;
                       serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                       int runtimeInMinute = 1;
                       if (AppDelegate.instance.serverVersion > 11) {
                           serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
                           runtimeInMinute = 60;
                       }
                       for (NSDictionary *item in playlistItems) {
                           NSString *idItem = [NSString stringWithFormat:@"%@", item[@"id"]];
                           NSString *label = [NSString stringWithFormat:@"%@", item[@"label"]];
                           NSString *title = [NSString stringWithFormat:@"%@", item[@"title"]];
                           NSString *artist = [Utilities getStringFromItem:item[@"artist"]];
                           NSString *album = [Utilities getStringFromItem:item[@"album"]];
                           NSString *runtime = [Utilities getTimeFromItem:item[@"runtime"] sec2min:runtimeInMinute];
                           NSString *showtitle = item[@"showtitle"];
                           NSString *season = item[@"season"];
                           NSString *episode = item[@"episode"];
                           NSString *type = item[@"type"];
                           NSString *artistid = [NSString stringWithFormat:@"%@", item[@"artistid"]];
                           NSString *albumid = [NSString stringWithFormat:@"%@", item[@"albumid"]];
                           NSString *movieid = [NSString stringWithFormat:@"%@", item[@"id"]];
                           NSString *channel = [NSString stringWithFormat:@"%@", item[@"channel"]];
                           NSString *genre = [Utilities getStringFromItem:item[@"genre"]];
                           NSString *durationTime = @"";
                           if ([item[@"duration"] isKindOfClass:[NSNumber class]]) {
                               durationTime = [Utilities convertTimeFromSeconds:item[@"duration"]];
                           }
                           NSString *thumbnailPath = [self getNowPlayingThumbnailPath:item];
                           NSString *stringURL = [Utilities formatStringURL:thumbnailPath serverURL:serverURL];
                           NSNumber *tvshowid = @([[NSString stringWithFormat:@"%@", item[@"tvshowid"]] intValue]);
                           NSString *file = [NSString stringWithFormat:@"%@", item[@"file"]];
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
                                                    movieid, @"musicvideoid",
                                                    movieid, @"recordingid",
                                                    channel, @"channel",
                                                    stringURL, @"thumbnail",
                                                    runtime, @"runtime",
                                                    showtitle, @"showtitle",
                                                    season, @"season",
                                                    episode, @"episode",
                                                    tvshowid, @"tvshowid",
                                                    nil]];
                       }
                       [self showPlaylistTable];
                       if (musicPartyMode && playlistID == PLAYERID_MUSIC) {
                           [playlistTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
                       }
                   }
               }
               else {
                   [self showPlaylistTable];
               }
           }];
}

- (void)updatePlaylistProgressbar:(float)percentage actual:(NSString*)actualTime {
    NSIndexPath* selection = [playlistTableView indexPathForSelectedRow];
    if (!selection) {
        return;
    }
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
    UILabel *playlistActualTime = (UILabel*)[cell viewWithTag:6];
    playlistActualTime.text = actualTime;
    UIImageView *playlistActualBar = (UIImageView*)[cell viewWithTag:7];
    CGFloat newx = MAX(MAX_CELLBAR_WIDTH * percentage / 100.0, 1.0);
    [self resizeCellBar:newx image:playlistActualBar];
    UIView *timePlaying = (UIView*)[cell viewWithTag:5];
    [self fadeView:timePlaying hidden:NO];
}

- (void)hidePlaylistProgressbarWithDeselect:(BOOL)deselect {
    NSIndexPath* selection = [playlistTableView indexPathForSelectedRow];
    if (!selection) {
        return;
    }
    if (deselect) {
        [playlistTableView deselectRowAtIndexPath:selection animated:YES];
    }
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
    UIView *timePlaying = (UIView*)[cell viewWithTag:5];
    [self fadeView:timePlaying hidden:YES];
    UIImageView *coverView = (UIImageView*)[cell viewWithTag:4];
    coverView.alpha = 1.0;
}

- (void)showPlaylistTable {
    numResults = (int)playlistData.count;
    if (numResults == 0) {
        [Utilities alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
    }
    else {
        [Utilities AnimView:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
    [playlistTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
    [activityIndicatorView stopAnimating];
    lastSelected = SELECTED_NONE;
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
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:menuItem.mainMethod[choosedTab]];
    NSDictionary *parameters = [Utilities indexKeyedDictionaryFromArray:menuItem.mainParameters[choosedTab]];
    
    NSMutableDictionary *mutableParameters = [parameters[@"extra_info_parameters"] mutableCopy];
    NSMutableArray *mutableProperties = [parameters[@"extra_info_parameters"][@"properties"] mutableCopy];
    
    if ([parameters[@"FrodoExtraArt"] boolValue] && AppDelegate.instance.serverVersion > 11) {
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
    if (IS_IPHONE) {
        ShowInfoViewController *showInfoViewController = [[ShowInfoViewController alloc] initWithNibName:@"ShowInfoViewController" bundle:nil];
        showInfoViewController.detailItem = item;
        [self.navigationController pushViewController:showInfoViewController animated:YES];
    }
    else {
        ShowInfoViewController *iPadShowViewController = [[ShowInfoViewController alloc] initWithNibName:@"ShowInfoViewController" withItem:item withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
        [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:iPadShowViewController invokeByController:self isStackStartView:YES];
        [AppDelegate.instance.windowController.stackScrollViewController enablePanGestureRecognizer];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object: nil];
    }
}

- (void)retrieveExtraInfoData:(NSString*)methodToCall parameters:(NSDictionary*)parameters index:(NSIndexPath*)indexPath item:(NSDictionary*)item menuItem:(mainMenu*)menuItem {
    NSString *itemid = @"";
    NSDictionary *mainFields = menuItem.mainFields[choosedTab];
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
    if (AppDelegate.instance.serverVersion > 11 && [methodToCall isEqualToString:@"AudioLibrary.GetArtistDetails"]) {// WORKAROUND due the lack of the artistid with Playlist.GetItems
        methodToCall = @"AudioLibrary.GetArtists";
        object = @{@"songid": @([item[@"idItem"] intValue])};
        itemid = @"filter";
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
                                     object, itemid,
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
                     [self somethingGoesWrong:LOCALIZED_STR(@"Details not found")];
                     return;
                 }
                 if (AppDelegate.instance.serverVersion > 11 && [methodToCall isEqualToString:@"AudioLibrary.GetArtists"]) {// WORKAROUND due the lack of the artistid with Playlist.GetItems
                     itemid_extra_info = @"artists";
                 }
                 NSDictionary *itemExtraDict = methodResult[itemid_extra_info];
                 if (((NSNull*)itemExtraDict == [NSNull null]) || itemExtraDict == nil) {
                     [self somethingGoesWrong:LOCALIZED_STR(@"Details not found")];
                     return;
                 }
                 if (AppDelegate.instance.serverVersion > 11 && [methodToCall isEqualToString:@"AudioLibrary.GetArtists"]) {// WORKAROUND due the lack of the artistid with Playlist.GetItems
                     if ([methodResult[itemid_extra_info] count]) {
                         itemExtraDict = methodResult[itemid_extra_info][0];
                     }
                     else {
                         [self somethingGoesWrong:LOCALIZED_STR(@"Details not found")];
                         return;
                     }
                 }
                 NSString *serverURL = @"";
                 serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                 int runtimeInMinute = 1;
                 if (AppDelegate.instance.serverVersion > 11) {
                     serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
                     runtimeInMinute = 60;
                 }

                 NSString *label = [NSString stringWithFormat:@"%@", itemExtraDict[mainFields[@"row1"]]];
                 NSString *genre = [Utilities getStringFromItem:itemExtraDict[mainFields[@"row2"]]];
                 NSString *year = [Utilities getYearFromItem:itemExtraDict[mainFields[@"row3"]]];
                 NSString *runtime = [Utilities getTimeFromItem:itemExtraDict[mainFields[@"row4"]] sec2min:runtimeInMinute];
                 NSString *rating = [Utilities getRatingFromItem:itemExtraDict[mainFields[@"row5"]]];
                 NSString *thumbnailPath = [self getNowPlayingThumbnailPath:itemExtraDict];
                 NSDictionary *art = itemExtraDict[@"art"];
                 NSString *clearlogo = [Utilities getClearArtFromDictionary:art type:@"clearlogo"];
                 NSString *clearart = [Utilities getClearArtFromDictionary:art type:@"clearart"];
                 NSString *stringURL = [Utilities formatStringURL:thumbnailPath serverURL:serverURL];
                 NSString *fanartURL = [Utilities formatStringURL:itemExtraDict[@"fanart"] serverURL:serverURL];
                 if ([stringURL isEqualToString:@""]) {
                     stringURL = [Utilities getItemIconFromDictionary:itemExtraDict mainFields:mainFields];
                 }
                 BOOL disableNowPlaying = YES;
                 NSObject *row11 = itemExtraDict[mainFields[@"row11"]];
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
                  itemExtraDict[mainFields[@"row6"]], mainFields[@"row6"],
                  itemExtraDict[mainFields[@"row8"]], mainFields[@"row8"],
                  year, @"year",
                  rating, @"rating",
                  mainFields[@"playlistid"], @"playlistid",
                  mainFields[@"row8"], @"family",
                  @([[NSString stringWithFormat:@"%@", itemExtraDict[mainFields[@"row9"]]] intValue]), mainFields[@"row9"],
                  itemExtraDict[mainFields[@"row10"]], mainFields[@"row10"],
                  row11, mainFields[@"row11"],
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
        animationOptionTransition = UIViewAnimationOptionTransitionFlipFromLeft;
        startFlipDemo = NO;
    }
    [UIView transitionWithView:button
                      duration:0.2
                       options:UIViewAnimationOptionCurveEaseIn | animationOptionTransition
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
                                 buttonImage = [self resizeToolbarThumb:[UIImage imageNamed:@"st_kodi_window"]];
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
                     } 
                     completion:^(BOOL finished) {
                        [UIView transitionWithView:button
                                          duration:0.5
                                           options:UIViewAnimationOptionCurveEaseOut | animationOptionTransition
                                        animations:^{
                                            button.hidden = NO;
                                        }
                                        completion:^(BOOL finished) {}
                        ];
                     }
    ];
}

- (void)animViews {
    UIColor *effectColor;
    UIColor *barColor;
    __block CGRect playlistToolBarOriginY = playlistActionView.frame;
    NSTimeInterval iOS7effectDuration = 1.0;
    if (!nowPlayingView.hidden) {
        iOS7effectDuration = 0.0;
        transitionView = nowPlayingView;
        transitionedView = playlistView;
        playlistHidden = NO;
        nowPlayingHidden = YES;
        self.navigationItem.title = LOCALIZED_STR(@"Playlist");
        self.navigationItem.titleView.hidden = YES;
        animationOptionTransition = UIViewAnimationOptionTransitionFlipFromRight;
        effectColor = UIColor.clearColor;
        barColor = TINT_COLOR;
        playlistToolBarOriginY.origin.y = playlistTableView.frame.size.height - playlistTableView.scrollIndicatorInsets.bottom;
        [self IOS7effect:effectColor barTintColor:barColor effectDuration:0.2];
    }
    else {
        transitionView = playlistView;
        transitionedView = nowPlayingView;
        playlistHidden = YES;
        nowPlayingHidden = NO;
        self.navigationItem.title = LOCALIZED_STR(@"Now Playing");
        self.navigationItem.titleView.hidden = YES;
        animationOptionTransition = UIViewAnimationOptionTransitionFlipFromLeft;
        if (foundEffectColor == nil) {
            effectColor = UIColor.clearColor;
            barColor = TINT_COLOR;
        }
        else {
            effectColor = foundEffectColor;
            barColor = foundEffectColor;
        }
        playlistToolBarOriginY.origin.y = playlistTableView.frame.size.height;
    }
    [self IOS7colorProgressSlider:effectColor];
    
    [UIView transitionWithView:transitionView
                      duration:0.2
                       options:UIViewAnimationOptionCurveEaseIn | animationOptionTransition
                    animations:^{
                          transitionView.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                        [UIView transitionWithView:transitionedView
                                          duration:0.5
                                           options:UIViewAnimationOptionCurveEaseOut | animationOptionTransition
                                        animations:^{
                                              playlistView.hidden = playlistHidden;
                                              nowPlayingView.hidden = nowPlayingHidden;
                                              self.navigationItem.titleView.hidden = NO;
                                              playlistActionView.frame = playlistToolBarOriginY;
                                              playlistActionView.alpha = (int)nowPlayingHidden;
                                              transitionedView.alpha = 1.0;
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
        case TAG_ID_PREVIOUS:
            if (AppDelegate.instance.serverVersion > 11) {
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
            
        case TAG_ID_PLAYPAUSE:
            action = @"Player.PlayPause";
            params = nil;
            [self playbackAction:action params:nil checkPartyMode:NO];
            break;
            
        case TAG_ID_STOP:
            action = @"Player.Stop";
            params = nil;
            [self playbackAction:action params:nil checkPartyMode:NO];
            storeSelection = nil;
            break;
            
        case TAG_ID_NEXT:
            if (AppDelegate.instance.serverVersion > 11) {
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
            
        case TAG_ID_TOGGLE:
            [self animViews];
            break;
            
        case TAG_SEEK_BACKWARD:
            action = @"Player.Seek";
            params = [Utilities buildPlayerSeekStepParams:@"smallbackward"];
            [self playbackAction:action params:params checkPartyMode:NO];
            break;
            
        case TAG_SEEK_FORWARD:
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
    if ((nothingIsPlaying && songDetailsView.alpha == 0.0) || playerID == PLAYERID_PICTURES) {
        return;
    }
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        if (songDetailsView.alpha == 0) {
            songDetailsView.alpha = 1.0;
            [self loadCodecView];
            itemDescription.scrollsToTop = YES;
        }
        else {
            songDetailsView.alpha = 0.0;
            itemDescription.scrollsToTop = NO;
        }
                     }
                     completion:^(BOOL finished) {}];
}

- (void)toggleHighlight:(UIButton*)button {
    button.highlighted = NO;
}

- (IBAction)changeShuffle:(id)sender {
    shuffleButton.highlighted = YES;
    [self performSelector:@selector(toggleHighlight:) withObject:shuffleButton afterDelay:.1];
    lastSelected = SELECTED_NONE;
    storeSelection = nil;
    if (AppDelegate.instance.serverVersion > 11) {
        [self SimpleAction:@"Player.SetShuffle" params:@{@"playerid": @(currentPlayerID), @"shuffle": @"toggle"} reloadPlaylist:YES startProgressBar:NO];
        if (shuffled) {
            [shuffleButton setBackgroundImage:[UIImage imageNamed:@"button_shuffle"] forState:UIControlStateNormal];
        }
        else {
            [shuffleButton setBackgroundImage:[UIImage imageNamed:@"button_shuffle_on"] forState:UIControlStateNormal];
        }
    }
    else {
        if (shuffled) {
            [self SimpleAction:@"Player.UnShuffle" params:@{@"playerid": @(currentPlayerID)} reloadPlaylist:YES startProgressBar:NO];
            [shuffleButton setBackgroundImage:[UIImage imageNamed:@"button_shuffle"] forState:UIControlStateNormal];
        }
        else {
            [self SimpleAction:@"Player.Shuffle" params:@{@"playerid": @(currentPlayerID)} reloadPlaylist:YES startProgressBar:NO];
            [shuffleButton setBackgroundImage:[UIImage imageNamed:@"button_shuffle_on"] forState:UIControlStateNormal];
        }
    }
}

- (IBAction)changeRepeat:(id)sender {
    repeatButton.highlighted = YES;
    [self performSelector:@selector(toggleHighlight:) withObject:repeatButton afterDelay:.1];
    if (AppDelegate.instance.serverVersion > 11) {
        [self SimpleAction:@"Player.SetRepeat" params:@{@"playerid": @(currentPlayerID), @"repeat": @"cycle"} reloadPlaylist:NO startProgressBar:NO];
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
            [self SimpleAction:@"Player.Repeat" params:@{@"playerid": @(currentPlayerID), @"state": @"all"} reloadPlaylist:NO startProgressBar:NO];
            [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat_all"] forState:UIControlStateNormal];
        }
        else if ([repeatStatus isEqualToString:@"all"]) {
            [self SimpleAction:@"Player.Repeat" params:@{@"playerid": @(currentPlayerID), @"state": @"one"} reloadPlaylist:NO startProgressBar:NO];
            [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat_one"] forState:UIControlStateNormal];
            
        }
        else if ([repeatStatus isEqualToString:@"one"]) {
            [self SimpleAction:@"Player.Repeat" params:@{@"playerid": @(currentPlayerID), @"state": @"off"} reloadPlaylist:NO startProgressBar:NO];
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
    if (AppDelegate.instance.serverVersion > 11) {
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
        [itemLogoImage setImageWithURL:[NSURL URLWithString:stringURL]
                      placeholderImage:itemLogoImage.image];
    }
}

- (IBAction)buttonToggleItemInfo:(id)sender {
    [self toggleSongDetails];
}

- (void)showClearPlaylistAlert {
    if (!playlistView.hidden && self.view.superview != nil) {
        NSString *message;
        switch (playerID) {
            case PLAYERID_MUSIC:
                message = LOCALIZED_STR(@"Are you sure you want to clear the music playlist?");
                break;
            case PLAYERID_VIDEO:
                message = LOCALIZED_STR(@"Are you sure you want to clear the video playlist?");
                break;
            case PLAYERID_PICTURES:
                message = LOCALIZED_STR(@"Are you sure you want to clear the picture playlist?");
                break;
            default:
                message = LOCALIZED_STR(@"Are you sure you want to clear the playlist?");
                break;
        }
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
            NSDictionary *item = (playlistData.count > indexPath.row) ? playlistData[indexPath.row] : nil;
            selected = indexPath;
            CGPoint selectedPoint = [gestureRecognizer locationInView:self.view];
            if ([item[@"albumid"] intValue] > 0) {
                [sheetActions addObjectsFromArray:@[LOCALIZED_STR(@"Album Details"), LOCALIZED_STR(@"Album Tracks")]];
            }
            if ([item[@"artistid"] intValue] > 0 || ([item[@"type"] isEqualToString:@"song"] && AppDelegate.instance.serverVersion > 11)) {
                [sheetActions addObjectsFromArray:@[LOCALIZED_STR(@"Artist Details"), LOCALIZED_STR(@"Artist Albums")]];
            }
            if ([item[@"movieid"] intValue] > 0) {
                if ([item[@"type"] isEqualToString:@"movie"]) {
                    [sheetActions addObjectsFromArray:@[LOCALIZED_STR(@"Movie Details")]];
                }
                else if ([item[@"type"] isEqualToString:@"episode"]) {
                    [sheetActions addObjectsFromArray:@[LOCALIZED_STR(@"TV Show Details"), LOCALIZED_STR(@"Episode Details")]];
                }
                else if ([item[@"type"] isEqualToString:@"musicvideo"]) {
                    [sheetActions addObjectsFromArray:@[LOCALIZED_STR(@"Music Video Details")]];
                }
                else if ([item[@"type"] isEqualToString:@"recording"]) {
                    [sheetActions addObjectsFromArray:@[LOCALIZED_STR(@"Recording Details")]];
                }
            }
            NSInteger numActions = sheetActions.count;
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
            case TAG_SEEK_BACKWARD:// BACKWARD BUTTON - DECREASE PLAYBACK SPEED
                [self playbackAction:@"Player.SetSpeed" params:@[@"decrement", @"speed"] checkPartyMode:NO];
                break;
                
            case TAG_SEEK_FORWARD:// FORWARD BUTTON - INCREASE PLAYBACK SPEED
                [self playbackAction:@"Player.SetSpeed" params:@[@"increment", @"speed"] checkPartyMode:NO];
                break;
                
            case TAG_ID_EDIT:// EDIT TABLE
                [self showClearPlaylistAlert];
                break;

            default:
                break;
        }
    }
}

- (IBAction)stopUpdateProgressBar:(id)sender {
    updateProgressBar = NO;
    [Utilities alphaView:scrabbingView AnimDuration:0.3 Alpha:1.0];
}

- (IBAction)startUpdateProgressBar:(id)sender {
    [self SimpleAction:@"Player.Seek" params:[Utilities buildPlayerSeekPercentageParams:playerID percentage:ProgressSlider.value] reloadPlaylist:NO startProgressBar:YES];
    [Utilities alphaView:scrabbingView AnimDuration:0.3 Alpha:0.0];
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
    if (sheetActions.count) {
        UIAlertController *actionView = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction* action_cancel = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];
        
        for (NSString *actionName in sheetActions) {
            NSString *actiontitle = actionName;
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
            popPresenter.sourceRect = CGRectMake(origin.x, origin.y, 1, 1);
        }
        [self presentViewController:actionView animated:YES completion:nil];
    }
}

- (void)actionSheetHandler:(NSString*)actiontitle {
    NSDictionary *item = nil;
    NSInteger numPlaylistEntries = playlistData.count;
    if (selected.row < numPlaylistEntries) {
        item = playlistData[selected.row];
    }
    else {
        return;
    }
    choosedTab = -1;
    mainMenu *menuItem = nil;
    notificationName = @"";
    if ([item[@"type"] isEqualToString:@"song"]) {
        notificationName = @"MainMenuDeselectSection";
        menuItem = [AppDelegate.instance.playlistArtistAlbums copy];
        if ([actiontitle isEqualToString:LOCALIZED_STR(@"Album Details")]) {
            choosedTab = 0;
            menuItem.subItem.mainLabel = item[@"album"];
            menuItem.subItem.mainMethod = nil;
        }
        else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Album Tracks")]) {
            choosedTab = 0;
            menuItem.subItem.mainLabel = item[@"album"];
        }
        else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Artist Details")]) {
            choosedTab = 1;
            menuItem.subItem.mainLabel = item[@"artist"];
            menuItem.subItem.mainMethod = nil;
        }
        else if ([actiontitle isEqualToString:LOCALIZED_STR(@"Artist Albums")]) {
            choosedTab = 1;
            menuItem.subItem.mainLabel = item[@"artist"];
        }
        else {
            return;
        }
    }
    else if ([item[@"type"] isEqualToString:@"movie"]) {
        menuItem = AppDelegate.instance.playlistMovies;
        choosedTab = 0;
        menuItem.subItem.mainLabel = item[@"label"];
        notificationName = @"MainMenuDeselectSection";
    }
    else if ([item[@"type"] isEqualToString:@"episode"]) {
        notificationName = @"MainMenuDeselectSection";
        if ([actiontitle isEqualToString:LOCALIZED_STR(@"Episode Details")]) {
            menuItem = AppDelegate.instance.playlistTvShows.subItem;
            choosedTab = 0;
            menuItem.subItem.mainLabel = item[@"label"];
        }
        else if ([actiontitle isEqualToString:LOCALIZED_STR(@"TV Show Details")]) {
            menuItem = [AppDelegate.instance.playlistTvShows copy];
            menuItem.subItem.mainMethod = nil;
            choosedTab = 0;
            menuItem.subItem.mainLabel = item[@"label"];
        }
    }
    else if ([item[@"type"] isEqualToString:@"musicvideo"]) {
        menuItem = AppDelegate.instance.playlistMusicVideos;
        choosedTab = 0;
        menuItem.subItem.mainLabel = item[@"label"];
        notificationName = @"MainMenuDeselectSection";
    }
    else if ([item[@"type"] isEqualToString:@"recording"]) {
        menuItem = AppDelegate.instance.playlistPVR;
        choosedTab = 2;
        menuItem.subItem.mainLabel = item[@"label"];
        notificationName = @"MainMenuDeselectSection";
    }
    else {
        return;
    }
    NSDictionary *methods = [Utilities indexKeyedDictionaryFromArray:[menuItem.subItem mainMethod][choosedTab]];
    if (methods[@"method"] != nil) { // THERE IS A CHILD
        NSDictionary *mainFields = menuItem.mainFields[choosedTab];
        NSMutableDictionary *parameters = [Utilities indexKeyedMutableDictionaryFromArray:[menuItem.subItem mainParameters][choosedTab]];
        NSString *key = @"null";
        if (item[mainFields[@"row15"]] != nil) {
            key = mainFields[@"row15"];
        }
        id obj = @([item[mainFields[@"row6"]] intValue]);
        id objKey = mainFields[@"row6"];
        if (AppDelegate.instance.serverVersion > 11 && ![parameters[@"disableFilterParameter"] boolValue]) {
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
        [[menuItem.subItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
        menuItem.subItem.chooseTab = choosedTab;
        fromItself = YES;
        if (IS_IPHONE) {
            DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
            detailViewController.detailItem = menuItem.subItem;
            [self.navigationController pushViewController:detailViewController animated:YES];
        }
        else {
            DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:menuItem.subItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
            [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:YES];
            [AppDelegate.instance.windowController.stackScrollViewController enablePanGestureRecognizer];
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object: nil];
        }
    }
    else {
        [self showInfo:item menuItem:menuItem indexPath:selected];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return playlistData.count;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    cell.backgroundColor = [Utilities getSystemGray6];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"playlistCell"];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"playlistCellView" owner:self options:nil];
        cell = nib[0];
        ((UILabel*)[cell viewWithTag:1]).highlightedTextColor = [Utilities get1stLabelColor];
        ((UILabel*)[cell viewWithTag:2]).highlightedTextColor = [Utilities get2ndLabelColor];
        ((UILabel*)[cell viewWithTag:3]).highlightedTextColor = [Utilities get2ndLabelColor];
        
        ((UILabel*)[cell viewWithTag:1]).textColor = [Utilities get1stLabelColor];
        ((UILabel*)[cell viewWithTag:2]).textColor = [Utilities get2ndLabelColor];
        ((UILabel*)[cell viewWithTag:3]).textColor = [Utilities get2ndLabelColor];
    }
    NSDictionary *item = (playlistData.count > indexPath.row) ? playlistData[indexPath.row] : nil;
    UIImageView *thumb = (UIImageView*)[cell viewWithTag:4];
    
    UILabel *mainLabel = (UILabel*)[cell viewWithTag:1];
    UILabel *subLabel = (UILabel*)[cell viewWithTag:2];
    UILabel *cornerLabel = (UILabel*)[cell viewWithTag:3];

    mainLabel.text = ![item[@"title"] isEqualToString:@""] ? item[@"title"] : item[@"label"];
    ((UILabel*)[cell viewWithTag:2]).text = @"";
    if ([item[@"type"] isEqualToString:@"episode"]) {
        if ([item[@"season"] intValue] != 0 || [item[@"episode"] intValue] != 0) {
            mainLabel.text = [NSString stringWithFormat:@"%@x%02i. %@", item[@"season"], [item[@"episode"] intValue], item[@"title"]];
        }
        subLabel.text = [NSString stringWithFormat:@"%@", item[@"showtitle"]];
    }
    else if ([item[@"type"] isEqualToString:@"song"] ||
             [item[@"type"] isEqualToString:@"musicvideo"]) {
        NSString *artist = [item[@"artist"] length] == 0 ? @"" : [NSString stringWithFormat:@" - %@", item[@"artist"]];
        subLabel.text = [NSString stringWithFormat:@"%@%@", item[@"album"], artist];
    }
    else if ([item[@"type"] isEqualToString:@"movie"]) {
        subLabel.text = [NSString stringWithFormat:@"%@", item[@"genre"]];
    }
    else if ([item[@"type"] isEqualToString:@"recording"]) {
        subLabel.text = [NSString stringWithFormat:@"%@", item[@"channel"]];
    }
    UIImage *defaultThumb;
    switch (playerID) {
        case PLAYERID_MUSIC:
            cornerLabel.text = item[@"duration"];
            defaultThumb = [UIImage imageNamed:@"icon_song"];
            break;
        case PLAYERID_VIDEO:
            cornerLabel.text = item[@"runtime"];
            defaultThumb = [UIImage imageNamed:@"icon_video"];
            break;
        case PLAYERID_PICTURES:
            cornerLabel.text = @"";
            defaultThumb = [UIImage imageNamed:@"icon_picture"];
            break;
        default:
            cornerLabel.text = @"";
            defaultThumb = [UIImage imageNamed:@"nocover_filemode"];
            break;
    }
    NSString *stringURL = item[@"thumbnail"];
    [thumb setImageWithURL:[NSURL URLWithString:stringURL]
          placeholderImage:defaultThumb];
    thumb = [Utilities applyRoundedEdgesView:thumb drawBorder:YES];
    UIView *timePlaying = (UIView*)[cell viewWithTag:5];
    [self fadeView:timePlaying hidden:YES];
    
    return cell;
}
- (void)tableView:(UITableView*)tableView didDeselectRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
    UIImageView *coverView = (UIImageView*)[cell viewWithTag:4];
    coverView.alpha = 1.0;
    UIView *timePlaying = (UIView*)[cell viewWithTag:5];
    storeSelection = nil;
    [self fadeView:timePlaying hidden:YES];
}

- (void)checkPartyMode {
    if (musicPartyMode) {
        lastSelected = SELECTED_NONE;
        storeSelection = 0;
        [self createPlaylist:NO animTableView:YES];
    }
 }

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
    UIActivityIndicatorView *queuing = (UIActivityIndicatorView*)[cell viewWithTag:8];
    storeSelection = nil;
    [queuing startAnimating];
    [[Utilities getJsonRPC]
     callMethod:@"Player.Open" 
     withParameters:@{@"item": @{@"position": @(indexPath.row), @"playlistid": @(playerID)}}
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error == nil && methodError == nil) {
             storedItemID = SELECTED_NONE;
             UIActivityIndicatorView *queuing = (UIActivityIndicatorView*)[cell viewWithTag:8];
             [queuing stopAnimating];
             UIView *timePlaying = (UIView*)[cell viewWithTag:5];
             [self fadeView:timePlaying hidden:NO];
         }
         else {
             UIActivityIndicatorView *queuing = (UIActivityIndicatorView*)[cell viewWithTag:8];
             [queuing stopAnimating];
         }
     }
     ];
    
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
    return !(storeSelection && storeSelection.row == indexPath.row);
}

- (BOOL)tableView:(UITableView*)tableview canMoveRowAtIndexPath:(NSIndexPath*)indexPath {
    return YES;
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
    
    if (sourceIndexPath.row >= playlistData.count) {
        return;
    }
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
    
    NSString *actionRemove = @"Playlist.Remove";
    NSDictionary *paramsRemove = @{
        @"playlistid": @(playerID),
        @"position": @(sourceIndexPath.row),
    };
    NSString *actionInsert = @"Playlist.Insert";
    NSDictionary *paramsInsert = @{
        @"playlistid": @(playerID),
        @"item": itemToMove,
        @"position": @(destinationIndexPath.row),
    };
    [[Utilities getJsonRPC] callMethod:actionRemove withParameters:paramsRemove onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error == nil && methodError == nil) {
            [[Utilities getJsonRPC] callMethod:actionInsert withParameters:paramsInsert];
            NSInteger numObj = playlistData.count;
            if (sourceIndexPath.row < numObj) {
                [playlistData removeObjectAtIndex:sourceIndexPath.row];
            }
            if (destinationIndexPath.row <= playlistData.count) {
                [playlistData insertObject:objSource atIndex:destinationIndexPath.row];
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
        NSString *actionRemove = @"Playlist.Remove";
        NSDictionary *paramsRemove = @{
            @"playlistid": @(playerID),
            @"position": @(indexPath.row),
        };
        [[Utilities getJsonRPC] callMethod:actionRemove withParameters:paramsRemove onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            if (error == nil && methodError == nil) {
                NSInteger numObj = playlistData.count;
                if (indexPath.row < numObj) {
                    [playlistData removeObjectAtIndex:indexPath.row];
                }
                if (indexPath.row < [playlistTableView numberOfRowsInSection:indexPath.section]) {
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
    if (playlistData.count == 0 && !playlistTableView.editing) {
        return;
    }
    if (playerID == PLAYERID_PICTURES) {
        return;
    }
    if (playlistTableView.editing || forceClose) {
        [playlistTableView setEditing:NO animated:YES];
        editTableButton.selected = NO;
        lastSelected = SELECTED_NONE;
        storeSelection = nil;
    }
    else {
        storeSelection = [playlistTableView indexPathForSelectedRow];
        [playlistTableView setEditing:YES animated:YES];
        editTableButton.selected = YES;
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
    
    // Maximum allowed height excludes status bar, toolbar and safe area
    CGFloat bottomPadding = [Utilities getBottomPadding];
    CGFloat statusBar = UIApplication.sharedApplication.statusBarFrame.size.height;
    CGFloat maxheight = height - bottomPadding - statusBar - TOOLBAR_HEIGHT;
    
    nowPlayingView.frame = CGRectMake(PAD_MENU_TABLE_WIDTH + 2,
                                      YPOS,
                                      width - (PAD_MENU_TABLE_WIDTH + 2),
                                      maxheight);
    
    BottomView.frame = CGRectMake(PAD_MENU_TABLE_WIDTH,
                                  CGRectGetMaxY(songDetailsView.frame),
                                  width - PAD_MENU_TABLE_WIDTH,
                                  maxheight - CGRectGetMaxY(songDetailsView.frame));
    
    frame = playlistToolbar.frame;
    frame.size.width = width;
    frame.origin.x = 0;
    playlistToolbar.frame = frame;
    
    frame = iOS7bgEffect.frame;
    frame.size.width = width;
    iOS7bgEffect.frame = frame;
    
    frame = TopView.frame;
    frame.size.height = CGRectGetMinY(songDetailsView.frame);
    TopView.frame = frame;
    
    [self setCoverSize:currentType];
}

- (void)setFontSizes {
    // Scale is derived from the minimum increase in NowPlaying's width or height
    CGFloat height = IS_IPHONE ? GET_MAINSCREEN_HEIGHT : GET_MAINSCREEN_WIDTH;
    CGFloat width = IS_IPHONE ? GET_MAINSCREEN_WIDTH : GET_MAINSCREEN_WIDTH - PAD_MENU_TABLE_WIDTH;
    CGFloat scale = MIN(height / IPHONE_SCREEN_DESIGN_HEIGHT, width / IPHONE_SCREEN_DESIGN_WIDTH);
    
    albumName.font        = [UIFont systemFontOfSize:floor(18 * scale)];
    songName.font         = [UIFont systemFontOfSize:floor(16 * scale)];
    artistName.font       = [UIFont systemFontOfSize:floor(14 * scale)];
    currentTime.font      = [UIFont systemFontOfSize:floor(12 * scale)];
    duration.font         = [UIFont systemFontOfSize:floor(12 * scale)];
    scrabbingMessage.font = [UIFont systemFontOfSize:floor(10 * scale)];
    scrabbingRate.font    = [UIFont systemFontOfSize:floor(10 * scale)];
}

- (void)setIphoneInterface {
    slideFrom = [self currentScreenBoundsDependOnOrientation].size.width;
    xbmcOverlayImage.hidden = YES;
    [playlistToolbar setShadowImage:[UIImage imageNamed:@"blank"] forToolbarPosition:UIBarPositionAny];
    
    CGRect frame = playlistActionView.frame;
    frame.origin.y = CGRectGetMaxY(playlistToolbar.frame);
    playlistActionView.frame = frame;
}

- (void)setIpadInterface {
    slideFrom = -PAD_MENU_TABLE_WIDTH;
    CGRect frame = playlistTableView.frame;
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
    
    itemDescription.font = [UIFont systemFontOfSize:15];
}

- (BOOL)enableJewelCases {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:@"jewel_preference"];
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
    NSArray *segmentItems = @[[UIImage imageNamed:@"icon_song"],
                              [UIImage imageNamed:@"icon_video"],
                              [UIImage imageNamed:@"icon_picture"]];
    playlistSegmentedControl = [[UISegmentedControl alloc] initWithItems:segmentItems];
    CGFloat left_margin = (PAD_MENU_TABLE_WIDTH - SEGMENTCONTROL_WIDTH)/2;
    if (IS_IPHONE) {
        left_margin = floor(([self currentScreenBoundsDependOnOrientation].size.width - SEGMENTCONTROL_WIDTH)/2);
    }
    playlistSegmentedControl.frame = CGRectMake(left_margin,
                                                (playlistActionView.frame.size.height - SEGMENTCONTROL_HEIGHT)/2,
                                                SEGMENTCONTROL_WIDTH,
                                                SEGMENTCONTROL_HEIGHT);
    playlistSegmentedControl.tintColor = UIColor.whiteColor;
    [playlistSegmentedControl addTarget:self action:@selector(segmentValueChanged:) forControlEvents: UIControlEventValueChanged];
    [playlistActionView addSubview:playlistSegmentedControl];
}

- (void)segmentValueChanged:(UISegmentedControl *)segment {
    [self editTable:nil forceClose:YES];
    if (playlistData.count && (playlistTableView.dragging || playlistTableView.decelerating)) {
        NSArray *visiblePaths = [playlistTableView indexPathsForVisibleRows];
        [playlistTableView scrollToRowAtIndexPath:visiblePaths[0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    switch (segment.selectedSegmentIndex) {
        case PLAYERID_MUSIC:
            selectedPlayerID = PLAYERID_MUSIC;
            break;
            
        case PLAYERID_VIDEO:
            selectedPlayerID = PLAYERID_VIDEO;
            break;
            
        case PLAYERID_PICTURES:
            selectedPlayerID = PLAYERID_PICTURES;
            break;
            
        default:
            NSAssert(NO, @"Unexpected segment selected.");
            break;
    }
    lastSelected = SELECTED_NONE;
    musicPartyMode = 0;
    [self createPlaylist:NO animTableView:YES];
}

#pragma mark - Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (IS_IPHONE) {
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
                                             selector: @selector(disablePopGestureRecognizer:)
                                                 name: @"ECSlidingViewUnderRightWillAppear"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(enablePopGestureRecognizer:)
                                                 name: @"ECSlidingViewTopDidReset"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(connectionSuccess:)
                                                 name: @"XBMCServerConnectionSuccess"
                                               object: nil];
}

- (void)handleDidEnterBackground:(NSNotification*)sender {
    [self viewWillDisappear:YES];
}

- (void)enablePopGestureRecognizer:(id)sender {
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void)disablePopGestureRecognizer:(id)sender {
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
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
    if (fromItself) {
        [self handleXBMCPlaylistHasChanged:nil];
    }
    [self playbackInfo];
    updateProgressBar = YES;
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateInfo) userInfo:nil repeats:YES];
    fromItself = NO;
    if (IS_IPHONE) {
        self.slidingViewController.underRightViewController = nil;
        RightMenuViewController *rightMenuViewController = [[RightMenuViewController alloc] initWithNibName:@"RightMenuViewController" bundle:nil];
        rightMenuViewController.rightMenuItems = AppDelegate.instance.nowPlayingMenuItems;
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
    if (iOS7navBarEffect == nil && IS_IPHONE) {
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
    currentItemID = SELECTED_NONE;
    self.slidingViewController.panGesture.delegate = nil;
    self.navigationController.navigationBar.tintColor = TINT_COLOR;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [Utilities AnimView:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:slideFrom];
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
    editTableButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [editTableButton setTitleColor:UIColor.grayColor forState:UIControlStateHighlighted];
    [editTableButton setTitleColor:UIColor.whiteColor forState:UIControlStateSelected];
    editTableButton.titleLabel.shadowOffset = CGSizeZero;
    
    PartyModeButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [PartyModeButton setTitleColor:UIColor.grayColor forState:UIControlStateNormal];
    [PartyModeButton setTitleColor:UIColor.whiteColor forState:UIControlStateSelected];
    [PartyModeButton setTitleColor:UIColor.whiteColor forState:UIControlStateHighlighted];
    PartyModeButton.titleLabel.shadowOffset = CGSizeZero;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    SDWebImageDownloader *manager = [SDWebImageManager sharedManager].imageDownloader;
    NSDictionary *httpHeaders = AppDelegate.instance.getServerHTTPHeaders;
    if (httpHeaders[@"Authorization"] != nil) {
        [manager setValue:httpHeaders[@"Authorization"] forHTTPHeaderField:@"Authorization"];
    }
    itemDescription.selectable = NO;
    itemLogoImage.layer.minificationFilter = kCAFilterTrilinear;
    songCodecImage.layer.minificationFilter = kCAFilterTrilinear;
    songBitRateImage.layer.minificationFilter = kCAFilterTrilinear;
    songSampleRateImage.layer.minificationFilter = kCAFilterTrilinear;
    songNumChanImage.layer.minificationFilter = kCAFilterTrilinear;
    tempFanartImageView = [UIImageView new];
    tempFanartImageView.hidden = YES;
    [self.view addSubview:tempFanartImageView];
    [PartyModeButton setTitle:LOCALIZED_STR(@"Party") forState:UIControlStateNormal];
    [PartyModeButton setTitle:LOCALIZED_STR(@"Party") forState:UIControlStateHighlighted];
    [PartyModeButton setTitle:LOCALIZED_STR(@"Party") forState:UIControlStateSelected];
    [editTableButton setTitle:LOCALIZED_STR(@"Edit") forState:UIControlStateNormal];
    [editTableButton setTitle:LOCALIZED_STR(@"Done") forState:UIControlStateSelected];
    editTableButton.titleLabel.numberOfLines = 1;
    editTableButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    noItemsLabel.text = LOCALIZED_STR(@"No items found.");
    [self addSegmentControl];
    bottomPadding = [Utilities getBottomPadding];
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
    playlistTableView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    ProgressSlider.minimumTrackTintColor = SLIDER_DEFAULT_COLOR;
    ProgressSlider.maximumTrackTintColor = APP_TINT_COLOR;
    playlistTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    ProgressSlider.userInteractionEnabled = NO;
    [ProgressSlider setThumbImage:[UIImage new] forState:UIControlStateNormal];
    [ProgressSlider setThumbImage:[UIImage new] forState:UIControlStateHighlighted];
    ProgressSlider.hidden = YES;
    scrabbingMessage.text = LOCALIZED_STR(@"Slide your finger up to adjust the scrubbing rate.");
    scrabbingRate.text = LOCALIZED_STR(@"Scrubbing 1");
    sheetActions = [NSMutableArray new];
    playerID = PLAYERID_UNKNOWN;
    selectedPlayerID = PLAYERID_UNKNOWN;
    lastSelected = SELECTED_NONE;
    storedItemID = SELECTED_NONE;
    storeSelection = nil;
    [self setFontSizes];
    if (IS_IPHONE) {
        [self setIphoneInterface];
    }
    else {
        [self setIpadInterface];
    }
    nowPlayingView.hidden = nowPlayingHidden = NO;
    playlistView.hidden = playlistHidden = IS_IPHONE;
    self.navigationItem.title = LOCALIZED_STR(@"Now Playing");
    if (IS_IPHONE) {
        startFlipDemo = YES;
    }
    playlistData = [NSMutableArray new];
}

- (void)connectionSuccess:(NSNotification*)note {
    SDWebImageDownloader *manager = [SDWebImageManager sharedManager].imageDownloader;
    NSDictionary *httpHeaders = AppDelegate.instance.getServerHTTPHeaders;
    if (httpHeaders[@"Authorization"] != nil) {
        [manager setValue:httpHeaders[@"Authorization"] forHTTPHeaderField:@"Authorization"];
    }
}

- (void)handleShakeNotification {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL shake_preference = [userDefaults boolForKey:@"shake_preference"];
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
    if (sender.userInfo) {
        selectedPlayerID = [sender.userInfo[@"params"][@"data"][@"playlistid"] intValue];
    }
    playerID = PLAYERID_UNKNOWN;
    lastSelected = SELECTED_NONE;
    storedItemID = SELECTED_NONE;
    storeSelection = nil;
    lastThumbnail = @"";
    [playlistData performSelectorOnMainThread:@selector(removeAllObjects) withObject:nil waitUntilDone:YES];
    [playlistTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
    [self createPlaylist:NO animTableView:YES];
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
