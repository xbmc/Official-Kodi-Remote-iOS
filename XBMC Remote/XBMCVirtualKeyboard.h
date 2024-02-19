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
    int paddingLeftRight;
    int paddingTopBottom;
    int textFieldHeight;
    int textFontSize;
    int keyboardTitleHeight;
    CGFloat screenWidth;
}

@end
