//
//  UIButton+Extensions.h
//  Kodi Remote
//
//  Created by Buschmann on 05.05.26.
//  Copyright © 2026 Team Kodi. All rights reserved.
//

@import UIKit;

@interface UIButton (Extensions)

- (void)setTextStyle;
- (void)setIconStyle:(UIImage*)image;
- (void)setIconStyle:(UIImage*)image withColor:(UIColor*)color;
- (void)setDatabaseToolbarStyle:(UIImage*)image;

@end
