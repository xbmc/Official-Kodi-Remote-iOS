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
#import "DetailViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "CustomNavigationController.h"
#import "customButton.h"

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
    if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:@"ServerInfo"]){
        return 44;
    }
    else if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:@"RemoteControl"]){
        return 532;
    }
    return 50;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tableData count];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"bgColor"] count]){
        cell.backgroundColor = [UIColor colorWithRed:[[[[tableData objectAtIndex:indexPath.row] objectForKey:@"bgColor"] objectForKey:@"red"] floatValue]
                                               green:[[[[tableData objectAtIndex:indexPath.row] objectForKey:@"bgColor"] objectForKey:@"green"] floatValue]
                                                blue:[[[[tableData objectAtIndex:indexPath.row] objectForKey:@"bgColor"] objectForKey:@"blue"] floatValue]
                                               alpha:1];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=nil;
    cell = [tableView dequeueReusableCellWithIdentifier:@"rightMenuCell"];
    [[NSBundle mainBundle] loadNibNamed:@"rightCellView" owner:self options:NULL];
    if (cell==nil || [[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:NSLocalizedString(@"LED Torch", nil)]){
        cell = rightMenuCell;
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height)];
        [backgroundView setBackgroundColor:[UIColor colorWithRed:.086 green:.086 blue:.086 alpha:1]];
        cell.selectedBackgroundView = backgroundView;
        if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:@"ServerInfo"]){
            [backgroundView setBackgroundColor:[UIColor colorWithRed:.208f green:.208f blue:.208f alpha:1]];
            cell.selectedBackgroundView = backgroundView;
            UIImageView *xbmc_logo = [[UIImageView alloc] initWithFrame:CGRectMake(125, (int)((44/2) - (36/2)) - 2, 145, 36)];
            xbmc_logo. alpha = .25f;
            [xbmc_logo setImage:[UIImage imageNamed:@"xbmc_logo.png"]];
            [cell insertSubview:xbmc_logo atIndex:0];
        }
    }
    UIImageView *icon = (UIImageView*) [cell viewWithTag:1];
    UILabel *title = (UILabel*) [cell viewWithTag:3];
    UIImageView *line = (UIImageView*) [cell viewWithTag:4];
    NSString *iconName = @"";
    if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:@"ServerInfo"]){
        if (putXBMClogo == YES){
            UIImageView *xbmc_logo = [[UIImageView alloc] initWithFrame:CGRectMake(125, (int)((44/2) - (36/2)) - 2, 145, 36)];
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
        [icon setFrame:CGRectMake(10, (int)((cellHeight/2) - (18/2)), 18, 18)];
        [title setFrame:CGRectMake(icon.frame.size.width + 16, (int)((cellHeight/2) - (title.frame.size.height/2)), self.view.frame.size.width - (icon.frame.size.width + 16), title.frame.size.height)];
        [title setTextAlignment:NSTextAlignmentLeft];
        [title setText:[AppDelegate instance].serverName];
        [title setNumberOfLines:2];
        UIImageView *arrowRight = (UIImageView*) [cell viewWithTag:5];
        [arrowRight setFrame:CGRectMake(arrowRight.frame.origin.x, (int)((cellHeight/2) - (arrowRight.frame.size.height/2)), arrowRight.frame.size.width, arrowRight.frame.size.height)];
    }
    else if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:@"VolumeControl"]){
        [title setText:@""];
        if (volumeSliderView == nil){
            volumeSliderView = [[VolumeSliderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 0, 0)];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
        [volumeSliderView startTimer];
        [cell.contentView addSubview:volumeSliderView];
    }
    else if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:@"RemoteControl"]){
        [title setText:@""];
        if (remoteControllerView == nil){
            remoteControllerView = [[RemoteController alloc] initWithNibName:@"RemoteController" bundle:nil];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [cell.contentView addSubview:remoteControllerView.view];
            [remoteControllerView setEmbeddedView];
        }
    }

    else{
        cell = rightMenuCell;
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height)];
        [backgroundView setBackgroundColor:[UIColor colorWithRed:.086 green:.086 blue:.086 alpha:1]];
        cell.selectedBackgroundView = backgroundView;
        icon = (UIImageView*) [cell viewWithTag:1];
        title = (UILabel*) [cell viewWithTag:3];
        line = (UIImageView*) [cell viewWithTag:4];
        icon.alpha = .6f;
        iconName = [[tableData objectAtIndex:indexPath.row] objectForKey:@"icon"];
        [title setFont:[UIFont fontWithName:@"Roboto-Regular" size:20]];
        [title setNumberOfLines:2];
        CGRect frame = title.frame;
        frame.origin.y = 6;
        frame.size.height = frame.size.height - 12;
        [title setFrame:frame];
        [title setText:[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"]];
    }
    if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"hideLineSeparator"] boolValue] == YES){
        line.hidden = YES;
    }
    if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"fontColor"] count]){
        UIColor *fontColor = [UIColor colorWithRed:[[[[tableData objectAtIndex:indexPath.row] objectForKey:@"fontColor"] objectForKey:@"red"] floatValue]
                                             green:[[[[tableData objectAtIndex:indexPath.row] objectForKey:@"fontColor"] objectForKey:@"green"] floatValue]
                                              blue:[[[[tableData objectAtIndex:indexPath.row] objectForKey:@"fontColor"] objectForKey:@"blue"] floatValue]
                                             alpha:1];
        [title setTextColor:fontColor];
        [title setHighlightedTextColor:fontColor];
    }
    else{
        UIColor *fontColor = [UIColor colorWithRed:.49f green:.49f blue:.49f alpha:1];
        [title setTextColor:fontColor];
        [title setHighlightedTextColor:fontColor];
    }
    if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:NSLocalizedString(@"LED Torch", nil)]){
        icon.alpha = .8f;
        if (torchIsOn){
            iconName = @"torch_on";
        }
    }
    [icon setImage:[UIImage imageNamed:iconName]];
    return cell;
}

-(UIView *)createTableFooterView {
    CGFloat footerHeight = 44.0f;
    UIView *newView = [[UIView alloc] initWithFrame:CGRectMake(-40, 0, self.view.bounds.size.width, footerHeight)];
    [newView setBackgroundColor:[UIColor clearColor]];
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:newView.frame];
    [toolbar setBarStyle:UIBarStyleBlackTranslucent];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")){
        [toolbar setTintColor:[UIColor lightGrayColor]];
    }
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFixedSpace
                                                                                   target: nil
                                                                                   action: nil];
    [fixedSpace setWidth:50.0f];
    
    UIBarButtonItem *fixedSpace2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFixedSpace
                                                                                target: nil
                                                                                action: nil];
    [fixedSpace2 setWidth:2.0f];

    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                                                                   target: nil
                                                                                   action: nil];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"...more", nil)
                                                                   style: UIBarButtonItemStyleBordered
                                                                  target: self
                                                                  action: @selector(addButtonToList)];
    editTableButton = [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Edit", nil)
                                                                   style: UIBarButtonItemStyleBordered
                                                                  target: self
                                                                  action: @selector(editTable:)];
    [toolbar setItems:[NSArray arrayWithObjects:fixedSpace, addButton, flexibleSpace, editTableButton, fixedSpace2, nil]];
    
    [newView insertSubview:toolbar atIndex:0];
    
    return newView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    mainMenu *menuItems = [self.rightMenuItems objectAtIndex:0];
    if (menuItems.family == 3 && [AppDelegate instance].serverOnLine == YES) {
        if (footerView == nil){
            footerView = [self createTableFooterView];
        }
        return footerView;
    }
    else {
        UIImage *myImage = [UIImage imageNamed:@"blank.png"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
        imageView.frame = CGRectMake(0,0,320,8);
        return imageView;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    mainMenu *menuItems = [self.rightMenuItems objectAtIndex:0];
    if (menuItems.family == 3) {
        return 44.0f;
    }
    else {
        return 1.0f;

    }
}

#pragma mark - Table actions

-(void)addButtonToList{
    if ([AppDelegate instance].serverVersion < 13){
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"XBMC \"Gotham\" version 13  or superior is required to access XBMC settings", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
    }
    else{
        DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
        CustomNavigationController *navController = [[CustomNavigationController alloc] initWithRootViewController:detailViewController];
        UINavigationBar *newBar = navController.navigationBar;
        [newBar setTintColor:IOS6_BAR_TINT_COLOR];
        [newBar setBarStyle:UIBarStyleBlack];
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")){
            [newBar setTintColor:TINT_COLOR];
        }
        detailViewController.detailItem = [AppDelegate instance].xbmcSettings;
        [self presentViewController:navController animated:YES completion:NULL];
    }
}

-(void)deleteCustomButton:(NSUInteger)idx {
    customButton *arrayButtons = [[customButton alloc] init];
    [arrayButtons.buttons removeObjectAtIndex:idx];
    [arrayButtons saveData];
    if ([arrayButtons.buttons count] == 0){
        [editTableButton setEnabled:NO];
    }
}

#pragma mark -
#pragma mark Table view delegate


-(void)editTable:(id)sender {
    UIBarButtonItem *editButton = (UIBarButtonItem *)sender;
    if (menuTableView.editing == YES){
        [menuTableView setEditing:NO animated:YES];
        [editButton setTitle:NSLocalizedString(@"Edit", nil)];
        [editButton setStyle:UIBarButtonItemStyleBordered];
    }
    else{
        [menuTableView setEditing:YES animated:YES];
        [editButton setTitle:NSLocalizedString(@"Done", nil)];
        [editButton setStyle:UIBarButtonItemStyleDone];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableview canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (proposedDestinationIndexPath.row < editableRowStartAt){
        return [NSIndexPath indexPathForRow:editableRowStartAt inSection:0];
    }
    else {
        return proposedDestinationIndexPath;
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"isSetting"] boolValue]);
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
	if (editingStyle == UITableViewCellEditingStyleDelete){
        [tableData removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
        [self deleteCustomButton:(indexPath.row - editableRowStartAt)];
	}
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"action"] count]){
        NSString *message=[[[tableData objectAtIndex:indexPath.row] objectForKey:@"action"] objectForKey:@"message"];
        if (message != nil){
            NSString *countdown_message = [[[tableData objectAtIndex:indexPath.row] objectForKey:@"action"] objectForKey:@"countdown_message"];
            if (countdown_message != nil){
                countdown_message = [NSString stringWithFormat:@"%@ %d seconds.", countdown_message, [[[[tableData objectAtIndex:indexPath.row] objectForKey:@"action"] objectForKey:@"countdown_time"] intValue]];
            }
            NSString *cancel_button = [[[tableData objectAtIndex:indexPath.row] objectForKey:@"action"] objectForKey:@"cancel_button"];
            if (cancel_button == nil) cancel_button = NSLocalizedString(@"Cancel", nil);
            NSString *ok_button = [[[tableData objectAtIndex:indexPath.row] objectForKey:@"action"] objectForKey:@"ok_button"];
            if (ok_button == nil) ok_button = NSLocalizedString(@"Yes", nil);
            actionAlertView = [[UIAlertView alloc] initWithTitle:message message:countdown_message delegate:self cancelButtonTitle:cancel_button otherButtonTitles:ok_button, nil];
            
            [actionAlertView show];
        }
        else{
            NSString *command = [[[tableData objectAtIndex:indexPath.row] objectForKey:@"action"] objectForKey:@"command"];
            if ([command isEqualToString:@"System.WOL"]){
                NSString *serverMAC = [AppDelegate instance].obj.serverHWAddr;
                if (serverMAC != nil && ![serverMAC isEqualToString:@":::::"]){
                    [self wakeUp:[AppDelegate instance].obj.serverHWAddr];
                    [messagesView showMessage:NSLocalizedString(@"Command executed", nil) timeout:2.0f color:[UIColor colorWithRed:39.0f/255.0f green:158.0f/255.0f blue:34.0f/255.0f alpha:0.95f]];
                }
                else{
                    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"No sever mac address definied", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                    [alertView show];
                }
            }
            else if ([command isEqualToString:@"AddButton"]){
                [self addButtonToList];
            }
            else if (command != nil){
                NSDictionary *parameters = [[[tableData objectAtIndex:indexPath.row] objectForKey:@"action"] objectForKey:@"params"];
                if (parameters == nil) {
                    parameters = [NSDictionary dictionaryWithObjectsAndKeys:nil];
                }
                [self xbmcAction:command params:parameters];
            }
        }
    }
    else if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:NSLocalizedString(@"Keyboard", nil)]){
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIToggleVirtualKeyboard" object:nil userInfo:nil];
        if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"revealViewTop"] boolValue] == YES){
            [self.slidingViewController resetTopView];
        }
    }
    else if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:NSLocalizedString(@"Help Screen", nil)]){
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIToggleQuickHelp" object:nil userInfo:nil];
        [self.slidingViewController resetTopView];
    }
    else if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:NSLocalizedString(@"Gesture Zone", nil)]){
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"forceGestureZone"];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIToggleGestureZone" object:nil userInfo:userInfo];
        [self.slidingViewController resetTopView];
    }
    else if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:NSLocalizedString(@"Button Pad", nil)]){
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"forceGestureZone"];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIToggleGestureZone" object:nil userInfo:userInfo];
        [self.slidingViewController resetTopView];
    }
    else if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:NSLocalizedString(@"Button Pad/Gesture Zone", nil)]){
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIToggleGestureZone" object:nil userInfo:nil];
        [self.slidingViewController resetTopView];
    }
    else if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:NSLocalizedString(@"LED Torch", nil)]){
        UIImageView *torchIcon = (UIImageView *)[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:1];
        [[tableView cellForRowAtIndexPath:indexPath] viewWithTag:1];
        [self turnTorchOn:!torchIsOn icon:torchIcon];
    }
}

#pragma mark - JSON

-(void)xbmcAction:(NSString *)action params:(NSDictionary *)params{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance];
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (methodError==nil && error == nil){
            [messagesView showMessage:NSLocalizedString(@"Command executed", nil) timeout:2.0f color:[UIColor colorWithRed:39.0f/255.0f green:158.0f/255.0f blue:34.0f/255.0f alpha:0.95f]];
        }
        else{
            [messagesView showMessage:NSLocalizedString(@"Cannot do that", nil) timeout:2.0f color:[UIColor colorWithRed:189.0f/255.0f green:36.0f/255.0f blue:36.0f/255.0f alpha:0.95f]];
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
        NSIndexPath *commandIdx = [self getIndexPathForKey:@"ok_button" withValue:userChoice inArray:[tableData valueForKey:@"action"]];
        NSString *command = [[[tableData valueForKey:@"action"] objectAtIndex:commandIdx.row] objectForKey:@"command"];
        if (command != nil){
            [self xbmcAction:command params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
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
    int deltaY = 0;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")){
        deltaY = 22;
    }
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
    infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.view.frame.size.height/2 - infoLabelHeight/2, self.view.frame.size.width - (20), infoLabelHeight)];
    infoLabel.numberOfLines = 2;
    [infoLabel setText:NSLocalizedString(@"Select an XBMC Server from the list", nil)];
    [infoLabel setBackgroundColor:[UIColor clearColor]];
    [infoLabel setFont:[UIFont fontWithName:@"Roboto-Regular" size:20]];
    [infoLabel setTextAlignment:NSTextAlignmentCenter];
    [infoLabel setTextColor:[UIColor colorWithRed:.49f green:.49f blue:.49f alpha:1]];
    infoLabel.alpha = 0;
    [self.view addSubview:infoLabel];
    menuTableView = [[UITableView alloc] initWithFrame:CGRectMake(self.peekLeftAmount, deltaY, self.view.frame.size.width - self.peekLeftAmount, self.view.frame.size.height - deltaY) style:UITableViewStylePlain];
    [menuTableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [menuTableView setSeparatorColor:[UIColor colorWithRed:0.114f green:0.114f blue:0.114f alpha:1]];
    [menuTableView setDelegate:self];
    [menuTableView setDataSource:self];
    [menuTableView setBackgroundColor:[UIColor clearColor]];
    [menuTableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [menuTableView setScrollEnabled:[[self.rightMenuItems objectAtIndex:0] enableSection]];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")){
        [menuTableView setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    }
    [self.view addSubview:menuTableView];
    footerView = [self createTableFooterView];

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
    
    CGRect frame = [[UIScreen mainScreen ] bounds];
    messagesView = [[MessagesView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 44.0f + deltaY) deltaY:deltaY deltaX:40.0f];
    [self.view addSubview:messagesView];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(connectionSuccess:)
                                                 name: @"XBMCServerConnectionSuccess"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(connectionFailed:)
                                                 name: @"XBMCServerConnectionFailed"
                                               object: nil];
//    [[NSNotificationCenter defaultCenter] addObserver: self
//                                             selector: @selector(startTimer:)
//                                                 name: @"ECSlidingViewUnderRightWillAppear"
//                                               object: nil];
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
    tableData = [[NSMutableArray alloc] initWithCapacity:0];

    for (NSDictionary *item in [[[menuItems mainMethod] objectAtIndex:0] objectForKey:key]){
        NSString *label = [item objectForKey:@"label"];
        if (label == nil) label = @"";

        NSMutableDictionary *bgColor = [item objectForKey:@"bgColor"];
        if (bgColor == nil) {
            bgColor = [[NSMutableDictionary alloc] initWithCapacity:0];
        }
        
        NSNumber *hideLine = [item objectForKey:@"hideLineSeparator"];
        if (hideLine == nil) hideLine = [NSNumber numberWithBool:NO];
        
        NSMutableDictionary *fontColor = [item objectForKey:@"fontColor"];
        if (fontColor == nil) {
            fontColor = [[NSMutableDictionary alloc] initWithCapacity:0];
        }

        NSString *icon = [item objectForKey:@"icon"];
        if (icon == nil) icon = @"";
        
        NSMutableDictionary *action = [item objectForKey:@"action"];
        if (action == nil) action = [[NSMutableDictionary alloc] initWithCapacity:0];
        
        NSNumber *showTop = [item objectForKey:@"revealViewTop"];
        if (showTop == nil) showTop = [NSNumber numberWithBool:NO];
        
        [tableData addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                              label, @"label",
                              bgColor, @"bgColor",
                              hideLine, @"hideLineSeparator",
                              fontColor, @"fontColor",
                              icon, @"icon",
                              action, @"action",
                              showTop, @"revealViewTop",
                              [NSNumber numberWithBool:NO], @"isSetting",
                            nil]];
    }
    editableRowStartAt = [tableData count];
    if ([key isEqualToString:@"online"] && menuItems.family == 3){
        customButton *arrayButtons = [[customButton alloc] init];
        if ([arrayButtons.buttons count] == 0){
            [editTableButton setEnabled:NO];
        }
        for (NSDictionary *item in arrayButtons.buttons) {
            NSString *label = [item objectForKey:@"label"];
            if (label == nil) label = @"";
            [tableData addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  label, @"label",
                                  [[NSMutableDictionary alloc] initWithCapacity:0], @"bgColor",
                                  [NSNumber numberWithBool:NO], @"hideLineSeparator",
                                  [[NSMutableDictionary alloc] initWithCapacity:0], @"fontColor",
                                  @"", @"icon",
                                  [item objectForKey:@"action"], @"action",
                                  [NSNumber numberWithBool:NO], @"revealViewTop",
                                  [NSNumber numberWithBool:YES], @"isSetting",
                                  nil]];
        }
    }

    [UIView animateWithDuration:0.2
                     animations:^{
                         NSInteger n = [menuTableView numberOfRowsInSection:0];
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
                                              NSInteger n = [menuTableView numberOfRowsInSection:0];
                                              for (int i=1;i<n;i++){
                                                  UITableViewCell *cell = [menuTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                                                  if (cell!=nil){
                                                      cell.alpha = 1;
                                                  }
                                              }
                                          }];
                     }];
}

- (NSIndexPath *)getIndexPathForKey:(NSString *)key withValue:(NSString *)value inArray:(NSMutableArray *)array {
    NSIndexPath *foundIndex = nil;
    NSUInteger index = [array indexOfObjectPassingTest:
                        ^BOOL(NSDictionary *dict, NSUInteger idx, BOOL *stop) {
                            return [[dict objectForKey:key] isEqual:value];
                        }];
    if (index != NSNotFound) {
        foundIndex = [NSIndexPath indexPathForRow:index inSection:0];
    }
    return foundIndex;
}


- (void)connectionSuccess:(NSNotification *)note {
    NSDictionary *theData = [note userInfo];
    if (theData != nil) {
        NSString *serverTxt = [theData objectForKey:@"infoText"];
        NSIndexPath *serverRow = [self getIndexPathForKey:@"label" withValue:@"ServerInfo" inArray:tableData];
        if (serverRow != nil) {
            UITableViewCell *cell = [menuTableView cellForRowAtIndexPath:serverRow];
            UILabel *title = (UILabel*) [cell viewWithTag:3];
            [title setText:serverTxt];
            UIImageView *icon = (UIImageView*) [cell viewWithTag:1];
            [icon setImage:[UIImage imageNamed:@"connection_on"]];
        }
        [self setRightMenuOption:@"online"];
        infoLabel.alpha = 0;
    }
}

- (void)connectionFailed:(NSNotification *)note {
    NSDictionary *theData = [note userInfo];
    if (theData != nil) {
        NSString *serverTxt = [theData objectForKey:@"infoText"];
        NSIndexPath *serverRow = [self getIndexPathForKey:@"label" withValue:@"ServerInfo" inArray:tableData];
        if (serverRow != nil) {
            UITableViewCell *cell = [menuTableView cellForRowAtIndexPath:serverRow];
            UILabel *title = (UILabel*) [cell viewWithTag:3];
            [title setText:serverTxt];
            UIImageView *icon = (UIImageView*) [cell viewWithTag:1];
            [icon setImage:[UIImage imageNamed:@"connection_off"]];
        }
        if ([[AppDelegate instance].obj.serverIP length]!=0) {
            infoLabel.alpha = 0;
            [self setRightMenuOption:@"offline"];
        }
        else {
            [tableData removeAllObjects];
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