//
//  BroadcastProgressView.h
//  Kodi Remote
//
//  Created by Buschmann on 27.12.24.
//  Copyright © 2024 Team Kodi. All rights reserved.
//

@import UIKit;

@class ProgressBarView;

@interface BroadcastProgressView : UIView {
    ProgressBarView *progressBarView;
}

- (void)setProgress:(CGFloat)progress;
- (CGPoint)getReservedCenter;

@property (nonatomic, readonly) UILabel *barLabel;

@end
