//
//  UIColor+Extensions.h
//  Kodi Remote
//
//  Created by Buschmann on 05.04.26.
//  Copyright © 2026 Team Kodi. All rights reserved.
//

@import UIKit;

@interface UIColor (Extensions)

+ (UIColor*)getSystemRed:(CGFloat)alpha;
+ (UIColor*)getSystemGreen:(CGFloat)alpha;
+ (UIColor*)getKodiBlue;
+ (UIColor*)getSystemBlue;
+ (UIColor*)getSystemGray1;
+ (UIColor*)getSystemGray2;
+ (UIColor*)getSystemGray3;
+ (UIColor*)getSystemGray4;
+ (UIColor*)getSystemGray5;
+ (UIColor*)getSystemGray6;
+ (UIColor*)get1stLabelColor;
+ (UIColor*)get2ndLabelColor;
+ (UIColor*)get3rdLabelColor;
+ (UIColor*)get4thLabelColor;
+ (UIColor*)getGrayColor:(int)tone alpha:(CGFloat)alpha;

@end
