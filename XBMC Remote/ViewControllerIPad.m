//
//  ViewControllerIPad.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 29/4/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"
#import "MenuViewController.h"
#import "NowPlaying.h"
#import "mainMenu.h"
#import "GlobalData.h"
#import "AppDelegate.h"

@interface ViewControllerIPad (){
    NSMutableArray *mainMenu;
}
@end

@interface UIViewExt : UIView {} 
@end


@implementation UIViewExt
- (UIView *) hitTest: (CGPoint) pt withEvent: (UIEvent *) event {   
	
	UIView* viewToReturn=nil;
	CGPoint pointToReturn;
	
	UIView* uiRightView = (UIView*)[[self subviews] objectAtIndex:1];
	
	if ([[uiRightView subviews] objectAtIndex:0]) {
		
		UIView* uiStackScrollView = [[uiRightView subviews] objectAtIndex:0];	
		
		if ([[uiStackScrollView subviews] objectAtIndex:1]) {	 
			
			UIView* uiSlideView = [[uiStackScrollView subviews] objectAtIndex:1];	
			
			for (UIView* subView in [uiSlideView subviews]) {
				CGPoint point  = [subView convertPoint:pt fromView:self];
				if ([subView pointInside:point withEvent:event]) {
					viewToReturn = subView;
					pointToReturn = point;
				}
				
			}
		}
		
	}
	
	if(viewToReturn != nil) {
		return [viewToReturn hitTest:pointToReturn withEvent:event];		
	}
	
	return [super hitTest:pt withEvent:event];	
	
}
@end



@implementation ViewControllerIPad

@synthesize mainMenu;
@synthesize menuViewController, stackScrollViewController;
@synthesize nowPlayingController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - InfoView

-(void)infoView{
    
}

#pragma mark - ServerManagement
-(void)selectServerAtIndexPath:(NSIndexPath *)indexPath{
    
    storeServerSelection = indexPath;
    AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary *item = [mainDelegate.arrayServerList objectAtIndex:indexPath.row];
    obj.serverDescription = [item objectForKey:@"serverDescription"];
    obj.serverUser = [item objectForKey:@"serverUser"];
    obj.serverPass = [item objectForKey:@"serverPass"];
    obj.serverIP = [item objectForKey:@"serverIP"];
    obj.serverPort = [item objectForKey:@"serverPort"];
    //[self changeServerStatus:NO infoText:@"No connection"];
}

#pragma mark - Lyfecycle

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
        }
    }
    int tableHeight = [(NSMutableArray *)mainMenu count] * 64 + 16;
    int tableWidth = 300;
//    int headerHeight=16;
    int headerHeight=0;
   
    rootView = [[UIViewExt alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
	rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
	[rootView setBackgroundColor:[UIColor clearColor]];
	
	leftMenuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableWidth, self.view.frame.size.height)];
	leftMenuView.autoresizingMask = UIViewAutoresizingFlexibleHeight;	
    
//    CGRect maniMenuTitleFrame = CGRectMake(0.0f, 2.0f, tableWidth, headerHeight);
//    UILabel *mainMenuTitle=[[UILabel alloc] initWithFrame:maniMenuTitleFrame];
//    [mainMenuTitle setFont:[UIFont fontWithName:@"Optima-Regular" size:12]];
//    [mainMenuTitle setTextAlignment:UITextAlignmentCenter];
//    [mainMenuTitle setBackgroundColor:[UIColor clearColor]];
//    [mainMenuTitle setText:@"Main Menu"];
//    [mainMenuTitle setTextColor:[UIColor lightGrayColor]];
//    [mainMenuTitle setShadowColor:[UIColor blackColor]];
//    [mainMenuTitle setShadowOffset:CGSizeMake(1, 1)];
//    [leftMenuView addSubview:mainMenuTitle];
    
	menuViewController = [[MenuViewController alloc] initWithFrame:CGRectMake(0, headerHeight, leftMenuView.frame.size.width, leftMenuView.frame.size.height) mainMenu:mainMenu];
	[menuViewController.view setBackgroundColor:[UIColor clearColor]];
	[menuViewController viewWillAppear:FALSE];
	[menuViewController viewDidAppear:FALSE];
	[leftMenuView addSubview:menuViewController.view];
    int separator = 0;

//    separator = 18;
//    CGRect leatherBackground = CGRectMake(0.0f, tableHeight + headerHeight - 6, tableWidth, separator + 4);
//    UIImageView *leather = [[UIImageView alloc] initWithFrame:leatherBackground];
//    [leather setImage:[UIImage imageNamed:@"denim_seam.png"]];
//    leather.opaque = YES;
//    leather.alpha = 0.5;
//    [leftMenuView addSubview:leather];
    
    separator = 5;
    CGRect seamBackground = CGRectMake(0.0f, tableHeight + headerHeight - 2, tableWidth, separator);
    UIImageView *seam = [[UIImageView alloc] initWithFrame:seamBackground];
    [seam setImage:[UIImage imageNamed:@"denim_single_seam.png"]];
    seam.opaque = YES;
//    seam.alpha = 0.7;
    [leftMenuView addSubview:seam];
////    
//    UILabel *playlistTitle=[[UILabel alloc] initWithFrame:leatherBackground];
//    [playlistTitle setFont:[UIFont fontWithName:@"Optima-Regular" size:12]];
//    [playlistTitle setTextAlignment:UITextAlignmentCenter];
//    [playlistTitle setBackgroundColor:[UIColor clearColor]];
//    [playlistTitle setText:@"Playlist"];
//    [playlistTitle setTextColor:[UIColor lightGrayColor]];
//    [playlistTitle setShadowColor:[UIColor blackColor]];
//    [playlistTitle setShadowOffset:CGSizeMake(1, 1)];
//    [leftMenuView addSubview:playlistTitle];
    
    
    nowPlayingController = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
    CGRect frame=nowPlayingController.view.frame;
    YPOS=-(tableHeight + separator + headerHeight);
    frame.origin.y=tableHeight + separator + headerHeight;
    frame.size.width=tableWidth;
    frame.size.height=self.view.frame.size.height - tableHeight - separator - headerHeight;
    nowPlayingController.view.autoresizingMask=UIViewAutoresizingFlexibleHeight;
    nowPlayingController.view.frame=frame;
    [nowPlayingController setToolbarWidth:768 height:610 origX:76 origY:60 thumbWidth:334 thumbHeight:334 YPOS:YPOS playBarWidth:426];
    
    [leftMenuView addSubview:nowPlayingController.view];

	rightSlideView = [[UIView alloc] initWithFrame:CGRectMake(leftMenuView.frame.size.width, 0, rootView.frame.size.width - leftMenuView.frame.size.width, rootView.frame.size.height-44)];
	rightSlideView.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
    
	stackScrollViewController = [[StackScrollViewController alloc] init];	
	[stackScrollViewController.view setFrame:CGRectMake(0, 0, rightSlideView.frame.size.width, rightSlideView.frame.size.height)];
	[stackScrollViewController.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight];
	[stackScrollViewController viewWillAppear:FALSE];
	[stackScrollViewController viewDidAppear:FALSE];
	[rightSlideView addSubview:stackScrollViewController.view];
	
	[rootView addSubview:leftMenuView];
	[rootView addSubview:rightSlideView];
    
//    self.view.backgroundColor = [UIColor blackColor];
//    self.view.backgroundColor = [[UIColor scrollViewTexturedBackgroundColor] colorWithAlphaComponent:0.5];
	[self.view setBackgroundColor:[UIColor colorWithPatternImage: [UIImage imageNamed:@"backgroundImage_repeat.png"]]];
    [self.view addSubview:rootView];
    
    xbmcLogo = [[UIButton alloc] initWithFrame:CGRectMake(690, 962, 74, 41)];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_up.png"] forState:UIControlStateNormal];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateHighlighted];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateSelected];
    [xbmcLogo addTarget:self action:@selector(infoView) forControlEvents:UIControlEventTouchUpInside];
    xbmcLogo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    //UIBarButtonItem *setupRemote = [[UIBarButtonItem alloc] initWithCustomView:xbmcLogo];
    [self.view addSubview:xbmcLogo];
    
}

- (void)viewDidUnload{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[menuViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[stackScrollViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	[menuViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[stackScrollViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        [nowPlayingController setToolbarWidth:768 height:610 origX:76 origY:60 thumbWidth:334 thumbHeight:334 YPOS:YPOS playBarWidth:426];

	}
	else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight){
        [nowPlayingController setToolbarWidth:1024 height:768 origX:152 origY:80 thumbWidth:435 thumbHeight:435 YPOS:YPOS playBarWidth:680];

	}
}	

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
	return YES;
}

@end
