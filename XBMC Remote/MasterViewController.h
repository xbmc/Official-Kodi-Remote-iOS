//
//  MasterViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"
#import "ECSlidingViewController.h"
#import "tcpJSONRPC.h"

@class DetailViewController;
@class NowPlaying;
@class RemoteController;
@class HostManagementViewController;
@class AppInfoViewController;
@class HostManagementViewController;

@interface MasterViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>{
    IBOutlet UITableView *menuList;
    IBOutlet UITableViewCell *resultMenuCell;
    DSJSONRPC *jsonRPC;
    UIButton *xbmcInfo;
    UIButton *xbmcLogo;
    UIButton *powerButton;
    NSDictionary *checkServerParams;
    NSIndexPath *storeServerSelection;
    AppInfoViewController *appInfoView;
    HostManagementViewController *hostManagementViewController;
    BOOL itemIsActive;
    UINavigationController *navController;
}

-(void)changeServerStatus:(BOOL)status infoText:(NSString *)infoText;

@property (nonatomic, strong) NSMutableArray *mainMenu;
@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) NowPlaying *nowPlaying;
@property (strong, nonatomic) RemoteController *remoteController;
@property (strong, nonatomic) HostManagementViewController *hostController;
@property (strong, nonatomic) tcpJSONRPC *tcpJSONRPCconnection;

@end