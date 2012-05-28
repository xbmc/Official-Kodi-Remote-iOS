//
//  RemoteController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 24/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "RemoteController.h"
#import "mainMenu.h"
#import <AudioToolbox/AudioToolbox.h>
#import "GlobalData.h"
#import "VolumeSliderView.h"
#import "SDImageCache.h"

@interface RemoteController ()

@end

@implementation RemoteController

@synthesize detailItem = _detailItem;

@synthesize holdVolumeTimer;

- (void)setDetailItem:(id)newDetailItem{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        // Update the view.
    }
}

- (void)configureView{
    if (self.detailItem) {
        self.navigationItem.title = [self.detailItem mainLabel]; 
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromRight:)];
        rightSwipe.numberOfTouchesRequired = 1;
        rightSwipe.cancelsTouchesInView=NO;
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:rightSwipe];
    }
    else{
        int newWidth = 477;
        int newHeight = remoteControlView.frame.size.height * newWidth / remoteControlView.frame.size.width;
        [remoteControlView setFrame:CGRectMake(remoteControlView.frame.origin.x, remoteControlView.frame.origin.y, newWidth, newHeight)];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

# pragma mark - view Effects

-(void)showSubInfo:(NSString *)message timeout:(float)timeout color:(UIColor *)color{
    // first fadeout 
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.1];
    subsInfoLabel. alpha = 0;
    [UIView commitAnimations];
    [subsInfoLabel setText:message];
    [subsInfoLabel setTextColor:color];
    // then fade in
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.1];
    subsInfoLabel.hidden = NO;
    subsInfoLabel. alpha = 0.8;
    [UIView commitAnimations];
    //then fade out again after timeout seconds
    if ([fadeoutTimer isValid])
        [fadeoutTimer invalidate];
    fadeoutTimer=[NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(fadeoutSubs) userInfo:nil repeats:NO];
}


-(void)fadeoutSubs{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.2];
//    subsInfoLabel.hidden = YES;
    subsInfoLabel. alpha = 0;
    [UIView commitAnimations];
    [fadeoutTimer invalidate];
    fadeoutTimer = nil;
}

# pragma mark - ToolBar

-(void)toggleViewToolBar:(UIView*)view AnimDuration:(float)seconds Alpha:(float)alphavalue YPos:(int)Y forceHide:(BOOL)hide {
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
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

# pragma mark - JSON 

- (NSDictionary *) indexKeyedDictionaryFromArray:(NSArray *)array {
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    int numelement=[array count];
    for (int i=0;i<numelement-1;i+=2){
        [mutableDictionary setObject:[array objectAtIndex:i] forKey:[array objectAtIndex:i+1]];
    }
    return (NSDictionary *)mutableDictionary;
}


/* method to cycle through subs. 
 If ths subs are disabled then are enabled. 
 If sub are enabled then go to the next sub. 
 If the last sub is reached then the subs are disabled.
*/
-(void)subtitlesAction{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    
    [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                NSNumber *response;
                if (((NSNull *)[[methodResult objectAtIndex:0] objectForKey:@"playerid"] != [NSNull null])){
                    response = [[methodResult objectAtIndex:0] objectForKey:@"playerid"];
                }
                [jsonRPC 
                 callMethod:@"Player.GetProperties" 
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                                 response, @"playerid",
                                 [[NSArray alloc] initWithObjects:@"subtitleenabled", @"currentsubtitle", @"subtitles", nil], @"properties",
                                 nil] 
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error==nil && methodError==nil){
                         if( [NSJSONSerialization isValidJSONObject:methodResult]){
                             if ([methodResult count]){
                                 NSDictionary *currentSubtitle = [methodResult objectForKey:@"currentsubtitle"];
                                 BOOL subtitleEnabled =  [[methodResult objectForKey:@"subtitleenabled"] boolValue];
                                 NSArray *subtitles = [methodResult objectForKey:@"subtitles"];
                                 if ([subtitles count]){
                                     int currentSubIdx = [[currentSubtitle objectForKey:@"index"] intValue];
                                     int totalSubs = [subtitles count];
                                     if (subtitleEnabled){
                                         if ( (currentSubIdx + 1) >= totalSubs ){
                                             // disable subs
                                             [self showSubInfo:@"Subtitles disabled" timeout:2.0 color:[UIColor redColor]];
                                             [self playbackAction:@"Player.SetSubtitle" params:[NSArray arrayWithObjects:@"off", @"subtitle", nil]];
                                         }
                                         else{
                                             NSString *message = [NSString stringWithFormat:@"%@ %d/%d %@", @"Subtitles: ", ([[[subtitles objectAtIndex:currentSubIdx + 1 ] objectForKey:@"index"] intValue] + 1), totalSubs, [[subtitles objectAtIndex:currentSubIdx + 1 ] objectForKey:@"name"]];
                                             [self showSubInfo:message timeout:2.0 color:[UIColor whiteColor]];
                                         }
                                         // next subs
                                         [self playbackAction:@"Player.SetSubtitle" params:[NSArray arrayWithObjects:@"next", @"subtitle", nil]];
                                     }
                                     else{
                                         // enable subs
                                         NSString *message = [NSString stringWithFormat:@"%@ %d/%d %@", @"Subtitles: ", currentSubIdx + 1, totalSubs, [[subtitles objectAtIndex:currentSubIdx] objectForKey:@"name"]];
                                         [self showSubInfo:message timeout:2.0 color:[UIColor whiteColor]];
                                         [self playbackAction:@"Player.SetSubtitle" params:[NSArray arrayWithObjects:@"on", @"subtitle", nil]];
                                     }
                                 }
                                 else{
                                     [self showSubInfo:@"Subtitles not available" timeout:2.0 color:[UIColor redColor]];
                                 }
                             }
                         }
                     }
                 }];
            }
            else{
                [self showSubInfo:@"Subtitles not available" timeout:2.0 color:[UIColor redColor]];
            }
        }
//        else {
//            NSLog(@"ci deve essere un primo problema %@", methodError);
//        }
    }];
}

/* 
 method to cycle through audio streams. 
  */
-(void)audiostreamAction:(NSString *)action params:(NSArray *)parameters{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    
    [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                NSNumber *response;
                if (((NSNull *)[[methodResult objectAtIndex:0] objectForKey:@"playerid"] != [NSNull null])){
                    response = [[methodResult objectAtIndex:0] objectForKey:@"playerid"];
                }
                [jsonRPC 
                 callMethod:@"Player.GetProperties" 
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                                 response, @"playerid",
                                 [[NSArray alloc] initWithObjects: @"currentaudiostream", @"audiostreams", nil], @"properties",
                                 nil] 
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error==nil && methodError==nil){
                         if( [NSJSONSerialization isValidJSONObject:methodResult]){
                             if ([methodResult count]){
                                 NSDictionary *currentAudiostream = [methodResult objectForKey:@"currentaudiostream"];
                                 NSArray *audiostreams = [methodResult objectForKey:@"audiostreams"];
                                 if ([audiostreams count]){
                                     int currentAudioIdx = [[currentAudiostream objectForKey:@"index"] intValue];
                                     int totalAudio = [audiostreams count];
                                     if ( (currentAudioIdx + 1) >= totalAudio ){
                                         currentAudioIdx = 0;
                                     }
                                     else{
                                         currentAudioIdx ++;
                                     }
                                     NSString *message = [NSString stringWithFormat:@"%d/%d %@", currentAudioIdx + 1, totalAudio, [[audiostreams objectAtIndex:currentAudioIdx] objectForKey:@"name"]];
                                     [self showSubInfo:message timeout:2.0 color:[UIColor whiteColor]];
                                     [self playbackAction:action params:parameters];
                                }
                                 else{
                                     [self showSubInfo:@"Audiostreams not available" timeout:2.0 color:[UIColor redColor]];
                                 }
                             }
                         }
                     }
                 }];
            }
            else{
                [self showSubInfo:@"Audiostream not available" timeout:2.0 color:[UIColor redColor]];
            }
        }
        //        else {
        //            NSLog(@"ci deve essere un primo problema %@", methodError);
        //        }
    }];
}


-(void)playbackAction:(NSString *)action params:(NSArray *)parameters{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                NSNumber *response = [[methodResult objectAtIndex:0] objectForKey:@"playerid"];
                NSMutableArray *commonParams=[NSMutableArray arrayWithObjects:response, @"playerid", nil];
                if (parameters!=nil)
                    [commonParams addObjectsFromArray:parameters];
                [jsonRPC callMethod:action withParameters:[self indexKeyedDictionaryFromArray:commonParams] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
//                    if (error==nil && methodError==nil){
//                        NSLog(@"comando %@ eseguito. Risultato: %@", action, methodResult);
//                    }
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

-(void)GUIAction:(NSString *)action params:(NSDictionary *)params{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (methodError!=nil || error != nil){
            if ([action isEqualToString:@"GUI.SetFullscreen"]){
                [self sendXbmcHttp:@"SendKey(0xf009)"];
            }
            if ([action isEqualToString:@"Input.Info"]){
                [self sendXbmcHttp:@"SendKey(0xF049)"];
            }
//            NSLog(@"ERRORE %@ %@", methodError, error);
        }
    }];
}

-(void)sendXbmcHttp:(NSString *) command{
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverHTTP=[NSString stringWithFormat:@"http://%@%@@%@:%@/xbmcCmds/xbmcHttp?command=%@", obj.serverUser, userPassword, obj.serverIP, obj.serverPort, command];
    NSURL *url = [NSURL  URLWithString:serverHTTP];
    NSString *requestANS = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];  
    requestANS=nil;

}

#pragma mark - Buttons 

NSInteger buttonAction;

-(IBAction)holdKey:(id)sender{
    buttonAction = [sender tag];
    [self sendAction];
    self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(sendAction) userInfo:nil repeats:YES];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    
    BOOL startVibrate=[[userDefaults objectForKey:@"vibrate_preference"] boolValue];
    if (startVibrate){
        [[UIDevice currentDevice] playInputClick];
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

-(IBAction)stopHoldKey:(id)sender{
    if (self.holdVolumeTimer!=nil){
        [self.holdVolumeTimer invalidate];
        self.holdVolumeTimer=nil;
    }
    buttonAction = 0;
}

-(void)sendAction{
    if (self.holdVolumeTimer.timeInterval == 0.5f){
        [self.holdVolumeTimer invalidate];
        self.holdVolumeTimer=nil;
        self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(sendAction) userInfo:nil repeats:YES];        
    }
    NSString *action;
    switch (buttonAction) {
        case 10:
            action=@"Input.Up";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            break;
            
        case 12:
            action=@"Input.Left";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            break;
            
        case 13:
            action=@"Input.Select";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            break;
            
        case 14:
            action=@"Input.Right";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            break;
            
        case 16:
            action=@"Input.Down";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            break;
            
        case 18:
            action=@"Input.Back";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            break;
            
        default:
            break;
    }
}




- (IBAction)startVibrate:(id)sender {
    NSString *action;
    NSArray *params;
    switch ([sender tag]) {
        case 1:
            action=@"GUI.SetFullscreen";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:@"toggle",@"fullscreen", nil]];
            break;
        case 2:
            action=@"Player.Seek";
            params=[NSArray arrayWithObjects:@"smallbackward", @"value", nil];
            [self playbackAction:action params:params];
            break;
            
        case 3:
            action=@"Player.PlayPause";
            params=nil;
            [self playbackAction:action params:nil];
            break;
            
        case 4:
            action=@"Player.Seek";
            params=[NSArray arrayWithObjects:@"smallforward", @"value", nil];
            [self playbackAction:action params:params];
            break;
        case 5:
            action=@"Player.GoPrevious";
            params=nil;
            [self playbackAction:action params:nil];
            break;
            
        case 6:
            action=@"Player.Stop";
            params=nil;
            [self playbackAction:action params:nil];
            break;
            
        case 7:
            action=@"Player.PlayPause";
            params=nil;
            [self playbackAction:action params:nil];
            break;
            
        case 8:
            action=@"Player.GoNext";
            params=nil;
            [self playbackAction:action params:nil];
            break;
        
        case 9: // HOME
            action=@"Input.Home";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
//            [self sendXbmcHttp:@"SendKey(0xF04F)"]; // STREAM INFO
            break;
            
        case 11: // INFO
            action=@"Input.Info";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            
            break;
            
        case 15: // MENU OSD
            [self sendXbmcHttp:@"SendKey(0xF04D)"];
            break;
        
        case 19:
            [self subtitlesAction];
            break;
            
        case 20:
            action=@"Player.SetAudioStream";
            params=[NSArray arrayWithObjects:@"next", @"stream", nil];
            [self audiostreamAction:action params:params];
            break;
            
        case 21:
            [self sendXbmcHttp:@"ExecBuiltIn&parameter=ActivateWindow(Music)"];
            break;
            
        case 22:
            [self sendXbmcHttp:@"ExecBuiltIn&parameter=ActivateWindow(Videos,MovieTitles)"];
            break;
        
        case 23:
            [self sendXbmcHttp:@"ExecBuiltIn&parameter=ActivateWindow(Videos,tvshowtitles)"];
            break;
        
        case 24:
            [self sendXbmcHttp:@"ExecBuiltIn&parameter=ActivateWindow(Pictures)"];
            break;
            
        default:
            break;
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    
    BOOL startVibrate=[[userDefaults objectForKey:@"vibrate_preference"] boolValue];
    if (startVibrate){
        [[UIDevice currentDevice] playInputClick];
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}
# pragma  mark - Gestures

- (void)handleSwipeFromRight:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Life Cycle

-(void)viewWillAppear:(BOOL)animated{
    [volumeSliderView startTimer];    
}

-(void)viewWillDisappear:(BOOL)animated{
    [volumeSliderView stopTimer];
    [self stopHoldKey:nil];
    [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [self configureView];
    [[SDImageCache sharedImageCache] clearMemory];

    volumeSliderView = [[VolumeSliderView alloc] 
                          initWithFrame:CGRectMake(0.0f, 0.0f, 62.0f, 296.0f)];
    CGRect frame=volumeSliderView.frame;
    frame.origin.x=258;
    frame.origin.y=-volumeSliderView.frame.size.height;
    volumeSliderView.frame=frame;
    [self.view addSubview:volumeSliderView];
    
    UIImage* volumeImg = [UIImage imageNamed:@"volume.png"];
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:volumeImg style:UIBarButtonItemStyleBordered target:self action:@selector(toggleVolume)];
    self.navigationItem.rightBarButtonItem = settingsButton;
    [self.view setBackgroundColor:[UIColor colorWithPatternImage: [UIImage imageNamed:@"backgroundImage_repeat.png"]]];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    volumeSliderView=nil;
    jsonRPC=nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
