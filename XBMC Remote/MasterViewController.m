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
#define MENU_ICON_SIZE 30
#define ICON_MARGIN 10

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
    NSString *notificationName;
    if (status) {
        [self.tcpJSONRPCconnection startNetworkCommunicationWithServer:AppDelegate.instance.obj.serverRawIP serverPort:AppDelegate.instance.obj.tcpPort];
        notificationName = @"XBMCServerConnectionSuccess";
    }
    else {
        [self.tcpJSONRPCconnection stopNetworkCommunication];
        notificationName = @"XBMCServerConnectionFailed";
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:params];
    AppDelegate.instance.serverOnLine = status;
    AppDelegate.instance.serverName = infoText;
    itemIsActive = NO;
    [Utilities setStyleOfMenuItems:menuList active:status];
    if (status) {
        // Send trigger to start the defalt controller
        [[NSNotificationCenter defaultCenter] postNotificationName: @"KodiStartDefaultController" object:nil userInfo:params];
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
    [Utilities setStyleOfMenuItemCell:cell active:AppDelegate.instance.serverOnLine || indexPath.row == 0];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mainMenuCellIdentifier"];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"cellView" owner:self options:nil];
        cell = nib[0];
        
        // Set background view
        UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
        backgroundView.backgroundColor = [Utilities getGrayColor:22 alpha:1];
        cell.selectedBackgroundView = backgroundView;
        
        // Load Kodi background logo
        UIImage *logo = [UIImage imageNamed:@"xbmc_logo"];
        UIImageView *xbmc_logo = [[UIImageView alloc] initWithFrame:[Utilities createXBMCInfoframe:logo height:PHONE_MENU_INFO_HEIGHT width:self.view.bounds.size.width]];
        xbmc_logo.alpha = 0.25;
        xbmc_logo.image = logo;
        xbmc_logo.highlightedImage = [UIImage imageNamed:@"xbmc_logo_selected"];
        xbmc_logo.tag = XIB_MAIN_MENU_CELL_XBMC_LOGO;
        [cell insertSubview:xbmc_logo atIndex:0];
    }
    mainMenu *item = self.mainMenu[indexPath.row];
    NSString *iconName = item.icon;
    UIImageView *icon = (UIImageView*)[cell viewWithTag:XIB_MAIN_MENU_CELL_ICON];
    UILabel *title = (UILabel*)[cell viewWithTag:XIB_MAIN_MENU_CELL_TITLE];
    UIImageView *line = (UIImageView*)[cell viewWithTag:XIB_MAIN_MENU_CELL_SEPARATOR];
    UIImageView *xbmc_logo = (UIImageView*)[cell viewWithTag:XIB_MAIN_MENU_CELL_XBMC_LOGO];
    if (indexPath.row == 0) {
        // Show kodi logo
        xbmc_logo.hidden = NO;
        
        // Adapt layout for first cell (showing connection status)
        [self setFrameSizes:cell height:PHONE_MENU_INFO_HEIGHT iconsize:CONNECTION_ICON_SIZE];
        
        // Set icon, background color and text content
        title.font = [UIFont fontWithName:@"Roboto-Regular" size:13];
        title.numberOfLines = 2;
        title.text = [Utilities getConnectionStatusServerName];
        line.hidden = YES;
        iconName = [Utilities getConnectionStatusIconName];
        icon.highlightedImage = nil;
        icon.image = [UIImage imageNamed:iconName];
        cell.backgroundColor = [Utilities getGrayColor:53 alpha:1];
    }
    else {
        // Hide kodi logo
        xbmc_logo.hidden = YES;
        
        // Adapt layout for main menu cells
        [self setFrameSizes:cell height:PHONE_MENU_HEIGHT iconsize:MENU_ICON_SIZE];
        
        // Set icon, background color and text content
        title.font = [UIFont fontWithName:@"Roboto-Regular" size:20];
        title.numberOfLines = 1;
        title.text = item.mainLabel;
        line.hidden = NO;
        icon.highlightedImage = [UIImage imageNamed:iconName];
        icon.image = [Utilities colorizeImage:icon.highlightedImage withColor:UIColor.grayColor];
        cell.backgroundColor = UIColor.clearColor;
    }
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
    
    // Mark the active menu as selected
    [menuList selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    
    itemIsActive = YES;
    UIViewController *object;
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
    navController.navigationBar.barStyle = UIBarStyleBlack;
    navController.navigationBar.tintColor = ICON_TINT_COLOR;
    UIImage *menuImg = [UIImage imageNamed:@"button_menu"];
    object.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:menuImg 
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:nil
                                                                              action:@selector(revealMenu:)];
    
    if (hideBottonLine) {
        [navController hideNavBarBottomLine:YES];
    }
    [Utilities addShadowsToView:navController.view viewFrame:self.view.frame];

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
        return PHONE_MENU_INFO_HEIGHT;
    }
    return PHONE_MENU_HEIGHT;
}

#pragma mark - Helper

- (void)setFrameSizes:(UITableViewCell*)cell height:(CGFloat)height iconsize:(CGFloat)iconsize {
    UIImageView *icon = (UIImageView*)[cell viewWithTag:XIB_MAIN_MENU_CELL_ICON];
    UILabel *title = (UILabel*)[cell viewWithTag:XIB_MAIN_MENU_CELL_TITLE];
    UIImageView *arrowRight = (UIImageView*)[cell viewWithTag:XIB_MAIN_MENU_CELL_ARROW_RIGHT];
    
    // Adapt layout for first cell (showing connection status)
    icon.frame = CGRectMake(icon.frame.origin.x,
                            (height - iconsize) / 2,
                            iconsize,
                            iconsize);
    title.frame = CGRectMake(CGRectGetMaxX(icon.frame) + ICON_MARGIN,
                             0,
                             CGRectGetMinX(arrowRight.frame) - CGRectGetMaxX(icon.frame) - 2 * ICON_MARGIN,
                             height);
    arrowRight.frame = CGRectMake(arrowRight.frame.origin.x,
                                  (height - arrowRight.frame.size.height) / 2,
                                  arrowRight.frame.size.width,
                                  arrowRight.frame.size.height);
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
    
    // The menu list starts at the bottom of the status bar to not overlap with it
    CGFloat statuBarHeight = [Utilities getTopPadding];
    CGRect frame = menuList.frame;
    frame.origin.y = statuBarHeight;
    frame.size.height = frame.size.height - statuBarHeight;
    menuList.frame = frame;
    
    menuList.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL clearCache = [userDefaults boolForKey:@"clearcache_preference"];
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
    checkServerParams = @{@"properties": @[@"version", @"volume"]};
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
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnablingDefaultController)
                                                 name: @"KodiStartDefaultController"
                                               object: nil];
    
    self.view.backgroundColor = [Utilities getGrayColor:36 alpha:1];
    [menuList selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
}

- (void)connectionStatus:(NSNotification*)note {
    NSDictionary *theData = note.userInfo;
    NSString *icon_connection = theData[@"icon_connection"];
    NSString *infoText = theData[@"message"];
    UITableViewCell *cell = [menuList cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UIImageView *icon = (UIImageView*)[cell viewWithTag:XIB_MAIN_MENU_CELL_ICON];
    icon.image = [UIImage imageNamed:icon_connection];
    UILabel *title = (UILabel*)[cell viewWithTag:XIB_MAIN_MENU_CELL_TITLE];
    title.text = infoText;
    
    // We are connected to server, we now need to share credentials with SDWebImageManager
    [Utilities setWebImageAuthorizationOnSuccessNotification:note];
}

- (void)handleTcpJSONRPCChangeServerStatus:(NSNotification*)sender {
    BOOL statusValue = [[sender.userInfo objectForKey:@"status"] boolValue];
    NSString *message = [sender.userInfo objectForKey:@"message"];
    NSString *icon_connection = [sender.userInfo objectForKey:@"icon_connection"];
    [self changeServerStatus:statusValue infoText:message icon:icon_connection];
}

- (void)handleWillResignActive:(NSNotification*)sender {
}

- (void)handleDidEnterBackground:(NSNotification*)sender {
    [self.tcpJSONRPCconnection stopNetworkCommunication];
}

- (void)handleEnterForeground:(NSNotification*)sender {
    if (AppDelegate.instance.serverOnLine) {
        if (self.tcpJSONRPCconnection == nil) {
            self.tcpJSONRPCconnection = [tcpJSONRPC new];
        }
        [self.tcpJSONRPCconnection startNetworkCommunicationWithServer:AppDelegate.instance.obj.serverRawIP serverPort:AppDelegate.instance.obj.tcpPort];
    }
}

- (void)handleXBMCServerHasChanged:(NSNotification*)sender {
    [self changeServerStatus:NO infoText:LOCALIZED_STR(@"No connection") icon:@"connection_off"];
}

- (void)handleEnablingDefaultController {
    [Utilities enableDefaultController:self tableView:menuList menuItems:self.mainMenu];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
