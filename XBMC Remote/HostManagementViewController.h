//
//  HostManagementViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 13/5/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECSlidingViewController.h"
#import "MasterViewController.h"
#import "RightMenuViewController.h"

@class HostViewController;
@class AppInfoViewController;

@interface HostManagementViewController : UIViewController {
    IBOutlet UITableView *serverListTableView;
    IBOutlet UITableViewCell *serverListCell;
    IBOutlet UIButton *editTableButton;
    IBOutlet UILongPressGestureRecognizer *lpgr;
    IBOutlet UIImageView *backgroundImageView;
    NSIndexPath *storeServerSelection;
    __weak IBOutlet UIActivityIndicatorView *connectingActivityIndicator;
    BOOL doRevealMenu;
    AppInfoViewController *appInfoView;
    __weak IBOutlet UIButton *addHostButton;
    UIView *iOS7navBarEffect;
    __weak IBOutlet UIView *supportedVersionView;
    __weak IBOutlet UILabel *supportedVersionLabel;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
-(void)selectIndex:(NSIndexPath *)selection reloadData:(BOOL)reload;

@property (strong, nonatomic) HostViewController *hostController;
@property (nonatomic, strong) NSMutableArray *mainMenu;

@end
