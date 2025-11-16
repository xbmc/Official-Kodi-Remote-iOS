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
#import "InitialSlidingViewController.h"
#import "AppInfoViewController.h"
#import "tcpJSONRPC.h"
#import "Utilities.h"

#define MENU_ICON_SIZE 30
#define ICON_MARGIN 10
#define CONNECTION_STATUS_PADDING 4
#define CONNECTION_STATUS_SIZE 8

@interface MasterViewController () {
    NSMutableArray *_objects;
    NSMutableArray *mainMenu;
}
@end

@implementation MasterViewController

@synthesize mainMenu;
	
- (void)changeServerStatus:(BOOL)status infoText:(NSString*)infoText icon:(NSString*)iconName {
    [super changeServerStatus:status infoText:infoText icon:iconName];
    itemIsActive = NO;
    [Utilities setStyleOfMenuItems:menuList active:status menu:self.mainMenu];
}

#pragma mark - Table view methods & data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return self.mainMenu.count;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    mainMenu *menuItem = self.mainMenu[indexPath.row];
    [Utilities setStyleOfMenuItemCell:cell active:AppDelegate.instance.serverOnLine menuType:menuItem.type];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mainMenuCellIdentifier"];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"cellView" owner:self options:nil];
        cell = nib[0];
        
        // Set background view
        UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
        backgroundView.backgroundColor = MAINMENU_SELECTED_COLOR;
        cell.selectedBackgroundView = backgroundView;
    }
    mainMenu *item = self.mainMenu[indexPath.row];
    NSString *iconName = item.icon;
    UIImageView *icon = (UIImageView*)[cell viewWithTag:XIB_MAIN_MENU_CELL_ICON];
    UILabel *title = (UILabel*)[cell viewWithTag:XIB_MAIN_MENU_CELL_TITLE];
    if (indexPath.row == 0) {
        // Adapt layout for first cell (showing connection status)
        [self setFrameSizes:cell height:PHONE_MENU_INFO_HEIGHT iconsize:MENU_ICON_SIZE];
        
        // Set icon, background color and text content
        title.font = [UIFont fontWithName:@"Roboto-Regular" size:13];
        title.numberOfLines = 2;
        title.text = [Utilities getConnectionStatusServerName];
        [self setConnectionIcon:icon];
        cell.backgroundColor = UIColor.clearColor;
    }
    else {
        // Adapt layout for main menu cells
        [self setFrameSizes:cell height:PHONE_MENU_HEIGHT iconsize:MENU_ICON_SIZE];
        
        // Set icon, background color and text content
        title.font = [UIFont fontWithName:@"Roboto-Regular" size:20];
        title.numberOfLines = 1;
        title.text = item.mainLabel;
        icon.highlightedImage = [UIImage imageNamed:iconName];
        icon.image = [icon.highlightedImage colorizeWithColor:UIColor.grayColor];
        cell.backgroundColor = UIColor.clearColor;
    }
    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    mainMenu *item = self.mainMenu[indexPath.row];
    if (item.family == FamilyAppSettings) {
        [self enterAppSettings];
        
        // Unselect App Settings again immediately. We leave the app, there is no active submenu.
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    else if (!AppDelegate.instance.serverOnLine && item.family != FamilyServer) {
        [menuList selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
        return;
    }
    else if (itemIsActive) {
        return;
    }
    
    // Mark the active menu as selected
    [menuList selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    
    itemIsActive = YES;
    UIViewController *object;
    BOOL hideBottonLine = NO;
    switch (item.family) {
        case FamilyNowPlaying:
        {
            NowPlaying *nowPlayingController = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
            nowPlayingController.detailItem = item;
            object = nowPlayingController;
            break;
        }
        case FamilyRemote:
        {
            RemoteController *remoteController = [[RemoteController alloc] initWithNibName:@"RemoteController" withEmbedded:NO bundle:nil];
            remoteController.detailItem = item;
            object = remoteController;
            break;
        }
        case FamilyServer:
        {
            HostManagementViewController *hostController = [[HostManagementViewController alloc] initWithNibName:@"HostManagementViewController" bundle:nil];
            object = hostController;
            hideBottonLine = YES;
            break;
        }
        case FamilyDetailView:
        {
            DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
            detailViewController.detailItem = item;
            object = detailViewController;
            hideBottonLine = YES;
            break;
        }
        default:
            break;
    }
    CustomNavigationController *navController = [[CustomNavigationController alloc] initWithRootViewController:object];
    navController.navigationBar.barStyle = UIBarStyleBlack;
    navController.navigationBar.tintColor = ICON_TINT_COLOR;
    UIImage *menuImg = [UIImage imageNamed:@"button_menu"];
    object.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:menuImg 
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:nil
                                                                              action:@selector(handleMenuButton)];
    
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
        
        // Add connection status icon to root view of new controller
        [self addConnectionStatusToRootView];
        
        // Add MessagesView to root view to be able to show messages on top
        [self addMessagesToRootView];
    }];
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
    return NO;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.row == 0) {
        return PHONE_MENU_INFO_HEIGHT;
    }
    return PHONE_MENU_HEIGHT;
}

#pragma mark - Helper

- (void)addMessagesToRootView {
    // Add MessagesView to root view to be able to show messages on top
    UIView *rootView = [Utilities topMostControllerIgnoringClass:[UIAlertController class]].view;
    [rootView addSubview:messagesView];
}

- (void)addConnectionStatusToRootView {
    // Add connection status icon to root view of new controller
    UIView *rootView = UIApplication.sharedApplication.keyWindow.rootViewController.view;
    [rootView addSubview:globalConnectionStatus];
}

- (void)setConnectionIcon:(UIImageView*)icon {
    // Load icon for top row in main menu
    UIColor *iconColor = AppDelegate.instance.serverOnLine ? KODI_BLUE_COLOR : UIColor.grayColor;
    UIImage *image = [[UIImage imageNamed:@"st_kodi_action"] colorizeWithColor:iconColor];
    icon.highlightedImage = image;
    icon.image = image;
    
    // Load icon for global connection status
    NSString *statusIconName = [Utilities getConnectionStatusIconName];
    globalConnectionStatus.image = [UIImage imageNamed:statusIconName];
}

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

#pragma mark - LifeCycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.slidingViewController.anchorRightPeekAmount = ANCHOR_RIGHT_PEEK;
    self.slidingViewController.underLeftWidthLayout = ECFullWidth;
    
    // Update dimension of message view
    CGFloat deltaY = [Utilities getTopPadding];
    [messagesView updateWithFrame:CGRectMake(0,
                                             0,
                                             UIScreen.mainScreen.bounds.size.width,
                                             DEFAULT_MSG_HEIGHT + deltaY)
                           deltaY:deltaY
                           deltaX:0];
    [self addMessagesToRootView];
    
    [self addConnectionStatusToRootView];
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
    
    AppDelegate.instance.obj = [GlobalData getInstance];
    menuList.scrollsToTop = NO;
    
    // Add connection status icon to root view
    globalConnectionStatus = [[UIImageView alloc] initWithFrame:CGRectMake(CONNECTION_STATUS_PADDING,
                                                                           [Utilities getTopPadding],
                                                                           CONNECTION_STATUS_SIZE,
                                                                           CONNECTION_STATUS_SIZE)];
    
    messagesView = [[MessagesView alloc] initWithFrame:CGRectZero deltaY:0 deltaX:0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleEnablingDefaultController)
                                                 name:@"KodiStartDefaultController"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showNotificationMessage:)
                                                 name:@"UIShowMessage"
                                               object:nil];
    
    [menuList selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
}

- (void)showNotificationMessage:(NSNotification*)note {
    NSDictionary *params = note.userInfo;
    UIViewController *activeVC = [Utilities topMostControllerIgnoringClass:[UIAlertController class]];
    if (!params || self.slidingViewController.underLeftShowing || [activeVC isKindOfClass:[AppInfoViewController class]]) {
        return;
    }
    [self addMessagesToRootView];
    [messagesView showMessage:params[@"message"] timeout:2.0 color:params[@"color"]];
}

- (void)connectionStatus:(NSNotification*)note {
    [super connectionStatus:note];
    NSDictionary *theData = note.userInfo;
    NSString *infoText = theData[@"message"];
    UITableViewCell *cell = [menuList cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UIImageView *icon = (UIImageView*)[cell viewWithTag:XIB_MAIN_MENU_CELL_ICON];
    [self setConnectionIcon:icon];
    UILabel *title = (UILabel*)[cell viewWithTag:XIB_MAIN_MENU_CELL_TITLE];
    title.text = infoText;
}

- (void)handleEnablingDefaultController {
    [Utilities enableDefaultController:self tableView:menuList menuItems:self.mainMenu];
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
