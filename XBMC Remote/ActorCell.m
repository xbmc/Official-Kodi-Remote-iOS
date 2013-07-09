//
//  ActorCell.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 8/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "ActorCell.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"

@implementation ActorCell

@synthesize actorThumbnail = _actorThumbnail;
@synthesize actorName = _actorName;
@synthesize actorRole = _actorRole;

int offsetX = 10;
int offsetY = 5;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier castWidth:(int)castWidth castHeight:(int)castHeight size:(int)size castFontSize:(int)castFontSize{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
        if ([AppDelegate instance].serverVersion>11){
            [self setSelectionStyle:UITableViewCellSelectionStyleGray];
        }
        
        UIView *actorContainer = [[UIView alloc] initWithFrame:CGRectMake(offsetX, offsetY, castWidth, castHeight)];
        [actorContainer setClipsToBounds: NO];
        [actorContainer setBackgroundColor:[UIColor clearColor]];
        actorContainer.layer.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8].CGColor;
        actorContainer.layer.shadowOpacity = 0.7f;
        actorContainer.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        actorContainer.layer.shadowRadius = 2.0f;
        actorContainer.layer.masksToBounds = NO;
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:actorContainer.bounds];
        actorContainer.layer.shadowPath = path.CGPath;
        
        _actorThumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, castWidth, castHeight)];
        [_actorThumbnail setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [_actorThumbnail setClipsToBounds:YES];
        [_actorThumbnail setContentMode:UIViewContentModeScaleAspectFill];
        [_actorThumbnail setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];
        [actorContainer addSubview:_actorThumbnail];
        [self addSubview:actorContainer];
        
        _actorName=[[UILabel alloc] initWithFrame:CGRectMake(castWidth + offsetX + 10, offsetY, self.frame.size.width - (castWidth + offsetX + 20) , 16 + size)];
        [_actorName setFont:[UIFont systemFontOfSize:castFontSize]];
        [_actorName setBackgroundColor:[UIColor clearColor]];
        [_actorName setTextColor:[UIColor whiteColor]];
        [_actorName setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth];
        [_actorName setShadowColor:[UIColor blackColor]];
        [_actorName setShadowOffset:CGSizeMake(1, 1)];
        [self addSubview:_actorName];
        
        _actorRole = [[UILabel alloc] initWithFrame:CGRectMake(castWidth + offsetX + 10, offsetY +  17 + size / 2, 320 - (castWidth + offsetX + 20) , 16 + size)];
        _actorRole.numberOfLines = 3;
        [_actorRole setFont:[UIFont systemFontOfSize:castFontSize - 2]];
        [_actorRole setBackgroundColor:[UIColor clearColor]];
        [_actorRole setTextColor:[UIColor lightGrayColor]];
        [_actorRole setShadowColor:[UIColor blackColor]];
        [_actorRole setShadowOffset:CGSizeMake(1, 1)];
        [_actorRole setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth];        
        [self addSubview:_actorRole];
        
        UIView *myBackView = [[UIView alloc] initWithFrame:self.frame];
        myBackView.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        self.selectedBackgroundView = myBackView;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated{
    [super setSelected:selected animated:animated];
}

@end
