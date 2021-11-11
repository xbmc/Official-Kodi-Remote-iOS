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
#import "Utilities.h"

@interface InitialSlidingViewController ()

@end

@implementation InitialSlidingViewController

@synthesize mainMenu;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    HostManagementViewController *hostManagementViewController = [[HostManagementViewController alloc] initWithNibName:@"HostManagementViewController" bundle:nil];
    navController = [[CustomNavigationController alloc] initWithRootViewController:hostManagementViewController];
    UINavigationBar *newBar = navController.navigationBar;
    newBar.barStyle = UIBarStyleBlackTranslucent;
    [self setNeedsStatusBarAppearanceUpdate];
    newBar.tintColor = TINT_COLOR;
    self.view.tintColor = APP_TINT_COLOR;
    [navController hideNavBarBottomLine:YES];
    hostManagementViewController.mainMenu = self.mainMenu;
    self.topViewController = navController;
}

- (void)revealMenu:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName: @"RevealMenu" object: nil];
}
- (void)revealUnderRight:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName: @"revealUnderRight" object: nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
