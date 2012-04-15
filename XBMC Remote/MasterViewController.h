//
//  MasterViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"
#import "GlobalData.h"


@class DetailViewController;
@class NowPlaying;
@class RemoteController;
@class HostViewController;


@interface MasterViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>{
    IBOutlet UITableView *menuList;
    IBOutlet UITableView *serverListTableView;

    IBOutlet UITableViewCell *resultMenuCell;
    IBOutlet UITableViewCell *serverListCell;

    IBOutlet UIView *settingsView;
    DSJSONRPC *jsonRPC;
    NSTimer* timer;
    UIButton *xbmcInfo;
    UIButton *xbmcLogo;
    GlobalData *obj;
//    SettingsPanel *settingsPanel;
    NSDictionary *checkServerParams;
    BOOL serverOnLine;
    NSIndexPath *storeServerSelection;
    IBOutlet UIButton *editTableButton;


//    NSMutableArray *serverList;
}

@property (nonatomic, strong) NSMutableArray *mainMenu;
//@property (nonatomic, strong) NSMutableArray *serverList;


@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) NowPlaying *nowPlaying;
@property (strong, nonatomic) RemoteController *remoteController;
@property (strong, nonatomic) HostViewController *hostController;

@property (nonatomic, copy) GlobalData *obj;

@end
