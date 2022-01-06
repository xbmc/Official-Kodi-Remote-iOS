//
//  ViewControllerIPad.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 29/4/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"
#import "MenuViewController.h"
#import "NowPlaying.h"
#import "mainMenu.h"
#import "GlobalData.h"
#import "AppDelegate.h"
#import "HostManagementViewController.h"
#import "AppInfoViewController.h"
#import "XBMCVirtualKeyboard.h"
#import "ClearCacheView.h"
#import "gradientUIView.h"
#import "CustomNavigationController.h"
#import "Utilities.h"

#define CONNECTION_TIMEOUT 240.0
#define SERVER_TIMEOUT 2.0
#define VIEW_PADDING 10 /* separation between toolbar views */
#define TOOLBAR_HEIGHT 44
#define XBMCLOGO_WIDTH 30
#define POWERBUTTON_WIDTH 42
#define CONNECTION_ICON_SIZE 18
#define CONNECTION_PADDING 20
#define VOLUME_PADDING_LEFT 40
#define PLAYLIST_HEADER_HEIGHT 24
#define LINE_HEIGHT 1

@interface ViewControllerIPad () {
    NSMutableArray *mainMenu;
}
@end

@interface UIViewExt : UIView {} 
@end


@implementation UIViewExt
- (UIView*)hitTest:(CGPoint)pt withEvent:(UIEvent*)event {
	UIView* viewToReturn = nil;
	CGPoint pointToReturn;
	UIView* uiRightView = (UIView*)(self.subviews[1]);
	if (uiRightView.subviews[0]) {
		UIView* uiStackScrollView = uiRightView.subviews[0];
		if (uiStackScrollView.subviews[1]) {
			UIView* uiSlideView = uiStackScrollView.subviews[1];
			for (UIView* subView in uiSlideView.subviews) {
				CGPoint point = [subView convertPoint:pt fromView:self];
				if ([subView pointInside:point withEvent:event]) {
					viewToReturn = subView;
					pointToReturn = point;
				}
			}
		}
	}
	
	if (viewToReturn != nil) {
		return [viewToReturn hitTest:pointToReturn withEvent:event];		
	}
	
	return [super hitTest:pt withEvent:event];
}
@end



@implementation ViewControllerIPad

@synthesize mainMenu;
@synthesize menuViewController, stackScrollViewController;
@synthesize nowPlayingController;
@synthesize hostPickerViewController = _hostPickerViewController;
@synthesize appInfoView = _appInfoView;
@synthesize tcpJSONRPCconnection;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - ServerManagement

- (void)selectServerAtIndexPath:(NSIndexPath*)indexPath {
    storeServerSelection = indexPath;
    NSDictionary *item = AppDelegate.instance.arrayServerList[indexPath.row];
    AppDelegate.instance.obj.serverDescription = item[@"serverDescription"];
    AppDelegate.instance.obj.serverUser = item[@"serverUser"];
    AppDelegate.instance.obj.serverPass = item[@"serverPass"];
    AppDelegate.instance.obj.serverIP = item[@"serverIP"];
    AppDelegate.instance.obj.serverPort = item[@"serverPort"];
    AppDelegate.instance.obj.tcpPort = [item[@"tcpPort"] intValue];
}

- (void)wakeUp:(NSString*)macAddress {
    [AppDelegate.instance sendWOL:macAddress withPort:9];
}

- (void)connectionStatus:(NSNotification*)note {
    NSDictionary *theData = note.userInfo;
    NSString *icon_connection = theData[@"icon_connection"];
    connectionStatus.image = [UIImage imageNamed:icon_connection];
}

- (void)changeServerStatus:(BOOL)status infoText:(NSString*)infoText icon:(NSString*)iconName {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   infoText, @"message",
                                   iconName, @"icon_connection",
                                   nil];
    if (status) {
        [self.tcpJSONRPCconnection startNetworkCommunicationWithServer:AppDelegate.instance.obj.serverIP serverPort:AppDelegate.instance.obj.tcpPort];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerConnectionSuccess" object:nil userInfo:params];
        AppDelegate.instance.serverOnLine = YES;
        AppDelegate.instance.serverName = infoText;
        [volumeSliderView startTimer];
        [xbmcInfo setTitle:infoText forState:UIControlStateNormal];
        [Utilities setStyleOfMenuItems:menuViewController.tableView active:YES];
    }
    else {
        [self.tcpJSONRPCconnection stopNetworkCommunication];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerConnectionFailed" object:nil userInfo:params];
        AppDelegate.instance.serverOnLine = NO;
        AppDelegate.instance.serverName = infoText;
        [xbmcInfo setTitle:infoText forState:UIControlStateNormal];
        [Utilities setStyleOfMenuItems:menuViewController.tableView active:NO];
        if (!extraTimer.valid) {
            extraTimer = [NSTimer scheduledTimerWithTimeInterval:CONNECTION_TIMEOUT target:self selector:@selector(offStackView) userInfo:nil repeats:NO];
        }
    }
}

- (void)offStackView {
    if (!AppDelegate.instance.serverOnLine) {
        [AppDelegate.instance.windowController.stackScrollViewController offView];
        NSIndexPath *selection = [menuViewController.tableView indexPathForSelectedRow];
        if (selection) {
            [menuViewController.tableView deselectRowAtIndexPath:selection animated:YES];
            [menuViewController setLastSelected:-1];
        }
    }
    [extraTimer invalidate];
    extraTimer = nil;
}

# pragma mark - toolbar management

- (void)initHostManagemetPopOver {
    self.hostPickerViewController = [[HostManagementViewController alloc] initWithNibName:@"HostManagementViewController" bundle:nil];
    AppDelegate.instance.navigationController = [[CustomNavigationController alloc] initWithRootViewController:_hostPickerViewController];
    [AppDelegate.instance.navigationController hideNavBarBottomLine:YES];
}

- (void)toggleSetup {
    [self initHostManagemetPopOver];
    AppDelegate.instance.navigationController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *popPresenter = [AppDelegate.instance.navigationController popoverPresentationController];
    if (popPresenter != nil) {
        popPresenter.sourceView = self.view;
        popPresenter.sourceRect = xbmcInfo.frame;
    }
    [self presentViewController:AppDelegate.instance.navigationController animated:YES completion:nil];
}

- (void)showSetup:(BOOL)show {
    firstRun = NO;
    if ([self.hostPickerViewController isViewLoaded]) {
        if (!show) {
            [self.hostPickerViewController dismissViewControllerAnimated:NO completion:nil];
        }
    }
    else {
        if (show) {
            [self toggleSetup];
        }
    }
}

- (void)toggleInfoView {
    self.appInfoView = [[AppInfoViewController alloc] initWithNibName:@"AppInfoViewController" bundle:nil];
    self.appInfoView.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *popPresenter = [self.appInfoView popoverPresentationController];
    if (popPresenter != nil) {
        popPresenter.sourceView = self.view;
        popPresenter.sourceRect = xbmcLogo.frame;
    }
    [self presentViewController:self.appInfoView animated:YES completion:nil];
}

#pragma mark - power control action sheet

- (void)powerControl {
    if (AppDelegate.instance.obj.serverIP.length == 0) {
        [self toggleSetup];
        return;
    }
    NSString *title = [NSString stringWithFormat:@"%@\n%@", AppDelegate.instance.obj.serverDescription, AppDelegate.instance.obj.serverIP];
    UIAlertController *actionView = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (!AppDelegate.instance.serverOnLine) {
        UIAlertAction* action_wake = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Wake On Lan") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            if (AppDelegate.instance.obj.serverHWAddr != nil) {
                [self wakeUp:AppDelegate.instance.obj.serverHWAddr];
                UIAlertController *alertView = [Utilities createAlertOK:LOCALIZED_STR(@"Command executed") message:nil];
                [self presentViewController:alertView animated:YES completion:nil];
            }
            else {
                UIAlertController *alertView = [Utilities createAlertOK:LOCALIZED_STR(@"Warning") message:LOCALIZED_STR(@"No server MAC address defined")];
                [self presentViewController:alertView animated:YES completion:nil];
            }
        }];
        [actionView addAction:action_wake];
    }
    else {
        UIAlertAction* action_pwr_off_system = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Power off System") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            [self powerAction:@"System.Shutdown" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_pwr_off_system];
        
        UIAlertAction* action_quit_kodi = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Quit XBMC application") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self powerAction:@"Application.Quit" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_quit_kodi];
        
        UIAlertAction* action_hibernate = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Hibernate") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self powerAction:@"System.Hibernate" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_hibernate];
        
        UIAlertAction* action_suspend = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Suspend") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self powerAction:@"System.Suspend" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_suspend];
        
        UIAlertAction* action_reboot = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Reboot") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self powerAction:@"System.Reboot" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_reboot];
        
        UIAlertAction* action_scan_audio_lib = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Update Audio Library") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self powerAction:@"AudioLibrary.Scan" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_scan_audio_lib];
        
        UIAlertAction* action_clean_audio_lib = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Clean Audio Library") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self powerAction:@"AudioLibrary.Clean" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_clean_audio_lib];
        
        UIAlertAction* action_scan_video_lib = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Update Video Library") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self powerAction:@"VideoLibrary.Scan" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_scan_video_lib];
        
        UIAlertAction* action_clean_video_lib = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Clean Video Library") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self powerAction:@"VideoLibrary.Clean" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_clean_video_lib];
    }
    
    UIAlertAction* cancelButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];
    [actionView addAction:cancelButton];
    actionView.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popPresenter = [actionView popoverPresentationController];
    if (popPresenter != nil) {
        popPresenter.sourceView = powerButton;
        popPresenter.sourceRect = powerButton.bounds;
    }
    [self presentViewController:actionView animated:YES completion:nil];
}

- (void)powerAction:(NSString*)action params:(NSDictionary*)params {
    [[Utilities getJsonRPC] callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        NSString *alertTitle = nil;
        if (methodError == nil && error == nil) {
            alertTitle = LOCALIZED_STR(@"Command executed");
        }
        else {
            alertTitle = LOCALIZED_STR(@"Cannot do that");
        }
        UIAlertController *alertView = [Utilities createAlertOK:alertTitle message:nil];
        [self presentViewController:alertView animated:YES completion:nil];
    }];
}

#pragma mark - Touch Events

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    CGPoint locationPoint = [[touches anyObject] locationInView:self.view];
    CGPoint viewPoint = [self.nowPlayingController.jewelView convertPoint:locationPoint fromView:self.view];
    CGPoint viewPoint4 = [self.nowPlayingController.itemLogoImage convertPoint:locationPoint fromView:self.view];

    if ([self.nowPlayingController.itemLogoImage pointInside:viewPoint4 withEvent:event] && self.nowPlayingController.songDetailsView.alpha > 0 && self.nowPlayingController.itemLogoImage.image != nil) {
        [self.nowPlayingController updateCurrentLogo];
    }
    else if ([self.nowPlayingController.jewelView pointInside:viewPoint withEvent:event] && !AppDelegate.instance.windowController.stackScrollViewController.viewControllersStack.count) {
        [self.nowPlayingController toggleSongDetails];
    }
}

#pragma mark - App clear disk cache methods

- (void)startClearAppDiskCache:(ClearCacheView*)clearView {
    [AppDelegate.instance clearAppDiskCache];
    [self performSelectorOnMainThread:@selector(clearAppDiskCacheFinished:) withObject:clearView waitUntilDone:YES];
}

- (void)clearAppDiskCacheFinished:(ClearCacheView*)clearView {
    [UIView animateWithDuration:0.3
                     animations:^{
                         [clearView stopActivityIndicator];
                         clearView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [clearView stopActivityIndicator];
                         [clearView removeFromSuperview];
                         NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                         [userDefaults removeObjectForKey:@"clearcache_preference"];
                     }];
}

#pragma mark - Lifecycle

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    int deltaY = UIApplication.sharedApplication.statusBarFrame.size.height + 2; // + 2 used by horizontanLineView
    [self setNeedsStatusBarAppearanceUpdate];
    self.view.tintColor = APP_TINT_COLOR;
    self.tcpJSONRPCconnection = [tcpJSONRPC new];
    XBMCVirtualKeyboard *virtualKeyboard = [[XBMCVirtualKeyboard alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    [self.view addSubview:virtualKeyboard];
    firstRun = YES;
    AppDelegate.instance.obj = [GlobalData getInstance]; 

    int cellHeight = PAD_MENU_HEIGHT;
    NSInteger tableHeight = [(NSMutableArray*)mainMenu count] * cellHeight;
    int tableWidth = PAD_MENU_TABLE_WIDTH;
    int headerHeight = 0;
   
    rootView = [[UIViewExt alloc] initWithFrame:CGRectMake(0, deltaY, self.view.frame.size.width, self.view.frame.size.height - deltaY - 1)];
	rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
	rootView.backgroundColor = UIColor.clearColor;
	
    fanartBackgroundImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    fanartBackgroundImage.autoresizingMask = rootView.autoresizingMask;
    fanartBackgroundImage.contentMode = UIViewContentModeScaleAspectFill;
    fanartBackgroundImage.alpha = 0.05;
    [self.view addSubview:fanartBackgroundImage];
    
	leftMenuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableWidth, self.view.frame.size.height)];
	leftMenuView.autoresizingMask = UIViewAutoresizingFlexibleHeight;	
    
	menuViewController = [[MenuViewController alloc] initWithFrame:CGRectMake(0, headerHeight, leftMenuView.frame.size.width, leftMenuView.frame.size.height) mainMenu:mainMenu];
	menuViewController.view.backgroundColor = UIColor.clearColor;
	[menuViewController viewWillAppear:NO];
	[menuViewController viewDidAppear:NO];
	[leftMenuView addSubview:menuViewController.view];
    
    UIView* horizontalLineView1 = [[UIView alloc] initWithFrame:CGRectMake(0, tableHeight, tableWidth, LINE_HEIGHT)];
    horizontalLineView1.backgroundColor = [Utilities getGrayColor:77 alpha:0.6];
    [leftMenuView addSubview:horizontalLineView1];
    
    UILabel *header = [[UILabel alloc] initWithFrame:CGRectMake(0, tableHeight, PAD_MENU_TABLE_WIDTH, PLAYLIST_HEADER_HEIGHT)];
    header.backgroundColor = UIColor.clearColor;
    header.textColor = UIColor.lightGrayColor;
    header.text = LOCALIZED_STR(@"Playlist");
    header.textAlignment = NSTextAlignmentCenter;
    [leftMenuView addSubview:header];

    self.nowPlayingController = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
    CGRect frame = self.nowPlayingController.view.frame;
    YPOS = (int)(tableHeight + LINE_HEIGHT + headerHeight + PLAYLIST_HEADER_HEIGHT);
    frame.origin.y = YPOS;
    frame.size.width = tableWidth;
    frame.size.height = self.view.frame.size.height - YPOS - deltaY;
    self.nowPlayingController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.nowPlayingController.view.frame = frame;
    
    [self.nowPlayingController setNowPlayingDimension:[self screenSizeOrientationIndependent].width height:[self screenSizeOrientationIndependent].height YPOS:-YPOS];
    
    [leftMenuView addSubview:self.nowPlayingController.view];

	rightSlideView = [[UIView alloc] initWithFrame:CGRectMake(leftMenuView.frame.size.width, 0, rootView.frame.size.width - leftMenuView.frame.size.width, rootView.frame.size.height - TOOLBAR_HEIGHT)];
	rightSlideView.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
    
	stackScrollViewController = [StackScrollViewController new];
	stackScrollViewController.view.frame = CGRectMake(0, 0, rightSlideView.frame.size.width, rightSlideView.frame.size.height);
	stackScrollViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
	[stackScrollViewController viewWillAppear:NO];
	[stackScrollViewController viewDidAppear:NO];
	[rightSlideView addSubview:stackScrollViewController.view];
	
	[rootView addSubview:leftMenuView];
	[rootView addSubview:rightSlideView];
    
    [self.view addSubview:rootView];
    
    // left most element
    volumeSliderView = [[VolumeSliderView alloc] initWithFrame:CGRectMake(leftMenuView.frame.size.width - VOLUME_PADDING_LEFT, self.view.frame.size.height - TOOLBAR_HEIGHT, 0, TOOLBAR_HEIGHT) leftAnchor:0.0];
    volumeSliderView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:volumeSliderView];
    
    // right most element
    connectionStatus = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - CONNECTION_ICON_SIZE - VIEW_PADDING, self.view.frame.size.height - (TOOLBAR_HEIGHT + CONNECTION_ICON_SIZE) / 2 - [Utilities getBottomPadding], CONNECTION_ICON_SIZE, CONNECTION_ICON_SIZE)];
    connectionStatus.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:connectionStatus];
    
    // 2nd right most element
    UIImage *image = [UIImage imageNamed:@"bottom_logo_only"];
    xbmcLogo = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(connectionStatus.frame) - XBMCLOGO_WIDTH - CONNECTION_PADDING, self.view.frame.size.height - TOOLBAR_HEIGHT, XBMCLOGO_WIDTH, TOOLBAR_HEIGHT)];
    [xbmcLogo setImage:image forState:UIControlStateNormal];
    [xbmcLogo setImage:image forState:UIControlStateHighlighted];
    xbmcLogo.showsTouchWhenHighlighted = NO;
    [xbmcLogo addTarget:self action:@selector(toggleInfoView) forControlEvents:UIControlEventTouchUpInside];
    xbmcLogo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    xbmcLogo.alpha = 0.9;
    [self.view addSubview:xbmcLogo];
    
    // 3rd right most element
    image = [UIImage imageNamed:@"icon_power_up"];
    powerButton = [[UIButton alloc] initWithFrame:CGRectMake(xbmcLogo.frame.origin.x - POWERBUTTON_WIDTH - VIEW_PADDING, self.view.frame.size.height - TOOLBAR_HEIGHT, POWERBUTTON_WIDTH, TOOLBAR_HEIGHT)];
    [powerButton setImage:image forState:UIControlStateNormal];
    [powerButton setImage:image forState:UIControlStateHighlighted];
    powerButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [powerButton addTarget:self action:@selector(powerControl) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:powerButton];
    
    // element between left most and 2nd right most uses up free space
    CGFloat startInfo = volumeSliderView.frame.origin.x + volumeSliderView.frame.size.width + 2 * VIEW_PADDING;
    CGFloat widthInfo = powerButton.frame.origin.x - startInfo - 2 * VIEW_PADDING;
    xbmcInfo = [[UIButton alloc] initWithFrame:CGRectMake(startInfo, self.view.frame.size.height - TOOLBAR_HEIGHT, widthInfo, TOOLBAR_HEIGHT)];
    [xbmcInfo setTitle:LOCALIZED_STR(@"No connection") forState:UIControlStateNormal];
    xbmcInfo.titleLabel.font = [UIFont systemFontOfSize:13];
    xbmcInfo.titleLabel.minimumScaleFactor = 6.0 / 13.0;
    xbmcInfo.titleLabel.numberOfLines = 2;
    xbmcInfo.titleLabel.textAlignment = NSTextAlignmentCenter;
    xbmcInfo.titleEdgeInsets = UIEdgeInsetsZero;
    xbmcInfo.titleLabel.shadowColor = UIColor.blackColor;
    xbmcInfo.titleLabel.shadowOffset = CGSizeZero;
    xbmcInfo.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [xbmcInfo addTarget:self action:@selector(toggleSetup) forControlEvents:UIControlEventTouchUpInside];
    [xbmcInfo setTitleColor:UIColor.grayColor forState:UIControlStateHighlighted];
    [xbmcInfo setTitleColor:UIColor.grayColor forState:UIControlStateSelected];
    [self.view addSubview:xbmcInfo];
    
    menuViewController.tableView.separatorInset = UIEdgeInsetsZero;
    
    [self.view insertSubview:self.nowPlayingController.songDetailsView aboveSubview:rootView];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL clearCache = [[userDefaults objectForKey:@"clearcache_preference"] boolValue];
    if (clearCache) {
        ClearCacheView *clearView = [[ClearCacheView alloc] initWithFrame:self.view.frame];
        [clearView startActivityIndicator];
        [self.view addSubview:clearView];
        [NSThread detachNewThreadSelector:@selector(startClearAppDiskCache:) toTarget:self withObject:clearView];
    }

    int bottomPadding = [Utilities getBottomPadding];
    
    if (bottomPadding > 0) {
        frame = volumeSliderView.frame;
        frame.origin.y -= bottomPadding;
        volumeSliderView.frame = frame;
        
        frame = powerButton.frame;
        frame.origin.y -= bottomPadding;
        powerButton.frame = frame;
        
        frame = xbmcInfo.frame;
        frame.origin.y -= bottomPadding;
        xbmcInfo.frame = frame;
        
        frame = xbmcLogo.frame;
        frame.origin.y -= bottomPadding;
        xbmcLogo.frame = frame;
    }

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleXBMCServerHasChanged:)
                                                 name: @"XBMCServerHasChanged"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleStackScrollOnScreen:)
                                                 name: @"StackScrollOnScreen"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleStackScrollOffScreen:)
                                                 name: @"StackScrollOffScreen"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleWillResignActive:)
                                                 name: @"UIApplicationWillResignActiveNotification"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleDidEnterBackground:)
                                                 name: @"UIApplicationDidEnterBackgroundNotification"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnterForeground:)
                                                 name: @"UIApplicationWillEnterForegroundNotification"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleTcpJSONRPCShowSetup:)
                                                 name: @"TcpJSONRPCShowSetup"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleTcpJSONRPCChangeServerStatus:)
                                                 name: @"TcpJSONRPCChangeServerStatus"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(connectionStatus:)
                                                 name: @"XBMCServerConnectionSuccess"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(connectionStatus:)
                                                 name: @"XBMCServerConnectionFailed"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleStackScrollFullScreenEnabled:)
                                                 name: @"StackScrollFullScreenEnabled"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleStackScrollFullScreenDisabled:)
                                                 name: @"StackScrollFullScreenDisabled"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleChangeBackgroundGradientColor:)
                                                 name: @"UIViewChangeBackgroundGradientColor"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleChangeBackgroundImage:)
                                                 name: @"UIViewChangeBackgroundImage"
                                               object: nil];
    
    [(gradientUIView*)self.view setColoursWithCGColors:[Utilities getGrayColor:36 alpha:1].CGColor
                                               endColor:[Utilities getGrayColor:22 alpha:1].CGColor];
}

- (void)handleChangeBackgroundImage:(NSNotification*)sender {
    [UIView transitionWithView: fanartBackgroundImage
                      duration: 1.0
                       options: UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^{
                        fanartBackgroundImage.image = [sender.userInfo objectForKey:@"image"];
                    }
                    completion: NULL];
}

- (void)handleChangeBackgroundGradientColor:(NSNotification*)sender {
    UIColor *startColor = (UIColor*)[sender.userInfo objectForKey:@"startColor"];
    UIColor *endColor = (UIColor*)[sender.userInfo objectForKey:@"endColor"];
    [(gradientUIView*)self.view setColoursWithCGColors:startColor.CGColor endColor:endColor.CGColor];
    [(gradientUIView*)self.view setNeedsDisplay];
}

- (void)handleStackScrollFullScreenEnabled:(NSNotification*)sender {
    stackScrollIsFullscreen = YES;
}

- (void)handleStackScrollFullScreenDisabled:(NSNotification*)sender {
    stackScrollIsFullscreen = NO;
}

- (void)handleTcpJSONRPCShowSetup:(NSNotification*)sender {
    BOOL showValue = [[sender.userInfo objectForKey:@"showSetup"] boolValue];
    if ((showValue && firstRun) || !showValue) {
        [self showSetup:showValue];
    }
}

- (void)handleTcpJSONRPCChangeServerStatus:(NSNotification*)sender {
    BOOL statusValue = [[sender.userInfo objectForKey:@"status"] boolValue];
    NSString *message = [sender.userInfo objectForKey:@"message"];
    NSString *icon_connection = [sender.userInfo objectForKey:@"icon_connection"];
    [self changeServerStatus:statusValue infoText:message icon:icon_connection];
}

- (void)hideSongInfoView {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.2];
    self.nowPlayingController.songDetailsView.alpha = 0.0;
    self.nowPlayingController.itemDescription.scrollsToTop = NO;
    [UIView commitAnimations];
}

- (void)handleStackScrollOnScreen:(NSNotification*)sender {
    [self.view insertSubview:self.nowPlayingController.BottomView belowSubview:rootView];
    [self hideSongInfoView];
}

- (void)handleStackScrollOffScreen:(NSNotification*)sender {
    stackScrollIsFullscreen = NO;
    [self.view insertSubview:self.nowPlayingController.BottomView aboveSubview:rootView];
}

- (void)handleXBMCServerHasChanged:(NSNotification*)sender {
    [AppDelegate.instance.windowController.stackScrollViewController offView];
    NSIndexPath *selection = [menuViewController.tableView indexPathForSelectedRow];
    if (selection) {
        [menuViewController.tableView deselectRowAtIndexPath:selection animated:YES];
        [menuViewController setLastSelected:-1];
    }
    [self changeServerStatus:NO infoText:LOCALIZED_STR(@"No connection") icon:@"connection_off"];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
}

- (void)handleWillResignActive:(NSNotification*)sender {
    [self.tcpJSONRPCconnection stopNetworkCommunication];
}

- (void)handleDidEnterBackground:(NSNotification*)sender {
    [self.tcpJSONRPCconnection stopNetworkCommunication];
}

- (void)handleEnterForeground:(NSNotification*)sender {
    if (AppDelegate.instance.serverOnLine) {
        if (self.tcpJSONRPCconnection == nil) {
            self.tcpJSONRPCconnection = [tcpJSONRPC new];
        }
        [self.tcpJSONRPCconnection startNetworkCommunicationWithServer:AppDelegate.instance.obj.serverIP serverPort:AppDelegate.instance.obj.tcpPort];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // save state for restoration after rotation and close popups
    if (self.hostPickerViewController.isViewLoaded && self.hostPickerViewController.view.window != nil) {
        serverPicker = YES;
        [self.hostPickerViewController dismissViewControllerAnimated:NO completion:nil];
    }
    if (self.appInfoView.isViewLoaded && self.appInfoView.view.window != nil) {
        appInfo = YES;
        [self.appInfoView dismissViewControllerAnimated:NO completion:nil];
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [menuViewController viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
        [stackScrollViewController viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    }
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // restore state
        if (serverPicker) {
            serverPicker = NO;
            [self toggleSetup];
        }
        if (appInfo) {
            appInfo = NO;
            [self toggleInfoView];
        }
    }];
}

- (CGSize)screenSizeOrientationIndependent {
    return UIScreen.mainScreen.fixedCoordinateSpace.bounds.size;
}

- (CGRect)currentScreenBoundsDependOnOrientation {
    return UIScreen.mainScreen.bounds;
}

- (void)viewWillLayoutSubviews {
    [self.nowPlayingController setNowPlayingDimension:[self currentScreenBoundsDependOnOrientation].size.width height:[self currentScreenBoundsDependOnOrientation].size.height YPOS:-YPOS];
}

- (BOOL)shouldAutorotate {
    return !stackScrollIsFullscreen;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
     return UIInterfaceOrientationMaskAll;
}

@end
