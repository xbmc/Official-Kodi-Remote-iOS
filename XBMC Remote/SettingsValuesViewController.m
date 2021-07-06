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
#import "Utilities.h"

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

        cellHeight = 44.0;
        
        settingOptions = self.detailItem[@"options"];
        
//        if (![settingOptions isKindOfClass:[NSArray class]]) {
//            if ([self.detailItem[@"definition"] isKindOfClass:[NSDictionary class]]) {
//                settingOptions = self.detailItem[@"definition"][@"options"];
//            }
//        }
        
        if (![settingOptions isKindOfClass:[NSArray class]]) {
            settingOptions = nil;
        }
        itemControls = self.detailItem[@"control"];
        
        xbmcSetting = cDefault;
        
        if ([itemControls[@"format"] isEqualToString:@"boolean"]) {
            xbmcSetting = cSwitch;
            cellHeight = 210.0;
        }
        else if ([itemControls[@"multiselect"] boolValue] && ![settingOptions isKindOfClass:[NSArray class]]) {
            xbmcSetting = cMultiselect;
            self.detailItem[@"value"] = [self.detailItem[@"value"] mutableCopy];
        }
        else if ([itemControls[@"format"] isEqualToString:@"addon"]) {
            xbmcSetting = cList;
            cellHeight = 44;
            [_tableView setFrame:CGRectMake(self.view.frame.size.width, _tableView.frame.origin.y, _tableView.frame.size.width, _tableView.frame.size.height)];
            self.navigationItem.title = self.detailItem[@"label"];
            settingOptions = [NSMutableArray new];
            [self retrieveXBMCData: @"Addons.GetAddons"
                        parameters: [NSDictionary dictionaryWithObjectsAndKeys:
                                     self.detailItem[@"addontype"], @"type",
                                     @(YES), @"enabled",
                                     @[@"name"], @"properties",
                                     nil]
                           itemKey: @"addons"];
        }
        else if ([itemControls[@"format"] isEqualToString:@"action"] || [itemControls[@"format"] isEqualToString:@"path"]) {
            self.navigationItem.title = self.detailItem[@"label"];
            xbmcSetting = cUnsupported;
            cellHeight = 142.0;
        }
        else if ([itemControls[@"type"] isEqualToString:@"spinner"] && settingOptions == nil) {
            xbmcSetting = cSlider;
            storeSliderValue = [self.detailItem[@"value"] intValue];
            cellHeight = 184.0;
        }
        else if ([itemControls[@"type"] isEqualToString:@"edit"]) {
            xbmcSetting = cInput;
            cellHeight = 172.0;
        }
        else if ([itemControls[@"type"] isEqualToString:@"list"] && settingOptions == nil) {
            xbmcSetting = cSlider;
            storeSliderValue = [self.detailItem[@"value"] intValue];
            cellHeight = 184.0;
        }
        else {
            self.navigationItem.title = self.detailItem[@"label"];
            if ([settingOptions isKindOfClass:[NSArray class]]) {
                if ([settingOptions count] > 0) {
                    xbmcSetting = cList;
                }
            }
        }
        if (xbmcSetting == cUnsupported) {
            footerMessage = LOCALIZED_STR(@"-- WARNING --\nThis kind of setting cannot be configured remotely. Use the XBMC GUI for changing this setting.\nThank you.");
        }
        else if (xbmcSetting == cList || xbmcSetting == cDefault || xbmcSetting == cMultiselect) {
            footerMessage = [NSString stringWithFormat:@"%@", self.detailItem[@"genre"] == nil ? self.detailItem[@"label"] : self.detailItem[@"genre"]];
        }
        if (xbmcSetting != cUnsupported) {
            footerMessage = [NSString stringWithFormat:@"%@\xE2\x84\xB9 %@", footerMessage == nil ? @"" : [NSString stringWithFormat:@"%@\n\n", footerMessage], LOCALIZED_STR(@"Tap and hold a setting to add a new button.")];
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
        
        CGFloat deltaY = 0;
        CGRect frame = [[UIScreen mainScreen] bounds];
        if (IS_IPAD) {
            frame.size.width = STACKSCROLL_WIDTH;
        }
        else {
            deltaY = 44 + CGRectGetHeight(UIApplication.sharedApplication.statusBarFrame);
        }
        
        scrubbingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 44)];
        [scrubbingView setCenter:CGPointMake((int)(frame.size.width / 2), (int)(frame.size.height / 2) + 50)];
        [scrubbingView setBackgroundColor:[Utilities getGrayColor:0 alpha:0.9]];
        scrubbingView.alpha = 0.0;
        CGRect toolbarShadowFrame = CGRectMake(0, 44, self.view.frame.size.width, 4);
        UIImageView *toolbarShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
        [toolbarShadow setImage:[UIImage imageNamed:@"tableUp"]];
        toolbarShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbarShadow.contentMode = UIViewContentModeScaleToFill;
        toolbarShadow.opaque = YES;
        [scrubbingView addSubview:toolbarShadow];
        toolbarShadowFrame.origin.y = -4;
        UIImageView *toolbarUpShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
        [toolbarUpShadow setImage:[UIImage imageNamed:@"tableDown"]];
        toolbarUpShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbarUpShadow.contentMode = UIViewContentModeScaleToFill;
        toolbarUpShadow.opaque = YES;
        [scrubbingView addSubview:toolbarUpShadow];
        
        scrubbingMessage = [[UILabel alloc] initWithFrame:CGRectMake(5, 3, frame.size.width - 10, 18)];
        [scrubbingMessage setBackgroundColor:[UIColor clearColor]];
        [scrubbingMessage setFont:[UIFont boldSystemFontOfSize:13]];
        [scrubbingMessage setAdjustsFontSizeToFitWidth:YES];
        [scrubbingMessage setMinimumScaleFactor:10.0/13.0];
        [scrubbingMessage setTextColor:[UIColor whiteColor]];
        [scrubbingMessage setText:LOCALIZED_STR(@"Slide your finger up or down to adjust the scrubbing rate.")];
        [scrubbingMessage setTextAlignment:NSTextAlignmentCenter];
        [scrubbingView addSubview:scrubbingMessage];
        
        scrubbingRate = [[UILabel alloc] initWithFrame:CGRectMake(5, 21, frame.size.width - 10, 18)];
        [scrubbingRate setBackgroundColor:[UIColor clearColor]];
        [scrubbingRate setFont:[UIFont boldSystemFontOfSize:13]];
        [scrubbingRate setTextColor:[UIColor grayColor]];
        [scrubbingRate setTextAlignment:NSTextAlignmentCenter];
        [scrubbingRate setText:LOCALIZED_STR(@"Scrubbing 1")];
        [scrubbingView addSubview:scrubbingRate];
        
        [self.view insertSubview:scrubbingView aboveSubview:_tableView];

        messagesView = [[MessagesView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, deltaY + DEFAULT_MSG_HEIGHT) deltaY:deltaY deltaX:0];
        [self.view addSubview:messagesView];
	}
    return self;
}

#pragma mark - Gesture Recognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch {
    if ([touch.view isKindOfClass:[OBSlider class]] || [touch.view isKindOfClass:[UISwitch class]] || [touch.view isKindOfClass:NSClassFromString(@"_UISwitchInternalView")]) {
        return NO;
    }
    return YES;
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint p = [gestureRecognizer locationInView:_tableView];
        NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:p];
        if (indexPath != nil) {
            longPressRow = indexPath;

            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:LOCALIZED_STR(@"Add a new button") message:LOCALIZED_STR(@"Enter the label:") preferredStyle:UIAlertControllerStyleAlert];
            [alertView addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.placeholder = @"";
                textField.text = [self getActionButtonTitle];
            }];
            UIAlertAction* addButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Add button") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                    [self addActionButton:alertView];
                }];
            UIAlertAction* cancelButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];
            [alertView addAction:addButton];
            [alertView addAction:cancelButton];
            [self presentViewController:alertView animated:YES completion:nil];
        }
    }
}

- (NSString*)getActionButtonTitle {
    NSString *subTitle = @"";
    NSString *stringFormat = @": %i";
    switch (xbmcSetting) {
        case cList:
            subTitle = [NSString stringWithFormat:@": %@", settingOptions[longPressRow.row][@"label"]];
            break;
        case cSlider:
            if (itemControls[@"formatlabel"] != nil) {
                stringFormat = [NSString stringWithFormat:@": %@", itemControls[@"formatlabel"]];
            }
            subTitle = [NSString stringWithFormat:stringFormat, (int)storeSliderValue];
            break;
        case cUnsupported:
            return nil;
        default:
            break;
    }
    return [NSString stringWithFormat:@"%@%@", self.detailItem[@"label"], subTitle];
}

- (void)addActionButton:(UIAlertController*)alertView {
    NSString *command = @"Settings.SetSettingValue";
    id value = @"";
    NSString *type = @"string";
    if (self.detailItem[@"year"] != nil) {
        type = self.detailItem[@"year"];
    }
    switch (xbmcSetting) {
        case cList:
            if ([type isEqualToString:@"integer"]) {
                value = @([settingOptions[longPressRow.row][@"value"] intValue]);
            }
            else {
                value = [NSString stringWithFormat:@"%@", settingOptions[longPressRow.row][@"value"]];
            }
            break;
        case cSlider:
            value = @(storeSliderValue);
            break;
        default:
            value = @"";
            break;
    }
    NSDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys: self.detailItem[@"id"], @"setting", value, @"value", nil];
    NSDictionary *newButton = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                               [[alertView textFields][0] text], @"label",
                               type, @"type",
                               @"default-right-menu-icon", @"icon",
                               @(xbmcSetting), @"xbmcSetting",
                               self.detailItem[@"genre"], @"helpText",
                               [NSDictionary dictionaryWithObjectsAndKeys:
                                command, @"command",
                                params, @"params",
                                nil], @"action",
                               nil];
    [self saveCustomButton:newButton];
}

#pragma mark - custom button

- (void)saveCustomButton:(NSDictionary*)button {
    customButton *arrayButtons = [customButton new];
    [arrayButtons.buttons addObject:button];
    [arrayButtons saveData];
    [messagesView showMessage:LOCALIZED_STR(@"Button added") timeout:2.0 color:[Utilities getSystemGreen:0.95]];
    if (IS_IPAD) {
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UIInterfaceCustomButtonAdded" object: nil];
    }
}

#pragma mark - JSON

- (void)xbmcAction:(NSString*)action params:(NSDictionary*)params uiControl:(id)sender {
    if ([sender respondsToSelector:@selector(setUserInteractionEnabled:)]) {
        [sender setUserInteractionEnabled:NO];
    }
    [activityIndicator startAnimating];
    [[Utilities getJsonRPC] callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        [activityIndicator stopAnimating];
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

- (void)retrieveXBMCData:(NSString*)method parameters:(NSDictionary*)params itemKey:(NSString*)itemkey {
    
    [activityIndicator startAnimating];
    [[Utilities getJsonRPC] callMethod: method
         withParameters: params
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               [activityIndicator stopAnimating];
               if (error == nil && methodError == nil) {
                   NSSortDescriptor *descriptor = [[NSSortDescriptor alloc]
                                                   initWithKey:@"name"
                                                   ascending:YES
                                                   selector:@selector(localizedCaseInsensitiveCompare:)];
                   NSArray *retrievedItems = [methodResult[itemkey] sortedArrayUsingDescriptors:@[descriptor]];
                   for (NSDictionary *item in retrievedItems) {
                       [settingOptions addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                  item[@"name"], @"label",
                                                  item[@"addonid"], @"value",
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

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return cellHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numRows = 1;
    if ([settingOptions isKindOfClass:[NSArray class]]) {
        numRows = [settingOptions count];
    }
    return numRows;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	cell.backgroundColor = [Utilities getSystemGray6];
}

- (void)adjustFontSize:(UILabel*)label {
    CGRect descriptionRect;
    BOOL done = NO;
    CGFloat startSize = label.font.pointSize - 1;
    CGFloat endSize = startSize - 2;
    while (!done && startSize >= endSize) {
        descriptionRect = [label.text  boundingRectWithSize:CGSizeMake(label.bounds.size.width, NSIntegerMax)
                                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                                 attributes:@{NSFontAttributeName:label.font}
                                                                    context:nil];
        CGSize descriptionSize = descriptionRect.size;
        if (descriptionSize.height > label.bounds.size.height) {
            [label setFont:[UIFont systemFontOfSize:startSize]];
        }
        else {
            done = YES;
        }
        startSize --;
    }
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *tableCellIdentifier = @"UITableViewCell";
	UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableCellIdentifier];
        UILabel *cellLabel = [[UILabel alloc] initWithFrame:CGRectMake(cellLabelOffset, cellHeight/2 - 11, self.view.bounds.size.width - cellLabelOffset - 38, 22)];
        cellLabel.tag = 1;
        [cellLabel setFont:[UIFont systemFontOfSize:18]];
        [cellLabel setAdjustsFontSizeToFitWidth:YES];
        [cellLabel setMinimumScaleFactor:12.0/18.0];
        [cellLabel setTextColor:[Utilities get1stLabelColor]];
        [cellLabel setHighlightedTextColor:[Utilities get1stLabelColor]];
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
        [descriptionLabel setMinimumScaleFactor:11.0/12.0];
        [descriptionLabel setTextColor:[Utilities get2ndLabelColor]];
        [descriptionLabel setHighlightedTextColor:[Utilities get2ndLabelColor]];
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
        [uiSliderLabel setMinimumScaleFactor:12.0/14.0];
        [uiSliderLabel setTextColor:[Utilities get2ndLabelColor]];
        [uiSliderLabel setHighlightedTextColor:[Utilities get2ndLabelColor]];
        [cell.contentView addSubview:uiSliderLabel];
        
        UITextField *textInputField = [[UITextField alloc] initWithFrame:CGRectMake(14, cellHeight - 20 - 20, cell.frame.size.width - 14 * 2, 30)];
        [textInputField setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        textInputField.borderStyle = UITextBorderStyleRoundedRect;
        textInputField.textAlignment = NSTextAlignmentCenter;
        textInputField.font = [UIFont systemFontOfSize:15];
        textInputField.placeholder = LOCALIZED_STR(@"enter value");
        textInputField.autocorrectionType = UITextAutocorrectionTypeNo;
        textInputField.keyboardType = UIKeyboardTypeDefault;
        textInputField.returnKeyType = UIReturnKeyDefault;
        textInputField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textInputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        textInputField.delegate = self;
        textInputField.tag = 301;
        [cell.contentView addSubview:textInputField];
        [cellLabel setHighlightedTextColor:[Utilities get1stLabelColor]];
        [descriptionLabel setHighlightedTextColor:[Utilities get2ndLabelColor]];
        [uiSliderLabel setHighlightedTextColor:[Utilities get2ndLabelColor]];
	}
    cell.accessoryType = UITableViewCellAccessoryNone;

    UILabel *cellLabel = (UILabel*)[cell viewWithTag:1];
    UILabel *descriptionLabel = (UILabel*)[cell viewWithTag:2];
    UISlider *slider = (UISlider*)[cell viewWithTag:101];
    UILabel *sliderLabel = (UILabel*)[cell viewWithTag:102];
    UISwitch *onoff = (UISwitch*)[cell viewWithTag:201];
    UITextField *textInputField = (UITextField*)[cell viewWithTag:301];

    descriptionLabel.hidden = YES;
    slider.hidden = YES;
    sliderLabel.hidden = YES;
    onoff.hidden = YES;
    textInputField.hidden = YES;
    
    NSString *cellText = @"";
    NSString *stringFormat = @"%i";
    NSString *descriptionString = [NSString stringWithFormat:@"%@", self.detailItem[@"genre"]];
    descriptionString = [descriptionString stringByReplacingOccurrencesOfString:@"[CR]" withString:@"\n"];
    switch (xbmcSetting) {
            
        case cSwitch:
    
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            descriptionLabel.hidden = NO;
            cellText = [NSString stringWithFormat:@"%@", self.detailItem[@"label"]];
            [cellLabel setFrame:CGRectMake(cellLabelOffset, 8, self.view.bounds.size.width - onoff.frame.size.width - cellLabelOffset * 3, 44)];
            [cellLabel setNumberOfLines:2];
            [descriptionLabel setText:descriptionString];
            [self adjustFontSize:descriptionLabel];
            onoff.hidden = NO;
            onoff.on = [self.detailItem[@"value"] boolValue];
            break;
            
        case cList:
            
            cellText = [NSString stringWithFormat:@"%@", settingOptions[indexPath.row][@"label"]];
            if ([self.detailItem[@"value"] isKindOfClass:[NSArray class]]) {
                if ([self.detailItem[@"value"] containsObject:settingOptions[indexPath.row][@"value"]]) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
            }
            else if ([settingOptions[indexPath.row][@"value"] isEqual:self.detailItem[@"value"]]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
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
            cellText = [NSString stringWithFormat:@"%@", self.detailItem[@"label"]];
            
            [descriptionLabel setFrame:CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y + 2, self.view.bounds.size.width - (cellLabelOffset * 2), 58)];
            [descriptionLabel setTextAlignment:NSTextAlignmentCenter];
            [descriptionLabel setNumberOfLines:4];
            [descriptionLabel setText: [NSString stringWithFormat:@"%@", self.detailItem[@"genre"]]];
            slider.minimumValue = [self.detailItem[@"minimum"] intValue];
            slider.maximumValue = [self.detailItem[@"maximum"] intValue];
            slider.value = [self.detailItem[@"value"] intValue];
            if (itemControls[@"formatlabel"] != nil) {
                stringFormat = [NSString stringWithFormat:@"%@", itemControls[@"formatlabel"]];
            }
            [sliderLabel setText:[NSString stringWithFormat:stringFormat, [self.detailItem[@"value"] intValue]]];
            break;
            
        case cInput:
            
            descriptionLabel.hidden = NO;
            textInputField.hidden = NO;
            [cellLabel setFrame:CGRectMake(cellLabelOffset, 8, self.view.bounds.size.width - (cellLabelOffset * 2), 46)];
            [cellLabel setNumberOfLines:2];
            [cellLabel setTextAlignment:NSTextAlignmentCenter];
            cellText = [NSString stringWithFormat:@"%@", self.detailItem[@"label"]];
            
            [descriptionLabel setFrame:CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y + 2, self.view.bounds.size.width - (cellLabelOffset * 2), 74)];
            [descriptionLabel setTextAlignment:NSTextAlignmentCenter];
            [descriptionLabel setNumberOfLines:5];
            descriptionString = [descriptionString stringByReplacingOccurrencesOfString:@"[B]" withString:@""];
            descriptionString = [descriptionString stringByReplacingOccurrencesOfString:@"[/B]" withString:@""];
            [descriptionLabel setText: descriptionString];
            [self adjustFontSize:descriptionLabel];
            [textInputField setText:[NSString stringWithFormat:@"%@", self.detailItem[@"value"]]];
            break;
            
        case cDefault | cMultiselect:
            
            if (self.detailItem[@"value"] != nil) {
                if ([self.detailItem[@"value"] isKindOfClass:[NSArray class]]) {
                    NSString *delimiter = self.detailItem[@"delimiter"];
                    if (delimiter == nil) {
                        delimiter = @", ";
                    }
                    else {
                        delimiter = [NSString stringWithFormat:@"%@ ", delimiter];
                    }
                    cellText = [self.detailItem[@"value"] componentsJoinedByString:delimiter];
                }
                else {
                    cellText = [NSString stringWithFormat:@"%@", self.detailItem[@"value"]];
                }
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            break;
            
        case cUnsupported:
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [cellLabel setFrame:CGRectMake(cellLabelOffset, 8, self.view.bounds.size.width - cellLabelOffset * 2, cellHeight - 8)];
            [cellLabel setNumberOfLines:10];
            cellText = [NSString stringWithFormat:@"%@", self.detailItem[@"genre"]];
            break;
            
        default:
            if (self.detailItem[@"value"] != nil) {
                cellText = [NSString stringWithFormat:@"%@", self.detailItem[@"value"]];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            break;
    }

    if ([cellText isEqualToString:@""] || cellText == nil) {
        cellText = [NSString stringWithFormat:@"%@", self.detailItem[@"genre"]];
    }

    [cellLabel setText:cellText];

    return cell;
}

#pragma mark Table view delegate

- (void)AnimTable:(UITableView*)tV AnimDuration:(NSTimeInterval)seconds Alpha:(CGFloat)alphavalue XPos:(int)X {
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

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = nil;
    NSString *command = nil;
    NSDictionary *params = nil;
    switch (xbmcSetting) {
        case cList:
            if ([self.detailItem[@"value"] isKindOfClass:[NSArray class]]) {
                cell = [tableView cellForRowAtIndexPath:indexPath];
                if (cell.accessoryType == UITableViewCellAccessoryNone) {
                    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                    [self.detailItem[@"value"] addObject:settingOptions[indexPath.row][@"value"]];
                }
                else {
                    [cell setAccessoryType:UITableViewCellAccessoryNone];
                    [self.detailItem[@"value"] removeObject:settingOptions[indexPath.row][@"value"]];
                }
            }
            else {
                if (selectedSetting == nil) {
                    selectedSetting = [self getCurrentSelectedOption:settingOptions];
                }
                if (selectedSetting != nil) {
                    cell = [tableView cellForRowAtIndexPath:selectedSetting];
                    [cell setAccessoryType:UITableViewCellAccessoryNone];
                }
                cell = [tableView cellForRowAtIndexPath:indexPath];
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                selectedSetting = indexPath;
                self.detailItem[@"value"] = settingOptions[selectedSetting.row][@"value"];
            }
            command = @"Settings.SetSettingValue";
            params = [NSDictionary dictionaryWithObjectsAndKeys: self.detailItem[@"id"], @"setting", self.detailItem[@"value"], @"value", nil];
            [self xbmcAction:command params:params uiControl:_tableView];

            break;
        case cMultiselect:
            if ([self.detailItem[@"definition"] isKindOfClass:[NSDictionary class]]) {
                self.detailItem[@"definition"][@"value"] = self.detailItem[@"value"];
                self.detailItem[@"definition"][@"id"] = self.detailItem[@"id"];
                SettingsValuesViewController *settingsViewController = [[SettingsValuesViewController alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) withItem:self.detailItem[@"definition"]];
                if (IS_IPHONE) {
                    [self.navigationController pushViewController:settingsViewController animated:YES];
                }
                else {
                    [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:settingsViewController invokeByController:self isStackStartView:NO];
                }
            }
            break;
        default:
            selectedSetting = indexPath;
            break;
    }
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    NSInteger viewWidth = self.view.frame.size.width;
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, 1)];
    [sectionView setBackgroundColor:[Utilities getGrayColor:102 alpha:1]];
    CGRect toolbarShadowFrame = CGRectMake(0, 1, viewWidth, 4);
    UIImageView *toolbarShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
    [toolbarShadow setImage:[UIImage imageNamed:@"tableUp"]];
    toolbarShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    toolbarShadow.contentMode = UIViewContentModeScaleToFill;
    toolbarShadow.opaque = YES;
    toolbarShadow.alpha = 0.3;
    [sectionView addSubview:toolbarShadow];
    return sectionView;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    return 1;
}

- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
//    if (xbmcSetting == cList || xbmcSetting == cDefault || xbmcSetting == cUnsupported || xbmcSetting == cMultiselect) {
    UIView *helpView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, footerHeight)];
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(cellLabelOffset, cellLabelOffset, self.view.bounds.size.width - cellLabelOffset * 2, 50)];
    [descriptionLabel setFont:[UIFont systemFontOfSize:12]];
    [descriptionLabel setBackgroundColor:[UIColor clearColor]];
    [descriptionLabel setNumberOfLines:20];
    [descriptionLabel setTextColor:[UIColor whiteColor]];
    [descriptionLabel setTextAlignment:NSTextAlignmentCenter];
    [descriptionLabel setHighlightedTextColor:[UIColor whiteColor]];
    [descriptionLabel setText:[footerMessage stringByReplacingOccurrencesOfString:@"[CR]" withString:@"\n"]];
    if (xbmcSetting == cUnsupported) {
        [helpView setBackgroundColor:[Utilities getSystemRed:1.0]];
    }
    else {
        [helpView setBackgroundColor:[Utilities getGrayColor:45 alpha:0.95]];
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

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
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
- (NSIndexPath*)getCurrentSelectedOption:(NSArray*)optionList {
    NSIndexPath *foundIndex = nil;
    NSUInteger index = [optionList indexOfObjectPassingTest:
                        ^BOOL(NSDictionary *dict, NSUInteger idx, BOOL *stop) {
                            return [dict[@"value"] isEqual:self.detailItem[@"value"]];
                        }];
    if (index != NSNotFound) {
        foundIndex = [NSIndexPath indexPathForRow:index inSection:0];
        selectedSetting = foundIndex;
    }
    return foundIndex;
}

- (void)scrollTableRow:(NSArray*)list {
    NSIndexPath *optionIndex = [self getCurrentSelectedOption:list];
    if (optionIndex != nil) {
        [_tableView scrollToRowAtIndexPath:optionIndex atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        
    }
}

#pragma mark - UISlider

- (void)changeAlphaView:(UIView*)view alpha:(CGFloat)value time:(NSTimeInterval)sec {
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:sec];
	view.alpha = value;
    [UIView commitAnimations];
}

- (void)startUpdateSlider:(id)sender {
    [self changeAlphaView:scrubbingView alpha:1.0 time:0.3];
}

- (void)stopUpdateSlider:(id)sender {
    [self changeAlphaView:scrubbingView alpha:0.0 time:0.3];
    NSString *command = @"Settings.SetSettingValue";
    self.detailItem[@"value"] = @(storeSliderValue);
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: self.detailItem[@"id"], @"setting", self.detailItem[@"value"], @"value", nil];
    [self xbmcAction:command params:params uiControl:sender];
}

- (void)sliderAction:(id)sender {
    OBSlider *slider = (OBSlider*)sender;
    float newStep = roundf((slider.value) / [self.detailItem[@"step"] intValue]);
    float newValue = newStep * [self.detailItem[@"step"] intValue];
    if (newValue != storeSliderValue) {
        storeSliderValue = newValue;
        if ([[[slider superview] viewWithTag:102] isKindOfClass:[UILabel class]]) {
            UILabel *sliderLabel = (UILabel*)[[slider superview] viewWithTag:102];
            NSString *stringFormat = @"%i";
            if (itemControls[@"formatlabel"] != nil) {
                stringFormat = [NSString stringWithFormat:@"%@", itemControls[@"formatlabel"]];
            }
            [sliderLabel setText:[NSString stringWithFormat:stringFormat, (int)storeSliderValue]];
        }
    }
    scrubbingRate.text = LOCALIZED_STR(([NSString stringWithFormat:@"Scrubbing %@", @(slider.scrubbingSpeed)]));
}

#pragma mark UISwitch

- (void)toggleSwitch:(id)sender {
    UISwitch *onoff = (UISwitch*)sender;
    NSString *command = @"Settings.SetSettingValue";
    self.detailItem[@"value"] = @(onoff.on);
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: self.detailItem[@"id"], @"setting", self.detailItem[@"value"], @"value", nil];
    [self xbmcAction:command params:params uiControl:sender];
}

#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField {
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField*)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    [textField resignFirstResponder];
    NSString *command = @"Settings.SetSettingValue";
    self.detailItem[@"value"] = [NSString stringWithFormat:@"%@", textField.text];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: self.detailItem[@"id"], @"setting", self.detailItem[@"value"], @"value", nil];
    [self xbmcAction:command params:params uiControl:textField];
    return YES;
}

- (void)handleTap:(id)sender {
    [self.view endEditing:YES];
}

#pragma mark - LifeCycle

- (void)dismissAddAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self presentingViewController] != nil) {
        UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissAddAction:)];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
    [_tableView setSeparatorInset:UIEdgeInsetsMake(0, cellLabelOffset, 0, 0)];
    UIEdgeInsets tableViewInsets = UIEdgeInsetsZero;
    tableViewInsets.top = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    if (@available(iOS 11.0, *)) {
        tableViewInsets.top = 0;
    }
    _tableView.contentInset = tableViewInsets;
    _tableView.scrollIndicatorInsets = tableViewInsets;
    [_tableView setContentOffset:CGPointMake(0, - tableViewInsets.top) animated:NO];
    if (xbmcSetting == cMultiselect) {
        [_tableView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (xbmcSetting == cList) {
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
