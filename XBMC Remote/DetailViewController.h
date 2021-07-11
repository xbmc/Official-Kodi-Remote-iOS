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
#import "MoreItemsViewController.h"
#import "Utilities.h"
#import "BDKCollectionIndexView.h"
#import "FloatingHeaderFlowLayout.h"
#import "MessagesView.h"
#import <SafariServices/SafariServices.h>

@class NowPlaying;
//@class DetailViewController;

@interface DetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating, SFSafariViewControllerDelegate> {
    IBOutlet UITableView *dataList;
    IBOutlet jsonDataCell *jsonCell;
    NSMutableArray	*filteredListContent;
    NSMutableArray *storeRichResults;
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
    NSMutableDictionary *sections;
    IBOutlet UILongPressGestureRecognizer *lpgr;
    int choosedTab;
    int numTabs;
    int watchMode;
    UILabel *topNavigationLabel;
    IBOutlet UIButton *button1;
    IBOutlet UIButton *button2;
    IBOutlet UIButton *button3;
    IBOutlet UIButton *button4;
    IBOutlet UIButton *button5;
    IBOutlet UIButton *button6;
    IBOutlet UIButton *button7;
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
    BOOL channelGuideView;
    BOOL channelListView;
    BOOL recordingListView;
    int albumViewHeight;
    int albumViewPadding;
    int artistFontSize;
    int albumFontSize;
    int trackCountFontSize;
    int trackCountLabelWidth;
    int epgChannelTimeLabelWidth;
    int labelPadding;
    int sectionHeight;
    UIColor *albumColor;
    UIColor *searchBarColor;
    UIColor *tableViewSearchBarColor;
    UIColor *collectionViewSearchBarColor;
    BOOL enableBarColor;
    UICollectionView *collectionView;
    BOOL enableCollectionView;
    int cellGridWidth;
    int cellGridHeight;
    int fullscreenCellGridWidth;
    int fullscreenCellGridHeight;
    int cellMinimumLineSpacing;
    id activeLayoutView;
    UILongPressGestureRecognizer *longPressGesture;
    int posterFontSize;
    int fanartFontSize;
    FloatingHeaderFlowLayout *flowLayout;
    //  EXPERIMENTAL CODE
//    NSMutableArray *darkCells;
//    BOOL autoScroll;
    // END EXPERIMENTAL CODE
    UIView *sectionNameOverlayView;
    UILabel *sectionNameLabel;
    BOOL recentlyAddedView;
    BOOL enableDiskCache;
    BOOL blackTableSeparator;
    NSString *currentCollectionViewName;
    CGFloat iOSYDelta;
    __weak IBOutlet UIToolbar *buttonsViewBgToolbar;
    BOOL isViewDidLoad;
    BOOL hideSearchBarActive;
    BOOL enableIpadWA;
    BOOL forceMusicAlbumMode;
    NSMutableDictionary *epgDict;
    NSMutableArray *epgDownloadQueue;
    NSDateFormatter *xbmcDateFormatter;
    NSDateFormatter *localHourMinuteFormatter;
    NSIndexPath *autoScrollTable;
    MessagesView *messagesView;
    __weak IBOutlet UILabel *noItemsLabel;
    BOOL stackscrollFullscreen;
    BOOL forceCollection;
    NSMutableDictionary *storeSections;
    NSArray *storeSectionArray;
    UIButton *fullscreenButton;
    UIView *titleView;
    BOOL hiddenLabel;
    UIPinchGestureRecognizer *twoFingerPinch;
    NSTimer* channelListUpdateTimer;
    NSUInteger sortMethodIndex;
    NSString *sortMethodName;
    NSString *sortAscDesc;
    int numberOfStars;
    NSDictionary *watchedListenedStrings;
    int serverVersion;
    int serverMinorVersion;
    NSString *libraryCachePath;
    CGFloat bottomPadding;
    NSString *epgCachePath;
    BOOL showbar;
    dispatch_queue_t epglockqueue;
    LogoBackgroundType logoBackgroundMode;
    BOOL showkeyboard;
}

- (id)initWithFrame:(CGRect)frame;
- (id)initWithNibName:(NSString*)nibNameOrNil withItem:(mainMenu*)item withFrame:(CGRect)frame bundle:(NSBundle*)nibBundleOrNil;

@property (nonatomic, retain) NSMutableArray *filteredListContent;
@property (strong, nonatomic) id detailItem;
@property (nonatomic, readonly) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) BDKCollectionIndexView *indexView;
@property (nonatomic, retain) NSMutableDictionary *sections;
@property (nonatomic, retain) NSMutableArray *richResults;
@property (nonatomic, retain) NSArray *sectionArray;
@property (nonatomic, retain) NSMutableArray *sectionArrayOpen;
@property (nonatomic, retain) NSMutableArray *extraSectionRichResults;
@property (strong, nonatomic) UISearchController *searchController;

@end
