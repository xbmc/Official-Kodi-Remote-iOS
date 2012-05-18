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
        NSIndexPath *idx=self.detailItem;
        
        descriptionUI.text=[[[AppDelegate instance].arrayServerList objectAtIndex:idx.row] objectForKey:@"serverDescription"];
        
        usernameUI.text=[[[AppDelegate instance].arrayServerList objectAtIndex:idx.row] objectForKey:@"serverUser"];

        passwordUI.text=[[[AppDelegate instance].arrayServerList objectAtIndex:idx.row] objectForKey:@"serverPass"];

        ipUI.text=[[[AppDelegate instance].arrayServerList objectAtIndex:idx.row] objectForKey:@"serverIP"];

        portUI.text=[[[AppDelegate instance].arrayServerList objectAtIndex:idx.row] objectForKey:@"serverPort"];
        
        preferTVPostersUI.on=[[[[AppDelegate instance].arrayServerList objectAtIndex:idx.row] objectForKey:@"preferTVPosters"] boolValue];


    }
}

- (void)setDetailItem:(id)newDetailItem{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
    }
}

- (IBAction) dismissView:(id)sender{
    
    [self textFieldDoneEditing:nil];
    if (self.detailItem==nil){
        [[AppDelegate instance].arrayServerList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                 descriptionUI.text, @"serverDescription",
                                                 usernameUI.text, @"serverUser",
                                                 passwordUI.text, @"serverPass",
                                                 ipUI.text, @"serverIP",
                                                 portUI.text, @"serverPort",
                                                 [NSNumber numberWithBool:preferTVPostersUI.on], @"preferTVPosters",
                                                 nil
                                                 ]];
    }
    else{
        NSIndexPath *idx = self.detailItem;
        [[AppDelegate instance].arrayServerList removeObjectAtIndex:idx.row];
        [[AppDelegate instance].arrayServerList insertObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    descriptionUI.text, @"serverDescription",
                                                    usernameUI.text, @"serverUser",
                                                    passwordUI.text, @"serverPass",
                                                    ipUI.text, @"serverIP",
                                                    portUI.text, @"serverPort",
                                                    [NSNumber numberWithBool:preferTVPostersUI.on], @"preferTVPosters",
                                                    nil
                                                    ] atIndex:idx.row];
    }
    [[AppDelegate instance] saveServerList];
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
    if(!searching){
        int j = [services  count];
        if (j==1){
            [self resolveIPAddress:[services objectAtIndex:0]];
        }
        else {
            if (j==0){
                [self AnimLabel:noInstances AnimDuration:0.3 Alpha:1.0 XPos:0];
            }
            else{
                [discoveredInstancesTableView reloadData];
                [self AnimView:discoveredInstancesView AnimDuration:0.3 Alpha:1.0 XPos:0];
            }
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
    NSNetService* service = [services objectAtIndex:indexPath.row];
	cell.textLabel.text = [service name];
	cell.textLabel.textColor = [UIColor blackColor];
	cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self resolveIPAddress:[services objectAtIndex:indexPath.row]];
}

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
