//
//  UISearchBar+LeftButton.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 7/4/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "UISearchBar+LeftButton.h"
#define CANCEL_BUTTON_DEFAULT_WIDTH 55.0
#define CANCEL_BUTTON_PADDING 10.0

@implementation UISearchBarLeftButton

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configureView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self){
        [self configureView];
    }
    return self;
}

-(void)configureView {
    self.isVisible = YES;
    leftPadding = 0;
    self.rightPadding = 0;
    buttonWidth = 44.0f;
    showLeftButton = NO;
    showSortButton = NO;
    float buttonHeight = 44.0f;
    
    self.leftButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.frame.size.height/2 - buttonHeight/2, buttonWidth, buttonHeight)];
    [self.leftButton setImage:[UIImage imageNamed:@"button_view_list"] forState:UIControlStateNormal];
    [self.leftButton setShowsTouchWhenHighlighted:YES];
    self.leftButton.alpha = 0;
    [self addSubview:self.leftButton];
    
    self.sortButton = [[UIButton alloc] initWithFrame:CGRectMake(buttonWidth, self.frame.size.height/2 - buttonHeight/2, buttonWidth, buttonHeight)];
    [self.sortButton setImage:[UIImage imageNamed:@"button_sort"] forState:UIControlStateNormal];
    [self.sortButton setShowsTouchWhenHighlighted:YES];
    self.sortButton.alpha = 0;
    [self addSubview:self.sortButton];
}

- (void) layoutSubviews {
    [super layoutSubviews];
    if (!self.isVisible) return;
    self.leftButton.alpha = 0;
    self.sortButton.alpha = 0;
    if (self.showsCancelButton == YES){
        cancelButtonWidth = CANCEL_BUTTON_DEFAULT_WIDTH;
        for (UIView *view in self.subviews) {
            if ([view isKindOfClass: [UIButton class]]){
                cancelButtonWidth = view.frame.size.width;
            }
        }
        [self updateTextFieldFrame:cancelButtonWidth + CANCEL_BUTTON_PADDING leftPadding:0];
    }
    else{
        leftPadding = 0;
        float buttonSortOriginX = 0;
        if (showLeftButton == YES) {
            self.leftButton.alpha = 1;
            leftPadding += buttonWidth;
            buttonSortOriginX = 44.0f;
        }
        if (showSortButton == YES) {
            self.sortButton.alpha = 1;
            leftPadding += buttonWidth;
            CGRect frame = self.sortButton.frame;
            frame.origin.x = buttonSortOriginX;
            self.sortButton.frame = frame;
        }
        [self updateTextFieldFrame:self.rightPadding leftPadding:leftPadding];
    }
}

-(void)updateTextFieldFrame:(float)rightMargin leftPadding:(float)leftMargin {
    int originX = self.textField.frame.origin.x + leftMargin;
    int width = self.frame.size.width - 16 - leftMargin - rightMargin;
    CGRect newFrame = CGRectMake (originX,
                                  self.textField.frame.origin.y,
                                  width,
                                  self.textField.frame.size.height);
    self.textField.frame = newFrame;
    newFrame = self.frame;
    newFrame.size.width = self.storeWidth;
    self.frame = newFrame;
}

-(UITextField *)textField{
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass: [UITextField class]]){
            return (UITextField *)view;
        }
        else if ([view isKindOfClass:[UIView class]]){
            for (UIView *view2 in view.subviews) {
                if ([view2 isKindOfClass: [UITextField class]]){
                    return (UITextField *)view2;
                }
            }
        }
    }
    return nil;
}

- (void)drawRect:(CGRect)rect{
    SEL selector = NSSelectorFromString(@"handleChangeLibraryView");
    if ([self.delegate respondsToSelector:selector]){
        [self.leftButton addTarget:self.delegate action:selector forControlEvents:UIControlEventTouchUpInside];
    }
    selector = NSSelectorFromString(@"handleChangeSortLibrary");
    if ([self.delegate respondsToSelector:selector]){
        [self.sortButton addTarget:self.delegate action:selector forControlEvents:UIControlEventTouchUpInside];
    }
}

-(void)showLeftButton:(BOOL)show {
    showLeftButton = show;
}

-(void)showSortButton:(BOOL)show {
    showSortButton = show;
}

@end