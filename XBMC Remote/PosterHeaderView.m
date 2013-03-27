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

@implementation PosterHeaderView

@synthesize headerLabel = _headerLabel;

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.restorationIdentifier = @"posterHeaderView";
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.bounds;
        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:.6 green:.6 blue:.6 alpha:.95] CGColor], (id)[[UIColor colorWithRed:.9 green:.9 blue:.9 alpha:.95] CGColor], nil];
        [self.layer insertSublayer:gradient atIndex:0];

        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 1)];
        [lineView setBackgroundColor:[UIColor colorWithRed:130.0f/255.0f green:130.0f/255.0f blue:130.0f/255.0f alpha:1]];
        [self addSubview:lineView];
        
        UIView *lineViewBottom = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 1, self.frame.size.width, 1)];
        [lineViewBottom setBackgroundColor:[UIColor colorWithRed:154.0f/255.0f green:154.0f/255.0f blue:154.0f/255.0f alpha:1]];
        [self addSubview:lineViewBottom];

        _headerLabel = [[PosterLabel alloc] initWithFrame:CGRectMake(10, 0, self.frame.size.width - 10, self.frame.size.height - 1)];
        [_headerLabel setBackgroundColor:[UIColor clearColor]];
        [_headerLabel setFont:[UIFont boldSystemFontOfSize:17]];
        [_headerLabel setShadowColor:[UIColor darkGrayColor]];
        [_headerLabel setShadowOffset:CGSizeMake(0, 1)];

        [_headerLabel setTextColor:[UIColor whiteColor]];
        [_headerLabel setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];

        [self addSubview:_headerLabel];
    }
    return self;
}

- (void) setHeaderText:(NSString *)text{
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
