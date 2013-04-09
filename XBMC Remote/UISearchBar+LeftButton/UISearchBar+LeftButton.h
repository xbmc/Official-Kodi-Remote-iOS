//
//  UISearchBar+LeftButton.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 7/4/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#define SEARCH_BAR_LEFT_PADDING 120.0f

@interface UISearchBarLeftButton : UISearchBar {
    float cancelButtonWidth;
//    UIButton *leftButton;
}

@property (readonly) UITextField *textField;
@property (nonatomic) int leftPadding;
@property (nonatomic) int rightPadding;
@property (nonatomic, retain) UILabel *viewLabel;
@property (nonatomic, retain) UIButton *leftButton;

@end