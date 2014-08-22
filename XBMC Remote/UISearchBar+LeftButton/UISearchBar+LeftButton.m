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

-(void)configureView{
    self.isVisible = YES;
    self.leftPadding = 0;
    self.rightPadding = 0;
    float buttonWidth = 44;
    float buttonHeight = 44;
    self.leftButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.frame.size.height/2 - buttonHeight/2, buttonWidth, buttonHeight)];
    [self.leftButton setImage:[UIImage imageNamed:@"button_view_list"] forState:UIControlStateNormal];
    [self.leftButton setShowsTouchWhenHighlighted:YES];
    self.leftButton.alpha = 0;
    [self addSubview:self.leftButton];
    
    self.viewLabel = [[UILabel alloc] initWithFrame:CGRectMake(buttonWidth, 0, SEARCH_BAR_LEFT_PADDING - buttonWidth, buttonHeight)];
    [self.viewLabel setBackgroundColor:[UIColor clearColor]];
    [self.viewLabel setFont:[UIFont boldSystemFontOfSize:12]];
    [self.viewLabel setTextColor:[UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:0.65f]];
    [self.viewLabel setShadowColor:[UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:0.3f]];
    BOOL isRetina = ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2);
    float shadowOffset = isRetina ? 0.5f : 1.0f;
    [self.viewLabel setShadowOffset:CGSizeMake(-shadowOffset, shadowOffset)];
    self.viewLabel.alpha = 0;
    [self addSubview:self.viewLabel];
}

- (void) layoutSubviews {
    [super layoutSubviews];
    if (!self.isVisible) return;
    self.leftButton.alpha = 0;
    self.viewLabel.alpha = 0;
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
        if (self.leftPadding){
            self.leftButton.alpha = 1;
            self.viewLabel.alpha = 1;

        }
        [self updateTextFieldFrame:self.rightPadding leftPadding:self.leftPadding];
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
}

@end