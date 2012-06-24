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
#define CONNECTION_TIMEOUT 240.0f

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
}

-(void)wakeUp:(NSString *)macAddress{
    [[AppDelegate instance] wake:macAddress];
}

-(void)checkServer{
    jsonRPC=nil;
    if ([[AppDelegate instance].obj.serverIP length]==0){
        if (firstRun){
            [self showSetup:YES];
        }
        if ([AppDelegate instance].serverOnLine){
            [self changeServerStatus:NO infoText:@"No connection"];
        }
        return;
    }
    NSString *userPassword=[[AppDelegate instance].obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", [AppDelegate instance].obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", [AppDelegate instance].obj.serverUser, userPassword, [AppDelegate instance].obj.serverIP, [AppDelegate instance].obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC 
     callMethod:@"Application.GetProperties" 
     withParameters:checkServerParams
     withTimeout: 2.0
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error==nil && methodError==nil){
             if (![AppDelegate instance].serverOnLine){
                 if( [NSJSONSerialization isValidJSONObject:methodResult]){
                     [volumeSliderView startTimer];
                     NSDictionary *serverInfo=[methodResult objectForKey:@"version"];
                     [AppDelegate instance].serverVersion=[[serverInfo objectForKey:@"major"] intValue];
                     NSString *infoTitle=[NSString stringWithFormat:@" XBMC %@.%@-%@", [serverInfo objectForKey:@"major"], [serverInfo objectForKey:@"minor"], [serverInfo objectForKey:@"tag"]];//, [serverInfo objectForKey:@"revision"]
                     [self changeServerStatus:YES infoText:infoTitle];
                     [self showSetup:NO];
                 }
                 else{
                     if ([AppDelegate instance].serverOnLine){
                         [self changeServerStatus:NO infoText:@"No connection"];
                     }
                     if (firstRun){
                         [self showSetup:YES];
                     }
                 }
             }
         }
         else {
             //             NSLog(@"ERROR %@ %@",error, methodError);
             if ([AppDelegate instance].serverOnLine){
                 //                 NSLog(@"mi spengo");
                 [self changeServerStatus:NO infoText:@"No connection"];
             }
             if (firstRun){
                 [self showSetup:YES];
             }
         }
     }];
    jsonRPC=nil;
}

-(void)changeServerStatus:(BOOL)status infoText:(NSString *)infoText{
    if (status==YES){
        [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateNormal];
        [xbmcLogo setImage:nil forState:UIControlStateHighlighted];
        [xbmcLogo setImage:nil forState:UIControlStateSelected];
        [xbmcInfo setTitle:infoText forState:UIControlStateNormal];
        [AppDelegate instance].serverOnLine=YES;
        int n = [menuViewController.tableView numberOfRowsInSection:0];
        for (int i=0;i<n;i++){
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
        [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_up.png"] forState:UIControlStateNormal];
        [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateHighlighted];
        [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateSelected];
        [xbmcInfo setTitle:infoText forState:UIControlStateNormal];
        [AppDelegate instance].serverOnLine=NO;
        int n = [menuViewController.tableView numberOfRowsInSection:0];
        for (int i=0;i<n;i++){
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

- (void)toggleSetup {
    if (_hostPickerViewController == nil) {
        
        self.hostPickerViewController = [[HostManagementViewController alloc] initWithNibName:@"HostManagementViewController" bundle:nil];
        [AppDelegate instance].navigationController = [[UINavigationController alloc] initWithRootViewController:_hostPickerViewController];
        self.serverPickerPopover = [[UIPopoverController alloc] 
                                    initWithContentViewController:[AppDelegate instance].navigationController];
        self.serverPickerPopover.delegate = self;
        [self.serverPickerPopover setPopoverContentSize:CGSizeMake(320, 436)];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        int lastServer;
        if ([userDefaults objectForKey:@"lastServer"]!=nil){
            lastServer=[[userDefaults objectForKey:@"lastServer"] intValue];
            if (lastServer>-1){
                NSIndexPath *lastServerIndexPath=[NSIndexPath indexPathForRow:lastServer inSection:0];
                [self.hostPickerViewController selectIndex:lastServerIndexPath reloadData:NO];
            }
        }    
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

    }
    [self.appInfoPopover presentPopoverFromRect:xbmcLogo.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}
#pragma mark - power control action sheet

-(void)powerControl{
    if ([[AppDelegate instance].obj.serverIP length]==0){
        [self toggleSetup];
        return;
    }
    NSString *title=[NSString stringWithFormat:@"%@ - %@", [AppDelegate instance].obj.serverDescription, [AppDelegate instance].obj.serverIP];
    if (![AppDelegate instance].serverOnLine){
        sheetActions=[NSArray arrayWithObjects:@"Wake On Lan", nil];
    }
    else{
        sheetActions=[NSArray arrayWithObjects:@"Power off System", @"Hibernate", @"Suspend", @"Reboot", nil];
    }
    int numActions=[sheetActions count];
    if (numActions){
        actionSheetPower = [[UIActionSheet alloc] initWithTitle:title
                                                            delegate:self
                                                   cancelButtonTitle:nil
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:nil];
        for (int i = 0; i < numActions; i++) {
            [actionSheetPower addButtonWithTitle:[sheetActions objectAtIndex:i]];
        }
        actionSheetPower.cancelButtonIndex = [actionSheetPower addButtonWithTitle:@"Cancel"];
       [actionSheetPower showFromRect:CGRectMake(powerButton.frame.origin.x + powerButton.frame.size.width/2, powerButton.frame.origin.y, 1, 1) inView:self.view animated:YES];
    }
}

-(void)powerAction:(NSString *)action params:(NSDictionary *)params{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (methodError==nil && error == nil){
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Command executed" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
        }
        else{
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Cannot do that" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
        }
    }];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex!=actionSheet.cancelButtonIndex){
        if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:@"Wake On Lan"]){
            if ([AppDelegate instance].obj.serverHWAddr != nil){
                [self wakeUp:[AppDelegate instance].obj.serverHWAddr];
                UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Command executed" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
            }
            else{
                UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"No sever mac address definied" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
            }
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:@"Power off System"]){
            [self powerAction:@"System.Shutdown" params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:@"Hibernate"]){
            [self powerAction:@"System.Hibernate" params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:@"Suspend"]){
            [self powerAction:@"System.Suspend" params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:@"Reboot"]){
            [self powerAction:@"System.Reboot" params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
        }
    }
}

#pragma mark - Touch Events

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint locationPoint = [[touches anyObject] locationInView:self.view];
    CGPoint viewPoint = [self.nowPlayingController.jewelView convertPoint:locationPoint fromView:self.view];
    if ([self.nowPlayingController.jewelView pointInside:viewPoint withEvent:event]) {
        [self.nowPlayingController toggleSongDetails];
    }
}

#pragma mark - Lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
    firstRun=YES;
    [AppDelegate instance].obj=[GlobalData getInstance]; 
    
    self.hostPickerViewController = [[HostManagementViewController alloc] initWithNibName:@"HostManagementViewController" bundle:nil];
    [AppDelegate instance].navigationController = [[UINavigationController alloc] initWithRootViewController:_hostPickerViewController];
    self.serverPickerPopover = [[UIPopoverController alloc] 
                                initWithContentViewController:[AppDelegate instance].navigationController];
    self.serverPickerPopover.delegate = self;
    [self.serverPickerPopover setPopoverContentSize:CGSizeMake(320, 436)];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    int lastServer;
    if ([userDefaults objectForKey:@"lastServer"]!=nil){
        lastServer=[[userDefaults objectForKey:@"lastServer"] intValue];
        if (lastServer>-1){
            NSIndexPath *lastServerIndexPath=[NSIndexPath indexPathForRow:lastServer inSection:0];
            [self.hostPickerViewController selectIndex:lastServerIndexPath reloadData:NO];
            [self handleXBMCServerHasChanged:nil];
        }
    }
    int tableHeight = [(NSMutableArray *)mainMenu count] * 64 + 16;
    int tableWidth = 300;
    int headerHeight=0;
   
    rootView = [[UIViewExt alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
	rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
	[rootView setBackgroundColor:[UIColor clearColor]];
	
	leftMenuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableWidth, self.view.frame.size.height)];
	leftMenuView.autoresizingMask = UIViewAutoresizingFlexibleHeight;	
    
//    CGRect maniMenuTitleFrame = CGRectMake(0.0f, 2.0f, tableWidth, headerHeight);
//    UILabel *mainMenuTitle=[[UILabel alloc] initWithFrame:maniMenuTitleFrame];
//    [mainMenuTitle setFont:[UIFont fontWithName:@"Optima-Regular" size:12]];
//    [mainMenuTitle setTextAlignment:UITextAlignmentCenter];
//    [mainMenuTitle setBackgroundColor:[UIColor clearColor]];
//    [mainMenuTitle setText:@"Main Menu"];
//    [mainMenuTitle setTextColor:[UIColor lightGrayColor]];
//    [mainMenuTitle setShadowColor:[UIColor blackColor]];
//    [mainMenuTitle setShadowOffset:CGSizeMake(1, 1)];
//    [leftMenuView addSubview:mainMenuTitle];
    
	menuViewController = [[MenuViewController alloc] initWithFrame:CGRectMake(0, headerHeight, leftMenuView.frame.size.width, leftMenuView.frame.size.height) mainMenu:mainMenu];
	[menuViewController.view setBackgroundColor:[UIColor clearColor]];
	[menuViewController viewWillAppear:FALSE];
	[menuViewController viewDidAppear:FALSE];
	[leftMenuView addSubview:menuViewController.view];
    int separator = 0;

//    separator = 18;
//    CGRect leatherBackground = CGRectMake(0.0f, tableHeight + headerHeight - 6, tableWidth, separator + 4);
//    UIImageView *leather = [[UIImageView alloc] initWithFrame:leatherBackground];
//    [leather setImage:[UIImage imageNamed:@"denim_seam.png"]];
//    leather.opaque = YES;
//    leather.alpha = 0.5;
//    [leftMenuView addSubview:leather];
    
    separator = 5;
    CGRect seamBackground = CGRectMake(0.0f, tableHeight + headerHeight - 2, tableWidth, separator);
    UIImageView *seam = [[UIImageView alloc] initWithFrame:seamBackground];
    [seam setImage:[UIImage imageNamed:@"denim_single_seam.png"]];
    seam.opaque = YES;
//    seam.alpha = 0.7;
    [leftMenuView addSubview:seam];
////    
//    UILabel *playlistTitle=[[UILabel alloc] initWithFrame:leatherBackground];
//    [playlistTitle setFont:[UIFont fontWithName:@"Optima-Regular" size:12]];
//    [playlistTitle setTextAlignment:UITextAlignmentCenter];
//    [playlistTitle setBackgroundColor:[UIColor clearColor]];
//    [playlistTitle setText:@"Playlist"];
//    [playlistTitle setTextColor:[UIColor lightGrayColor]];
//    [playlistTitle setShadowColor:[UIColor blackColor]];
//    [playlistTitle setShadowOffset:CGSizeMake(1, 1)];
//    [leftMenuView addSubview:playlistTitle];
    
    
    nowPlayingController = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
    CGRect frame=nowPlayingController.view.frame;
    YPOS=-(tableHeight + separator + headerHeight);
    frame.origin.y=tableHeight + separator + headerHeight;
    frame.size.width=tableWidth;
    frame.size.height=self.view.frame.size.height - tableHeight - separator - headerHeight;
    nowPlayingController.view.autoresizingMask=UIViewAutoresizingFlexibleHeight;
    nowPlayingController.view.frame=frame;
    
    [nowPlayingController setToolbarWidth:768 height:610 YPOS:YPOS playBarWidth:426 portrait:TRUE];
    
    [leftMenuView addSubview:nowPlayingController.view];

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
    
//    self.view.backgroundColor = [UIColor blackColor];
//    self.view.backgroundColor = [[UIColor scrollViewTexturedBackgroundColor] colorWithAlphaComponent:0.5];
	[self.view setBackgroundColor:[UIColor colorWithPatternImage: [UIImage imageNamed:@"backgroundImage_repeat.png"]]];
    [self.view addSubview:rootView];
    
    xbmcLogo = [[UIButton alloc] initWithFrame:CGRectMake(686, 962, 74, 41)];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_up.png"] forState:UIControlStateNormal];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateHighlighted];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateSelected];
    [xbmcLogo addTarget:self action:@selector(toggleInfoView) forControlEvents:UIControlEventTouchUpInside];
    xbmcLogo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
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
    
    xbmcInfo = [[UIButton alloc] initWithFrame:CGRectMake(438, 961, 190, 43)]; //225
    [xbmcInfo setTitle:@"No connection" forState:UIControlStateNormal];    
    xbmcInfo.titleLabel.font = [UIFont fontWithName:@"Courier" size:11];
    xbmcInfo.titleLabel.minimumFontSize=6.0f;
    xbmcInfo.titleLabel.shadowColor = [UIColor blackColor];
    xbmcInfo.titleLabel.shadowOffset    = CGSizeMake (1.0, 1.0);
    [xbmcInfo setBackgroundImage:[UIImage imageNamed:@"bottom_text_up.9.png"] forState:UIControlStateNormal];
    xbmcInfo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [xbmcInfo addTarget:self action:@selector(toggleSetup) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:xbmcInfo];
    
    powerButton = [[UIButton alloc] initWithFrame:CGRectMake(630, 961, 42, 43)]; //225
    [powerButton setBackgroundImage:[UIImage imageNamed:@"icon_power_up.png"] forState:UIControlStateNormal];
    powerButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [powerButton addTarget:self action:@selector(powerControl) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:powerButton];

    
    checkServerParams=[NSDictionary dictionaryWithObjectsAndKeys: [[NSArray alloc] initWithObjects:@"version", nil], @"properties", nil];
    timer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(checkServer) userInfo:nil repeats:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleXBMCServerHasChanged:)
                                                 name: @"XBMCServerHasChanged"
                                               object: nil];
}

- (void) handleXBMCServerHasChanged: (NSNotification*) sender{
    int thumbWidth = 477;
    int tvshowHeight = 91;
    if ([AppDelegate instance].obj.preferTVPosters==YES){
        thumbWidth = 53;
        tvshowHeight = 76;
    }
    mainMenu *menuItem=[self.mainMenu objectAtIndex:2];
    menuItem.thumbWidth=thumbWidth;
    menuItem.rowHeight=tvshowHeight;
    [[AppDelegate instance].windowController.stackScrollViewController offView];
    NSIndexPath *selection=[menuViewController.tableView indexPathForSelectedRow];
    if (selection){
        [menuViewController.tableView deselectRowAtIndexPath:selection animated:YES];
        [menuViewController setLastSelected:-1];
    }
    [self changeServerStatus:NO infoText:@"No connection"];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[menuViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[stackScrollViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    if ([self.serverPickerPopover isPopoverVisible]) {
        [self.serverPickerPopover dismissPopoverAnimated:NO];
        [self toggleSetup];
    }
    if ([self.appInfoPopover isPopoverVisible]) {
        [self.appInfoPopover dismissPopoverAnimated:NO];
        [self toggleInfoView];
    }
    if (showActionPower){
        [actionSheetPower showFromRect:CGRectMake(powerButton.frame.origin.x + powerButton.frame.size.width/2, powerButton.frame.origin.y, 1, 1) inView:self.view animated:YES];
        showActionPower = NO;
    }
}

-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	[menuViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[stackScrollViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        
        [nowPlayingController setToolbarWidth:768 height:610 YPOS:YPOS playBarWidth:426 portrait:TRUE];

	}
	else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight){
        
        [nowPlayingController setToolbarWidth:1024 height:768 YPOS:YPOS playBarWidth:680 portrait:FALSE];

	}
    showActionPower = NO;
    if (actionSheetPower.window != nil){
        showActionPower = YES;
        [actionSheetPower dismissWithClickedButtonIndex:actionSheetPower.cancelButtonIndex animated:YES];
    }
}	

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
	return YES;
}

@end
