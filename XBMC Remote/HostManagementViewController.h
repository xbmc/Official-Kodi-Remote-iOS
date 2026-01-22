//
//  HostManagementViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 13/5/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import "MasterViewController.h"
#import "DSJSONRPC.h"

@import UIKit;

@class HostViewController;
@class AppInfoViewController;

@interface HostManagementViewController : UIViewController <UIGestureRecognizerDelegate> {
    IBOutlet UITableView *serverListTableView;
    IBOutlet UIButton *editTableButton;
    UILongPressGestureRecognizer *longPressGesture;
    IBOutlet UIImageView *backgroundImageView;
    NSIndexPath *storeServerSelection;
    __weak IBOutlet UIActivityIndicatorView *connectingActivityIndicator;
    AppInfoViewController *appInfoView;
    UILabel *noFoundLabel;
    __weak IBOutlet UIButton *addHostButton;
    __weak IBOutlet UIView *supportedVersionView;
    __weak IBOutlet UILabel *supportedVersionLabel;
    __weak IBOutlet UIVisualEffectView *bottomToolbarEffect;
    UITextView *serverInfoView;
    __weak IBOutlet UIButton *serverInfoButton;
    NSTimer *serverInfoTimer;
    NSString *appImageCacheSize;
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil;

@property (nonatomic, strong) NSMutableArray *mainMenu;

@end
