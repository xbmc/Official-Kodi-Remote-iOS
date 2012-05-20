//
//  HostManagementViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 13/5/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HostViewController;

@interface HostManagementViewController : UIViewController <UINavigationControllerDelegate, UINavigationBarDelegate>{
    IBOutlet UITableView *serverListTableView;
    IBOutlet UITableViewCell *serverListCell;
    IBOutlet UIButton *editTableButton;
    IBOutlet UILongPressGestureRecognizer *lpgr;
    IBOutlet UIImageView *backgroundImageView;
    NSIndexPath *storeServerSelection;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
-(void)selectIndex:(NSIndexPath *)selection reloadData:(BOOL)reload;

@property (strong, nonatomic) HostViewController *hostController;

@end
