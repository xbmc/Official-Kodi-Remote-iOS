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
#import "VersionCheck.h"

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
#define TAG_BUTTON_SEEK_BACKWARD_BIG 25
#define TAG_BUTTON_SEEK_FORWARD_BIG 26
#define WINDOW_FULLSCREEN_VIDEO 12005
#define WINDOW_VISUALISATION 12006
#define KEY_HOLD_TIMEOUT 0.5
#define KEY_REPEAT_TIMEOUT 0.1

@interface RemoteController ()

@end

@implementation RemoteController

@synthesize holdKeyTimer;

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
    if (positionMode == RemoteAtBottom && [Utilities hasRemoteToolBar]) {
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
                    ypos:-shift];
    }
    else {
        shift = CGRectGetMinY(TransitionalView.frame) - CGRectGetMinY(buttonStop.frame);
        [self hideButton:@[buttonMusic,
                           buttonMovies,
                           buttonTVShows,
                           buttonPictures]
                    hide:YES];
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
    
    // embedded remote needs a transparent background
    panFallbackImageView.image = nil;
    
    [self setupGestureView];
    if ([Utilities hasRemoteToolBar]) {
        [self createRemoteToolbar:gestureImage width:newWidth xMin:ANCHOR_RIGHT_PEEK yMax:TOOLBAR_PARENT_HEIGHT];
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
        [self createRemoteToolbar:gestureImage width:remoteControlView.frame.size.width xMin:0 yMax:self.view.bounds.size.height];
    }
}

- (id)initWithNibName:(NSString*)nibNameOrNil withEmbedded:(BOOL)withEmbedded bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    isEmbeddedMode = withEmbedded;
    return self;
}

#pragma mark - Touch

- (void)handleSwipeFrom:(UISwipeGestureRecognizer*)recognizer {
    NSInteger buttonID;
    switch (recognizer.direction) {
        case UISwipeGestureRecognizerDirectionLeft:
            buttonID = TAG_BUTTON_ARROW_LEFT;
            break;
            
        case UISwipeGestureRecognizerDirectionRight:
            buttonID = TAG_BUTTON_ARROW_RIGHT;
            break;
            
        case UISwipeGestureRecognizerDirectionUp:
            buttonID = TAG_BUTTON_ARROW_UP;
            break;
            
        case UISwipeGestureRecognizerDirectionDown:
            buttonID = TAG_BUTTON_ARROW_DOWN;
            break;
            
        default:
            return;
            break;
    }
    [self processButtonPress:buttonID];
    
    NSDictionary *params = @{@"buttontag": @(buttonID)};
    self.holdKeyTimer = [NSTimer scheduledTimerWithTimeInterval:KEY_HOLD_TIMEOUT
                                                         target:self
                                                       selector:@selector(longpressKey:)
                                                       userInfo:params
                                                        repeats:NO];
}

- (void)handleTouchpadDoubleTap {
    [self processButtonPress:TAG_BUTTON_BACK];
}

- (void)handleTouchpadSingleTap {
    [self processButtonPress:TAG_BUTTON_SELECT];
}

- (void)twoFingersTap {
    [self processButtonPress:TAG_BUTTON_HOME];
}

- (void)handleTouchpadLongPress:(UILongPressGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [[Utilities getJsonRPC]
         callMethod:@"XBMC.GetInfoBooleans" 
         withParameters:@{@"booleans": @[@"Window.IsActive(fullscreenvideo)",
                                         @"Window.IsActive(visualisation)",
                                         @"Window.IsActive(slideshow)"]}
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
             
             if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSDictionary class]]) {
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
                     [self processButtonPress:TAG_BUTTON_MENU];
                 }
                 else {
                     [self processButtonLongPress:TAG_BUTTON_MENU];
                 }
             }
             else {
                 [self processButtonLongPress:TAG_BUTTON_MENU];
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
    [self.holdKeyTimer invalidate];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
    [self.holdKeyTimer invalidate];
}
        
# pragma mark - view Effects

- (void)showSubInfo:(NSString*)message color:(UIColor*)color {
    [Utilities showMessage:message color:color];
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
                         completion:nil];
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
                         completion:nil];
        imageName = @"finger";
    }
    if ([sender isKindOfClass:[UIButton class]]) {
        [sender setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:imageName] forState:UIControlStateHighlighted];

    }
    else if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        [sender setImage:[UIImage imageNamed:imageName]];
    }
    [self saveRemoteMode];
}

# pragma mark - JSON

- (NSArray*)buildActionSheetForArray:(NSArray*)languageArray currentLanguage:(NSDictionary*)currentActiveLanguage featureEnabled:(BOOL)featureEnabled  {
    NSUInteger numItems = languageArray.count;
    NSMutableArray *actionSheetTitles = [NSMutableArray arrayWithCapacity:numItems];
    [languageArray enumerateObjectsUsingBlock:^(NSDictionary *itemDict, NSUInteger idx, BOOL *stop) {
        if (![itemDict isKindOfClass:[NSDictionary class]]) {
            return;
        }
        NSString *language = LOCALIZED_STR(@"Unknown");
        NSString *currentItemLanguage = [Utilities getStringFromItem:itemDict[@"language"]];
        if (currentItemLanguage.length) {
            NSLocale *currentLocale = [NSLocale currentLocale];
            NSString *canonicalID = [NSLocale canonicalLanguageIdentifierFromString:currentItemLanguage];
            NSString *displayNameString = [currentLocale displayNameForKey:NSLocaleIdentifier value:canonicalID];
            if (displayNameString.length > 0) {
                language = displayNameString;
            }
            else {
                language = currentItemLanguage;
            }
        }
        NSString *tickMark = @"";
        if (featureEnabled && [currentActiveLanguage isEqual:itemDict]) {
            tickMark = @"\u2713 ";
        }
        NSString *name = itemDict[@"name"];
        NSString *title = [NSString stringWithFormat:@"%@%@%@%@ (%lu/%lu)", tickMark, language, name.length ? @" - " : @"", name, idx + 1, numItems];
        [actionSheetTitles addObject:title];
    }];
    return [actionSheetTitles copy];
}

- (void)subtitlesActionSheet {
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:@{} onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSArray class]]) {
            if ([methodResult count] > 0) {
                int playerID = [Utilities getActivePlayerID:methodResult];
                NSDictionary *params = @{
                    @"playerid": @(playerID),
                    @"properties": @[@"subtitleenabled", @"currentsubtitle", @"subtitles"],
                };
                [[Utilities getJsonRPC]
                 callMethod:@"Player.GetProperties"
                 withParameters:params
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                     if (error == nil && methodError == nil) {
                         if ([methodResult isKindOfClass:[NSDictionary class]]) {
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
                                     NSArray *actionSheetTitles = [self buildActionSheetForArray:subtitles
                                                                                 currentLanguage:currentSubtitle
                                                                                  featureEnabled:subtitleEnabled];
                                     [self showActionSubtitles:actionSheetTitles];
                                 }
                                 else {
                                     [self showSubInfo:LOCALIZED_STR(@"Subtitles not available") color:ERROR_MESSAGE_COLOR];
                                 }
                             }
                         }
                     }
                 }];
            }
            else {
                [self showSubInfo:LOCALIZED_STR(@"Subtitles not available") color:ERROR_MESSAGE_COLOR];
            }
        }
    }];
}

- (void)audioStreamActionSheet {
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:@{} onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSArray class]]) {
            if ([methodResult count] > 0) {
                int playerID = [Utilities getActivePlayerID:methodResult];
                NSDictionary *params = @{
                    @"playerid": @(playerID),
                    @"properties": @[@"currentaudiostream", @"audiostreams"],
                };
                [[Utilities getJsonRPC]
                 callMethod:@"Player.GetProperties"
                 withParameters:params
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                     if (error == nil && methodError == nil) {
                         if ([methodResult isKindOfClass:[NSDictionary class]]) {
                             if ([methodResult count]) {
                                 NSDictionary *currentAudiostream = methodResult[@"currentaudiostream"];
                                 NSArray *audiostreams = methodResult[@"audiostreams"];
                                 if (audiostreams.count) {
                                     audiostreamsDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                       currentAudiostream, @"currentaudiostream",
                                                       audiostreams, @"audiostreams",
                                                       nil];
                                     NSArray *actionSheetTitles = [self buildActionSheetForArray:audiostreams
                                                                                 currentLanguage:currentAudiostream
                                                                                  featureEnabled:YES];
                                     [self showActionAudiostreams:actionSheetTitles];
                                 }
                                 else {
                                     [self showSubInfo:LOCALIZED_STR(@"Audiostreams not available") color:ERROR_MESSAGE_COLOR];
                                 }
                             }
                        }
                     }
                 }];
            }
            else {
                [self showSubInfo:LOCALIZED_STR(@"Audiostream not available") color:ERROR_MESSAGE_COLOR];
            }
        }
    }];
}

- (void)playbackAction:(NSString*)action params:(NSDictionary*)parameters {
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:@{} onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSArray class]]) {
            if ([methodResult count] > 0) {
                NSMutableDictionary *commonParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
                int playerID = [Utilities getActivePlayerID:methodResult];
                commonParams[@"playerid"] = @(playerID);
                [[Utilities getJsonRPC] callMethod:action withParameters:commonParams onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                }];
            }
        }
    }];
}

- (void)GUIAction:(NSString*)action params:(NSDictionary*)params httpAPIcallback:(NSString*)callback {
    [[Utilities getJsonRPC] callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
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
}

#pragma mark - Action Sheet Method

- (void)showActionAudiostreams:(NSArray*)sheetActions {
    NSInteger numActions = sheetActions.count;
    if (numActions) {
        UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:LOCALIZED_STR(@"Audio stream") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *action_cancel = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
        
        for (int i = 0; i < numActions; i++) {
            NSString *actiontitle = sheetActions[i];
            UIAlertAction *action = [UIAlertAction actionWithTitle:actiontitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                if (audiostreamsDictionary[@"audiostreams"]) {
                    if (audiostreamsDictionary[@"audiostreams"][i]) {
                        if (![audiostreamsDictionary[@"audiostreams"][i] isEqual:audiostreamsDictionary[@"currentaudiostream"]]) {
                            id audiostreamIndex = audiostreamsDictionary[@"audiostreams"][i][@"index"];
                            if (audiostreamIndex) {
                                [self playbackAction:@"Player.SetAudioStream" params:@{@"stream": audiostreamIndex}];
                                [self showSubInfo:actiontitle color:SUCCESS_MESSAGE_COLOR];
                            }
                        }
                    }
                }
            }];
            [alertCtrl addAction:action];
        }
        [alertCtrl addAction:action_cancel];
        alertCtrl.modalPresentationStyle = UIModalPresentationPopover;
        
        UIPopoverPresentationController *popPresenter = [alertCtrl popoverPresentationController];
        if (popPresenter != nil) {
            popPresenter.sourceView = remoteControlView;
            popPresenter.sourceRect = buttonAudiostreams.frame;
        }
        [self presentViewController:alertCtrl animated:YES completion:nil];
    }
}

- (void)showActionSubtitles:(NSArray*)sheetActions {
    NSInteger numActions = sheetActions.count;
    if (numActions) {
        UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:LOCALIZED_STR(@"Subtitles") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *action_cancel = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:nil];

        UIAlertAction *action_disable = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Disable subtitles") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [self showSubInfo:LOCALIZED_STR(@"Subtitles disabled") color:SUCCESS_MESSAGE_COLOR];
            [self playbackAction:@"Player.SetSubtitle" params:@{@"subtitle": @"off"}];
        }];
        if ([subsDictionary[@"subtitleenabled"] boolValue]) {
            [alertCtrl addAction:action_disable];
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
                                [self showSubInfo:actiontitle color:SUCCESS_MESSAGE_COLOR];
                            }
                        }
                    }
                }
            }];
            [alertCtrl addAction:action];
        }
        [alertCtrl addAction:action_cancel];
        alertCtrl.modalPresentationStyle = UIModalPresentationPopover;
        
        UIPopoverPresentationController *popPresenter = [alertCtrl popoverPresentationController];
        if (popPresenter != nil) {
            popPresenter.sourceView = remoteControlView;
            popPresenter.sourceRect = buttonSubtitles.frame;
        }
        [self presentViewController:alertCtrl animated:YES completion:nil];
    }
}

#pragma mark - Buttons

- (IBAction)holdKey:(id)sender {
    NSInteger buttonID = [sender tag];
    [self processButtonPress:buttonID];
    
    NSDictionary *params = @{@"buttontag": @(buttonID)};
    [self.holdKeyTimer invalidate];
    self.holdKeyTimer = [NSTimer scheduledTimerWithTimeInterval:KEY_HOLD_TIMEOUT
                                                         target:self
                                                       selector:@selector(longpressKey:)
                                                       userInfo:params
                                                        repeats:NO];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL startVibrate = [userDefaults boolForKey:@"vibrate_preference"];
    if (startVibrate) {
        [[UIDevice currentDevice] playInputClick];
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

- (IBAction)stopHoldKey:(id)sender {
    [self.holdKeyTimer invalidate];
}

- (void)longpressKey:(id)timer {
    // Repeatable key was longpressed
    id sender = [timer userInfo];
    [self.holdKeyTimer invalidate];
    self.holdKeyTimer = [NSTimer scheduledTimerWithTimeInterval:KEY_REPEAT_TIMEOUT
                                                         target:self
                                                       selector:@selector(autoPressKey:)
                                                       userInfo:sender
                                                        repeats:YES];
}

- (void)autoPressKey:(id)timer {
    // Auto repeated button press
    NSDictionary *params = [timer userInfo];
    NSInteger buttonTag = [params[@"buttontag"] intValue];
    [self processButtonPress:buttonTag];
}

- (void)playerActionVideo:(NSInteger)videoButton actionMusic:(NSInteger)musicButton {
    if (AppDelegate.instance.serverVersion > 11) {
        [[Utilities getJsonRPC]
         callMethod:@"GUI.GetProperties"
         withParameters:@{@"properties": @[@"currentwindow",
                                           @"fullscreen"]}
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
             if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSDictionary class]]) {
                 long winID = 0;
                 BOOL isFullscreen = NO;
                 if (methodResult[@"fullscreen"] != [NSNull null]) {
                     isFullscreen = [methodResult[@"fullscreen"] boolValue];
                 }
                 if (methodResult[@"currentwindow"] != [NSNull null]) {
                     winID = [methodResult[@"currentwindow"][@"id"] longLongValue];
                 }
                 if (isFullscreen && (winID == WINDOW_FULLSCREEN_VIDEO || winID == WINDOW_VISUALISATION)) {
                     [[Utilities getJsonRPC]
                      callMethod:@"XBMC.GetInfoBooleans"
                      withParameters:@{@"booleans": @[@"VideoPlayer.HasMenu",
                                                      @"Pvr.IsPlayingTv"]}
                      onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
                          if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSDictionary class]]) {
                              BOOL VideoPlayerHasMenu = NO;
                              BOOL PvrIsPlayingTv = NO;
                              if (methodResult[@"VideoPlayer.HasMenu"] != [NSNull null]) {
                                  VideoPlayerHasMenu = [methodResult[@"VideoPlayer.HasMenu"] boolValue];
                              }
                              if (methodResult[@"Pvr.IsPlayingTv"] != [NSNull null]) {
                                  PvrIsPlayingTv = [methodResult[@"Pvr.IsPlayingTv"] boolValue];
                              }
                              if (winID == WINDOW_FULLSCREEN_VIDEO && !PvrIsPlayingTv && !VideoPlayerHasMenu) {
                                  [self processButtonPress:videoButton];
                              }
                              else if (winID == WINDOW_VISUALISATION) {
                                  [self processButtonPress:musicButton];
                              }
                          }
                      }];
                 }
             }
         }];
    }
}

- (void)processButtonPress:(NSInteger)buttonTag {
    NSString *action;
    NSDictionary *params;
    switch (buttonTag) {
        case TAG_BUTTON_ARROW_UP:
            if ([VersionCheck hasInputButtonEventSupport]) {
                [self GUIAction:@"Input.ButtonEvent" params:@{@"button": @"up", @"keymap": @"KB"} httpAPIcallback:nil];
            }
            else {
                [self GUIAction:@"Input.Up" params:@{} httpAPIcallback:nil];
                [self playerActionVideo:TAG_BUTTON_SEEK_FORWARD_BIG actionMusic:TAG_BUTTON_NEXT];
            }
            break;
            
        case TAG_BUTTON_ARROW_LEFT:
            if ([VersionCheck hasInputButtonEventSupport]) {
                [self GUIAction:@"Input.ButtonEvent" params:@{@"button": @"left", @"keymap": @"KB"} httpAPIcallback:nil];
            }
            else {
                [self GUIAction:@"Input.Left" params:@{} httpAPIcallback:nil];
                [self playerActionVideo:TAG_BUTTON_SEEK_BACKWARD actionMusic:TAG_BUTTON_SEEK_BACKWARD];
            }
            break;
            
        case TAG_BUTTON_ARROW_RIGHT:
            if ([VersionCheck hasInputButtonEventSupport]) {
                [self GUIAction:@"Input.ButtonEvent" params:@{@"button": @"right", @"keymap": @"KB"} httpAPIcallback:nil];
            }
            else {
                [self GUIAction:@"Input.Right" params:@{} httpAPIcallback:nil];
                [self playerActionVideo:TAG_BUTTON_SEEK_FORWARD actionMusic:TAG_BUTTON_SEEK_FORWARD];
            }
            break;
            
        case TAG_BUTTON_ARROW_DOWN:
            if ([VersionCheck hasInputButtonEventSupport]) {
                [self GUIAction:@"Input.ButtonEvent" params:@{@"button": @"down", @"keymap": @"KB"} httpAPIcallback:nil];
            }
            else {
                [self GUIAction:@"Input.Down" params:@{} httpAPIcallback:nil];
                [self playerActionVideo:TAG_BUTTON_SEEK_BACKWARD_BIG actionMusic:TAG_BUTTON_PREVIOUS];
            }
            break;
            
        case TAG_BUTTON_BACK:
            [self GUIAction:@"Input.Back" params:@{} httpAPIcallback:nil];
            break;
            
        case TAG_BUTTON_FULLSCREEN:
            action = @"GUI.SetFullscreen";
            [self GUIAction:action params:@{@"fullscreen": @"toggle"} httpAPIcallback:@"SendKey(0xf009)"];
            break;
            
        case TAG_BUTTON_SEEK_BACKWARD:
            action = @"Player.Seek";
            params = [Utilities buildPlayerSeekStepParams:@"smallbackward"];
            [self playbackAction:action params:params];
            break;
            
        case TAG_BUTTON_SEEK_BACKWARD_BIG:
            action = @"Player.Seek";
            params = [Utilities buildPlayerSeekStepParams:@"bigbackward"];
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
        
        case TAG_BUTTON_SEEK_FORWARD_BIG:
            action = @"Player.Seek";
            params = [Utilities buildPlayerSeekStepParams:@"bigforward"];
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
            [self GUIAction:action params:@{} httpAPIcallback:nil];
            break;
            
        case TAG_BUTTON_INFO: // INFO
            action = @"Input.Info";
            [self GUIAction:action params:@{} httpAPIcallback:@"SendKey(0xF049)"];
            break;
            
        case TAG_BUTTON_SELECT:
            action = @"Input.Select";
            [self GUIAction:action params:@{} httpAPIcallback:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Input.OnInputFinished" object:nil userInfo:nil];
            break;
            
        case TAG_BUTTON_MENU: // MENU OSD
            action = @"Input.ShowOSD";
            [self GUIAction:action params:@{} httpAPIcallback:@"SendKey(0xF04D)"];
            break;
        
        case TAG_BUTTON_SUBTITLES:
            [self subtitlesActionSheet];
            break;
            
        case TAG_BUTTON_AUDIOSTREAMS:
            [self audioStreamActionSheet];
            break;
            
        case TAG_BUTTON_MUSIC:
            action = @"GUI.ActivateWindow";
            params = @{@"window": @"music"};
            [self GUIAction:action params:params httpAPIcallback:@"ExecBuiltIn&parameter=ActivateWindow(Music)"];
            break;
            
        case TAG_BUTTON_MOVIES:
            action = @"GUI.ActivateWindow";
            params = @{@"window": @"videos",
                       @"parameters": @[@"MovieTitles"]};
            [self GUIAction:action params:params httpAPIcallback:@"ExecBuiltIn&parameter=ActivateWindow(Videos,MovieTitles)"];
            break;
        
        case TAG_BUTTON_TVSHOWS:
            action = @"GUI.ActivateWindow";
            params = @{@"window": @"videos",
                       @"parameters": @[@"tvshowtitles"]};
            [self GUIAction:action params:params httpAPIcallback:@"ExecBuiltIn&parameter=ActivateWindow(Videos,tvshowtitles)"];
            break;
        
        case TAG_BUTTON_PICTURES:
            action = @"GUI.ActivateWindow";
            params = @{@"window": @"pictures"};
            [self GUIAction:action params:params httpAPIcallback:@"ExecBuiltIn&parameter=ActivateWindow(Pictures)"];
            break;
            
        default:
            break;
    }
}

- (IBAction)startVibrate:(id)sender {
    [self processButtonPress:[sender tag]];
    
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

- (void)processButtonLongPress:(NSInteger)buttonTag {
    switch (buttonTag) {
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
                [self GUIAction:@"Input.ShowCodec" params:@{} httpAPIcallback:@"SendKey(0xF04F)"];
            }
            break;

        case TAG_BUTTON_SELECT: // CONTEXT MENU
        case TAG_BUTTON_MENU:
            [self GUIAction:@"Input.ContextMenu" params:@{} httpAPIcallback:@"SendKey(0xF043)"];
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

- (IBAction)handleButtonLongPress:(UILongPressGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self processButtonLongPress:gestureRecognizer.view.tag];
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
}

- (void)loadRemoteMode {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    isGestureViewActive = [userDefaults boolForKey:@"GestureViewEnabled"];
    positionMode = (RemotePositionType)[userDefaults integerForKey:@"RemotePosition"];
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
        UIImage *customImg = [UIImage imageNamed:@"icon_custom_buttons"];
        UIImage *powerImg = [UIImage imageNamed:@"icon_power"];
        self.navigationItem.rightBarButtonItems = @[
            [[UIBarButtonItem alloc] initWithImage:customImg style:UIBarButtonItemStylePlain target:self action:@selector(enterCustomButtons:)],
            [[UIBarButtonItem alloc] initWithImage:powerImg style:UIBarButtonItemStylePlain target:self action:@selector(powerControl)]
        ];
        self.navigationController.navigationBar.barTintColor = REMOTE_CONTROL_BAR_TINT_COLOR;
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    quickHelpView.alpha = 0.0;
    [self volumeInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(revealMenu:)
                                                 name:@"RevealMenu"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(toggleVirtualKeyboard:)
                                                 name:@"UIToggleVirtualKeyboard"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(toggleQuickHelp:)
                                                 name:@"UIToggleQuickHelp"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(toggleGestureZone:)
                                                 name:@"UIToggleGestureZone"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideKeyboard:)
                                                 name:@"ECSlidingViewTopWillReset"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideKeyboard:)
                                                 name:@"ECSlidingViewUnderRightWillAppear"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideKeyboard:)
                                                 name:@"ECSlidingViewUnderLeftWillAppear"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(disablePopGestureRecognizer:)
                                                 name:@"ECSlidingViewUnderRightWillAppear"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enablePopGestureRecognizer:)
                                                 name:@"ECSlidingViewTopDidReset"
                                               object:nil];
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
    [self.holdKeyTimer invalidate];
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
    positionMode = positionMode == RemoteAtBottom ? RemoteAtTop : RemoteAtBottom;
    CGRect frame = remoteControlView.frame;
    if (positionMode == RemoteAtBottom && [Utilities hasRemoteToolBar]) {
        frame.origin.y = CGRectGetMinY(remoteToolbar.frame) - CGRectGetHeight(remoteControlView.frame) + embeddedShift;
    }
    else {
        frame.origin.y = topRemoteOffset;
    }
    remoteControlView.frame = frame;
    remoteControlView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    [self saveRemoteMode];
}

- (void)createRemoteToolbar:(UIImage*)gestureButtonImg width:(CGFloat)width xMin:(CGFloat)xMin yMax:(CGFloat)yMax {
    torchIsOn = [Utilities isTorchOn];
    // iPhone layout has 5 buttons (Gesture > Keyboard > Info > Torch > Additional) with flex spaces around buttons.
    // iPad layout has 6 buttons (Settings > Gesture > Keyboard > Info > Torch > Additional) with flex spaces around buttons.
    // iPhone has an addtional button to toggle the remote's vertical position
    // iPad has an additional button to close the modal view
    int numButtons = IS_IPAD ? 6 : 5;
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
    if (IS_IPAD) {
        UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
        frame.origin.x += ToolbarPadding;
        customButton.frame = frame;
        customButton.showsTouchWhenHighlighted = YES;
        [customButton setImage:[UIImage imageNamed:@"icon_custom_buttons"] forState:UIControlStateNormal];
        [customButton addTarget:self action:@selector(enterCustomButtons:) forControlEvents:UIControlEventTouchUpInside];
        customButton.alpha = 0.8;
        [remoteToolbar addSubview:customButton];
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
    torchButton.enabled = [Utilities hasTorch];
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

    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    quickHelpImageView.image = [UIImage imageNamed:@"remote_quick_help"];
    [self loadRemoteMode];
    if (!isEmbeddedMode) {
        [self configureView];
    }
    else {
        [self setEmbeddedView];
    }
    
    gestureZoneImageView.layer.minificationFilter = kCAFilterTrilinear;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"backgroundImage_repeat"]];
}

- (void)enterCustomButtons:(id)sender {
    if (IS_IPHONE) {
        [self revealUnderRight];
    }
    else {
        [self enterCustomButtonsIPad];
    }
}

- (void)powerControl {
    if (AppDelegate.instance.obj.serverIP.length == 0) {
        return;
    }
    UIAlertController *alertCtrl = [Utilities createPowerControl];
    [self presentViewController:alertCtrl animated:YES completion:nil];
}

- (void)enterCustomButtonsIPad {
    RightMenuViewController *rightMenuViewController = [[RightMenuViewController alloc] initWithNibName:@"RightMenuViewController" bundle:nil];
    rightMenuViewController.rightMenuItems = AppDelegate.instance.remoteControlMenuItems;
    rightMenuViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    rightMenuViewController.view.frame = self.view.frame;
    [self presentViewController:rightMenuViewController animated:YES completion:nil];
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
