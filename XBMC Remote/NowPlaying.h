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

@interface NowPlaying : UIViewController{
    DSJSONRPC *jsonRPC;
    IBOutlet UILabel *albumName;
    IBOutlet UILabel *songName;
    IBOutlet UILabel *artistName;
    IBOutlet UILabel *currentTime;
    IBOutlet UILabel *duration;
    IBOutlet UIImageView *timeCursor;
    IBOutlet UIImageView *timeBar;
    IBOutlet UIImageView *jewelView;
    IBOutlet UIImageView *thumbnailView;
    NSTimer* timer;
    VolumeSliderView *volumeSliderView;
}

- (IBAction)startVibrate:(id)sender;

@property (strong, nonatomic) id detailItem;

@end
