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

static CGRect initialTextFieldFrame;

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
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        initialTextFieldFrame = self.textField.frame;
    });
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

-(void)updateTextFieldFrame:(float)rightMargin leftPadding:(float)leftMargin{
    int originX = self.textField.frame.origin.x + leftMargin;
    int width = initialTextFieldFrame.size.width - leftMargin - rightMargin;
    CGRect newFrame = CGRectMake (originX,
                                  self.textField.frame.origin.y,
                                  width,
                                  self.textField.frame.size.height);
    self.textField.frame = newFrame;
}

-(UITextField *)textField{
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass: [UITextField class]]){
            return (UITextField *)view;
        }
    }
    return nil;
}

- (void)drawRect:(CGRect)rect{
    if ([self.delegate respondsToSelector:@selector(handleChangeLibraryView)]){
        [self.leftButton addTarget:self.delegate action:@selector(handleChangeLibraryView) forControlEvents:UIControlEventTouchUpInside];
    }
}

@end