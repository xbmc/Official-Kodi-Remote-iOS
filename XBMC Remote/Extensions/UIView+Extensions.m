//
//  UIView+Extensions.m
//  Kodi Remote
//
//  Created by Buschmann on 05.04.26.
//  Copyright © 2026 Team Kodi. All rights reserved.
//

#import "UIView+Extensions.h"

@implementation UIView (Extensions)

- (CGSize)getFittingSize {
    return [self sizeThatFits:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
}

- (void)setX:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (void)setY:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (void)setOrigin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (void)setHeight:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (void)setWidth:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (void)offsetYBy:(CGFloat)offset {
    CGRect frame = self.frame;
    frame.origin.y += offset;
    self.frame = frame;
}

- (void)setX:(CGFloat)x alpha:(CGFloat)alpha {
    [self setX:x];
    self.alpha = alpha;
}

- (void)defaultAnimate:(nullable void(^)(void))animations duration:(NSTimeInterval)seconds {
    if (animations) {
        [UIView animateWithDuration:seconds
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            animations();
        }
                         completion:nil];
    }
}

- (void)animateX:(CGFloat)x alpha:(CGFloat)alpha duration:(NSTimeInterval)seconds {
    [self defaultAnimate:^{
        [self setX:x alpha:alpha];
    } duration:seconds];
}

- (void)animateOrigin:(CGPoint)origin duration:(NSTimeInterval)seconds {
    [self defaultAnimate:^{
        [self setOrigin:origin];
    } duration:seconds];
}

- (void)animateAlpha:(CGFloat)alpha duration:(NSTimeInterval)seconds {
    [self defaultAnimate:^{
        self.alpha = alpha;
    } duration:seconds];
}

- (void)setCornerRadiusForRoundedEdges {
    self.layer.cornerRadius = GET_ROUNDED_EDGES_RADIUS(self.layer.frame.size);
}

- (void)applyRoundedEdges {
    UIView *view = self;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL corner_preference = [userDefaults boolForKey:@"rounded_corner_preference"];
    if (corner_preference) {
        [view setCornerRadiusForRoundedEdges];
    }
}

@end
