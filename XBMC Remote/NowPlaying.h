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

@class RemoteController;

@interface NowPlaying : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>{
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
    BOOL updateDetailsView;

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
}

- (void)setToolbarWidth:(int)width height:(int)height YPOS:(int)YPOS playBarWidth:(int)playBarWidth portrait:(BOOL)isPortrait;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
- (IBAction)startVibrate:(id)sender;
- (void)toggleSongDetails;

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) RemoteController *remoteController;
@property (strong, nonatomic) UIImageView *jewelView;



@end
