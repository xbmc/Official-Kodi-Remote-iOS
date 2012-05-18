//
//  MasterViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"

@class DetailViewController;
@class NowPlaying;
@class RemoteController;
@class HostViewController;
@class AppInfoViewController;
@class HostManagementViewController;


@interface MasterViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>{
    IBOutlet UITableView *menuList;
    IBOutlet UITableViewCell *resultMenuCell;
    DSJSONRPC *jsonRPC;
    NSTimer* timer;
    UIButton *xbmcInfo;
    UIButton *xbmcLogo;
    NSDictionary *checkServerParams;
    BOOL firstRun;
    BOOL inCheck;
    NSIndexPath *storeServerSelection;
    AppInfoViewController *appInfoView;
    HostManagementViewController *hostManagementViewController;
}

-(void)changeServerStatus:(BOOL)status infoText:(NSString *)infoText;
-(void)setFirstRun:(BOOL)value;
-(void)setInCheck:(BOOL)value;

@property (nonatomic, strong) NSMutableArray *mainMenu;
@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) NowPlaying *nowPlaying;
@property (strong, nonatomic) RemoteController *remoteController;
@property (strong, nonatomic) HostViewController *hostController;

@end
