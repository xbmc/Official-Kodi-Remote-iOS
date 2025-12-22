//
//  ActorCell.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 8/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "ActorCell.h"
#import "AppDelegate.h"
#import "Utilities.h"

@import QuartzCore;

#define LABEL_PADDING 10
#define THUMB_PADDING 10
#define VERTICAL_PADDING 5
#define ACCESSORY_RESERVED 20

@implementation ActorCell

@synthesize actorThumbnail = _actorThumbnail;
@synthesize actorName = _actorName;
@synthesize actorRole = _actorRole;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier castWidth:(int)castWidth castHeight:(int)castHeight lineSpacing:(int)spacing castFontSize:(int)castFontSize {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        if (AppDelegate.instance.serverVersion > 11) {
            self.selectionStyle = UITableViewCellSelectionStyleGray;
        }
        
        UIView *actorContainer = [[UIView alloc] initWithFrame:CGRectMake(THUMB_PADDING, VERTICAL_PADDING, castWidth, castHeight)];
        actorContainer.clipsToBounds = NO;
        actorContainer.backgroundColor = UIColor.clearColor;
        actorContainer.layer.shadowColor = FONT_SHADOW_STRONG.CGColor;
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
        
        UIFont *nameFont = [UIFont systemFontOfSize:castFontSize];
        _actorName = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(actorContainer.frame) + LABEL_PADDING,
                                                               CGRectGetMinY(actorContainer.frame),
                                                               self.frame.size.width - CGRectGetMaxX(actorContainer.frame) - 2 * LABEL_PADDING,
                                                               nameFont.lineHeight)];
        _actorName.font = nameFont;
        _actorName.backgroundColor = UIColor.clearColor;
        _actorName.textColor = UIColor.whiteColor;
        _actorName.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        _actorName.shadowColor = FONT_SHADOW_WEAK;
        _actorName.shadowOffset = CGSizeMake(1, 1);
        [self addSubview:_actorName];
        
        UIFont *roleFont = [UIFont systemFontOfSize:castFontSize - 2];
        _actorRole = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_actorName.frame),
                                                               CGRectGetMaxY(_actorName.frame) + spacing,
                                                               CGRectGetWidth(_actorName.frame) - ACCESSORY_RESERVED,
                                                               roleFont.lineHeight)];
        _actorRole.numberOfLines = 3;
        _actorRole.font = roleFont;
        _actorRole.backgroundColor = UIColor.clearColor;
        _actorRole.textColor = UIColor.lightGrayColor;
        _actorRole.shadowColor = FONT_SHADOW_STRONG;
        _actorRole.shadowOffset = CGSizeMake(1, 1);
        _actorRole.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        [self addSubview:_actorRole];
        
        UIView *myBackView = [[UIView alloc] initWithFrame:self.frame];
        myBackView.backgroundColor = ACTOR_SELECTED_COLOR;
        self.selectedBackgroundView = myBackView;
    }
    return self;
}

@end
