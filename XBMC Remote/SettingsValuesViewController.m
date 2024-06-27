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

#define SETTINGS_CELL_LABEL 1
#define SETTINGS_CELL_DESCRIPTION 2
#define SETTINGS_CELL_SLIDER 101
#define SETTINGS_CELL_SLIDER_LABEL 102
#define SETTINGS_CELL_ONOFF_SWITCH 201
#define SETTINGS_CELL_TEXTFIELD 301
#define PADDING_HORIZONTAL 8
#define PADDING_VERTICAL 10
#define LABEL_HEIGHT_DEFAULT 20
#define CELL_HEIGHT_DEFAULT 44
#define TEXTFIELD_HEIGHT 30
#define SLIDER_HEIGHT 20
#define SLIDER_PADDING 14
#define SCRUBBINGVIEW_HEIGHT 44
#define SCRUBBINGTEXT_HEIGHT 18
#define SCRUBBINGTEXT_PADDING 5

@interface SettingsValuesViewController ()

@end

@implementation SettingsValuesViewController

- (id)initWithFrame:(CGRect)frame withItem:(id)item {
    if (self = [super init]) {
		
        self.view.frame = frame;
        
        UIImageView *imageBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"appViewBackground"]];
        imageBackground.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageBackground.frame = frame;
        [self.view addSubview:imageBackground];
        
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityIndicator.color = UIColor.grayColor;
        activityIndicator.center = CGPointMake(frame.size.width / 2, frame.size.height / 2);
        activityIndicator.hidesWhenStopped = YES;
        [self.view addSubview:activityIndicator];

        self.detailItem = item;

        cellHeight = CELL_HEIGHT_DEFAULT;
        
        settingOptions = self.detailItem[@"options"];
        
        if (![settingOptions isKindOfClass:[NSArray class]]) {
            settingOptions = nil;
        }
        itemControls = self.detailItem[@"control"];
        
        xbmcSetting = cDefault;
        
        if ([itemControls[@"format"] isEqualToString:@"boolean"]) {
            xbmcSetting = cSwitch;
        }
        else if ([itemControls[@"multiselect"] boolValue] && ![settingOptions isKindOfClass:[NSArray class]]) {
            xbmcSetting = cMultiselect;
            self.detailItem[@"value"] = [self.detailItem[@"value"] mutableCopy];
        }
        else if ([itemControls[@"format"] isEqualToString:@"addon"]) {
            xbmcSetting = cList;
            _tableView.frame = CGRectMake(self.view.frame.size.width, _tableView.frame.origin.y, _tableView.frame.size.width, _tableView.frame.size.height);
            self.navigationItem.title = self.detailItem[@"label"];
            settingOptions = [NSMutableArray new];
            [self retrieveXBMCData:@"Addons.GetAddons"
                        parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                    self.detailItem[@"addontype"], @"type",
                                    @YES, @"enabled",
                                    @[@"name"], @"properties",
                                    nil]
                           itemKey:@"addons"];
        }
        else if ([itemControls[@"format"] isEqualToString:@"action"] || [itemControls[@"format"] isEqualToString:@"path"]) {
            self.navigationItem.title = self.detailItem[@"label"];
            xbmcSetting = cUnsupported;
        }
        else if ([itemControls[@"type"] isEqualToString:@"spinner"] && settingOptions == nil) {
            xbmcSetting = cSlider;
            storeSliderValue = [self.detailItem[@"value"] intValue];
        }
        else if ([itemControls[@"type"] isEqualToString:@"edit"]) {
            xbmcSetting = cInput;
        }
        else if ([itemControls[@"type"] isEqualToString:@"list"] && settingOptions == nil) {
            xbmcSetting = cSlider;
            storeSliderValue = [self.detailItem[@"value"] intValue];
        }
        else {
            self.navigationItem.title = self.detailItem[@"label"];
            if ([settingOptions isKindOfClass:[NSArray class]]) {
                if (settingOptions.count > 0) {
                    xbmcSetting = cList;
                }
            }
        }
        
        NSString *footerMessage;
        if (xbmcSetting == cUnsupported) {
            footerMessage = LOCALIZED_STR(@"-- WARNING --\nThis kind of setting cannot be configured remotely. Use the XBMC GUI for changing this setting.\nThank you.");
        }
        else if (xbmcSetting == cList || xbmcSetting == cDefault || xbmcSetting == cMultiselect) {
            footerMessage = [NSString stringWithFormat:@"%@", self.detailItem[@"genre"] ?: self.detailItem[@"label"]];
        }
        if (xbmcSetting != cUnsupported) {
            footerMessage = [NSString stringWithFormat:@"%@\xE2\x84\xB9 %@", footerMessage == nil ? @"" : [NSString stringWithFormat:@"%@\n\n", footerMessage], LOCALIZED_STR(@"Tap and hold a setting to add a new button.")];
        }
        
        footerDescription = [[UILabel alloc] initWithFrame:CGRectMake(PADDING_HORIZONTAL,
                                                                      PADDING_VERTICAL,
                                                                      frame.size.width - 2 * PADDING_HORIZONTAL,
                                                                      LABEL_HEIGHT_DEFAULT)];
        footerDescription.backgroundColor = UIColor.clearColor;
        footerDescription.font = [UIFont systemFontOfSize:12];
        footerDescription.numberOfLines = 0;
        footerDescription.textAlignment = NSTextAlignmentCenter;
        footerDescription.textColor = UIColor.whiteColor;
        footerDescription.highlightedTextColor = UIColor.whiteColor;
        footerDescription.text = [footerMessage stringByReplacingOccurrencesOfString:@"[CR]" withString:@"\n"];
        [self setAutomaticLabelHeight:footerDescription];
        
        footerHeight = CGRectGetHeight(footerDescription.frame) + 2 * PADDING_VERTICAL;
        
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
        
        // Let the list end before the safe area. This avoids list items being shown under the footer.
        UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, [Utilities getBottomPadding], 0);
        _tableView.frame = UIEdgeInsetsInsetRect(_tableView.frame, insets);
        
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		_tableView.delegate = self;
		_tableView.dataSource = self;
        _tableView.backgroundColor = UIColor.clearColor;
        if (@available(iOS 15.0, *)) {
            _tableView.sectionHeaderTopPadding = 0;
        }
        self.view.backgroundColor = UIColor.clearColor;
        [self.view addSubview:_tableView];
        
        UILongPressGestureRecognizer *longPressGesture = [UILongPressGestureRecognizer new];
        [longPressGesture addTarget:self action:@selector(handleLongPress:)];
        longPressGesture.delegate = self;
        [_tableView addGestureRecognizer:longPressGesture];
        
        scrubbingView = [[UIView alloc] initWithFrame:CGRectMake(0, 
                                                                 0,
                                                                 frame.size.width,
                                                                 SCRUBBINGVIEW_HEIGHT)];
        scrubbingView.backgroundColor = [Utilities getGrayColor:0 alpha:0.8];
        scrubbingView.alpha = 0.0;
        
        scrubbingMessage = [[UILabel alloc] initWithFrame:CGRectMake(SCRUBBINGTEXT_PADDING,
                                                                     (SCRUBBINGVIEW_HEIGHT - 2 * SCRUBBINGTEXT_HEIGHT) / 2,
                                                                     frame.size.width - 2 * SCRUBBINGTEXT_PADDING,
                                                                     SCRUBBINGTEXT_HEIGHT)];
        scrubbingMessage.backgroundColor = UIColor.clearColor;
        scrubbingMessage.font = [UIFont boldSystemFontOfSize:13];
        scrubbingMessage.adjustsFontSizeToFitWidth = YES;
        scrubbingMessage.minimumScaleFactor = 0.8;
        scrubbingMessage.textColor = UIColor.whiteColor;
        scrubbingMessage.text = LOCALIZED_STR(@"Slide your finger up or down to adjust the scrubbing rate.");
        scrubbingMessage.textAlignment = NSTextAlignmentCenter;
        [scrubbingView addSubview:scrubbingMessage];
        
        scrubbingRate = [[UILabel alloc] initWithFrame:CGRectMake(SCRUBBINGTEXT_PADDING,
                                                                  CGRectGetMaxY(scrubbingMessage.frame),
                                                                  frame.size.width - 2 * SCRUBBINGTEXT_PADDING,
                                                                  SCRUBBINGTEXT_HEIGHT)];
        scrubbingRate.backgroundColor = UIColor.clearColor;
        scrubbingRate.font = [UIFont boldSystemFontOfSize:13];
        scrubbingRate.adjustsFontSizeToFitWidth = YES;
        scrubbingRate.minimumScaleFactor = 0.8;
        scrubbingRate.textColor = UIColor.lightGrayColor;
        scrubbingRate.textAlignment = NSTextAlignmentCenter;
        scrubbingRate.text = LOCALIZED_STR(@"Scrubbing 1");
        [scrubbingView addSubview:scrubbingRate];
        
        [self.view insertSubview:scrubbingView aboveSubview:_tableView];
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
            UIAlertAction *addButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Add button") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self addActionButton:alertView];
                }];
            UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
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
            stringFormat = [self getStringFormatFromItem:itemControls defaultFormat:stringFormat];
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
    NSString *type = self.detailItem[@"year"] ?: @"string";
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
    NSDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.detailItem[@"id"], @"setting", value, @"value", nil];
    NSDictionary *newButton = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                               alertView.textFields[0].text, @"label",
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
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UIInterfaceCustomButtonAdded" object:nil];
    }
}

#pragma mark - JSON

- (void)xbmcAction:(NSString*)action params:(NSDictionary*)params uiControl:(id)sender {
    if ([sender respondsToSelector:@selector(setUserInteractionEnabled:)]) {
        [sender setUserInteractionEnabled:NO];
    }
    [activityIndicator startAnimating];
    [[Utilities getJsonRPC] callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
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
    [[Utilities getJsonRPC] callMethod:method
                        withParameters:params
                          onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
               [activityIndicator stopAnimating];
               if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSDictionary class]]) {
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
                   [Utilities AnimView:_tableView AnimDuration:0.3 Alpha:1.0 XPos:0];
                   [self scrollTableRow:settingOptions];
               }
           }];
    return;
}

#pragma mark - Helper

- (NSString*)getStringFormatFromItem:(id)item defaultFormat:(NSString*)defaultFormat {
    // Workaround!! Before Kodi 18.x an older format ("%i ms") was used. The new format ("{0:d} ms") needs
    // an updated parser. Until this is implemented just display the value itself, without the unit.
    NSString *format = item[@"formatlabel"];
    if (format.length > 0 && AppDelegate.instance.serverVersion < 18) {
        return format;
    }
    return defaultFormat;
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return cellHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numRows = 1;
    if ([settingOptions isKindOfClass:[NSArray class]]) {
        numRows = settingOptions.count;
    }
    return numRows;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	cell.backgroundColor = [Utilities getSystemGray6];
}

- (void)setAutomaticLabelHeight:(UILabel*)label {
    CGRect frame = label.frame;
    frame.size.height = [Utilities getSizeOfLabel:label].height;
    label.frame = frame;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *tableCellIdentifier = @"UITableViewCell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableCellIdentifier];
        UILabel *cellLabel = [[UILabel alloc] initWithFrame:CGRectMake(PADDING_HORIZONTAL,
                                                                       (CELL_HEIGHT_DEFAULT - LABEL_HEIGHT_DEFAULT) / 2,
                                                                       cell.frame.size.width - 2 * PADDING_HORIZONTAL,
                                                                       LABEL_HEIGHT_DEFAULT)];
        cellLabel.tag = SETTINGS_CELL_LABEL;
        cellLabel.font = [UIFont systemFontOfSize:16];
        cellLabel.adjustsFontSizeToFitWidth = YES;
        cellLabel.minimumScaleFactor = 12.0 / 16.0;
        cellLabel.textColor = [Utilities get1stLabelColor];
        cellLabel.highlightedTextColor = [Utilities get1stLabelColor];
        cellLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [cell.contentView addSubview:cellLabel];
        
        UISwitch *onoff = [[UISwitch alloc] initWithFrame:CGRectZero];
        onoff.tag = SETTINGS_CELL_ONOFF_SWITCH;
        onoff.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [onoff addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:onoff];

        UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(PADDING_HORIZONTAL,
                                                                              0,
                                                                              cell.frame.size.width - 2 * PADDING_HORIZONTAL,
                                                                              LABEL_HEIGHT_DEFAULT)];
        descriptionLabel.tag = SETTINGS_CELL_DESCRIPTION;
        descriptionLabel.font = [UIFont systemFontOfSize:14];
        descriptionLabel.adjustsFontSizeToFitWidth = YES;
        descriptionLabel.numberOfLines = 0;
        descriptionLabel.minimumScaleFactor = 12.0 / 14.0;
        descriptionLabel.textColor = [Utilities get2ndLabelColor];
        descriptionLabel.highlightedTextColor = [Utilities get2ndLabelColor];
        descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [cell.contentView addSubview:descriptionLabel];
        
        OBSlider *slider = [[OBSlider alloc] initWithFrame:CGRectMake(SLIDER_PADDING,
                                                                      0,
                                                                      cell.frame.size.width - 2 * SLIDER_PADDING,
                                                                      SLIDER_HEIGHT)];
        [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
        slider.backgroundColor = UIColor.clearColor;
        slider.minimumTrackTintColor = KODI_BLUE_COLOR;
        slider.continuous = YES;
        slider.tag = SETTINGS_CELL_SLIDER;
        slider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [slider addTarget:self action:@selector(stopUpdateSlider:) forControlEvents:UIControlEventEditingDidEnd];
        [slider addTarget:self action:@selector(stopUpdateSlider:) forControlEvents:UIControlEventTouchCancel];
        [slider addTarget:self action:@selector(stopUpdateSlider:) forControlEvents:UIControlEventTouchUpInside];
        [slider addTarget:self action:@selector(stopUpdateSlider:) forControlEvents:UIControlEventTouchUpOutside];
        [slider addTarget:self action:@selector(startUpdateSlider:) forControlEvents:UIControlEventTouchDown];
        [cell.contentView addSubview:slider];
        
        UILabel *uiSliderLabel = [[UILabel alloc] initWithFrame:CGRectMake(SLIDER_PADDING,
                                                                           0,
                                                                           cell.frame.size.width - 2 * SLIDER_PADDING,
                                                                           LABEL_HEIGHT_DEFAULT)];
        uiSliderLabel.tag = SETTINGS_CELL_SLIDER_LABEL;
        uiSliderLabel.textAlignment = NSTextAlignmentCenter;
        uiSliderLabel.font = [UIFont systemFontOfSize:14];
        uiSliderLabel.adjustsFontSizeToFitWidth = YES;
        uiSliderLabel.minimumScaleFactor = 12.0 / 14.0;
        uiSliderLabel.textColor = [Utilities get2ndLabelColor];
        uiSliderLabel.highlightedTextColor = [Utilities get2ndLabelColor];
        uiSliderLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [cell.contentView addSubview:uiSliderLabel];
        
        UITextField *textInputField = [[UITextField alloc] initWithFrame:CGRectMake(SLIDER_PADDING,
                                                                                    0,
                                                                                    cell.frame.size.width - 2 * SLIDER_PADDING,
                                                                                    TEXTFIELD_HEIGHT)];
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
        textInputField.tag = SETTINGS_CELL_TEXTFIELD;
        textInputField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [cell.contentView addSubview:textInputField];
	}
    cell.accessoryType = UITableViewCellAccessoryNone;

    UILabel *cellLabel = (UILabel*)[cell viewWithTag:SETTINGS_CELL_LABEL];
    UILabel *descriptionLabel = (UILabel*)[cell viewWithTag:SETTINGS_CELL_DESCRIPTION];
    UISlider *slider = (UISlider*)[cell viewWithTag:SETTINGS_CELL_SLIDER];
    UILabel *sliderLabel = (UILabel*)[cell viewWithTag:SETTINGS_CELL_SLIDER_LABEL];
    UISwitch *onoff = (UISwitch*)[cell viewWithTag:SETTINGS_CELL_ONOFF_SWITCH];
    UITextField *textInputField = (UITextField*)[cell viewWithTag:SETTINGS_CELL_TEXTFIELD];

    descriptionLabel.hidden = YES;
    slider.hidden = YES;
    sliderLabel.hidden = YES;
    onoff.hidden = YES;
    textInputField.hidden = YES;
    
    NSString *stringFormat = @"%i";
    NSString *descriptionString = [NSString stringWithFormat:@"%@", self.detailItem[@"genre"]];
    descriptionString = [descriptionString stringByReplacingOccurrencesOfString:@"[CR]" withString:@"\n"];
    switch (xbmcSetting) {
        case cSwitch:
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            descriptionLabel.hidden = NO;
            onoff.hidden = NO;
            
            cellLabel.text = [NSString stringWithFormat:@"%@", self.detailItem[@"label"]];
            cellLabel.numberOfLines = 0;
            cellLabel.frame = CGRectMake(PADDING_HORIZONTAL,
                                         PADDING_VERTICAL,
                                         cell.bounds.size.width - onoff.frame.size.width - 3 * PADDING_HORIZONTAL,
                                         LABEL_HEIGHT_DEFAULT);
            [self setAutomaticLabelHeight:cellLabel];
            
            onoff.on = [self.detailItem[@"value"] boolValue];
            onoff.frame = CGRectMake(cell.bounds.size.width - onoff.frame.size.width - PADDING_HORIZONTAL,
                                     (CGRectGetHeight(cellLabel.frame) - CGRectGetHeight(onoff.frame)) / 2 + CGRectGetMinY(cellLabel.frame),
                                     CGRectGetWidth(onoff.frame),
                                     CGRectGetHeight(onoff.frame));
            
            descriptionLabel.text = descriptionString;
            descriptionLabel.frame = CGRectMake(PADDING_HORIZONTAL,
                                                CGRectGetMaxY(cellLabel.frame) + PADDING_VERTICAL,
                                                cell.bounds.size.width - 2 * PADDING_HORIZONTAL,
                                                LABEL_HEIGHT_DEFAULT);
            [self setAutomaticLabelHeight:descriptionLabel];
            
            cellHeight = CGRectGetMaxY(descriptionLabel.frame) + PADDING_VERTICAL;
            break;
            
        case cList:
            cellLabel.text = [NSString stringWithFormat:@"%@", settingOptions[indexPath.row][@"label"]];
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
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            slider.hidden = NO;
            sliderLabel.hidden = NO;
            descriptionLabel.hidden = NO;
            
            cellLabel.textAlignment = NSTextAlignmentCenter;
            cellLabel.text = [NSString stringWithFormat:@"%@", self.detailItem[@"label"]];
            cellLabel.numberOfLines = 0;
            cellLabel.frame = CGRectMake(PADDING_HORIZONTAL,
                                         PADDING_VERTICAL,
                                         cell.bounds.size.width - 2 * PADDING_HORIZONTAL,
                                         LABEL_HEIGHT_DEFAULT);
            [self setAutomaticLabelHeight:cellLabel];
            
            descriptionLabel.textAlignment = NSTextAlignmentCenter;
            descriptionLabel.text = descriptionString;
            descriptionLabel.numberOfLines = 0;
            descriptionLabel.frame = CGRectMake(PADDING_HORIZONTAL,
                                                CGRectGetMaxY(cellLabel.frame) + PADDING_VERTICAL,
                                                cell.bounds.size.width - 2 * PADDING_HORIZONTAL,
                                                LABEL_HEIGHT_DEFAULT);
            [self setAutomaticLabelHeight:descriptionLabel];
            
            stringFormat = [self getStringFormatFromItem:itemControls defaultFormat:stringFormat];
            sliderLabel.text = [NSString stringWithFormat:stringFormat, [self.detailItem[@"value"] intValue]];
            sliderLabel.frame = CGRectMake(CGRectGetMinX(sliderLabel.frame),
                                           CGRectGetMaxY(descriptionLabel.frame) + 2 * PADDING_VERTICAL,
                                           CGRectGetWidth(sliderLabel.frame),
                                           LABEL_HEIGHT_DEFAULT);
            [self setAutomaticLabelHeight:sliderLabel];
            
            slider.minimumValue = [self.detailItem[@"minimum"] intValue];
            slider.maximumValue = [self.detailItem[@"maximum"] intValue];
            slider.value = [self.detailItem[@"value"] intValue];
            slider.frame = CGRectMake(CGRectGetMinX(slider.frame),
                                      CGRectGetMaxY(sliderLabel.frame) + PADDING_VERTICAL,
                                      CGRectGetWidth(slider.frame),
                                      CGRectGetHeight(slider.frame));
            
            cellHeight = CGRectGetMaxY(slider.frame) + 2 * PADDING_VERTICAL;
            break;
            
        case cInput:
            descriptionLabel.hidden = NO;
            textInputField.hidden = NO;
            
            cellLabel.textAlignment = NSTextAlignmentCenter;
            cellLabel.text = [NSString stringWithFormat:@"%@", self.detailItem[@"label"]];
            cellLabel.numberOfLines = 0;
            cellLabel.frame = CGRectMake(PADDING_HORIZONTAL,
                                         PADDING_VERTICAL,
                                         cell.bounds.size.width - 2 * PADDING_HORIZONTAL,
                                         LABEL_HEIGHT_DEFAULT);
            [self setAutomaticLabelHeight:cellLabel];
            
            descriptionLabel.textAlignment = NSTextAlignmentCenter;
            descriptionString = [descriptionString stringByReplacingOccurrencesOfString:@"[B]" withString:@""];
            descriptionString = [descriptionString stringByReplacingOccurrencesOfString:@"[/B]" withString:@""];
            descriptionLabel.text = descriptionString;
            descriptionLabel.numberOfLines = 0;
            descriptionLabel.frame = CGRectMake(PADDING_HORIZONTAL,
                                                CGRectGetMaxY(cellLabel.frame) + PADDING_VERTICAL,
                                                cell.bounds.size.width - 2 * PADDING_HORIZONTAL,
                                                LABEL_HEIGHT_DEFAULT);
            [self setAutomaticLabelHeight:descriptionLabel];
            
            textInputField.text = [NSString stringWithFormat:@"%@", self.detailItem[@"value"]];
            textInputField.frame = CGRectMake(CGRectGetMinX(textInputField.frame),
                                              CGRectGetMaxY(descriptionLabel.frame) + PADDING_VERTICAL,
                                              CGRectGetWidth(textInputField.frame),
                                              CGRectGetHeight(textInputField.frame));
            
            cellHeight = CGRectGetMaxY(textInputField.frame) + PADDING_VERTICAL;
            break;
            
        case cDefault:
        case cMultiselect:
            if (self.detailItem[@"value"] != nil) {
                if ([self.detailItem[@"value"] isKindOfClass:[NSArray class]]) {
                    NSString *delimiter = self.detailItem[@"delimiter"];
                    if (delimiter == nil) {
                        delimiter = @", ";
                    }
                    else {
                        delimiter = [NSString stringWithFormat:@"%@ ", delimiter];
                    }
                    NSArray *settingsArray = self.detailItem[@"value"];
                    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:nil ascending:YES];
                    settingsArray = [settingsArray sortedArrayUsingDescriptors:@[descriptor]];
                    cellLabel.text = [settingsArray componentsJoinedByString:delimiter];
                }
                else {
                    cellLabel.text = [NSString stringWithFormat:@"%@", self.detailItem[@"value"]];
                }
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                
                cellLabel.text = cellLabel.text.length ? cellLabel.text : descriptionString;
                cellLabel.numberOfLines = 0;
                cellLabel.frame = CGRectMake(PADDING_HORIZONTAL,
                                             PADDING_VERTICAL,
                                             cell.bounds.size.width - 2 * PADDING_HORIZONTAL,
                                             LABEL_HEIGHT_DEFAULT);
                [self setAutomaticLabelHeight:cellLabel];
                
                cellHeight = CGRectGetMaxY(cellLabel.frame) + PADDING_VERTICAL;
            }
            break;
            
        case cUnsupported:
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cellLabel.text = descriptionString;
            cellLabel.numberOfLines = 0;
            cellLabel.frame = CGRectMake(PADDING_HORIZONTAL,
                                         PADDING_VERTICAL,
                                         cell.bounds.size.width - 2 * PADDING_HORIZONTAL,
                                         LABEL_HEIGHT_DEFAULT);
            [self setAutomaticLabelHeight:cellLabel];
            
            cellHeight = CGRectGetMaxY(cellLabel.frame) + PADDING_VERTICAL;
            break;
            
        default:
            if (self.detailItem[@"value"] != nil) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                
                cellLabel.text = [NSString stringWithFormat:@"%@", self.detailItem[@"value"]];
                cellLabel.text = cellLabel.text.length ? cellLabel.text : descriptionString;
                cellLabel.numberOfLines = 0;
                cellLabel.frame = CGRectMake(PADDING_HORIZONTAL,
                                             PADDING_VERTICAL,
                                             cell.bounds.size.width - 2 * PADDING_HORIZONTAL,
                                             LABEL_HEIGHT_DEFAULT);
                [self setAutomaticLabelHeight:cellLabel];
                
                cellHeight = CGRectGetMaxY(cellLabel.frame) + PADDING_VERTICAL;
            }
            break;
    }
    return cell;
}

#pragma mark - Table view delegate

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
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    [self.detailItem[@"value"] addObject:settingOptions[indexPath.row][@"value"]];
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    [self.detailItem[@"value"] removeObject:settingOptions[indexPath.row][@"value"]];
                }
            }
            else {
                if (selectedSetting == nil) {
                    selectedSetting = [self getCurrentSelectedOption:settingOptions];
                }
                if (selectedSetting != nil) {
                    cell = [tableView cellForRowAtIndexPath:selectedSetting];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
                cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                selectedSetting = indexPath;
                self.detailItem[@"value"] = settingOptions[selectedSetting.row][@"value"];
            }
            command = @"Settings.SetSettingValue";
            params = [NSDictionary dictionaryWithObjectsAndKeys:self.detailItem[@"id"], @"setting", self.detailItem[@"value"], @"value", nil];
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
                    [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:settingsViewController invokeByController:self isStackStartView:NO];
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
    sectionView.backgroundColor = [Utilities getGrayColor:102 alpha:1];
    return sectionView;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    UIView *helpView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, footerHeight)];
    if (xbmcSetting == cUnsupported) {
        helpView.backgroundColor = [Utilities getSystemRed:0.95];
    }
    else {
        helpView.backgroundColor = TOOLBAR_TINT_COLOR;
    }
    [helpView addSubview:footerDescription];
    return helpView;
}

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
    return footerHeight;
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
        [_tableView scrollToRowAtIndexPath:optionIndex atScrollPosition:UITableViewScrollPositionMiddle animated:!fromItself];
    }
}

#pragma mark - UISlider

- (void)startUpdateSlider:(id)sender {
    scrubbingView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    [Utilities alphaView:scrubbingView AnimDuration:0.3 Alpha:1.0];
}

- (void)stopUpdateSlider:(id)sender {
    [Utilities alphaView:scrubbingView AnimDuration:0.3 Alpha:0.0];
    NSString *command = @"Settings.SetSettingValue";
    self.detailItem[@"value"] = @(storeSliderValue);
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:self.detailItem[@"id"], @"setting", self.detailItem[@"value"], @"value", nil];
    [self xbmcAction:command params:params uiControl:sender];
}

- (void)sliderAction:(OBSlider*)slider {
    float newStep = roundf(slider.value / [self.detailItem[@"step"] intValue]);
    float newValue = newStep * [self.detailItem[@"step"] intValue];
    if (!FLOAT_EQUAL_ZERO(newValue - storeSliderValue)) {
        storeSliderValue = newValue;
        UILabel *sliderLabel = [[slider superview] viewWithTag:SETTINGS_CELL_SLIDER_LABEL];
        if (sliderLabel) {
            NSString *stringFormat = @"%i";
            stringFormat = [self getStringFormatFromItem:itemControls defaultFormat:stringFormat];
            sliderLabel.text = [NSString stringWithFormat:stringFormat, (int)storeSliderValue];
        }
    }
    scrubbingRate.text = LOCALIZED_STR(([NSString stringWithFormat:@"Scrubbing %@", @(slider.scrubbingSpeed)]));
}

#pragma mark - UISwitch

- (void)toggleSwitch:(id)sender {
    UISwitch *onoff = (UISwitch*)sender;
    NSString *command = @"Settings.SetSettingValue";
    self.detailItem[@"value"] = @(onoff.on);
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:self.detailItem[@"id"], @"setting", self.detailItem[@"value"], @"value", nil];
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
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:self.detailItem[@"id"], @"setting", self.detailItem[@"value"], @"value", nil];
    [self xbmcAction:command params:params uiControl:textField];
    return YES;
}

- (void)handleTap:(id)sender {
    [self.view endEditing:YES];
}

#pragma mark - LifeCycle

- (void)dismissAddAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    fromItself = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self presentingViewController] != nil) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissAddAction:)];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
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
    fromItself = NO;
    footerHeight = -1;
    selectedSetting = nil;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
    
    messagesView = [[MessagesView alloc] initWithFrame:CGRectZero deltaY:0 deltaX:0];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat deltaY = 0;
    CGRect frame = UIScreen.mainScreen.bounds;
    if (IS_IPAD) {
        frame.size.width = STACKSCROLL_WIDTH;
    }
    else {
        deltaY = [Utilities getTopPaddingWithNavBar:self.navigationController];
    }
    
    [messagesView updateWithFrame:CGRectMake(0, 0, frame.size.width, deltaY + DEFAULT_MSG_HEIGHT) deltaY:deltaY deltaX:0];
    [self.view addSubview:messagesView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
