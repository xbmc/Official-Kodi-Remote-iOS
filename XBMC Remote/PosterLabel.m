//
//  PosterLabel.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 17/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "PosterLabel.h"
//#import <QuartzCore/QuartzCore.h>

@implementation PosterLabel

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect{
//    UIEdgeInsets insets = {0, 5, 2, 5};
//    UIBezierPath* rounded = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight cornerRadii:CGSizeMake(5.0f, 5.0f)];
//    CAShapeLayer* shape = [[CAShapeLayer alloc] init];
//    [shape setPath:rounded.CGPath];
//    self.layer.mask = shape;
    UIEdgeInsets insets = {0, 3, 0, 3};
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

@end