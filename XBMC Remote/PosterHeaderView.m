//
//  PosterHeaderView.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 20/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "PosterHeaderView.h"


@implementation PosterHeaderView

@synthesize headerLabel = _headerLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.restorationIdentifier = @"posterHeaderView";

        _headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        [_headerLabel setBackgroundColor:[UIColor clearColor]];
        [_headerLabel setFont:[UIFont boldSystemFontOfSize:12]];

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
