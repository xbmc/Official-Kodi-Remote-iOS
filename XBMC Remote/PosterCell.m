//
//  PosterCell.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 17/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "PosterCell.h"

@implementation PosterCell

@synthesize posterThumbnail = _posterThumbnail;
@synthesize posterLabel = _posterLabel;

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        float labelHeight = (int)(frame.size.height * 0.22f);
        _posterThumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [_posterThumbnail setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [_posterThumbnail setClipsToBounds:YES];
        [_posterThumbnail setContentMode:UIViewContentModeScaleAspectFill];
        [_posterThumbnail setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];
        [self addSubview:_posterThumbnail];
        
        _posterLabel = [[PosterLabel alloc] initWithFrame:CGRectMake(0, frame.size.height - labelHeight, frame.size.width, labelHeight)];
        [_posterLabel setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6]];
        [_posterLabel setTextColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
        [_posterLabel setShadowColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6]];
        [_posterLabel setShadowOffset:CGSizeMake(0,1)];
        [_posterLabel setFont:[UIFont boldSystemFontOfSize:11.0f]];
        [_posterLabel setNumberOfLines:3];
        [_posterLabel setMinimumFontSize:8.0f];
        [_posterLabel setAdjustsFontSizeToFitWidth:YES];
        [self addSubview:_posterLabel];
    }
    return self;
}

@end