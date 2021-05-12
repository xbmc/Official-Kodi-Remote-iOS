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

#define ROTATION_TRIGGER 0.015 
#define SCALE_TO_REDUCE_BORDERS 1.05

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
    CGFloat transform = [Utilities getTransformX];
    int startX = -6;
    int startY = 6;
    int transViewY = 46;
    if (transform>=1.29) {
        // All devices with width >= 414
        startX = 6;
        transViewY = 66;
    }
    else if (transform>1.0) {
        // All devices with 320 > width > 414
        startX = 3;
        transViewY = 58;
    }
        
    int newWidth = (int) (296 * transform);
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
    BOOL showGesture = [[userDefaults objectForKey:@"gesture_preference"] boolValue];
    if (showGesture){
        gestureSwitchImg = [UIImage imageNamed:@"circle"];
        frame = [gestureZoneView frame];
        frame.origin.x = 0;
        gestureZoneView.frame = frame;
        frame = [buttonZoneView frame];
        frame.origin.x = self.view.frame.size.width;
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
    [gestureButton setBackgroundImage:[UIImage imageNamed:@"remote_button_blank_up"] forState:UIControlStateNormal];
    [gestureButton setBackgroundImage:[UIImage imageNamed:@"remote_button_blank_down"] forState:UIControlStateHighlighted];
    gestureButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [gestureButton addTarget:self action:@selector(toggleGestureZone:) forControlEvents:UIControlEventTouchUpInside];
    [remoteControlView addSubview:gestureButton];
    
    frame = subsInfoLabel.frame;
    frame.origin.x = -1 * startX;
    frame.size.width = newWidth + (startX * 2);
    subsInfoLabel.frame = frame;
}

- (void)configureView{
    if (self.detailItem) {
        self.navigationItem.title = [self.detailItem mainLabel]; 
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        quickHelpImageView.image = [UIImage imageNamed:@"remote quick help"];
        CGFloat transform = [Utilities getTransformX];
        CGRect frame = remoteControlView.frame;
        frame.size.height = frame.size.height *transform;
        frame.size.width = frame.size.width*transform;
        [remoteControlView setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width* SCALE_TO_REDUCE_BORDERS, frame.size.height* SCALE_TO_REDUCE_BORDERS)];
        frame = subsInfoLabel.frame;
        frame.size.width = [[UIScreen mainScreen ] bounds].size.width;
        frame.origin.x = ((remoteControlView.frame.size.width - [[UIScreen mainScreen ] bounds].size.width) / 2);
        subsInfoLabel.frame = frame;
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
        CGRect frame = subsInfoLabel.frame;
        frame.size.width = newWidth;
        frame.origin.x = 0;
        subsInfoLabel.frame = frame;
        
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
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

#pragma mark - Touch

-(void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
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
    [self GUIAction:@"Input.Home" params:[NSDictionary dictionary] httpAPIcallback:nil];
}

- (void)handleTouchpadLongPress:(UILongPressGestureRecognizer*)gestureRecognizer { 
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan){
        [[Utilities getJsonRPC]
         callMethod:@"XBMC.GetInfoBooleans" 
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                         [[NSArray alloc] initWithObjects:@"Window.IsActive(fullscreenvideo)", @"Window.IsActive(visualisation)", @"Window.IsActive(slideshow)", nil], @"booleans",
                         nil] 
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
             
             if (error==nil && methodError==nil && [methodResult isKindOfClass: [NSDictionary class]]){
                 NSNumber *fullscreenActive = 0;
                 NSNumber *visualisationActive = 0;
                 NSNumber *slideshowActive = 0;

                 if (((NSNull *)methodResult[@"Window.IsActive(fullscreenvideo)"] != [NSNull null])){
                     fullscreenActive = methodResult[@"Window.IsActive(fullscreenvideo)"];
                 }
                 if (((NSNull *)methodResult[@"Window.IsActive(visualisation)"] != [NSNull null])){
                     visualisationActive = methodResult[@"Window.IsActive(visualisation)"];
                 }
                 if (((NSNull *)methodResult[@"Window.IsActive(slideshow)"] != [NSNull null])){
                     slideshowActive = methodResult[@"Window.IsActive(slideshow)"];
                 }
                 if ([fullscreenActive intValue] == 1 || [visualisationActive intValue] == 1 || [slideshowActive intValue] == 1){
                     buttonAction = 15;
                     [self sendActionNoRepeat];
                 }
                 else{
                     [self GUIAction:@"Input.ContextMenu" params:[NSDictionary dictionary] httpAPIcallback:@"SendKey(0xF043)"];
                 }
             }
             else{
                 [self GUIAction:@"Input.ContextMenu" params:[NSDictionary dictionary] httpAPIcallback:@"SendKey(0xF043)"];
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

-(void)showSubInfo:(NSString *)message timeout:(NSTimeInterval)timeout color:(UIColor *)color{
    // first fadeout 
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.1];
    subsInfoLabel.alpha = 0;
    [UIView commitAnimations];
    [subsInfoLabel setText:message];
    [subsInfoLabel setTextColor:color];
    // then fade in
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.1];
    subsInfoLabel.hidden = NO;
    subsInfoLabel.alpha = 0.8;
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
    subsInfoLabel.alpha = 0;
    [UIView commitAnimations];
    [fadeoutTimer invalidate];
    fadeoutTimer = nil;
}

# pragma mark - ToolBar

-(void)toggleGestureZone:(id)sender{
    NSString *imageName=@"blank";
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
        frame.origin.x = -self.view.frame.size.width;
        gestureZoneView.frame = frame;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];     
        [UIView setAnimationDuration:0.3];
        frame = [gestureZoneView frame];
        frame.origin.x = 0;
        gestureZoneView.frame = frame;
        frame = [buttonZoneView frame];
        frame.origin.x = self.view.frame.size.width;
        buttonZoneView.frame = frame;
        gestureZoneView.alpha = 1;
        buttonZoneView.alpha = 0;
        [UIView commitAnimations];
        imageName=@"circle";
    }
    else{
        CGRect frame;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.3];      
        frame = [gestureZoneView frame];
        frame.origin.x = -self.view.frame.size.width;
        gestureZoneView.frame = frame;
        frame = [buttonZoneView frame];
        frame.origin.x = 0;
        buttonZoneView.frame = frame;
        gestureZoneView.alpha = 0;
        buttonZoneView.alpha = 1;
        [UIView commitAnimations];
        imageName=@"finger";
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
        [mutableDictionary setObject:array[i] forKey:array[i+1]];
    }
    return (NSDictionary *)mutableDictionary;
}

/* method to show an action sheet for subs. */

-(void)subtitlesActionSheet {
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionary] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil) {
            if( [methodResult count] > 0) {
                NSNumber *response;
                if (((NSNull *)methodResult[0][@"playerid"] != [NSNull null])) {
                    response = methodResult[0][@"playerid"];
                }
                [[Utilities getJsonRPC]
                 callMethod:@"Player.GetProperties"
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                 response, @"playerid",
                                 [[NSArray alloc] initWithObjects:@"subtitleenabled", @"currentsubtitle", @"subtitles", nil], @"properties",
                                 nil]
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error==nil && methodError==nil) {
                         if( [NSJSONSerialization isValidJSONObject:methodResult]) {
                             if ([methodResult count]){
                                 NSDictionary *currentSubtitle = methodResult[@"currentsubtitle"];
                                 BOOL subtitleEnabled = [methodResult[@"subtitleenabled"] boolValue];
                                 NSArray *subtitles = methodResult[@"subtitles"];
                                 if ([subtitles count]) {
                                     subsDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                       currentSubtitle, @"currentsubtitle",
                                                       @(subtitleEnabled), @"subtitleenabled",
                                                       subtitles, @"subtitles",
                                                       nil];
                                     NSInteger numSubs=[subtitles count];
                                     NSMutableArray *actionSheetTitles =[NSMutableArray array];
                                     for (int i = 0; i < numSubs; i++) {
                                         NSString *language = @"?";
                                         if (((NSNull *)subtitles[i][@"language"] != [NSNull null])) {
                                             NSLocale *currentLocale = [[NSLocale alloc] initWithLocaleIdentifier:NSLocalizedString(@"LocaleIdentifier",nil)];
                                             NSString *canonicalID = [NSLocale canonicalLanguageIdentifierFromString:subtitles[i][@"language"]];
                                             NSString *displayNameString = [currentLocale displayNameForKey:NSLocaleIdentifier value:canonicalID];
                                             if ([displayNameString length] > 0){
                                                 language = displayNameString;
                                             }
                                             else {
                                                 language = subtitles[i][@"language"];
                                             }
                                             if ([language length] == 0) {
                                                 language = NSLocalizedString(@"Unknown", nil);
                                             }
                                         }
                                         NSString *tickMark = @"";
                                         if (subtitleEnabled == YES && [currentSubtitle isEqual:subtitles[i]]) {
                                             tickMark = @"\u2713 ";
                                         }
                                         NSString *title = [NSString stringWithFormat:@"%@%@%@%@ (%d/%ld)", tickMark, language, [subtitles[i][@"name"] isEqual:@""] ? @"" : @" - ", subtitles[i][@"name"], i + 1, (long)numSubs];
                                         [actionSheetTitles addObject:title];
                                     }
                                     [self showActionSubtitles:actionSheetTitles];
                                }
                                 else {
                                     [self showSubInfo:NSLocalizedString(@"Subtitles not available",nil) timeout:2.0 color:[Utilities getSystemRed:1.0]];
                                 }
                             }
                         }
                     }
                 }];
            }
            else{
                [self showSubInfo:NSLocalizedString(@"Subtitles not available",nil) timeout:2.0 color:[Utilities getSystemRed:1.0]];
            }
        }
    }];
}

-(void)audioStreamActionSheet {
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionary] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                NSNumber *response;
                if (((NSNull *)methodResult[0][@"playerid"] != [NSNull null])){
                    response = methodResult[0][@"playerid"];
                }
                [[Utilities getJsonRPC]
                 callMethod:@"Player.GetProperties"
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                 response, @"playerid",
                                 [[NSArray alloc] initWithObjects: @"currentaudiostream", @"audiostreams", nil], @"properties",
                                 nil]
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error==nil && methodError==nil){
                         if( [NSJSONSerialization isValidJSONObject:methodResult]){
                             if ([methodResult count]){
                                 NSDictionary *currentAudiostream = methodResult[@"currentaudiostream"];
                                 NSArray *audiostreams = methodResult[@"audiostreams"];
                                 if ([audiostreams count]) {
                                     audiostreamsDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                       currentAudiostream, @"currentaudiostream",
                                                       audiostreams, @"audiostreams",
                                                       nil];
                                     NSInteger numAudio=[audiostreams count];
                                     NSMutableArray *actionSheetTitles =[NSMutableArray array];
                                     for (int i = 0; i < numAudio; i++) {
                                         NSString *language = @"?";
                                         if (((NSNull *)audiostreams[i][@"language"] != [NSNull null])) {
                                             NSLocale *currentLocale = [[NSLocale alloc] initWithLocaleIdentifier:NSLocalizedString(@"LocaleIdentifier",nil)];
                                             NSString *canonicalID = [NSLocale canonicalLanguageIdentifierFromString:audiostreams[i][@"language"]];
                                             NSString *displayNameString = [currentLocale displayNameForKey:NSLocaleIdentifier value:canonicalID];
                                             if ([displayNameString length] > 0){
                                                 language = displayNameString;
                                             }
                                             else {
                                                 language = audiostreams[i][@"language"];
                                             }
                                             if ([language length] == 0) {
                                                 language = NSLocalizedString(@"Unknown", nil);
                                             }
                                         }
                                         NSString *tickMark = @"";
                                         if ([currentAudiostream isEqual:audiostreams[i]]) {
                                             tickMark = @"\u2713 ";
                                         }
                                         NSString *title = [NSString stringWithFormat:@"%@%@%@%@ (%d/%ld)", tickMark, language, [audiostreams[i][@"name"] isEqual:@""] ? @"" : @" - ", audiostreams[i][@"name"], i + 1, (long)numAudio];
                                         [actionSheetTitles addObject:title];
                                     }
                                     [self showActionAudiostreams:actionSheetTitles];
                                 }
                                 else {
                                     [self showSubInfo:NSLocalizedString(@"Audiostreams not available",nil) timeout:2.0 color:[Utilities getSystemRed:1.0]];
                                 }
                             }
                        }
                     }
                 }];
            }
            else{
                [self showSubInfo:NSLocalizedString(@"Audiostream not available",nil) timeout:2.0 color:[Utilities getSystemRed:1.0]];
            }
        }
    }];
}

-(void)playbackAction:(NSString *)action params:(NSArray *)parameters{
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionary] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                NSNumber *response = methodResult[0][@"playerid"];
                NSMutableArray *commonParams=[NSMutableArray arrayWithObjects:response, @"playerid", nil];
                if (parameters!=nil)
                    [commonParams addObjectsFromArray:parameters];
                [[Utilities getJsonRPC] callMethod:action withParameters:[self indexKeyedDictionaryFromArray:commonParams] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
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
    [[Utilities getJsonRPC] callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
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
    [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
}

-(void)volumeInfo{
    if ([AppDelegate instance].serverVolume > -1){
        audioVolume = [AppDelegate instance].serverVolume;
    }
    else{
        audioVolume = 0;
    }

//    [[Utilities getJsonRPC]
//     callMethod:@"Application.GetProperties" 
//     withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [[NSArray alloc] initWithObjects:@"volume", nil], @"properties", nil]
//     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
//         if (error==nil && methodError==nil){
//             if( [NSJSONSerialization isValidJSONObject:methodResult] && [methodResult count]){
//                 audioVolume =  [methodResult[@"volume"] intValue];
//             }
//         }
//     }];
}

-(void)changeServerVolume{
    [[Utilities getJsonRPC]
     callMethod:@"Application.SetVolume" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:audioVolume], @"volume", nil]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([touches count] == 1){
        NSTimeInterval timeInterval = 1.5;
        if (buttonAction > 0) {
            timeInterval = 0.5;
        }
        self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(sendAction) userInfo:nil repeats:YES];
    }
}

#pragma mark - Action Sheet Method

-(void)showActionAudiostreams:(NSMutableArray *)sheetActions {
    NSInteger numActions = [sheetActions count];
    if (numActions) {
        UIAlertController *actionView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Audio stream", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction* action_cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];
        
        for (int i = 0; i < numActions; i++) {
            NSString *actiontitle = sheetActions[i];
            UIAlertAction* action = [UIAlertAction actionWithTitle:actiontitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                if (![audiostreamsDictionary[@"audiostreams"][i] isEqual:audiostreamsDictionary[@"currentaudiostream"]]){
                    [self playbackAction:@"Player.SetAudioStream" params:[NSArray arrayWithObjects:audiostreamsDictionary[@"audiostreams"][i][@"index"], @"stream", nil]];
                    [self showSubInfo:actiontitle timeout:2.0 color:[UIColor whiteColor]];
                }
            }];
            [actionView addAction:action];
        }
        [actionView addAction:action_cancel];
        [actionView setModalPresentationStyle:UIModalPresentationPopover];
        
        UIButton *audioStreamsButton = (UIButton *)[self.view viewWithTag:20];
        UIPopoverPresentationController *popPresenter = [actionView popoverPresentationController];
        if (popPresenter != nil) {
            popPresenter.sourceView = self.view;
            popPresenter.sourceRect = CGRectMake(audioStreamsButton.center.x, audioStreamsButton.center.y, 1, 1);
        }
        [self presentViewController:actionView animated:YES completion:nil];
    }
}

-(void)showActionSubtitles:(NSMutableArray *)sheetActions {
    NSInteger numActions = [sheetActions count];
    if (numActions) {
        UIAlertController *actionView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Subtitles", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction* action_cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];
        
        UIAlertAction* action_disable = [UIAlertAction actionWithTitle:NSLocalizedString(@"Disable subtitles", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            [self showSubInfo:NSLocalizedString(@"Subtitles disabled", nil) timeout:2.0 color:[Utilities getSystemRed:1.0]];
            [self playbackAction:@"Player.SetSubtitle" params:[NSArray arrayWithObjects:@"off", @"subtitle", nil]];
        }];
        if ([subsDictionary[@"subtitleenabled"] boolValue]) {
            [actionView addAction:action_disable];
        }
        
        for (int i = 0; i < numActions; i++) {
            NSString *actiontitle = sheetActions[i];
            UIAlertAction* action = [UIAlertAction actionWithTitle:actiontitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                if (![subsDictionary[@"subtitles"][i] isEqual:subsDictionary[@"currentsubtitle"]] || [subsDictionary[@"subtitleenabled"] boolValue] == NO){
                    [self playbackAction:@"Player.SetSubtitle" params:[NSArray arrayWithObjects:subsDictionary[@"subtitles"][i][@"index"], @"subtitle", nil]];
                    [self playbackAction:@"Player.SetSubtitle" params:[NSArray arrayWithObjects:@"on", @"subtitle", nil]];
                    [self showSubInfo:actiontitle timeout:2.0 color:[UIColor whiteColor]];
                }
            }];
            [actionView addAction:action];
        }
        [actionView addAction:action_cancel];
        [actionView setModalPresentationStyle:UIModalPresentationPopover];
        
        UIButton *subsButton = (UIButton *)[self.view viewWithTag:19];
        UIPopoverPresentationController *popPresenter = [actionView popoverPresentationController];
        if (popPresenter != nil) {
            popPresenter.sourceView = self.view;
            popPresenter.sourceRect = CGRectMake(subsButton.center.x, subsButton.center.y, 1, 1);
        }
        [self presentViewController:actionView animated:YES completion:nil];
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
    self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(sendAction) userInfo:nil repeats:YES];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    
    BOOL startVibrate = [[userDefaults objectForKey:@"vibrate_preference"] boolValue];
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
            [self GUIAction:@"Input.ShowOSD" params:[NSDictionary dictionary] httpAPIcallback:@"SendKey(0xF04D)"];
            break;
        default:
            break;
    }
}

-(void)playerStep:(NSString *)step musicPlayerGo:(NSString *)musicAction musicPlayerAction:(NSString *)musicMethod {
    if ([AppDelegate instance].serverVersion > 11){
        [[Utilities getJsonRPC]
         callMethod:@"GUI.GetProperties"
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                         [[NSArray alloc] initWithObjects:@"currentwindow", @"fullscreen",nil], @"properties",
                         nil]
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
             if (error==nil && methodError==nil && [methodResult isKindOfClass: [NSDictionary class]]){
                 int winID = 0;
                 NSNumber *fullscreen = 0;
                 if (((NSNull *)methodResult[@"fullscreen"] != [NSNull null])){
                     fullscreen = methodResult[@"fullscreen"];
                 }
                 if (((NSNull *)methodResult[@"currentwindow"] != [NSNull null])){
                     winID = [methodResult[@"currentwindow"][@"id"] intValue];
                 }
                 // 12005: WINDOW_FULLSCREEN_VIDEO
                 // 12006: WINDOW_VISUALISATION
                 if ([fullscreen boolValue] == YES && (winID == 12005 || winID == 12006)){
                     [[Utilities getJsonRPC]
                      callMethod:@"XBMC.GetInfoBooleans"
                      withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                      [[NSArray alloc] initWithObjects:@"VideoPlayer.HasMenu", @"Pvr.IsPlayingTv", nil], @"booleans",
                                      nil]
                      onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                          if (error==nil && methodError==nil && [methodResult isKindOfClass: [NSDictionary class]]){
                              NSNumber *VideoPlayerHasMenu = 0;
                              NSNumber *PvrIsPlayingTv = 0;
                              if (((NSNull *)methodResult[@"VideoPlayer.HasMenu"] != [NSNull null])){
                                  VideoPlayerHasMenu = methodResult[@"VideoPlayer.HasMenu"];
                              }
                              if (((NSNull *)methodResult[@"Pvr.IsPlayingTv"] != [NSNull null])){
                                  PvrIsPlayingTv = methodResult[@"Pvr.IsPlayingTv"];
                              }
                              if (winID == 12005  && [PvrIsPlayingTv boolValue] == NO && [VideoPlayerHasMenu boolValue] == NO){
                                  [self playbackAction:@"Player.Seek" params:[Utilities buildPlayerSeekStepParams:step]];
                              }
                              else if (winID == 12006 && musicAction != nil){
                                  [self playbackAction:@"Player.GoTo" params:[NSArray arrayWithObjects:musicAction, @"to", nil]];
                              }
                              else if (winID == 12006 && musicMethod != nil){
                                  [self GUIAction:@"Input.ExecuteAction" params:[NSDictionary dictionaryWithObjectsAndKeys:musicMethod, @"action", nil] httpAPIcallback:nil];
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
    if (self.holdVolumeTimer.timeInterval == 0.5 || self.holdVolumeTimer.timeInterval == 1.5){
        
        if (self.holdVolumeTimer.timeInterval == 1.5){
            [self.holdVolumeTimer invalidate];
            self.holdVolumeTimer=nil;
            self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(sendAction) userInfo:nil repeats:YES];
        }
        else{
            [self.holdVolumeTimer invalidate];
            self.holdVolumeTimer=nil;
            self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(sendAction) userInfo:nil repeats:YES]; 
        }
    }
    NSString *action;
    switch (buttonAction) {
        case 10:
            action=@"Input.Up";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:nil];
            [self playerStep:@"bigforward" musicPlayerGo:nil musicPlayerAction:@"increaserating"];
            break;
            
        case 12:
            action=@"Input.Left";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:nil];
            [self playerStep:@"smallbackward" musicPlayerGo:@"previous" musicPlayerAction:nil];
            break;

        case 13:
            action=@"Input.Select";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
            break;

        case 14:
            action=@"Input.Right";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:nil];
            [self playerStep:@"smallforward" musicPlayerGo:@"next" musicPlayerAction:nil];
            break;
            
        case 16:
            action=@"Input.Down";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:nil];
            [self playerStep:@"bigbackward" musicPlayerGo:nil musicPlayerAction:@"decreaserating"];
            break;
            
        case 18:
            action=@"Input.Back";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:nil];
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
            params = [Utilities buildPlayerSeekStepParams:@"smallbackward"];
            [self playbackAction:action params:params];
            break;
            
        case 3:
            action=@"Player.PlayPause";
            params=nil;
            [self playbackAction:action params:nil];
            break;
            
        case 4:
            action=@"Player.Seek";
            params = [Utilities buildPlayerSeekStepParams:@"smallforward"];
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
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:nil];
            break;
            
        case 11: // INFO
            action=@"Input.Info";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:@"SendKey(0xF049)"];
            break;
            
        case 13:
            action=@"Input.Select";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
            break;
            
        case 15: // MENU OSD
            action = @"Input.ShowOSD";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:@"SendKey(0xF04D)"];
            break;
        
        case 19:
            [self subtitlesActionSheet];
            break;
            
        case 20:
            [self audioStreamActionSheet];
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
    
    BOOL startVibrate = [[userDefaults objectForKey:@"vibrate_preference"] boolValue];
    if (startVibrate){
        [[UIDevice currentDevice] playInputClick];
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
}

# pragma  mark - Gestures

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
                if ([AppDelegate instance].serverVersion > 16) {
                    [self GUIAction:@"Input.ExecuteAction" params:[NSDictionary dictionaryWithObjectsAndKeys:@"playerdebug", @"action", nil] httpAPIcallback:nil];
                }
                else {
                    [self GUIAction:@"Input.ShowCodec" params:[NSDictionary dictionary] httpAPIcallback:@"SendKey(0xF04F)"];
                }
                break;

            case 13:// CONTEXT MENU
            case 15:
                [self GUIAction:@"Input.ContextMenu" params:[NSDictionary dictionary] httpAPIcallback:@"SendKey(0xF043)"];
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
        [self.navigationController setNavigationBarHidden:NO animated:YES];

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
    [super viewWillAppear:animated];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.slidingViewController.underRightViewController = nil;
        RightMenuViewController *rightMenuViewController = [[RightMenuViewController alloc] initWithNibName:@"RightMenuViewController" bundle:nil];
        rightMenuViewController.rightMenuItems = [AppDelegate instance].remoteControlMenuItems;
        self.slidingViewController.underRightViewController = rightMenuViewController;
        UIImage* settingsImg = [UIImage imageNamed:@"button_settings"];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:settingsImg style:UIBarButtonItemStylePlain target:self action:@selector(revealUnderRight:)];
        [self.navigationController.navigationBar setBarTintColor:REMOTE_CONTROL_BAR_TINT_COLOR];
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
    [super viewWillDisappear:animated];
    [self resetRemote];
}

- (void)turnTorchOn:(UIButton *)sender {
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    torchIsOn = !torchIsOn;
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
        if ([device hasTorch] && [device hasFlash]){
            [device lockForConfiguration:nil];
            if (torchIsOn) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [settings setFlashMode:AVCaptureFlashModeOn];
                torchIsOn = YES;
                [sender setImage:[UIImage imageNamed:@"torch_on"] forState:UIControlStateNormal];
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [settings setFlashMode:AVCaptureFlashModeOff];
                torchIsOn = NO;
                [sender setImage:[UIImage imageNamed:@"torch"] forState:UIControlStateNormal];
            }
            [device unlockForConfiguration];
        }
    }
}

- (void)viewDidLoad{
    [super viewDidLoad];
    SDWebImageDownloader *manager = [SDWebImageManager sharedManager].imageDownloader;
    NSDictionary *httpHeaders = [AppDelegate instance].getServerHTTPHeaders;
    if (httpHeaders[@"Authorization"] != nil){
        [manager setValue:httpHeaders[@"Authorization"] forHTTPHeaderField:@"Authorization"];
    }
    CGFloat infoButtonOriginY = -16;
    CGFloat infoButtonalpha = 0.9;

    self.edgesForExtendedLayout = 0;
    self.view.tintColor = TINT_COLOR;
    infoButtonOriginY = -14;
    infoButtonalpha = 1.0;
    [self configureView];
    [[SDImageCache sharedImageCache] clearMemory];
    [[gestureZoneImageView layer] setMinificationFilter:kCAFilterTrilinear];
    UIImage* gestureSwitchImg = [UIImage imageNamed:@"finger"];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    BOOL showGesture = [[userDefaults objectForKey:@"gesture_preference"] boolValue];
    if (showGesture){
        gestureSwitchImg = [UIImage imageNamed:@"circle"];
        CGRect frame = [gestureZoneView frame];
        frame.origin.x = 0;
        gestureZoneView.frame = frame;
        frame = [buttonZoneView frame];
        frame.origin.x = self.view.frame.size.width;
        buttonZoneView.frame = frame;
        gestureZoneView.alpha = 1;
        buttonZoneView.alpha = 0;
    }
    torchIsOn = NO;
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            if ([device torchLevel] == YES){
                torchIsOn = YES;
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
        gestureButton.frame = CGRectMake(self.view.bounds.size.width - 188, self.view.bounds.size.height - 43, 56, 36);
        [gestureButton setContentMode:UIViewContentModeRight];
        [gestureButton setShowsTouchWhenHighlighted:YES];
        [gestureButton setImage:gestureSwitchImg forState:UIControlStateNormal];
        gestureButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [gestureButton addTarget:self action:@selector(toggleGestureZone:) forControlEvents:UIControlEventTouchUpInside];
        gestureButton.alpha = 0.8;
        [self.view addSubview:gestureButton];
        
        UIButton *keyboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
        keyboardButton.frame = CGRectMake(self.view.bounds.size.width - 120, self.view.bounds.size.height - 43, 56, 36);
        UIImage* keyboardImg = [UIImage imageNamed:@"keyboard_icon"];
        [keyboardButton setContentMode:UIViewContentModeRight];
        [keyboardButton setShowsTouchWhenHighlighted:YES];
        [keyboardButton setImage:keyboardImg forState:UIControlStateNormal];
        keyboardButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [keyboardButton addTarget:self action:@selector(toggleVirtualKeyboard:) forControlEvents:UIControlEventTouchUpInside];
        keyboardButton.alpha = 0.8;
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
    [self.view setBackgroundColor:[UIColor colorWithPatternImage: [UIImage imageNamed:@"backgroundImage_repeat"]]];
}

-(void)addButtonToListIPad:(id)sender {
    if ([AppDelegate instance].serverVersion < 13){
        UIAlertController *alertView = [Utilities createAlertOK:@"" message:NSLocalizedString(@"XBMC \"Gotham\" version 13 or superior is required to access XBMC settings", nil)];
        [self presentViewController:alertView animated:YES completion:nil];
    }
    else{
        RightMenuViewController *rightMenuViewController = [[RightMenuViewController alloc] initWithNibName:@"RightMenuViewController" bundle:nil];
        rightMenuViewController.rightMenuItems = [AppDelegate instance].remoteControlMenuItems;
        if ([rightMenuViewController.rightMenuItems count]){
            mainMenu *menuItem = rightMenuViewController.rightMenuItems[0];
            menuItem.mainMethod = nil;
        }
        [rightMenuViewController.view setFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height)];
        [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:rightMenuViewController invokeByController:self isStackStartView:FALSE];
    }
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(BOOL)shouldAutorotate{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
