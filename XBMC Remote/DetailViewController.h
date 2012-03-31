//
//  DetailViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"
#import "jsonDataCell.h"
//#import "ShowInfoViewController.h"
#import "UIImageView+WebCache.h"

@class NowPlaying;
//@class DetailViewController;

@interface DetailViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>{
    IBOutlet UITableView *dataList;
    IBOutlet jsonDataCell *jsonCell;
    DSJSONRPC *jsonRPC;
    NSMutableArray *richResults;
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
    NSMutableDictionary *sections;  
    SDWebImageManager *manager;
}

@property (strong, nonatomic) id detailItem;
@property(nonatomic,readonly) UIActivityIndicatorView *activityIndicatorView;
//@property (strong, nonatomic) ShowInfoViewController *showInfoViewController;

@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) NowPlaying *nowPlaying;

@property (nonatomic,retain) NSMutableDictionary *sections;

@end
