//
//  RightMenuViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 9/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//
#import "RightMenuViewController.h"
#import "AppDelegate.h"
#import "DetailViewController.h"
#import "CustomNavigationController.h"
#import "customButton.h"
#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"
#import "Utilities.h"
#import "CustomButtonCell.h"

#define TOOLBAR_HEIGHT 44.0
#define BUTTON_SPACING 8.0
#define BUTTON_WIDTH 100.0

@implementation RightMenuViewController

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return CUSTOM_BUTTON_ITEM_HEIGHT;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return tableData.count;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    cell.backgroundColor = CUSTOM_BUTTON_BACKGROUND;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    CustomButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"customButtonCellIdentifier"];
    if (cell == nil) {
        cell = [[CustomButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"customButtonCellIdentifier"];
        cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.tintColor = UIColor.lightGrayColor;
        if (@available(iOS 13.0, *)) {
            cell.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        }
        
        // UISwitch calls toggleSwitch
        UISwitch *onoff = cell.onoffSwitch;
        [onoff addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
    }
    
    // Reset to default for each cell to allow dequeuing
    UIImageView *icon = cell.buttonIcon;
    icon.hidden = NO;
    icon.alpha = 0.6;
    
    UISwitch *onoff = cell.onoffSwitch;
    onoff.hidden = YES;
    
    UILabel *title = cell.buttonLabel;
    title.text = tableData[indexPath.row][@"label"];
    
    // Tailor cell layout for boolean switch
    if ([tableData[indexPath.row][@"type"] isEqualToString:@"boolean"]) {
        onoff.hidden = NO;
        icon.hidden = YES;
        
        NSMutableDictionary *params = tableData[indexPath.row][@"action"][@"params"];
        if ([params[@"value"] isKindOfClass:[NSNumber class]]) {
            [onoff setOn:[params[@"value"] boolValue]];
        }
        else {
            onoff.hidden = YES;
            [cell.busyView startAnimating];
            NSString *command = @"Settings.GetSettingValue";
            NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:params[@"setting"], @"setting", nil];
            [self getXBMCValue:command params:parameters uiControl:onoff storeSetting:params indicator:cell.busyView];
        }
    }
    
    // Load the icon for the custom button
    NSString *iconName = tableData[indexPath.row][@"icon"];
    NSString *command = tableData[indexPath.row][@"action"][@"command"];
    if ([command isEqualToString:@"Addons.ExecuteAddon"]) {
        [icon sd_setImageWithURL:[NSURL URLWithString:iconName]
                placeholderImage:[UIImage imageNamed:@"blank"]
                         options:SDWebImageScaleToNativeSize];
        icon.alpha = 1.0;
    }
    else if ([command isEqualToString:@"Input.ExecuteAction"]) {
        icon.image = [UIImage imageNamed:@"default-right-action-icon"];
    }
    else if ([command isEqualToString:@"GUI.ActivateWindow"]) {
        icon.image = [UIImage imageNamed:@"default-right-window-icon"];
    }
    else if ([command isEqualToString:@"Settings.SetSettingValue"]) {
        icon.image = [UIImage imageNamed:@"default-right-menu-icon"];
    }
    else {
        icon.image = [UIImage imageNamed:iconName];
    }
    return cell;
}

- (UIView*)createToolbarView:(CGFloat)toolbarHeight {
    CGRect frame = self.view.bounds;
    UIView *newView = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height - toolbarHeight, frame.size.width, toolbarHeight)];
    newView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    newView.backgroundColor = UIColor.clearColor;
    
    // Add visual effect
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithFrame:newView.frame];
    effectView.autoresizingMask = newView.autoresizingMask;
    effectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    [newView addSubview:effectView];
    
    // plus button
    UIImage *image = [UIImage imageNamed:@"icon_plus"];
    image = [Utilities colorizeImage:image withColor:UIColor.lightGrayColor];
    CGFloat originX = IS_IPHONE ? (ANCHOR_RIGHT_PEEK + PANEL_SHADOW_SIZE) : 0 + BUTTON_SPACING;
    moreButton = [[UIButton alloc] initWithFrame:CGRectMake(originX, 0, TOOLBAR_HEIGHT, TOOLBAR_HEIGHT)];
    moreButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    moreButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [moreButton setImage:image forState:UIControlStateNormal];
    [moreButton setImage:image forState:UIControlStateHighlighted];
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

#pragma mark - Table actions

- (void)addButtonToList:(id)sender {
    if (AppDelegate.instance.serverVersion < 13) {
        UIAlertController *alertCtrl = [Utilities createAlertOK:@"" message:LOCALIZED_STR(@"XBMC \"Gotham\" version 13 or superior is required to access XBMC settings")];
        [self presentViewController:alertCtrl animated:YES completion:nil];
    }
    else {
        DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
        detailViewController.detailItem = AppDelegate.instance.customButtonEntry;
        if (IS_IPHONE) {
            CustomNavigationController *navController = [[CustomNavigationController alloc] initWithRootViewController:detailViewController];
            navController.navigationBar.barStyle = UIBarStyleBlack;
            navController.navigationBar.tintColor = ICON_TINT_COLOR;
            navController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:navController animated:YES completion:nil];
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LeaveFullscreen" object:nil userInfo:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"StackScrollOnScreen" object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MainMenuDeselectSection" object:nil userInfo:nil];
            [UIApplication.sharedApplication.keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
            detailViewController.view.frame = CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height);
            [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:detailViewController invokeByController:self isStackStartView:YES];
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
        [self loadCustomButtons];
        [menuTableView reloadData];
    }
}

- (void)loadCustomButtons {
    // Create and load custom buttons
    customButton *arrayButtons = [customButton new];
    if (arrayButtons.buttons.count == 0) {
        editTableButton.enabled = NO;
        [arrayButtons.buttons addObject:infoCustomButton];
    }
    else {
        editTableButton.enabled = YES;
    }
    
    // Build table with custom buttons
    tableData = [NSMutableArray new];
    for (NSDictionary *item in arrayButtons.buttons) {
        NSString *label = item[@"label"] ?: @"";
        NSString *icon = item[@"icon"] ?: @"";
        NSString *type = item[@"type"] ?: @"";
        NSNumber *isSetting = item[@"isSetting"] ?: @YES;
        NSDictionary *action = item[@"action"] ?: @{};
        
        NSMutableDictionary *itemDict = [@{
            @"label": label,
            @"icon": icon,
            @"isSetting": isSetting,
            @"revealViewTop": @NO,
            @"type": type,
            @"action": action,
        } mutableCopy];
        
        [tableData addObject:itemDict];
    }
}

#pragma mark - UISwitch

- (void)toggleSwitch:(id)sender {
    // Gather NSIndexPath from sender
    CGPoint hitPoint = [sender convertPoint:CGPointZero toView:menuTableView];
    NSIndexPath *hitIndex = [menuTableView indexPathForRowAtPoint:hitPoint];
    
    // Process the clicked UISwitch
    NSInteger tableIdx = hitIndex.row;
    if (tableIdx < tableData.count) {
        UISwitch *onoff = (UISwitch*)sender;
        NSMutableDictionary *params = tableData[tableIdx][@"action"][@"params"];
        NSString *command = tableData[tableIdx][@"action"][@"command"];
        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:params[@"setting"], @"setting", @(onoff.on), @"value", nil];
        if ([params respondsToSelector:@selector(setObject:forKey:)]) {
            params[@"value"] = @(onoff.on);
        }
        [self xbmcAction:command params:parameters uiControl:onoff];
    }
}

#pragma mark - Table view delegate

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
    if (proposedDestinationIndexPath.row < 0) {
        return [NSIndexPath indexPathForRow:0 inSection:0];
    }
    else {
        return proposedDestinationIndexPath;
    }
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
    id objectMove = tableData[sourceIndexPath.row];
    [tableData removeObjectAtIndex:sourceIndexPath.row];
    [tableData insertObject:objectMove atIndex:destinationIndexPath.row];
    
    customButton *arrayButtons = [customButton new];
    objectMove = arrayButtons.buttons[sourceIndexPath.row];
    [arrayButtons.buttons removeObjectAtIndex:sourceIndexPath.row];
    [arrayButtons.buttons insertObject:objectMove atIndex:destinationIndexPath.row];
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
            [tableView performBatchUpdates:^{
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
            } completion:nil];
        }
        [self deleteCustomButton:indexPath.row];
	}
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath {
    UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:LOCALIZED_STR(@"Custom button") message:LOCALIZED_STR(@"Modify label:") preferredStyle:UIAlertControllerStyleAlert];
    [alertCtrl addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"";
        textField.text = tableData[indexPath.row][@"label"];
    }];
    UIAlertAction *updateButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Update label") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (indexPath.row >= tableData.count) {
            return;
        }
        tableData[indexPath.row][@"label"] = alertCtrl.textFields[0].text;
        
        CustomButtonCell *cell = [menuTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        UILabel *title = cell.buttonLabel;
        title.text = alertCtrl.textFields[0].text;
        
        customButton *arrayButtons = [customButton new];
        if ([arrayButtons.buttons[indexPath.row] respondsToSelector:@selector(setObject:forKey:)]) {
            arrayButtons.buttons[indexPath.row][@"label"] = alertCtrl.textFields[0].text;
            [arrayButtons saveData];
        }
    }];
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    [alertCtrl addAction:updateButton];
    [alertCtrl addAction:cancelButton];
    [self presentViewController:alertCtrl animated:YES completion:nil];
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
        NSString *command = tableData[indexPath.row][@"action"][@"command"];
        if ([command isEqualToString:@"AddButton"]) {
            [self addButtonToList:nil];
        }
        else if (command != nil) {
            NSDictionary *parameters = tableData[indexPath.row][@"action"][@"params"] ?: @{};
            [self xbmcAction:command params:parameters uiControl:nil];
        }
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
            [Utilities showMessage:LOCALIZED_STR(@"Command executed") color:SUCCESS_MESSAGE_COLOR];
        }
        else {
            [Utilities showMessage:LOCALIZED_STR(@"Cannot do that") color:ERROR_MESSAGE_COLOR];
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
        if (methodError == nil && error == nil && [methodResult isKindOfClass:[NSDictionary class]]) {
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

#pragma mark - LifeCycle

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat bottomPadding = IS_IPAD ? 0 : [Utilities getBottomPadding];
    CGFloat toolbarHeight = TOOLBAR_HEIGHT + bottomPadding;
    [self.view addSubview:[self createToolbarView:toolbarHeight]];
    
    menuTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    if (IS_IPHONE) {
        CGFloat deltaY = [Utilities getTopPadding];
        self.slidingViewController.anchorLeftPeekAmount = ANCHOR_RIGHT_PEEK;
        self.slidingViewController.underRightWidthLayout = ECFullWidth;
        menuTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        menuTableView.frame = CGRectMake(ANCHOR_RIGHT_PEEK,
                                         deltaY,
                                         UIScreen.mainScreen.bounds.size.width - ANCHOR_RIGHT_PEEK,
                                         self.view.frame.size.height - deltaY - toolbarHeight);
    }
    else {
        menuTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        menuTableView.frame = CGRectMake(0,
                                         0,
                                         self.view.frame.size.width,
                                         self.view.frame.size.height - toolbarHeight);
    }
    menuTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    menuTableView.delegate = self;
    menuTableView.dataSource = self;
    menuTableView.backgroundColor = UIColor.clearColor;
    menuTableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    menuTableView.contentInset = UIEdgeInsetsMake(0, 0, toolbarHeight, 0);
    menuTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    [self.view addSubview:menuTableView];
    
    torchIsOn = [Utilities isTorchOn];
    
    infoCustomButton = @{
        @"label": LOCALIZED_STR(@"No custom button defined."),
        @"icon": @"button_info",
        @"action": @{},
        @"revealViewTop": @NO,
        @"isSetting": @NO,
        @"type": @"",
    };

    if (AppDelegate.instance.obj.serverIP.length != 0) {
        [self loadCustomButtons];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionSuccess:)
                                                 name:@"XBMCServerConnectionSuccess"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionFailed:)
                                                 name:@"XBMCServerConnectionFailed"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadCustomButtonTable:)
                                                 name:@"UIInterfaceCustomButtonAdded"
                                               object:nil];
}

- (void)reloadCustomButtonTable:(NSNotification*)note {
    [self loadCustomButtons];
    [menuTableView reloadData];
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
    [self loadCustomButtons];
    [menuTableView reloadData];
    moreButton.enabled = YES;
}

- (void)connectionFailed:(NSNotification*)note {
    if (AppDelegate.instance.obj.serverIP.length != 0) {
        [self loadCustomButtons];
        [menuTableView reloadData];
        moreButton.enabled = NO;
    }
    else {
        [tableData removeAllObjects];
        [self loadCustomButtons];
        [menuTableView reloadData];
    }
}

@end
