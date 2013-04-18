//
//  DetailViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"
#import "jsonDataCell.h"
#import "ShowInfoViewController.h"
#import "UIImageView+WebCache.h"
#import <MediaPlayer/MediaPlayer.h>
#import "mainMenu.h"
#import "WebViewController.h"
#import "MoreItemsViewController.h"
#import "Utilities.h"
#import "BDKCollectionIndexView.h"
#import "FloatingHeaderFlowLayout.h"

@class NowPlaying;
@class PlayFileViewController;
//@class DetailViewController;

@interface DetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>{
    IBOutlet UITableView *dataList;
    IBOutlet jsonDataCell *jsonCell;
    DSJSONRPC *jsonRPC;
    NSMutableArray	*filteredListContent;
    NSMutableArray *storeRichResults;
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
    NSMutableDictionary *sections;  
    SDWebImageManager *manager;
    IBOutlet UILongPressGestureRecognizer *lpgr;
    BOOL alreadyPush;
    IBOutlet UIWebView *webPlayView;
    MPMoviePlayerController *playerViewController;
    int choosedTab;
    int numTabs;
    int watchMode;
    UILabel *topNavigationLabel;
    IBOutlet UIButton *button1;
    IBOutlet UIButton *button2;
    IBOutlet UIButton *button3;
    IBOutlet UIButton *button4;
    IBOutlet UIButton *button5;
    IBOutlet UIView *buttonsView;
    int numResults;
    int numFilteredResults;
    NSString *defaultThumb;
    int cellHeight;
    int thumbWidth;
    IBOutlet UIView *noFoundView;
    int viewWidth;
    IBOutlet UIView *detailView;
    MoreItemsViewController* moreItemsViewController;
    UIButton *selectedMoreTab;
    UIImageView *longTimeout;
    NSTimeInterval startTime;
    NSTimeInterval elapsedTime;
    NSTimer *countExecutionTime;
    __weak IBOutlet UITextView *debugText;
    BOOL callBack;
    int labelPosition;
    int flagX;
    int flagY;
    BOOL albumView;
    BOOL episodesView;
    BOOL tvshowsView;
    int albumViewHeight;
    int albumViewPadding;
    int artistFontSize;
    int albumFontSize;
    int trackCountFontSize;
    int trackCountLabelWidth;
    int labelPadding;
    UIColor *albumColor;
    UIColor *searchBarColor;
    UIColor *tableViewSearchBarColor;
    UIColor *collectionViewSearchBarColor;
    BOOL enableBarColor;
    Utilities *utils;
    UICollectionView *collectionView;
    BOOL enableCollectionView;
    int cellGridWidth;
    int cellGridHeight;
    int cellMinimumLineSpacing;
    id activeLayoutView;
    UILongPressGestureRecognizer *longPressGesture;
    int posterFontSize;
    int fanartFontSize;
    FloatingHeaderFlowLayout *flowLayout;
    //  EXPERIMENTAL CODE
    NSMutableArray *darkCells;
    BOOL autoScroll;
    // END EXPERIMENTAL CODE
    UIView *sectionNameOverlayView;
    UILabel *sectionNameLabel;
    BOOL recentlyAddedView;
    BOOL enableDiskCache;
    BOOL blackTableSeparator;
    NSString *currentCollectionViewName;
}

- (id)initWithFrame:(CGRect)frame;
- (id)initWithNibName:(NSString *)nibNameOrNil withItem:(mainMenu *)item withFrame:(CGRect)frame bundle:(NSBundle *)nibBundleOrNil;

@property (nonatomic, retain) NSMutableArray *filteredListContent;
@property (strong, nonatomic) id detailItem;
@property(nonatomic,readonly) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) ShowInfoViewController *showInfoViewController;
@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) NowPlaying *nowPlaying;
@property (strong, nonatomic) PlayFileViewController *playFileViewController;
@property (strong, nonatomic) WebViewController *webViewController;
@property (strong, nonatomic) BDKCollectionIndexView *indexView;
@property (nonatomic,retain) NSMutableDictionary *sections;
@property (nonatomic,retain) NSMutableArray *richResults;
@property (nonatomic,retain) NSArray *sectionArray;
@property (nonatomic,retain) NSMutableArray *sectionArrayOpen;
@property (nonatomic,retain) NSMutableArray *extraSectionRichResults;

@end