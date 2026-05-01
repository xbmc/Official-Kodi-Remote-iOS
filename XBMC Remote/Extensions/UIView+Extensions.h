//
//  UIView+Extensions.h
//  Kodi Remote
//
//  Created by Buschmann on 05.04.26.
//  Copyright © 2026 Team Kodi. All rights reserved.
//

@import UIKit;

@interface UIView (Extensions)

- (CGSize)getFittingSize;
- (void)setX:(CGFloat)x;
- (void)setY:(CGFloat)y;
- (void)setOrigin:(CGPoint)origin;
- (void)setHeight:(CGFloat)height;
- (void)setWidth:(CGFloat)width;
- (void)offsetYBy:(CGFloat)offset;
- (void)setX:(CGFloat)x alpha:(CGFloat)alpha;
- (void)animateX:(CGFloat)x alpha:(CGFloat)alpha duration:(NSTimeInterval)seconds;
- (void)animateOrigin:(CGPoint)origin duration:(NSTimeInterval)seconds;
- (void)animateAlpha:(CGFloat)alpha duration:(NSTimeInterval)seconds;
- (void)applyRoundedEdges;

@end
