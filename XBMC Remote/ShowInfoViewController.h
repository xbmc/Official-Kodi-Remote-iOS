//
//  ShowInfoViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"
#import "JBKenBurnsView.h"
#import "Utilities.h"
#import <SafariServices/SafariServices.h>

@class NowPlaying;
@class DetailViewController;

@interface ShowInfoViewController : UIViewController <UIScrollViewDelegate, KenBurnsViewDelegate, UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate> {
    IBOutlet UIImageView *coverView;
    IBOutlet UIImageView *starsView;
    IBOutlet UILabel *voteLabel;
    IBOutlet UILabel *numVotesLabel;
    IBOutlet UIScrollView *scrollView;
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
    IBOutlet UILabel *directorLabel;
    IBOutlet UILabel *genreLabel;
    IBOutlet UILabel *runtimeLabel;
    IBOutlet UILabel *studioLabel;
    IBOutlet UILabel *summaryLabel;
    IBOutlet UILabel *parentalRatingLabelUp;
    IBOutlet UILabel *parentalRatingLabel;
    
    IBOutlet UILabel *label1;
    IBOutlet UILabel *label2;
    IBOutlet UILabel *label3;
    IBOutlet UILabel *label4;
    IBOutlet UILabel *label5;
    IBOutlet UILabel *label6;

    UILabel *trailerLabel;
    UIButton *playTrailerButton;

    IBOutlet UIButton *arrow_continue_down;
    IBOutlet UIImageView *jewelView;
    IBOutlet UIImageView *fanartView;

    NSDateFormatter *xbmcDateFormatter;
    NSDateFormatter *localStartDateFormatter;
    NSDateFormatter *localEndDateFormatter;
    BOOL isPvrDetail;
    UIToolbar *toolbar;
    NSMutableArray *sheetActions;
    UIBarButtonItem *actionSheetButtonItemIpad;
    int choosedTab;
    NSString *notificationName;
    float resumePointPercentage;
    KenBurnsView *kenView;
    BOOL enableKenBurns;
    UIButton *closeButton;
    UIButton *clearlogoButton;
    UIImageView *clearLogoImageView;
    int clearLogoWidth;
    int clearLogoHeight;
    int clearlogoScrollViewY;
    NSArray *cast;
    int castWidth;
    int castHeight;
    int castFontSize;
    int lineSpacing;
    int thumbWidth;
    int tvshowHeight;
    UITableView *actorsTable;
    NSString *embedVideoURL;
    UIColor *foundTintColor;
    UILabel *viewTitle;
    __weak IBOutlet UIImageView *bottomShadow;
    CGRect originalSelfFrame;
    BOOL isViewDidLoad;
    UIImageView *isRecording;
    LogoBackgroundType logoBackgroundMode;
    UIBarButtonItem *doneButton;
}

- (id)initWithNibName:(NSString*)nibNameOrNil withItem:(NSDictionary*)item withFrame:(CGRect)frame bundle:(NSBundle*)nibBundleOrNil;

@property (strong, nonatomic) id detailItem;
@property (nonatomic, retain) KenBurnsView *kenView;

@end
