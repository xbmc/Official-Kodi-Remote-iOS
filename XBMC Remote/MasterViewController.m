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
    if (status==YES){
        [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateNormal];
        [xbmcLogo setImage:nil forState:UIControlStateHighlighted];
        [xbmcLogo setImage:nil forState:UIControlStateSelected];
        [xbmcInfo setTitle:infoText forState:UIControlStateNormal];
        [AppDelegate instance].serverOnLine=YES;
        int n = [menuList numberOfRowsInSection:0];
        for (int i=0;i<n;i++){
            UITableViewCell *cell = [menuList cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if (cell!=nil){
                cell.selectionStyle=UITableViewCellSelectionStyleBlue;
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.3];
                [(UIImageView*) [cell viewWithTag:1] setAlpha:1.0];
                [(UIImageView*) [cell viewWithTag:2] setAlpha:1.0];
                [(UIImageView*) [cell viewWithTag:3] setAlpha:1.0];
//                [(UIImageView*) [cell viewWithTag:4] setAlpha:1.0];

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
        int n = [menuList numberOfRowsInSection:0];
        for (int i=0;i<n;i++){
            UITableViewCell *cell = [menuList cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if (cell!=nil){
                cell.selectionStyle=UITableViewCellSelectionStyleGray;
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.3];

                [(UIImageView*) [cell viewWithTag:1] setAlpha:0.3];
                [(UIImageView*) [cell viewWithTag:2] setAlpha:0.3];
                [(UIImageView*) [cell viewWithTag:3] setAlpha:0.3];
//                [(UIImageView*) [cell viewWithTag:4] setAlpha:0.3];

                [UIView commitAnimations];
            }
        }
    }
}

-(void)checkServer{
    if (inCheck) return;
    [AppDelegate instance].obj=[GlobalData getInstance];  
    if ([[AppDelegate instance].obj.serverIP length]==0){
        if (firstRun){
            firstRun=NO;
            [self toggleViewToolBar:hostManagementViewController.view AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE forceOpen:TRUE];
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
                     NSString *infoTitle=[NSString stringWithFormat:@" XBMC %@.%@-%@", [serverInfo objectForKey:@"major"], [serverInfo objectForKey:@"minor"], [serverInfo objectForKey:@"tag"]];//, [serverInfo objectForKey:@"revision"]
                     [self changeServerStatus:YES infoText:infoTitle];
                     [self toggleViewToolBar:hostManagementViewController.view AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE forceOpen:FALSE];
                 }
                 else{
                     if ([AppDelegate instance].serverOnLine){
                         [self changeServerStatus:NO infoText:@"No connection"];
                     }
                     if (firstRun){
                         firstRun=NO;
                         [self toggleViewToolBar:hostManagementViewController.view AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE forceOpen:TRUE];
                     }
                 }
             }
         }
         else {
//             NSLog(@"ERROR %@ %@ %@",error, methodError, serverJSON);
             if ([AppDelegate instance].serverOnLine){
                 [self changeServerStatus:NO infoText:@"No connection"];
             }
             if (firstRun){
                 firstRun=NO;
                 [self toggleViewToolBar:hostManagementViewController.view AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE forceOpen:TRUE];
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
    [self toggleViewToolBar:hostManagementViewController.view AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE forceOpen:FALSE];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=nil;
    cell = [tableView dequeueReusableCellWithIdentifier:@"mainMenuCell"];
    [[NSBundle mainBundle] loadNibNamed:@"cellView" owner:self options:NULL];
    if (cell==nil)
        cell = resultMenuCell;
    mainMenu *item = [self.mainMenu objectAtIndex:indexPath.row];
    [(UIImageView*) [cell viewWithTag:1] setImage:[UIImage imageNamed:item.icon]];
    [(UILabel*) [cell viewWithTag:2] setText:item.upperLabel];   
    [(UILabel*) [cell viewWithTag:3] setFont:[UIFont fontWithName:@"DejaVuSans-Bold" size:21]];
    [(UILabel*) [cell viewWithTag:3] setText:item.mainLabel]; 
    if ([AppDelegate instance].serverOnLine){
        [(UIImageView*) [cell viewWithTag:1] setAlpha:1];
        [(UIImageView*) [cell viewWithTag:2] setAlpha:1];
        [(UIImageView*) [cell viewWithTag:3] setAlpha:1];
//        [(UIImageView*) [cell viewWithTag:4] setAlpha:1];

        cell.selectionStyle=UITableViewCellSelectionStyleBlue;
    }
    else {
        [(UIImageView*) [cell viewWithTag:1] setAlpha:0.3];
        [(UIImageView*) [cell viewWithTag:2] setAlpha:0.3];
        [(UIImageView*) [cell viewWithTag:3] setAlpha:0.3];
//        [(UIImageView*) [cell viewWithTag:4] setAlpha:0.3];

        cell.selectionStyle=UITableViewCellSelectionStyleGray;
    }
    
    return cell;
}

-(void)selectServerAtIndexPath:(NSIndexPath *)indexPath{
    storeServerSelection = indexPath;
    NSDictionary *item = [[AppDelegate instance].arrayServerList objectAtIndex:indexPath.row];
    [AppDelegate instance].obj.serverDescription = [item objectForKey:@"serverDescription"];
    [AppDelegate instance].obj.serverUser = [item objectForKey:@"serverUser"];
    [AppDelegate instance].obj.serverPass = [item objectForKey:@"serverPass"];
    [AppDelegate instance].obj.serverIP = [item objectForKey:@"serverIP"];
    [AppDelegate instance].obj.serverPort = [item objectForKey:@"serverPort"];
    [AppDelegate instance].obj.preferTVPosters = [[item objectForKey:@"preferTVPosters"] boolValue];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        int thumbWidth = 320;
        int tvshowHeight = 61;
        if ([AppDelegate instance].obj.preferTVPosters==YES){
            thumbWidth = 53;
            tvshowHeight = 76;
        }
        mainMenu *menuItem=[self.mainMenu objectAtIndex:2];
        menuItem.thumbWidth=thumbWidth;
        menuItem.rowHeight=tvshowHeight;
    }
    [self changeServerStatus:NO infoText:@"No connection"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (![AppDelegate instance].serverOnLine) {
        [menuList deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    [self toggleViewToolBar:hostManagementViewController.view AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE forceOpen:FALSE];
    mainMenu *item = [self.mainMenu objectAtIndex:indexPath.row];
    if (item.family == 2){
        self.nowPlaying=nil;
        self.nowPlaying = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
        self.nowPlaying.detailItem = item;
        [self.navigationController pushViewController:self.nowPlaying animated:YES];
    }
    else if (item.family == 3){
        self.remoteController=nil; 
        self.remoteController = [[RemoteController alloc] initWithNibName:@"RemoteController" bundle:nil];
        self.remoteController.detailItem = item;
        [self.navigationController pushViewController:self.remoteController animated:YES];
    }
    else if (item.family == 1){
        //        if (!self.detailViewController) 
        self.detailViewController=nil;
        self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil] ;
        self.detailViewController.detailItem = item;
        [self.navigationController pushViewController:self.detailViewController animated:YES];
    }    
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return NO;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIImage *myImage = [UIImage imageNamed:@"blank.png"];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
	imageView.frame = CGRectMake(0,0,320,8);
	return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 8;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIImage *myImage = [UIImage imageNamed:@"blank.png"];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
	imageView.frame = CGRectMake(0,0,320,8);
	return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 8;
}

#pragma mark - View Methods

-(void)setFirstRun:(BOOL)value{
    firstRun=value;
}

-(void)setInCheck:(BOOL)value{
    inCheck = value;
}

#pragma mark - LifeCycle

-(void)viewWillAppear:(BOOL)animated{
    timer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(checkServer) userInfo:nil repeats:YES];
    NSIndexPath*	selection = [menuList indexPathForSelectedRow];
	if (selection){
		[menuList deselectRowAtIndexPath:selection animated:YES];
    }
    [hostManagementViewController selectIndex:nil reloadData:YES];
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
    xbmcLogo = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 75, 43)];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_up.png"] forState:UIControlStateNormal];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateHighlighted];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateSelected];
    [xbmcLogo addTarget:self action:@selector(infoView) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *setupRemote = [[UIBarButtonItem alloc] initWithCustomView:xbmcLogo];
    self.navigationItem.leftBarButtonItem = setupRemote;
    xbmcInfo = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 225, 43)];
    [xbmcInfo setTitle:@"No connection" forState:UIControlStateNormal];    
    xbmcInfo.titleLabel.font = [UIFont fontWithName:@"Courier" size:11];
    xbmcInfo.titleLabel.minimumFontSize=6.0f;
    xbmcInfo.titleLabel.shadowColor = [UIColor blackColor];
    xbmcInfo.titleLabel.shadowOffset    = CGSizeMake (1.0, 1.0);
    [xbmcInfo setBackgroundImage:[UIImage imageNamed:@"bottom_text_up.9.png"] forState:UIControlStateNormal];
    [xbmcInfo addTarget:self action:@selector(toggleSetup) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *setupInfo = [[UIBarButtonItem alloc] initWithCustomView:xbmcInfo];
    self.navigationItem.rightBarButtonItem = setupInfo;
}

-(void)initHostManagement{
    hostManagementViewController = [[HostManagementViewController alloc] initWithNibName:@"HostManagementViewController" bundle:nil masterController:self];
    CGRect frame=hostManagementViewController.view.frame;
    frame.origin.y = - frame.size.height;
    hostManagementViewController.view.frame=frame;
    [self.view addSubview:hostManagementViewController.view];
}

- (void)viewDidLoad{
    [super viewDidLoad];

    [AppDelegate instance].obj=[GlobalData getInstance]; 
    
    [self initHostManagement];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    int lastServer;
    if ([userDefaults objectForKey:@"lastServer"]!=nil){
        lastServer=[[userDefaults objectForKey:@"lastServer"] intValue];
        if (lastServer>-1){
            NSIndexPath *lastServerIndexPath=[NSIndexPath indexPathForRow:lastServer inSection:0];
            [hostManagementViewController selectIndex:lastServerIndexPath reloadData:NO];
        }
    }
    firstRun=YES;
    checkServerParams=[NSDictionary dictionaryWithObjectsAndKeys: [[NSArray alloc] initWithObjects:@"version", nil], @"properties", nil];
    [self initNavigationBar];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnterForeground:)
                                                 name: @"UIApplicationWillEnterForegroundNotification"
                                               object: nil];
    [self.view setBackgroundColor:[UIColor colorWithPatternImage: [UIImage imageNamed:@"backgroundImage_repeat.png"]]];
//    [self.view setBackgroundColor:[UIColor blackColor]];
}

- (void) handleEnterForeground: (NSNotification*) sender;{
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
//    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
//}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
