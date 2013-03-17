//
//  PosterCell.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 17/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PosterLabel.h"

@interface PosterCell : UICollectionViewCell

@property (nonatomic, readonly) UIImageView *posterThumbnail;
@property (nonatomic, readonly) PosterLabel *posterLabel;

@end