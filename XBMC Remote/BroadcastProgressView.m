//
//  BroadcastProgressView.m
//  Kodi Remote
//
//  Created by Buschmann on 27.12.24.
//  Copyright © 2024 Team Kodi. All rights reserved.
//

#import "BroadcastProgressView.h"
#import "ProgressBarView.h"
#import "Utilities.h"

#define RESERVED_WIDTH 14
#define PROGRESSBAR_HEIGHT 6
#define FONT_SIZE 10

@implementation BroadcastProgressView

@synthesize barLabel;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self createProgressView];
    }
    return self;
}

- (void)createProgressView {
    progressBarView = [ProgressBarView new];
    [self addSubview:progressBarView];
    
    barLabel = [UILabel new];
    barLabel.font = [UIFont systemFontOfSize:FONT_SIZE];
    barLabel.adjustsFontSizeToFitWidth = YES;
    barLabel.minimumScaleFactor = FONT_SCALING_MIN;
    barLabel.textAlignment = NSTextAlignmentRight;
    barLabel.textColor = [UIColor get1stLabelColor];
    [self addSubview:barLabel];
    
    [progressBarView setTrackColor:UIColor.darkGrayColor];
}

- (void)setProgress:(CGFloat)progress {
    progressBarView.progress = progress;
}

- (CGPoint)getReservedCenter {
    return CGPointMake(RESERVED_WIDTH / 2, (CGRectGetHeight(self.frame) + PROGRESSBAR_HEIGHT) / 2);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat labelHeight = CGRectGetHeight(self.frame) - PROGRESSBAR_HEIGHT;
    CGFloat labelWidth = CGRectGetWidth(self.frame) - RESERVED_WIDTH;
    barLabel.frame = CGRectMake(RESERVED_WIDTH, PROGRESSBAR_HEIGHT, labelWidth, labelHeight);
    progressBarView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), PROGRESSBAR_HEIGHT);
}

@end
