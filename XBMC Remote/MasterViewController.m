//
//  MasterViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
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

@synthesize obj;

@synthesize mainMenu;
//@synthesize serverList;

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
        serverOnLine=YES;
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
                [UIView commitAnimations];
            }
        }
    }
    else{
        [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_up.png"] forState:UIControlStateNormal];
        [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateHighlighted];
        [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateSelected];
        [xbmcInfo setTitle:infoText forState:UIControlStateNormal];
        serverOnLine=NO;
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
                [UIView commitAnimations];
            }
        }
    }
}

-(void)checkServer{
    jsonRPC=nil;
    obj=[GlobalData getInstance];  
    if ([obj.serverIP length]==0){
        if (firstRun){
            firstRun=NO;
            [self toggleViewToolBar:settingsView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE forceOpen:TRUE];
            
        }
        return;
    }
    
//    NSString *userName=[NSString string]
//    NSLog(@"ECCOCI %@", obj.serverPass);
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
//    NSLog(@"%@", serverJSON);
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    
//    [jsonRPC 
//     callMethod:@"JSONRPC.Introspect" 
//     withParameters:[NSDictionary dictionaryWithObjectsAndKeys: nil]
//     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
//         NSLog(@"%@", methodResult);
//     }];
    
    [jsonRPC 
     callMethod:@"Application.GetProperties" 
     withParameters:checkServerParams
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error==nil && methodError==nil){
             if (!serverOnLine){
                 if( [NSJSONSerialization isValidJSONObject:methodResult]){
                     NSDictionary *serverInfo=[methodResult objectForKey:@"version"];
                     NSString *infoTitle=[NSString stringWithFormat:@" XBMC %@.%@-%@", [serverInfo objectForKey:@"major"], [serverInfo objectForKey:@"minor"], [serverInfo objectForKey:@"tag"]];//, [serverInfo objectForKey:@"revision"]
                     [self changeServerStatus:YES infoText:infoTitle];
                     [self toggleViewToolBar:settingsView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE forceOpen:FALSE];
                     
                     
                 }
                 else{
                     if (serverOnLine){
//                         NSLog(@"mi spengo");
                         
                         [self changeServerStatus:NO infoText:@"No connection"];
                         
                     }
                     if (firstRun){
                         firstRun=NO;
                         [self toggleViewToolBar:settingsView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE forceOpen:TRUE];
                         
                     }
                 }
             }
         }
         else {
//             NSLog(@"ERROR %@ %@",error, methodError);
             if (serverOnLine){
//                 NSLog(@"mi spengo");
                 
                 [self changeServerStatus:NO infoText:@"No connection"];
                 
             }
             if (firstRun){
                 firstRun=NO;
                 [self toggleViewToolBar:settingsView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE forceOpen:TRUE];
                 
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
//    [self textFieldDoneEditing:nil];
}

- (void)toggleSetup{
    [self toggleViewToolBar:settingsView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE forceOpen:FALSE];
}

- (void) pushController: (UIViewController*) controller
         withTransition: (UIViewAnimationTransition) transition
{
    [UIView beginAnimations:nil context:NULL];
    [self.navigationController pushViewController:controller animated:NO];
    [UIView setAnimationDuration:.5];
    [UIView setAnimationBeginsFromCurrentState:YES];        
    [UIView setAnimationTransition:transition forView:self.navigationController.view cache:YES];
    [UIView commitAnimations];
}

#pragma  mark - Add/Modify Hosts

-(IBAction)addHost:(id)sender{
    self.hostController=nil;
    self.hostController = [[HostViewController alloc] initWithNibName:@"HostViewController" bundle:nil] ;
//    self.detailViewController.detailItem = item;
//    [self pushController:self.hostController withTransition:UIViewAnimationTransitionCurlUp];
    [self.navigationController pushViewController:self.hostController animated:YES];
}

-(void)modifyHost:(NSIndexPath *)item{
    self.hostController=nil;
    self.hostController = [[HostViewController alloc] initWithNibName:@"HostViewController" bundle:nil] ;
    self.hostController.detailItem=item;
    //    self.detailViewController.detailItem = item;
    //    [self pushController:self.hostController withTransition:UIViewAnimationTransitionCurlUp];
    [self.navigationController pushViewController:self.hostController animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView.tag==0)
        return [self.mainMenu count];
    else if (tableView.tag==1){
        AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if ([mainDelegate.arrayServerList count] == 0 && !tableView.editing) {
            return 1; // a single cell to report no data
        }
        return [mainDelegate.arrayServerList count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=nil;
    if (tableView.tag==0){
        cell = [tableView dequeueReusableCellWithIdentifier:@"mainMenuCell"];
        [[NSBundle mainBundle] loadNibNamed:@"cellView" owner:self options:NULL];
        if (cell==nil)
            cell = resultMenuCell;
        mainMenu *item = [self.mainMenu objectAtIndex:indexPath.row];
        [(UIImageView*) [cell viewWithTag:1] setImage:[UIImage imageNamed:item.icon]];
        [(UILabel*) [cell viewWithTag:2] setText:item.upperLabel];   
        [(UILabel*) [cell viewWithTag:3] setText:item.mainLabel]; 
        if (serverOnLine){
            [(UIImageView*) [cell viewWithTag:1] setAlpha:1];
            [(UIImageView*) [cell viewWithTag:2] setAlpha:1];
            [(UIImageView*) [cell viewWithTag:3] setAlpha:1];
            cell.selectionStyle=UITableViewCellSelectionStyleBlue;
        }
        else {
            [(UIImageView*) [cell viewWithTag:1] setAlpha:0.3];
            [(UIImageView*) [cell viewWithTag:2] setAlpha:0.3];
            [(UIImageView*) [cell viewWithTag:3] setAlpha:0.3];
            cell.selectionStyle=UITableViewCellSelectionStyleGray;
            
        }
        
        return cell;
    }
    else if (tableView.tag==1){
        cell = [tableView dequeueReusableCellWithIdentifier:@"serverListCell"];
        [[NSBundle mainBundle] loadNibNamed:@"serverListCellView" owner:self options:NULL];
        if (cell==nil){
            cell = serverListCell;
        }
        AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if ([mainDelegate.arrayServerList count] == 0){
            [(UIImageView*) [cell viewWithTag:1] setHidden:TRUE];
            UILabel *cellLabel=(UILabel*) [cell viewWithTag:2];
            UILabel *cellIP=(UILabel*) [cell viewWithTag:3];
            cellLabel.textAlignment=UITextAlignmentCenter;
            [cellLabel setText:@"No saved hosts found"];
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
            cellLabel.textAlignment=UITextAlignmentLeft;
            NSDictionary *item=[mainDelegate.arrayServerList objectAtIndex:indexPath.row];
            [cellLabel setText:[item objectForKey:@"serverDescription"]];
            [cellIP setText:[item objectForKey:@"serverIP"]];
            CGRect frame=cellLabel.frame;
            frame.origin.x=66;
            frame.size.width=142;
            cellLabel.frame=frame;
            NSIndexPath *selection = [serverListTableView indexPathForSelectedRow];
            if (selection && indexPath.row == selection.row){
                cell.accessoryType=UITableViewCellAccessoryCheckmark;
            }
            else {
                cell.accessoryType=UITableViewCellAccessoryNone;

            }
        }
        return cell;
    }
    return cell;
}

-(void)selectServerAtIndexPath:(NSIndexPath *)indexPath{
    
    storeServerSelection = indexPath;
    AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary *item = [mainDelegate.arrayServerList objectAtIndex:indexPath.row];
    obj.serverDescription = [item objectForKey:@"serverDescription"];
    obj.serverUser = [item objectForKey:@"serverUser"];
    obj.serverPass = [item objectForKey:@"serverPass"];
    obj.serverIP = [item objectForKey:@"serverIP"];
    obj.serverPort = [item objectForKey:@"serverPort"];
    [self changeServerStatus:NO infoText:@"No connection"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView.tag == 0){
        if (!serverOnLine) {
            [menuList deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }
        [self toggleViewToolBar:settingsView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE forceOpen:FALSE];
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
    else if (tableView.tag == 1){
        AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

        if ([mainDelegate.arrayServerList count] == 0){
            [serverListTableView deselectRowAtIndexPath:indexPath animated:YES];
        }
        else{
            firstRun=NO;
            NSIndexPath *selection = [serverListTableView indexPathForSelectedRow];
            if (storeServerSelection && selection.row == storeServerSelection.row){
                UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:indexPath];
                [serverListTableView deselectRowAtIndexPath:selection animated:YES];
                cell.accessoryType = UITableViewCellAccessoryNone;
                storeServerSelection = nil;
                obj.serverDescription = @"";
                obj.serverUser = @"";
                obj.serverPass = @"";
                obj.serverIP = @"";
                obj.serverPort = @"";
                [self changeServerStatus:NO infoText:@"No connection"];
                NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
                
                if (standardUserDefaults) {
                    [standardUserDefaults setObject:[NSNumber numberWithInt:-1] forKey:@"lastServer"];
                    [standardUserDefaults synchronize];
                }

            }
            else{
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

    }
}
-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag==1){
        UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType=UITableViewCellAccessoryNone;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Detemine if it's in editing mode
    if (aTableView.editing) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView.tag==0){
        return NO;
    }
    else if (tableView.tag==1){
        return YES;
    }

    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
	if (editingStyle == UITableViewCellEditingStyleDelete){
        AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [mainDelegate.arrayServerList removeObjectAtIndex:indexPath.row];
        [mainDelegate saveServerList];
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
                obj.serverDescription = @"";
                obj.serverUser = @"";
                obj.serverPass = @"";
                obj.serverIP = @"";
                obj.serverPort = @"";
                [self changeServerStatus:NO infoText:@"No connection"];
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
//
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView.tag == 1)
        return 4;
    return 8;
}
//
- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIImage *myImage = [UIImage imageNamed:@"blank.png"];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
	imageView.frame = CGRectMake(0,0,320,8);
	return imageView;
}
//
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (tableView.tag == 1)
        return 4;
	return 8;
}

-(IBAction)editTable:(id)sender forceClose:(BOOL)forceClose{
    AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([mainDelegate.arrayServerList count]==0 && !serverListTableView.editing) return;
    if (serverListTableView.editing || forceClose==YES){
        [serverListTableView setEditing:NO animated:YES];
        [editTableButton setSelected:NO];
        if ([mainDelegate.arrayServerList count] == 0)
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
        CGPoint p = [lpgr locationInView:menuList];
        NSIndexPath *indexPath = [menuList indexPathForRowAtPoint:p];
        AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

        if (indexPath != nil && indexPath.row<[mainDelegate.arrayServerList count]){
            
            [self modifyHost:indexPath];
        }
    }
}

#pragma mark - LifeCycle

-(void)viewWillAppear:(BOOL)animated{
    NSIndexPath*	selection = [menuList indexPathForSelectedRow];
	if (selection)
		[menuList deselectRowAtIndexPath:selection animated:YES];
    selection = [serverListTableView indexPathForSelectedRow];
    timer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(checkServer) userInfo:nil repeats:YES];
    [serverListTableView reloadData];
    if (selection){
		[serverListTableView selectRowAtIndexPath:selection animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        UITableViewCell *cell = [serverListTableView cellForRowAtIndexPath:selection];
        cell.accessoryType=UITableViewCellAccessoryCheckmark;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
//    NSLog(@"ME NE VADO");
    [timer invalidate];  
    jsonRPC=nil;
}

- (void)infoView{
    if (appInfoView==nil)
        appInfoView = [[AppInfoViewController alloc] initWithNibName:@"AppInfoViewController" bundle:nil] ;
  //  appInfoView.delegate = self;
    appInfoView.modalTransitionStyle = UIModalTransitionStylePartialCurl;
	appInfoView.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentModalViewController:appInfoView animated:YES];
}

BOOL firstRun;

- (void)viewDidLoad{
    [super viewDidLoad];
    obj=[GlobalData getInstance];  
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    int lastServer;
    if ([userDefaults objectForKey:@"lastServer"]!=nil){
        lastServer=[[userDefaults objectForKey:@"lastServer"] intValue];
        if (lastServer>-1){
            NSIndexPath *lastServerIndexPath=[NSIndexPath indexPathForRow:lastServer inSection:0];
            [self selectServerAtIndexPath:lastServerIndexPath];
            [serverListTableView selectRowAtIndexPath:lastServerIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
    firstRun=YES;
    checkServerParams=[NSDictionary dictionaryWithObjectsAndKeys: [[NSArray alloc] initWithObjects:@"version", nil], @"properties", nil];
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
    serverOnLine=NO;
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnterForeground:)
                                                 name: @"UIApplicationWillEnterForegroundNotification"
                                               object: nil];
    [self.view setBackgroundColor:[UIColor colorWithPatternImage: [UIImage imageNamed:@"backgroundImage_repeat.png"]]];

    

}

- (void) handleEnterForeground: (NSNotification*) sender;{
   // [self checkPartyMode];
   // [self changeServerStatus:NO infoText:@"No connection"];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver: self];

    // Release any retained subviews of the main view.
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
//    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
//}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


//-(BOOL)textFieldShouldReturn:(UITextField *)theTextField {
//    [theTextField resignFirstResponder];
//    return YES;
//}

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


//#pragma mark - Table View
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//    return 1;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    return _objects.count;
//}
//
//// Customize the appearance of table view cells.
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *CellIdentifier = @"mainMenuCell";
//    
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//	
//    [[NSBundle mainBundle] loadNibNamed:@"cellView" owner:self options:NULL];
//    
//    if (cell==nil)
//        cell = resultPOICell;
//    
//    mainMenu *item = [self.mainMenu objectAtIndex:indexPath.row];
//    [(UIImageView*) [cell viewWithTag:1] setImage:[UIImage imageNamed:item.icon]];
//    [(UILabel*) [cell viewWithTag:2] setText:item.upperLabel];   
//    [(UILabel*) [cell viewWithTag:3] setText:item.mainLabel];    
//    return cell;
//
//}
//

//
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        [_objects removeObjectAtIndex:indexPath.row];
//        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
//    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
//    }
//}
//
///*
//// Override to support rearranging the table view.
//- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
//{
//}
//*/
//
///*
//// Override to support conditional rearranging of the table view.
//- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Return NO if you do not want the item to be re-orderable.
//    return YES;
//}
//*/
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (!self.detailViewController) {
//        self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
//    }
//    NSDate *object = [_objects objectAtIndex:indexPath.row];
//    self.detailViewController.detailItem = object;
//    [self.navigationController pushViewController:self.detailViewController animated:YES];
//}

@end
