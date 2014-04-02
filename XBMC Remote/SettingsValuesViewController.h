//
//  SettingsValuesViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 2/4/14.
//  Copyright (c) 2014 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsValuesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    int cellLabelOffset;
    CGFloat cellHeight;
}

- (id)initWithFrame:(CGRect)frame;

@property(nonatomic, retain) UITableView* tableView;

@property (strong, nonatomic) id detailItem;

@end
