//
//  RightMenuViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 9/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECSlidingViewController.h"

@interface RightMenuViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>{
    UITableView *menuTableView;
    NSMutableArray* _rightMenuItems;
    IBOutlet UITableViewCell *resultMenuCell;
}

@property(nonatomic, retain) NSMutableArray *rightMenuItems;

@end
