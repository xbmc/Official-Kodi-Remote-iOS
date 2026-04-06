//
//  UILabel+Extensions.m
//  Kodi Remote
//
//  Created by Buschmann on 27.03.26.
//  Copyright © 2026 Team Kodi. All rights reserved.
//

#import "UILabel+Extensions.h"

@implementation UILabel (Extensions)

- (void)setNoFoundStyle {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.textColor = UIColor.lightGrayColor;
    self.font = [UIFont systemFontOfSize:17];
    self.textAlignment = NSTextAlignmentCenter;
    self.adjustsFontSizeToFitWidth = YES;
    self.minimumScaleFactor = FONT_SCALING_MIN;
    self.numberOfLines = 2;
    self.alpha = 0.0;
}

@end
