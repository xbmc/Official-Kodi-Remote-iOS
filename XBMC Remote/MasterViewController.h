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


@interface MasterViewController : UIViewController <UITableViewDataSource,UITableViewDelegate, UITextFieldDelegate>{
    IBOutlet UITableView *menuList;
    IBOutlet UITableViewCell *resultMenuCell;
    IBOutlet UIView *settingsView;
    DSJSONRPC *jsonRPC;
    NSTimer* timer;
    UIButton *xbmcInfo;
    UIButton *xbmcLogo;
    GlobalData *obj;
//    SettingsPanel *settingsPanel;
    NSDictionary *checkServerParams;
    BOOL serverOnLine;
    
    IBOutlet UITextField *descriptionUI;
    IBOutlet UITextField *ipUI;
    IBOutlet UITextField *portUI;
    IBOutlet UITextField *usernameUI;
    IBOutlet UITextField *passwordUI;
}

@property (nonatomic, strong) NSMutableArray *mainMenu;

@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) NowPlaying *nowPlaying;
@property (strong, nonatomic) RemoteController *remoteController;
@property (nonatomic, copy) GlobalData *obj;

@end
