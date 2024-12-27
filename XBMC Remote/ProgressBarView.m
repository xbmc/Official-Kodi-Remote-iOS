//
//  ProgressBarView.m
//  Kodi Remote
//
//  Created by Buschmann on 12.01.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "ProgressBarView.h"
#import "Utilities.h"

#define PROGRESSBAR_RADIUS 2

@implementation ProgressBarView

@synthesize progress;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self createProgressBar];
    }
    return self;
}

- (void)createProgressBar {
    progressBarTrack = [UIView new];
    progressBarTrack.layer.cornerRadius = PROGRESSBAR_RADIUS;
    progressBarTrack.clipsToBounds = YES;
    [self addSubview:progressBarTrack];
    
    progressBar = [UIView new];
    progressBar.backgroundColor = KODI_BLUE_COLOR;
    [progressBarTrack addSubview:progressBar];
}

- (void)setTrackColor:(UIColor*)color {
    progressBarTrack.backgroundColor = color;
}

- (void)setProgress:(CGFloat)newProgress {
    progress = newProgress;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    progressBarTrack.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    progressBar.frame = CGRectMake(0, 0, progress * CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
}

@end
