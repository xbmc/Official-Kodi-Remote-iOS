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

#define VOLUMEICON_PADDING_NOSLIDER 15 /* space left of volume icons */
#define VOLUMELABEL_PADDING_NOSLIDER 15 /* space left/right of volume label */
#define VOLUMEICON_PADDING 10 /* space left/right from volume icons */
#define VOLUMELABEL_PADDING 5 /* space left/right from volume label */
#define VOLUMESLIDER_HEIGHT 44
#define VOLUME_HOLD_TIMEOUT 0.2
#define VOLUME_REPEAT_TIMEOUT 0.03
#define VOLUME_INFO_TIMEOUT 1.0
#define SET_VOLUME_TIMEOUT 3.0
#define SET_MUTE_TIMEOUT 3.0
#define VOLUME_BUTTON_INC 1
#define VOLUME_BUTTON_DEC 2
#define VOLUME_SLIDER_INC 3
#define VOLUME_SLIDER_DEC 4
#define VOLUME_SLIDER_SET 10

@implementation VolumeSliderView

- (id)initWithFrame:(CGRect)frame leftAnchor:(CGFloat)leftAnchor isSliderType:(BOOL)isSliderType {
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VolumeSliderView" owner:nil options:nil];
    self = nib[0];
    if (self) {
        UIImage *img = [UIImage imageNamed:@"pgbar_thumb"];
        img = [Utilities colorizeImage:img withColor:KODI_BLUE_COLOR];
        volumeSlider.minimumTrackTintColor = KODI_BLUE_COLOR;
        volumeSlider.maximumTrackTintColor = UIColor.darkGrayColor;
        [volumeSlider setThumbImage:img forState:UIControlStateNormal];
        [volumeSlider setThumbImage:img forState:UIControlStateHighlighted];
        [volumeSlider addTarget:self action:@selector(handleSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [volumeSlider addTarget:self action:@selector(stopVolume:) forControlEvents:UIControlEventTouchUpInside];
        [volumeSlider addTarget:self action:@selector(stopVolume:) forControlEvents:UIControlEventTouchUpOutside];
        CGRect frame_tmp;
        if (!isSliderType) {
            volumeLabel.alpha = 1.0;
            volumeView.hidden = YES;
            volumeSlider.hidden = YES;
            
            // Width is full iPad menu width
            frame_tmp = frame;
            frame_tmp.size.width = PAD_MENU_TABLE_WIDTH;
            self.frame = frame_tmp;
            
            // Left is mute button
            frame_tmp = muteButton.frame;
            frame_tmp.origin.x = VOLUMEICON_PADDING_NOSLIDER;
            muteButton.frame = frame_tmp;
            
            // Center is volume label
            frame_tmp = volumeLabel.frame;
            frame_tmp.origin.x = (CGRectGetWidth(self.frame) - CGRectGetWidth(volumeLabel.frame)) / 2;
            volumeLabel.frame= frame_tmp;
            
            // Left of center is minus button
            frame_tmp = minusButton.frame;
            frame_tmp.origin.x = CGRectGetMinX(volumeLabel.frame) - VOLUMELABEL_PADDING_NOSLIDER - CGRectGetWidth(minusButton.frame);
            minusButton.frame = frame_tmp;
            
            // Right of center is plus button
            frame_tmp = plusButton.frame;
            frame_tmp.origin.x = CGRectGetMaxX(volumeLabel.frame) + VOLUMELABEL_PADDING_NOSLIDER;
            plusButton.frame = frame_tmp;
            
            volumeLabel.textColor = UIColor.lightGrayColor;
        }
        else {
            volumeView.hidden = YES;
            volumeLabel.hidden = YES;

            CGFloat width = IS_IPHONE ? UIScreen.mainScreen.bounds.size.width - leftAnchor : PAD_REMOTE_WIDTH;
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
            frame_tmp.size.width = self.frame.size.width - frame_tmp.origin.x - 2 * VOLUMEICON_PADDING - plusButton.frame.size.width;
            volumeSlider.frame = frame_tmp;
            
            frame_tmp = plusButton.frame;
            frame_tmp.origin.x = CGRectGetMaxX(volumeSlider.frame) + VOLUMEICON_PADDING;
            plusButton.frame = frame_tmp;
        }
        // Move all buttons to vertical center of view
        CGFloat center_y = self.frame.size.height / 2;
        for (UIView *subView in self.subviews) {
            subView.center = CGPointMake(subView.center.x, center_y);
        }
        
        img = [UIImage imageNamed:@"volume_slash"];
        img = [Utilities colorizeImage:img withColor:UIColor.grayColor];
        [muteButton setImage:img forState:UIControlStateNormal];
        
        img = [UIImage imageNamed:@"volume_1"];
        img = [Utilities colorizeImage:img withColor:ICON_TINT_COLOR];
        [minusButton setImage:img forState:UIControlStateNormal];
        [minusButton setImage:img forState:UIControlStateHighlighted];
        
        img = [UIImage imageNamed:@"volume_3"];
        img = [Utilities colorizeImage:img withColor:ICON_TINT_COLOR];
        [plusButton setImage:img forState:UIControlStateNormal];
        [plusButton setImage:img forState:UIControlStateHighlighted];
        
        [self readServerVolume];
        
        [self setVolumeButtonMode];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleApplicationOnVolumeChanged:)
                                                     name:@"Application.OnVolumeChanged"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleServerStatusChanged:)
                                                     name:@"TcpJSONRPCChangeServerStatus"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)handleServerStatusChanged:(NSNotification*)sender {
    [self readServerVolume];
}

- (void)handleApplicationOnVolumeChanged:(NSNotification*)sender {
    if (!isChangingVolume) {
        NSDictionary *theData = sender.userInfo;
        if ([theData isKindOfClass:[NSDictionary class]]) {
            serverVolume = [theData[@"params"][@"data"][@"volume"] intValue];
            [self showServerVolume];
            isMuted = [theData[@"params"][@"data"][@"muted"] boolValue];
            [self showServerMute];
        }
    }
}

- (void)handleDidEnterBackground:(NSNotification*)sender {
    [self stopTimer];
}

- (void)handleDidBecomeActive:(NSNotification*)sender {
    [self readServerVolume];
    [self startTimer];
    [self setVolumeButtonMode];
}

- (void)setVolumeButtonMode {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL enableCEC = [userDefaults boolForKey:@"cec_support_preference"];
    if (enableCEC) {
        // Volume buttons will set increment/decrement (supports CEC)
        minusButton.tag = VOLUME_BUTTON_DEC;
        plusButton.tag = VOLUME_BUTTON_INC;
    }
    else {
        // Volume buttons will set absolute values (0-100%) - default
        minusButton.tag = VOLUME_SLIDER_DEC;
        plusButton.tag = VOLUME_SLIDER_INC;
    }
    volumeSlider.tag = VOLUME_SLIDER_SET;
}

- (void)changeServerVolume:(id)value {
    [[Utilities getJsonRPC]
     callMethod:@"Application.SetVolume"
     withParameters:@{@"volume": value}
     withTimeout:SET_VOLUME_TIMEOUT
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil) {
            serverVolume = [methodResult intValue];
            [self showServerVolume];
        }
    }];
}

- (void)startTimer {
    [self showServerVolume];
    [self stopTimer];
    self.pollVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:VOLUME_INFO_TIMEOUT
                                                            target:self
                                                          selector:@selector(volumeInfo)
                                                          userInfo:nil
                                                           repeats:YES];
}

- (void)stopTimer {
    [self.pollVolumeTimer invalidate];
}

- (void)volumeInfo {
    if (AppDelegate.instance.serverTCPConnectionOpen || isChangingVolume) {
        return;
    }
    else {
        [self readServerVolume];
    }
}

- (void)readServerVolume {
    [[Utilities getJsonRPC]
     callMethod:@"Application.GetProperties"
     withParameters:@{@"properties": @[@"volume", @"muted"]}
     withTimeout:VOLUME_INFO_TIMEOUT
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSDictionary class]]) {
            serverVolume = [methodResult[@"volume"] intValue];
            isMuted = [methodResult[@"muted"] boolValue];
            [self showServerMute];
        }
        else {
            serverVolume = -1;
        }
        [self showServerVolume];
    }];
}

- (void)showServerVolume {
    if (serverVolume > -1) {
        volumeLabel.text = [NSString stringWithFormat:@"%d", serverVolume];
        volumeSlider.value = serverVolume;
    }
    else {
        volumeLabel.text = @"0";
        volumeSlider.value = 0;
    }
}

- (IBAction)toggleMute:(id)sender {
    [self changeServerMute:nil];
}

- (void)showServerMute {
    if (!AppDelegate.instance.serverOnLine) {
        return;
    }
    
    UIColor *buttonColor = isMuted ? UIColor.systemRedColor : UIColor.grayColor;
    UIColor *sliderColor = isMuted ? UIColor.darkGrayColor : KODI_BLUE_COLOR;

    UIImage *img = [UIImage imageNamed:@"volume_slash"];
    img = [Utilities colorizeImage:img withColor:buttonColor];
    [muteButton setImage:img forState:UIControlStateNormal];
    
    img = [UIImage imageNamed:@"pgbar_thumb"];
    img = [Utilities colorizeImage:img withColor:sliderColor];
    [volumeSlider setThumbImage:img forState:UIControlStateNormal];
    volumeSlider.minimumTrackTintColor = sliderColor;
    volumeSlider.userInteractionEnabled = !isMuted;
}

- (void)changeServerMute:(void(^)(void))onSuccess {
    [[Utilities getJsonRPC]
     callMethod:@"Application.SetMute"
     withParameters:@{@"mute": @"toggle"}
     withTimeout:SET_MUTE_TIMEOUT
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil) {
            isMuted = [methodResult boolValue];
            [self showServerMute];
            if (onSuccess) {
                onSuccess();
            }
        }
    }];
}

- (IBAction)holdVolume:(id)sender {
    // Volume up/down button is touched
    isChangingVolume = YES;
    [self stopTimer];
    [self changeVolume:[sender tag]];
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
    // Volume up/down was longpressed
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
    [self changeVolume:[sender tag]];
}

- (void)handleVolumeIncrease {
    [self changeVolume:plusButton.tag];
}

- (void)handleVolumeDecrease {
    [self changeVolume:minusButton.tag];
}

- (void)handleSliderValueChanged:(id)sender {
    // Volume slider is changed
    isChangingVolume = YES;
    [self changeVolume:[sender tag]];
}

- (void)changeVolume:(NSInteger)action {
    if (!AppDelegate.instance.serverOnLine) {
        return;
    }
    
    // Process the volume change
    id volumeCommand;
    switch (action) {
        case VOLUME_BUTTON_INC: // Volume increase using increment
            volumeCommand = @"increment";
            break;
        case VOLUME_BUTTON_DEC: // Volume decrease using decrement
            volumeCommand = @"decrement";
            break;
        case VOLUME_SLIDER_INC: // Volume increase using absolute value
            volumeSlider.value = (int)MIN(volumeSlider.value + 1, 100);
            volumeCommand =  @((int)volumeSlider.value);
            break;
        case VOLUME_SLIDER_DEC: // Volume decrease using absolute value
            volumeSlider.value = (int)MAX(volumeSlider.value - 1, 0);
            volumeCommand =  @((int)volumeSlider.value);
            break;
        case VOLUME_SLIDER_SET: // Volume slider with 1% step resolution
            volumeCommand = @((int)volumeSlider.value);
            break;
        default: // Undefined state, better return.
            return;
            break;
    }
    
    // In case of active mute, demute first. Then change the volume. This keeps Kodi's internal mute state
    // and potentially connected AV equipment in sync.
    if (isMuted) {
        [self changeServerMute:^{
            [self changeServerVolume:volumeCommand];
        }];
    }
    else {
        [self changeServerVolume:volumeCommand];
    }
}

@end
