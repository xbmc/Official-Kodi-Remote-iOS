//
//  ProgressPieView.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 8/2/14.
//  Copyright (c) 2014 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProgressPieView : UIView {
    int padding;
    float lineWidth;
    UIColor *pieColor;
    CGFloat radius;
    CAShapeLayer *progressShape;
}

- (id)initWithFrame:(CGRect)frame color:(UIColor *)aColor;
- (void)updateProgressPercentage:(CGFloat)progresspercentage;
- (CGFloat)getPieRadius;
- (CGFloat)getPiePadding;
- (CGFloat)getLineWidth;

@property(nonatomic,readonly) UILabel *pieLabel;

@end
