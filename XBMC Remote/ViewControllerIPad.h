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


@interface ViewControllerIPad : UIViewController <UIPopoverControllerDelegate, UIActionSheetDelegate>{
	UIViewExt* rootView;
	UIView* leftMenuView;
	UIView* rightSlideView;
	MenuViewController* menuViewController;
    NowPlaying* nowPlayingController;
	StackScrollViewController* stackScrollViewController;
    NSIndexPath *storeServerSelection;
    int YPOS;
    UIButton *xbmcLogo;
    UIButton *xbmcInfo;
    UIButton *powerButton;
    VolumeSliderView *volumeSliderView;
    DSJSONRPC *jsonRPC;
    BOOL firstRun;
    NSTimer* extraTimer;
    UIPopoverController *_serverPickerPopover;
    HostManagementViewController *_hostPickerViewController;
    UIActionSheet *actionSheetPower;
    BOOL showActionPower;
}

@property (nonatomic, strong) NSMutableArray *mainMenu;
@property (nonatomic, retain) MenuViewController* menuViewController;
@property (nonatomic, retain) NowPlaying* nowPlayingController;
@property (nonatomic, strong) StackScrollViewController* stackScrollViewController;
@property (nonatomic, retain) UIPopoverController *serverPickerPopover;
@property (nonatomic, retain) UIPopoverController *appInfoPopover;
@property (strong, nonatomic) tcpJSONRPC *tcpJSONRPCconnection;
@property (nonatomic, retain) HostManagementViewController *hostPickerViewController;
@property (nonatomic, retain) AppInfoViewController *appInfoView;

@end
