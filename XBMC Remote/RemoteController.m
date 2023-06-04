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
#import "SDImageCache.h"
#import "AppDelegate.h"
#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"
#import "RemoteControllerGestureZoneView.h"
#import "RightMenuViewController.h"
#import "DetailViewController.h"
#import "Utilities.h"

#define ROTATION_TRIGGER 0.015
#define REMOTE_PADDING (44 + 44 + 44) // Space unused above and below the popover and by remote toolbar
#define TOOLBAR_ICON_SIZE 36
#define TOOLBAR_FIXED_OFFSET 8
#define TOOLBAR_HEIGHT (TOOLBAR_ICON_SIZE + TOOLBAR_FIXED_OFFSET)
#define TOOLBAR_PARENT_HEIGHT 50
#define TAG_BUTTON_FULLSCREEN 1
#define TAG_BUTTON_SEEK_BACKWARD 2
#define TAG_BUTTON_PLAY_PAUSE 3
#define TAG_BUTTON_SEEK_FORWARD 4
#define TAG_BUTTON_PREVIOUS 5
#define TAG_BUTTON_STOP 6
#define TAG_BUTTON_NEXT 8
#define TAG_BUTTON_HOME 9
#define TAG_BUTTON_ARROW_UP 10
#define TAG_BUTTON_INFO 11
#define TAG_BUTTON_ARROW_LEFT 12
#define TAG_BUTTON_SELECT 13
#define TAG_BUTTON_ARROW_RIGHT 14
#define TAG_BUTTON_MENU 15
#define TAG_BUTTON_ARROW_DOWN 16
#define TAG_BUTTON_BACK 18
#define TAG_BUTTON_SUBTITLES 19
#define TAG_BUTTON_AUDIOSTREAMS 20
#define TAG_BUTTON_MUSIC 21
#define TAG_BUTTON_MOVIES 22
#define TAG_BUTTON_TVSHOWS 23
#define TAG_BUTTON_PICTURES 24
#define WINDOW_FULLSCREEN_VIDEO 12005
#define WINDOW_VISUALISATION 12006

@interface RemoteController ()

@end

@implementation RemoteController

@synthesize holdVolumeTimer;
@synthesize panFallbackImageView;

- (void)setupGestureView {
    NSArray *GestureDirections = @[@(UISwipeGestureRecognizerDirectionLeft),
                                   @(UISwipeGestureRecognizerDirectionRight),
                                   @(UISwipeGestureRecognizerDirectionUp),
                                   @(UISwipeGestureRecognizerDirectionDown)];
    for (NSNumber *direction in GestureDirections) {
        UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
        gesture.numberOfTouchesRequired = 1;
        gesture.cancelsTouchesInView = NO;
        gesture.direction = direction.intValue;
        [gestureZoneView addGestureRecognizer:gesture];
    }
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouchpadLongPress:)];
    longPress.cancelsTouchesInView = YES;
    [gestureZoneView addGestureRecognizer:longPress];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouchpadDoubleTap)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.cancelsTouchesInView = YES;
    [gestureZoneView addGestureRecognizer:doubleTap];
        
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouchpadSingleTap)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.cancelsTouchesInView = YES;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [gestureZoneView addGestureRecognizer:singleTap];
    
    UIRotationGestureRecognizer *rotation = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotate:)];
    [gestureZoneView addGestureRecognizer:rotation];
    
    UITapGestureRecognizer *twoFingersTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingersTap)];
    twoFingersTap.numberOfTapsRequired = 1;
    twoFingersTap.numberOfTouchesRequired = 2;
    [gestureZoneView addGestureRecognizer:twoFingersTap];
    
    gestureImage = [UIImage imageNamed:@"finger"];
    if (!isGestureViewActive) {
        return;
    }
    
    gestureImage = [UIImage imageNamed:@"circle"];
    CGRect frame = gestureZoneView.frame;
    frame.origin.x = 0;
    gestureZoneView.frame = frame;
    
    frame = buttonZoneView.frame;
    frame.origin.x = self.view.frame.size.width;
    buttonZoneView.frame = frame;
    
    gestureZoneView.alpha = 1;
    buttonZoneView.alpha = 0;
}

- (void)moveButton:(NSArray*)buttonsToDo ypos:(int)y {
    for (UIButton *button in buttonsToDo) {
        button.frame = CGRectMake(button.frame.origin.x, button.frame.origin.y + y, button.frame.size.width, button.frame.size.height);
    }
}

- (void)hideButton:(NSArray*)buttonsToDo hide:(BOOL)hide {
    for (UIButton *button in buttonsToDo) {
        button.hidden = hide;
    }
}

- (CGFloat)getOriginYForRemote:(CGFloat)offsetBottomMode {
    CGFloat yOrigin = 0;
    topRemoteOffset = 0;
    if (positionMode == remoteBottom && [Utilities hasRemoteToolBar]) {
        yOrigin = offsetBottomMode;
        remoteControlView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    }
    else {
        remoteControlView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    }
    return yOrigin;
}

- (void)setEmbeddedView {
    CGRect frame = TransitionalView.frame;
    CGFloat newWidth = GET_MAINSCREEN_WIDTH - ANCHOR_RIGHT_PEEK;
    CGFloat shift;
    [self hideButton:@[buttonSeekBackward,
                       buttonPlayPause,
                       buttonSeekForward,
                       buttonPrevious,
                       buttonNext]
                hide:YES];
    if ([Utilities hasRemoteToolBar]) {
        shift = CGRectGetMinY(TransitionalView.frame) - CGRectGetMinY(buttonNext.frame);
        [self moveButton:@[buttonMusic,
                           buttonMovies,
                           buttonTVShows,
                           buttonPictures]
                    ypos: -shift];
    }
    else {
        shift = CGRectGetMinY(TransitionalView.frame) - CGRectGetMinY(buttonStop.frame);
        [self hideButton:@[buttonMusic,
                           buttonMovies,
                           buttonTVShows,
                           buttonPictures]
                    hide: YES];
    }
    
    // Place the transitional view in the middle between the two button rows
    CGFloat lowerButtonUpperBorder = CGRectGetMinY(buttonMusic.frame);
    CGFloat upperButtonLowerBorder = CGRectGetMaxY(buttonStop.frame);
    CGFloat transViewY = (lowerButtonUpperBorder + upperButtonLowerBorder - TransitionalView.frame.size.height) / 2;
    TransitionalView.frame = CGRectMake(frame.origin.x, transViewY, frame.size.width, frame.size.height);
    
    // Maintain aspect ratio
    CGFloat transform = newWidth / remoteControlView.frame.size.width;
    CGFloat newHeight = remoteControlView.frame.size.height * transform;
    CGFloat toolbarPadding = [Utilities getBottomPadding];
    CGFloat offset = [self getOriginYForRemote:shift * transform - newHeight + TOOLBAR_PARENT_HEIGHT - TOOLBAR_HEIGHT - toolbarPadding];
    remoteControlView.frame = CGRectMake(0, offset, newWidth, newHeight);
    embeddedShift = shift * transform;
    
    frame = remoteControlView.frame;
    frame.origin.y = 0;
    frame.size.height -= shift;
    quickHelpView.frame = frame;
    
    [self setupGestureView];
    if ([Utilities hasRemoteToolBar]) {
        [self createRemoteToolbar:gestureImage width:newWidth xMin:ANCHOR_RIGHT_PEEK yMax:TOOLBAR_PARENT_HEIGHT isEmbedded:YES];
    }
    else {
        // Overload "stop" button with gesture icon in case the toolbar cannot be displayed (e.g. iPhone 4S)
        UIButton *gestureButton = buttonStop;
        gestureButton.contentMode = UIViewContentModeScaleAspectFit;
        gestureButton.showsTouchWhenHighlighted = NO;
        [gestureButton setImage:gestureImage forState:UIControlStateNormal];
        [gestureButton setImage:gestureImage forState:UIControlStateHighlighted];
        [gestureButton setBackgroundImage:[UIImage imageNamed:@"remote_button_blank_up"] forState:UIControlStateNormal];
        [gestureButton setBackgroundImage:[UIImage imageNamed:@"remote_button_blank_down"] forState:UIControlStateHighlighted];
        gestureButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [gestureButton addTarget:self action:@selector(toggleGestureZone:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)configureView {
    self.navigationItem.title = LOCALIZED_STR(@"Remote Control");
    CGFloat toolbarPadding = TOOLBAR_HEIGHT;
    if (![Utilities hasRemoteToolBar]) {
        toolbarPadding = 0;
    }
    if (IS_IPHONE) {
        VolumeSliderView *volumeSliderView = nil;
        CGFloat transform = [Utilities getTransformX];
        CGRect frame = remoteControlView.frame;
        toolbarPadding += [Utilities getBottomPadding];
        frame.size.height *= transform;
        frame.size.width *= transform;
        frame.origin.y = [self getOriginYForRemote:remoteControlView.frame.size.height - frame.size.height - toolbarPadding];
        
        if ([Utilities hasRemoteToolBar]) {
            volumeSliderView = [[VolumeSliderView alloc] initWithFrame:CGRectZero leftAnchor:0.0 isSliderType:YES];
            [volumeSliderView startTimer];
            [self.view addSubview:volumeSliderView];
            if (frame.origin.y == 0) {
                frame.origin.y = volumeSliderView.frame.size.height;
            }
            topRemoteOffset = volumeSliderView.frame.size.height;
        }
        remoteControlView.frame = frame;
        
        frame.origin.y = 0;
        quickHelpView.frame = frame;
    }
    else {
        VolumeSliderView *volumeSliderView = [[VolumeSliderView alloc] initWithFrame:CGRectZero leftAnchor:0.0 isSliderType:YES];
        [volumeSliderView startTimer];
        [self.view addSubview:volumeSliderView];
        
        // Used to avoid drawing remote buttons into the safe area
        CGFloat bottomPadding = [Utilities getBottomPadding];
        // Calculate the maximum possible scaling for the remote
        CGFloat scaleFactorHorizontal = PAD_REMOTE_WIDTH / CGRectGetWidth(remoteControlView.frame);
        CGFloat minViewHeight = MIN(GET_MAINSCREEN_WIDTH, GET_MAINSCREEN_HEIGHT) - REMOTE_PADDING - bottomPadding - CGRectGetMaxY(volumeSliderView.frame);
        CGFloat scaleFactorVertical = minViewHeight / CGRectGetHeight(remoteControlView.frame);
        CGFloat transform = MIN(scaleFactorHorizontal, scaleFactorVertical);

        CGRect frame = remoteControlView.frame;
        frame.size.height *= transform;
        frame.size.width *= transform;
        frame.origin.x = 0;
        frame.origin.y = [self getOriginYForRemote:remoteControlView.frame.size.height - frame.size.height - toolbarPadding];
        if (frame.origin.y == 0) {
            frame.origin.y = CGRectGetMaxY(volumeSliderView.frame);
        }
        remoteControlView.frame = frame;
        
        frame.origin = CGPointZero;
        quickHelpView.frame = frame;
        
        frame = remoteControlView.frame;
        frame.size.height += TOOLBAR_HEIGHT + CGRectGetMaxY(volumeSliderView.frame);
        self.view.frame = frame;
    }
    [self setupGestureView];
    if ([Utilities hasRemoteToolBar]) {
        [self createRemoteToolbar:gestureImage width:remoteControlView.frame.size.width xMin:0 yMax:self.view.bounds.size.height isEmbedded:NO];
    }
}

- (id)initWithNibName:(NSString*)nibNameOrNil withEmbedded:(BOOL)withEmbedded bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    isEmbeddedMode = withEmbedded;
    return self;
}

#pragma mark - Touch

- (void)handleSwipeFrom:(UISwipeGestureRecognizer*)recognizer {
    if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        buttonAction = TAG_BUTTON_ARROW_RIGHT;
        [self sendAction];
    }
    else if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        buttonAction = TAG_BUTTON_ARROW_LEFT;
        [self sendAction];
    }
    else if (recognizer.direction == UISwipeGestureRecognizerDirectionUp) {
        buttonAction = TAG_BUTTON_ARROW_UP;
        [self sendAction];
    }
    else if (recognizer.direction == UISwipeGestureRecognizerDirectionDown) {
        buttonAction = TAG_BUTTON_ARROW_DOWN;
        [self sendAction];
    }
}

- (void)handleTouchpadDoubleTap {
    buttonAction = TAG_BUTTON_BACK;
    [self sendAction];
}

- (void)handleTouchpadSingleTap {
    buttonAction = TAG_BUTTON_SELECT;
    [self sendAction];
}

- (void)twoFingersTap {
    [self GUIAction:@"Input.Home" params:[NSDictionary dictionary] httpAPIcallback:nil];
}

- (void)handleTouchpadLongPress:(UILongPressGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [[Utilities getJsonRPC]
         callMethod:@"XBMC.GetInfoBooleans" 
         withParameters:@{@"booleans": @[@"Window.IsActive(fullscreenvideo)",
                                         @"Window.IsActive(visualisation)",
                                         @"Window.IsActive(slideshow)"]}
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
             
             if (error == nil && methodError == nil && [methodResult isKindOfClass: [NSDictionary class]]) {
                 NSNumber *fullscreenActive = 0;
                 NSNumber *visualisationActive = 0;
                 NSNumber *slideshowActive = 0;

                 if (methodResult[@"Window.IsActive(fullscreenvideo)"] != [NSNull null]) {
                     fullscreenActive = methodResult[@"Window.IsActive(fullscreenvideo)"];
                 }
                 if (methodResult[@"Window.IsActive(visualisation)"] != [NSNull null]) {
                     visualisationActive = methodResult[@"Window.IsActive(visualisation)"];
                 }
                 if (methodResult[@"Window.IsActive(slideshow)"] != [NSNull null]) {
                     slideshowActive = methodResult[@"Window.IsActive(slideshow)"];
                 }
                 if ([fullscreenActive intValue] == 1 || [visualisationActive intValue] == 1 || [slideshowActive intValue] == 1) {
                     buttonAction = TAG_BUTTON_MENU;
                     [self sendActionNoRepeat];
                 }
                 else {
                     [self GUIAction:@"Input.ContextMenu" params:[NSDictionary dictionary] httpAPIcallback:@"SendKey(0xF043)"];
                 }
             }
             else {
                 [self GUIAction:@"Input.ContextMenu" params:[NSDictionary dictionary] httpAPIcallback:@"SendKey(0xF043)"];
             }
         }];
    }
}


- (void)handleRotate:(id)sender {
    if ([(UIRotationGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
        [self volumeInfo];
    }
	else if ([(UIRotationGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
		lastRotation = 0.0;
		return;
	}
	CGFloat rotation = 0.0 - (lastRotation - [(UIRotationGestureRecognizer*)sender rotation]);
    
    if (rotation > ROTATION_TRIGGER && audioVolume < 100) {
        audioVolume += 1;
    }
    else if (rotation < -ROTATION_TRIGGER && audioVolume > 0) {
        audioVolume -= 1;
    }
    [self changeServerVolume];
	lastRotation = [(UIRotationGestureRecognizer*)sender rotation];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    [self stopHoldKey:nil];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
    [self stopHoldKey:nil];
}
        
# pragma mark - view Effects

- (void)showSubInfo:(NSString*)message timeout:(NSTimeInterval)timeout color:(UIColor*)color {
    [messagesView showMessage:message timeout:timeout color:color];
}

# pragma mark - ToolBar

- (void)toggleGestureZone:(id)sender {
    NSString *imageName = @"blank";
    BOOL showGesture = !isGestureViewActive;
    if ([sender isKindOfClass:[NSNotification class]]) {
        if ([[sender userInfo] isKindOfClass:[NSDictionary class]]) {
            showGesture = [[[sender userInfo] objectForKey:@"forceGestureZone"] boolValue];
        }
    }
    if (showGesture && gestureZoneView.alpha == 1) {
        return;
    }
    if (showGesture) {
        isGestureViewActive = YES;
        CGRect frame;
        frame = gestureZoneView.frame;
        frame.origin.x = -self.view.frame.size.width;
        gestureZoneView.frame = frame;
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            CGRect frame = gestureZoneView.frame;
            frame.origin.x = 0;
            gestureZoneView.frame = frame;
            
            frame = buttonZoneView.frame;
            frame.origin.x = self.view.frame.size.width;
            buttonZoneView.frame = frame;
            
            gestureZoneView.alpha = 1;
            buttonZoneView.alpha = 0;
                         }
                         completion:^(BOOL finished) {}];
        imageName = @"circle";
    }
    else {
        isGestureViewActive = NO;
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            CGRect frame;
            frame = gestureZoneView.frame;
            frame.origin.x = -self.view.frame.size.width;
            gestureZoneView.frame = frame;
            
            frame = buttonZoneView.frame;
            frame.origin.x = 0;
            buttonZoneView.frame = frame;
            
            gestureZoneView.alpha = 0;
            buttonZoneView.alpha = 1;
                         }
                         completion:^(BOOL finished) {}];
        imageName = @"finger";
    }
    if ([sender isKindOfClass: [UIButton class]]) {
        [sender setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:imageName] forState:UIControlStateHighlighted];

    }
    else if ([sender isKindOfClass: [UIBarButtonItem class]]) {
        [sender setImage:[UIImage imageNamed:imageName]];
    }
    [self saveRemoteMode];
}

# pragma mark - JSON

/* method to show an action sheet for subs. */

- (void)subtitlesActionSheet {
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionary] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil) {
            if ([methodResult count] > 0) {
                NSNumber *response;
                if (methodResult[0][@"playerid"] != [NSNull null]) {
                    response = methodResult[0][@"playerid"];
                }
                [[Utilities getJsonRPC]
                 callMethod:@"Player.GetProperties"
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                 response, @"playerid",
                                 @[@"subtitleenabled", @"currentsubtitle", @"subtitles"], @"properties",
                                 nil]
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                     if (error == nil && methodError == nil) {
                         if ([NSJSONSerialization isValidJSONObject:methodResult]) {
                             if ([methodResult count]) {
                                 NSDictionary *currentSubtitle = methodResult[@"currentsubtitle"];
                                 BOOL subtitleEnabled = [methodResult[@"subtitleenabled"] boolValue];
                                 NSArray *subtitles = methodResult[@"subtitles"];
                                 if (subtitles.count) {
                                     subsDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                       currentSubtitle, @"currentsubtitle",
                                                       @(subtitleEnabled), @"subtitleenabled",
                                                       subtitles, @"subtitles",
                                                       nil];
                                     NSInteger numSubs = subtitles.count;
                                     NSMutableArray *actionSheetTitles = [NSMutableArray array];
                                     for (int i = 0; i < numSubs; i++) {
                                         NSString *language = @"?";
                                         if ((NSNull*)subtitles[i][@"language"] != [NSNull null]) {
                                             NSLocale *currentLocale = [NSLocale currentLocale];
                                             NSString *canonicalID = [NSLocale canonicalLanguageIdentifierFromString:subtitles[i][@"language"]];
                                             NSString *displayNameString = [currentLocale displayNameForKey:NSLocaleIdentifier value:canonicalID];
                                             if (displayNameString.length > 0) {
                                                 language = displayNameString;
                                             }
                                             else {
                                                 language = subtitles[i][@"language"];
                                             }
                                             if (language.length == 0) {
                                                 language = LOCALIZED_STR(@"Unknown");
                                             }
                                         }
                                         NSString *tickMark = @"";
                                         if (subtitleEnabled && [currentSubtitle isEqual:subtitles[i]]) {
                                             tickMark = @"\u2713 ";
                                         }
                                         NSString *title = [NSString stringWithFormat:@"%@%@%@%@ (%d/%ld)", tickMark, language, [subtitles[i][@"name"] isEqual:@""] ? @"" : @" - ", subtitles[i][@"name"], i + 1, (long)numSubs];
                                         [actionSheetTitles addObject:title];
                                     }
                                     [self showActionSubtitles:actionSheetTitles];
                                 }
                                 else {
                                     [self showSubInfo:LOCALIZED_STR(@"Subtitles not available") timeout:2.0 color:[Utilities getSystemRed:0.95]];
                                 }
                             }
                         }
                     }
                 }];
            }
            else {
                [self showSubInfo:LOCALIZED_STR(@"Subtitles not available") timeout:2.0 color:[Utilities getSystemRed:0.95]];
            }
        }
    }];
}

- (void)audioStreamActionSheet {
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionary] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil) {
            if ([methodResult count] > 0) {
                NSNumber *response;
                if (methodResult[0][@"playerid"] != [NSNull null]) {
                    response = methodResult[0][@"playerid"];
                }
                [[Utilities getJsonRPC]
                 callMethod:@"Player.GetProperties"
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                 response, @"playerid",
                                 @[@"currentaudiostream", @"audiostreams"], @"properties",
                                 nil]
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                     if (error == nil && methodError == nil) {
                         if ([NSJSONSerialization isValidJSONObject:methodResult]) {
                             if ([methodResult count]) {
                                 NSDictionary *currentAudiostream = methodResult[@"currentaudiostream"];
                                 NSArray *audiostreams = methodResult[@"audiostreams"];
                                 if (audiostreams.count) {
                                     audiostreamsDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                       currentAudiostream, @"currentaudiostream",
                                                       audiostreams, @"audiostreams",
                                                       nil];
                                     NSInteger numAudio = audiostreams.count;
                                     NSMutableArray *actionSheetTitles = [NSMutableArray array];
                                     for (int i = 0; i < numAudio; i++) {
                                         NSString *language = @"?";
                                         if ((NSNull*)audiostreams[i][@"language"] != [NSNull null]) {
                                             NSLocale *currentLocale = [NSLocale currentLocale];
                                             NSString *canonicalID = [NSLocale canonicalLanguageIdentifierFromString:audiostreams[i][@"language"]];
                                             NSString *displayNameString = [currentLocale displayNameForKey:NSLocaleIdentifier value:canonicalID];
                                             if (displayNameString.length > 0) {
                                                 language = displayNameString;
                                             }
                                             else {
                                                 language = audiostreams[i][@"language"];
                                             }
                                             if (language.length == 0) {
                                                 language = LOCALIZED_STR(@"Unknown");
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
                                     [self showSubInfo:LOCALIZED_STR(@"Audiostreams not available") timeout:2.0 color:[Utilities getSystemRed:0.95]];
                                 }
                             }
                        }
                     }
                 }];
            }
            else {
                [self showSubInfo:LOCALIZED_STR(@"Audiostream not available") timeout:2.0 color:[Utilities getSystemRed:0.95]];
            }
        }
    }];
}

- (void)playbackAction:(NSString*)action params:(NSDictionary*)parameters {
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionary] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil) {
            if ([methodResult count] > 0) {
                NSMutableDictionary *commonParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
                NSNumber *response = methodResult[0][@"playerid"];
                if (response != nil) {
                    commonParams[@"playerid"] = response;
                }
                [[Utilities getJsonRPC] callMethod:action withParameters:commonParams onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                }];
            }
        }
    }];
}

- (void)GUIAction:(NSString*)action params:(NSDictionary*)params httpAPIcallback:(NSString*)callback {
    [[Utilities getJsonRPC] callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
//        NSLog(@"Action %@ ok with %@ ", action, methodResult);
//        if (methodError != nil || error != nil) {
//            NSLog(@"method error %@ %@", methodError, error);
//        }
        if ((methodError != nil || error != nil) && callback != nil) { // Backward compatibility
            [Utilities sendXbmcHttp:callback];
        }
    }];
}

- (void)volumeInfo {
    if (AppDelegate.instance.serverVolume > -1) {
        audioVolume = AppDelegate.instance.serverVolume;
    }
    else {
        audioVolume = 0;
    }

//    [[Utilities getJsonRPC]
//     callMethod:@"Application.GetProperties" 
//     withParameters:@{"properties": @[@"volume"]}
//     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
//         if (error == nil && methodError == nil) {
//             if ([NSJSONSerialization isValidJSONObject:methodResult] && [methodResult count]) {
//                 audioVolume = [methodResult[@"volume"] intValue];
//             }
//         }
//     }];
}

- (void)changeServerVolume {
    [[Utilities getJsonRPC]
     callMethod:@"Application.SetVolume" 
     withParameters:@{@"volume": @(audioVolume)}];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    if (IS_IPAD) {
        // Disable gestures to move the modal remote as this would conflict with the gesture zone
        [self.presentationController.presentedView.gestureRecognizers.firstObject setEnabled:NO];
    }
    if (touches.count == 1) {
        NSTimeInterval timeInterval = 1.5;
        if (buttonAction > 0) {
            timeInterval = 0.5;
        }
        self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(sendAction) userInfo:nil repeats:YES];
    }
}

#pragma mark - Action Sheet Method

- (void)showActionAudiostreams:(NSMutableArray*)sheetActions {
    NSInteger numActions = sheetActions.count;
    if (numActions) {
        UIAlertController *actionView = [UIAlertController alertControllerWithTitle:LOCALIZED_STR(@"Audio stream") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *action_cancel = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
        
        for (int i = 0; i < numActions; i++) {
            NSString *actiontitle = sheetActions[i];
            UIAlertAction *action = [UIAlertAction actionWithTitle:actiontitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                if (audiostreamsDictionary[@"audiostreams"]) {
                    if (audiostreamsDictionary[@"audiostreams"][i]) {
                        if (![audiostreamsDictionary[@"audiostreams"][i] isEqual:audiostreamsDictionary[@"currentaudiostream"]]) {
                            id audiostreamIndex = audiostreamsDictionary[@"audiostreams"][i][@"index"];
                            if (audiostreamIndex) {
                                [self playbackAction:@"Player.SetAudioStream" params:@{@"stream": audiostreamIndex}];
                                [self showSubInfo:actiontitle timeout:2.0 color:[Utilities getSystemGreen:0.95]];
                            }
                        }
                    }
                }
            }];
            [actionView addAction:action];
        }
        [actionView addAction:action_cancel];
        actionView.modalPresentationStyle = UIModalPresentationPopover;
        
        UIPopoverPresentationController *popPresenter = [actionView popoverPresentationController];
        if (popPresenter != nil) {
            popPresenter.sourceView = remoteControlView;
            popPresenter.sourceRect = buttonAudiostreams.frame;
        }
        [self presentViewController:actionView animated:YES completion:nil];
    }
}

- (void)showActionSubtitles:(NSMutableArray*)sheetActions {
    NSInteger numActions = sheetActions.count;
    if (numActions) {
        UIAlertController *actionView = [UIAlertController alertControllerWithTitle:LOCALIZED_STR(@"Subtitles") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *action_cancel = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];

        UIAlertAction *action_disable = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Disable subtitles") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [self showSubInfo:LOCALIZED_STR(@"Subtitles disabled") timeout:2.0 color:[Utilities getSystemGreen:0.95]];
            [self playbackAction:@"Player.SetSubtitle" params:@{@"subtitle": @"off"}];
        }];
        if ([subsDictionary[@"subtitleenabled"] boolValue]) {
            [actionView addAction:action_disable];
        }
        
        for (int i = 0; i < numActions; i++) {
            NSString *actiontitle = sheetActions[i];
            UIAlertAction *action = [UIAlertAction actionWithTitle:actiontitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                if (subsDictionary[@"subtitles"]) {
                    if (subsDictionary[@"subtitles"][i]) {
                        if (![subsDictionary[@"subtitles"][i] isEqual:subsDictionary[@"currentsubtitle"]] ||
                            ![subsDictionary[@"subtitleenabled"] boolValue]) {
                            id subsIndex = subsDictionary[@"subtitles"][i][@"index"];
                            if (subsIndex) {
                                [self playbackAction:@"Player.SetSubtitle" params:@{@"subtitle": subsIndex}];
                                [self playbackAction:@"Player.SetSubtitle" params:@{@"subtitle": @"on"}];
                                [self showSubInfo:actiontitle timeout:2.0 color:[Utilities getSystemGreen:0.95]];
                            }
                        }
                    }
                }
            }];
            [actionView addAction:action];
        }
        [actionView addAction:action_cancel];
        actionView.modalPresentationStyle = UIModalPresentationPopover;
        
        UIPopoverPresentationController *popPresenter = [actionView popoverPresentationController];
        if (popPresenter != nil) {
            popPresenter.sourceView = remoteControlView;
            popPresenter.sourceRect = buttonSubtitles.frame;
        }
        [self presentViewController:actionView animated:YES completion:nil];
    }
}

#pragma mark - Buttons

NSInteger buttonAction;

- (IBAction)holdKey:(id)sender {
    buttonAction = [sender tag];
    [self sendAction];
    [self.holdVolumeTimer invalidate];
    self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(sendAction) userInfo:nil repeats:YES];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    BOOL startVibrate = [userDefaults boolForKey:@"vibrate_preference"];
    if (startVibrate) {
        [[UIDevice currentDevice] playInputClick];
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

- (IBAction)stopHoldKey:(id)sender {
    [self.holdVolumeTimer invalidate];
    buttonAction = 0;
}

- (void)sendActionNoRepeat {
//    NSString *action;
    switch (buttonAction) {
        case TAG_BUTTON_MENU: // MENU OSD
            [self GUIAction:@"Input.ShowOSD" params:[NSDictionary dictionary] httpAPIcallback:@"SendKey(0xF04D)"];
            break;
        default:
            break;
    }
}

- (void)playerStep:(NSString*)step musicPlayerGo:(NSString*)musicAction musicPlayerAction:(NSString*)musicMethod {
    if (AppDelegate.instance.serverVersion > 11) {
        [[Utilities getJsonRPC]
         callMethod:@"GUI.GetProperties"
         withParameters:@{@"properties": @[@"currentwindow",
                                           @"fullscreen"]}
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
             if (error == nil && methodError == nil && [methodResult isKindOfClass: [NSDictionary class]]) {
                 long winID = 0;
                 BOOL isFullscreen = NO;
                 if (methodResult[@"fullscreen"] != [NSNull null]) {
                     isFullscreen = [methodResult[@"fullscreen"] boolValue];
                 }
                 if (methodResult[@"currentwindow"] != [NSNull null]) {
                     winID = [methodResult[@"currentwindow"][@"id"] longValue];
                 }
                 if (isFullscreen && (winID == WINDOW_FULLSCREEN_VIDEO || winID == WINDOW_VISUALISATION)) {
                     [[Utilities getJsonRPC]
                      callMethod:@"XBMC.GetInfoBooleans"
                      withParameters:@{@"booleans": @[@"VideoPlayer.HasMenu",
                                                      @"Pvr.IsPlayingTv"]}
                      onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                          if (error == nil && methodError == nil && [methodResult isKindOfClass: [NSDictionary class]]) {
                              BOOL VideoPlayerHasMenu = NO;
                              BOOL PvrIsPlayingTv = NO;
                              if (methodResult[@"VideoPlayer.HasMenu"] != [NSNull null]) {
                                  VideoPlayerHasMenu = [methodResult[@"VideoPlayer.HasMenu"] boolValue];
                              }
                              if (methodResult[@"Pvr.IsPlayingTv"] != [NSNull null]) {
                                  PvrIsPlayingTv = [methodResult[@"Pvr.IsPlayingTv"] boolValue];
                              }
                              if (winID == WINDOW_FULLSCREEN_VIDEO && !PvrIsPlayingTv && !VideoPlayerHasMenu) {
                                  [self playbackAction:@"Player.Seek" params:[Utilities buildPlayerSeekStepParams:step]];
                              }
                              else if (winID == WINDOW_VISUALISATION && musicAction != nil) {
                                  [self playbackAction:@"Player.GoTo" params:@{@"to": musicAction}];
                              }
                              else if (winID == WINDOW_VISUALISATION && musicMethod != nil) {
                                  [self GUIAction:@"Input.ExecuteAction" params:@{@"action": musicMethod} httpAPIcallback:nil];
                              }
                          }
                      }];
                 }
             }
         }];
    }
    return;
}

- (void)sendAction {
    if (!buttonAction) {
        return;
    }
    if (self.holdVolumeTimer.timeInterval == 0.5 || self.holdVolumeTimer.timeInterval == 1.5) {
        
        if (self.holdVolumeTimer.timeInterval == 1.5) {
            [self.holdVolumeTimer invalidate];
            self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(sendAction) userInfo:nil repeats:YES];
        }
        else {
            [self.holdVolumeTimer invalidate];
            self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(sendAction) userInfo:nil repeats:YES];
        }
    }
    NSString *action;
    switch (buttonAction) {
        case TAG_BUTTON_ARROW_UP:
            action = @"Input.Up";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:nil];
            [self playerStep:@"bigforward" musicPlayerGo:nil musicPlayerAction:@"increaserating"];
            break;
            
        case TAG_BUTTON_ARROW_LEFT:
            action = @"Input.Left";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:nil];
            [self playerStep:@"smallbackward" musicPlayerGo:@"previous" musicPlayerAction:nil];
            break;

        case TAG_BUTTON_SELECT:
            action = @"Input.Select";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
            break;

        case TAG_BUTTON_ARROW_RIGHT:
            action = @"Input.Right";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:nil];
            [self playerStep:@"smallforward" musicPlayerGo:@"next" musicPlayerAction:nil];
            break;
            
        case TAG_BUTTON_ARROW_DOWN:
            action = @"Input.Down";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:nil];
            [self playerStep:@"bigbackward" musicPlayerGo:nil musicPlayerAction:@"decreaserating"];
            break;
            
        case TAG_BUTTON_BACK:
            action = @"Input.Back";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:nil];
            break;
            
        default:
            break;
    }
}

- (IBAction)startVibrate:(id)sender {
    NSString *action;
    NSDictionary *params;
    NSDictionary *dicParams;
    switch ([sender tag]) {
        case TAG_BUTTON_FULLSCREEN:
            action = @"GUI.SetFullscreen";
            [self GUIAction:action params:@{@"fullscreen": @"toggle"} httpAPIcallback:@"SendKey(0xf009)"];
            break;
            
        case TAG_BUTTON_SEEK_BACKWARD:
            action = @"Player.Seek";
            params = [Utilities buildPlayerSeekStepParams:@"smallbackward"];
            [self playbackAction:action params:params];
            break;
            
        case TAG_BUTTON_PLAY_PAUSE:
            action = @"Player.PlayPause";
            params = nil;
            [self playbackAction:action params:nil];
            break;
            
        case TAG_BUTTON_SEEK_FORWARD:
            action = @"Player.Seek";
            params = [Utilities buildPlayerSeekStepParams:@"smallforward"];
            [self playbackAction:action params:params];
            break;
            
        case TAG_BUTTON_PREVIOUS:
            if (AppDelegate.instance.serverVersion > 11) {
                action = @"Player.GoTo";
                params = @{@"to": @"previous"};
                [self playbackAction:action params:params];
            }
            else {
                action = @"Player.GoPrevious";
                params = nil;
                [self playbackAction:action params:nil];
            }
            break;
            
        case TAG_BUTTON_STOP:
            action = @"Player.Stop";
            params = nil;
            [self playbackAction:action params:nil];
            break;
            
        case TAG_BUTTON_NEXT:
            if (AppDelegate.instance.serverVersion > 11) {
                action = @"Player.GoTo";
                params = @{@"to": @"next"};
                [self playbackAction:action params:params];
            }
            else {
                action = @"Player.GoNext";
                params = nil;
                [self playbackAction:action params:nil];
            }
            break;
        
        case TAG_BUTTON_HOME: // HOME
            action = @"Input.Home";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:nil];
            break;
            
        case TAG_BUTTON_INFO: // INFO
            action = @"Input.Info";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:@"SendKey(0xF049)"];
            break;
            
        case TAG_BUTTON_SELECT:
            action = @"Input.Select";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
            break;
            
        case TAG_BUTTON_MENU: // MENU OSD
            action = @"Input.ShowOSD";
            [self GUIAction:action params:[NSDictionary dictionary] httpAPIcallback:@"SendKey(0xF04D)"];
            break;
        
        case TAG_BUTTON_SUBTITLES:
            [self subtitlesActionSheet];
            break;
            
        case TAG_BUTTON_AUDIOSTREAMS:
            [self audioStreamActionSheet];
            break;
            
        case TAG_BUTTON_MUSIC:
            action = @"GUI.ActivateWindow";
            dicParams = @{@"window": @"music"};
            [self GUIAction:action params:dicParams httpAPIcallback:@"ExecBuiltIn&parameter=ActivateWindow(Music)"];
            break;
            
        case TAG_BUTTON_MOVIES:
            action = @"GUI.ActivateWindow";
            dicParams = @{@"window": @"videos",
                          @"parameters": @[@"MovieTitles"]};
            [self GUIAction:action params:dicParams httpAPIcallback:@"ExecBuiltIn&parameter=ActivateWindow(Videos,MovieTitles)"];
            break;
        
        case TAG_BUTTON_TVSHOWS:
            action = @"GUI.ActivateWindow";
            dicParams = @{@"window": @"videos",
                          @"parameters": @[@"tvshowtitles"]};
            [self GUIAction:action params:dicParams httpAPIcallback:@"ExecBuiltIn&parameter=ActivateWindow(Videos,tvshowtitles)"];
            break;
        
        case TAG_BUTTON_PICTURES:
            action = @"GUI.ActivateWindow";
            dicParams = @{@"window": @"pictures"};
            [self GUIAction:action params:dicParams httpAPIcallback:@"ExecBuiltIn&parameter=ActivateWindow(Pictures)"];
            break;
            
        default:
            break;
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    BOOL startVibrate = [userDefaults boolForKey:@"vibrate_preference"];
    if (startVibrate) {
        [[UIDevice currentDevice] playInputClick];
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
}

#pragma mark - GestureRecognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch {
    // Do not support any pan gestures, if the Remote's GestureZone was touched
    if ([touch.view isKindOfClass:[RemoteControllerGestureZoneView class]]) {
        return NO;
    }
    return YES;
}

# pragma mark - Gestures

- (IBAction)handleButtonLongPress:(UILongPressGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        switch (gestureRecognizer.view.tag) {
            case TAG_BUTTON_FULLSCREEN:
                [self GUIAction:@"Input.ExecuteAction" params:@{@"action": @"togglefullscreen"} httpAPIcallback:@"Action(199)"];
                break;
                
            case TAG_BUTTON_SEEK_BACKWARD: // DECREASE PLAYBACK SPEED
                [self playbackAction:@"Player.SetSpeed" params:@{@"speed": @"decrement"}];
                break;
                
            case TAG_BUTTON_SEEK_FORWARD: // INCREASE PLAYBACK SPEED
                [self playbackAction:@"Player.SetSpeed" params:@{@"speed": @"increment"}];
                break;
                
            case TAG_BUTTON_INFO: // CODEC INFO
                if (AppDelegate.instance.serverVersion > 16) {
                    [self GUIAction:@"Input.ExecuteAction" params:@{@"action": @"playerdebug"} httpAPIcallback:nil];
                }
                else {
                    [self GUIAction:@"Input.ShowCodec" params:[NSDictionary dictionary] httpAPIcallback:@"SendKey(0xF04F)"];
                }
                break;

            case TAG_BUTTON_SELECT: // CONTEXT MENU
            case TAG_BUTTON_MENU:
                [self GUIAction:@"Input.ContextMenu" params:[NSDictionary dictionary] httpAPIcallback:@"SendKey(0xF043)"];
                break;

            case TAG_BUTTON_SUBTITLES: // SUBTITLES BUTTON
                if (AppDelegate.instance.serverVersion > 12) {
                    [self GUIAction:@"GUI.ActivateWindow"
                             params:@{@"window": @"subtitlesearch"}
                    httpAPIcallback:nil];
                }
                else {
                    [self GUIAction:@"Addons.ExecuteAddon"
                             params:@{@"addonid": @"script.xbmc.subtitles"}
                    httpAPIcallback:@"ExecBuiltIn&parameter=RunScript(script.xbmc.subtitles)"];
                }
                break;
                
            case TAG_BUTTON_MOVIES:
                [self GUIAction:@"GUI.ActivateWindow"
                         params:@{@"window": @"pvr",
                                  @"parameters": @[@"31", @"0", @"10", @"0"]}
                httpAPIcallback:nil];
                break;
                
            case TAG_BUTTON_TVSHOWS:
                [self GUIAction:@"GUI.ActivateWindow"
                         params:@{@"window": @"pvrosdguide"}
                httpAPIcallback:nil];
                break;
                
            case TAG_BUTTON_PICTURES:
                [self GUIAction:@"GUI.ActivateWindow"
                         params:@{@"window": @"pvrosdchannels"}
                httpAPIcallback:nil];
                break;

            default:
                break;
        }
    }
}

#pragma mark - Quick Help

- (IBAction)toggleQuickHelp:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
    if (quickHelpView.alpha == 0) {
        [Utilities alphaView:quickHelpView AnimDuration:0.2 Alpha:1.0];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
    else {
        [Utilities alphaView:quickHelpView AnimDuration:0.2 Alpha:0.0];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}

#pragma mark - Keyboard methods

- (void)toggleVirtualKeyboard:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleVirtualKeyboard" object:nil userInfo:nil];
}

- (void)hideKeyboard:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
}

#pragma mark - Persistence

- (void)saveRemoteMode {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:isGestureViewActive forKey:@"GestureViewEnabled"];
    [userDefaults setInteger:positionMode forKey:@"RemotePosition"];
    return;
}

- (void)loadRemoteMode {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    isGestureViewActive = [userDefaults boolForKey:@"GestureViewEnabled"];
    positionMode = (RemotePositionType)[userDefaults integerForKey:@"RemotePosition"];
    return;
}

#pragma mark - Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (IS_IPHONE) {
        if (self.slidingViewController != nil) {
            [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
            self.slidingViewController.underRightViewController = nil;
            self.slidingViewController.anchorLeftPeekAmount   = 0;
            self.slidingViewController.anchorLeftRevealAmount = 0;
            self.slidingViewController.panGesture.delegate = self;
            // Allow panning gesture for full view (but gestureRecognizer will skip if GestureZone is touched)
            [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
        }
        RightMenuViewController *rightMenuViewController = [[RightMenuViewController alloc] initWithNibName:@"RightMenuViewController" bundle:nil];
        rightMenuViewController.rightMenuItems = AppDelegate.instance.remoteControlMenuItems;
        self.slidingViewController.underRightViewController = rightMenuViewController;
        UIImage *settingsImg = [UIImage imageNamed:@"default-right-menu-icon"];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:settingsImg style:UIBarButtonItemStylePlain target:self action:@selector(handleSettingsButton:)];
        self.navigationController.navigationBar.barTintColor = REMOTE_CONTROL_BAR_TINT_COLOR;
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
                                                 name: @"ECSlidingViewTopWillReset"
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
                                             selector: @selector(disablePopGestureRecognizer:)
                                                 name: @"ECSlidingViewUnderRightWillAppear"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(enablePopGestureRecognizer:)
                                                 name: @"ECSlidingViewTopDidReset"
                                               object: nil];
}

- (void)enablePopGestureRecognizer:(id)sender {
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void)disablePopGestureRecognizer:(id)sender {
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)revealUnderRight {
    [self.slidingViewController anchorTopViewTo:ECLeft];
}

- (void)resetRemote {
    [self stopHoldKey:nil];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resetRemote];
    self.slidingViewController.panGesture.delegate = nil;
}

- (void)turnTorchOn:(id)sender {
    torchIsOn = !torchIsOn;
    [Utilities turnTorchOn:sender on:torchIsOn];
}

- (void)dismissModal {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)toggleRemotePosition {
    positionMode = positionMode == remoteBottom ? remoteTop : remoteBottom;
    CGRect frame = remoteControlView.frame;
    if (positionMode == remoteBottom && [Utilities hasRemoteToolBar]) {
        frame.origin.y = CGRectGetMinY(remoteToolbar.frame) - CGRectGetHeight(remoteControlView.frame) + embeddedShift;
    }
    else {
        frame.origin.y = topRemoteOffset;
    }
    remoteControlView.frame = frame;
    remoteControlView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    [self saveRemoteMode];
}

- (void)createRemoteToolbar:(UIImage*)gestureButtonImg width:(CGFloat)width xMin:(CGFloat)xMin yMax:(CGFloat)yMax isEmbedded:(BOOL)isEmbedded {
    torchIsOn = [Utilities isTorchOn];
    // Non-embedded layout has 5 buttons (Settings > Gesture > Keyboard > Info > Torch with Flex around the buttons)
    // Embedded layout has 4 buttons (Gesture > Keyboard > Info > Torch with Flex around the buttons)
    // iPhone has an addtional button to toggle the remote's position is available
    // iPad has an additional button to close the modal view
    int numButtons = isEmbedded ? 5 : 6;
    CGFloat ToolbarFlexSpace = ((width - numButtons * TOOLBAR_ICON_SIZE) / (numButtons + 1));
    CGFloat ToolbarPadding = (TOOLBAR_ICON_SIZE + ToolbarFlexSpace);
    
    // Avoid drawing into safe area on iPhones
    if (IS_IPHONE) {
        yMax -= [Utilities getBottomPadding];
    }
    
    // Frame for remoteToolbarView placed at bottom - toolbar's height
    remoteToolbar = [[UIView alloc] initWithFrame:CGRectMake(0, yMax - TOOLBAR_HEIGHT, width, TOOLBAR_HEIGHT)];
    remoteToolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    
    // Frame for buttons in remoteToolbarView
    CGRect frame = CGRectMake(ToolbarFlexSpace, TOOLBAR_FIXED_OFFSET / 2, TOOLBAR_ICON_SIZE, TOOLBAR_ICON_SIZE);
    
    // Add buttons to toolbar
    frame.origin.x -= ToolbarPadding;
    if (!isEmbedded) {
        UIButton *settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        frame.origin.x += ToolbarPadding;
        settingButton.frame = frame;
        settingButton.showsTouchWhenHighlighted = YES;
        [settingButton setImage:[UIImage imageNamed:@"default-right-menu-icon"] forState:UIControlStateNormal];
        [settingButton addTarget:self action:@selector(handleSettingsButton:) forControlEvents:UIControlEventTouchUpInside];
        settingButton.alpha = 0.8;
        [remoteToolbar addSubview:settingButton];
    }
    
    UIButton *gestureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    frame.origin.x += ToolbarPadding;
    gestureButton.frame = frame;
    gestureButton.showsTouchWhenHighlighted = YES;
    [gestureButton setImage:gestureButtonImg forState:UIControlStateNormal];
    [gestureButton addTarget:self action:@selector(toggleGestureZone:) forControlEvents:UIControlEventTouchUpInside];
    gestureButton.alpha = 0.8;
    [remoteToolbar addSubview:gestureButton];
    
    UIButton *keyboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    frame.origin.x += ToolbarPadding;
    keyboardButton.frame = frame;
    keyboardButton.showsTouchWhenHighlighted = YES;
    [keyboardButton setImage:[UIImage imageNamed:@"keyboard_icon"] forState:UIControlStateNormal];
    [keyboardButton addTarget:self action:@selector(toggleVirtualKeyboard:) forControlEvents:UIControlEventTouchUpInside];
    keyboardButton.alpha = 0.8;
    [remoteToolbar addSubview:keyboardButton];

    UIButton *helpButton = [UIButton buttonWithType:UIButtonTypeCustom];
    frame.origin.x += ToolbarPadding;
    helpButton.frame = frame;
    helpButton.showsTouchWhenHighlighted = YES;
    [helpButton setImage:[UIImage imageNamed:@"button_info"] forState:UIControlStateNormal];
    [helpButton addTarget:self action:@selector(toggleQuickHelp:) forControlEvents:UIControlEventTouchUpInside];
    helpButton.alpha = 0.8;
    [remoteToolbar addSubview:helpButton];
    
    UIButton *torchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    frame.origin.x += ToolbarPadding;
    torchButton.frame = frame;
    torchButton.showsTouchWhenHighlighted = YES;
    [torchButton setImage:[UIImage imageNamed:torchIsOn ? @"torch_on" : @"torch"] forState:UIControlStateNormal];
    [torchButton addTarget:self action:@selector(turnTorchOn:) forControlEvents:UIControlEventTouchUpInside];
    torchButton.alpha = 0.8;
    [remoteToolbar addSubview:torchButton];
    
    if (IS_IPHONE) {
        positionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        frame.origin.x += ToolbarPadding;
        positionButton.frame = frame;
        positionButton.showsTouchWhenHighlighted = YES;
        [positionButton setImage:[UIImage imageNamed:@"icon_up_down"] forState:UIControlStateNormal];
        [positionButton addTarget:self action:@selector(toggleRemotePosition) forControlEvents:UIControlEventTouchUpInside];
        positionButton.alpha = 0.6;
        [remoteToolbar addSubview:positionButton];
    }
    else {
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        frame.origin.x += ToolbarPadding;
        closeButton.frame = frame;
        closeButton.showsTouchWhenHighlighted = YES;
        [closeButton setImage:[UIImage imageNamed:@"button_close"] forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(dismissModal) forControlEvents:UIControlEventTouchUpInside];
        closeButton.alpha = 0.6;
        [remoteToolbar addSubview:closeButton];
    }
    
    // Add toolbar to RemoteController's view
    [self.view addSubview:remoteToolbar];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    SDWebImageDownloader *manager = [SDWebImageManager sharedManager].imageDownloader;
    NSDictionary *httpHeaders = AppDelegate.instance.getServerHTTPHeaders;
    if (httpHeaders[@"Authorization"] != nil) {
        [manager setValue:httpHeaders[@"Authorization"] forHTTPHeaderField:@"Authorization"];
    }

    self.edgesForExtendedLayout = 0;
    self.view.tintColor = APP_TINT_COLOR;
    
    quickHelpImageView.image = [UIImage imageNamed:@"remote_quick_help"];
    [self loadRemoteMode];
    if (!isEmbeddedMode) {
        [self configureView];
    }
    else {
        [self setEmbeddedView];
    }
    
    [[SDImageCache sharedImageCache] clearMemory];
    gestureZoneImageView.layer.minificationFilter = kCAFilterTrilinear;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"backgroundImage_repeat"]];
    
    UIView *rootView = IS_IPHONE ? UIApplication.sharedApplication.keyWindow.rootViewController.view : self.view;
    CGFloat deltaY = IS_IPHONE ? UIApplication.sharedApplication.statusBarFrame.size.height : 0;
    CGFloat originX = isEmbeddedMode ? ANCHOR_RIGHT_PEEK : 0;
    messagesView = [[MessagesView alloc] initWithFrame:CGRectMake(originX,
                                                                  0,
                                                                  TransitionalView.frame.size.width,
                                                                  DEFAULT_MSG_HEIGHT + deltaY)
                                                deltaY:deltaY
                                                deltaX:0];
    messagesView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [rootView addSubview:messagesView];
    
    if (isEmbeddedMode) {
        // Shadow on right side of movable screen
        CGRect shadowRect = CGRectMake(0,
                                       0,
                                       PANEL_SHADOW_SIZE,
                                       messagesView.frame.size.height);
        UIImageView *shadowRight = [[UIImageView alloc] initWithFrame:shadowRect];
        shadowRight.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
        shadowRight.image = [UIImage imageNamed:@"tableRight"];
        shadowRight.opaque = YES;
        [messagesView addSubview:shadowRight];
    }
}

- (void)handleSettingsButton:(id)sender {
    if (IS_IPHONE) {
        [self revealUnderRight];
    }
    else {
        [self addButtonToListIPad];
    }
}

- (void)addButtonToListIPad {
    if (AppDelegate.instance.serverVersion < 13) {
        UIAlertController *alertView = [Utilities createAlertOK:@"" message:LOCALIZED_STR(@"XBMC \"Gotham\" version 13 or superior is required to access XBMC settings")];
        [self presentViewController:alertView animated:YES completion:nil];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
        RightMenuViewController *rightMenuViewController = [[RightMenuViewController alloc] initWithNibName:@"RightMenuViewController" bundle:nil];
        rightMenuViewController.rightMenuItems = AppDelegate.instance.remoteControlMenuItems;
        if (rightMenuViewController.rightMenuItems.count) {
            mainMenu *menuItem = rightMenuViewController.rightMenuItems[0];
            menuItem.mainMethod = nil;
        }
        rightMenuViewController.view.frame = CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height);
        [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:rightMenuViewController invokeByController:self isStackStartView:NO];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LeaveFullscreen" object:nil userInfo:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollOnScreen" object: nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
