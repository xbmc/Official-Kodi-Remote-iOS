//
//  ShowInfoViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "DSJSONRPC.h"
#import "JBKenBurnsView.h"
#import "Utilities.h"
#import "BaseActionViewController.h"

@import UIKit;
@import SafariServices;
@import WebKit;

@class NowPlaying;
@class DetailViewController;

@interface ShowInfoViewController : BaseActionViewController <UIScrollViewDelegate, KenBurnsViewDelegate, UITableViewDataSource, UITableViewDelegate, WKUIDelegate> {
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

    NSDateFormatter *localStartDateFormatter;
    NSDateFormatter *localEndDateFormatter;
    BOOL isPvrDetail;
    UIToolbar *toolbar;
    UIVisualEffectView *effectView;
    NSMutableArray *sheetActions;
    UIBarButtonItem *actionSheetButtonItem;
    UIBarButtonItem *extraButton;
    NSString *notificationName;
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
    UIImageView *isRecording;
    LogoBackgroundType logoBackgroundMode;
    UIBarButtonItem *doneButton;
}

- (id)initWithNibName:(NSString*)nibNameOrNil withItem:(NSDictionary*)item withFrame:(CGRect)frame bundle:(NSBundle*)nibBundleOrNil;

@property (nonatomic, strong) KenBurnsView *kenView;

@end
