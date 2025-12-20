//
//  VolumeSliderView.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"

@interface VolumeSliderView : UIView {
    IBOutlet UIView *volumeView;
    IBOutlet UISlider *volumeSlider;
    IBOutlet UILabel *volumeLabel;
    IBOutlet UIButton *muteButton;
    IBOutlet UIButton *plusButton;
    IBOutlet UIButton *minusButton;
    BOOL isMuted;
    BOOL isChangingVolume;
    int serverVolume;
}

- (id)initWithFrame:(CGRect)frame leftAnchor:(CGFloat)leftAnchor isSliderType:(BOOL)isSliderType;
- (void)startTimer;
- (void)stopTimer;
- (void)handleVolumeIncrease;
- (void)handleVolumeDecrease;

@property (nonatomic, strong) NSTimer *pollVolumeTimer;
@property (nonatomic, strong) NSTimer *holdVolumeTimer;
@property (nonatomic, strong) NSTimer *muteReadTimer;

@end
