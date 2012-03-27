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
#import "SettingsPanel.h"

@interface MasterViewController () {
    NSMutableArray *_objects;
    NSMutableArray *mainMenu;

}
@end

@implementation MasterViewController

@synthesize detailViewController = _detailViewController;
@synthesize nowPlaying = _nowPlaying;
@synthesize remoteController = _remoteController;

@synthesize mainMenu;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//
//        self.title = NSLocalizedString(@"Master", @"Master");
//    }
    return self;
}
	

-(void)checkServer{
    [jsonRPC 
     callMethod:@"Application.GetProperties" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [[NSArray alloc] initWithObjects:@"version", nil], @"properties", nil]
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error==nil && methodError==nil){
//            NSLog(@"DATO RICEVUTO %@", methodResult);
             if( [NSJSONSerialization isValidJSONObject:methodResult]){
                 [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateNormal];
                 [xbmcLogo setImage:nil forState:UIControlStateHighlighted];
                 [xbmcLogo setImage:nil forState:UIControlStateSelected];
                 NSDictionary *serverInfo=[methodResult objectForKey:@"version"];
                 NSString *infoTitle=[NSString stringWithFormat:@" XBMC %@.%@ %@ ", [serverInfo objectForKey:@"major"], [serverInfo objectForKey:@"minor"], [serverInfo objectForKey:@"revision"]];
                 [xbmcInfo setTitle:infoTitle forState:UIControlStateNormal];
             }
         }
         else {
//             NSLog(@"ERROR:%@ METHOD:%@", error, methodError);
             [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_up.png"] forState:UIControlStateNormal];
             [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateHighlighted];
             [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateSelected];
             [xbmcInfo setTitle:@"No connection" forState:UIControlStateNormal];
         }
     }];
}

#pragma Toobar Actions

-(void)toggleViewToolBar:(UIView*)view AnimDuration:(float)seconds Alpha:(float)alphavalue YPos:(int)Y forceHide:(BOOL)hide {
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:seconds];
    int actualPosY=view.frame.origin.y;
    if (actualPosY==Y || hide){
        Y=-view.frame.size.height;
    }
    view.alpha = alphavalue;
	CGRect frame;
	frame = [view frame];
	frame.origin.y = Y;
    view.frame = frame;
    [UIView commitAnimations];
}

- (void)toggleSetup{
    [self toggleViewToolBar:settingsPanel AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE];
}

#pragma LifeCycle
-(void)viewWillAppear:(BOOL)animated{
    NSIndexPath*	selection = [menuList indexPathForSelectedRow];
	if (selection)
		[menuList deselectRowAtIndexPath:selection animated:YES];
    [self checkServer];
    timer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(checkServer) userInfo:nil repeats:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    NSLog(@"ME NE VADO");
    [timer invalidate];    
}

- (void)viewDidLoad{
    [super viewDidLoad];
    GlobalData *obj=[GlobalData getInstance];  
    obj.serverUser=@"xbmc";
    obj.serverPass=@"";
    obj.serverIP= @"192.168.0.8";
    obj.serverPort=@"8080";
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, obj.serverPass, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    
    settingsPanel = [[SettingsPanel alloc] 
                     initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 270.0f)];
    CGRect frame=settingsPanel.frame;
    frame.origin.x=0;
    frame.origin.y=-270;
    settingsPanel.frame=frame;
    [self.view addSubview:settingsPanel];

    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:.14 green:.14 blue:.14 alpha:1];;
    xbmcLogo = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 75, 43)];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_up.png"] forState:UIControlStateNormal];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateHighlighted];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateSelected];
    [xbmcLogo addTarget:self action:@selector(toggleSetup) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *setupRemote = [[UIBarButtonItem alloc] initWithCustomView:xbmcLogo];
    self.navigationItem.leftBarButtonItem = setupRemote;
    xbmcInfo = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 220, 43)];
    [xbmcInfo setTitle:@"No connection" forState:UIControlStateNormal];    
    xbmcInfo.titleLabel.font = [UIFont fontWithName:@"Courier" size:11];
    xbmcInfo.titleLabel.minimumFontSize=6.0f;
    xbmcInfo.titleLabel.shadowColor = [UIColor blackColor];
    xbmcInfo.titleLabel.shadowOffset    = CGSizeMake (1.0, 1.0);
    [xbmcInfo setBackgroundImage:[UIImage imageNamed:@"bottom_text_up.9.png"] forState:UIControlStateNormal];
    [xbmcInfo addTarget:self action:@selector(toggleSetup) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *setupInfo = [[UIBarButtonItem alloc] initWithCustomView:xbmcInfo];
    self.navigationItem.rightBarButtonItem = setupInfo;
//    [self checkServer];
//    [jsonRPC 
//     callMethod:@"VideoLibrary.GetMovieDetails" 
//     withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
//                     [NSNumber numberWithInt:6], @"movieid",
//                     [[NSArray alloc] initWithObjects:@"year", @"runtime", @"file", @"playcount", @"rating", @"plot", @"fanart", @"thumbnail", @"resume", @"trailer", nil], @"properties",
//                     nil] 
//     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
//        if (error==nil && methodError==nil){
}

- (void)viewDidUnload{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
//    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
//}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.mainMenu count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mainMenuCell"];
    [[NSBundle mainBundle] loadNibNamed:@"cellView" owner:self options:NULL];
    if (cell==nil)
        cell = resultMenuCell;
    mainMenu *item = [self.mainMenu objectAtIndex:indexPath.row];
    [(UIImageView*) [cell viewWithTag:1] setImage:[UIImage imageNamed:item.icon]];
    [(UILabel*) [cell viewWithTag:2] setText:item.upperLabel];   
    [(UILabel*) [cell viewWithTag:3] setText:item.mainLabel];    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    //	if (editingStyle == UITableViewCellEditingStyleDelete)
    //	{
    //		[self.albums removeObjectAtIndex:indexPath.row];
    //		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    //	}   
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIImage *myImage = [UIImage imageNamed:@"tableUp.png"];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
	imageView.frame = CGRectMake(0,0,480,8);
	return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 8;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIImage *myImage = [UIImage imageNamed:@"tableDown.png"];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
	imageView.frame = CGRectMake(0,0,480,8);
	return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 8;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    mainMenu *item = [self.mainMenu objectAtIndex:indexPath.row];
    if (item.family==2){
        if (!self.nowPlaying) 
            self.nowPlaying = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
        self.nowPlaying.detailItem = item;
        [self.navigationController pushViewController:self.nowPlaying animated:YES];
    }
    else if (item.family==3){
        if (!self.remoteController) 
            self.remoteController = [[RemoteController alloc] initWithNibName:@"RemoteController" bundle:nil];
        self.remoteController.detailItem = item;
        [self.navigationController pushViewController:self.remoteController animated:YES];
    }
    else if (item.family==1){
        if (!self.detailViewController) 
            self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
        self.detailViewController.detailItem = item;
        [self.navigationController pushViewController:self.detailViewController animated:YES];
    }    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return NO;
}

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
