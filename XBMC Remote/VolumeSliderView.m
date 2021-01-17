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

@implementation VolumeSliderView

@synthesize timer, holdVolumeTimer;

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VolumeSliderView" owner:self options:nil];
		self = [nib objectAtIndex:0];
        CGAffineTransform trans = CGAffineTransformMakeRotation(M_PI * -0.5);
        volumeSlider.transform = trans;
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
            trans = CGAffineTransformMakeRotation(M_PI * - 0.5);
            minusButton.transform = trans;
            volumeLabel.transform = trans;
            volumeLabel.alpha = .8f;
            [volumeLabel setFrame:CGRectMake((int)volumeLabel.frame.origin.x, (int)volumeLabel.frame.origin.y, volumeLabel.frame.size.width, volumeLabel.frame.size.height)];
            volumeView.hidden = YES;
            
            volumeSlider.hidden = YES;
            frame_tmp = volumeLabel.frame;
            frame_tmp.origin.y = 204;
            volumeLabel.frame= frame_tmp;
            
            frame_tmp = plusButton.frame;
            frame_tmp.origin.y = plusButton.frame.origin.y - 30;
            plusButton.frame = frame_tmp;
            
        }
        else if (frame.size.width == 0){
            [plusButton setBackgroundImage:[UIImage imageNamed:@"button_volume_plus.png"] forState:UIControlStateNormal];
            [plusButton setBackgroundImage:[UIImage imageNamed:@"blank.png"] forState:UIControlStateHighlighted];
            [plusButton setTitle:@"" forState:UIControlStateNormal];
            [plusButton setTitle:@"" forState:UIControlStateHighlighted];
            [plusButton setShowsTouchWhenHighlighted:YES];

            [minusButton setBackgroundImage:[UIImage imageNamed:@"button_volume_minus.png"] forState:UIControlStateNormal];
            [minusButton setBackgroundImage:[UIImage imageNamed:@"blank.png"] forState:UIControlStateHighlighted];
            [minusButton setTitle:@"" forState:UIControlStateNormal];
            [minusButton setTitle:@"" forState:UIControlStateHighlighted];
            [minusButton setShowsTouchWhenHighlighted:YES];

            volumeView.hidden = YES;
            frame_tmp = volumeLabel.frame;
            frame_tmp.origin.y = (int)(([self currentScreenBoundsDependOnOrientation].size.width - 12) / 2) - (int)(frame_tmp.size.height/2);
            frame_tmp.origin.x = 22;
            volumeLabel.frame = frame_tmp;
            [volumeLabel setFont:[UIFont boldSystemFontOfSize:15]];
            UIColor *darkShadow =[UIColor colorWithRed:.2 green:.2 blue:.2 alpha:.6];
            [volumeLabel setTextColor:[UIColor colorWithRed:.1 green:.1 blue:.1 alpha:.8]];
            [volumeLabel setShadowColor:darkShadow];
            [volumeLabel setShadowOffset:CGSizeMake(0.5, 0.7)];
            volumeLabel.layer.shadowColor = darkShadow.CGColor;
            volumeLabel.layer.shadowOffset = CGSizeMake(0, 0);
            volumeLabel.layer.shadowOpacity = 1;
            volumeLabel.layer.shadowRadius = 1.0;
            self.transform = trans;
            minusButton.transform = trans;
            trans = CGAffineTransformMakeRotation(M_PI * 0.5);
            volumeSlider.transform = trans;
            volumeLabel.transform = trans;
            frame_tmp = self.frame;
            frame_tmp.origin.x = -10;
            frame_tmp.origin.y = 12;
            frame_tmp.size.height = 44;
            frame_tmp.size.width = [self currentScreenBoundsDependOnOrientation].size.width;
            self.frame = frame_tmp;
            plusButton.frame = minusButton.frame;
            frame_tmp = plusButton.frame;
            frame_tmp.origin.y = [self currentScreenBoundsDependOnOrientation].size.width - 44 - plusButton.frame.size.height;
            plusButton.frame = frame_tmp;
            frame_tmp = minusButton.frame;
            [minusButton setFrame:CGRectMake(frame_tmp.origin.x, 26, frame_tmp.size.width, frame_tmp.size.height)];
            frame_tmp = volumeSlider.frame;
            [volumeSlider setFrame:CGRectMake(frame_tmp.origin.x, 33 + minusButton.frame.size.width, frame_tmp.size.width, plusButton.frame.origin.y - minusButton.frame.origin.y - minusButton.frame.size.height - 12)];
        }
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleApplicationOnVolumeChanged:)
                                                     name: @"Application.OnVolumeChanged"
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

-(void)handleApplicationOnVolumeChanged:(NSNotification *)sender{
    [AppDelegate instance].serverVolume = [[[[[sender userInfo] valueForKey:@"params"] objectForKey:@"data"] objectForKey:@"volume"] intValue];
    volumeLabel.text = [NSString stringWithFormat:@"%d", [AppDelegate instance].serverVolume];
    volumeSlider.value = [AppDelegate instance].serverVolume;
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
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(volumeInfo) userInfo:nil repeats:YES];
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

NSInteger action;

-(IBAction)holdVolume:(id)sender{
    [self stopTimer];
    action = [sender tag];
    [self changeVolume];
    self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(changeVolume) userInfo:nil repeats:YES];
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
    if (self.holdVolumeTimer.timeInterval == 0.5f){
        [self.holdVolumeTimer invalidate];
        self.holdVolumeTimer=nil;
        self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(changeVolume) userInfo:nil repeats:YES];        
    }
    if (action==1){ //Volume Raise
       volumeSlider.value=(int)volumeSlider.value+2; 
        
    }
    else if (action==2) { // Volume Lower
        volumeSlider.value=(int)volumeSlider.value-2;

    }
    [AppDelegate instance].serverVolume = volumeSlider.value;
    volumeLabel.text=[NSString  stringWithFormat:@"%.0f", volumeSlider.value];
    [self changeServerVolume:nil];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [self stopTimer];
}

@end
