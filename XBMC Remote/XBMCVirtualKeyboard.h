//
//  XBMCVirtualKeyboard.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "DSJSONRPC.h"

@import UIKit;

@interface XBMCVirtualKeyboard : UIView <UITextFieldDelegate> {
    UITextField *xbmcVirtualKeyboard;
    UIView *inputAccView;
    UILabel *keyboardTitle;
    UITextField *backgroundTextField;
}

@end
