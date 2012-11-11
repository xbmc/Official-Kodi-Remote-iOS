//
//  MasterViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "MasterViewController.h"
#import "mainMenu.h"
#import "DetailViewController.h"
#import "NowPlaying.h"
#import "RemoteController.h"
#import "DSJSONRPC.h"
#import "GlobalData.h"
#import "HostViewController.h"
#import "AppDelegate.h"
#import "AppInfoViewController.h"
#import "HostManagementViewController.h"

@interface MasterViewController () {
    NSMutableArray *_objects;
    NSMutableArray *mainMenu;
}
@end

@implementation MasterViewController

@synthesize detailViewController = _detailViewController;
@synthesize nowPlaying = _nowPlaying;
@synthesize remoteController = _remoteController;
@synthesize hostController = _hostController;

//@synthesize obj;

@synthesize mainMenu;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}
	
-(void)changeServerStatus:(BOOL)status infoText:(NSString *)infoText{
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:infoText forKey:@"infoText"];
    if (status==YES){
        [AppDelegate instance].serverOnLine = YES;
        [AppDelegate instance].serverName = infoText;
        itemIsActive = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerConnectionSuccess" object:nil userInfo:dataDict];
        UITableViewCell *cell = [menuList cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        UILabel *title = (UILabel*) [cell viewWithTag:3];
        [title setText:infoText];
        UIImageView *icon = (UIImageView*) [cell viewWithTag:1];
        [icon setImage:[UIImage imageNamed:@"connection_on"]];
        int n = [menuList numberOfRowsInSection:0];
        for (int i=1;i<n;i++){
            UITableViewCell *cell = [menuList cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if (cell!=nil){
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.3];
                [(UIImageView*) [cell viewWithTag:1] setAlpha:1.0];
                [(UIImageView*) [cell viewWithTag:2] setAlpha:1.0];
                [(UIImageView*) [cell viewWithTag:3] setAlpha:1.0];
                [UIView commitAnimations];
            }
        }
//        NSString *userPassword=[[AppDelegate instance].obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", [AppDelegate instance].obj.serverPass];
//        NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", [AppDelegate instance].obj.serverUser, userPassword, [AppDelegate instance].obj.serverIP, [AppDelegate instance].obj.serverPort];
//        jsonRPC=nil;
//        jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
//
//        [jsonRPC
//         callMethod:@"JSONRPC.Introspect"
//         withParameters:[NSDictionary dictionaryWithObjectsAndKeys: nil]
//         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
//             NSLog(@"%@", methodResult);
//         }];
    }
    else{
        [AppDelegate instance].serverOnLine = NO;
        [AppDelegate instance].serverName = infoText;
        itemIsActive = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerConnectionFailed" object:nil userInfo:dataDict];
        UITableViewCell *cell = [menuList cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        UILabel *title = (UILabel*) [cell viewWithTag:3];
        [title setText:infoText];
        UIImageView *icon = (UIImageView*) [cell viewWithTag:1];
        [icon setImage:[UIImage imageNamed:@"connection_off"]];
        int n = [menuList numberOfRowsInSection:0];
        for (int i=1;i<n;i++){
            UITableViewCell *cell = [menuList cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if (cell!=nil){
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.3];
                [(UIImageView*) [cell viewWithTag:1] setAlpha:0.3];
                [(UIImageView*) [cell viewWithTag:2] setAlpha:0.3];
                [(UIImageView*) [cell viewWithTag:3] setAlpha:0.3];
                [UIView commitAnimations];
            }
        }
    }
}

-(void)wakeUp:(NSString *)macAddress{
    [[AppDelegate instance] wake:macAddress];
}

-(void)checkServer{
    if (inCheck) return;
    [AppDelegate instance].obj=[GlobalData getInstance];  
    if ([[AppDelegate instance].obj.serverIP length]==0){
        if (firstRun){
            firstRun=NO;
        }
        return;
    }
    inCheck = TRUE;
    NSString *userPassword=[[AppDelegate instance].obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", [AppDelegate instance].obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", [AppDelegate instance].obj.serverUser, userPassword, [AppDelegate instance].obj.serverIP, [AppDelegate instance].obj.serverPort];
    jsonRPC=nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC 
     callMethod:@"Application.GetProperties" 
     withParameters:checkServerParams
     withTimeout:2.0
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         inCheck = FALSE;
         if (error==nil && methodError==nil){
             if (![AppDelegate instance].serverOnLine){
                 if( [NSJSONSerialization isValidJSONObject:methodResult]){
                     NSDictionary *serverInfo=[methodResult objectForKey:@"version"];
                     [AppDelegate instance].serverVersion=[[serverInfo objectForKey:@"major"] intValue];
                     NSString *infoTitle=[NSString stringWithFormat:@"%@ v%@.%@ %@", [AppDelegate instance].obj.serverDescription, [serverInfo objectForKey:@"major"], [serverInfo objectForKey:@"minor"], [serverInfo objectForKey:@"tag"]];//, [serverInfo objectForKey:@"revision"]
                     [self changeServerStatus:YES infoText:infoTitle];
                 }
                 else{
                     if ([AppDelegate instance].serverOnLine){
                         [self changeServerStatus:NO infoText:@"No connection"];
                     }
                     if (firstRun){
                         firstRun=NO;
                     }
                 }
             }
         }
         else {
             if ([AppDelegate instance].serverOnLine){
                 [self changeServerStatus:NO infoText:@"No connection"];
             }
             if (firstRun){
                 firstRun=NO;
             }
         }
     }];
    jsonRPC=nil;
}

#pragma Toobar Actions

-(void)toggleViewToolBar:(UIView*)view AnimDuration:(float)seconds Alpha:(float)alphavalue YPos:(int)Y forceHide:(BOOL)hide forceOpen:(BOOL)open {
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:seconds];
    int actualPosY=view.frame.origin.y;
    if (actualPosY==Y || hide){
        Y=-view.frame.size.height;
    }
    if (open){
        Y=0;
    }
    view.alpha = alphavalue;
	CGRect frame;
	frame = [view frame];
	frame.origin.y = Y;
    view.frame = frame;
    [UIView commitAnimations];
}

- (void)toggleSetup{
//    [self toggleViewToolBar:hostManagementViewController.view AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE forceOpen:FALSE];
}

- (void) pushController:(UIViewController*)controller withTransition:(UIViewAnimationTransition)transition{
    [UIView beginAnimations:nil context:NULL];
    [self.navigationController pushViewController:controller animated:NO];
    [UIView setAnimationDuration:.5];
    [UIView setAnimationBeginsFromCurrentState:YES];        
    [UIView setAnimationTransition:transition forView:self.navigationController.view cache:YES];
    [UIView commitAnimations];
}

#pragma mark - Table view methods & data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.mainMenu count];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0){
        cell.backgroundColor = [UIColor colorWithRed:.208f green:.208f blue:.208f alpha:1];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=nil;
    cell = [tableView dequeueReusableCellWithIdentifier:@"mainMenuCell"];
    [[NSBundle mainBundle] loadNibNamed:@"cellView" owner:self options:NULL];
    if (cell == nil){
        cell = resultMenuCell;
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height)];
        [backgroundView setBackgroundColor:[UIColor colorWithRed:.086 green:.086 blue:.086 alpha:1]];
        cell.selectedBackgroundView = backgroundView;
        if (indexPath.row == 0){
            UIImageView *xbmc_logo = [[UIImageView alloc] initWithFrame:CGRectMake(127, (int)((44/2) - (36/2)) - 2, 145, 36)];
            xbmc_logo. alpha = .25f;
            [xbmc_logo setImage:[UIImage imageNamed:@"xbmc_logo.png"]];
            [xbmc_logo setHighlightedImage:[UIImage imageNamed:@"xbmc_logo_selected.png"]];

            [cell insertSubview:xbmc_logo atIndex:0];
        }
    }
    mainMenu *item = [self.mainMenu objectAtIndex:indexPath.row];
    UIImageView *icon = (UIImageView*) [cell viewWithTag:1];
    UILabel *upperTitle = (UILabel*) [cell viewWithTag:2];
    UILabel *title = (UILabel*) [cell viewWithTag:3];
    UIImageView *line = (UIImageView*) [cell viewWithTag:4];
    NSString *iconName = [NSString stringWithFormat:@"%@_alt", item.icon];
    [upperTitle setFont:[UIFont fontWithName:@"Roboto-Regular" size:11]];
    [upperTitle setText:item.upperLabel];
    if (indexPath.row == 0){
        UIImageView *arrowRight = (UIImageView*) [cell viewWithTag:5];
        iconName = @"connection_off";
        if ([AppDelegate instance].serverOnLine){
            iconName = @"connection_on";
        }
        line.hidden = YES;
        int cellHeight = 44;
                [title setFont:[UIFont fontWithName:@"Roboto-Regular" size:13]];
        [icon setFrame:CGRectMake(icon.frame.origin.x, (int)((cellHeight/2) - (18/2)), 18, 18)];
        [title setFrame:CGRectMake(42, 0, title.frame.size.width - arrowRight.frame.size.width - 10, cellHeight)];
        [title setNumberOfLines:2];
        [arrowRight setFrame:CGRectMake(arrowRight.frame.origin.x, (int)((cellHeight/2) - (arrowRight.frame.size.height/2)), arrowRight.frame.size.width, arrowRight.frame.size.height)];
    }
    else{
        [title setFont:[UIFont fontWithName:@"Roboto-Regular" size:20]];
        [title setText:[item.mainLabel uppercaseString]];
    }
    if ([AppDelegate instance].serverOnLine || indexPath.row == 0){
        [icon setAlpha:1];
        [upperTitle setAlpha:1];
        [title setAlpha:1];
    }
    else {
        [icon setAlpha:0.3];
        [upperTitle setAlpha:0.3];
        [title setAlpha:0.3];
    }
    [icon setImage:[UIImage imageNamed:iconName]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    mainMenu *item = [self.mainMenu objectAtIndex:indexPath.row];
    if (![AppDelegate instance].serverOnLine && item.family!=4) {
        [menuList selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
        return;
    }
    if (itemIsActive == YES){
        return;
    }
    itemIsActive = YES;
    UIViewController *object;
    if (item.family == 2){
        if (self.nowPlaying == nil){
            self.nowPlaying = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
        }
        self.nowPlaying.detailItem = item;
        object = self.nowPlaying;
    }
    else if (item.family == 3){
        if (self.remoteController == nil){
            self.remoteController = [[RemoteController alloc] initWithNibName:@"RemoteController" bundle:nil];
        }
        self.remoteController.detailItem = item;
        object = self.remoteController;
    }
    else if (item.family == 4){
        if (self.hostController == nil){
            self.hostController = [[HostManagementViewController alloc] initWithNibName:@"HostManagementViewController" bundle:nil];
        }
//        self.hostController.rightMenuItems = [AppDelegate instance].rightMenuItems;

        object = self.hostController;
    }
    else if (item.family == 1){
        self.detailViewController=nil;
        self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil] ;
        self.detailViewController.detailItem = item;
        object = self.detailViewController;
    }
    UINavigationController *navController;
    navController = [[UINavigationController alloc] initWithRootViewController:object];
    
    UIImage* menuImg = [UIImage imageNamed:@"button_menu"];
    object.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:menuImg style:UIBarButtonItemStyleBordered target:nil action:@selector(revealMenu:)];
    
    UINavigationBar *newBar = navController.navigationBar;
    [newBar setTintColor:[UIColor colorWithRed:.14 green:.14 blue:.14 alpha:1]];
    [newBar setBarStyle:UIBarStyleBlackOpaque];
    
    CGRect shadowRect = CGRectMake(-16.0f, 0.0f, 16.0f, self.view.frame.size.height + 22);
    UIImageView *shadow = [[UIImageView alloc] initWithFrame:shadowRect];
    [shadow setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [shadow setImage:[UIImage imageNamed:@"tableLeft.png"]];
    shadow.opaque = YES;
    [navController.view addSubview:shadow];
    
    shadowRect = CGRectMake(self.view.frame.size.width, 0.0f, 16.0f, self.view.frame.size.height + 22);
    UIImageView *shadowRight = [[UIImageView alloc] initWithFrame:shadowRect];
    [shadowRight setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [shadowRight setImage:[UIImage imageNamed:@"tableRight.png"]];
    shadowRight.opaque = YES;
    [navController.view addSubview:shadowRight];

    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        CGRect frame = self.slidingViewController.topViewController.view.frame;
        self.slidingViewController.topViewController = navController;
        self.slidingViewController.topViewController.view.frame = frame;
        [self.slidingViewController resetTopView];
        itemIsActive = NO;
    }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIImage *myImage = [UIImage imageNamed:@"blank.png"];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
	imageView.frame = CGRectMake(0,0,320,8);
	return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0){
        return 44;
    }
    return 56;
}

#pragma mark - power control action sheet

-(void)powerControl{
    if ([[AppDelegate instance].obj.serverIP length]==0){
        return;
    }
    NSString *title=[NSString stringWithFormat:@"%@\n%@", [AppDelegate instance].obj.serverDescription, [AppDelegate instance].obj.serverIP];
    NSString *destructive = nil;
    NSArray *sheetActions = nil;
    if (![AppDelegate instance].serverOnLine){
        sheetActions=[NSArray arrayWithObjects:@"Wake On Lan", nil];
    }
    else{
        destructive = @"Power off System";
        sheetActions=[NSArray arrayWithObjects:@"Hibernate", @"Suspend", @"Reboot", @"Update Audio Library", @"Update Video Library", nil];
    }
    int numActions=[sheetActions count];
    if (numActions){
        UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:title
                                                            delegate:self
                                                   cancelButtonTitle:nil
                                              destructiveButtonTitle:destructive
                                                   otherButtonTitles:nil];
        action.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        for (int i = 0; i < numActions; i++) {
            [action addButtonWithTitle:[sheetActions objectAtIndex:i]];
        }
        action.cancelButtonIndex = [action addButtonWithTitle:@"Cancel"];
        [action showInView:self.view];
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
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Wake On Lan"]){
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
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Power off System"]){
            [self powerAction:@"System.Shutdown" params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Hibernate"]){
            [self powerAction:@"System.Hibernate" params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Suspend"]){
            [self powerAction:@"System.Suspend" params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Reboot"]){
            [self powerAction:@"System.Reboot" params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Update Audio Library"]){
            [self powerAction:@"AudioLibrary.Scan" params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Update Video Library"]){
            [self powerAction:@"VideoLibrary.Scan" params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
        }
    }
}

#pragma mark - LifeCycle

-(void)viewWillAppear:(BOOL)animated{
    if (timer == nil){
        timer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(checkServer) userInfo:nil repeats:YES];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [timer invalidate]; 
    timer=nil;
    jsonRPC=nil;
}

- (void)infoView{
    if (appInfoView==nil)
        appInfoView = [[AppInfoViewController alloc] initWithNibName:@"AppInfoViewController" bundle:nil] ;
    appInfoView.modalTransitionStyle = UIModalTransitionStylePartialCurl;
	appInfoView.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentModalViewController:appInfoView animated:YES];
}


-(void)initNavigationBar{
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:.14 green:.14 blue:.14 alpha:1];
    self.navigationController.navigationBar.backgroundColor = [UIColor blackColor];
    xbmcLogo = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 68, 43)];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_up.png"] forState:UIControlStateNormal];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateHighlighted];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateSelected];
    [xbmcLogo addTarget:self action:@selector(infoView) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *setupRemote = [[UIBarButtonItem alloc] initWithCustomView:xbmcLogo];
    self.navigationItem.leftBarButtonItem = setupRemote;
    
    xbmcInfo = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 184, 43)]; 
    [xbmcInfo setTitle:@"No connection" forState:UIControlStateNormal];
//    [xbmcInfo setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
//    [xbmcInfo setImageEdgeInsets:UIEdgeInsetsMake(-1, 5, 0, 0)];
    xbmcInfo.titleLabel.font = [UIFont systemFontOfSize:11];
    [xbmcInfo.titleLabel setTextColor:[UIColor colorWithRed:.8 green:.8 blue:.8 alpha:1]];
    [xbmcInfo.titleLabel setHighlightedTextColor:[UIColor whiteColor]];
    xbmcInfo.titleLabel.minimumFontSize=6.0f;
    xbmcInfo.titleLabel.numberOfLines=2;
    xbmcInfo.titleLabel.textAlignment=UITextAlignmentCenter;
//    xbmcInfo.titleEdgeInsets=UIEdgeInsetsMake(0, 7, 0, 3);
    xbmcInfo.titleEdgeInsets=UIEdgeInsetsMake(0, 3, 0, 3);

    xbmcInfo.titleLabel.shadowColor = [UIColor blackColor];
    xbmcInfo.titleLabel.shadowOffset    = CGSizeMake (1.0, 1.0);
//    [xbmcInfo setImage:[UIImage imageNamed:@"connection_off"] forState:UIControlStateNormal];
    [xbmcInfo setBackgroundImage:[UIImage imageNamed:@"bottom_text_up.9.png"] forState:UIControlStateNormal];
    [xbmcInfo addTarget:self action:@selector(toggleSetup) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *setupInfo = [[UIBarButtonItem alloc] initWithCustomView:xbmcInfo];
    
    powerButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 42, 43)];
    [powerButton setBackgroundImage:[UIImage imageNamed:@"icon_power_up.png"] forState:UIControlStateNormal];
    [powerButton addTarget:self action:@selector(powerControl) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *powerButtonItem = [[UIBarButtonItem alloc] initWithCustomView:powerButton];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects: powerButtonItem, setupInfo, nil];
}

-(void)initHostManagement{
    timer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(checkServer) userInfo:nil repeats:YES];
    return;
    hostManagementViewController = [[HostManagementViewController alloc] initWithNibName:@"HostManagementViewController" bundle:nil];
    CGRect frame=hostManagementViewController.view.frame;
    frame.origin.y = - frame.size.height - 1000;
    hostManagementViewController.view.frame=frame;
    [self.view addSubview:hostManagementViewController.view];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [self.slidingViewController setAnchorRightRevealAmount:280.0f];
    self.slidingViewController.underLeftWidthLayout = ECFullWidth;
    [AppDelegate instance].obj=[GlobalData getInstance];
    firstRun=YES;
    checkServerParams=[NSDictionary dictionaryWithObjectsAndKeys: [[NSArray alloc] initWithObjects:@"version", nil], @"properties", nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnterForeground:)
                                                 name: @"UIApplicationWillEnterForegroundNotification"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleXBMCServerHasChanged:)
                                                 name: @"XBMCServerHasChanged"
                                               object: nil];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:.141f green:.141f blue:.141f alpha:1]];
    [menuList selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
}

- (void) handleEnterForeground: (NSNotification*) sender;{
}

- (void) handleXBMCServerHasChanged: (NSNotification*) sender{
    inCheck = NO;
    firstRun = NO;
    int thumbWidth = 320;
    int tvshowHeight = 61;
    if ([AppDelegate instance].obj.preferTVPosters==YES){
        thumbWidth = 53;
        tvshowHeight = 76;
    }
    mainMenu *menuItem=[self.mainMenu objectAtIndex:3];
    menuItem.thumbWidth=thumbWidth;
    menuItem.rowHeight=tvshowHeight;
    [self changeServerStatus:NO infoText:@"No connection"];
}

-(void)dealloc{
    self.nowPlaying=nil;
    self.remoteController=nil;
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)shouldAutorotate{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

@end
