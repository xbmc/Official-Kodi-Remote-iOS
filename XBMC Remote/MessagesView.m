//
//  MessagesView.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 8/4/14.
//  Copyright (c) 2014 joethefox inc. All rights reserved.
//

#import "MessagesView.h"
#import "AppDelegate.h"

@implementation MessagesView

@synthesize viewMessage;

- (id)initWithFrame:(CGRect)frame deltaY:(float)deltaY deltaX:(float)deltaX {
    self = [super initWithFrame:frame];
    if (self) {
        CALayer *bottomBorder = [CALayer layer];
        CGFloat borderSize = 1.0f;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            borderSize = 0.5f;
        }
        bottomBorder.frame = CGRectMake(0.0f, frame.size.height - borderSize, frame.size.width, borderSize);
        bottomBorder.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.35f].CGColor;
        [self.layer addSublayer:bottomBorder];
        [self setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.9f]];
        slideHeight = frame.size.height;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            slideHeight += 22.0f;
        }
        [self setFrame:CGRectMake(frame.origin.x, -slideHeight, frame.size.width, frame.size.height)];
        viewMessage = [[UILabel alloc] initWithFrame:CGRectMake(deltaX, deltaY, frame.size.width - deltaX, frame.size.height - deltaY)];
        [viewMessage setBackgroundColor:[UIColor clearColor]];
        [viewMessage setFont:[UIFont boldSystemFontOfSize:16]];
        [viewMessage setAdjustsFontSizeToFitWidth:YES];
        [viewMessage setMinimumFontSize:10];
        [viewMessage setTextColor:[UIColor whiteColor]];
        [viewMessage setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:viewMessage];
    }
    return self;
}

# pragma mark - view Effects

- (void)showMessage:(NSString *)message timeout:(float)timeout color:(UIColor *)color{
    // first slide out
    CGRect frame = self.frame;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.1];
    [self setFrame:CGRectMake(frame.origin.x, -slideHeight, frame.size.width, frame.size.height)];
    [UIView commitAnimations];
    [viewMessage setText:message];
    [self setBackgroundColor:color];
    // then slide in
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.2];
    [self setFrame:CGRectMake(frame.origin.x, 0, frame.size.width, frame.size.height)];
    [self setAlpha:1.0f];
    [UIView commitAnimations];
    //then slide out again after timeout seconds
    if ([fadeoutTimer isValid])
        [fadeoutTimer invalidate];
    fadeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(fadeoutMessage:) userInfo:nil repeats:NO];
}

- (void)fadeoutMessage:(NSTimer *)timer{
    CGRect frame = self.frame;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.4];
    [self setFrame:CGRectMake(frame.origin.x, -slideHeight, frame.size.width, frame.size.height)];
    [self setAlpha:0.0f];
    [UIView commitAnimations];
    [fadeoutTimer invalidate];
    fadeoutTimer = nil;
}

@end
