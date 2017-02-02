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
#import "VolumeSliderView.h"
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
@synthesize detailViewController;
@synthesize shuffleButton;
@synthesize repeatButton;
@synthesize itemLogoImage;
@synthesize songDetailsView;
@synthesize ProgressSlider;
@synthesize showInfoViewController;
@synthesize scrabbingView;
@synthesize itemDescription;
//@synthesize presentedFromNavigation;

float startx=14;
float barwidth=280;
float cellBarWidth=45;
#define SHOW_ONLY_VISIBLE_THUMBNAIL_START_AT 50

- (void)setDetailItem:(id)newDetailItem{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        // Update the view.
        [self configureView];
    }
}

- (void)configureView{
    // Update the user interface for the detail item.
    if (self.detailItem) {
//        CGRect frame = CGRectMake(0, 0, 320, 44);
//        viewTitle = [[UILabel alloc] initWithFrame:frame];
//        viewTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//        viewTitle.backgroundColor = [UIColor clearColor];
//        viewTitle.font = [UIFont boldSystemFontOfSize:18];
//        viewTitle.shadowColor = [UIColor colorWithWhite:0.0 alpha:.5];
//        viewTitle.textAlignment = UITextAlignmentCenter;
//        viewTitle.textColor = [UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1];
//        viewTitle.text = NSLocalizedString(@"Now Playing", nil);
//        [viewTitle sizeToFit];
//        self.navigationItem.titleView = viewTitle;
        self.navigationItem.title = NSLocalizedString(@"Now Playing", nil); // DA SISTEMARE COME PARAMETRO
        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromRight:)];
        rightSwipe.numberOfTouchesRequired = 1;
        rightSwipe.cancelsTouchesInView=NO;
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:rightSwipe];
        
        UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromLeft:)];
        leftSwipe.numberOfTouchesRequired = 1;
        leftSwipe.cancelsTouchesInView=NO;
        leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.view addGestureRecognizer:leftSwipe];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}



# pragma mark - toolbar management

-(void)toggleViewToolBar:(UIView*)view AnimDuration:(float)seconds Alpha:(float)alphavalue YPos:(int)Y forceHide:(BOOL)hide {
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:seconds];
    int actualPosY=view.frame.origin.y;
    if (actualPosY==Y || hide){
        Y=-view.frame.size.height;
    }
    view.alpha = alphavalue;
	CGRect frame;
	frame = [view frame];
	frame.origin.y = Y;
    view.frame = frame;
    [UIView commitAnimations];
}

- (void)toggleVolume{
    [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE];
}

-(IBAction)changePlaylist:(id)sender{
    if ([sender tag]==101 && seg_music.selected) return;
    if ([sender tag]==102 && seg_video.selected) return;
    [self editTable:nil forceClose:YES];
    if ([playlistData count] && (playlistTableView.dragging == YES || playlistTableView.decelerating == YES)){
        NSArray *visiblePaths = [playlistTableView indexPathsForVisibleRows];
        [playlistTableView  scrollToRowAtIndexPath:[visiblePaths objectAtIndex:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    if (seg_music.selected){
        lastSelected=-1;
        seg_music.selected=NO;
        seg_video.selected=YES;
        selectedPlayerID=1;
        musicPartyMode=0;
        [self createPlaylist:NO animTableView:YES];
    }
    else {
        lastSelected=-1;
        seg_music.selected=YES;
        seg_video.selected=NO;
        selectedPlayerID=0;
        musicPartyMode=0;
        [self createPlaylist:NO animTableView:YES];
    }
}

#pragma mark - utility

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
    NSInteger numelement = [array count];
    for (int i=0;i<numelement-1;i+=2){
        [mutableDictionary setObject:[array objectAtIndex:i] forKey:[array objectAtIndex:i+1]];
    }
    return (NSDictionary *)mutableDictionary;
}

-(void)animCursor:(float)x{
    float time=1.0f;
    if (x==startx){
        time=0.1f;
    }
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:time];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear ];
    CGRect frame;
    frame = [timeCursor frame];
    frame.origin.x = x;
    timeCursor.frame = frame;
    [UIView commitAnimations];
}

-(void)resizeCellBar:(float)width image:(UIImageView *)cellBarImage{
    float time=1.0f;
    if (width==0){
        time=0.1f;
    }
    if (width>cellBarWidth)
        width=cellBarWidth;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:time];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    CGRect frame;
    frame = [cellBarImage frame];
    frame.size.width = width;
    cellBarImage.frame = frame;
    [UIView commitAnimations];
}

-(IBAction)togglePartyMode:(id)sender{
    if ([AppDelegate instance].serverVersion == 11){
        storedItemID=-1;
        [PartyModeButton setSelected:YES];
        GlobalData *obj=[GlobalData getInstance];
        NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
        NSString *serverHTTP=[NSString stringWithFormat:@"http://%@%@@%@:%@/xbmcCmds/xbmcHttp?command=ExecBuiltIn&parameter=PlayerControl(Partymode('music'))", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
        NSURL *url = [NSURL  URLWithString:serverHTTP];
        [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
        playerID = -1;
        selectedPlayerID = -1;
        [self createPlaylist:NO animTableView:YES];
    }
    else{
        if (musicPartyMode){
            [PartyModeButton setSelected:NO];
            [jsonRPC
             callMethod:@"Player.SetPartymode"
             withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0], @"playerid", @"toggle", @"partymode", nil]
             onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                 [PartyModeButton setSelected:NO];
             }];
        }
        else{
            [PartyModeButton setSelected:YES];
            [jsonRPC
             callMethod:@"Player.Open"
             withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                             [NSDictionary dictionaryWithObjectsAndKeys:@"music", @"partymode", nil], @"item", nil]
             onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                 [PartyModeButton setSelected:YES];
                 playerID = -1;
                 selectedPlayerID = -1;
                 storedItemID=-1;
//                 [self createPlaylist:NO animTableView:YES];
             }];
        }
    }
    return;
}

-(void)fadeView:(UIView *)view hidden:(BOOL)value{
    if (value == view.hidden) {
        return;
    }
    view.hidden=value;
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

- (void)AnimButton:(UIButton *)button AnimDuration:(float)seconds hidden:(BOOL)hiddenValue XPos:(int)X{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	CGRect frame;
	frame = [button frame];
	frame.origin.x = X;
	button.frame = frame;
    [UIView commitAnimations];
}

-(UIImage *)resizeImage:(UIImage *)image width:(int)destWidth height:(int)destHeight padding:(int)destPadding {
	int w = image.size.width;
    int h = image.size.height;
    if (!w || !h) return image;
    destPadding = 0;
    CGImageRef imageRef = [image CGImage];
	
	int width, height;
    
	if(w > h){
		width = destWidth - destPadding;
		height = h * (destWidth - destPadding) / w;
	} else {
		height = destHeight - destPadding;
		width = w * (destHeight - destPadding) / h;
	}
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
	CGContextRef bitmap;
	bitmap = CGBitmapContextCreate(NULL, destWidth, destHeight, 8, 4 * destWidth, colorSpace, kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
	
	if (image.imageOrientation == UIImageOrientationLeft) {
		CGContextRotateCTM (bitmap, M_PI/2);
		CGContextTranslateCTM (bitmap, 0, -height);
		
	} else if (image.imageOrientation == UIImageOrientationRight) {
		CGContextRotateCTM (bitmap, -M_PI/2);
		CGContextTranslateCTM (bitmap, -width, 0);
		
	} else if (image.imageOrientation == UIImageOrientationUp) {
		
	} else if (image.imageOrientation == UIImageOrientationDown) {
		CGContextTranslateCTM (bitmap, width,height);
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
    return [self imageWithShadow:source];
//    CGSize size = [source size];
//    UIGraphicsBeginImageContext(size);
//    CGRect rect = CGRectMake(0, 0, size.width, size.height);
//    [source drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0];
//    
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
//    CGFloat borderWidth = 2.0;
//	CGContextSetLineWidth(context, borderWidth);
//    CGContextStrokeRect(context, rect);
//    
//    UIImage *Img =  UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return [self imageWithShadow:Img];
}

#pragma  mark - JSON management

int lastSelected=-1;
int currentPlayerID=-1;
float storePercentage;
int storedItemID;
int currentItemID;

-(void)setCoverSize:(NSString *)type{
    NSString *jewelImg = @"";
    float screenSize = [[UIScreen mainScreen ] bounds].size.height;
    float screenWidth = [[UIScreen mainScreen ] bounds].size.width;
    float originalSize = 480.0f;

    if ([type isEqualToString:@"song"]){
        jewelImg = @"jewel_cd.9.png";
        CGRect frame = thumbnailView.frame;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            frame.origin.x = 52;
            frame.origin.y = 43;
            frame.size.width = 238;
            frame.size.height = 238;
            if(screenSize >= 568) {
                frame.origin.y = frame.origin.y  + 36;
            }
            if (screenWidth > 320) {
                frame.origin.x = frame.origin.x * (screenWidth/320);
                frame.origin.y = frame.origin.y * (screenWidth/320) + ( 36 * (screenWidth/320)) - 36;
                frame.size.width = frame.size.width * (screenWidth/320) + ( 6 * (screenWidth/320));
                frame.size.height = frame.size.height * (screenWidth/320) + ( 6 * (screenWidth/320));
            }
        }
        else {
            jewelImg=@"jewel_cd.9@2x.png";
            if (portraitMode){
                frame.origin.x = 82;
                frame.origin.y = 60;
                frame.size.width = 334;
                frame.size.height = 334;
            }
            else {
                frame.origin.x = 158;
                frame.origin.y = 80;
                frame.size.width = 435;
                frame.size.height = 435;
            }
        }
        thumbnailView.frame = frame;
    }
    else if ([type isEqualToString:@"movie"]){
        jewelImg=@"jewel_dvd.9.png";
        CGRect frame = thumbnailView.frame;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            frame.origin.x = 86;
            frame.origin.y = 39;
            frame.size.width = 172;
            frame.size.height = 248;
            if(screenSize >= 568) {
                frame.origin.x = frame.origin.x - 12;
                frame.origin.y = frame.origin.y + 10;
                frame.size.width = frame.size.width * (screenSize/originalSize);
                frame.size.height = frame.size.height * (screenSize/originalSize) + 10;
            }
            if (screenWidth > 320) {
                float transform = 1.0f;
                if (IS_IPHONE_6) {
                    transform = 0.9f;
                }
                else if (IS_IPHONE_6_PLUS){
                    transform = 0.82f;
                    frame.origin.x = frame.origin.x + 8;
                    frame.origin.y = frame.origin.y + 3;
                }
                frame.origin.x = frame.origin.x * (screenWidth/320) * transform;
                frame.origin.y = frame.origin.y * (screenWidth/320);
                frame.size.width = frame.size.width * (screenWidth/320) * transform;
                frame.size.height = frame.size.height * (screenWidth/320) * transform;
            }
        }
        else{
            jewelImg=@"jewel_dvd.9@2x.png";
            if (portraitMode){
                frame.origin.x = 128;
                frame.origin.y = 56;
                frame.size.width = 240;
                frame.size.height = 346;
            }
            else {
                frame.origin.x = 222;
                frame.origin.y = 74;
                frame.size.width = 306;
                frame.size.height = 450;
            }
        }
        thumbnailView.frame = frame;
    }
    else if ([type isEqualToString:@"episode"]){
        jewelImg = @"jewel_tv.9.png";
        CGRect frame = thumbnailView.frame;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            frame.origin.x = 22;
            frame.origin.y = 78;
            frame.size.width = 280;
            frame.size.height = 158;
            if(screenSize >= 568) {
                frame.origin.y = frame.origin.y  + 36;
                frame.origin.x = frame.origin.x  + 2;
            }
            if (screenWidth > 320) {
                frame.origin.x = frame.origin.x * (screenWidth/320);
                frame.origin.y = frame.origin.y * (screenWidth/320) + ( 36 * (screenWidth/320)) - 34;
                frame.size.width = frame.size.width * (screenWidth/320);
                frame.size.height = frame.size.height * (screenWidth/320) + ( 6 * (screenWidth/320));
            }

        }
        else{
            jewelImg=@"jewel_tv.9@2x.png";
            if (portraitMode){
                frame.origin.x = 28;
                frame.origin.y = 102;
                frame.size.width = 412;
                frame.size.height = 236;
            }
            else {
                frame.origin.x = 38 ;
                frame.origin.y = 102;
                frame.size.width = 646;
                frame.size.height = 364;
            }
        }
        thumbnailView.frame = frame;
    }
    else{
        jewelImg = @"jewel_cd.9.png";
        CGRect frame = thumbnailView.frame;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            frame.origin.x = 52;
            frame.origin.y = 43;
            frame.size.width = 238;
            frame.size.height = 238;
            if(screenSize >= 568) {
                frame.origin.y = frame.origin.y  + 36;
            }
            if (screenWidth > 320) {
                frame.origin.x = frame.origin.x * (screenWidth/320);
                frame.origin.y = frame.origin.y * (screenWidth/320) + ( 36 * (screenWidth/320)) - 36;
                frame.size.width = frame.size.width * (screenWidth/320) + ( 6 * (screenWidth/320));
                frame.size.height = frame.size.height * (screenWidth/320) + ( 6 * (screenWidth/320));
            }
        }
        else {
            jewelImg=@"jewel_cd.9@2x.png";
            if (portraitMode){
                frame.origin.x = 82;
                frame.origin.y = 60;
                frame.size.width = 334;
                frame.size.height = 334;
            }
            else {
                frame.origin.x = 158;
                frame.origin.y = 80;
                frame.size.width = 435;
                frame.size.height = 435;
            }
        }
        thumbnailView.frame = frame;
    }
    if ([self enableJewelCases]){
        jewelView.image = [UIImage imageNamed:jewelImg];
        [nowPlayingView bringSubviewToFront:jewelView];
        thumbnailView.hidden = NO;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            CGRect frame = jewelView.frame;
            frame.origin.x = 10;
            jewelView.frame = frame;
            frame = thumbnailView.frame;
            frame.origin.x += PAD_MENU_TABLE_WIDTH;
            frame.origin.y += 22;
            songDetailsView.frame = frame;
        }
        else {
            songDetailsView.frame = thumbnailView.frame;

        }
    }
    else {
        [nowPlayingView sendSubviewToBack:jewelView];
        thumbnailView.hidden = YES;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            CGRect frame = jewelView.frame;
            frame.origin.x = 14;
            jewelView.frame = frame;
            frame.origin.x += PAD_MENU_TABLE_WIDTH;
            frame.origin.y += 22;
            songDetailsView.frame = frame;
        }
        else {
            songDetailsView.frame = jewelView.frame;
            songDetailsView.center = jewelView.center;
        }
    }
    [nowPlayingView sendSubviewToBack:xbmcOverlayImage];
}

-(void)nothingIsPlaying{
    if (startFlipDemo){
        [playlistButton setImage:[UIImage imageNamed:@"xbmc_overlay_small"] forState:UIControlStateNormal];
        [playlistButton setImage:[UIImage imageNamed:@"xbmc_overlay_small"] forState:UIControlStateHighlighted];
        [playlistButton setImage:[UIImage imageNamed:@"xbmc_overlay_small"] forState:UIControlStateSelected];
        [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(startFlipDemo) userInfo:nil repeats:NO];
        startFlipDemo = NO;
    }
    if (nothingIsPlaying == YES) return;
    nothingIsPlaying = YES;
    ProgressSlider.userInteractionEnabled = NO;
    [ProgressSlider setThumbImage:[[UIImage alloc] init] forState:UIControlStateNormal];
    [ProgressSlider setThumbImage:[[UIImage alloc] init] forState:UIControlStateHighlighted];
    currentTime.text=@"";
    thumbnailView.image = nil;
    lastThumbnail = @"";
    if (![self enableJewelCases]){
        jewelView.image = nil;
    }
    duration.text = @"";
    albumName.text = NSLocalizedString(@"Nothing is playing", nil);
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
    storedItemID=-1;
    [PartyModeButton setSelected:NO];
    repeatButton.hidden = YES;
    shuffleButton.hidden = YES;
    albumDetailsButton.hidden = YES;
    albumTracksButton.hidden = YES;
    artistDetailsButton.hidden = YES;
    artistAlbumsButton.hidden = YES;
    musicPartyMode = 0;
    [self setIOS7backgroundEffect:[UIColor clearColor] barTintColor:TINT_COLOR];
    NSIndexPath *selection = [playlistTableView indexPathForSelectedRow];
    if (selection){
        [playlistTableView deselectRowAtIndexPath:selection animated:YES];
        UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
        UIImageView *coverView = (UIImageView*) [cell viewWithTag:4];
        coverView.alpha = 1.0;
        UIView *timePlaying=(UIView*) [cell viewWithTag:5];
        storeSelection = nil;
        if (timePlaying.hidden == NO)
            [self fadeView:timePlaying hidden:YES];
    }
    [self showPlaylistTable];
}

-(void)setButtonImageAndStartDemo:(UIImage *)buttonImage{
    if (nowPlayingHidden || startFlipDemo){
        [playlistButton setImage:buttonImage forState:UIControlStateNormal];
        [playlistButton setImage:buttonImage forState:UIControlStateHighlighted];
        [playlistButton setImage:buttonImage forState:UIControlStateSelected];
        if (startFlipDemo){
            [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(startFlipDemo) userInfo:nil repeats:NO];
            startFlipDemo = NO;
        }
    }
}

-(void)IOS7colorProgressSlider:(UIColor *)color{
    [UIView transitionWithView:ProgressSlider
                      duration:0.3f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        if ([color isEqual:[UIColor clearColor]]){
                            [ProgressSlider setMinimumTrackTintColor:SLIDER_DEFAULT_COLOR];
                            if (ProgressSlider.userInteractionEnabled){
                                [ProgressSlider setThumbImage:[UIImage imageNamed:pg_thumb_name] forState:UIControlStateNormal];
                                [ProgressSlider setThumbImage:[UIImage imageNamed:pg_thumb_name] forState:UIControlStateHighlighted];
                            }
                            [UIView transitionWithView:albumName
                                              duration:1.0f
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [albumName setTextColor:[UIColor whiteColor]];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:songName
                                              duration:1.0f
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [songName setTextColor:[UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:1.0f]];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:artistName
                                              duration:1.0f
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [artistName setTextColor:[UIColor lightGrayColor]];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:currentTime
                                              duration:1.0f
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [currentTime setTextColor:[UIColor lightGrayColor]];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:duration
                                              duration:1.0f
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [duration setTextColor:[UIColor lightGrayColor]];
                                            }
                                            completion:NULL];
                        }
                        else{
                            Utilities *utils = [[Utilities alloc] init];
                            UIColor *lighterColor = [utils lighterColorForColor:color];
                            UIColor *slightLighterColor = [utils slightLighterColorForColor:color];
                            UIColor *progressColor =[utils updateColor:color lightColor:slightLighterColor darkColor:color trigger:0.2];
                            UIColor *pgThumbColor = [utils updateColor:color lightColor:lighterColor darkColor:slightLighterColor trigger:0.2];
                            [ProgressSlider setMinimumTrackTintColor:progressColor];
                            if (ProgressSlider.userInteractionEnabled){
                                UIImage *thumbImage = [utils colorizeImage:[UIImage imageNamed:pg_thumb_name] withColor:pgThumbColor];
                                [ProgressSlider setThumbImage:thumbImage forState:UIControlStateNormal];
                                [ProgressSlider setThumbImage:thumbImage forState:UIControlStateHighlighted];
                            }
                            [UIView transitionWithView:albumName
                                              duration:1.0f
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [albumName setTextColor:pgThumbColor];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:songName
                                              duration:1.0f
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [songName setTextColor:pgThumbColor];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:artistName
                                              duration:1.0f
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [artistName setTextColor:progressColor];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:currentTime
                                              duration:1.0f
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [currentTime setTextColor:progressColor];
                                            }
                                            completion:NULL];
                            [UIView transitionWithView:duration
                                              duration:1.0f
                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                            animations:^{
                                                [duration setTextColor:progressColor];
                                            }
                                            completion:NULL];
                        }
                    }
                    completion:NULL];
}

-(void)IOS7effect:(UIColor *)color barTintColor:(UIColor *)barColor effectDuration:(float)time{
    [UIView animateWithDuration:time
                     animations:^{
                         [iOS7bgEffect setBackgroundColor:color];
                         [iOS7navBarEffect setBackgroundColor:color];
                         if ([color isEqual:[UIColor clearColor]]){
                             self.navigationController.navigationBar.tintColor = TINT_COLOR;
                             [UIView transitionWithView:backgroundImageView
                                               duration:1.0f
                                                options:UIViewAnimationOptionTransitionCrossDissolve
                                             animations:^{
                                                 backgroundImageView.image=[UIImage imageNamed:@"shiny_black_back"];
                                             }
                                             completion:NULL];
                             if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
                                 NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                                         [UIColor colorWithRed:0.141f green:0.141f blue:0.141f alpha:1.0f], @"startColor",
                                                         [UIColor colorWithRed:0.086f green:0.086f blue:0.086f alpha:1.0f], @"endColor",
                                                         nil, @"image",
                                                         nil];
                                 [[NSNotificationCenter defaultCenter] postNotificationName:@"UIViewChangeBackgroundGradientColor" object:nil userInfo:params];
                                 [[NSNotificationCenter defaultCenter] postNotificationName:@"UIViewChangeBackgroundImage" object:nil userInfo:params];
                             }
                         }
                         else{
                             Utilities *utils = [[Utilities alloc] init];
                             UIColor *lighterColor = [utils lighterColorForColor:color];
                             UIColor *slightLighterColor = [utils slightLighterColorForColor:color];
                             UIColor *navBarColor = [utils updateColor:color lightColor:slightLighterColor darkColor:color trigger:0.4];
                             self.navigationController.navigationBar.tintColor = navBarColor;
                             [UIView transitionWithView:backgroundImageView
                                               duration:1.0f
                                                options:UIViewAnimationOptionTransitionCrossDissolve
                                             animations:^{
                                                 backgroundImageView.image=[utils colorizeImage:[UIImage imageNamed:@"shiny_black_back"] withColor:lighterColor];
                                             }
                                             completion:NULL];
                             if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
                                 CGFloat hue, saturation, brightness, alpha;
                                 BOOL ok = [color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
                                 if (ok) {
                                     UIColor *iPadStartColor = [UIColor colorWithHue:hue saturation:saturation brightness:0.2f alpha:alpha];
                                     
                                     UIColor *iPadEndColor = [UIColor colorWithHue:hue saturation:saturation brightness:0.1f alpha:alpha];
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

-(void)setIOS7backgroundEffect:(UIColor *)color barTintColor:(UIColor *)barColor{
    foundEffectColor = color;
    if (nowPlayingView.hidden == NO){
        [self IOS7colorProgressSlider:color];
        [self IOS7effect:color barTintColor:barColor effectDuration:1.0f];
    }
}

-(void)changeImage:(UIImageView *)imageView image:(UIImage *)newImage{
    [UIView transitionWithView:jewelView
                      duration:0.2f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        imageView.image=newImage;
                    }
                    completion:NULL];
}

-(void)getActivePlayers{
    [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionary] withTimeout:2.0 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                nothingIsPlaying = NO;
                NSNumber *response;
                if (((NSNull *)[[methodResult objectAtIndex:0] objectForKey:@"playerid"] != [NSNull null])){
                    response = [[methodResult objectAtIndex:0] objectForKey:@"playerid"];
                }
                currentPlayerID=[response intValue];
                if (playerID!=[response intValue] || (selectedPlayerID>-1 && playerID!=selectedPlayerID)){  // DA SISTEMARE SE AGGIUNGONO ITEM DALL'ESTERNO: FUTURA SEGNALAZIONE CON SOCKET!                    
                    if (selectedPlayerID>-1  && playerID!=selectedPlayerID){
                        playerID=selectedPlayerID;
                    }
                    else if (selectedPlayerID==-1) {
                        playerID = [response intValue];
                        [self createPlaylist:NO animTableView:YES];
                    }
                }
                NSMutableArray *properties = [[NSMutableArray alloc] initWithObjects:@"album", @"artist",@"title", @"thumbnail", @"track", @"studio", @"showtitle", @"episode", @"season", @"fanart", @"description", @"plot", nil];
                if ([AppDelegate instance].serverVersion > 11){
                    [properties addObject:@"art"];
                }
                [jsonRPC 
                 callMethod:@"Player.GetItem" 
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                                 response, @"playerid",
                                 properties, @"properties",
                                 nil] 
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error==nil && methodError==nil){
//                         NSLog(@"Risposta %@", methodResult);
                         bool enableJewel = [self enableJewelCases];
                         if( [NSJSONSerialization isValidJSONObject:methodResult]){
                             NSDictionary *nowPlayingInfo = [methodResult objectForKey:@"item"];
                             if ([nowPlayingInfo  objectForKey:@"id"] == nil)
                                 currentItemID = -2;
                             else
                                 currentItemID = [[nowPlayingInfo  objectForKey:@"id"] intValue];
                             if (([nowPlayingInfo count] && currentItemID!=storedItemID) || [nowPlayingInfo  objectForKey:@"id"] == nil || ([[nowPlayingInfo  objectForKey:@"type"] isEqualToString:@"channel"] && ![[nowPlayingInfo  objectForKey:@"title"] isEqualToString:storeLiveTVTitle])){
                                 storedItemID = currentItemID;
                                 [self performSelector:@selector(loadCodecView) withObject:nil afterDelay:.5];
                                 itemDescription.text = [[nowPlayingInfo  objectForKey:@"description"] length] !=0 ? [NSString stringWithFormat:@"%@", [nowPlayingInfo  objectForKey:@"description"]] : [[nowPlayingInfo  objectForKey:@"plot"] length] !=0 ? [NSString stringWithFormat:@"%@", [nowPlayingInfo  objectForKey:@"plot"]] : @"";
                                 [itemDescription scrollRangeToVisible:NSMakeRange(0, 0)];
                                 NSString *album = [[nowPlayingInfo  objectForKey:@"album"] length] !=0 ?[NSString stringWithFormat:@"%@",[nowPlayingInfo  objectForKey:@"album"]] : @"" ;
                                 if ([[nowPlayingInfo  objectForKey:@"type"] isEqualToString:@"channel"]){
                                     album = [nowPlayingInfo  objectForKey:@"label"];
                                 }
                                 NSString *title = [[nowPlayingInfo  objectForKey:@"title"] length] !=0 ? [NSString stringWithFormat:@"%@",[nowPlayingInfo  objectForKey:@"title"]] : @"";
                                 storeLiveTVTitle = title;
                                 NSString *artist=@"";
                                 if ([[nowPlayingInfo objectForKey:@"artist"] isKindOfClass:NSClassFromString(@"JKArray")]){
                                     artist = [[nowPlayingInfo objectForKey:@"artist"] componentsJoinedByString:@" / "];
                                     artist = [artist length]==0 ? @"" : artist;
                                 }
                                 else{
                                     artist=[[nowPlayingInfo objectForKey:@"artist"] length]==0? @"" :[nowPlayingInfo objectForKey:@"artist"];
                                 }
                                 if ([album length] == 0 && ((NSNull *)[nowPlayingInfo  objectForKey:@"showtitle"] != [NSNull null]) && [nowPlayingInfo objectForKey:@"season"]>0){
                                     album=[[nowPlayingInfo  objectForKey:@"showtitle"] length] !=0 ? [NSString stringWithFormat:@"%@ - %@x%@", [nowPlayingInfo objectForKey:@"showtitle"], [nowPlayingInfo objectForKey:@"season"], [nowPlayingInfo objectForKey:@"episode"]] : @"";
                                 }
                                 if ([title length] == 0)
                                     title = [[nowPlayingInfo  objectForKey:@"label"] length]!=0? [nowPlayingInfo  objectForKey:@"label"] : @"";

                                 if ([artist length] == 0 && ((NSNull *)[nowPlayingInfo  objectForKey:@"studio"] != [NSNull null])){
                                     if ([[nowPlayingInfo  objectForKey:@"studio"] isKindOfClass:NSClassFromString(@"JKArray")]){
                                         artist = [[nowPlayingInfo  objectForKey:@"studio"] componentsJoinedByString:@" / "];
                                         artist = [artist length]==0 ? @"" : artist;
                                     }
                                     else{
                                         artist = [[nowPlayingInfo  objectForKey:@"studio"] length]!=0? [nowPlayingInfo objectForKey:@"studio"] : @"";
                                     }
                                 }
                                 albumName.text = album;
                                 songName.text = title;
                                 artistName.text = artist;
                                 NSString *type = [[nowPlayingInfo objectForKey:@"type"] length]!=0? [nowPlayingInfo objectForKey:@"type"] : @"unknown";
                                 currentType = type;
                                 [self setCoverSize:currentType];
                                 GlobalData *obj=[GlobalData getInstance]; 
                                 NSString *serverURL=[NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                                 if ([AppDelegate instance].serverVersion > 11){
                                     serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
                                 }
                                 NSString *thumbnailPath=[nowPlayingInfo objectForKey:@"thumbnail"];
                                 NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [thumbnailPath stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
                                 if (![lastThumbnail isEqualToString:stringURL]){
                                     if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
                                         NSString *fanart = (NSNull *)[nowPlayingInfo  objectForKey:@"fanart"] == [NSNull null] ? @"" : [nowPlayingInfo  objectForKey:@"fanart"];
                                         if (![fanart isEqualToString:@""]){
                                             NSString *fanartURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [fanart stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
                                             [tempFanartImageView setImageWithURL:[NSURL URLWithString:fanartURL]
                                                                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                                                            if (error == nil && image != nil){
                                                                                NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: image, @"image", nil];
                                                                                [[NSNotificationCenter defaultCenter] postNotificationName:@"UIViewChangeBackgroundImage" object:nil userInfo:params];
                                                                            }
                                                                            else {
                                                                                NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: [UIImage imageNamed:@""], @"image", nil];
                                                                                [[NSNotificationCenter defaultCenter] postNotificationName:@"UIViewChangeBackgroundImage" object:nil userInfo:params];
                                                                            }
                                                                            
                                                                        }];
                                         }
                                         else {
                                             NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: [UIImage imageNamed:@""], @"image", nil];
                                             [[NSNotificationCenter defaultCenter] postNotificationName:@"UIViewChangeBackgroundImage" object:nil userInfo:params];
                                         }
                                     }
                                     if ([thumbnailPath isEqualToString:@""]){
                                         UIImage *buttonImage = [self resizeImage:[UIImage imageNamed:@"coverbox_back.png"] width:76 height:66 padding:10];
                                         [self setButtonImageAndStartDemo:buttonImage];
                                         [self setIOS7backgroundEffect:[UIColor clearColor] barTintColor:TINT_COLOR];
                                         if (enableJewel){
                                             thumbnailView.image=[UIImage imageNamed:@"coverbox_back.png"];
                                         }
                                         else{
                                             [self changeImage:jewelView image:[UIImage imageNamed:@"coverbox_back.png"]];
                                         }
                                     }
                                     else{
                                         [[SDImageCache sharedImageCache] queryDiskCacheForKey:stringURL done:^(UIImage *image, SDImageCacheType cacheType) {
                                             if (image!=nil){
                                                 UIImage *buttonImage = nil;
                                                 if (enableJewel){
                                                     thumbnailView.image=image;
                                                     buttonImage=[self resizeImage:[self imageWithBorderFromImage:image] width:76 height:66 padding:10];
                                                 }
                                                 else{
                                                     [self changeImage:jewelView image:[self imageWithBorderFromImage:image]];
                                                     buttonImage=[self resizeImage:jewelView.image width:76 height:66 padding:10];
                                                 }
                                                 [self setButtonImageAndStartDemo:buttonImage];
                                                 Utilities *utils = [[Utilities alloc] init];
                                                 UIColor *effectColor = [utils averageColor:image inverse:NO];
                                                 [self setIOS7backgroundEffect:effectColor barTintColor:effectColor];
                                             }
                                             else{
                                                 __weak NowPlaying *sf = self;
                                                 __block UIColor *newColor = nil;
                                                 if (enableJewel){
                                                     [thumbnailView setImageWithURL:[NSURL URLWithString:stringURL]
                                                                   placeholderImage:[UIImage imageNamed:@"coverbox_back.png"]
                                                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                                                              if (error == nil){
                                                                                  
                                                                                  UIImage *buttonImage=[sf resizeImage:[sf imageWithBorderFromImage:image] width:76 height:66 padding:10];
                                                                                  [sf setButtonImageAndStartDemo:buttonImage];
                                                                                  Utilities *utils = [[Utilities alloc] init];
                                                                                  newColor = [utils averageColor:image inverse:NO];
                                                                                  [sf setIOS7backgroundEffect:newColor barTintColor:newColor];
                                                                              }
                                                                          }];
                                                 }
                                                 else{
                                                     __weak UIImageView *jV = jewelView;
                                                     [jewelView
                                                      setImageWithURL:[NSURL URLWithString:stringURL]
                                                      placeholderImage:[UIImage imageNamed:@"coverbox_back.png"]
                                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                                          if (error == nil){
                                                              [sf changeImage:jV image:[sf imageWithBorderFromImage:image]];
                                                              UIImage *buttonImage=[sf resizeImage:jV.image width:76 height:66 padding:10];
                                                              [sf setButtonImageAndStartDemo:buttonImage];
                                                              Utilities *utils = [[Utilities alloc] init];
                                                              newColor = [utils averageColor:image inverse:NO];
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
                                 NSDictionary *art = [nowPlayingInfo objectForKey:@"art"];
                                 storeClearlogo = @"";
                                 storeClearart = @"";
                                 for (NSString *key in art) {
                                     if ([key rangeOfString:@"clearlogo"].location != NSNotFound){
                                         storeClearlogo = [art objectForKey:key];
                                     }
                                     if ([key rangeOfString:@"clearart"].location != NSNotFound){
                                         storeClearart = [art objectForKey:key];
                                     }
                                 }
                                 if ([storeClearlogo isEqualToString:@""]) {
                                     storeClearlogo = storeClearart;
                                 }
                                 if (![storeClearlogo isEqualToString:@""]){
                                     NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [storeClearlogo stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
                                     [itemLogoImage setImageWithURL:[NSURL URLWithString:stringURL]];
                                     storeCurrentLogo = storeClearlogo;
                                 }
                             }
                         }
                         else {
                             storedItemID=-1;
                             lastThumbnail = @"";
                             if (enableJewel){
                                 thumbnailView.image=[UIImage imageNamed:@"coverbox_back.png"];
                             }
                             else{
                                 jewelView.image=[UIImage imageNamed:@"coverbox_back.png"];
                             }
                         }
                     }
                     else {
                         storedItemID=-1;
                     }
                 }];
                [jsonRPC 
                 callMethod:@"Player.GetProperties" 
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                                 response, @"playerid",
                                 [[NSArray alloc] initWithObjects:@"percentage", @"time", @"totaltime", @"partymode", @"position", @"canrepeat", @"canshuffle", @"repeat", @"shuffled", @"canseek", nil], @"properties",
                                 nil] 
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error==nil && methodError==nil){
                         if( [NSJSONSerialization isValidJSONObject:methodResult]){
                             //                             NSLog(@"risposta %@", methodResult);
                             if ([methodResult count]){
                                 if (updateProgressBar){
                                     ProgressSlider.value = [(NSNumber*) [methodResult objectForKey:@"percentage"] floatValue];
                                 }
                                 musicPartyMode=[[methodResult objectForKey:@"partymode"] intValue];
                                 if (musicPartyMode==YES) {
                                     [PartyModeButton setSelected:YES];
                                 }
                                 else{
                                     [PartyModeButton setSelected:NO];
                                 }
                                 BOOL canrepeat = [[methodResult objectForKey:@"canrepeat"] boolValue] && !musicPartyMode;
                                 if (canrepeat){
                                     repeatStatus = [methodResult objectForKey:@"repeat"];
                                     if (repeatButton.hidden == YES){
                                         repeatButton.hidden = NO;
                                     }
                                     if ([repeatStatus isEqualToString:@"all"]){
                                         [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat_all"] forState:UIControlStateNormal];
                                     }
                                     else if ([repeatStatus isEqualToString:@"one"]){
                                         [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat_one"] forState:UIControlStateNormal];
                                     }
                                     else{
                                         [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat"] forState:UIControlStateNormal];
                                     }
                                 }
                                 else if (repeatButton.hidden == NO){
                                     repeatButton.hidden = YES;
                                 }
                                 BOOL canshuffle = [[methodResult objectForKey:@"canshuffle"] boolValue] && !musicPartyMode;
                                 if (canshuffle){
                                     shuffled = [[methodResult objectForKey:@"shuffled"] boolValue];
                                     if (shuffleButton.hidden == YES){
                                         shuffleButton.hidden = NO;
                                     }
                                     if (shuffled){
                                         [shuffleButton setBackgroundImage:[UIImage imageNamed:@"button_shuffle_on"] forState:UIControlStateNormal];
                                     }
                                     else{
                                         [shuffleButton setBackgroundImage:[UIImage imageNamed:@"button_shuffle"] forState:UIControlStateNormal];
                                     }
                                 }
                                 else if (shuffleButton.hidden == NO){
                                     shuffleButton.hidden = YES;
                                 }
                                 
                                 BOOL canseek = [[methodResult objectForKey:@"canseek"] boolValue];
                                 if (canseek && !ProgressSlider.userInteractionEnabled){
                                     ProgressSlider.userInteractionEnabled = YES;
                                     [ProgressSlider setThumbImage:[UIImage imageNamed:pg_thumb_name] forState:UIControlStateNormal];
                                     [ProgressSlider setThumbImage:[UIImage imageNamed:pg_thumb_name] forState:UIControlStateHighlighted];
//                                     [ProgressSlider setThumbTintColor:[UIColor lightGrayColor]];

                                 }
                                 if (!canseek && ProgressSlider.userInteractionEnabled){
                                     ProgressSlider.userInteractionEnabled = NO;
                                     [ProgressSlider setThumbImage:[[UIImage alloc] init] forState:UIControlStateNormal];
                                     [ProgressSlider setThumbImage:[[UIImage alloc] init] forState:UIControlStateHighlighted];
                                 }

                                 NSDictionary *timeGlobal=[methodResult objectForKey:@"totaltime"];
                                 int hoursGlobal=[[timeGlobal objectForKey:@"hours"] intValue];
                                 int minutesGlobal=[[timeGlobal objectForKey:@"minutes"] intValue];
                                 int secondsGlobal=[[timeGlobal objectForKey:@"seconds"] intValue];
                                 NSString *globalTime=[NSString stringWithFormat:@"%@%02i:%02i", (hoursGlobal == 0) ? @"":[NSString stringWithFormat:@"%02i:", hoursGlobal], minutesGlobal, secondsGlobal];
                                 globalSeconds = hoursGlobal * 3600 + minutesGlobal * 60 + secondsGlobal;
                                 duration.text=globalTime;
                                 
                                 NSDictionary *time=[methodResult objectForKey:@"time"];
                                 int hours=[[time objectForKey:@"hours"] intValue];
                                 int minutes=[[time objectForKey:@"minutes"] intValue];
                                 int seconds=[[time objectForKey:@"seconds"] intValue];
                                 NSString *actualTime=[NSString stringWithFormat:@"%@%02i:%02i", (hoursGlobal == 0) ? @"":[NSString stringWithFormat:@"%02i:", hours], minutes, seconds];
                                 if (updateProgressBar){
                                     currentTime.text=actualTime;
                                 }
                                 NSIndexPath* selection = [playlistTableView indexPathForSelectedRow];
                                 if (storeSelection)
                                     selection=storeSelection;
                                 if (selection){
                                     UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
                                     UILabel *playlistActualTime=(UILabel*) [cell viewWithTag:6];
                                     playlistActualTime.text=actualTime;
                                     UIImageView *playlistActualBar=(UIImageView*) [cell viewWithTag:7];
                                     float newx=cellBarWidth * [(NSNumber*) [methodResult objectForKey:@"percentage"] floatValue] / 100;
                                     if (newx<1)
                                         newx=1;
                                     [self resizeCellBar:newx image:playlistActualBar];
                                     UIView *timePlaying=(UIView*) [cell viewWithTag:5];
                                     if (timePlaying.hidden==YES)
                                         [self fadeView:timePlaying hidden:NO];
                                 }
                                 int playlistPosition = [[methodResult objectForKey:@"position"] intValue];
                                 if (playlistPosition>-1)
                                     playlistPosition+=1;
                                 if (musicPartyMode && [(NSNumber*) [methodResult objectForKey:@"percentage"] floatValue]<storePercentage){ // BLEAH!!!
                                     [self checkPartyMode];
                                 }
                                 //                                 if (selection){
                                 //                                     NSLog(@"%d %d %@", currentItemID, [[[playlistData objectAtIndex:selection.row] objectForKey:@"idItem"] intValue], selection);
                                 //                                     
                                 ////                                     if (currentItemID!=[[[playlistData objectAtIndex:selection.row] objectForKey:@"idItem"] intValue] && [[[playlistData objectAtIndex:selection.row] objectForKey:@"idItem"] intValue]>0){
                                 //////                                         lastSelected=-1;
                                 //////                                         // storeSelection=0;
                                 //////                                         currentItemID=[[[playlistData objectAtIndex:selection.row] objectForKey:@"idItem"] intValue];
                                 ////                                         [self createPlaylist:NO];
                                 ////                                     }
                                 //                                 }
                                 
                                 //                                 NSLog(@"CURRENT ITEMID %d PLAYLIST ID %@", currentItemID, [[playlistData objectAtIndex:selection.row] objectForKey:@"idItem"]);
                                 storePercentage=[(NSNumber*) [methodResult objectForKey:@"percentage"] floatValue];
                                 if (playlistPosition!=lastSelected && playlistPosition>0){
                                     if (([playlistData count]>=playlistPosition) && currentPlayerID==playerID){
                                         if (playlistPosition>0){
                                             if (lastSelected!=playlistPosition){
                                                 NSIndexPath* selection = [playlistTableView indexPathForSelectedRow];
                                                 if (storeSelection)
                                                     selection=storeSelection;
                                                 if (selection){
                                                     UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
                                                     UIView *timePlaying=(UIView*) [cell viewWithTag:5];
                                                     if (timePlaying.hidden==NO)
                                                         [self fadeView:timePlaying hidden:YES];
                                                     UIImageView *coverView=(UIImageView*) [cell viewWithTag:4];
                                                     coverView.alpha=1.0;                                                     
                                                 }
                                                 NSIndexPath *newSelection=[NSIndexPath indexPathForRow:playlistPosition - 1 inSection:0];
                                                 UITableViewScrollPosition position=UITableViewScrollPositionMiddle;
                                                 if (musicPartyMode)
                                                     position=UITableViewScrollPositionNone;
                                                 [playlistTableView selectRowAtIndexPath:newSelection animated:YES scrollPosition:position];
                                                 UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:newSelection];
                                                 UIView *timePlaying=(UIView*) [cell viewWithTag:5];
                                                 if (timePlaying.hidden==YES)
                                                     [self fadeView:timePlaying hidden:NO];
                                                 storeSelection=newSelection;
                                                 lastSelected=playlistPosition;
                                             }
                                         }
                                         else {
                                             NSIndexPath* selection = [playlistTableView indexPathForSelectedRow];
                                             if (selection){
                                                 
                                                 [playlistTableView deselectRowAtIndexPath:selection animated:YES];
                                                 UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
                                                 UIView *timePlaying=(UIView*) [cell viewWithTag:5];
                                                 if (timePlaying.hidden==NO)
                                                     [self fadeView:timePlaying hidden:YES];
                                                 UIImageView *coverView=(UIImageView*) [cell viewWithTag:4];
                                                 coverView.alpha=1.0;
                                             }
                                         }
                                     }
                                 }
                             }
                             else{
                                 [PartyModeButton setSelected:NO];
                             }
                         }
                         else{
                             [PartyModeButton setSelected:NO];
                         }
                     }
                     else {
                         [PartyModeButton setSelected:NO];
                     }
                 }];
            }
            else{
                [self nothingIsPlaying];
                if (playerID==-1 && selectedPlayerID==-1){
                    playerID=-2;
                    [self createPlaylist:YES animTableView:YES];
                }
            }
        }
        else {
            [self nothingIsPlaying];
        }
    }];
}

-(void)loadCodecView {
    [jsonRPC 
     callMethod:@"XBMC.GetInfoLabels" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                     [[NSArray alloc] initWithObjects:@"MusicPlayer.Codec",@"MusicPlayer.SampleRate",@"MusicPlayer.BitRate", @"MusicPlayer.Channels", @"VideoPlayer.VideoResolution", @"VideoPlayer.VideoAspect", @"VideoPlayer.AudioCodec", @"VideoPlayer.VideoCodec", nil], @"labels",
                     nil] 
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error==nil && methodError==nil && [methodResult isKindOfClass: [NSDictionary class]]){
             NSString *codec = @"";
             NSString *bitrate = @"";
             NSString *samplerate = @"";
             NSString *numchan = @"";
             if (playerID==0 && currentPlayerID==playerID) {
                 codec = [[methodResult objectForKey:@"MusicPlayer.Codec"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@", [methodResult objectForKey:@"MusicPlayer.Codec"]] ;
                 songCodec.text = codec;
                 songCodec.hidden = NO;
                 songCodecImage.image = nil;
                 songSampleRateImage.image = nil;
                 songNumChanImage.image = nil;
                 
                 UIImage *songImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", codec]];
                 [songCodecImage setImage:songImage];
                 if (songImage != nil){
                     songCodec.hidden = YES;
                 }
                 
                 numchan = [[methodResult objectForKey:@"MusicPlayer.Channels"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@", [methodResult objectForKey:@"MusicPlayer.Channels"]];
                 songBitRate.text = numchan;
                 songBitRate.hidden = NO;
                 songBitRateImage.image = nil;
                 UIImage *numChanImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", numchan]];
                 [songBitRateImage setImage:numChanImage];
                 if (numChanImage != nil){
                     songBitRate.hidden = YES;
                 }
        
                 samplerate = [[methodResult objectForKey:@"MusicPlayer.SampleRate"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@\nkHz", [methodResult objectForKey:@"MusicPlayer.SampleRate"]];
                 songNumChannels.text = samplerate;
                 songNumChannels.hidden = NO;
                 
                 bitrate = [[methodResult objectForKey:@"MusicPlayer.BitRate"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@\nkbit/s", [methodResult objectForKey:@"MusicPlayer.BitRate"]] ;
                 songSampleRate.text = bitrate;
                 songSampleRate.hidden = NO;
             }
             else if (currentPlayerID==playerID) {
                 codec = [[methodResult objectForKey:@"VideoPlayer.VideoResolution"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@", [methodResult objectForKey:@"VideoPlayer.VideoResolution"]] ;
                 songCodec.text = codec;
                 songCodec.hidden = NO;
                 songCodecImage.image = nil;
                 UIImage *resolutionImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", codec]];
                 [songCodecImage setImage:resolutionImage];
                 if (resolutionImage != nil){
                     songCodec.hidden = YES;
                 }
                 
                 bitrate = [[methodResult objectForKey:@"VideoPlayer.VideoAspect"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@", [methodResult objectForKey:@"VideoPlayer.VideoAspect"]] ;
                 songBitRate.text = bitrate;
                 songBitRate.hidden = NO;
                 songBitRateImage.image = nil;
                 UIImage *aspectImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", bitrate]];
                 [songBitRateImage setImage:aspectImage];
                 if (aspectImage != nil){
                     songBitRate.hidden = YES;
                 }
                 
                samplerate = [[methodResult objectForKey:@"VideoPlayer.VideoCodec"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@", [methodResult objectForKey:@"VideoPlayer.VideoCodec"]];
                 songSampleRate.text = samplerate;
                 songSampleRate.hidden = NO;
                 songSampleRateImage.image = nil;
                 UIImage *videoCodecImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", samplerate]];
                 [songSampleRateImage setImage:videoCodecImage];
                 if (videoCodecImage != nil){
                     songSampleRate.hidden = YES;
                 }
                 
                 numchan = [[methodResult objectForKey:@"VideoPlayer.AudioCodec"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@", [methodResult objectForKey:@"VideoPlayer.AudioCodec"]];
                 songNumChannels.text = numchan;
                 songNumChannels.hidden = NO;
                 songNumChanImage.image = nil;
                 UIImage *audioCodecImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", numchan]];
                 [songNumChanImage setImage:audioCodecImage];
                 if (audioCodecImage != nil){
                     songNumChannels.hidden = YES;
                 }
             }
         }
    }];
}

-(void)playbackInfo{
    if (![AppDelegate instance].serverOnLine) {
        playerID = -1;
        selectedPlayerID = -1;
        storedItemID = 0;
        [self AnimTable:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:slideFrom];
        [playlistData performSelectorOnMainThread:@selector(removeAllObjects) withObject:nil waitUntilDone:YES];
        [self nothingIsPlaying];
        return;
    }
    jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    if ([AppDelegate instance].serverVersion == 11){
        [jsonRPC 
         callMethod:@"XBMC.GetInfoBooleans" 
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                         [[NSArray alloc] initWithObjects:@"Window.IsActive(virtualkeyboard)", @"Window.IsActive(selectdialog)",nil], @"booleans",
                         nil] 
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
             
             if (error==nil && methodError==nil && [methodResult isKindOfClass: [NSDictionary class]]){
                 if (((NSNull *)[methodResult objectForKey:@"Window.IsActive(virtualkeyboard)"] != [NSNull null]) && ((NSNull *)[methodResult objectForKey:@"Window.IsActive(selectdialog)"] != [NSNull null])){
                     NSNumber *virtualKeyboardActive = [methodResult objectForKey:@"Window.IsActive(virtualkeyboard)"];
                     NSNumber *selectDialogActive = [methodResult objectForKey:@"Window.IsActive(selectdialog)"];
                     if ([virtualKeyboardActive intValue] == 1 || [selectDialogActive intValue] == 1){
                         return;
                     }
                     else{
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


-(void)clearPlaylist:(int)playlistID{
    jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    [jsonRPC callMethod:@"Playlist.Clear" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:playlistID],@"playlistid", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            [self createPlaylist:NO animTableView:NO];
        }
//        else {
//            NSLog(@"ci deve essere un problema %@", methodError);
//        }
    }];
}

-(void)playbackAction:(NSString *)action params:(NSArray *)parameters checkPartyMode:(BOOL)checkPartyMode{
    jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionary] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                NSNumber *response = [[methodResult objectAtIndex:0] objectForKey:@"playerid"];
                NSMutableArray *commonParams=[NSMutableArray arrayWithObjects:response, @"playerid", nil];
                if (parameters!=nil)
                    [commonParams addObjectsFromArray:parameters];
                [jsonRPC callMethod:action withParameters:[self indexKeyedDictionaryFromArray:commonParams] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                    if (error==nil && methodError==nil){
                        if (musicPartyMode && checkPartyMode){
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
-(void)alphaView:(UIView *)view AnimDuration:(float)seconds Alpha:(float)alphavalue{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	view.alpha = alphavalue;
    [UIView commitAnimations];
}

-(void)alphaButton:(UIButton *)button AnimDuration:(float)seconds show:(BOOL)show{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	button.hidden = show;
    [UIView commitAnimations];
}

-(void)createPlaylist:(BOOL)forcePlaylistID animTableView:(BOOL)animTable{ 
    if (![AppDelegate instance].serverOnLine) {
        playerID = -1;
        selectedPlayerID = -1;
        storedItemID = 0;
        [self AnimTable:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:slideFrom];
        [playlistData performSelectorOnMainThread:@selector(removeAllObjects) withObject:nil waitUntilDone:YES];
        [self nothingIsPlaying];
        return;
    }
    if (!musicPartyMode && animTable)
        [self AnimTable:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:slideFrom];
    [activityIndicatorView startAnimating];
    GlobalData *obj=[AppDelegate instance].obj; 
    int playlistID=playerID;
    if (forcePlaylistID)
        playlistID=0;
    
    if (selectedPlayerID>-1){
        playlistID=selectedPlayerID;
        playerID=selectedPlayerID;
    }
    
    if (playlistID==0){
        playerID=0;
        [playlistSegmentedControl setSelectedSegmentIndex:0];
        seg_music.selected=YES;
        seg_video.selected=NO;
        [self AnimButton:PartyModeButton AnimDuration:0.3 hidden:NO XPos:8];
    }
    else if (playlistID==1){
        playerID=1;
        [playlistSegmentedControl setSelectedSegmentIndex:1];
        seg_music.selected=NO;
        seg_video.selected=YES;
        [self AnimButton:PartyModeButton AnimDuration:0.3 hidden:YES XPos:-72];
    }
    [self alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
    jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    [jsonRPC callMethod:@"Playlist.GetItems" 
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                         [[NSArray alloc] initWithObjects:@"thumbnail", @"duration",@"artist", @"album", @"runtime", @"showtitle", @"season", @"episode",@"artistid", @"albumid", @"genre", @"tvshowid", @"file", @"title", nil], @"properties",
                         [NSNumber numberWithInt:playlistID], @"playlistid",
                         nil] 
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               NSInteger total=0;
               if (error==nil && methodError==nil){
                   [playlistData performSelectorOnMainThread:@selector(removeAllObjects) withObject:nil waitUntilDone:YES];
                   [playlistTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
                   if( [NSJSONSerialization isValidJSONObject:methodResult]){
                       NSArray *playlistItems = [methodResult objectForKey:@"items"];
                       total=[playlistItems count];
                       if (total==0){
                           [self alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
                       }
                       else {
                           [self alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
                       }
                       NSString *serverURL;
                       serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                       int runtimeInMinute = 1;
                       if ([AppDelegate instance].serverVersion > 11){
                           serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
                           runtimeInMinute = 60;
                       }
                       for (int i=0; i<total; i++) {
                           NSString *idItem=[NSString stringWithFormat:@"%@",[[playlistItems objectAtIndex:i] objectForKey:@"id"]];
                           NSString *label=[NSString stringWithFormat:@"%@",[[playlistItems objectAtIndex:i] objectForKey:@"label"]];
                           NSString *title=[NSString stringWithFormat:@"%@",[[playlistItems objectAtIndex:i] objectForKey:@"title"]];
                           
                           NSString *artist=@"";
                           if ([[[playlistItems objectAtIndex:i] objectForKey:@"artist"] isKindOfClass:NSClassFromString(@"JKArray")]){
                               artist = [[[playlistItems objectAtIndex:i] objectForKey:@"artist"] componentsJoinedByString:@" / "];
                               artist = [artist length]==0 ? @"-" : artist;
                           }
                           else{
                                artist=[[[playlistItems objectAtIndex:i] objectForKey:@"artist"] length]==0? @"" :[[playlistItems objectAtIndex:i] objectForKey:@"artist"];
                           }
                           NSString *album=[[[playlistItems objectAtIndex:i] objectForKey:@"album"] length]==0? @"" :[[playlistItems objectAtIndex:i] objectForKey:@"album"];
                           
                           NSString *patchRuntime = [NSString stringWithFormat:@"%@",[[playlistItems objectAtIndex:i] objectForKey:@"runtime"]];
                           NSString *runtime=[patchRuntime intValue] == 0 ? @"" : [NSString stringWithFormat:@"%d min",[patchRuntime intValue]/runtimeInMinute];
                           
                           NSString *showtitle=[[playlistItems objectAtIndex:i] objectForKey:@"showtitle"];
                         
                           NSString *season=[[playlistItems objectAtIndex:i] objectForKey:@"season"];
                           NSString *episode=[[playlistItems objectAtIndex:i] objectForKey:@"episode"];
                           NSString *type=[[playlistItems objectAtIndex:i] objectForKey:@"type"];
                           
                           NSString *artistid=[NSString stringWithFormat:@"%@", [[playlistItems objectAtIndex:i] objectForKey:@"artistid"]];
                           NSString *albumid=[NSString stringWithFormat:@"%@", [[playlistItems objectAtIndex:i] objectForKey:@"albumid"]];
                           NSString *movieid=[NSString stringWithFormat:@"%@", [[playlistItems objectAtIndex:i] objectForKey:@"id"]];
                           NSString *genre = @"";
                           if ([[[playlistItems objectAtIndex:i] objectForKey:@"genre"] isKindOfClass:NSClassFromString(@"JKArray")]){
                               genre=[NSString stringWithFormat:@"%@",[[[playlistItems objectAtIndex:i] objectForKey:@"genre"] componentsJoinedByString:@" / "]];
                           }
                           else{
                               genre=[NSString stringWithFormat:@"%@", [[playlistItems objectAtIndex:i] objectForKey:@"genre"]];
                           }
                           
                           if ([genre isEqualToString:@"(null)"]) genre=@"";
                           NSNumber *itemDurationSec=[[playlistItems objectAtIndex:i] objectForKey:@"duration"];
                           NSString *durationTime=[itemDurationSec longValue]==0 ? @"" : [self convertTimeFromSeconds:itemDurationSec];

                           NSString *thumbnail=[NSString stringWithFormat:@"%@",[[playlistItems objectAtIndex:i] objectForKey:@"thumbnail"]];
                           NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [thumbnail stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
                           NSNumber *tvshowid =[NSNumber numberWithInt:[[NSString stringWithFormat:@"%@", [[playlistItems objectAtIndex:i]  objectForKey:@"tvshowid"]]intValue]];
                           NSString *file=[NSString stringWithFormat:@"%@", [[playlistItems objectAtIndex:i] objectForKey:@"file"]];
                           [playlistData addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    idItem, @"idItem",
                                                    file, @"file",
                                                    label, @"label",
                                                    title, @"title",
                                                    type,@"type",
                                                    artist, @"artist",
                                                    album, @"album",
                                                    durationTime, @"duration",
                                                    artistid, @"artistid",
                                                    albumid, @"albumid",
                                                    genre, @"genre",
                                                    movieid, @"movieid",
                                                    movieid, @"episodeid",
                                                    stringURL, @"thumbnail",
                                                    runtime,@"runtime",
                                                    showtitle,@"showtitle",
                                                    season, @"season",
                                                    episode, @"episode",
                                                    tvshowid, @"tvshowid",
                                                    nil]];
                       }                       
                       [self showPlaylistTable];
                       if (musicPartyMode && playlistID==0){
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

-(void)showPlaylistTable{
    numResults = (int)[playlistData count];
    if (numResults==0)
        [self alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
    else {
        [self AnimTable:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
    [playlistTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
    [activityIndicatorView stopAnimating];
}

-(void)SimpleAction:(NSString *)action params:(NSDictionary *)parameters reloadPlaylist:(BOOL)reload startProgressBar:(BOOL)progressBar{
    jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    [jsonRPC callMethod:action withParameters:parameters onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if (reload){
                [self createPlaylist:NO animTableView:YES];
            }
            if (progressBar){
                updateProgressBar = YES;
            }
        }
        else {
            if (progressBar){
                updateProgressBar = YES;
            }
        }
    }];
}

-(void)showInfo:(NSDictionary *)item menuItem:(mainMenu *)menuItem indexPath:(NSIndexPath *)indexPath{
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[menuItem mainMethod] objectAtIndex:choosedTab]];
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[menuItem mainParameters] objectAtIndex:choosedTab]];
    
    NSMutableDictionary *mutableParameters = [[parameters objectForKey:@"extra_info_parameters"] mutableCopy];
    NSMutableArray *mutableProperties = [[[parameters objectForKey:@"extra_info_parameters"] objectForKey:@"properties"] mutableCopy];
    
    if ([[parameters objectForKey:@"FrodoExtraArt"] boolValue] == YES && [AppDelegate instance].serverVersion > 11){
        [mutableProperties addObject:@"art"];
        [mutableParameters setObject:mutableProperties forKey:@"properties"];
    }

    if ([parameters objectForKey:@"extra_info_parameters"]!=nil && [methods objectForKey:@"extra_info_method"]!=nil){
        [self retrieveExtraInfoData:[methods objectForKey:@"extra_info_method"] parameters:mutableParameters index:indexPath item:item menuItem:menuItem];
    }
    else{
        [self displayInfoView:item];
    }
}

-(void)displayInfoView:(NSDictionary *)item{
    fromItself = TRUE;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        self.showInfoViewController=nil;
        self.showInfoViewController = [[ShowInfoViewController alloc] initWithNibName:@"ShowInfoViewController" bundle:nil];
        self.showInfoViewController.detailItem = item;
        [self.navigationController pushViewController:self.showInfoViewController animated:YES];
    }
    else{
        ShowInfoViewController *iPadShowViewController = [[ShowInfoViewController alloc] initWithNibName:@"ShowInfoViewController" withItem:item withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
        [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadShowViewController invokeByController:self isStackStartView:TRUE];
        [[AppDelegate instance].windowController.stackScrollViewController enablePanGestureRecognizer];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object: nil];
    }
}

-(void) retrieveExtraInfoData:(NSString *)methodToCall parameters:(NSDictionary*)parameters index:(NSIndexPath *)indexPath item:(NSDictionary *)item menuItem:(mainMenu *)menuItem{
    NSString *itemid = @"";
    NSDictionary *mainFields=[[menuItem mainFields] objectAtIndex:choosedTab];
    if (((NSNull *)[mainFields objectForKey:@"row6"] != [NSNull null])){
        itemid = [mainFields objectForKey:@"row6"];
    }
    else{
        return; // something goes wrong
    }
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
    UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
    [queuing startAnimating];
    id object = [NSNumber numberWithInt:[[item objectForKey:itemid] intValue]];
    if ([AppDelegate instance].serverVersion > 11 && [methodToCall isEqualToString:@"AudioLibrary.GetArtistDetails"]){// WORKAROUND due the lack of the artistid with Playlist.GetItems
        methodToCall = @"AudioLibrary.GetArtists";
        NSString *artistFrodoWorkaround = [NSString stringWithFormat:@"%@", [item objectForKey:@"idItem"]];
        object = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[artistFrodoWorkaround intValue]], @"songid", nil];
        itemid = @"filter";
    }
    NSMutableArray *newProperties =[[parameters objectForKey:@"properties"] mutableCopy];
    if ([parameters objectForKey:@"kodiExtrasPropertiesMinimumVersion"] != nil) {
        for(id key in [parameters objectForKey:@"kodiExtrasPropertiesMinimumVersion"]) {
            if ([AppDelegate instance].serverVersion >= [key integerValue]){
                id arrayProperties = [[parameters objectForKey:@"kodiExtrasPropertiesMinimumVersion"] objectForKey:key];
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
    GlobalData *obj=[GlobalData getInstance];
//    NSLog(@"%@ - %@", methodToCall, newParameters);
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
                     [self somethingGoesWrong:NSLocalizedString(@"Details not found", nil)];
                     return;
                 }
                 if ([AppDelegate instance].serverVersion > 11 && [methodToCall isEqualToString:@"AudioLibrary.GetArtists"]){// WORKAROUND due the lack of the artistid with Playlist.GetItems
                     itemid_extra_info = @"artists";
                 }
                 NSDictionary *videoLibraryMovieDetail = [methodResult objectForKey:itemid_extra_info];
                 if (((NSNull *)videoLibraryMovieDetail == [NSNull null]) || videoLibraryMovieDetail == nil){
                     [self somethingGoesWrong:NSLocalizedString(@"Details not found", nil)];
                     return;
                 }
                 if ([AppDelegate instance].serverVersion > 11 && [methodToCall isEqualToString:@"AudioLibrary.GetArtists"]){// WORKAROUND due the lack of the artistid with Playlist.GetItems
                     if ([[methodResult objectForKey:itemid_extra_info] count]){
                         videoLibraryMovieDetail = [[methodResult objectForKey:itemid_extra_info] objectAtIndex:0];
                     }
                     else{
                         [self somethingGoesWrong:NSLocalizedString(@"Details not found", nil)];
                         return;
                     }
                 }
                 NSString *serverURL= @"";
                 serverURL = [NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                 if ([AppDelegate instance].serverVersion > 11){
                     serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
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
                     runtime=[NSString stringWithFormat:@"%d min",[[videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row4"]] intValue]];
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
                 if (![thumbnailPath isEqualToString:@""]){
                     stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [thumbnailPath stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
                 }
                 if (![fanartPath isEqualToString:@""]){
                     fanartURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [fanartPath stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
                 }
                 NSString *filetype=@"";
                 
                 if ([videoLibraryMovieDetail objectForKey:@"filetype"]!=nil){
                     filetype=[videoLibraryMovieDetail objectForKey:@"filetype"];
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
                 BOOL disableNowPlaying = YES;
                 NSObject *row11 = [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row11"]];
                 if (row11 == nil){
                     row11 = [NSNumber numberWithInt:0];
                 }
                 NSDictionary *newItem =
                 [NSMutableDictionary dictionaryWithObjectsAndKeys:
                  [NSNumber numberWithBool:disableNowPlaying], @"disableNowPlaying",
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
                  [videoLibraryMovieDetail objectForKey:[mainFields objectForKey:@"row20"]], [mainFields objectForKey:@"row20"],
                  nil];
                 [self displayInfoView:newItem];
             }
             else {
                 [queuing stopAnimating];
             }
         }
         else {
//             NSLog(@"ERORR %@ ", methodError);
             [self somethingGoesWrong:NSLocalizedString(@"Details not found", nil)];
             [queuing stopAnimating];
         }
     }];
}

-(void)somethingGoesWrong:(NSString *)message{
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:message message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    [alertView show];
}

# pragma mark -  animations

-(void)flipAnimButton:(UIButton *)button demo:(bool)demo{
    if (demo){
        anim=UIViewAnimationTransitionFlipFromLeft;
        anim2=UIViewAnimationTransitionFlipFromLeft;
        startFlipDemo = NO;
    }
    [UIView animateWithDuration:0.2
                     animations:^{ 
                         button.hidden = YES;
                         if (nowPlayingHidden){
                             UIImage *buttonImage;
                             if ([self enableJewelCases] && thumbnailView.image.size.width){
                                 buttonImage=[self resizeImage:[self imageWithBorderFromImage:thumbnailView.image] width:76 height:66 padding:10];
                             }
                             else if (jewelView.image.size.width){
                                 buttonImage=[self resizeImage:jewelView.image width:76 height:66 padding:10];
                             }
                             if (!buttonImage.size.width){
                                 buttonImage = [self resizeImage:[UIImage imageNamed:@"xbmc_overlay_small"] width:76 height:66 padding:10];
                             }
                             [button setImage:buttonImage forState:UIControlStateNormal];
                             [button setImage:buttonImage forState:UIControlStateHighlighted];
                             [button setImage:buttonImage forState:UIControlStateSelected];
                         }
                         else{
                             [button setImage:[UIImage imageNamed:@"now_playing_playlist@2x"] forState:UIControlStateNormal];
                             [button setImage:[UIImage imageNamed:@"now_playing_playlist@2x"] forState:UIControlStateHighlighted];
                             [button setImage:[UIImage imageNamed:@"now_playing_playlist@2x"] forState:UIControlStateSelected];
                         }
                         [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                         [UIView setAnimationTransition:anim forView:button cache:YES];
                     } 
                     completion:^(BOOL finished){
                         [UIView beginAnimations:nil context:nil];
                         button.hidden = NO;
                         [UIView setAnimationDuration:0.5];
                         [UIView setAnimationDelegate:self];
                         [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
                         [UIView setAnimationTransition:anim2 forView:button cache:YES];
                         [UIView commitAnimations];
                     }];
}

-(void)animViews{
    UIColor *effectColor;
    UIColor *barColor;
    __block CGRect playlistToolBarOriginY = playlistActionView.frame;
    float iOS7effectDuration = 1.0f;
    BOOL hideLine = NO;
    if (!nowPlayingView.hidden) {
        hideLine = YES;
        iOS7effectDuration = 0.0f;
        nowPlayingView.hidden = YES;
        transitionView=nowPlayingView;
        transitionedView=playlistView;
        playlistHidden = NO;
        nowPlayingHidden = YES;
        viewTitle.text = NSLocalizedString(@"Playlist", nil);
        self.navigationItem.title = NSLocalizedString(@"Playlist", nil);
        self.navigationItem.titleView.hidden=YES;
        anim=UIViewAnimationTransitionFlipFromRight;
        anim2=UIViewAnimationTransitionFlipFromRight;
        effectColor = [UIColor clearColor];
        barColor = TINT_COLOR;
        playlistToolBarOriginY.origin.y = playlistTableView.frame.size.height - playlistTableView.contentInset.bottom;
        [self IOS7effect:effectColor barTintColor:barColor effectDuration:0.2f];
    }
    else {
        playlistView.hidden = YES;
        transitionView=playlistView;
        transitionedView=nowPlayingView;
        playlistHidden = YES;
        nowPlayingHidden = NO;
        viewTitle.text = NSLocalizedString(@"Now Playing", nil);
        self.navigationItem.title = NSLocalizedString(@"Now Playing", nil);
        self.navigationItem.titleView.hidden=YES;
        anim=UIViewAnimationTransitionFlipFromLeft;
        anim2=UIViewAnimationTransitionFlipFromLeft;
        if (foundEffectColor == nil){
            effectColor = [UIColor clearColor];
            barColor = TINT_COLOR;
        }
        else{
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
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:0.5
                                          animations:^{
                                              [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
                                              playlistView.hidden=playlistHidden;
                                              nowPlayingView.hidden=nowPlayingHidden;
                                              self.navigationItem.titleView.hidden=NO;
                                              playlistActionView.frame = playlistToolBarOriginY;
                                              playlistActionView.alpha = (int)nowPlayingHidden;
                                              playlistToolbar.clipsToBounds = hideLine;
                                              [UIView setAnimationTransition:anim2 forView:transitionedView cache:YES];
                                          }
                                          completion:^(BOOL finished){
                                              if (iOS7effectDuration){
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
            if ([AppDelegate instance].serverVersion>11){
                action=@"Player.GoTo";
                params=[NSArray arrayWithObjects:@"previous", @"to", nil];
                [self playbackAction:action params:params checkPartyMode:YES];
            }
            else{
                action=@"Player.GoPrevious";
                params=nil;
                [self playbackAction:action params:nil checkPartyMode:YES];
            }
            ProgressSlider.value = 0;
            break;
            
        case 2:
            action=@"Player.PlayPause";
            params=nil;
            [self playbackAction:action params:nil checkPartyMode:NO];
            break;
            
        case 3:
            action=@"Player.Stop";
            params=nil;
            [self playbackAction:action params:nil checkPartyMode:NO];
            storeSelection=nil;
            break;
            
        case 4:
            if ([AppDelegate instance].serverVersion>11){
                action=@"Player.GoTo";
                params=[NSArray arrayWithObjects:@"next", @"to", nil];
                [self playbackAction:action params:params checkPartyMode:YES];
            }
            else{
                action=@"Player.GoNext";
                params=nil;
                [self playbackAction:action params:nil checkPartyMode:YES];
            }
            break;
            
        case 5:
            [self animViews];       
            [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE];
            break;
            
        case 6:
            action=@"Player.Seek";
            params=[NSArray arrayWithObjects:@"smallbackward", @"value", nil];
            [self playbackAction:action params:params checkPartyMode:NO];
            break;
            
        case 7:
            action=@"Player.Seek";
            params=[NSArray arrayWithObjects:@"smallforward", @"value", nil];
            [self playbackAction:action params:params checkPartyMode:NO];
            break;
                    
        default:
            break;
    }
}



- (void)updateInfo{
    [self playbackInfo];
}

- (void)toggleSongDetails{
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

-(void)toggleHighlight:(UIButton *)button {
    button.highlighted = NO;
}

-(IBAction)changeShuffle:(id)sender{
    [shuffleButton setHighlighted:YES];
    [self performSelector:@selector(toggleHighlight:) withObject:shuffleButton afterDelay:.1];
    lastSelected=-1;
    storeSelection=nil;
    if ([AppDelegate instance].serverVersion>11){
        [self SimpleAction:@"Player.SetShuffle" params:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:currentPlayerID], @"playerid", @"toggle", @"shuffle", nil] reloadPlaylist:YES startProgressBar:NO];
        if (shuffled){
            [shuffleButton setBackgroundImage:[UIImage imageNamed:@"button_shuffle"] forState:UIControlStateNormal];
        }
        else{
            [shuffleButton setBackgroundImage:[UIImage imageNamed:@"button_shuffle_on"] forState:UIControlStateNormal];
        }
    }
    else{
        if (shuffled){
            [self SimpleAction:@"Player.UnShuffle" params:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:currentPlayerID],@"playerid", nil] reloadPlaylist:YES startProgressBar:NO];
            [shuffleButton setBackgroundImage:[UIImage imageNamed:@"button_shuffle"] forState:UIControlStateNormal];
        }
        else{
            [self SimpleAction:@"Player.Shuffle" params:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:currentPlayerID], @"playerid", nil] reloadPlaylist:YES startProgressBar:NO];
            [shuffleButton setBackgroundImage:[UIImage imageNamed:@"button_shuffle_on"] forState:UIControlStateNormal];
        }
    }
}

-(IBAction)changeRepeat:(id)sender{
    [repeatButton setHighlighted:YES];
    [self performSelector:@selector(toggleHighlight:) withObject:repeatButton afterDelay:.1];
    if ([AppDelegate instance].serverVersion>11){
        [self SimpleAction:@"Player.SetRepeat" params:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:currentPlayerID], @"playerid", @"cycle", @"repeat", nil] reloadPlaylist:NO startProgressBar:NO];
        if ([repeatStatus isEqualToString:@"off"]){
            [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat_all"] forState:UIControlStateNormal];
        }
        else if ([repeatStatus isEqualToString:@"all"]){
            [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat_one"] forState:UIControlStateNormal];

        }
        else if ([repeatStatus isEqualToString:@"one"]){
            [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat"] forState:UIControlStateNormal];
        }
    }
    else{
        if ([repeatStatus isEqualToString:@"off"]){
            [self SimpleAction:@"Player.Repeat" params:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:currentPlayerID], @"playerid", @"all", @"state", nil] reloadPlaylist:NO startProgressBar:NO];
            [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat_all"] forState:UIControlStateNormal];
        }
        else if ([repeatStatus isEqualToString:@"all"]){
            [self SimpleAction:@"Player.Repeat" params:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:currentPlayerID], @"playerid", @"one", @"state", nil] reloadPlaylist:NO startProgressBar:NO];
            [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat_one"] forState:UIControlStateNormal];
            
        }
        else if ([repeatStatus isEqualToString:@"one"]){
            [self SimpleAction:@"Player.Repeat" params:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:currentPlayerID], @"playerid", @"off", @"state", nil] reloadPlaylist:NO startProgressBar:NO];
            [repeatButton setBackgroundImage:[UIImage imageNamed:@"button_repeat"] forState:UIControlStateNormal];
        }
    }
}

#pragma mark - Touch Events & Gestures

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
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
    else if([touch.view isEqual:jewelView] || [touch.view isEqual:songDetailsView]){
        [self toggleSongDetails];
        [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE];
    }
}

-(void)updateCurrentLogo {
    GlobalData *obj=[GlobalData getInstance];
    NSString *serverURL=[NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
    if ([AppDelegate instance].serverVersion > 11){
        serverURL = [NSString stringWithFormat:@"%@:%@/image/", obj.serverIP, obj.serverPort];
    }
    if ([storeCurrentLogo isEqualToString:storeClearart]) {
        storeCurrentLogo = storeClearlogo;
    }
    else {
        storeCurrentLogo = storeClearart;
    }
    if (![storeCurrentLogo isEqualToString:@""]){
        NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [storeCurrentLogo stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
        [itemLogoImage setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:itemLogoImage.image];
    }
}

- (IBAction)buttonToggleItemInfo:(id)sender {
    [self toggleSongDetails];
}

-(void)showClearPlaylistAlert{
    if (playlistView.hidden == NO && self.view.superview != nil){
        NSString *playlistName=@"";
        if (playerID == 0){
            playlistName=NSLocalizedString(@"Music ", nil);
        }
        else if (playerID == 1){
            playlistName=NSLocalizedString(@"Video ", nil);
        }
        NSString *message=[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to clear the %@playlist?", nil), playlistName];
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:message message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Clear Playlist", nil), nil];
        [alertView show];
    }
}

-(IBAction)handleTableLongPress:(UILongPressGestureRecognizer *)gestureRecognizer{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan){
        CGPoint p = [gestureRecognizer locationInView:playlistTableView];
        NSIndexPath *indexPath = [playlistTableView indexPathForRowAtPoint:p];
        if (indexPath != nil){
            [sheetActions removeAllObjects];
            NSDictionary *item = [playlistData objectAtIndex:indexPath.row];
            selected = indexPath;
            CGPoint selectedPoint = [gestureRecognizer locationInView:self.view];
            if ([[item objectForKey:@"albumid"] intValue]>0){
                [sheetActions addObjectsFromArray:[NSArray arrayWithObjects:NSLocalizedString(@"Album Details", nil), NSLocalizedString(@"Album Tracks", nil), nil]];
            }
            if ([[item objectForKey:@"artistid"] intValue]>0 || ([[item objectForKey:@"type"] isEqualToString:@"song"] && [AppDelegate instance].serverVersion>11)){
                [sheetActions addObjectsFromArray:[NSArray arrayWithObjects:NSLocalizedString(@"Artist Details", nil), NSLocalizedString(@"Artist Albums", nil), nil]];
            }
            if ([[item objectForKey:@"movieid"] intValue]>0){
                if ([[item objectForKey:@"type"] isEqualToString:@"movie"]){
                    [sheetActions addObjectsFromArray:[NSArray arrayWithObjects:NSLocalizedString(@"Movie Details", nil), nil]];
                }
                else if ([[item objectForKey:@"type"] isEqualToString:@"episode"]){
                    [sheetActions addObjectsFromArray:[NSArray arrayWithObjects: NSLocalizedString(@"TV Show Details", nil), NSLocalizedString(@"Episode Details", nil), nil]];
                }
            }
            NSInteger numActions=[sheetActions count];
            if (numActions){
                 NSString *title= [item objectForKey:@"label"];
                if ([[item objectForKey:@"type"] isEqualToString:@"song"]){
                    title=[NSString stringWithFormat:@"%@\n%@\n%@", [item objectForKey:@"label"], [item objectForKey:@"album"], [item objectForKey:@"artist"]];
                }
                else if ([[item objectForKey:@"type"] isEqualToString:@"episode"]){
                    title=[NSString stringWithFormat:@"%@\n%@x%@. %@", [item objectForKey:@"showtitle"], [item objectForKey:@"season"], [item objectForKey:@"episode"], [item objectForKey:@"label"]];
                }
                UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:title
                                                                    delegate:self
                                                           cancelButtonTitle:nil
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:nil];
                action.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
                for (int i = 0; i < numActions; i++) {
                    [action addButtonWithTitle:[sheetActions objectAtIndex:i]];
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

-(IBAction)handleButtonLongPress:(UILongPressGestureRecognizer *)gestureRecognizer{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan){
        switch (gestureRecognizer.view.tag) {
            case 6:// BACKWARD BUTTON - DECREASE PLAYBACK SPEED
                [self playbackAction:@"Player.SetSpeed" params:[NSArray arrayWithObjects:@"decrement", @"speed", nil] checkPartyMode:NO];
                break;
                
            case 7:// FORWARD BUTTON - INCREASE PLAYBACK SPEED
                [self playbackAction:@"Player.SetSpeed" params:[NSArray arrayWithObjects:@"increment", @"speed", nil] checkPartyMode:NO];
                break;
                
            case 88:// EDIT TABLE
                [self showClearPlaylistAlert];
                break;

            default:
                break;
        }
    }
}

-(void)changeAlphaView:(UIView *)view alpha:(float)value time:(float)sec{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:sec];
	view.alpha = value;
    [UIView commitAnimations];
}

-(IBAction)stopUpdateProgressBar:(id)sender{
    updateProgressBar = FALSE;
    [self changeAlphaView:scrabbingView alpha:1.0 time:0.3];
}

-(IBAction)startUpdateProgressBar:(id)sender{
    [self SimpleAction:@"Player.Seek" params:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:playerID], @"playerid", [NSNumber numberWithFloat:ProgressSlider.value], @"value", nil] reloadPlaylist:NO startProgressBar:YES];
    [self changeAlphaView:scrabbingView alpha:0.0 time:0.3];
}

-(IBAction)updateCurrentTime:(id)sender{
    if (!updateProgressBar && !nothingIsPlaying){      
        int selectedTime = (ProgressSlider.value/100) * globalSeconds;
        NSUInteger h = selectedTime / 3600;
        NSUInteger m = (selectedTime / 60) % 60;
        NSUInteger s = selectedTime % 60;
        NSString *displaySelectedTime=[NSString stringWithFormat:@"%@%02lu:%02lu", (globalSeconds < 3600) ? @"":[NSString stringWithFormat:@"%02lu:", (unsigned long)h], (unsigned long)m, (unsigned long)s];
        currentTime.text = displaySelectedTime;
        scrabbingRate.text = NSLocalizedString(([NSString stringWithFormat:@"Scrubbing %@",[NSNumber numberWithFloat:ProgressSlider.scrubbingSpeed]]), nil);
    }
}

# pragma mark - UIActionSheet

- (NSMutableDictionary *) indexKeyedMutableDictionaryFromArray:(NSArray *)array {
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    NSInteger numelement=[array count];
    for (int i=0;i<numelement-1;i+=2){
        [mutableDictionary setObject:[array objectAtIndex:i] forKey:[array objectAtIndex:i+1]];
    }
    return (NSMutableDictionary *)mutableDictionary;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex!=actionSheet.cancelButtonIndex){
        NSDictionary *item = nil;
        NSInteger numPlaylistEntries = [playlistData count];
        if (selected.row < numPlaylistEntries) {
            item = [playlistData objectAtIndex:selected.row];
        }
        else {
            return;
        }
        choosedTab = -1;
        mainMenu *MenuItem = nil;
        notificationName = @"";
        if ([[item objectForKey:@"type"] isEqualToString:@"song"]){
            notificationName = @"UIApplicationEnableMusicSection";
            MenuItem = [[AppDelegate instance].playlistArtistAlbums copy];
            if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Album Details", nil)]) {
                choosedTab = 0;
                MenuItem.subItem.mainLabel=[item objectForKey:@"album"];
                [MenuItem.subItem setMainMethod:nil];
            }
            else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Album Tracks", nil)]){
                choosedTab = 0;
                MenuItem.subItem.mainLabel=[item objectForKey:@"album"];

            }
            else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Artist Details", nil)]) {
                choosedTab = 1;
                MenuItem.subItem.mainLabel=[item objectForKey:@"artist"];
                [MenuItem.subItem setMainMethod:nil];
            }
            else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Artist Albums", nil)]) {
                choosedTab = 1;
                MenuItem.subItem.mainLabel=[item objectForKey:@"artist"];
            }
            else {
                return;
            }
        }
        else if ([[item objectForKey:@"type"] isEqualToString:@"movie"]){
            MenuItem = [AppDelegate instance].playlistMovies;
            choosedTab = 0;
            MenuItem.subItem.mainLabel=[item objectForKey:@"label"];
            notificationName = @"UIApplicationEnableMovieSection";
        }
        else if ([[item objectForKey:@"type"] isEqualToString:@"episode"]){
            notificationName = @"UIApplicationEnableTvShowSection";
            if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Episode Details", nil)]) {
                MenuItem = [AppDelegate instance].playlistTvShows.subItem;
                choosedTab = 0;
                MenuItem.subItem.mainLabel=[item objectForKey:@"label"];
            }
            else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"TV Show Details", nil)]) {
                MenuItem = [[AppDelegate instance].playlistTvShows copy];
                [MenuItem.subItem setMainMethod:nil];
                choosedTab = 0;
                MenuItem.subItem.mainLabel=[item objectForKey:@"label"];
            }
        }
        else{
            return;
        }
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
                if ([[mainFields objectForKey:@"row6"] isEqualToString:@"artistid"]){ // WORKAROUND due the lack of the artistid with Playlist.GetItems
                    NSString *artistFrodoWorkaround = [NSString stringWithFormat:@"%@", [[item objectForKey:@"artist"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                    obj = [NSDictionary dictionaryWithObjectsAndKeys:artistFrodoWorkaround, @"artist", nil];
                }
                else{
                    obj = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[[item objectForKey:[mainFields objectForKey:@"row6"]] intValue]],[mainFields objectForKey:@"row6"], nil];
                }
                objKey = @"filter";
            }
            NSMutableArray *newParameters=[NSMutableArray arrayWithObjects:
                                           [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            obj,objKey,
                                            [[parameters objectForKey:@"parameters"] objectForKey:@"properties"], @"properties",
                                            [[parameters objectForKey:@"parameters"] objectForKey:@"sort"],@"sort",
                                            [item objectForKey:[mainFields objectForKey:@"row15"]], key,
                                            nil], @"parameters", [parameters objectForKey:@"label"], @"label",
                                           [parameters objectForKey:@"extra_info_parameters"], @"extra_info_parameters",
                                           [NSDictionary dictionaryWithDictionary:[parameters objectForKey:@"itemSizes"]], @"itemSizes",
                                           [NSString stringWithFormat:@"%d",[[parameters objectForKey:@"enableCollectionView"] boolValue]], @"enableCollectionView",
                                           nil];
            [[MenuItem.subItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
            MenuItem.subItem.chooseTab=choosedTab;
            fromItself = TRUE;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
                self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
                self.detailViewController.detailItem = MenuItem.subItem;
                [self.navigationController pushViewController:self.detailViewController animated:YES];
            }
            else{
                DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem.subItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
                [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:TRUE];
                [[AppDelegate instance].windowController.stackScrollViewController enablePanGestureRecognizer];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object: nil];
            }
        }
        else{
            [self showInfo:item menuItem:MenuItem indexPath:selected];
        }
    }
    
}

# pragma mark - UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1){
        [self clearPlaylist:playerID];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [playlistData count];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//	cell.backgroundColor = [UIColor colorWithRed:0.85f green:0.85f blue:0.85f alpha:1];
    cell.backgroundColor = cellBackgroundColor;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"playlistCell"];
    if (cell == nil){
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"playlistCellView" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        [(UILabel*) [cell viewWithTag:1] setHighlightedTextColor:[UIColor blackColor]];
        [(UILabel*) [cell viewWithTag:2] setHighlightedTextColor:[UIColor blackColor]];
        [(UILabel*) [cell viewWithTag:3] setHighlightedTextColor:[UIColor blackColor]];
    }
    NSDictionary *item = [playlistData objectAtIndex:indexPath.row];
    UIImageView *thumb = (UIImageView*) [cell viewWithTag:4];
    
    UILabel *mainLabel = (UILabel*) [cell viewWithTag:1];
    UILabel *subLabel = (UILabel*) [cell viewWithTag:2];
    UILabel *cornerLabel = (UILabel*) [cell viewWithTag:3];

    [mainLabel setText:![[item objectForKey:@"title"] isEqualToString:@""] ? [item objectForKey:@"title"] : [item objectForKey:@"label"] ];
    [(UILabel*) [cell viewWithTag:2] setText:@""];
    if ([[item objectForKey:@"type"] isEqualToString:@"episode"]){
        if ([[item objectForKey:@"season"] intValue]!=0 || [[item objectForKey:@"episode"] intValue]!=0){
            [mainLabel setText:[NSString stringWithFormat:@"%@x%02i. %@", [item objectForKey:@"season"], [[item objectForKey:@"episode"] intValue], [item objectForKey:@"label"]]];
        }
        [subLabel setText:[NSString stringWithFormat:@"%@", [item objectForKey:@"showtitle"]]];
    }
    else if ([[item objectForKey:@"type"] isEqualToString:@"song"]){
        NSString *artist = [[item objectForKey:@"artist"] length]==0? @"" :[NSString stringWithFormat:@" - %@", [item objectForKey:@"artist"]];
        [subLabel setText:[NSString stringWithFormat:@"%@%@",[item objectForKey:@"album"], artist]];
    }
    else if ([[item objectForKey:@"type"] isEqualToString:@"movie"]){
        [subLabel setText:[NSString stringWithFormat:@"%@",[item objectForKey:@"genre"]]];
    }
    if (playerID == 0)
        [cornerLabel setText:[item objectForKey:@"duration"]];
    if (playerID == 1)
        [cornerLabel setText:[item objectForKey:@"runtime"]];
    NSString *stringURL = [item objectForKey:@"thumbnail"]; 
    [thumb setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:@"nocover_music.png"]];
    // andResize:CGSizeMake(thumb.frame.size.width, thumb.frame.size.height)
    UIView *timePlaying = (UIView*) [cell viewWithTag:5];
    if (timePlaying.hidden == NO){
        [self fadeView:timePlaying hidden:YES];
    }
    
    return cell;
}
-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
    UIImageView *coverView=(UIImageView*) [cell viewWithTag:4];
    coverView.alpha=1.0;
    UIView *timePlaying=(UIView*) [cell viewWithTag:5];
    storeSelection=nil;
    if (timePlaying.hidden==NO)
        [self fadeView:timePlaying hidden:YES];
}

-(void)checkPartyMode{
    if (musicPartyMode){
        lastSelected=-1;
        storeSelection=0;
        [self createPlaylist:NO animTableView:YES];
    }
 }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
    UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
    storeSelection=nil;
    [queuing startAnimating];
    if (playerID==-2)
        playerID=0;
    jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    [jsonRPC 
     callMethod:@"Player.Open" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithInt:(int)indexPath.row], @"position", [NSNumber numberWithInt:playerID], @"playlistid", nil], @"item", nil]
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error==nil && methodError==nil){
             storedItemID=-1;
             UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
             [queuing stopAnimating];
             UIView *timePlaying=(UIView*) [cell viewWithTag:5];
             if (timePlaying.hidden==YES){
                 [self fadeView:timePlaying hidden:NO];
             }
//             [self SimpleAction:@"GUI.SetFullscreen" params:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"fullscreen", nil] reloadPlaylist:NO startProgressBar:NO];
         }
         else {
             UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
             [queuing stopAnimating];
         }
     }
     ];
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (storeSelection && storeSelection.row==indexPath.row)
        return NO;
    return YES;
}

- (BOOL)tableView:(UITableView *)tableview canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    
    NSDictionary *objSource = [playlistData objectAtIndex:sourceIndexPath.row];
    NSDictionary *itemToMove;
    
    int idItem=[[objSource objectForKey:@"idItem"] intValue];
    if (idItem){
        itemToMove = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithInt:idItem], [NSString stringWithFormat:@"%@id", [objSource objectForKey:@"type"]],
                      nil];
    }
    else{
        itemToMove = [NSDictionary dictionaryWithObjectsAndKeys:
                      [objSource objectForKey:@"file"], @"file",
                      nil];
    }
    
    NSString *action1=@"Playlist.Remove";
    NSDictionary *params1=[NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:playerID], @"playlistid",
                          [NSNumber numberWithInt:(int)sourceIndexPath.row],@"position",
                          nil] ;
    NSString *action2=@"Playlist.Insert";
    NSDictionary *params2=[NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:playerID], @"playlistid",
                          itemToMove, @"item",
                          [NSNumber numberWithInt:(int)destinationIndexPath.row],@"position",
                          nil];
    jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    [jsonRPC callMethod:action1 withParameters:params1 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            [jsonRPC callMethod:action2 withParameters:params2];
            NSInteger numObj = [playlistData count];
            if ([sourceIndexPath row] < numObj){
                [playlistData removeObjectAtIndex:[sourceIndexPath row]];
            }
            [playlistData insertObject:objSource atIndex:[destinationIndexPath row]];
            if (sourceIndexPath.row>storeSelection.row && destinationIndexPath.row<=storeSelection.row){
                storeSelection=[NSIndexPath  indexPathForRow:storeSelection.row+1 inSection:storeSelection.section];
            }
            else if (sourceIndexPath.row<storeSelection.row && destinationIndexPath.row>=storeSelection.row){
                storeSelection=[NSIndexPath  indexPathForRow:storeSelection.row-1 inSection:storeSelection.section];
            }
            [playlistTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
        }
        else{
            [playlistTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
            [playlistTableView selectRowAtIndexPath:storeSelection animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        }
    }];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        jsonRPC = nil;
        jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
        NSString *action1=@"Playlist.Remove";
        NSDictionary *params1=[NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithInt:playerID], @"playlistid",
                               [NSNumber numberWithInt:(int)indexPath.row],@"position",
                               nil] ;
        [jsonRPC callMethod:action1 withParameters:params1 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            if (error==nil && methodError==nil){
                NSInteger numObj = [playlistData count];
                if ([indexPath row] < numObj){
                    [playlistData removeObjectAtIndex:indexPath.row];
                }
                [playlistTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
                if ((storeSelection) && (indexPath.row<storeSelection.row)){
                    storeSelection=[NSIndexPath  indexPathForRow:storeSelection.row-1 inSection:storeSelection.section];
                }
            }
            else{
                [playlistTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
                [playlistTableView selectRowAtIndexPath:storeSelection animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            }
        }];
    } 
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if (playlistTableView.editing) {
        return NO;
        
    } else {
        return YES;
    }
}

-(IBAction)editTable:(id)sender forceClose:(BOOL)forceClose{
    if (sender != nil){
        forceClose = FALSE;
    }
    if ([playlistData count]==0 && !playlistTableView.editing) {
        return;
    }
    if (playlistTableView.editing || forceClose==YES){
        [playlistTableView setEditing:NO animated:YES];
        [editTableButton setSelected:NO];
        lastSelected=-1;
        storeSelection=nil;
    }
    else{
        storeSelection = [playlistTableView indexPathForSelectedRow];
        [playlistTableView setEditing:YES animated:YES];
        [editTableButton setSelected:YES];
    }
}

# pragma  mark - Swipe Gestures

- (void)handleSwipeFromRight:(id)sender {
    if (updateProgressBar){
        if ([self.navigationController.viewControllers indexOfObject:self] == 0){
            [self revealMenu:nil];
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)handleSwipeFromLeft:(id)sender {
    if (updateProgressBar){
        [self revealUnderRight:nil];
    }
}

-(void)showRemoteController{
    if (updateProgressBar){
        if (self.remoteController == nil){
            self.remoteController = [[RemoteController alloc] initWithNibName:@"RemoteController" bundle:nil];
        }
        mainMenu *item = [[mainMenu alloc] init];
        item.mainLabel = NSLocalizedString(@"Remote Control", nil);
        self.remoteController.detailItem = item;
        fromItself = TRUE;
        [self.navigationController pushViewController:self.remoteController animated:YES];
    }
}

#pragma mark - Interface customizations

-(void)setToolbarWidth:(int)width height:(int)height YPOS:(int)YPOS playBarWidth:(int)playBarWidth portrait:(BOOL)isPortrait{
    CGRect frame;
    barwidth = playBarWidth;
    frame=playlistToolbar.frame;
    frame.size.width=width+20;
    frame.origin.x=0;
    playlistToolbar.frame=frame;
    frame=nowPlayingView.frame;
    frame.origin.x=302;
    frame.origin.y=YPOS;
    frame.size.height=height - 84;
    frame.size.width=width - 302;
    nowPlayingView.frame=frame;
    portraitMode = isPortrait;
    
    frame = iOS7bgEffect.frame;
    frame.size.width = width;
    iOS7bgEffect.frame = frame;
    [self setCoverSize:currentType];
}

-(void)setIphoneInterface{
    slideFrom = [self currentScreenBoundsDependOnOrientation].size.width;
    xbmcOverlayImage.hidden = YES;
}

-(void)setIpadInterface:(float)toolbarAlpha{
    playlistLeftShadow.hidden = NO;
    slideFrom=-300;
    CGRect frame;
    [albumName setFont:[UIFont systemFontOfSize:24]];
    frame=albumName.frame;
    frame.origin.y=10;
    albumName.frame=frame;
    [songName setFont:[UIFont systemFontOfSize:18]];

    frame=songName.frame;
    frame.origin.y=frame.origin.y+6;
    songName.frame=frame;
    
    [artistName setFont:[UIFont systemFontOfSize:16]];
    frame=artistName.frame;
    frame.origin.y=frame.origin.y+12;
    artistName.frame=frame;
    
    [currentTime setFont:[UIFont systemFontOfSize:14]];
    [duration setFont:[UIFont systemFontOfSize:14]];

    frame=playlistTableView.frame;
    frame.origin.x=slideFrom;
    playlistTableView.frame=frame;
    
    frame = ProgressSlider.frame;
    frame.origin.y = frame.origin.y - 5;
    ProgressSlider.frame = frame;
    
    NSMutableArray *items = [NSMutableArray arrayWithArray:playlistToolbar.items];
    [items removeObjectAtIndex:0];
    [items removeObjectAtIndex:1];
    [items removeObjectAtIndex:2];
    [items removeObjectAtIndex:3];
    [items removeObjectAtIndex:4];
    [items removeObjectAtIndex:5];
    [items removeObjectAtIndex:6];
    [items removeObjectAtIndex:7];
    [playlistToolbar setItems:items animated:YES];
    playlistToolbar.alpha = toolbarAlpha;
    UIButton *buttonItem=(UIButton *)[self.view viewWithTag:5];
    [buttonItem removeFromSuperview];
    
    nowPlayingView.hidden=NO;
    playlistView.hidden=NO;
    xbmcOverlayImage_iphone.hidden = YES;
    
    frame = playlistActionView.frame;
    frame.origin.y = playlistToolbar.frame.origin.y - playlistToolbar.frame.size.height;
    playlistActionView.frame = frame;
    playlistActionView.alpha = 1.0f;
    
    frame = scrabbingView.frame;
    frame.origin.y =frame.origin.y - 24.0f;
    [scrabbingView setFrame:frame];
    [itemDescription setFont:[UIFont systemFontOfSize:15]];
}

-(bool)enableJewelCases{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    return [[userDefaults objectForKey:@"jewel_preference"] boolValue];
}

#pragma mark - GestureRecognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UISlider class]]) {
        return NO;
    }
    return YES;
}

#pragma mark - UISegmentControl

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

-(void)addSegmentControl{
    seg_music.hidden = YES;
    seg_video.hidden = YES;
    playlistSegmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
                                                                          NSLocalizedString(@"Music", nil),
                                                                          [[NSLocalizedString(@"Video ", nil) capitalizedString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]], nil
                                                                          ]
                                ];
    float seg_width = 122.0f;
    float left_margin = 99.0f;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        left_margin = (int)(([self currentScreenBoundsDependOnOrientation].size.width/2) - (seg_width/2));
    }
    playlistSegmentedControl.frame = CGRectMake(left_margin, 7, seg_width, 29);
    playlistSegmentedControl.tintColor = [UIColor whiteColor];
    [playlistSegmentedControl addTarget:self action:@selector(segmentValueChanged:) forControlEvents: UIControlEventValueChanged];
    [playlistActionView addSubview:playlistSegmentedControl];
}

- (void)segmentValueChanged:(UISegmentedControl *)segment {
    [self editTable:nil forceClose:YES];
    if ([playlistData count] && (playlistTableView.dragging == YES || playlistTableView.decelerating == YES)){
        NSArray *visiblePaths = [playlistTableView indexPathsForVisibleRows];
        [playlistTableView  scrollToRowAtIndexPath:[visiblePaths objectAtIndex:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    if(segment.selectedSegmentIndex == 0) {
        lastSelected=-1;
        seg_music.selected=YES;
        seg_video.selected=NO;
        selectedPlayerID=0;
        musicPartyMode=0;
        [self createPlaylist:NO animTableView:YES];
        
    }else if(segment.selectedSegmentIndex == 1){
        lastSelected=-1;
        seg_music.selected=NO;
        seg_video.selected=YES;
        selectedPlayerID=1;
        musicPartyMode=0;
        [self createPlaylist:NO animTableView:YES];
    }
}

#pragma mark - Life Cycle

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if (self.slidingViewController.panGesture != nil) {
            [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
        }
        if ([self.navigationController.viewControllers indexOfObject:self] == 0){
            UIImage* menuImg = [UIImage imageNamed:@"button_menu"];
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:menuImg style:UIBarButtonItemStylePlain target:nil action:@selector(revealMenu:)];
        }
        UIImage* settingsImg = [UIImage imageNamed:@"button_settings"];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:settingsImg style:UIBarButtonItemStylePlain target:self action:@selector(revealUnderRight:)];
        self.slidingViewController.underRightViewController = nil;
        self.slidingViewController.panGesture.delegate = self;
    }
    if (!fromItself){
        if (nowPlayingView.hidden){
            nowPlayingView.hidden = NO;
            nowPlayingHidden = NO;
            playlistView.hidden = YES;
            playlistHidden = YES;
            viewTitle.text = NSLocalizedString(@"Now Playing", nil);
            self.navigationItem.title = NSLocalizedString(@"Now Playing", nil);
            CGRect playlistToolBarOriginY = playlistActionView.frame;
            playlistToolBarOriginY.origin.y = playlistToolbar.frame.origin.y + playlistToolbar.frame.size.height;
            playlistActionView.frame = playlistToolBarOriginY;
        }
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            startFlipDemo = YES;
            UIImage *buttonImage;
            if ([self enableJewelCases]){
                buttonImage=[self resizeImage:thumbnailView.image width:76 height:66 padding:10];
            }
            else {
                buttonImage=[self resizeImage:jewelView.image width:76 height:66 padding:10];
            }
            if (buttonImage.size.width!=0){
                [playlistButton setImage:buttonImage forState:UIControlStateNormal];
                [playlistButton setImage:buttonImage forState:UIControlStateHighlighted];
                [playlistButton setImage:buttonImage forState:UIControlStateSelected];
            }
            else{
                [playlistButton setImage:[UIImage imageNamed:@"xbmc_overlay_small"] forState:UIControlStateNormal];
                [playlistButton setImage:[UIImage imageNamed:@"xbmc_overlay_small"] forState:UIControlStateHighlighted];
                [playlistButton setImage:[UIImage imageNamed:@"xbmc_overlay_small"] forState:UIControlStateSelected];
            }
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
                                             selector: @selector(handleShakeNotification)
                                                 name: @"UIApplicationShakeNotification"
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

- (void) handleDidEnterBackground: (NSNotification*) sender{
    [self viewWillDisappear:YES];
}

-(void)disableInteractivePopGestureRecognizer:(id)sender{
    if ([[sender name] isEqualToString:@"ECSlidingViewUnderRightWillAppear"]){
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    else{
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}

- (void)revealMenu:(id)sender{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)revealUnderRight:(id)sender{
    [self.slidingViewController anchorTopViewTo:ECLeft];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self handleXBMCPlaylistHasChanged:nil];
    [self playbackInfo];
    updateProgressBar = YES;
    if (timer != nil){
        [timer invalidate];
        timer = nil;
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateInfo) userInfo:nil repeats:YES];
    fromItself = FALSE;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.slidingViewController.underRightViewController = nil;
        RightMenuViewController *rightMenuViewController = [[RightMenuViewController alloc] initWithNibName:@"RightMenuViewController" bundle:nil];
        rightMenuViewController.rightMenuItems = [AppDelegate instance].nowPlayingMenuItems;
        self.slidingViewController.underRightViewController = rightMenuViewController;
    }
    int effectHeight = 22;
    int barEffectHeight = 32;
    if (iOS7bgEffect == nil){
        iOS7bgEffect = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, effectHeight)];
        iOS7bgEffect.autoresizingMask = playlistToolbar.autoresizingMask;
        [self.view insertSubview:iOS7bgEffect atIndex:0];
    }
    if (iOS7navBarEffect == nil && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        iOS7navBarEffect = [[UIView alloc] initWithFrame:CGRectMake(0, 64 - barEffectHeight, self.view.frame.size.width, barEffectHeight)];
        iOS7navBarEffect.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self.view insertSubview:iOS7navBarEffect atIndex:0];
    }
}

-(void)startFlipDemo{
    [self flipAnimButton:playlistButton demo:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [timer invalidate];
    currentItemID = -1;
    self.slidingViewController.panGesture.delegate = nil;
    self.navigationController.navigationBar.tintColor = TINT_COLOR;
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self AnimTable:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:slideFrom];
    songDetailsView.alpha = 0;
    [playlistTableView setEditing:NO animated:YES];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

-(void)setIOS7toolbar{
    UIButton *buttonItem= nil;
    for (int i=1; i<8; i++) {
        buttonItem=(UIButton *)[self.view viewWithTag:i];
        [buttonItem setBackgroundImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
        [buttonItem setBackgroundImage:[UIImage imageNamed:@""] forState:UIControlStateHighlighted];
    }
    
    [editTableButton setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateNormal];
    [editTableButton setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateHighlighted];
    [editTableButton setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateSelected];
    [editTableButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [editTableButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [editTableButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [editTableButton.titleLabel setShadowOffset:CGSizeMake(0, 0)];
    
    [PartyModeButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [PartyModeButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [PartyModeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [PartyModeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [PartyModeButton.titleLabel setShadowOffset:CGSizeMake(0, 0)];


}

- (void)viewDidLoad{
    [super viewDidLoad];
    SDWebImageDownloader *manager = [SDWebImageManager sharedManager].imageDownloader;
    NSDictionary *httpHeaders = [AppDelegate instance].getServerHTTPHeaders;
    if ([httpHeaders objectForKey:@"Authorization"] != nil){
        [manager setValue:[httpHeaders objectForKey:@"Authorization"] forHTTPHeaderField:@"Authorization"];
    }
    [itemDescription setSelectable:FALSE];
    [itemLogoImage.layer setMinificationFilter:kCAFilterTrilinear];
    [songCodecImage.layer setMinificationFilter:kCAFilterTrilinear];
    [songBitRateImage.layer setMinificationFilter:kCAFilterTrilinear];
    [songSampleRateImage.layer setMinificationFilter:kCAFilterTrilinear];
    [songNumChanImage.layer setMinificationFilter:kCAFilterTrilinear];
    tempFanartImageView = [[UIImageView alloc] init];
    tempFanartImageView.hidden = YES;
    [self.view addSubview:tempFanartImageView];
    [seg_music setTitle:NSLocalizedString(@"Music",nil) forState:UIControlStateNormal];
    [seg_video setTitle:NSLocalizedString(@"Video",nil) forState:UIControlStateNormal];
    [PartyModeButton setTitle:NSLocalizedString(@"Party",nil) forState:UIControlStateNormal];
    [PartyModeButton setTitle:NSLocalizedString(@"Party",nil) forState:UIControlStateHighlighted];
    [PartyModeButton setTitle:NSLocalizedString(@"Party",nil) forState:UIControlStateSelected];
    [editTableButton setTitle:NSLocalizedString(@"Edit",nil) forState:UIControlStateNormal];
    [editTableButton setTitle:NSLocalizedString(@"Done",nil) forState:UIControlStateSelected];
    editTableButton.titleLabel.numberOfLines = 1;
    editTableButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [noItemsLabel setText:NSLocalizedString(@"No items found.", nil)];
    float toolbarAlpha = 0.8f;
    pg_thumb_name = @"pgbar_thumb";
    cellBackgroundColor = [UIColor colorWithRed:0.85f green:0.85f blue:0.85f alpha:1];
    [self addSegmentControl];
    pg_thumb_name = @"pgbar_thumb_iOS7";
    cellBackgroundColor = [UIColor whiteColor];
    toolbarAlpha = 1.0f;
    int barHeight = 44;
    int statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        UIEdgeInsets tableViewInsets = UIEdgeInsetsZero;
        tableViewInsets.top = barHeight + statusBarHeight;
        playlistTableView.contentInset = tableViewInsets;
        playlistTableView.scrollIndicatorInsets = tableViewInsets;
        CGRect frame = xbmcOverlayImage_iphone.frame;
        frame.origin.y = frame.origin.y + barHeight - statusBarHeight/2;
        xbmcOverlayImage_iphone.frame = frame;
        frame = noFoundView.frame;
        frame.origin.y = frame.origin.y + barHeight + statusBarHeight;
        noFoundView.frame = frame;
        
        tableViewInsets = playlistTableView.contentInset;
        tableViewInsets.bottom = barHeight * 2;
        playlistTableView.contentInset = tableViewInsets;
        playlistTableView.scrollIndicatorInsets = tableViewInsets;
        
        frame= playlistTableView.frame;
        frame.size.height=self.view.bounds.size.height;
        playlistView.frame = frame;
        playlistTableView.frame = frame;
    }
    [self setIOS7toolbar];
    [playlistTableView setSeparatorInset:UIEdgeInsetsMake(0, 53, 0, 0)];
    CGRect frame;
    frame = nowPlayingView.frame;
    frame.origin.y = barHeight + statusBarHeight;
    frame.size.height = frame.size.height - barHeight - statusBarHeight;
    nowPlayingView.frame = frame;
    
    [ProgressSlider setMinimumTrackTintColor:SLIDER_DEFAULT_COLOR];
    [ProgressSlider setMaximumTrackTintColor:APP_TINT_COLOR];
    playlistTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    ProgressSlider.userInteractionEnabled = NO;
    [ProgressSlider setThumbImage:[[UIImage alloc] init] forState:UIControlStateNormal];
    [ProgressSlider setThumbImage:[[UIImage alloc] init] forState:UIControlStateHighlighted];
    [scrabbingMessage setText:NSLocalizedString(@"Slide your finger up to adjust the scrubbing rate.", nil)];
    [scrabbingRate setText:NSLocalizedString(@"Scrubbing 1", nil)];
    sheetActions = [[NSMutableArray alloc] init];
    playerID = -1;
    selectedPlayerID = -1;
    lastSelected = -1;
    storedItemID = -1;
    storeSelection = nil;
    albumDetailsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    albumTracksButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    artistDetailsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    artistAlbumsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self setIphoneInterface];
    }
    else{
        [self setIpadInterface:toolbarAlpha];
    }
    playlistData = [[NSMutableArray alloc] init ];
}

- (void)connectionSuccess:(NSNotification *)note {
    SDWebImageDownloader *manager = [SDWebImageManager sharedManager].imageDownloader;
    NSDictionary *httpHeaders = [AppDelegate instance].getServerHTTPHeaders;
    if ([httpHeaders objectForKey:@"Authorization"] != nil){
        [manager setValue:[httpHeaders objectForKey:@"Authorization"] forHTTPHeaderField:@"Authorization"];
    }
}

-(void)handleShakeNotification{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    BOOL shake_preference=[[userDefaults objectForKey:@"shake_preference"] boolValue];
    if (shake_preference) {
        [self showClearPlaylistAlert];
    }
}

- (void) handleEnterForeground: (NSNotification*) sender{
    [self handleXBMCPlaylistHasChanged:nil];
    [self playbackInfo];
    updateProgressBar = YES;
    if (timer != nil){
        [timer invalidate];
        timer = nil;
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateInfo) userInfo:nil repeats:YES];
}

- (void) handleXBMCPlaylistHasChanged: (NSNotification*) sender{
    playerID = -1;
    selectedPlayerID = -1;
    lastSelected = -1;
    storedItemID = -1;
    storeSelection = nil;
    lastThumbnail = @"";
    [playlistData performSelectorOnMainThread:@selector(removeAllObjects) withObject:nil waitUntilDone:YES];
    [playlistTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

- (void)viewDidUnload{
    playlistLeftShadow = nil;
    scrabbingView = nil;
    scrabbingMessage = nil;
    scrabbingRate = nil;
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    volumeSliderView = nil;
    [timer invalidate];
    timer = nil;
}

-(void)dealloc{
    volumeSliderView = nil;
    self.detailItem = nil;
    playlistData = nil;
    jsonRPC = nil;
    self.remoteController=nil;
    sheetActions = nil;
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [timer invalidate];
    timer = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    return UIInterfaceOrientationMaskPortrait;
}

@end
