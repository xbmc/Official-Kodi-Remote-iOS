//
//  MasterViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;
@class NowPlaying;
@class RemoteController;


@interface MasterViewController : UITableViewController{
    IBOutlet UITableView *menuList;
    IBOutlet UITableViewCell *resultPOICell;
}

@property (nonatomic, strong) NSMutableArray *mainMenu;

@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) NowPlaying *nowPlaying;
@property (strong, nonatomic) RemoteController *remoteController;

@end
