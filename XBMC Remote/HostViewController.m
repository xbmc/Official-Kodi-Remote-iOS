//
//  HostViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 14/4/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "HostViewController.h"
#import "AppDelegate.h"
#include <arpa/inet.h>

#define serviceType @"_xbmc-jsonrpc-h._tcp"
#define domainName @"local"
#define DISCOVER_TIMEOUT 5.0f

@interface HostViewController ()
-(void)configureView;
@end

@implementation HostViewController

@synthesize detailItem = _detailItem;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}
- (void)AnimLabel:(UILabel *)Lab AnimDuration:(float)seconds Alpha:(float)alphavalue XPos:(int)X{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	Lab.alpha = alphavalue;
	CGRect frame;
	frame = [Lab frame];
	frame.origin.x = X;
	Lab.frame = frame;
    [UIView commitAnimations];
}

- (void)AnimView:(UIView *)view AnimDuration:(float)seconds Alpha:(float)alphavalue XPos:(int)X{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	view.alpha = alphavalue;
	CGRect frame;
	frame = [view frame];
	frame.origin.x = X;
	view.frame = frame;
    [UIView commitAnimations];
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
#pragma mark - UITextFieldDelegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    [textField setTextColor:[UIColor blackColor]];
}
-(void)resignKeyboard{
    [descriptionUI resignFirstResponder];
    [ipUI resignFirstResponder];
    [portUI resignFirstResponder];
    [usernameUI resignFirstResponder];
    [passwordUI resignFirstResponder];
}

-(BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [self resignKeyboard];
    [theTextField resignFirstResponder];
    return YES;
}

-(IBAction)textFieldDoneEditing:(id)sender{
    [self resignKeyboard];
}

# pragma  mark - Gestures

- (void)handleSwipeFromRight:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


# pragma mark - NSNetServiceBrowserDelegate Methods

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser{
    searching = YES;
    [self updateUI];
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser{
    searching = NO;
    [self updateUI];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary *)errorDict{
    searching = NO;
    [self handleError:[errorDict objectForKey:NSNetServicesErrorCode]];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
           didFindService:(NSNetService *)aNetService
               moreComing:(BOOL)moreComing {    
    [services addObject:aNetService];
    if(!moreComing) {
        [self stopDiscovery];
        [self updateUI];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
         didRemoveService:(NSNetService *)aNetService
               moreComing:(BOOL)moreComing{
    [services removeObject:aNetService];
    if(!moreComing) {
        [self updateUI];
    }
}

- (void)handleError:(NSNumber *)error {
    NSLog(@"An error occurred. Error code = %d", [error intValue]);
    // Handle error here
}

- (void)updateUI{
    if(searching){
        // Update the user interface to indicate searching
        // Also update any UI that lists available services
//        NSLog(@"sto cercando");

    }
    else{
        // Update the user interface to indicate not searching
//        NSLog(@"finito di cercare");
        int j = [services  count];
        if (j==1){
            [self resolveIPAddress:[services objectAtIndex:0]];
        }
        else {
//            NSLog(@"Ne ho trovati %d", j);
            if (j==0){
                [self AnimLabel:noInstances AnimDuration:0.3 Alpha:1.0 XPos:0];
            }
            else{
                [discoveredInstancesTableView reloadData];
                [self AnimView:discoveredInstancesView AnimDuration:0.3 Alpha:1.0 XPos:0];

            }
            //build selection table!
        }
    }
}

# pragma mark - resolveIPAddress Methods


-(void) resolveIPAddress:(NSNetService *)service {    
    NSNetService *remoteService = service;
    remoteService.delegate = self;
    [remoteService resolveWithTimeout:0];
}
-(void)netServiceDidResolveAddress:(NSNetService *)service {
//    NSString *name = nil;
//    NSData *address = nil;
//    struct sockaddr_in *socketAddress = nil;
//    NSString *ipString = nil;
//    int port;
    for (NSData* data in [service addresses]) {
        char addressBuffer[100];
        struct sockaddr_in* socketAddress = (struct sockaddr_in*) [data bytes];
        int sockFamily = socketAddress->sin_family;
        if (sockFamily == AF_INET ) {//|| sockFamily == AF_INET6 should be considered
            const char* addressStr = inet_ntop(sockFamily,
                                               &(socketAddress->sin_addr), addressBuffer,
                                               sizeof(addressBuffer));
            int port = ntohs(socketAddress->sin_port);
            if (addressStr && port){
//                NSLog(@"%@ at %s:%d", [service name], addressStr, port);
                descriptionUI.text = [service name];
                ipUI.text = [NSString stringWithFormat:@"%s", addressStr];
                portUI.text = [NSString stringWithFormat:@"%d", port];
                
                [descriptionUI setTextColor:[UIColor blueColor]];
                [ipUI setTextColor:[UIColor blueColor]];
                [portUI setTextColor:[UIColor blueColor]];

                [self AnimView:discoveredInstancesView AnimDuration:0.3 Alpha:1.0 XPos:320];

            }
        }
    }
}

-(void)stopDiscovery{
    [netServiceBrowser stop];
    [activityIndicatorView stopAnimating];
    startDiscover.enabled = YES;
}

-(IBAction)startDiscover:(id)sender{
    [self resignKeyboard];
    [activityIndicatorView startAnimating];
    [services removeAllObjects];
    startDiscover.enabled = NO;
    [self AnimLabel:noInstances AnimDuration:0.3 Alpha:0.0 XPos:320];
    [self AnimView:discoveredInstancesView AnimDuration:0.3 Alpha:1.0 XPos:320];

    searching = NO;
    [netServiceBrowser setDelegate:self];
    [netServiceBrowser searchForServicesOfType:serviceType inDomain:domainName];
    timer = [NSTimer scheduledTimerWithTimeInterval:DISCOVER_TIMEOUT target:self selector:@selector(stopDiscovery) userInfo:nil repeats:NO];
}

#pragma mark - TableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [services count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *tableCellIdentifier = @"UITableViewCell";
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableCellIdentifier];
	}
	
	NSUInteger count = [services count];
	if (count == 0) {
		return cell;
	}
	
	// Set up the text for the cell
	NSNetService* service = [services objectAtIndex:indexPath.row];
	cell.textLabel.text = [service name];
	cell.textLabel.textColor = [UIColor blackColor];
	cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self resolveIPAddress:[services objectAtIndex:indexPath.row]];
}


//- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//	// Ignore the selection if there are no services as the searchingForServicesString cell
//	// may be visible and tapping it would do nothing
//	if ([services count] == 0)
//		return nil;
//	return indexPath;
//}


#pragma mark - LifeCycle
-(void)viewDidDisappear:(BOOL)animated{
    [timer invalidate];
    timer = nil;
    netServiceBrowser = nil;
    services = nil;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    services = [[NSMutableArray alloc] init];
    netServiceBrowser = [[NSNetServiceBrowser alloc] init];
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

-(void)dealloc{
    services = nil;
    netServiceBrowser = nil;
    descriptionUI = nil;
    ipUI = nil;
    usernameUI = nil;
    passwordUI = nil;
    portUI = nil;
}

@end
