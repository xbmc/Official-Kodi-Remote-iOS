//
//  RemoteController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 24/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "DSJSONRPC.h"
#import "VolumeSliderView.h"

@import UIKit;
@import AVFoundation;

typedef NS_ENUM(NSInteger, RemotePositionType) {
    RemoteAtTop,
    RemoteAtBottom,
};

@interface RemoteController : UIViewController <UIGestureRecognizerDelegate> {
    IBOutlet UIView *remoteControlView;
    IBOutlet UIView *quickHelpView;
    IBOutlet UIImageView *quickHelpImageView;
    IBOutlet UILabel *quickHelpMainLabel;
    IBOutlet UILabel *quickHelpSubLabel;
    IBOutlet UIView *gestureZoneView;
    IBOutlet UIView *buttonZoneView;
    IBOutlet UIImageView *panFallbackImageView;
    IBOutlet UIButton *buttonSeekBackward;
    IBOutlet UIButton *buttonPlayPause;
    IBOutlet UIButton *buttonSeekForward;
    IBOutlet UIButton *buttonPrevious;
    IBOutlet UIButton *buttonNext;
    IBOutlet UIButton *buttonStop;
    IBOutlet UIButton *buttonMusic;
    IBOutlet UIButton *buttonMovies;
    IBOutlet UIButton *buttonTVShows;
    IBOutlet UIButton *buttonPictures;
    IBOutlet UIButton *buttonSubtitles;
    IBOutlet UIButton *buttonAudiostreams;
    CGFloat lastRotation;
    RemotePositionType positionMode;
    UIView *remoteToolbar;
    UIButton *positionButton;
    UIButton *torchButton;
    VolumeSliderView *volumeSliderView;
    __weak IBOutlet UIView *TransitionalView;
    __weak IBOutlet UIImageView *gestureZoneImageView;
    BOOL torchIsOn;
    BOOL isEmbeddedMode;
    BOOL isGestureViewActive;
    NSDictionary *subsDictionary;
    NSDictionary *audiostreamsDictionary;
}

- (IBAction)startVibrate:(id)sender;
- (id)initWithNibName:(NSString*)nibNameOrNil withEmbedded:(BOOL)withEmbedded bundle:(NSBundle*)nibBundleOrNil;

@property (strong, nonatomic) id detailItem;
@property (nonatomic, strong) NSTimer *holdKeyTimer;
@property (nonatomic, strong) AVCaptureDevice *avCaptureDevice;

@end
