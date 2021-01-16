//
//  HostManagementViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 13/5/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import "HostManagementViewController.h"
#import "HostViewController.h"
#import "AppDelegate.h"
#import "mainMenu.h"
#import "AppInfoViewController.h"

// +2 to cover two single-line separators
#define HOSTMANAGERVC_MSG_HEIGHT (supportedVersionView.frame.size.height + 2)

@interface HostManagementViewController ()

@end

@implementation HostManagementViewController

@synthesize hostController;
@synthesize mainMenu;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

#pragma mark - Button Mamagement

-(IBAction)addHost:(id)sender{
    if (self.hostController == nil) {
        self.hostController = [[HostViewController alloc] initWithNibName:@"HostViewController" bundle:nil];
    }
    self.hostController.detailItem = nil;
    [self.navigationController pushViewController:self.hostController animated:YES];
}

-(void)modifyHost:(NSIndexPath *)item{
    if (storeServerSelection && item.row == storeServerSelection.row){
        UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:item];
        [(UIImageView *)[cell viewWithTag:1] setImage:[UIImage imageNamed:@"connection_off.png"]];
        [serverListTableView deselectRowAtIndexPath:item animated:YES];
        cell.accessoryType = UITableViewCellAccessoryNone;
        storeServerSelection = nil;
        [AppDelegate instance].obj.serverDescription = @"";
        [AppDelegate instance].obj.serverUser = @"";
        [AppDelegate instance].obj.serverPass = @"";
        [AppDelegate instance].obj.serverIP = @"";
        [AppDelegate instance].obj.serverPort = @"";
        [AppDelegate instance].obj.serverHWAddr = @"";
        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerHasChanged" object: nil]; 
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        if (standardUserDefaults) {
            [standardUserDefaults setObject:[NSNumber numberWithInt:-1] forKey:@"lastServer"];
            [standardUserDefaults synchronize];
        }
        [connectingActivityIndicator stopAnimating];
    }
    if (self.hostController == nil) {
        self.hostController = [[HostViewController alloc] initWithNibName:@"HostViewController" bundle:nil] ;
    }
    self.hostController.detailItem = item;
    [self.navigationController pushViewController:self.hostController animated:YES];
}

#pragma mark - Table view methods & data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if ([[AppDelegate instance].arrayServerList count] == 0 && !tableView.editing) {
        return 1; 
    }
    return [[AppDelegate instance].arrayServerList count];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=nil;
    cell = [tableView dequeueReusableCellWithIdentifier:@"serverListCell"];
    [[NSBundle mainBundle] loadNibNamed:@"serverListCellView" owner:self options:NULL];
    if (cell==nil){
        cell = serverListCell;
        [(UILabel*) [cell viewWithTag:2] setHighlightedTextColor:[UIColor blackColor]];
        [(UILabel*) [cell viewWithTag:3] setHighlightedTextColor:[UIColor blackColor]];
        [cell setTintColor:[UIColor lightGrayColor]];
        cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    if ([[AppDelegate instance].arrayServerList count] == 0){
        [(UIImageView*) [cell viewWithTag:1] setHidden:TRUE];
        UILabel *cellLabel=(UILabel*) [cell viewWithTag:2];
        UILabel *cellIP=(UILabel*) [cell viewWithTag:3];
        cellLabel.textAlignment=NSTextAlignmentCenter;
        [cellLabel setText:NSLocalizedString(@"No saved hosts found", nil)];
        [cellIP setText:@""];
        cell.accessoryType=UITableViewCellAccessoryNone;
        return cell;
    }
    else{
        [(UIImageView*) [cell viewWithTag:1] setHidden:FALSE];
        UILabel *cellLabel=(UILabel*) [cell viewWithTag:2];
        UILabel *cellIP=(UILabel*) [cell viewWithTag:3];
        cellLabel.textAlignment=NSTextAlignmentLeft;
        NSDictionary *item=[[AppDelegate instance].arrayServerList objectAtIndex:indexPath.row];
        [cellLabel setText:[item objectForKey:@"serverDescription"]];
        [cellIP setText:[item objectForKey:@"serverIP"]];
        NSIndexPath *selection = [serverListTableView indexPathForSelectedRow];
        if (selection && indexPath.row == selection.row){
            cell.accessoryType=UITableViewCellAccessoryCheckmark;
            if ([AppDelegate instance].serverOnLine == YES) {
                if ([AppDelegate instance].serverTCPConnectionOpen == YES) {
                    [(UIImageView *)[cell viewWithTag:1] setImage:[UIImage imageNamed:@"connection_on.png"]];
                }
                else {
                    [(UIImageView *)[cell viewWithTag:1] setImage:[UIImage imageNamed:@"connection_on_notcp.png"]];
                }
            }
        }
        else {
            cell.accessoryType=UITableViewCellAccessoryNone;
        }
    }
    return cell;
}

static inline BOOL IsEmpty(id obj) {
    return obj == nil
    || ([obj respondsToSelector:@selector(length)]
        && [(NSData *)obj length] == 0)
    || ([obj respondsToSelector:@selector(count)]
        && [(NSArray *)obj count] == 0);
}

-(void)selectServerAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *item = [[AppDelegate instance].arrayServerList objectAtIndex:indexPath.row];
    [AppDelegate instance].obj.serverDescription = IsEmpty([item objectForKey:@"serverDescription"]) ? @"" : [item objectForKey:@"serverDescription"];
    [AppDelegate instance].obj.serverUser = IsEmpty([item objectForKey:@"serverUser"]) ? @"" : [item objectForKey:@"serverUser"];
    [AppDelegate instance].obj.serverPass = IsEmpty([item objectForKey:@"serverPass"]) ? @"" : [item objectForKey:@"serverPass"];
    [AppDelegate instance].obj.serverIP = IsEmpty([item objectForKey:@"serverIP"]) ? @"" : [item objectForKey:@"serverIP"];
    [AppDelegate instance].obj.serverPort = IsEmpty([item objectForKey:@"serverPort"]) ? @"" : [item objectForKey:@"serverPort"];
    [AppDelegate instance].obj.serverHWAddr = IsEmpty([item objectForKey:@"serverMacAddress"]) ? @"" : [item objectForKey:@"serverMacAddress"];
    [AppDelegate instance].obj.preferTVPosters = [[item objectForKey:@"preferTVPosters"] boolValue];
    [AppDelegate instance].obj.tcpPort = [[item objectForKey:@"tcpPort"] intValue];
}

-(void)deselectServerAtIndexPath:(NSIndexPath *)indexPath{
    [connectingActivityIndicator stopAnimating];
    UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:indexPath];
    [serverListTableView deselectRowAtIndexPath:indexPath animated:YES];
    cell.accessoryType = UITableViewCellAccessoryNone;
    storeServerSelection = nil;
    [AppDelegate instance].obj.serverDescription = @"";
    [AppDelegate instance].obj.serverUser = @"";
    [AppDelegate instance].obj.serverPass = @"";
    [AppDelegate instance].obj.serverIP = @"";
    [AppDelegate instance].obj.serverPort = @"";
    [AppDelegate instance].obj.serverHWAddr = @"";
    [AppDelegate instance].serverOnLine = NO;
    [AppDelegate instance].obj.tcpPort = 0;
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if (standardUserDefaults) {
        [standardUserDefaults setObject:[NSNumber numberWithInt:-1] forKey:@"lastServer"];
        [standardUserDefaults synchronize];
    }
    [(UIImageView *)[cell viewWithTag:1] setImage:[UIImage imageNamed:@"connection_off.png"]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    doRevealMenu = YES;
    if ([[AppDelegate instance].arrayServerList count] == 0){
        [serverListTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else{
        NSIndexPath *selection = [serverListTableView indexPathForSelectedRow];
        if (storeServerSelection && selection.row == storeServerSelection.row){
            [self deselectServerAtIndexPath:indexPath];
        }
        else{
            storeServerSelection = indexPath;
            [connectingActivityIndicator startAnimating];
            UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [self selectServerAtIndexPath:indexPath];
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            if (standardUserDefaults) {
                [standardUserDefaults setObject:[NSNumber numberWithInt:(int)indexPath.row] forKey:@"lastServer"];
                [standardUserDefaults synchronize];
            }
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerHasChanged" object: nil]; 
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType=UITableViewCellAccessoryNone;
    [(UIImageView *)[cell viewWithTag:1] setImage:[UIImage imageNamed:@"connection_off.png"]];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (aTableView.editing) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
	if (editingStyle == UITableViewCellEditingStyleDelete){
        [[AppDelegate instance].arrayServerList removeObjectAtIndex:indexPath.row];
        [[AppDelegate instance] saveServerList];
        if (storeServerSelection){
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            if (indexPath.row<storeServerSelection.row){
                storeServerSelection=[NSIndexPath  indexPathForRow:storeServerSelection.row-1 inSection:storeServerSelection.section];
                if (standardUserDefaults) {
                    [standardUserDefaults setObject:[NSNumber numberWithInt:(int)storeServerSelection.row] forKey:@"lastServer"];
                    [standardUserDefaults synchronize];
                }
            }
            else if (storeServerSelection.row==indexPath.row){
                storeServerSelection=nil;
                [AppDelegate instance].obj.serverDescription = @"";
                [AppDelegate instance].obj.serverUser = @"";
                [AppDelegate instance].obj.serverPass = @"";
                [AppDelegate instance].obj.serverIP = @"";
                [AppDelegate instance].obj.serverPort = @"";
                [AppDelegate instance].obj.serverHWAddr = @"";
                [AppDelegate instance].obj.tcpPort = 0;
                [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerHasChanged" object: nil];
                [standardUserDefaults setObject:[NSNumber numberWithInt:-1] forKey:@"lastServer"];
                [standardUserDefaults synchronize];
            }
        }
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
	}   
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
//    UIImage *myImage = [UIImage imageNamed:@"blank.png"];
//	UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
//	imageView.frame = CGRectMake(0,0,320,8);
//	return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
//    UIImage *myImage = [UIImage imageNamed:@"blank.png"];
//	UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
//	imageView.frame = CGRectMake(0,0,320,8);
//	return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    [self modifyHost:indexPath];
}

-(IBAction)editTable:(id)sender forceClose:(BOOL)forceClose{
    if (sender != nil){
        forceClose = FALSE;
    }
    if ([[AppDelegate instance].arrayServerList count] == 0 && !serverListTableView.editing) return;
    if (serverListTableView.editing == YES || forceClose == YES){
        [serverListTableView setEditing:NO animated:YES];
        [editTableButton setSelected:NO];
        if ([[AppDelegate instance].arrayServerList count] == 0)
            [serverListTableView reloadData];
        if (storeServerSelection){
            [serverListTableView selectRowAtIndexPath:storeServerSelection animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:storeServerSelection];
            cell.accessoryType=UITableViewCellAccessoryCheckmark;
        }
    }
    else{
        [serverListTableView setEditing:YES animated:YES];
        [editTableButton setSelected:YES];
    }
}

#pragma mark - Long Press & Action sheet

-(IBAction)handleLongPress{
    if (lpgr.state == UIGestureRecognizerStateBegan){
        CGPoint p = [lpgr locationInView:serverListTableView];
        NSIndexPath *indexPath = [serverListTableView indexPathForRowAtPoint:p];
        if (indexPath != nil && indexPath.row<[[AppDelegate instance].arrayServerList count]){
            [self modifyHost:indexPath];
        }
    }
}

#pragma mark - TableManagement instances 

-(void)selectIndex:(NSIndexPath *)selection reloadData:(BOOL)reload{
    if (reload){
        NSIndexPath *checkSelection = [serverListTableView indexPathForSelectedRow];
        [serverListTableView reloadData];
        if (checkSelection){
            [serverListTableView selectRowAtIndexPath:checkSelection animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:checkSelection];
            storeServerSelection = checkSelection;
            cell.accessoryType=UITableViewCellAccessoryCheckmark;
        }
    }
    else if (selection){
        storeServerSelection = selection;
        [self selectServerAtIndexPath:selection];
        [serverListTableView selectRowAtIndexPath:selection animated:NO scrollPosition:UITableViewScrollPositionNone];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerHasChanged" object: nil];
    }
}

- (void)infoView{
    if (appInfoView==nil)
        appInfoView = [[AppInfoViewController alloc] initWithNibName:@"AppInfoViewController" bundle:nil] ;
    if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 13) {
        appInfoView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    } else {
        appInfoView.modalTransitionStyle = UIModalTransitionStylePartialCurl;
    }
    [self.navigationController presentViewController:appInfoView animated:YES completion:nil];
}

#pragma mark - LifeCycle

- (void)viewWillAppear:(BOOL)animated{
    CGSize size = CGSizeMake(320, 400); // size of view in popover
    self.preferredContentSize = size;
    [super viewWillAppear:animated];
    [self selectIndex:nil reloadData:YES];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.slidingViewController.underRightViewController = nil;
        RightMenuViewController *rightMenuViewController = [[RightMenuViewController alloc] initWithNibName:@"RightMenuViewController" bundle:nil];
        rightMenuViewController.rightMenuItems = [AppDelegate instance].rightMenuItems;
        self.slidingViewController.underRightViewController = rightMenuViewController;
        if (![self.slidingViewController.underLeftViewController isKindOfClass:[MasterViewController class]]) {
            MasterViewController *masterViewController = [[MasterViewController alloc] initWithNibName:@"MasterViewController" bundle:nil];
            masterViewController.mainMenu = self.mainMenu;
            self.slidingViewController.underLeftViewController = masterViewController;
        }
        [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    }
    else{
        UIImageView *xbmcLogoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bottom_logo_up.png"]];
        self.navigationItem.titleView = xbmcLogoView;
    }
}

- (void)revealMenu:(NSNotification *)note{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)revealUnderRight:(NSNotification *)note{
    [self.slidingViewController anchorTopViewTo:ECLeft];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    CGFloat deltaY = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        deltaY = 0;
    }
    CGFloat bottomPadding = 0;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        bottomPadding = window.safeAreaInsets.bottom;
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        bottomPadding = 10;
    }
    CGRect frame = bottomToolbar.frame;
    frame.origin.y -= bottomPadding;
    frame.size.height += bottomPadding;
    [bottomToolbar setFrame:frame];
    
    frame = bottomToolbarShadowImageView.frame;
    frame.origin.y -= bottomPadding;
    [bottomToolbarShadowImageView setFrame:frame];
    
    frame = addHostButton.frame;
    frame.origin.y -= bottomPadding;
    [addHostButton setFrame:frame];
    
    frame = editTableButton.frame;
    frame.origin.y -= bottomPadding;
    [editTableButton setFrame:frame];
    
    messagesView = [[MessagesView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HOSTMANAGERVC_MSG_HEIGHT + deltaY) deltaY:deltaY deltaX:0];
    [messagesView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    [self.view addSubview:messagesView];
    [addHostButton setTitle:NSLocalizedString(@"Add Host", nil) forState:UIControlStateNormal];
    addHostButton.titleLabel.numberOfLines = 1;
    addHostButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    addHostButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
    [editTableButton setTitle:NSLocalizedString(@"Edit",nil) forState:UIControlStateNormal];
    [editTableButton setTitle:NSLocalizedString(@"Done",nil) forState:UIControlStateSelected];
    editTableButton.titleLabel.numberOfLines = 1;
    editTableButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    editTableButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
    [supportedVersionLabel setText:NSLocalizedString(@"Supported XBMC version is Eden (11) or higher", nil)];
    [self.navigationController.navigationBar setBarTintColor:BAR_TINT_COLOR];
    
    [editTableButton setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateNormal];
    [editTableButton setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateHighlighted];
    [editTableButton setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateSelected];
    [editTableButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [editTableButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [editTableButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [editTableButton.titleLabel setShadowOffset:CGSizeMake(0, 0)];
    
    [addHostButton setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateNormal];
    [addHostButton setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateHighlighted];
    [addHostButton setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateSelected];
    [addHostButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [addHostButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [addHostButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [addHostButton.titleLabel setShadowOffset:CGSizeMake(0, 0)];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.edgesForExtendedLayout = 0;
        self.view.tintColor = APP_TINT_COLOR;
        CGRect frame = backgroundImageView.frame;
        frame.size.height = frame.size.height + 8;
        backgroundImageView.frame = frame;
        [self.view setBackgroundColor:[UIColor blackColor]];
        [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
        [self.navigationController.navigationBar setTintColor:TINT_COLOR];
    }
    else{
        int barHeight = 44;
        int statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
        
        CGRect frame = supportedVersionView.frame;
        frame.origin.y = frame.origin.y + barHeight + statusBarHeight;
        supportedVersionView.frame = frame;
        
        frame = serverListTableView.frame;
        frame.origin.y = frame.origin.y + barHeight + statusBarHeight;
        frame.size.height = frame.size.height - (barHeight + statusBarHeight) - bottomPadding;
        serverListTableView.frame = frame;
        
        frame = connectingActivityIndicator.frame;
        frame.origin.y = frame.origin.y + barHeight + statusBarHeight;
        connectingActivityIndicator.frame = frame;
        
        UIButton *xbmcLogo = [[UIButton alloc] initWithFrame:CGRectMake(688, 964, 107, 37)];
        [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_up_iphone.png"] forState:UIControlStateNormal];
        [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_up_iphone.png"] forState:UIControlStateHighlighted];
        xbmcLogo.showsTouchWhenHighlighted = NO;
        [xbmcLogo addTarget:self action:@selector(infoView) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.titleView = xbmcLogo;
        UIImage* menuImg = [UIImage imageNamed:@"button_menu.png"];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:menuImg style:UIBarButtonItemStylePlain target:nil action:@selector(revealMenu:)];
        UIImage* settingsImg = [UIImage imageNamed:@"button_settings.png"];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:settingsImg style:UIBarButtonItemStylePlain target:nil action:@selector(revealUnderRight:)];
    }
    doRevealMenu = YES;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    int lastServer;
    if ([userDefaults objectForKey:@"lastServer"]!=nil){
        lastServer=[[userDefaults objectForKey:@"lastServer"] intValue];
        if (lastServer > -1 && lastServer < [[AppDelegate instance].arrayServerList count]){
            NSIndexPath *lastServerIndexPath=[NSIndexPath indexPathForRow:lastServer inSection:0];
            if (![AppDelegate instance].serverOnLine){
                [self selectIndex:lastServerIndexPath reloadData:NO];
                [connectingActivityIndicator startAnimating];
            }
            else{
                [self selectServerAtIndexPath:lastServerIndexPath];
                [serverListTableView selectRowAtIndexPath:lastServerIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(revealMenu:)
                                                 name: @"RevealMenu"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(revealUnderRight:)
                                                 name: @"revealUnderRight"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(connectionSuccess:)
                                                 name: @"XBMCServerConnectionSuccess"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(connectionFailed:)
                                                 name: @"XBMCServerConnectionFailed"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(resetDoReveal:)
                                                 name: @"ECSlidingViewUnderRightWillAppear"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(authFailed:)
                                                 name: @"XBMCServerAuthenticationFailed"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(connectionError:)
                                                 name: @"XBMCServerConnectionError"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(tcpJSONRPCConnectionError:)
                                                 name: @"tcpJSONRPCConnectionError"
                                               object: nil];
    
    
}

-(void)tcpJSONRPCConnectionError:(NSNotification *)note {
    BOOL showConnectionNotice = NO;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    NSString *showConnectionNoticeString = [userDefaults objectForKey:@"connection_info_preference"];
    if (showConnectionNoticeString == nil || [showConnectionNoticeString boolValue]) {
        showConnectionNotice = YES;
    }
    if (showConnectionNotice == YES && [AppDelegate instance].serverOnLine == YES) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Kodi connection notice", nil)
                                              message:[NSString stringWithFormat:@"%@\n\n%@", NSLocalizedString(@"It seems that the TCP connection with Kodi cannot be established. This will prevent the app from listening to Kodi. For example, the keyboard input within the app will not show when Kodi requests keyboard input.", nil), NSLocalizedString(@"Do you want to enable this connection now?", nil)]
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *action) {}];
        
        UIAlertAction *dontShowAction = [UIAlertAction
                                         actionWithTitle:NSLocalizedString(@"Don't show this message again", nil)
                                         style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction *action) {
                                             [self disableTCPconnectionNotice];
                                         }];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Enable TCP connection on Kodi", nil)
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action) {
                                       [self enableTCPconnection];
                                   }];
        
        [alertController addAction:cancelAction];
        [alertController addAction:dontShowAction];
        [alertController addAction:okAction];
        id presentingView = self.presentingViewController == nil ? self : self.presentingViewController;
        [presentingView presentViewController:alertController animated:YES completion:nil];
    }
}

-(void)disableTCPconnectionNotice {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    [userDefaults setObject:[NSNumber numberWithBool:NO] forKey:@"connection_info_preference"];
}

-(void)enableTCPconnection {
    jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    NSString *methodToCall = @"Settings.SetSettingValue";
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"services.esallinterfaces", @"setting",
                                [NSNumber numberWithBool:YES], @"value",
                                nil];
    [jsonRPC callMethod: methodToCall
         withParameters: parameters
           onCompletion: ^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               if ( error == nil && methodError == nil ) {
                   [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationWillEnterForegroundNotification" object:nil userInfo:nil];
               }
               else {
                   UIAlertController *alertController = [UIAlertController
                                                         alertControllerWithTitle:NSLocalizedString(@"Cannot do that", nil)
                                                         message:nil
                                                         preferredStyle:UIAlertControllerStyleAlert];

                   UIAlertAction *okAction = [UIAlertAction
                                              actionWithTitle:NSLocalizedString(@"OK", nil)
                                              style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *action) {}];
                   [alertController addAction:okAction];
                   id presentingView = self.presentingViewController == nil ? self : self.presentingViewController;
                   [presentingView presentViewController:alertController animated:YES completion:nil];
               }
           }
     ];
}

-(void)connectionError:(NSNotification *)note {
    NSDictionary *theData = [note userInfo];
    [messagesView showMessage:[theData objectForKey:@"error_message"] timeout:2.0f color:[UIColor colorWithRed:189.0f/255.0f green:36.0f/255.0f blue:36.0f/255.0f alpha:0.95f]];
}

-(void)authFailed:(NSNotification *)note {
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Authentication Failed", nil) message:NSLocalizedString(@"Incorrect Username or Password.\nCheck your settings.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    [alertView show];
    [self modifyHost:storeServerSelection];
}

-(void)resetDoReveal:(NSNotification *)note {
    doRevealMenu = NO;
}

- (void)connectionSuccess:(NSNotification *)note {
    NSDictionary *theData = [note userInfo];
    if (storeServerSelection != nil) {
        UITableViewCell *cell  = [serverListTableView cellForRowAtIndexPath:storeServerSelection];
        [(UIImageView *)[cell viewWithTag:1] setImage:[UIImage imageNamed:[theData objectForKey:@"icon_connection"]]];
    }
    [connectingActivityIndicator stopAnimating];
    if (doRevealMenu) [self revealMenu:nil];
}

- (void)connectionFailed:(NSNotification *)note {
    NSDictionary *theData = [note userInfo];
    if (storeServerSelection != nil){
        UITableViewCell *cell  = [serverListTableView cellForRowAtIndexPath:storeServerSelection];
        [(UIImageView *)[cell viewWithTag:1] setImage:[UIImage imageNamed:[theData objectForKey:@"icon_connection"]]];
    }
}

- (void)viewDidUnload{
    connectingActivityIndicator = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)shouldAutorotate{
    return YES;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc {
    jsonRPC = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
