//
//  CustomButtonCell.h
//  Kodi Remote
//
//  Created by Buschmann on 09.10.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

@import UIKit;

#define CUSTOM_BUTTON_ITEM_HEIGHT 50.0
#define CUSTOM_BUTTON_ITEM_SPACING 4.0
#define CUSTOM_BUTTON_LABEL_PADDING 4.0

@interface CustomButtonCell : UITableViewCell {
    UILabel *buttonLabel;
    UIImageView *buttonIcon;
    UISwitch *onoffSwitch;
    UIActivityIndicatorView *busyView;
}

@property (nonatomic, strong) UILabel *buttonLabel;
@property (nonatomic, strong) UIImageView *buttonIcon;
@property (nonatomic, strong) UISwitch *onoffSwitch;
@property (nonatomic, strong) UIActivityIndicatorView *busyView;

@end
