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
#define XBMCLOGO_WIDTH 87
#define POWERBUTTON_WIDTH 42

@interface ViewControllerIPad () {
    NSMutableArray *mainMenu;
}
@end

@interface UIViewExt : UIView {} 
@end


@implementation UIViewExt
- (UIView *) hitTest: (CGPoint) pt withEvent: (UIEvent *) event {   
	
	UIView* viewToReturn = nil;
	CGPoint pointToReturn;
	
	UIView* uiRightView = (UIView*)[self subviews][1];
	
	if ([uiRightView subviews][0]) {
		
		UIView* uiStackScrollView = [uiRightView subviews][0];
		
		if ([uiStackScrollView subviews][1]) {
			
			UIView* uiSlideView = [uiStackScrollView subviews][1];
			
			for (UIView* subView in [uiSlideView subviews]) {
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - ServerManagement

-(void)selectServerAtIndexPath:(NSIndexPath *)indexPath{
    storeServerSelection = indexPath;
    NSDictionary *item = [AppDelegate instance].arrayServerList[indexPath.row];
    [AppDelegate instance].obj.serverDescription = item[@"serverDescription"];
    [AppDelegate instance].obj.serverUser = item[@"serverUser"];
    [AppDelegate instance].obj.serverPass = item[@"serverPass"];
    [AppDelegate instance].obj.serverIP = item[@"serverIP"];
    [AppDelegate instance].obj.serverPort = item[@"serverPort"];
    [AppDelegate instance].obj.tcpPort = [item[@"tcpPort"] intValue];
}

-(void)wakeUp:(NSString *)macAddress{
    [[AppDelegate instance] sendWOL:macAddress withPort:9];
}

-(void)changeServerStatus:(BOOL)status infoText:(NSString *)infoText icon:(NSString *)iconName {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   infoText, @"message",
                                   iconName, @"icon_connection",
                                   nil];
    if (status) {
        [self.tcpJSONRPCconnection startNetworkCommunicationWithServer:[AppDelegate instance].obj.serverIP serverPort:[AppDelegate instance].obj.tcpPort];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerConnectionSuccess" object:nil userInfo:params];
        [AppDelegate instance].serverOnLine = YES;
        [AppDelegate instance].serverName = infoText;
        [volumeSliderView startTimer];
        [xbmcInfo setTitle:infoText forState:UIControlStateNormal];
        NSInteger n = [menuViewController.tableView numberOfRowsInSection:0];
        for (int i = 1; i < n; i++) {
            UITableViewCell *cell = [menuViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if (cell != nil) {
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.3];
                [(UIImageView*) [cell viewWithTag:1] setAlpha:1.0];
                [(UIImageView*) [cell viewWithTag:2] setAlpha:1.0];
                [(UIImageView*) [cell viewWithTag:3] setAlpha:1.0];
                [UIView commitAnimations];
            }
        }
    }
    else {
        [self.tcpJSONRPCconnection stopNetworkCommunication];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerConnectionFailed" object:nil userInfo:params];
        [AppDelegate instance].serverOnLine = NO;
        [AppDelegate instance].serverName = infoText;
        [xbmcInfo setTitle:infoText forState:UIControlStateNormal];
        NSInteger n = [menuViewController.tableView numberOfRowsInSection:0];
        for (int i = 1; i < n; i++) {
            UITableViewCell *cell = [menuViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if (cell != nil) {
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.3];
                
                [(UIImageView*) [cell viewWithTag:1] setAlpha:0.3];
                [(UIImageView*) [cell viewWithTag:2] setAlpha:0.3];
                [(UIImageView*) [cell viewWithTag:3] setAlpha:0.3];
                [UIView commitAnimations];
            }
        }
        if (![extraTimer isValid])
            extraTimer = [NSTimer scheduledTimerWithTimeInterval:CONNECTION_TIMEOUT target:self selector:@selector(offStackView) userInfo:nil repeats:NO];
    }
}

-(void) offStackView{
    if (![AppDelegate instance].serverOnLine) {
        [[AppDelegate instance].windowController.stackScrollViewController offView];
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

-(void)toggleViewToolBar:(UIView*)view AnimDuration:(NSTimeInterval)seconds Alpha:(CGFloat)alphavalue YPos:(int)Y forceHide:(BOOL)hide {
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:seconds];
    int actualPosY = view.frame.origin.y;
    CGRect frame;
	frame = [view frame];
    if (actualPosY < 667 || hide) {
        Y = self.view.frame.size.height;
    }
    view.alpha = alphavalue;
	frame.origin.y = Y;
    view.frame = frame;
    [UIView commitAnimations];
}

- (void)toggleVolume{
    [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:volumeSliderView.frame.origin.y - volumeSliderView.frame.size.height - 42 forceHide:NO];
}

-(void)initHostManagemetPopOver{
    self.hostPickerViewController = [[HostManagementViewController alloc] initWithNibName:@"HostManagementViewController" bundle:nil];
    [AppDelegate instance].navigationController = [[CustomNavigationController alloc] initWithRootViewController:_hostPickerViewController];
    [[AppDelegate instance].navigationController hideNavBarBottomLine:YES];
}

- (void)toggleSetup {
    if (_hostPickerViewController == nil) {
        [self initHostManagemetPopOver];
    }
    [[AppDelegate instance].navigationController setModalPresentationStyle:UIModalPresentationPopover];
    UIPopoverPresentationController *popPresenter = [[AppDelegate instance].navigationController popoverPresentationController];
    if (popPresenter != nil) {
        popPresenter.sourceView = self.view;
        popPresenter.sourceRect = xbmcInfo.frame;
    }
    if (![[AppDelegate instance].navigationController isBeingPresented]) {
        [self presentViewController:[AppDelegate instance].navigationController animated:YES completion:nil];
    }
}

-(void) showSetup:(BOOL)show{
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
    if (_appInfoView == nil) {
        self.appInfoView = [[AppInfoViewController alloc] initWithNibName:@"AppInfoViewController" bundle:nil];
        [self.appInfoView setModalPresentationStyle:UIModalPresentationPopover];
    }
    UIPopoverPresentationController *popPresenter = [self.appInfoView popoverPresentationController];
    if (popPresenter != nil) {
        popPresenter.sourceView = self.view;
        popPresenter.sourceRect = xbmcLogo.frame;
    }
    [self presentViewController:self.appInfoView animated:YES completion:nil];
}

#pragma mark - power control action sheet

-(void)powerControl{
    if ([[AppDelegate instance].obj.serverIP length] == 0) {
        [self toggleSetup];
        return;
    }
    NSString *title = [NSString stringWithFormat:@"%@\n%@", [AppDelegate instance].obj.serverDescription, [AppDelegate instance].obj.serverIP];
    UIAlertController *actionView = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (![AppDelegate instance].serverOnLine) {
        UIAlertAction* action_wake = [UIAlertAction actionWithTitle:NSLocalizedString(@"Wake On Lan", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            if ([AppDelegate instance].obj.serverHWAddr != nil) {
                [self wakeUp:[AppDelegate instance].obj.serverHWAddr];
                UIAlertController *alertView = [Utilities createAlertOK:NSLocalizedString(@"Command executed", nil) message:nil];
                [self presentViewController:alertView animated:YES completion:nil];
            }
            else {
                UIAlertController *alertView = [Utilities createAlertOK:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"No server MAC address defined", nil)];
                [self presentViewController:alertView animated:YES completion:nil];
            }
        }];
        [actionView addAction:action_wake];
    }
    else {
        UIAlertAction* action_pwr_off_system = [UIAlertAction actionWithTitle:NSLocalizedString(@"Power off System", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            [self powerAction:@"System.Shutdown" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_pwr_off_system];
        
        UIAlertAction* action_quit_kodi = [UIAlertAction actionWithTitle:NSLocalizedString(@"Quit XBMC application", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self powerAction:@"Application.Quit" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_quit_kodi];
        
        UIAlertAction* action_hibernate = [UIAlertAction actionWithTitle:NSLocalizedString(@"Hibernate", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self powerAction:@"System.Hibernate" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_hibernate];
        
        UIAlertAction* action_suspend = [UIAlertAction actionWithTitle:NSLocalizedString(@"Suspend", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self powerAction:@"System.Suspend" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_suspend];
        
        UIAlertAction* action_reboot = [UIAlertAction actionWithTitle:NSLocalizedString(@"Reboot", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self powerAction:@"System.Reboot" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_reboot];
        
        UIAlertAction* action_scan_audio_lib = [UIAlertAction actionWithTitle:NSLocalizedString(@"Update Audio Library", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self powerAction:@"AudioLibrary.Scan" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_scan_audio_lib];
        
        UIAlertAction* action_clean_audio_lib = [UIAlertAction actionWithTitle:NSLocalizedString(@"Clean Audio Library", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self powerAction:@"AudioLibrary.Clean" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_clean_audio_lib];
        
        UIAlertAction* action_scan_video_lib = [UIAlertAction actionWithTitle:NSLocalizedString(@"Update Video Library", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self powerAction:@"VideoLibrary.Scan" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_scan_video_lib];
        
        UIAlertAction* action_clean_video_lib = [UIAlertAction actionWithTitle:NSLocalizedString(@"Clean Video Library", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self powerAction:@"VideoLibrary.Clean" params:[NSDictionary dictionary]];
        }];
        [actionView addAction:action_clean_video_lib];
    }
    
    UIAlertAction* cancelButton = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];
    [actionView addAction:cancelButton];
    [actionView setModalPresentationStyle:UIModalPresentationPopover];
    
    UIPopoverPresentationController *popPresenter = [actionView popoverPresentationController];
    if (popPresenter != nil) {
        popPresenter.sourceView = powerButton;
        popPresenter.sourceRect = powerButton.bounds;
    }
    [self presentViewController:actionView animated:YES completion:nil];
}

-(void)powerAction:(NSString *)action params:(NSDictionary *)params{
    [[Utilities getJsonRPC] callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        NSString *alertTitle = nil;
        if (methodError == nil && error == nil) {
            alertTitle = NSLocalizedString(@"Command executed", nil);
        }
        else {
            alertTitle = NSLocalizedString(@"Cannot do that", nil);
        }
        UIAlertController *alertView = [Utilities createAlertOK:alertTitle message:nil];
        [self presentViewController:alertView animated:YES completion:nil];
    }];
}

#pragma mark - Touch Events

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint locationPoint = [[touches anyObject] locationInView:self.view];
    CGPoint viewPoint = [self.nowPlayingController.jewelView convertPoint:locationPoint fromView:self.view];
    CGPoint viewPoint4 = [self.nowPlayingController.itemLogoImage convertPoint:locationPoint fromView:self.view];

    if ([self.nowPlayingController.itemLogoImage pointInside:viewPoint4 withEvent:event] && self.nowPlayingController.songDetailsView.alpha > 0 && self.nowPlayingController.itemLogoImage.image != nil) {
        [self.nowPlayingController updateCurrentLogo];
    }
    else if ([self.nowPlayingController.jewelView pointInside:viewPoint withEvent:event] && ![[AppDelegate instance].windowController.stackScrollViewController.viewControllersStack count]) {
        [self.nowPlayingController toggleSongDetails];
    }
}

#pragma mark - App clear disk cache methods

-(void)startClearAppDiskCache:(ClearCacheView *)clearView{
    [[AppDelegate instance] clearAppDiskCache];
    [self performSelectorOnMainThread:@selector(clearAppDiskCacheFinished:) withObject:clearView waitUntilDone:YES];
}

-(void)clearAppDiskCacheFinished:(ClearCacheView *)clearView{
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

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    int deltaY = 22;
    [self setNeedsStatusBarAppearanceUpdate];
    self.view.tintColor = APP_TINT_COLOR;
    self.tcpJSONRPCconnection = [[tcpJSONRPC alloc] init];
    XBMCVirtualKeyboard *virtualKeyboard = [[XBMCVirtualKeyboard alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    [self.view addSubview:virtualKeyboard];
    firstRun = YES;
    [AppDelegate instance].obj = [GlobalData getInstance]; 

    int cellHeight = PAD_MENU_HEIGHT;
    int infoHeight = PAD_MENU_INFO_HEIGHT;
    NSInteger tableHeight = ([(NSMutableArray *)mainMenu count] - 1) * cellHeight + infoHeight;
    int tableWidth = PAD_MENU_TABLE_WIDTH;
    int headerHeight = 0;
   
    rootView = [[UIViewExt alloc] initWithFrame:CGRectMake(0, deltaY, self.view.frame.size.width, self.view.frame.size.height - deltaY - 1)];
	rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
	[rootView setBackgroundColor:[UIColor clearColor]];
	
    fanartBackgroundImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    fanartBackgroundImage.autoresizingMask = rootView.autoresizingMask;
    fanartBackgroundImage.contentMode = UIViewContentModeScaleAspectFill;
    fanartBackgroundImage.alpha = 0.05;
    [self.view addSubview:fanartBackgroundImage];
    
	leftMenuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableWidth, self.view.frame.size.height)];
	leftMenuView.autoresizingMask = UIViewAutoresizingFlexibleHeight;	
    
	menuViewController = [[MenuViewController alloc] initWithFrame:CGRectMake(0, headerHeight, leftMenuView.frame.size.width, leftMenuView.frame.size.height) mainMenu:mainMenu];
	[menuViewController.view setBackgroundColor:[UIColor clearColor]];
	[menuViewController viewWillAppear:NO];
	[menuViewController viewDidAppear:NO];
	[leftMenuView addSubview:menuViewController.view];
    int separator = 2;
    
//    CGRect seamBackground = CGRectMake(0, tableHeight + headerHeight - 2, tableWidth, separator);
//    UIImageView *seam = [[UIImageView alloc] initWithFrame:seamBackground];
//    [seam setImage:[UIImage imageNamed:@"denim_single_seam"]];
//    seam.opaque = YES;
//    [leftMenuView addSubview:seam];
    
    UIView* horizontalLineView1 = [[UIView alloc] initWithFrame:CGRectMake(0, tableHeight + separator - 2, tableWidth, 1)];
//    [horizontalLineView1 setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [horizontalLineView1 setBackgroundColor:[Utilities getGrayColor:77 alpha:0.2]];
    [leftMenuView addSubview:horizontalLineView1];

    self.nowPlayingController = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
    CGRect frame = self.nowPlayingController.view.frame;
    YPOS = (int)-(tableHeight + separator + headerHeight);
    frame.origin.y = tableHeight + separator + headerHeight;
    frame.size.width = tableWidth;
    frame.size.height = self.view.frame.size.height - tableHeight - separator - headerHeight - deltaY;
    self.nowPlayingController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.nowPlayingController.view.frame = frame;
    
    [self.nowPlayingController setNowPlayingDimension:[self screenSizeOrientationIndependent].width height:[self screenSizeOrientationIndependent].height YPOS:YPOS];
    
    [leftMenuView addSubview:self.nowPlayingController.view];

	rightSlideView = [[UIView alloc] initWithFrame:CGRectMake(leftMenuView.frame.size.width, 0, rootView.frame.size.width - leftMenuView.frame.size.width, rootView.frame.size.height - TOOLBAR_HEIGHT)];
	rightSlideView.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
    
	stackScrollViewController = [[StackScrollViewController alloc] init];	
	[stackScrollViewController.view setFrame:CGRectMake(0, 0, rightSlideView.frame.size.width, rightSlideView.frame.size.height)];
	[stackScrollViewController.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight];
	[stackScrollViewController viewWillAppear:NO];
	[stackScrollViewController viewDidAppear:NO];
	[rightSlideView addSubview:stackScrollViewController.view];
	
	[rootView addSubview:leftMenuView];
	[rootView addSubview:rightSlideView];
    
    [self.view addSubview:rootView];
    
    // left most element
    volumeSliderView = [[VolumeSliderView alloc] initWithFrame:CGRectMake(leftMenuView.frame.size.width, self.view.frame.size.height - TOOLBAR_HEIGHT, 0, TOOLBAR_HEIGHT)];
    volumeSliderView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:volumeSliderView];
    
    // right most element
    UIImage *image = [UIImage imageNamed:@"bottom_logo_up"];
    xbmcLogo = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - XBMCLOGO_WIDTH - VIEW_PADDING, self.view.frame.size.height - TOOLBAR_HEIGHT, XBMCLOGO_WIDTH, TOOLBAR_HEIGHT)];
    [xbmcLogo setImage:image forState:UIControlStateNormal];
    [xbmcLogo setImage:image forState:UIControlStateHighlighted];
    xbmcLogo.showsTouchWhenHighlighted = NO;
    [xbmcLogo addTarget:self action:@selector(toggleInfoView) forControlEvents:UIControlEventTouchUpInside];
    xbmcLogo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    xbmcLogo.alpha = 0.9;
    [self.view addSubview:xbmcLogo];
    
    // 2nd right most element
    image = [UIImage imageNamed:@"icon_power_up"];
    powerButton = [[UIButton alloc] initWithFrame:CGRectMake(xbmcLogo.frame.origin.x - POWERBUTTON_WIDTH - VIEW_PADDING, self.view.frame.size.height - TOOLBAR_HEIGHT, POWERBUTTON_WIDTH, TOOLBAR_HEIGHT)];
    [powerButton setImage:image forState:UIControlStateNormal];
    [powerButton setImage:image forState:UIControlStateHighlighted];
    powerButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [powerButton addTarget:self action:@selector(powerControl) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:powerButton];
    
    // element between left most and 2nd right most uses up free space
    CGFloat startInfo = volumeSliderView.frame.origin.x + volumeSliderView.frame.size.width + VIEW_PADDING;
    CGFloat widthInfo = powerButton.frame.origin.x - startInfo - VIEW_PADDING;
    xbmcInfo = [[UIButton alloc] initWithFrame:CGRectMake(startInfo, self.view.frame.size.height - TOOLBAR_HEIGHT, widthInfo, TOOLBAR_HEIGHT)];
    [xbmcInfo setTitle:NSLocalizedString(@"No connection", nil) forState:UIControlStateNormal];
    xbmcInfo.titleLabel.font = [UIFont systemFontOfSize:13];
    xbmcInfo.titleLabel.minimumScaleFactor = 6.0 / 13.0;
    xbmcInfo.titleLabel.numberOfLines = 2;
    xbmcInfo.titleLabel.textAlignment = NSTextAlignmentCenter;
    xbmcInfo.titleEdgeInsets = UIEdgeInsetsZero;
    xbmcInfo.titleLabel.shadowColor = [UIColor blackColor];
    xbmcInfo.titleLabel.shadowOffset = CGSizeZero;
    xbmcInfo.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [xbmcInfo addTarget:self action:@selector(toggleSetup) forControlEvents:UIControlEventTouchUpInside];
    [xbmcInfo setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [xbmcInfo setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
    [self.view addSubview:xbmcInfo];
    
    menuViewController.tableView.separatorInset = UIEdgeInsetsZero;
    
    [self.view insertSubview:self.nowPlayingController.scrabbingView aboveSubview:rootView];
    [self.view insertSubview:self.nowPlayingController.songDetailsView aboveSubview:rootView];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL clearCache = [[userDefaults objectForKey:@"clearcache_preference"] boolValue];
    if (clearCache) {
        ClearCacheView *clearView = [[ClearCacheView alloc] initWithFrame:self.view.frame];
        [clearView startActivityIndicator];
        [self.view addSubview:clearView];
        [NSThread detachNewThreadSelector:@selector(startClearAppDiskCache:) toTarget:self withObject:clearView];
    }

    int bottomPadding = 0;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        bottomPadding = window.safeAreaInsets.bottom;
    }
    
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
    
    [self initHostManagemetPopOver];
    
    [(gradientUIView *)self.view setColoursWithCGColors:[Utilities getGrayColor:36 alpha:1].CGColor
                                               endColor:[Utilities getGrayColor:22 alpha:1].CGColor];
}

-(void)handleChangeBackgroundImage:(NSNotification *)sender {
    [UIView transitionWithView: fanartBackgroundImage
                      duration: 1.0
                       options: UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^{
                        [fanartBackgroundImage setImage:[[sender userInfo] valueForKey:@"image"]];
                    }
                    completion: NULL];
}

-(void)handleChangeBackgroundGradientColor:(NSNotification *)sender{
    UIColor *startColor = (UIColor *)[[sender userInfo] valueForKey:@"startColor"];
    UIColor *endColor = (UIColor *)[[sender userInfo] valueForKey:@"endColor"];
    [(gradientUIView *)self.view setColoursWithCGColors:startColor.CGColor endColor:endColor.CGColor];
    [(gradientUIView *)self.view setNeedsDisplay];
}

-(void)handleStackScrollFullScreenEnabled:(NSNotification *)sender{
    stackScrollIsFullscreen = YES;
}

-(void)handleStackScrollFullScreenDisabled:(NSNotification *)sender{
    stackScrollIsFullscreen = NO;
}

-(void)handleTcpJSONRPCShowSetup:(NSNotification *)sender{
    BOOL showValue = [[[sender userInfo] valueForKey:@"showSetup"] boolValue];
    if ((showValue && firstRun) || !showValue) {
        [self showSetup:showValue];
    }
}

-(void)handleTcpJSONRPCChangeServerStatus:(NSNotification*) sender{
    BOOL statusValue = [[[sender userInfo] valueForKey:@"status"] boolValue];
    NSString *message = [[sender userInfo] valueForKey:@"message"];
    NSString *icon_connection = [[sender userInfo] valueForKey:@"icon_connection"];
    [self changeServerStatus:statusValue infoText:message icon:icon_connection];
}

- (void)hideSongInfoView {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.2];
    self.nowPlayingController.songDetailsView.alpha = 0.0;
    [self.nowPlayingController.itemDescription setScrollsToTop:NO];
    [UIView commitAnimations];
}

- (void)handleStackScrollOnScreen: (NSNotification*) sender{
    [self.view insertSubview:self.nowPlayingController.ProgressSlider belowSubview:rootView];
    [self hideSongInfoView];
}

- (void)handleStackScrollOffScreen: (NSNotification*) sender{
    stackScrollIsFullscreen = NO;
    [self.view insertSubview:self.nowPlayingController.ProgressSlider aboveSubview:rootView];
}

- (void) handleXBMCServerHasChanged: (NSNotification*) sender{
    [[AppDelegate instance].windowController.stackScrollViewController offView];
    NSIndexPath *selection = [menuViewController.tableView indexPathForSelectedRow];
    if (selection) {
        [menuViewController.tableView deselectRowAtIndexPath:selection animated:YES];
        [menuViewController setLastSelected:-1];
    }
    [self changeServerStatus:NO infoText:NSLocalizedString(@"No connection", nil) icon:@"connection_off"];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
}

- (void) handleWillResignActive: (NSNotification*) sender{
    [self.tcpJSONRPCconnection stopNetworkCommunication];
}

- (void) handleDidEnterBackground: (NSNotification*) sender{
    [self.tcpJSONRPCconnection stopNetworkCommunication];
}

- (void) handleEnterForeground: (NSNotification*) sender{
    if ([AppDelegate instance].serverOnLine) {
        if (self.tcpJSONRPCconnection == nil) {
            self.tcpJSONRPCconnection = [[tcpJSONRPC alloc] init];
        }
        [self.tcpJSONRPCconnection startNetworkCommunicationWithServer:[AppDelegate instance].obj.serverIP serverPort:[AppDelegate instance].obj.tcpPort];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
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

-(CGSize)screenSizeOrientationIndependent {
    return UIScreen.mainScreen.fixedCoordinateSpace.bounds.size;
}

-(CGRect)currentScreenBoundsDependOnOrientation {
    return UIScreen.mainScreen.bounds;
}

- (void)viewWillLayoutSubviews{
    [self.nowPlayingController setNowPlayingDimension:[self currentScreenBoundsDependOnOrientation].size.width height:[self currentScreenBoundsDependOnOrientation].size.height YPOS:YPOS];
}

-(BOOL)shouldAutorotate{
    return !stackScrollIsFullscreen;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
     return UIInterfaceOrientationMaskAll;
 }

@end
