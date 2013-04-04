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
    self.hostController=nil;
    self.hostController = [[HostViewController alloc] initWithNibName:@"HostViewController" bundle:nil];
    [self.navigationController pushViewController:self.hostController animated:YES];
}

-(void)modifyHost:(NSIndexPath *)item{
    if (storeServerSelection && item.row == storeServerSelection.row){
        UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:item];
        [(UIImageView *)[cell viewWithTag:1] setImage:[UIImage imageNamed:@"connection_off"]];
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
    self.hostController=nil;
    self.hostController = [[HostViewController alloc] initWithNibName:@"HostViewController" bundle:nil] ;
    self.hostController.detailItem=item;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=nil;
    cell = [tableView dequeueReusableCellWithIdentifier:@"serverListCell"];
    [[NSBundle mainBundle] loadNibNamed:@"serverListCellView" owner:self options:NULL];
    if (cell==nil){
        cell = serverListCell;
    }
    if ([[AppDelegate instance].arrayServerList count] == 0){
        [(UIImageView*) [cell viewWithTag:1] setHidden:TRUE];
        UILabel *cellLabel=(UILabel*) [cell viewWithTag:2];
        UILabel *cellIP=(UILabel*) [cell viewWithTag:3];
        cellLabel.textAlignment=UITextAlignmentCenter;
        [cellLabel setText:NSLocalizedString(@"No saved hosts found", nil)];
        [cellIP setText:@""];
        CGRect frame=cellLabel.frame;
        frame.origin.x=10;
        frame.origin.y=0;
        frame.size.width=300;
        frame.size.height=44;
        cellLabel.frame=frame;
        cell.accessoryType=UITableViewCellAccessoryNone;
        return cell;
    }
    else{
        [(UIImageView*) [cell viewWithTag:1] setHidden:FALSE];
        UILabel *cellLabel=(UILabel*) [cell viewWithTag:2];
        UILabel *cellIP=(UILabel*) [cell viewWithTag:3];
        CGRect frame=cellLabel.frame;
        frame.origin.x=36;
        frame.origin.y=0;
        frame.size.width=166;
        frame.size.height=44;
        cellLabel.frame=frame;
        cellLabel.textAlignment=UITextAlignmentLeft;
        NSDictionary *item=[[AppDelegate instance].arrayServerList objectAtIndex:indexPath.row];
        [cellLabel setText:[item objectForKey:@"serverDescription"]];
        [cellIP setText:[item objectForKey:@"serverIP"]];
        NSIndexPath *selection = [serverListTableView indexPathForSelectedRow];
        if (selection && indexPath.row == selection.row){
            cell.accessoryType=UITableViewCellAccessoryCheckmark;
            if ([AppDelegate instance].serverOnLine == YES){
                [(UIImageView *)[cell viewWithTag:1] setImage:[UIImage imageNamed:@"connection_on"]];
            }
        }
        else {
            cell.accessoryType=UITableViewCellAccessoryNone;
        }
        cell.editingAccessoryType=UITableViewCellAccessoryDetailDisclosureButton;
    }
    return cell;
}

-(void)selectServerAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *item = [[AppDelegate instance].arrayServerList objectAtIndex:indexPath.row];
    [AppDelegate instance].obj.serverDescription = [item objectForKey:@"serverDescription"];
    [AppDelegate instance].obj.serverUser = [item objectForKey:@"serverUser"];
    [AppDelegate instance].obj.serverPass = [item objectForKey:@"serverPass"];
    [AppDelegate instance].obj.serverIP = [item objectForKey:@"serverIP"];
    [AppDelegate instance].obj.serverPort = [item objectForKey:@"serverPort"];
    [AppDelegate instance].obj.serverHWAddr = [item objectForKey:@"serverMacAddress"];
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
    [(UIImageView *)[cell viewWithTag:1] setImage:[UIImage imageNamed:@"connection_off"]];
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
                [standardUserDefaults setObject:[NSNumber numberWithInt:indexPath.row] forKey:@"lastServer"];
                [standardUserDefaults synchronize];
            }
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCServerHasChanged" object: nil]; 
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType=UITableViewCellAccessoryNone;
    [(UIImageView *)[cell viewWithTag:1] setImage:[UIImage imageNamed:@"connection_off"]];
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
                    [standardUserDefaults setObject:[NSNumber numberWithInt:storeServerSelection.row] forKey:@"lastServer"];
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
    UIImage *myImage = [UIImage imageNamed:@"blank.png"];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
	imageView.frame = CGRectMake(0,0,320,8);
	return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 4;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIImage *myImage = [UIImage imageNamed:@"blank.png"];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
	imageView.frame = CGRectMake(0,0,320,8);
	return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 4;
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    [self modifyHost:indexPath];
}

-(IBAction)editTable:(id)sender forceClose:(BOOL)forceClose{
    if ([[AppDelegate instance].arrayServerList count]==0 && !serverListTableView.editing) return;
    if (serverListTableView.editing || forceClose==YES){
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
    appInfoView.modalTransitionStyle = UIModalTransitionStylePartialCurl;
	appInfoView.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentModalViewController:appInfoView animated:YES];
}


#pragma mark - LifeCycle

- (void)viewWillAppear:(BOOL)animated{
    CGSize size = CGSizeMake(320, 400); // size of view in popover
    self.contentSizeForViewInPopover = size;
    [super viewWillAppear:animated];
    [self selectIndex:nil reloadData:YES];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        UIButton *xbmcLogo = [[UIButton alloc] initWithFrame:CGRectMake(688, 964, 107, 37)];
        [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_up_iphone"] forState:UIControlStateNormal];
        [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_up_iphone"] forState:UIControlStateHighlighted];
        xbmcLogo.showsTouchWhenHighlighted = NO;
        [xbmcLogo addTarget:self action:@selector(infoView) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.titleView = xbmcLogo;
        UIImage* menuImg = [UIImage imageNamed:@"button_menu"];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:menuImg style:UIBarButtonItemStyleBordered target:nil action:@selector(revealMenu:)];
        UIImage* settingsImg = [UIImage imageNamed:@"button_settings"];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:settingsImg style:UIBarButtonItemStyleBordered target:nil action:@selector(revealUnderRight:)];
        if (![self.slidingViewController.underLeftViewController isKindOfClass:[MasterViewController class]]) {
            MasterViewController *masterViewController = [[MasterViewController alloc] initWithNibName:@"MasterViewController" bundle:nil];
            masterViewController.mainMenu = self.mainMenu;
            self.slidingViewController.underLeftViewController = masterViewController;
        }
        self.slidingViewController.underRightViewController = nil;
        RightMenuViewController *rightMenuViewController = [[RightMenuViewController alloc] initWithNibName:@"RightMenuViewController" bundle:nil];
        rightMenuViewController.rightMenuItems = [AppDelegate instance].rightMenuItems;
        self.slidingViewController.underRightViewController = rightMenuViewController;
        [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    }
    else{
        UIImageView *xbmcLogoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bottom_logo_up"]];
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
    doRevealMenu = YES;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        CGRect frame = backgroundImageView.frame;
        frame.size.height = frame.size.height + 8;
        backgroundImageView.frame = frame;
    }
    else if (![self.slidingViewController.underLeftViewController isKindOfClass:[MasterViewController class]]) {
        MasterViewController *masterViewController = [[MasterViewController alloc] initWithNibName:@"MasterViewController" bundle:nil];
        masterViewController.mainMenu = self.mainMenu;
        self.slidingViewController.underLeftViewController = masterViewController;
    }
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
    if (storeServerSelection!=nil){
        UITableViewCell *cell  = [serverListTableView cellForRowAtIndexPath:storeServerSelection];
        [(UIImageView *)[cell viewWithTag:1] setImage:[UIImage imageNamed:@"connection_on"]];
    }
    [connectingActivityIndicator stopAnimating];
    if (doRevealMenu) [self revealMenu:nil];
}

- (void)connectionFailed:(NSNotification *)note {
    if (storeServerSelection!=nil){
        UITableViewCell *cell  = [serverListTableView cellForRowAtIndexPath:storeServerSelection];
        [(UIImageView *)[cell viewWithTag:1] setImage:[UIImage imageNamed:@"connection_off"]];
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

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end