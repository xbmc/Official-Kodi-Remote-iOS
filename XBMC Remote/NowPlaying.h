//
//  NowPlaying.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 24/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "DSJSONRPC.h"
#import "UIImageView+WebCache.h"
#import "OBSlider.h"

@import UIKit;

@class ShowInfoViewController;
@class RemoteController;
@class DetailViewController;

@interface NowPlaying : UIViewController <UITableViewDataSource, UITableViewDelegate, SDWebImageManagerDelegate, UIGestureRecognizerDelegate> {
    IBOutlet UIView *transitionView;
    IBOutlet UITableView *playlistTableView;
    IBOutlet UILabel *albumName;
    IBOutlet UILabel *songName;
    IBOutlet UILabel *artistName;
    IBOutlet UILabel *currentTime;
    IBOutlet UILabel *duration;
    IBOutlet UILabel *upnp;
    IBOutlet UIImageView *jewelView;
    IBOutlet UIImageView *thumbnailView;
    IBOutlet UIView *BottomView;
    IBOutlet UIImageView *fullscreenCover;
    IBOutlet UIVisualEffectView *visualEffectView;
    UIView *transitionFromView;
    UIView *transitionToView;
    IBOutlet UIView *nowPlayingView;
    IBOutlet UIView *playlistView;
    IBOutlet UIView *songDetailsView;
    NSTimer *updateInfoTimer;
    NSTimer *debounceTimer;
    NSMutableArray *playlistData;
    IBOutlet UILabel *songCodec;
    __weak IBOutlet UIImageView *songCodecImage;
    IBOutlet UILabel *songBitRate;
    __weak IBOutlet UIImageView *songBitRateImage;
    IBOutlet UILabel *songSampleRate;
    __weak IBOutlet UIImageView *songSampleRateImage;
    __weak IBOutlet UILabel *songNumChannels;
    __weak IBOutlet UIImageView *songNumChanImage;
    __weak IBOutlet UIImageView *hiresImage;
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
    BOOL musicPartyMode;
    IBOutlet UIButton *editTableButton;
    IBOutlet UIButton *PartyModeButton;
    IBOutlet UIImageView *backgroundImageView;
    IBOutlet UILabel *noFoundLabel;
    NSIndexPath *storeSelection;
    IBOutlet UIView *playlistToolbarView;
    IBOutlet UIView *playlistActionView;
    NSString *currentType;
    BOOL nothingIsPlaying;
    IBOutlet UIButton *playlistButton;
    int animationOptionTransition;
    BOOL startFlipDemo;
    IBOutlet OBSlider *ProgressSlider;
    NSIndexPath *selectedIndexPath;
    NSMutableArray *sheetActions;
    BOOL fromItself;
    IBOutlet UIButton *shuffleButton;
    IBOutlet UIButton *repeatButton;
    IBOutlet UIButton *closeButton;
    UIButton *fullscreenToggleButton;
    BOOL shuffled;
    NSString *repeatStatus;
    BOOL updateProgressBar;
    int totalSeconds;
    NSString *lastThumbnail;
    NSString *notificationName;
    __weak IBOutlet UILabel *scrabbingMessage;
    __weak IBOutlet UILabel *scrabbingRate;
    UIView *toolbarBackground;
    UISegmentedControl *playlistSegmentedControl;
    NSString *storeLiveTVTitle;
    NSString *storeClearlogo;
    NSString *storeClearart;
    NSString *storeCurrentLogo;
    CGFloat bottomPadding;
    BOOL waitForInfoLabelsToSettle;
    CGFloat descriptionFontSize;
    long lastSelected;
    int lastPlayerID;
    int currentPlayerID;
    int currentPlaylistID;
    BOOL isSlideshowActive;
    NSTimer *ignoreAutoscrollTimer;
    BOOL ignoreAutoscrollPlaylist;
    int storePosSeconds;
    long storedItemID;
    BOOL isRemotePlayer;
}

- (void)setNowPlayingSize:(CGSize)viewSize YPOS:(CGFloat)YPOS fullscreen:(BOOL)isFullscreen;
- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil;
- (IBAction)startVibrate:(id)sender;
- (IBAction)changeShuffle:(id)sender;
- (IBAction)changeRepeat:(id)sender;

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) RemoteController *remoteController;
@property (strong, nonatomic) UIImageView *jewelView;
@property (strong, nonatomic) IBOutlet UIImageView *itemLogoImage;
@property (strong, nonatomic) UIButton *shuffleButton;
@property (strong, nonatomic) UIButton *repeatButton;
@property (strong, nonatomic) UIView *songDetailsView;
@property (strong, nonatomic) OBSlider *ProgressSlider;
@property (strong, nonatomic) UIView *BottomView;
@property (strong, nonatomic) UIView *playlistToolbarView;
@property (strong, nonatomic) UIView *toolbarBackground;
@property (strong, nonatomic) IBOutlet UIView *scrabbingView;
@property (strong, nonatomic) IBOutlet UITextView *itemDescription;

@end
