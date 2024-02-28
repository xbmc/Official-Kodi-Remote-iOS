//
//  ViewControllerIPad.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 29/4/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"
#import "gradientUIView.h"
#import "tcpJSONRPC.h"

@class MenuViewController;
@class StackScrollViewController;
@class UIViewExt;
@class NowPlaying;
@class VolumeSliderView;
@class HostManagementViewController;
@class AppInfoViewController;


@interface ViewControllerIPad : UIViewController {
    UIViewExt *rootView;
    UIView *leftMenuView;
    UIView *rightSlideView;
    UILabel *playlistHeader;
    MenuViewController *menuViewController;
    NowPlaying *nowPlayingController;
    StackScrollViewController *stackScrollViewController;
    NSIndexPath *storeServerSelection;
    int YPOS;
    UIButton *remoteButton;
    UIButton *xbmcLogo;
    UIButton *xbmcInfo;
    UIButton *powerButton;
    UIImageView *connectionStatus;
    VolumeSliderView *volumeSliderView;
    BOOL firstRun;
    BOOL didTouchLeftMenu;
    NSTimer *extraTimer;
    HostManagementViewController *_hostPickerViewController;
    BOOL serverPicker;
    BOOL appInfo;
    UIImageView *fanartBackgroundImage;
    BOOL isFullscreen;
}

@property (nonatomic, strong) NSMutableArray *mainMenu;
@property (nonatomic, strong) MenuViewController *menuViewController;
@property (nonatomic, strong) NowPlaying *nowPlayingController;
@property (nonatomic, strong) StackScrollViewController *stackScrollViewController;
@property (strong, nonatomic) tcpJSONRPC *tcpJSONRPCconnection;
@property (nonatomic, strong) HostManagementViewController *hostPickerViewController;
@property (nonatomic, strong) AppInfoViewController *appInfoView;

@end
