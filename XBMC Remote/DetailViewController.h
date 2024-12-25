//
//  DetailViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "DSJSONRPC.h"
#import "jsonDataCell.h"
#import "ShowInfoViewController.h"
#import "UIImageView+WebCache.h"
#import "mainMenu.h"
#import "MoreItemsViewController.h"
#import "Utilities.h"
#import "BDKCollectionIndexView.h"
#import "FloatingHeaderFlowLayout.h"
#import "BaseActionViewController.h"

@import UIKit;
@import SafariServices;

@class NowPlaying;

@interface DetailViewController : BaseActionViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating> {
    IBOutlet UITableView *dataList;
    IBOutlet jsonDataCell *jsonCell;
    NSMutableArray *filteredListContent;
    NSMutableArray *storeRichResults;
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
    NSMutableDictionary *sections;
    int chosenTab;
    int filterModeIndex;
    ViewModes filterModeType;
    UILabel *topNavigationLabel;
    IBOutlet UIButton *button1;
    IBOutlet UIButton *button2;
    IBOutlet UIButton *button3;
    IBOutlet UIButton *button4;
    IBOutlet UIButton *button5;
    IBOutlet UIButton *button6;
    IBOutlet UIButton *button7;
    IBOutlet UIView *buttonsView;
    IBOutlet UIVisualEffectView *buttonsViewEffect;
    NSString *defaultThumb;
    int cellHeight;
    int thumbWidth;
    IBOutlet UIView *noFoundView;
    int viewWidth;
    IBOutlet UIView *maskView;
    MoreItemsViewController *moreItemsViewController;
    UIImageView *longTimeout;
    NSTimeInterval startTime;
    NSTimeInterval elapsedTime;
    NSTimer *countExecutionTime;
    int labelPosition;
    int flagX;
    int flagY;
    BOOL albumView;
    BOOL episodesView;
    BOOL tvshowsView;
    BOOL channelGuideView;
    BOOL channelListView;
    BOOL recordingListView;
    BOOL globalSearchView;
    BOOL useSectionInSearchResults;
    int albumViewHeight;
    int albumViewPadding;
    int artistFontSize;
    int albumFontSize;
    int trackCountFontSize;
    int sectionHeight;
    UIColor *albumColor;
    UICollectionView *collectionView;
    BOOL enableCollectionView;
    int cellGridWidth;
    int cellGridHeight;
    int fullscreenCellGridWidth;
    int fullscreenCellGridHeight;
    int cellMinimumLineSpacing;
    UITableView *activeLayoutView;
    UILongPressGestureRecognizer *longPressGestureCollection;
    UILongPressGestureRecognizer *longPressGestureList;
    int posterFontSize;
    int fanartFontSize;
    FloatingHeaderFlowLayout *flowLayout;
    UIView *sectionNameOverlayView;
    UILabel *sectionNameLabel;
    BOOL recentlyAddedView;
    BOOL enableDiskCache;
    CGFloat iOSYDelta;
    __weak IBOutlet UIToolbar *buttonsViewBgToolbar;
    BOOL loadAndPresentDataOnViewDidAppear;
    BOOL forceMusicAlbumMode;
    NSMutableDictionary *epgDict;
    NSMutableArray *epgDownloadQueue;
    NSDateFormatter *xbmcDateFormatter;
    NSDateFormatter *localHourMinuteFormatter;
    NSIndexPath *autoScrollTable;
    __weak IBOutlet UILabel *noItemsLabel;
    BOOL stackscrollFullscreen;
    BOOL forceCollection;
    NSMutableDictionary *storeSections;
    NSArray *storeSectionArray;
    UIButton *fullscreenButton;
    UIView *titleView;
    BOOL hiddenLabel;
    UIPinchGestureRecognizer *twoFingerPinch;
    NSTimer *channelListUpdateTimer;
    NSInteger sortMethodIndex;
    NSString *sortMethodName;
    NSString *sortAscDesc;
    int numberOfStars;
    NSDictionary *watchedListenedStrings;
    int serverMajorVersion;
    int serverMinorVersion;
    NSString *libraryCachePath;
    CGFloat bottomPadding;
    NSString *epgCachePath;
    BOOL showSearchbar;
    dispatch_queue_t epglockqueue;
    LogoBackgroundType logoBackgroundMode;
    BOOL showkeyboard;
    NSIndexPath *selectedIndexPath;
    NSNumber *processAllItemsInSection;
}

- (id)initWithFrame:(CGRect)frame;
- (id)initWithNibName:(NSString*)nibNameOrNil withItem:(mainMenu*)item withFrame:(CGRect)frame bundle:(NSBundle*)nibBundleOrNil;

@property (nonatomic, strong) NSMutableArray *filteredListContent;
@property (strong, nonatomic) BDKCollectionIndexView *indexView;
@property (nonatomic, strong) NSMutableDictionary *sections;
@property (nonatomic, strong) NSMutableArray *richResults;
@property (nonatomic, strong) NSArray *sectionArray;
@property (nonatomic, strong) NSMutableArray *sectionArrayOpen;
@property (nonatomic, strong) NSMutableArray *extraSectionRichResults;
@property (strong, nonatomic) UISearchController *searchController;

@end
