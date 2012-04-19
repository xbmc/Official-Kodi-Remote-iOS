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
-(void)configureView;
@end

@implementation HostViewController

@synthesize detailItem = _detailItem;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)configureView{
    if (self.detailItem==nil){
        self.navigationItem.title=@"New XBMC Server";
    }
    else {
        self.navigationItem.title=@"Modify XBMC Server";
        AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSIndexPath *idx=self.detailItem;
        
        descriptionUI.text=[[mainDelegate.arrayServerList objectAtIndex:idx.row] objectForKey:@"serverDescription"];
        
        usernameUI.text=[[mainDelegate.arrayServerList objectAtIndex:idx.row] objectForKey:@"serverUser"];

        passwordUI.text=[[mainDelegate.arrayServerList objectAtIndex:idx.row] objectForKey:@"serverPass"];

        ipUI.text=[[mainDelegate.arrayServerList objectAtIndex:idx.row] objectForKey:@"serverIP"];

        portUI.text=[[mainDelegate.arrayServerList objectAtIndex:idx.row] objectForKey:@"serverPort"];

    }
}

- (void)setDetailItem:(id)newDetailItem{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
    }
}

- (IBAction) dismissView:(id)sender{
    
    [self textFieldDoneEditing:nil];
    AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (self.detailItem==nil){
        [mainDelegate.arrayServerList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                 descriptionUI.text, @"serverDescription",
                                                 usernameUI.text, @"serverUser",
                                                 passwordUI.text, @"serverPass",
                                                 ipUI.text, @"serverIP",
                                                 portUI.text, @"serverPort",
                                                 nil
                                                 ]];
    }
    else{
        NSIndexPath *idx = self.detailItem;
        [mainDelegate.arrayServerList removeObjectAtIndex:idx.row];
        [mainDelegate.arrayServerList insertObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    descriptionUI.text, @"serverDescription",
                                                    usernameUI.text, @"serverUser",
                                                    passwordUI.text, @"serverPass",
                                                    ipUI.text, @"serverIP",
                                                    portUI.text, @"serverPort",
                                                    nil
                                                    ] atIndex:idx.row];
//        [[mainDelegate.arrayServerList objectAtIndex:idx.row] setObject:descriptionUI.text forKey:@"serverDescription"];
//        [[mainDelegate.arrayServerList objectAtIndex:idx.row] setObject:usernameUI.text forKey:@"serverUser"];
//        [[mainDelegate.arrayServerList objectAtIndex:idx.row] setObject:passwordUI.text forKey:@"serverPass"];
//        [[mainDelegate.arrayServerList objectAtIndex:idx.row] setObject:ipUI.text forKey:@"serverIP"];
//        [[mainDelegate.arrayServerList objectAtIndex:idx.row] setObject:portUI.text forKey:@"serverPort"];

    }
    [mainDelegate saveServerList];
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark - UITextField

-(BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [descriptionUI resignFirstResponder];
    [ipUI resignFirstResponder];
    [portUI resignFirstResponder];
    [usernameUI resignFirstResponder];
    [passwordUI resignFirstResponder];
    [theTextField resignFirstResponder];
    return YES;
}

-(IBAction)textFieldDoneEditing:(id)sender{
    [descriptionUI resignFirstResponder];
    [ipUI resignFirstResponder];
    [portUI resignFirstResponder];
    [usernameUI resignFirstResponder];
    [passwordUI resignFirstResponder];
}

# pragma  mark - Gestures

- (void)handleSwipeFromRight:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - LifeCycle

- (void)viewDidLoad{
    [super viewDidLoad];
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromRight:)];
    rightSwipe.numberOfTouchesRequired = 1;
    rightSwipe.cancelsTouchesInView=NO;
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwipe];
    [self configureView];
}

- (void)viewDidUnload{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
