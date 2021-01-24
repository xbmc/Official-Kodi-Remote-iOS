//
//  gradientUIView.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 14/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface gradientUIView : UIView {
    CGFloat startRed;
    CGFloat startGreen;
    CGFloat startBlue;
    CGFloat endRed;
    CGFloat endGreen;
    CGFloat endBlue;
}

- (void)setColoursWithCGColors:(CGColorRef)color1 endColor:(CGColorRef)color2;
- (void)setStartRed:(CGFloat)sR startGreen:(CGFloat)sG startBlue:(CGFloat)sB endRed:(CGFloat)eR endGreen:(CGFloat)eG endBlue:(CGFloat)eB;

@end
