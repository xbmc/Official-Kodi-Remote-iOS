//
//  RemoteController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 24/3/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import "RemoteController.h"
#import "mainMenu.h"
#import <AudioToolbox/AudioToolbox.h>
#import "GlobalData.h"
#import "VolumeSliderView.h"

@interface RemoteController ()

@end

@implementation RemoteController

@synthesize detailItem = _detailItem;

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
//        UILabel *label = [[UILabel alloc] initWithFrame:frame] ;
//        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//        label.backgroundColor = [UIColor clearColor];
//        label.font = [UIFont fontWithName:@"Optima-Bold" size:22];
//        label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0];
//        label.textAlignment = UITextAlignmentCenter;
//        label.textColor = [UIColor whiteColor];
//        label.text = [self.detailItem mainLabel];
//        [label sizeToFit];
//        self.navigationItem.titleView = label; 
        self.navigationItem.title = [self.detailItem mainLabel]; 
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)toggleViewToolBar:(UIView*)view AnimDuration:(float)seconds Alpha:(float)alphavalue YPos:(int)Y forceHide:(BOOL)hide {
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:seconds];
    int actualPosY=view.frame.origin.y;
    
    if (actualPosY==Y || hide){
        Y=-206;
    }
    view.alpha = alphavalue;
	CGRect frame;
	frame = [view frame];
	frame.origin.y = Y;
    view.frame = frame;
    [UIView commitAnimations];
}
- (void)toggleVolume{
    [self toggleViewToolBar:volumeSliderView AnimDuration:0.2 Alpha:1.0 YPos:0 forceHide:FALSE];
}

- (NSDictionary *) indexKeyedDictionaryFromArray:(NSArray *)array {
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    int numelement=[array count];
    for (int i=0;i<numelement-1;i+=2){
        [mutableDictionary setObject:[array objectAtIndex:i] forKey:[array objectAtIndex:i+1]];
    }
    return (NSDictionary *)mutableDictionary;
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
                        NSLog(@"comando %@ eseguito ", action);
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

-(void)GUIAction:(NSString *)action{
    [jsonRPC callMethod:action withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
    }];
}

- (IBAction)startVibrate:(id)sender {
//    NSLog(@"%d", [sender tag]);
    NSString *action;
    NSArray *params;
    switch ([sender tag]) {
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
            
        case 10:
            action=@"Input.Up";
            [self GUIAction:action];
            break;
            
        case 12:
            action=@"Input.Left";
            [self GUIAction:action];
            break;

        case 13:
            action=@"Input.Select";
            [self GUIAction:action];
            break;
            
        case 14:
            action=@"Input.Right";
            [self GUIAction:action];
            break;
            
//        case 15:
//            action=@"Input.Home";
//            [self GUIAction:action];
//            break;

        case 16:
            action=@"Input.Down";
            [self GUIAction:action];
            break;
            
        case 18:
            action=@"Input.Back";
            [self GUIAction:action];
            break;
            
        default:
            break;
    }
   // [[UIDevice currentDevice] playInputClick];
//    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

-(void)viewWillAppear:(BOOL)animated{
    [volumeSliderView startTimer];    
}

-(void)viewWillDisappear:(BOOL)animated{
    [volumeSliderView stopTimer];
    [self toggleViewToolBar:volumeSliderView AnimDuration:0.2 Alpha:1.0 YPos:0 forceHide:TRUE];
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
    
    
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, obj.serverPass, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    UIImage* volumeImg = [UIImage imageNamed:@"volume.png"];
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:volumeImg style:UIBarButtonItemStyleBordered target:self action:@selector(toggleVolume)];
    self.navigationItem.rightBarButtonItem = settingsButton;
}

- (void)viewDidUnload{
    [super viewDidUnload];
    volumeSliderView=nil;
    // Release any retained subviews of the main view.
    jsonRPC=nil;
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
