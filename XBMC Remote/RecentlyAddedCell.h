//
//  RecentlyAddedCell.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 1/4/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "PosterLabel.h"

@import UIKit;

@interface RecentlyAddedCell : UICollectionViewCell {
    UIImageView *overlayWatched;
}

- (void)setOverlayWatched:(BOOL)enable;
- (void)setRecentlyAddedCellLayoutManually:(CGRect)frame;

@property (nonatomic, readonly) UIImageView *posterThumbnail;
@property (nonatomic, readonly) UIImageView *posterFanart;
@property (nonatomic, readonly) UIImageView *labelImageView;
@property (nonatomic, readonly) PosterLabel *posterLabel;
@property (nonatomic, readonly) PosterLabel *posterGenre;
@property (nonatomic, readonly) PosterLabel *posterYear;
@property (nonatomic, readonly) UIActivityIndicatorView *busyView;

@end
