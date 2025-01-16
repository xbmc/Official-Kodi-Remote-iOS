//
//  PlaylistProgressView.h
//  Kodi Remote
//
//  Created by Buschmann on 12.01.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "ProgressBarView.h"
@import UIKit;

#define PLAYLIST_PROGRESS_HEIGHT 24

@interface PlaylistProgressView : UIView {
    UILabel *timeLabel;
    ProgressBarView *progressBarView;
}

- (void)setProgress:(CGFloat)progress;
- (void)setTime:(NSString*)timeString;

@end
