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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [Utilities addShadowsToView:navController.view viewFrame:self.view.frame];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    HostManagementViewController *hostManagementViewController = [[HostManagementViewController alloc] initWithNibName:@"HostManagementViewController" bundle:nil];
    navController = [[CustomNavigationController alloc] initWithRootViewController:hostManagementViewController];
    navController.navigationBar.barStyle = UIBarStyleBlack;
    navController.navigationBar.tintColor = ICON_TINT_COLOR;
    
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

@end
