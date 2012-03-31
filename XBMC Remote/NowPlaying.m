//
//  NowPlaying.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 24/3/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import "NowPlaying.h"
#import "mainMenu.h"
#import "UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>
#import "GlobalData.h"
#import "VolumeSliderView.h"

@interface NowPlaying ()

@end

@implementation NowPlaying

@synthesize detailItem = _detailItem;
float startx=14;
float barwidth=280;

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
        CGRect frame = CGRectMake(0, 0, 320, 44);
        UILabel *label = [[UILabel alloc] initWithFrame:frame] ;
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont boldSystemFontOfSize:12];
        label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0];
        label.textAlignment = UITextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.text = @"Now playing";
        [label sizeToFit];
        self.navigationItem.titleView = label; 
       // self.navigationItem.title = [self.detailItem mainLabel]; 
        self.navigationItem.title = @"Now playing"; // DA SISTEMARE COME PARAMETRO
    }
}

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
    int numelement=[array count];
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

-(void)resizeBar:(float)width{
    float time=1.0f;
    if (width==0){
        time=0.1f;
    }
    if (width>barwidth)
        width=barwidth;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:time];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    CGRect frame;
    frame = [timeBar frame];
    frame.size.width = width;
    timeBar.frame = frame;
    [UIView commitAnimations];
}

-(void)playbackInfo{
    [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                NSNumber *response = [[methodResult objectAtIndex:0] objectForKey:@"playerid"];
                [jsonRPC 
                 callMethod:@"Player.GetItem" 
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                                 response, @"playerid",
                                 [[NSArray alloc] initWithObjects:@"album", @"artist",@"title", @"thumbnail", nil], @"properties",
                                 nil] 
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error==nil && methodError==nil){
//                         NSLog(@"Risposta %@", methodResult);
                         if( [NSJSONSerialization isValidJSONObject:methodResult]){
                             NSDictionary *nowPlayingInfo = [methodResult objectForKey:@"item"];
                             if ([nowPlayingInfo count]){
                                 NSString *album=[NSString stringWithFormat:@"%@",[nowPlayingInfo  objectForKey:@"album"]];
                                 NSString *title=[NSString stringWithFormat:@"%@",[nowPlayingInfo  objectForKey:@"title"]];
                                 NSString *artist=[NSString stringWithFormat:@"%@",[nowPlayingInfo objectForKey:@"artist"]];
//                                 NSNumber *timeduration=[nowPlayingInfo objectForKey:@"duration"];
                                 albumName.text=album;
                                 songName.text=title;
                                 artistName.text=artist;
                                 NSString *type=[nowPlayingInfo objectForKey:@"type"];
                                 NSString *jewelImg=@"";
                                 if ([type isEqualToString:@"song"]){
                                     jewelImg=@"jewel_cd.9.png";
                                     CGRect frame=thumbnailView.frame;
                                     frame.origin.x=50;
                                     frame.origin.y=39;
                                     frame.size.width=237;
                                     frame.size.height=245;
                                     thumbnailView.frame=frame;
                                 }
                                 else if ([type isEqualToString:@"movie"]){
                                     CGRect frame=thumbnailView.frame;
                                     frame.origin.x=50;
                                     frame.origin.y=39;
                                     frame.size.width=237;
                                     frame.size.height=245;
                                     thumbnailView.frame=frame;
                                     jewelImg=@"jewel_dvd.9.png";
                                 }
                                 else if ([type isEqualToString:@"episode"]){
                                     jewelImg=@"jewel_tv.9.png";
                                     CGRect frame=thumbnailView.frame;
                                     frame.origin.x=20;
                                     frame.origin.y=78;
                                     frame.size.width=280;
                                     frame.size.height=158;
                                     thumbnailView.frame=frame;
                                     
                                 }
                                 jewelView.image=[UIImage imageNamed:jewelImg];
//                                 NSLog(@"TIPO %@", type);
//                                 duration.text=[self convertTimeFromSeconds:timeduration];
                             }
                             GlobalData *obj=[GlobalData getInstance]; 
                             NSString *serverURL=[NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];

                             NSString *thumbnailPath=[nowPlayingInfo objectForKey:@"thumbnail"];
                             
                             NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, thumbnailPath];
                             
                             NSURL *imageUrl = [NSURL URLWithString: stringURL];
//                             NSLog(@"%@", thumbnailPath);
//                             thumbnailView.image=[UIImage im];
                             SDWebImageManager *manager = [SDWebImageManager sharedManager];
                             UIImage *cachedImage = [manager imageWithURL:imageUrl];
                             if (cachedImage){
                                 thumbnailView.image=cachedImage;
                             }
                             else{
                                 [thumbnailView setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:@"coverbox_back.png"] ];
                             }
                             //                                      NSLog(@"Visualizzo %@", stringURL);
                         }
                         else {
                             thumbnailView.image=[UIImage imageNamed:@"coverbox_back.png"];
                             //                                      NSLog(@"SONO IO ERROR:%@ METHOD:%@", error, methodError);
                         }
                             
                         
                     }
                     else {
                         NSLog(@"ci deve essere un secondo problema %@", methodError);
                     }
                 }];
             
                [jsonRPC 
                 callMethod:@"Player.GetProperties" 
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                                 response, @"playerid",
                                 [[NSArray alloc] initWithObjects:@"percentage", @"time", @"totaltime", nil], @"properties",
                                 nil] 
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error==nil && methodError==nil){
                         if( [NSJSONSerialization isValidJSONObject:methodResult]){
//                             NSLog(@"risposta %@", methodResult);
                             if ([methodResult count]){
                                 
                                 float newx=barwidth * [(NSNumber*) [methodResult objectForKey:@"percentage"] floatValue] / 100;
                                 [self animCursor:startx+newx];
                                 [self resizeBar:newx];
                                 NSDictionary *timeGlobal=[methodResult objectForKey:@"totaltime"];
                                 int hoursGlobal=[[timeGlobal objectForKey:@"hours"] intValue];
                                 int minutesGlobal=[[timeGlobal objectForKey:@"minutes"] intValue];
                                 int secondsGlobal=[[timeGlobal objectForKey:@"seconds"] intValue];
                                 NSString *globalTime=[NSString stringWithFormat:@"%@%02i:%02i", (hoursGlobal == 0) ? @"":[NSString stringWithFormat:@"%02i:", hoursGlobal], minutesGlobal, secondsGlobal];
                                 duration.text=globalTime;
                                 
                                 
                                 NSDictionary *time=[methodResult objectForKey:@"time"];
                                 int hours=[[time objectForKey:@"hours"] intValue];
                                 int minutes=[[time objectForKey:@"minutes"] intValue];
                                 int seconds=[[time objectForKey:@"seconds"] intValue];
                                 NSString *actualTime=[NSString stringWithFormat:@"%@%02i:%02i", (hoursGlobal == 0) ? @"":[NSString stringWithFormat:@"%02i:", hours], minutes, seconds];
                                 currentTime.text=actualTime;
                                 
                                 

//                                 NSLog(@"time %@", actualTime);
                             }
                         }
                     }
                     else {
                         NSLog(@"ci deve essere un secondo problema %@", methodError);
                     }
                 }];
            }
            else{
                currentTime.text=@"";
                [timeCursor.layer removeAllAnimations];
                [timeBar.layer removeAllAnimations];
                [self animCursor:startx];
                [self resizeBar:0];
                thumbnailView.image=nil;
                duration.text=@"";
                albumName.text=@"Nothing is playing";
                songName.text=@"";
                artistName.text=@"";
//                NSLog(@"Nothing is playing");
            }
        }
        else {
//            NSLog(@"ci deve essere un primo problema %@", methodError);
            currentTime.text=@"";
            [timeCursor.layer removeAllAnimations];
            [timeBar.layer removeAllAnimations];
            [self animCursor:startx];
            [self resizeBar:0];
            thumbnailView.image=nil;
            duration.text=@"";
            albumName.text=@"Nothing is playing";
            songName.text=@"";
            artistName.text=@"";

        }
    }];
}

-(void)playbackAction:(NSString *)action params:(NSArray *)parameters{
    [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                NSNumber *response = [[methodResult objectAtIndex:0] objectForKey:@"playerid"];
                NSMutableArray *commonParams=[NSMutableArray arrayWithObjects:response, @"playerid", nil];
                if (parameters!=nil)
                    [commonParams addObjectsFromArray:parameters];
                [jsonRPC callMethod:action withParameters:[self indexKeyedDictionaryFromArray:commonParams] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                    if (error==nil && methodError==nil){
//                        NSLog(@"comando %@ eseguito ", action);
                    }
                    else {
                        NSLog(@"ci deve essere un secondo problema %@", methodError);
                    }
                }];
            }
        }
        else {
            NSLog(@"ci deve essere un primo problema %@", methodError);
        }
    }];
}
- (IBAction)startVibrate:(id)sender {
//    NSLog(@"%d", [sender tag]);
    NSString *action;
    NSArray *params;
    switch ([sender tag]) {
       
        case 1:
            action=@"Player.GoPrevious";
            params=nil;
            [self playbackAction:action params:nil];
            [timeCursor.layer removeAllAnimations];
            [timeBar.layer removeAllAnimations];
            [self animCursor:startx];
            [self resizeBar:0];
            break;
            
        case 2:
            action=@"Player.PlayPause";
            params=nil;
            [self playbackAction:action params:nil];
            break;
            
        case 3:
            action=@"Player.Stop";
            params=nil;
            [self playbackAction:action params:nil];
            break;
            
        case 4:
            action=@"Player.GoNext";
            params=nil;
            [self playbackAction:action params:nil];
//            [timeCursor.layer removeAllAnimations];
//            [timeBar.layer removeAllAnimations];
//            [self animCursor:startx];
//            [self resizeBar:0];
            break;
            
        case 6:
            action=@"Player.Seek";
            params=[NSArray arrayWithObjects:@"smallbackward", @"value", nil];
            [self playbackAction:action params:params];
            break;
            
        case 7:
            action=@"Player.Seek";
            params=[NSArray arrayWithObjects:@"smallforward", @"value", nil];
            [self playbackAction:action params:params];
            break;
            
                    
        default:
            break;
    }
    //    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)updateInfo{
//    NSLog(@"OGNI SECONDO");
    [self playbackInfo];
    
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if([touch.view isEqual:jewelView]){
        NSLog(@"ingrandisco");
//        CGRect frame;
//        frame = [thumbnailView frame];
//        frame.origin.x = 0;
//        frame.origin.y = 0;
//        frame.size.width=320;
//        frame.size.height=372;
//        thumbnailView.frame = frame;
        //maximize the image here
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [self playbackInfo];
    [volumeSliderView startTimer]; 
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateInfo) userInfo:nil repeats:YES];
    
}
-(void)viewWillDisappear:(BOOL)animated{
    NSLog(@"ME NE VADO");
    [timer invalidate];
    [volumeSliderView stopTimer];
    [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE];
    
}
- (void)viewDidLoad{
    [super viewDidLoad];
    volumeSliderView = [[VolumeSliderView alloc] 
                        initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 206.0f)];
    CGRect frame=volumeSliderView.frame;
    frame.origin.x=258;
    frame.origin.y=-206;
    volumeSliderView.frame=frame;
    [self.view addSubview:volumeSliderView];
    UIImage* volumeImg = [UIImage imageNamed:@"volume.png"];
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:volumeImg style:UIBarButtonItemStyleBordered target:self action:@selector(toggleVolume)];
    self.navigationItem.rightBarButtonItem = settingsButton;
    GlobalData *obj=[GlobalData getInstance]; 
    
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, obj.serverPass, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    volumeSliderView = nil;
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)dealloc{
    volumeSliderView=nil;
    self.detailItem = nil;
    jsonRPC=nil;
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
//    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
//}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
