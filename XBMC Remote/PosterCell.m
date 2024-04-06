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

#define POSTER_CELL_ACTIVTYINDICATOR SHARED_CELL_ACTIVTYINDICATOR
#define POSTER_CELL_RECORDING_ICON SHARED_CELL_RECORDING_ICON

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
        _posterThumbnail.clipsToBounds = YES;
        _posterThumbnail.contentMode = UIViewContentModeScaleAspectFill;
        self.contentView.backgroundColor = UIColor.clearColor;
        [self.contentView addSubview:_posterThumbnail];
        
        _labelImageView = [[UIImageView alloc] initWithFrame:CGRectMake(borderWidth, frame.size.height - labelHeight, frame.size.width - borderWidth * 2, labelHeight - borderWidth)];
        _labelImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _labelImageView.image = [UIImage imageNamed:@"cell_bg"];
        _labelImageView.highlightedImage = [UIImage imageNamed:@"cell_bg_selected"];

        _posterLabel = [[PosterLabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width - borderWidth * 2, labelHeight - borderWidth)];
        _posterLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _posterLabel.backgroundColor = UIColor.clearColor;
        _posterLabel.textAlignment = NSTextAlignmentCenter;
        _posterLabel.textColor = UIColor.whiteColor;
        _posterLabel.shadowColor = [Utilities getGrayColor:0 alpha:0.6];
        _posterLabel.shadowOffset = CGSizeMake(0, 1);
        _posterLabel.numberOfLines = 2;
        _posterLabel.adjustsFontSizeToFitWidth = YES;
        _posterLabel.minimumScaleFactor = 1.0;

        [_labelImageView addSubview:_posterLabel];
        [self.contentView addSubview:_labelImageView];
        
        if (IS_IPAD) {
            _posterLabelFullscreen = [[PosterLabel alloc] initWithFrame:CGRectMake(0, frame.size.height, frame.size.width - borderWidth * 2, FULLSCREEN_LABEL_HEIGHT)];
            _posterLabelFullscreen.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            _posterLabelFullscreen.backgroundColor = UIColor.clearColor;
            _posterLabelFullscreen.textColor = UIColor.lightGrayColor;
            _posterLabelFullscreen.textAlignment = NSTextAlignmentCenter;
            _posterLabelFullscreen.numberOfLines = 1;
            _posterLabelFullscreen.adjustsFontSizeToFitWidth = NO;
            _posterLabelFullscreen.minimumScaleFactor = 1.0;
            [self.contentView addSubview:_posterLabelFullscreen];
        }

        _busyView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _busyView.hidesWhenStopped = YES;
        _busyView.center = CGPointMake(frame.size.width / 2, (frame.size.height / 2) - borderWidth);
        _busyView.tag = POSTER_CELL_ACTIVTYINDICATOR;
        [self.contentView addSubview:_busyView];

        UIView *bgView = [[UIView alloc] initWithFrame:frame];
        bgView.layer.borderWidth = borderWidth;
        bgView.layer.borderColor = [Utilities getSystemBlue].CGColor;
        self.selectedBackgroundView = bgView;
    }
    return self;
}

- (CGFloat)halfSizeIfRetina:(CGFloat)size {
    return size / UIScreen.mainScreen.scale;
}

- (void)setIsRecording:(BOOL)enable {
    if (enable) {
        if (isRecordingImageView == nil) {
            CGFloat dotSize = 8;
            isRecordingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(6, 6, dotSize, dotSize)];
            isRecordingImageView.image = [UIImage imageNamed:@"button_timer"];
            isRecordingImageView.contentMode = UIViewContentModeScaleToFill;
            isRecordingImageView.tag = POSTER_CELL_RECORDING_ICON;
            isRecordingImageView.backgroundColor = UIColor.clearColor;
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
            overlayWatched.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
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
