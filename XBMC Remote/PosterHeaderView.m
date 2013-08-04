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

@implementation PosterHeaderView

@synthesize headerLabel = _headerLabel;

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setClipsToBounds:NO];
        self.restorationIdentifier = @"posterHeaderView";
        
//        if (self.frame.size.height > 0){
//            UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 1)];
//            [lineView setBackgroundColor:[UIColor colorWithRed:130.0f/255.0f green:130.0f/255.0f blue:130.0f/255.0f alpha:1]];
//            [self addSubview:lineView];
//        }
        
        if (self.frame.size.height > 1){
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")){
                //TYPE 1
//                UIToolbar *buttonsToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
//                [buttonsToolbar setBarStyle:UIBarStyleBlack];
//                [buttonsToolbar setTranslucent:YES];
//                [self insertSubview: buttonsToolbar atIndex:0];
                
                // TYPE 2
                [self setBackgroundColor:[UIColor colorWithRed:30.0f/255.0f green:30.0f/255.0f blue:30.0f/255.0f alpha:.95]];
                
                // TYPE 3
//                CAGradientLayer *gradient = [CAGradientLayer layer];
//                gradient.frame = self.bounds;
//                gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:75.0f/255.0f green:75.0f/255.0f blue:75.0f/255.0f alpha:.95] CGColor], (id)[[UIColor colorWithRed:35.0f/255.0f green:35.0f/255.0f blue:35.0f/255.0f alpha:.95] CGColor], nil];
//                [self.layer insertSublayer:gradient atIndex:0];
            }
            else{
                UIView *lineViewBottom = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 1, self.frame.size.width, 1)];
                [lineViewBottom setBackgroundColor:[UIColor colorWithRed:52.0f/255.0f green:52.0f/255.0f blue:52.0f/255.0f alpha:1]];
                [self addSubview:lineViewBottom];
                CAGradientLayer *gradient = [CAGradientLayer layer];
                gradient.frame = self.bounds;
                gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:103.0f/255.0f green:103.0f/255.0f blue:103.0f/255.0f alpha:.9] CGColor], (id)[[UIColor colorWithRed:.1 green:.1 blue:.1 alpha:.9] CGColor], nil];
                [self.layer insertSublayer:gradient atIndex:0];
            }
        }

        if (self.frame.size.height > 10){
            _headerLabel = [[PosterLabel alloc] initWithFrame:CGRectMake(10, 0, self.frame.size.width - 10, self.frame.size.height - 1)];
            [_headerLabel setBackgroundColor:[UIColor clearColor]];
            [_headerLabel setFont:[UIFont boldSystemFontOfSize:(self.frame.size.height > 20 ? 17 : self.frame.size.height - 5)]];
            [_headerLabel setShadowColor:[UIColor darkGrayColor]];
            [_headerLabel setShadowOffset:CGSizeMake(0, 1)];
            
            [_headerLabel setTextColor:[UIColor whiteColor]];
            [_headerLabel setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
            
            [self addSubview:_headerLabel];
        }
        
        CGRect toolbarShadowFrame = CGRectMake(0.0f, self.frame.size.height - 1, self.frame.size.width, 4);
        UIImageView *toolbarShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
        [toolbarShadow setImage:[UIImage imageNamed:@"tableUp.png"]];
        toolbarShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbarShadow.contentMode = UIViewContentModeScaleToFill;
        toolbarShadow.opaque = YES;
        toolbarShadow.alpha = .8f;
        [self addSubview:toolbarShadow];

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
