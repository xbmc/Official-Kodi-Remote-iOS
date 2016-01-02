//
//  RightMenuViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 9/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECSlidingViewController.h"
#import "DSJSONRPC.h"
#import "RemoteController.h"
#import "VolumeSliderView.h"
#import "MessagesView.h"

@interface RightMenuViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>{
    UITableView *menuTableView;
    NSMutableArray* _rightMenuItems;
    IBOutlet UITableViewCell *rightMenuCell;
    NSMutableArray *tableData;
    UILabel *infoLabel;
    DSJSONRPC *jsonRPC;
    UIAlertView *actionAlertView;
    VolumeSliderView *volumeSliderView;
    RemoteController *remoteControllerView;
    BOOL torchIsOn;
    BOOL putXBMClogo;
    MessagesView *messagesView;
    NSUInteger editableRowStartAt;
    UIBarButtonItem *editTableButton;
    UIBarButtonItem *addButton;
    NSMutableDictionary *infoCustomButton;
}

@property (strong, nonatomic) NSMutableArray *rightMenuItems;

@end
