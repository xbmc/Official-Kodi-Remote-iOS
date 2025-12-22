//
//  ViewControllerIPad.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 29/4/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "BaseMasterViewController.h"
#import "DSJSONRPC.h"
#import "tcpJSONRPC.h"
#import "MessagesView.h"
#import "VolumeSliderView.h"

@import UIKit;

@class MenuViewController;
@class StackScrollViewController;
@class UIViewExt;
@class NowPlaying;
@class VolumeSliderView;
@class HostManagementViewController;
@class AppInfoViewController;

@interface ViewControllerIPad : BaseMasterViewController {
    UIViewExt *rootView;
    UIView *leftMenuView;
    UIView *rightSlideView;
    UILabel *playlistHeader;
    MenuViewController *menuViewController;
    NowPlaying *nowPlayingController;
    StackScrollViewController *stackScrollViewController;
    int YPOS;
    UIButton *xbmcLogo;
    UIButton *xbmcInfo;
    UIButton *powerButton;
    UIButton *settingsButton;
    UIImageView *connectionStatus;
    VolumeSliderView *volumeSliderView;
    BOOL didTouchLeftMenu;
    NSTimer *extraTimer;
    HostManagementViewController *_hostPickerViewController;
    BOOL serverPicker;
    BOOL appInfo;
    UIImageView *fanartBackgroundImage;
    UIImageView *coverBackgroundImage;
    UIVisualEffectView *visualEffectView;
    BOOL isFullscreen;
    MessagesView *messagesView;
}

@property (nonatomic, strong) NSMutableArray *mainMenu;
@property (nonatomic, strong) MenuViewController *menuViewController;
@property (nonatomic, strong) NowPlaying *nowPlayingController;
@property (nonatomic, strong) StackScrollViewController *stackScrollViewController;
@property (nonatomic, strong) HostManagementViewController *hostPickerViewController;
@property (nonatomic, strong) AppInfoViewController *appInfoView;

@end
