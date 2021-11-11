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
#import "HostManagementViewController.h"
#import "tcpJSONRPC.h"
#import "XBMCVirtualKeyboard.h"
#import "ClearCacheView.h"
#import "Utilities.h"

#define SERVER_TIMEOUT 2.0
#define CONNECTION_ICON_SIZE 18

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
@synthesize mainMenu;
@synthesize tcpJSONRPCconnection;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
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
        itemIsActive = NO;
        NSInteger n = [menuList numberOfRowsInSection:0];
        for (int i = 1; i < n; i++) {
            UITableViewCell *cell = [menuList cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if (cell != nil) {
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.3];
                ((UIImageView*)[cell viewWithTag:1]).alpha = 1.0;
                ((UIImageView*)[cell viewWithTag:2]).alpha = 1.0;
                ((UIImageView*)[cell viewWithTag:3]).alpha = 1.0;
                [UIView commitAnimations];
            }
        }
//        [[Utilities getJsonRPC]
//         callMethod:@"JSONRPC.Introspect"
//         withParameters:[NSDictionary dictionaryWithObjectsAndKeys: nil]
//         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
//             NSLog(@"%@", methodResult);
//         }];
    }
    else {
        [self.tcpJSONRPCconnection stopNetworkCommunication];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerConnectionFailed" object:nil userInfo:params];
        AppDelegate.instance.serverOnLine = NO;
        AppDelegate.instance.serverName = infoText;
        itemIsActive = NO;
        NSInteger n = [menuList numberOfRowsInSection:0];
        for (int i = 1; i < n; i++) {
            UITableViewCell *cell = [menuList cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if (cell != nil) {
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.3];
                ((UIImageView*)[cell viewWithTag:1]).alpha = 0.3;
                ((UIImageView*)[cell viewWithTag:2]).alpha = 0.3;
                ((UIImageView*)[cell viewWithTag:3]).alpha = 0.3;
                [UIView commitAnimations];
            }
        }
    }
}

#pragma mark - Table view methods & data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return self.mainMenu.count;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.row == 0) {
        cell.backgroundColor = [Utilities getGrayColor:53 alpha:1];
    }
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mainMenuCell"];
    [[NSBundle mainBundle] loadNibNamed:@"cellView" owner:self options:NULL];
    mainMenu *item = self.mainMenu[indexPath.row];
    NSString *iconName = item.icon;
    if (cell == nil) {
        cell = resultMenuCell;
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height)];
        backgroundView.backgroundColor = [Utilities getGrayColor:22 alpha:1];
        cell.selectedBackgroundView = backgroundView;
        ((UILabel*)[cell viewWithTag:3]).text = LOCALIZED_STR(@"No connection");
        UILabel *title = (UILabel*)[cell viewWithTag:3];
        if (indexPath.row == 0) {
            UIImage *logo = [UIImage imageNamed:@"xbmc_logo"];
            int cellHeight = 44;
            UIImageView *xbmc_logo = [[UIImageView alloc] initWithFrame:[Utilities createXBMCInfoframe:logo height:cellHeight width:self.view.bounds.size.width]];
            xbmc_logo.alpha = 0.25;
            xbmc_logo.image = logo;
            xbmc_logo.highlightedImage = [UIImage imageNamed:@"xbmc_logo_selected"];
            [cell insertSubview:xbmc_logo atIndex:0];
            UIImageView *icon = (UIImageView*)[cell viewWithTag:1];
            UIImageView *line = (UIImageView*)[cell viewWithTag:4];
            UIImageView *arrowRight = (UIImageView*)[cell viewWithTag:5];
            line.hidden = YES;
            title.font = [UIFont fontWithName:@"Roboto-Regular" size:13];
            icon.frame = CGRectMake(icon.frame.origin.x, (int)((cellHeight - CONNECTION_ICON_SIZE) / 2), CONNECTION_ICON_SIZE, CONNECTION_ICON_SIZE);
            title.frame = CGRectMake(42, 0, title.frame.size.width - arrowRight.frame.size.width - 10, cellHeight);
            title.numberOfLines = 2;
            arrowRight.frame = CGRectMake(arrowRight.frame.origin.x, (int)((cellHeight / 2) - (arrowRight.frame.size.height / 2)), arrowRight.frame.size.width, arrowRight.frame.size.height);
        }
        else {
            title.font = [UIFont fontWithName:@"Roboto-Regular" size:20];
            title.text = [item.mainLabel uppercaseString];
        }
    }
    UIImageView *icon = (UIImageView*)[cell viewWithTag:1];
    UILabel *upperTitle = (UILabel*)[cell viewWithTag:2];
    UILabel *title = (UILabel*)[cell viewWithTag:3];
    upperTitle.font = [UIFont fontWithName:@"Roboto-Regular" size:11];
    upperTitle.text = item.upperLabel;
    if (indexPath.row == 0) {
        iconName = @"connection_off";
        if (AppDelegate.instance.serverOnLine) {
            if (AppDelegate.instance.serverTCPConnectionOpen) {
                iconName = @"connection_on";
            }
            else {
                iconName = @"connection_on_notcp";
            }
        }
    }
    if (AppDelegate.instance.serverOnLine || indexPath.row == 0) {
        icon.alpha = 1.0;
        upperTitle.alpha = 1.0;
        title.alpha = 1.0;
    }
    else {
        icon.alpha = 0.3;
        upperTitle.alpha = 0.3;
        title.alpha = 0.3;
    }
    icon.image = [UIImage imageNamed:iconName];
    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    mainMenu *item = self.mainMenu[indexPath.row];
    if (!AppDelegate.instance.serverOnLine && item.family != FamilyServer) {
        [menuList selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
        return;
    }
    if (itemIsActive) {
        return;
    }
    itemIsActive = YES;
    UIViewController *object;
    BOOL setBarTintColor = NO;
    BOOL hideBottonLine = NO;
    switch (item.family) {
        case FamilyNowPlaying:
            self.nowPlaying = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
            self.nowPlaying.detailItem = item;
            object = self.nowPlaying;
            break;
        case FamilyRemote:
            [self.remoteController resetRemote];
            self.remoteController = [[RemoteController alloc] initWithNibName:@"RemoteController" withEmbedded:NO bundle:nil];
            self.remoteController.detailItem = item;
            object = self.remoteController;
            break;
        case FamilyServer:
            self.hostController = [[HostManagementViewController alloc] initWithNibName:@"HostManagementViewController" bundle:nil];
            object = self.hostController;
            setBarTintColor = YES;
            hideBottonLine = YES;
            break;
        case FamilyDetailView:
            self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
            self.detailViewController.detailItem = item;
            object = self.detailViewController;
            hideBottonLine = YES;
            break;
    }
    navController = [[CustomNavigationController alloc] initWithRootViewController:object];
    UIImage* menuImg = [UIImage imageNamed:@"button_menu"];
    object.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:menuImg style:UIBarButtonItemStylePlain target:nil action:@selector(revealMenu:)];
    
    UINavigationBar *newBar = navController.navigationBar;
    newBar.barStyle = UIBarStyleBlack;
    newBar.tintColor = TINT_COLOR;
    if (setBarTintColor) {
        newBar.backgroundColor = [Utilities getGrayColor:204 alpha:0.35];
    }
    if (hideBottonLine) {
        [navController hideNavBarBottomLine:YES];
    }
    navController.view.clipsToBounds = NO;
    CGRect shadowRect = CGRectMake(-16, 0, 16, self.view.frame.size.height + 22);
    UIImageView *shadow = [[UIImageView alloc] initWithFrame:shadowRect];
    shadow.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    shadow.image = [UIImage imageNamed:@"tableLeft"];
    shadow.opaque = YES;
    [navController.view addSubview:shadow];
    
    shadowRect = CGRectMake(self.view.frame.size.width, 0, 16, self.view.frame.size.height + 22);
    UIImageView *shadowRight = [[UIImageView alloc] initWithFrame:shadowRect];
    shadowRight.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    shadowRight.image = [UIImage imageNamed:@"tableRight"];
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

- (void)revealMenu:(id)sender {
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
    return NO;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    UIImage *myImage = [UIImage imageNamed:@"blank"];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage];
	imageView.frame = CGRectMake(0, 0, 320, 8);
	return imageView;
}

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
	return 1;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.row == 0) {
        return 44;
    }
    return 56;
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

#pragma mark - LifeCycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.slidingViewController.anchorRightPeekAmount = ANCHOR_RIGHT_PEEK;
    self.slidingViewController.underLeftWidthLayout = ECFullWidth;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect frame = menuList.frame;
    frame.origin.y = 22;
    frame.size.height = frame.size.height - 22;
    menuList.frame = frame;
    menuList.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL clearCache = [[userDefaults objectForKey:@"clearcache_preference"] boolValue];
    if (clearCache) {
        ClearCacheView *clearView = [[ClearCacheView alloc] initWithFrame:self.view.frame border:40];
        [clearView startActivityIndicator];
        [self.view addSubview:clearView];
        [NSThread detachNewThreadSelector:@selector(startClearAppDiskCache:) toTarget:self withObject:clearView];
    }
    self.tcpJSONRPCconnection = [tcpJSONRPC new];
    XBMCVirtualKeyboard *virtualKeyboard = [[XBMCVirtualKeyboard alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    [self.view addSubview:virtualKeyboard];
    AppDelegate.instance.obj = [GlobalData getInstance];
    checkServerParams = [NSDictionary dictionaryWithObjectsAndKeys: @[@"version", @"volume"], @"properties", nil];
    menuList.scrollsToTop = NO;
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
                                             selector: @selector(handleXBMCServerHasChanged:)
                                                 name: @"XBMCServerHasChanged"
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
    
    self.view.backgroundColor = [Utilities getGrayColor:36 alpha:1];
    [menuList selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
}

- (void)connectionStatus:(NSNotification*)note {
    NSDictionary *theData = note.userInfo;
    NSString *icon_connection = theData[@"icon_connection"];
    NSString *infoText = theData[@"message"];
    UITableViewCell *cell = [menuList cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UIImageView *icon = (UIImageView*)[cell viewWithTag:1];
    icon.image = [UIImage imageNamed:icon_connection];
    UILabel *title = (UILabel*)[cell viewWithTag:3];
    title.text = infoText;
}

- (void)handleTcpJSONRPCChangeServerStatus:(NSNotification*)sender {
    BOOL statusValue = [[sender.userInfo objectForKey:@"status"] boolValue];
    NSString *message = [sender.userInfo objectForKey:@"message"];
    NSString *icon_connection = [sender.userInfo objectForKey:@"icon_connection"];
    [self changeServerStatus:statusValue infoText:message icon:icon_connection];
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

- (void)handleXBMCServerHasChanged:(NSNotification*)sender {
    [self changeServerStatus:NO infoText:LOCALIZED_STR(@"No connection") icon:@"connection_off"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
