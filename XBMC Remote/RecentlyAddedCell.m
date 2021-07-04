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

@implementation RecentlyAddedCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.restorationIdentifier = @"recentlyAddedCell";
        self.backgroundColor = [UIColor grayColor];
        int labelHeight = (int)(frame.size.height * 0.19);
        int genreHeight = (int)(frame.size.height * 0.12);
        int yearHeight = (int)(frame.size.height * 0.12);
        int borderWidth = 2;
        int posterWidth = (int)(frame.size.height * 0.66) + 1;
        int fanartWidth = frame.size.width - posterWidth;
        int posterStartX = borderWidth;
        int startX = borderWidth * 2 + posterWidth;

        _posterThumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(posterStartX, borderWidth, posterWidth, frame.size.height - borderWidth * 2)];
        [_posterThumbnail setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [_posterThumbnail setClipsToBounds:YES];
        [_posterThumbnail setContentMode:UIViewContentModeScaleAspectFill];
        [self.contentView addSubview:_posterThumbnail];
        
        _posterFanart = [[UIImageView alloc] initWithFrame:CGRectMake(startX, borderWidth, fanartWidth - borderWidth * 3, frame.size.height - borderWidth * 2)];
        [_posterFanart setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [_posterFanart setClipsToBounds:YES];
        [_posterFanart setContentMode:UIViewContentModeScaleAspectFill];
        _posterFanart.alpha = 0.9;
        [self.contentView addSubview:_posterFanart];

        int frameHeight = labelHeight + genreHeight + yearHeight - borderWidth*2;
        UIImageView *labelImageView = [[UIImageView alloc] initWithFrame:CGRectMake(startX, frame.size.height - genreHeight - yearHeight - labelHeight + borderWidth*2, fanartWidth - borderWidth * 3, labelHeight + genreHeight + yearHeight - borderWidth*3)];
        [labelImageView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];

        [labelImageView setImage:[UIImage imageNamed:@"cell_bg"]];
        [labelImageView setHighlightedImage:[UIImage imageNamed:@"cell_bg_selected"]];
        
        int posterYOffset = 4;
        int labelPadding = 4;
        if (IS_IPHONE) {
            posterYOffset = 0;
        }
         _posterLabel = [[PosterLabel alloc] initWithFrame:CGRectMake(labelPadding, posterYOffset, fanartWidth - labelPadding -borderWidth * 4, labelHeight - borderWidth)];
        [_posterLabel setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [_posterLabel setBackgroundColor:[UIColor clearColor]];
        [_posterLabel setTextColor:[UIColor whiteColor]];
        [_posterLabel setShadowColor:[Utilities getGrayColor:0 alpha:0.6]];
        [_posterLabel setShadowOffset:CGSizeMake(0, 1)];
        [_posterLabel setNumberOfLines:1];
        [_posterLabel setMinimumScaleFactor:0.5];
        [_posterLabel setAdjustsFontSizeToFitWidth:YES];
        [labelImageView addSubview:_posterLabel];
        
        _posterGenre = [[PosterLabel alloc] initWithFrame:CGRectMake(labelPadding, frameHeight - genreHeight - yearHeight + borderWidth, fanartWidth - labelPadding - borderWidth * 4, genreHeight - borderWidth)];
        [_posterGenre setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [_posterGenre setBackgroundColor:[UIColor clearColor]];
        [_posterGenre setTextColor:[UIColor whiteColor]];
        [_posterGenre setShadowColor:[Utilities getGrayColor:0 alpha:0.6]];
        [_posterGenre setShadowOffset:CGSizeMake(0, 1)];
        [_posterGenre setNumberOfLines:1];
        [_posterGenre setMinimumScaleFactor:0.5];
        [_posterGenre setAdjustsFontSizeToFitWidth:YES];
        [labelImageView addSubview:_posterGenre];
        
        _posterYear = [[PosterLabel alloc] initWithFrame:CGRectMake(labelPadding, frameHeight - yearHeight, fanartWidth - labelPadding - borderWidth * 4, yearHeight - borderWidth)];
        [_posterYear setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [_posterYear setBackgroundColor:[UIColor clearColor]];
        [_posterYear setTextColor:[UIColor whiteColor]];
        [_posterYear setShadowColor:[Utilities getGrayColor:0 alpha:0.6]];
        [_posterYear setShadowOffset:CGSizeMake(0, 1)];
        [_posterYear setNumberOfLines:1];
        [_posterYear setMinimumScaleFactor:0.5];
        [_posterYear setAdjustsFontSizeToFitWidth:YES];
        [labelImageView addSubview:_posterYear];
        [self.contentView addSubview:labelImageView];

        _busyView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _busyView.hidesWhenStopped = YES;
        _busyView.center = CGPointMake(frame.size.width / 2 + _posterThumbnail.frame.size.width / 2 + borderWidth / 2, (frame.size.height / 2) - borderWidth);
        _busyView.tag = 8;
        [self.contentView addSubview:_busyView];
        
        UIView *bgView = [[UIView alloc] initWithFrame:frame];
        bgView.layer.borderWidth = borderWidth;
        bgView.layer.borderColor = [Utilities getSystemGreen:1.0].CGColor;
        self.selectedBackgroundView = bgView;
    }
    return self;
}

- (void)setOverlayWatched:(BOOL)enable {
    if (enable) {
        if (overlayWatched == nil) {
            overlayWatched = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"OverlayWatched"]];
            [overlayWatched setAutoresizingMask: UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin];
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
