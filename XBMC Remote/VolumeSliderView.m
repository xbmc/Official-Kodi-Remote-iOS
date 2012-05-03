//
//  VolumeSliderView.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import "VolumeSliderView.h"
#import "GlobalData.h"
#import "DSJSONRPC.h"

@implementation VolumeSliderView

@synthesize timer;

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        NSArray *nib = [[NSBundle mainBundle] 
						loadNibNamed:@"VolumeSliderView"
						owner:self
						options:nil];
		
		self = [nib objectAtIndex:0];
        CGAffineTransform trans = CGAffineTransformMakeRotation(M_PI * -0.5);
        volumeSlider.transform = trans;
        [volumeSlider setMaximumTrackImage:[UIImage imageNamed:@"pgbar_inact_fake.png"] forState:UIControlStateNormal];
        [volumeSlider setMinimumTrackImage:[UIImage imageNamed:@"pgbar_act.png"] forState:UIControlStateNormal];
        [volumeSlider setThumbImage:[UIImage imageNamed:@"pgbar_thumb.png"] forState:UIControlStateNormal];
        GlobalData *obj=[GlobalData getInstance]; 
        NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
        NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
        jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
        [self volumeInfo];
        [volumeSlider addTarget:self action:@selector(changeServerVolume) forControlEvents:UIControlEventTouchUpInside];
        [volumeSlider addTarget:self action:@selector(stopTimer) forControlEvents:UIControlEventTouchDown];

    }
    return self;
}

-(void)changeServerVolume{
    [jsonRPC 
     callMethod:@"Application.SetVolume" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:(int)volumeSlider.value], @"volume", nil]];
    [self startTimer];
}

-(void)startTimer{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(volumeInfo) userInfo:nil repeats:YES];
}

-(void)stopTimer{
    [self.timer invalidate];
}

-(void)volumeInfo{
//    NSLog(@"ECCOMI");
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
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    [userDefaults synchronize];
//    
//    BOOL realtimeVolume=[[userDefaults objectForKey:@"volume_preference"] boolValue];
//    if (realtimeVolume){
//        [self changeServerVolume];
//    }
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
