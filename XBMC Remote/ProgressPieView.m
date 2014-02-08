//
//  ProgressPieView.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 8/2/14.
//  Copyright (c) 2014 joethefox inc. All rights reserved.
//

#import "ProgressPieView.h"

@implementation ProgressPieView

@synthesize pieLabel;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        padding = 8;
        BOOL isRetina = ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2);
        lineWidth = isRetina ? 0.5f : 1.0f;
        [self setBackgroundColor:[UIColor clearColor]];
        pieColor = [UIColor blueColor];
        radius = (MIN(self.frame.size.width, self.frame.size.height) / 2 ) - padding;
        pieLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (radius * 2) + 4, self.frame.size.width, 8)];
        [pieLabel setBackgroundColor:[UIColor clearColor]];
        [pieLabel setFont:[UIFont systemFontOfSize:7]];
        pieLabel.adjustsFontSizeToFitWidth = YES;
        pieLabel.minimumFontSize = 6;
        pieLabel.textAlignment = NSTextAlignmentCenter;
        [pieLabel setTextColor:[UIColor blueColor]];
        [pieLabel setHighlightedTextColor:[UIColor blueColor]];
        [self addSubview:pieLabel];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(contextRef, lineWidth);
    CGContextSetStrokeColorWithColor(contextRef, pieColor.CGColor);
    CGRect circlePoint = (CGRectMake(padding, lineWidth * 2, radius * 2, radius * 2));
    CGContextStrokeEllipseInRect(contextRef, circlePoint);
}

- (void)updateProgressPercentage:(CGFloat)progresspercentage {
    progresspercentage = progresspercentage < 0 ? 0 : progresspercentage > 100 ? 100 : progresspercentage;
    [self setNeedsLayout];
    CGFloat angle = (progresspercentage * 2 * M_PI) / 100;
    CAShapeLayer *mShapeLayer = [self createPieSliceForRadian:angle];
    [self.layer addSublayer:mShapeLayer];
}

- (CAShapeLayer *)createPieSliceForRadian:(CGFloat)angle {
    CAShapeLayer *slice = [CAShapeLayer layer];
    slice.fillColor = pieColor.CGColor;
    slice.strokeColor = pieColor.CGColor;
    slice.lineWidth = 0;
    CGFloat startAngle = -M_PI_2;
    CGPoint center = CGPointMake(radius + padding, radius + lineWidth * 2);
    UIBezierPath *piePath = [UIBezierPath bezierPath];
    [piePath moveToPoint:center];
    [piePath addLineToPoint:CGPointMake(center.x + radius * cosf(startAngle), center.y + radius * sinf(startAngle))];
    [piePath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:(angle - M_PI_2) clockwise:YES];
    [piePath closePath];
    slice.path = piePath.CGPath;
    return slice;
}

@end
