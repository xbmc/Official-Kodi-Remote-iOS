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

#import "GeneratedAssetSymbols.h"

#define POSTER_CELL_ACTIVTYINDICATOR SHARED_CELL_ACTIVTYINDICATOR
#define POSTER_CELL_RECORDING_ICON SHARED_CELL_RECORDING_ICON
#define OVERLAY_OFFSET_X 2
#define OVERLAY_OFFSET_Y 1
#define REC_DOT_SIZE 8
#define REC_DOT_PADDING 6

@implementation PosterCell

@synthesize posterThumbnail = _posterThumbnail;
@synthesize labelImageView = _labelImageView;
@synthesize posterLabel = _posterLabel;
@synthesize posterLabelFullscreen = _posterLabelFullscreen;
@synthesize busyView = _busyView;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.restorationIdentifier = @"posterCell";
        _posterThumbnail = [UIImageView new];
        _posterThumbnail.clipsToBounds = YES;
        _posterThumbnail.contentMode = UIViewContentModeScaleAspectFill;
        self.contentView.backgroundColor = UIColor.clearColor;
        [self.contentView addSubview:_posterThumbnail];
        
        _labelImageView = [UIImageView new];
        _labelImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _labelImageView.image = [UIImage imageNamed:@"cell_bg"];
        _labelImageView.highlightedImage = [UIImage imageNamed:@"cell_bg_selected"];

        _posterLabel = [PosterLabel new];
        _posterLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _posterLabel.backgroundColor = UIColor.clearColor;
        _posterLabel.textAlignment = NSTextAlignmentCenter;
        _posterLabel.textColor = UIColor.whiteColor;
        _posterLabel.shadowColor = FONT_SHADOW_WEAK;
        _posterLabel.shadowOffset = CGSizeMake(0, 1);
        _posterLabel.numberOfLines = 2;
        _posterLabel.adjustsFontSizeToFitWidth = YES;
        _posterLabel.minimumScaleFactor = FONT_SCALING_NONE;

        [_labelImageView addSubview:_posterLabel];
        [_posterThumbnail addSubview:_labelImageView];
        
        if (IS_IPAD) {
            _posterLabelFullscreen = [PosterLabel new];
            _posterLabelFullscreen.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
            _posterLabelFullscreen.backgroundColor = UIColor.clearColor;
            _posterLabelFullscreen.textColor = UIColor.lightGrayColor;
            _posterLabelFullscreen.textAlignment = NSTextAlignmentCenter;
            _posterLabelFullscreen.numberOfLines = 1;
            _posterLabelFullscreen.adjustsFontSizeToFitWidth = NO;
            _posterLabelFullscreen.minimumScaleFactor = FONT_SCALING_NONE;
            [self.contentView addSubview:_posterLabelFullscreen];
        }
        
        [self setPosterCellLayout:frame];

        _busyView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _busyView.hidesWhenStopped = YES;
        _busyView.center = _posterThumbnail.center;
        _busyView.tag = POSTER_CELL_ACTIVTYINDICATOR;
        [self.contentView addSubview:_busyView];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    CALayer *layer = self.contentView.layer;
    layer.borderColor = [UIColor getSystemBlue].CGColor;
    layer.borderWidth = selected ? 1.0 / UIScreen.mainScreen.scale : 0;
}

- (void)setIsRecording:(BOOL)enable {
    if (enable) {
        if (isRecordingImageView == nil) {
            isRecordingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(REC_DOT_PADDING, REC_DOT_PADDING, REC_DOT_SIZE, REC_DOT_SIZE)];
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
            overlayWatched = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ACImageNameOverlayWatched]];
            overlayWatched.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
            overlayWatched.frame = CGRectMake(self.contentView.frame.size.width - overlayWatched.frame.size.width + OVERLAY_OFFSET_X,
                                              self.contentView.frame.size.height - overlayWatched.frame.size.height + OVERLAY_OFFSET_Y,
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

- (void)setPosterCellLayout:(CGRect)frame {
    CGFloat labelHeight = ceil(frame.size.height * 0.19);
    
    _posterThumbnail.frame = CGRectMake(0,
                                        0,
                                        frame.size.width,
                                        frame.size.height);
    
    _labelImageView.frame = CGRectMake(0,
                                       _posterThumbnail.frame.size.height - labelHeight,
                                       _posterThumbnail.frame.size.width,
                                       labelHeight);
    
    _posterLabel.frame = CGRectMake(0,
                                    0,
                                    _labelImageView.frame.size.width,
                                    _labelImageView.frame.size.height);
    
    _posterLabelFullscreen.frame = CGRectMake(0,
                                              frame.size.height,
                                              frame.size.width,
                                              FULLSCREEN_LABEL_HEIGHT);
}

- (void)setPosterCellLayoutManually:(CGRect)frame {
    _posterThumbnail.autoresizingMask = UIViewAutoresizingNone;
    _labelImageView.autoresizingMask = UIViewAutoresizingNone;
    _posterLabel.autoresizingMask = UIViewAutoresizingNone;
    _posterLabelFullscreen.autoresizingMask = UIViewAutoresizingNone;
    [self setPosterCellLayout:frame];
}

@end
