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
    NSMutableArray *labelsList;
    NSMutableArray *colorsList;
    NSMutableArray *hideLineSeparator;
    NSMutableArray *fontColorList;
    NSMutableArray *iconsList;
    NSMutableArray *actionsList;
    NSMutableArray *revealTopView;
    NSMutableArray *isSetting;
    UILabel *infoLabel;
    DSJSONRPC *jsonRPC;
    UIAlertView *actionAlertView;
    VolumeSliderView *volumeSliderView;
    RemoteController *remoteControllerView;
    BOOL torchIsOn;
    BOOL putXBMClogo;
    UIView *footerView;
    MessagesView *messagesView;
}

@property (strong, nonatomic) NSMutableArray *rightMenuItems;

@end
