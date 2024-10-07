//
//  HostManagementViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 13/5/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MasterViewController.h"
#import "DSJSONRPC.h"

@class HostViewController;
@class AppInfoViewController;

@interface HostManagementViewController : UIViewController <UIGestureRecognizerDelegate> {
    IBOutlet UITableView *serverListTableView;
    IBOutlet UIButton *editTableButton;
    UILongPressGestureRecognizer *longPressGesture;
    IBOutlet UIImageView *backgroundImageView;
    NSIndexPath *storeServerSelection;
    __weak IBOutlet UIActivityIndicatorView *connectingActivityIndicator;
    BOOL doRevealMenu;
    AppInfoViewController *appInfoView;
    __weak IBOutlet UIButton *addHostButton;
    __weak IBOutlet UIView *supportedVersionView;
    __weak IBOutlet UILabel *supportedVersionLabel;
    __weak IBOutlet UIToolbar *bottomToolbar;
    __weak IBOutlet UIImageView *bottomToolbarShadowImageView;
    UITextView *serverInfoView;
    __weak IBOutlet UIButton *serverInfoButton;
    NSTimer *serverInfoTimer;
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil;
- (void)selectIndex:(NSIndexPath*)selection reloadData:(BOOL)reload;

@property (nonatomic, strong) NSMutableArray *mainMenu;

@end
