//
//  NowPlaying.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 24/3/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"
#import "VolumeSliderView.h"

@interface NowPlaying : UIViewController <UITableViewDataSource,UITableViewDelegate>{
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
    int PlayerPaused;
    int musicPartyMode;
    IBOutlet UIButton *seg_music;
    IBOutlet UIButton *seg_video;
}

- (IBAction)startVibrate:(id)sender;

@property (strong, nonatomic) id detailItem;

@end
