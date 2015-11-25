//
//  UISearchBar+LeftButton.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 7/4/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UISearchBarLeftButton : UISearchBar {
    float cancelButtonWidth;
    int searchbarLeftPadding;
}

- (void)setLeftPadding;

@property (readonly) UITextField *textField;
@property (nonatomic) int leftPadding;
@property (nonatomic) int rightPadding;
@property (nonatomic) float storeWidth;
@property (nonatomic, retain) UIButton *leftButton;
@property (nonatomic, retain) UIButton *sortButton;
@property (nonatomic) BOOL isVisible;

@end