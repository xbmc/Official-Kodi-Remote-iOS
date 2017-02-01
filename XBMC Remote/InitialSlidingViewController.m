//
//  InitialSlidingViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 7/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "InitialSlidingViewController.h"
#import "HostManagementViewController.h"
#import "AppDelegate.h"

@interface InitialSlidingViewController ()

@end

@implementation InitialSlidingViewController

@synthesize mainMenu;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    CGRect shadowRect = CGRectMake(-16.0f, 0.0f, 16.0f, self.view.frame.size.height + 22);
    UIImageView *shadow = [[UIImageView alloc] initWithFrame:shadowRect];
    [shadow setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [shadow setImage:[UIImage imageNamed:@"tableLeft.png"]];
    shadow.opaque = YES;
    [navController.view addSubview:shadow];
    
    shadowRect = CGRectMake(self.view.frame.size.width, 0.0f, 16.0f, self.view.frame.size.height + 22);
    UIImageView *shadowRight = [[UIImageView alloc] initWithFrame:shadowRect];
    [shadowRight setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [shadowRight setImage:[UIImage imageNamed:@"tableRight.png"]];
    shadowRight.opaque = YES;
    [navController.view addSubview:shadowRight];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    HostManagementViewController *hostManagementViewController = [[HostManagementViewController alloc] initWithNibName:@"HostManagementViewController" bundle:nil];
    navController = [[CustomNavigationController alloc] initWithRootViewController:hostManagementViewController];
    UINavigationBar *newBar = navController.navigationBar;
    [newBar setTintColor:IOS6_BAR_TINT_COLOR];
    [newBar setBarStyle:UIBarStyleBlackTranslucent];
    [self setNeedsStatusBarAppearanceUpdate];
    [newBar setTintColor:TINT_COLOR];
    self.view.tintColor = APP_TINT_COLOR;
    [navController hideNavBarBottomLine:YES];
    hostManagementViewController.mainMenu = self.mainMenu;
    self.topViewController = navController;
}

- (void)revealMenu:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName: @"RevealMenu" object: nil];
}
- (void)revealUnderRight:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName: @"revealUnderRight" object: nil];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
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

@end
