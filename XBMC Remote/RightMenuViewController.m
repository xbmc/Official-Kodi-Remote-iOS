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
#import "CustomNavigationController.h"
#import "customButton.h"
#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"
#import "Utilities.h"

#define TOOLBAR_HEIGHT 44.0
#define SERVER_INFO_HEIGHT 44.0
#define RIGHT_MENU_ITEM_HEIGHT 50.0
#define RIGHT_MENU_ICON_SIZE 18.0
#define RIGHT_MENU_ICON_SPACING 16.0
#define BUTTON_SPACING 8.0
#define BUTTON_WIDTH 100.0

@interface RightMenuViewController ()
@property (nonatomic, unsafe_unretained) CGFloat peekLeftAmount;
@end

@implementation RightMenuViewController
@synthesize peekLeftAmount;
@synthesize rightMenuItems;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

#pragma mark -
#pragma mark Table view data source

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    NSString *rowContent = tableData[indexPath.row][@"label"];
    if ([rowContent isEqualToString:@"ServerInfo"]) {
        return SERVER_INFO_HEIGHT;
    }
    else if ([rowContent isEqualToString:@"RemoteControl"]) {
        return UIScreen.mainScreen.bounds.size.height - [self getRemoteViewOffsetY];
    }
    else if ([rowContent isEqualToString:@"VolumeControl"]) {
        return volumeSliderView.frame.size.height;
    }
    return RIGHT_MENU_ITEM_HEIGHT;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return tableData.count;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    NSDictionary *rgbColor = tableData[indexPath.row][@"bgColor"];
    if (rgbColor.count) {
        cell.backgroundColor = [UIColor colorWithRed:[rgbColor[@"red"] floatValue]
                                               green:[rgbColor[@"green"] floatValue]
                                                blue:[rgbColor[@"blue"] floatValue]
                                               alpha:1];
    }
    else { // xcode xib bug with ipad?
        cell.backgroundColor = [Utilities getGrayColor:36 alpha:1];
    }
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rightMenuCell"];
    [[NSBundle mainBundle] loadNibNamed:@"rightCellView" owner:self options:NULL];
    if (cell == nil) {
        cell = rightMenuCell;
        UIView *backView = [[UIView alloc] initWithFrame:cell.frame];
        backView.backgroundColor = [Utilities getGrayColor:22 alpha:1];
        cell.selectedBackgroundView = backView;
        UIImage *logo = [UIImage imageNamed:@"xbmc_logo"];
        UIImageView *xbmc_logo = [[UIImageView alloc] initWithFrame:[Utilities createXBMCInfoframe:logo height:44 width:self.view.bounds.size.width]];
        xbmc_logo.alpha = 0.25;
        xbmc_logo.image = logo;
        xbmc_logo.tag = 101;
        [cell.contentView insertSubview:xbmc_logo atIndex:0];
    }
    UIImageView *icon = (UIImageView*)[cell viewWithTag:1];
    UILabel *title = (UILabel*)[cell viewWithTag:3];
    UIImageView *line = (UIImageView*)[cell viewWithTag:4];
    UIImageView *xbmc_logo = (UIImageView*)[cell viewWithTag:101];
    icon.hidden = NO;
    xbmc_logo.hidden = YES;
    cell.accessoryView = nil;
    NSString *iconName = @"blank";
    if ([tableData[indexPath.row][@"label"] isEqualToString:@"ServerInfo"]) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        xbmc_logo.hidden = NO;
        iconName = [Utilities getConnectionStatusIconName];
        icon.alpha = 1;
        title.font = [UIFont fontWithName:@"Roboto-Regular" size:13];
        title.autoresizingMask = UIViewAutoresizingNone;
        icon.autoresizingMask = UIViewAutoresizingNone;
        icon.frame = CGRectMake(10, (SERVER_INFO_HEIGHT - RIGHT_MENU_ICON_SIZE) / 2, RIGHT_MENU_ICON_SIZE, RIGHT_MENU_ICON_SIZE);
        title.frame = CGRectMake(icon.frame.size.width + RIGHT_MENU_ICON_SPACING, (SERVER_INFO_HEIGHT - title.frame.size.height) / 2, tableView.frame.size.width - (icon.frame.size.width + 2 * RIGHT_MENU_ICON_SPACING), title.frame.size.height);
        title.textAlignment = NSTextAlignmentLeft;
        title.text = AppDelegate.instance.serverName;
        title.numberOfLines = 2;
        UIImageView *arrowRight = (UIImageView*)[cell viewWithTag:5];
        arrowRight.frame = CGRectMake(arrowRight.frame.origin.x, (SERVER_INFO_HEIGHT - arrowRight.frame.size.height) / 2, arrowRight.frame.size.width, arrowRight.frame.size.height);
    }
    else if ([tableData[indexPath.row][@"label"] isEqualToString:@"VolumeControl"]) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        title.text = @"";
        if (volumeSliderView == nil) {
            volumeSliderView = [[VolumeSliderView alloc] initWithFrame:CGRectZero leftAnchor:ANCHOR_RIGHT_PEEK isSliderType:YES];
            [volumeSliderView startTimer];
        }
        [cell.contentView addSubview:volumeSliderView];
    }
    else if ([tableData[indexPath.row][@"label"] isEqualToString:@"RemoteControl"]) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        title.text = @"";
        if (remoteControllerView == nil) {
            remoteControllerView = [[RemoteController alloc] initWithNibName:@"RemoteController" withEmbedded:YES bundle:nil];
            remoteControllerView.panFallbackImageView.frame = cell.frame;
        }
        [cell.contentView addSubview:remoteControllerView.view];
    }
    else {
        cell = rightMenuCell;
        cell.accessoryView = nil;
        cell.backgroundColor = [Utilities getGrayColor:36 alpha:1];
        cell.tintColor = UIColor.lightGrayColor;
        cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        icon = (UIImageView*)[cell viewWithTag:1];
        title = (UILabel*)[cell viewWithTag:3];
        line = (UIImageView*)[cell viewWithTag:4];
        UIView *backView = [[UIView alloc] initWithFrame:cell.frame];
        backView.backgroundColor = [Utilities getGrayColor:22 alpha:1];
        cell.selectedBackgroundView = backView;
        UIImage *logo = [UIImage imageNamed:@"xbmc_logo"];
        UIImageView *xbmc_logo = [[UIImageView alloc] initWithFrame:[Utilities createXBMCInfoframe:logo height:44 width:self.view.bounds.size.width]];
        xbmc_logo.alpha = 0.25;
        xbmc_logo.image = logo;
        xbmc_logo.tag = 101;
        xbmc_logo.hidden = YES;
        [cell.contentView insertSubview:xbmc_logo atIndex:0];
        
        UIViewAutoresizing storeMask = title.autoresizingMask;
        title.autoresizingMask = UIViewAutoresizingNone;
        CGRect frame = title.frame;
        frame.origin.y = 6;
        frame.size.height = frame.size.height - 12;
        if ([tableData[indexPath.row][@"type"] isEqualToString:@"boolean"]) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UISwitch *onoff = [[UISwitch alloc] initWithFrame: CGRectZero];
            onoff.autoresizingMask = icon.autoresizingMask;
            [onoff addTarget: self action: @selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
            onoff.frame = CGRectMake(0, (RIGHT_MENU_ITEM_HEIGHT - onoff.frame.size.height) / 2, onoff.frame.size.width, onoff.frame.size.height);
            onoff.hidden = NO;
            onoff.tag = 1000 + indexPath.row;

            UIView *onoffview = [[UIView alloc] initWithFrame: CGRectMake(0, 0, onoff.frame.size.width, RIGHT_MENU_ITEM_HEIGHT)];
            [onoffview addSubview:onoff];

            UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            indicator.hidesWhenStopped = YES;
            indicator.center = onoff.center;
            [onoffview addSubview:indicator];

            frame.size.width = cell.frame.size.width - frame.origin.x - RIGHT_MENU_ICON_SPACING;
            icon.hidden = YES;
            if ([tableData[indexPath.row][@"action"][@"params"][@"value"] isKindOfClass:[NSNumber class]]) {
                [onoff setOn:[tableData[indexPath.row][@"action"][@"params"][@"value"] boolValue]];
            }
            else {
                onoff.hidden = YES;
                [indicator startAnimating];
                NSString *command = @"Settings.GetSettingValue";
                NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys: tableData[indexPath.row][@"action"][@"params"][@"setting"], @"setting", nil];
                [self getXBMCValue:command params:parameters uiControl:onoff storeSetting: tableData[indexPath.row][@"action"][@"params"] indicator:indicator];
            }
            cell.accessoryView = onoffview;
        }
        else {
            frame.size.width = 202;
        }
        title.frame = frame;
        title.autoresizingMask = storeMask;
        title.font = [UIFont fontWithName:@"Roboto-Regular" size:20];
        title.numberOfLines = 2;
        title.text = tableData[indexPath.row][@"label"];
        icon.alpha = 0.6;
        iconName = tableData[indexPath.row][@"icon"];
    }
    if ([tableData[indexPath.row][@"hideLineSeparator"] boolValue]) {
        line.hidden = YES;
    }
    if ([tableData[indexPath.row][@"fontColor"] count]) {
        UIColor *fontColor = [UIColor colorWithRed:[tableData[indexPath.row][@"fontColor"][@"red"] floatValue]
                                             green:[tableData[indexPath.row][@"fontColor"][@"green"] floatValue]
                                              blue:[tableData[indexPath.row][@"fontColor"][@"blue"] floatValue]
                                             alpha:1];
        title.textColor = fontColor;
        title.highlightedTextColor = fontColor;
    }
    else {
        UIColor *fontColor = [Utilities getGrayColor:125 alpha:1];
        title.textColor = fontColor;
        title.highlightedTextColor = fontColor;
    }
    if ([tableData[indexPath.row][@"label"] isEqualToString:LOCALIZED_STR(@"LED Torch")]) {
        icon.alpha = 0.8;
        if (torchIsOn) {
            iconName = @"torch_on";
        }
    }
    if ([tableData[indexPath.row][@"type"] isEqualToString:@"xbmc-exec-addon"]) {
        [icon setImageWithURL:[NSURL URLWithString:tableData[indexPath.row][@"icon"]]
             placeholderImage:[UIImage imageNamed:@"blank"]
                    andResize:CGSizeMake(icon.frame.size.width, icon.frame.size.height)];
        icon.alpha = 1.0;
    }
    else {
        icon.image = [UIImage imageNamed:iconName];
    }
    return cell;
}

- (UIView*)createTableFooterView:(CGFloat)footerHeight {
    CGRect frame = self.view.bounds;
    UIView *newView = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height - footerHeight, frame.size.width, footerHeight)];
    newView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    newView.backgroundColor = [Utilities getGrayColor:36 alpha:1];
    
    // ...more button
    CGFloat originX = self.peekLeftAmount + BUTTON_SPACING;
    moreButton = [[UIButton alloc] initWithFrame:CGRectMake(originX, 0, BUTTON_WIDTH, TOOLBAR_HEIGHT)];
    moreButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    moreButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [moreButton setTitleColor:UIColor.darkGrayColor forState:UIControlStateDisabled];
    [moreButton setTitleColor:UIColor.lightGrayColor forState:UIControlStateNormal];
    [moreButton setTitle:LOCALIZED_STR(@"...more") forState:UIControlStateNormal];
    [moreButton addTarget:self action:@selector(addButtonToList:) forControlEvents:UIControlEventTouchUpInside];
    [newView addSubview:moreButton];
    
    // edit button
    originX = newView.frame.size.width - BUTTON_WIDTH - BUTTON_SPACING;
    editTableButton = [[UIButton alloc] initWithFrame:CGRectMake(originX, 0, BUTTON_WIDTH, TOOLBAR_HEIGHT)];
    editTableButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    editTableButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [editTableButton setTitleColor:UIColor.darkGrayColor forState:UIControlStateDisabled];
    [editTableButton setTitleColor:UIColor.lightGrayColor forState:UIControlStateNormal];
    [editTableButton setTitle:LOCALIZED_STR(@"Edit") forState:UIControlStateNormal];
    [editTableButton addTarget:self action:@selector(editTable:) forControlEvents:UIControlEventTouchUpInside];
    [newView addSubview:editTableButton];
    
    return newView;
}

#pragma mark - Helper

- (CGFloat)getRemoteViewOffsetY {
    // Layout is (top-down): status bar > server info > volume slider > (menu items) > remote view
    CGFloat statusBarHeight = UIApplication.sharedApplication.statusBarFrame.size.height;
    CGFloat sliderHeight = volumeSliderView.frame.size.height;
    CGFloat menuItemsHeight = [Utilities hasRemoteToolBar] ? 0 : 3 * RIGHT_MENU_ITEM_HEIGHT;
    return statusBarHeight + SERVER_INFO_HEIGHT + sliderHeight + menuItemsHeight;
}

#pragma mark - Table actions

- (void)addButtonToList:(id)sender {
    if (AppDelegate.instance.serverVersion < 13) {
        UIAlertController *alertView = [Utilities createAlertOK:@"" message:LOCALIZED_STR(@"XBMC \"Gotham\" version 13 or superior is required to access XBMC settings")];
        [self presentViewController:alertView animated:YES completion:nil];
    }
    else {
        DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
        detailViewController.detailItem = AppDelegate.instance.xbmcSettings;
        if (IS_IPHONE) {
            CustomNavigationController *navController = [[CustomNavigationController alloc] initWithRootViewController:detailViewController];
            UINavigationBar *newBar = navController.navigationBar;
            newBar.barStyle = UIBarStyleBlack;
            newBar.tintColor = TINT_COLOR;
            navController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:navController animated:YES completion:NULL];
        }
        else {
            detailViewController.view.frame = CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height);
            [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:detailViewController invokeByController:self isStackStartView:NO];
        }
    }
}

- (void)deleteCustomButton:(NSUInteger)idx {
    customButton *arrayButtons = [customButton new];
    [arrayButtons.buttons removeObjectAtIndex:idx];
    [arrayButtons saveData];
    if (arrayButtons.buttons.count == 0) {
        [menuTableView setEditing:NO animated:YES];
        [editTableButton setTitle:LOCALIZED_STR(@"Edit") forState:UIControlStateNormal];
        editTableButton.enabled = NO;
        [arrayButtons.buttons addObject:infoCustomButton];
        [self setRightMenuOption:@"online" reloadTableData:YES];
    }
}

#pragma mark UISwitch

- (void)toggleSwitch:(id)sender {
    UISwitch *onoff = (UISwitch*)sender;
    NSInteger tableIdx = onoff.tag - 1000;
    if (tableIdx < tableData.count) {
        NSString *command = tableData[tableIdx][@"action"][@"command"];
        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys: tableData[tableIdx][@"action"][@"params"][@"setting"], @"setting", @(onoff.on), @"value", nil];
        if ([tableData[tableIdx][@"action"][@"params"] respondsToSelector:@selector(setObject:forKey:)]) {
            tableData[tableIdx][@"action"][@"params"][@"value"] = @(onoff.on);
        }
        [self xbmcAction:command params:parameters uiControl:onoff];
    }
}

#pragma mark -
#pragma mark Table view delegate

- (void)editTable:(id)sender {
    UIButton *editButton = (UIButton*)sender;
    if (menuTableView.editing) {
        [menuTableView setEditing:NO animated:YES];
        [editButton setTitle:LOCALIZED_STR(@"Edit") forState:UIControlStateNormal];
    }
    else {
        [menuTableView setEditing:YES animated:YES];
        [editButton setTitle:LOCALIZED_STR(@"Done") forState:UIControlStateNormal];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)aTableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView*)tableview canMoveRowAtIndexPath:(NSIndexPath*)indexPath {
    return YES;
}

- (NSIndexPath*)tableView:(UITableView*)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath*)sourceIndexPath toProposedIndexPath:(NSIndexPath*)proposedDestinationIndexPath {
    if (proposedDestinationIndexPath.row < editableRowStartAt) {
        return [NSIndexPath indexPathForRow:editableRowStartAt inSection:0];
    }
    else {
        return proposedDestinationIndexPath;
    }
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
    UISwitch *onoffSource = (UISwitch*)[[[tableView cellForRowAtIndexPath:sourceIndexPath]accessoryView] viewWithTag:1000 + sourceIndexPath.row];
    UISwitch *onoffDestination = (UISwitch*)[[[tableView cellForRowAtIndexPath:destinationIndexPath]accessoryView] viewWithTag:1000 + destinationIndexPath.row];
    onoffSource.tag = 1000 + destinationIndexPath.row;
    onoffDestination.tag = 1000 + sourceIndexPath.row;

    id objectMove = tableData[sourceIndexPath.row];
    [tableData removeObjectAtIndex:sourceIndexPath.row];
    [tableData insertObject:objectMove atIndex:destinationIndexPath.row];
    
    customButton *arrayButtons = [customButton new];
    objectMove = arrayButtons.buttons[(sourceIndexPath.row - editableRowStartAt)];
    [arrayButtons.buttons removeObjectAtIndex:(sourceIndexPath.row - editableRowStartAt)];
    [arrayButtons.buttons insertObject:objectMove atIndex:(destinationIndexPath.row - editableRowStartAt)];
    [arrayButtons saveData];
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.row < tableData.count) {
        return [tableData[indexPath.row][@"isSetting"] boolValue];
    }
    else {
        return NO;
    }
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (indexPath.row < tableData.count) {
            [tableData removeObjectAtIndex:indexPath.row];
        }
        if (indexPath.row < [tableView numberOfRowsInSection:indexPath.section]) {
            [tableView beginUpdates];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
            [tableView endUpdates];
        }
        [self deleteCustomButton:(indexPath.row - editableRowStartAt)];
	}
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath {
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:LOCALIZED_STR(@"Custom button") message:LOCALIZED_STR(@"Modify label:") preferredStyle:UIAlertControllerStyleAlert];
    [alertView addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"";
        textField.text = tableData[indexPath.row][@"label"];
    }];
    UIAlertAction *updateButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Update label") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        tableData[indexPath.row][@"label"] = alertView.textFields[0].text;
            
            UITableViewCell *cell = [menuTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
            UILabel *title = (UILabel*)[cell viewWithTag:3];
            title.text = alertView.textFields[0].text;
            
            customButton *arrayButtons = [customButton new];
            if ([arrayButtons.buttons[indexPath.row - editableRowStartAt] respondsToSelector:@selector(setObject:forKey:)]) {
                arrayButtons.buttons[indexPath.row - editableRowStartAt][@"label"] = alertView.textFields[0].text;
                [arrayButtons saveData];
            }
        }];
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
    [alertView addAction:updateButton];
    [alertView addAction:cancelButton];
    [self presentViewController:alertView animated:YES completion:nil];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row >= tableData.count) {
        return;
    }
    if ([tableData[indexPath.row][@"type"] isEqualToString:@"boolean"]) {
        return;
    }
    if ([tableData[indexPath.row][@"action"] count]) {
        NSString *message = tableData[indexPath.row][@"action"][@"message"];
        if (message != nil) {
            NSString *countdown_message = tableData[indexPath.row][@"action"][@"countdown_message"];
            if (countdown_message != nil) {
                countdown_message = [NSString stringWithFormat:@"%@ %d seconds.", countdown_message, [tableData[indexPath.row][@"action"][@"countdown_time"] intValue]];
            }
            NSString *cancel_button = tableData[indexPath.row][@"action"][@"cancel_button"] ?: LOCALIZED_STR(@"Cancel");
            NSString *ok_button = tableData[indexPath.row][@"action"][@"ok_button"] ?: LOCALIZED_STR(@"Yes");
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:message message:countdown_message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:cancel_button style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
            UIAlertAction *okButton = [UIAlertAction actionWithTitle:ok_button style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSIndexPath *commandIdx = [self getIndexPathForKey:@"ok_button" withValue:ok_button inArray:[tableData valueForKey:@"action"]];
                NSString *command = [tableData valueForKey:@"action"][commandIdx.row][@"command"];
                if (command != nil) {
                    [self xbmcAction:command params:[NSDictionary dictionary] uiControl:nil];
                }
            }];
            [alertView addAction:cancelButton];
            [alertView addAction:okButton];
            [self presentViewController:alertView animated:YES completion:nil];
        }
        else {
            NSString *command = tableData[indexPath.row][@"action"][@"command"];
            if ([command isEqualToString:@"System.WOL"]) {
                NSString *serverMAC = AppDelegate.instance.obj.serverHWAddr;
                if (serverMAC != nil && ![serverMAC isEqualToString:@":::::"]) {
                    [self wakeUp:AppDelegate.instance.obj.serverHWAddr];
                    [messagesView showMessage:LOCALIZED_STR(@"Command executed") timeout:2.0 color:[Utilities getSystemGreen:0.95]];
                }
                else {
                    UIAlertController *alertView = [Utilities createAlertOK:LOCALIZED_STR(@"Warning") message:LOCALIZED_STR(@"No server MAC address defined")];
                    [self presentViewController:alertView animated:YES completion:nil];
                }
            }
            else if ([command isEqualToString:@"AddButton"]) {
                [self addButtonToList:nil];
            }
            else if (command != nil) {
                NSDictionary *parameters = tableData[indexPath.row][@"action"][@"params"] ?: @{};
                [self xbmcAction:command params:parameters uiControl:nil];
            }
        }
    }
    else if ([tableData[indexPath.row][@"label"] isEqualToString:LOCALIZED_STR(@"Keyboard")]) {
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIToggleVirtualKeyboard" object:nil userInfo:nil];
        if ([tableData[indexPath.row][@"revealViewTop"] boolValue]) {
            [self.slidingViewController resetTopView];
        }
    }
    else if ([tableData[indexPath.row][@"label"] isEqualToString:LOCALIZED_STR(@"Help Screen")]) {
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIToggleQuickHelp" object:nil userInfo:nil];
        [self.slidingViewController resetTopView];
    }
    else if ([tableData[indexPath.row][@"label"] isEqualToString:LOCALIZED_STR(@"Gesture Zone")]) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@(YES) forKey:@"forceGestureZone"];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIToggleGestureZone" object:nil userInfo:userInfo];
        [self.slidingViewController resetTopView];
    }
    else if ([tableData[indexPath.row][@"label"] isEqualToString:LOCALIZED_STR(@"Button Pad")]) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@(NO) forKey:@"forceGestureZone"];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIToggleGestureZone" object:nil userInfo:userInfo];
        [self.slidingViewController resetTopView];
    }
    else if ([tableData[indexPath.row][@"label"] isEqualToString:LOCALIZED_STR(@"Button Pad/Gesture Zone")]) {
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIToggleGestureZone" object:nil userInfo:nil];
        [self.slidingViewController resetTopView];
    }
    else if ([tableData[indexPath.row][@"label"] isEqualToString:LOCALIZED_STR(@"LED Torch")]) {
        UIImageView *torchIcon = (UIImageView*)[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:1];
        [[tableView cellForRowAtIndexPath:indexPath] viewWithTag:1];
        torchIsOn = !torchIsOn;
        [Utilities turnTorchOn:torchIcon on:torchIsOn];
    }
    else if ([tableData[indexPath.row][@"label"] isEqualToString:LOCALIZED_STR(@"Cancel")]) {
        [self.slidingViewController resetTopView];
    }
}

#pragma mark - JSON

- (void)xbmcAction:(NSString*)action params:(NSDictionary*)params uiControl:(id)sender {
    if ([sender respondsToSelector:@selector(setUserInteractionEnabled:)]) {
        [sender setUserInteractionEnabled:NO];
    }
    [[Utilities getJsonRPC] callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (methodError == nil && error == nil) {
            [messagesView showMessage:LOCALIZED_STR(@"Command executed") timeout:2.0 color:[Utilities getSystemGreen:0.95]];
        }
        else {
            [messagesView showMessage:LOCALIZED_STR(@"Cannot do that") timeout:2.0 color:[Utilities getSystemRed:0.95]];
        }
        if ([sender respondsToSelector:@selector(setUserInteractionEnabled:)]) {
            [sender setUserInteractionEnabled:YES];
        }
    }];
}

- (void)getXBMCValue:(NSString*)action params:(NSDictionary*)params uiControl:(id)sender storeSetting:(NSMutableDictionary*)setting indicator:(UIActivityIndicatorView*)busyView {
    if ([sender respondsToSelector:@selector(setUserInteractionEnabled:)]) {
        [sender setUserInteractionEnabled:NO];
    }
    [[Utilities getJsonRPC] callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (methodError == nil && error == nil) {
            [busyView stopAnimating];
            if ([sender respondsToSelector:@selector(setHidden:)]) {
                [sender setHidden:NO];
            }
            if ([sender respondsToSelector:@selector(setOn:)]) {
                [sender setOn:[methodResult[@"value"] boolValue]];
                if ([setting respondsToSelector:@selector(setObject:forKey:)]) {
                    setting[@"value"] = @([methodResult[@"value"] boolValue]);
                }
            }
        }
        if ([sender respondsToSelector:@selector(setUserInteractionEnabled:)]) {
            [sender setUserInteractionEnabled:YES];
        }
    }];
}

- (void)wakeUp:(NSString*)macAddress {
    [AppDelegate.instance sendWOL:macAddress withPort:WOL_PORT];
}

#pragma mark - LifeCycle

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [volumeSliderView stopTimer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat deltaY = UIApplication.sharedApplication.statusBarFrame.size.height;
    self.peekLeftAmount = ANCHOR_RIGHT_PEEK;
    CGRect frame = UIScreen.mainScreen.bounds;
    CGFloat deltaX = ANCHOR_RIGHT_PEEK;
    if (IS_IPAD) {
        frame.size.width = STACKSCROLL_WIDTH;
        deltaX = 0;
        deltaY = 0;
        self.peekLeftAmount = 0;
    }
    torchIsOn = [Utilities isTorchOn];
    self.slidingViewController.anchorLeftPeekAmount = self.peekLeftAmount;
    self.slidingViewController.underRightWidthLayout = ECFullWidth;
    CGFloat infoLabelHeight = 2 * RIGHT_MENU_ITEM_HEIGHT;
    infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.peekLeftAmount, (frame.size.height - infoLabelHeight) / 2, frame.size.width - self.peekLeftAmount, infoLabelHeight)];
    infoLabel.numberOfLines = 2;
    infoLabel.text = LOCALIZED_STR(@"Select an XBMC Server from the list");
    infoLabel.backgroundColor = UIColor.clearColor;
    infoLabel.font = [UIFont fontWithName:@"Roboto-Regular" size:20];
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.textColor = [Utilities getGrayColor:125 alpha:1];
    infoLabel.alpha = 0;
    [self.view addSubview:infoLabel];
    
    infoCustomButton = @{
        @"label": LOCALIZED_STR(@"No custom button defined.\r\nPress \"...more\" below to add new ones."),
        @"bgColor": @{},
        @"hideLineSeparator": @NO,
        @"fontColor": @{},
        @"icon": @"default-right-menu-icon",
        @"action": @{},
        @"revealViewTop": @NO,
        @"isSetting": @NO,
        @"type": @"",
    };
    
    mainMenu *menuItems = self.rightMenuItems[0];
    CGFloat bottomPadding = [Utilities getBottomPadding];
    CGFloat footerHeight = 0;
    if (menuItems.family == FamilyRemote) {
        footerHeight = TOOLBAR_HEIGHT + bottomPadding;
        [self.view addSubview:[self createTableFooterView: footerHeight]];
    }
    if (menuItems.family == FamilyNowPlaying || menuItems.family == FamilyRemote) {
        volumeSliderView = [[VolumeSliderView alloc] initWithFrame:CGRectZero leftAnchor:ANCHOR_RIGHT_PEEK isSliderType:YES];
        [volumeSliderView startTimer];
    }
    menuTableView = [[UITableView alloc] initWithFrame:CGRectMake(self.peekLeftAmount, deltaY, frame.size.width - self.peekLeftAmount, self.view.frame.size.height - deltaY - footerHeight - 1) style:UITableViewStylePlain];
    menuTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    menuTableView.separatorColor = [Utilities getGrayColor:29 alpha:1];
    menuTableView.delegate = self;
    menuTableView.dataSource = self;
    menuTableView.backgroundColor = UIColor.clearColor;
    menuTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [menuTableView setScrollEnabled:[self.rightMenuItems[0] enableSection]];
    menuTableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    menuTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:menuTableView];

    if (AppDelegate.instance.obj.serverIP.length != 0) {
        if (!AppDelegate.instance.serverOnLine) {
            [self setRightMenuOption:@"offline" reloadTableData:NO];
            moreButton.enabled = NO;
        }
        else {
            [self setRightMenuOption:@"online" reloadTableData:NO];
            moreButton.enabled = YES;
        }
    }
    else {
        infoLabel.alpha = 1;
        [self setRightMenuOption:@"utility" reloadTableData:NO];
    }
    messagesView = [[MessagesView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, DEFAULT_MSG_HEIGHT + deltaY) deltaY:deltaY deltaX:deltaX];
    [self.view addSubview:messagesView];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(connectionSuccess:)
                                                 name: @"XBMCServerConnectionSuccess"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(connectionFailed:)
                                                 name: @"XBMCServerConnectionFailed"
                                               object: nil];
    
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

- (void)showNotificationMessage:(NSNotification*)note {
    [messagesView showMessage:note.name timeout:2.0 color:[Utilities getSystemGreen:0.95]];
}

- (void)reloadCustomButtonTable:(NSNotification*)note {
    [self setRightMenuOption:@"online" reloadTableData:YES];
}

- (void)startTimer:(id)sender {
    [volumeSliderView startTimer];
}

- (void)stopTimer:(id)sender {
    [volumeSliderView stopTimer];
}

- (BOOL)itemShownInRemoteToolBar:(NSDictionary*)item {
    return ([item[@"label"] isEqualToString:LOCALIZED_STR(@"Keyboard")] ||
            [item[@"label"] isEqualToString:LOCALIZED_STR(@"Button Pad/Gesture Zone")] ||
            [item[@"label"] isEqualToString:LOCALIZED_STR(@"Help Screen")] ||
            [item[@"label"] isEqualToString:LOCALIZED_STR(@"VolumeControl")] ||
            [item[@"label"] isEqualToString:LOCALIZED_STR(@"LED Torch")]) &&
            [Utilities hasRemoteToolBar];
}

- (BOOL)showEmbeddedVolumeBar:(NSDictionary*)item mainLabel:(NSString*)mainLabel {
    return [item[@"label"] isEqualToString:LOCALIZED_STR(@"VolumeControl")] &&
           [mainLabel isEqualToString:@"EmbeddedRemote"] && [Utilities hasRemoteToolBar];
}

- (void)setRightMenuOption:(NSString*)key reloadTableData:(BOOL)reload {
    mainMenu *menuItem = self.rightMenuItems[0];
    tableData = [[NSMutableArray alloc] initWithCapacity:0];

    for (NSDictionary *item in menuItem.mainMethod[0][key]) {
        NSString *label = item[@"label"] ?: @"";
        NSDictionary *bgColor = item[@"bgColor"] ?: @{};
        NSNumber *hideLine = item[@"hideLineSeparator"] ?: @NO;
        NSDictionary *fontColor = item[@"fontColor"] ?: @{};
        NSString *icon = item[@"icon"] ?: @"blank";
        NSDictionary *action = item[@"action"] ?: @{};
        NSNumber *showTop = item[@"revealViewTop"] ?: @NO;
        
        NSDictionary *itemDict = @{@"label": label,
                                   @"bgColor": bgColor,
                                   @"hideLineSeparator": hideLine,
                                   @"fontColor": fontColor,
                                   @"icon": icon,
                                   @"action": action,
                                   @"revealViewTop": showTop,
                                   @"isSetting": @(NO),
                                   @"type": @"embedded"};
         
        // Do not show the remoteToolBar items in the menu while in "online" state
        if (!([self itemShownInRemoteToolBar:item] && [key isEqualToString:@"online"])) {
            [tableData addObject:itemDict];
        }
        // "embedded remote" (reachable from NowPlaying screen) always has the volume bar
        if ([self showEmbeddedVolumeBar:item mainLabel:menuItem.mainLabel] && [key isEqualToString:@"online"]) {
            [tableData addObject:itemDict];
        }
    }
    editableRowStartAt = tableData.count;
    if ([key isEqualToString:@"online"] && menuItem.family == FamilyRemote) {
        customButton *arrayButtons = [customButton new];
        if (arrayButtons.buttons.count == 0) {
            editTableButton.enabled = NO;
            [arrayButtons.buttons addObject:infoCustomButton];
        }
        else {
            editTableButton.enabled = YES;
        }
        for (NSDictionary *item in arrayButtons.buttons) {
            NSString *label = item[@"label"] ?: @"";
            NSString *icon = item[@"icon"] ?: @"";
            NSString *type = item[@"type"] ?: @"";
            NSNumber *isSetting = item[@"isSetting"] ?: @YES;
            NSDictionary *action = item[@"action"] ?: @{};
            
            NSDictionary *itemDict = @{
                @"label": label,
                @"bgColor": @{},
                @"hideLineSeparator": @NO,
                @"fontColor": @{},
                @"icon": icon,
                @"isSetting": isSetting,
                @"revealViewTop": @NO,
                @"type": type,
                @"action": action,
            };
            
            [tableData addObject:itemDict];
        }
    }

    if (reload) {
        [menuTableView reloadData];
    }
}

- (NSIndexPath*)getIndexPathForKey:(NSString*)key withValue:(NSString*)value inArray:(NSMutableArray*)array {
    NSIndexPath *foundIndex = nil;
    NSUInteger index = [array indexOfObjectPassingTest:
                        ^BOOL(NSDictionary *dict, NSUInteger idx, BOOL *stop) {
                            return [dict[key] isEqual:value];
                        }];
    if (index != NSNotFound) {
        foundIndex = [NSIndexPath indexPathForRow:index inSection:0];
    }
    return foundIndex;
}

- (void)connectionSuccess:(NSNotification*)note {
    NSDictionary *theData = note.userInfo;
    if (theData != nil) {
        NSString *serverTxt = theData[@"message"];
        NSString *icon_connection = theData[@"icon_connection"];
        NSIndexPath *serverRow = [self getIndexPathForKey:@"label" withValue:@"ServerInfo" inArray:tableData];
        if (serverRow != nil) {
            UITableViewCell *cell = [menuTableView cellForRowAtIndexPath:serverRow];
            if (serverTxt != nil && ![serverTxt isEqualToString:@""]) {
                UILabel *title = (UILabel*)[cell viewWithTag:3];
                title.text = serverTxt;
            }
            if (icon_connection != nil && ![icon_connection isEqualToString:@""]) {
                UIImageView *icon = (UIImageView*)[cell viewWithTag:1];
                icon.image = [UIImage imageNamed:icon_connection];
            }
        }
    }
    [self setRightMenuOption:@"online" reloadTableData:YES];
    infoLabel.alpha = 0;
    moreButton.enabled = YES;
}

- (void)connectionFailed:(NSNotification*)note {
    NSDictionary *theData = note.userInfo;
    if (theData != nil) {
        NSString *serverTxt = theData[@"message"];
        NSString *icon_connection = theData[@"icon_connection"];
        NSIndexPath *serverRow = [self getIndexPathForKey:@"label" withValue:@"ServerInfo" inArray:tableData];
        if (serverRow != nil) {
            UITableViewCell *cell = [menuTableView cellForRowAtIndexPath:serverRow];
            if (serverTxt != nil && ![serverTxt isEqualToString:@""]) {
                UILabel *title = (UILabel*)[cell viewWithTag:3];
                title.text = serverTxt;
            }
            if (icon_connection != nil && ![icon_connection isEqualToString:@""]) {
                UIImageView *icon = (UIImageView*)[cell viewWithTag:1];
                icon.image = [UIImage imageNamed:icon_connection];
            }
        }
    }
    if (AppDelegate.instance.obj.serverIP.length != 0) {
        infoLabel.alpha = 0;
        [self setRightMenuOption:@"offline" reloadTableData:YES];
        moreButton.enabled = NO;
    }
    else {
        [tableData removeAllObjects];
        [menuTableView reloadData];
        infoLabel.alpha = 1;
        [self setRightMenuOption:@"utility" reloadTableData:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
