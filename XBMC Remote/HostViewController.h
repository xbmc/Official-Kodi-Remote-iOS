//
//  HostViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 14/4/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "GlobalData.h"

#define SERVERPOPUP_BOTTOMPADDING 10

@interface HostViewController : UIViewController <UITextFieldDelegate, NSNetServiceDelegate, NSNetServiceBrowserDelegate, UITableViewDataSource, UITableViewDelegate, NSURLConnectionDataDelegate>{
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
    IBOutlet UILabel *descriptionLabel;
    IBOutlet UILabel *hostLabel;
    IBOutlet UILabel *macLabel;
    IBOutlet UILabel *userLabel;
    IBOutlet UILabel *noInstancesLabel;
    IBOutlet UILabel *findLabel;
    IBOutlet UIView *tipView;
    IBOutlet UILabel *howtoLabel;
    IBOutlet UILabel *howtoLaterLabel;
    IBOutlet UIButton *saveButton;
}

@property (strong, nonatomic) id detailItem;

@end
