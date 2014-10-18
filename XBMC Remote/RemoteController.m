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
#import "AppDelegate.h"
#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"
#import "RightMenuViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "DetailViewController.h"

#define ROTATION_TRIGGER 0.015f 

@interface RemoteController ()

@end

@implementation RemoteController

@synthesize detailItem = _detailItem;

@synthesize holdVolumeTimer;
@synthesize panFallbackImageView;

- (void)setDetailItem:(id)newDetailItem{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        // Update the view.
    }
}

-(void)moveButton:(NSArray *)buttonsToDo ypos:(int)y{
    for (UIButton *button in buttonsToDo){
        [button setFrame:CGRectMake(button.frame.origin.x, button.frame.origin.y + y, button.frame.size.width, button.frame.size.height)];
    }
}

-(void)hideButton:(NSArray *)buttonsToDo hide:(BOOL)hide{
    for (UIButton *button in buttonsToDo){
        [button setHidden:hide];
    }
}

- (void)setEmbeddedView{
    CGRect frame = TransitionalView.frame;
    float transform = 1.0f;
    int startX = -6;
    int startY = 6;
    int transViewY = 46;
    if (IS_IPHONE_6) {
        transform = 1.16f;
        startX = 3;
        transViewY = 58;
    }
    else if (IS_IPHONE_6_PLUS){
        transform = 1.29f;
        startX = 6;
        transViewY = 66;
    }
    int newWidth = (int) (296.0f * transform);
    [self hideButton: [NSArray arrayWithObjects:
                       [(UIButton *) self.view viewWithTag:2],
                       [(UIButton *) self.view viewWithTag:3],
                       [(UIButton *) self.view viewWithTag:4],
                       [(UIButton *) self.view viewWithTag:5],
                       [(UIButton *) self.view viewWithTag:8],
                       nil]
                hide:YES];
    UIButton *buttonTodo = (UIButton *)[self.view viewWithTag:10];
    [buttonTodo setFrame:CGRectMake(buttonTodo.frame.origin.x, buttonTodo.frame.origin.y - 1, buttonTodo.frame.size.width, buttonTodo.frame.size.height)];
    if([[UIScreen mainScreen ] bounds].size.height >= 568){
        [self moveButton: [NSArray arrayWithObjects:
                           (UIButton *)[self.view viewWithTag:21],
                           (UIButton *)[self.view viewWithTag:22],
                           (UIButton *)[self.view viewWithTag:23],
                           (UIButton *)[self.view viewWithTag:24],
                           nil]
                    ypos: -32];
    }
    else{
        [self hideButton: [NSArray arrayWithObjects:
                           [(UIButton *) self.view viewWithTag:21],
                           [(UIButton *) self.view viewWithTag:22],
                           [(UIButton *) self.view viewWithTag:23],
                           [(UIButton *) self.view viewWithTag:24],
                           nil]
                    hide: YES];
    }
    [TransitionalView setFrame:CGRectMake(frame.origin.x, transViewY, frame.size.width, frame.size.height)];
    int newHeight = remoteControlView.frame.size.height * newWidth / remoteControlView.frame.size.width;
    [remoteControlView setFrame:CGRectMake(startX, startY, newWidth, newHeight)];
    
    UIImage* gestureSwitchImg = [UIImage imageNamed:@"finger"];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    BOOL showGesture=[[userDefaults objectForKey:@"gesture_preference"] boolValue];
    if (showGesture){
        gestureSwitchImg = [UIImage imageNamed:@"circle"];
        frame = [gestureZoneView frame];
        frame.origin.x = 0;
        gestureZoneView.frame = frame;
        frame = [buttonZoneView frame];
        frame.origin.x = 320;
        buttonZoneView.frame = frame;
        gestureZoneView.alpha = 1;
        buttonZoneView.alpha = 0;
    }
    UIButton *stopButton = (UIButton *)[self.view viewWithTag:6];

    UIButton *gestureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [stopButton setHidden:YES];
    gestureButton.frame = CGRectMake(stopButton.frame.origin.x + 1, stopButton.frame.origin.y, stopButton.frame.size.width, stopButton.frame.size.height);
    [gestureButton setContentMode:UIViewContentModeRight];
    [gestureButton setShowsTouchWhenHighlighted:NO];
    [gestureButton setImage:gestureSwitchImg forState:UIControlStateNormal];
    [gestureButton setImage:gestureSwitchImg forState:UIControlStateHighlighted];
    [gestureButton setBackgroundImage:[UIImage imageNamed:@"remote_button_blank_up@2x"] forState:UIControlStateNormal];
    [gestureButton setBackgroundImage:[UIImage imageNamed:@"remote_button_blank_down@2x"] forState:UIControlStateHighlighted];
    gestureButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [gestureButton addTarget:self action:@selector(toggleGestureZone:) forControlEvents:UIControlEventTouchUpInside];
    [remoteControlView addSubview:gestureButton];
    
//    UIButton *keyboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    keyboardButton.frame = CGRectMake(stopButton.frame.origin.x, stopButton.frame.origin.y, stopButton.frame.size.width, stopButton.frame.size.height);
//    UIImage* keyboardImg = [UIImage imageNamed:@"keyboard_icon.png"];
//    [keyboardButton setContentMode:UIViewContentModeRight];
//    [keyboardButton setShowsTouchWhenHighlighted:NO];
//    [keyboardButton setImage:keyboardImg forState:UIControlStateNormal];
//    [keyboardButton setBackgroundImage:[UIImage imageNamed:@"remote_button_blank_up@2x"] forState:UIControlStateNormal];
//    [keyboardButton setBackgroundImage:[UIImage imageNamed:@"remote_button_blank_down@2x"] forState:UIControlStateHighlighted];
//    keyboardButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
//    [keyboardButton addTarget:self action:@selector(toggleVirtualKeyboard) forControlEvents:UIControlEventTouchUpInside];
//    [remoteControlView addSubview:keyboardButton];
}

- (void)configureView{
    if (self.detailItem) {
        self.navigationItem.title = [self.detailItem mainLabel]; 
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromRight:)];
        rightSwipe.numberOfTouchesRequired = 1;
        rightSwipe.cancelsTouchesInView=YES;
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [remoteControlView addGestureRecognizer:rightSwipe];
        leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromLeft:)];
        leftSwipe.numberOfTouchesRequired = 1;
        leftSwipe.cancelsTouchesInView=YES;
        leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
        [remoteControlView addGestureRecognizer:leftSwipe];
        quickHelpImageView.image = [UIImage imageNamed:@"remote quick help"];
        if([[UIScreen mainScreen ] bounds].size.height >= 568){
            float transform = 1.0f;
            if (IS_IPHONE_6) {
                transform = 1.16f;
            }
            else if (IS_IPHONE_6_PLUS){
                transform = 1.29f;
            }
            CGRect frame = remoteControlView.frame;
            frame.size.height = frame.size.height *transform;
            frame.size.width = frame.size.width*transform;
            [remoteControlView setFrame:CGRectMake(frame.origin.x, frame.origin.y + 12, frame.size.width * 1.075, frame.size.height * 1.075)];
        }
    }
    else{
        int newWidth = STACKSCROLL_WIDTH;
        [quickHelpView setFrame:CGRectMake(quickHelpView.frame.origin.x, quickHelpView.frame.origin.y, quickHelpView.frame.size.width, quickHelpView.frame.size.height - 20)];
        [quickHelpView
         setAutoresizingMask:
         UIViewAutoresizingFlexibleBottomMargin |
         UIViewAutoresizingFlexibleTopMargin |
         UIViewAutoresizingFlexibleLeftMargin |
         UIViewAutoresizingFlexibleRightMargin |
         UIViewAutoresizingFlexibleHeight |
         UIViewAutoresizingFlexibleWidth
         ];

        int newHeight = remoteControlView.frame.size.height * newWidth / remoteControlView.frame.size.width;        
        [remoteControlView setFrame:CGRectMake(remoteControlView.frame.origin.x, remoteControlView.frame.origin.y, newWidth, newHeight)];
        quickHelpImageView.image = [UIImage imageNamed:@"remote quick help_ipad"];
                 
    }
    UISwipeGestureRecognizer *gestureRightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    gestureRightSwipe.numberOfTouchesRequired = 1;
    gestureRightSwipe.cancelsTouchesInView=NO;
    gestureRightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [gestureZoneView addGestureRecognizer:gestureRightSwipe];
    
    UISwipeGestureRecognizer *gestureLeftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    gestureLeftSwipe.numberOfTouchesRequired = 1;
    gestureLeftSwipe.cancelsTouchesInView=NO;
    gestureLeftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [gestureZoneView addGestureRecognizer:gestureLeftSwipe];
    
    UISwipeGestureRecognizer *upSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    upSwipe.numberOfTouchesRequired = 1;
    upSwipe.cancelsTouchesInView=NO;
    upSwipe.direction = UISwipeGestureRecognizerDirectionUp;
    [gestureZoneView addGestureRecognizer:upSwipe];
    
    UISwipeGestureRecognizer *downSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    downSwipe.numberOfTouchesRequired = 1;
    downSwipe.cancelsTouchesInView=NO;
    downSwipe.direction = UISwipeGestureRecognizerDirectionDown;
    [gestureZoneView addGestureRecognizer:downSwipe];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouchpadLongPress:)];
    longPress.cancelsTouchesInView = YES;
    [gestureZoneView addGestureRecognizer:longPress];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouchpadDoubleTap)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.cancelsTouchesInView=YES;
    [gestureZoneView addGestureRecognizer:doubleTap];
        
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouchpadSingleTap)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.cancelsTouchesInView=YES;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [gestureZoneView addGestureRecognizer:singleTap];
    
    UIRotationGestureRecognizer *rotation = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotate:)];
	[gestureZoneView addGestureRecognizer:rotation];
    
    UITapGestureRecognizer *twoFingersTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingersTap)];
    [twoFingersTap setNumberOfTapsRequired:1];
    [twoFingersTap setNumberOfTouchesRequired:2];
    [gestureZoneView addGestureRecognizer:twoFingersTap];
    
    UISwipeGestureRecognizer *twoFingersDownSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    twoFingersDownSwipe.numberOfTouchesRequired = 2;
    twoFingersDownSwipe.cancelsTouchesInView=NO;
    twoFingersDownSwipe.direction = UISwipeGestureRecognizerDirectionDown;
    [gestureZoneView addGestureRecognizer:twoFingersDownSwipe];
    
    UISwipeGestureRecognizer *twoFingersUpSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    twoFingersUpSwipe.numberOfTouchesRequired = 2;
    twoFingersUpSwipe.cancelsTouchesInView=NO;
    twoFingersUpSwipe.direction = UISwipeGestureRecognizerDirectionUp;
    [gestureZoneView addGestureRecognizer:twoFingersUpSwipe];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

#pragma mark - Touch

-(void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
//    if (recognizer.numberOfTouches == 2 && recognizer.direction == UISwipeGestureRecognizerDirectionDown){
////        NSLog(@"down");
////        if (storeBrightness == -1){
////            storeBrightness = [UIScreen mainScreen].brightness;
////            [[UIScreen mainScreen] setWantsSoftwareDimming:YES];
////            [[UIScreen mainScreen] setBrightness:0.0];
////        }
//    }
//    else if (recognizer.numberOfTouches == 2 && recognizer.direction == UISwipeGestureRecognizerDirectionUp){
////        NSLog(@"up");
////        if (storeBrightness > -1){
////            [[UIScreen mainScreen] setWantsSoftwareDimming:NO];
////            [[UIScreen mainScreen] setBrightness:storeBrightness];
////            storeBrightness = -1;
////        }
//    }
//    else
    if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        buttonAction = 14;
        [self sendAction];
    }
    else if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        buttonAction = 12;
        [self sendAction];
    }
    else if (recognizer.direction == UISwipeGestureRecognizerDirectionUp) {
        buttonAction = 10;
        [self sendAction];
    }
    else if (recognizer.direction == UISwipeGestureRecognizerDirectionDown ) {
        buttonAction = 16;
        [self sendAction];
    }
}

-(void)handleTouchpadDoubleTap{
    buttonAction = 18;
    [self sendAction];
}

-(void)handleTouchpadSingleTap{
    buttonAction = 13;
    [self sendAction];
}

-(void)twoFingersTap{
    [self GUIAction:@"Input.Home" params:[NSDictionary dictionaryWithObjectsAndKeys:nil] httpAPIcallback:nil];
}

- (void)handleTouchpadLongPress:(UILongPressGestureRecognizer*)gestureRecognizer { 
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan){
        jsonRPC = nil;
        GlobalData *obj=[GlobalData getInstance]; 
        NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
        NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
        jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];

        [jsonRPC 
         callMethod:@"XBMC.GetInfoBooleans" 
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                         [[NSArray alloc] initWithObjects:@"Window.IsActive(fullscreenvideo)", @"Window.IsActive(visualisation)", @"Window.IsActive(slideshow)", nil], @"booleans",
                         nil] 
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
             
             if (error==nil && methodError==nil && [methodResult isKindOfClass: [NSDictionary class]]){
                 NSNumber *fullscreenActive = 0;
                 NSNumber *visualisationActive = 0;
                 NSNumber *slideshowActive = 0;

                 if (((NSNull *)[methodResult objectForKey:@"Window.IsActive(fullscreenvideo)"] != [NSNull null])){
                     fullscreenActive = [methodResult objectForKey:@"Window.IsActive(fullscreenvideo)"];
                 }
                 if (((NSNull *)[methodResult objectForKey:@"Window.IsActive(visualisation)"] != [NSNull null])){
                     visualisationActive = [methodResult objectForKey:@"Window.IsActive(visualisation)"];
                 }
                 if (((NSNull *)[methodResult objectForKey:@"Window.IsActive(slideshow)"] != [NSNull null])){
                     slideshowActive = [methodResult objectForKey:@"Window.IsActive(slideshow)"];
                 }
                 if ([fullscreenActive intValue] == 1 || [visualisationActive intValue] == 1 || [slideshowActive intValue] == 1){
                     buttonAction = 15;
                     [self sendActionNoRepeat];
                 }
                 else{
                     [self GUIAction:@"Input.ContextMenu" params:[NSDictionary dictionaryWithObjectsAndKeys:nil] httpAPIcallback:@"SendKey(0xF043)"];
                 }
             }
             else{
                 [self GUIAction:@"Input.ContextMenu" params:[NSDictionary dictionaryWithObjectsAndKeys:nil] httpAPIcallback:@"SendKey(0xF043)"];
             }
         }];   
    }
}


-(void)handleRotate:(id)sender {
    if([(UIRotationGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
        [self volumeInfo];
    }
	else if([(UIRotationGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
		lastRotation = 0.0;
		return;
	}
	CGFloat rotation = 0.0 - (lastRotation - [(UIRotationGestureRecognizer*)sender rotation]);
    
    if (rotation > ROTATION_TRIGGER && audioVolume < 100){
        audioVolume += 1;
    }
    else if (rotation < -ROTATION_TRIGGER && audioVolume > 0){
        audioVolume -= 1;
    }
    [self changeServerVolume];
	lastRotation = [(UIRotationGestureRecognizer*)sender rotation];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [self stopHoldKey:nil];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    [self stopHoldKey:nil];
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
    subsInfoLabel. alpha = 0;
    [UIView commitAnimations];
    [fadeoutTimer invalidate];
    fadeoutTimer = nil;
}

# pragma mark - ToolBar

-(void)toggleGestureZone:(id)sender{
    NSString *imageName=@"";
    BOOL showGesture = (gestureZoneView.alpha == 0);
    if ([sender isKindOfClass:[NSNotification class]]){
        if ([[sender userInfo] isKindOfClass:[NSDictionary class]]){
            showGesture = [[[sender userInfo] objectForKey:@"forceGestureZone"] boolValue];
        }
    }
    if (showGesture == YES && gestureZoneView.alpha == 1) return;
    if (showGesture == YES){
        CGRect frame;
        frame = [gestureZoneView frame];
        frame.origin.x = -320;
        gestureZoneView.frame = frame;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];     
        [UIView setAnimationDuration:0.3];
        frame = [gestureZoneView frame];
        frame.origin.x = 0;
        gestureZoneView.frame = frame;
        frame = [buttonZoneView frame];
        frame.origin.x = 320;
        buttonZoneView.frame = frame;
        gestureZoneView.alpha = 1;
        buttonZoneView.alpha = 0;
        leftSwipe.enabled = NO;
        rightSwipe.enabled = NO;
        [UIView commitAnimations];
        imageName=@"circle.png";
    }
    else{
        CGRect frame;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.3];      
        frame = [gestureZoneView frame];
        frame.origin.x = -320;
        gestureZoneView.frame = frame;
        frame = [buttonZoneView frame];
        frame.origin.x = 0;
        buttonZoneView.frame = frame;
        gestureZoneView.alpha = 0;
        buttonZoneView.alpha = 1;
        leftSwipe.enabled = YES;
        rightSwipe.enabled = YES;
        [UIView commitAnimations];
        imageName=@"finger.png";
    }
    if ([sender isKindOfClass: [UIButton class]]){
        [sender setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:imageName] forState:UIControlStateHighlighted];

    }
    else if ([sender isKindOfClass: [UIBarButtonItem class]]){
        [sender setImage:[UIImage imageNamed:imageName]];        
    }
}

# pragma mark - JSON 

- (NSDictionary *) indexKeyedDictionaryFromArray:(NSArray *)array {
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    NSInteger numelement=[array count];
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
                                     NSString *language = @"?";
                                     NSInteger totalSubs = [subtitles count];
                                     if (subtitleEnabled){
                                         if ( (currentSubIdx + 1) >= totalSubs ){
                                             // disable subs
                                             [self showSubInfo:NSLocalizedString(@"Subtitles disabled", nil) timeout:2.0 color:[UIColor redColor]];
                                             [self playbackAction:@"Player.SetSubtitle" params:[NSArray arrayWithObjects:@"off", @"subtitle", nil]];
                                         }
                                         else{
                                             if (((NSNull *)[[subtitles objectAtIndex:currentSubIdx + 1 ] objectForKey:@"language"] != [NSNull null])){
                                                 language = [[subtitles objectAtIndex:currentSubIdx + 1 ] objectForKey:@"language"];
                                             }
                                             NSString *message = [NSString stringWithFormat:@"%@: %d/%ld %@%@%@", NSLocalizedString(@"Subtitle", nil), ([[[subtitles objectAtIndex:currentSubIdx + 1 ] objectForKey:@"index"] intValue] + 1), (long)totalSubs, language, [[[subtitles objectAtIndex:currentSubIdx + 1 ] objectForKey:@"name"] isEqual:@""] ? @"" : @" - ", [[subtitles objectAtIndex:currentSubIdx + 1 ] objectForKey:@"name"]];
                                             [self showSubInfo:message timeout:2.0 color:[UIColor whiteColor]];
                                         }
                                         // next subs
                                         [self playbackAction:@"Player.SetSubtitle" params:[NSArray arrayWithObjects:@"next", @"subtitle", nil]];
                                     }
                                     else{
                                         // enable subs
                                         if (((NSNull *)[[subtitles objectAtIndex:currentSubIdx] objectForKey:@"language"] != [NSNull null])){
                                             language = [[subtitles objectAtIndex:currentSubIdx] objectForKey:@"language"];
                                         }
                                         NSString *message = [NSString stringWithFormat:@"%@: %d/%ld %@%@%@", NSLocalizedString(@"Subtitle", nil), currentSubIdx + 1, (long)totalSubs, language, [[[subtitles objectAtIndex:currentSubIdx] objectForKey:@"name"] isEqual:@""] ? @"" : @" - ", [[subtitles objectAtIndex:currentSubIdx] objectForKey:@"name"]];
                                         [self showSubInfo:message timeout:2.0 color:[UIColor whiteColor]];
                                         [self playbackAction:@"Player.SetSubtitle" params:[NSArray arrayWithObjects:@"on", @"subtitle", nil]];
                                     }
                                 }
                                 else{
                                     [self showSubInfo:NSLocalizedString(@"Subtitles not available",nil) timeout:2.0 color:[UIColor redColor]];
                                 }
                             }
                         }
                     }
                 }];
            }
            else{
                [self showSubInfo:NSLocalizedString(@"Subtitles not available",nil) timeout:2.0 color:[UIColor redColor]];
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
                                     NSInteger totalAudio = [audiostreams count];
                                     if ( (currentAudioIdx + 1) >= totalAudio ){
                                         currentAudioIdx = 0;
                                     }
                                     else{
                                         currentAudioIdx ++;
                                     }
                                     NSString *language = @"?";
                                     if (((NSNull *)[[audiostreams objectAtIndex:currentAudioIdx] objectForKey:@"language"] != [NSNull null])){
                                         language = [[audiostreams objectAtIndex:currentAudioIdx] objectForKey:@"language"];
                                     }
                                     NSString *message = [NSString stringWithFormat:@"%d/%ld %@%@%@", currentAudioIdx + 1, (long)totalAudio, language, [[[audiostreams objectAtIndex:currentAudioIdx] objectForKey:@"name"] isEqualToString:@""] ? @"" : @" - ",  [[audiostreams objectAtIndex:currentAudioIdx] objectForKey:@"name"]];
                                     [self showSubInfo:message timeout:2.0 color:[UIColor whiteColor]];
                                     [self playbackAction:action params:parameters];
                                }
                                 else{
                                     [self showSubInfo:NSLocalizedString(@"Audiostreams not available",nil) timeout:2.0 color:[UIColor redColor]];
                                 }
                             }
                         }
                     }
                 }];
            }
            else{
                [self showSubInfo:NSLocalizedString(@"Audiostream not available",nil) timeout:2.0 color:[UIColor redColor]];
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

-(void)GUIAction:(NSString *)action params:(NSDictionary *)params httpAPIcallback:(NSString *)callback{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
//        NSLog(@"Action %@ ok with %@ ", action , methodResult);
//        if (methodError!=nil || error != nil){
//            NSLog(@"method error %@ %@", methodError, error);
//        }
        if ((methodError!=nil || error != nil) && callback!=nil){ // Backward compatibility
            [self sendXbmcHttp:callback];
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

-(void)volumeInfo{
    if ([AppDelegate instance].serverVolume > -1){
        audioVolume = [AppDelegate instance].serverVolume;
    }
    else{
        audioVolume = 0;
    }

//    jsonRPC = nil;
//    GlobalData *obj=[GlobalData getInstance]; 
//    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
//    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
//    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
//    [jsonRPC 
//     callMethod:@"Application.GetProperties" 
//     withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [[NSArray alloc] initWithObjects:@"volume", nil], @"properties", nil]
//     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
//         if (error==nil && methodError==nil){
//             if( [NSJSONSerialization isValidJSONObject:methodResult] && [methodResult count]){
//                 audioVolume =  [[methodResult objectForKey:@"volume"] intValue];
//             }
//         }
//     }];
}

-(void)changeServerVolume{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC 
     callMethod:@"Application.SetVolume" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:audioVolume], @"volume", nil]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([touches count] == 1){
        self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:1.5f target:self selector:@selector(sendAction) userInfo:nil repeats:YES];
    }
}


#pragma mark - Buttons 

NSInteger buttonAction;

-(IBAction)holdKey:(id)sender{
    buttonAction = [sender tag];
    [self sendAction];
    if (self.holdVolumeTimer!=nil){
        [self.holdVolumeTimer invalidate];
        self.holdVolumeTimer=nil;
    }
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

-(void)sendActionNoRepeat{
//    NSString *action;
    switch (buttonAction) {
        case 15: // MENU OSD
            [self GUIAction:@"Input.ShowOSD" params:[NSDictionary dictionaryWithObjectsAndKeys:nil] httpAPIcallback:@"SendKey(0xF04D)"];
            break;
        default:
            break;
    }
}

-(void)playerStep:(NSString *)step musicPlayerGo:(NSString *)musicAction{
    if ([AppDelegate instance].serverVersion > 11){
        if (jsonRPC == nil){
            GlobalData *obj=[GlobalData getInstance];
            NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
            NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
            jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
        }
        
        ;
        [jsonRPC
         callMethod:@"GUI.GetProperties"
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                         [[NSArray alloc] initWithObjects:@"currentwindow", @"fullscreen",nil], @"properties",
                         nil]
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
             if (error==nil && methodError==nil && [methodResult isKindOfClass: [NSDictionary class]]){
                 int winID = 0;
                 NSNumber *fullscreen = 0;
                 if (((NSNull *)[methodResult objectForKey:@"fullscreen"] != [NSNull null])){
                     fullscreen = [methodResult objectForKey:@"fullscreen"];
                 }
                 if (((NSNull *)[methodResult objectForKey:@"currentwindow"] != [NSNull null])){
                     winID = [[[methodResult objectForKey:@"currentwindow"] objectForKey:@"id"] intValue];
                 }
                 // 12005: WINDOW_FULLSCREEN_VIDEO
                 // 12006: WINDOW_VISUALISATION
                 if ([fullscreen boolValue] == YES && (winID == 12005 || winID == 12006)){
                     [jsonRPC
                      callMethod:@"XBMC.GetInfoBooleans"
                      withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                      [[NSArray alloc] initWithObjects:@"VideoPlayer.HasMenu", @"Pvr.IsPlayingTv", nil], @"booleans",
                                      nil]
                      onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                          if (error==nil && methodError==nil && [methodResult isKindOfClass: [NSDictionary class]]){
                              NSNumber *VideoPlayerHasMenu = 0;
                              NSNumber *PvrIsPlayingTv = 0;
                              if (((NSNull *)[methodResult objectForKey:@"VideoPlayer.HasMenu"] != [NSNull null])){
                                  VideoPlayerHasMenu = [methodResult objectForKey:@"VideoPlayer.HasMenu"];
                              }
                              if (((NSNull *)[methodResult objectForKey:@"Pvr.IsPlayingTv"] != [NSNull null])){
                                  PvrIsPlayingTv = [methodResult objectForKey:@"Pvr.IsPlayingTv"];
                              }
                              if (winID == 12005  && [PvrIsPlayingTv boolValue] == NO && [VideoPlayerHasMenu boolValue] == NO){
                                  [self playbackAction:@"Player.Seek" params:[NSArray arrayWithObjects:step, @"value", nil]];
                              }
                              else if (winID == 12006 && musicAction != nil){
                                  [self playbackAction:@"Player.GoTo" params:[NSArray arrayWithObjects:musicAction, @"to", nil]];
                              }
                          }
                      }];
                 }
             }
         }];
    }
    return;
}

-(void)sendAction{
    if (!buttonAction) return;
    if (self.holdVolumeTimer.timeInterval == 0.5f || self.holdVolumeTimer.timeInterval == 1.5f){
        
        if (self.holdVolumeTimer.timeInterval == 1.5f){
            [self.holdVolumeTimer invalidate];
            self.holdVolumeTimer=nil;
            self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(sendAction) userInfo:nil repeats:YES];  
        }
        else{
            [self.holdVolumeTimer invalidate];
            self.holdVolumeTimer=nil;
            self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(sendAction) userInfo:nil repeats:YES]; 
        }
    }
    NSString *action;
    switch (buttonAction) {
        case 10:
            action=@"Input.Up";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil] httpAPIcallback:nil];
            [self playerStep:@"bigforward" musicPlayerGo:nil];
            break;
            
        case 12:
            action=@"Input.Left";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil] httpAPIcallback:nil];
            [self playerStep:@"smallbackward" musicPlayerGo:@"previous"];
            break;
            
        case 13:
            action=@"Input.Select";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil] httpAPIcallback:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
            break;
            
        case 14:
            action=@"Input.Right";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil] httpAPIcallback:nil];
            [self playerStep:@"smallforward" musicPlayerGo:@"next"];
            break;
            
        case 16:
            action=@"Input.Down";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil] httpAPIcallback:nil];
            [self playerStep:@"bigbackward" musicPlayerGo:nil];
            break;
            
        case 18:
            action=@"Input.Back";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil] httpAPIcallback:nil];
            break;
            
        default:
            break;
    }
}




- (IBAction)startVibrate:(id)sender {
    NSString *action;
    NSArray *params;
    NSDictionary *dicParams;
    switch ([sender tag]) {
        case 1:
            action=@"GUI.SetFullscreen";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:@"toggle",@"fullscreen", nil] httpAPIcallback:@"SendKey(0xf009)"];
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
            if ([AppDelegate instance].serverVersion>11){
                action=@"Player.GoTo";
                params=[NSArray arrayWithObjects:@"previous", @"to", nil];
                [self playbackAction:action params:params];
            }
            else{
                action=@"Player.GoPrevious";
                params=nil;
                [self playbackAction:action params:nil];
            }
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
            if ([AppDelegate instance].serverVersion>11){
                action=@"Player.GoTo";
                params=[NSArray arrayWithObjects:@"next", @"to", nil];
                [self playbackAction:action params:params];
            }
            else{
                action=@"Player.GoNext";
                params=nil;
                [self playbackAction:action params:nil];
            }
            break;
        
        case 9: // HOME
            action=@"Input.Home";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil] httpAPIcallback:nil];
            break;
            
        case 11: // INFO
            action=@"Input.Info";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil] httpAPIcallback:@"SendKey(0xF049)"];
            break;
            
        case 15: // MENU OSD
            action = @"Input.ShowOSD";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil] httpAPIcallback:@"SendKey(0xF04D)"];
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
            action = @"GUI.ActivateWindow";
            dicParams = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"music", @"window",
                         nil];
            [self GUIAction:action params:dicParams httpAPIcallback:@"ExecBuiltIn&parameter=ActivateWindow(Music)"];
            break;
            
        case 22:
            action = @"GUI.ActivateWindow";
            dicParams = [NSDictionary dictionaryWithObjectsAndKeys:
                      @"videos", @"window",
                      [[NSArray alloc] initWithObjects:@"MovieTitles", nil], @"parameters",
                      nil];
            [self GUIAction:action params:dicParams httpAPIcallback:@"ExecBuiltIn&parameter=ActivateWindow(Videos,MovieTitles)"];
            break;
        
        case 23:
            action = @"GUI.ActivateWindow";
            dicParams = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"videos", @"window",
                         [[NSArray alloc] initWithObjects:@"tvshowtitles", nil], @"parameters",
                         nil];
            [self GUIAction:action params:dicParams httpAPIcallback:@"ExecBuiltIn&parameter=ActivateWindow(Videos,tvshowtitles)"];
            break;
        
        case 24:
            action = @"GUI.ActivateWindow";
            dicParams = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"pictures", @"window",
                         nil];
            [self GUIAction:action params:dicParams httpAPIcallback:@"ExecBuiltIn&parameter=ActivateWindow(Pictures)"];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
}

# pragma  mark - Gestures

- (void)handleSwipeFromRight:(id)sender {
    if ([self.navigationController.viewControllers indexOfObject:self] == 0){
        [self revealMenu:nil];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleSwipeFromLeft:(id)sender {
    if ([self.navigationController.viewControllers indexOfObject:self] == 0){
        [self revealUnderRight:nil];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)handleButtonLongPress:(UILongPressGestureRecognizer *)gestureRecognizer{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan){
        switch (gestureRecognizer.view.tag) {
            case 1:// FULLSCREEN BUTTON
                [self GUIAction:@"Input.ExecuteAction" params:[NSDictionary dictionaryWithObjectsAndKeys:@"togglefullscreen", @"action", nil] httpAPIcallback:@"Action(199)"];
                break;
                
            case 2:// BACKWARD BUTTON - DECREASE PLAYBACK SPEED
                [self playbackAction:@"Player.SetSpeed" params:[NSArray arrayWithObjects:@"decrement", @"speed", nil]];
                break;
                
            case 4:// FORWARD BUTTON - INCREASE PLAYBACK SPEED
                [self playbackAction:@"Player.SetSpeed" params:[NSArray arrayWithObjects:@"increment", @"speed", nil]];
                break;
                
            case 11:// CODEC INFO
                [self GUIAction:@"Input.ShowCodec" params:[NSDictionary dictionaryWithObjectsAndKeys:nil] httpAPIcallback:@"SendKey(0xF04F)"];
                break;
            
            case 15:// CONTEXT MENU 
                [self GUIAction:@"Input.ContextMenu" params:[NSDictionary dictionaryWithObjectsAndKeys:nil] httpAPIcallback:@"SendKey(0xF043)"];
                break;
                
            case 19:// SUBTITLES BUTTON
                if ([AppDelegate instance].serverVersion > 12){
                    [self GUIAction:@"GUI.ActivateWindow"
                             params:[NSDictionary dictionaryWithObjectsAndKeys:
                                     @"subtitlesearch", @"window",
                                     nil]
                    httpAPIcallback:nil];
                }
                else{
                    [self GUIAction:@"Addons.ExecuteAddon"
                             params:[NSDictionary dictionaryWithObjectsAndKeys:
                                     @"script.xbmc.subtitles", @"addonid",
                                     nil]
                    httpAPIcallback:@"ExecBuiltIn&parameter=RunScript(script.xbmc.subtitles)"];
                }
                break;
                
            case 22:
                [self GUIAction:@"GUI.ActivateWindow"
                         params:[NSDictionary dictionaryWithObjectsAndKeys:
                                 @"pvr", @"window",
                                 [[NSArray alloc] initWithObjects:@"31", @"0", @"10", @"0", nil], @"parameters",
                                 nil]
                httpAPIcallback:nil];
                break;
                
            case 23:
                [self GUIAction:@"GUI.ActivateWindow"
                         params:[NSDictionary dictionaryWithObjectsAndKeys:
                                 @"pvrosdguide", @"window",
                                 nil]
                httpAPIcallback:nil];
                break;
                
            case 24:
                [self GUIAction:@"GUI.ActivateWindow"
                         params:[NSDictionary dictionaryWithObjectsAndKeys:
                                 @"pvrosdchannels", @"window",
                                 nil]
                httpAPIcallback:nil];
                break;

            default:
                break;
        }
    }
}

#pragma mark - Quick Help

-(IBAction)toggleQuickHelp:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
    if (quickHelpView.alpha == 0){
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.2];
        quickHelpView.alpha = 1.0;
        [UIView commitAnimations];
        [self.navigationController setNavigationBarHidden:YES animated:YES];

    }
    else {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.2];
        quickHelpView.alpha = 0.0;
        [UIView commitAnimations];
        [self.navigationController setNavigationBarHidden:NO animated:YES];

    }
}

#pragma mark - Keyboard methods

-(void)toggleVirtualKeyboard:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleVirtualKeyboard" object:nil userInfo:nil];
}

-(void) hideKeyboard:(id)sender{
    [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
}

#pragma mark - Life Cycle

-(void)viewWillAppear:(BOOL)animated{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.slidingViewController.underRightViewController = nil;
        RightMenuViewController *rightMenuViewController = [[RightMenuViewController alloc] initWithNibName:@"RightMenuViewController" bundle:nil];
        rightMenuViewController.rightMenuItems = [AppDelegate instance].remoteControlMenuItems;
        self.slidingViewController.underRightViewController = rightMenuViewController;
        UIImage* settingsImg = [UIImage imageNamed:@"button_settings"];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:settingsImg style:UIBarButtonItemStyleBordered target:self action:@selector(revealUnderRight:)];
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")){
            [self.navigationController.navigationBar setBarTintColor:REMOTE_CONTROL_BAR_TINT_COLOR];            
        }
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    quickHelpView.alpha = 0.0;
    [self volumeInfo];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(revealMenu:)
                                                 name: @"RevealMenu"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(toggleVirtualKeyboard:)
                                                 name: @"UIToggleVirtualKeyboard"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(toggleQuickHelp:)
                                                 name: @"UIToggleQuickHelp"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(toggleGestureZone:)
                                                 name: @"UIToggleGestureZone"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(hideKeyboard:)
                                                 name: @"ECSlidingViewUnderRightWillAppear"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(hideKeyboard:)
                                                 name: @"ECSlidingViewUnderLeftWillAppear"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleECSlidingViewTopDidReset:)
                                                 name: @"ECSlidingViewTopDidReset"
                                               object: nil];
}

-(void)handleECSlidingViewTopDidReset:(id)sender{
    [self.navigationController.view removeGestureRecognizer:self.slidingViewController.panGesture];
    [self.navigationController.navigationBar addGestureRecognizer:self.slidingViewController.panGesture];
}

- (void)revealMenu:(id)sender{
    [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)revealUnderRight:(id)sender{
    [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    [self.slidingViewController anchorTopViewTo:ECLeft];
}

-(void)resetRemote{
    [self stopHoldKey:nil];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
 
}

-(void)viewWillDisappear:(BOOL)animated{
    [self resetRemote];
}

- (void)turnTorchOn:(UIButton *)sender {
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    torchIsOn = !torchIsOn;
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            [device lockForConfiguration:nil];
            if (torchIsOn) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                torchIsOn = YES;
                [sender setImage:[UIImage imageNamed:@"torch_on"] forState:UIControlStateNormal];
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
                torchIsOn = NO;
                [sender setImage:[UIImage imageNamed:@"torch"] forState:UIControlStateNormal];
            }
            [device unlockForConfiguration];
        }
    }
}

- (void)viewDidLoad{
    [super viewDidLoad];
    float infoButtonOriginY = -16;
    float infoButtonalpha = 0.9f;

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")){
        self.edgesForExtendedLayout = 0;
        self.view.tintColor = TINT_COLOR;
        infoButtonOriginY = -14;
        infoButtonalpha = 1.0f;
    }
    [self configureView];
    [[SDImageCache sharedImageCache] clearMemory];
    [[gestureZoneImageView layer] setMinificationFilter:kCAFilterTrilinear];
    UIImage* gestureSwitchImg = [UIImage imageNamed:@"finger.png"];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    BOOL showGesture=[[userDefaults objectForKey:@"gesture_preference"] boolValue];
    if (showGesture){
        gestureSwitchImg = [UIImage imageNamed:@"circle.png"];
        CGRect frame = [gestureZoneView frame];
        frame.origin.x = 0;
        gestureZoneView.frame = frame;
        frame = [buttonZoneView frame];
        frame.origin.x = 320;
        buttonZoneView.frame = frame;
        gestureZoneView.alpha = 1;
        buttonZoneView.alpha = 0;
        leftSwipe.enabled = NO;
        rightSwipe.enabled = NO;
    }
    torchIsOn = NO;
    NSString *torchIcon = @"torch";
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            if ([device torchLevel] == YES){
                torchIsOn = YES;
                torchIcon = @"torch_on";
            }
        }
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIButton *settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        settingButton.frame = CGRectMake(self.view.bounds.size.width - 238, self.view.bounds.size.height - 36, 22, 22);
        [settingButton setContentMode:UIViewContentModeRight];
        [settingButton setShowsTouchWhenHighlighted:YES];
        [settingButton setImage:[UIImage imageNamed:@"default-right-menu-icon"] forState:UIControlStateNormal];
        settingButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [settingButton addTarget:self action:@selector(addButtonToListIPad:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:settingButton];
        
        UIButton *gestureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        gestureButton.frame = CGRectMake(self.view.bounds.size.width - 188, self.view.bounds.size.height - 43, 56.0, 36.0);
        [gestureButton setContentMode:UIViewContentModeRight];
        [gestureButton setShowsTouchWhenHighlighted:YES];
        [gestureButton setImage:gestureSwitchImg forState:UIControlStateNormal];
        gestureButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [gestureButton addTarget:self action:@selector(toggleGestureZone:) forControlEvents:UIControlEventTouchUpInside];
        gestureButton.alpha = .8f;
        [self.view addSubview:gestureButton];
        
        UIButton *keyboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
        keyboardButton.frame = CGRectMake(self.view.bounds.size.width - 120, self.view.bounds.size.height - 43, 56.0, 36.0);
        UIImage* keyboardImg = [UIImage imageNamed:@"keyboard_icon.png"];
        [keyboardButton setContentMode:UIViewContentModeRight];
        [keyboardButton setShowsTouchWhenHighlighted:YES];
        [keyboardButton setImage:keyboardImg forState:UIControlStateNormal];
        keyboardButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [keyboardButton addTarget:self action:@selector(toggleVirtualKeyboard:) forControlEvents:UIControlEventTouchUpInside];
        keyboardButton.alpha = .8f;
        [self.view addSubview:keyboardButton];

        UIButton *helpButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
        helpButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [helpButton addTarget:self action:@selector(toggleQuickHelp:) forControlEvents:UIControlEventTouchUpInside];
        CGRect buttonRect = helpButton.frame;
        buttonRect.origin.x = self.view.bounds.size.width - buttonRect.size.width - 16;
        buttonRect.origin.y = self.view.bounds.size.height - buttonRect.size.height + infoButtonOriginY;
        [helpButton setFrame:buttonRect];
        helpButton.alpha = infoButtonalpha;
        [self.view addSubview:helpButton];
    }
    storeBrightness = -1;
    [self.view setBackgroundColor:[UIColor colorWithPatternImage: [UIImage imageNamed:@"backgroundImage_repeat.png"]]];
}

-(void)addButtonToListIPad:(id)sender {
    if ([AppDelegate instance].serverVersion < 13){
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"XBMC \"Gotham\" version 13  or superior is required to access XBMC settings", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
    }
    else{
        RightMenuViewController *rightMenuViewController = [[RightMenuViewController alloc] initWithNibName:@"RightMenuViewController" bundle:nil];
        rightMenuViewController.rightMenuItems = [AppDelegate instance].remoteControlMenuItems;
        if ([rightMenuViewController.rightMenuItems count]){
            mainMenu *menuItem = [rightMenuViewController.rightMenuItems  objectAtIndex:0];
            menuItem.mainMethod = nil;
        }
        [rightMenuViewController.view setFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height)];
        [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:rightMenuViewController invokeByController:self isStackStartView:FALSE];
    }
}

- (void)viewDidUnload{
    TransitionalView = nil;
    gestureZoneImageView = nil;
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    jsonRPC = nil;
}

-(void)dealloc{
    jsonRPC = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)shouldAutorotate{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

@end
