//
//  gradientUIView.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 14/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "gradientUIView.h"

@implementation gradientUIView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGGradientRef glossGradient;
    CGColorSpaceRef rgbColorspace;
    size_t numLocations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] = { startRed, startGreen, startBlue, 1.0, endRed, endGreen, endBlue, 1.0 };
    rgbColorspace = CGColorSpaceCreateDeviceRGB();
    glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, numLocations);
    CGRect currentBounds = self.bounds;
    CGPoint topCenter = CGPointMake(CGRectGetMidX(currentBounds), 0.0f);
    CGPoint bottomCenter = CGPointMake(CGRectGetMidX(currentBounds), CGRectGetMaxY(currentBounds));
    CGContextDrawLinearGradient(currentContext, glossGradient, topCenter, bottomCenter, 0);
    CGGradientRelease(glossGradient);
    CGColorSpaceRelease(rgbColorspace);
}

- (void)setStartRed:(float)sR startGreen:(float)sG startBlue:(float)sB endRed:(float)eR endGreen:(float)eG endBlue:(float)eB {
    startRed = sR;
    startGreen = sG;
    startBlue = sB;
    endRed = eR;
    endGreen = eG;
    endBlue = eB;
}

- (void)setColoursWithCGColors:(CGColorRef)color1 endColor:(CGColorRef)color2 {
    const CGFloat *startComponents = CGColorGetComponents(color1);
    const CGFloat *endComponents = CGColorGetComponents(color2);
    [self setStartRed:startComponents[0] startGreen:startComponents[1] startBlue:startComponents[2] endRed:endComponents[0] endGreen:endComponents[1] endBlue:endComponents[2]];
}

@end