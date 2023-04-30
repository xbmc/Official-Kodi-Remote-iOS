//
//  MoreItemsViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MoreItemsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	UITableView *_tableView;
    NSArray *mainMenuItems;
    int cellLabelOffset;
}

- (id)initWithFrame:(CGRect)frame mainMenu:(NSArray*)menu;

@property (nonatomic, strong) UITableView *tableView;

@end
