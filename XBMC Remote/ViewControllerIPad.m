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

#define CONNECTION_TIMEOUT 240.0f
#define SERVER_TIMEOUT 2.0f

@interface ViewControllerIPad (){
    NSMutableArray *mainMenu;
}
@end

@interface UIViewExt : UIView {} 
@end


@implementation UIViewExt
- (UIView *) hitTest: (CGPoint) pt withEvent: (UIEvent *) event {   
	
	UIView* viewToReturn=nil;
	CGPoint pointToReturn;
	
	UIView* uiRightView = (UIView*)[[self subviews] objectAtIndex:1];
	
	if ([[uiRightView subviews] objectAtIndex:0]) {
		
		UIView* uiStackScrollView = [[uiRightView subviews] objectAtIndex:0];	
		
		if ([[uiStackScrollView subviews] objectAtIndex:1]) {	 
			
			UIView* uiSlideView = [[uiStackScrollView subviews] objectAtIndex:1];	
			
			for (UIView* subView in [uiSlideView subviews]) {
				CGPoint point  = [subView convertPoint:pt fromView:self];
				if ([subView pointInside:point withEvent:event]) {
					viewToReturn = subView;
					pointToReturn = point;
				}
				
			}
		}
		
	}
	
	if(viewToReturn != nil) {
		return [viewToReturn hitTest:pointToReturn withEvent:event];		
	}
	
	return [super hitTest:pt withEvent:event];	
	
}
@end



@implementation ViewControllerIPad

@synthesize mainMenu;
@synthesize menuViewController, stackScrollViewController;
@synthesize nowPlayingController;
@synthesize serverPickerPopover = _serverPickerPopover;
@synthesize hostPickerViewController = _hostPickerViewController;
@synthesize appInfoView = _appInfoView;
@synthesize appInfoPopover = _appInfoPopover;
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
    NSDictionary *item = [[AppDelegate instance].arrayServerList objectAtIndex:indexPath.row];
    [AppDelegate instance].obj.serverDescription = [item objectForKey:@"serverDescription"];
    [AppDelegate instance].obj.serverUser = [item objectForKey:@"serverUser"];
    [AppDelegate instance].obj.serverPass = [item objectForKey:@"serverPass"];
    [AppDelegate instance].obj.serverIP = [item objectForKey:@"serverIP"];
    [AppDelegate instance].obj.serverPort = [item objectForKey:@"serverPort"];
    [AppDelegate instance].obj.tcpPort = [[item objectForKey:@"tcpPort"] intValue];
}

-(void)wakeUp:(NSString *)macAddress{
    [[AppDelegate instance] sendWOL:macAddress withPort:9];
}

-(void)changeServerStatus:(BOOL)status infoText:(NSString *)infoText icon:(NSString *)iconName {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   infoText, @"message",
                                   iconName, @"icon_connection",
                                   nil];
    if (status == YES) {
        [self.tcpJSONRPCconnection startNetworkCommunicationWithServer:[AppDelegate instance].obj.serverIP serverPort:[AppDelegate instance].obj.tcpPort];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerConnectionSuccess" object:nil userInfo:params];
        [AppDelegate instance].serverOnLine=YES;
        [AppDelegate instance].serverName = infoText;
        [volumeSliderView startTimer];
        [xbmcInfo setTitle:infoText forState:UIControlStateNormal];
        NSInteger n = [menuViewController.tableView numberOfRowsInSection:0];
        for (int i=1;i<n;i++){
            UITableViewCell *cell = [menuViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if (cell!=nil){
                cell.selectionStyle=UITableViewCellSelectionStyleBlue;
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.3];
                [(UIImageView*) [cell viewWithTag:1] setAlpha:1.0];
                [(UIImageView*) [cell viewWithTag:2] setAlpha:1.0];
                [(UIImageView*) [cell viewWithTag:3] setAlpha:1.0];
                [UIView commitAnimations];
            }
        }
    }
    else{
        [self.tcpJSONRPCconnection stopNetworkCommunication];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerConnectionFailed" object:nil userInfo:params];
        [AppDelegate instance].serverOnLine=NO;
        [AppDelegate instance].serverName = infoText;
        [xbmcInfo setTitle:infoText forState:UIControlStateNormal];
        NSInteger n = [menuViewController.tableView numberOfRowsInSection:0];
        for (int i=1;i<n;i++){
            UITableViewCell *cell = [menuViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if (cell!=nil){
                cell.selectionStyle=UITableViewCellSelectionStyleGray;
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
    if (![AppDelegate instance].serverOnLine){
        [[AppDelegate instance].windowController.stackScrollViewController offView];
        NSIndexPath *selection=[menuViewController.tableView indexPathForSelectedRow];
        if (selection){
            [menuViewController.tableView deselectRowAtIndexPath:selection animated:YES];
            [menuViewController setLastSelected:-1];
        }
    }
    [extraTimer invalidate];
    extraTimer = nil;
}

# pragma mark - toolbar management

-(void)toggleViewToolBar:(UIView*)view AnimDuration:(float)seconds Alpha:(float)alphavalue YPos:(int)Y forceHide:(BOOL)hide {
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:seconds];
    int actualPosY=view.frame.origin.y;
    CGRect frame;
	frame = [view frame];
    if (actualPosY<667 || hide){
        Y=self.view.frame.size.height;
    }
    view.alpha = alphavalue;
	frame.origin.y = Y;
    view.frame = frame;
    [UIView commitAnimations];
}

- (void)toggleVolume{
    [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:volumeSliderView.frame.origin.y - volumeSliderView.frame.size.height - 42 forceHide:FALSE];
}

-(void)initHostManagemetPopOver{
    self.hostPickerViewController = [[HostManagementViewController alloc] initWithNibName:@"HostManagementViewController" bundle:nil];
    [AppDelegate instance].navigationController = [[CustomNavigationController alloc] initWithRootViewController:_hostPickerViewController];
    [[AppDelegate instance].navigationController hideNavBarBottomLine:YES];
    self.serverPickerPopover = [[UIPopoverController alloc]
                                initWithContentViewController:[AppDelegate instance].navigationController];
    self.serverPickerPopover.delegate = self;
    [self.serverPickerPopover setBackgroundColor:[UIColor clearColor]];
    [self.serverPickerPopover setPopoverContentSize:CGSizeMake(320, 436)];
}

- (void)toggleSetup {
    if (_hostPickerViewController == nil) {
        [self initHostManagemetPopOver];
    }
    [self.serverPickerPopover presentPopoverFromRect:xbmcInfo.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(void) showSetup:(BOOL)show{
    firstRun = NO;
    if ([self.serverPickerPopover isPopoverVisible]) {
        if (show==NO)
            [self.serverPickerPopover dismissPopoverAnimated:YES];
    }
    else{
        if (show==YES){
            [self toggleSetup];
        }
    }
}

- (void)toggleInfoView {
    if (_appInfoView == nil) {
        self.appInfoView = [[AppInfoViewController alloc] initWithNibName:@"AppInfoViewController" bundle:nil];
        self.appInfoPopover = [[UIPopoverController alloc] 
                                    initWithContentViewController:_appInfoView];
        self.appInfoPopover.delegate = self;
        [self.appInfoPopover setPopoverContentSize:CGSizeMake(320, 460)];
        self.appInfoPopover.backgroundColor = [UIColor colorWithRed:187.0f/255.0f green:187.0f/255.0f blue:187.0f/255.0f alpha:1.0f];
    }
    [self.appInfoPopover presentPopoverFromRect:xbmcLogo.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}
#pragma mark - power control action sheet

-(void)powerControl{
    if ([[AppDelegate instance].obj.serverIP length]==0){
        [self toggleSetup];
        return;
    }
    NSString *title=[NSString stringWithFormat:@"%@\n%@", [AppDelegate instance].obj.serverDescription, [AppDelegate instance].obj.serverIP];
    NSString *destructive = nil;
    NSArray *sheetActions = nil;
    if (![AppDelegate instance].serverOnLine){
        sheetActions=[NSArray arrayWithObjects:NSLocalizedString(@"Wake On Lan", nil), nil];
    }
    else{
        destructive = NSLocalizedString(@"Power off System", nil);
        sheetActions=[NSArray arrayWithObjects:
                      NSLocalizedString(@"Hibernate", nil),
                      NSLocalizedString(@"Suspend", nil),
                      NSLocalizedString(@"Reboot", nil),
                      NSLocalizedString(@"Quit XBMC application", nil),
                      NSLocalizedString(@"Update Audio Library", nil),
                      NSLocalizedString(@"Clean Audio Library", nil),
                      NSLocalizedString(@"Update Video Library", nil),
                      NSLocalizedString(@"Clean Video Library", nil),  nil];
    }
    NSInteger numActions=[sheetActions count];
    if (numActions){
        actionSheetPower = [[UIActionSheet alloc] initWithTitle:title
                                                            delegate:self
                                                   cancelButtonTitle:nil
                                              destructiveButtonTitle:destructive
                                                   otherButtonTitles:nil];
        actionSheetPower.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        for (int i = 0; i < numActions; i++) {
            [actionSheetPower addButtonWithTitle:[sheetActions objectAtIndex:i]];
        }
        actionSheetPower.cancelButtonIndex = [actionSheetPower addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
       [actionSheetPower showFromRect:CGRectMake(powerButton.frame.origin.x + powerButton.frame.size.width/2, powerButton.frame.origin.y, 1, 1) inView:self.view animated:YES];
    }
}

-(void)powerAction:(NSString *)action params:(NSDictionary *)params{
    jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    [jsonRPC callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (methodError==nil && error == nil){
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Command executed", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
        }
        else{
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot do that", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
            [alertView show];
        }
    }];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex!=actionSheet.cancelButtonIndex){
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Wake On Lan", nil)]){
            if ([AppDelegate instance].obj.serverHWAddr != nil){
                [self wakeUp:[AppDelegate instance].obj.serverHWAddr];
                UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Command executed", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                [alertView show];
            }
            else{
                UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"No server MAC address defined", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                [alertView show];
            }
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Power off System", nil)]){
            [self powerAction:@"System.Shutdown" params:[NSDictionary dictionary]];
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Quit XBMC application", nil)]){
            [self powerAction:@"Application.Quit" params:[NSDictionary dictionary]];
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Hibernate", nil)]){
            [self powerAction:@"System.Hibernate" params:[NSDictionary dictionary]];
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Suspend", nil)]){
            [self powerAction:@"System.Suspend" params:[NSDictionary dictionary]];
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Reboot", nil)]){
            [self powerAction:@"System.Reboot" params:[NSDictionary dictionary]];
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Update Audio Library", nil)]){
            [self powerAction:@"AudioLibrary.Scan" params:[NSDictionary dictionary]];
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Clean Audio Library", nil)]){
            [self powerAction:@"AudioLibrary.Clean" params:[NSDictionary dictionary]];
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Update Video Library", nil)]){
            [self powerAction:@"VideoLibrary.Scan" params:[NSDictionary dictionary]];
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Clean Video Library", nil)]){
            [self powerAction:@"VideoLibrary.Clean" params:[NSDictionary dictionary]];
        }
    }
}

#pragma mark - Touch Events

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint locationPoint = [[touches anyObject] locationInView:self.view];
    CGPoint viewPoint = [self.nowPlayingController.jewelView convertPoint:locationPoint fromView:self.view];
    CGPoint viewPoint4 = [self.nowPlayingController.itemLogoImage convertPoint:locationPoint fromView:self.view];

    if ([self.nowPlayingController.itemLogoImage pointInside:viewPoint4 withEvent:event]  && self.nowPlayingController.songDetailsView.alpha > 0 && self.nowPlayingController.itemLogoImage.image != nil) {
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
                     completion:^(BOOL finished){
                         [clearView stopActivityIndicator];
                         [clearView removeFromSuperview];
                         NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                         [userDefaults synchronize];
                         [userDefaults removeObjectForKey:@"clearcache_preference"];
                     }];
}

#pragma mark - Lifecycle

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    int deltaY = 22.0f;
    [self setNeedsStatusBarAppearanceUpdate];
    self.view.tintColor = APP_TINT_COLOR;
    self.tcpJSONRPCconnection = [[tcpJSONRPC alloc] init];
    XBMCVirtualKeyboard *virtualKeyboard = [[XBMCVirtualKeyboard alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    [self.view addSubview:virtualKeyboard];
    firstRun=YES;
    [AppDelegate instance].obj=[GlobalData getInstance]; 

    int cellHeight = PAD_MENU_HEIGHT;
    int infoHeight = PAD_MENU_INFO_HEIGHT;
    NSInteger tableHeight = ([(NSMutableArray *)mainMenu count] - 1) * cellHeight + infoHeight;
    int tableWidth = PAD_MENU_TABLE_WIDTH;
    int headerHeight=0;
   
    rootView = [[UIViewExt alloc] initWithFrame:CGRectMake(0, deltaY, self.view.frame.size.width, self.view.frame.size.height - deltaY - 1)];
	rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
	[rootView setBackgroundColor:[UIColor clearColor]];
	
    fanartBackgroundImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    fanartBackgroundImage.autoresizingMask = rootView.autoresizingMask;
    fanartBackgroundImage.contentMode = UIViewContentModeScaleAspectFill;
    fanartBackgroundImage.alpha = 0.05f;
    [self.view addSubview:fanartBackgroundImage];
    
	leftMenuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableWidth, self.view.frame.size.height)];
	leftMenuView.autoresizingMask = UIViewAutoresizingFlexibleHeight;	
    
	menuViewController = [[MenuViewController alloc] initWithFrame:CGRectMake(0, headerHeight, leftMenuView.frame.size.width, leftMenuView.frame.size.height) mainMenu:mainMenu];
	[menuViewController.view setBackgroundColor:[UIColor clearColor]];
	[menuViewController viewWillAppear:FALSE];
	[menuViewController viewDidAppear:FALSE];
	[leftMenuView addSubview:menuViewController.view];
    int separator = 2;
    
//    CGRect seamBackground = CGRectMake(0.0f, tableHeight + headerHeight - 2, tableWidth, separator);
//    UIImageView *seam = [[UIImageView alloc] initWithFrame:seamBackground];
//    [seam setImage:[UIImage imageNamed:@"denim_single_seam.png"]];
//    seam.opaque = YES;
//    [leftMenuView addSubview:seam];
    
    UIView* horizontalLineView1 = [[UIView alloc] initWithFrame:CGRectMake(0.0f, tableHeight + separator - 2, tableWidth, 1)];
//    [horizontalLineView1 setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [horizontalLineView1 setBackgroundColor:[UIColor colorWithRed:0.3f green:0.3f blue:0.3f alpha:.2]];
    [leftMenuView addSubview:horizontalLineView1];

    self.nowPlayingController = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
    CGRect frame = self.nowPlayingController.view.frame;
    YPOS = (int)-(tableHeight + separator + headerHeight);
    frame.origin.y = tableHeight + separator + headerHeight;
    frame.size.width = tableWidth;
    frame.size.height=self.view.frame.size.height - tableHeight - separator - headerHeight - deltaY;
    self.nowPlayingController.view.autoresizingMask=UIViewAutoresizingFlexibleHeight;
    self.nowPlayingController.view.frame=frame;
    
    [self.nowPlayingController setToolbarWidth:[self screenSizeOrientationIndependent].width height:[self screenSizeOrientationIndependent].height - 414 YPOS:YPOS playBarWidth:1426 portrait:TRUE];
    
    [leftMenuView addSubview:self.nowPlayingController.view];

	rightSlideView = [[UIView alloc] initWithFrame:CGRectMake(leftMenuView.frame.size.width, 0, rootView.frame.size.width - leftMenuView.frame.size.width, rootView.frame.size.height-44)];
	rightSlideView.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
    
	stackScrollViewController = [[StackScrollViewController alloc] init];	
	[stackScrollViewController.view setFrame:CGRectMake(0, 0, rightSlideView.frame.size.width, rightSlideView.frame.size.height)];
	[stackScrollViewController.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight];
	[stackScrollViewController viewWillAppear:FALSE];
	[stackScrollViewController viewDidAppear:FALSE];
	[rightSlideView addSubview:stackScrollViewController.view];
	
	[rootView addSubview:leftMenuView];
	[rootView addSubview:rightSlideView];
    
//    self.view.backgroundColor = [UIColor colorWithWhite:.14 alpha:1];
//    self.view.backgroundColor = [[UIColor scrollViewTexturedBackgroundColor] colorWithAlphaComponent:0.5];
//	[self.view setBackgroundColor:[UIColor colorWithPatternImage: [UIImage imageNamed:@"backgroundImage_repeat.png"]]];
    [self.view addSubview:rootView];
    
    xbmcLogo = [[UIButton alloc] initWithFrame:CGRectMake(671, 967, 87, 30)];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_up"] forState:UIControlStateNormal];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_up"] forState:UIControlStateHighlighted];
    xbmcLogo.showsTouchWhenHighlighted = NO;
    [xbmcLogo addTarget:self action:@selector(toggleInfoView) forControlEvents:UIControlEventTouchUpInside];
    xbmcLogo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    xbmcLogo.alpha = .9f;
    [self.view addSubview:xbmcLogo];
    
    UIButton  *volumeButton = [[UIButton alloc] initWithFrame:CGRectMake(341, 964, 36, 37)];
    [volumeButton setImage:[UIImage imageNamed:@"volume@2x.png"] forState:UIControlStateNormal];
    [volumeButton setImage:[UIImage imageNamed:@"volume@2x.png"] forState:UIControlStateHighlighted];
    [volumeButton setImage:[UIImage imageNamed:@"volume@2x.png"] forState:UIControlStateSelected];
    volumeButton.alpha = 0.1;
    volumeButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    volumeButton.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:volumeButton];
    
    volumeSliderView = [[VolumeSliderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 62.0f, 296.0f)];
    volumeSliderView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    frame=volumeSliderView.frame;
    frame.origin.x=408;
    frame.origin.y=self.view.frame.size.height - 170;
    volumeSliderView.frame=frame;
    CGAffineTransform trans = CGAffineTransformMakeRotation(M_PI * 0.5);
    volumeSliderView.transform = trans;
    [self.view addSubview:volumeSliderView];
    
    xbmcInfo = [[UIButton alloc] initWithFrame:CGRectMake(428, 966, 190, 33)]; //225
    [xbmcInfo setTitle:NSLocalizedString(@"No connection", nil) forState:UIControlStateNormal];
    xbmcInfo.titleLabel.font = [UIFont systemFontOfSize:11];
    xbmcInfo.titleLabel.minimumScaleFactor = 6.0f / 11.0f;
    xbmcInfo.titleLabel.numberOfLines = 2;
    xbmcInfo.titleLabel.textAlignment=NSTextAlignmentCenter;
    xbmcInfo.titleEdgeInsets = UIEdgeInsetsMake(0, 3, 0, 3);
    xbmcInfo.titleLabel.shadowColor = [UIColor blackColor];
    xbmcInfo.titleLabel.shadowOffset = CGSizeMake (1.0, 1.0);
    xbmcInfo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [xbmcInfo addTarget:self action:@selector(toggleSetup) forControlEvents:UIControlEventTouchUpInside];
    
    powerButton = [[UIButton alloc] initWithFrame:CGRectMake(620, 966, 42, 33)]; //225
    xbmcInfo.titleLabel.font = [UIFont systemFontOfSize:13];
    xbmcInfo.titleEdgeInsets = UIEdgeInsetsZero;
    xbmcInfo.titleLabel.shadowOffset = CGSizeZero;
    [xbmcInfo setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [xbmcInfo setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
    [menuViewController.tableView setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 0)];

    [powerButton setImage:[UIImage imageNamed: @"icon_power_up"] forState:UIControlStateNormal];
    [powerButton setImage:[UIImage imageNamed: @"icon_power_up"] forState:UIControlStateHighlighted];
    powerButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [powerButton addTarget:self action:@selector(powerControl) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:xbmcInfo];
    [self.view addSubview:powerButton];
    
    [self.view insertSubview:self.nowPlayingController.scrabbingView aboveSubview:rootView];
    [self.view insertSubview:self.nowPlayingController.songDetailsView aboveSubview:rootView];
    [self.view insertSubview:self.nowPlayingController.ProgressSlider aboveSubview:rootView];
    frame = self.nowPlayingController.ProgressSlider.frame;
    frame.origin.x = self.nowPlayingController.ProgressSlider.frame.origin.x + PAD_MENU_TABLE_WIDTH;
    self.nowPlayingController.ProgressSlider.frame=frame;
    
    frame = self.nowPlayingController.scrabbingView.frame;
    frame.size.width += 2;
    frame.origin.x = self.nowPlayingController.scrabbingView.frame.origin.x + PAD_MENU_TABLE_WIDTH;
    self.nowPlayingController.scrabbingView.frame=frame;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    BOOL clearCache=[[userDefaults objectForKey:@"clearcache_preference"] boolValue];
    if (clearCache==YES){
        ClearCacheView *clearView = [[ClearCacheView alloc] initWithFrame:self.view.frame];
        [clearView startActivityIndicator];
        [self.view addSubview:clearView];
        [NSThread detachNewThreadSelector:@selector(startClearAppDiskCache:) toTarget:self withObject:clearView];
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
    
    [(gradientUIView *)self.view setColoursWithCGColors:[UIColor colorWithRed:0.141f green:0.141f blue:0.141f alpha:1.0f].CGColor
                                               endColor:[UIColor colorWithRed:0.086f green:0.086f blue:0.086f alpha:1.0f].CGColor];
}

-(void)handleChangeBackgroundImage:(NSNotification *)sender {
    [UIView transitionWithView: fanartBackgroundImage
                      duration: 1.0f
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
    if ((showValue && firstRun) || !showValue){
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
    [self.nowPlayingController.itemDescription setScrollsToTop:FALSE];
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
    int thumbWidth = PAD_TV_SHOWS_BANNER_WIDTH;
    int tvshowHeight = PAD_TV_SHOWS_BANNER_HEIGHT;
    if ([AppDelegate instance].obj.preferTVPosters==YES){
        thumbWidth = PAD_TV_SHOWS_POSTER_WIDTH;
        tvshowHeight = PAD_TV_SHOWS_POSTER_HEIGHT;
    }
    mainMenu *menuItem=[self.mainMenu objectAtIndex:3];
    menuItem.thumbWidth=thumbWidth;
    menuItem.rowHeight=tvshowHeight;
    [[AppDelegate instance].windowController.stackScrollViewController offView];
    NSIndexPath *selection=[menuViewController.tableView indexPathForSelectedRow];
    if (selection){
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
    if ([AppDelegate instance].serverOnLine == YES){
        if (self.tcpJSONRPCconnection == nil){
            self.tcpJSONRPCconnection = [[tcpJSONRPC alloc] init];
        }
        [self.tcpJSONRPCconnection startNetworkCommunicationWithServer:[AppDelegate instance].obj.serverIP serverPort:[AppDelegate instance].obj.tcpPort];
    }
}

- (void)viewDidUnload{
    [super viewDidUnload];
    self.tcpJSONRPCconnection = nil;
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[menuViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[stackScrollViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    if (serverPicker == TRUE){
        serverPicker = FALSE;
        [self toggleSetup];
    }
    if (appInfo == TRUE){
        appInfo = FALSE;
        [self toggleInfoView];
    }
    if (showActionPower){
        [actionSheetPower showFromRect:CGRectMake(powerButton.frame.origin.x + powerButton.frame.size.width/2, powerButton.frame.origin.y, 1, 1) inView:self.view animated:YES];
        showActionPower = NO;
    }
}

-(CGSize)screenSizeOrientationIndependent {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    return CGSizeMake(MIN(screenSize.width, screenSize.height), MAX(screenSize.width, screenSize.height));
}

-(CGRect)currentScreenBoundsDependOnOrientation {
    NSString *reqSysVer = @"8.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending) {
        return [UIScreen mainScreen].bounds;
    }
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if(UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        screenBounds.size = CGSizeMake(width, height);
    }
    else if(UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        screenBounds.size = CGSizeMake(height, width);
    }
    
    return screenBounds ;
}

- (void)viewWillLayoutSubviews{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        CGRect frame = self.nowPlayingController.ProgressSlider.frame;
        frame.origin.y = [self currentScreenBoundsDependOnOrientation].size.height - 580;
        self.nowPlayingController.ProgressSlider.frame=frame;
        frame = self.nowPlayingController.scrabbingView.frame;
        frame.origin.y = self.nowPlayingController.ProgressSlider.frame.origin.y - self.nowPlayingController.scrabbingView.frame.size.height - 2.0f;
        self.nowPlayingController.scrabbingView.frame=frame;

        [self.nowPlayingController setToolbarWidth:[self currentScreenBoundsDependOnOrientation].size.width height:[self currentScreenBoundsDependOnOrientation].size.height - 414 YPOS:YPOS playBarWidth:426 portrait:TRUE];
	}
	else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight){
        CGRect frame = self.nowPlayingController.ProgressSlider.frame;
        frame.origin.y = [self currentScreenBoundsDependOnOrientation].size.height - 168;
        self.nowPlayingController.ProgressSlider.frame=frame;
        frame = self.nowPlayingController.scrabbingView.frame;
        frame.origin.y = self.nowPlayingController.ProgressSlider.frame.origin.y - self.nowPlayingController.scrabbingView.frame.size.height - 2.0f;
        self.nowPlayingController.scrabbingView.frame=frame;
        [self.nowPlayingController setToolbarWidth:[self currentScreenBoundsDependOnOrientation].size.width height:[self currentScreenBoundsDependOnOrientation].size.height YPOS:YPOS playBarWidth:680 portrait:FALSE];
	}
}

-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	[menuViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[stackScrollViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if ([self.serverPickerPopover isPopoverVisible]) {
        [self.serverPickerPopover dismissPopoverAnimated:NO];
        serverPicker = TRUE;
    }
    if ([self.appInfoPopover isPopoverVisible]) {
        [self.appInfoPopover dismissPopoverAnimated:NO];
        appInfo = TRUE;
    }
    showActionPower = NO;
    if ([actionSheetPower isVisible]){
        showActionPower = YES;
        [actionSheetPower dismissWithClickedButtonIndex:actionSheetPower.cancelButtonIndex animated:YES];
    }
}	

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
	return YES;
}

-(BOOL)shouldAutorotate{
    return !stackScrollIsFullscreen;
}


@end
