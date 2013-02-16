//
//  RightMenuViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 9/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//
#import "RightMenuViewController.h"
#import "mainMenu.h"
#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@interface RightMenuViewController ()
@property (nonatomic, unsafe_unretained) CGFloat peekLeftAmount;
@end

@implementation RightMenuViewController
@synthesize peekLeftAmount;
@synthesize rightMenuItems;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)turnTorchOn:(bool)on icon:(UIImageView *)iconTorch {
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            [device lockForConfiguration:nil];
            if (on) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                torchIsOn = YES;
                [iconTorch setImage:[UIImage imageNamed:@"torch_on"]];
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
                torchIsOn = NO;
                [iconTorch setImage:[UIImage imageNamed:@"torch"]];
            }
            [device unlockForConfiguration];
        }
    }
}

#pragma mark -
#pragma mark Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([[labelsList objectAtIndex:indexPath.row] isEqualToString:@"ServerInfo"]){
        return 44;
    }
    else if ([[labelsList objectAtIndex:indexPath.row] isEqualToString:@"RemoteControl"]){
        return 532;
    }
    return 50;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [labelsList count];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[colorsList objectAtIndex:indexPath.row] count]){        
        cell.backgroundColor = [UIColor colorWithRed:[[[colorsList objectAtIndex:indexPath.row] objectForKey:@"red"] floatValue]
                                               green:[[[colorsList objectAtIndex:indexPath.row] objectForKey:@"green"] floatValue]
                                                blue:[[[colorsList objectAtIndex:indexPath.row] objectForKey:@"blue"] floatValue]
                                               alpha:1];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=nil;
    cell = [tableView dequeueReusableCellWithIdentifier:@"rightMenuCell"];
    [[NSBundle mainBundle] loadNibNamed:@"rightCellView" owner:self options:NULL];
    if (cell==nil || [[labelsList objectAtIndex:indexPath.row] isEqualToString:NSLocalizedString(@"LED Torch", nil)]){
        cell = rightMenuCell;
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height)];
        [backgroundView setBackgroundColor:[UIColor colorWithRed:.086 green:.086 blue:.086 alpha:1]];
        cell.selectedBackgroundView = backgroundView;
        if ([[labelsList objectAtIndex:indexPath.row] isEqualToString:@"ServerInfo"]){
            [backgroundView setBackgroundColor:[UIColor colorWithRed:.208f green:.208f blue:.208f alpha:1]];
            cell.selectedBackgroundView = backgroundView;
            UIImageView *xbmc_logo = [[UIImageView alloc] initWithFrame:CGRectMake(165, (int)((44/2) - (36/2)) - 2, 145, 36)];
            xbmc_logo. alpha = .25f;
            [xbmc_logo setImage:[UIImage imageNamed:@"xbmc_logo.png"]];
            [cell insertSubview:xbmc_logo atIndex:0];
        }
    }
    UIImageView *icon = (UIImageView*) [cell viewWithTag:1];
    UILabel *title = (UILabel*) [cell viewWithTag:3];
    UIImageView *line = (UIImageView*) [cell viewWithTag:4];
    NSString *iconName = @"";
    if ([[labelsList objectAtIndex:indexPath.row] isEqualToString:@"ServerInfo"]){
        if (putXBMClogo == YES){
            UIImageView *xbmc_logo = [[UIImageView alloc] initWithFrame:CGRectMake(165, (int)((44/2) - (36/2)) - 2, 145, 36)];
            xbmc_logo. alpha = .25f;
            [xbmc_logo setImage:[UIImage imageNamed:@"xbmc_logo.png"]];
            [cell insertSubview:xbmc_logo atIndex:0];
            putXBMClogo = NO;
        }
        iconName = @"connection_off";
        icon.alpha = 1;
        if ([AppDelegate instance].serverOnLine){
            iconName = @"connection_on";
        }
        int cellHeight = 44;
        [title setFont:[UIFont fontWithName:@"Roboto-Regular" size:13]];
        [icon setFrame:CGRectMake(self.peekLeftAmount +10, (int)((cellHeight/2) - (18/2)), 18, 18)];
        [title setFrame:CGRectMake(self.peekLeftAmount + icon.frame.size.width + 16, (int)((cellHeight/2) - (title.frame.size.height/2)), self.view.frame.size.width - (self.peekLeftAmount + icon.frame.size.width + 16), title.frame.size.height)];
        [title setTextAlignment:NSTextAlignmentLeft];
        [title setText:[AppDelegate instance].serverName];
        [title setNumberOfLines:2];
        UIImageView *arrowRight = (UIImageView*) [cell viewWithTag:5];
        [arrowRight setFrame:CGRectMake(arrowRight.frame.origin.x, (int)((cellHeight/2) - (arrowRight.frame.size.height/2)), arrowRight.frame.size.width, arrowRight.frame.size.height)];
    }
    else if ([[labelsList objectAtIndex:indexPath.row] isEqualToString:@"VolumeControl"]){
        [title setText:@""];
        if (volumeSliderView == nil){
            volumeSliderView = [[VolumeSliderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 0, 0)];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
        [cell.contentView addSubview:volumeSliderView];
    }
    else if ([[labelsList objectAtIndex:indexPath.row] isEqualToString:@"RemoteControl"]){
        [title setText:@""];
        if (remoteControllerView == nil){
            remoteControllerView = [[RemoteController alloc] initWithNibName:@"RemoteController" bundle:nil];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [cell.contentView addSubview:remoteControllerView.view];
            [remoteControllerView setEmbeddedView];
        }
    }

    else{
        icon.alpha = .6f;
        iconName = [iconsList objectAtIndex:indexPath.row];
        [title setFont:[UIFont fontWithName:@"Roboto-Regular" size:20]];
        [title setText:[labelsList objectAtIndex:indexPath.row]];
    }
    if ([[hideLineSeparator objectAtIndex:indexPath.row] boolValue] == YES){
        line.hidden = YES;
    }
    if ([[fontColorList objectAtIndex:indexPath.row] count]){
        UIColor *fontColor = [UIColor colorWithRed:[[[fontColorList objectAtIndex:indexPath.row] objectForKey:@"red"] floatValue]
                                             green:[[[fontColorList objectAtIndex:indexPath.row] objectForKey:@"green"] floatValue]
                                              blue:[[[fontColorList objectAtIndex:indexPath.row] objectForKey:@"blue"] floatValue]
                                             alpha:1];
        [title setTextColor:fontColor];
        [title setHighlightedTextColor:fontColor];
    }
    else{
        UIColor *fontColor = [UIColor colorWithRed:.49f green:.49f blue:.49f alpha:1];
        [title setTextColor:fontColor];
        [title setHighlightedTextColor:fontColor];
    }
    if ([[labelsList objectAtIndex:indexPath.row] isEqualToString:NSLocalizedString(@"LED Torch", nil)]){
        icon.alpha = .8f;
        if (torchIsOn){
            iconName = @"torch_on";
        }
    }
    [icon setImage:[UIImage imageNamed:iconName]];
    
    return cell;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIImage *myImage = [UIImage imageNamed:@"blank.png"];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
	imageView.frame = CGRectMake(0,0,320,8);
	return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 1;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([[actionsList objectAtIndex:indexPath.row] count]){
        NSString *message=[[actionsList objectAtIndex:indexPath.row] objectForKey:@"message"];
        if (message != nil){
            NSString *countdown_message = [[actionsList objectAtIndex:indexPath.row] objectForKey:@"countdown_message"];
            if (countdown_message != nil){
                countdown_message = [NSString stringWithFormat:@"%@ %d seconds.", countdown_message, [[[actionsList objectAtIndex:indexPath.row] objectForKey:@"countdown_time"] intValue]];
            }
            NSString *cancel_button = [[actionsList objectAtIndex:indexPath.row] objectForKey:@"cancel_button"];
            if (cancel_button == nil) cancel_button = NSLocalizedString(@"Cancel", nil);
            NSString *ok_button = [[actionsList objectAtIndex:indexPath.row] objectForKey:@"ok_button"];
            if (ok_button == nil) ok_button = NSLocalizedString(@"Yes", nil);
            actionAlertView = [[UIAlertView alloc] initWithTitle:message message:countdown_message delegate:self cancelButtonTitle:cancel_button otherButtonTitles:ok_button, nil];
            
            [actionAlertView show];
        }
        else{
            NSString *command = [[actionsList objectAtIndex:indexPath.row] objectForKey:@"command"];
            if ([command isEqualToString:@"System.WOL"]){
                NSString *serverMAC = [AppDelegate instance].obj.serverHWAddr;
                if (serverMAC != nil && ![serverMAC isEqualToString:@":::::"]){
                    [self wakeUp:[AppDelegate instance].obj.serverHWAddr];
                    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Command executed", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                    [alertView show];
                }
                else{
                    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"No sever mac address definied", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                    [alertView show];
                }
            }
            else if (command != nil){
                [self powerAction:command params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            }
        }
    }
    else if ([[labelsList objectAtIndex:indexPath.row] isEqualToString:NSLocalizedString(@"Keyboard", nil)]){
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIToggleVirtualKeyboard" object:nil userInfo:nil];
        if ([[revealTopView objectAtIndex:indexPath.row] boolValue] == YES){
            [self.slidingViewController resetTopView];
        }
    }
    else if ([[labelsList objectAtIndex:indexPath.row] isEqualToString:NSLocalizedString(@"Help Screen", nil)]){
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIToggleQuickHelp" object:nil userInfo:nil];
        [self.slidingViewController resetTopView];
    }
    else if ([[labelsList objectAtIndex:indexPath.row] isEqualToString:NSLocalizedString(@"Gesture Zone", nil)]){
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"forceGestureZone"];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIToggleGestureZone" object:nil userInfo:userInfo];
        [self.slidingViewController resetTopView];
    }
    else if ([[labelsList objectAtIndex:indexPath.row] isEqualToString:NSLocalizedString(@"Button Pad", nil)]){
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"forceGestureZone"];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIToggleGestureZone" object:nil userInfo:userInfo];
        [self.slidingViewController resetTopView];
    }
    else if ([[labelsList objectAtIndex:indexPath.row] isEqualToString:NSLocalizedString(@"LED Torch", nil)]){
        UIImageView *torchIcon = (UIImageView *)[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:1];
        [[tableView cellForRowAtIndexPath:indexPath] viewWithTag:1];
        [self turnTorchOn:!torchIsOn icon:torchIcon];
    }
}

#pragma mark - JSON

-(void)powerAction:(NSString *)action params:(NSDictionary *)params{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance];
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (methodError==nil && error == nil){
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Command executed", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
        }
        else{
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot do that", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
        }
    }];
}

-(void)wakeUp:(NSString *)macAddress{
    [[AppDelegate instance] wake:macAddress];
}

# pragma mark - UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1){
        NSString *userChoice = [alertView buttonTitleAtIndex:buttonIndex];
        NSString *command = @"";
        for (NSDictionary *commands in actionsList){
            if ([[commands objectForKey:@"ok_button"] isEqualToString:userChoice]){
                command = [commands objectForKey:@"command"];
            }
        }
        if (![command isEqualToString:@""]){
            [self powerAction:command params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
        }
    }
}

-(void)updateUIAlertViewCountdown:(NSString *)countdown_message{
    [actionAlertView setMessage:countdown_message];
}

#pragma mark - LifeCycle

-(void)viewWillDisappear:(BOOL)animated{
    [volumeSliderView stopTimer];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    torchIsOn = NO;
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            torchIsOn = [device torchLevel];
        }
    }
    self.peekLeftAmount = 40.0f;
    [self.slidingViewController setAnchorLeftPeekAmount:self.peekLeftAmount];
    self.slidingViewController.underRightWidthLayout = ECFullWidth;
    int infoLabelHeight = 100;
    infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.peekLeftAmount +10, self.view.frame.size.height/2 - infoLabelHeight/2, self.view.frame.size.width - (self.peekLeftAmount + 20), infoLabelHeight)];
    infoLabel.numberOfLines = 2;
    [infoLabel setText:NSLocalizedString(@"Select an XBMC Server from the list", nil)];
    [infoLabel setBackgroundColor:[UIColor clearColor]];
    [infoLabel setFont:[UIFont fontWithName:@"Roboto-Regular" size:20]];
    [infoLabel setTextAlignment:NSTextAlignmentCenter];
    [infoLabel setTextColor:[UIColor colorWithRed:.49f green:.49f blue:.49f alpha:1]];
    infoLabel.alpha = 0;
    [self.view addSubview:infoLabel];
    menuTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    [menuTableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [menuTableView setSeparatorColor:[UIColor colorWithRed:0.114f green:0.114f blue:0.114f alpha:1]];
    [menuTableView setDelegate:self];
    [menuTableView setDataSource:self];
    [menuTableView setBackgroundColor:[UIColor clearColor]];
    [menuTableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [menuTableView setScrollEnabled:[[self.rightMenuItems objectAtIndex:0] enableSection]];
    if([[UIScreen mainScreen ] bounds].size.height >= 568){
        [menuTableView setScrollEnabled:NO];
    }
    [self.view addSubview:menuTableView];
    if ([[AppDelegate instance].obj.serverIP length]!=0){
        if (![AppDelegate instance].serverOnLine){
            [self setRightMenuOption:@"offline"];
        }
        else{
            [self setRightMenuOption:@"online"];
        }
    }
    else {
        infoLabel.alpha = 1;
        putXBMClogo = YES;
        [self setRightMenuOption:@"utility"];

    }
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(connectionSuccess:)
                                                 name: @"XBMCServerConnectionSuccess"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(connectionFailed:)
                                                 name: @"XBMCServerConnectionFailed"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(startTimer:)
                                                 name: @"ECSlidingViewUnderRightWillAppear"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(stopTimer:)
                                                 name: @"ECSlidingViewUnderRightWillDisappear"
                                               object: nil];

}

-(void)startTimer:(id)sender{
    [volumeSliderView startTimer];
}

-(void)stopTimer:(id)sender{
    [volumeSliderView stopTimer];
}

- (void)setRightMenuOption:(NSString *)key{
    mainMenu *menuItems = [self.rightMenuItems objectAtIndex:0];
    labelsList = [[NSMutableArray alloc] initWithCapacity:0];
    colorsList = [[NSMutableArray alloc] initWithCapacity:0];
    hideLineSeparator = [[NSMutableArray alloc] initWithCapacity:0];
    fontColorList = [[NSMutableArray alloc] initWithCapacity:0];
    iconsList = [[NSMutableArray alloc] initWithCapacity:0];
    actionsList = [[NSMutableArray alloc] initWithCapacity:0];
    revealTopView = [[NSMutableArray alloc] initWithCapacity:0];

    for (NSDictionary *item in [[[menuItems mainMethod] objectAtIndex:0] objectForKey:key]){
        NSString *label = [item objectForKey:@"label"];
        if (label == nil) label = @"";
        [labelsList addObject:label];
        NSMutableDictionary *bgColor = [item objectForKey:@"bgColor"];
        if (bgColor == nil) {
            bgColor = [[NSMutableDictionary alloc] initWithCapacity:0];
        }
        [colorsList addObject:bgColor];
        
        NSNumber *hideLine = [item objectForKey:@"hideLineSeparator"];
        if (hideLine == nil) hideLine = [NSNumber numberWithBool:NO];
        [hideLineSeparator addObject:hideLine];
        
        NSMutableDictionary *fontColor = [item objectForKey:@"fontColor"];
        if (fontColor == nil) {
            fontColor = [[NSMutableDictionary alloc] initWithCapacity:0];
        }
        [fontColorList addObject:fontColor];
        NSString *icon = [item objectForKey:@"icon"];
        if (icon == nil) icon = @"";
        [iconsList addObject:icon];
        
        NSMutableDictionary *action = [item objectForKey:@"action"];
        if (action == nil) action = [[NSMutableDictionary alloc] initWithCapacity:0];
        [actionsList addObject:action];
        
        NSNumber *showTop = [item objectForKey:@"revealViewTop"];
        if (showTop == nil) showTop = [NSNumber numberWithBool:NO];
        [revealTopView addObject:showTop];
    }
    [UIView animateWithDuration:0.2
                     animations:^{
                         int n = [menuTableView numberOfRowsInSection:0];
                         for (int i=1;i<n;i++){
                             UITableViewCell *cell = [menuTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                             if (cell!=nil){
                                 cell.alpha = 0;
                             }
                         }
                     }
                     completion:^(BOOL finished){
                         [menuTableView reloadData];
                         [UIView animateWithDuration:0.2
                                          animations:^{
                                              int n = [menuTableView numberOfRowsInSection:0];
                                              for (int i=1;i<n;i++){
                                                  UITableViewCell *cell = [menuTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                                                  if (cell!=nil){
                                                      cell.alpha = 1;
                                                  }
                                              }
                                          }];
                     }];
}

- (void)connectionSuccess:(NSNotification *)note {
    NSDictionary *theData = [note userInfo];
    if (theData != nil) {
        NSString *serverTxt = [theData objectForKey:@"infoText"];
        UITableViewCell *cell = [menuTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[labelsList indexOfObject:@"ServerInfo"] inSection:0]];
        UILabel *title = (UILabel*) [cell viewWithTag:3];
        [title setText:serverTxt];
        UIImageView *icon = (UIImageView*) [cell viewWithTag:1];
        [icon setImage:[UIImage imageNamed:@"connection_on"]];
        [self setRightMenuOption:@"online"];
        infoLabel.alpha = 0;
    }
}

- (void)connectionFailed:(NSNotification *)note {
    NSDictionary *theData = [note userInfo];
    if (theData != nil) {
        NSString *serverTxt = [theData objectForKey:@"infoText"];
        UITableViewCell *cell = [menuTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[labelsList indexOfObject:@"ServerInfo"] inSection:0]];
        UILabel *title = (UILabel*) [cell viewWithTag:3];
        [title setText:serverTxt];
        UIImageView *icon = (UIImageView*) [cell viewWithTag:1];
        [icon setImage:[UIImage imageNamed:@"connection_off"]];
        if ([[AppDelegate instance].obj.serverIP length]!=0){
            infoLabel.alpha = 0;
            [self setRightMenuOption:@"offline"];
        }
        else{
            [labelsList removeAllObjects];
            [menuTableView reloadData];
            infoLabel.alpha = 1;
            putXBMClogo = YES;
            [self setRightMenuOption:@"utility"];
        }
    }
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end