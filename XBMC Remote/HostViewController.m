//
//  HostViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 14/4/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import "HostViewController.h"
//#import "GlobalData.h"
#import "AppDelegate.h"


@interface HostViewController ()

@end

@implementation HostViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.title=@"New XBMC Server";
        // Custom initialization
    }
    return self;
}

- (IBAction) dismissView:(id)sender{
    
    [self textFieldDoneEditing:nil];
    AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [mainDelegate.arrayServerList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                              descriptionUI.text, @"serverDescription",
                                              usernameUI.text, @"serverUser",
                                              passwordUI.text, @"serverPass",
                                              ipUI.text, @"serverIP",
                                              portUI.text, @"serverPort",
                                              nil
                                              ]];
    [mainDelegate saveServerList];
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark - UITextField

-(BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    //NSLog(@"ECCOMI");
//    obj=[GlobalData getInstance]; 
    [descriptionUI resignFirstResponder];
    [ipUI resignFirstResponder];
    [portUI resignFirstResponder];
    [usernameUI resignFirstResponder];
    [passwordUI resignFirstResponder];
//    obj.serverDescription=descriptionUI.text;
//    obj.serverUser=usernameUI.text;
//    obj.serverPass=passwordUI.text;
//    obj.serverIP= ipUI.text;
//    obj.serverPort=portUI.text;
    [theTextField resignFirstResponder];
   // [self changeServerStatus:NO infoText:@"No connection"];
    //[self checkServer];
    return YES;
}

-(IBAction)textFieldDoneEditing:(id)sender{
    [descriptionUI resignFirstResponder];
    [ipUI resignFirstResponder];
    [portUI resignFirstResponder];
    [usernameUI resignFirstResponder];
    [passwordUI resignFirstResponder];
//    obj=[GlobalData getInstance]; 
//    obj.serverDescription=descriptionUI.text;
//    obj.serverUser=usernameUI.text;
//    obj.serverPass=passwordUI.text;
//    obj.serverIP= ipUI.text;
//    obj.serverPort=portUI.text;
    //    [self changeServerStatus:NO infoText:@"No connection"];
}


#pragma mark - LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
