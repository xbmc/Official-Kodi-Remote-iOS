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

@implementation VolumeSliderView

@synthesize timer, holdVolumeTimer;

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VolumeSliderView" owner:self options:nil];
		self = [nib objectAtIndex:0];
        CGAffineTransform trans = CGAffineTransformMakeRotation(M_PI * -0.5);
        volumeSlider.transform = trans;
        [volumeSlider setMaximumTrackImage:[UIImage imageNamed:@"pgbar_inact_fake.png"] forState:UIControlStateNormal];
        [volumeSlider setMinimumTrackImage:[UIImage imageNamed:@"pgbar_act.png"] forState:UIControlStateNormal];
        [volumeSlider setThumbImage:[UIImage imageNamed:@"pgbar_thumb.png"] forState:UIControlStateNormal];
        
        [self volumeInfo];
        volumeSlider.tag=10;
        [volumeSlider addTarget:self action:@selector(changeServerVolume:) forControlEvents:UIControlEventTouchUpInside];
        [volumeSlider addTarget:self action:@selector(stopTimer) forControlEvents:UIControlEventTouchDown];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            trans = CGAffineTransformMakeRotation(M_PI * - 0.5);
            minusButton.transform = trans;
            volumeLabel.transform = trans;
            volumeView.hidden = YES;
            
            volumeSlider.hidden = YES;
            frame = volumeLabel.frame;
            frame.origin.y = 204;
            volumeLabel.frame= frame;
            
            frame = plusButton.frame;
            frame.origin.y = plusButton.frame.origin.y - 30;
            plusButton.frame = frame;
            
        }
    }
    return self;
}

-(void)changeServerVolume:(id)sender{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC 
     callMethod:@"Application.SetVolume" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:(int)volumeSlider.value], @"volume", nil]];
    if ([sender tag]==10)
        [self startTimer];
}

-(void)startTimer{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(volumeInfo) userInfo:nil repeats:YES];
}

-(void)stopTimer{
    if (self.timer!=nil){
        [self.timer invalidate];
        self.timer=nil;
    }
}

-(void)volumeInfo{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC 
     callMethod:@"Application.GetProperties" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [[NSArray alloc] initWithObjects:@"volume", nil], @"properties", nil]
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error==nil && methodError==nil){
             //                         NSLog(@"DATO RICEVUTO %@", methodResult);
             if( [NSJSONSerialization isValidJSONObject:methodResult]){
                 //                             NSLog(@"risposta %@", methodResult);
                 if ([methodResult count]){
                     volumeLabel.text=[(NSNumber*) [methodResult objectForKey:@"volume"] stringValue];
                     volumeSlider.value=[(NSNumber*) [methodResult objectForKey:@"volume"] floatValue];
                 }
             }
         }
         else {
//             NSLog(@"ERROR:%@ METHOD:%@", error, methodError);
         }
     }];
}

-(IBAction)slideVolume:(id)sender{
    volumeSlider.value=(int)volumeSlider.value;
    volumeLabel.text=[NSString  stringWithFormat:@"%.0f", volumeSlider.value];
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
    volumeLabel.text=[NSString  stringWithFormat:@"%.0f", volumeSlider.value];
    [self changeServerVolume:nil];
}

@end
