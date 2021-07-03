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
        [self setClipsToBounds:NO];
        self.restorationIdentifier = @"posterHeaderView";
        
//        if (self.frame.size.height > 0) {
//            UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 1)];
//            [lineView setBackgroundColor:[Utilities getGrayColor:130 alpha:1]];
//            [self addSubview:lineView];
//        }
        
        if (self.frame.size.height > 1) {
            //TYPE 1
            UIToolbar *buttonsToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
            [buttonsToolbar setBarStyle:UIBarStyleBlack];
            [buttonsToolbar setTranslucent:YES];
            [self insertSubview: buttonsToolbar atIndex:0];
            
            // TYPE 2
//            [self setBackgroundColor:[Utilities getGrayColor:30 alpha:0.95]];
            
            // TYPE 3
//            CAGradientLayer *gradient = [CAGradientLayer layer];
//            gradient.frame = self.bounds;
//            gradient.colors = @[(id)[[Utilities getGrayColor:75 alpha:0.95] CGColor], (id)[[Utilities getGrayColor:35 alpha:0.95] CGColor]];
//            [self.layer insertSublayer:gradient atIndex:0];
        }

        if (self.frame.size.height > 10) {
            _headerLabel = [[PosterLabel alloc] initWithFrame:CGRectMake(10, 0, self.frame.size.width - 10, self.frame.size.height - 1)];
            [_headerLabel setBackgroundColor:[UIColor clearColor]];
            [_headerLabel setFont:[UIFont boldSystemFontOfSize:(self.frame.size.height > 20 ? 17 : self.frame.size.height - 5)]];
            [_headerLabel setShadowColor:[Utilities getGrayColor:10 alpha:1]];
            [_headerLabel setShadowOffset:CGSizeZero];
            
            [_headerLabel setTextColor:[Utilities getGrayColor:120 alpha:1]];
            [_headerLabel setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
            
            [self addSubview:_headerLabel];
        }
        
        CGRect toolbarShadowFrame = CGRectMake(0, self.frame.size.height - 1, self.frame.size.width, 4);
        UIImageView *toolbarShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
        [toolbarShadow setImage:[UIImage imageNamed:@"tableUp"]];
        toolbarShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbarShadow.contentMode = UIViewContentModeScaleToFill;
        toolbarShadow.opaque = YES;
        toolbarShadow.alpha = 0.8;
        [self addSubview:toolbarShadow];

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
