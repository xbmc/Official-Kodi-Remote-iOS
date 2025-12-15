//
//  RightMenuViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 9/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "DSJSONRPC.h"

@import UIKit;

@interface RightMenuViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    UITableView *menuTableView;
    NSMutableArray *tableData;
    UIButton *editTableButton;
    UIButton *moreButton;
    NSDictionary *infoCustomButton;
}

@end
