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
@synthesize playlistToolbarView;
@synthesize toolbarBackground;
@synthesize scrabbingView;
@synthesize itemDescription;

#define HMS_TO_STRING(h, m, s) [NSString stringWithFormat:@"%@%02i:%02i", (totalSeconds < 3600) ? @"" : [NSString stringWithFormat:@"%02i:", h], m, s];

#define MAX_CELLBAR_WIDTH 45
#define PARTYBUTTON_PADDING_LEFT 0
#define PROGRESSBAR_PADDING_LEFT 20
#define PROGRESSBAR_PADDING_BOTTOM 80
#define COVERVIEW_PADDING 10
#define SEGMENTCONTROL_WIDTH 122
#define SEGMENTCONTROL_HEIGHT 32
#define BOTTOMVIEW_WIDTH 320.0
#define BOTTOMVIEW_HEIGHT 158.0
#define TOOLBAR_HEIGHT 44
#define SHUFFLE_REPEAT_VERTICAL_PADDING 3
#define SHUFFLE_REPEAT_HORIZONTAL_PADDING 5
#define TAG_ID_PREVIOUS 1
#define TAG_ID_PLAYPAUSE 2
#define TAG_ID_STOP 3
#define TAG_ID_NEXT 4
#define TAG_ID_TOGGLE 5
#define TAG_SEEK_BACKWARD 6
#define TAG_SEEK_FORWARD 7
#define TAG_SHUFFLE 8
#define TAG_REPEAT 9
#define TAG_ID_EDIT 88
#define SELECTED_NONE -1
#define ID_INVALID -2
#define FLIP_DEMO_DELAY 1.0
#define TRANSITION_TIME 0.2
#define PLAYLIST_DEBOUNCE_TIMEOUT 0.2
#define PLAYLIST_DEBOUNCE_TIMEOUT_MAX 1.0
#define UPDATE_INFO_TIMEOUT 1.0

#define XIB_PLAYLIST_CELL_MAINTITLE 1
#define XIB_PLAYLIST_CELL_SUBTITLE 2
#define XIB_PLAYLIST_CELL_CORNERTITLE 3
#define XIB_PLAYLIST_CELL_COVER 4
#define XIB_PLAYLIST_CELL_PROGRESSVIEW 5
#define XIB_PLAYLIST_CELL_ACTUALTIME 6
#define XIB_PLAYLIST_CELL_PROGRESSBAR 7
#define XIB_PLAYLIST_CELL_ACTIVTYINDICATOR 8

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
        lastPlayerID = PLAYERID_UNKNOWN;
        lastSelected = SELECTED_NONE;
        currentPlayerID = PLAYERID_UNKNOWN;
    }
    return self;
}

# pragma mark - toolbar management

- (UIImage*)resizeToolbarThumb:(UIImage*)img {
    return [self resizeImage:img width:34 height:34 padding:0];
}

#pragma mark - utility

- (int)getSecondsFromTimeDict:(NSDictionary*)timeDict {
    int hours = [timeDict[@"hours"] intValue];
    int minutes = [timeDict[@"minutes"] intValue];
    int seconds = [timeDict[@"seconds"] intValue];
    return ((hours * 60) + minutes) * 60 + seconds;
}

- (NSString*)formatRuntimeFromTimeDict:(NSDictionary*)timeDict {
    int hours = [timeDict[@"hours"] intValue];
    int minutes = [timeDict[@"minutes"] intValue];
    int seconds = [timeDict[@"seconds"] intValue];
    NSString *timeString = HMS_TO_STRING(hours, minutes, seconds);
    return timeString;
}

- (NSString*)getPlaylistHeaderLabel {
    NSString *headerLabel = LOCALIZED_STR(@"Playlist");
    NSUInteger numItems = playlistData.count;
    if (numItems > 0) {
        headerLabel = [NSString stringWithFormat:@"%@ (%lu)", headerLabel, numItems];
    }
    return headerLabel;
}

- (void)updateBlurredCoverBackground:(UIImage*)image {
    // Show blurred cover background (iPhone only, as iPad uses other layout)
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:@"blurred_cover_preference"] && IS_IPHONE) {
        [Utilities imageView:fullscreenCover AnimDuration:1.0 Image:image];
        visualEffectView.hidden = NO;
    }
    else {
        fullscreenCover.image = nil;
        visualEffectView.hidden = YES;
    }
}

- (NSString*)getNowPlayingThumbnailPath:(NSDictionary*)item {
    // If a recording is played, we can use the iocn (typically the station logo)
    BOOL useIcon = [item[@"type"] isEqualToString:@"recording"] || [item[@"recordingid"] longValue] > 0;
    return [Utilities getThumbnailFromDictionary:item useBanner:NO useIcon:useIcon];
}

- (void)setSongDetails:(UILabel*)label image:(UIImageView*)imageView item:(id)item {
    label.text = [Utilities getStringFromItem:item];
    imageView.image = [self loadImageFromName:label.text];
    imageView.hidden = NO;
    label.hidden = imageView.image != nil;
}

- (NSString*)processAudioCodecName:(NSString*)codec {
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

- (NSString*)processChannelString:(NSString*)channels {
    NSDictionary *channelSetupTable = @{
        @"0": @"0.0",
        @"1": @"1.0",
        @"2": @"2.0",
        @"3": @"2.1",
        @"4": @"4.0",
        @"5": @"4.1",
        @"6": @"5.1",
        @"7": @"6.1",
        @"8": @"7.1",
        @"9": @"8.1",
        @"10": @"9.1",
    };
    channels = channelSetupTable[channels] ?: channels;
    channels = channels.length ? [NSString stringWithFormat:@"%@\n", channels] : @"";
    return channels;
}

- (NSString*)processAspectString:(NSString*)aspect {
    NSDictionary *aspectTable = @{
        @"1.00": @"1:1",
        @"1.33": @"4:3",
        @"1.78": @"16:9",
        @"2.00": @"2:1",
    };
    aspect = aspectTable[aspect] ?: aspect;
    return aspect;
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
        image = [UIImage imageNamed:imageName];
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
    }
    else {
        if (musicPartyMode) {
            PartyModeButton.selected = NO;
            [[Utilities getJsonRPC]
             callMethod:@"Player.SetPartymode"
             withParameters:@{@"playerid": @(0), @"partymode": @"toggle"}
             onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                 PartyModeButton.selected = NO;
             }];
        }
        else {
            PartyModeButton.selected = YES;
            [[Utilities getJsonRPC]
             callMethod:@"Player.Open"
             withParameters:@{@"item": @{@"partymode": @"music"}}
             onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                 PartyModeButton.selected = YES;
                 storedItemID = SELECTED_NONE;
             }];
        }
    }
    return;
}

- (void)setPlaylistCellProgressBar:(UITableViewCell*)cell hidden:(BOOL)hidden {
    // Do not unhide the playlist progress bar while in pictures playlist
    UIView *view = (UIView*)[cell viewWithTag:XIB_PLAYLIST_CELL_PROGRESSVIEW];
    if (currentPlaylistID == PLAYERID_PICTURES || currentPlaylistID != currentPlayerID) {
        hidden = YES;
    }
    view.hidden = hidden;
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
		CGContextRotateCTM (bitmap, M_PI / 2);
		CGContextTranslateCTM (bitmap, 0, -height);
	}
    else if (image.imageOrientation == UIImageOrientationRight) {
		CGContextRotateCTM (bitmap, -M_PI / 2);
		CGContextTranslateCTM (bitmap, -width, 0);
	}
    else if (image.imageOrientation == UIImageOrientationUp) {
		
	}
    else if (image.imageOrientation == UIImageOrientationDown) {
		CGContextTranslateCTM (bitmap, width, height);
		CGContextRotateCTM (bitmap, -M_PI);
		
	}
	
	CGContextDrawImage(bitmap, CGRectMake(destWidth / 2 - width / 2, destHeight / 2 - height / 2, width, height), imageRef);
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

- (void)updateRepeatButton:(NSString*)mode {
    if ([mode isEqualToString:@"all"]) {
        UIImage *image = [UIImage imageNamed:@"button_repeat_all"];
        image = [Utilities colorizeImage:image withColor:KODI_BLUE_COLOR];
        [repeatButton setBackgroundImage:image forState:UIControlStateNormal];
    }
    else if ([mode isEqualToString:@"one"]) {
        UIImage *image = [UIImage imageNamed:@"button_repeat_one"];
        image = [Utilities colorizeImage:image withColor:KODI_BLUE_COLOR];
        [repeatButton setBackgroundImage:image forState:UIControlStateNormal];
    }
    else {
        UIImage *image = [UIImage imageNamed:@"button_repeat"];
        image = [Utilities colorizeImage:image withColor:IS_IPAD ? UIColor.whiteColor : UIColor.lightGrayColor];
        [repeatButton setBackgroundImage:image forState:UIControlStateNormal];
    }
}

- (void)updateShuffleButton:(BOOL)shuffle {
    if (shuffle) {
        UIImage *image = [UIImage imageNamed:@"button_shuffle_on"];
        image = [Utilities colorizeImage:image withColor:KODI_BLUE_COLOR];
        [shuffleButton setBackgroundImage:image forState:UIControlStateNormal];
    }
    else {
        UIImage *image = [UIImage imageNamed:@"button_shuffle"];
        image = [Utilities colorizeImage:image withColor:IS_IPAD ? UIColor.whiteColor : UIColor.lightGrayColor];
        [shuffleButton setBackgroundImage:image forState:UIControlStateNormal];
    }
}

#pragma mark - JSON management

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
    else if ([type isEqualToString:@"episode"] ||
             [type isEqualToString:@"channel"] ||
             [type isEqualToString:@"recording"]) {
        jewelImg = @"jewel_tv.9";
        jeweltype = jewelTypeTV;
    }
    else {
        jewelImg = @"jewel_cd.9";
        jeweltype = jewelTypeCD;
    }
    BOOL forceAspectFit = [type isEqual:@"channel"] || [type isEqual:@"recording"];
    if ([self enableJewelCases]) {
        jewelView.image = [UIImage imageNamed:jewelImg];
        thumbnailView.frame = [Utilities createCoverInsideJewel:jewelView jewelType:jeweltype];
        thumbnailView.contentMode = forceAspectFit ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
    }
    else {
        jewelView.image = nil;
        thumbnailView.frame = jewelView.frame;
        thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
    }
    thumbnailView.clipsToBounds = YES;
    songDetailsView.frame = jewelView.frame;
    songDetailsView.center = [jewelView.superview convertPoint:jewelView.center toView:songDetailsView.superview];
    [nowPlayingView bringSubviewToFront:songDetailsView];
    [nowPlayingView bringSubviewToFront:BottomView];
}

- (void)serverIsDisconnected {
    currentPlaylistID = PLAYERID_UNKNOWN;
    storedItemID = 0;
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        // Fade out
        playlistTableView.alpha = 0.0;
    }
                     completion:^(BOOL finished) {
        [playlistData removeAllObjects];
        [playlistTableView reloadData];
        [self notifyChangeForPlaylistHeader];
    }];
    [self nothingIsPlaying];
}

- (void)nothingIsPlaying {
    UIImage *image = [UIImage imageNamed:@"st_nowplaying_small"];
    [self setButtonImageAndStartDemo:image];
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
    jewelView.image = nil;
    lastThumbnail = @"";
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
    upnp.hidden = YES;
    musicPartyMode = NO;
    isRemotePlayer = NO;
    [self notifyChangeForBackgroundImage:nil coverImage:nil];
    [self deselectPlaylistItem];
    [self showPlaylistTableAnimated:NO];
    [self toggleSongDetails];
    
    // Unload and hide blurred cover effect
    fullscreenCover.image = nil;
    visualEffectView.hidden = YES;
}

- (void)setButtonImageAndStartDemo:(UIImage*)buttonImage {
    if (nowPlayingView.hidden || startFlipDemo) {
        [playlistButton setImage:buttonImage forState:UIControlStateNormal];
        [playlistButton setImage:buttonImage forState:UIControlStateHighlighted];
        [playlistButton setImage:buttonImage forState:UIControlStateSelected];
        if (startFlipDemo) {
            [NSTimer scheduledTimerWithTimeInterval:FLIP_DEMO_DELAY target:self selector:@selector(startFlipDemo) userInfo:nil repeats:NO];
            startFlipDemo = NO;
        }
    }
}

- (void)changeImage:(UIImageView*)imageView image:(UIImage*)newImage {
    [Utilities imageView:imageView AnimDuration:0.2 Image:newImage];
}

- (void)setWaitForInfoLabelsToSettle {
    waitForInfoLabelsToSettle = NO;
}

- (void)updateNowPlayingLabels:(NSDictionary*)item {
    // Set song details description text
    if (currentPlayerID != PLAYERID_PICTURES) {
        NSString *description = [Utilities getStringFromItem:item[@"description"]];
        NSString *plot = [Utilities getStringFromItem:item[@"plot"]];
        itemDescription.text = description.length ? description : (plot.length ? plot : @"");
        itemDescription.text = [Utilities stripBBandHTML:itemDescription.text];
        [itemDescription scrollRangeToVisible:NSMakeRange(0, 0)];
    }
    
    // Set NowPlaying text fields
    // 1st: title
    NSString *label = [Utilities getStringFromItem:item[@"label"]];
    NSString *title = [Utilities getStringFromItem:item[@"title"]];
    storeLiveTVTitle = title;
    if (title.length == 0) {
        title = label;
    }
    
    // 2nd: artists
    NSString *artist = [Utilities getStringFromItem:item[@"artist"]];
    NSString *studio = [Utilities getStringFromItem:item[@"studio"]];
    NSString *channel = [Utilities getStringFromItem:item[@"channel"]];
    if (artist.length == 0 && studio.length) {
        artist = studio;
    }
    if (artist.length == 0 && channel.length && ![channel isEqualToString:title]) {
        artist = channel;
    }
    
    // 3rd: album
    NSString *album = [Utilities getStringFromItem:item[@"album"]];
    NSString *showtitle = [Utilities getStringFromItem:item[@"showtitle"]];
    NSString *season = [Utilities getStringFromItem:item[@"season"]];
    NSString *episode = [Utilities getStringFromItem:item[@"episode"]];
    if (album.length == 0 && showtitle.length) {
        album = [Utilities formatTVShowStringForSeasonTrailing:season episode:episode title:showtitle];
    }
    NSString *director = [Utilities getStringFromItem:item[@"director"]];
    if (album.length == 0 && director.length) {
        album = director;
    }
    
    // Add year to artist string, if available
    NSString *year = [Utilities getYearFromItem:item[@"year"]];
    artist = [self formatArtistYear:artist year:year];
    
    // top to bottom: songName, artistName, albumName
    songName.text = title;
    artistName.text = artist;
    albumName.text = album;
}

- (void)updateNowPlayingArtwork:(NSDictionary*)item withJewel:(BOOL)enableJewel {
    // Set cover size and load covers
    NSString *type = [Utilities getStringFromItem:item[@"type"]];
    currentType = type;
    [self setCoverSize:currentType];
    NSString *serverURL = [Utilities getImageServerURL];
    NSString *thumbnailPath = [self getNowPlayingThumbnailPath:item];
    NSString *stringURL = [Utilities formatStringURL:thumbnailPath serverURL:serverURL];
    NSString *fanart = [Utilities getStringFromItem:item[@"fanart"]];
    if (![lastThumbnail isEqualToString:stringURL] || [lastThumbnail isEqualToString:@""]) {
        if (!thumbnailPath.length) {
            UIImage *image = [UIImage imageNamed:@"coverbox_back"];
            [self processLoadedThumbImage:self thumb:thumbnailView image:image enableJewel:enableJewel];
            [self updateBlurredCoverBackground:nil];
            [self notifyChangeForBackgroundImage:fanart coverImage:nil];
        }
        else {
            __weak UIImageView *thumb = thumbnailView;
            __typeof__(self) __weak weakSelf = self;
            [thumbnailView sd_setImageWithURL:[NSURL URLWithString:stringURL]
                             placeholderImage:[UIImage imageNamed:@"coverbox_back"]
                                      options:SDWebImageDelayPlaceholder
                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *url) {
                 if (error == nil) {
                     [weakSelf processLoadedThumbImage:weakSelf thumb:thumb image:image enableJewel:enableJewel];
                     [weakSelf updateBlurredCoverBackground:image];
                     [weakSelf notifyChangeForBackgroundImage:fanart coverImage:image];
                 }
             }];
        }
    }
    lastThumbnail = stringURL;
}

- (void)updateOverlayArtWork:(NSDictionary*)item {
    itemLogoImage.image = nil;
    NSString *serverURL = [Utilities getImageServerURL];
    NSDictionary *art = item[@"art"];
    storeClearlogo = [Utilities getClearArtFromDictionary:art type:@"clearlogo"];
    storeClearart = [Utilities getClearArtFromDictionary:art type:@"clearart"];
    if (!storeClearlogo.length) {
        storeClearlogo = storeClearart;
    }
    if (storeClearlogo.length) {
        NSString *stringURL = [Utilities formatStringURL:storeClearlogo serverURL:serverURL];
        [itemLogoImage sd_setImageWithURL:[NSURL URLWithString:stringURL]];
        storeCurrentLogo = storeClearlogo;
    }
}

- (void)updateControlsAndPlaylist:(NSDictionary*)item {
    // Read percentage of playback progress and set progress slider
    float percentage = [Utilities getFloatValueFromItem:item[@"percentage"]];
    if (updateProgressBar) {
        ProgressSlider.value = percentage;
    }
    
    // Read PartyMode state and set button
    musicPartyMode = [item[@"partymode"] boolValue];
    PartyModeButton.selected = musicPartyMode;
    
    // Read repeat capability and mode to set button state
    BOOL canRepeat = [item[@"canrepeat"] boolValue] && !musicPartyMode;
    repeatButton.hidden = !canRepeat;
    if (canRepeat) {
        repeatStatus = item[@"repeat"];
        [self updateRepeatButton:repeatStatus];
    }
    
    // Read shuffle capability and mode to set button state
    BOOL canShuffle = [item[@"canshuffle"] boolValue] && !musicPartyMode;
    shuffleButton.hidden = !canShuffle;
    if (canShuffle) {
        shuffled = [item[@"shuffled"] boolValue];
        [self updateShuffleButton:shuffled];
    }
    
    // Read seek capability and mode to set progress bar state
    BOOL canSeek = [item[@"canseek"] boolValue];
    if (canSeek && !ProgressSlider.userInteractionEnabled) {
        ProgressSlider.userInteractionEnabled = YES;
        UIImage *image = [UIImage imageNamed:@"pgbar_thumb_iOS7"];
        [ProgressSlider setThumbImage:image forState:UIControlStateNormal];
        [ProgressSlider setThumbImage:image forState:UIControlStateHighlighted];
    }
    if (!canSeek && ProgressSlider.userInteractionEnabled) {
        ProgressSlider.userInteractionEnabled = NO;
        [ProgressSlider setThumbImage:[UIImage new] forState:UIControlStateNormal];
        [ProgressSlider setThumbImage:[UIImage new] forState:UIControlStateHighlighted];
    }

    // Read item's total playback time, totalSeconds is used for formatting and progress slider
    NSDictionary *totalTimeDict = item[@"totaltime"];
    totalSeconds = [self getSecondsFromTimeDict:totalTimeDict];
    NSString *totalTime = [self formatRuntimeFromTimeDict:totalTimeDict];
    duration.text = totalTime;
    
    // Read item's current playback time and update display time in playlist
    NSDictionary *actualTimeDict = item[@"time"];
    NSString *actualTime = [self formatRuntimeFromTimeDict:actualTimeDict];
    if (updateProgressBar) {
        currentTime.text = actualTime;
        ProgressSlider.hidden = NO;
        currentTime.hidden = NO;
        duration.hidden = NO;
    }
    
    // Disable progress bar for pictures, slideshows or items with no total time (e.g. audio streams)
    if (currentPlayerID == PLAYERID_PICTURES || totalSeconds == 0) {
        ProgressSlider.hidden = YES;
        currentTime.hidden = YES;
        duration.hidden = YES;
    }
    
    // Detect start of new song to update party mode playlist
    int posSeconds = [self getSecondsFromTimeDict:actualTimeDict];
    if (musicPartyMode && posSeconds < storePosSeconds) {
        [self updatePartyModePlaylist];
        
        // Leave here to avoid flickering playlist progressbar (next code block)
        storePosSeconds = posSeconds;
        return;
    }
    storePosSeconds = posSeconds;
    
    // Update the playlist position and time when a new item plays, else update progress only
    long playlistPosition = [item[@"position"] longValue];
    if (playlistPosition != lastSelected && playlistPosition != SELECTED_NONE) {
        [self setPlaylistPosition:playlistPosition forPlayer:currentPlayerID];
        [self updatePlaylistProgressbar:0.0f actual:@"00:00"];
    }
    else {
        [self updatePlaylistProgressbar:percentage actual:actualTime];
    }
}

- (void)setPlayerStates:(NSArray*)activePlayerList {
    // Get active player from list
    int activePlayerID = [Utilities getActivePlayerID:activePlayerList];
    
    // Get status of slideshow
    isSlideshowActive = [self getSlideshowState:activePlayerList];
    
    // Set the current playerid. This is used to gather current played item's metadata.
    currentPlayerID = activePlayerID;
    if (currentPlayerID == PLAYERID_UNKNOWN || currentPlayerID != lastPlayerID) {
        lastPlayerID = currentPlayerID;
        // Pause the A/V codec updates until Kodi's info labels settled
        waitForInfoLabelsToSettle = YES;
        [self performSelector:@selector(setWaitForInfoLabelsToSettle) withObject:nil afterDelay:1.0];
    }
    
    // If no playlist is selected yet in the UI, set it to the player's id and update the playlist.
    // Active slideshows can use video and picture players. If we start with an active slideshow
    // and do not have the music player active, we force the playlist to picture playlist to deal
    // with potentially running slideshow videos.
    if (currentPlaylistID == PLAYERID_UNKNOWN) {
        currentPlaylistID = (isSlideshowActive && currentPlayerID != PLAYERID_MUSIC) ? PLAYERID_PICTURES : activePlayerID;
        [self createPlaylistAnimated:YES];
    }
    
    // Codec view uses "XBMC.GetInfoLabels" which might change asynchronously. Therefore check each time.
    if (songDetailsView.alpha && !waitForInfoLabelsToSettle) {
        [self loadCodecView];
    }
}

- (void)setPlaylistPosition:(long)playlistPosition forPlayer:(int)playerID {
    if (playlistData.count <= playlistPosition ||
        currentPlaylistID != playerID ||
        ![playlistTableView numberOfSections]) {
        return;
    }
    // Make current cell's progress bar invisible
    NSIndexPath *selection = [playlistTableView indexPathForSelectedRow];
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
    [self setPlaylistCellProgressBar:cell hidden:YES];
    
    // Make new cell's progress bar visible and select playlist cell
    NSIndexPath *newSelection = [NSIndexPath indexPathForRow:playlistPosition inSection:0];
    if (newSelection.row < [playlistTableView numberOfRowsInSection:0]) {
        [playlistTableView selectRowAtIndexPath:newSelection animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:newSelection];
        [self setPlaylistCellProgressBar:cell hidden:NO];
        storeSelection = newSelection;
        lastSelected = playlistPosition;
    }
}

- (BOOL)getSlideshowState:(NSArray*)activePlayerList {
    // Detect, if there is an active slideshow running in Kodi.
    for (id activePlayer in activePlayerList) {
        if ([activePlayer[@"playerid"] intValue] == PLAYERID_PICTURES) {
            return YES;
        }
    }
    return NO;
}

- (void)getPlayerItems {
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
                                    @"channel",
                                    @"description",
                                    @"year",
                                    @"director",
                                    @"plot"] mutableCopy];
    if (AppDelegate.instance.serverVersion > 11) {
        [properties addObject:@"art"];
    }
    [[Utilities getJsonRPC]
     callMethod:@"Player.GetItem"
     withParameters:@{@"playerid": @(currentPlayerID),
                      @"properties": properties}
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
         // Do not process further, if the view is already off the view hierarchy.
         if (!self.viewIfLoaded.window) {
             return;
         }
         if (error == nil && methodError == nil) {
             bool enableJewel = [self enableJewelCases];
             if ([methodResult isKindOfClass:[NSDictionary class]]) {
                 NSDictionary *nowPlayingInfo = methodResult[@"item"];
                 if (![nowPlayingInfo isKindOfClass:[NSDictionary class]]) {
                     return;
                 }
                 long currentItemID = nowPlayingInfo[@"id"] ? [nowPlayingInfo[@"id"] longValue] : ID_INVALID;
                 if ((nowPlayingInfo.count && currentItemID != storedItemID) || 
                     nowPlayingInfo[@"id"] == nil ||
                     ([nowPlayingInfo[@"type"] isEqualToString:@"channel"] && ![nowPlayingInfo[@"title"] isEqualToString:storeLiveTVTitle])) {
                     storedItemID = currentItemID;

                     [self updateNowPlayingLabels:nowPlayingInfo];
                     [self updateNowPlayingArtwork:nowPlayingInfo withJewel:enableJewel];
                     [self updateOverlayArtWork:nowPlayingInfo];
                 }
             }
             else {
                 storedItemID = SELECTED_NONE;
                 lastThumbnail = @"";
                 [self setCoverSize:@"song"];
                 UIImage *image = [UIImage imageNamed:@"coverbox_back"];
                 [self processLoadedThumbImage:self thumb:thumbnailView image:image enableJewel:enableJewel];
             }
         }
         else {
             storedItemID = SELECTED_NONE;
         }
     }];
}

- (void)getPlayerProperties {
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
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
         // Do not process further, if the view is already off the view hierarchy.
         if (!self.viewIfLoaded.window) {
             return;
         }
         if (error == nil && methodError == nil) {
             if ([methodResult isKindOfClass:[NSDictionary class]]) {
                 if ([methodResult count]) {
                     // Updates repeat, shuffle and seek capabilities and status.
                     // Updates progress bar visibilty, progress and time.
                     // Updates playlist position and tiggers playlist reload in Partymode.
                     [self updateControlsAndPlaylist:methodResult];
                 }
             }
         }
     }];
}

- (void)getPlayerPropertiesSlideshow {
    [[Utilities getJsonRPC]
     callMethod:@"Player.GetProperties"
     withParameters:@{@"playerid": @(PLAYERID_PICTURES),
                      @"properties": @[@"position"]}
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
         // Do not process further, if the view is already off the view hierarchy.
         if (!self.viewIfLoaded.window) {
             return;
         }
         if (error == nil && methodError == nil) {
             if ([methodResult isKindOfClass:[NSDictionary class]]) {
                 if ([methodResult count]) {
                     // Update the playlist position
                     [self setPlaylistPosition:[methodResult[@"position"] longValue] forPlayer:PLAYERID_PICTURES];
                 }
             }
         }
     }];
}

- (void)getActivePlayers {
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:@{} withTimeout:2.0 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        // Do not process further, if the view is already off the view hierarchy.
        if (!self.viewIfLoaded.window) {
            return;
        }
        if (error == nil && methodError == nil) {
            if ([methodResult isKindOfClass:[NSArray class]] && [methodResult count] > 0) {
                isRemotePlayer = [methodResult[0][@"playertype"] isEqualToString:@"remote"];
                upnp.hidden = !isRemotePlayer;
                nothingIsPlaying = NO;
                
                // Set state machine variables for player / playlist
                [self setPlayerStates:methodResult];
                
                // Reads the details of the currently playing item and updates NowPlaying labels and artwork.
                [self getPlayerItems];
                
                // Reads the properties of the current active player and updates NowPlaying controls and playlist.
                [self getPlayerProperties];
                
                // Reads the properties for a running slideshow to be able to select the correct playlist position.
                if (isSlideshowActive) {
                    [self getPlayerPropertiesSlideshow];
                }
            }
            else {
                [self nothingIsPlaying];
                // If there is no running player or active playlist, select music as default playlist
                if (currentPlaylistID == PLAYERID_UNKNOWN) {
                    currentPlaylistID = PLAYERID_MUSIC;
                    [self createPlaylistAnimated:YES];
                }
            }
        }
        else {
            [self nothingIsPlaying];
        }
    }];
}

- (void)notifyChangeForPlaylistHeader {
    // Define playlist header label, adding number of playlist items in brackets
    NSString *playlistLabel = [self getPlaylistHeaderLabel];
    if (!playlistView.hidden) {
        self.navigationItem.title = playlistLabel;
    }
    // For iPad send a notification with the label
    if (IS_IPAD) {
        NSDictionary *params = @{@"playlistHeaderLabel": playlistLabel};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PlaylistHeaderUpdate" object:nil userInfo:params];
    }
}

- (void)notifyChangeForBackgroundImage:(NSString*)bgImagePath coverImage:(UIImage*)coverImage {
    if (IS_IPAD) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                bgImagePath ?: @"", @"image",
                                coverImage, @"cover",
                                nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"IpadChangeBackgroundImage" object:nil userInfo:params];
    }
}

- (void)processLoadedThumbImage:(NowPlaying*)sf thumb:(UIImageView*)thumb image:(UIImage*)image enableJewel:(BOOL)enableJewel {
    UIImage *processedImage = [sf imageWithBorderFromImage:image];
    UIImage *buttonImage = [sf resizeToolbarThumb:processedImage];
    if (enableJewel) {
        thumb.image = image;
    }
    else {
        [sf changeImage:thumb image:processedImage];
    }
    [sf setButtonImageAndStartDemo:buttonImage];
}

- (NSString*)formatArtistYear:(NSString*)artist year:(NSString*)year {
    NSString *text = @"";
    if (artist.length && year.length) {
        text = [NSString stringWithFormat:@"%@ (%@)", artist, year];
    }
    else if (year.length) {
        text = year;
    }
    else if (artist.length) {
        text = artist;
    }
    return text;
}

- (void)loadCodecView {
    [[Utilities getJsonRPC]
     callMethod:@"XBMC.GetInfoLabels" 
     withParameters:@{@"labels": @[@"MusicPlayer.Codec",
                                   @"MusicPlayer.SampleRate",
                                   @"MusicPlayer.BitRate",
                                   @"MusicPlayer.BitsPerSample",
                                   @"MusicPlayer.Channels",
                                   @"Slideshow.Resolution",
                                   @"Slideshow.Filename",
                                   @"Slideshow.CameraModel",
                                   @"Slideshow.EXIFTime",
                                   @"Slideshow.Aperture",
                                   @"Slideshow.ISOEquivalence",
                                   @"Slideshow.ExposureTime",
                                   @"Slideshow.Exposure",
                                   @"Slideshow.ExposureBias",
                                   @"Slideshow.MeteringMode",
                                   @"Slideshow.FocalLength",
                                   @"VideoPlayer.VideoResolution",
                                   @"VideoPlayer.VideoAspect",
                                   @"VideoPlayer.AudioCodec",
                                   @"VideoPlayer.VideoCodec"]}
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
         if (error == nil && methodError == nil && [methodResult isKindOfClass: [NSDictionary class]]) {
             hiresImage.hidden = YES;
             itemDescription.textAlignment = NSTextAlignmentJustified;
             if (currentPlayerID == PLAYERID_MUSIC) {
                 NSString *codec = [Utilities getStringFromItem:methodResult[@"MusicPlayer.Codec"]];
                 codec = [self processAudioCodecName:codec];
                 [self setSongDetails:songCodec image:songCodecImage item:codec];
                 
                 NSString *channels = [Utilities getStringFromItem:methodResult[@"MusicPlayer.Channels"]];
                 channels = [self processChannelString:channels];
                 songBitRate.text = channels;
                 songBitRateImage.image = [self loadImageFromName:@"channels"];
                 songBitRate.hidden = songBitRateImage.hidden = channels.length == 0;
                 
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
                
                 NSString *newLine = bps.length && kHz.length ? @"\n" : @"";
                 NSString *samplerate = [NSString stringWithFormat:@"%@%@%@", bps, newLine, kHz];
                 songNumChannels.text = samplerate;
                 songNumChannels.hidden = NO;
                 songNumChanImage.image = nil;
                 
                 NSString *bitrate = [Utilities getStringFromItem:methodResult[@"MusicPlayer.BitRate"]];
                 bitrate = bitrate.length ? [NSString stringWithFormat:@"%@\nkbit/s", bitrate] : @"";
                 songSampleRate.text = bitrate;
                 songSampleRate.hidden = NO;
                 songSampleRateImage.image = nil;
                 
                 itemDescription.font  = [UIFont systemFontOfSize:descriptionFontSize];
             }
             else if (currentPlayerID == PLAYERID_VIDEO) {
                 NSString *codec = [Utilities getStringFromItem:methodResult[@"VideoPlayer.AudioCodec"]];
                 codec = [self processAudioCodecName:codec];
                 [self setSongDetails:songNumChannels image:songNumChanImage item:codec];
                 [self setSongDetails:songCodec image:songCodecImage item:methodResult[@"VideoPlayer.VideoResolution"]];
                 [self setSongDetails:songSampleRate image:songSampleRateImage item:methodResult[@"VideoPlayer.VideoCodec"]];
                 
                 NSString *aspect = [Utilities getStringFromItem:methodResult[@"VideoPlayer.VideoAspect"]];
                 aspect = [self processAspectString:aspect];
                 songBitRate.text = aspect;
                 songBitRateImage.image = [self loadImageFromName:@"aspect"];
                 songBitRateImage.hidden = songBitRate.hidden = aspect.length == 0;
                 
                 itemDescription.font  = [UIFont systemFontOfSize:descriptionFontSize];
             }
             else if (currentPlayerID == PLAYERID_PICTURES) {
                 NSString *filename = [Utilities getStringFromItem:methodResult[@"Slideshow.Filename"]];
                 NSString *filetype = [[filename pathExtension] uppercaseString];
                 songBitRate.text = filetype;
                 
                 NSString *resolution = [Utilities getStringFromItem:methodResult[@"Slideshow.Resolution"]];
                 resolution = [resolution stringByReplacingOccurrencesOfString:@" x " withString:@"\n"];
                 songCodec.text = resolution;
                 songCodecImage.image = [self loadImageFromName:@"aspect"];
                 songCodecImage.hidden = resolution.length == 0;
                 
                 NSString *camera = [Utilities getStringFromItem:methodResult[@"Slideshow.CameraModel"]];
                 songSampleRate.text = camera;
                 
                 BOOL hasEXIF = camera.length;
                 songNumChannels.text = @"EXIF\n";
                 songNumChanImage.image = [self loadImageFromName:@"exif"];
                 songNumChannels.hidden = songNumChanImage.hidden = !hasEXIF;
                 
                 songCodec.hidden = !songCodec.text.length;
                 songBitRate.hidden = !songBitRate.text.length;
                 songSampleRate.hidden = !songSampleRate.text.length;
                 songBitRateImage.hidden = YES;
                 songSampleRateImage.hidden = YES;
                 
                 NSMutableAttributedString *infoString = [NSMutableAttributedString new];
                 if (hasEXIF) {
                     [infoString appendAttributedString:[self formatInfo:LOCALIZED_STR(@"Date & time") text:methodResult[@"Slideshow.EXIFTime"]]];
                     [infoString appendAttributedString:[self formatInfo:LOCALIZED_STR(@"ISO equivalence") text:methodResult[@"Slideshow.ISOEquivalence"]]];
                     [infoString appendAttributedString:[self formatInfo:LOCALIZED_STR(@"Resolution") text:methodResult[@"Slideshow.Resolution"]]];
                     [infoString appendAttributedString:[self formatInfo:LOCALIZED_STR(@"Aperture") text:methodResult[@"Slideshow.Aperture"]]];
                     [infoString appendAttributedString:[self formatInfo:LOCALIZED_STR(@"Exposure time") text:methodResult[@"Slideshow.ExposureTime"]]];
                     [infoString appendAttributedString:[self formatInfo:LOCALIZED_STR(@"Exposure mode") text:methodResult[@"Slideshow.Exposure"]]];
                     [infoString appendAttributedString:[self formatInfo:LOCALIZED_STR(@"Exposure bias") text:methodResult[@"Slideshow.ExposureBias"]]];
                     [infoString appendAttributedString:[self formatInfo:LOCALIZED_STR(@"Metering mode") text:methodResult[@"Slideshow.MeteringMode"]]];
                     [infoString appendAttributedString:[self formatInfo:LOCALIZED_STR(@"Focal length") text:methodResult[@"Slideshow.FocalLength"]]];
                     [infoString appendAttributedString:[self formatInfo:LOCALIZED_STR(@"Camera model") text:methodResult[@"Slideshow.CameraModel"]]];
                 }
                 itemDescription.attributedText = infoString;
             }
             else {
                 songCodec.hidden = YES;
                 songBitRate.hidden = YES;
                 songSampleRate.hidden = YES;
                 songNumChannels.hidden = YES;
                 songCodecImage.hidden = YES;
                 songBitRateImage.hidden = YES;
                 songSampleRateImage.hidden = YES;
                 songNumChanImage.hidden = YES;
             }
         }
    }];
}

- (NSAttributedString*)formatInfo:(NSString*)name text:(NSString*)text {
    if (!text.length) {
        text = @"-";
    }
    int fontSize = descriptionFontSize;
    // Bold and gray for label
    name = [NSString stringWithFormat:@"%@: ", name];
    NSDictionary *boldFontAttrib = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:fontSize],
        NSForegroundColorAttributeName: UIColor.lightGrayColor,
    };
    // Normal and white for the text
    NSMutableAttributedString *string1 = [[NSMutableAttributedString alloc] initWithString:name attributes:boldFontAttrib];
    text = [NSString stringWithFormat:@"%@\n", text];
    NSDictionary *normalFontAttrib = @{
        NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
        NSForegroundColorAttributeName: UIColor.whiteColor,
    };
    NSMutableAttributedString *string2 = [[NSMutableAttributedString alloc] initWithString:text attributes:normalFontAttrib];
    // Build the complete string
    [string1 appendAttributedString:string2];
    return string1;
}

- (void)playbackInfo {
    if (!AppDelegate.instance.serverOnLine) {
        [self serverIsDisconnected];
        return;
    }
    if (AppDelegate.instance.serverVersion == 11) {
        [[Utilities getJsonRPC]
         callMethod:@"XBMC.GetInfoBooleans" 
         withParameters:@{@"booleans": @[@"Window.IsActive(virtualkeyboard)", @"Window.IsActive(selectdialog)"]}
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
             
             if (error == nil && methodError == nil && [methodResult isKindOfClass: [NSDictionary class]]) {
                 if (methodResult[@"Window.IsActive(virtualkeyboard)"] != [NSNull null] && methodResult[@"Window.IsActive(selectdialog)"] != [NSNull null]) {
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
    [[Utilities getJsonRPC] callMethod:@"Playlist.Clear" withParameters:@{@"playlistid": @(playlistID)} onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil) {
            [playlistTableView setEditing:NO animated:NO];
            [self createPlaylistAnimated:NO];
        }
    }];
}

- (void)playbackAction:(NSString*)action params:(NSDictionary*)parameters {
    NSMutableDictionary *commonParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
    commonParams[@"playerid"] = @(currentPlayerID);
    [[Utilities getJsonRPC] callMethod:action withParameters:commonParams onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
    }];
}

- (void)updatePartyModePlaylist {
    lastSelected = SELECTED_NONE;
    storeSelection = 0;
    // Do not update/switch to an updated Party playlist while the user watches another playlist.
    if (currentPlaylistID == PLAYERID_MUSIC) {
        [self createPlaylistAnimated:NO];
    }
}

- (void)createPlaylistAnimated:(BOOL)animTable {
    if (!AppDelegate.instance.serverOnLine) {
        [self serverIsDisconnected];
        return;
    }
    if (currentPlaylistID == PLAYERID_UNKNOWN) {
        return;
    }
    if (animTable) {
        [activityIndicatorView startAnimating];
    }
    
    if (currentPlaylistID == PLAYERID_MUSIC) {
        playlistSegmentedControl.selectedSegmentIndex = PLAYERID_MUSIC;
        [Utilities AnimView:PartyModeButton AnimDuration:0.3 Alpha:1.0 XPos:PARTYBUTTON_PADDING_LEFT];
    }
    else if (currentPlaylistID == PLAYERID_VIDEO) {
        playlistSegmentedControl.selectedSegmentIndex = PLAYERID_VIDEO;
        [Utilities AnimView:PartyModeButton AnimDuration:0.3 Alpha:0.0 XPos:-PartyModeButton.frame.size.width];
    }
    else if (currentPlaylistID == PLAYERID_PICTURES) {
        playlistSegmentedControl.selectedSegmentIndex = PLAYERID_PICTURES;
        [Utilities AnimView:PartyModeButton AnimDuration:0.3 Alpha:0.0 XPos:-PartyModeButton.frame.size.width];
    }
    editTableButton.hidden = currentPlaylistID == PLAYERID_PICTURES;
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
                                         @"playlistid": @(currentPlaylistID)}
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
               if (error == nil && methodError == nil) {
                   if ([methodResult isKindOfClass:[NSDictionary class]]) {
                       NSArray *playlistItems = methodResult[@"items"];
                       if (playlistItems.count == 0) {
                           [Utilities alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
                           editTableButton.enabled = NO;
                           editTableButton.selected = NO;
                       }
                       else {
                           [Utilities alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
                           editTableButton.enabled = YES;
                       }
                       NSString *serverURL = [Utilities getImageServerURL];
                       int runtimeInMinute = [Utilities getSec2Min:YES];
                       
                       [playlistData removeAllObjects];
                       for (NSDictionary *item in playlistItems) {
                           NSString *idItem = [Utilities getStringFromItem:item[@"id"]];
                           NSString *label = [Utilities getStringFromItem:item[@"label"]];
                           NSString *title = [Utilities getStringFromItem:item[@"title"]];
                           NSString *artist = [Utilities getStringFromItem:item[@"artist"]];
                           NSString *album = [Utilities getStringFromItem:item[@"album"]];
                           NSString *runtime = [Utilities getTimeFromItem:item[@"runtime"] sec2min:runtimeInMinute];
                           NSString *showtitle = [Utilities getStringFromItem:item[@"showtitle"]];
                           NSString *season = [Utilities getStringFromItem:item[@"season"]];
                           NSString *episode = [Utilities getStringFromItem:item[@"episode"]];
                           NSString *type = [Utilities getStringFromItem:item[@"type"]];
                           NSString *artistid = [Utilities getStringFromItem:item[@"artistid"]];
                           NSString *albumid = [Utilities getStringFromItem:item[@"albumid"]];
                           NSString *movieid = [Utilities getStringFromItem:item[@"id"]];
                           NSString *channel = [Utilities getStringFromItem:item[@"channel"]];
                           NSString *genre = [Utilities getStringFromItem:item[@"genre"]];
                           NSString *durationTime = @"";
                           if ([item[@"duration"] isKindOfClass:[NSNumber class]]) {
                               durationTime = [Utilities convertTimeFromSeconds:item[@"duration"]];
                           }
                           NSString *thumbnailPath = [self getNowPlayingThumbnailPath:item];
                           NSString *stringURL = [Utilities formatStringURL:thumbnailPath serverURL:serverURL];
                           NSNumber *tvshowid = @([item[@"tvshowid"] longValue]);
                           NSString *file = [Utilities getStringFromItem:item[@"file"]];
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
                       [self showPlaylistTableAnimated:animTable];
                   }
               }
               else {
                   [self showPlaylistTableAnimated:animTable];
               }
           }];
}

- (void)updatePlaylistProgressbar:(float)percentage actual:(NSString*)actualTime {
    NSIndexPath *selection = [playlistTableView indexPathForSelectedRow];
    if (!selection) {
        return;
    }
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
    UILabel *playlistActualTime = (UILabel*)[cell viewWithTag:XIB_PLAYLIST_CELL_ACTUALTIME];
    playlistActualTime.text = actualTime;
    UIImageView *playlistActualBar = (UIImageView*)[cell viewWithTag:XIB_PLAYLIST_CELL_PROGRESSBAR];
    CGFloat newx = MAX(MAX_CELLBAR_WIDTH * percentage / 100.0, 1.0);
    [self resizeCellBar:newx image:playlistActualBar];
    [self setPlaylistCellProgressBar:cell hidden:NO];
}

- (void)deselectPlaylistItem {
    NSIndexPath *selection = [playlistTableView indexPathForSelectedRow];
    if (!selection) {
        return;
    }
    [playlistTableView deselectRowAtIndexPath:selection animated:YES];
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
    [self setPlaylistCellProgressBar:cell hidden:YES];
}

- (void)showPlaylistTableAnimated:(BOOL)animated {
    if (playlistData.count == 0) {
        [Utilities alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
        [playlistTableView reloadData];
    }
    else {
        if (animated) {
            // 1. Fade out the playlist
            [UIView animateWithDuration:0.1
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                playlistTableView.alpha = 0.0;
            }
                             completion:^(BOOL finished) {
                // 2. Then reload the playlist data
                [playlistTableView reloadData];
                if (musicPartyMode && currentPlaylistID == PLAYERID_MUSIC) {
                    [playlistTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
                }
                [UIView animateWithDuration:0.2
                                      delay:0.0
                                    options:UIViewAnimationOptionCurveEaseInOut
                                 animations:^{
                    // 3. Then fade in again
                    playlistTableView.alpha = 1.0;
                }
                                 completion:nil];
            }];
        }
        else {
            [playlistTableView reloadData];
            if (musicPartyMode && currentPlaylistID == PLAYERID_MUSIC) {
                [playlistTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            }
        }
    }
    
    [self notifyChangeForPlaylistHeader];
    [activityIndicatorView stopAnimating];
    lastSelected = SELECTED_NONE;
}

- (void)SimpleAction:(NSString*)action params:(NSDictionary*)parameters reloadPlaylist:(BOOL)reload startProgressBar:(BOOL)progressBar {
    [[Utilities getJsonRPC] callMethod:action withParameters:parameters onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil) {
            if (reload) {
                [self createPlaylistAnimated:YES];
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
        [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollOnScreen" object: nil];
        ShowInfoViewController *iPadShowViewController = [[ShowInfoViewController alloc] initWithNibName:@"ShowInfoViewController" withItem:item withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
        [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:iPadShowViewController invokeByController:self isStackStartView:YES];
        [AppDelegate.instance.windowController.stackScrollViewController enablePanGestureRecognizer];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object: nil];
    }
}

- (void)retrieveExtraInfoData:(NSString*)methodToCall parameters:(NSDictionary*)parameters index:(NSIndexPath*)indexPath item:(NSDictionary*)item menuItem:(mainMenu*)menuItem {
    NSDictionary *mainFields = menuItem.mainFields[choosedTab];
    NSString *itemid = mainFields[@"row6"] ?: @"";
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
    UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView*)[cell viewWithTag:XIB_PLAYLIST_CELL_ACTIVTYINDICATOR];
    id object;
    if (AppDelegate.instance.serverVersion > 11 && [methodToCall isEqualToString:@"AudioLibrary.GetArtistDetails"]) {
        // WORKAROUND due to the lack of the artistid with Playlist.GetItems
        methodToCall = @"AudioLibrary.GetArtists";
        object = @{@"songid": @([item[@"idItem"] intValue])};
        itemid = @"filter";
    }
    else {
        object = @([item[itemid] intValue]);
    }
    if (!object) {
        return; // something goes wrong
    }
    [activityIndicator startAnimating];
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
    [[Utilities getJsonRPC]
     callMethod:methodToCall
     withParameters:newParameters
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
         [activityIndicator stopAnimating];
         if (error == nil && methodError == nil) {
             if ([methodResult isKindOfClass:[NSDictionary class]]) {
                 NSDictionary *itemExtraDict;
                 if (AppDelegate.instance.serverVersion > 11 && [methodToCall isEqualToString:@"AudioLibrary.GetArtists"]) {
                     // WORKAROUND due to the lack of the artistid with Playlist.GetItems
                     NSString *itemid_extra_info = @"artists";
                     if ([methodResult[itemid_extra_info] count]) {
                         itemExtraDict = methodResult[itemid_extra_info][0];
                     }
                 }
                 else {
                     NSString *itemid_extra_info = mainFields[@"itemid_extra_info"] ?: @"";
                     itemExtraDict = methodResult[itemid_extra_info];
                 }
                 if (!itemExtraDict || ![itemExtraDict isKindOfClass:[NSDictionary class]]) {
                     [self somethingGoesWrong:LOCALIZED_STR(@"Details not found")];
                     return;
                 }
                 NSString *serverURL = [Utilities getImageServerURL];
                 int runtimeInMinute = [Utilities getSec2Min:YES];

                 NSString *label = [Utilities getStringFromItem:itemExtraDict[mainFields[@"row1"]]];
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
                 if (!stringURL.length) {
                     stringURL = [Utilities getItemIconFromDictionary:itemExtraDict];
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
                  @([itemExtraDict[mainFields[@"row9"]] longValue]), mainFields[@"row9"],
                  itemExtraDict[mainFields[@"row10"]], mainFields[@"row10"],
                  row11, mainFields[@"row11"],
                  itemExtraDict[mainFields[@"row12"]], mainFields[@"row12"],
                  itemExtraDict[mainFields[@"row13"]], mainFields[@"row13"],
                  itemExtraDict[mainFields[@"row14"]], mainFields[@"row14"],
                  itemExtraDict[mainFields[@"row15"]], mainFields[@"row15"],
                  itemExtraDict[mainFields[@"row16"]], mainFields[@"row16"],
                  itemExtraDict[mainFields[@"row17"]], mainFields[@"row17"],
                  itemExtraDict[mainFields[@"row18"]], mainFields[@"row18"],
                  itemExtraDict[mainFields[@"row19"]], mainFields[@"row19"],
                  itemExtraDict[mainFields[@"row20"]], mainFields[@"row20"],
                  nil];
                 [self displayInfoView:newItem];
             }
         }
         else {
             [self somethingGoesWrong:LOCALIZED_STR(@"Details not found")];
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
        animationOptionTransition = UIViewAnimationOptionTransitionCrossDissolve;
        startFlipDemo = NO;
    }
    UIImage *buttonImage;
    if (nowPlayingView.hidden && !demo) {
        if (thumbnailView.image.size.width) {
            UIImage *image = [self enableJewelCases] ? [self imageWithBorderFromImage:thumbnailView.image] : thumbnailView.image;
            buttonImage = [self resizeToolbarThumb:image];
        }
        if (!buttonImage.size.width) {
            buttonImage = [self resizeToolbarThumb:[UIImage imageNamed:@"st_nowplaying_small"]];
        }
    }
    else {
        buttonImage = [UIImage imageNamed:@"now_playing_playlist"];
    }
    [UIView transitionWithView:button
                      duration:TRANSITION_TIME
                       options:UIViewAnimationOptionCurveEaseOut | animationOptionTransition
                    animations:^{
        // Animate transition to new button image
        [button setImage:buttonImage forState:UIControlStateNormal];
        [button setImage:buttonImage forState:UIControlStateHighlighted];
        [button setImage:buttonImage forState:UIControlStateSelected];
                     } 
                     completion:^(BOOL finished) {}
    ];
}

- (void)animViews {
    __block CGFloat playtoolbarAlpha = 1.0;
    if (!nowPlayingView.hidden) {
        transitionFromView = nowPlayingView;
        transitionToView = playlistView;
        self.navigationItem.title = [self getPlaylistHeaderLabel];
        self.navigationItem.titleView.hidden = YES;
        animationOptionTransition = UIViewAnimationOptionTransitionCrossDissolve;
        playtoolbarAlpha = 1.0;
    }
    else {
        transitionFromView = playlistView;
        transitionToView = nowPlayingView;
        self.navigationItem.title = LOCALIZED_STR(@"Now Playing");
        self.navigationItem.titleView.hidden = YES;
        animationOptionTransition = UIViewAnimationOptionTransitionCrossDissolve;
        playtoolbarAlpha = 0.0;
    }
    
    [UIView transitionWithView:transitionView
                      duration:TRANSITION_TIME
                       options:UIViewAnimationOptionCurveEaseOut | animationOptionTransition
                    animations:^{
        self.slidingViewController.underRightViewController.view.hidden = YES;
        self.slidingViewController.underLeftViewController.view.hidden = YES;
        transitionFromView.hidden = YES;
        transitionToView.hidden = NO;
        playlistActionView.alpha = playtoolbarAlpha;
        self.navigationItem.titleView.hidden = NO;
                     }
                     completion:^(BOOL finished) {
        self.slidingViewController.underRightViewController.view.hidden = NO;
        self.slidingViewController.underLeftViewController.view.hidden = NO;
    }];
    [self flipAnimButton:playlistButton demo:NO];
}

#pragma mark - bottom toolbar

- (IBAction)startVibrate:(id)sender {
    NSString *action;
    NSDictionary *params;
    switch ([sender tag]) {
        case TAG_ID_PREVIOUS:
            if (AppDelegate.instance.serverVersion > 11) {
                action = @"Player.GoTo";
                params = @{@"to": @"previous"};
                [self playbackAction:action params:params];
            }
            else {
                action = @"Player.GoPrevious";
                params = nil;
                [self playbackAction:action params:nil];
            }
            ProgressSlider.value = 0;
            break;
            
        case TAG_ID_PLAYPAUSE:
            action = @"Player.PlayPause";
            params = nil;
            [self playbackAction:action params:nil];
            break;
            
        case TAG_ID_STOP:
            action = @"Player.Stop";
            params = nil;
            [self playbackAction:action params:nil];
            storeSelection = nil;
            break;
            
        case TAG_ID_NEXT:
            if (AppDelegate.instance.serverVersion > 11) {
                action = @"Player.GoTo";
                params = @{@"to": @"next"};
                [self playbackAction:action params:params];
            }
            else {
                action = @"Player.GoNext";
                params = nil;
                [self playbackAction:action params:nil];
            }
            break;
            
        case TAG_ID_TOGGLE:
            if (IS_IPHONE) {
                [self animViews];
            }
            else {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"NowPlayingFullscreenToggle" object:nil];
            }
            break;
            
        case TAG_SEEK_BACKWARD:
            action = @"Player.Seek";
            params = [Utilities buildPlayerSeekStepParams:@"smallbackward"];
            [self playbackAction:action params:params];
            break;
            
        case TAG_SEEK_FORWARD:
            action = @"Player.Seek";
            params = [Utilities buildPlayerSeekStepParams:@"smallforward"];
            [self playbackAction:action params:params];
            break;
                    
        default:
            break;
    }
}

- (void)updateInfo {
    [self playbackInfo];
}

- (void)toggleSongDetails {
    if ((nothingIsPlaying && songDetailsView.alpha == 0.0) || isRemotePlayer) {
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
    
    // Next shuffle status
    BOOL newShuffleStatus = !shuffled;
    
    // Send the command to Kodi
    if (AppDelegate.instance.serverVersion > 11) {
        [self SimpleAction:@"Player.SetShuffle" params:@{@"playerid": @(currentPlayerID), @"shuffle": @"toggle"} reloadPlaylist:YES startProgressBar:NO];
    }
    else {
        NSString *shuffleCommand = newShuffleStatus ? @"Player.Shuffle" : @"Player.UnShuffle";
        [self SimpleAction:shuffleCommand params:@{@"playerid": @(currentPlayerID)} reloadPlaylist:YES startProgressBar:NO];
    }
    
    // Update the button status
    [self updateShuffleButton:newShuffleStatus];
}

- (IBAction)changeRepeat:(id)sender {
    repeatButton.highlighted = YES;
    [self performSelector:@selector(toggleHighlight:) withObject:repeatButton afterDelay:.1];
    
    // Gather the next repeat status
    NSString *newRepeatStatus = @"all";
    if ([repeatStatus isEqualToString:@"off"]) {
        newRepeatStatus = @"all";
    }
    else if ([repeatStatus isEqualToString:@"all"]) {
        newRepeatStatus = @"one";
    }
    else if ([repeatStatus isEqualToString:@"one"]) {
        newRepeatStatus = @"off";
    }
    
    // Send the command to Kodi
    if (AppDelegate.instance.serverVersion > 11) {
        [self SimpleAction:@"Player.SetRepeat" params:@{@"playerid": @(currentPlayerID), @"repeat": @"cycle"} reloadPlaylist:NO startProgressBar:NO];
    }
    else {
        [self SimpleAction:@"Player.Repeat" params:@{@"playerid": @(currentPlayerID), @"state": newRepeatStatus} reloadPlaylist:NO startProgressBar:NO];
    }
    
    // Update the button status
    [self updateRepeatButton:newRepeatStatus];
}

#pragma mark - Touch Events & Gestures

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch *touch = [touches anyObject];
    if (songDetailsView.alpha == 0) {
        // songDetailsView is not shown
        CGPoint locationPoint = [touch locationInView:nowPlayingView];
        CGPoint viewPoint = [jewelView convertPoint:locationPoint fromView:nowPlayingView];
        BOOL iPadStackActive = AppDelegate.instance.windowController.stackScrollViewController.viewControllersStack.count > 0;
        if ([jewelView pointInside:viewPoint withEvent:event] && !iPadStackActive) {
            // We have no iPad stack shown amd jewelView was touched, bring up songDetailsView
            [self toggleSongDetails];
        }
    }
    else {
        // songDetailsView is shown, process touches
        CGPoint locationPoint = [touch locationInView:songDetailsView];
        CGPoint viewPointImage = [itemLogoImage convertPoint:locationPoint fromView:songDetailsView];
        CGPoint viewPointClose = [closeButton convertPoint:locationPoint fromView:songDetailsView];
        if ([itemLogoImage pointInside:viewPointImage withEvent:event] && itemLogoImage.image != nil) {
            [self updateCurrentLogo];
        }
        else if ([closeButton pointInside:viewPointClose withEvent:event] && !closeButton.hidden) {
            [self toggleSongDetails];
        }
        else if (![songDetailsView pointInside:locationPoint withEvent:event] && !closeButton.hidden) {
            // touches outside of songDetailsView close it
            [self toggleSongDetails];
        }
    }
}

- (void)updateCurrentLogo {
    NSString *serverURL = [Utilities getImageServerURL];
    if ([storeCurrentLogo isEqualToString:storeClearart]) {
        storeCurrentLogo = storeClearlogo;
    }
    else {
        storeCurrentLogo = storeClearart;
    }
    if (storeCurrentLogo.length) {
        NSString *stringURL = [Utilities formatStringURL:storeCurrentLogo serverURL:serverURL];
        [itemLogoImage sd_setImageWithURL:[NSURL URLWithString:stringURL]
                         placeholderImage:itemLogoImage.image];
    }
}

- (IBAction)buttonToggleItemInfo:(id)sender {
    [self toggleSongDetails];
}

- (void)showClearPlaylistAlert {
    if (!playlistView.hidden && self.view.superview != nil) {
        NSString *message;
        switch (currentPlaylistID) {
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
        UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *clearButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Clear Playlist") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self clearPlaylist:currentPlaylistID];
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
            selectedIndexPath = indexPath;
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
                    NSString *tvshowText = [Utilities formatTVShowStringForSeasonTrailing:item[@"season"] episode:item[@"episode"] title:item[@"showtitle"]];
                    title = [NSString stringWithFormat:@"%@%@%@", item[@"label"], tvshowText.length ? @"\n" : @"", tvshowText];
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
                [self playbackAction:@"Player.SetSpeed" params:@{@"speed": @"decrement"}];
                break;
                
            case TAG_SEEK_FORWARD:// FORWARD BUTTON - INCREASE PLAYBACK SPEED
                [self playbackAction:@"Player.SetSpeed" params:@{@"speed": @"increment"}];
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
    [self SimpleAction:@"Player.Seek" params:[Utilities buildPlayerSeekPercentageParams:currentPlayerID percentage:ProgressSlider.value] reloadPlaylist:NO startProgressBar:YES];
    [Utilities alphaView:scrabbingView AnimDuration:0.3 Alpha:0.0];
}

- (IBAction)updateCurrentTime:(id)sender {
    if (!updateProgressBar && !nothingIsPlaying) {
        int selectedTimeInSeconds = (int)((ProgressSlider.value / 100) * totalSeconds);
        int hours = selectedTimeInSeconds / 3600;
        int minutes = (selectedTimeInSeconds / 60) % 60;
        int seconds = selectedTimeInSeconds % 60;
        NSString *selectedTime = HMS_TO_STRING(hours, minutes, seconds);
        currentTime.text = selectedTime;
        scrabbingRate.text = LOCALIZED_STR(([NSString stringWithFormat:@"Scrubbing %@", @(ProgressSlider.scrubbingSpeed)]));
    }
}

# pragma mark - Action Sheet

- (void)showActionNowPlaying:(NSMutableArray*)sheetActions title:(NSString*)title point:(CGPoint)origin {
    if (sheetActions.count) {
        UIAlertController *actionView = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *action_cancel = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
        
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
            popPresenter.sourceRect = CGRectMake(origin.x, origin.y, 1, 1);
        }
        [self presentViewController:actionView animated:YES completion:nil];
    }
}

- (void)actionSheetHandler:(NSString*)actiontitle {
    NSDictionary *item = nil;
    NSInteger numPlaylistEntries = playlistData.count;
    if (selectedIndexPath.row < numPlaylistEntries) {
        item = playlistData[selectedIndexPath.row];
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
            if ([mainFields[@"row6"] isEqualToString:@"artistid"]) {
                // WORKAROUND due to the lack of the artistid with Playlist.GetItems
                NSString *artistFrodoWorkaround = [NSString stringWithFormat:@"%@", [item[@"artist"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                obj = @{@"artist": artistFrodoWorkaround};
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
                                       @([parameters[@"enableCollectionView"] boolValue]), @"enableCollectionView",
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
            [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollOnScreen" object: nil];
            DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:menuItem.subItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
            [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:YES];
            [AppDelegate.instance.windowController.stackScrollViewController enablePanGestureRecognizer];
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object: nil];
        }
    }
    else {
        [self showInfo:item menuItem:menuItem indexPath:selectedIndexPath];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"playlistCellIdentifier"];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"playlistCellView" owner:self options:nil];
        cell = nib[0];
        UILabel *mainLabel = (UILabel*)[cell viewWithTag:XIB_PLAYLIST_CELL_MAINTITLE];
        UILabel *subLabel = (UILabel*)[cell viewWithTag:XIB_PLAYLIST_CELL_SUBTITLE];
        UILabel *cornerLabel = (UILabel*)[cell viewWithTag:XIB_PLAYLIST_CELL_CORNERTITLE];
        
        mainLabel.highlightedTextColor = [Utilities get1stLabelColor];
        subLabel.highlightedTextColor = [Utilities get2ndLabelColor];
        cornerLabel.highlightedTextColor = [Utilities get2ndLabelColor];
        
        mainLabel.textColor = [Utilities get1stLabelColor];
        subLabel.textColor = [Utilities get2ndLabelColor];
        cornerLabel.textColor = [Utilities get2ndLabelColor];
        
        tableView.separatorInset = UIEdgeInsetsMake(0, CGRectGetMinX(mainLabel.frame), 0, 0);
    }
    NSDictionary *item = (playlistData.count > indexPath.row) ? playlistData[indexPath.row] : nil;
    UIImageView *thumb = (UIImageView*)[cell viewWithTag:XIB_PLAYLIST_CELL_COVER];
    
    UILabel *mainLabel = (UILabel*)[cell viewWithTag:XIB_PLAYLIST_CELL_MAINTITLE];
    UILabel *subLabel = (UILabel*)[cell viewWithTag:XIB_PLAYLIST_CELL_SUBTITLE];
    UILabel *cornerLabel = (UILabel*)[cell viewWithTag:XIB_PLAYLIST_CELL_CORNERTITLE];
    
    NSString *title = item[@"title"];
    NSString *label = item[@"label"];
    mainLabel.text = title.length ? title : label;
    subLabel.text = @"";
    if ([item[@"type"] isEqualToString:@"episode"]) {
        mainLabel.text = label;
        subLabel.text = [Utilities formatTVShowStringForSeasonTrailing:item[@"season"] episode:item[@"episode"] title:item[@"showtitle"]];
    }
    else if ([item[@"type"] isEqualToString:@"song"] ||
             [item[@"type"] isEqualToString:@"musicvideo"]) {
        NSString *album = item[@"album"];
        NSString *artist = item[@"artist"];
        NSString *dash = album.length && artist.length ? @" - " : @"";
        subLabel.text = [NSString stringWithFormat:@"%@%@%@", album, dash, artist];
    }
    else if ([item[@"type"] isEqualToString:@"movie"]) {
        subLabel.text = item[@"genre"];
    }
    else if ([item[@"type"] isEqualToString:@"recording"]) {
        subLabel.text = item[@"channel"];
    }
    UIImage *defaultThumb;
    switch (currentPlaylistID) {
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
    [thumb sd_setImageWithURL:[NSURL URLWithString:stringURL]
             placeholderImage:defaultThumb
                      options:SDWebImageScaleToNativeSize];
    [Utilities applyRoundedEdgesView:thumb drawBorder:YES];
    BOOL active = indexPath.row == lastSelected;
    [self setPlaylistCellProgressBar:cell hidden:!active];
    
    return cell;
}

- (void)tableView:(UITableView*)tableView didDeselectRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
    storeSelection = nil;
    [self setPlaylistCellProgressBar:cell hidden:YES];
}

- (NSIndexPath*)tableView:(UITableView*)tableView willSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    return isRemotePlayer ? nil : indexPath;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
    UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView*)[cell viewWithTag:XIB_PLAYLIST_CELL_ACTIVTYINDICATOR];
    storeSelection = nil;
    [activityIndicator startAnimating];
    [[Utilities getJsonRPC]
     callMethod:@"Player.Open" 
     withParameters:@{@"item": @{@"position": @(indexPath.row), @"playlistid": @(currentPlaylistID)}}
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
         if (error == nil && methodError == nil) {
             storedItemID = SELECTED_NONE;
         }
         [activityIndicator stopAnimating];
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
    if (sourceIndexPath.row >= playlistData.count ||
        sourceIndexPath.row == destinationIndexPath.row) {
        return;
    }
    NSDictionary *objSource = playlistData[sourceIndexPath.row];
    NSDictionary *itemToMove;
    
    int idItem = [objSource[@"idItem"] intValue];
    if (idItem) {
        itemToMove = @{[NSString stringWithFormat:@"%@id", objSource[@"type"]]: @(idItem)};
    }
    else {
        itemToMove = [NSDictionary dictionaryWithObjectsAndKeys:
                      objSource[@"file"], @"file",
                      nil];
    }
    
    NSString *actionRemove = @"Playlist.Remove";
    NSDictionary *paramsRemove = @{
        @"playlistid": @(currentPlaylistID),
        @"position": @(sourceIndexPath.row),
    };
    NSString *actionInsert = @"Playlist.Insert";
    NSDictionary *paramsInsert = @{
        @"playlistid": @(currentPlaylistID),
        @"item": itemToMove,
        @"position": @(destinationIndexPath.row),
    };
    [[Utilities getJsonRPC] callMethod:actionRemove withParameters:paramsRemove onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
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
                storeSelection = [NSIndexPath indexPathForRow:storeSelection.row + 1 inSection:storeSelection.section];
            }
            else if (sourceIndexPath.row < storeSelection.row && destinationIndexPath.row >= storeSelection.row) {
                storeSelection = [NSIndexPath indexPathForRow:storeSelection.row - 1 inSection:storeSelection.section];
            }
            [playlistTableView reloadData];
        }
        else {
            [playlistTableView reloadData];
            [playlistTableView selectRowAtIndexPath:storeSelection animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        }
    }];
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *actionRemove = @"Playlist.Remove";
        NSDictionary *paramsRemove = @{
            @"playlistid": @(currentPlaylistID),
            @"position": @(indexPath.row),
        };
        [[Utilities getJsonRPC] callMethod:actionRemove withParameters:paramsRemove onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
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
                if (storeSelection && indexPath.row<storeSelection.row) {
                    storeSelection = [NSIndexPath indexPathForRow:storeSelection.row - 1 inSection:storeSelection.section];
                }
            }
            else {
                [playlistTableView reloadData];
                [playlistTableView selectRowAtIndexPath:storeSelection animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            }
        }];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)aTableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView*)tableView didEndEditingRowAtIndexPath:(NSIndexPath*)indexPath {
    [self createPlaylistAnimated:YES];
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
    if (currentPlaylistID == PLAYERID_PICTURES) {
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

- (void)setNowPlayingDimensionIPhone:(CGFloat)width height:(CGFloat)height {
    CGFloat scaleX = width / BOTTOMVIEW_WIDTH;
    CGFloat scaleY = height / BOTTOMVIEW_HEIGHT;
    CGFloat scale = MIN(scaleX, scaleY);
    
    [self setFontSizes:scale];
    
    // Get padding and reserved height (= top padding, bottom padding and tool bar)
    CGFloat topBarHeight = [Utilities getTopPaddingWithNavBar:self.navigationController];
    CGFloat reservedHeight = [Utilities getBottomPadding] + topBarHeight + CGRectGetHeight(playlistToolbarView.frame);
    
    // Set correct size for background image and views
    CGRect frame = transitionView.frame;
    frame.size.height = GET_MAINSCREEN_HEIGHT;
    frame.origin.y = -topBarHeight;
    transitionView.frame = frame;
    
    frame = nowPlayingView.frame;
    frame.size.height = GET_MAINSCREEN_HEIGHT - reservedHeight;
    frame.origin.y = topBarHeight;
    nowPlayingView.frame = frame;
    
    frame = playlistView.frame;
    frame.size.height = GET_MAINSCREEN_HEIGHT - reservedHeight;
    frame.origin.y = topBarHeight;
    playlistView.frame = frame;
    
    CGFloat newWidth = floor(BOTTOMVIEW_WIDTH * scale);
    CGFloat newHeight = floor(BOTTOMVIEW_HEIGHT * scale);
    
    BottomView.frame = CGRectMake((nowPlayingView.frame.size.width - newWidth) / 2,
                                  nowPlayingView.frame.size.height - newHeight,
                                  newWidth,
                                  newHeight);
    
    jewelView.frame = CGRectMake(jewelView.frame.origin.x,
                                 jewelView.frame.origin.y,
                                 jewelView.frame.size.width,
                                 CGRectGetMinY(BottomView.frame) - jewelView.frame.origin.y);
    
    // Set position for shuffle and repeat
    UIButton *buttonStop = [playlistToolbarView viewWithTag:TAG_ID_STOP];
    UIButton *buttonToggle = [playlistToolbarView viewWithTag:TAG_ID_TOGGLE];
    shuffleButton.center = CGPointMake(buttonStop.center.x, shuffleButton.center.y);
    repeatButton.center  = CGPointMake(buttonToggle.center.x, repeatButton.center.y);
    
    // Blurred cover uses the transtion view's dimensions
    fullscreenCover.frame = visualEffectView.frame = transitionView.frame;
}

- (void)setNowPlayingDimension:(CGFloat)width height:(CGFloat)height YPOS:(CGFloat)YPOS fullscreen:(BOOL)isFullscreen {
    CGRect frame;
    
    // Maximum allowed height excludes status bar, toolbar and safe area
    CGFloat bottomPadding = [Utilities getBottomPadding];
    CGFloat statusBar = [Utilities getTopPadding];
    CGFloat maxheight = height - bottomPadding - statusBar - TOOLBAR_HEIGHT;
    
    CGFloat viewOriginX = isFullscreen ? 0 : PAD_MENU_TABLE_WIDTH + IPAD_MENU_SEPARATOR_WIDTH;
    CGFloat viewOriginY = YPOS;
    CGFloat viewWidth = isFullscreen ? width : width - (PAD_MENU_TABLE_WIDTH + IPAD_MENU_SEPARATOR_WIDTH);
    CGFloat viewHeight = maxheight;
    nowPlayingView.frame = CGRectMake(viewOriginX, viewOriginY, viewWidth, viewHeight);
    
    CGFloat scaleX = MIN(nowPlayingView.frame.size.width, PAD_REMOTE_WIDTH) / BOTTOMVIEW_WIDTH;
    CGFloat scaleY = nowPlayingView.frame.size.height / BOTTOMVIEW_HEIGHT;
    CGFloat scale = MIN(scaleX, scaleY);
    
    [self setFontSizes:scale];
    
    CGFloat newWidth = (GET_MAINSCREEN_WIDTH - PAD_MENU_TABLE_WIDTH) - 2 * COVERVIEW_PADDING;
    CGFloat newHeight = floor(BOTTOMVIEW_HEIGHT * scale);
    viewOriginX = (nowPlayingView.frame.size.width - newWidth) / 2;
    viewOriginX = isFullscreen ? viewOriginX : PAD_MENU_TABLE_WIDTH + viewOriginX;
    BottomView.frame = CGRectMake(viewOriginX,
                                  nowPlayingView.frame.size.height - newHeight + statusBar - CGRectGetHeight(playlistToolbarView.frame),
                                  newWidth,
                                  newHeight);
    
    jewelView.frame = CGRectMake(jewelView.frame.origin.x,
                                 jewelView.frame.origin.y,
                                 jewelView.frame.size.width,
                                 CGRectGetMinY(BottomView.frame) - jewelView.frame.origin.y - statusBar);
    
    frame = playlistToolbarView.frame;
    frame.origin.x = viewOriginX;
    frame.origin.y = CGRectGetMaxY(BottomView.frame);
    frame.size.width = CGRectGetWidth(BottomView.frame);
    playlistToolbarView.frame = frame;
    [self buildIpadPlaylistToolbar];
    
    frame = toolbarBackground.frame;
    frame.size.width = width;
    toolbarBackground.frame = frame;
    
    backgroundImageView.frame = nowPlayingView.frame;
    playlistActionView.alpha = playlistView.alpha = isFullscreen ? 0 : 1;
    
    // Adapt fullscreen toggle button icon to current screen mode
    NSString *imageName = isFullscreen ? @"button_exit_fullscreen" : @"button_fullscreen";
    UIImage *image = [UIImage imageNamed:imageName];
    image = [Utilities colorizeImage:image withColor:UIColor.whiteColor];
    [fullscreenToggleButton setImage:image forState:UIControlStateNormal];
    [fullscreenToggleButton setImage:image forState:UIControlStateHighlighted];
    
    [self setCoverSize:currentType];
}

- (void)buildIpadPlaylistToolbar {
    // Move shuffle/repeat to play control bar
    [playlistToolbarView addSubview:shuffleButton];
    [playlistToolbarView addSubview:repeatButton];
    
    // Align buttons around this center
    CGFloat buttonCenterY = CGRectGetHeight(playlistToolbarView.frame) / 2;
    
    // Define the list of playcontrol buttons (top to down = left to right)
    NSArray *toolbarButtonList = @[
        @{@"buttonTag": @(TAG_SHUFFLE),         @"originY": @(buttonCenterY + SHUFFLE_REPEAT_VERTICAL_PADDING)},
        @{@"buttonTag": @(TAG_ID_STOP),         @"originY": @(buttonCenterY)},
        @{@"buttonTag": @(TAG_ID_PREVIOUS),     @"originY": @(buttonCenterY)},
        @{@"buttonTag": @(TAG_SEEK_BACKWARD),   @"originY": @(buttonCenterY)},
        @{@"buttonTag": @(TAG_ID_PLAYPAUSE),    @"originY": @(buttonCenterY)}, /* this is central button */
        @{@"buttonTag": @(TAG_SEEK_FORWARD),    @"originY": @(buttonCenterY)},
        @{@"buttonTag": @(TAG_ID_NEXT),         @"originY": @(buttonCenterY)},
        @{@"buttonTag": @(TAG_ID_TOGGLE),       @"originY": @(buttonCenterY)},
        @{@"buttonTag": @(TAG_REPEAT),          @"originY": @(buttonCenterY + SHUFFLE_REPEAT_VERTICAL_PADDING)},
    ];
    
    // Calculate start position and distance between all buttons
    CGFloat borderPadding = MAX(CGRectGetWidth(shuffleButton.frame), CGRectGetWidth(repeatButton.frame)) / 2 + SHUFFLE_REPEAT_HORIZONTAL_PADDING;
    CGFloat buttonPadding = (CGRectGetWidth(playlistToolbarView.frame) - 2 * borderPadding) / (toolbarButtonList.count - 1);
    
    // Loop through button list and place them in the toolbar
    CGFloat startX = borderPadding;
    for (NSDictionary *item in toolbarButtonList) {
        UIButton *button = [playlistToolbarView viewWithTag:[item[@"buttonTag"] intValue]];
        button.center = CGPointMake(startX, [item[@"originY"] floatValue]);
        startX += buttonPadding;
    }
}

- (void)setAVCodecFont:(UILabel*)label size:(CGFloat)fontsize {
    label.font = [UIFont boldSystemFontOfSize:fontsize];
    label.numberOfLines = 2;
    label.minimumScaleFactor = FONT_SCALING_DEFAULT;
}

- (void)setFontSizes:(CGFloat)scale {
    albumName.font        = [UIFont systemFontOfSize:floor(16 * scale)];
    songName.font         = [UIFont boldSystemFontOfSize:floor(20 * scale)];
    artistName.font       = [UIFont systemFontOfSize:floor(16 * scale)];
    currentTime.font      = [UIFont systemFontOfSize:floor(14 * scale)];
    duration.font         = [UIFont systemFontOfSize:floor(14 * scale)];
    scrabbingMessage.font = [UIFont systemFontOfSize:floor(11 * scale)];
    scrabbingRate.font    = [UIFont systemFontOfSize:floor(11 * scale)];
    songBitRate.font      = [UIFont systemFontOfSize:floor(14 * scale) weight:UIFontWeightHeavy];
    [self setAVCodecFont:songCodec size:floor(14 * scale)];
    [self setAVCodecFont:songSampleRate size:floor(14 * scale)];
    [self setAVCodecFont:songNumChannels size:floor(14 * scale)];
    descriptionFontSize = floor(12 * scale);
}

- (void)setIphoneInterface {
    CGRect frame = playlistActionView.frame;
    frame.origin.y = CGRectGetMinY(playlistToolbarView.frame) - CGRectGetHeight(playlistActionView.frame);
    playlistActionView.frame = frame;
    playlistActionView.alpha = 0.0;
}

- (void)setIpadInterface {
    playlistToolbarView.alpha = 1.0;
    
    nowPlayingView.hidden = NO;
    playlistView.hidden = NO;
    
    CGRect frame = playlistActionView.frame;
    frame.origin.y = CGRectGetHeight(playlistTableView.frame) - CGRectGetHeight(playlistActionView.frame);
    playlistActionView.frame = frame;
    playlistActionView.alpha = 1.0;
    
    // Prepare iPad fullscreen toggle button
    fullscreenToggleButton = [self.view viewWithTag:TAG_ID_TOGGLE];
    fullscreenToggleButton.showsTouchWhenHighlighted = YES;
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
    CGFloat left_margin = (PAD_MENU_TABLE_WIDTH - SEGMENTCONTROL_WIDTH) / 2;
    if (IS_IPHONE) {
        left_margin = floor(([self currentScreenBoundsDependOnOrientation].size.width - SEGMENTCONTROL_WIDTH) / 2);
    }
    playlistSegmentedControl.frame = CGRectMake(left_margin,
                                                (playlistActionView.frame.size.height - SEGMENTCONTROL_HEIGHT) / 2,
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
        [playlistTableView scrollToRowAtIndexPath:visiblePaths[0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
    switch (segment.selectedSegmentIndex) {
        case PLAYERID_MUSIC:
            currentPlaylistID = PLAYERID_MUSIC;
            break;
            
        case PLAYERID_VIDEO:
            currentPlaylistID = PLAYERID_VIDEO;
            break;
            
        case PLAYERID_PICTURES:
            currentPlaylistID = PLAYERID_PICTURES;
            break;
            
        default:
            NSAssert(NO, @"Unexpected segment selected.");
            break;
    }
    lastSelected = SELECTED_NONE;
    musicPartyMode = NO;
    [self createPlaylistAnimated:YES];
}

#pragma mark - Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (IS_IPHONE) {
        if (self.slidingViewController.panGesture != nil) {
            [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
        }
        if ([self.navigationController.viewControllers indexOfObject:self] == 0) {
            UIImage *menuImg = [UIImage imageNamed:@"button_menu"];
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:menuImg style:UIBarButtonItemStylePlain target:nil action:@selector(revealMenu:)];
        }
        UIImage *remoteImg = [UIImage imageNamed:@"icon_menu_remote"];
        UIImage *powerImg = [UIImage imageNamed:@"icon_power"];
        self.navigationItem.rightBarButtonItems = @[
            [[UIBarButtonItem alloc] initWithImage:remoteImg style:UIBarButtonItemStylePlain target:self action:@selector(showRemote)],
            [[UIBarButtonItem alloc] initWithImage:powerImg style:UIBarButtonItemStylePlain target:self action:@selector(powerControl)]
        ];
        self.slidingViewController.underRightViewController = nil;
        self.slidingViewController.panGesture.delegate = self;
        
        [self setNowPlayingDimensionIPhone:nowPlayingView.frame.size.width
                                    height:nowPlayingView.frame.size.height];
        
        UIView *rootView = IS_IPHONE ? UIApplication.sharedApplication.keyWindow.rootViewController.view : self.view;
        CGFloat deltaY = IS_IPHONE ? UIApplication.sharedApplication.statusBarFrame.size.height : 0;
        messagesView = [[MessagesView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, DEFAULT_MSG_HEIGHT + deltaY) deltaY:deltaY deltaX:0];
        messagesView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [rootView addSubview:messagesView];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnterForeground:)
                                                 name: @"UIApplicationWillEnterForegroundNotification"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleDidEnterBackground:)
                                                 name: @"UIApplicationDidEnterBackgroundNotification"
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
    [updateInfoTimer invalidate];
    [debounceTimer invalidate];
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

- (void)showRemote {
    RemoteController *remote = [[RemoteController alloc] initWithNibName:@"RemoteController" bundle:nil];
    [self.navigationController pushViewController:remote animated:YES];
}

- (void)powerControl {
    if (AppDelegate.instance.obj.serverIP.length == 0) {
        return;
    }
    UIAlertController *actionView = [Utilities createPowerControl:self messageView:messagesView];
    [self presentViewController:actionView animated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
    if (fromItself) {
        [self handleXBMCPlaylistHasChanged:nil];
    }
    [self startNowPlayingUpdates];
    fromItself = NO;
    if (IS_IPHONE) {
        self.slidingViewController.underRightViewController = nil;
        RightMenuViewController *rightMenuViewController = [[RightMenuViewController alloc] initWithNibName:@"RightMenuViewController" bundle:nil];
        rightMenuViewController.rightMenuItems = AppDelegate.instance.nowPlayingMenuItems;
        self.slidingViewController.underRightViewController = rightMenuViewController;
    }
}

- (void)startFlipDemo {
    [self flipAnimButton:playlistButton demo:YES];
}
     
- (void)startNowPlayingUpdates {
    storedItemID = SELECTED_NONE;
    [self playbackInfo];
    updateProgressBar = YES;
    [updateInfoTimer invalidate];
    updateInfoTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATE_INFO_TIMEOUT target:self selector:@selector(updateInfo) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [updateInfoTimer invalidate];
    storedItemID = SELECTED_NONE;
    self.slidingViewController.panGesture.delegate = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)setToolbar {
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
    [editTableButton setTitleColor:UIColor.grayColor forState:UIControlStateDisabled];
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
    itemDescription.selectable = NO;
    itemLogoImage.layer.minificationFilter = kCAFilterTrilinear;
    songCodecImage.layer.minificationFilter = kCAFilterTrilinear;
    songBitRateImage.layer.minificationFilter = kCAFilterTrilinear;
    songSampleRateImage.layer.minificationFilter = kCAFilterTrilinear;
    songNumChanImage.layer.minificationFilter = kCAFilterTrilinear;
    thumbnailView.layer.minificationFilter = kCAFilterTrilinear;
    thumbnailView.layer.magnificationFilter = kCAFilterTrilinear;
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
    [self setToolbar];

    if (bottomPadding > 0) {
        CGRect frame = playlistToolbarView.frame;
        frame.origin.y -= bottomPadding;
        playlistToolbarView.frame = frame;
        
        frame = nowPlayingView.frame;
        frame.size.height -= bottomPadding;
        nowPlayingView.frame = frame;
        
        frame = playlistTableView.frame;
        frame.size.height -= bottomPadding;
        playlistView.frame = frame;
        playlistTableView.frame = frame;
    }
    playlistTableView.contentInset = UIEdgeInsetsMake(0, 0, CGRectGetHeight(playlistActionView.frame), 0);
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // Background of toolbar
    CGFloat bottomBarHeight = playlistToolbarView.frame.size.height + bottomPadding;
    if (IS_IPAD) {
        // iPad needs clear background for the playlist (to show the fanart), but a colored background for the toolbar.
        toolbarBackground = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - bottomBarHeight, self.view.frame.size.width, bottomBarHeight)];
        toolbarBackground.autoresizingMask = playlistToolbarView.autoresizingMask;
        toolbarBackground.backgroundColor = TOOLBAR_TINT_COLOR;
        [self.view insertSubview:toolbarBackground atIndex:1];
        self.view.backgroundColor = UIColor.clearColor;
        backgroundImageView.alpha = 0.0;
    }
    else {
        // Make navigation bar transparent
        if (@available(iOS 13, *)) {
            UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
            [appearance configureWithOpaqueBackground];
            [appearance configureWithTransparentBackground];
            appearance.titleTextAttributes = @{NSForegroundColorAttributeName : UIColor.whiteColor};
            appearance.backgroundColor = UIColor.clearColor;
            self.navigationItem.standardAppearance = appearance;
            self.navigationItem.scrollEdgeAppearance = appearance;
        }
        self.view.backgroundColor = UIColor.clearColor;
    }
    
    ProgressSlider.userInteractionEnabled = NO;
    [ProgressSlider setThumbImage:[UIImage new] forState:UIControlStateNormal];
    [ProgressSlider setThumbImage:[UIImage new] forState:UIControlStateHighlighted];
    ProgressSlider.hidden = YES;
    scrabbingMessage.text = LOCALIZED_STR(@"Slide your finger up to adjust the scrubbing rate.");
    scrabbingRate.text = LOCALIZED_STR(@"Scrubbing 1");
    sheetActions = [NSMutableArray new];
    currentPlaylistID = PLAYERID_UNKNOWN;
    lastSelected = SELECTED_NONE;
    storedItemID = SELECTED_NONE;
    storeSelection = nil;
    if (IS_IPHONE) {
        [self setIphoneInterface];
    }
    else {
        [self setIpadInterface];
    }
    nowPlayingView.hidden = NO;
    playlistView.hidden = IS_IPHONE;
    self.navigationItem.title = LOCALIZED_STR(@"Now Playing");
    if (IS_IPHONE) {
        startFlipDemo = YES;
    }
    playlistData = [NSMutableArray new];
    
    songName.text = @"";
    artistName.text = @"";
    albumName.text = @"";
    duration.text = @"";
    currentTime.text = @"";
    
    // Colors
    self.navigationController.navigationBar.tintColor = ICON_TINT_COLOR;
    ProgressSlider.minimumTrackTintColor = UIColor.lightGrayColor;
    ProgressSlider.maximumTrackTintColor = UIColor.darkGrayColor;
    albumName.textColor = UIColor.lightGrayColor;
    songName.textColor = UIColor.whiteColor;
    artistName.textColor = UIColor.whiteColor;
    currentTime.textColor = UIColor.lightGrayColor;
    duration.textColor = UIColor.lightGrayColor;
    
    // UPnP indicator layout
    upnp.textColor = KODI_BLUE_COLOR;
    upnp.layer.cornerRadius = 4;
    upnp.layer.borderColor = KODI_BLUE_COLOR.CGColor;
    upnp.layer.borderWidth = 1;
    
    // Prepare and add blur effect
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    visualEffectView.effect = blurEffect;
    
    // Add gradient overlay to improve readability of control elements and labels
    UIImageView *overlayGradient = [[UIImageView alloc] initWithFrame:backgroundImageView.frame];
    overlayGradient.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlayGradient.image = [UIImage imageNamed:@"overlay_gradient"];
    overlayGradient.contentMode = UIViewContentModeScaleToFill;
    overlayGradient.alpha = 0.5;
    [visualEffectView.contentView addSubview:overlayGradient];
}

- (void)connectionSuccess:(NSNotification*)note {
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
    [self startNowPlayingUpdates];
}

- (void)handleXBMCPlaylistHasChanged:(NSNotification*)sender {
    // Party mode will cause playlist updates for each new song, if TCP is enabled. Just ignore here and
    // let this be handled by the updatePartyModePlaylist which is called for each new song in Party Mode.
    if (musicPartyMode) {
        return;
    }
    NSDictionary *theData = sender.userInfo;
    if ([theData isKindOfClass:[NSDictionary class]]) {
        currentPlaylistID = [theData[@"params"][@"data"][@"playlistid"] intValue];
    }
    lastSelected = SELECTED_NONE;
    storedItemID = SELECTED_NONE;
    storeSelection = nil;
    lastThumbnail = @"";
    
    // Only clear and reload the playlist after debouncing timeout. This reduces load and flickering, if multiple update notifications
    // arrive in a short time frame -- like for picture slideshows.
    NSTimeInterval debounceInterval = currentPlaylistID != PLAYERID_PICTURES ? PLAYLIST_DEBOUNCE_TIMEOUT : PLAYLIST_DEBOUNCE_TIMEOUT_MAX;
    [debounceTimer invalidate];
    debounceTimer = [NSTimer scheduledTimerWithTimeInterval:debounceInterval
                                                     target:self
                                                   selector:@selector(clearAndReloadPlaylist)
                                                   userInfo:nil
                                                    repeats:NO];
}

- (void)clearAndReloadPlaylist {
    [self createPlaylistAnimated:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [updateInfoTimer invalidate];
    [debounceTimer invalidate];
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
