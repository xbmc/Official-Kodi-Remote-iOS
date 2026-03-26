//
//  UIViewController+Extensions.m
//  Kodi Remote
//
//  Created by Buschmann on 23.03.26.
//  Copyright © 2026 Team Kodi. All rights reserved.
//

#import "UIViewController+Extensions.h"

@import Foundation;

@implementation UIViewController (Extensions)

- (void)setNavigationBarTint:(UIColor*)tintColor {
    self.navigationController.navigationBar.tintColor = tintColor;
    if (@available(iOS 26.0, *)) {
        for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems) {
            if ([item isKindOfClass:[UIBarButtonItem class]]) {
                item.tintColor = tintColor;
            }
        }
    }
}

@end
