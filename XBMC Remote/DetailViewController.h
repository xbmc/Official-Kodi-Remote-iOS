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
#import "ShowInfoViewController.h"
#import "UIImageView+WebCache.h"
#import <MediaPlayer/MediaPlayer.h>

@class NowPlaying;
@class PlayFileViewController;
//@class DetailViewController;

@interface DetailViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UIActionSheetDelegate, UIWebViewDelegate>{
    IBOutlet UITableView *dataList;
    IBOutlet jsonDataCell *jsonCell;
    DSJSONRPC *jsonRPC;
    NSMutableArray *richResults;
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
    NSMutableDictionary *sections;  
    SDWebImageManager *manager;
    IBOutlet UILongPressGestureRecognizer *lpgr;
    IBOutlet UISearchBar *searchBar;
    BOOL searching;
    BOOL letUserSelectRow;
	NSMutableArray *copyListOfItems;
    BOOL alreadyPush;
    IBOutlet UIWebView *webPlayView;
    MPMoviePlayerController *playerViewController;

}

@property (strong, nonatomic) id detailItem;
@property(nonatomic,readonly) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) ShowInfoViewController *showInfoViewController;

@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) NowPlaying *nowPlaying;
@property (strong, nonatomic) PlayFileViewController *playFileViewController;


@property (nonatomic,retain) NSMutableDictionary *sections;

@end
