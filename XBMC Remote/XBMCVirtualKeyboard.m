//
//  XBMCVirtualKeyboard.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "XBMCVirtualKeyboard.h"
#import "AppDelegate.h"
#import "Utilities.h"

#define VIRTUAL_KEYBOARD_TEXTFIELD 10
#define WINDOW_VIRTUAL_KEYBOARD 10103
#define INPUT_PADDING_LEFT_RIGHT 18
#define INPUT_PADDING_BOTTOM 10
#define TEXT_FONT_SIZE 14
#define TEXT_HEIGHT 24
#define TITLE_PADDING 6

@implementation XBMCVirtualKeyboard

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat scale = IS_IPAD ? 1.4 : 1.0;
        paddingLeftRight = floor(INPUT_PADDING_LEFT_RIGHT * scale);
        paddingTopBottom = floor(INPUT_PADDING_BOTTOM * scale);
        keyboardTitleHeight = floor(TEXT_HEIGHT * scale);
        textFieldHeight = floor(TEXT_HEIGHT * scale);
        textFontSize = floor(TEXT_FONT_SIZE * scale);
        
        xbmcVirtualKeyboard = [[UITextField alloc] initWithFrame:frame];
        xbmcVirtualKeyboard.hidden = YES;
        xbmcVirtualKeyboard.delegate = self;
        xbmcVirtualKeyboard.autocorrectionType = UITextAutocorrectionTypeNo;
        xbmcVirtualKeyboard.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [self addSubview:xbmcVirtualKeyboard];
        
        screenWidth = UIScreen.mainScreen.bounds.size.width;
        
        keyboardTitle = [[UILabel alloc] initWithFrame:CGRectMake(TITLE_PADDING, 0, screenWidth - TITLE_PADDING * 2, keyboardTitleHeight)];
        keyboardTitle.contentMode = UIViewContentModeScaleToFill;
        keyboardTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        keyboardTitle.textAlignment = NSTextAlignmentCenter;
        keyboardTitle.backgroundColor = UIColor.clearColor;
        keyboardTitle.font = [UIFont boldSystemFontOfSize:textFontSize];
        keyboardTitle.adjustsFontSizeToFitWidth = YES;
        keyboardTitle.minimumScaleFactor = 0.6;
        keyboardTitle.textColor = [Utilities get1stLabelColor];

        backgroundTextField = [[UITextField alloc] initWithFrame:CGRectMake(paddingLeftRight, keyboardTitleHeight, screenWidth - paddingLeftRight * 2, textFieldHeight)];
        backgroundTextField.userInteractionEnabled = YES;
        backgroundTextField.borderStyle = UITextBorderStyleRoundedRect;
        backgroundTextField.backgroundColor = [Utilities getSystemGray6];
        backgroundTextField.font = [UIFont systemFontOfSize:textFontSize];
        backgroundTextField.textColor = [Utilities get1stLabelColor];
        backgroundTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        backgroundTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        backgroundTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        backgroundTextField.textAlignment = NSTextAlignmentCenter;
        backgroundTextField.delegate = self;
        backgroundTextField.tag = VIRTUAL_KEYBOARD_TEXTFIELD;
        
        inputAccView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, keyboardTitleHeight + textFieldHeight + paddingTopBottom)];
        inputAccView.backgroundColor = [Utilities getSystemGray4];
        [inputAccView addSubview:keyboardTitle];
        [inputAccView addSubview:backgroundTextField];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(showKeyboard:)
                                                     name: @"Input.OnInputRequested"
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(hideKeyboard)
                                                     name: @"Input.OnInputFinished"
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(cancelKeyboard)
                                                     name: @"Input.OnInputCanceled"
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(toggleVirtualKeyboard)
                                                     name: @"toggleVirtualKeyboard"
                                                   object: nil];
    }
    return self;
}

#pragma mark - keyboard

- (BOOL)canBecomeFirstResponder {
    return NO;
}

- (void)cancelKeyboard {
    if ([backgroundTextField isEditing]) {
        [[Utilities getJsonRPC]
         callMethod:@"GUI.GetProperties"
         withParameters:@{@"properties": @[@"currentwindow"]}
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
             if (error == nil && methodError == nil && [methodResult isKindOfClass: [NSDictionary class]]) {
                 if (methodResult[@"currentwindow"] != [NSNull null]) {
                     if ([methodResult[@"currentwindow"][@"id"] longValue] == WINDOW_VIRTUAL_KEYBOARD) {
                         [self GUIAction:@"Input.Back" params:@{} httpAPIcallback:nil];
                     }
                 }
             }
         }];
    }
    [self hideKeyboard];
}

- (void)hideKeyboard {
    [backgroundTextField resignFirstResponder];
    backgroundTextField.text = @"";
    [xbmcVirtualKeyboard resignFirstResponder];
}

- (void)showKeyboard:(NSNotification*)note {
    if (AppDelegate.instance.serverVersion == 11) {
        backgroundTextField.text = @" ";
    }
    NSDictionary *params;
    if (note != nil) {
        NSDictionary *theData = note.userInfo;
        params = theData[@"params"];
    }
    keyboardTitle.text = @"";
    backgroundTextField.keyboardType = UIKeyboardTypeDefault;
    if (params != nil) {
        if (params[@"data"] != [NSNull null]) {
            if (params[@"data"][@"title"] != [NSNull null]) {
                keyboardTitle.text = params[@"data"][@"title"];
            }
            if (params[@"data"][@"value"] != [NSNull null]) {
                if (![params[@"data"][@"value"] isEqualToString:@""]) {
                    backgroundTextField.text = params[@"data"][@"value"];
                }
            }
            if (params[@"data"][@"type"] != [NSNull null]) {
                if ([params[@"data"][@"type"] isEqualToString:@"number"]) {
                    backgroundTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                }
            }
        }
    }
    [xbmcVirtualKeyboard becomeFirstResponder];
    [backgroundTextField becomeFirstResponder];
}

- (void)toggleVirtualKeyboard {
    if ([xbmcVirtualKeyboard isFirstResponder] || [backgroundTextField isFirstResponder]) {
        [self hideKeyboard];
    }
    else {
        [self showKeyboard:nil];
    }
}

#pragma mark - UITextFieldDelegate Methods

- (void)textFieldDidBeginEditing:(UITextField*)textField {
    int titleHeight = keyboardTitle.text.length ? keyboardTitleHeight : paddingTopBottom;
    screenWidth = UIScreen.mainScreen.bounds.size.width;
    inputAccView.frame = CGRectMake(0, 0, screenWidth, titleHeight + textFieldHeight + paddingTopBottom);
    backgroundTextField.frame = CGRectMake(paddingLeftRight, titleHeight, screenWidth - paddingLeftRight * 2, textFieldHeight);
    textField.inputAccessoryView = inputAccView;
}

- (BOOL)textField:(UITextField*)theTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
    if (AppDelegate.instance.serverVersion == 11) {
        if (range.location == 0) { //BACKSPACE
            [Utilities sendXbmcHttp:@"SendKey(0xf108)"];
        }
        else { // CHARACTER
            unichar x = [string characterAtIndex:0];
            if (x == '\n') {
                [self GUIAction:@"Input.Select" params:@{} httpAPIcallback:nil];
                [backgroundTextField resignFirstResponder];
                [xbmcVirtualKeyboard resignFirstResponder];
            }
            else if (x < 1000) {
                [Utilities sendXbmcHttp:[NSString stringWithFormat:@"SendKey(0xf1%x)", x]];
            }
        }
        return NO;
    }
    else {
        BOOL inputFinished = NO;
        NSString *stringToSend = [theTextField.text stringByReplacingCharactersInRange:range withString:string];
        if (string.length != 0) {
            unichar x = [string characterAtIndex:0];
            if (x == '\n') {
                stringToSend = [stringToSend substringToIndex:stringToSend.length - 1];
                [backgroundTextField resignFirstResponder];
                [xbmcVirtualKeyboard resignFirstResponder];
                theTextField.text = @"";
                inputFinished = YES;
            }
        }
        stringToSend = stringToSend ?: @"";
        [self GUIAction:@"Input.SendText" params:@{@"text": stringToSend, @"done": @(inputFinished)} httpAPIcallback:nil];
        return YES;
    }
}

- (void)textFieldDidEndEditing:(UITextField*)textField {
    if (textField.tag == VIRTUAL_KEYBOARD_TEXTFIELD) {
        [self performSelectorOnMainThread:@selector(hideKeyboard) withObject:nil waitUntilDone:NO];
    }
}

#pragma mark - json commands

- (void)GUIAction:(NSString*)action params:(NSDictionary*)params httpAPIcallback:(NSString*)callback {
    [[Utilities getJsonRPC] callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if ((methodError != nil || error != nil) && callback != nil) { // Backward compatibility
            [Utilities sendXbmcHttp:callback];
        }
    }];
}

#pragma mark - lifecycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
