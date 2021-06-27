//
//  XBMCVirtualKeyboard.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"

@interface XBMCVirtualKeyboard : UIView <UITextFieldDelegate> {
    UITextField *xbmcVirtualKeyboard;
    UIView *inputAccView;
    UILabel *keyboardTitle;
    UITextField *backgroundTextField;
    int accessoryHeight;
    int padding;
    int verboseHeight;
    int textSize;
    int background_padding;
    int alignBottom;
    CGFloat screenWidth;
}

@end
