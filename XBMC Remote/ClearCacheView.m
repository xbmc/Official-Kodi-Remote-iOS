//
//  ClearCacheView.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 6/4/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "ClearCacheView.h"
#import "PosterLabel.h"

@implementation ClearCacheView

- (id)initWithFrame:(CGRect)frame{
    return [self initWithFrame:frame border:0];
}

- (id)initWithFrame:(CGRect)frame border:(int)borderWidth
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [self setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7]];
        float labelHeight = 300;
        PosterLabel *label = [[PosterLabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.frame)/2 - (labelHeight/2), CGRectGetWidth(self.frame) - borderWidth, labelHeight)];
         [label setAutoresizingMask:
          UIViewAutoresizingFlexibleHeight |
          UIViewAutoresizingFlexibleWidth |
          UIViewAutoresizingFlexibleRightMargin |
          UIViewAutoresizingFlexibleTopMargin |
          UIViewAutoresizingFlexibleBottomMargin];
        [label setText:NSLocalizedString(@"Clearing app disk cache...\n\nPlease wait, since this may take a while", nil)];
        [label setShadowColor:[UIColor blackColor]];
        [label setShadowOffset:CGSizeMake(1, 1)];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setNumberOfLines:0];
        [label setFont:[UIFont boldSystemFontOfSize:26]];
        [label setTextColor:[UIColor whiteColor]];
        [label setBackgroundColor:[UIColor clearColor]];
        busyView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        busyView.hidesWhenStopped = YES;
        [busyView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [busyView setFrame:CGRectMake((self.frame.size.width / 2) - busyView.frame.size.width/2 - borderWidth/2, label.frame.size.height + label.frame.origin.y, busyView.frame.size.width, busyView.frame.size.height)];
        [self addSubview:busyView];
        [self addSubview:label];
    }
    return self;
}

-(void)startActivityIndicator{
    [busyView startAnimating];
}

-(void)stopActivityIndicator{
    [busyView stopAnimating];
}

@end