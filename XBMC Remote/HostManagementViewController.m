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
#import "Utilities.h"

// + 2 to cover two single-line separators
#define HOSTMANAGERVC_MSG_HEIGHT (supportedVersionView.frame.size.height + 2)
#define MARGIN 5
#define BLOCK_MARGIN 10
#define IPAD_POPOVER_WIDTH 400
#define IPAD_POPOVER_HEIGHT 500

#define XIB_HOST_MGMT_CELL_ICON 1
#define XIB_HOST_MGMT_CELL_LABEL 2
#define XIB_HOST_MGMT_CELL_IP 3
#define XIB_HOST_MGMT_CELL_NO_SERVER_FOUND 4

@interface HostManagementViewController ()

@end

@implementation HostManagementViewController

@synthesize mainMenu;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

#pragma mark - Button Management

- (IBAction)addHost:(id)sender {
    serverInfoView.hidden = YES;
    [serverInfoTimer invalidate];
    HostViewController *hostController = [[HostViewController alloc] initWithNibName:@"HostViewController" bundle:nil];
    hostController.detailItem = nil;
    [self.navigationController pushViewController:hostController animated:YES];
    [serverListTableView setEditing:NO animated:YES];
}

- (void)modifyHost:(NSIndexPath*)item {
    if (storeServerSelection && item.row == storeServerSelection.row) {
        UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:item];
        ((UIImageView*)[cell viewWithTag:XIB_HOST_MGMT_CELL_ICON]).image = [UIImage imageNamed:@"connection_off"];
        [serverListTableView deselectRowAtIndexPath:item animated:YES];
        cell.accessoryType = UITableViewCellAccessoryNone;
        storeServerSelection = nil;
        AppDelegate.instance.obj.serverDescription = @"";
        AppDelegate.instance.obj.serverUser = @"";
        AppDelegate.instance.obj.serverPass = @"";
        AppDelegate.instance.obj.serverRawIP = @"";
        AppDelegate.instance.obj.serverIP = @"";
        AppDelegate.instance.obj.serverPort = @"";
        AppDelegate.instance.obj.serverHWAddr = @"";
        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerHasChanged" object: nil];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject: @(-1) forKey:@"lastServer"];
        [connectingActivityIndicator stopAnimating];
    }
    HostViewController *hostController = [[HostViewController alloc] initWithNibName:@"HostViewController" bundle:nil];
    hostController.detailItem = item;
    [self.navigationController pushViewController:hostController animated:YES];
}

#pragma mark - Table view methods & data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if (AppDelegate.instance.arrayServerList.count == 0 && !tableView.editing) {
        return 1;
    }
    return AppDelegate.instance.arrayServerList.count;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    cell.backgroundColor = UIColor.clearColor;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"serverListCellIdentifier"];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"serverListCellView" owner:self options:nil];
        cell = nib[0];
        UILabel *cellNoServerFound = (UILabel*)[cell viewWithTag:XIB_HOST_MGMT_CELL_NO_SERVER_FOUND];
        UILabel *cellLabel = (UILabel*)[cell viewWithTag:XIB_HOST_MGMT_CELL_LABEL];
        UILabel *cellIP = (UILabel*)[cell viewWithTag:XIB_HOST_MGMT_CELL_IP];
        
        cellNoServerFound.highlightedTextColor = [Utilities get1stLabelColor];
        cellLabel.highlightedTextColor = [Utilities get1stLabelColor];
        cellIP.highlightedTextColor = [Utilities get1stLabelColor];
        
        cellNoServerFound.textColor = [Utilities getSystemGray1];
        cellLabel.textColor = [Utilities getSystemGray1];
        cellIP.textColor = [Utilities getSystemGray1];
        
        cell.tintColor = UIColor.lightGrayColor;
        cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        if (@available(iOS 13.0, *)) {
            cell.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        }
    }
    UIImageView *iconView = (UIImageView*)[cell viewWithTag:XIB_HOST_MGMT_CELL_ICON];
    UILabel *cellNoServerFound = (UILabel*)[cell viewWithTag:XIB_HOST_MGMT_CELL_NO_SERVER_FOUND];
    UILabel *cellLabel = (UILabel*)[cell viewWithTag:XIB_HOST_MGMT_CELL_LABEL];
    UILabel *cellIP = (UILabel*)[cell viewWithTag:XIB_HOST_MGMT_CELL_IP];
    if (AppDelegate.instance.arrayServerList.count == 0) {
        iconView.hidden = YES;
        cellNoServerFound.hidden = NO;
        cellNoServerFound.text = LOCALIZED_STR(@"No saved hosts found");
        cellLabel.text = @"";
        cellIP.text = @"";
        cell.accessoryType = UITableViewCellAccessoryNone;
        editTableButton.enabled = NO;
        return cell;
    }
    else {
        iconView.hidden = NO;
        cellNoServerFound.hidden = YES;
        cellLabel.textAlignment = NSTextAlignmentLeft;
        NSDictionary *item = AppDelegate.instance.arrayServerList[indexPath.row];
        cellLabel.text = item[@"serverDescription"];
        cellIP.text = item[@"serverIP"];
        NSIndexPath *selection = [serverListTableView indexPathForSelectedRow];
        if (selection && indexPath.row == selection.row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            NSString *iconName = [Utilities getConnectionStatusIconName];
            iconView.image = [UIImage imageNamed:iconName];
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            iconView.image = [UIImage imageNamed:@"connection_off"];
        }
        editTableButton.enabled = YES;
    }
    return cell;
}

- (void)selectServerAtIndexPath:(NSIndexPath*)indexPath {
    NSDictionary *item = AppDelegate.instance.arrayServerList[indexPath.row];
    AppDelegate.instance.obj.serverDescription = item[@"serverDescription"];
    AppDelegate.instance.obj.serverUser = item[@"serverUser"];
    AppDelegate.instance.obj.serverPass = item[@"serverPass"];
    AppDelegate.instance.obj.serverRawIP = item[@"serverIP"];
    AppDelegate.instance.obj.serverIP = [Utilities getUrlStyleAddress:item[@"serverIP"]];
    AppDelegate.instance.obj.serverPort = item[@"serverPort"];
    AppDelegate.instance.obj.serverHWAddr = item[@"serverMacAddress"];
    AppDelegate.instance.obj.tcpPort = [item[@"tcpPort"] intValue];
}

- (void)deselectServerAtIndexPath:(NSIndexPath*)indexPath {
    [connectingActivityIndicator stopAnimating];
    UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:indexPath];
    [serverListTableView deselectRowAtIndexPath:indexPath animated:YES];
    cell.accessoryType = UITableViewCellAccessoryNone;
    storeServerSelection = nil;
    AppDelegate.instance.obj.serverDescription = @"";
    AppDelegate.instance.obj.serverUser = @"";
    AppDelegate.instance.obj.serverPass = @"";
    AppDelegate.instance.obj.serverRawIP = @"";
    AppDelegate.instance.obj.serverIP = @"";
    AppDelegate.instance.obj.serverPort = @"";
    AppDelegate.instance.obj.serverHWAddr = @"";
    AppDelegate.instance.serverOnLine = NO;
    AppDelegate.instance.obj.tcpPort = 0;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject: @(-1) forKey:@"lastServer"];
    ((UIImageView*)[cell viewWithTag:XIB_HOST_MGMT_CELL_ICON]).image = [UIImage imageNamed:@"connection_off"];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    doRevealMenu = YES;
    if (AppDelegate.instance.arrayServerList.count == 0) {
        [serverListTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else {
        NSIndexPath *selection = [serverListTableView indexPathForSelectedRow];
        if (storeServerSelection && selection.row == storeServerSelection.row) {
            [self deselectServerAtIndexPath:indexPath];
        }
        else {
            storeServerSelection = indexPath;
            [connectingActivityIndicator startAnimating];
            UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [self selectServerAtIndexPath:indexPath];
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject: @(indexPath.row) forKey:@"lastServer"];
            // Trigger Local Network Privacy Alert (if not already done for the App)
            [AppDelegate.instance triggerLocalNetworkPrivacyAlert];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerHasChanged" object: nil];
}

- (void)tableView:(UITableView*)tableView didDeselectRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    ((UIImageView*)[cell viewWithTag:XIB_HOST_MGMT_CELL_ICON]).image = [UIImage imageNamed:@"connection_off"];
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)aTableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (aTableView.editing) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
    return YES;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
        [AppDelegate.instance.arrayServerList removeObjectAtIndex:indexPath.row];
        [AppDelegate.instance saveServerList];
        if (storeServerSelection) {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            if (indexPath.row < storeServerSelection.row) {
                storeServerSelection = [NSIndexPath indexPathForRow:storeServerSelection.row - 1 inSection:storeServerSelection.section];
                [userDefaults setObject: @(storeServerSelection.row) forKey:@"lastServer"];
            }
            else if (storeServerSelection.row == indexPath.row) {
                storeServerSelection = nil;
                AppDelegate.instance.obj.serverDescription = @"";
                AppDelegate.instance.obj.serverUser = @"";
                AppDelegate.instance.obj.serverPass = @"";
                AppDelegate.instance.obj.serverRawIP = @"";
                AppDelegate.instance.obj.serverIP = @"";
                AppDelegate.instance.obj.serverPort = @"";
                AppDelegate.instance.obj.serverHWAddr = @"";
                AppDelegate.instance.obj.tcpPort = 0;
                [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerHasChanged" object: nil];
                [userDefaults setObject: @(-1) forKey:@"lastServer"];
            }
        }
        if (indexPath.row < [tableView numberOfRowsInSection:indexPath.section]) {
            [tableView beginUpdates];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
            [tableView endUpdates];
        }
        // Are there still editable entries?
        editTableButton.selected = editTableButton.enabled = AppDelegate.instance.arrayServerList.count > 0;
	}
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath {
    [self modifyHost:indexPath];
}

- (IBAction)editTable:(id)sender forceClose:(BOOL)forceClose {
    serverInfoView.hidden = YES;
    [serverInfoTimer invalidate];
    if (sender != nil) {
        forceClose = NO;
    }
    if (AppDelegate.instance.arrayServerList.count == 0 && !serverListTableView.editing) {
        return;
    }
    if (serverListTableView.editing || forceClose) {
        [serverListTableView setEditing:NO animated:YES];
        editTableButton.selected = NO;
        if (AppDelegate.instance.arrayServerList.count == 0) {
            [serverListTableView reloadData];
        }
        if (storeServerSelection) {
            [serverListTableView selectRowAtIndexPath:storeServerSelection animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:storeServerSelection];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    else {
        [serverListTableView setEditing:YES animated:YES];
        editTableButton.selected = YES;
    }
}

#pragma mark - Long Press & Action sheet

- (void)handleLongPress {
    serverInfoView.hidden = YES;
    if (longPressGesture.state == UIGestureRecognizerStateBegan) {
        CGPoint origin = [longPressGesture locationInView:serverListTableView];
        NSIndexPath *indexPath = [serverListTableView indexPathForRowAtPoint:origin];
        if (indexPath != nil && indexPath.row < AppDelegate.instance.arrayServerList.count) {
            [self modifyHost:indexPath];
        }
    }
}

#pragma mark - TableManagement instances 

- (void)selectIndex:(NSIndexPath*)selection reloadData:(BOOL)reload {
    if (reload) {
        NSIndexPath *checkSelection = [serverListTableView indexPathForSelectedRow];
        [serverListTableView reloadData];
        if (checkSelection) {
            [serverListTableView selectRowAtIndexPath:checkSelection animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:checkSelection];
            storeServerSelection = checkSelection;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    else if (selection) {
        storeServerSelection = selection;
        [self selectServerAtIndexPath:selection];
        [serverListTableView selectRowAtIndexPath:selection animated:NO scrollPosition:UITableViewScrollPositionNone];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerHasChanged" object: nil];
    }
}

- (void)infoView {
    appInfoView = [[AppInfoViewController alloc] initWithNibName:@"AppInfoViewController" bundle:nil];
    if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 13) {
        appInfoView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    }
    else {
        appInfoView.modalTransitionStyle = UIModalTransitionStylePartialCurl;
    }
    [self.navigationController presentViewController:appInfoView animated:YES completion:nil];
}

- (void)updateServerInfo {
    [[Utilities getJsonRPC]
     callMethod:@"XBMC.GetInfoLabels"
     withParameters:@{@"labels": @[@"System.FriendlyName",
                                   @"System.Date",
                                   @"System.Time",
                                   @"System.FreeSpace",
                                   @"System.UsedSpace",
                                   @"System.TotalSpace",
                                   @"System.UsedSpacePercent",
                                   @"System.FreeSpacePercent",
                                   @"System.CPUTemperature",
                                   @"System.CpuUsage",
                                   @"System.GPUTemperature",
                                   @"System.BuildVersion",
                                   @"System.BuildDate",
                                   @"System.FPS",
                                   @"System.Memory(free)",
                                   @"System.Memory(used)",
                                   @"System.Memory(total)",
                                   @"System.Memory(free.percent)",
                                   @"System.Memory(used.percent)",
                                   @"System.Memory(total)",
                                   @"System.CpuFrequency",
                                   @"System.ScreenResolution",
                                   @"System.HddTemperature",
                                   @"System.OSVersionInfo"]}
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSDictionary class]]) {
            NSMutableAttributedString *infoString = [NSMutableAttributedString new];
            NSAttributedString *newLine = [[NSAttributedString alloc] initWithString:@"\n"];
            [infoString appendAttributedString:[self formatInfo:@"Name" text:methodResult[@"System.FriendlyName"]]];
            [infoString appendAttributedString:[self formatInfo:@"Build" text:methodResult[@"System.BuildVersion"]]];
            [infoString appendAttributedString:[self formatInfo:@"Build Date" text:methodResult[@"System.BuildDate"]]];
            [infoString appendAttributedString:[self formatInfo:@"Server Date" text:methodResult[@"System.Date"]]];
            [infoString appendAttributedString:[self formatInfo:@"Server Time" text:methodResult[@"System.Time"]]];
            [infoString appendAttributedString:newLine];
            [infoString appendAttributedString:[self formatInfo:@"OS" text:methodResult[@"System.OSVersionInfo"]]];
            [infoString appendAttributedString:newLine];
            [infoString appendAttributedString:[self formatInfo:@"Screen" text:methodResult[@"System.ScreenResolution"]]];
            [infoString appendAttributedString:[self formatInfo:@"FPS" text:methodResult[@"System.FPS"]]];
            [infoString appendAttributedString:newLine];
            [infoString appendAttributedString:[self formatInfo:@"CPU Clock" text:methodResult[@"System.CpuFrequency"]]];
            [infoString appendAttributedString:[self formatInfo:@"CPU Load" text:methodResult[@"System.CpuUsage"]]];
            [infoString appendAttributedString:[self formatInfo:@"CPU Temp" text:methodResult[@"System.CPUTemperature"]]];
            [infoString appendAttributedString:[self formatInfo:@"GPU Temp" text:methodResult[@"System.GPUTemperature"]]];
            [infoString appendAttributedString:[self formatInfo:@"HDD Temp" text:methodResult[@"System.HddTemperature"]]];
            [infoString appendAttributedString:newLine];
            NSString *memory = [NSString stringWithFormat:@"%@ Used / %@ Total",
                                methodResult[@"System.Memory(used.percent)"],
                                methodResult[@"System.Memory(total)"]];
            [infoString appendAttributedString:[self formatInfo:@"Memory" text:memory]];
            NSString *storage = [NSString stringWithFormat:@"%@ / %@",
                                methodResult[@"System.UsedSpacePercent"],
                                methodResult[@"System.TotalSpace"]];
            [infoString appendAttributedString:[self formatInfo:@"Storage" text:storage]];
            
            serverInfoView.attributedText = infoString;
        }
        else {
            NSString *errorText = @"";
            if (error) {
                errorText = [NSString stringWithFormat:@"%@\n\n", error.localizedDescription];
            }
            if (methodError) {
                errorText = [NSString stringWithFormat:@"%@%@\n\n", errorText, methodError];
            }
            if (methodResult && ![methodResult isKindOfClass:[NSDictionary class]]) {
                errorText = [NSString stringWithFormat:@"%@Unexpected class '%@' received.", errorText, NSStringFromClass([methodResult class])];
            }
            serverInfoView.attributedText = [self formatInfo:LOCALIZED_STR(@"ERROR") text:errorText];
        }
    }];
}

- (void)showServerInfoView {
    // Toggle visibility of serverInfoViw
    serverInfoView.hidden = !serverInfoView.hidden;
    [serverInfoTimer invalidate];
    if (!serverInfoView.hidden) {
        [self updateServerInfo];
        // Start timer to update the server info view
        serverInfoTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateServerInfo) userInfo:nil repeats:YES];
    }
}

- (NSAttributedString*)formatInfo:(NSString*)name text:(NSString*)text {
    int fontSize = 15;
    // Bold and gray for label
    name = [NSString stringWithFormat:@"%@: ", name];
    NSDictionary *boldFontAttrib = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:fontSize],
        NSForegroundColorAttributeName: UIColor.lightGrayColor,
    };
    // Normal and white for the text
    NSMutableAttributedString *string1 = [[NSMutableAttributedString alloc] initWithString:name attributes:boldFontAttrib];
    text = [NSString stringWithFormat:@"%@\n", text];
    NSDictionary *normalFontAttrib = @{
        NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
        NSForegroundColorAttributeName: UIColor.whiteColor,
    };
    NSMutableAttributedString *string2 = [[NSMutableAttributedString alloc] initWithString:text attributes:normalFontAttrib];
    // Build the complete string
    [string1 appendAttributedString:string2];
    return string1;
}

#pragma mark - LifeCycle

- (void)viewWillAppear:(BOOL)animated {
    CGSize size = CGSizeMake(IPAD_POPOVER_WIDTH, IPAD_POPOVER_HEIGHT); // size of view in popover
    self.preferredContentSize = size;
    [super viewWillAppear:animated];
    if (IS_IPHONE) {
        if (![self.slidingViewController.underLeftViewController isKindOfClass:[MasterViewController class]]) {
            MasterViewController *masterViewController = [[MasterViewController alloc] initWithNibName:@"MasterViewController" bundle:nil];
            masterViewController.mainMenu = self.mainMenu;
            self.slidingViewController.underLeftViewController = masterViewController;
        }
        self.slidingViewController.underRightViewController = nil;
        self.slidingViewController.anchorLeftPeekAmount   = 0;
        self.slidingViewController.anchorLeftRevealAmount = 0;
        self.slidingViewController.panGesture.delegate = self;
        [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    }
    else {
        UIImageView *xbmcLogoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bottom_logo_up"]];
        self.navigationItem.titleView = xbmcLogoView;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self selectIndex:nil reloadData:YES];
}

- (void)revealMenu:(NSNotification*)note {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat deltaY = [Utilities getTopPaddingWithNavBar:self.navigationController];
    if (IS_IPAD) {
        deltaY = 0;
    }
    CGFloat bottomPadding = [Utilities getBottomPadding];
    if (IS_IPAD) {
        bottomPadding = SERVERPOPUP_BOTTOMPADDING;
    }
    CGRect frame = bottomToolbar.frame;
    frame.origin.y -= bottomPadding;
    frame.size.height += bottomPadding;
    bottomToolbar.frame = frame;
    
    frame = bottomToolbarShadowImageView.frame;
    frame.origin.y -= bottomPadding;
    bottomToolbarShadowImageView.frame = frame;
    
    frame = addHostButton.frame;
    frame.origin.y -= bottomPadding;
    addHostButton.frame = frame;
    
    frame = editTableButton.frame;
    frame.origin.y -= bottomPadding;
    editTableButton.frame = frame;
    
    frame = serverInfoButton.frame;
    frame.origin.y -= bottomPadding;
    serverInfoButton.frame = frame;
    
    CGFloat toolbarHeight = bottomToolbar.frame.size.height;
    serverInfoView = [[UITextView alloc] initWithFrame:CGRectMake(MARGIN, deltaY + MARGIN, self.view.frame.size.width - 2 * MARGIN, self.view.frame.size.height - deltaY - toolbarHeight - 2 * MARGIN)];
    serverInfoView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                      UIViewAutoresizingFlexibleHeight |
                                      UIViewAutoresizingFlexibleLeftMargin |
                                      UIViewAutoresizingFlexibleRightMargin;
    serverInfoView.hidden = YES;
    serverInfoView.backgroundColor = UIColor.blackColor;
    serverInfoView.layer.borderColor = UIColor.grayColor.CGColor;
    serverInfoView.layer.borderWidth = 2.0 / UIScreen.mainScreen.scale;
    [self.view addSubview:serverInfoView];
    
    serverInfoButton.titleLabel.numberOfLines = 1;
    serverInfoButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    serverInfoButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
    [serverInfoButton addTarget:self action:@selector(showServerInfoView) forControlEvents:UIControlEventTouchUpInside];
    
    [addHostButton setTitle:LOCALIZED_STR(@"Add Host") forState:UIControlStateNormal];
    addHostButton.titleLabel.numberOfLines = 1;
    addHostButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    addHostButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
    [editTableButton setTitle:LOCALIZED_STR(@"Edit") forState:UIControlStateNormal];
    [editTableButton setTitle:LOCALIZED_STR(@"Done") forState:UIControlStateSelected];
    editTableButton.titleLabel.numberOfLines = 1;
    editTableButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    editTableButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
    supportedVersionLabel.text = LOCALIZED_STR(@"Supported XBMC version is Eden (11) or higher");
    
    editTableButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [editTableButton setTitleColor:UIColor.grayColor forState:UIControlStateDisabled];
    [editTableButton setTitleColor:UIColor.grayColor forState:UIControlStateHighlighted];
    [editTableButton setTitleColor:UIColor.whiteColor forState:UIControlStateSelected];
    editTableButton.titleLabel.shadowOffset = CGSizeZero;
    
    addHostButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [addHostButton setTitleColor:UIColor.grayColor forState:UIControlStateHighlighted];
    [addHostButton setTitleColor:UIColor.whiteColor forState:UIControlStateSelected];
    addHostButton.titleLabel.shadowOffset = CGSizeZero;
    
    serverInfoButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [serverInfoButton setTitleColor:UIColor.grayColor forState:UIControlStateHighlighted];
    [serverInfoButton setTitleColor:UIColor.whiteColor forState:UIControlStateSelected];
    serverInfoButton.titleLabel.shadowOffset = CGSizeZero;
    
    serverListTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
    if (IS_IPAD) {
        self.edgesForExtendedLayout = 0;
        self.view.tintColor = APP_TINT_COLOR;
        CGRect frame = backgroundImageView.frame;
        frame.size.height = frame.size.height + 8;
        backgroundImageView.frame = frame;
        self.view.backgroundColor = UIColor.blackColor;
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.navigationBar.tintColor = ICON_TINT_COLOR;
    }
    else {
        CGRect frame = supportedVersionView.frame;
        frame.origin.y = frame.origin.y + deltaY;
        supportedVersionView.frame = frame;
        
        frame = serverListTableView.frame;
        frame.origin.y = frame.origin.y + deltaY;
        frame.size.height = frame.size.height - deltaY - bottomPadding;
        serverListTableView.frame = frame;
        
        frame = connectingActivityIndicator.frame;
        frame.origin.y = frame.origin.y + deltaY;
        connectingActivityIndicator.frame = frame;
        
        UIButton *xbmcLogo = [[UIButton alloc] initWithFrame:CGRectMake(688, 964, 107, 37)];
        UIImage *image = [UIImage imageNamed:@"bottom_logo_up_iphone"];
        [xbmcLogo setImage:image forState:UIControlStateNormal];
        [xbmcLogo setImage:image forState:UIControlStateHighlighted];
        xbmcLogo.showsTouchWhenHighlighted = NO;
        [xbmcLogo addTarget:self action:@selector(infoView) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.titleView = xbmcLogo;
        UIImage *powerImg = [UIImage imageNamed:@"icon_power"];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:powerImg style:UIBarButtonItemStylePlain target:self action:@selector(powerControl)];
    }
    doRevealMenu = YES;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"lastServer"] != nil) {
        NSInteger lastServer = [userDefaults integerForKey:@"lastServer"];
        if (lastServer > -1 && lastServer < AppDelegate.instance.arrayServerList.count) {
            NSIndexPath *lastServerIndexPath = [NSIndexPath indexPathForRow:lastServer inSection:0];
            if (!AppDelegate.instance.serverOnLine) {
                [self selectIndex:lastServerIndexPath reloadData:NO];
                [connectingActivityIndicator startAnimating];
            }
            else {
                [self selectServerAtIndexPath:lastServerIndexPath];
                [serverListTableView selectRowAtIndexPath:lastServerIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
    
    // If there is no host saved at all, enter "add host" automatically
    if (AppDelegate.instance.arrayServerList.count == 0) {
        [self addHost:nil];
    }
    
    longPressGesture = [UILongPressGestureRecognizer new];
    [longPressGesture addTarget:self action:@selector(handleLongPress)];
    [self.view addGestureRecognizer:longPressGesture];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(revealMenu:)
                                                 name: @"RevealMenu"
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
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(disablePopGestureRecognizer:)
                                                 name: @"ECSlidingViewUnderRightWillAppear"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(enablePopGestureRecognizer:)
                                                 name: @"ECSlidingViewTopDidReset"
                                               object: nil];
}

- (void)powerControl {
    UIAlertController *actionView;
    if (AppDelegate.instance.obj.serverIP.length == 0) {
        actionView = [Utilities createAlertOK:LOCALIZED_STR(@"Select an XBMC Server from the list") message:nil];
    }
    else {
        actionView = [Utilities createPowerControl];
    }
    [self presentViewController:actionView animated:YES completion:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [serverInfoTimer invalidate];
}

- (void)enablePopGestureRecognizer:(id)sender {
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void)disablePopGestureRecognizer:(id)sender {
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)tcpJSONRPCConnectionError:(NSNotification*)note {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL showConnectionNotice = [userDefaults boolForKey:@"connection_info_preference"];
    if (showConnectionNotice && AppDelegate.instance.serverOnLine) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:LOCALIZED_STR(@"Kodi connection notice")
                                              message:[NSString stringWithFormat:@"%@\n\n%@", LOCALIZED_STR(@"It seems that the TCP connection with Kodi cannot be established. This will prevent the app from listening to Kodi. For example, the keyboard input within the app will not show when Kodi requests keyboard input."), LOCALIZED_STR(@"Do you want to enable this connection now?")]
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle:LOCALIZED_STR(@"Cancel")
                                       style:UIAlertActionStyleCancel
                                       handler:nil];
        
        UIAlertAction *dontShowAction = [UIAlertAction
                                         actionWithTitle:LOCALIZED_STR(@"Don't show this message again")
                                         style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction *action) {
                                             [self disableTCPconnectionNotice];
                                         }];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:LOCALIZED_STR(@"Enable TCP connection on Kodi")
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

- (void)disableTCPconnectionNotice {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:NO forKey:@"connection_info_preference"];
}

- (void)enableTCPconnection {
    NSString *methodToCall = @"Settings.SetSettingValue";
    NSDictionary *parameters = @{
        @"setting": @"services.esallinterfaces",
        @"value": @YES,
    };
    [[Utilities getJsonRPC] callMethod: methodToCall
         withParameters: parameters
           onCompletion: ^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
               if (error == nil && methodError == nil) {
                   [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationWillEnterForegroundNotification" object:nil userInfo:nil];
               }
               else {
                   UIAlertController *alertView = [Utilities createAlertOK:LOCALIZED_STR(@"Cannot do that") message:nil];
                   id presentingView = self.presentingViewController == nil ? self : self.presentingViewController;
                   [presentingView presentViewController:alertView animated:YES completion:nil];
               }
           }
     ];
}

- (void)connectionError:(NSNotification*)note {
    NSDictionary *theData = note.userInfo;
    [Utilities showMessage:theData[@"error_message"] color:[Utilities getSystemRed:0.95]];
}

- (void)authFailed:(NSNotification*)note {
    UIAlertController *alertView = [Utilities createAlertOK:LOCALIZED_STR(@"Authentication Failed") message:LOCALIZED_STR(@"Incorrect Username or Password.\nCheck your settings.")];
    [self presentViewController:alertView animated:YES completion:nil];
    
    // Deselect the server which causes the authentication error to allow to correct the credentials
    NSIndexPath *selection = [serverListTableView indexPathForSelectedRow];
    [self tableView:serverListTableView didSelectRowAtIndexPath:selection];
}

- (void)resetDoReveal:(NSNotification*)note {
    doRevealMenu = NO;
}

- (void)connectionSuccess:(NSNotification*)note {
    NSDictionary *theData = note.userInfo;
    if (storeServerSelection != nil) {
        UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:storeServerSelection];
        ((UIImageView*)[cell viewWithTag:XIB_HOST_MGMT_CELL_ICON]).image = [UIImage imageNamed:theData[@"icon_connection"]];
    }
    [connectingActivityIndicator stopAnimating];
    if (doRevealMenu) {
        [self revealMenu:nil];
    }
}

- (void)connectionFailed:(NSNotification*)note {
    NSDictionary *theData = note.userInfo;
    if (storeServerSelection != nil) {
        UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:storeServerSelection];
        ((UIImageView*)[cell viewWithTag:XIB_HOST_MGMT_CELL_ICON]).image = [UIImage imageNamed:theData[@"icon_connection"]];
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
