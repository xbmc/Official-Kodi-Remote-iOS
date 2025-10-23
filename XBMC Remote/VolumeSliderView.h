//
//  VolumeSliderView.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"

#define VOLUME_BUTTON_UP 1
#define VOLUME_BUTTON_DOWN 2
#define VOLUME_SLIDER 10

@interface VolumeSliderView : UIView {
    IBOutlet UIView *volumeView;
    IBOutlet UISlider *volumeSlider;
    IBOutlet UILabel *volumeLabel;
    IBOutlet UIButton *muteButton;
    IBOutlet UIButton *plusButton;
    IBOutlet UIButton *minusButton;
    BOOL isMuted;
    BOOL isChangingVolume;
    UIColor *muteIconColor;
}

- (id)initWithFrame:(CGRect)frame leftAnchor:(CGFloat)leftAnchor isSliderType:(BOOL)isSliderType;
- (void)startTimer;
- (void)stopTimer;
- (void)changeVolume:(NSInteger)action;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSTimer *holdVolumeTimer;

@end
