//
//  MasterViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"
#import "SettingsPanel.h"


@class DetailViewController;
@class NowPlaying;
@class RemoteController;


@interface MasterViewController : UITableViewController <UITableViewDataSource,UITableViewDelegate>{
    IBOutlet UITableView *menuList;
    IBOutlet UITableViewCell *resultMenuCell;
    DSJSONRPC *jsonRPC;
    NSTimer* timer;
    UIButton *xbmcInfo;
    UIButton *xbmcLogo;
    SettingsPanel *settingsPanel;
}

@property (nonatomic, strong) NSMutableArray *mainMenu;

@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) NowPlaying *nowPlaying;
@property (strong, nonatomic) RemoteController *remoteController;

@end
