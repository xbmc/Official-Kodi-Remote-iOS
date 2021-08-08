//
//  PosterHeaderView.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 20/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "PosterHeaderView.h"
#import "QuartzCore/CALayer.h"
#import <QuartzCore/QuartzCore.h>
#import "PosterLabel.h"
#import "AppDelegate.h"
#import "Utilities.h"

@implementation PosterHeaderView

@synthesize headerLabel = _headerLabel;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = NO;
        self.restorationIdentifier = @"posterHeaderView";
        
        // Draw gray bar as section header background
        UIView *sectionView = [[UIView alloc] initWithFrame:self.bounds];
        sectionView.backgroundColor = [Utilities getGrayColor:44 alpha:1.0];
        [self insertSubview: sectionView atIndex:0];

        // Draw text into section header
        if (self.frame.size.height > 20) {
            _headerLabel = [[PosterLabel alloc] initWithFrame:CGRectMake(10, 0, self.frame.size.width - 20, self.frame.size.height)];
            _headerLabel.backgroundColor = UIColor.clearColor;
            _headerLabel.font = [UIFont boldSystemFontOfSize:self.frame.size.height - 10];
            _headerLabel.textColor = [Utilities getGrayColor:235 alpha:0.6];
            _headerLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight |
                                            UIViewAutoresizingFlexibleWidth |
                                            UIViewAutoresizingFlexibleLeftMargin |
                                            UIViewAutoresizingFlexibleRightMargin |
                                            UIViewAutoresizingFlexibleTopMargin |
                                            UIViewAutoresizingFlexibleBottomMargin;
            [self addSubview:_headerLabel];
        }
    }
    return self;
}

- (void)setHeaderText:(NSString*)text {
    _headerLabel.text = text;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
