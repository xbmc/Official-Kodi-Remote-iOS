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

@interface DetailViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>{
    IBOutlet UITableView *dataList;
    IBOutlet jsonDataCell *jsonCell;
    DSJSONRPC *jsonRPC;
    NSMutableArray *richResults;
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
}

@property (strong, nonatomic) id detailItem;
@property(nonatomic,readonly) UIActivityIndicatorView *activityIndicatorView;


@end
