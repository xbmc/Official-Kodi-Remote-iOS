//
//  RecentlyAddedCell.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 1/4/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "RecentlyAddedCell.h"

@implementation RecentlyAddedCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.restorationIdentifier = @"recentlyAddedCell";
        self.backgroundColor = [UIColor lightGrayColor];
        float labelHeight = (int)(frame.size.height * 0.19f);
        float genreHeight = (int)(frame.size.height * 0.12f);
        float yearHeight = (int)(frame.size.height * 0.12f);
        int borderWidth = 2;
        int posterWidth = (int)(frame.size.height * 0.66f) + 1;
        int fanartWidth = frame.size.width - posterWidth;
//        int posterStartX = borderWidth * 2 + fanartWidth;
        int posterStartX = borderWidth;
//        int startX = borderWidth;
        int startX = borderWidth * 2 + posterWidth;

        _posterThumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(posterStartX, borderWidth, posterWidth, frame.size.height - borderWidth * 2)];
        [_posterThumbnail setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [_posterThumbnail setClipsToBounds:YES];
        [_posterThumbnail setContentMode:UIViewContentModeScaleAspectFill];
        [self.contentView addSubview:_posterThumbnail];
        
        _posterFanart = [[UIImageView alloc] initWithFrame:CGRectMake(startX, borderWidth, fanartWidth - borderWidth * 3, frame.size.height - borderWidth * 2)];
        [_posterFanart setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [_posterFanart setClipsToBounds:YES];
        [_posterFanart setContentMode:UIViewContentModeScaleAspectFit];
        _posterFanart.alpha = 0.9f;
        [self.contentView addSubview:_posterFanart];

        int frameHeight = labelHeight + genreHeight + yearHeight - borderWidth*2;
        UIImageView *labelImageView = [[UIImageView alloc] initWithFrame:CGRectMake(startX, frame.size.height - genreHeight - yearHeight - labelHeight + borderWidth*2, fanartWidth - borderWidth * 3, labelHeight + genreHeight + yearHeight - borderWidth*3)];
        [labelImageView setImage:[UIImage imageNamed:@"cell_bg"]];
        [labelImageView setHighlightedImage:[UIImage imageNamed:@"cell_bg_selected"]];
        
//        _posterLabel = [[PosterLabel alloc] initWithFrame:CGRectMake(borderWidth, frame.size.height - labelHeight, frame.size.width - borderWidth * 2, labelHeight - borderWidth)];
         _posterLabel = [[PosterLabel alloc] initWithFrame:CGRectMake(0, 0, fanartWidth - borderWidth * 3, labelHeight - borderWidth)];
        [_posterLabel setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [_posterLabel setBackgroundColor:[UIColor clearColor]];
        [_posterLabel setTextColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
        [_posterLabel setShadowColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6]];
        [_posterLabel setShadowOffset:CGSizeMake(0,1)];
        [_posterLabel setNumberOfLines:1];
        [_posterLabel setMinimumFontSize:8.0f];
        [_posterLabel setAdjustsFontSizeToFitWidth:YES];
        [labelImageView addSubview:_posterLabel];
        
        _posterGenre = [[PosterLabel alloc] initWithFrame:CGRectMake(0, frameHeight - genreHeight - yearHeight + borderWidth, fanartWidth - borderWidth * 3, genreHeight - borderWidth)];
        [_posterGenre setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [_posterGenre setBackgroundColor:[UIColor clearColor]];
        [_posterGenre setTextColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
        [_posterGenre setShadowColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6]];
        [_posterGenre setShadowOffset:CGSizeMake(0,1)];
        [_posterGenre setNumberOfLines:1];
        [_posterGenre setMinimumFontSize:8.0f];
        [_posterGenre setAdjustsFontSizeToFitWidth:YES];
        [labelImageView addSubview:_posterGenre];
        
        _posterYear = [[PosterLabel alloc] initWithFrame:CGRectMake(0, frameHeight - yearHeight, fanartWidth - borderWidth * 3, yearHeight - borderWidth)];
        [_posterYear setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [_posterYear setBackgroundColor:[UIColor clearColor]];
        [_posterYear setTextColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
        [_posterYear setShadowColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6]];
        [_posterYear setShadowOffset:CGSizeMake(0,1)];
        [_posterYear setNumberOfLines:1];
        [_posterYear setMinimumFontSize:8.0f];
        [_posterYear setAdjustsFontSizeToFitWidth:YES];
        [labelImageView addSubview:_posterYear];
        [self.contentView addSubview:labelImageView];

        UIView *bgView = [[UIView alloc] initWithFrame:frame];
        [bgView setBackgroundColor:[UIColor colorWithRed:0.0f green:132.0f/255.0f blue:1.0f alpha:1]];
        self.selectedBackgroundView = bgView;
    }
    return self;
}

-(void)setOverlayWatched:(BOOL)enable{
    if (enable == YES){
        if (overlayWatched == nil){
            overlayWatched = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"OverlayWatched"]];
            [overlayWatched setAutoresizingMask: UIViewAutoresizingFlexibleLeftMargin  | UIViewAutoresizingFlexibleBottomMargin];
            overlayWatched.frame = CGRectMake(self.contentView.frame.size.width - overlayWatched.frame.size.width - 4,
                                              self.contentView.frame.size.height - overlayWatched.frame.size.height - 4,
                                              overlayWatched.frame.size.width,
                                              overlayWatched.frame.size.height);
            [self.contentView addSubview:overlayWatched];
        }
        overlayWatched.hidden = NO;
    }
    else{
        overlayWatched.hidden = YES;
    }
}

@end