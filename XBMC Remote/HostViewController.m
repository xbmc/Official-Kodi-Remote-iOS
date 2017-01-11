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
#if (TARGET_IPHONE_SIMULATOR)
#import <net/if_types.h>
#import <net/route.h>
#import <netinet/if_ether.h>
#else
#import "if_types.h"
#import "route.h"
#import "if_ether.h"
#endif

#import <sys/socket.h>
#import <sys/sysctl.h>
#import <ifaddrs.h>
#import <net/if_dl.h>
#import <net/if.h>
#import <netinet/in.h>

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
- (void)AnimLabel:(UIView *)Lab AnimDuration:(float)seconds Alpha:(float)alphavalue XPos:(int)X{
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
        self.navigationItem.title=NSLocalizedString(@"New XBMC Server", nil);
    }
    else {
        self.navigationItem.title=NSLocalizedString(@"Modify XBMC Server", nil);
        NSIndexPath *idx=self.detailItem;
        
        descriptionUI.text=[[[AppDelegate instance].arrayServerList objectAtIndex:idx.row] objectForKey:@"serverDescription"];
        
        usernameUI.text=[[[AppDelegate instance].arrayServerList objectAtIndex:idx.row] objectForKey:@"serverUser"];

        passwordUI.text=[[[AppDelegate instance].arrayServerList objectAtIndex:idx.row] objectForKey:@"serverPass"];

        ipUI.text=[[[AppDelegate instance].arrayServerList objectAtIndex:idx.row] objectForKey:@"serverIP"];

        portUI.text=[[[AppDelegate instance].arrayServerList objectAtIndex:idx.row] objectForKey:@"serverPort"];
        
        NSString *macAddress = [[[AppDelegate instance].arrayServerList objectAtIndex:idx.row] objectForKey:@"serverMacAddress"];
        NSArray *mac_octect = [macAddress componentsSeparatedByString:@":"];
        NSInteger num_octects = [mac_octect count];
        if (num_octects>0) mac_0_UI.text = [mac_octect objectAtIndex:0];
        if (num_octects>1) mac_1_UI.text = [mac_octect objectAtIndex:1];
        if (num_octects>2) mac_2_UI.text = [mac_octect objectAtIndex:2];
        if (num_octects>3) mac_3_UI.text = [mac_octect objectAtIndex:3];
        if (num_octects>4) mac_4_UI.text = [mac_octect objectAtIndex:4];
        if (num_octects>5) mac_5_UI.text = [mac_octect objectAtIndex:5];

        preferTVPostersUI.on=[[[[AppDelegate instance].arrayServerList objectAtIndex:idx.row] objectForKey:@"preferTVPosters"] boolValue];
        tcpPortUI.text = [[[AppDelegate instance].arrayServerList objectAtIndex:idx.row] objectForKey:@"tcpPort"];

    }
}

- (void)setDetailItem:(id)newDetailItem{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
    }
}

- (IBAction) dismissView:(id)sender{
    
    [self textFieldDoneEditing:nil];
    
    if (descriptionUI.text == nil) descriptionUI.text = @"";
    if (usernameUI.text == nil) usernameUI.text = @"";
    if (passwordUI.text == nil) passwordUI.text = @"";
    if (ipUI.text == nil) ipUI.text = @"";
    if (portUI.text == nil) portUI.text = @"";
    if (tcpPortUI.text == nil) tcpPortUI.text = @"";
    if (mac_0_UI.text == nil) mac_0_UI.text = @"";
    if (mac_1_UI.text == nil) mac_1_UI.text = @"";
    if (mac_2_UI.text == nil) mac_2_UI.text = @"";
    if (mac_3_UI.text == nil) mac_3_UI.text = @"";
    if (mac_4_UI.text == nil) mac_4_UI.text = @"";
    if (mac_5_UI.text == nil) mac_5_UI.text = @"";

    NSString *macAddress = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@", mac_0_UI.text, mac_1_UI.text, mac_2_UI.text, mac_3_UI.text, mac_4_UI.text, mac_5_UI.text];
    if (self.detailItem==nil){
        [[AppDelegate instance].arrayServerList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           descriptionUI.text, @"serverDescription",
                                                           usernameUI.text, @"serverUser",
                                                           passwordUI.text, @"serverPass",
                                                           ipUI.text, @"serverIP",
                                                           portUI.text, @"serverPort",
                                                           macAddress, @"serverMacAddress",
                                                           [NSNumber numberWithBool:preferTVPostersUI.on], @"preferTVPosters",
                                                           tcpPortUI.text, @"tcpPort",
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
                                                              macAddress, @"serverMacAddress",
                                                              [NSNumber numberWithBool:preferTVPostersUI.on], @"preferTVPosters",
                                                              tcpPortUI.text, @"tcpPort",
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
    [mac_0_UI resignFirstResponder];
    [mac_1_UI resignFirstResponder];
    [mac_2_UI resignFirstResponder];
    [mac_3_UI resignFirstResponder];
    [mac_4_UI resignFirstResponder];
    [mac_5_UI resignFirstResponder];
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



- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    if (newLength > 2 && textField.tag>100){
        if (textField.tag < 106){
            UITextField *next = (UITextField*) [self.view viewWithTag:textField.tag + 1];
            [next becomeFirstResponder];
            [next selectAll:self];
        }
        return NO;
    }
    else{
        return YES;
    }
//    return (newLength > 2 && textField.tag>100) ? NO : YES;
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
//    NSLog(@"An error occurred. Error code = %d", [error intValue]);
    // Handle error here
}

- (void)updateUI{
    if(!searching){
        NSInteger j = [services  count];
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

#pragma mark - resolveMacAddress Methods

- (NSString*)resolveMacFromIP:(NSString*)ipAddress {
    NSString* res = nil;
    
    in_addr_t addr = inet_addr([ipAddress UTF8String]);
    
    size_t needed;
    char *buf, *next;
    
    struct rt_msghdr *rtm;
    struct sockaddr_inarp *sin;
    struct sockaddr_dl *sdl;
    
    int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, RTF_LLINFO};
    
    if (sysctl(mib, sizeof(mib) / sizeof(mib[0]), NULL, &needed, NULL, 0) < 0)
    {
        NSLog(@"error in route-sysctl-estimate");
        return nil;
    }
    
    if ((buf = (char*)malloc(needed)) == NULL)
    {
        NSLog(@"error in malloc");
        return nil;
    }
    
    if (sysctl(mib, sizeof(mib) / sizeof(mib[0]), buf, &needed, NULL, 0) < 0)
    {
        NSLog(@"retrieval of routing table");
        return nil;
    }
    
    for (next = buf; next < buf + needed; next += rtm->rtm_msglen)
    {
        rtm = (struct rt_msghdr *)next;
        sin = (struct sockaddr_inarp *)(rtm + 1);
        sdl = (struct sockaddr_dl *)(sin + 1);
        
        if (addr != sin->sin_addr.s_addr || sdl->sdl_alen < 6)
            continue;
        
        u_char *cp = (u_char*)LLADDR(sdl);
        
        res = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
               cp[0], cp[1], cp[2], cp[3], cp[4], cp[5]];
        
        break;
    }
    
    free(buf);
    
    return res;
}

-(void)fillMacAddressInfo {
    NSString *macAddress = [self resolveMacFromIP:ipUI.text];
    NSArray *macPart = [macAddress componentsSeparatedByString:@":"];
    if ([macPart count] == 6 && ![macAddress isEqualToString:@"02:00:00:00:00:00"]){
        [mac_0_UI setText:[macPart objectAtIndex:0]];
        [mac_0_UI setTextColor:[UIColor blueColor]];
        [mac_1_UI setText:[macPart objectAtIndex:1]];
        [mac_1_UI setTextColor:[UIColor blueColor]];
        [mac_2_UI setText:[macPart objectAtIndex:2]];
        [mac_2_UI setTextColor:[UIColor blueColor]];
        [mac_3_UI setText:[macPart objectAtIndex:3]];
        [mac_3_UI setTextColor:[UIColor blueColor]];
        [mac_4_UI setText:[macPart objectAtIndex:4]];
        [mac_4_UI setTextColor:[UIColor blueColor]];
        [mac_5_UI setText:[macPart objectAtIndex:5]];
        [mac_5_UI setTextColor:[UIColor blueColor]];
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
                NSString *serverJSON=[NSString stringWithFormat:@"http://%@:%@/jsonrpc", ipUI.text, portUI.text];
                NSURL *url = [[NSURL alloc] initWithString:serverJSON];
                NSURLRequest *request = [NSURLRequest requestWithURL:url];
                NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
                [connection start];
                [self AnimView:discoveredInstancesView AnimDuration:0.3 Alpha:1.0 XPos:self.view.frame.size.width];
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
    [self AnimLabel:noInstances AnimDuration:0.3 Alpha:0.0 XPos:self.view.frame.size.width];
    [self AnimView:discoveredInstancesView AnimDuration:0.3 Alpha:1.0 XPos:self.view.frame.size.width];

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

#pragma mark - NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [self fillMacAddressInfo];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self fillMacAddressInfo];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self fillMacAddressInfo];
}

#pragma mark - LifeCycle

- (void)viewWillAppear:(BOOL)animated{
    CGSize size = CGSizeMake(320, 380);
    self.preferredContentSize = size;
    [super viewWillAppear:animated];
}

-(void)viewDidDisappear:(BOOL)animated{
    [timer invalidate];
    timer = nil;
    netServiceBrowser = nil;
    services = nil;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [descriptionLabel setText:NSLocalizedString(@"Description", nil)];
    [hostLabel setText:NSLocalizedString(@"Host : port /\nTCP port", nil)];
    [macLabel setText:NSLocalizedString(@"MAC Address", nil)];
    [userLabel setText:NSLocalizedString(@"Username and Password", nil)];
    [preferLabel setText:NSLocalizedString(@"Prefer posters for TV shows", nil)];
    [noInstancesLabel setText:NSLocalizedString(@"No XBMC instances were found :(", nil)];
    [findLabel setText:NSLocalizedString(@"\"Find XBMC\" requires XBMC server option\n\"Announce these services to other systems via Zeroconf\" enabled", nil)];
    [howtoLabel setText:NSLocalizedString(@"How-to activate the remote app in XBMC", nil)];
    [howtoEdenLabel setText:NSLocalizedString(@"Eden\nSettings -> Network -> Allow control of XBMC via HTTP", nil)];
    [howtoLaterLabel setText:NSLocalizedString(@"Frodo / Gotham\nSettings -> Services -> Web Server -> Allow control of XBMC via HTTP", nil)];
    
    [startDiscover setTitle:NSLocalizedString(@"Find XBMC", nil) forState:UIControlStateNormal];
    startDiscover.titleLabel.numberOfLines = 1;
    startDiscover.titleLabel.adjustsFontSizeToFitWidth = YES;
    startDiscover.titleLabel.lineBreakMode = NSLineBreakByClipping;
    UIImage *buttonEdit = [UIImage imageNamed:@"button_edit"];
    UIEdgeInsets insets = UIEdgeInsetsMake(0.0f, 16.0f, 0.0f, 16.0f);
    buttonEdit = [buttonEdit resizableImageWithCapInsets:insets];
    [startDiscover setBackgroundImage:buttonEdit forState:UIControlStateNormal];
    UIImage *buttonEditSelected = [UIImage imageNamed:@"button_edit_highlight"];
    buttonEditSelected = [buttonEditSelected resizableImageWithCapInsets:insets];
    [startDiscover setBackgroundImage:buttonEditSelected forState:UIControlStateSelected];
    [startDiscover setBackgroundImage:buttonEditSelected forState:UIControlStateHighlighted];
    
    UIImage *buttonSave = [UIImage imageNamed:@"button_edit_down.png"];
    buttonSave = [buttonSave resizableImageWithCapInsets:insets];
    [saveButton setBackgroundImage:buttonSave forState:UIControlStateNormal];
    [saveButton setTitle:NSLocalizedString(@"Save", nil) forState:UIControlStateNormal];
    
    [descriptionUI setPlaceholder:NSLocalizedString(@"e.g. My XBMC", nil)];
    [ipUI setPlaceholder:NSLocalizedString(@"e.g. 192.168.0.8", nil)];
    [usernameUI setPlaceholder:NSLocalizedString(@"Username", nil)];
    [passwordUI setPlaceholder:NSLocalizedString(@"Password", nil)];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")){
        self.edgesForExtendedLayout = 0;
    }
    [discoveredInstancesTableView setBackgroundColor:[UIColor whiteColor]];
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

-(void)dealloc{
    services = nil;
    netServiceBrowser = nil;
    descriptionUI = nil;
    ipUI = nil;
    usernameUI = nil;
    passwordUI = nil;
    portUI = nil;
    mac_0_UI = nil;
    mac_1_UI = nil;
    mac_2_UI = nil;
    mac_3_UI = nil;
    mac_4_UI = nil;
    mac_5_UI = nil;
}

@end
