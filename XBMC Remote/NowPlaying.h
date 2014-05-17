//
//  NowPlaying.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 24/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"
#import "VolumeSliderView.h"
#import "UIImageView+WebCache.h"
#import "RightMenuViewController.h"
#import "OBSlider.h"

@class ShowInfoViewController;
@class RemoteController;
@class DetailViewController;

@interface NowPlaying : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIActionSheetDelegate, SDWebImageManagerDelegate, UIGestureRecognizerDelegate>{
    DSJSONRPC *jsonRPC;
    IBOutlet UITableView *playlistTableView;
    IBOutlet UITableViewCell *playlistTableViewCell;
   // IBOutlet jsonDataCell *jsonCell;
    IBOutlet UILabel *albumName;
    IBOutlet UILabel *songName;
    IBOutlet UILabel *artistName;
    IBOutlet UILabel *currentTime;
    IBOutlet UILabel *duration;
    IBOutlet UIImageView *timeCursor;
    IBOutlet UIImageView *timeBar;
    IBOutlet UIImageView *jewelView;
    IBOutlet UIImageView *thumbnailView;
    UIView *transitionView;
    UIView *transitionedView;
    IBOutlet UIView *nowPlayingView;
    IBOutlet UIView *playlistView;
    IBOutlet UIView *songDetailsView;
    UILabel *viewTitle;
    NSTimer* timer;
    VolumeSliderView *volumeSliderView;
    NSMutableArray *playlistData;
    IBOutlet UILabel *songCodec;
    IBOutlet UILabel *songBitRate;
    IBOutlet UILabel *songSampleRate;
    
    IBOutlet UILabel *labelSongCodec;
    IBOutlet UILabel *labelSongBitRate;
    IBOutlet UILabel *labelSongSampleRate;
    int playerID;
    int selectedPlayerID;
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
    int playerPlaying;
    BOOL PlayerPaused;
    int musicPartyMode;
    IBOutlet UIButton *seg_music;
    IBOutlet UIButton *seg_video;
    IBOutlet UIButton *editTableButton;
    IBOutlet UIButton *PartyModeButton;
    IBOutlet UIImageView *backgroundImageView;

    IBOutlet UIView *noFoundView;
    NSIndexPath *storeSelection;
    int slideFrom;
    int numResults;
    SDWebImageManager *manager;
    IBOutlet UIToolbar *playlistToolbar;
    
    int iPadOrigX;
    int iPadOrigY;
    int iPadthumbWidth;
    int iPadthumbHeight;
    IBOutlet UIView *playlistActionView;
    IBOutlet UIImageView *pgbar;
    BOOL portraitMode;
    NSString *currentType;
    BOOL nothingIsPlaying;
    IBOutlet UIImageView *xbmcOverlayImage;
    IBOutlet UIImageView *xbmcOverlayImage_iphone;
    IBOutlet UIButton *playlistButton;
    BOOL playlistHidden;
    BOOL nowPlayingHidden;
    int anim;
    int anim2;
    BOOL startFlipDemo;
    IBOutlet OBSlider *ProgressSlider;
    NSIndexPath *selected;
    NSMutableArray *sheetActions;
    BOOL fromItself;
    IBOutlet UIButton *shuffleButton;
    IBOutlet UIButton *repeatButton;
    IBOutlet UIButton *albumDetailsButton;
    IBOutlet UIButton *albumTracksButton;
    IBOutlet UIButton *artistDetailsButton;
    IBOutlet UIButton *artistAlbumsButton;
        BOOL shuffled;
    NSString *repeatStatus;
    BOOL updateProgressBar;
    int globalSeconds;
    NSString *lastThumbnail;
    int choosedTab;
    NSString *notificationName;
    __weak IBOutlet UIImageView *playlistLeftShadow;
    __weak IBOutlet UIView *scrabbingView;
    __weak IBOutlet UILabel *scrabbingMessage;
    __weak IBOutlet UILabel *scrabbingRate;
    UIView *iOS7bgEffect;
    UIView *iOS7navBarEffect;
    UIColor *foundEffectColor;
    NSString *pg_thumb_name;
    UISegmentedControl *playlistSegmentedControl;
    UIColor *cellBackgroundColor;
    __weak IBOutlet UILabel *noItemsLabel;
}

- (void)setToolbarWidth:(int)width height:(int)height YPOS:(int)YPOS playBarWidth:(int)playBarWidth portrait:(BOOL)isPortrait;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
- (IBAction)startVibrate:(id)sender;
- (void)toggleSongDetails;
- (IBAction)changeShuffle:(id)sender;
- (IBAction)changeRepeat:(id)sender;


@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) RemoteController *remoteController;
@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) ShowInfoViewController *showInfoViewController;
@property (strong, nonatomic) UIImageView *jewelView;
@property (strong, nonatomic) UIButton *shuffleButton;
@property (strong, nonatomic) UIButton *repeatButton;
@property (strong, nonatomic) UIView *songDetailsView;
@property (strong, nonatomic) OBSlider *ProgressSlider;
//@property BOOL presentedFromNavigation;



@end
