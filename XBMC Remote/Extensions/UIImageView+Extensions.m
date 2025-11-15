//
//  UIImageView+Extensions.m
//  Kodi Remote
//
//  Created by Buschmann on 05.04.26.
//  Copyright © 2026 Team Kodi. All rights reserved.
//

#import "UIImageView+Extensions.h"

@implementation UIImageView (Extensions)

- (void)animateImage:(UIImage*)image duration:(NSTimeInterval)seconds {
    [UIView transitionWithView:self
                      duration:seconds
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        self.image = image;
    }
                    completion:nil];
}

@end
