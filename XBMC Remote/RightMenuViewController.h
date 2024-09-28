//
//  RightMenuViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 9/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"
#import "RemoteController.h"
#import "VolumeSliderView.h"

@interface RightMenuViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    UITableView *menuTableView;
    NSMutableArray *tableData;
    VolumeSliderView *volumeSliderView;
    RemoteController *remoteControllerView;
    BOOL torchIsOn;
    NSUInteger editableRowStartAt;
    UIButton *editTableButton;
    UIButton *moreButton;
    NSDictionary *infoCustomButton;
}

@property (strong, nonatomic) NSMutableArray *rightMenuItems;

@end
