//
//  CustomButtonCell.m
//  Kodi Remote
//
//  Created by Buschmann on 09.10.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "CustomButtonCell.h"
#import "Utilities.h"

#define CUSTOM_BUTTON_ITEM_SPACING 4.0
#define CUSTOM_BUTTON_LABEL_PADDING 4.0
#define CUSTOM_BUTTON_BACKGROUND_INSET 2.0
#define ICON_ALPHA 0.8 // Reduce alpha to soften appearance next to button name
#define ICON_ALPHA_DISABLED 0.5 // Align with alpha of disabled UISwitch

@implementation CustomButtonCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Background view to better match a button style
        UIView *buttonBackground = [UIView new];
        buttonBackground.frame = CGRectInset(self.frame, CUSTOM_BUTTON_BACKGROUND_INSET, CUSTOM_BUTTON_BACKGROUND_INSET);
        buttonBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        buttonBackground.layer.cornerRadius = 8;
        buttonBackground.backgroundColor = CUSTOM_BUTTON_BACKGROUND;
        [self insertSubview:buttonBackground belowSubview:self.contentView];
        
        // OnOff switch is placed right aligned in the content view
        UISwitch *onoff = [UISwitch new];
        CGRect frame = onoff.frame;
        frame.origin = CGPointMake(CGRectGetWidth(self.contentView.frame) - CGRectGetWidth(onoff.frame) - CUSTOM_BUTTON_ITEM_SPACING,
                                   (CUSTOM_BUTTON_ITEM_HEIGHT - CGRectGetHeight(onoff.frame)) / 2);
        onoff.frame = frame;
        onoff.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        onoff.hidden = YES;
        onoff.alpha = ICON_ALPHA;
        [self.contentView addSubview:onoff];
        self.onoffSwitch = onoff;
        
        // Icon frame follows onoffSwitch size
        CGFloat iconSize = CGRectGetHeight(self.onoffSwitch.frame);
        UIImageView *icon = [UIImageView new];
        icon.frame = CGRectMake(CGRectGetWidth(self.contentView.frame) - (CGRectGetWidth(self.onoffSwitch.frame) + iconSize) / 2 - CUSTOM_BUTTON_ITEM_SPACING,
                                (CUSTOM_BUTTON_ITEM_HEIGHT - iconSize) / 2,
                                iconSize,
                                iconSize);
        icon.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        icon.alpha = ICON_ALPHA;
        [self.contentView addSubview:icon];
        self.buttonIcon = icon;
        
        // Label follows onoffSwitch/icon size
        UILabel *title = [UILabel new];
        title.frame = CGRectMake(CUSTOM_BUTTON_LABEL_PADDING,
                                 CUSTOM_BUTTON_ITEM_SPACING,
                                 CGRectGetWidth(self.contentView.frame) - CGRectGetWidth(self.onoffSwitch.frame) - CUSTOM_BUTTON_LABEL_PADDING * 3,
                                 CUSTOM_BUTTON_ITEM_HEIGHT - CUSTOM_BUTTON_ITEM_SPACING * 2);
        title.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        title.textAlignment = NSTextAlignmentRight;
        title.numberOfLines = 2;
        title.font = [UIFont fontWithName:@"Roboto-Regular" size:20];
        title.adjustsFontSizeToFitWidth = YES;
        title.minimumScaleFactor = FONT_SCALING_MIN;
        title.textColor = UIColor.lightGrayColor;
        title.highlightedTextColor = UIColor.grayColor;
        [self.contentView addSubview:title];
        self.buttonLabel = title;
        
        // Activity indicator is placed on top of onoff switch
        UIActivityIndicatorView *busyView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        busyView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        busyView.hidesWhenStopped = YES;
        busyView.center = onoff.center;
        [self.contentView addSubview:busyView];
        self.busyView = busyView;
    }
    return self;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if (editing) {
        self.onoffSwitch.enabled = NO;
        self.buttonIcon.alpha = ICON_ALPHA_DISABLED;
    }
    else {
        self.onoffSwitch.enabled = YES;
        self.buttonIcon.alpha = ICON_ALPHA;
    }
}

@end
