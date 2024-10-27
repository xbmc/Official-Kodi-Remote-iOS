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
#define FONT_SIZE (IS_IPAD ? 20 : 14)
#define HEIGHT_DEFAULT (IS_IPAD ? 34 : 24)
#define INPUT_PADDING 18
#define TITLE_PADDING 6
#define VERTICAL_PADDING 8

@implementation XBMCVirtualKeyboard

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        xbmcVirtualKeyboard = [[UITextField alloc] initWithFrame:frame];
        xbmcVirtualKeyboard.hidden = YES;
        xbmcVirtualKeyboard.delegate = self;
        xbmcVirtualKeyboard.autocorrectionType = UITextAutocorrectionTypeNo;
        xbmcVirtualKeyboard.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [self addSubview:xbmcVirtualKeyboard];
        
        // The accessory view inputAccView holds both the title (on top) and the input field (at bottom).
        keyboardTitle = [[UILabel alloc] initWithFrame:CGRectMake(TITLE_PADDING,
                                                                  VERTICAL_PADDING,
                                                                  UIScreen.mainScreen.bounds.size.width - TITLE_PADDING * 2,
                                                                  HEIGHT_DEFAULT)];
        keyboardTitle.contentMode = UIViewContentModeScaleToFill;
        keyboardTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        keyboardTitle.textAlignment = NSTextAlignmentCenter;
        keyboardTitle.backgroundColor = UIColor.clearColor;
        keyboardTitle.numberOfLines = 4;
        keyboardTitle.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
        keyboardTitle.textColor = [Utilities get1stLabelColor];

        backgroundTextField = [[UITextField alloc] initWithFrame:CGRectMake(INPUT_PADDING,
                                                                            CGRectGetMaxY(keyboardTitle.frame) + VERTICAL_PADDING,
                                                                            UIScreen.mainScreen.bounds.size.width - 2 * INPUT_PADDING,
                                                                            HEIGHT_DEFAULT)];
        backgroundTextField.userInteractionEnabled = YES;
        backgroundTextField.borderStyle = UITextBorderStyleRoundedRect;
        backgroundTextField.backgroundColor = [Utilities getSystemGray6];
        backgroundTextField.font = [UIFont systemFontOfSize:FONT_SIZE];
        backgroundTextField.textColor = [Utilities get1stLabelColor];
        backgroundTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        backgroundTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        backgroundTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        backgroundTextField.textAlignment = NSTextAlignmentCenter;
        backgroundTextField.delegate = self;
        backgroundTextField.tag = VIRTUAL_KEYBOARD_TEXTFIELD;
        
        inputAccView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                0,
                                                                UIScreen.mainScreen.bounds.size.width,
                                                                CGRectGetMaxY(backgroundTextField.frame) + VERTICAL_PADDING)];
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
                     if ([methodResult[@"currentwindow"][@"id"] longLongValue] == WINDOW_VIRTUAL_KEYBOARD) {
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
    // Adapt title height to render full text
    CGRect frame = keyboardTitle.frame;
    frame.size.height = [Utilities getSizeOfLabel:keyboardTitle].height;
    keyboardTitle.frame = frame;
    
    // Calculate accessory view height. In case no title is given, only show the input text field with padding.
    CGFloat accessoryHeight = CGRectGetHeight(keyboardTitle.frame) + CGRectGetHeight(backgroundTextField.frame) + 3 * VERTICAL_PADDING;
    if (!keyboardTitle.text.length) {
        accessoryHeight = CGRectGetHeight(backgroundTextField.frame) + 2 * VERTICAL_PADDING;
    }
    
    inputAccView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, accessoryHeight);
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
