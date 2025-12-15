//
//  PosterHeaderView.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 20/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "PosterHeaderView.h"
#import "PosterLabel.h"
#import "AppDelegate.h"
#import "Utilities.h"

@import QuartzCore;

#define LABEL_PADDING 10

@implementation PosterHeaderView

@synthesize headerLabel = _headerLabel;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = NO;
        self.restorationIdentifier = @"posterHeaderView";
        self.backgroundColor = GRIDVIEW_SECTION_COLOR;

        // Draw text into section header
        if (self.frame.size.height > 2 * LABEL_PADDING) {
            _headerLabel = [[PosterLabel alloc] initWithFrame:CGRectMake(LABEL_PADDING, 0, self.frame.size.width - 2 * LABEL_PADDING, self.frame.size.height)];
            _headerLabel.backgroundColor = UIColor.clearColor;
            _headerLabel.font = [UIFont boldSystemFontOfSize:self.frame.size.height - 10];
            _headerLabel.textColor = UIColor.lightGrayColor;
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
