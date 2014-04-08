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
        self.alpha = 0.0f;
        [self setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.9f]];
        
        CGRect toolbarShadowFrame = CGRectMake(0.0f, frame.size.height, frame.size.width, 4);
        UIImageView *toolbarShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
        [toolbarShadow setImage:[UIImage imageNamed:@"tableUp.png"]];
        toolbarShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbarShadow.contentMode = UIViewContentModeScaleToFill;
        toolbarShadow.opaque = YES;
        toolbarShadow.alpha = 0.5f;
        [self addSubview:toolbarShadow];
        
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
    // first fadeout
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.1];
    self.alpha = 0;
    [UIView commitAnimations];
    [viewMessage setText:message];
    [self setBackgroundColor:color];
    // then fade in
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.3];
    self.hidden = NO;
    self.alpha = 1.0;
    [UIView commitAnimations];
    //then fade out again after timeout seconds
    if ([fadeoutTimer isValid])
        [fadeoutTimer invalidate];
    fadeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(fadeoutMessage:) userInfo:nil repeats:NO];
}

- (void)fadeoutMessage:(NSTimer *)timer{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.6];
    self.alpha = 0;
    [UIView commitAnimations];
    [fadeoutTimer invalidate];
    fadeoutTimer = nil;
}

@end
