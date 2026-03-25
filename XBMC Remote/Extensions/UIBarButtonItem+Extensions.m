//
//  UIBarButtonItem+Extensions.m
//  Kodi Remote
//
//  Created by Buschmann on 23.03.26.
//  Copyright © 2026 Team Kodi. All rights reserved.
//

#import "UIBarButtonItem+Extensions.h"

@import Foundation;

@implementation UIBarButtonItem (Extensions)

- (void)setAppDefaultStyle {
    self.tintColor = ICON_TINT_COLOR;
    if (@available(iOS 26.0, *)) {
        self.hidesSharedBackground = YES;
    }
}

@end
