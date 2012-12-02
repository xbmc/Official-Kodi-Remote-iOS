//
//  HostViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 14/4/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "GlobalData.h"

@interface HostViewController : UIViewController <UITextFieldDelegate, NSNetServiceDelegate,  NSNetServiceBrowserDelegate, UITableViewDataSource, UITableViewDelegate>{
//    GlobalData *obj;
    IBOutlet UITextField *descriptionUI;
    IBOutlet UITextField *ipUI;
    IBOutlet UITextField *portUI;
    IBOutlet UITextField *usernameUI;
    IBOutlet UITextField *passwordUI;
    IBOutlet UITextField *mac_0_UI;
    IBOutlet UITextField *mac_1_UI;
    IBOutlet UITextField *mac_2_UI;
    IBOutlet UITextField *mac_3_UI;
    IBOutlet UITextField *mac_4_UI;
    IBOutlet UITextField *mac_5_UI;
    IBOutlet UISwitch *preferTVPostersUI;
    IBOutlet UITextField *tcpPortUI;
    NSMutableArray *services;
    BOOL searching;
    NSNetServiceBrowser *netServiceBrowser;
    NSTimer *timer;
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
    IBOutlet UIView *noInstances;
    IBOutlet UIButton *startDiscover;
    IBOutlet UITableView *discoveredInstancesTableView;
    IBOutlet UIView *discoveredInstancesView;
}

@property (strong, nonatomic) id detailItem;

@end
