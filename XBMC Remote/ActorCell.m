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
#import "Utilities.h"

@implementation ActorCell

@synthesize actorThumbnail = _actorThumbnail;
@synthesize actorName = _actorName;
@synthesize actorRole = _actorRole;

int offsetX = 10;
int offsetY = 5;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier castWidth:(int)castWidth castHeight:(int)castHeight size:(int)size castFontSize:(int)castFontSize {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        if (AppDelegate.instance.serverVersion > 11) {
            self.selectionStyle = UITableViewCellSelectionStyleGray;
        }
        
        UIView *actorContainer = [[UIView alloc] initWithFrame:CGRectMake(offsetX, offsetY, castWidth, castHeight)];
        actorContainer.clipsToBounds = NO;
        actorContainer.backgroundColor = UIColor.clearColor;
        actorContainer.layer.shadowColor = [Utilities getGrayColor:0 alpha:0.8].CGColor;
        actorContainer.layer.shadowOpacity = 0.7f;
        actorContainer.layer.shadowOffset = CGSizeZero;
        actorContainer.layer.shadowRadius = 2.0;
        actorContainer.layer.masksToBounds = NO;
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:actorContainer.bounds];
        actorContainer.layer.shadowPath = path.CGPath;
        
        _actorThumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, castWidth, castHeight)];
        _actorThumbnail.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _actorThumbnail.clipsToBounds = YES;
        _actorThumbnail.contentMode = UIViewContentModeScaleAspectFill;
        _actorThumbnail.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
        [actorContainer addSubview:_actorThumbnail];
        [self addSubview:actorContainer];
        
        _actorName = [[UILabel alloc] initWithFrame:CGRectMake(castWidth + offsetX + 10, offsetY, self.frame.size.width - (castWidth + offsetX + 20), 16 + size)];
        _actorName.font = [UIFont systemFontOfSize:castFontSize];
        _actorName.backgroundColor = UIColor.clearColor;
        _actorName.textColor = UIColor.whiteColor;
        _actorName.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        _actorName.shadowColor = UIColor.blackColor;
        _actorName.shadowOffset = CGSizeMake(1, 1);
        [self addSubview:_actorName];
        
        _actorRole = [[UILabel alloc] initWithFrame:CGRectMake(castWidth + offsetX + 10, offsetY + 17 + size / 2, self.frame.size.width - (castWidth + offsetX + 20), 16 + size)];
        _actorRole.numberOfLines = 3;
        _actorRole.font = [UIFont systemFontOfSize:castFontSize - 2];
        _actorRole.backgroundColor = UIColor.clearColor;
        _actorRole.textColor = UIColor.lightGrayColor;
        _actorRole.shadowColor = UIColor.blackColor;
        _actorRole.shadowOffset = CGSizeMake(1, 1);
        _actorRole.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        [self addSubview:_actorRole];
        
        UIView *myBackView = [[UIView alloc] initWithFrame:self.frame];
        myBackView.backgroundColor = [Utilities getGrayColor:128 alpha:0.5];
        self.selectedBackgroundView = myBackView;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
