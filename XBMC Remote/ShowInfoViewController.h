//
//  ShowInfoViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "DSJSONRPC.h"
#import "JBKenBurnsView.h"
#import "Utilities.h"
#import <SafariServices/SafariServices.h>

@class NowPlaying;
@class DetailViewController;

@interface ShowInfoViewController : UIViewController <UIScrollViewDelegate, KenBurnsViewDelegate, UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate, WKUIDelegate> {
    IBOutlet UIImageView *coverView;
    IBOutlet UIImageView *starsView;
    IBOutlet UILabel *voteLabel;
    IBOutlet UILabel *numVotesLabel;
    IBOutlet UIScrollView *scrollView;
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
    
    UILabel *mainLabel0;
    UILabel *mainLabel1;
    UILabel *mainLabel2;
    UILabel *mainLabel3;
    UILabel *mainLabel4;
    UILabel *mainLabel5;
    UILabel *parentalRatingMainLabel;
    UILabel *castMainLabel;
    
    UILabel *subLabel0;
    UILabel *subLabel1;
    UILabel *subLabel2;
    UILabel *subLabel3;
    UILabel *subLabel4;
    UILabel *subLabel5;
    UILabel *parentalRatingSubLabel;

    UILabel *trailerLabel;
    UIButton *trailerPlayButton;
    WKWebView *trailerWebView;

    IBOutlet UIButton *arrow_back_up;
    IBOutlet UIButton *arrow_continue_down;
    IBOutlet UIImageView *jewelView;
    IBOutlet UIImageView *fanartView;

    NSDateFormatter *xbmcDateFormatter;
    NSDateFormatter *localStartDateFormatter;
    NSDateFormatter *localEndDateFormatter;
    BOOL isPvrDetail;
    UIToolbar *toolbar;
    NSMutableArray *sheetActions;
    UIBarButtonItem *actionSheetButtonItem;
    UIBarButtonItem *extraButton;
    int choosedTab;
    NSString *notificationName;
    float resumePointPercentage;
    KenBurnsView *kenView;
    BOOL enableKenBurns;
    BOOL isFullscreenFanArt;
    UIButton *closeButton;
    UIButton *clearlogoButton;
    UIImageView *clearLogoImageView;
    int clearLogoWidth;
    int clearLogoHeight;
    int clearlogoScrollViewY;
    NSArray *castList;
    int castWidth;
    int castHeight;
    int castFontSize;
    int lineSpacing;
    int thumbWidth;
    int tvshowHeight;
    UITableView *actorsTable;
    NSURL *embedVideoURL;
    UIColor *foundTintColor;
    UILabel *viewTitle;
    __weak IBOutlet UIImageView *bottomShadow;
    BOOL isViewDidLoad;
    UIImageView *isRecording;
    LogoBackgroundType logoBackgroundMode;
    UIBarButtonItem *doneButton;
}

- (id)initWithNibName:(NSString*)nibNameOrNil withItem:(NSDictionary*)item withFrame:(CGRect)frame bundle:(NSBundle*)nibBundleOrNil;

@property (strong, nonatomic) id detailItem;
@property (nonatomic, strong) KenBurnsView *kenView;

@end
