//
//  gradientUIView.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 14/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface gradientUIView : UIView {
    float startRed;
    float startGreen;
    float startBlue;
    float endRed;
    float endGreen;
    float endBlue;
}

- (void)setColoursWithCGColors:(CGColorRef)color1 endColor:(CGColorRef)color2;
- (void)setStartRed:(float)sR startGreen:(float)sG startBlue:(float)sB endRed:(float)eR endGreen:(float)eG endBlue:(float)eB;

@end