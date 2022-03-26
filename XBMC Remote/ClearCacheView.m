//
//  ClearCacheView.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 6/4/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "ClearCacheView.h"
#import "PosterLabel.h"
#import "Utilities.h"
#import "AppDelegate.h"

@implementation ClearCacheView

- (id)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame border:0];
}

- (id)initWithFrame:(CGRect)frame border:(int)borderWidth {
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [Utilities getGrayColor:0 alpha:0.7];
        CGFloat labelHeight = 300.0;
        PosterLabel *label = [[PosterLabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.frame) / 2 - labelHeight / 2, CGRectGetWidth(self.frame) - borderWidth, labelHeight)];
        label.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        label.text = LOCALIZED_STR(@"Clearing app disk cache...\n\nPlease wait, since this may take a while");
        label.shadowColor = UIColor.blackColor;
        label.shadowOffset = CGSizeMake(1, 1);
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.font = [UIFont boldSystemFontOfSize:26];
        label.textColor = UIColor.whiteColor;
        label.backgroundColor = UIColor.clearColor;
        busyView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        busyView.hidesWhenStopped = YES;
        busyView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        busyView.frame = CGRectMake(self.frame.size.width / 2 - busyView.frame.size.width / 2 - borderWidth / 2, label.frame.size.height + label.frame.origin.y, busyView.frame.size.width, busyView.frame.size.height);
        [self addSubview:busyView];
        [self addSubview:label];
    }
    return self;
}

- (void)startActivityIndicator {
    [busyView startAnimating];
}

- (void)stopActivityIndicator {
    [busyView stopAnimating];
}

@end
