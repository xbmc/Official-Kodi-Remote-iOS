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

#include "convert_fmt.hpp"

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
        
        xbmcSetting = SettingTypeDefault;
        
        if ([itemControls[@"format"] isEqualToString:@"boolean"]) {
            xbmcSetting = SettingTypeSwitch;
        }
        else if ([itemControls[@"multiselect"] boolValue] && ![settingOptions isKindOfClass:[NSArray class]]) {
            xbmcSetting = SettingTypeMultiselect;
            self.detailItem[@"value"] = [self.detailItem[@"value"] mutableCopy];
        }
        else if ([itemControls[@"format"] isEqualToString:@"addon"]) {
            xbmcSetting = SettingTypeList;
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
            xbmcSetting = SettingTypeUnsupported;
        }
        else if ([itemControls[@"type"] isEqualToString:@"spinner"] && settingOptions == nil) {
            xbmcSetting = SettingTypeSlider;
            storeSliderValue = [self.detailItem[@"value"] intValue];
        }
        else if ([itemControls[@"type"] isEqualToString:@"edit"]) {
            xbmcSetting = SettingTypeInput;
        }
        else if ([itemControls[@"type"] isEqualToString:@"list"] && settingOptions == nil) {
            xbmcSetting = SettingTypeSlider;
            storeSliderValue = [self.detailItem[@"value"] intValue];
        }
        else {
            self.navigationItem.title = self.detailItem[@"label"];
            if ([settingOptions isKindOfClass:[NSArray class]]) {
                if (settingOptions.count > 0) {
                    xbmcSetting = SettingTypeList;
                }
            }
        }
        
        NSString *footerMessage;
        if (xbmcSetting == SettingTypeUnsupported) {
            footerMessage = LOCALIZED_STR(@"-- WARNING --\nThis kind of setting cannot be configured remotely. Use the XBMC GUI for changing this setting.\nThank you.");
        }
        else if (xbmcSetting == SettingTypeList || xbmcSetting == SettingTypeDefault || xbmcSetting == SettingTypeMultiselect) {
            footerMessage = [NSString stringWithFormat:@"%@", self.detailItem[@"genre"] ?: self.detailItem[@"label"]];
        }
        if (xbmcSetting != SettingTypeUnsupported) {
            footerMessage = [NSString stringWithFormat:@"%@%@ⓘ %@",
                             footerMessage.length ? footerMessage : @"",
                             footerMessage.length ? @"\n\n" : @"",
                             LOCALIZED_STR(@"Tap and hold a setting to add a new button.")];
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
        scrubbingView.backgroundColor = INFO_POPOVER_COLOR;
        scrubbingView.alpha = 0.0;
        
        scrubbingMessage = [[UILabel alloc] initWithFrame:CGRectMake(SCRUBBINGTEXT_PADDING,
                                                                     (SCRUBBINGVIEW_HEIGHT - 2 * SCRUBBINGTEXT_HEIGHT) / 2,
                                                                     frame.size.width - 2 * SCRUBBINGTEXT_PADDING,
                                                                     SCRUBBINGTEXT_HEIGHT)];
        scrubbingMessage.backgroundColor = UIColor.clearColor;
        scrubbingMessage.font = [UIFont boldSystemFontOfSize:13];
        scrubbingMessage.adjustsFontSizeToFitWidth = YES;
        scrubbingMessage.minimumScaleFactor = FONT_SCALING_MIN;
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
        scrubbingRate.minimumScaleFactor = FONT_SCALING_MIN;
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

            UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:LOCALIZED_STR(@"Add a new button") message:LOCALIZED_STR(@"Enter the label:") preferredStyle:UIAlertControllerStyleAlert];
            [alertCtrl addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.placeholder = @"";
                textField.text = [self getActionButtonTitle];
            }];
            UIAlertAction *addButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Add button") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self addActionButton:alertCtrl];
                }];
            UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
            [alertCtrl addAction:addButton];
            [alertCtrl addAction:cancelButton];
            [self presentViewController:alertCtrl animated:YES completion:nil];
        }
    }
}

- (NSString*)getActionButtonTitle {
    NSString *subTitle = @"";
    switch (xbmcSetting) {
        case SettingTypeList:
            subTitle = [NSString stringWithFormat:@"%@", settingOptions[longPressRow.row][@"label"]];
            break;
            
        case SettingTypeSlider:
            subTitle = [self getStringForSliderItem:itemControls value:(int)storeSliderValue];
            break;
            
        case SettingTypeUnsupported:
            return nil;
            
        default:
            break;
    }
    return [NSString stringWithFormat:@"%@%@%@", self.detailItem[@"label"], subTitle.length ? @": " : @"", subTitle ?: @""];
}

- (void)addActionButton:(UIAlertController*)alertCtrl {
    id value = @"";
    NSString *type = self.detailItem[@"type"] ?: @"string";
    switch (xbmcSetting) {
        case SettingTypeList:
            if ([type isEqualToString:@"integer"]) {
                value = @([settingOptions[longPressRow.row][@"value"] intValue]);
            }
            else {
                value = [NSString stringWithFormat:@"%@", settingOptions[longPressRow.row][@"value"]];
            }
            break;
            
        case SettingTypeSlider:
            value = @(storeSliderValue);
            break;
            
        case SettingTypeMultiselect:
        case SettingTypeInput:
            value = self.detailItem[@"value"] ?: @"";
            break;
            
        default:
            value = @"";
            break;
    }
    NSDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.detailItem[@"id"], @"setting", value, @"value", nil];
    NSDictionary *newButton = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                               alertCtrl.textFields[0].text, @"label",
                               type, @"type",
                               @"", @"icon",
                               @(xbmcSetting), @"xbmcSetting",
                               self.detailItem[@"genre"], @"helpText",
                               [NSDictionary dictionaryWithObjectsAndKeys:
                                @"Settings.SetSettingValue", @"command",
                                params, @"params",
                                nil], @"action",
                               nil];
    [self saveCustomButton:newButton];
}

#pragma mark - Custom button

- (void)saveCustomButton:(NSDictionary*)button {
    customButton *arrayButtons = [customButton new];
    [arrayButtons.buttons addObject:button];
    [arrayButtons saveData];
    [Utilities showMessage:LOCALIZED_STR(@"Button added") color:SUCCESS_MESSAGE_COLOR];
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
}

- (void)setSettingValue:(id)value sender:(id)sender {
    if (!value || !self.detailItem[@"id"]) {
        return;
    }
    self.detailItem[@"value"] = value;
    NSDictionary *params = @{@"setting": self.detailItem[@"id"],
                             @"value": self.detailItem[@"value"]};
    [self xbmcAction:@"Settings.SetSettingValue" params:params uiControl:sender];
}

#pragma mark - Helper

- (NSString*)getStringForSliderItem:(id)item value:(int)value {
    NSString *stringResult;
    NSString *format = item[@"formatlabel"];
    if (AppDelegate.instance.serverVersion < 18) {
        // Before Kodi 18.x an older format ("%i ms") was used.
        stringResult = [NSString stringWithFormat:format, value];
    }
    else {
        // Since Kodi 18.x fmt formatting ("{0:d} ms") is used.
        const char *formatStr = [format UTF8String];
        char *string = convert_fmt(formatStr, value);
        stringResult = [NSString stringWithUTF8String:string];
    }
    return stringResult;
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

- (void)layoutCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	cell.backgroundColor = [Utilities getSystemGray6];
    cell.tintColor = [Utilities getSystemBlue];
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
    
    NSString *descriptionString = [NSString stringWithFormat:@"%@", self.detailItem[@"genre"]];
    descriptionString = [descriptionString stringByReplacingOccurrencesOfString:@"[CR]" withString:@"\n"];
    descriptionString = [Utilities stripBBandHTML:descriptionString];
    switch (xbmcSetting) {
        case SettingTypeSwitch:
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
            
        case SettingTypeList:
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
            
        case SettingTypeSlider:
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
            
            sliderLabel.text = [self getStringForSliderItem:itemControls value:[self.detailItem[@"value"] intValue]];
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
            
        case SettingTypeInput:
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
            
        case SettingTypeDefault:
        case SettingTypeMultiselect:
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
            
        case SettingTypeUnsupported:
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
        cellLabel.minimumScaleFactor = FONT_SCALING_MIN;
        cellLabel.textColor = [Utilities get1stLabelColor];
        cellLabel.highlightedTextColor = [Utilities get1stLabelColor];
        cellLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [cell.contentView addSubview:cellLabel];
        
        UISwitch *onoff = [UISwitch new];
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
        descriptionLabel.minimumScaleFactor = FONT_SCALING_MIN;
        descriptionLabel.numberOfLines = 0;
        descriptionLabel.textColor = [Utilities get2ndLabelColor];
        descriptionLabel.highlightedTextColor = [Utilities get2ndLabelColor];
        descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [cell.contentView addSubview:descriptionLabel];
        
        OBSlider *slider = [[OBSlider alloc] initWithFrame:CGRectMake(SLIDER_PADDING,
                                                                      0,
                                                                      cell.frame.size.width - 2 * SLIDER_PADDING,
                                                                      SLIDER_HEIGHT)];
        slider.tag = SETTINGS_CELL_SLIDER;
        slider.backgroundColor = UIColor.clearColor;
        slider.minimumTrackTintColor = KODI_BLUE_COLOR;
        slider.continuous = YES;
        slider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
        [slider addTarget:self action:@selector(stopUpdateSlider:) forControlEvents:UIControlEventEditingDidEnd];
        [slider addTarget:self action:@selector(stopUpdateSlider:) forControlEvents:UIControlEventTouchCancel];
        [slider addTarget:self action:@selector(stopUpdateSlider:) forControlEvents:UIControlEventTouchUpInside];
        [slider addTarget:self action:@selector(stopUpdateSlider:) forControlEvents:UIControlEventTouchUpOutside];
        [slider addTarget:self action:@selector(startUpdateSlider:) forControlEvents:UIControlEventTouchDown];
        [cell.contentView addSubview:slider];
        
        UILabel *sliderLabel = [[UILabel alloc] initWithFrame:CGRectMake(SLIDER_PADDING,
                                                                         0,
                                                                         cell.frame.size.width - 2 * SLIDER_PADDING,
                                                                         LABEL_HEIGHT_DEFAULT)];
        sliderLabel.tag = SETTINGS_CELL_SLIDER_LABEL;
        sliderLabel.font = [UIFont systemFontOfSize:14];
        sliderLabel.adjustsFontSizeToFitWidth = YES;
        sliderLabel.minimumScaleFactor = FONT_SCALING_MIN;
        sliderLabel.textAlignment = NSTextAlignmentCenter;
        sliderLabel.textColor = [Utilities get2ndLabelColor];
        sliderLabel.highlightedTextColor = [Utilities get2ndLabelColor];
        sliderLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [cell.contentView addSubview:sliderLabel];
        
        UITextField *textInputField = [[UITextField alloc] initWithFrame:CGRectMake(SLIDER_PADDING,
                                                                                    0,
                                                                                    cell.frame.size.width - 2 * SLIDER_PADDING,
                                                                                    TEXTFIELD_HEIGHT)];
        textInputField.tag = SETTINGS_CELL_TEXTFIELD;
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
        textInputField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [cell.contentView addSubview:textInputField];
	}
    [self layoutCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = nil;
    switch (xbmcSetting) {
        case SettingTypeList:
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
            [self setSettingValue:self.detailItem[@"value"] sender:_tableView];
            break;
            
        case SettingTypeMultiselect:
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

- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    UIView *helpView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, footerHeight)];
    if (xbmcSetting == SettingTypeUnsupported) {
        helpView.backgroundColor = ERROR_MESSAGE_COLOR;
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
    [self setSettingValue:@(storeSliderValue) sender:sender];
}

- (void)sliderAction:(OBSlider*)slider {
    float newStep = roundf(slider.value / [self.detailItem[@"step"] intValue]);
    float newValue = newStep * [self.detailItem[@"step"] intValue];
    if (!FLOAT_EQUAL_ZERO(newValue - storeSliderValue)) {
        storeSliderValue = newValue;
        UILabel *sliderLabel = [[slider superview] viewWithTag:SETTINGS_CELL_SLIDER_LABEL];
        sliderLabel.text = [self getStringForSliderItem:itemControls value:(int)storeSliderValue];
    }
    scrubbingRate.text = LOCALIZED_STR(([NSString stringWithFormat:@"Scrubbing %@", @(slider.scrubbingSpeed)]));
}

#pragma mark - UISwitch

- (void)toggleSwitch:(id)sender {
    UISwitch *onoff = (UISwitch*)sender;
    [self setSettingValue:@(onoff.on) sender:sender];
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
    [self setSettingValue:[NSString stringWithFormat:@"%@", textField.text] sender:textField];
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
    if (xbmcSetting == SettingTypeMultiselect) {
        [_tableView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (xbmcSetting == SettingTypeList) {
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
}

@end
