//
//  ViewControllerIPad.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 29/4/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@class MenuViewController;
@class StackScrollViewController;
@class UIViewExt;
@class NowPlaying;
@class GlobalData;
@class VolumeSliderView;


@interface ViewControllerIPad : UIViewController {
	UIViewExt* rootView;
	UIView* leftMenuView;
	UIView* rightSlideView;
	MenuViewController* menuViewController;
    NowPlaying* nowPlayingController;
	StackScrollViewController* stackScrollViewController;
    GlobalData *obj;
    NSIndexPath *storeServerSelection;
    int YPOS;
    UIButton *xbmcLogo;
    UIButton *volumeButton;
    VolumeSliderView *volumeSliderView;
}

@property (nonatomic, strong) NSMutableArray *mainMenu;
@property (nonatomic, retain) MenuViewController* menuViewController;
@property (nonatomic, retain) NowPlaying* nowPlayingController;


@property (nonatomic, strong) StackScrollViewController* stackScrollViewController;

@end
