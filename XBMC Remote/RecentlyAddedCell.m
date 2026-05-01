//
//  RecentlyAddedCell.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 1/4/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "RecentlyAddedCell.h"
#import "Utilities.h"
#import "AppDelegate.h"

#import "GeneratedAssetSymbols.h"

#define RECENTLY_ADDED_CELL_ACTIVTYINDICATOR SHARED_CELL_ACTIVTYINDICATOR
#define LABEL_PADDING 4
#define OVERLAY_PADDING 4
#define VERTICAL_PADDING 10

@implementation RecentlyAddedCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.restorationIdentifier = @"recentlyAddedCell";
        self.backgroundColor = UIColor.clearColor;
        self.contentView.clipsToBounds = YES;

        _posterThumbnail = [UIImageView new];
        _posterThumbnail.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _posterThumbnail.clipsToBounds = YES;
        _posterThumbnail.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_posterThumbnail];
        
        _posterFanart = [UIImageView new];
        _posterFanart.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _posterFanart.clipsToBounds = YES;
        _posterFanart.contentMode = UIViewContentModeScaleAspectFill;
        _posterFanart.alpha = 0.9;
        [self.contentView addSubview:_posterFanart];

        _labelImageView = [UIImageView new];
        _labelImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _labelImageView.image = [UIImage imageNamed:@"cell_bg"];
        _labelImageView.highlightedImage = [UIImage imageNamed:@"cell_bg_selected"];
        
        _posterLabel = [PosterLabel new];
        _posterLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _posterLabel.backgroundColor = UIColor.clearColor;
        _posterLabel.textColor = UIColor.whiteColor;
        _posterLabel.shadowColor = FONT_SHADOW_WEAK;
        _posterLabel.shadowOffset = CGSizeMake(0, 1);
        _posterLabel.numberOfLines = 1;
        _posterLabel.minimumScaleFactor = FONT_SCALING_MIN;
        _posterLabel.adjustsFontSizeToFitWidth = YES;
        [_labelImageView addSubview:_posterLabel];
        
        _posterGenre = [PosterLabel new];
        _posterGenre.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _posterGenre.backgroundColor = UIColor.clearColor;
        _posterGenre.textColor = UIColor.whiteColor;
        _posterGenre.shadowColor = FONT_SHADOW_WEAK;
        _posterGenre.shadowOffset = CGSizeMake(0, 1);
        _posterGenre.numberOfLines = 1;
        _posterGenre.minimumScaleFactor = FONT_SCALING_MIN;
        _posterGenre.adjustsFontSizeToFitWidth = YES;
        [_labelImageView addSubview:_posterGenre];
        
        _posterYear = [PosterLabel new];
        _posterYear.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _posterYear.backgroundColor = UIColor.clearColor;
        _posterYear.textColor = UIColor.whiteColor;
        _posterYear.shadowColor = FONT_SHADOW_WEAK;
        _posterYear.shadowOffset = CGSizeMake(0, 1);
        _posterYear.numberOfLines = 1;
        _posterYear.minimumScaleFactor = FONT_SCALING_MIN;
        _posterYear.adjustsFontSizeToFitWidth = YES;
        [_labelImageView addSubview:_posterYear];
        [self.contentView addSubview:_labelImageView];
        
        [self setRecentlyAddedCellLayout:frame];

        _busyView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _busyView.hidesWhenStopped = YES;
        _busyView.center = _posterThumbnail.center;
        _busyView.tag = RECENTLY_ADDED_CELL_ACTIVTYINDICATOR;
        [self.contentView addSubview:_busyView];
    }
    return self;
}

- (void)setOverlayWatched:(BOOL)enable {
    if (enable) {
        if (overlayWatched == nil) {
            overlayWatched = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ACImageNameOverlayWatched]];
            overlayWatched.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
            overlayWatched.frame = CGRectMake(self.contentView.frame.size.width - overlayWatched.frame.size.width - OVERLAY_PADDING,
                                              self.contentView.frame.size.height - overlayWatched.frame.size.height - OVERLAY_PADDING,
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

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    CALayer *layer = self.contentView.layer;
    layer.borderColor = [UIColor getSystemBlue].CGColor;
    layer.borderWidth = selected ? 1.0 / UIScreen.mainScreen.scale : 0;
}

- (void)setRecentlyAddedCellLayout:(CGRect)frame {
    CGFloat labelHeight = (floor)(frame.size.height * 0.18);
    CGFloat genreHeight = (floor)(frame.size.height * 0.12);
    CGFloat yearHeight = (floor)(frame.size.height * 0.10);
    CGFloat posterWidth = (ceil)(frame.size.height * 0.67);
    CGFloat fanartWidth = frame.size.width - posterWidth;
    CGFloat labelImageHeight = labelHeight + genreHeight + yearHeight + VERTICAL_PADDING;
    
    _posterThumbnail.frame = CGRectMake(0, 0, posterWidth, frame.size.height);
    
    _posterFanart.frame = CGRectMake(posterWidth, 0, fanartWidth, frame.size.height);
    
    _labelImageView.frame = CGRectMake(posterWidth,
                                       frame.size.height - labelImageHeight,
                                       fanartWidth,
                                       labelImageHeight);
    
    _posterLabel.frame = CGRectMake(LABEL_PADDING,
                                    VERTICAL_PADDING,
                                    fanartWidth - 2 * LABEL_PADDING,
                                    labelHeight);
    
    _posterGenre.frame = CGRectMake(LABEL_PADDING,
                                    CGRectGetMaxY(_posterLabel.frame),
                                    CGRectGetWidth(_posterLabel.frame),
                                    genreHeight);
    
    _posterYear.frame = CGRectMake(LABEL_PADDING,
                                   CGRectGetMaxY(_posterGenre.frame),
                                   CGRectGetWidth(_posterGenre.frame),
                                   yearHeight);
}

- (void)setRecentlyAddedCellLayoutManually:(CGRect)frame {
    _posterThumbnail.autoresizingMask = UIViewAutoresizingNone;
    _posterFanart.autoresizingMask = UIViewAutoresizingNone;
    _labelImageView.autoresizingMask = UIViewAutoresizingNone;
    _posterLabel.autoresizingMask = UIViewAutoresizingNone;
    _posterGenre.autoresizingMask = UIViewAutoresizingNone;
    _posterYear.autoresizingMask = UIViewAutoresizingNone;
    [self setRecentlyAddedCellLayout:frame];
}

@end
