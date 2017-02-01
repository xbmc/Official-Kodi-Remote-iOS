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
#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"

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
        return 570;
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
    else { // xcode xib bug with ipad?
        cell.backgroundColor = [UIColor colorWithRed:0.141176f green:0.141176f blue:0.141176f alpha:1.0f];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=nil;
    cell = [tableView dequeueReusableCellWithIdentifier:@"rightMenuCell"];
    [[NSBundle mainBundle] loadNibNamed:@"rightCellView" owner:self options:NULL];
    if ( cell == nil ) {
        cell = rightMenuCell;
        UIView *backView = [[UIView alloc] initWithFrame:cell.frame];
        [backView setBackgroundColor:[UIColor colorWithRed:.086 green:.086 blue:.086 alpha:1]];
        cell.selectedBackgroundView = backView;
        UIImageView *xbmc_logo = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 195.0f, (int)((44/2) - (36/2)) - 2, 145, 36)];
        xbmc_logo. alpha = .25f;
        [xbmc_logo setImage:[UIImage imageNamed:@"xbmc_logo.png"]];
        xbmc_logo.tag = 101;
        [cell.contentView insertSubview:xbmc_logo atIndex:0];
    }
    UIImageView *icon = (UIImageView*) [cell viewWithTag:1];
    UILabel *title = (UILabel*) [cell viewWithTag:3];
    UIImageView *line = (UIImageView*) [cell viewWithTag:4];
    UIImageView *xbmc_logo = (UIImageView*) [cell viewWithTag:101];
    icon.hidden = NO;
    xbmc_logo.hidden = YES;
    [cell setAccessoryView:nil];
    NSString *iconName = @"";
    if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:@"ServerInfo"]) {
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        xbmc_logo.hidden = NO;
        iconName = @"connection_off";
        icon.alpha = 1;
        if ([AppDelegate instance].serverOnLine == YES) {
            if ([AppDelegate instance].serverTCPConnectionOpen == YES) {
                iconName = @"connection_on";
            }
            else {
                iconName = @"connection_on_notcp";
            }
        }
        int cellHeight = 44;
        [title setFont:[UIFont fontWithName:@"Roboto-Regular" size:13]];
        [title setAutoresizingMask:UIViewAutoresizingNone];
        [icon setAutoresizingMask:UIViewAutoresizingNone];
        [icon setFrame:CGRectMake(10, (int)((cellHeight/2) - (18/2)), 18, 18)];
        [title setFrame:CGRectMake(icon.frame.size.width + 16, (int)((cellHeight/2) - (title.frame.size.height/2)), tableView.frame.size.width - (icon.frame.size.width + 32), title.frame.size.height)];
        [title setTextAlignment:NSTextAlignmentLeft];
        [title setText:[AppDelegate instance].serverName];
        [title setNumberOfLines:2];
        UIImageView *arrowRight = (UIImageView*) [cell viewWithTag:5];
        [arrowRight setFrame:CGRectMake(arrowRight.frame.origin.x, (int)((cellHeight/2) - (arrowRight.frame.size.height/2)), arrowRight.frame.size.width, arrowRight.frame.size.height)];
    }
    else if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:@"VolumeControl"]) {
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

        [title setText:@""];
        if (volumeSliderView == nil){
            volumeSliderView = [[VolumeSliderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 0, 0)];
            [volumeSliderView startTimer];
        }
        [cell.contentView addSubview:volumeSliderView];
    }
    else if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"] isEqualToString:@"RemoteControl"]) {
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [title setText:@""];
        if (remoteControllerView == nil){
            remoteControllerView = [[RemoteController alloc] initWithNibName:@"RemoteController" bundle:nil];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [cell.contentView addSubview:remoteControllerView.view];
            [remoteControllerView setEmbeddedView];
        }
    }
    else {
        int cellHeight = 50.0f;
        cell = rightMenuCell;
        [cell setAccessoryView:nil];
        cell.backgroundColor = [UIColor colorWithRed:0.141176f green:0.141176f blue:0.141176f alpha:1.0f];
        [cell setTintColor:[UIColor lightGrayColor]];
        [cell setEditingAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
        icon = (UIImageView*) [cell viewWithTag:1];
        title = (UILabel*) [cell viewWithTag:3];
        line = (UIImageView*) [cell viewWithTag:4];
        UIView *backView = [[UIView alloc] initWithFrame:cell.frame];
        [backView setBackgroundColor:[UIColor colorWithRed:.086 green:.086 blue:.086 alpha:1]];
        cell.selectedBackgroundView = backView;
        UIImageView *xbmc_logo = [[UIImageView alloc] initWithFrame:CGRectMake(125, (int)((44/2) - (36/2)) - 2, 145, 36)];
        xbmc_logo. alpha = .25f;
        [xbmc_logo setImage:[UIImage imageNamed:@"xbmc_logo.png"]];
        xbmc_logo.tag = 101;
        xbmc_logo.hidden = YES;
        [cell.contentView insertSubview:xbmc_logo atIndex:0];
        
        UIViewAutoresizing storeMask = title.autoresizingMask;
        [title setAutoresizingMask:UIViewAutoresizingNone];
        CGRect frame = title.frame;
        frame.origin.y = 6;
        frame.size.height = frame.size.height - 12;
        if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"type"] isEqualToString:@"boolean"]){
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            UISwitch *onoff = [[UISwitch alloc] initWithFrame: CGRectZero];
            [onoff setAutoresizingMask:icon.autoresizingMask];
            [onoff addTarget: self action: @selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
            [onoff setFrame:CGRectMake(0, cellHeight/2 - onoff.frame.size.height/2, onoff.frame.size.width, onoff.frame.size.height)];
            onoff.hidden = NO;
            onoff.tag = 1000 + indexPath.row;

            UIView *onoffview = [[UIView alloc] initWithFrame: CGRectMake(0, 0, onoff.frame.size.width, 50)];
            [onoffview addSubview:onoff];

            UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            [indicator setHidesWhenStopped:YES];
            [indicator setCenter:onoff.center];
            [onoffview addSubview:indicator];

            frame.size.width = cell.frame.size.width - frame.origin.x - 16.0f;
            icon.hidden = YES;
            if ([[[[[tableData objectAtIndex:indexPath.row] objectForKey:@"action"] objectForKey:@"params"] objectForKey:@"value"] isKindOfClass:[NSNumber class]]){
                [onoff setOn:[[[[[tableData objectAtIndex:indexPath.row] objectForKey:@"action"] objectForKey:@"params"] objectForKey:@"value"] boolValue]];
            }
            else{
                onoff.hidden = YES;
                [indicator startAnimating];
                NSString *command = @"Settings.GetSettingValue";
                NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:[[[[tableData objectAtIndex:indexPath.row] objectForKey:@"action"] objectForKey:@"params"] objectForKey:@"setting" ], @"setting", nil];
                [self getXBMCValue:command params:parameters uiControl:onoff storeSetting:[[[tableData objectAtIndex:indexPath.row] objectForKey:@"action"] objectForKey:@"params"] indicator:indicator];
            }
            [cell setAccessoryView:onoffview];
        }
        else {
            frame.size.width = 202.0f;
        }
        [title setFrame:frame];
        [title setAutoresizingMask:storeMask];
        [title setFont:[UIFont fontWithName:@"Roboto-Regular" size:20]];
        [title setNumberOfLines:2];
        [title setText:[[tableData objectAtIndex:indexPath.row] objectForKey:@"label"]];
        icon.alpha = .6f;
        iconName = [[tableData objectAtIndex:indexPath.row] objectForKey:@"icon"];
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
    if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"type"] isEqualToString:@"xbmc-exec-addon"]){
        [icon setImageWithURL:[NSURL URLWithString:[[tableData objectAtIndex:indexPath.row] objectForKey:@"icon"]] placeholderImage:[UIImage imageNamed:@""] andResize:CGSizeMake(icon.frame.size.width, icon.frame.size.height)];
        icon.alpha = 1.0f;
    }
    else{
        [icon setImage:[UIImage imageNamed:iconName]];
    }
    return cell;
}

-(UIView *)createTableFooterView:(CGFloat)footerHeight {
    CGRect frame = self.view.bounds;
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFixedSpace
                                                                                target: nil
                                                                                action: nil];
    [fixedSpace setWidth:50.0f];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, footerHeight)];
    [toolbar setAutoresizingMask: UIViewAutoresizingFlexibleWidth];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        frame.size.width = STACKSCROLL_WIDTH;
        [fixedSpace setWidth:0.0f];
        [toolbar setFrame:CGRectMake(0, 0, frame.size.width, footerHeight)];
        [toolbar setAutoresizingMask: UIViewAutoresizingNone];
    }
    UIView *newView = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height - footerHeight, frame.size.width, footerHeight)];
    [newView setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth];
    [newView setBackgroundColor:[UIColor clearColor]];
    [toolbar setBarStyle:UIBarStyleBlackTranslucent];
    [toolbar setTintColor:[UIColor lightGrayColor]];

    UIBarButtonItem *fixedSpace2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFixedSpace
                                                                                target: nil
                                                                                action: nil];
    [fixedSpace2 setWidth:2.0f];

    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                                                                   target: nil
                                                                                   action: nil];
    addButton = [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"...more", nil)
                                                                   style: UIBarButtonItemStylePlain
                                                                  target: self
                                                                 action: @selector(addButtonToList:)];
    
    addButton.enabled = NO;
    editTableButton = [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Edit", nil)
                                                                   style: UIBarButtonItemStylePlain
                                                                  target: self
                                                                  action: @selector(editTable:)];
    [toolbar setItems:[NSArray arrayWithObjects:fixedSpace, addButton, flexibleSpace, editTableButton, fixedSpace2, nil]];
    
    [newView insertSubview:toolbar atIndex:0];
    
    return newView;
}

#pragma mark - Table actions

-(void)addButtonToList:(id)sender {
    if ([AppDelegate instance].serverVersion < 13){
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"XBMC \"Gotham\" version 13 or superior is required to access XBMC settings", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
    }
    else{
        DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
        detailViewController.detailItem = [AppDelegate instance].xbmcSettings;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
            CustomNavigationController *navController = [[CustomNavigationController alloc] initWithRootViewController:detailViewController];
            UINavigationBar *newBar = navController.navigationBar;
            [newBar setTintColor:IOS6_BAR_TINT_COLOR];
            [newBar setBarStyle:UIBarStyleBlack];
            [newBar setTintColor:TINT_COLOR];
            [self presentViewController:navController animated:YES completion:NULL];
        }
        else {
            [detailViewController.view setFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height)];
            [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:detailViewController invokeByController:self isStackStartView:FALSE];
        }
    }
}

-(void)deleteCustomButton:(NSUInteger)idx {
    customButton *arrayButtons = [[customButton alloc] init];
    [arrayButtons.buttons removeObjectAtIndex:idx];
    [arrayButtons saveData];
    if ([arrayButtons.buttons count] == 0){
        [menuTableView setEditing:NO animated:YES];
        [editTableButton setTitle:NSLocalizedString(@"Edit", nil)];
        [editTableButton setStyle:UIBarButtonItemStylePlain];
        [editTableButton setEnabled:NO];
        [arrayButtons.buttons addObject:infoCustomButton];
        [self setRightMenuOption:@"online" reloadTableData:YES];
    }
}

#pragma mark UISwitch

- (void)toggleSwitch:(id)sender {
    UISwitch *onoff = (UISwitch *)sender;
    NSInteger tableIdx = onoff.tag - 1000;
    if (tableIdx < [tableData count]){
        NSString *command = [[[tableData objectAtIndex:tableIdx] objectForKey:@"action"] objectForKey:@"command"];
        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:[[[[tableData objectAtIndex:tableIdx] objectForKey:@"action"] objectForKey:@"params"] objectForKey:@"setting" ], @"setting", [NSNumber numberWithBool:onoff.on], @"value", nil];
        if ([[[[tableData objectAtIndex:tableIdx] objectForKey:@"action"] objectForKey:@"params"] respondsToSelector:@selector(setObject:forKey:)]){
            [[[[tableData objectAtIndex:tableIdx] objectForKey:@"action"] objectForKey:@"params"] setObject:[NSNumber numberWithBool:onoff.on] forKey:@"value"];
        }
        [self xbmcAction:command params:parameters uiControl:onoff];
    }
}

#pragma mark -
#pragma mark Table view delegate

-(void)editTable:(id)sender {
    UIBarButtonItem *editButton = (UIBarButtonItem *)sender;
    if (menuTableView.editing == YES){
        [menuTableView setEditing:NO animated:YES];
        [editButton setTitle:NSLocalizedString(@"Edit", nil)];
        [editButton setStyle:UIBarButtonItemStylePlain];
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
    UISwitch *onoffSource = (UISwitch*)[[[tableView cellForRowAtIndexPath:sourceIndexPath]accessoryView] viewWithTag:1000 + sourceIndexPath.row];
    UISwitch *onoffDestination = (UISwitch*)[[[tableView cellForRowAtIndexPath:destinationIndexPath]accessoryView] viewWithTag:1000 + destinationIndexPath.row];
    onoffSource.tag = 1000 + destinationIndexPath.row;
    onoffDestination.tag = 1000 + sourceIndexPath.row;

    id objectMove = [tableData objectAtIndex:sourceIndexPath.row];
    [tableData removeObjectAtIndex:sourceIndexPath.row];
    [tableData insertObject:objectMove atIndex:destinationIndexPath.row];
    
    customButton *arrayButtons = [[customButton alloc] init];
    objectMove = [arrayButtons.buttons objectAtIndex:(sourceIndexPath.row - editableRowStartAt)];
    [arrayButtons.buttons removeObjectAtIndex:(sourceIndexPath.row - editableRowStartAt)];
    [arrayButtons.buttons insertObject:objectMove atIndex:(destinationIndexPath.row - editableRowStartAt)];
    [arrayButtons saveData];
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
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Custom button", nil)
                                                        message: NSLocalizedString(@"Modify label:", nil)
                                                       delegate: self
                                              cancelButtonTitle: NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles: NSLocalizedString(@"Update label", nil), nil];
    [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    NSString *title=[NSString stringWithFormat:@"%@", [[tableData objectAtIndex:indexPath.row] objectForKey:@"label"]];
    alertView.tag = indexPath.row;
    [[alertView textFieldAtIndex:0] setText:title];
    [alertView show];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([[[tableData objectAtIndex:indexPath.row] objectForKey:@"type"] isEqualToString:@"boolean"]){
        return;
    }
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
                    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"No server MAC address defined", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                    [alertView show];
                }
            }
            else if ([command isEqualToString:@"AddButton"]){
                [self addButtonToList:nil];
            }
            else if (command != nil){
                NSDictionary *parameters = [[[tableData objectAtIndex:indexPath.row] objectForKey:@"action"] objectForKey:@"params"];
                if (parameters == nil) {
                    parameters = [NSDictionary dictionary];
                }
                [self xbmcAction:command params:parameters uiControl:nil];
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

-(void)xbmcAction:(NSString *)action params:(NSDictionary *)params uiControl:(id)sender {
    if ([sender respondsToSelector:@selector(setUserInteractionEnabled:)]){
        [sender setUserInteractionEnabled:NO];
    }
    jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    [jsonRPC callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (methodError==nil && error == nil){
            [messagesView showMessage:NSLocalizedString(@"Command executed", nil) timeout:2.0f color:[UIColor colorWithRed:39.0f/255.0f green:158.0f/255.0f blue:34.0f/255.0f alpha:0.95f]];
        }
        else{
            [messagesView showMessage:NSLocalizedString(@"Cannot do that", nil) timeout:2.0f color:[UIColor colorWithRed:189.0f/255.0f green:36.0f/255.0f blue:36.0f/255.0f alpha:0.95f]];
        }
        if ([sender respondsToSelector:@selector(setUserInteractionEnabled:)]){
            [sender setUserInteractionEnabled:YES];
        }
    }];
}

-(void)getXBMCValue:(NSString *)action params:(NSDictionary *)params uiControl:(id)sender storeSetting:(NSMutableDictionary *)setting indicator:(UIActivityIndicatorView *)busyView {
    if ([sender respondsToSelector:@selector(setUserInteractionEnabled:)]){
        [sender setUserInteractionEnabled:NO];
    }
    jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    [jsonRPC callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (methodError==nil && error == nil){
            [busyView stopAnimating];
            if ([sender respondsToSelector:@selector(setHidden:)]){
                [sender setHidden:NO];
            }
            if ([sender respondsToSelector:@selector(setOn:)]){
                [sender setOn:[[methodResult objectForKey:@"value"] boolValue]];
                if ([setting respondsToSelector:@selector(setObject:forKey:)]){
                    [setting setObject:[NSNumber numberWithBool:[[methodResult objectForKey:@"value"] boolValue]] forKey:@"value"];
                }
            }
        }
        if ([sender respondsToSelector:@selector(setUserInteractionEnabled:)]){
            [sender setUserInteractionEnabled:YES];
        }
    }];
}

-(void)wakeUp:(NSString *)macAddress{
    [[AppDelegate instance] sendWOL:macAddress withPort:9];
}

# pragma mark - UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex!=alertView.cancelButtonIndex){
        NSString *option = [alertView buttonTitleAtIndex:buttonIndex];
        if ([option isEqualToString:NSLocalizedString(@"Update label", nil)]){
            
            [[tableData objectAtIndex:alertView.tag] setObject:[[alertView textFieldAtIndex:0]text] forKey:@"label"];
            
            UITableViewCell *cell = [menuTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:alertView.tag inSection:0]];
            UILabel *title = (UILabel*) [cell viewWithTag:3];
            [title setText:[[alertView textFieldAtIndex:0]text]];
            
            customButton *arrayButtons = [[customButton alloc] init];
            if ([[arrayButtons.buttons objectAtIndex:alertView.tag -  editableRowStartAt] respondsToSelector:@selector(setObject:forKey:)]){
                [[arrayButtons.buttons objectAtIndex:alertView.tag -  editableRowStartAt] setObject:[[alertView textFieldAtIndex:0]text] forKey:@"label"];
                [arrayButtons saveData];
            }
        }
        else {
            NSString *userChoice = [alertView buttonTitleAtIndex:buttonIndex];
            NSIndexPath *commandIdx = [self getIndexPathForKey:@"ok_button" withValue:userChoice inArray:[tableData valueForKey:@"action"]];
            NSString *command = [[[tableData valueForKey:@"action"] objectAtIndex:commandIdx.row] objectForKey:@"command"];
            if (command != nil){
                [self xbmcAction:command params:[NSDictionary dictionary] uiControl:nil];
            }
        }
    }
}

-(void)updateUIAlertViewCountdown:(NSString *)countdown_message{
    [actionAlertView setMessage:countdown_message];
}

#pragma mark - LifeCycle

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [volumeSliderView stopTimer];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    int deltaY = 22.0f;
    self.peekLeftAmount = 40.0f;
    CGRect frame = [[UIScreen mainScreen ] bounds];
    CGFloat deltaX = 40.0f;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        frame.size.width = STACKSCROLL_WIDTH;
        deltaX = 0.0f;
        deltaY = 0.0f;
        self.peekLeftAmount = 0.0f;
    }
    torchIsOn = NO;
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            torchIsOn = [device torchLevel];
        }
    }
    [self.slidingViewController setAnchorLeftPeekAmount:self.peekLeftAmount];
    self.slidingViewController.underRightWidthLayout = ECFullWidth;
    int infoLabelHeight = 100;
    infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, self.view.frame.size.height/2 - infoLabelHeight/2, self.view.frame.size.width - (60), infoLabelHeight)];
    infoLabel.numberOfLines = 2;
    [infoLabel setText:NSLocalizedString(@"Select an XBMC Server from the list", nil)];
    [infoLabel setBackgroundColor:[UIColor clearColor]];
    [infoLabel setFont:[UIFont fontWithName:@"Roboto-Regular" size:20]];
    [infoLabel setTextAlignment:NSTextAlignmentCenter];
    [infoLabel setTextColor:[UIColor colorWithRed:.49f green:.49f blue:.49f alpha:1]];
    infoLabel.alpha = 0;
    [self.view addSubview:infoLabel];
    
    infoCustomButton = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        NSLocalizedString(@"No custom button defined.\r\nPress \"...more\" below to add new ones.", nil), @"label",
                        [[NSMutableDictionary alloc] initWithCapacity:0], @"bgColor",
                        [NSNumber numberWithBool:NO], @"hideLineSeparator",
                        [[NSMutableDictionary alloc] initWithCapacity:0], @"fontColor",
                        @"default-right-menu-icon", @"icon",
                        [[NSMutableDictionary alloc] initWithCapacity:0], @"action",
                        [NSNumber numberWithBool:NO], @"revealViewTop",
                        [NSNumber numberWithBool:NO], @"isSetting",
                        @"", @"type",
                        nil];
    
    mainMenu *menuItems = [self.rightMenuItems objectAtIndex:0];
    CGFloat footerHeight = 0.0f;
    if (menuItems.family == 3) {
        footerHeight = 44.0f;
        [self.view addSubview:[self createTableFooterView: footerHeight]];
    }
    if (menuItems.family == 2 || menuItems.family == 3) {
        volumeSliderView = [[VolumeSliderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 0, 0)];
        [volumeSliderView startTimer];
    }
    menuTableView = [[UITableView alloc] initWithFrame:CGRectMake(self.peekLeftAmount, deltaY, frame.size.width - self.peekLeftAmount, self.view.frame.size.height - deltaY - footerHeight - 1) style:UITableViewStylePlain];
    [menuTableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [menuTableView setSeparatorColor:[UIColor colorWithRed:0.114f green:0.114f blue:0.114f alpha:1]];
    [menuTableView setDelegate:self];
    [menuTableView setDataSource:self];
    [menuTableView setBackgroundColor:[UIColor clearColor]];
    [menuTableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [menuTableView setScrollEnabled:[[self.rightMenuItems objectAtIndex:0] enableSection]];
    [menuTableView setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    menuTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:menuTableView];

    if ([[AppDelegate instance].obj.serverIP length]!=0){
        if (![AppDelegate instance].serverOnLine){
            [self setRightMenuOption:@"offline" reloadTableData:NO];
            addButton.enabled = NO;
        }
        else{
            [self setRightMenuOption:@"online" reloadTableData:NO];
            addButton.enabled = YES;
        }
    }
    else {
        infoLabel.alpha = 1;
        putXBMClogo = YES;
        [self setRightMenuOption:@"utility" reloadTableData:NO];
    }
    messagesView = [[MessagesView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 44.0f + deltaY) deltaY:deltaY deltaX:deltaX];
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
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadCustomButtonTable:)
                                                 name: @"UIInterfaceCustomButtonAdded"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(showNotificationMessage:)
                                                 name: @"AudioLibrary.OnScanFinished"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(showNotificationMessage:)
                                                 name: @"AudioLibrary.OnCleanFinished"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(showNotificationMessage:)
                                                 name: @"VideoLibrary.OnScanFinished"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(showNotificationMessage:)
                                                 name: @"VideoLibrary.OnCleanFinished"
                                               object: nil];
}

-(void)showNotificationMessage:(NSNotification *)note {
    [messagesView showMessage:note.name timeout:2.0f color:[UIColor colorWithRed:39.0f/255.0f green:158.0f/255.0f blue:34.0f/255.0f alpha:0.95f]];
}

-(void)reloadCustomButtonTable:(NSNotification *)note {
    [self setRightMenuOption:@"online" reloadTableData:YES];
}

-(void)startTimer:(id)sender{
    [volumeSliderView startTimer];
}

-(void)stopTimer:(id)sender{
    [volumeSliderView stopTimer];
}

- (void)setRightMenuOption:(NSString *)key reloadTableData:(BOOL)reload {
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
                              @"embedded", @"type",
                            nil]];
    }
    editableRowStartAt = [tableData count];
    if ([key isEqualToString:@"online"] && menuItems.family == 3){
        customButton *arrayButtons = [[customButton alloc] init];
        if ([arrayButtons.buttons count] == 0){
            [editTableButton setEnabled:NO];
            [arrayButtons.buttons addObject:infoCustomButton];
        }
        else{
            [editTableButton setEnabled:YES];
        }
        for (NSDictionary *item in arrayButtons.buttons) {
            NSString *label = [item objectForKey:@"label"];
            if (label == nil) label = @"";
            NSString *icon = [item objectForKey:@"icon"];
            if (icon == nil) icon = @"";
            NSString *type = [item objectForKey:@"type"];
            if (type == nil) type = @"";
            NSNumber *isSetting = [item objectForKey:@"isSetting"];
            if (isSetting == nil) isSetting = [NSNumber numberWithBool:YES];
            [tableData addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  label, @"label",
                                  [[NSMutableDictionary alloc] initWithCapacity:0], @"bgColor",
                                  [NSNumber numberWithBool:NO], @"hideLineSeparator",
                                  [[NSMutableDictionary alloc] initWithCapacity:0], @"fontColor",
                                  icon, @"icon",
                                  isSetting, @"isSetting",
                                  [NSNumber numberWithBool:NO], @"revealViewTop",
                                  type, @"type",
                                  [item objectForKey:@"action"], @"action",
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
                         if (reload){
                             [menuTableView reloadData];
                         }
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
        NSString *serverTxt = [theData objectForKey:@"message"];
        NSString *icon_connection = [theData objectForKey:@"icon_connection"];
        NSIndexPath *serverRow = [self getIndexPathForKey:@"label" withValue:@"ServerInfo" inArray:tableData];
        if (serverRow != nil) {
            UITableViewCell *cell = [menuTableView cellForRowAtIndexPath:serverRow];
            if (serverTxt != nil && ![serverTxt isEqualToString:@""]) {
                UILabel *title = (UILabel*) [cell viewWithTag:3];
                [title setText:serverTxt];
            }
            if (icon_connection != nil && ![icon_connection isEqualToString:@""]){
                UIImageView *icon = (UIImageView*) [cell viewWithTag:1];
                [icon setImage:[UIImage imageNamed:icon_connection]];
            }
        }
    }
    [self setRightMenuOption:@"online" reloadTableData:YES];
    infoLabel.alpha = 0;
    addButton.enabled = YES;
}

- (void)connectionFailed:(NSNotification *)note {
    NSDictionary *theData = [note userInfo];
    if (theData != nil) {
        NSString *serverTxt = [theData objectForKey:@"message"];
        NSString *icon_connection = [theData objectForKey:@"icon_connection"];
        NSIndexPath *serverRow = [self getIndexPathForKey:@"label" withValue:@"ServerInfo" inArray:tableData];
        if (serverRow != nil) {
            UITableViewCell *cell = [menuTableView cellForRowAtIndexPath:serverRow];
            if (serverTxt != nil && ![serverTxt isEqualToString:@""]) {
                UILabel *title = (UILabel*) [cell viewWithTag:3];
                [title setText:serverTxt];
            }
            if (icon_connection != nil && ![icon_connection isEqualToString:@""]){
                UIImageView *icon = (UIImageView*) [cell viewWithTag:1];
                [icon setImage:[UIImage imageNamed:icon_connection]];
            }
        }
    }
    if ([[AppDelegate instance].obj.serverIP length]!=0) {
        infoLabel.alpha = 0;
        [self setRightMenuOption:@"offline" reloadTableData:YES];
        addButton.enabled = NO;
    }
    else {
        [tableData removeAllObjects];
        [menuTableView reloadData];
        infoLabel.alpha = 1;
        putXBMClogo = YES;
        [self setRightMenuOption:@"utility" reloadTableData:YES];
    }
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
