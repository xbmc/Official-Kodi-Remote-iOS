//
//  SettingsValuesViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 2/4/14.
//  Copyright (c) 2014 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SettingType) {
    SettingTypeDefault,
    SettingTypeSlider,
    SettingTypeSwitch,
    SettingTypeInput,
    SettingTypeList,
    SettingTypeMultiselect,
    SettingTypeUnsupported,
};

@interface SettingsValuesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate> {
    CGFloat cellHeight;
    NSMutableArray *settingOptions;
    NSDictionary *itemControls;
    SettingType xbmcSetting;
    CGFloat footerHeight;
    UIActivityIndicatorView *activityIndicator;
    NSIndexPath *selectedSetting;
    NSIndexPath *longPressRow;
    CGFloat storeSliderValue;
    UIView *scrubbingView;
    UILabel *scrubbingMessage;
    UILabel *scrubbingRate;
    UILabel *footerDescription;
    BOOL fromItself;
}

- (id)initWithFrame:(CGRect)frame withItem:(id)item;

@property (nonatomic, strong) UITableView *tableView;
@property (strong, nonatomic) id detailItem;

@end
