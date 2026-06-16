//
//  UIButton+Extensions.m
//  Kodi Remote
//
//  Created by Buschmann on 05.05.26.
//  Copyright © 2026 Team Kodi. All rights reserved.
//

#import "UIButton+Extensions.h"

@implementation UIButton (Extensions)

- (void)setTextStyle {
    [self setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self setTitleColor:UIColor.whiteColor forState:UIControlStateSelected];
    [self setTitleColor:UIColor.grayColor forState:UIControlStateDisabled];
}

- (void)setIconStyle:(UIImage*)image {
    [self setIconStyle:image withColor:ICON_TINT_COLOR];
}

- (void)setIconStyle:(UIImage*)image withColor:(UIColor*)color {
    if (!image) {
        return;
    }
    
    // Set icon colors
    UIImage *imageNormal = color ? [image colorizeWithColor:color] : image;
    [self setImage:imageNormal forState:UIControlStateNormal];
    [self setImage:nil forState:UIControlStateSelected];
    [self setImage:nil forState:UIControlStateHighlighted];
    self.showsTouchWhenHighlighted = NO;
}

- (void)setDatabaseToolbarStyle:(UIImage*)image {
    if (!image) {
        return;
    }
    
    // Set icon colors
    UIImage *imageNormal = [image colorizeWithColor:ICON_TINT_COLOR];
    UIImage *imageActive = [image colorizeWithColor:ICON_TINT_COLOR_ACTIVE];
    [self setBackgroundImage:imageNormal forState:UIControlStateNormal];
    [self setBackgroundImage:imageActive forState:UIControlStateSelected];
    [self setBackgroundImage:nil forState:UIControlStateHighlighted];
    self.showsTouchWhenHighlighted = NO;
}

@end
