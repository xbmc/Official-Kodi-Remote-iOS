//
//  HostViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 14/4/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
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
    NSMutableArray *services;
    BOOL searching;
    NSNetServiceBrowser *netServiceBrowser;
    NSTimer *timer;
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
    IBOutlet UILabel *noInstances;
    IBOutlet UIButton *startDiscover;
    IBOutlet UITableView *discoveredInstancesTableView;
    IBOutlet UIView *discoveredInstancesView;
}

@property (strong, nonatomic) id detailItem;

@end
