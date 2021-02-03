//
//  Utilities.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 4/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utilities : NSObject

- (UIColor *)averageColor:(UIImage *)image inverse:(BOOL)inverse;
- (UIColor *)slightLighterColorForColor:(UIColor *)c;
- (UIColor *)lighterColorForColor:(UIColor *)c;
- (UIColor *)darkerColorForColor:(UIColor *)c;
- (UIColor *)updateColor:(UIColor *) newColor lightColor:(UIColor *)lighter darkColor:(UIColor *)darker;
- (UIColor *)updateColor:(UIColor *) newColor lightColor:(UIColor *)lighter darkColor:(UIColor *)darker trigger:(CGFloat)trigger;
- (UIImage*)colorizeImage:(UIImage *)image withColor:(UIColor*)color;
+ (NSDictionary*)buildPlayerSeekPercentageParams:(int)playerID percentage:(float)percentage;
+ (NSArray*)buildPlayerSeekStepParams:(NSString*)stepmode;
+ (CGFloat)getTransformX;
+ (UIColor*)getSystemRed:(CGFloat)alpha;
+ (UIColor*)getSystemGreen:(CGFloat)alpha;
+ (UIColor*)getSystemBlue;
+ (UIColor*)getSystemTeal;
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
+ (CGRect)createXBMCInfoframe:(UIImage *)logo height:(CGFloat)height width:(CGFloat)width;

@end
