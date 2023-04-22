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
#define VOLUMELABEL_PADDING 5 /* space left/right from volume label */
#define VOLUMESLIDER_HEIGHT 44
#define SERVER_TIMEOUT 3.0
#define VOLUME_HOLD_TIMEOUT 0.2
#define VOLUME_REPEAT_TIMEOUT 0.05
#define VOLUME_INFO_TIMEOUT 1.0
#define VOLUME_BUTTON_UP 1
#define VOLUME_BUTTON_DOWN 2
#define VOLUME_SLIDER 10

@implementation VolumeSliderView

@synthesize timer, holdVolumeTimer;

- (id)initWithFrame:(CGRect)frame leftAnchor:(CGFloat)leftAnchor isSliderType:(BOOL)isSliderType {
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VolumeSliderView" owner:nil options:nil];
    self = nib[0];
    if (self) {
        UIImage *img = [UIImage imageNamed:@"pgbar_thumb_iOS7"];
        img = [Utilities colorizeImage:img withColor:SLIDER_DEFAULT_COLOR];
        volumeSlider.minimumTrackTintColor = SLIDER_DEFAULT_COLOR;
        volumeSlider.maximumTrackTintColor = APP_TINT_COLOR;
        [volumeSlider setThumbImage:img forState:UIControlStateNormal];
        [volumeSlider setThumbImage:img forState:UIControlStateHighlighted];
        [self volumeInfo];
        [volumeSlider addTarget:self action:@selector(changeVolume:) forControlEvents:UIControlEventValueChanged];
        [volumeSlider addTarget:self action:@selector(stopVolume:) forControlEvents:UIControlEventTouchUpInside];
        [volumeSlider addTarget:self action:@selector(stopVolume:) forControlEvents:UIControlEventTouchUpOutside];
        CGRect frame_tmp;
        UIColor *volumeIconColor = nil;
        UIImage *muteBackgroundImage = nil;
        if (!isSliderType) {
            volumeLabel.alpha = 1.0;
            volumeView.hidden = YES;
            volumeSlider.hidden = YES;
            
            frame_tmp = muteButton.frame;
            frame_tmp.origin.x = 0;
            muteButton.frame = frame_tmp;
            
            frame_tmp = minusButton.frame;
            frame_tmp.origin.x = CGRectGetMaxX(muteButton.frame) + VOLUMEICON_PADDING;
            minusButton.frame = frame_tmp;
            
            frame_tmp = volumeLabel.frame;
            frame_tmp.origin.x = CGRectGetMaxX(minusButton.frame) + VOLUMELABEL_PADDING;
            volumeLabel.frame= frame_tmp;
            
            frame_tmp = plusButton.frame;
            frame_tmp.origin.x = CGRectGetMaxX(volumeLabel.frame) + VOLUMELABEL_PADDING;
            plusButton.frame = frame_tmp;
            
            volumeLabel.textColor = UIColor.lightGrayColor;
            
            muteIconColor = UIColor.grayColor;
            volumeIconColor = UIColor.lightGrayColor;
            
            // set final used width for this view
            frame_tmp = frame;
            frame_tmp.size.width = CGRectGetMaxX(plusButton.frame);
            self.frame = frame_tmp;
        }
        else {
            volumeView.hidden = YES;
            volumeLabel.hidden = YES;

            CGFloat width = IS_IPHONE ? [self currentScreenBoundsDependOnOrientation].size.width - leftAnchor : PAD_REMOTE_WIDTH;
            CGFloat padding = IS_IPHONE ? 0 : VOLUMEICON_PADDING;
            self.frame = CGRectMake(padding, padding, width - 2 * padding, VOLUMESLIDER_HEIGHT);
            
            frame_tmp = muteButton.frame;
            frame_tmp.origin.x = VOLUMEICON_PADDING;
            muteButton.frame = frame_tmp;
            
            frame_tmp = minusButton.frame;
            frame_tmp.origin.x = CGRectGetMaxX(muteButton.frame) + VOLUMEICON_PADDING;
            minusButton.frame = frame_tmp;
            
            frame_tmp = volumeSlider.frame;
            frame_tmp.origin.x = CGRectGetMaxX(minusButton.frame) + VOLUMEICON_PADDING;
            frame_tmp.size.width = self.frame.size.width - frame_tmp.origin.x - 3 * VOLUMEICON_PADDING - volumeLabel.frame.size.width;
            volumeSlider.frame = frame_tmp;
            
            frame_tmp = plusButton.frame;
            frame_tmp.origin.x = CGRectGetMaxX(volumeSlider.frame) + VOLUMEICON_PADDING;
            plusButton.frame = frame_tmp;
            
            muteIconColor = UIColor.blackColor;
            muteBackgroundImage = [UIImage imageNamed:@"icon_dark"];
            muteBackgroundImage = [Utilities colorizeImage:img withColor:UIColor.darkGrayColor];
            volumeIconColor = UIColor.grayColor;
        }
        // Move all buttons to vertical center of view
        CGFloat center_y = self.frame.size.height / 2;
        for (UIView *subView in self.subviews) {
            subView.center = CGPointMake(subView.center.x, center_y);
        }
        
        [muteButton setBackgroundImage:muteBackgroundImage forState:UIControlStateNormal];
        [muteButton setBackgroundImage:muteBackgroundImage forState:UIControlStateHighlighted];
        img = [UIImage imageNamed:@"volume_slash"];
        img = [Utilities colorizeImage:img withColor:muteIconColor];
        [muteButton setImage:img forState:UIControlStateNormal];
        
        img = [UIImage imageNamed:@"volume_1"];
        img = [Utilities colorizeImage:img withColor:volumeIconColor];
        [minusButton setImage:img forState:UIControlStateNormal];
        [minusButton setImage:img forState:UIControlStateHighlighted];
        
        img = [UIImage imageNamed:@"volume_3"];
        img = [Utilities colorizeImage:img withColor:volumeIconColor];
        [plusButton setImage:img forState:UIControlStateNormal];
        [plusButton setImage:img forState:UIControlStateHighlighted];
        
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

- (CGRect)currentScreenBoundsDependOnOrientation {
    return UIScreen.mainScreen.bounds;
}

- (void)handleServerStatusChanged:(NSNotification*)sender {
    volumeLabel.text = [NSString stringWithFormat:@"%d", AppDelegate.instance.serverVolume];
    volumeSlider.value = AppDelegate.instance.serverVolume;
    [self checkMuteServer];
}

- (void)handleApplicationOnVolumeChanged:(NSNotification*)sender {
    if (!isChangingVolume) {
        NSDictionary *theData = sender.userInfo;
        AppDelegate.instance.serverVolume = [theData[@"params"][@"data"][@"volume"] intValue];
        [self handleServerStatusChanged:nil];
    }
}

- (void)handleDidEnterBackground:(NSNotification*)sender {
    [self stopTimer];
}

- (void)handleEnterForeground:(NSNotification*)sender {
    [self startTimer];
}

- (void)changeServerVolume:(id)sender {
    [[Utilities getJsonRPC]
     callMethod:@"Application.SetVolume" 
     withParameters:@{@"volume": @(volumeSlider.value)}];
}

- (void)startTimer {
    volumeLabel.text = [NSString stringWithFormat:@"%d", AppDelegate.instance.serverVolume];
    volumeSlider.value = AppDelegate.instance.serverVolume;
    [self stopTimer];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:VOLUME_INFO_TIMEOUT
                                                  target:self
                                                selector:@selector(volumeInfo)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)stopTimer {
    [self.timer invalidate];
}

- (void)volumeInfo {
    if (AppDelegate.instance.serverTCPConnectionOpen) {
        return;
    }
    if (AppDelegate.instance.serverVolume > -1) {
        volumeLabel.text = [NSString stringWithFormat:@"%d", AppDelegate.instance.serverVolume];
        volumeSlider.value = AppDelegate.instance.serverVolume;
    }
    else {
        volumeLabel.text = @"0";
        volumeSlider.value = 0;
    }
}

- (IBAction)slideVolume:(id)sender {
    volumeSlider.value = (int)volumeSlider.value;
    AppDelegate.instance.serverVolume = (int)volumeSlider.value;
    volumeLabel.text = [NSString stringWithFormat:@"%.0f", volumeSlider.value];
}

- (IBAction)toggleMute:(id)sender {
    [self handleMute:!isMuted];
    [self changeMuteServer];
}

- (void)handleMute:(BOOL)mute {
    isMuted = mute;
    UIColor *buttonColor = isMuted ? UIColor.systemRedColor : muteIconColor;
    UIColor *sliderColor = isMuted ? UIColor.darkGrayColor : SLIDER_DEFAULT_COLOR;

    UIImage *img = [UIImage imageNamed:@"volume_slash"];
    img = [Utilities colorizeImage:img withColor:buttonColor];
    [muteButton setImage:img forState:UIControlStateNormal];
    
    img = [UIImage imageNamed:@"pgbar_thumb_iOS7"];
    img = [Utilities colorizeImage:img withColor:sliderColor];
    [volumeSlider setThumbImage:img forState:UIControlStateNormal];
    volumeSlider.minimumTrackTintColor = sliderColor;
    volumeSlider.userInteractionEnabled = !isMuted;
}

- (void)changeMuteServer {
    [[Utilities getJsonRPC]
     callMethod:@"Application.SetMute"
     withParameters:@{@"mute": @"toggle"}];
}

- (void)checkMuteServer {
    [[Utilities getJsonRPC]
     callMethod:@"Application.GetProperties"
     withParameters:@{@"properties": @[@"muted"]}
     withTimeout: SERVER_TIMEOUT
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
         if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSDictionary class]]) {
             isMuted = [methodResult[@"muted"] boolValue];
             [self handleMute:isMuted];
         }
    }];
}

- (IBAction)holdVolume:(id)sender {
    // Volume up/down button is touched
    isChangingVolume = YES;
    [self stopTimer];
    [self changeVolume:sender];
    self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:VOLUME_HOLD_TIMEOUT
                                                            target:self
                                                          selector:@selector(longpressVolume:)
                                                          userInfo:sender
                                                           repeats:NO];
}

- (IBAction)stopVolume:(id)timer {
    // Volume change ended (slider or buttons untouched)
    [self.holdVolumeTimer invalidate];
    [self startTimer];
    isChangingVolume = NO;
}
- (void)longpressVolume:(id)timer {
    // Volume up/down was lomgpressed
    id sender = [timer userInfo];
    [self.holdVolumeTimer invalidate];
    self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:VOLUME_REPEAT_TIMEOUT
                                                            target:self
                                                          selector:@selector(autoChangeVolume:)
                                                          userInfo:sender
                                                           repeats:YES];
}

- (void)autoChangeVolume:(id)timer {
    // Volume up/down is automatically changed until holdVolumeTimer is stopped when button is untouched again
    id sender = [timer userInfo];
    [self changeVolume:sender];
}

- (void)changeVolume:(id)sender {
    // Process the volume change
    isChangingVolume = YES;
    NSInteger action = [sender tag];
    switch (action) {
        case VOLUME_BUTTON_UP: // Volume Increase
            volumeSlider.value += 2;
            break;
        case VOLUME_BUTTON_DOWN: // Volume Decrease
            volumeSlider.value -= 2;
            break;
        case VOLUME_SLIDER: // Volume slider in 2-step resolution
            volumeSlider.value = ((int)volumeSlider.value / 2) * 2;
            break;
        default:
            break;
    }
    AppDelegate.instance.serverVolume = volumeSlider.value;
    volumeLabel.text = [NSString stringWithFormat:@"%.0f", volumeSlider.value];
    [self changeServerVolume:nil];
    if (isMuted) {
        [self toggleMute:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [self stopTimer];
}

@end
