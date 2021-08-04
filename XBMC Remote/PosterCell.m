//
//  PosterCell.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 17/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "PosterCell.h"
#import "Utilities.h"
#import "AppDelegate.h"

@implementation PosterCell

@synthesize posterThumbnail = _posterThumbnail;
@synthesize labelImageView = _labelImageView;
@synthesize posterLabel = _posterLabel;
@synthesize posterLabelFullscreen = _posterLabelFullscreen;
@synthesize busyView = _busyView;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat labelHeight = ceil(frame.size.height * 0.19);
        CGFloat borderWidth = [self halfSizeIfRetina:1.0];
        self.restorationIdentifier = @"posterCell";
        _posterThumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(borderWidth, borderWidth, frame.size.width - borderWidth * 2, frame.size.height - borderWidth * 2)];
        [_posterThumbnail setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin];
        [_posterThumbnail setClipsToBounds:YES];
        [_posterThumbnail setContentMode:UIViewContentModeScaleAspectFill];
        [self.contentView addSubview:_posterThumbnail];
        
        _labelImageView = [[UIImageView alloc] initWithFrame:CGRectMake(borderWidth, frame.size.height - labelHeight, frame.size.width - borderWidth * 2, labelHeight - borderWidth)];
        [_labelImageView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [_labelImageView setImage:[UIImage imageNamed:@"cell_bg"]];
        [_labelImageView setHighlightedImage:[UIImage imageNamed:@"cell_bg_selected"]];

        _posterLabel = [[PosterLabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width - borderWidth * 2, labelHeight - borderWidth)];
        [_posterLabel setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [_posterLabel setBackgroundColor:[UIColor clearColor]];
        [_posterLabel setTextAlignment:NSTextAlignmentCenter];
        [_posterLabel setTextColor:[UIColor whiteColor]];
        [_posterLabel setShadowColor:[Utilities getGrayColor:0 alpha:0.6]];
        [_posterLabel setShadowOffset:CGSizeMake(0, 1)];
        [_posterLabel setNumberOfLines:2];
        [_posterLabel setMinimumScaleFactor:0.8];
        [_posterLabel setAdjustsFontSizeToFitWidth:YES];
        [_posterLabel setMinimumScaleFactor:1.0];

        [_labelImageView addSubview:_posterLabel];
        [self.contentView addSubview:_labelImageView];
        
        if (IS_IPAD) {
            _posterLabelFullscreen = [[PosterLabel alloc] initWithFrame:CGRectMake(0, frame.size.height, frame.size.width - borderWidth * 2, labelHeight/2)];
            [_posterLabelFullscreen setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
            [_posterLabelFullscreen setBackgroundColor:[UIColor clearColor]];
            [_posterLabelFullscreen setTextColor:[UIColor grayColor]];
            [_posterLabelFullscreen setTextAlignment:NSTextAlignmentCenter];
            [_posterLabelFullscreen setNumberOfLines:1];
            [_posterLabelFullscreen setMinimumScaleFactor:0.8];
            [_posterLabelFullscreen setAdjustsFontSizeToFitWidth:NO];
            [_posterLabelFullscreen setMinimumScaleFactor:1.0];
            [self.contentView addSubview:_posterLabelFullscreen];
        }

        _busyView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _busyView.hidesWhenStopped = YES;
        _busyView.center = CGPointMake(frame.size.width / 2, (frame.size.height / 2) - borderWidth);
        _busyView.tag = 8;
        [self.contentView addSubview:_busyView];

        UIView *bgView = [[UIView alloc] initWithFrame:frame];
        bgView.layer.borderWidth = borderWidth;
        bgView.layer.borderColor = [Utilities getSystemGreen:1.0].CGColor;
        self.selectedBackgroundView = bgView;
    }
    return self;
}

- (CGFloat)halfSizeIfRetina:(CGFloat)size {
    return size / [[UIScreen mainScreen] scale];
}

- (void)setIsRecording:(BOOL)enable {
    if (enable) {
        if (isRecordingImageView == nil) {
            CGFloat dotSize = 8;
            isRecordingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(6, 6, dotSize, dotSize)];
            [isRecordingImageView setImage:[UIImage imageNamed:@"button_timer"]];
            [isRecordingImageView setContentMode:UIViewContentModeScaleToFill];
            isRecordingImageView.tag = 104;
            [isRecordingImageView setBackgroundColor:[UIColor clearColor]];
            [self.contentView addSubview:isRecordingImageView];
        }
        isRecordingImageView.hidden = NO;
    }
    else {
        isRecordingImageView.hidden = YES;
    }
}

- (void)setOverlayWatched:(BOOL)enable {
    if (enable) {
        if (overlayWatched == nil) {
            overlayWatched = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"OverlayWatched"]];
            [overlayWatched setAutoresizingMask: UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin];
            overlayWatched.frame = CGRectMake(self.contentView.frame.size.width - overlayWatched.frame.size.width + 2,
                                              self.contentView.frame.size.height - overlayWatched.frame.size.height + 1,
                                              overlayWatched.frame.size.width,
                                              overlayWatched.frame.size.height);
            [self.contentView addSubview:overlayWatched];
        }
        overlayWatched.hidden = NO;
    }
    else {
        overlayWatched.hidden = YES;
    }
}

@end
