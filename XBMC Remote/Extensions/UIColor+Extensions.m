//
//  UIColor+Extensions.m
//  Kodi Remote
//
//  Created by Buschmann on 05.04.26.
//  Copyright © 2026 Team Kodi. All rights reserved.
//

#import "UIColor+Extensions.h"

#define RGBA(r, g, b, a) [UIColor colorWithRed:(r) / 255.0 green:(g) / 255.0 blue:(b) / 255.0 alpha:(a)]

@implementation UIColor (Extensions)

+ (UIColor*)getSystemRed:(CGFloat)alpha {
    return [UIColor.systemRedColor colorWithAlphaComponent:alpha];
}

+ (UIColor*)getSystemGreen:(CGFloat)alpha {
    return [UIColor.systemGreenColor colorWithAlphaComponent:alpha];
}

+ (UIColor*)getKodiBlue {
    return RGBA(20, 178, 231, 1.0);
}

+ (UIColor*)getSystemBlue {
    return UIColor.systemBlueColor;
}

+ (UIColor*)getSystemGray1 {
    return UIColor.systemGrayColor;
}

+ (UIColor*)getSystemGray2 {
    if (@available(iOS 13.0, *)) {
        return UIColor.systemGray2Color;
    }
    else {
        return RGBA(174, 174, 178, 1.0);
    }
}

+ (UIColor*)getSystemGray3 {
    if (@available(iOS 13.0, *)) {
        return UIColor.systemGray3Color;
    }
    else {
        return RGBA(199, 199, 204, 1.0);
    }
}

+ (UIColor*)getSystemGray4 {
    if (@available(iOS 13.0, *)) {
        return UIColor.systemGray4Color;
    }
    else {
        return RGBA(209, 209, 214, 1.0);
    }
}

+ (UIColor*)getSystemGray5 {
    if (@available(iOS 13.0, *)) {
        return UIColor.systemGray5Color;
    }
    else {
        return RGBA(229, 229, 234, 1.0);
    }
}

+ (UIColor*)getSystemGray6 {
    if (@available(iOS 13.0, *)) {
        return UIColor.systemGray6Color;
    }
    else {
        return RGBA(242, 242, 247, 1.0);
    }
}

+ (UIColor*)get1stLabelColor {
    if (@available(iOS 13.0, *)) {
        return UIColor.labelColor;
    }
    else {
        return RGBA(0, 0, 0, 1.0);
    }
}

+ (UIColor*)get2ndLabelColor {
    if (@available(iOS 13.0, *)) {
        return UIColor.secondaryLabelColor;
    }
    else {
        return RGBA(60, 60, 67, 0.6);
    }
}

+ (UIColor*)get3rdLabelColor {
    if (@available(iOS 13.0, *)) {
        return UIColor.tertiaryLabelColor;
    }
    else {
        return RGBA(60, 60, 67, 0.3);
    }
}

+ (UIColor*)get4thLabelColor {
    if (@available(iOS 13.0, *)) {
        return UIColor.quaternaryLabelColor;
    }
    else {
        return RGBA(60, 60, 67, 0.18);
    }
}

+ (UIColor*)getGrayColor:(int)tone alpha:(CGFloat)alpha {
    return RGBA(tone, tone, tone, alpha);
}

@end
