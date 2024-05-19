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

#define RECENTLY_ADDED_CELL_ACTIVTYINDICATOR SHARED_CELL_ACTIVTYINDICATOR

@implementation RecentlyAddedCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.restorationIdentifier = @"recentlyAddedCell";
        self.backgroundColor = UIColor.clearColor;
        CGFloat labelHeight = (floor)(frame.size.height * 0.18);
        CGFloat genreHeight = (floor)(frame.size.height * 0.11);
        CGFloat yearHeight = (floor)(frame.size.height * 0.11);
        CGFloat borderWidth = 1.0 / UIScreen.mainScreen.scale;
        CGFloat posterWidth = (ceil)(frame.size.height * 0.67);
        CGFloat fanartWidth = frame.size.width - posterWidth;
        CGFloat posterStartX = borderWidth;
        CGFloat startX = borderWidth * 2 + posterWidth;

        _posterThumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(posterStartX, borderWidth, posterWidth, frame.size.height - borderWidth * 2)];
        _posterThumbnail.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _posterThumbnail.clipsToBounds = YES;
        _posterThumbnail.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_posterThumbnail];
        
        _posterFanart = [[UIImageView alloc] initWithFrame:CGRectMake(startX, borderWidth, fanartWidth - borderWidth * 3, frame.size.height - borderWidth * 2)];
        _posterFanart.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _posterFanart.clipsToBounds = YES;
        _posterFanart.contentMode = UIViewContentModeScaleAspectFill;
        _posterFanart.alpha = 0.9;
        [self.contentView addSubview:_posterFanart];

        int frameHeight = labelHeight + genreHeight + yearHeight - borderWidth * 2;
        UIImageView *labelImageView = [[UIImageView alloc] initWithFrame:CGRectMake(startX, frame.size.height - genreHeight - yearHeight - labelHeight + borderWidth * 2, fanartWidth - borderWidth * 3, labelHeight + genreHeight + yearHeight - borderWidth * 3)];
        labelImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

        labelImageView.image = [UIImage imageNamed:@"cell_bg"];
        labelImageView.highlightedImage = [UIImage imageNamed:@"cell_bg_selected"];
        
        CGFloat posterYOffset = IS_IPAD ? 4 : 0;
        CGFloat labelPadding = 4;
         _posterLabel = [[PosterLabel alloc] initWithFrame:CGRectMake(labelPadding, posterYOffset, fanartWidth - labelPadding - borderWidth * 4, labelHeight - borderWidth)];
        _posterLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _posterLabel.backgroundColor = UIColor.clearColor;
        _posterLabel.textColor = UIColor.whiteColor;
        _posterLabel.shadowColor = [Utilities getGrayColor:0 alpha:0.6];
        _posterLabel.shadowOffset = CGSizeMake(0, 1);
        _posterLabel.numberOfLines = 1;
        _posterLabel.minimumScaleFactor = 0.5;
        _posterLabel.adjustsFontSizeToFitWidth = YES;
        [labelImageView addSubview:_posterLabel];
        
        _posterGenre = [[PosterLabel alloc] initWithFrame:CGRectMake(labelPadding, frameHeight - genreHeight - yearHeight + borderWidth, fanartWidth - labelPadding - borderWidth * 4, genreHeight - borderWidth)];
        _posterGenre.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _posterGenre.backgroundColor = UIColor.clearColor;
        _posterGenre.textColor = UIColor.whiteColor;
        _posterGenre.shadowColor = [Utilities getGrayColor:0 alpha:0.6];
        _posterGenre.shadowOffset = CGSizeMake(0, 1);
        _posterGenre.numberOfLines = 1;
        _posterGenre.minimumScaleFactor = 0.5;
        _posterGenre.adjustsFontSizeToFitWidth = YES;
        [labelImageView addSubview:_posterGenre];
        
        _posterYear = [[PosterLabel alloc] initWithFrame:CGRectMake(labelPadding, frameHeight - yearHeight, fanartWidth - labelPadding - borderWidth * 4, yearHeight - borderWidth)];
        _posterYear.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _posterYear.backgroundColor = UIColor.clearColor;
        _posterYear.textColor = UIColor.whiteColor;
        _posterYear.shadowColor = [Utilities getGrayColor:0 alpha:0.6];
        _posterYear.shadowOffset = CGSizeMake(0, 1);
        _posterYear.numberOfLines = 1;
        _posterYear.minimumScaleFactor = 0.5;
        _posterYear.adjustsFontSizeToFitWidth = YES;
        [labelImageView addSubview:_posterYear];
        [self.contentView addSubview:labelImageView];

        _busyView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _busyView.hidesWhenStopped = YES;
        _busyView.center = CGPointMake(frame.size.width / 2 + _posterThumbnail.frame.size.width / 2 + borderWidth / 2, frame.size.height / 2 - borderWidth);
        _busyView.tag = RECENTLY_ADDED_CELL_ACTIVTYINDICATOR;
        [self.contentView addSubview:_busyView];
        
        UIView *bgView = [[UIView alloc] initWithFrame:frame];
        bgView.layer.borderWidth = borderWidth;
        bgView.layer.borderColor = [Utilities getSystemBlue].CGColor;
        self.selectedBackgroundView = bgView;
    }
    return self;
}

- (void)setOverlayWatched:(BOOL)enable {
    if (enable) {
        if (overlayWatched == nil) {
            overlayWatched = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"OverlayWatched"]];
            overlayWatched.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
            overlayWatched.frame = CGRectMake(self.contentView.frame.size.width - overlayWatched.frame.size.width - 4,
                                              self.contentView.frame.size.height - overlayWatched.frame.size.height - 4,
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
