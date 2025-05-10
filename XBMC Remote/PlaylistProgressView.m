//
//  PlaylistProgressView.m
//  Kodi Remote
//
//  Created by Buschmann on 12.01.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "PlaylistProgressView.h"
#import "Utilities.h"

#define TIMELABEL_HEIGHT 15
#define PROGRESSBAR_HEIGHT 6
#define BAR_PADDING 4
#define FONT_SIZE 12

@implementation PlaylistProgressView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self createProgressView];
    }
    return self;
}

- (void)createProgressView {
    self.backgroundColor = PLAYLIST_PROGRESSBAR_BACKGROUND_COLOR;
    
    timeLabel = [UILabel new];
    timeLabel.font = [UIFont systemFontOfSize:FONT_SIZE];
    timeLabel.adjustsFontSizeToFitWidth = YES;
    timeLabel.minimumScaleFactor = FONT_SCALING_MIN;
    timeLabel.textAlignment = NSTextAlignmentCenter;
    timeLabel.textColor = UIColor.whiteColor;
    timeLabel.text = @"00:00";
    [self addSubview:timeLabel];
    
    progressBarView = [ProgressBarView new];
    [self addSubview:progressBarView];
    
    [progressBarView setTrackColor:PLAYLIST_PROGRESSBAR_TRACK_COLOR];
}

- (void)setProgress:(CGFloat)progress {
    if (progressBarView.progress == 0 && progress > 0) {
        [UIView animateWithDuration:0.5
                         animations:^{
            progressBarView.progress = progress;
            [self layoutIfNeeded];
        }];
    }
    else {
        progressBarView.progress = progress;
    }
}

- (void)setTime:(NSString*)timeString {
    timeLabel.text = timeString;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    timeLabel.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), TIMELABEL_HEIGHT);
    progressBarView.frame = CGRectMake(BAR_PADDING, CGRectGetMaxY(timeLabel.frame), CGRectGetWidth(self.frame) - 2 * BAR_PADDING, PROGRESSBAR_HEIGHT);
}

@end
