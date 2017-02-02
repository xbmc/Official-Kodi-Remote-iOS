//
//  SettingsValuesViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 2/4/14.
//  Copyright (c) 2014 joethefox inc. All rights reserved.
//

#import "SettingsValuesViewController.h"
#import "DSJSONRPC.h"
#import "AppDelegate.h"
#import "OBSlider.h"
#import "customButton.h"
#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"

@interface SettingsValuesViewController ()

@end

@implementation SettingsValuesViewController

@synthesize detailItem = _detailItem;

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
    }
}

- (id)initWithFrame:(CGRect)frame withItem:(id)item {
    if (self = [super init]) {
		
        [self.view setFrame:frame];
        
        UIImageView *imageBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shiny_black_back"]];
        [imageBackground setAutoresizingMask: UIViewAutoresizingFlexibleBottomMargin |UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [imageBackground setFrame:frame];
        [self.view addSubview:imageBackground];
        
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [activityIndicator setColor:[UIColor grayColor]];
        [activityIndicator setCenter:CGPointMake(frame.size.width / 2, frame.size.height / 2)];
        [activityIndicator setHidesWhenStopped:YES];
        [self.view addSubview:activityIndicator];

        self.detailItem = item;

        cellHeight = 44.0f;
        
        settingOptions = [self.detailItem objectForKey:@"options"];
        
//        if (![settingOptions isKindOfClass:[NSArray class]]) {
//            if ([[self.detailItem objectForKey:@"definition"] isKindOfClass:NSClassFromString(@"JKDictionary")]){
//                settingOptions = [[self.detailItem objectForKey:@"definition"] objectForKey:@"options"];
//            }
//        }
        
        if (![settingOptions isKindOfClass:[NSArray class]]) {
            settingOptions = nil;
        }
        itemControls = [self.detailItem objectForKey:@"control"];
        
        xbmcSetting = cDefault;
        
        if ([[itemControls objectForKey:@"format"] isEqualToString:@"boolean"]) {
            xbmcSetting = cSwitch;
            cellHeight = 210.0f;
        }
        else if ([[itemControls objectForKey:@"multiselect"] boolValue] == YES && ![settingOptions isKindOfClass:[NSArray class]]){
            xbmcSetting = cMultiselect;
            [self.detailItem setObject:[[self.detailItem objectForKey:@"value"] mutableCopy] forKey:@"value"];
        }
        else if ([[itemControls objectForKey:@"format"] isEqualToString:@"addon"]) {
            xbmcSetting = cList;
            cellHeight = 44.0f;
            [_tableView setFrame:CGRectMake(self.view.frame.size.width, _tableView.frame.origin.y, _tableView.frame.size.width, _tableView.frame.size.height)];
            self.navigationItem.title = [self.detailItem objectForKey:@"label"];
            settingOptions = [[NSMutableArray alloc] init];
            [self retrieveXBMCData: @"Addons.GetAddons"
                        parameters: [NSDictionary dictionaryWithObjectsAndKeys:
                                     [self.detailItem objectForKey:@"addontype"], @"type",
                                     [NSNumber numberWithBool:YES], @"enabled",
                                     [NSArray arrayWithObjects:@"name", nil], @"properties",
                                     nil]
                           itemKey: @"addons"];
        }
        else if ([[itemControls objectForKey:@"format"] isEqualToString:@"action"] || [[itemControls objectForKey:@"format"] isEqualToString:@"path"]) {
            self.navigationItem.title = [self.detailItem objectForKey:@"label"];
            xbmcSetting = cUnsupported;
            cellHeight = 142.0f;
        }
        else if ([[itemControls objectForKey:@"type"] isEqualToString:@"spinner"] && settingOptions == nil) {
            xbmcSetting = cSlider;
            storeSliderValue = [[self.detailItem objectForKey:@"value"] intValue];
            cellHeight = 184.0f;
        }
        else if ([[itemControls objectForKey:@"type"] isEqualToString:@"edit"]) {
            xbmcSetting = cInput;
            cellHeight = 172.0f;
        }
        else if ([[itemControls objectForKey:@"type"] isEqualToString:@"list"] && settingOptions == nil) {
            xbmcSetting = cSlider;
            storeSliderValue = [[self.detailItem objectForKey:@"value"] intValue];
            cellHeight = 184.0f;
        }
        else {
            self.navigationItem.title = [self.detailItem objectForKey:@"label"];
            if ([settingOptions isKindOfClass:[NSArray class]]){
                if ([settingOptions count] > 0){
                    xbmcSetting = cList;
                }
            }
        }
        if (xbmcSetting == cUnsupported){
            footerMessage = NSLocalizedString(@"-- WARNING --\nThis kind of setting cannot be configured remotely. Use the XBMC GUI for changing this setting.\nThank you.", nil);
        }
        else if (xbmcSetting == cList || xbmcSetting == cDefault || xbmcSetting == cMultiselect) {
            footerMessage = [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"genre"] == nil ? [self.detailItem objectForKey:@"label"] : [self.detailItem objectForKey:@"genre"]];
        }
        if (xbmcSetting != cUnsupported){
            footerMessage = [NSString stringWithFormat:@"%@\xE2\x84\xB9 %@", footerMessage == nil ? @"" : [NSString stringWithFormat:@"%@\n\n", footerMessage], NSLocalizedString(@"Tap and hold a setting to add a new button.", nil)];
        }
        
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
        cellLabelOffset = 8;
		[_tableView setDelegate:self];
		[_tableView setDataSource:self];
        [_tableView setBackgroundColor:[UIColor clearColor]];
        UIView* footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
		[_tableView setTableFooterView:footerView];
        [self.view setBackgroundColor:[UIColor clearColor]];
        [self.view addSubview:_tableView];
        
        UILongPressGestureRecognizer *longPressGesture = [UILongPressGestureRecognizer new];
        [longPressGesture addTarget:self action:@selector(handleLongPress:)];
        [longPressGesture setDelegate:self];
        [_tableView addGestureRecognizer:longPressGesture];
        
        CGFloat deltaY = 64.0f;
        CGRect frame = [[UIScreen mainScreen ] bounds];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            frame.size.width = STACKSCROLL_WIDTH;
            deltaY = 0;
        }
        
        scrubbingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 44)];
        [scrubbingView setCenter:CGPointMake((int)(frame.size.width / 2), (int)(frame.size.height / 2) + 50)];
        [scrubbingView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.9f]];
        scrubbingView.alpha = 0.0f;
        CGRect toolbarShadowFrame = CGRectMake(0.0f, 44, self.view.frame.size.width, 4);
        UIImageView *toolbarShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
        [toolbarShadow setImage:[UIImage imageNamed:@"tableUp.png"]];
        toolbarShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbarShadow.contentMode = UIViewContentModeScaleToFill;
        toolbarShadow.opaque = YES;
        [scrubbingView addSubview:toolbarShadow];
        toolbarShadowFrame.origin.y = -4;
        UIImageView *toolbarUpShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
        [toolbarUpShadow setImage:[UIImage imageNamed:@"tableDown.png"]];
        toolbarUpShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbarUpShadow.contentMode = UIViewContentModeScaleToFill;
        toolbarUpShadow.opaque = YES;
        [scrubbingView addSubview:toolbarUpShadow];
        
        scrubbingMessage = [[UILabel alloc] initWithFrame:CGRectMake(5, 3, frame.size.width - 10, 18)];
        [scrubbingMessage setBackgroundColor:[UIColor clearColor]];
        [scrubbingMessage setFont:[UIFont boldSystemFontOfSize:13]];
        [scrubbingMessage setAdjustsFontSizeToFitWidth:YES];
        [scrubbingMessage setMinimumScaleFactor:10.0f/13.0f];
        [scrubbingMessage setTextColor:[UIColor whiteColor]];
        [scrubbingMessage setText:NSLocalizedString(@"Slide your finger up or down to adjust the scrubbing rate.", nil)];
        [scrubbingMessage setTextAlignment:NSTextAlignmentCenter];
        [scrubbingView addSubview:scrubbingMessage];
        
        scrubbingRate = [[UILabel alloc] initWithFrame:CGRectMake(5, 21, frame.size.width - 10, 18)];
        [scrubbingRate setBackgroundColor:[UIColor clearColor]];
        [scrubbingRate setFont:[UIFont boldSystemFontOfSize:13]];
        [scrubbingRate setTextColor:[UIColor grayColor]];
        [scrubbingRate setTextAlignment:NSTextAlignmentCenter];
        [scrubbingRate setText:NSLocalizedString(@"Scrubbing 1", nil)];
        [scrubbingView addSubview:scrubbingRate];
        
        [self.view insertSubview:scrubbingView aboveSubview:_tableView];

        messagesView = [[MessagesView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, deltaY + 42.0f) deltaY:deltaY deltaX:0];
        [self.view addSubview:messagesView];
	}
    return self;
}

#pragma mark - Gesture Recognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[OBSlider class]] || [touch.view isKindOfClass:[UISwitch class]] || [touch.view isKindOfClass:NSClassFromString(@"_UISwitchInternalView")]) {
        return NO;
    }
    return YES;
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint p;
        NSIndexPath *indexPath = nil;
        p = [gestureRecognizer locationInView:_tableView];
        indexPath = [_tableView indexPathForRowAtPoint:p];
        if (indexPath != nil){
            longPressRow = indexPath;
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Add a new button", nil)
                                                                message: NSLocalizedString(@"Enter the label:", nil)
                                                               delegate: self
                                                      cancelButtonTitle: NSLocalizedString(@"Cancel", nil)
                                                      otherButtonTitles: NSLocalizedString(@"Add button", nil), nil];
            [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
            NSString *subTitle = @"";
            NSString *stringFormat = @": %i";
            switch (xbmcSetting) {
                case cList:
                    subTitle = [NSString stringWithFormat:@": %@",[[settingOptions objectAtIndex:longPressRow.row] objectForKey:@"label"]];
                    break;
                case cSlider:
                    if ([itemControls objectForKey:@"formatlabel"] != nil){
                        stringFormat = [NSString stringWithFormat:@": %@", [itemControls objectForKey:@"formatlabel"]];
                    }
                    subTitle = [NSString stringWithFormat:stringFormat, (int)storeSliderValue];
                    break;
                case cUnsupported:
                    return;
                    break;
                default:
                    break;
            }
            NSString *title=[NSString stringWithFormat:@"%@%@", [self.detailItem objectForKey:@"label"], subTitle];
            [[alertView textFieldAtIndex:0] setText:title];
            [alertView show];
        }
    }
}

#pragma mark - Alert View

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex!=alertView.cancelButtonIndex){
        NSString *option = [alertView buttonTitleAtIndex:buttonIndex];
        if ([option isEqualToString:NSLocalizedString(@"Add button", nil)]){
            NSString *command = @"Settings.SetSettingValue";
            id value = @"";
            NSString *type = @"string";
            if ([self.detailItem objectForKey:@"year"] != nil){
                type = [self.detailItem objectForKey:@"year"];
            }
            switch (xbmcSetting) {
                case cList:
                    if ([type isEqualToString:@"integer"]){
                        value = [NSNumber numberWithInt:[[[settingOptions objectAtIndex:longPressRow.row] objectForKey:@"value"] intValue]];
                    }
                    else {
                        value = [NSString stringWithFormat:@"%@",[[settingOptions objectAtIndex:longPressRow.row] objectForKey:@"value"]];
                    }
                    break;
                case cSlider:
                    value = [NSNumber numberWithInt: (int)storeSliderValue];
                    break;
                default:
                    value = @"";
                    break;
            }
            NSDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys: [self.detailItem objectForKey:@"id"], @"setting", value, @"value", nil];
            NSDictionary *newButton = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       [[alertView textFieldAtIndex:0]text], @"label",
                                       type, @"type",
                                       @"default-right-menu-icon", @"icon",
                                       [NSNumber numberWithInt:xbmcSetting], @"xbmcSetting",
                                       [self.detailItem objectForKey:@"genre"], @"helpText",
                                       [NSDictionary dictionaryWithObjectsAndKeys:
                                        command, @"command",
                                        params, @"params",
                                        nil], @"action",
                                       nil];
            [self saveCustomButton:newButton];
        }
    }
}

#pragma mark - custom button

-(void)saveCustomButton:(NSDictionary *)button {
    customButton *arrayButtons = [[customButton alloc] init];
    [arrayButtons.buttons addObject:button];
    [arrayButtons saveData];
    [messagesView showMessage:NSLocalizedString(@"Button added", nil) timeout:2.0f color:[UIColor colorWithRed:39.0f/255.0f green:158.0f/255.0f blue:34.0f/255.0f alpha:0.95f]];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIInterfaceCustomButtonAdded" object: nil];
    }
}

#pragma mark - JSON

-(void)xbmcAction:(NSString *)action params:(NSDictionary *)params uiControl:(id)sender {
    if ([sender respondsToSelector:@selector(setUserInteractionEnabled:)]){
        [sender setUserInteractionEnabled:NO];
    }
    [activityIndicator startAnimating];
    DSJSONRPC *jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    [jsonRPC callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        [activityIndicator stopAnimating];
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

-(void)retrieveXBMCData:(NSString *)method parameters:(NSDictionary *)params itemKey:(NSString *)itemkey{
    
    [activityIndicator startAnimating];
    DSJSONRPC *jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
    [jsonRPC callMethod: method
         withParameters: params
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               [activityIndicator stopAnimating];
               if (error == nil && methodError == nil) {
                   NSSortDescriptor *descriptor = [[NSSortDescriptor alloc]
                                                   initWithKey:@"name"
                                                   ascending:YES
                                                   selector:@selector(localizedCaseInsensitiveCompare:)];
                   NSArray *retrievedItems = [[methodResult objectForKey:itemkey] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
                   for (NSDictionary *item in retrievedItems) {
                       [settingOptions addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                  [item objectForKey:@"name"], @"label",
                                                  [item objectForKey:@"addonid"], @"value",
                                                  nil]
                        ];
                   }
                   [_tableView reloadData];
                   [self AnimTable:_tableView AnimDuration:0.3 Alpha:1.0 XPos:0];
                   [self scrollTableRow:settingOptions];
               }
           }];
    return;
}

#pragma mark -
#pragma mark Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return cellHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numRows = 1;
    if ([settingOptions isKindOfClass:[NSArray class]]) {
        numRows = [settingOptions count];
    }
    return numRows;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	cell.backgroundColor = [UIColor whiteColor];
}

- (void)adjustFontSize:(UILabel *)label {
    CGRect descriptionRect;
    BOOL done = FALSE;
    CGFloat startSize = label.font.pointSize - 1;
    CGFloat endSize = startSize - 2;
    while (done == FALSE && startSize >= endSize){
        descriptionRect = [label.text  boundingRectWithSize:CGSizeMake(label.bounds.size.width, NSIntegerMax)
                                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                                 attributes:@{NSFontAttributeName:label.font}
                                                                    context:nil];
        CGSize descriptionSize = descriptionRect.size;
        if (descriptionSize.height > label.bounds.size.height) {
            [label setFont:[UIFont systemFontOfSize:startSize]];
        }
        else{
            done = TRUE;
        }
        startSize --;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tableCellIdentifier = @"UITableViewCell";
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableCellIdentifier];
        UILabel *cellLabel = [[UILabel alloc] initWithFrame:CGRectMake(cellLabelOffset, cellHeight/2 - 11, self.view.bounds.size.width - cellLabelOffset - 38, 22)];
        cellLabel.tag = 1;
        [cellLabel setFont:[UIFont systemFontOfSize:18]];
        [cellLabel setAdjustsFontSizeToFitWidth:YES];
        [cellLabel setMinimumScaleFactor:12.0f/18.0f];
        [cellLabel setTextColor:[UIColor blackColor]];
        [cellLabel setHighlightedTextColor:[UIColor whiteColor]];
        [cell.contentView addSubview:cellLabel];
        
        UISwitch *onoff = [[UISwitch alloc] initWithFrame: CGRectZero];
        onoff.tag = 201;
        [onoff addTarget: self action: @selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
        [onoff setFrame:CGRectMake(self.view.bounds.size.width - onoff.frame.size.width - 12, cellHeight/2 - onoff.frame.size.height/2+ 20, onoff.frame.size.width, onoff.frame.size.height)];
        [cell.contentView addSubview: onoff];

        UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(cellLabelOffset, 54, self.view.bounds.size.width - onoff.frame.size.width - cellLabelOffset * 3, cellHeight - 54 - 10)];
        descriptionLabel.tag = 2;
        [descriptionLabel setFont:[UIFont systemFontOfSize:12]];
        [descriptionLabel setAdjustsFontSizeToFitWidth:YES];
        [descriptionLabel setNumberOfLines:0];
        [descriptionLabel setMinimumScaleFactor:11.0f/12.0f];
        [descriptionLabel setTextColor:[UIColor grayColor]];
        [descriptionLabel setHighlightedTextColor:[UIColor lightGrayColor]];
        [cell.contentView addSubview:descriptionLabel];
        
        OBSlider *slider = [[OBSlider alloc] initWithFrame:CGRectMake(14, cellHeight - 20 - 20, cell.frame.size.width - 14 * 2, 20)];
        [slider setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
        [slider setBackgroundColor:[UIColor clearColor]];
        slider.continuous = YES;
        slider.tag = 101;
        [slider addTarget:self action:@selector(stopUpdateSlider:) forControlEvents:UIControlEventEditingDidEnd];
        [slider addTarget:self action:@selector(stopUpdateSlider:) forControlEvents:UIControlEventTouchCancel];
        [slider addTarget:self action:@selector(stopUpdateSlider:) forControlEvents:UIControlEventTouchUpInside];
        [slider addTarget:self action:@selector(stopUpdateSlider:) forControlEvents:UIControlEventTouchUpOutside];
        [slider addTarget:self action:@selector(startUpdateSlider:) forControlEvents:UIControlEventTouchDown];
        [cell.contentView addSubview:slider];
        
        int uiSliderLabelWidth = cell.frame.size.width - 14 * 2;
        UILabel *uiSliderLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width / 2 - uiSliderLabelWidth / 2, slider.frame.origin.y - 28, uiSliderLabelWidth, 20)];
        uiSliderLabel.tag = 102;
        [uiSliderLabel setTextAlignment:NSTextAlignmentCenter];
        [uiSliderLabel setFont:[UIFont systemFontOfSize:14]];
        [uiSliderLabel setAdjustsFontSizeToFitWidth:YES];
        [uiSliderLabel setMinimumScaleFactor:12.0f/14.0f];
        [uiSliderLabel setTextColor:[UIColor grayColor]];
        [uiSliderLabel setHighlightedTextColor:[UIColor lightGrayColor]];
        [cell.contentView addSubview:uiSliderLabel];
        
        UITextField *textInputField = [[UITextField alloc] initWithFrame:CGRectMake(14, cellHeight - 20 - 20, cell.frame.size.width - 14 * 2, 30)];
        [textInputField setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        textInputField.borderStyle = UITextBorderStyleRoundedRect;
        textInputField.textAlignment = NSTextAlignmentCenter;
        textInputField.font = [UIFont systemFontOfSize:15];
        textInputField.placeholder = NSLocalizedString(@"enter value", nil);;
        textInputField.autocorrectionType = UITextAutocorrectionTypeNo;
        textInputField.keyboardType = UIKeyboardTypeDefault;
        textInputField.returnKeyType = UIReturnKeyDefault;
        textInputField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textInputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        textInputField.delegate = self;
        textInputField.tag = 301;
        [cell.contentView addSubview:textInputField];
        [cellLabel setHighlightedTextColor:[UIColor blackColor]];
        [descriptionLabel setHighlightedTextColor:[UIColor grayColor]];
        [uiSliderLabel setHighlightedTextColor:[UIColor grayColor]];
	}
    cell.accessoryType =  UITableViewCellAccessoryNone;

    UILabel *cellLabel =  (UILabel*) [cell viewWithTag:1];
    UILabel *descriptionLabel =  (UILabel*) [cell viewWithTag:2];
    UISlider *slider = (UISlider*) [cell viewWithTag:101];
    UILabel *sliderLabel =  (UILabel*) [cell viewWithTag:102];
    UISwitch *onoff = (UISwitch*) [cell viewWithTag:201];
    UITextField *textInputField = (UITextField*) [cell viewWithTag:301];

    descriptionLabel.hidden = YES;
    slider.hidden = YES;
    sliderLabel.hidden = YES;
    onoff.hidden = YES;
    textInputField.hidden = YES;
    
    NSString *cellText = @"";
    NSString *stringFormat = @"%i";
    NSString *descriptionString = [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"genre"]];
    descriptionString = [descriptionString stringByReplacingOccurrencesOfString:@"[CR]" withString:@"\n"];
    switch (xbmcSetting) {
            
        case cSwitch:
    
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            descriptionLabel.hidden = NO;
            cellText = [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"label"]];
            [cellLabel setFrame:CGRectMake(cellLabelOffset, 8, self.view.bounds.size.width - onoff.frame.size.width - cellLabelOffset * 3, 44)];
            [cellLabel setNumberOfLines:2];
            [descriptionLabel setText:descriptionString];
            [self adjustFontSize:descriptionLabel];
            onoff.hidden = NO;
            onoff.on = [[self.detailItem objectForKey:@"value"] boolValue];
            break;
            
        case cList:
            
            cellText = [NSString stringWithFormat:@"%@", [[settingOptions objectAtIndex:indexPath.row] objectForKey:@"label"]];
            if ([[self.detailItem objectForKey:@"value"] isKindOfClass:[NSArray class]]){
                if ([[self.detailItem objectForKey:@"value"] containsObject:[[settingOptions objectAtIndex:indexPath.row] objectForKey:@"value"]]){
                    cell.accessoryType =  UITableViewCellAccessoryCheckmark;
                }
            }
            else if ([[[settingOptions objectAtIndex:indexPath.row] objectForKey:@"value"] isEqual:[self.detailItem objectForKey:@"value"]]){
                cell.accessoryType =  UITableViewCellAccessoryCheckmark;
            }
            break;
            
        case cSlider:
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            slider.hidden = NO;
            sliderLabel.hidden = NO;
            descriptionLabel.hidden = NO;
            [cellLabel setFrame:CGRectMake(cellLabelOffset, 8, self.view.bounds.size.width - (cellLabelOffset * 2), 46)];
            [cellLabel setNumberOfLines:2];
            [cellLabel setTextAlignment:NSTextAlignmentCenter];
            cellText = [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"label"]];
            
            [descriptionLabel setFrame:CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y + 2, self.view.bounds.size.width - (cellLabelOffset * 2), 58)];
            [descriptionLabel setTextAlignment:NSTextAlignmentCenter];
            [descriptionLabel setNumberOfLines:4];
            [descriptionLabel setText: [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"genre"]]];
            slider.minimumValue = [[self.detailItem objectForKey:@"minimum"] intValue];
            slider.maximumValue = [[self.detailItem objectForKey:@"maximum"] intValue];
            slider.value = [[self.detailItem objectForKey:@"value"] intValue];
            if ([itemControls objectForKey:@"formatlabel"] != nil){
                stringFormat = [NSString stringWithFormat:@"%@", [itemControls objectForKey:@"formatlabel"]];
            }
            [sliderLabel setText:[NSString stringWithFormat:stringFormat, [[self.detailItem objectForKey:@"value"] intValue]]];
            break;
            
        case cInput:
            
            descriptionLabel.hidden = NO;
            textInputField.hidden = NO;
            [cellLabel setFrame:CGRectMake(cellLabelOffset, 8, self.view.bounds.size.width - (cellLabelOffset * 2), 46)];
            [cellLabel setNumberOfLines:2];
            [cellLabel setTextAlignment:NSTextAlignmentCenter];
            cellText = [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"label"]];
            
            [descriptionLabel setFrame:CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y + 2, self.view.bounds.size.width - (cellLabelOffset * 2), 74)];
            [descriptionLabel setTextAlignment:NSTextAlignmentCenter];
            [descriptionLabel setNumberOfLines:5];
            descriptionString  = [descriptionString stringByReplacingOccurrencesOfString:@"[B]" withString:@""];
            descriptionString  = [descriptionString stringByReplacingOccurrencesOfString:@"[/B]" withString:@""];
            [descriptionLabel setText: descriptionString];
            [self adjustFontSize:descriptionLabel];
            [textInputField setText:[NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"value"]]];
            break;
            
        case cDefault | cMultiselect:
            
            if ([self.detailItem objectForKey:@"value"] != nil){
                if ([[self.detailItem objectForKey:@"value"] isKindOfClass:[NSArray class]]){
                    NSString *delimiter = [self.detailItem objectForKey:@"delimiter"];
                    if (delimiter == nil){
                        delimiter = @", ";
                    }
                    else {
                        delimiter = [NSString stringWithFormat:@"%@ ", delimiter];
                    }
                    cellText = [[self.detailItem objectForKey:@"value"] componentsJoinedByString:delimiter];
                }
                else{
                    cellText = [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"value"]];
                }
                cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;
            }
            break;
            
        case cUnsupported:
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [cellLabel setFrame:CGRectMake(cellLabelOffset, 8, self.view.bounds.size.width - cellLabelOffset * 2, cellHeight - 8)];
            [cellLabel setNumberOfLines:10];
            cellText = [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"genre"]];
            break;
            
        default:
            if ([self.detailItem objectForKey:@"value"] != nil){
                cellText = [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"value"]];
                cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;
            }
            break;
    }

    if ([cellText isEqualToString:@""] || cellText == nil){
        cellText = [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"genre"]];
    }

    [cellLabel setText:cellText];

    return cell;
}

#pragma mark Table view delegate

- (void)AnimTable:(UITableView *)tV AnimDuration:(float)seconds Alpha:(float)alphavalue XPos:(int)X{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	tV.alpha = alphavalue;
	CGRect frame;
	frame = [tV frame];
	frame.origin.x = X;
    frame.origin.y = 0;
	tV.frame = frame;
    [UIView commitAnimations];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = nil;
    NSString *command = nil;
    NSDictionary *params = nil;
    switch (xbmcSetting) {
        case cList:
            if ([[self.detailItem objectForKey:@"value"] isKindOfClass:[NSArray class]]){
                cell = [tableView cellForRowAtIndexPath:indexPath];
                if (cell.accessoryType == UITableViewCellAccessoryNone){
                    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                    [[self.detailItem objectForKey:@"value"] addObject:[[settingOptions objectAtIndex:indexPath.row] objectForKey:@"value"]];
                }
                else{
                    [cell setAccessoryType:UITableViewCellAccessoryNone];
                    [[self.detailItem objectForKey:@"value"] removeObject:[[settingOptions objectAtIndex:indexPath.row] objectForKey:@"value"]];
                }
            }
            else{
                if (selectedSetting == nil){
                    selectedSetting = [self getCurrentSelectedOption:settingOptions];
                }
                if (selectedSetting != nil){
                    cell = [tableView cellForRowAtIndexPath:selectedSetting];
                    [cell setAccessoryType:UITableViewCellAccessoryNone];
                }
                cell = [tableView cellForRowAtIndexPath:indexPath];
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                selectedSetting = indexPath;
                [self.detailItem setObject:[[settingOptions objectAtIndex:selectedSetting.row] objectForKey:@"value"] forKey:@"value"];
            }
            command = @"Settings.SetSettingValue";
            params = [NSDictionary dictionaryWithObjectsAndKeys: [self.detailItem objectForKey:@"id"], @"setting", [self.detailItem objectForKey:@"value"], @"value", nil];
            [self xbmcAction:command params:params uiControl:_tableView];

            break;
        case cMultiselect:
            if ([[self.detailItem objectForKey:@"definition"] isKindOfClass:[NSDictionary class]]){
                [[self.detailItem objectForKey:@"definition"] setObject:[self.detailItem objectForKey:@"value"] forKey:@"value"];
                [[self.detailItem objectForKey:@"definition"] setObject:[self.detailItem objectForKey:@"id"] forKey:@"id"];
                SettingsValuesViewController *settingsViewController = [[SettingsValuesViewController alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) withItem:[self.detailItem objectForKey:@"definition"]];
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
                    [self.navigationController pushViewController:settingsViewController animated:YES];
                }
                else{
                    [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:settingsViewController invokeByController:self isStackStartView:FALSE];
                }
            }
            break;
        default:
            selectedSetting = indexPath;
            break;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSInteger viewWidth = self.view.frame.size.width;
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, 1)];
    [sectionView setBackgroundColor:[UIColor colorWithRed:.4 green:.4 blue:.4 alpha:1]];
    CGRect toolbarShadowFrame = CGRectMake(0.0f, 1, viewWidth, 4);
    UIImageView *toolbarShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
    [toolbarShadow setImage:[UIImage imageNamed:@"tableUp.png"]];
    toolbarShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    toolbarShadow.contentMode = UIViewContentModeScaleToFill;
    toolbarShadow.opaque = YES;
    toolbarShadow.alpha = .3f;
    [sectionView addSubview:toolbarShadow];
    return sectionView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
//    if (xbmcSetting == cList || xbmcSetting == cDefault || xbmcSetting == cUnsupported || xbmcSetting == cMultiselect) {
    UIView *helpView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, footerHeight)];
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(cellLabelOffset, cellLabelOffset, self.view.bounds.size.width - cellLabelOffset * 2, 50)];
    [descriptionLabel setFont:[UIFont systemFontOfSize:12]];
    [descriptionLabel setBackgroundColor:[UIColor clearColor]];
    [descriptionLabel setNumberOfLines:20];
    [descriptionLabel setTextColor:[UIColor whiteColor]];
    [descriptionLabel setTextAlignment:NSTextAlignmentCenter];
    [descriptionLabel setHighlightedTextColor:[UIColor grayColor]];
    [descriptionLabel setText:[footerMessage stringByReplacingOccurrencesOfString:@"[CR]" withString:@"\n"]];
    if (xbmcSetting == cUnsupported){
        [helpView setBackgroundColor:[UIColor colorWithRed:.741f green:.141f blue:.141f alpha:1.0f]];
    }
    else{
        [helpView setBackgroundColor:[UIColor colorWithRed:45.0f/255.0f green:45.0f/255.0f blue:45.0f/255.0f alpha:0.95f]];
    }
    CGRect descriptionRect = [descriptionLabel.text  boundingRectWithSize:CGSizeMake(descriptionLabel.bounds.size.width, NSIntegerMax)
                                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                                               attributes:@{NSFontAttributeName:descriptionLabel.font}
                                                                  context:nil];
    CGSize descriptionSize = descriptionRect.size;
    
    [descriptionLabel setFrame:CGRectMake(cellLabelOffset, cellLabelOffset, self.view.bounds.size.width - cellLabelOffset * 2, descriptionSize.height)];
    footerHeight = descriptionSize.height + cellLabelOffset * 2;
    [helpView addSubview:descriptionLabel];
    return helpView;
//    }
//    else {
//        return nil;
//    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
//    if (xbmcSetting == cList || xbmcSetting == cDefault || xbmcSetting == cUnsupported || xbmcSetting == cMultiselect) {
        if (footerHeight < 0) {
            UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(cellLabelOffset, cellLabelOffset, self.view.bounds.size.width - cellLabelOffset * 2, 50)];
            [descriptionLabel setFont:[UIFont systemFontOfSize:12]];
            [descriptionLabel setNumberOfLines:20];
            [descriptionLabel setTextAlignment:NSTextAlignmentCenter];
            [descriptionLabel setText:[footerMessage stringByReplacingOccurrencesOfString:@"[CR]" withString:@"\n"]];
            CGRect descriptionRect = [descriptionLabel.text  boundingRectWithSize:CGSizeMake(descriptionLabel.bounds.size.width, NSIntegerMax)
                                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                                       attributes:@{NSFontAttributeName:descriptionLabel.font}
                                                                          context:nil];
            CGSize descriptionSize = descriptionRect.size;
            footerHeight = descriptionSize.height + cellLabelOffset * 2;
        }
        return footerHeight;
//    }
//    else {
//        return 0;
//    }
}
- (NSIndexPath *)getCurrentSelectedOption:(NSArray *)optionList {
    NSIndexPath *foundIndex = nil;
    NSUInteger index = [optionList indexOfObjectPassingTest:
                        ^BOOL(NSDictionary *dict, NSUInteger idx, BOOL *stop) {
                            return [[dict objectForKey:@"value"] isEqual:[self.detailItem objectForKey:@"value"]];
                        }];
    if (index != NSNotFound) {
        foundIndex = [NSIndexPath indexPathForRow:index inSection:0];
        selectedSetting = foundIndex;
    }
    return foundIndex;
}

- (void)scrollTableRow:(NSArray *)list {
    NSIndexPath *optionIndex = [self getCurrentSelectedOption:list];
    if (optionIndex != nil){
        [_tableView scrollToRowAtIndexPath:optionIndex atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        
    }
}

#pragma mark - UISlider

-(void)changeAlphaView:(UIView *)view alpha:(float)value time:(float)sec{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:sec];
	view.alpha = value;
    [UIView commitAnimations];
}

-(void)startUpdateSlider:(id)sender{
    [self changeAlphaView:scrubbingView alpha:1.0 time:0.3];
}

-(void)stopUpdateSlider:(id)sender{
    [self changeAlphaView:scrubbingView alpha:0.0 time:0.3];
    NSString *command = @"Settings.SetSettingValue";
    [self.detailItem setObject:[NSNumber numberWithInt: (int)storeSliderValue] forKey:@"value"];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: [self.detailItem objectForKey:@"id"], @"setting", [self.detailItem objectForKey:@"value"], @"value", nil];
    [self xbmcAction:command params:params uiControl:sender];
}

-(void)sliderAction:(id)sender {
    OBSlider *slider = (OBSlider*) sender;
    float newStep = roundf((slider.value) / [[self.detailItem objectForKey:@"step"] intValue]);
    float newValue = newStep * [[self.detailItem objectForKey:@"step"] intValue];
    if (newValue != storeSliderValue){
        storeSliderValue = newValue;
        if ([[[slider superview] viewWithTag:102] isKindOfClass:[UILabel class]]){
            UILabel *sliderLabel = (UILabel *)[[slider superview] viewWithTag:102];
            NSString *stringFormat = @"%i";
            if ([itemControls objectForKey:@"formatlabel"] != nil){
                stringFormat = [NSString stringWithFormat:@"%@", [itemControls objectForKey:@"formatlabel"]];
            }
            [sliderLabel setText:[NSString stringWithFormat:stringFormat, (int)storeSliderValue]];
        }
    }
    scrubbingRate.text = NSLocalizedString(([NSString stringWithFormat:@"Scrubbing %@",[NSNumber numberWithFloat:slider.scrubbingSpeed]]), nil);
}

#pragma mark UISwitch

- (void)toggleSwitch:(id)sender {
    UISwitch *onoff = (UISwitch *)sender;
    NSString *command = @"Settings.SetSettingValue";
    [self.detailItem setObject:[NSNumber numberWithBool:onoff.on] forKey:@"value"];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: [self.detailItem objectForKey:@"id"], @"setting", [self.detailItem objectForKey:@"value"], @"value", nil];
    [self xbmcAction:command params:params uiControl:sender];
}

#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    NSString *command = @"Settings.SetSettingValue";
    [self.detailItem setObject:[NSString stringWithFormat:@"%@", textField.text] forKey:@"value"];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: [self.detailItem objectForKey:@"id"], @"setting", [self.detailItem objectForKey:@"value"], @"value", nil];
    [self xbmcAction:command params:params uiControl:textField];
    return YES;
}

- (void)handleTap:(id)sender {
    [self.view endEditing:YES];
}

#pragma mark - LifeCycle

- (void)dismissAddAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^ {
    }];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self presentingViewController] != nil) {
        UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissAddAction:)];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
    [_tableView setSeparatorInset:UIEdgeInsetsMake(0, cellLabelOffset, 0, 0)];
    UIEdgeInsets tableViewInsets = UIEdgeInsetsZero;
    tableViewInsets.top = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    _tableView.contentInset = tableViewInsets;
    _tableView.scrollIndicatorInsets = tableViewInsets;
    [_tableView setContentOffset:CGPointMake(0, - tableViewInsets.top) animated:NO];
    if (xbmcSetting == cMultiselect) {
        [_tableView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (xbmcSetting == cList){
        [self scrollTableRow:settingOptions];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    footerHeight = -1;
    selectedSetting = nil;
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [tap setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
