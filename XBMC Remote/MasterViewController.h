//
//  MasterViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseMasterViewController.h"
#import "DSJSONRPC.h"
#import "tcpJSONRPC.h"
#import "CustomNavigationController.h"
#import "MessagesView.h"

@interface MasterViewController : BaseMasterViewController <UITableViewDataSource, UITableViewDelegate> {
    IBOutlet UITableView *menuList;
    BOOL itemIsActive;
    UIImageView *globalConnectionStatus;
    MessagesView *messagesView;
}

@property (nonatomic, strong) NSMutableArray *mainMenu;
@property (strong, nonatomic) tcpJSONRPC *tcpJSONRPCconnection;

@end
