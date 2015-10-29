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

@end