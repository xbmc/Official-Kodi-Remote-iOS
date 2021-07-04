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

@implementation XBMCVirtualKeyboard

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat keyboardTitlePadding = 6;
        accessoryHeight = 52;
        padding = 25;
        verboseHeight = 24;
        textSize = 14;
        background_padding = 6;
        alignBottom = 10;
        UIColor *accessoryBackgroundColor = [Utilities getSystemGray4];
        if (IS_IPAD) {
            accessoryHeight = 74;
            verboseHeight = 34;
            padding = 50;
            textSize = 20;
            alignBottom = 12;
        }

        xbmcVirtualKeyboard = [[UITextField alloc] initWithFrame:frame];
        xbmcVirtualKeyboard.hidden = YES;
        xbmcVirtualKeyboard.delegate = self;
        xbmcVirtualKeyboard.autocorrectionType = UITextAutocorrectionTypeNo;
        xbmcVirtualKeyboard.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [self addSubview:xbmcVirtualKeyboard];
        
        CGRect screenBound = [[UIScreen mainScreen] bounds];
        CGSize screenSize = screenBound.size;
        screenWidth = screenSize.width;
        
        keyboardTitle = [[UILabel alloc] initWithFrame:CGRectMake(keyboardTitlePadding, 0, screenWidth - keyboardTitlePadding * 2, (int)(accessoryHeight/2) - (int)(verboseHeight/2) + alignBottom + 1)];
        [keyboardTitle setContentMode:UIViewContentModeScaleToFill];
        [keyboardTitle setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin];
        [keyboardTitle setTextAlignment:NSTextAlignmentCenter];
        [keyboardTitle setBackgroundColor:[UIColor clearColor]];
        [keyboardTitle setFont:[UIFont boldSystemFontOfSize:textSize]];
        [keyboardTitle setAdjustsFontSizeToFitWidth:YES];
        [keyboardTitle setMinimumScaleFactor:0.6];
        [keyboardTitle setTextColor:BAR_TINT_COLOR];

        backgroundTextField = [[UITextField alloc] initWithFrame:CGRectMake(padding - background_padding, (int)(accessoryHeight/2) - (int)(verboseHeight/2) + alignBottom, screenWidth - (padding - background_padding) * 2, verboseHeight)];
        [backgroundTextField setUserInteractionEnabled:YES];
        [backgroundTextField setBorderStyle:UITextBorderStyleRoundedRect];
        [backgroundTextField setBackgroundColor:[Utilities getSystemGray6]];
        [backgroundTextField setFont:[UIFont systemFontOfSize:textSize]];
        [backgroundTextField setTextColor:[Utilities get1stLabelColor]];
        [backgroundTextField setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin];
        backgroundTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        backgroundTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [backgroundTextField setTextAlignment:NSTextAlignmentCenter];
        [backgroundTextField setDelegate:self];
        [backgroundTextField setTag:10];
        
        inputAccView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, accessoryHeight)];
        [inputAccView setBackgroundColor:accessoryBackgroundColor];
        [inputAccView addSubview:keyboardTitle];
        [inputAccView addSubview:backgroundTextField];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(showKeyboard:)
                                                     name: @"Input.OnInputRequested"
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(hideKeyboard:)
                                                     name: @"Input.OnInputFinished"
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(toggleVirtualKeyboard:)
                                                     name: @"toggleVirtualKeyboard"
                                                   object: nil];
    }
    return self;
}

#pragma mark - keyboard

- (BOOL)canBecomeFirstResponder {
    return NO;
}

- (void)hideKeyboard:(id)sender {
    [backgroundTextField resignFirstResponder];
    backgroundTextField.text = @"";
    [xbmcVirtualKeyboard resignFirstResponder];
}

- (void)showKeyboard:(NSNotification*)note {
    if ([AppDelegate instance].serverVersion == 11) {
        backgroundTextField.text = @" ";
    }
    NSDictionary *params;
    if (note != nil) {
        params = [note userInfo][@"params"];
    }
    keyboardTitle.text = @"";
    backgroundTextField.keyboardType = UIKeyboardTypeDefault;
    if (params != nil) {
        if (((NSNull*)params[@"data"] != [NSNull null])) {
            if (((NSNull*)params[@"data"][@"title"] != [NSNull null])) {
                keyboardTitle.text = params[@"data"][@"title"];
            }
            if (((NSNull*)params[@"data"][@"value"] != [NSNull null])) {
                if (![params[@"data"][@"value"] isEqualToString:@""]) {
                    backgroundTextField.text = params[@"data"][@"value"];
                }
            }
            if (((NSNull*)params[@"data"][@"type"] != [NSNull null])) {
                if ([params[@"data"][@"type"] isEqualToString:@"number"]) {
                    backgroundTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                }
            }
        }
    }
    [xbmcVirtualKeyboard becomeFirstResponder];
    [backgroundTextField becomeFirstResponder];
}

- (void)toggleVirtualKeyboard:(id)sender {
    if ([xbmcVirtualKeyboard isFirstResponder] || [backgroundTextField isFirstResponder]) {
        [self hideKeyboard:nil];
    }
    else {
        [self showKeyboard:nil];
    }
}

#pragma mark - UITextFieldDelegate Methods

- (void)textFieldDidBeginEditing:(UITextField*)textField {
    CGFloat finalHeight = accessoryHeight - alignBottom;
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    screenWidth = screenSize.width;
    CGRect frame = inputAccView.frame;
    frame.size.width = screenWidth;
    [inputAccView setFrame:frame];
    
    if ([keyboardTitle.text isEqualToString:@""]) {
        [inputAccView setFrame:
         CGRectMake(0, 0, screenWidth, finalHeight)];
        [backgroundTextField setFrame:
         CGRectMake(padding - background_padding, (int)(accessoryHeight/2) - (int)(verboseHeight/2) - (int)(alignBottom/2), screenWidth - (padding - background_padding) * 2, verboseHeight)];
    }
    else {
        finalHeight = accessoryHeight;
        [inputAccView setFrame:CGRectMake(0, 0, screenWidth, finalHeight)];
        [backgroundTextField setFrame:CGRectMake(padding - background_padding, (int)(accessoryHeight/2) - (int)(verboseHeight/2) + alignBottom, screenWidth - (padding - background_padding) * 2, verboseHeight)];
    }
    [textField setInputAccessoryView:inputAccView];
    if ([textField.inputAccessoryView constraints].count > 0) {
        NSLayoutConstraint *constraint = [textField.inputAccessoryView constraints][0];
        constraint.constant = finalHeight;
    }
}

- (BOOL)textField:(UITextField*)theTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
    if ([AppDelegate instance].serverVersion == 11) {
        if (range.location == 0) { //BACKSPACE
            [self sendXbmcHttp:@"SendKey(0xf108)"];
        }
        else { // CHARACTER
            int x = (unichar) [string characterAtIndex: 0];
            if (x == 10) {
                [self GUIAction:@"Input.Select" params:[NSDictionary dictionary] httpAPIcallback:nil];
                [backgroundTextField resignFirstResponder];
                [xbmcVirtualKeyboard resignFirstResponder];
            }
            else if (x < 1000) {
                [self sendXbmcHttp:[NSString stringWithFormat:@"SendKey(0xf1%x)", x]];
            }
        }
        return NO;
    }
    else {
        NSString *stringToSend = [theTextField.text stringByReplacingCharactersInRange:range withString:string];
        if ([string length] != 0) {
            int x = (unichar) [string characterAtIndex: 0];
            if (x == 10) {
                [self GUIAction:@"Input.SendText" params:[NSDictionary dictionaryWithObjectsAndKeys:[stringToSend substringToIndex:[stringToSend length] - 1], @"text", @(YES), @"done", nil] httpAPIcallback:nil];
                [backgroundTextField resignFirstResponder];
                [xbmcVirtualKeyboard resignFirstResponder];
                theTextField.text = @"";
                return YES;
            }
        }
        [self GUIAction:@"Input.SendText" params:[NSDictionary dictionaryWithObjectsAndKeys:stringToSend, @"text", @(NO), @"done", nil] httpAPIcallback:nil];
        return YES;
    }
}

- (void)textFieldDidEndEditing:(UITextField*)textField {
    if (textField.tag == 10) {
        [self performSelectorOnMainThread:@selector(hideKeyboard:) withObject:nil waitUntilDone:NO];
    }
}

#pragma mark - json commands

- (void)GUIAction:(NSString*)action params:(NSDictionary*)params httpAPIcallback:(NSString*)callback {
    [[Utilities getJsonRPC] callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if ((methodError != nil || error != nil) && callback != nil) { // Backward compatibility
            [self sendXbmcHttp:callback];
        }
    }];
}

- (void)sendXbmcHttp:(NSString*)command {
    GlobalData *obj = [GlobalData getInstance];
    NSString *userPassword = [obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    
    NSString *serverHTTP = [NSString stringWithFormat:@"http://%@%@@%@:%@/xbmcCmds/xbmcHttp?command=%@", obj.serverUser, userPassword, obj.serverIP, obj.serverPort, command];
    NSURL *url = [NSURL URLWithString:serverHTTP];
    [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
}

#pragma mark - lifecycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
