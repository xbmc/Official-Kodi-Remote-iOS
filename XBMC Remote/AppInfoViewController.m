//
//  AppInfoViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 16/4/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import "AppInfoViewController.h"

@interface AppInfoViewController ()

@end

@implementation AppInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(IBAction)CloseView{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
