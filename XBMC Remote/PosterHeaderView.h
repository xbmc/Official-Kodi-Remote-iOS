//
//  PosterHeaderView.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 20/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "PosterLabel.h"

@import UIKit;

@interface PosterHeaderView : UICollectionReusableView

@property (nonatomic, readonly) UILabel *headerLabel;

- (void)setHeaderText:(NSString*)text;

@end
