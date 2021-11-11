//
//  MessagesView.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 8/4/14.
//  Copyright (c) 2014 joethefox inc. All rights reserved.
//

#import "MessagesView.h"
#import "AppDelegate.h"
#import "Utilities.h"

@implementation MessagesView

@synthesize viewMessage;

- (id)initWithFrame:(CGRect)frame deltaY:(CGFloat)deltaY deltaX:(CGFloat)deltaX {
    self = [super initWithFrame:frame];
    if (self) {
        CALayer *bottomBorder = [CALayer layer];
        CGFloat borderSize = 0.5;
        bottomBorder.frame = CGRectMake(0.0, frame.size.height - borderSize, frame.size.width, borderSize);
        bottomBorder.backgroundColor = [Utilities getGrayColor:0 alpha:0.35].CGColor;
        [self.layer addSublayer:bottomBorder];
        self.backgroundColor = [Utilities getGrayColor:0 alpha:0.9];
        slideHeight = frame.size.height;
        if (IS_IPAD) {
            slideHeight += 22.0;
        }
        self.frame = CGRectMake(frame.origin.x, -slideHeight, frame.size.width, frame.size.height);
        viewMessage = [[UILabel alloc] initWithFrame:CGRectMake(deltaX, deltaY, frame.size.width - deltaX, frame.size.height - deltaY)];
        viewMessage.backgroundColor = UIColor.clearColor;
        viewMessage.font = [UIFont boldSystemFontOfSize:16];
        viewMessage.adjustsFontSizeToFitWidth = YES;
        viewMessage.minimumScaleFactor = 10.0 / 16.0;
        viewMessage.textColor = UIColor.whiteColor;
        viewMessage.textAlignment = NSTextAlignmentCenter;
        viewMessage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:viewMessage];
    }
    return self;
}

# pragma mark - view Effects

- (void)showMessage:(NSString*)message timeout:(NSTimeInterval)timeout color:(UIColor*)color {
    // first slide out
    CGRect frame = self.frame;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.1];
    self.frame = CGRectMake(frame.origin.x, -slideHeight, frame.size.width, frame.size.height);
    [UIView commitAnimations];
    viewMessage.text = message;
    self.backgroundColor = color;
    // then slide in
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.2];
    self.frame = CGRectMake(frame.origin.x, 0, frame.size.width, frame.size.height);
    self.alpha = 1.0;
    [UIView commitAnimations];
    //then slide out again after timeout seconds
    if ([fadeoutTimer isValid]) {
        [fadeoutTimer invalidate];
    }
    fadeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(fadeoutMessage:) userInfo:nil repeats:NO];
}

- (void)fadeoutMessage:(NSTimer*)timer {
    CGRect frame = self.frame;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.4];
    self.frame = CGRectMake(frame.origin.x, -slideHeight, frame.size.width, frame.size.height);
    self.alpha = 0.0;
    [UIView commitAnimations];
    [fadeoutTimer invalidate];
    fadeoutTimer = nil;
}

@end
