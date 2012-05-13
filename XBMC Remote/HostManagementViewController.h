//
//  HostManagementViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 13/5/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HostViewController;
@class GlobalData;
@class MasterViewController;

@interface HostManagementViewController : UIViewController{
    IBOutlet UITableView *serverListTableView;
    IBOutlet UITableViewCell *serverListCell;
    IBOutlet UIButton *editTableButton;
    IBOutlet UILongPressGestureRecognizer *lpgr;
    NSIndexPath *storeServerSelection;
    MasterViewController *masterViewController;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil masterController:(MasterViewController *)controller;
-(void)selectIndex:(NSIndexPath *)selection reloadData:(BOOL)reload;

@property (strong, nonatomic) HostViewController *hostController;

@end
