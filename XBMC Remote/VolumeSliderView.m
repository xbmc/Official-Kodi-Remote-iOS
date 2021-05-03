//
//  VolumeSliderView.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "VolumeSliderView.h"
#import "GlobalData.h"
#import "DSJSONRPC.h"
#import "AppDelegate.h"
#import "Utilities.h"

#define VOLUMEICON_PADDING 10 /* space left/right from volume icons */
#define VOLUMEVIEW_OFFSET 8 /* vertical offset to match menu */
#define VOLUMESLIDER_HEIGHT 44
#define SERVER_TIMEOUT 3.0

@implementation VolumeSliderView

@synthesize timer, holdVolumeTimer;

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        Utilities *utils = [[Utilities alloc] init];
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VolumeSliderView" owner:self options:nil];
		self = [nib objectAtIndex:0];
        pg_thumb_name = @"pgbar_thumb_iOS7.png";
        [volumeSlider setMinimumTrackTintColor:SLIDER_DEFAULT_COLOR];
        [volumeSlider setMaximumTrackTintColor:APP_TINT_COLOR];
        [volumeSlider setThumbImage:[UIImage imageNamed:pg_thumb_name] forState:UIControlStateNormal];
        [volumeSlider setThumbImage:[UIImage imageNamed:pg_thumb_name] forState:UIControlStateHighlighted];
        [self volumeInfo];
        volumeSlider.tag = 10;
        [volumeSlider addTarget:self action:@selector(changeServerVolume:) forControlEvents:UIControlEventTouchUpInside];
        [volumeSlider addTarget:self action:@selector(changeServerVolume:) forControlEvents:UIControlEventTouchUpOutside];
        [volumeSlider addTarget:self action:@selector(stopTimer) forControlEvents:UIControlEventTouchDown];
        CGRect frame_tmp;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            volumeLabel.alpha = 0.8;
            [volumeLabel setFrame:CGRectMake(volumeLabel.frame.origin.x, volumeLabel.frame.origin.y, volumeLabel.frame.size.width, volumeLabel.frame.size.height)];
            volumeView.hidden = YES;
            volumeSlider.hidden = YES;
            
            frame_tmp = muteButton.frame;
            frame_tmp.origin.x = 0;
            muteButton.frame = frame_tmp;
            
            frame_tmp = minusButton.frame;
            frame_tmp.origin.x = muteButton.frame.origin.x + muteButton.frame.size.width;
            minusButton.frame = frame_tmp;
            
            frame_tmp = volumeLabel.frame;
            frame_tmp.origin.x = minusButton.frame.origin.x + minusButton.frame.size.width;
            volumeLabel.frame= frame_tmp;
            
            frame_tmp = plusButton.frame;
            frame_tmp.origin.x = volumeLabel.frame.origin.x + volumeLabel.frame.size.width;
            plusButton.frame = frame_tmp;
            
            UIImage *img = [UIImage imageNamed:@"button_metal_up"];
            [muteButton setBackgroundImage:img forState:UIControlStateNormal];
            [muteButton setBackgroundImage:img forState:UIControlStateHighlighted];
            img = [UIImage imageNamed:@"volume_slash"];
            img = [utils colorizeImage:img withColor:[UIColor darkGrayColor]];
            [muteButton setImage:img forState:UIControlStateNormal];
            [muteButton setShowsTouchWhenHighlighted:YES];
            
            img = [UIImage imageNamed:@"button_metal_down"];
            [minusButton setBackgroundImage:img forState:UIControlStateNormal];
            [minusButton setBackgroundImage:img forState:UIControlStateHighlighted];
            
            img = [UIImage imageNamed:@"button_metal_up"];
            [plusButton setBackgroundImage:img forState:UIControlStateNormal];
            [plusButton setBackgroundImage:img forState:UIControlStateHighlighted];
            
            // set final used width for this view
            frame_tmp = frame;
            frame_tmp.size.width = plusButton.frame.origin.x + plusButton.frame.size.width;
            self.frame = frame_tmp;
        }
        else {
            minusButton.hidden = YES;
            plusButton.hidden = YES;
            
            UIImage *img = [UIImage imageNamed:@"button_metal_up"];
            img = [utils colorizeImage:img withColor:[UIColor grayColor]];
            [muteButton setBackgroundImage:img forState:UIControlStateNormal];
            [muteButton setBackgroundImage:img forState:UIControlStateHighlighted];
            img = [UIImage imageNamed:@"volume_slash"];
            img = [utils colorizeImage:img withColor:[UIColor darkGrayColor]];
            [muteButton setImage:img forState:UIControlStateNormal];
            [muteButton setShowsTouchWhenHighlighted:YES];

            volumeView.hidden = YES;
            volumeLabel.hidden = YES;

            self.frame = CGRectMake(0, VOLUMEVIEW_OFFSET, [self currentScreenBoundsDependOnOrientation].size.width, VOLUMESLIDER_HEIGHT);
            
            frame_tmp = muteButton.frame;
            frame_tmp.origin.x = VOLUMEICON_PADDING;
            muteButton.frame = frame_tmp;
            
            frame_tmp = volumeSlider.frame;
            frame_tmp.origin.x = muteButton.frame.origin.x + muteButton.frame.size.width + VOLUMEICON_PADDING;
            frame_tmp.size.width = self.frame.size.width - frame_tmp.origin.x - ANCHORRIGHTPEEK - VOLUMEICON_PADDING;
            volumeSlider.frame = frame_tmp;
            
            img = [UIImage imageNamed:@"volume_1"];
            img = [utils colorizeImage:img withColor:[UIColor grayColor]];
            [volumeSlider setMinimumValueImage:img];
            img = [UIImage imageNamed:@"volume_3"];
            img = [utils colorizeImage:img withColor:[UIColor grayColor]];
            [volumeSlider setMaximumValueImage:img];
        }
        [self checkMuteServer];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleApplicationOnVolumeChanged:)
                                                     name: @"Application.OnVolumeChanged"
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleServerStatusChanged:)
                                                     name: @"TcpJSONRPCChangeServerStatus"
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleEnterForeground:)
                                                     name: @"UIApplicationWillEnterForegroundNotification"
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleDidEnterBackground:)
                                                     name: @"UIApplicationDidEnterBackgroundNotification"
                                                   object: nil];
    }
    return self;
}

-(CGRect)currentScreenBoundsDependOnOrientation {
    return UIScreen.mainScreen.bounds;
}

-(void)handleServerStatusChanged:(NSNotification *)sender{
    volumeLabel.text = [NSString stringWithFormat:@"%d", [AppDelegate instance].serverVolume];
    volumeSlider.value = [AppDelegate instance].serverVolume;
    [self checkMuteServer];
}

-(void)handleApplicationOnVolumeChanged:(NSNotification *)sender{
    if (holdVolumeTimer == nil) {
        [AppDelegate instance].serverVolume = [[sender userInfo][@"params"][@"data"][@"volume"] intValue];
        [self handleServerStatusChanged:nil];
    }
}

- (void) handleDidEnterBackground: (NSNotification*) sender{
    [self stopTimer];
}

- (void) handleEnterForeground: (NSNotification*) sender{
    [self startTimer];
}

-(void)changeServerVolume:(id)sender{
    jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    [jsonRPC 
     callMethod:@"Application.SetVolume" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:(int)volumeSlider.value], @"volume", nil]];
    if ([sender tag] == 10){
        [self startTimer];
    }
}

-(void)startTimer{
    volumeLabel.text = [NSString stringWithFormat:@"%d", [AppDelegate instance].serverVolume];
    volumeSlider.value = [AppDelegate instance].serverVolume;
    [self stopTimer];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(volumeInfo) userInfo:nil repeats:YES];
}

-(void)stopTimer{
    if (self.timer!=nil){
        [self.timer invalidate];
        self.timer=nil;
    }
}

-(void)volumeInfo{
    if ([AppDelegate instance].serverTCPConnectionOpen == YES) {
        return;
    }
    if ([AppDelegate instance].serverVolume > -1){
        volumeLabel.text = [NSString stringWithFormat:@"%d", [AppDelegate instance].serverVolume];
        volumeSlider.value = [AppDelegate instance].serverVolume;
    }
    else{
        volumeLabel.text = @"0";
        volumeSlider.value = 0;
    }
}

-(IBAction)slideVolume:(id)sender{
    volumeSlider.value = (int)volumeSlider.value;
    [AppDelegate instance].serverVolume = (int)volumeSlider.value;
    volumeLabel.text = [NSString  stringWithFormat:@"%.0f", volumeSlider.value];
}

-(IBAction)toggleMute:(id)sender {
    [self handleMute:!isMuted];
    [self changeMuteServer];
}

-(void)handleMute:(BOOL)mute {
    Utilities *utils = [[Utilities alloc] init];
    isMuted = mute;
    if (isMuted) {
        UIImage *img = [UIImage imageNamed:@"volume_slash"];
        img = [utils colorizeImage:img withColor:[UIColor systemRedColor]];
        [muteButton setImage:img forState:UIControlStateNormal];
        
        img = [UIImage imageNamed:@"pgbar_thumb_iOS7.png"];
        img = [utils colorizeImage:img withColor:[UIColor darkGrayColor]];
        [volumeSlider setThumbImage:img forState:UIControlStateNormal];
        [volumeSlider setMinimumTrackTintColor:[UIColor darkGrayColor]];
        [volumeSlider setUserInteractionEnabled:NO];
    }
    else {
        UIImage *img = [UIImage imageNamed:@"volume_slash"];
        img = [utils colorizeImage:img withColor:[UIColor darkGrayColor]];
        [muteButton setImage:img forState:UIControlStateNormal];
        
        img = [UIImage imageNamed:@"pgbar_thumb_iOS7.png"];
        [volumeSlider setThumbImage:img forState:UIControlStateNormal];
        [volumeSlider setMinimumTrackTintColor:SLIDER_DEFAULT_COLOR];
        [volumeSlider setUserInteractionEnabled:YES];
    }
}

-(void)changeMuteServer {
    jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    [jsonRPC
     callMethod:@"Application.SetMute"
     withParameters:@{@"mute": @"toggle"}];
}

-(void)checkMuteServer {
    jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    [jsonRPC
     callMethod:@"Application.GetProperties"
     withParameters:@{@"properties": @[@"muted"]}
     withTimeout: SERVER_TIMEOUT
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error==nil && methodError==nil){
             isMuted = [methodResult[@"muted"] boolValue];
             [self handleMute:isMuted];
         }
    }];
}

NSInteger action;

-(IBAction)holdVolume:(id)sender{
    [self stopTimer];
    action = [sender tag];
    [self changeVolume];
    self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(changeVolume) userInfo:nil repeats:YES];
}

-(IBAction)stopVolume:(id)sender{
    if (self.holdVolumeTimer!=nil){
        [self.holdVolumeTimer invalidate];
        self.holdVolumeTimer=nil;
    }
    action = 0;
    [self startTimer];
}

-(void)changeVolume{
    if (self.holdVolumeTimer.timeInterval == 0.5){
        [self.holdVolumeTimer invalidate];
        self.holdVolumeTimer=nil;
        self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(changeVolume) userInfo:nil repeats:YES];        
    }
    if (action==1){ // Volume Raise
       volumeSlider.value = (int)volumeSlider.value + 2;
        
    }
    else if (action==2) { // Volume Lower
        volumeSlider.value = (int)volumeSlider.value - 2;

    }
    else { // Volume in 2-step resolution
        volumeSlider.value= ((int)volumeSlider.value / 2) * 2;
    }
    [AppDelegate instance].serverVolume = volumeSlider.value;
    volumeLabel.text=[NSString  stringWithFormat:@"%.0f", volumeSlider.value];
    [self changeServerVolume:nil];
    [self handleMute:NO];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [self stopTimer];
}

@end
