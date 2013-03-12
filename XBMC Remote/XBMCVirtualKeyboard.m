//
//  XBMCVirtualKeyboard.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "XBMCVirtualKeyboard.h"
#import "AppDelegate.h"

@implementation XBMCVirtualKeyboard

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        accessoryHeight = 52;
        padding = 25;
        verboseHeight = 24;
        textSize = 14;
        background_padding = 6;
        alignBottom = 10;
        UIColor *accessoryColor = [UIColor colorWithRed:0.565f green:0.596f blue:0.643f alpha:1];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            accessoryHeight = 74;
            verboseHeight = 34;
            padding = 50;
            textSize = 20;
            alignBottom = 12;
            accessoryColor = [UIColor colorWithRed:0.615f green:0.611f blue:0.654f alpha:1];
        }

        xbmcVirtualKeyboard = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 300, 20)];
        xbmcVirtualKeyboard.hidden = NO;
        xbmcVirtualKeyboard.delegate = self;
        xbmcVirtualKeyboard.autocorrectionType = UITextAutocorrectionTypeNo;
        xbmcVirtualKeyboard.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [self addSubview:xbmcVirtualKeyboard];
        
        CGRect screenBound = [[UIScreen mainScreen] bounds];
        CGSize screenSize = screenBound.size;
        screenWidth = screenSize.width;
        
        verboseOutput = [[UILabel alloc] initWithFrame:CGRectMake(padding, (int)(accessoryHeight/2) - (int)(verboseHeight/2) + alignBottom, screenWidth - padding * 2, verboseHeight)];
        [verboseOutput setFont:[UIFont systemFontOfSize:textSize]];
        [verboseOutput setContentMode:UIViewContentModeScaleToFill];
        [verboseOutput setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin];
        [verboseOutput setLineBreakMode:NSLineBreakByTruncatingHead];
        [verboseOutput setUserInteractionEnabled:NO];
        [verboseOutput setBackgroundColor:[UIColor clearColor]];
        [verboseOutput setTextAlignment:NSTextAlignmentCenter];
        
        inputAccView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, accessoryHeight)];
        [inputAccView setBackgroundColor:accessoryColor];
        UIImageView *keyboardLineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 2)];
        [keyboardLineImageView setImage:[UIImage imageNamed:@"keyboard_line"]];
        [keyboardLineImageView setContentMode:UIViewContentModeScaleToFill];
        [keyboardLineImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [inputAccView addSubview:keyboardLineImageView];
        
        backgroundTextField = [[UITextField alloc] initWithFrame:CGRectMake(padding - background_padding, (int)(accessoryHeight/2) - (int)(verboseHeight/2) + alignBottom, screenWidth - (padding - background_padding) * 2, verboseHeight)];
        [backgroundTextField setUserInteractionEnabled:NO];
        [backgroundTextField setBorderStyle:UITextBorderStyleRoundedRect];
        [backgroundTextField setBackgroundColor:[UIColor whiteColor]];
        [backgroundTextField setFont:[UIFont boldSystemFontOfSize:textSize]];
        [backgroundTextField setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin];
        
        keyboardTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, screenWidth, (int)(accessoryHeight/2) - (int)(verboseHeight/2) + alignBottom + 1)];
        [keyboardTitle setContentMode:UIViewContentModeScaleToFill];
        [keyboardTitle setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin];
        [keyboardTitle setTextAlignment:NSTextAlignmentCenter];
        [keyboardTitle setBackgroundColor:[UIColor clearColor]];
        [keyboardTitle setFont:[UIFont boldSystemFontOfSize:textSize]];
        [keyboardTitle setTextColor:[UIColor whiteColor]];
        [keyboardTitle setShadowColor:[UIColor blackColor]];
        [keyboardTitle setShadowOffset:CGSizeMake(0, 1)];
        
        [inputAccView addSubview:keyboardTitle];
        [inputAccView addSubview:backgroundTextField];
        [inputAccView addSubview:verboseOutput];
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

-(void) hideKeyboard:(id)sender{
    [xbmcVirtualKeyboard resignFirstResponder];
}

-(void) showKeyboard:(NSNotification *)note{
    if ([AppDelegate instance].serverVersion == 11){
        xbmcVirtualKeyboard.text = @" ";
    }
    NSDictionary *params;
    if (note!=nil){
        params = [[note userInfo] objectForKey:@"params"];
    }
    keyboardTitle.text = @"";
    if (params != nil){
        if (((NSNull *)[params objectForKey:@"data"] != [NSNull null])){
            if (((NSNull *)[[params objectForKey:@"data"] objectForKey:@"title"] != [NSNull null])){
                keyboardTitle.text = [[params objectForKey:@"data"] objectForKey:@"title"];
            }
            if (((NSNull *)[[params objectForKey:@"data"] objectForKey:@"value"] != [NSNull null])){
                if (![[[params objectForKey:@"data"] objectForKey:@"value"] isEqualToString:@""]){
                    xbmcVirtualKeyboard.text = [[params objectForKey:@"data"] objectForKey:@"value"];
                }
            }
        }
    }
    [xbmcVirtualKeyboard becomeFirstResponder];
}

-(void)toggleVirtualKeyboard:(id)sender{
    if ([xbmcVirtualKeyboard isFirstResponder]){
        [self hideKeyboard:nil];
    }
    else {
        [self showKeyboard:nil];
    }
}

#pragma mark - UITextFieldDelegate Methods


-(void)textFieldDidBeginEditing:(UITextField *)textField{
    verboseOutput.text = xbmcVirtualKeyboard.text;
    if ([keyboardTitle.text isEqualToString:@""]){
        [inputAccView setFrame:
         CGRectMake(0, 0, screenWidth, accessoryHeight - alignBottom)];
        [verboseOutput setFrame:
         CGRectMake(padding, (int)(accessoryHeight/2) - (int)(verboseHeight/2) - (int)(alignBottom/2), screenWidth - padding * 2, verboseHeight)];
        [backgroundTextField setFrame:
         CGRectMake(padding - background_padding, (int)(accessoryHeight/2) - (int)(verboseHeight/2) - (int)(alignBottom/2), screenWidth - (padding - background_padding) * 2, verboseHeight)];
    }
    else{
        [inputAccView setFrame:CGRectMake(0, 0, screenWidth, accessoryHeight)];
        [verboseOutput setFrame:CGRectMake(padding, (int)(accessoryHeight/2) - (int)(verboseHeight/2) + alignBottom, screenWidth - padding * 2, verboseHeight)];
        [backgroundTextField setFrame:CGRectMake(padding - background_padding, (int)(accessoryHeight/2) - (int)(verboseHeight/2) + alignBottom, screenWidth - (padding - background_padding) * 2, verboseHeight)];
    }
    [textField setInputAccessoryView:inputAccView];
}

-(BOOL) textField: (UITextField *)theTextField shouldChangeCharactersInRange: (NSRange)range replacementString: (NSString *)string {
    if ([AppDelegate instance].serverVersion == 11){
        if (range.location == 0){ //BACKSPACE
            [self sendXbmcHttp:@"SendKey(0xf108)"];
            if ([verboseOutput.text length]>0){
                [verboseOutput setText:[NSString stringWithFormat:@"%@", [verboseOutput.text substringToIndex:[verboseOutput.text length] - 1]]];
            }
            else{
                verboseOutput.text = @"";
            }
        }
        else{ // CHARACTER
            int x = (unichar) [string characterAtIndex: 0];
            if (x==10) {
                [self GUIAction:@"Input.Select" params:[NSDictionary dictionaryWithObjectsAndKeys:nil] httpAPIcallback:nil];
                [xbmcVirtualKeyboard resignFirstResponder];
            }
            else if (x<1000){
                [self sendXbmcHttp:[NSString stringWithFormat:@"SendKey(0xf1%x)", x]];
            }
            [verboseOutput setText:[NSString stringWithFormat:@"%@%@", verboseOutput.text == nil ? @"" : verboseOutput.text, string]];
        }
        return NO;
    }
    else{
        NSString *stringToSend = [theTextField.text stringByReplacingCharactersInRange:range withString:string];
//        if ([stringToSend isEqualToString:@""]){
//            stringToSend = @"";
//        }
        verboseOutput.text = stringToSend;
        if ([string length] != 0){
            int x = (unichar) [string characterAtIndex: 0];
            if (x==10) {
                [self GUIAction:@"Input.SendText" params:[NSDictionary dictionaryWithObjectsAndKeys:stringToSend, @"text", [NSNumber numberWithBool:TRUE], @"done", nil] httpAPIcallback:nil];
                [xbmcVirtualKeyboard resignFirstResponder];
                theTextField.text = @"";
                return YES;
            }
        }
        [self GUIAction:@"Input.SendText" params:[NSDictionary dictionaryWithObjectsAndKeys:stringToSend, @"text", [NSNumber numberWithBool:FALSE], @"done", nil] httpAPIcallback:nil];
        return YES;
    }
}

#pragma mark - json commands

-(void)GUIAction:(NSString *)action params:(NSDictionary *)params httpAPIcallback:(NSString *)callback{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance];
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        //        NSLog(@"Action %@ ok with %@ ", action , methodResult);
        //        if (methodError!=nil || error != nil){
        //            NSLog(@"method error %@", methodError);
        //        }
        if ((methodError!=nil || error != nil) && callback!=nil){ // Backward compatibility
            //            NSLog(@"method error %@", methodError);
            [self sendXbmcHttp:callback];
        }
    }];
}

-(void)sendXbmcHttp:(NSString *) command{
    GlobalData *obj=[GlobalData getInstance];
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    
    NSString *serverHTTP=[NSString stringWithFormat:@"http://%@%@@%@:%@/xbmcCmds/xbmcHttp?command=%@", obj.serverUser, userPassword, obj.serverIP, obj.serverPort, command];
    NSURL *url = [NSURL  URLWithString:serverHTTP];
    NSString *requestANS = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
    requestANS=nil;
}

#pragma mark - lifecycle

-(void)dealloc{
    jsonRPC = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
