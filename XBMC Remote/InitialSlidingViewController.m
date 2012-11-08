//
//  InitialSlidingViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 7/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "InitialSlidingViewController.h"
#import "HostManagementViewController.h"

@interface InitialSlidingViewController ()

@end

@implementation InitialSlidingViewController

@synthesize mainMenu;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    HostManagementViewController *hostManagementViewController = [[HostManagementViewController alloc] initWithNibName:@"HostManagementViewController" bundle:nil];
    
    UINavigationController *navController = [[UINavigationController alloc]
                                             initWithRootViewController:hostManagementViewController];

    UINavigationBar *newBar = navController.navigationBar;
    [newBar setTintColor:[UIColor colorWithRed:.14 green:.14 blue:.14 alpha:1]];
    [newBar setBarStyle:UIBarStyleBlackOpaque];
    CGRect shadowRect = CGRectMake(-16.0f, 0.0f, 16.0f, self.view.frame.size.height + 16);
    UIImageView *shadow = [[UIImageView alloc] initWithFrame:shadowRect];
    [shadow setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [shadow setImage:[UIImage imageNamed:@"tableLeft.png"]];
    shadow.opaque = YES;
    [navController.view addSubview:shadow];
    hostManagementViewController.mainMenu = self.mainMenu;
    self.topViewController = navController;
}
- (void)revealMenu:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName: @"RevealMenu" object: nil];
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

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

@end
